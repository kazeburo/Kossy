use strict;
use warnings;
use Test::More;
use File::Basename;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use lib "t";

use_ok "MyApp";

my $root_dir = File::Basename::dirname(__FILE__);
my $app = MyApp->psgi($root_dir);

subtest "/" => sub {
    test_psgi
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $res = $cb->( GET "http://localhost/" );
            is $res->code, 200;
            is $res->content, "ok";
            is $res->header('Content-Type'), 'text/html; charset=UTF-8';
            is $res->header('X-Frame-Options'), 'DENY';
            is $res->header('X-XSS-Protection'), '1';

            $res = $cb->( GET "http://localhost/foo" );
            is $res->code, 404;

            $res = $cb->( GET "http://localhost/uri_for" );
            is $res->code, 200;
            is $res->content, "http://localhost/uri_for";

            $res = $cb->( POST "http://localhost/uri_for" );
            is $res->code, 405;

            $res = $cb->( GET "http://localhost/bar?q=baz" );
            is $res->code, 200;
            is $res->content, "ok => baz";
            $res = $cb->( POST "http://localhost/bar?q=baz" );
            is $res->code, 200;
            is $res->content, "ok => baz";
            $res = $cb->( HEAD "http://localhost/bar?q=baz" );
            is $res->code, 405;

            $res = $cb->( GET "http://localhost/set_cookie" );
            is $res->code, 200;
            is $res->content, "cookies are baked";
            is $res->header('Content-Type'), 'text/html; charset=UTF-8';
            is $res->header('X-Frame-Options'), 'DENY';
            is $res->header('X-XSS-Protection'), '1';
            is $res->header('Set-Cookie'), 'foo=123%20456';

            $res = $cb->(HTTP::Request->new(
                "POST","http://localhost/json_api",
                ["Content-Type"=>'application/json',"Content-Length"=> 11 ],
                q!{"q":"abc"}!
            ));
            is $res->content, "json_api:abc";
            is $res->header('X-Frame-Options'), 'SAMEORIGIN';

            $res = $cb->( GET "http://localhost/new_response" );
            is $res->code, 200;
            is $res->content, "new_response";
            is $res->header('X-XSS-Protection'), '1';

            $res = $cb->( GET "http://localhost/args/foo" );
            is $res->code, 200;
            is $res->content, "is_decoded:1,foo";

            $res = $cb->( GET "http://localhost/args/%E3%81%82%E3%81%84%E3%81%86" );
            is $res->code, 200;
            is $res->content, "is_decoded:1,あいう";
        };
};

subtest "/mount" => sub {
    test_psgi
        app    => builder { mount "/mount", $app },
        client => sub {
            my $cb  = shift;
            my $res = $cb->( GET "http://localhost/" );
            is $res->code, 404;

            $res = $cb->( GET "http://localhost/mount/" );
            is $res->code, 200;
            is $res->content, "ok";

            $res = $cb->( GET "http://localhost/mount/foo" );
            is $res->code, 404;

            $res = $cb->( GET "http://localhost/mount/uri_for" );
            is $res->code, 200;
            is $res->content, "http://localhost/mount/uri_for";

            $res = $cb->( GET "http://localhost/mount/uri_for_with_param" );
            is $res->code, 200;
            is $res->content, "http://localhost/mount/uri_for?a=b";

            $res = $cb->( GET "http://localhost/mount/uri_for_with_noparam" );
            is $res->code, 200;
            is $res->content, "http://localhost/mount/uri_for";


        };
};

done_testing;
