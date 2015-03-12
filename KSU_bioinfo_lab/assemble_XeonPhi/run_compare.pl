#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl run_compare.pl <assembly working directory>
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: # Script replaces project_directory with the name of the working directory update other variables for project in "Project variables" section

#

#
# Example: perl run_compare.pl
#
###############################################################################
use strict;
use warnings;
#use File::Find::Rule;
# use List::Util qw(max);
# use List::Util qw(sum);
#
########################  Project variables  ########################

# Working directory without trailing slash
my $best_dir ="best assembly directory"; # no trailing slash
my $fasta = "fasta full path";
my $enzyme= "enzyme or enzymes"; # space separated list that can include BspQI BbvCI BsrDI bseCI
#bng_assembly="BNG_assembly_basename"
#FASTA_EXT="fasta_extension_without_dot"

my $f_con="13";
my $f_algn="30";
my $s_con="8";
my $s_algn="90";

# Strict alignments
my $strict_align_para ="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10";
# Relaxed alignments
my $relaxed_align_para="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15";

my $project="project_name";

########################  End project variables  ########################

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