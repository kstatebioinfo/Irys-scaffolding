#!/usr/bin/perl
#################################################################################
#
# USAGE: perl plot_bpp.pl <bbp_list.txt>
# Script outputs PDF plot of bpp per scan
#  Created by jennifer shelton 10/16/14
#
#################################################################################
use strict;
use warnings;
# use IO::File;
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
# use List::Util qw(max);
# use List::Util qw(sum);

my $bbp_list_file = $ARGV[0];

open ( my $bpp_list, "<", $bbp_list_file) or die "Can't open $bbp_list_file in plot_bpp.pl\n";
my @bpp_table;
while (<$bpp_list>)
{
    chomp;
    /.*\/Molecules_.*\/Molecules_(.*)_(.*).err\t(.*)/;
    my ($flow_cell,$scan,$bpp) = ($1,$2,$3);
    my @scan_info = ($flow_cell,$scan,$bpp);
    push (@bpp_table,[@scan_info]);
    
#    print "X${flow_cell}X X${scan}X $bpp\n"
    
}

my @bpp_table_sorted = sort {
    
    $a->[0] <=> $b->[0] || # the result is -1,0,1 ...
    $a->[1] <=> $b->[1]    # so [1] when [0] is same
    
} @bpp_table;

my $bbp_list_out_file = "${bbp_list_file}_sorted.tab";
open (my $bbp_list_out, ">", $bbp_list_out_file) or die "Can't open $bbp_list_out_file in plot_bpp.pl\n";
print $bbp_list_out "flow_cell\tscan\tbpp\n";

print $bbp_list_out (join("\t", @$_), "\n") for @bpp_table_sorted;