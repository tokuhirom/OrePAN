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
    'h|help' => \my $help,
);
pod2usage(-verbose=>1) if $help;
$repository or pod2usage(-verbose=>1);

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

orepan_index.pl - yet another CPAN mirror aka DarkPAN index builder

=head1 SYNOPSIS

    # make directory
    % mkdir -p /path/to/repository/{modules,authors}
    # copy CPAN mouldes to the directory
    % cp MyModule-0.03.tar.gz /path/to/repository/authors/id/A/AB/ABC/

    # make index file
    % orepan_index.pl --repository=/path/to/repository

    # remove module and recreate index
    % rm /path/to/repository/authors/id/A/AB/ABC/MyModule-0.04.tar.gz
    % orepan_index.pl --repository=/path/to/repository

    # and use it
    % cpanm --mirror-only --mirror=file:///path/to/repository Foo

=head1 DESCRIPTION

OrePAN is yet another CPAN mirror aka DarkPAN repository manager.

orepan_index.pl is CPAN mirror aka DarkPAN index builder. 
orepan_index.pl parses all tarballs in specified repository directory, and makes 02packages.txt.gz file.

You can use the directory aka DarkPAN with `cpanm --mirror`.

If you want to add other mouldes to repository in one command, you can use L<orepan.pl>

=head1 OPTIONS

=over 4

=item B<--repository>

Set a directory that use as DarkPAN repository

=back

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
