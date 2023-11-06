use strict;
use warnings;

use Test::More;
use Kossy;

subtest 'with cache' => sub {
    my $tx = Kossy->_build_text_xslate(
        root_dir  => '/path/to/root',
        cache     => 1,
        cache_dir => '/path/to/cache_dir',
    );

    isa_ok $tx, 'Text::Xslate';
    is_deeply $tx->{path}, ['/path/to/root/views'];
    is $tx->input_layer, ':utf8';
    is $tx->{cache}, 1;
    is $tx->{cache_dir}, '/path/to/cache_dir';

    local $TODO = 'test fillinform';
    ok $tx->{function}->{fillinform};
};

subtest 'no cache' => sub {
    my $tx = Kossy->_build_text_xslate(
        root_dir => '/path/to/root',
        cache    => 0,
    );

    isa_ok $tx, 'Text::Xslate';
    is_deeply $tx->{path}, ['/path/to/root/views'];
    is $tx->{cache}, 0;
    like $tx->{cache_dir}, qr/\.xslate_cache/;
};

done_testing;
