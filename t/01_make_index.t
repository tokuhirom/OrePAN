use strict;
use warnings;
use utf8;
use Test::More;
use OrePAN::Package::Index;
use File::Temp;
use OrePAN::Archive;

$Log::Minimal::PRINT = sub {
    my ( $time, $type, $message, $trace) = @_;
    note "$time [$type] $message at $trace";
};

my $tmp = File::Temp->new();

# make index
{
    my $index = OrePAN::Package::Index->new(filename => $tmp->filename);
    my $archive = OrePAN::Archive->new(filename => "t/dummy-cpan/Foo-Bar-0.01.tar.gz");
    my %packages = $archive->get_packages;
    is_deeply \%packages, { 'Foo::Bar' => '0.01' };
    my $pauseid = "DUMMY";

    $index->add(
        File::Spec->catfile(
            substr( $pauseid, 0, 1 ), substr( $pauseid, 0, 2 ),
            $pauseid, "Foo-Bar-0.01.tar.gz" 
        ),
        \%packages
    );
    $index->save();
}

# and read it.
my $fh = IO::Zlib->new($tmp->filename, 'rb') or die $!;
my $got = join('', <$fh>); # Note: IO::Zlib does not handle $/
is $got, <<"...";
File:         02packages.details.txt

Foo::Bar\t0.01\tD/DU/DUMMY/Foo-Bar-0.01.tar.gz
...

done_testing;

