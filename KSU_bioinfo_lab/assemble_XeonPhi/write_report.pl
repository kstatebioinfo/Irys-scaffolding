#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl write_report.pl
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: # Copy script into assembly working directory and update other variables for project in "Project variables" section. To do this cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP and the best alignment (Default or Relaxed).
# REQUIREMENTS: Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory. Also requires BioPerl.
#
# Example: perl write_report.pl
#
###############################################################################
use strict;
use warnings;
#use File::Find::Rule;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable manipulating of the full path
#####################################################################
########################  Project variables  ########################
#####################################################################
# Full path of the directory of the best assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 )
#############################################
####  Default or Relaxed alignments
my $alignment_parameters="default_alignment";
#my $alignment_parameters="relaxed_alignment";
#############################################
my $best_dir ="best assembly directory"; # no trailing slash
my $fasta = "fasta full path";
my $cmap = "reference cmap full path";
my $enzyme= "enzyme or enzymes"; # space separated list that can include BspQI BbvCI BsrDI bseCI
my $f_con="20";
my $f_algn="40";
my $s_con="15";
my $s_algn="90";
my $T = 1e-8;
my $project="project_name";
my $optional_assembled_cmap = ''; # add assembled cmap path here if it is not in the "refineFinal1" subdirectory within the "contigs" subdirectory of the best assembly directory
#########################################################################
########################  End project variables  ########################
#########################################################################

###########################################################
#            Get genome map CMAP file (fullpath)
###########################################################
my $genome_map_cmap;
unless($optional_assembled_cmap)
{
    $genome_map_cmap = `ls ${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap`;
    chomp($genome_map_cmap);
}
else
{
    $genome_map_cmap = $optional_assembled_cmap;
}
###########################################################
#          Sanity check project variables section
###########################################################
unless(( -f $fasta) && ( -f $cmap) && (-f $genome_map_cmap))
{
    die "File paths in the \"Project variables\" section of write_report.pl are not valid. Remember to copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP and the best alignment (Default or Relaxed).\n";
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "Enzymes listed in the \"Project variables\" section of write_report.pl are not valid. Valid entries would be a space separated list that includes one or more of the following options \"BspQI BbvCI BsrDI bseCI\". Remember to copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP and the best alignment (Default or Relaxed).\n";
}

my $report_dir = "$best_dir/../$project";

mkdir "$report_dir/BioNano_consensus_cmap";
unless (-d "$report_dir/BioNano_consensus_cmap")
{
    die "Can't create $report_dir/BioNano_consensus_cmap/";
}
mkdir "$report_dir/in_silico_cmap";
unless (-d "$report_dir/in_silico_cmap")
{
    die "Can't create $report_dir/in_silico_cmap/";
}
mkdir "$report_dir/align_in_silico_xmap";
unless (-d "$report_dir/align_in_silico_xmap")
{
    die "Can't create $report_dir/align_in_silico_xmap/";
}
mkdir "$report_dir/super_scaffold";
unless (-d "$report_dir/super_scaffold")
{
    die "Can't create $report_dir/super_scaffold/";
}
mkdir "$report_dir/align_in_silico_super_scaffold_xmap";
unless (-d "$report_dir/align_in_silico_super_scaffold_xmap")
{
    die "Can't create $report_dir/align_in_silico_super_scaffold_xmap/";
}
