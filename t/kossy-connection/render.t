use strict;
use warnings;
use Test::More;

use Kossy::Connection;
use Plack::Request;
use Plack::Response;

my $env = {};
my $c = Kossy::Connection->new(
    tx  => MyTemplate->new,
    req => Plack::Request->new($env),
    res => Plack::Response->new,
);

subtest 'normal case' => sub {
    my $res = $c->render('myfile', { a => 'hello' });

    is $res->code, 200;
    is_deeply $res->body, {
        file => 'myfile',
        vars => {
            a     => 'hello',
            c     => $c,
            stash => undef,
        }
    };
    is $res->header('Content-Type'), 'text/html; charset=UTF-8';
};

done_testing;

package MyTemplate;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub render {
    my $self = shift;
    my ($file, $vars) = @_;

    return {
        file => $file,
        vars => $vars,
    }
}

