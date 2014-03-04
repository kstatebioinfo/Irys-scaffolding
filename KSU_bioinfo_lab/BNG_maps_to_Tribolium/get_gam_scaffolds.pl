#!/bin/perl
##################################################################################
#   
#	USAGE: perl get_gam_scaffolds.pl
# Scripts brings gam-ngs scaffolds into the reoriented scaffold fasta file
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
my %joined = ("Scaffold1655"=>undef, "Scaffold661"=>undef, "Scaffold1773"=>undef, "Scaffold378"=>undef);
my %changed = ("Scaffold297"=>"PairedContig_307", "Scaffold128"=>"PairedContig_606");
my @new = qw/PairedContig_71 PairedContig_325/;
my $infile_fasta = "master.tcas4.0.slave.scaffolds_merge.gam_reverted.fasta";
my $db = Bio::DB::Fasta->new("$infile_fasta");
open (FASTA, '<', "${dir}/tcas.in_silico_plus.fasta") or die "can't open ${dir}tcas.contigs.fasta !\n";
my $out = "${dir}/tcas.scaffolds_plus_gam.fasta"; ## changed name to plus to indicate that they reversed if aligning in the minus direction to the superscaffold
my $seq_out = Bio::SeqIO->new('-file' => ">$out",'-format' => 'fasta');		#Create new fasta outfile object.
my $header;
$/=">";
while (<FASTA>)
{
    my ($header,@seq)=split/\n/;
    my $seq=join '', @seq;
    if ($header =~ /^>/){next};
    $seq =~ s/>//g;
    $header =~ s/ //g; ## removed white space because bioperl doesn't allow it in headers
#     >Scaffold0001 | ChLGX:1..255309 | Scaffold144
    $header =~ /Scaffold[0]*.*\|(Scaffold.*)/;
    #######################################################################
    ##              print to  tcas_contigs_plus.fasta                  ####
    #######################################################################
    my $seq_obj = Bio::Seq->new( -display_id => $header, -seq => $seq);
    if ($joined{$1})
    {
		next; #skip superscaffolded fasta files
    }
    if ($changed{$1})
    {
    	$seq_obj = $db->get_Seq_by_id($changed{$1}); #get altered fasta files
    	$seq_out->write_seq($seq_obj);
    }
    else
    {
        $seq_out->write_seq($seq_obj);
    }
    
}
for my $new (@new)
{
	$seq_obj = $db->get_Seq_by_id($new); #get altered fasta files
	$seq_out->write_seq($seq_obj);
}



