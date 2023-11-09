use strict;
use warnings;
use utf8;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(encode_json);

sub run_test {
    my ($request, $expected_query, $expected_body, $expected_parameters) = @_;
    $expected_parameters ||= { %$expected_query, %$expected_body };

    my $app = sub {
        my $env = shift;
        my $req = Kossy::Request->new($env);

        eval {
            is_deeply($req->query_parameters->as_hashref_mixed, $expected_query, 'query parameters');
            is_deeply($req->body_parameters->as_hashref_mixed, $expected_body, 'body parameters');
            is_deeply $req->parameters->as_hashref_mixed, $expected_parameters, 'query and body parameters are merged';
        };

        ok(!$@, 'no error') or diag $@;

        $req->new_response(200)->finalize;
    };

    # Run tests with default parser when Content-Type is NOT application/json
    if ( ($request->header('Content-Type')||'') !~ m{^application/json}) {
        subtest 'default_parser' => sub {
            test_psgi $app, sub {
                my $cb = shift;
                $cb->($request);
            };
        };
    }

    # Run tests with JSON parser
    #   when Content-Type is application/json, www-form-urlencoded or multipart/form-data
    subtest 'json_parser' => sub {
        my $parse_json_app = sub {
            my $env = shift;
            $env->{'kossy.request.parse_json_body'} = 1;
            $app->($env);
        };

        test_psgi $parse_json_app, sub {
            my $cb = shift;
            $cb->($request);
        };
    };
}

subtest 'When GET request' => sub {
    my $request = GET "/?q1=123&q2=456", { b => "hello" };

    run_test($request,
        { q1 => '123', q2 => '456' },
        {}, # empty body parameters
    );
};

subtest 'When POST request with parameter values are single' => sub {
    my $request = POST "/?q1=123&q2=456", { b1 => 'hello', b2 => 'world' };

    run_test($request,
        { q1 => '123', q2 => '456' },
        { b1 => 'hello', b2 => 'world' }
    );
};

subtest 'When POST request with parameter key is conflict' => sub {
    my $request = POST "/?key=123", { key => 'hello' };

    run_test($request,
        { key => '123' },
        { key => 'hello' },
        { key => ['123', 'hello'] } # merged parameters
    );
};

subtest 'When POST request with parameter values are multi' => sub {
    my $request = POST "/?q=123&q=456", [ b => "hello", b => "world" ];

    run_test($request,
        { q => ['123', '456'] },
        { b => ['hello', 'world'] }
    );
};

subtest 'When POST request with parameter values are array' => sub {
    subtest 'If requested an empty array, then the body parameters is empty.' => sub {
        my $request = POST "/?q=123", { b => [] };
        run_test($request, { q => '123' }, {} );
    };

    subtest 'If requested an one element array, then the body parameters is single value.' => sub {
        my $request = POST "/?q=123", { b => ['hello'] };
        run_test($request, { q => '123' }, { b => 'hello' } );
    };

    subtest 'If requested an multi elements array, then the body parameters is array.' => sub {
        my $request = POST "/?q=123", { b => ['hello', 'world'] };
        run_test($request, { q => '123' }, { b => ['hello', 'world'] } );
    };
};

subtest 'When POST JSON request with parameter values are single' => sub {
    my $request = POST "/?q=123&q=456";

    my $encocded_json = encode_json({ b1 => 'hello', b2 => 'world' });
    $request->header('Content-Type' => 'application/json; charset=utf-8');
    $request->header('Content-Length' => length $encocded_json);
    $request->content($encocded_json);

    run_test($request,
        { q => ['123', '456'] },
        { b1 => 'hello', b2 => 'world' }
    );
};

subtest 'When POST JSON request with parameter value is complex structure' => sub {

    my $run_test = sub {
        my ($request_data) = @_;

        # body parameters are expected to match $request_data
        my $expected = $request_data;

        my $request = POST "/?q=123";

        my $encocded_json = encode_json($request_data);
        $request->header('Content-Type' => 'application/json; charset=utf-8');
        $request->header('Content-Length' => length $encocded_json);
        $request->content($encocded_json);

        run_test($request, { q => '123' }, $expected);
    };

    subtest 'Empty array' => sub {
        $run_test->({ b => [] });
    };

    subtest 'One element array' => sub {
        $run_test->({ b => ['hello'] });
    };

    subtest 'Multi elements array' => sub {
        $run_test->({ b => ['hello', 'world'] });
    };

    subtest 'Array with undef' => sub {
        $run_test->({ b => ['hello', undef] });
    };

    subtest 'Empty hashref' => sub {
        $run_test->({ b => { } });
    };

    subtest 'One element hashref' => sub {
        $run_test->({ b => { 'foo' => 1 } });
    };

    subtest 'Multi elements hashref' => sub {
        $run_test->({ b => { 'foo' => 1, 'bar' => 2 } });
    };

    subtest 'HashRef with undef' => sub {
        $run_test->({ b => { 'hello' => undef } });
    };

    subtest 'Complex case' => sub {
        $run_test->({
            b1 => 'hello',
            b2 => [ 'hono', '🔥' ],
            b3 => { 'foo' => 1, 'bar' => 2, 'boo' => '👍' },
            b4 => undef,
        });
    };
};

subtest 'Use json_parameters' => sub {

    my $run_test = sub {
        my $request_data = shift;

        # JSON parameters are expected to match $request_data
        my $expected = $request_data;

        my $app = sub {
            my $env = shift;
            my $req = Kossy::Request->new($env);

            is_deeply $req->json_parameters, $expected;

            $req->new_response(200)->finalize;
        };

        # NOTE: json_parameters not need to set kossy.request.parse_json_body
        test_psgi $app, sub {
            my $cb = shift;

            my $request = POST "/";

            my $encocded_json = encode_json($request_data);
            $request->header('Content-Type' => 'application/json; charset=utf-8');
            $request->header('Content-Length' => length $encocded_json);
            $request->content($encocded_json);

            $cb->($request);
        };
    };

    subtest 'Empty array' => sub {
        $run_test->({ b => [] });
    };

    subtest 'One element array' => sub {
        $run_test->({ b => ['hello'] });
    };

    subtest 'Multi elements array' => sub {
        $run_test->({ b => ['hello', 'world'] });
    };

    subtest 'Array with undef' => sub {
        $run_test->({ b => ['hello', undef] });
    };

    subtest 'Empty hashref' => sub {
        $run_test->({ b => { } });
    };

    subtest 'One element hashref' => sub {
        $run_test->({ b => { 'foo' => 1 } });
    };

    subtest 'Multi elements hashref' => sub {
        $run_test->({ b => { 'foo' => 1, 'bar' => 2 } });
    };

    subtest 'HashRef with undef' => sub {
        $run_test->({ b => { 'hello' => undef } });
    };

    subtest 'Complex case' => sub {
        $run_test->({
            b1 => 'hello',
            b2 => [ 'hono', '🔥' ],
            b3 => { 'foo' => 1, 'bar' => 2, 'boo' => '👍' },
            b4 => undef,
        });
    };
};

done_testing;
