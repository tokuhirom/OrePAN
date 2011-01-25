use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'OrePAN';
all_from 'orepan.pl';
readme_markdown_from 'orepan.pl';

requires 'JSON' => 2.27;
requires 'YAML::Tiny';
requires 'List::MoreUtils';
requires 'Log::Minimal' => 0.02;
requires 'IO::Zlib';
requires 'Mouse';
requires 'Path::Class';
requires 'LWP::UserAgent';
requires 'Module::Metadata';
requires 'File::Which';
requires 'Cwd';
requires 'File::Basename';
requires 'File::Find';

install_script 'orepan.pl';
install_script 'orepan_index.pl';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
