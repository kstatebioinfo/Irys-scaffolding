#!/usr/bin/perl
################################################################################
#   
#	USAGE: perl rescale_stretch.pl <bnx_dir> <p_value Threshold> <project> <reference>
#
#  Created by jennifer shelton
#  perl rescale_stretch.pl $bnx_dir $reference $T $dirname
#
################################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
################################################################################
##############           Customize RefAligner Settings        ##################
################################################################################
# This pipeline was designed to run on a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization of this section may be required to run the BioNano Assembler on a different machine. Customization of Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/clusterArguments.xml may also be required for assembly to run successfully on a different cluster.
my $refaligner = $ENV{"HOME"} ."/tools/RefAligner"; # See "~/tools/RefAligner -help" for details about these parameters
unless (-f $refaligner)
{
    die "Can't find RefAligner at $refaligner. Please add correct path to rescale_stretch.pl and retry:\n $!";
}
my $maxmem = 240;
my $hashmaxmem = 120;
my $insertThreads = 16;
my $maxthreads = 64;
################################################################################
##############                 get arguments                  ##################
################################################################################
my $assembly_directory=$ARGV[0];
my $T=$ARGV[1];
my $project = $ARGV[2];
my $de_novo=1; # project is de novo
if ($ARGV[3])
{
    if (-f "$ARGV[3]")
    {
        $de_novo=0; # change project is not de novo because a refernce CMAP exists
        print "de_novo = false\n";
    }
}
else
{
    print "de_novo = true\n";
}
my $reference;
if($de_novo == 0)
{
    $reference = $ARGV[3];
    print "ref = $ARGV[3]\n";
}
my $dirname = dirname(__FILE__);
################################################################################
############         Adjust stretch (bpp) for BNX files       ##################
################################################################################
my $bnx_list_file = "${assembly_directory}/bnx_list.text"; #creat list to use in merging BNX files
open (my $bnx_list, ">", $bnx_list_file) or die "Can't open $bnx_list_file: $!";
my $bnx_dir = "$assembly_directory/bnx";
opendir(DIR, $bnx_dir) or die "Can't open $bnx_dir!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR))
{
    next if ($file =~ m/^\./); # ignore files beginning with a period
    next if ($file !~ m/Molecules.*\.bnx$/); # if the filename is Molecules.bnx
    ############################################################################
    ############              Check BNX file version          ##################
    ############################################################################
    my $bnx_stats=`perl ${dirname}/../map_tools/bnx_version.pl -i ${bnx_dir}/${file}`;
    print "$bnx_stats";
    $bnx_stats =~ /version: (.*)\n/;
    if ($1 < 1)
    {
        die "Exiting because this workflow was developed for BNX version 1.0+";
    }
    print $bnx_list "${bnx_dir}/${file}\n";
}
################################################################################
############                Merge your BNX files               #################
################################################################################
my $refalign_log_file = "${assembly_directory}/refAlign_log.txt"; #creat log for refAligner output
open (my $refalign_log, ">", $refalign_log_file) or die "Can't open $refalign_log_file: $!";

mkdir "${assembly_directory}/all_flowcells"; # Make an outout directory for merged flowcells

my $merge_bnxs = `$refaligner -if $bnx_list_file -o ${assembly_directory}/all_flowcells/bnx_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads $maxthreads`;
print $refalign_log "$merge_bnxs";
my $merged_file = "${bnx_dir}/../all_flowcells/bnx_merged.bnx";
if($de_novo == 0)
{
    ############################################################################
    ####         Subsample 50,000 molecules and run alignment with          ####
    ####         very loose alignment parameters (T should be about         ####
    ####                   inverse of the genome size).                     ####
    ############################################################################
    ## Subsample 50,000 molecules and run alignment with very loose alignment parameters.
    my $error_A = "${bnx_dir}/../all_flowcells/bnx_merged_errA";
    my $get_error_A = `$refaligner -o $error_A -i $merged_file -ref $reference -minlen 180 -minsites 9 -refine 0 -id 1 -mres 0.9 -res 3.4 -resSD 0.75 -FP 1.0 -FN 0.1 -sf 0.2 -sd 0 -sr 0.02 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 50000 -BestRef 1 -BestRefPV 1 -hashoffset 1 -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem $maxmem -hashmaxmem $hashmaxmem -insertThreads $insertThreads -maxthreads $maxthreads`; ## TEST when you get a reference !!!!!!!!
    print $refalign_log "#####\n#####\nStep 1: Subsample 50,000 molecules and run alignment with very loose alignment parameters\n#####\n#####\n";
    print $refalign_log "$get_error_A";

    ## The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.
    my $error_B = "${assembly_directory}/all_flowcells/bnx_merged_errB";

    my $get_error_B = `$refaligner -o $error_B -i $merged_file -ref $reference -readparameters ${error_A}_id1.errbin -minlen 180 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 100000 -BestRef 1 -BestRefPV 1 -hashoffset 1  -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem $maxmem -hashmaxmem $hashmaxmem -insertThreads $insertThreads  -maxthreads $maxthreads`;
    print $refalign_log "#####\n#####\nStep 2: The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.\n#####\n#####\n";

    print $refalign_log "$get_error_B";

    ## Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb.

    my $merged_file_adjusted = "${assembly_directory}/all_flowcells/bnx_merged_adj";

    #my $get_adjusted_bnx = `~/tools/RefAligner -o $merged_file_adjusted -i $merged_file -ref $reference -readparameters ${error_B}_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -AligneRes 1.5  -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64`; ## threw error unknown option:-AligneRes(argc=28)

    my $get_adjusted_bnx = `$refaligner -o $merged_file_adjusted -i $merged_file -ref $reference -readparameters ${error_B}_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem $maxmem -hashmaxmem $hashmaxmem -insertThreads $insertThreads  -maxthreads $maxthreads`;
    print $refalign_log "#####\n#####\nStep 3: Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb\n#####\n#####\n";
    print $refalign_log "$get_adjusted_bnx";

    ## Run final alignment for noise parameters .
    my $rescaled_file = "${bnx_dir}/../all_flowcells/bnx_merged_adj_rescaled.bnx";
    my $error_C = "${bnx_dir}/../all_flowcells/bnx_merged_rescaled_final";
    my $get_error_C = `$refaligner -o $error_C -i $rescaled_file -ref $reference -nosplit 2 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 100 -minsites 5 -T $T -insertThreads $insertThreads -maxthreads $maxthreads -randomize 1 -subset 1 10000`;
    print $refalign_log "#####\n#####\nStep 4: Subsample 10,000 molecules and run final alignment for noise parameters\n#####\n#####\n";
    print $refalign_log "$get_error_C";

    close($refalign_log);

    ############################################################################
    ####                      Plot rescaling factors by scan                ####
    ############################################################################
    #  scan=0:RunIndex=1,ScanNumber=0:scale=0.99938102
    open ($refalign_log, "<", $refalign_log_file) or die "Can't open $refalign_log_file: $!";

    my $rescaling_factor_list_out_file = "${assembly_directory}/${project}/bnx_rescaling_factors.tab";
    open (my $rescaling_factor_list_out, ">", $rescaling_factor_list_out_file) or die "Can't open $rescaling_factor_list_out_file in rescale_stretch.pl\n";
    print $rescaling_factor_list_out "flow_cell\tscan\tscale\n";
    my $scan_count=0;
    my $first_scans = '';
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
            if ($ScanNumber == 0)
            {
                $first_scans = $first_scans." ".$scan_count; # grab position of the first scan for each BNX file
            }
        }
    }

    my $command = "Rscript ${dirname}/plot_bnx_rescaling_factors.R ${assembly_directory}/${project}/bnx_rescaling_factors.tab ${assembly_directory}/${project}/bnx_rescaling_factors.pdf ${scan_count}${first_scans}";
    #print "Command: $command\n";
    my $get_rescaled_bnx = `$command`; # plot rescaling factor for each scan
    print "$get_rescaled_bnx";

    ############################################################################

    print "Done merging BNX files and rescaling molecule maps\n";
}
else
{
    print "Done merging BNX files\n";
}
