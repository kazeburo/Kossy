use strict;
use warnings;

use Test::More;
use Kossy;

subtest 'normal' => sub {
    my $json = Kossy->_build_json_serializer;

    isa_ok $json, 'JSON';
    ok $json->allow_blessed;
    ok $json->convert_blessed;
    ok $json->ascii;
};

subtest 'customize json_serializer' => sub {
    my $json_serializer = JSON->new;
    local $Kossy::JSON_SERIALIZER = $json_serializer;
    my $json = Kossy->_build_json_serializer;
    is $json, $json_serializer;
};

subtest 'exceptions' => sub {
    subtest 'not blessed' => sub {
        my $json_serializer = 'Hoge';
        local $Kossy::JSON_SERIALIZER = $json_serializer;
        eval { Kossy->_build_json_serializer };
        like $@, qr/\$Kossy::JSON_SERIALIZER must have/;
    };

    subtest 'blessed & no encode method' => sub {
        my $json_serializer = bless {}, 'Hoge';
        local $Kossy::JSON_SERIALIZER = $json_serializer;
        eval { Kossy->_build_json_serializer };
        like $@, qr/\$Kossy::JSON_SERIALIZER must have/;
    };
};

done_testing;
