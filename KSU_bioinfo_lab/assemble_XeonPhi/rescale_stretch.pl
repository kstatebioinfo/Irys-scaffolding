#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl rescale_stretch.pl <bnx_dir> <reference> <p_value Threshold> <project>
#
#  Created by jennifer shelton
#  perl rescale_stretch.pl $bnx_dir $reference $T $dirname
#
##################################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                 get arguments                    ##################
##################################################################################
my $bnx_dir=$ARGV[0];
my $reference=$ARGV[1];
my $T=$ARGV[2];
my $project = $ARGV[3];
my $dirname = dirname(__FILE__);
###################################################################################
############          Adjust stretch (bpp) for BNX files         ##################
###################################################################################
my $bnx_list_file = "${bnx_dir}/../bnx_list.text"; #creat list to use in merging BNX files
open (my $bnx_list, ">", $bnx_list_file) or die "Can't open $bnx_list_file: $!";
opendir(DIR, $bnx_dir) or die "Can't open $bnx_dir!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR))
{
    next if ($file =~ m/^\./); # ignore files beginning with a period
    next if ($file !~ m/Molecules.*\.bnx$/); # if the filename is Molecules.bnx
    
    ###################################################################################
    ############              Check BNX file version                 ##################
    ###################################################################################
    my $bnx_stats=`perl ${dirname}/../map_tools/bnx_version.pl -i ${bnx_dir}/${file}`;
    print "$bnx_stats";
    $bnx_stats =~ /version: (.*)\n/;
    if ($1 < 1)
    {
        die "Exiting because this workflow was developed for BNX version 1.0+";
    }
    print $bnx_list "${bnx_dir}/${file}\n";
}

###################################################################################
############                Merge your BNX files                 ##################
###################################################################################
my $refalign_log_file = "${bnx_dir}/../refAlign_log.txt"; #creat log for refAligner output
open (my $refalign_log, ">", $refalign_log_file) or die "Can't open $refalign_log_file: $!";

mkdir "${bnx_dir}/../all_flowcells"; # Make an outout directory for merged flowcells

my $merge_bnxs = `~/tools/RefAligner -if $bnx_list_file -o ${bnx_dir}/../all_flowcells/bnx_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads 64`;
print $refalign_log "$merge_bnxs";

###################################################################################
####         Subsample 50,000 molecules and run alignment with                 ####
####         very loose alignment parameters (T should be about                ####
####                   inverse of the genome size).                            ####
###################################################################################

## Subsample 50,000 molecules and run alignment with very loose alignment parameters (T should be about inverse of the genome size).
my $merged_file = "${bnx_dir}/../all_flowcells/bnx_merged.bnx";
my $error_A = "${bnx_dir}/../all_flowcells/bnx_merged_errA";
my $get_error_A = `~/tools/RefAligner -o $error_A -i $merged_file -ref $reference -minlen 180 -minsites 9 -refine 0 -id 1 -mres 0.9 -res 3.4 -resSD 0.75 -FP 1.0 -FN 0.1 -sf 0.2 -sd 0 -sr 0.02 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T $T -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 50000 -BestRef 1 -BestRefPV 1 -hashoffset 1 -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16 -maxthreads 64`; ## TEST when you get a reference !!!!!!!!
print $refalign_log "Step 1: Subsample 50,000 molecules and run alignment with very loose alignment parameters (T should be about inverse of the genome size)\n";


print $refalign_log "$get_error_A";

## The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.
my $error_B = "${bnx_dir}/../all_flowcells/bnx_merged_errB";

my $get_error_B = `~/tools/RefAligner -o $error_B -i $merged_file -ref $reference -readparameters ${error_A}_id1.errbin -minlen 180 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 100000 -BestRef 1 -BestRefPV 1 -hashoffset 1  -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64`;
print $refalign_log "Step 2: The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.\n";

print $refalign_log "$get_error_B";

## Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb.

my $merged_file_adjusted = "${bnx_dir}/../all_flowcells/bnx_merged_adj";

#my $get_adjusted_bnx = `~/tools/RefAligner -o $merged_file_adjusted -i $merged_file -ref $reference -readparameters ${error_B}_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -AligneRes 1.5  -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64`; ## threw error unknown option:-AligneRes(argc=28)

my $get_adjusted_bnx = `~/tools/RefAligner -o $merged_file_adjusted -i $merged_file -ref $reference -readparameters ${error_B}_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64`;
print $refalign_log "Step 3: Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb\n";
print $refalign_log "$get_adjusted_bnx";

close($refalign_log);

###################################################################################
####                          Plot rescaling factors by scan                   ####
###################################################################################
#  scan=0:RunIndex=1,ScanNumber=0:scale=0.99938102
open ($refalign_log, "<", $refalign_log_file) or die "Can't open $refalign_log_file: $!";

my $rescaling_factor_list_out_file = "${bnx_dir}/../${project}/bnx_rescaling_factors.tab";
open (my $rescaling_factor_list_out, ">", $rescaling_factor_list_out_file) or die "Can't open $rescaling_factor_list_out_file in rescale_stretch.pl\n";
print $rescaling_factor_list_out "flow_cell\tscan\tscale\n";
my $scan_count=0;
while (<$refalign_log>) # grab rescaling factor for each scan from RefAlign log
{
    chomp;
    if (/scan=(.*):RunIndex=(.*),ScanNumber=(.*):scale=(.*)/)
    {
        my $scan = $1;
        my $RunIndex = $2;
        my $ScanNumber = $3;
        my $scale = $4;
        print $rescaling_factor_list_out "$RunIndex\t$ScanNumber\t$scale\n";
        ++$scan_count;
    }
}
my $get_rescaled_bnx = `Rscript ${dirname}/plot_bnx_rescaling_factors.R ${bnx_dir}/../${project}/bnx_rescaling_factors.tab ${bnx_dir}/../${project}/bnx_rescaling_factors.pdf $scan_count`; # plot rescaling factor for each scan
print "$get_rescaled_bnx";

##############################################################################

print "Done rescaling stretch\n";

#### $ cd /home/irys; /home/irys/tools/RefAligner -ref /home/irys/data/Gram_nega_2014_055/Gram_nega_2014_055_2_2015-02-16_11_41/Irys_S1_SL3XI_BspQI.cmap -i /home/irys/data/Gram_nega_2014_055/Gram_nega_2014_055_2_2015-02-16_11_41/output/contigs/exp_refineFinal1/EXP_REFINEFINAL1.cmap -o /home/irys/data/Gram_nega_2014_055/Gram_nega_2014_055_2_2015-02-16_11_41/output/contigs/exp_refineFinal1/alignref_final/EXP_REFINEFINAL1 -stdout -stderr -maxthreads 228 -output-veto-filter _intervals.txt$ -res 2.9 -FP 0.6 -FN 0.06 -sf 0.20 -sd 0.10 -extend 1 -outlier 0.0001 -endoutlier 0.001 -deltaX 12 -deltaY 12 -xmapchim 14 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -T 1e-10 -indel -rres 1.2 -f -maxmem 256 -BestRef 1
