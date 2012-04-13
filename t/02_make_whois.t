use strict;
use warnings;
use utf8;
use Test::More;
use OrePAN::Package::Whois;
use File::Temp;
use IO::File;

my $tmp = File::Temp->new();

# make whois
{
    my $whois = OrePAN::Package::Whois->new(filename => $tmp->filename);
    my $pauseid = "DUMMY";
    $whois->add(cpanid => $pauseid);
    $whois->save();
}

# and read it.
{
    my $fh = IO::File->new($tmp->filename, 'r') or die $!;
    my $got = do { local $/; undef $/; <$fh> };
    is $got, <<"...";
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois>
  <cpanid>
    <id>DUMMY</id>
    <type>author</type>
    <has_cpandir>1</has_cpandir>
  </cpanid>
</cpan-whois>
...
}

done_testing;
