package OrePAN::Archive;
use strict;
use warnings;
use utf8;
use Moo;
use Archive::Peek ();
use YAML::Tiny ();
use JSON ();
use List::MoreUtils qw/any/;
use Log::Minimal;

has filename => (
    is       => 'ro',
    required => 1,
);

has _archive => (
    is => 'ro',
    isa => 'Archive::Peek',
    lazy => 1,
    default => sub {
        my $self = shift;
        debugf('extering');
        Archive::Peek->new(filename => $self->filename);
    },
);

has meta => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;

        infof("retrieve meta data");
        my $archive = $self->_archive;
        infof("arcive meta data");
        my @files = $archive->files();
        infof("ready to find meta");
        if ( my ($yml) = grep /META\.yml/, @files ) {
            YAML::Tiny::Load($archive->file($yml));
        }
        elsif ( my ($json) = grep /META.json$/, @files ) {
            JSON::decode_json($archive->file($json));
        }
        else {
            Carp::croak("Archive does not contains META file");
        }
    },
);

has name => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->meta->{name};
    },
);

sub _parse_version {
    my $content = shift;
    my $inpod = 0;
    my $pkg;
    my $version;
    for (split /\n/, $content) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        next if /^\s*(if|unless)/;
        if ( m{^ \s* package \s+ (\w[\w\:\']*) (?: \s+ (v?[0-9._]+) \s*)? ;  }x ) {
            $pkg = $1;
            $version = $2 if defined $2;
        } elsif (m{\$VERSION\s*=\s*["']([0-9_.]+)['"]}) {
            $version = $1;
        } elsif (/^\s*__END__/) {
            last;
        }
        last if $pkg && $version;
    }
    return ($pkg, $version);
}

sub get_packages {
    my ($self) = @_;
    my $meta = $self->meta || +{};
    my @ignore_dirs = @{ $meta->{no_index}->{directory} || [] };
    infof("files");
    my @files = $self->_archive->files();
    infof("ok files");
    my %res;
    for my $file (@files) {
        next if any { $file =~ m{$_/} } @ignore_dirs;
        next if $file !~ /\.pm$/;
        infof("parsing: $file");
        my ($pkg, $ver) = _parse_version($self->_archive->file($file));
        if ($pkg) {
            $res{$pkg} = $ver;
        }
    }
    return wantarray ? %res : \%res;
}

1;

