#!/usr/bin/perl

# This script prints any directory and file names appearing in project.xml
# It uses an xml parser so that we are parsing it correctly 
# (e.g., ignoring commented out sections, etc.)
#
# Command line input: path to XML file (directory and filename)
# e.g., /db/hymenopteramine_release/intermine/hymenopteramine/project.xml

use strict;
use warnings;
use XML::Twig;
use Data::Dumper;

die "Error: missing command-line input for filename to parse\n" if @ARGV < 1;

my $projectxmlfile = $ARGV[0];

#print "Parsing ${projectxmlfile}:\n\n";

my $tree = XML::Twig->new(twig_handlers => { source => \&source }, );

$tree->parsefile($projectxmlfile);

sub source {
    my ($t, $source) = @_;
    my $sourcename = $source->att('name');
    #print "Source: ", $sourcename, "\n";
    my @props = $source->children('property');
    my $loc = "";
    my $inc = "";
    foreach my $prop (@props) {
        my $name = $prop->att('name');
        if ( ($name eq "src.data.dir") || ($name eq "src.data.file")) {
            $loc = $prop->att('location');
        }
 
        if ($name eq "src.data.dir.includes") {
            $inc = $prop->att('value');
        }
    }
    print $loc, "\n" if (length $loc);
    print $loc, "/", $inc, "\n" if (length $inc);
}

__END__
