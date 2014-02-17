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
############## Make output directory for flowcell outputs ##########
####################################################################
my $directory = "${bnx_dir}/all_flowcells";
unless(mkdir $directory)
{
    print "Unable to create $directory\n";
}
####################################################################
##############   run refaligner to merge adjusted BNXs    ##########
##############   for each flowcell                        ##########
####################################################################
my $merging= `/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -if ${bnx_dir}/flowcell_bnx.txt -o ${directory}/all_flowcells_adj_merged -merge -bnx -minsites 5 -minlen 150 -maxthreads 16`;
print "$merging";
####################################################################
##############   Third molecule quality report:           ##########
##############   test the final merged BNX with -BestRef  ##########
####################################################################
my @err_files;
my $third_mqr_b = `/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${directory}/all_flowcells_adj_merged.bnx -o ${directory}/all_flowcells_adj_merged_bestref -T ${T} -ref ${ref} -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5 -maxthreads 16`;
print "$third_mqr_b";
push (@err_files,"${directory}/all_flowcells_adj_merged_bestref.err");
####################################################################
##############   Third molecule quality report:           ##########
############## test the final merged BNX without -BestRef ##########
####################################################################
my $third_mqr = `/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${directory}/all_flowcells_adj_merged.bnx -o ${directory}/all_flowcells_adj_merged -T ${T} -ref ${ref} -nosplit 2 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -S -1000 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 150 -minsites 5 -maxthreads 16`;
print "$third_mqr";
push (@err_files,"${directory}/all_flowcells_adj_merged.err");
####################################################################
##############  Compare  molecule quality reports         ##########
##############  with and without -BestRef                 ##########
####################################################################
open (FLOWCELL_BNX_SUMMARY, '>', "$bnx_dir/bestref_effect_summary.csv") or die "can't open $bnx_dir/bestref_effect_summary.csv !\n"; # create file for summary stats of flowcell BNXs
print FLOWCELL_BNX_SUMMARY "Filename,FP(/100kb),FNrate,bppSD,Maps,GoodMaps,GoodMaps/Maps\n";
my $good_maps;
#my $bestref_value; # fill in when you find out which metric to test
#my $non_bestref_value; # fill in when you find out which metric to test
for my $file (@err_files)
{
    unless (open (ERR, '<',"$file"))
    {
        print "can't open $file!\n";
        next;
    }
    while (<ERR>)
    {
        if (/^ 4\t/)
        {
            my @other_values=split/\t/; # because the final good maps is reported as 0
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
            if ($values[7] != 0)
            {
                my $map_ratio = $good_maps/$values[7];
                print FLOWCELL_BNX_SUMMARY "$file,$values[1],$values[2],$values[11],$values[7],$good_maps,$map_ratio\n";
#                $bestref_value = ; # fill in when you find out which metric to test
#                $non_bestref_value = ; # fill in when you find out which metric to test
            }
            else
            {
                print FLOWCELL_BNX_SUMMARY "$file,bad flow cell 0 Maps\n";
            }
        }
    }
}

#if (($non_bestref_value >= $bestref_value+($bestref_value*.05) || ($non_bestref_value <= $bestref_value-($bestref_value*.05))
#{
#    print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
#    print "Warning: value of X has shifted by more than 5\% of it's oringinal value when molecules are mapped without \"-BestRef\" turned on. this may indicate that your p-value threshold \"-T\" is too lax.\n"
#} # fill in when you find out which metric to test

