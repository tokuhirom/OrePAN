#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib 'lib';
use 5.008001;
use OrePAN::Package::Index;
use OrePAN::Archive;

use Carp ();
use Pod::Usage qw/pod2usage/;
use Data::Dumper; sub p { print STDERR Dumper(@_) }
use Getopt::Long;
use File::Basename;
use Path::Class;
use File::Copy;
use Log::Minimal;
use LWP::UserAgent;
use File::Temp;

our $VERSION='0.02';

my $pauseid = 'DUMMY';
GetOptions(
    'p|pauseid=s' => sub { $pauseid = uc $_[1] },
    'd|destination=s' => \my $destination
);
pod2usage() unless $destination;

my ($pkg) = @ARGV;
$pkg or pod2usage();

my $tmp;
if ($pkg =~ m{^https?://}) {
    infof("retrieve from $pkg");
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($pkg);
    die "cannot get $pkg: " . $res->status_line unless $res->is_success;
    my $filename = $res->filename;
    my ($suffix) = ($filename =~ m{(\..+)$});
    $tmp = File::Temp->new(UNLINK => 1, SUFFIX => $suffix);
    print {$tmp} $res->content;
    $tmp->flush();
    $pkg = $tmp->filename;
}
my $archive = OrePAN::Archive->new(filename => $pkg);

infof("put the archive to repository");
$destination = dir($destination);
my $authordir = $destination->subdir('authors', 'id', substr($pauseid, 0, 1), substr($pauseid, 0, 2), $pauseid);
$authordir->mkpath;
copy($pkg, $authordir->file(basename($pkg)));

infof("get package names");
my %packages = $archive->get_packages;

# make index
infof('make index');
$destination->subdir('modules')->mkpath;
my $pkg_file = $destination->file('modules', '02packages.details.txt.gz');
my $index = OrePAN::Package::Index->new(filename => "$pkg_file");
$index->add(
    File::Spec->catfile(
        substr( $pauseid, 0, 1 ), substr( $pauseid, 0, 2 ),
        $pauseid, basename($pkg)
    ),
    \%packages
);
$index->save();

__END__

=encoding utf8

=head1 NAME

orepan.pl - my own Perl Archive Network.

=head1 SYNOPSIS

    % orepan.pl --destination=/path/to/repository Foo-0.01.tar.gz
        --pause=FOO
    % orepan.pl --destination=/path/to/repository https://example.com/MyModule-0.96.tar.gz

    # and so...
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION

OrePAN is yet another DarkPAN repository manager.

OrePAN is highly simple and B<limited>. OrePAN supports only L<App::cpanminus>. Because I'm using cpanm for daily jobs.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<CPAN::Mini::Inject>, L<App::cpanminus>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
