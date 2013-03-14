use strict;
use warnings;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Request;
use Kossy::Validator;
use Test::More;

sub mkreq {
    Plack::Request->new(req_to_psgi(shift));
}

{
    my $req = mkreq( GET 'http://example.com/' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','is_null']],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    like($result->messages->[0], qr/is_null/);
    ok(!$result->valid('q'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','is_null']],
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'a');
}

{
    my $req = mkreq( GET 'http://example.com/' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','q_is_null']],
        'k' => [['NOT_NULL','k_is_null']],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    like($result->messages->[0], qr/q_is_null/);
    like($result->messages->[1], qr/k_is_null/);
    ok(!$result->valid('q'));
    ok(!$result->valid('k'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','q_is_null']],
        'k' => [['NOT_NULL','k_is_null']],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    like($result->messages->[0], qr/k_is_null/);
    ok($result->valid('q'));
    ok(!$result->valid('k'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a&k=b' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','q_is_null']],
        'k' => [['NOT_NULL','k_is_null']],
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'a');
    is($result->valid('k'),'b');
}

{
    my $req = mkreq( GET 'http://example.com/?q=c' );
    my $result = Kossy::Validator->check($req,[
        'q' => [
            ['NOT_NULL','is_null'],
            [['CHOICE',qw/a b/],'invalid_choice'],
        ],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['invalid_choice']);
    ok(!$result->valid('q'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a' );
    my $result = Kossy::Validator->check($req,[
        'q' => [
            ['NOT_NULL','is_null'],
            [['CHOICE',qw/a b/],'invalid_choice'],
        ],
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'a');
}


{
    my $req = mkreq( GET 'http://example.com/' );
    my $result = Kossy::Validator->check($req,[
        'q' => {
            default => 'a',
            rule => [
                ['NOT_NULL','q_is_null'],
                [['CHOICE',qw/a b/],'invalid_choice'],
            ],
        }
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'a');
}

{
    my $req = mkreq( GET 'http://example.com/?q=c' );
    my $result = Kossy::Validator->check($req,[
        'q' => {
            default => 'a',
            rule => [
                ['NOT_NULL','q_is_null'],
                [['CHOICE',qw/a b/],'invalid_choice'],
            ],
        }
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['invalid_choice']);
    ok(!$result->valid('q'));
}


{
    my $req = mkreq( GET 'http://example.com/' );
    my $result = Kossy::Validator->check($req,[
        'q' => {
            default => sub { 'a' },
            rule => [
                [['CHOICE',qw/a b/],'invalid_choice'],
            ],
        }
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'a');
}


{
    my $req = mkreq( GET 'http://example.com/?q=a&q=b' );
    my $result = Kossy::Validator->check($req,[
        'q' => [['NOT_NULL','is_null']],
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is($result->valid('q'),'b');
}

{
    my $req = mkreq( GET 'http://example.com/?q=a&q=b' );
    my $result = Kossy::Validator->check($req,[
        '@q' => [['NOT_NULL','is_null']],
    ]);
    ok(!$result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, []);
    is_deeply([$result->valid('q')],['a','b']);
}

{
    my $req = mkreq( GET 'http://example.com/?q=a&q=b' );
    my $result = Kossy::Validator->check($req,[
        '@q' => [
            [['@SELECTED_NUM',1,1],'selected_num']
        ],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['selected_num']);
    is_deeply([$result->valid('q')],[]);
}

{
    my $req = mkreq( GET 'http://example.com/?q=a&q=c' );
    my $result = Kossy::Validator->check($req,[
        '@q' => {
            rule => [
                ['NOT_NULL','q_is_null'],
                [['CHOICE',qw/a b/],'invalid_choice'],
            ],
        }
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['invalid_choice']);
    ok(!$result->valid('q'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a&q=a' );
    my $result = Kossy::Validator->check($req,[
        '@q' => {
            rule => [
                ['NOT_NULL','q_is_null'],
                [['CHOICE',qw/a b/],'invalid_choice'],
                [['@SELECTED_NUM',1,2],'selected_num'],
                ['@SELECTED_UNIQ','selected_uniq']
            ],
        }
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['selected_uniq']);
    ok(!$result->valid('q'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a' );
    my $result = Kossy::Validator->check($req,[
        'q' => [
            [sub{ 0 },'code']
        ],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['code']);
    ok(!$result->valid('q'));
}

{
    my $req = mkreq( GET 'http://example.com/?q=a' );
    my $result = Kossy::Validator->check($req,[
        'q' => [
            [[sub{ $_[2] },0],'code']
        ],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['code']);
    ok(!$result->valid('q'));
}

{
    my $i=0;
    my $req = mkreq( GET 'http://example.com/?q=a&q=b' );
    my $result = Kossy::Validator->check($req,[
        '@q' => [
            [[sub{ $i++; $i%2 }],'code']
        ],
    ]);
    ok($result->has_error);
    is(ref($result->messages),'ARRAY');
    is_deeply($result->messages, ['code']);
    ok(!$result->valid('q'));
    is($i,2);
}


done_testing;
