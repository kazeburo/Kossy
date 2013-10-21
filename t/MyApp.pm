package MyApp;

use strict;
use warnings;
use Kossy;
use Cookie::Baker;

get "/" => sub {
    my ( $self, $c )  = @_;
    $c->response->body("ok");
};

get "/uri_for" => sub {
    my ( $self, $c )  = @_;
    $c->response->body( $c->request->uri_for("/uri_for")->as_string );
};

router [qw/GET POST/] => "/bar" => sub {
    my ( $self, $c )  = @_;
    $c->response->body("ok");
};

get '/set_cookie' => sub {
    my ( $self, $c )  = @_;
    $c->response->cookies->{foo} = '123456';
    $c->response->body("cookies are baked");
};
 
1;

