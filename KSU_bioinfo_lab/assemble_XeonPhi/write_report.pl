#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl write_report.pl
#
#  Created by Jennifer Shelton 4/09/15
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
    $genome_map_cmap = glob "${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap";
}
else
{
    $genome_map_cmap = $optional_assembled_cmap;
}
my (${genome_map_filename}, ${genome_map_directories}, ${genome_map_suffix}) = fileparse($genome_map_cmap,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
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
###########################################################
#          Check that report directory already exists
###########################################################
my $report_dir = "$best_dir/../$project";
unless (-d "$report_dir")
{
    die "Exiting because $report_dir does not exist\n";
}
###########################################################
#          Prepare: BioNano_consensus_cmap
###########################################################
mkdir "$report_dir/BioNano_consensus_cmap";
unless (-d "$report_dir/BioNano_consensus_cmap")
{
    die "Can't create $report_dir/BioNano_consensus_cmap/";
}
link ($genome_map_cmap, "$report_dir/BioNano_consensus_cmap/${genome_map_filename}.cmap") or warn "Can't link $genome_map_cmap to $report_dir/BioNano_consensus_cmap/${genome_map_filename}.cmap: $!";
###########################################################
#          Prepare: in_silico_cmap
###########################################################
mkdir "$report_dir/in_silico_cmap";
unless (-d "$report_dir/in_silico_cmap")
{
    die "Can't create $report_dir/in_silico_cmap/";
}
my (${cmap_filename}, ${cmap_directories}, ${cmap_suffix}) = fileparse($cmap,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
link ($cmap,"$report_dir/in_silico_cmap/${cmap_filename}.cmap" ) or die "Can't link $cmap to $report_dir/in_silico_cmap/${cmap_filename}.cmap: $!";
if (-f "${cmap_directories}${cmap_filename}_key.txt")
{
    link ("${cmap_directories}${cmap_filename}_key.txt","$report_dir/in_silico_cmap/${cmap_filename}_key.txt" or die "Can't link ${cmap_directories}${cmap_filename}_key.txt to $report_dir/in_silico_cmap/${cmap_filename}_key.txt: $!";
}
else
{
    die "Error you are missing a key to your in silico reference CMAP in the same directory as $cmap. Create a new CMAP with ~/bin/fa2cmap_multi.pl and try again.\n";
}
###########################################################
#          Prepare: align_in_silico_xmap
###########################################################
mkdir "$report_dir/align_in_silico_xmap";
unless (-d "$report_dir/align_in_silico_xmap")
{
    die "Can't create $report_dir/align_in_silico_xmap/";
}
my $in_silico_align_dir_path = "$best_dir/..";
opendir (my $in_silico_align_dir, $in_silico_align_dir_path) or die "Can't open $in_silico_align_dir_path: $!";
my $prefix;
for my $file (readdir $in_silico_align_dir)
{
    if ($file =~ /_filtered\.xmap/)
    {
        link ("$in_silico_align_dir_path/$file","$report_dir/align_in_silico_xmap/$file") or die "Can't link $in_silico_align_dir_path/$file to $report_dir/align_in_silico_xmap/$file : $!"; # make a hard link for the filtered XMAP file
    }
    elsif ($file =~ /\.xmap/)
    {
        $file =~ /(.*)\.xmap/; # grab the unfiltered XMAP file prefix
        $prefix = $1;
    }
}
my @in_silico_aligns = glob "${prefix}*"
for my $file (@in_silico_aligns)
{
    link ("$in_silico_align_dir_path/$file","$report_dir/align_in_silico_xmap/$file") or die "Can't link $in_silico_align_dir_path/$file to $report_dir/align_in_silico_xmap/$file : $!"; # make a hard link for the unfiltered XMAP file and all supporting files (required by IrysView)
}

#mkdir "$report_dir/super_scaffold";
#unless (-d "$report_dir/super_scaffold")
#{
#    die "Can't create $report_dir/super_scaffold/";
#}
#mkdir "$report_dir/align_in_silico_super_scaffold_xmap";
#unless (-d "$report_dir/align_in_silico_super_scaffold_xmap")
#{
#    die "Can't create $report_dir/align_in_silico_super_scaffold_xmap/";
#}
#my $compress = `cd ${best_dir}; tar -czvf ${project}.tar.gz $project`;
#print $compress;

