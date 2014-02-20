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
open (FASTA,'<',$fasta) or die "can't open $fasta\n";
open (AGP,'<',$agp) or die "can't open $agp\n";
$fasta ~= /(.*)\.agp/$1\.bed/;
open (BED,'>',"$fasta") or die "can't open $fasta\n";
while (<FASTA>)
{
    if (/^>/)
    {
        />Scaffold[0]*(.*)\s\|/;
        while (<AGP>)
        {
            unless (/^#/)
            {
                my @rows = split(\t);
                if (($rows[4] eq "W")&&("Scaffold$1" eq "$rows[0]"))
                {
                    print BED "$count\t$rows[1]\t$rows[2]\t$rows[5]\n";
                }
            }
        }
        ++$count;
    }
    
}
