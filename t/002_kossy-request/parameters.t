use strict;
use warnings;

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
    my $request = POST "/?q=123&q=456", { b => [ "hello", "world" ] };

    run_test($request,
        { q => ['123', '456'] },
        { b => ['hello', 'world'] }
    );
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

subtest 'When POST JSON request with parameter values are array' => sub {
    my $request = POST "/?q=123&q=456";

    my $encocded_json = encode_json({ b => ['hello', 'world'] });
    $request->header('Content-Type' => 'application/json; charset=utf-8');
    $request->header('Content-Length' => length $encocded_json);
    $request->content($encocded_json);

    run_test($request,
        { q => ['123', '456'] },
        { b => ['hello', 'world'] }
    );
};

done_testing;
