use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Response;

my $c = Kossy::Connection->new();

local $Kossy::Response::SECURITY_HEADER = 0;

subtest "default case" => sub {
    eval { $c->halt() };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 500;
    like $body->[0], qr/Internal Server Error/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

subtest "only code" => sub {
    eval { $c->halt(404) };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 404;
    like $body->[0], qr/Not Found/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

subtest "code and message" => sub {
    eval { $c->halt(201, "Created Foo") };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 201;
    like $body->[0], qr/Created Foo/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

subtest "code and message / named interface" => sub {
    eval { $c->halt(500, message => "My Error") };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 500;
    like $body->[0], qr/My Error/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

subtest "location" => sub {
    eval { $c->halt(301, location => "/foo") };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 301;
    like $body->[0], qr/Moved Permanently/;
    is_deeply $headers, [
        'Location'     => '/foo',
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

subtest "no location" => sub {
    eval { $c->halt(301) };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 301;
    like $body->[0], qr/Moved Permanently/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};


subtest "original response" => sub {
    my $res = Plack::Response->new();
    $res->content_type('application/json');
    $res->body("{ 'error': 'Bad Request!!' }");
    $res->code(200);

    eval { $c->halt(400, response => $res) };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 400; # override 200
    is $body->[0], "{ 'error': 'Bad Request!!' }";
    is_deeply $headers, [
        'Content-Type' => 'application/json',
    ];
};

subtest "odd arguments" => sub {
    eval { $c->halt(201, message => 'Foo!!', 'bar') };

    isa_ok $@, 'Kossy::Exception';
    my ($code, $headers, $body) = @{ $@->response };

    is $code, 201;
    like $body->[0], qr/Created/;
    unlike $body->[0], qr/Foo!!/;
    is_deeply $headers, [
        'Content-Type' => 'text/html; charset=UTF-8',
    ];
};

done_testing;
