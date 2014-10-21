#!/usr/bin/perl
###############################################################################
#
#  Created by jennifer shelton
#
#	USAGE: perl agp2_gap_bed.pl [agp]
#
#   DESCRIPTION: Script to create bed files for viewing on IrysView from an AGP or using with SV_detect. Scripts finds scaffold objects in an agp (in the same order as the fasta file and prints a bed file of the gaps in the same order as the fasta with only autoincrementing numbers as the scaffold id changes.
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
my ($basename, $directories, $suffix) = fileparse($agp,'\..*'); # break appart filenames
my $bed_file = "${directories}${basename}_gaps.bed";
open (BED,'>',"$bed_file") or die "can't open $bed_file\n";
my $current_scaffold_id ='';
my $scaffold = 0;
my $i=1;
while (<AGP>)
{
    unless (/^#/)
    {
        my @rows = split("\t");
        if ($current_scaffold_id ne "$rows[0]")
        {
            ++$scaffold;
            $current_scaffold_id = "$rows[0]";
            $i=1;
        }
        if (($rows[4] eq "N")||($rows[4] eq "U"))
        {
            print BED "$scaffold\t$rows[1]\t$rows[2]\tgap_$i\n";
            ++$i;
        }
    }
}
close (AGP);
close (BED);