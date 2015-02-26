#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl prep_bnx.pl <dataset directory> <bnx directory>
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: Script makes links to all Molecules.bnx files in a common bnx directory and renames with auto-incremented numbers. Make paths absolute. Do not include trailing spaces in paths.

# The script takes the path to the "Datasets" directory transfered from the IrysView workspace and the new BNX directory name. This organizes the raw data in the correct format to run AssembleIrysXeonPhi.pl. The script also write a key with the original file path and the new link.

#
# Example: perl /home/irys/Data/Irys-scaffolding/KSU_bioinfo_lab/assemble/prep_bnx.pl /home/irys/Data/Esch_coli_0000/Datasets /home/irys/Data/Esch_coli_0000/bnx
#
###############################################################################
use strict;
use warnings;
#use File::Find::Rule;
# use List::Util qw(max);
# use List::Util qw(sum);
#
#
###############################################################################
##############                 get arguments                 ##################
###############################################################################
my $dataset_directory=$ARGV[0];
my $i=1;
my $directory = $ARGV[1];
unless(mkdir $directory)
{
    print "Unable to create $directory\n";
}
###############################################################################
##############            Move and rename files              ##################
###############################################################################
#my @dir_array = ('/homes', grep -d, glob "$dataset_directory/*");
my $logfile = "$directory/bnx_key.txt";
open (LOG, ">", $logfile) or die "Can't open $logfile\n";
opendir (DATA, $dataset_directory) or die "Can't open $dataset_directory\n";
print "Creating links to all Molecules.bnx files in a common bnx directory and renaming with auto-incremented numbers...\n";
while (my $entry = readdir DATA )
{
    if (-d "${dataset_directory}/${entry}")
    {
        unless (($entry eq '..') || ($entry eq '.'))
        {
            my $link = "$directory/Molecules_${i}.bnx";
            while (-e $link)
            {
                ++$i;
                $link = "$directory/Molecules_${i}.bnx";
                
            }
            my $linked= `ln -s \'${dataset_directory}/${entry}/Molecules.bnx\' $link`; # code for new Datasets directories
            #            print "ln -s \'${dataset_directory}/${entry}/Detect Molecules/Molecules.bnx\' $link\n"; # code for older Datasets directories
            print "$linked";
            print LOG "Molecules_${i}.bnx\t${entry}\n";
            ++$i;
        }
        
    }
}

print "Done\n";