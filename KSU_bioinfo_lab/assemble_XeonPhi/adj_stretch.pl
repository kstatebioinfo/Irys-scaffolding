#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl adj_stretch.pl <bnx_dir> <reference> <p_value Threshold> <script directory>
#
#  Created by jennifer shelton
#  perl adj_stretch.pl $bnx_dir $reference $T $dirname
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
my $dirname=$ARGV[3];
###################################################################################
############          Adjust stretch (bpp) for BNX files         ##################
###################################################################################

opendir(DIR, $bnx_dir) or die "can't open $bnx_dir!\n"; # open directory full of .bnx files
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
    
    ###################################################################################
    ############                Merge your BNX files                 ##################
    ###################################################################################
 
    ~/tools/RefAligner -if sample_dir/bnx_list.txt -o sample_dir/bnx_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads 16
        
        # Subsample 50,000 molecules and run alignment with very loose alignment parameters (T should be about inverse of the genome size).
        
        ~/tools/RefAligner -o sample_dir/bnx_merged_errA -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -minlen 180 -minsites 9 -refine 0 -id 1 -mres 0.9 -res 3.4 -resSD 0.75 -FP 1.0 -FN 0.1 -sf 0.2 -sd 0 -sr 0.02 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 50000 -BestRef 1 -BestRefPV 1 -hashoffset 1 -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16 -maxthreads 64
        
        # The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.
        
        ~/tools/RefAligner -o sample_dir/bnx_merged_errB -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -readparameters sample_dir/bnx_merged_errA_id1.errbin -minlen 180 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 100000 -BestRef 1 -BestRefPV 1 -hashoffset 1  -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64
        
        # Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb.
        
        ~/tools/RefAligner -o sample_dir/bnx_merged_adj -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -readparameters sample_dir/bnx_merged_errB_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -AligneRes 1.5  -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64

}


#${bnx_dir}/${file}
#    
#    my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');

###################################################################################
###############                    split by scan                 ##################
###################################################################################
#opendir(DIR, $bnx_dir) or die "can't open $bnx_dir!\n"; # open directory full of .bnx files
#while (my $file = readdir(DIR)) 
#{
#	next if ($file =~ m/^\./); # ignore files beginning with a period
#	next if ($file !~ m/Molecules.*\.bnx$/); # if the filename is Molecules.bnx
#    my ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell,$CurrentScanNumber);
#    my @headers;
#    my $scan=1;
#    my $line_count=1;
#	my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
#	open (WHOLE_BNX, '<', "${bnx_dir}/${file}") or die "can't open ${bnx_dir}/${file}!\n";
#	while (<WHOLE_BNX>)
#	{
#        ####################################################################
#        ##############   make array of the header lines   ##################
#        ####################################################################
#        
#        if (/^#/)
#        {
#        	if (($line_count == 1) && ($_ !~ /# BNX File Version:\t1/))
#        	{
#        	 	die "BNX version is not 1!!!\n";
#        	}
#        	else
#        	{
#            		push (@headers,$_);
#            		++ $line_count;
#        	}
#        }
#        elsif (/^0/)
#        {
#            if (!$ScanNumber)
#            {
#                ##############################################################
#                ########  make directory for the first split bnxs ############
#                ##############################################################
#                unless(-e "${bnx_dir}/${filename}")
#                {
#                    mkdir "${bnx_dir}/${filename}";
#                }
#                open (SCAN_BNX, '>',"${bnx_dir}/${filename}/${filename}_${scan}.bnx") or die "couldn't open ${bnx_dir}/${filename}/${filename}_${scan}.bnx!\n";
#               for my $head (@headers)
#               {
#                   print SCAN_BNX "$head";
#               }
#                print SCAN_BNX;
#            }
#            ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell)=split /\t/;
#            $ScanNumber =~ s/\s+//g;
#            if (($CurrentScanNumber)&&($ScanNumber==$CurrentScanNumber))
#            {
#                print SCAN_BNX;
#            }
#            ##############################################################
#            ####  make bnx file for split bnxs when scan changes  ########
#            ##############################################################
#            if (($CurrentScanNumber)&&($ScanNumber != $CurrentScanNumber))
#            {
#                ++$scan;
#                open (SCAN_BNX, '>',"${bnx_dir}/${filename}/${filename}_${scan}.bnx") or die "couldn't open ${bnx_dir}/${filename}/${filename}_${scan}.bnx!\n";
#                for my $head (@headers)
#                {
#                    print SCAN_BNX "$head";
#                }
#                print SCAN_BNX;
#            }
#            $CurrentScanNumber=$ScanNumber; # define last scan number
#
#        }
#        else
#        {
#            print SCAN_BNX; # print the other four lines
#        }
#	}
#}
print "done\n";