use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Request;
use Plack::Response;
use JSON qw//;

my $env = {};
my $json_serializer = JSON->new();
my $c = Kossy::Connection->new(
    req => Plack::Request->new($env),
    res => Plack::Response->new,
    json_serializer => $json_serializer,
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

subtest 'customize json_serializer' => sub {
    my $json_serializer = MyJSONSerializer->new;
    $c->json_serializer($json_serializer);

    my $res = $c->render_json("foo", "bar", "baz");
    is $res->body, 'foo-bar-baz';
};

done_testing;

package MyJSONSerializer;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub encode {
    my $self = shift;
    join '-', @_;
}
