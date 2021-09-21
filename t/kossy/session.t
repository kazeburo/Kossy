use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

use Kossy;
use Plack::Builder;
use Plack::Middleware::Session;

get '/' => sub {
    my ($self, $c) = @_;

    my $counter = $c->session->get('counter') || 0;
    ++$counter;
    $c->session->set(counter => $counter);
    return $c->halt_text(200, $counter);
};

my $app = builder {
    enable 'Session';

    __PACKAGE__->psgi()
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );
$mech->get_ok('/');
is $mech->content(), '1';
$mech->get_ok('/');
is $mech->content(), '2';

done_testing;
