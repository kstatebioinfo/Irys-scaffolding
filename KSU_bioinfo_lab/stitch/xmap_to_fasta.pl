#!/bin/perl

#  perl stitchmap_to_fasta.pl sample.stitchmap sample_scaffold.fasta tcas.scaffolds.fasta_key.txt
#  USAGE: perl stitchmap_to_fasta.pl [scaff_stitchmap] [scaffold_fasta]
#   This script creates a non-redundant (i.e. no scaffold is used twice unless it is used to stich together molecule maps) super-scaffolds from a scaffold fasta file (ordered so that the scaffold id is the numeric order in the fasta file starting with ">1") and the filtered stitchmap
#   Run number_fasta.pl on your fasta file to create the correct fasta to pass as an arguement to this script. If two scaffolds overlap on the superscaffold than a 30 "n" gap is used as a spacer between them. If a scaffold has two high quality alignments the longest alignment is sellected. If both alignments are equally long the alignment with the highest confidence is sellected. 
#  Created by jennifer shelton on 12/2/13.
#
################ Read arguments ###############################################
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::DB::Fasta; #makes a searchable db from my fasta file

my $infile_stitchmap=$ARGV[0];
my $infile_fasta=$ARGV[1];
print "infile_stitchmap: $infile_stitchmap\n";
print "infile_fasta: $infile_fasta\n";
###############################################################################
################ Open stitchmap and create fasta file ##############################
###############################################################################

open (STITCHMAP, "<$infile_stitchmap")or die "can't open $infile_stitchmap $!";

$infile_stitchmap =~ /(.*)_scaffolds.stitchmap/;
my $outfile="$1"."_superscaffold.fasta";
if (-e "$outfile") {print "$outfile file Exists!\n"; exit;}
#my $db = Bio::DB::Fasta->new("$infile_fasta",-reindex=>1,-makeid=>\&make_my_id); 	# Create new DB object. BioPerl will warn you if no file specified
my $db = Bio::DB::Fasta->new("$infile_fasta");
my $seq_out = Bio::SeqIO->new('-file' => ">$outfile",'-format' => 'fasta');		#Create new fasta outfile object.


###############################################################################
################### make table of stitchmap ###################################
###############################################################################

my (@stitchmap_table); # 2D arrays
while (<STITCHMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if (($_ !~ /^#/) && ($_ ne ''))
	{
        chomp;
        my @stitchmap=split ("\t");
        s/\s+//g foreach @stitchmap;
        push (@stitchmap_table, [@stitchmap]);
	}
}


#############################################################################
########################     clean up stitchmap    ##########################
#############################################################################
my %alignments; ## list of best alignments ranked by length with ties broken by confidence score
my %second_alignments; ## list of second best alignments ranked by length with ties broken by confidence score
my $main_index=0;
for my $row (@stitchmap_table)## calculate sequence generated scaffold's footprint on the molecule map
{
    ## object begining = 5 stitchmap
    ## object end = 6 stitchmap
    ## comp begining = 3 or 4 stitchmap
    ## contig id = 1 stitchmap
    ## end of alignment = 3 or 4 stitchmap
    ## begining of alignment = 3 or 4 stitchmap
    #############################################################################
    ######### find all redundant alignments of a single contig  #################
    #########               and choose the best                 #################
    #############################################################################
    if ($alignments{$row->[1]}) # if we already have a "best alignment" for this contig
    {
        my $array_id=$alignments{$row->[1]};
        if (($row->[6]-$row->[5]) > ($stitchmap_table[$array_id]->[6] - $stitchmap_table[$array_id]->[5])) # if the current alignment is longer than the previous "best alignment" make it best
        {
            $alignments{$row->[1]}="$main_index";
            $second_alignments{$row->[1]}="$array_id";
        }
        elsif ((($row->[6]-$row->[5])==($stitchmap_table[$array_id]->[6] - $stitchmap_table[$array_id]->[5]))&&($row->[8] > $stitchmap_table[$array_id]->[8])) # if the current alignment is as long than the previous "best alignment" with higher confidence make it best
        {
            $alignments{$row->[1]}="$main_index";
            $second_alignments{$row->[1]}="$array_id";
        }
        #############################################################################
        ######### find all redundant alignments of a single contig  #################
        #########               and choose the second best          #################
        #############################################################################
        elsif ($second_alignments{$row->[1]})# if the current alignment is not better than the "best alignment" test if it is better than the "second best" (if we already have a "second best alignment" for this contig)
        {
            my $second_array_id = $second_alignments{$row->[1]};
            {
                if (($row->[6]-$row->[5]) > ($stitchmap_table[$second_array_id]->[6] - $stitchmap_table[$second_array_id]->[5])) # if the current alignment is longer than the previous "second best alignment" make it best
                {
                    $second_alignments{$row->[1]}="$main_index";
                }
                elsif ((($row->[6]-$row->[5])==($stitchmap_table[$second_array_id]->[6] - $stitchmap_table[$second_array_id]->[5])) && ($row->[8]>$stitchmap_table[$second_array_id]->[8])) # if the current alignment is as long than the previous "second best alignment" with higher confidence make it best

                {
                    $second_alignments{$row->[1]}="$main_index";
                }
            }
        }
        elsif (!$second_alignments{$row->[1]}) ## initialize "second best alignment"
        {
            $second_alignments{$row->[1]}="$main_index";
        }
    }
    elsif (!$alignments{$row->[1]})
    {
        $alignments{$row->[1]}="$main_index"; ## initialize "best alignment"
    }
    ++$main_index;
}
###############################################################################
##################   check for "stitching scaffolds   #########################
##################     add them to an overlap hash    #########################
###############################################################################
for my $best (keys %alignments)
{
    if ($second_alignments{$best})
    {
        if (($stitchmap_table[$alignments{$best}]->[14] eq "zero_stitch") && ($stitchmap_table[$second_alignments{$best}]->[14] eq "n_stitch"))
        {
            print "MOL:$stitchmap_table[$alignments{$best}]->[2] best= zero_stitch ; MOL:$stitchmap_table[$second_alignments{$best}]->[2] second best = n_stitch for CON: $stitchmap_table[$alignments{$best}]->[1]\n";
        }
        if (($stitchmap_table[$alignments{$best}]->[14] eq "n_stitch") && ($stitchmap_table[$second_alignments{$best}]->[14] eq "zero_stitch"))
        {
            print "MOL:$stitchmap_table[$alignments{$best}]->[2] best= n_stitch ; MOL:$stitchmap_table[$second_alignments{$best}]->[2] second = zero_stitch for CON: $stitchmap_table[$alignments{$best}]->[1]\n";
        }
    }
}
###############################################################################
##################   identify overlapping footprints  #########################
##################     add them to an overlap hash    #########################
###############################################################################
####### this process assumes a 1 base coordinate system ###############
#######################################################################

$main_index=0;
for my $main_loop (@stitchmap_table) # for each sequence-based contig feature in the stitchmap
{
    my $nested_index=0;
 	for my $nested_loop (@stitchmap_table) # compare its footprint to every other contig feature's footprint
    {
        if (($main_loop->[2] eq $nested_loop->[2]))# check only for footprints on the same molecule map
        {
            
            if ($main_loop->[10] <= $nested_loop->[10] && $nested_loop->[10] <= $main_loop->[11])
                # run if the sequenced-based contig in the nested loop has start coordinates within any the footprints of the main loop sequenced-based contig
            {
                if ("$main_loop->[1]" ne "$nested_loop->[1]")# don't calculate overlaps of the same sequence-based contig
                {
                    undef $main_loop->[17]{$nested_index}; ## add all overlaps to a hash in the 17th column (contig_id->[17])
                    undef $nested_loop->[17]{$main_index};

                }
            }
        }
        ++$nested_index;
    }
    ++$main_index;
}

##############################################################################
#########         add confounding overlaps to overlap hash           #########
##############################################################################
my @reversed_stitchmap_table=reverse(@stitchmap_table); ## because if "a" overlaps with "b" and "b" overlaps with "c" then no gap of known size exists between "a" "b" or "c"

for my $row (@reversed_stitchmap_table) # for each stitchmap entry
{
    --$main_index;
    for my $overlap_index (keys %{ $stitchmap_table[$main_index]->[17] }) # for each reported ovelaping alignment
    {
        for my $confounded (keys %{ $stitchmap_table[$overlap_index]->[17] }) # for its reported overlaps
        {
            if ($confounded != $main_index)
            {
                undef $row->[17]{$confounded};
            }

        }
        
    }
}
########################################################################
########################     print to new    ###########################
######################## fasta scaffold file ###########################
########################################################################
my $n=1;
my $last_fasta=-1;
my %finished; ## we  will use %finished as a list of scaffolds added to super scaffolds so that the remaining contigs can be added
my $old_mol=-1; ## begins with the last molecule (in theory this should not match the first molecule but must be changed if the first molecule in the stitchmap is also the last e.g. bacterial)
my $scaffold_id = "Super_scaffold_$n"; ### initialize first superscaffold
my $new_seq  = ''; ### initialize first superscaffold
for my $row (@stitchmap_table)
{
	unless (exists $finished{$row->[1]})
    {
        my $new_mol=$row->[2];
        ###################################################################
        #################  starting/changing molecules ####################
        ###################################################################
        if ($new_mol != $old_mol) ## if we are not on the same molecule
        {
            unless ($n==1)
            {
                my $scaffold_obj = Bio::Seq->new( -display_id =>  $scaffold_id, -seq => $new_seq, -alphabet => 'dna');
                $seq_out->write_seq($scaffold_obj); ## write the finished superscaffold
            }
            $scaffold_id = "Super_scaffold_$n"; ## initialize new superscaffold
            $new_seq = '';
            ++$n;
        }

                    ### continue building superscaffolds ###
        ###################################################################
        ########             append known gaps                  ###########
        ###################################################################
        if ($old_mol==$new_mol)
        {
            $new_seq = "$new_seq"."n" x ($row->[10]-($stitchmap_table[$last_fasta]->[11])-1); ## add n's (as many as there are positions from the the footprint start of the current contig to the footprint end of the last contig if the last contig is on the same molecule
        }
        ###################################################################
        ######## append non-overlapping contigs to the scaffold ###########
        ###################################################################
        my ($start,$stop) = ($row->[7] eq '+')?(1, $row->[15]):($row->[15], 1); # "?:" operator tests if the sequence is in the forward or reverse direction and reverses start and stop if minus strand
        $new_seq = "$new_seq".$db->seq("$row->[1]:$start,$stop"); ## add the new sequence to the growing superscaffold
        $finished{$row->[1]}=1; ## add to the list of superscaffolded sequences
        ++$last_fasta; ## keep track of the array index for the last contig added

        ###################################################################
        #########  append overlapping contigs to the scaffold #############
        ###################################################################
        if (scalar(keys %{ $row->[17] }) > 0 ) # if the molecule has overlaping alignments
        {
            for my $overlap (sort keys %{ $row->[17] } ) ## for all overlaping alignments
            {
                
                $new_seq = "$new_seq"."n" x 30; ## add "spacer" gaps of 30 x n
                ($start,$stop) = ($stitchmap_table[$overlap]->[7] eq '+')?(1, $stitchmap_table[$overlap]->[15]):($stitchmap_table[$overlap]->[15], 1); # "?:" operator tests if the sequence is in the forward or reverse direction and reverses start and stop if minus strand
                $new_seq = "$new_seq".$db->seq("$stitchmap_table[$overlap]->[1]:$start,$stop");
                $finished{$stitchmap_table[$overlap]->[1]}=1; ## add to the list of superscaffolded sequences
                ++$last_fasta; ## keep track of the array index for the last contig added
            }
        }
		$old_mol=$new_mol; ## now the current molecule will be listed as the last molecule we have seen
        if ($last_fasta==$#stitchmap_table) ## if this is the last row in the stitchmap
        {
            my $scaffold_obj = Bio::Seq->new( -display_id =>  $scaffold_id, -seq => $new_seq, -alphabet => 'dna');
            $seq_out->write_seq($scaffold_obj); ## Write the final sequence object
        }
    }
}
###############################################################################
###### Append scaffolds not used to create a super-scaffold to fasta ##########
####### this process uses a 1 base coordinate system #######################
###############################################################################
my $key_file=$ARGV[2];
open (KEY,"<",$key_file) or die "couldn't open $key_file $!";
my %key_hash;
while (<KEY>)
{
    unless (/^#/)
    {
        chomp;
        my @row=split ("\t");
        s/\s+//g foreach @row;
        $key_hash{$row[4]}=$row[2];
    }
}

my $stream  = $db->get_PrimarySeq_stream;
while (my $seq = $stream->next_seq)
{
    my $final_seq = $seq->seq;
    unless ($finished{$seq})
    {
        $scaffold_id=$key_hash{$seq};
        my $scaffold_obj = Bio::Seq->new( -display_id =>  $scaffold_id, -seq => $final_seq, -alphabet => 'dna');
        $seq_out->write_seq($scaffold_obj); ## Write the unsuperscaffolded sequence object
    }
}


