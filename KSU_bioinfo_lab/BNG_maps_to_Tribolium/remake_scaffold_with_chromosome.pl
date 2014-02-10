#!/usr/bin/perl
use strict;
use warnings;
# USAGE: perl remake_scaffold_with_chromosome.pl
# Script to convert the Tcas 4.0 scaffold key from bionanos into a key with Chromosome a Known/Unknown status
# column 5 (with the first column being 0) is the contig id when column 4 is "W"
############### scaffold 20-2058 are unknowns ################
open (AGP_CHR, "<","tcas_chromosome_from_component.agp")or die "can't open tcas_chromosome_from_component.agp $!";
open (AGP_SCF, "<","tcas_scaffold_from_component.agp")or die "can't open tcas_scaffold_from_component.agp $!";


open (NEW_SCAFFOLD, ">","Tcas_4_cmap_key.agp")or die "can't open Tcas_4_cmap_key.agp $!";


my (%agp_contig_hash,%known_hash,%unknown_hash,@unknowns,@knowns,%key_hash,$knowledge,%agp_scaffold_hash);
while (<AGP_CHR>)
{
	unless (/^#/)
	{
		chomp;
		my @columns=split ("\t");
		if ($columns[4] eq "W")
		{
			if (/Unknown/)
			{
				$knowledge="U";
			}
			else
			{
				$knowledge="K";
			}
			push (@columns, $knowledge);
			$agp_contig_hash{$columns[5]}=[@columns];
		}	
	}
}

while (<AGP_SCF>)
{
	unless (/^#/)
	{
		chomp;
		my @columns=split ("\t");
		if (($columns[4] eq "W") && (!$agp_scaffold_hash{$columns[0]}))
		{
			my @agp_contig_array = ("$agp_contig_hash{$columns[5]}->[0]", "$agp_contig_hash{$columns[5]}->[9]");
			$agp_scaffold_hash{$columns[0]}=[ @agp_contig_array ];	
		}
	}
}


open (SCAFFOLD, "<","/Users/jennifershelton/Desktop/Trib_cast_0002_Tcas_4.0\ to_bionano_6-13/alignref_all_mrg4c/Tribolium4_merged_bbvcbspq.scaffold")or die "can't open Tribolium4_merged_bbvcbspq.scaffold $!";
print NEW_SCAFFOLD "Chromosome\tKnown(K) or Unknown (U)\tfastaHead\tfastaID\tcontigID\tscaffoldID\tfastaStart\tfastaStop\n";
while (<SCAFFOLD>)
{
	if (/^#/) {print NEW_SCAFFOLD;}
	elsif (!/^#/)
	{
		chomp;
		s/^\s+//;
		s/\s+/ /g;
		my @columns=split (' ');
		if ($agp_scaffold_hash{$columns[0]}->[1] eq "U")
		{
			push (@unknowns,"$columns[2]");
		}
		elsif ($agp_scaffold_hash{$columns[0]}->[1] eq "K")
		{
			push (@knowns,"$columns[2]");
		}
		
		print NEW_SCAFFOLD "$agp_scaffold_hash{$columns[0]}->[0]\t$agp_scaffold_hash{$columns[0]}->[1]\t";
		print NEW_SCAFFOLD join("\t",@columns);
		print NEW_SCAFFOLD "\n";
	}
}
print join(' ',@unknowns);
print "\n";
