package MyApp;

use strict;
use warnings;
use Kossy;

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
    my $param = $c->req->param('q');
    $c->response->body("ok => " . $param);
};

get '/set_cookie' => sub {
    my ( $self, $c )  = @_;
    $c->response->cookies->{'foo'} = '123 456';
    $c->response->body("cookies are baked");
};
 
1;

