#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl write_report.pl
#
#  Created by Jennifer Shelton 4/09/15
#
# DESCRIPTION: # Copy script into assembly working directory and update other variables for project in "Project variables" section. To do this cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP and the best alignment (Default or Relaxed).
# REQUIREMENTS: Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory.
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
#############################################
####  Default or Relaxed alignments
my $alignment_parameters="default_alignment";
#my $alignment_parameters="relaxed_alignment";
#############################################
# Full path of the directory of the best assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 )
my $best_dir ="/home/bionano/bionano/Leis_mani_2014_049_final/strict_t_150"; # no trailing slash
my $fasta = "/home/bionano/bionano/Leis_mani_2014_049_final/GCF_000227135_wrapped.fasta";
my $cmap = "/home/bionano/bionano/Leis_mani_2014_049_final/GCF_000227135_wrapped_BbvCI.cmap";
my $enzyme= "BbvCI"; # space separated list that can include BspQI BbvCI BsrDI bseCI
my $f_con="20";
my $f_algn="40";
my $s_con="15";
my $s_algn="90";
my $T = 1e-8;
my $project="Leis_mani_2014_049";
#########################################################################
########################  End project variables  ########################
#########################################################################

#########################################################################
####################  Optional project variables  #######################
#########################################################################
my $optional_assembled_cmap = ''; # add assembled cmap path here if it is not in the "refineFinal1" subdirectory within the "contigs" subdirectory of the best assembly's parent directory
my $optional_assembly_optArguments_xml = ''; # optional path to the best assembly's "optArguments.xml" file (if not within the best assembly's parent directory)
## If the "optArguments.xml" file is NOT within the best assembly's parent directory and you have no "optArguments.xml" file you must specify best assembly parameters below ##
my $min_length = ''; # Minumum molecule length allowed in the sort_bnx section of the best assembly's "optArguments.xml" file (often = 150 )
my $min_labels = ''; # Minumum number of labels per single molecule map allowed in the sort_bnx section of the best assembly's "optArguments.xml" file (often = 8 )

my $optional_assembly_pipelineReport_txt = ''; # optional path to the best assembly's "_pipelineReport.txt" file (if not within the best assembly's parent directory)
## If the "_pipelineReport.txt" file is NOT within the best assembly's parent directory and you have no "_pipelineReport.txt" file you must specify best assembly parameters below ##
my $pipeline_version=''; # Was 3464 at the time this code was written
my $refaligner_version=''; # Was 3520 at the time this code was written
#########################################################################
##################  End optional project variables  #####################
#########################################################################

###########################################################
#      Get genome map _pipelineReport.txt file (fullpath)
###########################################################
my $assembly_pipelineReport_txt_file='';
if (-f $optional_assembly_pipelineReport_txt)
{
    # Check path to best assembly's "_pipelineReport.txt" file if provided ##
    $assembly_pipelineReport_txt_file=$optional_assembly_pipelineReport_txt; # get path
}
else
{
    ## Else check if "_pipelineReport.txt" file exists in the best assembly directory ##
    my $possible_assembly_pipelineReport_txt = glob ("${best_dir}/*_pipelineReport.txt");
    if (-f "$possible_assembly_pipelineReport_txt")
    {
        $assembly_pipelineReport_txt_file = $possible_assembly_pipelineReport_txt;
    }
}
###########################################################
#      Get genome map optArguments.xml file (fullpath)
###########################################################
my $assembly_optArguments_xml_file='';
if (-f $optional_assembly_optArguments_xml)
{
    # Check path to best assembly's "optArguments.xml" file if provided ##
    $assembly_optArguments_xml_file=$optional_assembly_optArguments_xml; # get path
}
else
{
    ## Else check if optArguments.xml exists in the best assembly directory ##
    my @possible_assembly_optArguments_xml = glob ("${best_dir}/*_optArguments\.xml"); # BioNano assembler automatically copies the xml file so there may be two identical copies here
    if (-f "$possible_assembly_optArguments_xml[0]") # take the first copy if it exists
    {
        $assembly_optArguments_xml_file = $possible_assembly_optArguments_xml[0];
    }
}
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
print "Sanity checking project variables section...\n\n";
unless (($assembly_optArguments_xml_file) || (($min_length)&&($min_labels)))
{
    die "write_report.pl is missing either a path to the best assembly's \"optArguments.xml\" file or details about the assembly's parameters needed to fill out the report. Please add either of these and retry."
}
unless(( -f $fasta) && ( -f $cmap) && (-f $genome_map_cmap))
{
    die "File paths in the \"Project variables\" section of write_report.pl are not valid. Remember to copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\" and then edit the new version to point to the best assembly or the best assembly CMAP and the best alignment (Default or Relaxed).\n";
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "Enzymes listed in the \"Project variables\" section of write_report.pl are not valid. Valid entries would be a space separated list that includes one or more of the following options \"BspQI BbvCI BsrDI bseCI\". Remember to copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\" and then edit the new version to point to the best assembly or the best assembly CMAP and the best alignment (Default or Relaxed).\n";
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
#          Create text file for report
###########################################################
my $report_file = "${best_dir}/../report.txt";
open (my $report, ">", $report_file) or die "Can't open $report_file: $!";

###########################################################
#    Get parameters from genome map optArguments.xml file
###########################################################
open (my $assembly_optArguments_xml, "<", $assembly_optArguments_xml_file) or die "Can't open $assembly_optArguments_xml_file: $!";
my $minlen;
my $minsites;
my $AssemblyT;
while (<$assembly_optArguments_xml>)
{
    if (/<flag attr=\"-minlen\"\s+val0=\"(\d+)\" display=/)
    {
        $minlen = $1;
    }
    if (/<flag attr=\"-minsites\"\s+val0=\"(\d+)\" display=/)
    {
        $minsites = $1;
    }
    if (/<flag attr=\"-T\"\s+val0=\"(.*)\" display=\"P Value Cutoff Threshold\" group=\"Initial Assembly/)
    {
        $AssemblyT = $1;
    }
}
###########################################################
#  Get parameters from genome map _pipelineReport.txt file
###########################################################
open (my $assembly_pipelineReport_txt, "<", $assembly_pipelineReport_txt_file) or die "Can't open $assembly_pipelineReport_txt_file: $!";
while (<$assembly_pipelineReport_txt>)
{
#    Pipeline Version: $Id: SVModule.py 3323 2014-10-14 21:11:25Z wandrews $

    if (/Pipeline Version: \$Id: .*\.py \d+ /)
    {
        /Pipeline Version: \$Id: .*\.py (\d+) /;
        $pipeline_version = $1;
    }
    if (/RefAligner Version: SVNversion=\d+/)
    {
        /RefAligner Version: SVNversion=(\d+)/;
        $refaligner_version = $1;
    }
}
close ($assembly_pipelineReport_txt);
###########################################################
#      Get custom software version (AssembleIrysXeonPhi)
###########################################################
print "Getting custom software version (AssembleIrysXeonPhi)...\n\n";
my $AssembleIrysXeonPhi_version = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/AssembleIrysXeonPhi.pl -version`;
$AssembleIrysXeonPhi_version =~ /AssembleIrysXeonPhi.pl Version ([0-9.]+)\n/;
$AssembleIrysXeonPhi_version = $1;
###########################################################
#          Prepare: BioNano_consensus_cmap
###########################################################
print "Preparing BioNano_consensus_cmap...\n\n";
mkdir "$report_dir/BioNano_consensus_cmap";
unless (-d "$report_dir/BioNano_consensus_cmap")
{
    die "Can't create $report_dir/BioNano_consensus_cmap/";
}
link ($genome_map_cmap, "$report_dir/BioNano_consensus_cmap/${genome_map_filename}.cmap") or warn "Can't link $genome_map_cmap to $report_dir/BioNano_consensus_cmap/${genome_map_filename}.cmap: $!";
###########################################################
#          Prepare: in_silico_cmap
###########################################################
print "Preparing in_silico_cmap...\n\n";
mkdir "$report_dir/in_silico_cmap";
unless (-d "$report_dir/in_silico_cmap")
{
    die "Can't create $report_dir/in_silico_cmap/";
}
my (${cmap_filename}, ${cmap_directories}, ${cmap_suffix}) = fileparse($cmap,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
link ($cmap,"$report_dir/in_silico_cmap/${cmap_filename}.cmap" ) or warn "Can't link $cmap to $report_dir/in_silico_cmap/${cmap_filename}.cmap: $!";
if (-f "${cmap_directories}${cmap_filename}_key.txt")
{
    link ("${cmap_directories}${cmap_filename}_key.txt","$report_dir/in_silico_cmap/${cmap_filename}_key.txt") or warn "Can't link ${cmap_directories}${cmap_filename}_key.txt to $report_dir/in_silico_cmap/${cmap_filename}_key.txt: $!";
}
else
{
    die "Error you are missing a key to your in silico reference CMAP in the same directory as $cmap. Create a new CMAP with ~/bin/fa2cmap_multi.pl and try again.\n";
}
###############################################################################
#########                     create new AGP                         ##########
###############################################################################
my (${fasta_filename}, ${fasta_directories}, ${fasta_suffix}) = fileparse($fasta,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
unless (-f "${fasta}_contig.agp")
{
    print "Making new AGP and contig file for FASTA file...\n";
    my $make_agp=`perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_contigs_from_fasta.pl $fasta`;
    #my $make_agp=`perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_contigs_from_fasta.pl ${output_basename}_superscaffold.fasta`;
    print "$make_agp";
}
###############################################################################
#########              create a BNG compatible contig BED file       ##########
###############################################################################
unless (-f "${fasta}_contig.bed")
{
    print "Making new BED file of contigs for FASTA file...\n";
    my $make_contig_bed=`perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/agp2bed.pl ${fasta}_contig.agp`;
    print "$make_contig_bed";
}
###############################################################################
#########              create a BNG compatible GAP BED file          ##########
###############################################################################
unless (-f "${fasta}_gaps.bed")
{
    print "Making new BED file of gaps for super-scaffolded FASTA file...\n";
    my $make_gap_bed=`perl ~/Irys-scaffolding/KSU_bioinfo_lab/sv_detect/agp2_gap_bed.pl ${fasta}_contig.agp`;
    print "$make_gap_bed";
}
my $get_beds = `cp ${fasta}_contig.bed ${fasta}_contig_gaps.bed $report_dir/in_silico_cmap`;
print "$get_beds";
###########################################################
#          Prepare: align_in_silico_xmap
###########################################################
print "Preparing align_in_silico_xmap...\n\n";
mkdir "$report_dir/align_in_silico_xmap";
unless (-d "$report_dir/align_in_silico_xmap")
{
    die "Can't create $report_dir/align_in_silico_xmap/";
}
my $in_silico_align_dir_path = "${best_dir}/../${alignment_parameters}";
opendir (my $in_silico_align_dir, $in_silico_align_dir_path) or die "Can't open $in_silico_align_dir_path: $!";
my $prefix;
for my $file (readdir $in_silico_align_dir)
{
    if ($file =~ /\.xmap/)
    {
        $file =~ /(.*)\.xmap/; # grab the unfiltered XMAP file prefix
        $prefix = $1;
    }
}
my @in_silico_aligns = glob "$in_silico_align_dir_path/${prefix}*";
for my $file (@in_silico_aligns)
{
    my (${alignment_filename}, ${alignment_directories}, ${alignment_suffix}) = fileparse($file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
    link ("$file","$report_dir/align_in_silico_xmap/${alignment_filename}${alignment_suffix}") or warn "Can't link $file to $report_dir/align_in_silico_xmap/${alignment_filename}${alignment_suffix} : $!"; # make a hard link for the unfiltered XMAP file and all supporting files (required by IrysView)
}
###########################################################
#           Prepare: structural variant calls
###########################################################
print "Preparing structural variant calls...\n\n";
my $sv_directory = glob "${best_dir}/contigs/*refineFinal1_sv/merged_smaps";
my $sv_calls_worked = glob "${best_dir}/contigs/*refineFinal1_sv/merged_smaps/*_merged.bed"; # This file should exist if structural variants were found
if (-d "$sv_directory")
{
    if ( -f "$sv_calls_worked")
    {
        symlink ($sv_directory,"$report_dir/merged_smaps") or warn "FYI: SV detect may not have been run because script can't link $sv_directory to $report_dir/merged_smaps : $!"; # make a soft link for the directory with SV call files and all supporting files (required by IrysView)
    }
    else
    {
        warn "FYI: it looks like SV detect ran but found no structural variants"; 
    }
}
else
{
    warn "FYI: SV detect may not have been run because script can't link  to ${best_dir}/contigs/*refineFinal1_sv/merged_smaps : $!"; # make a soft link for the directory with SV call files and all supporting files (required by IrysView)
}
#/home/bionano/bionano/Zea_maiz_2015_004/default_t_150/contigs/Zea_maiz_2015_004_default_t_150_refineFinal1_sv/merged_smaps
###########################################################
#          Prepare: CSV file
###########################################################
print "Preparing final BNGCompare.csv file...\n\n";
my $bng_compare_file = glob ("${best_dir}/../*_BNGCompare.csv");
my @metrics;
my $final_bng_compare_file;
if (-f $bng_compare_file)
{
    open (my $bng_compare, "<", $bng_compare_file) or die "Can't open $bng_compare_file: $!";
    my $first_section = 1;
    while (<$bng_compare>)
    {
        chomp;
        if (/^relaxed_alignment/)
        {
            $first_section = 0;
        }
        if (($alignment_parameters eq "default_alignment") && ($first_section == 1))
        {
            push (@metrics,$_);
        }
        elsif (($alignment_parameters eq "relaxed_alignment") && ($first_section == 0))
        {
            push (@metrics,$_);
        }
    }
    my (${bng_compare_filename}, ${bng_compare_directories}, ${bng_compare_suffix}) = fileparse($bng_compare_file,qr/\.[^.]*/); # directories has trailing slash and suffix includes dot in suffix
    $final_bng_compare_file = "${bng_compare_directories}${bng_compare_filename}_final.csv";
    open (my $final_bng_compare, ">", $final_bng_compare_file) or die "Can't open $final_bng_compare_file: $!";
    print $final_bng_compare "$metrics[1],Percent of CMAP covered by alignment\n";
    ## Get percent aligned for Reference
    my ($breadth_of_align_fasta) = (split (/\,/, $metrics[2]))[2];
    my ($length_fasta) = (split (/\,/, $metrics[5]))[4];
    my $percent_aligned_fasta = ($breadth_of_align_fasta/$length_fasta)*100;
    $metrics[2] =~ s/^XMAP alignment/XMAP alignment lengths relative to the in silico maps/;
    print $final_bng_compare "$metrics[2],$percent_aligned_fasta\n";
    ## Get percent aligned for Query
    my ($breadth_of_align_query) = (split (/\,/, $metrics[9]))[2];
    my ($length_query) = (split (/\,/, $metrics[7]))[4];
    my $percent_aligned_query = ($breadth_of_align_query/$length_query)*100;
    $metrics[9] =~ s/^XMAP alignment/XMAP alignment lengths relative to the genome maps/;
    print $final_bng_compare "$metrics[9],$percent_aligned_query\n";
    print $final_bng_compare "$metrics[4]\n";
    $metrics[5] =~ s/^Genome fasta/Genome FASTA/;
    print $final_bng_compare "$metrics[5]\n";
    print $final_bng_compare "$metrics[6]\n";
    print $final_bng_compare "$metrics[7]\n";
    if (($metrics[12]) && ($metrics[12] =~ /superscaffold/)) # test that a superscaffolding line exists in _BNGCompare.csv
    {
        $metrics[12] =~ s/^Genome fasta/Super scaffold FASTA/;
        print $final_bng_compare "$metrics[12]\n";
    }
}
###########################################################
#    Print to report: Text for basic assembly and alignment
###########################################################
print "Printing to report: Text for basic assembly and alignment...\n\n";
print $report "Further training and installation instructions for IrysView are available here: \nhttp://www.bnxinstall.com/training/docs/IrysViewSoftwareInstallationGuide.pdf\nhttp://www.bnxinstall.com/training/docs/IrysViewSoftwareTrainingGuide.pdf\n\nFor further information about your output refer to the included \"README.pdf\" file and the XMAP and CMAP file format specs in \"file_format.zip\".\n\nAssembly of consensus cmap from BioNano molecules\n________________________________________________________________________________________________________\nAll assembly scripts to run the BioNano IrysSolve pipeline were written and molecule maps were prepared using AssembleIrysXeonPhi.pl version ${AssembleIrysXeonPhi_version}. BioNano single molecule maps were filtered with a minimum length of ${minlen} (kb) and ${minsites} minimum labels. A p-value threshold for the BioNano assembler was set to ${AssemblyT} during the initial pair wise alignment stage and p-value thresholds for subsequent assembly stages were based off of this value by AssembleIrysXeonPhi.pl. The BioNano IrysSolve de novo assembly pipeline utilized RefAligner and Assembler binaries version ${refaligner_version} and pipeline scripts version ${pipeline_version}.\n\nCreation of in silico cmap from your fasta genome\n________________________________________________________________________________________________________\nYour FASTA file was in silico nicked for ${enzyme} label(s). Note that in silico maps are only created for FASTA sequences > 20 kb enough and with > 5 labels. \n\nAlignment of BioNano consensus map to fasta genome\n________________________________________________________________________________________________________\n\nA stringency of ${T} was used for alignment with in silico cmaps as the anchor and BioNano consensus maps as the query.\n\n";
###########################################################
#     Check if Super scaffolds were created
###########################################################
print "Checking if Super scaffolds were created...\n\n";
my @stitch_dir_paths = glob "${best_dir}/../${alignment_parameters}/stitch*"; # glob returns no trailing slash
my $stitch_dir_path;
my $num_iterations;
if (scalar(@stitch_dir_paths) == 1)
{
    $stitch_dir_path = $stitch_dir_paths[0];
    $stitch_dir_path =~ /\/stitch([\d]+)/;
    $num_iterations = $1;
}
elsif (scalar(@stitch_dir_paths) == 0)
{
    ###########################################################
    #          Prepare: compress files
    ###########################################################
#    print "Compressing files...\n\n";
#    my $compress = `cd ${best_dir}/.. ; tar -czvf ${project}.tar.gz $project`;
#    print $compress;
#    print "Done writing report.\n";
    print "Finished and exiting because no super scaffolds were made.\n";
#    exit;
    goto FINISH;
}
else
{
    die "You have more than one stitch directory in ${best_dir}/../${alignment_parameters}/ delete any failed directories and any intermediate directories leaving only the final iteration to add any new superscaffolds and rerun this script.\n";
}
###########################################################
#      Prepare:Get stitch version and parameters
###########################################################
print "Getting custom software version and parameters (stitch)...\n\n";
my $stitch_version = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -version`;
$stitch_version =~ /stitch.pl Version ([0-9.]+)\n/;
$stitch_version = $1;
my $stitch_count;
###########################################################
#          Prepare: align_in_silico_super_scaffold
###########################################################
print "Preparing align_in_silico_super_scaffold...\n\n";
mkdir "$report_dir/align_in_silico_super_scaffold_xmap";
unless (-d "$report_dir/align_in_silico_super_scaffold_xmap")
{
    die "Can't create $report_dir/align_in_silico_super_scaffold_xmap/";
}
#print "\n\n$stitch_dir_path\n";
my @in_silico_super_scaffolds = glob "${stitch_dir_path}/*_REFINEFINAL1*";
for my $file (@in_silico_super_scaffolds)
{
    my (${alignment_filename}, ${alignment_directories}, ${alignment_suffix}) = fileparse($file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
    link ("$file","$report_dir/align_in_silico_super_scaffold_xmap/${alignment_filename}${alignment_suffix}") or warn "Can't link $file to $report_dir/align_in_silico_super_scaffold_xmap/${alignment_filename}${alignment_suffix} : $!"; # make a hard link for the unfiltered XMAP  file and all supporting files (required by IrysView)
}
###########################################################
#          Prepare: super_scaffold
###########################################################
print "Preparing super_scaffold...\n\n";
mkdir "$report_dir/super_scaffold";
my (${fasta_superscaffold_filename}, ${superscaffold_directories}, ${superscaffold_suffix});

unless (-d "$report_dir/super_scaffold")
{
    die "Can't create $report_dir/super_scaffold/";
}
my @super_scaffold_files = glob "${stitch_dir_path}/*_superscaffold*";
for my $file (@super_scaffold_files)
{
    unless ($file =~ /superscaffold\.agp/)
    {
        my (${superscaffold_filename}, ${superscaffold_directories}, ${superscaffold_suffix}) = fileparse($file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
        link ("$file","$report_dir/super_scaffold/${superscaffold_filename}${superscaffold_suffix}") or warn "Can't link $file to $report_dir/super_scaffold/${superscaffold_filename}${superscaffold_suffix} : $!"; # make a hard link for the super scaffold files
    }
    if ($file =~ /superscaffold\.fasta\Z/)
    {
        (${fasta_superscaffold_filename}, ${superscaffold_directories}, ${superscaffold_suffix}) = fileparse($file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
        $stitch_count = `grep -c "^>Super_scaffold" $file`;
    }
}
print "NOTE: pipeline_version = $pipeline_version and refaligner_version = $refaligner_version AssembleIrysXeonPhi_version = $AssembleIrysXeonPhi_version stitch_version = $stitch_version num_iterations = $num_iterations fasta_superscaffold_filename = $fasta_superscaffold_filename AssemblyT = $AssemblyT minlen = $minlen minsites = $minsites stitch_count = $stitch_count\n";
###########################################################
#          Print to report: Super scaffolding text
###########################################################
print "Printing to report: Super scaffolding text...\n\n";
print $report "Super-scaffolding of fasta genome using Bionano consensus map\n________________________________________________________________________________________________________\n\nFiles in the \"super_scaffold\" folder were output by stitch.pl version ${stitch_version} (at https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch). The program \"stitch.pl\" was run for ${num_iterations} iterations. BioNano genome maps were aligned as queries to the in silico maps. The XMAP alignment was inverted and used as input for \"stitch.pl\". Alignments were kept if alignment length was greater than ${f_algn}\% of the possible length and their confidence score was above ${f_con}.  In order to include good alignments in lower label density regions of the genome, alignments were also kept if alignment length was greater than ${s_algn}\% of the possible length and their confidence score was above ${s_con}. These filtered alignments were searched for BioNano genome maps that super scaffold sequence contigs. In your case ${stitch_count} super scaffolds were created and they are reflected in the ${fasta_superscaffold_filename}.fasta file. \n\nSequences that were not super scaffolded were added to this file with the same header as before.\n";
###########################################################
#          Prepare: compress files
###########################################################
FINISH:
print "Compressing files...\n\n";
my $compress_log_file = "${best_dir}/..compress_log.txt";
open (my $compress_log, ">", $compress_log_file) or die "Can't open $compress_log_file: $!";
my $compress = `cd ${best_dir}/.. ; tar -czvf ${project}.tar.gz $project`;
print $compress_log "$compress";
###########################################################
#          Print to report: Text File inventory
###########################################################
print "Printing to report: File inventory...\n\n";
my $file_inventory = `cd $report_dir ; ls *`;
print $report "\nFile inventory\n________________________________________________________________________________________________________\n\n$file_inventory\n"; # Print File inventory
print "Done writing report and preping files.\n";


