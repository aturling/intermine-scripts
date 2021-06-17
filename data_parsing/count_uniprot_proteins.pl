#!/usr/bin/perl

use strict;
use warnings;
use XML::Twig;

die "Error: missing command-line input for filename to parse\n" if @ARGV < 1;

my $uniprotfile = $ARGV[0];

print "Parsing ${uniprotfile}:\n\n";
