#!/bin/perl
##################################################################################
#   
#	USAGE: perl third_mqr.pl [bnx_dir] [reference] [p-value Threshold]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                     get arguments                ##################
##################################################################################
my $bnx_dir = $ARGV[0];
my $ref = $ARGV[1];
my $T = $ARGV[2];
####################################################################
##############   run refaligner to merge adjusted BNXs    ##########
##############   for each flowcell                        ##########
####################################################################
my $merging= `~/tools/RefAligner -if ${bnx_dir}/flowcell_bnx.txt -o ${bnx_dir}/all_flowcells_adj_merged -merge -bnx -minsites 5 -minlen 150`;
print "$merging";
####################################################################
##############   Third molecule quality report:           ##########
##############   test the final merged BNX with -BestRef  ##########
####################################################################
my @err_files;
my $third_mqr_b = `~/tools/RefAligner -i ${bnx_dir}/all_flowcells_adj_merged.bnx -o ${bnx_dir}/all_flowcells_adj_merged_bestref -T ${T} -ref ${ref} -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5`;
print "$third_mqr_b";
push (@err_files,"${bnx_dir}/all_flowcells_adj_merged_bestref.err");
####################################################################
##############   Third molecule quality report:           ##########
############## test the final merged BNX without -BestRef ##########
####################################################################
my $third_mqr = `~/tools/RefAligner -i ${bnx_dir}/all_flowcells_adj_merged.bnx -o ${bnx_dir}/all_flowcells_adj_merged -T ${T} -nosplit 2 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5`;
print "$third_mqr";
push (@err_files,"${bnx_dir}/all_flowcells_adj_merged.err")
####################################################################
##############  Compare  molecule quality reports         ##########
##############  with and without -BestRef                 ##########
####################################################################
open (FLOWCELL_BNX_SUMMARY, '>', "$bnx_dir/bestref_effect_summary.csv") or die "can't open $bnx_dir/flowcell_summary.csv !\n"; # create file for summary stats of flowcell BNXs
print FLOWCELL_BNX_SUMMARY "Filename,FP(/100kb),FNrate,bppSD,Maps,GoodMaps,GoodMaps/Maps\n";
for my $file (@err_files)
{
    open (ERR,'<',"$file") or die "can't open $file!\n";
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

