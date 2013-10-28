package Kossy::BodyParser::OctetStream;
use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub add { }

sub finalize {
    return ([],[]);
}

1;

