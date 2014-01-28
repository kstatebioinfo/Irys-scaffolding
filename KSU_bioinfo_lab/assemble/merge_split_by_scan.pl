#!/bin/perl
##################################################################################
#   
#	USAGE: perl merge_split_by_scan.pl [bnx_dir] [reference] [p-value Threshold]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable maipulating of the full path
##################################################################################
##############                     get arguments                ##################
##################################################################################
my $bnx_dir = $ARGV[0];
my $ref = $ARGV[1];
my $T = $ARGV[2];
open (FLOWCELL_BNX_LIST, '>', "$bnx_dir/flowcell_bnx.txt") or die "can't open $bnx_dir/flowcell_bnx.txt !\n"; # create list of flowcell BNXs
open (FLOWCELL_BNX_SUMMARY, '>', "$bnx_dir/flowcell_summary.csv") or die "can't open $bnx_dir/flowcell_summary.csv !\n"; # create file for summary stats of flowcell BNXs
print FLOWCELL_BNX_SUMMARY "Filename,FP(/100kb),FNrate,bppSD,Maps,GoodMaps,GoodMaps/Maps\n";
##################################################################################
######### For each split and adjusted BNX from each orignal BNX file  ############
##################################################################################
opendir(DIR, "${bnx_dir}") or die "can't open ${bnx_dir}!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR))
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
    ####################################################################
    ##############   run refaligner to merge adjusted BNXs    ##########
    ####################################################################
    my $merging= `~/tools/RefAligner -if ${bnx_dir}/${filename}_adj_bnx_list.txt -o ${bnx_dir}/${filename}_adj_merged -merge -bnx -minsites 5 -minlen 150`;
    print "$merging";
    ####################################################################
    ######## run refaligner for flowcell molecule quality report  ######
    ####################################################################
    my $run_ref=`~/tools/RefAligner -i ${bnx_dir}/${filename}_adj_merged.bnx -o ${bnx_dir}/${filename}_adj_merged -bnx -minsites 5 -minlen 150 -BestRef 1 -M 2 -T ${T} -ref ${ref}`;
    print "$run_ref";
    print FLOWCELL_BNX_LIST "${bnx_dir}/${filename}_adj_merged.bnx\n"; # make final merge list
    ####################################################################
    ######## summarize flowcell molecule quality report .err values ####
    ####################################################################
    open (ERR,'<',"${bnx_dir}/${filename}_adj_merged.err") or die "can't open ${bnx_dir}/${filename}_adj_merged.err!\n";
    while (<ERR>)
    {
        if (eof)
        {
            my @values=split/\t/;
            for my $value (@values)
            {
                s/\s+//g;
            }
            if ($values[7] != 0)
            {
                my $map_ratio = $values[9]/$values[7];
                print FLOWCELL_BNX_SUMMARY "${bnx_dir}/${filename}_adj_merged.bnx,$values[1],$values[2],$values[11],$values[7],$values[9],$map_ratio\n";
            }
            else
            {
                print FLOWCELL_BNX_SUMMARY "${bnx_dir}/${filename}_adj_merged.bnx,bad flow cell 0 Maps\n";
            }
        }
    }
}




