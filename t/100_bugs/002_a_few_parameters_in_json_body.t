use strict;
use warnings;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(encode_json);

sub run_test {
    my $data = shift;

    my $app = sub {
        my $env = shift;
        $env->{'kossy.request.parse_json_body'} = 1; # parse json body

        my $req = Kossy::Request->new($env);

        is_deeply $req->body_parameters->as_hashref_mixed, $data;

        $req->new_response(200)->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;

        my $req = POST "/";
        my $encocded_json = encode_json($data);
        $req->header('Content-Type' => 'application/json; charset=utf-8');
        $req->header('Content-Length' => length $encocded_json);
        $req->content($encocded_json);

        $cb->($req);
    };
}

run_test({ b => ['hello'] });
run_test({ b => [] });

done_testing;
