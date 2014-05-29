# NAME

Kossy - Sinatra-ish Simple and Clear web application framework

# SYNOPSIS

    % kossy-setup MyApp
    % cd MyApp
    % plackup app.psgi
    
    ## lib/MyApp/Web.pm
    
    use Kossy;
    
    get '/' => sub {
        my ( $self, $c )  = @_;
        $c->render('index.tx', { greeting => "Hello!" });
    };
    
    get '/json' => sub {
        my ( $self, $c )  = @_;
        my $result = $c->req->validator([
            'q' => {
                default => 'Hello',
                rule => [
                    [['CHOICE',qw/Hello Bye/],'Hello or Bye']
                ],
            }
        ]);
        $c->render_json({ greeting => $result->valid->get('q') });
    };
    
    1;
    
    ## views/index.tx
    : cascade base
    : around content -> {
      <: $greeting :>
    : }

# DESCRIPTION

Kossy is Sinatra-ish Simple and Clear web application framework, which is based upon [Plack](https://metacpan.org/pod/Plack), [Router::Simple](https://metacpan.org/pod/Router::Simple), [Text::Xslate](https://metacpan.org/pod/Text::Xslate) and build-in Form-Validator. That's suitable for small application and rapid development.

# Kossy class

Kossy exports some methods to building application

## CLASS METHODS for Kossy class

- my $kossy = Kossy->new( root\_dir => $root\_dir );

    Create instance of the application object.

## OBJECT METHODS for Kossy class

- my $root\_dir = $kossy->root\_dir();

    accessor to root directory of the application

- my $app = $kossy->psgi();

    return PSGI application

## DISPATCHER METHODS for Kossy class

- filter

    makes application wrapper like plack::middlewares.

        filter 'set_title' => sub {
            my $app:CODE = shift;
            sub {
                my ( $self:Kossy, $c:Kossy::Connection )  = @_;
                $c->stash->{site_name} = __PACKAGE__;
                $app->($self,$c);
            }
        };

- get path:String => \[\[filters\] =>\] CODE
- post path:String => \[\[filters\] =>\] CODE

    setup router and dispatch code

        get '/' => [qw/set_title/] => sub {
            my ( $self:Kossy, $c:Kossy::Connection )  = @_;
            $c->render('index.tx', { greeting => "Hello!" });
        };
        
        get '/json' => sub {
            my ( $self:Kossy, $c:Kossy::Connection )  = @_;
            $c->render_json({ greeting => "Hello!" });
        };

    dispatch code shall return Kossy::Response object or PSGI response ArrayRef or String.

- router 'HTTP\_METHOD'|\['METHOD'\[,'METHOD'\]\] => path:String => \[\[filters\] =>\] CODE

    adds routing rule other than GET and POST

        router 'PUT' => '/put' => sub {
            my ( $self:Kossy, $c:Kossy::Connection )  = @_;
            $c->render_json({ greeting => "Hello!" });
        };

# Kossy::Connection class

per-request object, herds request and response

## OBJECT METHODS for Kossy::Connection class

- req:Kossy::Request
- res:Kossy::Response
- stash:HashRef
- args:HashRef

    Router::Simple->match result

- halt(status\_code, message)

    die and response immediately

- redirect($uri,status\_code): Kossy::Response
- render($file,$args): Kossy::Response

    calls Text::Xslate->render makes response. template files are searching in root\_dir/views directory

    template syntax is Text::Xslate::Syntax::Kolon, can use Kossy::Connection object and fillinform block.

        ## template.tx
        : block form |  fillinform( $c.req ) -> {
        <head>
        <title><: $c.stash.title :></title>
        </head>
        <body>
        <form action="<: $c.req.uri_for('/post') :>">
        <input type="text" size="10" name="title" />
        <textarea name="body" rows="20" cols="90"></textarea>
        </form>
        </body>
        : }

    also can use [Text::Xslate::Bridge::TT2Like](https://metacpan.org/pod/Text::Xslate::Bridge::TT2Like) and [Number::Format](https://metacpan.org/pod/Number::Format) methods in your template

- render\_json($args): Kossy::Response

    serializes arguments with JSON and makes response

    This method escapes '<', '>', and '+' characters by "\\uXXXX" form. Browser don't detects the JSON as HTML. And also this module outputs "X-Content-Type-Options: nosniff" header for IEs.

    render\_json have a JSON hijacking detection feature same as [Amon2::Plugin::Web::JSON](https://metacpan.org/pod/Amon2::Plugin::Web::JSON). This returns "403 Forbidden" response if following pattern request.

    - The request have 'Cookie' header.
    - The request doesn't have 'X-Requested-With' header.
    - The request contains /android/i string in 'User-Agent' header.
    - Request method is 'GET'

# Kossy::Request

This class is child class of Plack::Request, decode query/body parameters automatically. Return value of $req->param(), $req->body\_parameters, etc. is the decoded value.

## OBJECT METHODS for Kossy::Request class

- uri\_for($path,$args):String

    build absolute URI with path and $args

        my $uri = $c->req->uri_for('/login',[ arg => 'Hello']);  

- validator($rule):Kossy::Validaor::Result

    validate parameters using [Kossy::Validatar](https://metacpan.org/pod/Kossy::Validatar)

        my $result = $c->req->validator([
          'q' => [['NOT_NULL','query must be defined']],
          'level' => {
              default => 'M',
              rule => [
                  [['CHOICE',qw/L M Q H/],'invalid level char'],
              ],
          },
        ]);

        my $val = $result->valid('q');
        my $val = $result->valid('level');

- body\_parameters\_raw
- query\_parameters\_raw
- parameters\_raw
- param\_raw

    These methods are the accessor to raw values. 'raw' means the value is not decoded.

# Kossy::Response

This class is child class of Plack::Response

# CUSTOMIZE

- X-Frame-Options

    By default, Kossy outputs "X-Frame-Options: DENY". You can change this header 

        get '/iframe' => sub {
            my ($self, $c) = @_;
            $c->res->header('X-Frame-Options','SAMEORIGIN');
            # or remove from response header
            # delete $c->res->headers->remove_header('X-Frame-Options');
            ..
        }

    (Default: DENY)

- kossy.request.parse\_json\_body

    If enabled, Kossy will decode json in the request body that has "application/json" content header

        post '/api' => sub {
            my ($self, $c) = @_;
            $c->env->{kossy.request.parse_json_body} = 1;
            my val = $c->req->param('foo'); # bar
        }

        # requrest
        # $ua->requrest(
        #     HTTP::Request->new(
        #         "POST",
        #         "http://example.com/api",
        #         [ "Content-Type" => 'application/json', "Content-Length" => 13 ],
        #         '{"foo":"bar"}'
        #     )
        # );

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

Kossy is small waf, that has only 400 lines code. so easy to reading framework code and customize it. Sinatra-ish router, build-in templating, validators and zero-configuration features are suitable for small application and rapid development.

[Amon2::Lite](https://metacpan.org/pod/Amon2::Lite)

[Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite)

[Dancer](https://metacpan.org/pod/Dancer)

[Kossy::Validator](https://metacpan.org/pod/Kossy::Validator)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
