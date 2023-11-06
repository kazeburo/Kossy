use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Response;

my $c = Kossy::Connection->new(
    res => Plack::Response->new,
);

subtest "normal case" => sub {
    eval { $c->halt_no_content(201) };

    isa_ok $@, 'Kossy::Exception';
    is_deeply $@->response, [
        201,
        [ 'Content-Length' => 0 ],
        [ ],
    ];
};

subtest "no code" => sub {
    eval { $c->halt_no_content() };

    isa_ok $@, 'Kossy::Exception';
    is_deeply $@->response, [
        500,
        [ 'Content-Length' => 0 ],
        [ ],
    ];
};

done_testing;
