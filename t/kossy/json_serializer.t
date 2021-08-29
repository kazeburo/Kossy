use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Kossy;

local $Kossy::JSON_SERIALIZER = MyJSONSerializer->new;

get '/' => sub {
    my ($self, $c) = @_;
    isa_ok($c->json_serializer, 'MyJSONSerializer');
    return $c->render_json({ a => 1 });
};

my $app = __PACKAGE__->psgi;

test_psgi($app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/");
    is $res->content, "a:1";
});

done_testing;

package MyJSONSerializer;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub encode {
    my ($self, $obj) = @_;
    join '-', map { "$_:$obj->{$_}" } sort keys %$obj;
}

