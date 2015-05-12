#!/usr/bin/perl
###############################################################################
#
#  Created by jennifer shelton
#
#	USAGE: perl agp2bed.pl [agp]
#
#   DESCRIPTION: Script to create bed files for viewing on IrysView from an AGP. Scripts finds scaffold objects in an agp (in the same order as the fasta file and prints a bed file in the same order as the fasta with only autoincrementing numbers as the scaffold id
#
###############################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
###############################################################################
##############                      notes                       ###############
###############################################################################

my $agp= $ARGV[0];
open (AGP,'<',$agp) or die "can't open $agp\n";
my ($basename, $directories, $suffix) = fileparse($agp,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
my $bed_file = "${directories}${basename}.bed";
open (BED,'>',"$bed_file") or die "can't open $bed_file\n";
my $current_scaffold_id ='';
my $scaffold = 0;
while (<AGP>)
{
    unless (/^#/)
    {
        my @rows = split("\t");
        if ($current_scaffold_id ne "$rows[0]")
        {
            ++$scaffold;
            $current_scaffold_id = "$rows[0]"
        }
        if ($rows[4] eq "W")
        {
            print BED "$scaffold\t$rows[1]\t$rows[2]\t$rows[5]\n";
        }
    }
}
close (AGP);
close (BED);