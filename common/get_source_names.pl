#!/usr/bin/perl

# This script prints the source names from project.xml
# It uses an xml parser so that we are parsing it correctly 
# (e.g., ignoring commented out sections, etc.)
#
# Command line input: path to XML file (directory and filename)
# e.g., /db/hymenopteramine_release/intermine/hymenopteramine/project.xml

use strict;
use warnings;
use XML::Twig;

die "Error: missing command-line input for filename to parse\n" if @ARGV < 1;

my $projectxmlfile = $ARGV[0];

#print "Parsing ${projectxmlfile}:\n\n";

my $tree = XML::Twig->new(twig_handlers => { source => \&source }, );

$tree->parsefile($projectxmlfile);

sub source {
    my ($t, $source) = @_;
    print $source->att('name'), "\n";
}

__END__
