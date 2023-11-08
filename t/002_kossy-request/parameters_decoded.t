use strict;
use warnings;
use utf8;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(encode_json);
use Encode ();

# create a test app that parses JSON body
sub filter_json {
    my $app = shift;

    sub {
        my $env = shift;
        $env->{'kossy.request.parse_json_body'} = 1;
        $app->($env);
    }
}

subtest 'Decode query parameters' => sub {
    my $app = sub {
        my $env = shift;
        my $req = Kossy::Request->new($env);

        my $p1 = $req->query_parameters->{'p1'};
        my @p2 = $req->query_parameters->get_all('p2');

        ok Encode::is_utf8($p1);
        ok Encode::is_utf8($_) for @p2;

        is $p1, '👍', 'The thumb up emoji is correctly decoded';
        is_deeply \@p2, ['☀️', '🌕'], 'The sun and full moon emoji are correctly decoded';

        $req->new_response(200)->finalize;
    };

    test_psgi $app, sub {
        my $cb = shift;
        $cb->(GET "/?p1=%F0%9F%91%8D&p2=%E2%98%80%EF%B8%8F&p2=%F0%9F%8C%95");
    };
};

subtest 'Decode body parameters' => sub {

    my $app = sub {
        my $env = shift;
        my $req = Kossy::Request->new($env);

        my $p1 = $req->body_parameters->{'p1'};
        my @p2 = $req->body_parameters->get_all('p2');

        ok Encode::is_utf8($p1);
        ok Encode::is_utf8($_) for @p2;

        is $p1, '👍', 'The thumb up emoji is correctly decoded';
        is_deeply \@p2, ['☀️', '🌕'], 'The sun and full moon emoji are correctly decoded';

        $req->new_response(200)->finalize;
    };

    subtest 'with default parser' => sub {
        test_psgi $app, sub {
            my $cb = shift;
            $cb->(POST '/', { 
                p1 => '👍',
                p2 => ['☀️', '🌕'],
            });
        };
    };

    subtest 'with json parser' => sub {
        test_psgi filter_json($app), sub {
            my $cb = shift;
            $cb->(POST '/', { 
                p1 => '👍',
                p2 => ['☀️', '🌕'],
            });
        };
    };
};

subtest 'Decode JSON body parameters' => sub {

    my $app = sub {
        my $env = shift;
        my $req = Kossy::Request->new($env);

        my $p1 = $req->body_parameters->{'p1'};

        # NOTE: There is no need to use `get_all` method to get all of the array values.
        my $p2 = $req->body_parameters->{'p2'};

        ok Encode::is_utf8($p1);
        ok Encode::is_utf8($_) for @$p2;

        is $p1, '👍', 'The thumb up emoji is correctly decoded';
        is_deeply $p2, ['☀️', '🌕'], 'The sun and full moon emoji are correctly decoded';

        $req->new_response(200)->finalize;
    };

    test_psgi filter_json($app), sub {
        my $cb = shift;

        my $request = POST "/";

        my $encocded_json = encode_json({
            p1 => '👍',
            p2 => ['☀️', '🌕'],
        });
        $request->header('Content-Type' => 'application/json; charset=utf-8');
        $request->header('Content-Length' => length $encocded_json);
        $request->content($encocded_json);

        $cb->($request);
    };
};

done_testing;
