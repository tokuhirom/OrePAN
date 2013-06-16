use inc::Module::Install;
use Module::Install::AuthorTests;

name 'OrePAN';
all_from 'lib/OrePAN.pm';
abstract 'yet another CPAN mirror aka DarkPAN repository manager';
license 'perl';

cpanfile;

requires_external_bin('tar');
requires_external_bin('unzip');

install_script('orepan.pl');
install_script('orepan_index.pl');

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
