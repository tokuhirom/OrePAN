use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'OrePAN';
reference_module 'lib/OrePAN.pm'; # all_from, readme_from, readme_markdown_from

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
# test_requires 'Test::Requires';
author_tests('xt');
# test_requires 'YAML'; # required for use_test_base.
# use_test_base;
WriteAll;
