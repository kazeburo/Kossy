package Kossy::Request;

use strict;
use warnings;
use parent qw/Plack::Request/;
use Hash::MultiValue;
use Encode;
use Kossy::Validator;
use HTTP::Entity::Parser;
use WWW::Form::UrlEncoded qw/parse_urlencoded build_urlencoded/;

our $VERSION = '0.32';

sub new {
    my($class, $env, %opts) = @_;
    Carp::croak(q{$env is required})
        unless defined $env && ref($env) eq 'HASH';

    bless {
        %opts,
        env => $env,
    }, $class;
}

sub new_response {
    my $self = shift;
    require Kossy::Response;
    Kossy::Response->new(@_);
}

sub request_body_parser {
    my $self = shift;
    unless (exists $self->{request_body_parser}) {
        $self->{request_body_parser} = $self->_build_request_body_parser();
    }
    return $self->{request_body_parser};
}

sub _build_request_body_parser {
    my $self = shift;

    my $parser = HTTP::Entity::Parser->new();
    $parser->register(
        'application/x-www-form-urlencoded',
        'HTTP::Entity::Parser::UrlEncoded'
    );
    $parser->register(
        'multipart/form-data',
        'HTTP::Entity::Parser::MultiPart'
    );
    if ( $self->env->{'kossy.request.parse_json_body'} ) {
            $parser->register(
                'application/json',
                'HTTP::Entity::Parser::JSON'
            );
    }
    $parser;
}

sub _parse_request_body {
    my $self = shift;
    my ($params,$uploads) = $self->request_body_parser->parse($self->env);
    $self->env->{'kossy.request.body_parameters'} = $params;

    my $upload_hmv = Hash::MultiValue->new();
    while ( my ($k,$v) = splice @$uploads, 0, 2 ) {
        my %copy = %$v;
        $copy{headers} = HTTP::Headers::Fast->new(@{$v->{headers}});
        $upload_hmv->add($k, Plack::Request::Upload->new(%copy));
    }
    $self->env->{'plack.request.upload'} = $upload_hmv;
}

sub uploads {
    my $self = shift;
    unless ($self->env->{'plack.request.upload'}) {
        $self->_parse_request_body;
    }
    $self->env->{'plack.request.upload'};
}

sub body_parameters {
    my ($self) = @_;
    $self->env->{'kossy.request.body'} ||= $self->_decode_parameters(@{$self->_body_parameters()});
}

sub query_parameters {
    my ($self) = @_;
    $self->env->{'kossy.request.query'} ||= $self->_decode_parameters(@{$self->_query_parameters()});
}

sub parameters {
    my $self = shift;
    $self->env->{'kossy.request.merged'} ||= do {
        Hash::MultiValue->new(
            $self->query_parameters->flatten,
            $self->body_parameters->flatten,            
        );
    };
}

sub _decode_parameters {
    my ($self, @flatten) = @_;
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode_utf8($k), Encode::decode_utf8($v);
    }
    return Hash::MultiValue->new(@decoded);
}

sub _body_parameters {
    my $self = shift;
    unless ($self->env->{'kossy.request.body_parameters'}) {
        $self->_parse_request_body;
    }
    return $self->env->{'kossy.request.body_parameters'};    
}

sub _query_parameters {
    my $self = shift;
    unless ( $self->env->{'kossy.request.query_parameter'} ) {
        $self->env->{'kossy.request.query_parameters'} = 
            [parse_urlencoded($self->env->{'QUERY_STRING'})];
    }
    return $self->env->{'kossy.request.query_parameters'};
}

sub body_parameters_raw {
    my $self = shift;
    unless ($self->env->{'plack.request.body'}) {
        $self->env->{'plack.request.body'} = Hash::MultiValue->new(@{$self->_body_parameters});
    }
    return $self->env->{'plack.request.body'};
}

sub query_parameters_raw {
    my $self = shift;
    unless ($self->env->{'plack.request.query'}) {
        $self->env->{'plack.request.query'} = Hash::MultiValue->new(@{$self->_query_parameters});
    }
    return $self->env->{'plack.request.query'};
}

sub parameters_raw {
    my $self = shift;
    $self->env->{'plack.request.merged'} ||= do {
        Hash::MultiValue->new(
            @{$self->_query_parameters},
            @{$self->_body_parameters}
        );
    };
}

sub param_raw {
    my $self = shift;

    return keys %{ $self->parameters_raw } if @_ == 0;

    my $key = shift;
    return $self->parameters_raw->{$key} unless wantarray;
    return $self->parameters_raw->get_all($key);
}

sub base {
    my $self = shift;
    $self->{_base} ||= {};
    my $base = $self->_uri_base;
    $self->{_base}->{$base} ||= $self->SUPER::base;
    $self->{_base}->{$base}->clone;
}

sub uri_for {
     my($self, $path, $args) = @_;
     my $uri = $self->base;
     my $base = $uri->path eq "/"
              ? ""
              : $uri->path;
     $uri->path( $base . $path );
     $uri->query(build_urlencoded($args)) if $args;
     $uri;
}

sub validator {
    my ($self, $rule) = @_;
    Kossy::Validator->check($self,$rule);
}

1;
