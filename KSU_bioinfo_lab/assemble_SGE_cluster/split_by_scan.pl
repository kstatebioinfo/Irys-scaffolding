#!/bin/perl
##################################################################################
#   
#	USAGE: perl split_by_scan.pl [bnx directory]
#
#  Created by jennifer shelton
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
##################################################################################
##############                    split by scan                 ##################
##################################################################################
opendir(DIR, $bnx_dir) or die "can't open $bnx_dir!\n"; # open directory full of .bnx files
while (my $file = readdir(DIR)) 
{
	next if ($file =~ m/^\./); # ignore files beginning with a period
	next if ($file !~ m/\.bnx$/); # ignore files not ending with a period
    my ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell,$CurrentScanNumber);
    my @headers;
    my $scan=1;
    my $line_count=1;
	my (${filename}, ${directories}, ${suffix}) = fileparse($file,'\..*');
	open (WHOLE_BNX, '<', "${bnx_dir}/${file}") or die "can't open ${bnx_dir}/${file}!\n";
	while (<WHOLE_BNX>)
	{
        ####################################################################
        ##############   make array of the header lines   ##################
        ####################################################################
        
        if (/^#/)
        {
        	if (($line_count == 1) && ($_ !~ /# BNX File Version:\t1/))
        	{
        	 	die "BNX version is not 1!!!\n";
        	}
        	else
        	{
            		push (@headers,$_);
            		++ $line_count;
        	}
        }
        elsif (/^0/)
        {
            if (!$ScanNumber)
            {
                ##############################################################
                ########  make directory for the first split bnxs ############
                ##############################################################
                unless(-e "${bnx_dir}/${filename}")
                {
                    mkdir "${bnx_dir}/${filename}";
                }
                open (SCAN_BNX, '>',"${bnx_dir}/${filename}/${filename}_${scan}.bnx") or die "couldn't open ${bnx_dir}/${filename}/${filename}_${scan}.bnx!\n";
               for my $head (@headers)
               {
                   print SCAN_BNX "$head";
               }
                print SCAN_BNX;
            }
            ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell)=split /\t/;
            $ScanNumber =~ s/\s+//g;
            if (($CurrentScanNumber)&&($ScanNumber==$CurrentScanNumber))
            {
                print SCAN_BNX;
            }
            ##############################################################
            ####  make bnx file for split bnxs when scan changes  ########
            ##############################################################
            if (($CurrentScanNumber)&&($ScanNumber != $CurrentScanNumber))
            {
                ++$scan;
                open (SCAN_BNX, '>',"${bnx_dir}/${filename}/${filename}_${scan}.bnx") or die "couldn't open ${bnx_dir}/${filename}/${filename}_${scan}.bnx!\n";
                for my $head (@headers)
                {
                    print SCAN_BNX "$head";
                }
                print SCAN_BNX;
            }
            $CurrentScanNumber=$ScanNumber; # define last scan number

        }
        else
        {
            print SCAN_BNX; # print the other four lines
        }
	}
}
