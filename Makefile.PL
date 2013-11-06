use inc::Module::Install;
name 'Kossy';
all_from 'lib/Kossy.pm';

tests 't/*.t t/*/*.t';
author_tests 'xt';

cpanfile;
install_share 'share';
install_script 'kossy-setup';
auto_set_repository;
#auto_include;
WriteAll;
