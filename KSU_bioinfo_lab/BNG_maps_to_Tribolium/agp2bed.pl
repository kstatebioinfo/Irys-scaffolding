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
my $fasta= ARGV[0];
#my $agp= ARGV[1];
open (FASTA,'<',$fasta) or die "can't open $fasta\n";
#open (AGP,'<',$agp) or die "can't open $agp\n";
while (<FASTA>)
{
    if (/^>/)
    {
        
        />(.*)[0]*(.*)\s/;
        print "$1$2\n";
    }
}
