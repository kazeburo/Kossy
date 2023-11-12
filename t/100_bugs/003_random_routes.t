use strict;
use warnings;

use Test::More;
use Kossy;
use Plack::Test;
use HTTP::Request::Common;

get '/api/me' => sub {
    my ($self, $c) = @_;
    $c->halt_text(200, '/api/me');
};

get '/api/:name' => sub {
    my ($self, $c) = @_;
    $c->halt_text(200, '/api/:name');
};

my $app = __PACKAGE__->psgi;

test_psgi $app, sub {
    my $cb = shift;

    # Matching routing was unstable due to random Hash keys.
    # This change gives priority to the previously defined routing
    my $res = $cb->(GET "/api/me");
    is $res->content, '/api/me';
};

done_testing;
