use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Request;
use Plack::Response;

my $env = {};
my $c = Kossy::Connection->new(
    req => Plack::Request->new($env),
    res => Plack::Response->new,
);

subtest 'default case' => sub {
    my $res = $c->render_json({ a => 1 });
    is $res->code, 200;
    is $res->body, '{"a":1}';
    is $res->header('Content-Type'), 'application/json; charset=UTF-8';
    is $res->header('X-Content-Type-Options'), 'nosniff';
};

subtest 'json hijack' => sub {
    subtest 'halt' => sub {
        $c->req->env->{HTTP_USER_AGENT} = 'android';
        $c->req->env->{HTTP_COOKIE} = 'foo=bar';
        delete $c->req->env->{'HTTP_X_REQUESTED_WITH'};

        eval { $c->render_json({ a => 1 }) };
        isa_ok $@, 'Kossy::Exception';
        is $@->{code}, 403;
    };

    subtest 'no halt' => sub {
        $c->req->env->{HTTP_USER_AGENT} = 'android';
        $c->req->env->{HTTP_COOKIE} = 'foo=bar';
        $c->req->env->{'HTTP_X_REQUESTED_WITH'} = 'XMLHttpRequest';

        my $res = $c->render_json({ a => 1 });
        is $res->code, 200;
    };
};

done_testing;
