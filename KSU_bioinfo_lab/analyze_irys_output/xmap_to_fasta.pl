#!/bin/perl

#  perl xmap_to_fasta.pl sample.xmap sample_scaffold.fasta tcas.scaffolds.fasta_key.txt
#  USAGE: perl xmap_to_fasta.pl [scaff_xmap] [scaffold_fasta]
#   This script creates a non-redundant (i.e. no scaffold is used twice) super scaffold from a scaffold file (ordered so that the scaffold id is the numeric order in the fasta file starting with ">1") and the filtered xmap
#   Run number_fast.pl on your fasta file to create the correct fasta to pass as an arguement to this script. If two scaffolds overlap on the superscaffold than a 30 "n" gap is used as a spacer between them. If a scaffold has two high quality alignments the longest alignment is sellected. If both alignments are equally long the alignment with the highest confidence is sellected. 
#  Created by jennifer shelton on 12/2/13.
#
################ Read arguments ###############################################
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::DB::Fasta; #makes a searchable db from my fasta file

my $infile_xmap=$ARGV[0];
my $infile_fasta=$ARGV[1];
print "infile_xmap: $infile_xmap\n";
print "infile_fasta: $infile_fasta\n";
###############################################################################
################ Open maps and create fasta file ##############################
###############################################################################

open (XMAP, "<$infile_xmap")or die "can't open $infile_xmap $!";

$infile_xmap =~ /(.*)_scaffolds.xmap/;
my $outfile="$1"."_super_scaffold.fasta";
if (-e "$outfile") {print "$outfile file Exists!\n"; exit;}
#my $db = Bio::DB::Fasta->new("$infile_fasta",-reindex=>1,-makeid=>\&make_my_id); 	# Create new DB object. BioPerl will warn you if no file specified
my $db = Bio::DB::Fasta->new("$infile_fasta");
my $seq_out = Bio::SeqIO->new('-file' => ">$outfile",'-format' => 'fasta');		#Create new fasta outfile object.


###############################################################################
################### Load input files ##########################################
###############################################################################


###############################################################################
##################### Find contig lengths #####################################
####### this process uses a 1 base coordinate system #######################
###############################################################################

my (%contig_length);
my $stream  = $db->get_PrimarySeq_stream;
while (my $seq = $stream->next_seq)
{
	my $contig_length=$db->length("$seq");
	$contig_length{$seq} = $contig_length; ## hash with id as key and sequence generated contig length as value
}

########################################################################
##################### Load xmap ########################################
my (@xmap_table); # 2D arrays
while (<XMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if ($_ !~ /^#/)
	{
        chomp;
        my @xmap=split ("\t");
        s/\s+//g foreach @xmap;
        push (@xmap_table, [@xmap]);
	}
}


#############################################################################
########################     clean up xmap    ###############################
#############################################################################
my $main_index=0;
my %alignments; ## list of best alignments ranked by length with ties broken by confidence score
for my $row (@xmap_table)## calculate sequence generated scaffold's footprint on the molecule contig 
{
    ## object begining = 5 xmap
    ## object end = 6 xmap
    ## comp begining = 3 or 4 xmap
    ## contig id = 1 xmap
    ## end of alignment = 3 or 4 xmap
    ## begining of alignment = 3 or 4 xmap
    #############################################################################
    ######### find all redundant alignments of a single contig  #################
    #########               and choose the best                 #################
    #############################################################################
    if ($alignments{$row->[1]})
    {
        my ($map_id,$length,$confidence)=split /,/,$alignments{$row->[1]};
        if (($row->[6]-$row->[5])>$length)
        {
            $alignments{$row->[1]}="$main_index,$row->[6]-$row->[5]),$row->[8]";
        }
        if ((($row->[6]-$row->[5])==$length)&&($row->[8]>$confidence))
        {
            $alignments{$row->[1]}="$main_index,$row->[6]-$row->[5]),$row->[8]";
        }
    }
    elsif (!$alignments{$row->[1]})
    {
        $alignments{$row->[1]}="$main_index,$row->[6]-$row->[5]),$row->[8]";
    }
    ++$main_index;

    ############################################################################
    ########################### find all footprints  ###########################
    ############################################################################
    if ($row->[3] < $row->[4]) #if contig aligns in the '+' orientation
        {
            my $contig_start_pos=$row->[3];
            my $contig_end_pos=$row->[4];
            ###################################################################
            ######################## calculate footprint ######################
            ###################################################################
            my $footprint_start=$row->[5]-$contig_start_pos+1;
            $footprint_start=int($footprint_start);
            my $footprint_end=$footprint_start + $contig_length{$row->[1]}-1;
            $footprint_end=int($footprint_end);
            $row->[10] = "$footprint_start";
            $row->[11] = "$footprint_end";
#            print "$row->[1]: $row->[10] = footprint_start\n";
#            print "$row->[1]: $row->[11] = footprint_end\n";
        }
    elsif ($row->[3] >= $row->[4]) #if contig aligns in the '-' orientation
        {
            my $contig_start_pos=$row->[4];
            my $contig_end_pos=$row->[3];
            my $footprint_start=$row->[5]-($contig_length{$row->[1]}-$row->[3]);
            $footprint_start=int($footprint_start);
            my $footprint_end=$row->[6]+($row->[4]-1) ;
            $footprint_end=int($footprint_end);
            $row->[10] = "$footprint_start";
            $row->[11] = "$footprint_end";
#            print "$row->[1]: $row->[10] = footprint_start\n";
#            print "$row->[1]: $row->[11] = footprint_end\n";
        }

}
###############################################################################
##################   identify overlapping footprints  #########################
##################     add them to an overlap hash    #########################
###############################################################################
####### this process assumes a 1 base coordinate system ###############
#######################################################################

$main_index=0;
for my $main_loop (@xmap_table) # for each sequence-based contig feature in the xmap
{
    my $nested_index=0;
 	for my $nested_loop (@xmap_table) # compare its footprint to every other contig feature's footprint
    {
        if (($main_loop->[2] eq $nested_loop->[2]))# check only for footprints on the same molecule contig
        {
            
            if ($main_loop->[10] <= $nested_loop->[10] && $nested_loop->[10] <= $main_loop->[11])
                # run if the sequenced-based contig in the nested loop has start coordinates within any the footprints of the main loop sequenced-based contig
            {
                if ("$main_loop->[1]" ne "$nested_loop->[1]")# don't calculate overlaps of the same sequence-based contig
                {
                    undef $main_loop->[12]{$nested_index}; ## add all overlaps to a hash in the 12th column (contig_id->[12])
                    undef $nested_loop->[12]{$main_index};

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
my @reversed_xmap_table=reverse(@xmap_table); ## because if "a" overlaps with "b" and "b" overlaps with "c" then no gap of known size exists between "a" "b" or "c"

for my $row (@reversed_xmap_table) # for each xmap entry
{
    --$main_index;
    for my $overlap_index (keys %{ $xmap_table[$main_index]->[12] }) # for each reported ovelaping alignment
    {
        for my $confounded (keys %{ $xmap_table[$overlap_index]->[12] }) # for its reported overlaps
        {
            if ($confounded != $main_index)
            {
                undef $row->[12]{$confounded};
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
my $old_mol=-1; ## begins with the last molecule (in theory this should not match the first molecule but must be changed if the first molecule in the xmap is also the last e.g. bacterial)
my $scaffold_id = "Super_scaffold_$n"; ### initialize first superscaffold
my $new_seq  = ''; ### initialize first superscaffold
for my $row (@xmap_table)
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
                $seq_out->write_seq($scaffold_obj); ## write the finsihed superscaffold
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
            $new_seq = "$new_seq"."n" x ($row->[10]-($xmap_table[$last_fasta]->[11])-1); ## add n's (as many as there are positions from the the footprint start of the current contig to the footprint end of the last contig if the last contig is on the same molecule
        }
        ###################################################################
        ######## append non-overlapping contigs to the scaffold ###########
        ###################################################################
        my ($start,$stop) = ($row->[7] eq '+')?(1, $contig_length{$row->[1]}):($contig_length{$row->[1]}, 1); # "?:" operator tests if the sequence is in the forward or reverse direction and reverses start and stop if minus strand
        $new_seq = "$new_seq".$db->seq("$row->[1]:$start,$stop"); ## add the new sequence to the growing superscaffold
        $finished{$row->[1]}=1; ## add to the list of superscaffolded sequences
        ++$last_fasta; ## keep track of the array index for the last contig added

        ###################################################################
        #########  append overlapping contigs to the scaffold #############
        ###################################################################
        if (scalar(keys %{ $row->[12] }) > 0 ) # if the molecule has overlaping alignments
        {
            for my $overlap (sort keys %{ $row->[12] } ) ## for all overlaping alignments
            {
                
                $new_seq = "$new_seq"."n" x 30; ## add "spacer" gaps of 30 x n
                ($start,$stop) = ($xmap_table[$overlap]->[7] eq '+')?(1, $contig_length{$xmap_table[$overlap]->[1]}):($contig_length{$xmap_table[$overlap]->[1]}, 1); # "?:" operator tests if the sequence is in the forward or reverse direction and reverses start and stop if minus strand
                $new_seq = "$new_seq".$db->seq("$xmap_table[$overlap]->[1]:$start,$stop");
                $finished{$xmap_table[$overlap]->[1]}=1; ## add to the list of superscaffolded sequences
                ++$last_fasta; ## keep track of the array index for the last contig added
            }
        }
		$old_mol=$new_mol; ## now the current molecule will be listed as the last molecule we have seen
        if ($last_fasta==$#xmap_table) ## if this is the last row in the xmap
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

$stream  = $db->get_PrimarySeq_stream;
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


