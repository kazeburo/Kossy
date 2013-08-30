use inc::Module::Install;
name 'Kossy';
all_from 'lib/Kossy.pm';

requires 'parent';
requires 'Scalar::Util';
requires 'Plack';
requires 'Plack::Middleware::Static';
requires 'Plack::Middleware::ReverseProxy';
requires 'Router::Simple';
requires 'Cwd';
requires 'File::Basename';
requires 'Text::Xslate'                      => '1.6001';
requires 'Text::Xslate::Bridge::TT2Like';
requires 'HTML::FillInForm::Lite'            => '1.11';
requires 'Try::Tiny'                         => '0.09';
requires 'Class::Accessor::Lite';
requires 'JSON';
requires 'Number::Format';
requires 'Data::Section::Simple';
requires 'Test::More'                        => '0.88';
requires 'File::ShareDir';
requires 'HTTP::Message';
requires 'Hash::MultiValue';

tests 't/*.t t/*/*.t';
author_tests 'xt';

test_requires 'Test::More';

install_share 'share';
install_script 'kossy-setup';
auto_set_repository;
#auto_include;
WriteAll;
