package OrePAN::Package::Index;

use strict;
use warnings;
use utf8;
use Mouse;
use IO::Zlib;
use CPAN::DistnameInfo;
use version;
use Log::Minimal;
use File::Temp qw(:mktemp);
use Carp ();

has filename => (
    is       => 'ro',
    required => 1,
);

has data => (
    is      => 'ro',
    default => sub { +{} },
);

sub BUILD {
    my ($self, ) = @_;
    if (-f $self->filename) {
        infof( "Loading %s", $self->filename);
        my $fh = IO::Zlib->new($self->filename, 'rb');
        while (<$fh>) { # skip headers
            last unless /\S/;
        }
        while (<$fh>) {
            my ($pkg, $ver, $path) = split /\s+/, $_;
            my $dist = CPAN::DistnameInfo->new($path);
            $self->{data}->{$dist->dist} ||= {
                path    => $path,
                version => $dist->version,
                modules => {},
            };
            $self->{data}->{$dist->dist}->{modules}->{$pkg} = $ver;
        }
        close $fh;
    }
}

sub add {
    my ($self, $path, $data) = @_;
    my $dist = CPAN::DistnameInfo->new($path);
    if ( $self->{data}->{$dist->dist} ) {
        my $p_version;
        my $n_version;
        eval {
            $p_version = version->parse($self->{data}->{$dist->dist}->{version});
            $n_version = version->parse($dist->version);
        };
        if ( !$@ && $n_version <= $p_version ) {
            infof( "SKIP: already has newer version %s-%s: adding %s", $dist->dist, $self->{data}->{$dist->dist}->{version}, 
                   $dist->version);
            return;
        }
    }

    infof( "Adding %s-%s", $dist->dist, $dist->version);
    $self->{data}->{$dist->dist} = {
        path    => $path,
        version => $dist->version,
        modules => $data,
    };

    for my $distname ( keys %{$self->data} ) {
        next if $dist->dist eq $distname;
        for my $pkg ( keys %$data ) {
            die "'$pkg' is exists on $distname" if exists $self->data->{$distname}->{modules}->{$pkg}
        }
    }
}

# TODO need flock?
sub save {
    my ($self, ) = @_;

    my %modules;
    for my $distname ( keys %{$self->data} ) {
        my $dist = $self->data->{$distname};
        for my $module ( keys %{$dist->{modules}} ) {
            die "'$module' is exists on $distname" if exists $modules{$module};
            $modules{$module} = [ $dist->{modules}->{$module}, $dist->{path} ];
        } 
    }

    infof( "Save %s", $self->filename);
    # Because we do rename(2) atomically, temporary file must be in same
    # partion with target file.
    my $tmp = mktemp($self->filename . '.XXXXXX');

    my $fh = IO::Zlib->new($tmp,'wb') or die $!;
    $fh->print("File:         02packages.details.txt\n\n");
    for my $key ( sort keys %modules ) {
        $fh->print(sprintf("%s\t%s\t%s\n", $key, $modules{$key}->[0] || 'undef', $modules{$key}->[1]));
    }
    $fh->close();

    rename( $tmp, $self->filename )
      or Carp::croak("Cannot rename temporary file '$tmp' to @{[ $self->filename ]}: $!");
}

no Mouse; __PACKAGE__->meta->make_immutable;
1;

