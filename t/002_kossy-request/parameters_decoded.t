use strict;
use warnings;
use utf8;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(encode_json);
use Encode ();

my $app = sub {
    my $env = shift;
    my $req = Kossy::Request->new($env);

    ok Encode::is_utf8($req->query_parameters->{'q'});
    is $req->query_parameters->{'q'}, '👍', 'The thumb up emoji is correctly decoded';

    ok Encode::is_utf8($req->body_parameters->{'b'});
    is $req->body_parameters->{'b'}, 'こんにちは', 'Japanese greeting is correctly decoded';

    my @q2 = $req->query_parameters->get_all('q2');
    ok Encode::is_utf8($_) for @q2;
    is_deeply \@q2, ['☀️', '🌕'], 'The sun and full moon emoji are correctly decoded';

    my @b2 = $req->body_parameters->get_all('b2');
    ok Encode::is_utf8($_) for @b2;
    is_deeply \@b2, ['おはよう', 'こんばんは'], 'Japanese greeting are correctly decoded';

    $req->new_response(200)->finalize;
};

my $parse_json_app = sub {
    my $env = shift;
    $env->{'kossy.request.parse_json_body'} = 1;
    $app->($env);
};

my $query = 'q=%F0%9F%91%8D&q2=%E2%98%80%EF%B8%8F&q2=%F0%9F%8C%95';
my $body_parameters = {
    b  => 'こんにちは',
    b2 => ['おはよう', 'こんばんは'],
};

subtest 'default parser' => sub {
    my $request = POST "/?$query", $body_parameters;

    test_psgi $app, sub {
        my $cb = shift;
        $cb->($request);
    };
};

subtest 'json parser' => sub {
    my $request = POST "/?$query", $body_parameters;

    test_psgi $parse_json_app, sub {
        my $cb = shift;
        $cb->($request);
    };
};

subtest 'JSON request with json parser' => sub {
    my $request = POST "/?$query";

    my $encocded_json = encode_json($body_parameters);
    $request->header('Content-Type' => 'application/json; charset=utf-8');
    $request->header('Content-Length' => length $encocded_json);
    $request->content($encocded_json);

    test_psgi $parse_json_app, sub {
        my $cb = shift;
        $cb->($request);
    };
};

done_testing;
