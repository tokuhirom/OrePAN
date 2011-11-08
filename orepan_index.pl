#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use 5.008001;
use OrePAN::Package::Index;
use OrePAN::Archive;
use OrePAN::Package::Whois;

use Carp ();
use Pod::Usage qw/pod2usage/;
use Data::Dumper; sub p { print STDERR Dumper(@_) }
use Getopt::Long;
use File::Basename;
use Path::Class;
use Log::Minimal;
use File::Find;

our $VERSION='0.01';

GetOptions(
    'r|repository=s' => \my $repository, 
);
$repository or pod2usage();

$repository = dir($repository);
my $authordir = $repository->subdir('authors');

$repository->subdir('modules')->mkpath;
my $pkg_file = $repository->file('modules', '02packages.details.txt.gz');
my $index = OrePAN::Package::Index->new(filename => "$pkg_file");

my $whois_file = $repository->file('authors', '00whois.xml');
my $whois = OrePAN::Package::Whois->new(filename => "$whois_file");

sub build_index {
    my $file = $_;
    return if ! -f $file;
    return if $file !~ m!(?:\.zip|\.tar|\.tar\.gz|\.tgz)$!i;

    (my $parsed = $file) =~ s/^\Q$authordir\E\/id\///;
    
    my $pauseid = [split /\//, $parsed]->[2];

    my $archive = OrePAN::Archive->new(filename => $file);
    infof("get package names of %s", $file);
    my %packages = $archive->get_packages;

    # make index
    infof('make index');
    $index->add(
        $parsed,
        \%packages
    );

    $whois->add(cpanid => $pauseid);
}

find({ wanted => \&build_index, no_chdir => 1 }, $authordir );
$index->save();
$whois->save();

__END__

=encoding utf8

=head1 NAME

orepan_index.pl - index builder

=head1 SYNOPSIS

    % orepan_index.pl --repository=/path/to/repository

    # and so...
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION


=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

Masahiro Nagano E<lt>kazeburo AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<CPAN::Mini::Inject>, L<App::cpanminus>, L<OrePAN>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
