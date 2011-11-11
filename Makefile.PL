use inc::Module::Install;
name 'Kossy';
all_from 'lib/Kossy.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
#auto_include;
WriteAll;
