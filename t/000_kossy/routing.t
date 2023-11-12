use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);

{
    package SampleApp;
    use Kossy;

    get '/'                              => sub { $_[1]->halt_text(200, 'GET /') };
    get '/user/me'                       => sub { $_[1]->halt_text(200, 'GET /user/me') };
    get '/user/:name'                    => sub { $_[1]->halt_text(200, 'GET /user/:name') };
    get '/user/:name/likes'              => sub { $_[1]->halt_text(200, 'GET /user/:name/likes') };
    post '/user/:name/likes'             => sub { $_[1]->halt_text(200, 'POST /user/:name/likes') };
    router 'DELETE', '/user/:name/likes' => sub { $_[1]->halt_text(200, 'DELETE /user/:name/likes') };

    get '/entry/:id'           => sub { $_[1]->halt_text(200, 'GET /entry/:id') };
    router 'PUT', '/entry/:id' => sub { $_[1]->halt_text(200, 'PUT /entry/:id') };
    get '/entry/foo'           => sub { $_[1]->halt_text(200, 'GET /entry/foo') };

    get '/org/{org_id:[0-9]+}' => sub { $_[1]->halt_text(200, 'GET /org/{org_id}') };
    get '/org/foo'             => sub { $_[1]->halt_text(200, 'GET /org/foo') };
}

my $app = SampleApp->psgi;

test_psgi $app, sub {
    my $cb = shift;

    is $cb->(GET "/")->content,                  'GET /';
    is $cb->(GET "/user/me")->content,           'GET /user/me';
    is $cb->(GET "/user/foo")->content,          'GET /user/:name';
    is $cb->(GET "/user/foo/likes")->content,    'GET /user/:name/likes';
    is $cb->(POST "/user/foo/likes")->content,   'POST /user/:name/likes';
    is $cb->(DELETE "/user/foo/likes")->content, 'DELETE /user/:name/likes';

    is $cb->(GET "/entry/bar")->content, 'GET /entry/:id';
    is $cb->(PUT "/entry/bar")->content, 'PUT /entry/:id';
    is $cb->(GET "/entry/foo")->content, 'GET /entry/:id', 'Not match /entry/foo';

    is $cb->(GET "/org/123")->content, 'GET /org/{org_id}';
    is $cb->(GET "/org/foo")->content, 'GET /org/foo';
    is $cb->(GET "/org/bar")->code, 404, 'Not match since `bar` is not number';

    is $cb->(GET "/not_found")->code, 404, 'Not found path';
    is $cb->(POST "/")->code, 405, 'Method not allowed';
};

done_testing;
