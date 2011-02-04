package OrePAN::Archive;

use strict;
use warnings;
use utf8;
use Mouse;
use Mouse::Util::TypeConstraints;
use YAML::Tiny ();
use JSON ();
use List::MoreUtils qw/any/;
use Log::Minimal;
use File::Basename;
use File::Temp;
use Path::Class;
use File::Which qw(which);  
use Cwd qw/realpath getcwd/;

subtype 'File' => as class_type('Path::Class::File');
coerce 'File' => from 'Str' => via { Path::Class::file(realpath($_)) };

subtype 'Dir' => as class_type('Path::Class::Dir');
coerce 'Dir' => from 'Str' => via { Path::Class::dir(realpath($_)) };

has filename => (
    is       => 'ro',
    isa      => 'File',
    coerce   => 1,
    required => 1,
);

has archive => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        debugf('extering');
        $self->filename =~ m!\.zip$!i ?
            $self->unzip($self->filename)
          : $self->untar($self->filename);
    },
);

has tmpdir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Path::Class::dir(File::Temp::tempdir(CLEANUP => 0))
    },
);

has files => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @files;
        $self->archive->recurse(callback => sub {
            my $path = shift;
            return if $path->is_dir;
            push @files, $path;
        });
        return \@files;
    },
);

has meta => (
    is      => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my @files = @{$self->files};
        infof("retrieve meta data");
        if ( my ($json) = grep /META.json$/, @files ) {
             JSON::decode_json($json->slurp);
        }
        elsif ( my ($yml) = grep /META\.yml/, @files ) {
            eval{
                # json format yaml
                my $data = $yml->slurp;
                YAML::Tiny::Load($data) || JSON::decode_json($data);
            };
        }
        else {
            warnf("Archive does not contains META file");
            return +{};
        }
    },
);

has name => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->meta->{name};
    },
);

# Copy from ExtUtils::MM_Unix
sub _parse_version($) {
    my $parsefile = shift;
    my $inpod = 0;
    my $pkg;
    my $version;

    local $/ = "\n";
    my $fh = $parsefile->openr;

    while (<$fh>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        chop;
        next if /^\s*(if|unless)/;
        if ( m{^ \s* package \s+ (\w[\w\:\']*) (?: \s+ (v?[0-9._]+) \s*)? ;  }x ) {
            $pkg = $1;
            $version = $2;
        }
        elsif ( m{(?<!\\) ([\$*]) (([\w\:\']*) \bVERSION)\b .* =}x ) {
            my $eval = qq{
                package ExtUtils::MakeMaker::_version;
                no strict;
                BEGIN { eval {
                    # Ensure any version() routine which might have leaked
                    # into this package has been deleted.  Interferes with
                    # version->import()
                    undef *version;
                    require version;
                    "version"->import;
                } }

                local $1$2;
                \$$2=undef;
                do {
                    $_
                };
                \$$2;
            };
            local $^W = 0;
            $version = eval($eval);  ## no critic
            warn "Could not eval '$eval' in $parsefile: $@" if $@;
        }
        elsif (/^\s*__END__/) {
            last;
        }
        last if $pkg && $version;
    }
    return ($pkg, $version);
}

sub get_packages {
    my ($self) = @_;
    my $meta = $self->meta || +{};
    my $ignore_dirs = $meta->{no_index} && $meta->{no_index}->{directory} ? $meta->{no_index}->{directory} : [];
    my @ignore_dirs = ref $ignore_dirs ? @$ignore_dirs : [$ignore_dirs];
    push @ignore_dirs, "t","xt", 'contrib', 'examples','inc','share','private', 'blib';
    infof("files");
    my $archive = $self->archive;
    my @files = @{$self->files()};
    infof("ok files");
    my %res;
    for my $file (@files) {
        my $quote = quotemeta($archive);
        next if any { $file =~ m{^$quote/$_/} } @ignore_dirs;
        next if $file !~ /\.pm(?:\.PL)?$/;
        infof("parsing: $file");
        my ( $pkg, $ver) = _parse_version($file);
        infof("parsed: %s version: %s", $pkg || 'unknown', $ver || 'none');
        if ($pkg) {
            $res{$pkg} = defined $ver ? "$ver" : "";
        }
    }
    return wantarray ? %res : \%res;
}

sub untar {
    my $self = shift;
    my $tarfile = shift;
    if ( my $tar = which('tar') ) {
        my $tempdir = $self->tmpdir;
        my $guard = OrePAN::Archive::Chdir->new($tempdir);
        
        my $xf = "xf";
        my $ar = $tarfile =~ /bz2$/ ? 'j' : 'z';
        my($root, @others) = `$tar tf$ar $tarfile`
            or return die "Bad archive $tarfile";
        chomp $root;
        $root =~ s{^(.+?)/.*$}{$1};
        debugf("cwd: %s, tar: $tar $xf$ar $tarfile", getcwd);
        system "$tar $xf$ar $tarfile";
        return $tempdir->subdir($root) if -d $root;
        die "Bad archive: $tarfile";
    }
    else {
        die "can't find tar";
    }
}

sub unzip {
    my $self = shift;
    my $zipfile = shift;
    if ( my $unzip = which('unzip') ) {
        my $tempdir = $self->tmpdir;
        my $guard = OrePAN::Archive::Chdir->new($tempdir);

        my(undef, $root, @others) = `$unzip -t $zipfile`
            or return undef;
        chomp $root;
        $root =~ s{^\s+testing:\s+(.+?)/\s+OK$}{$1};
        system "$unzip $zipfile";
        return $tempdir->subdir($root) if -d $root;        
    }
    else {
        die "can't find unzip";
    }
}

sub DEMOLISH {
    my $self = shift;
    $self->tmpdir->rmtree();
}

no Mouse;
# FIXME This class has a 'meta' attribute. Cannot access to Mouse meta class.
# __PACKAGE__->meta->make_immutable;

package 
    OrePAN::Archive::Chdir;

use Cwd qw/getcwd/;

sub new {
    my $class = shift;
    my $dir = shift;
    my $cwd = getcwd();
    my $guard = sub { chdir($cwd) };
    chdir($dir);
    bless \$guard, $class;
}

sub DESTROY {
    ${$_[0]}->();
}

1;

