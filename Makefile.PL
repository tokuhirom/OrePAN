use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'OrePAN';
all_from 'orepan.pl';
readme_markdown_from 'orepan.pl';

requires 'Archive::Peek';
requires 'JSON';
requires 'YAML::Tiny';
requires 'List::MoreUtils';
requires 'Log::Minimal';
requires 'IO::Zlib';
requires 'Moo';

install_script 'orepan.pl';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
