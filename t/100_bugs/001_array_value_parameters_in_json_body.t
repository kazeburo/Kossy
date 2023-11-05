use strict;
use warnings;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(encode_json);

my $app = sub {
    my $env = shift;
    $env->{'kossy.request.parse_json_body'} = 1; # parse json body

    my $req = Kossy::Request->new($env);

    is_deeply $req->body_parameters->as_hashref_mixed, { b => ['hello', 'world'] };

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = POST "/";
    my $encocded_json = encode_json({ b => ['hello', 'world'] });
    $req->header('Content-Type' => 'application/json; charset=utf-8');
    $req->header('Content-Length' => length $encocded_json);
    $req->content($encocded_json);

    $cb->($req);
};

done_testing;
