package Kossy::Response;

use strict;
use warnings;
use parent qw/Plack::Response/;
use Encode;
use Kossy::Headers;
use Cookie::Baker;

our $VERSION = '0.39';

sub new {
    my ($class, $rc, $headers, $content) = @_;
    if ( defined $headers ) {
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = Kossy::Headers->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = Kossy::Headers->new(%$headers);
        }
    }
    bless {
        defined $rc ? ( status => $rc ) : (),
        defined $content ? ( body => $content ) : (),
        defined $headers ? ( headers => $headers ) : (),
    }, $class;
}

sub headers {
    my $self = shift;

    if (@_) {
        my $headers = shift;
        if (ref $headers eq 'ARRAY') {
            Carp::carp("Odd number of headers") if @$headers % 2 != 0;
            $headers = Kossy::Headers->new(@$headers);
        } elsif (ref $headers eq 'HASH') {
            $headers = Kossy::Headers->new(%$headers);
        }
        return $self->{headers} = $headers;
    } else {
        return $self->{headers} ||= Kossy::Headers->new();
    }
}

sub _body {
    my $self = shift;
    my $body = $self->body;
       $body = [] unless defined $body;
    if (!ref $body or Scalar::Util::blessed($body) && overload::Method($body, q("")) && !$body->can('getline')) {
        return [ Encode::encode_utf8($body) ] if Encode::is_utf8($body);
        return [ $body ];
    } else {
        return $body;
    }
}

sub finalize {
    my $self = shift;
    Carp::croak "missing status" unless $self->status();

    my $headers = $self->headers->as_psgi;

    while (my($name, $val) = each %{$self->cookies}) {
        my $cookie = bake_cookie($name, $val);
        push @$headers, 'Set-Cookie' => $cookie;
    }

    return [
        $self->status,
        $headers,
        $self->_body,
    ];
}

1;
