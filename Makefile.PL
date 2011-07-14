use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::ReadmeMarkdownFromPod;

name 'OrePAN';
all_from 'orepan.pl';
readme_markdown_from 'orepan.pl';

# OrePAN should not depend to any XS modules, since this is a utility for operating CPAN modules.
# It should works with FatPacker.
requires 'JSON' => 2.27;
requires 'YAML::Tiny';
requires 'List::MoreUtils';
requires 'Log::Minimal' => 0.02;
requires 'IO::Zlib';
requires 'Mouse';
requires 'Path::Class';
requires 'LWP::UserAgent';
requires 'File::Which';
requires 'Cwd';
requires 'File::Basename';
requires 'File::Find';
requires 'CPAN::DistnameInfo';
requires 'File::Sync';
requires 'File::Temp';

requires_external_bin('tar');
requires_external_bin('unzip');

install_script('orepan.pl');
install_script('orepan_index.pl');

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
