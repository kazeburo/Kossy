use strict;
use Test::More;
use lib 't';
use MyApp;
use File::Basename;
use Cwd;

my $dir = dirname(Cwd::realpath(__FILE__));

{
    my $app = MyApp->new();
    is $app->root_dir, $dir;
}

{
    my $app = MyApp->new($dir);
    is $app->root_dir, $dir;
}

{
    my $app = MyApp->new(root_dir => $dir, foo => "bar");
    is $app->root_dir, $dir;
    is $app->{foo}, "bar";
}

done_testing();



