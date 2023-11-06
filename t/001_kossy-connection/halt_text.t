use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Response;

my $c = Kossy::Connection->new(
    res => Plack::Response->new,
);

subtest "normal case" => sub {
    eval { $c->halt_text(201, 'hello') };

    isa_ok $@, 'Kossy::Exception';
    is_deeply $@->response, [
        201,
        [ 'Content-Type' => 'text/plain' ],
        [ 'hello' ],
    ];
};

subtest "no code" => sub {
    eval { $c->halt_text() };

    isa_ok $@, 'Kossy::Exception';
    is_deeply $@->response, [
        500,
        [ 'Content-Type' => 'text/plain' ],
        [  ],
    ];
};

subtest "no message" => sub {
    eval { $c->halt_text(200) };

    isa_ok $@, 'Kossy::Exception';
    is_deeply $@->response, [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [  ],
    ];
};

done_testing;
