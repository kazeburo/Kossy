use strict;
use warnings;
use Test::More;
use File::Basename;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use lib "t";

use MyApp;

my $root_dir = File::Basename::dirname(__FILE__);

subtest "/" => sub {
    local $Kossy::SECURITY_HEADER = 0;
    my $app = MyApp->psgi($root_dir);
    test_psgi
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $res = $cb->( GET "http://localhost/" );
            is $res->code, 200;
            is $res->content, "ok";
            is $res->header('Content-Type'), 'text/html; charset=UTF-8';
            ok !$res->header('X-Frame-Options');;
            ok !$res->header('X-XSS-Protection');
        };
};

done_testing;
