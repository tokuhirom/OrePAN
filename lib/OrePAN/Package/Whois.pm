package OrePAN::Package::Whois;

use strict;
use warnings;
use utf8;
use Mouse;
use XML::LibXML;

has filename => (
    is       => 'ro',
    required => 1,
);

has doc => (
    is      => 'ro',
    default => sub {
        my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
        $doc->setDocumentElement($doc->createElement('cpan-whois'));
        $doc;
    },
);

sub add {
    my ($self, %data) = @_;
    my $whois = $self->doc->documentElement();
    $whois->addChild(my $cpanid = XML::LibXML::Element->new('cpanid'));
    $cpanid->addChild(XML::LibXML::Element->new('id'))->appendText($data{cpanid});
    $cpanid->addChild(XML::LibXML::Element->new('type'))->appendText('author');
    $cpanid->addChild(XML::LibXML::Element->new('has_cpandir'))->appendText('1');
}

sub save {
    my ($self, ) = @_;
    $self->doc->toFile($self->filename, 1);
}

no Mouse; __PACKAGE__->meta->make_immutable;
1;
