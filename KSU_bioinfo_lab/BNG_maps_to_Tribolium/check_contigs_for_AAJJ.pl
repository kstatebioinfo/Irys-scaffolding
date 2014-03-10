#!/bin/perl
##################################################################################
#   
#	USAGE: perl [
#	Blasts each tcas contig to every AAJJ listed on it and list alignments less than the full AAJJ length
#  Created by jennifer shelton
#	curl -O ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas.contigs.fasta
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use Bio::Seq;
use Bio::SeqIO;
use Bio::DB::Fasta; #makes a searchable db from my fasta file
###############################################################################
##############  define input fastas and bioperl database      #################
###############################################################################
my $contig_fasta = "tcas.contigs.fasta"; #query fasta
my $aajj_fasta = "Contigs.dna.fa"; #subject fasta
my $db = Bio::DB::Fasta->new("$contig_fasta"); #query bioperl database
mkdir "databases";
mkdir "blasts";
mkdir "split";
###############################################################################
##############               make single file fasta          ##################
###############################################################################
sub make_single_fasta
{
    my $sub_contig = $_[0];
    my $out = "split/${sub_contig}.fasta";
    my $seq_out = Bio::SeqIO->new('-file' => ">$out",'-format' => 'fasta');		#Create new fasta outfile object.
    my $seq_obj = $db->get_Seq_by_id($sub_contig); #get fasta file
	$seq_out->write_seq($seq_obj);
    return $out;
}
###############################################################################
##############               make subject database           ##################
###############################################################################
sub make_subj_db
{
    my $sub_fasta = $_[0];
    my $makedb = `../../ncbi-blast-2.2.29+/bin/makeblastdb -in $sub_fasta -out databases/${sub_fasta} -dbtype nucl`;
    return $makedb;
}
###############################################################################
##############               make blast database             ##################
###############################################################################
sub blast_db
{
    my $sub_query = $_[0];
    my $sub_subj = $_[1];
    `../../ncbi-blast-2.2.29+/bin/blastn -query $sub_query -db databases/${sub_subj} -max_hsps 1 -ungapped -num_alignments 1 -outfmt 5 > ${sub_subj}.txt`;
    my $results = "${sub_subj}.txt";
    return $results;
}
###############################################################################
##############       Loop through AAJJ to conitg id key      ##################
###############################################################################
open (MAP, '<', "contig.map") or die "can't open contig.map!\n";
while (<MAP>)
{
    if (/^AAJJ/)
    {
        chomp;
        my ($aajj,$contig) = split ("\t");
        my $query_filename = make_single_fasta($contig);
        my $subj_filename = make_single_fasta($aajj);
        my $subj_db =  make_subj_db($subj_filename);
        my $blast = blast_db($query_filename,$subj_filename);
        open (BLAST_OUT, '<', "$blast") or die "can't open $blast\n";
        my @blast_result = (<BLAST_OUT>);
        my ($aajj_length,$hsp_length);
        for my $result (@blast_result)
        {
            if ($result =~ /<Hit_len>(.*)<\/Hit_len>/)
            {
                $aajj_length = $1;
            }
            if ($result =~ /<Hsp_align-len>(.*)<\/Hsp_align-len>/)
            {
                $hsp_length = $1;
            }

        }
        my $failed;
        if (!defined $hsp_length)
        {
            $failed = 1;
        }
        elsif ($hsp_length < $aajj_length)
        {
            $failed = 1;
        }
        else
        {
            `rm ${blast} ${query_filename} ${subj_filename} ${subj_filename}*`;
        }
            
    }
}
