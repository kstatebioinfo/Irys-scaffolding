#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl add_scaffold_to_header.pl [tcas.in_silico.fasta] [tcas_chromosome_from_scaffold.agp]
#
#  Created by jennifer shelton
# perl /home/irys/Data/Irys-scaffolding/KSU_bioinfo_lab/BNG_maps_to_Tribolium/add_scaffold_to_header.pl /home/irys/Data/Trib_cast_0002/tcas.in_silico.fasta /home/irys/Trib_cast_0002_gam-ngs/tcas_chromosome_from_scaffold.agp
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
        $scaffolds{"$columns[0]:$columns[1]..$columns[2]"} = $columns[4];
    }
}
open (NEWFASTA,'>',"tcas.in_silico_header.fasta") or die "can't open tcas.in_silico_header.fasta!\n";
open (FASTA,'<',"$fasta") or die "can't open $fasta!\n";
while (<FASTA>)
{
    if (/^>/)
    {
        chomp;
        />Scaffold[0]*.*\s\|\s(.*)/;
        if ($scaffolds{$1})
        {
            print NEWFASTA "$_ | $scaffolds{$1}\n";
        }
        else
        {
            print "can't find $_ in AGP\n";
        }
    }
    else
    {
        print NEWFASTA;
    }
}
	
# >Scaffold0001 | ChLGX:1..255309