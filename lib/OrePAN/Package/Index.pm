package OrePAN::Package::Index;
use strict;
use warnings;
use utf8;
use Mouse;
use IO::Zlib;
use File::Temp qw(:mktemp);
use File::Sync ();
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
        my $fh = IO::Zlib->new($self->filename, 'rb');
        while (<$fh>) { # skip headers
            last unless /\S/;
        }
        while (<$fh>) {
            my ($pkg, $ver, $path) = split /\s+/, $_;
            $self->{data}->{$pkg} = [$ver, $path];
        }
        close $fh;
    }
}

sub add {
    my ($self, $path, $data) = @_;
    while (my ($pkg, $ver) = each %$data) {
        $self->{data}->{$pkg} = [$ver, $path];
    }
}

# TODO need flock?
sub save {
    my ($self, ) = @_;

    # Because we do rename(2) atomically, temporary file must be in same
    # partion with target file.
    my $tmp = mktemp($self->filename . '.XXXXXX');

    my $fh = IO::Zlib->new($tmp, 'wb') or die $!;
    print {$fh} "File:         02packages.details.txt\n\n";
    for my $key (sort keys %{$self->data}) {
        print {$fh} sprintf("%s\t%s\t%s\n", $key, $self->{data}->{$key}->[0] || 'undef', $self->{data}->{$key}->[1]);
    }
    File::Sync::fsync($fh);
    close $fh;

    rename( $tmp, $self->filename )
      or Carp::croak("Cannot rename temporary file '$tmp' to @{[ $self->filename ]}: $!");
}

no Mouse; __PACKAGE__->meta->make_immutable;
1;

