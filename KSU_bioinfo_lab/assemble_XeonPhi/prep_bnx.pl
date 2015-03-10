#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl prep_bnx.pl <assembly working directory>
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: Script makes links to all Molecules.bnx files in a common bnx directory and renames with auto-incremented numbers. Make paths absolute. Do not include trailing spaces in paths.

# Make an assembly working directory for a project. Transfer the "Datasets" directory transfered from the IrysView workspace to the assembly working directory for your project. The script then takes the path of the assembly working directory for your project as input and organizes the raw data in the correct format to run AssembleIrysXeonPhi.pl. The script also writes a key with the original file path and the new link for all BNX files.

#
# Example: perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble/prep_bnx.pl /home/irys/Data/Esch_coli_0000
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
my $assembly_directory=$ARGV[0];
my $i=1;
my $bnx_directory = "${assembly_directory}/bnx";
unless(mkdir $bnx_directory)
{
    print "Unable to create $assembly_directory\n";
}
###############################################################################
##############            Move and rename files              ##################
###############################################################################
#my @dir_array = ('/homes', grep -d, glob "$dataset_directory/*");
my $logfile = "$bnx_directory/bnx_key.txt";
open (LOG, ">", $logfile) or die "Can't open $logfile\n";
my $dataset_directory = "${assembly_directory}/Datasets";
opendir (DATA, $dataset_directory) or die "Can't open $dataset_directory. Transfer the Dataset directory from Irysview after generating the run report.\n";
print "Creating links to all Molecules.bnx files in a common bnx directory and renaming with auto-incremented numbers...\n";
while (my $entry = readdir DATA )
{
    if (-d "${dataset_directory}/${entry}")
    {
        unless (($entry eq '..') || ($entry eq '.'))
        {
            my $link = "$bnx_directory/Molecules_${i}.bnx";
            while (-e $link)
            {
                ++$i;
                $link = "$bnx_directory/Molecules_${i}.bnx";
                
            }
#            my $linked= `ln -s \'${dataset_directory}/${entry}/Molecules.bnx\' $link`; # code for new Datasets directories
            my $linked= `ln -s \'${dataset_directory}/${entry}/Detect Molecules/Molecules.bnx\' $link`; # code for older Datasets directories
            print "$linked";
            print LOG "Molecules_${i}.bnx\t${entry}\n";
            ++$i;
        }
        
    }
}


print "Done preping the working directory for AssembleIrysXeonPhi.pl\n";