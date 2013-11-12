use strict;
use Test::More;

use_ok $_ for qw(
    Kossy
    Kossy::Connection
    Kossy::Exception
    Kossy::Request
    Kossy::Response
    Kossy::BodyParser
    Kossy::BodyParser::JSON
    Kossy::BodyParser::MultiPart
    Kossy::BodyParser::OctetStream
    Kossy::BodyParser::UrlEncoded
);

done_testing;


