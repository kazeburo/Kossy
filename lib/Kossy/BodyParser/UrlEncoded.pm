package Kossy::BodyParser::UrlEncoded;
use strict;
use warnings;
use utf8;
use URL::Encode;

sub new {
    my $class = shift;
    bless { buffer => '' }, $class;
}

sub add {
    my $self = shift;
    if (defined $_[0]) {
        $self->{buffer} .= $_[0];
    }
}

sub finalize {
    my $self = shift;

    my $p = URL::Encode::url_params_flat($self->{buffer});
    return ($p, []);
}

1;
