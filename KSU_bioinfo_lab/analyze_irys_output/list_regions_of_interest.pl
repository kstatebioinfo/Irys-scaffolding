#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw(min max);

# usage: ./list_regions_of_interest.pl map.txt superscaffold_from_component.agp
# usage: ./list_regions_of_interest.pl contigs_of_interest.txt tcas40/tcas_chromosome_from_component.agp

# sample input
# head -n 2 contigs_of_interest.txt
#Anchor_name	Anchor_start	Anchor_stop	Query_name	Query_start	Query_stop	Query_orientation	Queries_in_superscaffold	Contig_name_40	Scaffold_start_40	Scaffold_stop_40	Contig_name_30	Contig_in_alignment_region	Superscaffold_name	Superscaffold_start	Superscaffold_stop
#Anchor18	1259315	1709173.1	Query275	2541.7	452667	+	2	tcas_3722	480656	574935	AAJJ01000216		no	ChLG2

# head -n 8 tcas40/tcas_chromosome_from_component.agp
###agp-version   2.0
## ORGANISM: Tribolium castaneum
## TAX_ID: 7070
## ASSEMBLY NAME: Tcas_4.0
## ASSEMBLY DATE: 10-December-2012
## GENOME CENTER: Bioinformatics Center at Kansas State University
## DESCRIPTION: AGP specifying the assembly of chromosomes from WGS contigs
#ChLGX	1	18146	1	W	tcas_4417	1	18146	+

# load input files
open MAP, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
#my %anchor_map;	# Anchor18=>(1259315	1709173.1	Query275=>(2541.7	452667	+	2	tcas_3722=>(480656	574935	AAJJ01000216	no ChLG2)))
my %query_to_anchor;	# Query275=>(Anchor18=>(Anchor_start, Anchor_stop))
my %anchor_to_query;	# Anchor18=>(Query275=>(Anchor_start, Anchor_stop))
my %query_to_superscaffold;	# Query275=>(ChLG2, Superscaffold_start, Superscaffold_stop)
#my %contig_map;	# tcas_3722=>Query275
my %edge_contigs;	# Query275=>(tcas_3722, tcas_3724)
while(<MAP>) {
  unless(/stop/) {
    chomp;
    my @map_line = split;
    #my %contig = ($map_line[8] => [@map_line[9..13]]);
    #my %query = ($map_line[3] => [@map_line[4..7], \%contig]);
    #push(@{$anchor_map{$map_line[0]}}, [@map_line[1..2], \%query]);
    ${$query_to_anchor{$map_line[3]}}{$map_line[0]} = [@map_line[1,2]];
    ${$anchor_to_query{$map_line[0]}}{$map_line[3]} = [@map_line[1,2]];
    $query_to_superscaffold{$map_line[3]} = [@map_line[13..15]];
    #$contig_map{$map_line[8]} = $map_line[3];
    $edge_contigs{$map_line[3]}[0] = $map_line[8] if (!defined ($edge_contigs{$map_line[3]}[0]));
    $edge_contigs{$map_line[3]}[1] = $map_line[8];
  }
}
close MAP;

open AGP, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my %agp;	# ChLGX=>(1	18146	1	tcas_4417	+)
my %contig_to_superscaffold;	# tcas_4417=>(ChLGX	1	18146	+)
while(<AGP>) {
  if(/\tW\t/) {						# read only the contig rows
    chomp;
    my @agp_line = (split)[0..3,5,8];
    push(@{$agp{$agp_line[0]}}, [@agp_line[0..5]]);
    $contig_to_superscaffold{$agp_line[4]} = [@agp_line[0..2,5]];
  }
}
close AGP;

# analize the data
&query_on_multiple_anchors ();			# task 6
&multiple_queries_on_superscaffold ();		# tasks 1 & 2
&multiple_superscaffolds_on_anchor ();		# tasks 3 & 7

sub query_on_multiple_anchors {
  my @queries;
  for my $query (keys %query_to_anchor) {
    if (scalar (keys %{$query_to_anchor{$query}}) > 1) {
      push (@queries, [$query, [keys %{$query_to_anchor{$query}}]]);
    }
  }
  if (scalar (@queries) > 0) {
    print '=' x 80, "\n", "Each of the following queries has aligned to multiple anchors\n", '=' x 80, "\n";
    print "Query\tAnchors\n";
    print '-' x 80, "\n";
    for my $query (@queries) {
      print "$query->[0]\t", join (", ", @{$query->[1]}), "\n";
    }
    print "\n";
  }
}

sub multiple_queries_on_superscaffold {
  my $header_printed = 0;
  # map queries on superscaffolds
  my %superscaffold_to_query;	# superscaffold=>(query=>(start_contig, stop_contig))
  for my $query (keys %edge_contigs) {
    my $contig = $edge_contigs{$query}[0];
    my $superscaffold = $contig_to_superscaffold{$contig}[0];
    $superscaffold_to_query{$superscaffold}{$query} = $edge_contigs{$query};
  }

  for my $superscaffold (keys %superscaffold_to_query) {
    # look at superscaffolds with two or more queries
    if (scalar (keys %{$superscaffold_to_query{$superscaffold}}) > 1) {
      # find the queries that are on the same superscaffold and same anchor
      my %anchors;	# anchor=>([query, anchor_start, anchor_stop])
      for my $query (keys %{$superscaffold_to_query{$superscaffold}}) {
        for my $anchor (keys %{$query_to_anchor{$query}}) {
          push (@{$anchors{$anchor}}, [$query, @{$query_to_anchor{$query}{$anchor}}]);
        }
      }
      for my $anchor (keys %anchors) {
        # look at anchors with two or more queries
        if (scalar (@{$anchors{$anchor}}) > 1) {
          my (@queries, @anchor_start);
          for my $query_array (@{$anchors{$anchor}}) {
            push (@queries, [@{$query_array}]);
            push (@anchor_start, $query_array->[1]);
          }
          # sort queries by the start coordinates on the anchor
          my @print_lines;
          for my $start (sort {$a <=> $b} @anchor_start) {
            if ($header_printed++ == 0) {
              print '=' x 80, "\n", "Distance between queries in AGP v. BioNano map (coordinates for queries)\n", '=' x 80, "\n";
              print "Superscaffold\tQuery\tAGP_start\tAGP_stop\tAnchor_start\tAnchor_stop\tAnchor\n";
              print '-' x 80, "\n";
            }
            for my $query_array (@{$anchors{$anchor}}) {
              if ($query_array->[1] == $start) {
                push (@print_lines, [$query_to_superscaffold{$query_array->[0]}[0], $query_array->[0], @{$query_to_superscaffold{$query_array->[0]}}[1,2], @{$query_array}[1,2], $anchor]);
              }
            }
          }
            for my $i (0..$#print_lines) {
              if ($i > 0) {
                my ($agp_gap, $bn_gap) = ($print_lines[$i][2] - $print_lines[$i - 1][3] > 0 ? $print_lines[$i][2] - $print_lines[$i - 1][3] : $print_lines[$i - 1][2] - $print_lines[$i][3],
                                          $print_lines[$i][4] - $print_lines[$i - 1][5]);
                print "AGP_gap - BioNano_gap = $agp_gap - $bn_gap = ", $agp_gap - $bn_gap, "\n";
              }
              print join ("\t", @{$print_lines[$i]}), "\n";
            }
            print "\n";
        }
      }
    }
  }
}

sub multiple_superscaffolds_on_anchor {
  # find what superscaffolds are on each anchor
  my %anchor_to_superscaffold;	# anchor=>(superscaffold=>([Query, Anchor_start, Anchor_stop]))
  for my $anchor (keys %anchor_to_query) {
    for my $query (keys %{$anchor_to_query{$anchor}}) {
      my $contig = $edge_contigs{$query}[0];
      my $superscaffold = $contig_to_superscaffold{$contig}[0];
      push (@{$anchor_to_superscaffold{$anchor}{$superscaffold}}, [$query, @{$anchor_to_query{$anchor}{$query}}]);
    }
  }
  # look at anchors with multiple superscaffolds
  my @anchors;			# [anchor, superscaffold, query, anchor_start, anchor_stop]
  for my $anchor (keys %anchor_to_superscaffold) {
    if (scalar (keys %{$anchor_to_superscaffold{$anchor}}) > 1) {	# 2+ superscaffolds per anchor
      # sort by starting coordinates
      my (@start_coords, @superscaffolds);
      for my $superscaffold (keys %{$anchor_to_superscaffold{$anchor}}) {
        for my $coords (@{$anchor_to_superscaffold{$anchor}{$superscaffold}}) {
          push (@start_coords, $coords->[1]);
          push (@superscaffolds, [$superscaffold, @{$coords}]);
        }
      }
      for my $coord (sort {$a <=> $b} @start_coords) {
        for my $superscaffold (@superscaffolds) {
          push (@anchors, [$anchor, @{$superscaffold}]) if ($coord == $superscaffold->[2]);
        }
      }
      # add 'blank' line to separate anchors
      push (@anchors, [split (//, '' x 5)]);
    }
  }
  # print anchors with multiple superscaffolds
  if (scalar (@anchors) > 0) {
    print '=' x 80, "\n", "Multiple superscaffolds have aligned to the following anchors\n", '=' x 80, "\n";
    print "Anchor\tSuperscaffold\tQuery\tAnchor_start\tAnchor_stop\n";
    print '-' x 80, "\n";
    for my $line (@anchors) {
      print join ("\t", @{$line}), "\n";
    }
  }
}
