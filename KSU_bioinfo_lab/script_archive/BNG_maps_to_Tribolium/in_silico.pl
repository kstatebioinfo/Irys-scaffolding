#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Bio::DB::Fasta;
use Bio::SeqIO;
use Bio::Seq;

my ($i_fasta, $agp, $build_db, $o_fasta, $key, $seq_name, $seq, $seq_id, %chr);

# read user arguments
my $usage = "usage: ./in_silico.pl -if contigs.fasta -a chromosome_from_component.agp [-d yes|no, default=yes] -of tcas.in_silico.fasta -k key.txt\n";
GetOptions ('if|input_fasta=s'		=> \$i_fasta,
            'a|agp=s'			=> \$agp,
            'd|database:s'		=> \$build_db,
            'of|output_fasta=s'		=> \$o_fasta,
            'k|key=s'			=> \$key) or die $usage;
if (!($i_fasta and $agp and $o_fasta and $key)) {
  print $usage;
  exit;
}
$build_db = defined ($build_db) ? $build_db : 'yes';
if ($build_db ne 'yes' && $build_db ne 'no') {
  print $usage;
  exit;
}

# create database handle for FASTA sequences
my $db = Bio::DB::Fasta->new ($i_fasta, -reindex => $build_db eq 'yes' ? 1 : 0); 

# parse chromosome AGP and build FASTA sequences
my $outseq = Bio::SeqIO->new (-file => ">$o_fasta", -format => 'Fasta', -flush => 1);
($seq_id, $seq_name) = (0, '');
my @ch_coords;						# chromosome coordinates for the sequence
open AGP, '<', $agp or die "Couldn't open $agp: $!";
while (<AGP>) {
  unless (/^#/ or /^\s*$/) {	# skip blank and comment lines
    chomp;
    my @col = split;
    if ($seq_name ne $col[0]) {		# new superscaffold in AGP file
      # output previous sequence
      &write_seq () if ($seq_name ne '');
      # start new sequence
      $seq_id++;
      $seq_name = $col[0];							# get sequence name in AGP file
      @{$chr{$col[0]}}[0] = $seq_id if (!defined (@{$chr{$col[0]}}[0]));	# set first sequence number in this chromosome
      @{$chr{$col[0]}}[1] = $seq_id;						# set last sequence number in this chromosome
      @ch_coords = ($col[1], $col[2]);						# set start and end coordinates on the chromosome for this sequence
      $seq = $col[8] eq '+' ? $db->get_Seq_by_id ($col[5])->seq : $db->get_Seq_by_id ($col[5])->revcom->seq;	# get the sequence for this contig
    }
    elsif ($col[4] eq 'W') {		# contig
      $seq .= $col[8] eq '+' ? $db->get_Seq_by_id ($col[5])->seq : $db->get_Seq_by_id ($col[5])->revcom->seq;	# append contig to sequence
      $ch_coords[1] = $col[2];							# set end coordinate on the chromosome for this sequence
    }
    elsif ($col[4] eq 'N') {		# captured gap
      $seq .= 'N' x $col[5];							# append gap to sequence
    }
    elsif ($col[4] eq 'U') {		# uncaptured gap
      # output current sequence
      &write_seq ();
      # flag the start of new sequence
      $seq_name = '';
    }
  }
}
&write_seq();
close AGP;

# write key file
open my $key_fh, '>', $key or die "Couldn't open $key: $!";
for my $k (sort keys %chr) {
  printf $key_fh "$k\tScaffold%04u - Scaffold%04u\n", $chr{$k}[0], $chr{$k}[1];
}
close $key_fh;

sub write_seq {
  my $seq = Bio::Seq->new (-seq			=> $seq,
                           -id			=> sprintf ("Scaffold%04u_%s:%u..%u", $seq_id, $seq_name, $ch_coords[0], $ch_coords[1]));
  $outseq->write_seq ($seq);
}
