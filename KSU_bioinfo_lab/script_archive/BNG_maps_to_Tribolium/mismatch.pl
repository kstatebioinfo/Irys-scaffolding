#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(min max);

# usage: ./mismatch.pl bionano_query_from_component.agp tcas_chromosome_from_component.agp IrysView.xmap contig.map > contigs_of_interest.txt

# load input files
open AGP, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my %qry_agp;
while(<AGP>) {
  if(/\tW\t/) {						# read only the contig rows
    chomp;
    my($qry_name,@agp_line) = (split)[0,1,2,5];		# from: Query1	2248	5116	3	W	tcas_2	1	2869	+
    push (@{$qry_agp{$qry_name}}, \@agp_line);		# keep: Query1	2248	5116	tcas_2
  }
}
close AGP;

open AGP, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my %tcas_agp;
while(<AGP>) {
  if(!/^#/ && /\tW\t/) {				# read only the contig rows
    chomp;
    my($contig_name, @agp_line) = (split)[5,0..2];	# from: ChLGX   1       18146   1       W       tcas_4417       1       18146   +
    $tcas_agp{$contig_name} = \@agp_line;		# keep: ChLGX   1	18146       tcas_4417
  }
}
close AGP;

open XMAP, '<', $ARGV[2] or die "Couldn't open $ARGV[2]: $!";
my %iv_xmap;
while(<XMAP>) {
  unless(/^#/) {					# skip comment rows
    chomp;						# #h XmapEntryID  QryContigID     RefcontigID     QryStartPos     QryEndPos       RefStartPos     RefEndPos       Orientation     Confidence      HitEnum
    my @xmap_line = split (/\s+/, $_);			#     1          115               1                 615821.6        511250.5       234980.0        339943.0       -                 6.03          1M1I4M
    push(@{$iv_xmap{$xmap_line[3]}}, \@xmap_line);
  }
}
close XMAP;

open MAP, '<', $ARGV[3] or die "Couldn't open $ARGV[3]: $!";
my %contig_map;
while(<MAP>) {
  if(/^AAJJ/) {
    chomp;
    my($tcas3, $tcas4) = split;
    push(@{$contig_map{$tcas4}}, $tcas3);
  }
}
close MAP;

my %qry_coordinates;
&get_superscaffold_coordinates_for_query();

# traverse IrysView XMAP
print "Anchor_name\tAnchor_start\tAnchor_stop\tQuery_name\tQuery_start\tQuery_stop\tQuery_orientation\tQueries_in_superscaffold\tContig_name_40\tScaffold_start_40\tScaffold_stop_40\tContig_name_30\tContig_in_alignment_region\tSuperscaffold_name\tSuperscaffold_start\tSuperscaffold_stop\n";
for my $anchor_name (keys %iv_xmap) {
  my %qry_list;
  # get the list of Tcas4.0 superscaffolds in this anchor
  for my $xmap_line_ref (@{$iv_xmap{$anchor_name}}) {
    my $qry_name = $xmap_line_ref->[2];
    my $first_contig = $qry_agp{$qry_name}->[0][2];
    my $qry_superscaffold_start = $qry_agp{$qry_name}->[0][0];
    my $qry_superscaffold_stop = $qry_agp{$qry_name}->[scalar (@{$qry_agp{$qry_name}}) - 1][1];
    if (defined ($first_contig)) {
      my $superscaffold = $tcas_agp{$first_contig}->[0];
      push(@{$qry_list{$superscaffold}}, [$qry_name, $xmap_line_ref->[6], $xmap_line_ref->[7], $xmap_line_ref->[4], $xmap_line_ref->[5], $xmap_line_ref->[8], $qry_coordinates{$qry_name}->[0], $qry_coordinates{$qry_name}->[1]]);
    }
  }

  # process superscaffolds
  for my $superscaffold (keys %qry_list) {
    for my $query (@{$qry_list{$superscaffold}}) {
      for my $contig (@{$qry_agp{$query->[0]}}) {
        for my $contig3 (@{$contig_map{$contig->[2]}}) {
          my $align = 'no';
          if(($query->[3] <= $contig->[0] && $contig->[1] <= $query->[4]) || ($contig->[0] <= $query->[3] && $query->[3] <= $contig->[1]) || ($contig->[0] <= $query->[4] && $query->[4] <= $contig->[1])) {
            $align = 'yes';
          }
          print "$anchor_name\t", join("\t", @{$query}[1,2,0,3..5]), "\t", 1 + $#{$qry_list{$superscaffold}}, "\t", join("\t", @{$contig}[2,0,1]), "\t$contig3\t", "\t$align\t$superscaffold\t$query->[6]\t$query->[7]\n";
        }
      }
    }
  }
}

sub get_superscaffold_coordinates_for_query {
  for my $qry_name (keys %qry_agp) {
    my $first_contig = $qry_agp{$qry_name}->[0][2];
    my $last_contig = $qry_agp{$qry_name}->[scalar (@{$qry_agp{$qry_name}}) - 1][2];
    $qry_coordinates{$qry_name} = [min ($tcas_agp{$first_contig}->[1], $tcas_agp{$last_contig}->[1]), max ($tcas_agp{$first_contig}->[2], $tcas_agp{$last_contig}->[2])];
  }
}
