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

            $res = $cb->( GET "http://localhost/foo" );
            is $res->code, 404;

            $res = $cb->( GET "http://localhost/uri_for" );
            is $res->code, 200;
            is $res->content, "http://localhost/uri_for";

            $res = $cb->( POST "http://localhost/uri_for" );
            is $res->code, 405;

            $res = $cb->( GET "http://localhost/bar" );
            is $res->code, 200;
            $res = $cb->( POST "http://localhost/bar" );
            is $res->code, 200;
            $res = $cb->( HEAD "http://localhost/bar" );
            is $res->code, 405;

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
        };
};

done_testing;
