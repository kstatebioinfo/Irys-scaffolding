#!/usr/bin/perl
use strict;
use warnings;

#  xmap_coverter.pl
#  
# USAGE: perl xmap_coverter.pl [r.cmap] [q.cmap] [xmap] [new_xmap] [min confidence] [min % aligned]
#
# Script to filter Xmaps by confidence and the precent of the maximum potential length of the alignment and to generate summary stats of the more stringent alignement. Script also lists remaining conflicting alignments. These may be candidates for further assembly using the conflicting contigs and paired end reads. 
# perl /Users/jennifershelton/Desktop/Perl_course_texts/scripts/Irys-scaffolding/KSU_bioinfo_lab/xmap_coverter.pl /Users/jennifershelton/Desktop/agp_chicken_1/chicken1_r.cmap /Users/jennifershelton/Desktop/agp_chicken_1/chicken1_q.cmap /Users/jennifershelton/Desktop/agp_chicken_1/chicken1.xmap new.xmap new_xmap.txt 0 0.0
#  Created by jennifer shelton on 7/10/13.
#

my $infile1=$ARGV[0];
my $infile2=$ARGV[1];
my $infile3=$ARGV[2];
my $outfile1=$ARGV[3];
my $outfile2=$ARGV[4];

open (CMAP_MOL, "<$infile1") or die "can't open $infile1 $!";
open (CMAP_CONTIGS, "<$infile2")or die "can't open $infile2 $!";
open (XMAP, "<$infile3")or die "can't open $infile3 $!";
open (NEWXMAP, ">$outfile1")or die "can't open $outfile1 $!";

############################## QC thresholds ##############################
my $min_confidence=$ARGV[5];
my $min_precent_aligned=$ARGV[6];
my $first_unknown=230;
my $last_unknown=317;
my (@xmap_table); # 2D arrays
############################## define variables ##########################################
my (%mol_length, %contig_length,%scaffolding,%cumulative,%unknowns,%knowns); #hashes
my $total_scaffolds=0;
my $total_unknown_scaffolds=0;
my $length_scaffolded_contigs=0;
my ($contig_start_pos,$contig_end_pos,$percent_aligned);
my ($main_loop, $nested_loop,$row,$footprint_start,$footprint_end,$key,$value,$overlap);
################################ Load input files ########################################
while (<CMAP_MOL>) #make array of molecule contigs and a hash of their lengths
{
    if ($_ !~ /^#/)
	{
        #print "$_ \n";
        chomp;
        my @cmap_mol=split ("\t");
        s/\s+//g foreach @cmap_mol;
        $mol_length{$cmap_mol[0]} = $cmap_mol[1]; ## hash with id as key and molecule contig length as value
	}
}

while (<CMAP_CONTIGS>) #make array of contigs from the customer and a hash of their lengths
{
    if ($_ !~ /^#/)
	{
        chomp;
        my @cmap_contigs=split ("\t");
        s/\s+//g foreach @cmap_contigs;
        $contig_length{$cmap_contigs[0]} = $cmap_contigs[1]; ## hash with id as key and sequence generated contig length as value
	}
}
while (<XMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if ($_ =~ /^#/)
	{
		print NEWXMAP;
	}
    elsif ($_ !~ /^#/)
	{
        chomp;
        my @xmap=split ("\t");
        s/\s+//g foreach @xmap;
        push (@xmap_table, [@xmap]);
	}
}
########################## filter xmap rows ##############################################
foreach $row (@xmap_table)## calculate sequence generated contig's footprint on the molecule contig and add contig footprint to the xmap array
{
    if ($row->[3] < $row->[4]) #if contig aligns in the '+' orientation
    {
        $contig_start_pos=$row->[3];
        $contig_end_pos=$row->[4];
    }
    elsif ($row->[3] >= $row->[4]) #if contig aligns in the '-' orientation
    {
        $contig_start_pos=$row->[4];
        $contig_end_pos=$row->[3];
    }
    ############################## calculate footprint ################################
        $footprint_start=$row->[5]-$contig_start_pos+1;
        ## row 1=object begining = 5 xmap
        ## row 6= comp begining = 3 or 4 xmap
        $footprint_end=$footprint_start + $contig_length{$row->[1]}-1;
        ##row 5 = contig id = 1 xmap
        $row->[10] = "$footprint_start";
        $row->[11] = "$footprint_end";
             ## 7 = end of alignment = 3 or 4 xmap
        ## 6 = begining of alignment = 3 or 4 xmap

        ############################## calculate percent aligned #######################
        if (($footprint_start<0)&&($footprint_end<=$mol_length{$row->[2]})) #if their is an overhang on one side
        {
            $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($footprint_end);
        }
        if (($footprint_start<=0)&&($footprint_end>$mol_length{$row->[2]}))#if their is an overhang on one side
        {
            $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($mol_length{$row->[2]}-$footprint_start+1);
        }
        if (($footprint_start>=0)&&($footprint_end<=$mol_length{$row->[2]})) ## if contig aligns either perfeactly or within the molecule
        {
            $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$contig_length{$row->[1]};
        }
        if (($footprint_start<0)&&($footprint_end>$mol_length{$row->[2]})) ## if contig aligns with overhang on both ends of the molecule
        {
            $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$mol_length{$row->[2]};
        }
        
        
        #################### check to see if alignemnt passes QC filters #################
        if (($percent_aligned >= $min_precent_aligned)&&($row->[8]>=$min_confidence))
        {
        	$row->[12] = "passed";
# 			print NEWXMAP "$row->[0]\t$row->[1]\t$row->[2]\t$row->[3]\t$row->[4]\t$row->[5]\t$row->[6]\t$row->[7]\t$row->[8]\t$row->[9]\n";
   			if (!$scaffolding{$row->[2]})
   			{
   				#### keep track of every unique contig that aligns to each molecule ######
   				$scaffolding{$row->[2]}{$row->[1]}=0; ## initialize the hash of uniquely aligned contigs
#    				print "contig $row->[1] aligns with $percent_aligned \n";
				
				############### check for unknowns and knowns on scaffold ################
				if (($row->[1]>=$first_unknown) && ($row->[1]<=$last_unknown))
				{
					$unknowns{$row->[2]}{$row->[1]}=1;
				}
				elsif (($row->[1]<$first_unknown) || ($row->[1]>$last_unknown))
				{
					$knowns{$row->[2]}{$row->[1]}=1;
				}
   			}
   			############# count scaffolding events per molecule ##########################
   			++$scaffolding{$row->[2]}{$row->[1]}; 
   		}
   		else
   		{
   			$row->[12] = "failed";
   		}
}
close NEWXMAP;

############################### count scaffolding events #################################
open (REPORT, ">>$outfile2")or die "can't open $outfile2 $!";
for my $mol_with_contig (keys %scaffolding)
{
	my $counted_scaffolds=(scalar( keys %{ $scaffolding{$mol_with_contig} } ));
	if  ($counted_scaffolds>1)
	{
# 		print REPORT "IrysView alignments suggest Molecule $mol_with_contig has scaffolded $counted_scaffolds contigs\n";
		++$total_scaffolds;
		for my $contig_on_scaffold ( keys %{ $scaffolding{$mol_with_contig} } )
		{
			######### sum non-redundant list of scaffolded contig lengths ################
			if (!$cumulative{$contig_on_scaffold}) 
			{
				$length_scaffolded_contigs+=$contig_length{$contig_on_scaffold};
				$cumulative{$contig_on_scaffold}=1;
			}			 
		}	
	}
	################# check for unknowns and knowns on scaffold ##########################
	my $unknown_scaffolds=(scalar( keys %{ $unknowns{$mol_with_contig} } ));
	my $known_scaffolds=(scalar( keys %{ $knowns{$mol_with_contig} } ));
	if ($unknown_scaffolds>1 && $known_scaffolds>1)
	{
		++$total_unknown_scaffolds;
	}
	
}
$length_scaffolded_contigs=($length_scaffolded_contigs/1000000);
print REPORT "IrysView alignments suggest Molecules have scaffolded $total_scaffolds contigs.\n";
print REPORT "IrysView alignments suggest Molecules the cummulative length of the scaffolded contigs is $length_scaffolded_contigs.\n";
print REPORT "Total number of scaffolded contigs,Total number of unknowns scaffolded to known contigs,Cummulative length of the scaffolded contigs (Mb),minimum percent aligned, minimum confidence\n";
print REPORT "$total_scaffolds,$total_unknown_scaffolds,$length_scaffolded_contigs,$min_precent_aligned,$min_confidence\n";
open (NEWXMAP, "<$outfile1")or die "can't open $outfile1 for second pass $!";

################################# identify overlaps in filtered outfile #################################
# print REPORT "overlapping sequence-based scaffold 1,overlapping sequence-based scaffold 2,overlap length (bp)\n";
# foreach $main_loop (@xmap_table)#for each sequence-based contig feature in the xmap
# {
# 	if ($main_loop->[12] eq "passed")
# 	{
# 		foreach $nested_loop (@xmap_table) #compare its footprint to every other contig feature's footprint 
# 		{
#         	if ($nested_loop->[12] eq "passed")
#         	{
#             if (($main_loop->[2] eq $nested_loop->[2]))#check only for footprints on the same molecule contig
#             {
#         		
#                 if ($nested_loop->[10] <= $main_loop->[10] && $main_loop->[10] <= $nested_loop->[11])#run if the sequenced-based contig in the main loop has start coordinates within any the footprints of any other sequenced-based contig
#                 {
#                     if ("$main_loop->[1]" ne "$nested_loop->[1]")#don't calculate overlaps of the same sequence-based contig
#                     {
#                         if ($nested_loop->[11] < $main_loop->[11]) #if the end main loop's footprint is before the end of the nested loop footprint use the end of the main loop's footprint
#                         {
#                             $overlap=$nested_loop->[11]-$main_loop->[10]+1;
# #                         	print REPORT "contig $main_loop->[1] overlaps with $nested_loop->[1] . The length of the overlap is $overlap=$nested_loop->[11]-$main_loop->[10] + 1\n";
#                         	print REPORT "$main_loop->[1],$nested_loop->[1],$overlap\n";
#                         }
#                         else # else use the end of the nested loop's footprint
#                         {
#                             $overlap=$main_loop->[11]-$main_loop->[10]+1;
# #                             print REPORT "Contig $main_loop->[1] overlaps with $nested_loop->[1] . The length of the overlap is $overlap=$main_loop->[11]-$main_loop->[10] + 1\n";
#                             print REPORT "$main_loop->[1],$nested_loop->[1],$overlap\n";
#                         }
#                     }
#                 }
#             }
#             }
#         }
#     }
# }
close REPORT;