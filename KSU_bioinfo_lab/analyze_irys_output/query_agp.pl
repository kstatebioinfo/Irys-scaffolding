#!/usr/bin/perl

use strict;
use warnings;

# usage: ./query_agp.pl cmap_key scaffold_from_component.agp > bionano_query_from_component.agp
# usage: ./query_agp.pl Tcas_4_cmap_key tcas_scaffold_from_component.agp > bionano_query_from_component.agp

# load input files
open MAP, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
my @map = <MAP>;
chomp @map;
close MAP;

open AGP, '<', $ARGV[1] or die "Couldn't open $ARGV[1]: $!";
my @in_agp = <AGP>;
chomp @in_agp;
close AGP;

# read map file
for(@map) {
  unless(/^#/ || /^Chromosome/) {
    #my($scaffold_name, $query_id, $scaffold_start, $scaffold_stop) = (split)[2,4,6,7];
    my($scaffold_name, $query_id, $scaffold_start, $scaffold_stop) = (split)[0,1,3,4];
    # find in input AGP file
    my @scaffold;
    my($start, $stop);
    for(@in_agp) {
      unless(/^#/) {
        my @agp_line = split;
        if($agp_line[0] eq $scaffold_name) {
          # add AGP line to @scaffold
          push(@scaffold, \@agp_line);
          # find closest start, stop coordinates of a contig in input AGP file
          if($agp_line[4] eq "W") {
            if(!defined($start)) {
              $start = $agp_line[1];
              $stop = $agp_line[2];
            }
            else {
              if(abs($agp_line[1] - $scaffold_start) < abs($start - $scaffold_start)) {
                $start = $agp_line[1];
              }
              if(abs($agp_line[2] - $scaffold_stop) < abs($stop - $scaffold_stop)) {
                $stop = $agp_line[2];
              }
            }
          }
        }
      }
    }
    # output AGP for query from component
    my $part_number = 1;
    for my $i (0..$#scaffold) {
      if($scaffold[$i][1] >= $start && $scaffold[$i][2] <= $stop) {
        shift(@{$scaffold[$i]});
        $scaffold[$i][2] = $part_number++;
        print "Query$query_id\t", join("\t", @{$scaffold[$i]}), "\n";
      }
    }
  }
}
