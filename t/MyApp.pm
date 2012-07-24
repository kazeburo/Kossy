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

1;

