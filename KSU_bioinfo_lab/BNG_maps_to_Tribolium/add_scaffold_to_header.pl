#!/bin/perl
##################################################################################
#   
#	USAGE: perl add_scaffold_to_header.pl [tcas.in_silico.fasta] [tcas_chromosome_from_scaffold.agp]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                      notes                       ##################
##################################################################################
my $fasta =$ARGV[0];
my $agp = $ARGV[1];
my %scaffolds;
open (AGP,'<',"$agp") or die "can't open $agp!\n";
while (<AGP>)
{
	unless (/^#/)
    {
        chomp;
        my @columns = split;
        $scaffolds{"$column[0]:$column[1]..$column[2]"} = $column[4];
    }
}
while (<FASTA>)
{
    if (/^>/)
    {
        chomp;
        />Scaffold[0]*.*\s\|\s(.*)/;
        if ($scaffolds{$1})
        {
            print "$_ | $scaffolds{$1}\n";
        }
    }
}
	
# >Scaffold0001 | ChLGX:1..255309