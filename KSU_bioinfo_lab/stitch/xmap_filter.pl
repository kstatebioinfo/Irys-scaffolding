#!/usr/bin/perl
##################################################################################
#   xmap_filter.pl
#	USAGE: perl xmap_filter.pl [r.cmap] [numbered fasta] [xmap] [new_xmap] [min confidence] [min % aligned] [second min confidence] [second min % aligned] [fasta key] [neg gap]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::DB::Fasta; #makes a searchable db from my fasta file
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                      notes                       ##################
##################################################################################
# xmap_filter.pl
#
# USAGE: perl xmap_filter.pl [r.cmap] [numbered fasta] [xmap] [new_xmap] [min confidence] [min % aligned] [second min confidence] [second min % aligned] [fasta key] [neg gap]
#
# Script to filter Xmaps by confidence and the precent of the maximum potential length of the alignment and generates summary stats of the more stringent alignment. An xmap with only molecules that scaffold contigs. Script also lists remaining conflicting alignments. These may be candidates for further assembly using the conflicting contigs and paired end reads.
# perl xmap_filter.pl chicken1_r.cmap chicken1_q.cmap chicken1.xmap new_basename 40 0.3 5 0.8
#  Created by jennifer shelton on 7/10/13.
#

my $infile_rcmap=$ARGV[0];
my $infile_numbered_fasta=$ARGV[1];
my $infile_xmap=$ARGV[2];
my $outfile_base=$ARGV[3];
my $neg_gap;
if ($ARGV[9])
{
	$neg_gap = $ARGV[9]; ## Grab min neg gap length (Default = 20000)
}
else
{
	$neg_gap = 20000; ## Default: Fail overlaps less than -20,000 (bp)
}
############################## create filenames ##############################
my $outfile_scf="${outfile_base}_scaffolds".".xmap"; # xmap of molecules that scaffold contigs
my $outfile_report="$outfile_base"."_report.csv"; # summary of alignments
my $outfile_overlaps="$outfile_base"."_overlaps.csv"; # overlapping alignment summary
my $outfile_all_filtered="${outfile_base}_all_filtered".".xmap"; # xmap of all passing alignments
my $outfile_stitch="${outfile_base}_scaffolds".".stitchmap"; # map used to find contigs that scaffold molecules
my $outfile_weakpoints="$outfile_base"."_weakpoints.csv"; # all alignments that pass QC but align < 60% of possible alignment
############################## report if outfile already exists ##############################
if (-e "$outfile_scf") {print "$outfile_scf file Exists!\n"; exit;}
if (-e "$outfile_all_filtered") {print "$outfile_all_filtered file Exists!\n"; exit;}
if (-e "$outfile_stitch") {print "$outfile_stitch file Exists!\n"; exit;}
if (-e "$outfile_weakpoints") {print "$outfile_weakpoints file Exists!\n"; exit;}
############################## open files ##############################
open (CMAP_MOL, "<$infile_rcmap") or die "can't open $infile_rcmap !";
open (XMAP, "<$infile_xmap")or die "can't open $infile_xmap !";
open (SCFXMAP, ">$outfile_scf")or die "can't open $outfile_scf !";
open (NEWXMAP, ">$outfile_all_filtered")or die "can't open $outfile_all_filtered !";
open (STITCHMAP, ">$outfile_stitch")or die "can't open $outfile_stitch !";
open (WEAK_POINTS, ">$outfile_weakpoints") or die "can't open $outfile_weakpoints !";
###############################################################################
############################## QC thresholds ##################################
###############################################################################
my $min_confidence=$ARGV[4];
my $min_precent_aligned=$ARGV[5];
my $second_min_confidence=$ARGV[6];
my $second_min_precent_aligned=$ARGV[7];
my $first_unknown=0; # first unknown contig in cmap
my $last_unknown=0; # last unknown contig in cmap
my (@xmap_table); # 2D arrays
###############################################################################
############################## define variables ###############################
###############################################################################
my (%mol_length, %scaffolding,%cumulative,%unknowns,%knowns,$contig_count); #hashes
my $total_scaffolds=0;
my $total_unknown_scaffolds=0;
my $length_scaffolded_contigs=0;
my $overlap_count=0;
my ($contig_start_pos,$contig_end_pos,$percent_aligned);
my ($footprint_start,$footprint_end,$key,$value,$overlap);
###############################################################################
################################ Load molecule cmap ###########################
###############################################################################
while (<CMAP_MOL>) #make array of molecule contigs and a hash of their lengths
{
    if ($_ !~ /^#/)
	{
        chomp;
        unless ($_ eq '')
        {
            my @cmap_mol=split ("\t");
            s/\s+//g foreach @cmap_mol;
            $mol_length{$cmap_mol[0]} = $cmap_mol[1]; ## hash with id as key and molecule contig length as value
        }
	}
}
###############################################################################
########## Load sequence fasta with headers converted to numbers ##############
############# this process uses a 1 base coordinate system ####################
###############################################################################
my $db = Bio::DB::Fasta->new("$infile_numbered_fasta");
my (%contig_length);
my $stream  = $db->get_PrimarySeq_stream;
while (my $seq = $stream->next_seq)
{
	my $contig_length=$db->length("$seq");
	$contig_length{$seq} = $contig_length; ## hash with id as key and sequence generated contig length as value
}
###############################################################################
################################ Load xmap ####################################
###############################################################################
while (<XMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if ($_ =~ /^#/)
	{
		print NEWXMAP;
        print SCFXMAP;
	}
    elsif ($_ !~ /^#/)
	{
        chomp;
        unless ($_ eq '')
        {
            my @xmap=split ("\t");
            s/\s+//g foreach @xmap;
            push (@xmap_table, [@xmap]);
        }

	}
}
###############################################################################
######               find original scaffold headers                  ##########
###############################################################################
my $key_file=$ARGV[8];
open (KEY,"<",$key_file) or die "couldn't open $key_file $!";
my %key_hash;
while (<KEY>)
{
    unless (/^#/)
    {
        chomp;
        unless ($_ eq '')
        {
            my @row=split ("\t");
            s/\s+//g foreach @row;
            $key_hash{$row[4]}=$row[2];
        }
    }
}
###############################################################################
####################### 1st pass over xmap             ########################
####################### filter xmap rows               ########################
###############################################################################
for my $row (@xmap_table)## calculate sequence generated contig's footprint on the molecule contig and add contig footprint to the xmap array
{
    ## object begining = 5 xmap
    ## object end = 6 xmap
    ## comp begining = 3 or 4 xmap
    ## contig id = 1 xmap
    ## end of alignment = 3 or 4 xmap
    ## begining of alignment = 3 or 4 xmap
    $row->[15]=$contig_length{$row->[1]};
#    print "$contig_length{$row->[1]} = contig_length for \'$row->[1]\'\n";
    if ($row->[3] < $row->[4]) #if contig aligns in the '+' orientation
    {
        $contig_start_pos=$row->[3];
        $contig_end_pos=$row->[4];
        ###############################################################################
        ############################## calculate footprint ############################
        ###############################################################################
        $footprint_start=$row->[5]-$contig_start_pos+1;
        $footprint_end=$footprint_start + $contig_length{$row->[1]}-1;
        $row->[10] = "$footprint_start";
        $row->[11] = "$footprint_end";
    }
    elsif ($row->[3] >= $row->[4]) #if contig aligns in the '-' orientation
    {
        $contig_start_pos=$row->[4];
        $contig_end_pos=$row->[3];
        $footprint_start=$row->[5]-($contig_length{$row->[1]}-$row->[3]);
        $footprint_end=$row->[6]+($row->[4]-1) ;
        $row->[10] = "$footprint_start";
        $row->[11] = "$footprint_end";
        #        print "contig $row->[1] to $row->[2]:\n contig_start_pos=$row->[4];\n contig_end_pos=$row->[3];\n footprint_start=$row->[5]-($contig_length{$row->[1]}-$row->[3]);\n footprint_end=-$row->[6]+($row->[4]-1) ;\n";
        
    }
    ################################################################################
    ############################## calculate percent aligned #######################
    ################################################################################
    if (($footprint_start<0)&&($footprint_end<=$mol_length{$row->[2]})) #if their is an overhang on the left side
    {
        $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($footprint_end);
        #         print "contig $row->[1] to $row->[2]left overhang: $percent_aligned\n $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($footprint_end)\n";
        ###########################################################################
        ################ Find potential stiching contigs ##########################
        ###########################################################################
        if ($row->[3] < $row->[4]) #if contig aligns in the '+' orientation
        {
            $row->[14]="n_stitch";
        }
        elsif ($row->[3] >= $row->[4]) #if contig aligns in the '-' orientation
        {
            $row->[14]="zero_stitch";
        }
    }
    if (($footprint_start>=0)&&($footprint_end>$mol_length{$row->[2]}))#if their is an overhang on the right side
    {
        $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($mol_length{$row->[2]}-$footprint_start+1);
        #         print "contig $row->[1] to $row->[2] right overhang: $percent_aligned\n $percent_aligned=($contig_end_pos-$contig_start_pos+1)/($mol_length{$row->[2]}-$footprint_start+1);\n";
        ###########################################################################
        ################ Find potential stiching contigs ##########################
        ###########################################################################
        if ($row->[3] < $row->[4]) #if contig aligns in the '+' orientation
        {
            $row->[14]="zero_stitch";
        }
        elsif ($row->[3] >= $row->[4]) #if contig aligns in the '-' orientation
        {
            $row->[14]="n_stitch";
        }
    }
    if (($footprint_start>=0)&&($footprint_end<=$mol_length{$row->[2]})) ## if contig aligns either perfectly with or within the molecule
    {
        $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$contig_length{$row->[1]};
        #         print "contig $row->[1] to $row->[2] inside: $percent_aligned\n $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$contig_length{$row->[1]};\n";
    }
    if (($footprint_start<0)&&($footprint_end>$mol_length{$row->[2]})) ## if contig aligns with overhang on both ends of the molecule
    {
        $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$mol_length{$row->[2]};
        #         print "contig $row->[1] to $row->[2] outside both sides: $percent_aligned\n $percent_aligned=($contig_end_pos-$contig_start_pos+1)/$mol_length{$row->[2]};\n";
    }
    if ($percent_aligned<0)
    {
        $percent_aligned=$percent_aligned*(-1);
    }
    ###############################################################################
    #################### check to see if alignemnt passes QC filters ##############
    ###############################################################################
    if ((($percent_aligned >= $min_precent_aligned)&&($row->[8]>=$min_confidence))||(($percent_aligned >= $second_min_precent_aligned)&&($row->[8]>=$second_min_confidence)))
        
    {
        $row->[12] = "passed";
        print NEWXMAP "$row->[0]\t$row->[1]\t$row->[2]\t$row->[3]\t$row->[4]\t$row->[5]\t$row->[6]\t$row->[7]\t$row->[8]\t$row->[9]\n";
        if (!$scaffolding{$row->[2]})
        {
            #### initialize new molecule to begin counting total number of alignments ######
            $scaffolding{$row->[2]}->{$row->[1]}=0; ## initialize the hash of uniquely aligned contigs
            
            
        }
        ###############################################################################
        ################# check for unknowns and knowns on scaffold ###################
        ###############################################################################
        if (($row->[1]>=$first_unknown) && ($row->[1]<=$last_unknown))
        {
        	$unknowns{$row->[2]}->{$row->[1]}=1;
        }
        elsif (($row->[1]<$first_unknown) || ($row->[1]>$last_unknown))
        {
        	$knowns{$row->[2]}->{$row->[1]}=1;
        }
        ###############################################################################
        ############# count scaffolding events per molecule ###########################
        ###############################################################################
        ++$scaffolding{$row->[2]}->{$row->[1]};
        
        ###### report if less than %60 percent of possible alignment was made ########
        if ($percent_aligned > .6)
        {
            $row->[13] = "strong"; # aligns over > 60%
        }
        if ($percent_aligned <= .6)
        {
            $row->[13] = "weak"; # aligns over =< 60%
        }
    }
    else
    {
        $row->[12] = "failed"; # failed QC therefore we don't care if the alignment is strong or weak
        $row->[13] = "NA";
    }
}
if (-e "$outfile_overlaps") {print "$outfile_overlaps file Exists!\n"; exit;}
open (OVERLAPS, ">$outfile_overlaps")or die "can't open $outfile_overlaps !";

######################################################################################
####################### 3rd pass over xmap                    ########################
####################### identify overlaps in filtered outfile ########################
####################### find best and second best alignment   ########################
######################################################################################

print OVERLAPS "Original fasta header sequence-based scaffold 1,overlapping sequence-based scaffold 1,Original fasta header sequence-based scaffold 2,overlapping sequence-based scaffold 2,overlap length (bp)\n";
for my $main_loop (@xmap_table) # for each sequence-based contig feature in the xmap
{
    if ($main_loop->[12] eq "passed")
    {
        for my $nested_loop (@xmap_table) # compare its footprint to every other contig feature's footprint
        {
            if ($nested_loop->[12] eq "passed")
            {
                if (($main_loop->[2] eq $nested_loop->[2]))# check only for footprints on the same molecule contig
                {
                    
                    if ($nested_loop->[10] <= $main_loop->[10] && $main_loop->[10] <= $nested_loop->[11]) # run if the sequenced-based contig in the main loop has start coordinates within any the footprints of any other sequenced-based contig
                    {
                        if ("$main_loop->[1]" ne "$nested_loop->[1]")# don't calculate overlaps of the same sequence-based contig
                        {
                            if ($nested_loop->[11] < $main_loop->[11]) # if the end main loop's footprint is before the end of the nested loop footprint use the end of the main loop's footprint
                            {
                                $overlap=$nested_loop->[11]-$main_loop->[10]+1;
                                print OVERLAPS "$key_hash{$main_loop->[1]},$main_loop->[1],$key_hash{$nested_loop->[1]},$nested_loop->[1],$overlap";
                                ++$overlap_count;
                            }
                            else # else use the end of the nested loop's footprint
                            {
                                $overlap=$main_loop->[11]-$main_loop->[10]+1;
                                print OVERLAPS "$key_hash{$main_loop->[1]},$main_loop->[1],$key_hash{$nested_loop->[1]},$nested_loop->[1],$overlap";
                                ++$overlap_count;
                            }
                            if ($overlap > $neg_gap) # Fail overlaps less than -20,000 (bp)
                            {
                                $nested_loop->[12] = "failed";
                                $main_loop->[12] = "failed";
                                print OVERLAPS ",FAILED\n";
                            }
                            else
                            {
                                print OVERLAPS ",PASSED\n";
                            }
                        }
                        
                    }
                }
            }
        }
    }
}
#print REPORT "$overlap_count\n";

############################################################################################
############# Second pass over xmap                                         ################
############# print only scaffolding molecule maps                          ################
############# and potential misassemblies alignments  (<60%)                ################
############################################################################################
print STITCHMAP "#0 XmapEntryID\t1 QryContigID\t2 RefcontigID\t3 QryStartPos\t4 QryEndPos\t5 RefStartPos\t6 RefEndPos\t7 Orientation\t8 Confidence\t9 HitEnum\t10 footprint_start\t11 footprint_end\t12 QC filters (passed/failed)\t13 60% alignment (strong/weak)\t14 stitch (zero_stitch/n_stitch/na)\t15 contig length\t16 alignment rank (best/second/'')\n"; # print tab separated headers for stitchmap
print WEAK_POINTS "#Original fasta header,QryContigID,RefcontigID,QryStartPos,QryEndPos,RefStartPos,RefEndPos\n"; # print comma separated headers for list of weak alignments

for my $row (@xmap_table)
{
    my $counted_scaffolds=(scalar( keys %{ $scaffolding{$row->[2]} } ));
    #    print "scaffold: Row $row->[2] = $counted_scaffolds\n";
    if (($row->[12] eq "passed") && ($counted_scaffolds>1))
        
    {
        print SCFXMAP "$row->[0]\t$row->[1]\t$row->[2]\t$row->[3]\t$row->[4]\t$row->[5]\t$row->[6]\t$row->[7]\t$row->[8]\t$row->[9]\n"; # print to the scaffolding xmap
        print STITCHMAP "$row->[0]\t$row->[1]\t$row->[2]\t$row->[3]\t$row->[4]\t$row->[5]\t$row->[6]\t$row->[7]\t$row->[8]\t$row->[9]\t$row->[10]\t$row->[11]\t$row->[12]\t$row->[13]\t"; # print to the stitchmap
        if ($row->[14])
        {
            print STITCHMAP "$row->[14]\t$row->[15]\n";
        }
        elsif (!$row->[14])
        {
            print STITCHMAP "na\t$row->[15]\n";
        }
        if ($row->[13] eq "weak")
        {
            print WEAK_POINTS "$key_hash{$row->[1]},$row->[1],$row->[2],$row->[3],$row->[4],$row->[5],$row->[6]\n";
        }
    }
}
close SCFXMAP;
close NEWXMAP;


##########################################################################################
############################### tally scaffolding events #################################
##########################################################################################
open (REPORT, ">>$outfile_report")or die "can't open $outfile_report !";
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
                ++$contig_count;
			}
		}
	}
    ###############################################################################
    ################ check for unknowns and knowns on scaffold ####################
    ###############################################################################
    my $unknown_scaffolds=(scalar( keys %{ $unknowns{$mol_with_contig} } ));
    my $known_scaffolds=(scalar( keys %{ $knowns{$mol_with_contig} } ));
    if ($unknown_scaffolds>=1 && $known_scaffolds>=1)
    {
        ++$total_unknown_scaffolds;
    }
	
}
$length_scaffolded_contigs=($length_scaffolded_contigs/1000000);
print REPORT "Total number of scaffolds used in super-scaffolds,Total number of super-scaffolds created,Total number of unknowns super-scaffolded to known scaffolds,Cummulative length of the super-scaffolded scaffolds (Mb),minimum percent aligned, minimum confidence,second min percent aligned,second min confidence, Number of overlaps\n";
if (!$contig_count)
{
    print "No_scaffolds";
    die "Exiting because stitch iteration did not produce scaffolds: ";
}
print REPORT "$contig_count,$total_scaffolds,$total_unknown_scaffolds,$length_scaffolded_contigs,$min_precent_aligned,$min_confidence,$second_min_precent_aligned,$second_min_confidence,";

#open (NEWXMAP, "<${outfile_base}_all_filtered".".xmap")or die "can't open ${outfile_base}_all_filtered.xmap !";
close REPORT;
close OVERLAPS;
