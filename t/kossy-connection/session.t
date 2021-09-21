use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Request;

my $env = {};
my $c = Kossy::Connection->new(
    req => Plack::Request->new($env),
);

subtest 'session' => sub {
    ok !exists $c->{session}, 'no instance cache';
    isa_ok($c->session, 'Plack::Session');
    isa_ok($c->{session}, 'Plack::Session');
};

done_testing;
