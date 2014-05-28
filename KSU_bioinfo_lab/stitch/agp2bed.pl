#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl agp2bed.pl [fasta] [agp]
#
#  Created by jennifer shelton

#   Scripts finds correct scaffold object in an agp (in the same order as the fasta file and prints a bed file in the same order as the fasta with only autoincrementing numbers as the scaffold id
# perl /home/irys/Data/Irys-scaffolding/KSU_bioinfo_lab/BNG_maps_to_Tribolium/agp2bed.pl /home/irys/Data/Trib_cast_0002/tcas.in_silico_header.fasta /home/irys/Data/Trib_cast_0002/tcas_scaffold_from_component.agp
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
my $scaffold = 0;
my $scaffold_id = "x";
open (FASTA,'<',$fasta) or die "can't open $fasta\n";
open (BED,'>',"$fasta.bed") or die "can't open output\n";
while (<FASTA>)
{
    if (/^>/)
    {
        chomp;
        s/>//;
        my $new_scaffold_id = $_;
        if ($scaffold_id ne $new_scaffold_id)
        {
            ++$scaffold ;
        }
        open (AGP,'<',$agp) or die "can't open $agp\n";
        my $found=0;
        while (<AGP>)
        {
            unless (/^#/)
            {
                my @rows = split("\t");
                if (($rows[4] eq "W")&&($new_scaffold_id eq "$rows[0]"))
                {
                    print BED "$scaffold\t$rows[1]\t$rows[2]\t$rows[5]\n";
                    $found=1;
                }
            }
        }
        if ($found==0)
        {
            print "$new_scaffold_id not found in agp\n";
        }
        close (AGP);
    }
    
}
