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
open (FLOWCELL_BNX_LIST, '>>', "$bnx_dir/flowcell_bnx.txt") or die "can't open $bnx_dir/flowcell_bnx.txt !\n"; # create list of flowcell BNXs
open (FLOWCELL_BNX_SUMMARY, '>', "$bnx_dir/flowcell_summary.csv") or die "can't open $bnx_dir/flowcell_summary.csv !\n"; # create file for summary stats of flowcell BNXs
print FLOWCELL_BNX_SUMMARY "Filename,FP(/100kb),FNrate,bpp,bppSD,Maps,GoodMaps,GoodMaps/Maps\n";
##################################################################################
######### For each split and adjusted BNX from each orignal BNX file  ############
##################################################################################
#opendir(DIR, "${bnx_dir}") or die "can't open ${bnx_dir}!\n"; # open directory full of .bnx files
unless (opendir(DIR, "${bnx_dir}"))
{
	print "can't open ${bnx_dir}!\n"; # open directory full of .bnx files

	next;
}
while (my $file = readdir(DIR))
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
    ####################################################################
    ##############   Run refaligner to merge adjusted BNXs    ##########
    ####################################################################
    my $merging= `/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -if ${bnx_dir}/${filename}_adj_bnx_list.txt -o ${bnx_dir}/${filename}/${filename}_adj_merged -merge -bnx -minsites 5 -minlen 150 -maxthreads 16`;
    print "$merging";
    ####################################################################
    ######## Second molecule quality report:                      ######
    ######## run refaligner for flowcell molecule quality report  ######
    ####################################################################
    my $run_ref=`/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${bnx_dir}/${filename}/${filename}_adj_merged.bnx -o ${bnx_dir}/${filename}/${filename}_adj_merged  -T ${T} -ref ${ref} -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5 -maxthreads 16 -xmapchim 1`;
    print "$run_ref";
    print FLOWCELL_BNX_LIST "${bnx_dir}/${filename}/${filename}_adj_merged.bnx\n"; # make final merge list
    ####################################################################
    ######## summarize flowcell molecule quality report .err values ####
    ####################################################################
    unless (open (ERR, '<',"${bnx_dir}/${filename}/${filename}_adj_merged.err"))
    {
        print "can't open ${bnx_dir}/${filename}/${filename}_adj_merged.err!\n";
        next;
    }
    my $good_maps;
    while (<ERR>)
    {
        my @other_values;
        if (/^ 4\t/)
        {
            @other_values=split/\t/; # because the final good maps is always reported as 0
            $other_values[9] =~ s/\s+//g;
            $good_maps=$other_values[9];
        }
        elsif (eof)
        {
            my @values=split/\t/;
            for my $value (@values)
            {
                s/\s+//g;
            }
            ##########################################################
            ######## Test if bpp has returned to ~500 as expected ####
            ##########################################################
            unless ((497<$values[5])&&($values[5]<503))
            {
                print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
                print "Warning: bpp, $values[5], is not ~500 for flowcell ${filename}_adj_merged.bnx\n";
            }
            ##########################################################
            ######## Test if bppSD value is high after merging    ####
            ##########################################################
            if ($values[11]>19)
            {
                print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
                print "Warning: bppSD, $values[11], is higher than 19 for flowcell ${filename}_adj_merged.bnx\n";
            }
            if ((15<$values[11])&&($values[11]<20))
            {
                print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
                print "Warning: bppSD, $values[11], is higher than 15 for flowcell ${filename}_adj_merged.bnx\n";
            }

            ##########################################################
            ######## Print out quality metrics for all flowcells  ####
            ##########################################################
            if ($values[7] != 0)
            {
                my $map_ratio = $good_maps/$values[7];
                print FLOWCELL_BNX_SUMMARY "${bnx_dir}/${filename}/${filename}_adj_merged.bnx,$values[1],$values[2],$values[5],$values[11],$values[7],$good_maps,$map_ratio\n";
            }
            else
            {
                print FLOWCELL_BNX_SUMMARY "${bnx_dir}/${filename}/${filename}_adj_merged.bnx,bad flow cell 0 Maps\n";
            }
        }
    }
}
print "done\n";



