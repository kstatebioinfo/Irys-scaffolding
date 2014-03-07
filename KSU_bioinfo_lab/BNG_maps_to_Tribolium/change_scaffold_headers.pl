#!/bin/perl
###############################################################################
#   
#	USAGE: perl change_scaffold_headers.pl
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
###############################################################################
##############                      notes                    ##################
###############################################################################

my %bad_headers = ('>PairedContig_606'=>'>Scaffold0009|ChLGX:1024246..1484848|Scaffold128','>PairedContig_307'=>'>Scaffold0314|Unknown132:1..12967|Scaffold297','>PairedContig_71'=>'>Scaffold2222|1..2137|Scaffold2229','>PairedContig_325'=>'>Scaffold2223|1..14723|Scaffold2230');
#>Scaffold0001|ChLGX:1..255309|Scaffold144
open (FASTA, '<', "tcas.scaffolds_gam_plus.fasta") or die "can't open tcas.scaffolds_gam_plus.fasta\n";
open (NEW_FASTA,'>',"tcas.scaffolds_gam_plus_header.fasta") or die "can't open tcas.scaffolds_gam_plus_header.fasta\n";
while (<FASTA>)
{
    chomp;
    if ($bad_headers{$_})
    {
        print NEW_FASTA "$bad_headers{$_}\n";
    }
    else
    {
        print NEW_FASTA "$_\n";;
    }
}


