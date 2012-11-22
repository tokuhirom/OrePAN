use strict;
use warnings;
use utf8;
use Test::More;
use OrePAN::Archive;
use Path::Class;
use Log::Minimal;

{
    no warnings 'redefine';
    *OrePAN::Archive::warnf = sub {
        fail $_[0];
    };
}

my ($pkg, $version) = OrePAN::Archive::_parse_version(file('t/dat/Base.pm'));
is($pkg, 'Test::Base');
is($version, '0.60');

done_testing;

