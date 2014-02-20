#!/bin/perl
###############################################################################
#
#	USAGE: perl agp2bed.pl [fasta] [agp]
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
###############################################################################
##############                      notes                       ###############
###############################################################################
my $fasta= $ARGV[0];
my $agp= $ARGV[1];
my $scaffold = 1;
my $bng_id;
open (FASTA,'<',$fasta) or die "can't open $fasta\n";
open (BED,'>',"$fasta.bed") or die "can't open output\n";
while (<FASTA>)
{
    if (/^>/)
    {
        chomp;
        />Scaffold[0]*.*\s\|\sScaffold(.*)/;
        if (($bng_id )&&($bng_id != $1))
        {
            ++$scaffold ;
        }
        $bng_id = "$1";
        open (AGP,'<',$agp) or die "can't open $agp\n";
        while (<AGP>)
        {
            unless (/^#/)
            {
                my @rows = split("\t");
                if (($rows[4] eq "W")&&("Scaffold${bng_id}" eq "$rows[0]"))
                {
                    print BED "$scaffold\t$rows[1]\t$rows[2]\t$rows[5]\n";
                }
            }
        }
        close (AGP);
    }
    
}
