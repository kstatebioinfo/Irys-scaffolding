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
use Term::ANSIColor;
use File::Basename; # enable manipulating of the full path
use Getopt::Long;
use Pod::Usage;
#####################################################################
########################  Project variables  ########################
#####################################################################
#############################################
####  Default or Relaxed alignments
my $alignment_parameters="default_alignment";
#my $alignment_parameters="relaxed_alignment";
#############################################
# Full path of the directory of the best assembly without trailing slash (e.g. /home/bionano/bionano/Dros_psue_2014_012/default_t_100 )
my $fasta = ""; # (e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped.fasta)
my $cmap = ""; #(e.g. /home/bionano/bionano/Trib_cast_0002_final/GCF_000227135_wrapped_BbvCI.cmap)
my $enzyme= ""; # space separated list that can include BspQI BbvCI BsrDI bseCI (e.g. BspQI)
my $f_con="20"; # default value
my $f_algn="40"; # default value
my $s_con="15"; # default value
my $s_algn="90"; # default value
my $T = 1e-8; # default value
my $neg_gap = 20000; # default value
my $project=""; # no spaces, slashes or characters other than underscore (e.g. Trib_cast_0002)
# Use either both "$out" and "$genome_maps":
my $genome_maps = ''; # add assembled cmap path here if it is not in the "refineFinal1" subdirectory within the "contigs" subdirectory of the best assembly directory
my $out =''; # no trailing slash (e.g. /home/bionano/bionano/Trib_cast_0002_final)
# Or "$best_dir":
my $best_dir =''; # no trailing slash (e.g. /home/bionano/bionano/Trib_cast_0002_final)
#########################################################################
########################  End project variables  ########################
#########################################################################

#########################################################################
####################  Optional project variables  #######################
#########################################################################
my $optional_assembly_optArguments_xml = ''; # optional path to the best assembly's "optArguments.xml" file (if not within the best assembly's parent directory)
## If the "optArguments.xml" file is NOT within the best assembly's parent directory and you have no "optArguments.xml" file you must specify best assembly parameters below ##
my $minlen = 'UNKNOWN'; # Minumum molecule length allowed in the sort_bnx section of the best assembly's "optArguments.xml" file (often = 150 )
my $minsites = 'UNKNOWN'; # Minumum number of labels per single molecule map allowed in the sort_bnx section of the best assembly's "optArguments.xml" file (often = 8 )
my $AssemblyT = 'UNKNOWN'; # p-value threshold for the BioNano assembler during the initial pair wise alignment stage
my $optional_assembly_pipelineReport_txt = ''; # optional path to the best assembly's "_pipelineReport.txt" file (if not within the best assembly's parent directory)
## If the "_pipelineReport.txt" file is NOT within the best assembly's parent directory and you have no "_pipelineReport.txt" file you must specify best assembly parameters below ##
my $pipeline_version='UNKNOWN'; # Was 3464 at the time this code was written
my $refaligner_version='UNKNOWN'; # Was 3520 at the time this code was written
#########################################################################
##################  End optional project variables  #####################
#########################################################################
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print "#  write_report.pl Version 1.0.1                          #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/26/15                    #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl write_report.pl -help # for usage/options         #\n";
print "#  perl write_report.pl -man # for more details           #\n";
print "###########################################################\n";
#########################################################################
########################  End project variables  ########################
#########################################################################
my ($de_novo);
my $man = 0;
my $help = 0;
my $version = 0;
GetOptions (
    'help|?' => \$help,
    'version' => \$version,
    'man' => \$man,
    'a_p|alignment_parameters:s' => \$alignment_parameters,
    'p|proj:s' => \$project,
    'e|enzyme:s' => \$enzyme,
    'f|fasta:s' => \$fasta,
    'r|ref:s' => \$cmap,
    'f_con|fc:f' => \$f_con,
    'f_algn|fa:f' => \$f_algn,
    's_con|sc:f' => \$s_con,
    's_algn|sa:f' => \$s_algn,
    't|p-value_T:f' => \$T,
    'n|neg_gap:f' => \$neg_gap,
    'd|de_novo' => \$de_novo,
    'o|out_dir:s' => \$out,
    'g|genome_maps:s' => \$genome_maps,
    'b|best_dir:s' => \$best_dir
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version)
{
    print "run_compare.pl Version 1.0.0\n";
    exit;
}
my $dirname = dirname(__FILE__);
unless (($best_dir) || (($out) && ($genome_maps)))
{
    die "Either specify option -b / --best_dir or both options -o / --out_dir and -g / --genome_maps.\n"; # report missing required variables
}
die "Option -p or --proj not specified.\n" unless $project; # report missing required variables
die "Option -e or --enzyme not specified.\n" unless $enzyme; # report missing required variables
unless ($de_novo)
{
    die "Option -f or --fasta not specified.\n" unless $fasta; # report missing required variables
    die "Option -r or --ref not specified.\n" unless $cmap; # report missing required variables
}
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
    if (${best_dir})
    {
        ## Else check if "_pipelineReport.txt" file exists in the best assembly directory ##
        my @possible_assembly_pipelineReport_txt = glob ("${best_dir}/*_pipelineReport.txt");
        for my $possible_assembly_pipelineReport_txt (@possible_assembly_pipelineReport_txt)
        {
            if (-f "$possible_assembly_pipelineReport_txt")
            {
                $assembly_pipelineReport_txt_file = $possible_assembly_pipelineReport_txt;
            }
        }
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
    if (${best_dir})
    {
        ## Else check if optArguments.xml exists in the best assembly directory ##
        my @possible_assembly_optArguments_xml = glob ("${best_dir}/*_optArguments\.xml"); # BioNano assembler automatically copies the xml file so there may be two identical copies here
        for my $possible_assembly_optArguments_xml (@possible_assembly_optArguments_xml)
        {
            if (-f "$possible_assembly_optArguments_xml") # take the first copy if it exists
            {
                $assembly_optArguments_xml_file = $possible_assembly_optArguments_xml;
            }
        }
    }
}
###########################################################
#            Get genome map CMAP file (fullpath)
###########################################################
my $genome_map_cmap;
unless($genome_maps)
{
    if (${best_dir})
    {
        my @genome_map_cmaps = glob("${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap");
        for my $genome_map_cmap_candidate (@genome_map_cmaps)
        {
            $genome_map_cmap = $genome_map_cmap_candidate;
        }
    }
}
else
{
    $genome_map_cmap = $genome_maps;
}
my (${genome_map_filename}, ${genome_map_directories}, ${genome_map_suffix});
if (-f $genome_map_cmap)
{
    (${genome_map_filename}, ${genome_map_directories}, ${genome_map_suffix}) = fileparse($genome_map_cmap,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
}
###########################################################
#                Get/create output directory
###########################################################
unless($out)
{
    my @outs = glob("${best_dir}/..");
    for my $path (@outs)
    {
        $out = $path;
    }
    
}
else
{
    unless (-d $out)
    {
        mkdir($out) or die "Can't create $out: $!";
    }
}
###########################################################
#          Sanity check project variables section
###########################################################
print "Sanity checking project variables section...\n\n";
unless (($assembly_optArguments_xml_file) || (($minlen)&&($minsites)))
{
    die "write_report.pl cannot automatically find the path to the best assembly's \"optArguments.xml\" file or details about the assembly's parameters needed to fill out the report. Please make a copy of write_report.pl, add these to the \"Optional project variables\" section of write_report.pl and retry."
}
my $error = "write_report.pl cannot automatically find the path to the best assembly's reference FASTA, reference in silico CMAP and/or the BioNano genome CMAP files needed to fill out the report. Remember to either copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section or add the equivalent flags and values to your command.\nTo do the former cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\", then edit the new version to point to the best asssembly or the best assembly's reference FASTA, reference in silico CMAP, the best alignment (Default or Relaxed) etc and retry.\n";
unless (-f $genome_map_cmap)
{
    die "$error";
}
unless ($de_novo)
{
    unless(( -f $fasta) && ( -f $cmap))
    {
        die "$error";
    }
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "write_report.pl cannot find a valid list of enzymes used for molecule labeling or in silico labeling of the reference FASTA. Remember to either copy the write_report.pl script into your assembly working directory and update other variables for project in \"Project variables\" section or add the equivalent flags and values to your command.\nTo do the former cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl .\", then edit the new version's \"Project variables\" section and retry.\n";
}
###########################################################
#          Check that report directory already exists
###########################################################
my $report_dir = "${out}/$project";
unless (-d "$report_dir")
{

    mkdir $report_dir;
    print "Creating output directory because $report_dir does not exist\n";
}
###########################################################
#          Create text file for report
###########################################################
my $report_file = "${out}/report.txt";
open (my $report, ">", $report_file) or die "Can't open $report_file: $!";

###########################################################
#    Get parameters from genome map optArguments.xml file
###########################################################
if (-f $assembly_optArguments_xml_file)
{
    open (my $assembly_optArguments_xml, "<", $assembly_optArguments_xml_file) or die "Can't open $assembly_optArguments_xml_file: $!";
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
}
###########################################################
#  Get parameters from genome map _pipelineReport.txt file
###########################################################
if (-f $assembly_pipelineReport_txt_file)
{
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
}
###########################################################
#      Get custom software version (AssembleIrysXeonPhi)
###########################################################
print "Getting custom software version (AssembleIrysXeonPhi)...\n\n";
my $AssembleIrysXeonPhi_version = `perl ${dirname}/../assemble_XeonPhi/AssembleIrysXeonPhi.pl -version`;
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
unless($de_novo)
{
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
        die "Error you are missing a key to your in silico reference CMAP in the same directory as $cmap. Create a new CMAP with ${dirname}/third-party/fa2cmap_multi.pl and try again.\n";
    }
    ###############################################################################
    #########                     create new AGP                         ##########
    ###############################################################################
    my (${fasta_filename}, ${fasta_directories}, ${fasta_suffix}) = fileparse($fasta,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
    unless (-f "${fasta}_contig.agp")
    {
        print "Making new AGP and contig file for FASTA file...\n";
        my $make_agp=`perl ${dirname}/../stitch/make_contigs_from_fasta.pl $fasta`;
        #my $make_agp=`perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_contigs_from_fasta.pl ${output_basename}_superscaffold.fasta`;
        print "$make_agp";
    }
    ###############################################################################
    #########              create a BNG compatible contig BED file       ##########
    ###############################################################################
    unless (-f "${fasta}_contig.bed")
    {
        print "Making new BED file of contigs for FASTA file...\n";
        my $make_contig_bed=`perl ${dirname}/../stitch/agp2bed.pl ${fasta}_contig.agp`;
        print "$make_contig_bed";
    }
    ###############################################################################
    #########              create a BNG compatible GAP BED file          ##########
    ###############################################################################
    unless (-f "${fasta}_gaps.bed")
    {
        print "Making new BED file of gaps for super-scaffolded FASTA file...\n";
        my $make_gap_bed=`perl ${dirname}/../sv_detect/agp2_gap_bed.pl ${fasta}_contig.agp`;
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
    my $in_silico_align_dir_path = "${out}/${alignment_parameters}";
    opendir (my $in_silico_align_dir, $in_silico_align_dir_path) or die "Can't open $in_silico_align_dir_path: $!";
    my $prefix;
    for my $file (readdir $in_silico_align_dir)
    {
        if ($file =~ /\.xmap/)
        {
            unless ($file =~ /_filtered\.xmap/)
            {
                $file =~ /(.*)\.xmap/; # grab the unfiltered XMAP file prefix
                $prefix = $1;
            }
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
    if (($sv_directory) && (-d "$sv_directory"))
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
    my $bng_compare_file = glob ("${out}/*_BNGCompare.csv");
    my (${bng_compare_filename}, ${bng_compare_directories}, ${bng_compare_suffix}) = fileparse($bng_compare_file,qr/\.[^.]*/); # directories has trailing slash and suffix includes dot in suffix
    my $final_bng_compare_file = "${bng_compare_directories}${bng_compare_filename}_final.csv";
    open (my $final_bng_compare, ">", $final_bng_compare_file) or die "Can't open $final_bng_compare_file: $!";
    my @metrics;
    if (-f $bng_compare_file)
    {
        open (my $bng_compare, "<", $bng_compare_file) or die "Can't open $bng_compare_file: $!";
        my $first_section = 1;
        while (<$bng_compare>)
        {
#            chomp;
            if (/^relaxed_alignment/)
            {
                $first_section = 0;
            }
            if (($alignment_parameters eq "default_alignment") && ($first_section == 1))
            {
                print $final_bng_compare "$_";
            }
            elsif (($alignment_parameters eq "relaxed_alignment") && ($first_section == 0))
            {
                print $final_bng_compare "$_";
            }
        }
    }
}
###########################################################
#    Print to report: Text for basic assembly and alignment
###########################################################
print "Printing to report: Text for basic assembly and alignment...\n\n";
print $report "Further training and installation instructions for IrysView are available here: \nhttp://www.bnxinstall.com/training/docs/IrysViewSoftwareInstallationGuide.pdf\nhttp://www.bnxinstall.com/training/docs/IrysViewSoftwareTrainingGuide.pdf\n\nFor further information about your output refer to the included \"README.pdf\" file and the XMAP and CMAP file format specs in \"file_format.zip\".\n\nAssembly of consensus cmap from BioNano molecules\n________________________________________________________________________________________________________\nAll assembly scripts to run the BioNano IrysSolve pipeline were written and molecule maps were prepared using AssembleIrysXeonPhi.pl version ${AssembleIrysXeonPhi_version}. BioNano single molecule maps were filtered with a minimum length of ${minlen} (kb) and ${minsites} minimum labels. A p-value threshold for the BioNano assembler was set to ${AssemblyT} during the initial pair wise alignment stage and p-value thresholds for subsequent assembly stages were based off of this value by AssembleIrysXeonPhi.pl. The BioNano IrysSolve de novo assembly pipeline utilized RefAligner and Assembler binaries version ${refaligner_version} and pipeline scripts version ${pipeline_version}.";
unless($de_novo)
{
    print $report "\n\nCreation of in silico cmap from your fasta genome\n________________________________________________________________________________________________________\nYour FASTA file was in silico nicked for ${enzyme} label(s). Note that in silico maps are only created for FASTA sequences > 20 kb enough and with > 5 labels. \n\nAlignment of BioNano consensus map to fasta genome\n________________________________________________________________________________________________________\n\nA stringency of ${T} was used for alignment with in silico cmaps as the anchor and BioNano consensus maps as the query.\n\n";
}
else
{
    my $cmap_stat_out = `${dirname}/../map_tools/cmap_stats.pl -c $genome_map_cmap`;
    $cmap_stat_out =~ s/(^.*\#.*\n)(cmap N50: .* \(Mb\)\nTotal cmap length: .* \(Mb\)\nNumber of cmaps: .*\n)(done.*)/$2/gs;
    $cmap_stat_out =~ s/cmaps/BioNano genome maps/g;
    $cmap_stat_out =~ s/cmap/BioNano genome map assembly/g;
    print $report "\n\nCMAP metrics\n________________________________________________________________________________________________________\n$cmap_stat_out"; # Add BioNano genome map stats to report for de novo assemblies
}
###########################################################
#     Check if Super scaffolds were created
###########################################################
print "Checking if Super scaffolds were created...\n\n";
my @stitch_dir_paths = glob "${out}/${alignment_parameters}/stitch*"; # glob returns no trailing slash
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
    print "Finished and exiting because no super scaffolds were made.\n";
    ###########################################################
    #          Prepare: compress files
    ###########################################################
    goto FINISH; # Skip to section for compressing files
}
else
{
    die "You have more than one stitch directory in ${out}/${alignment_parameters}/ delete any failed directories and any intermediate directories leaving only the final iteration to add any new superscaffolds and rerun this script. This should have been done when you ran run_compare.pl.\n";
}
###########################################################
#      Prepare:Get stitch version and parameters
###########################################################
print "Getting custom software version and parameters (stitch)...\n\n";
my $stitch_version = `perl ${dirname}/../stitch/stitch.pl -version`;
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
my $compress_log_file = "${out}/compress_log.txt";
open (my $compress_log, ">", $compress_log_file) or die "Can't open $compress_log_file: $!";
my $compress = `cd ${out} ; tar -chzvf ${project}.tar.gz $project`;
print $compress_log "$compress";
###########################################################
#          Print to report: Text File inventory
###########################################################
print "Printing to report: File inventory...\n\n";
my $file_inventory = `cd $report_dir ; ls *`;
print $report "\nFile inventory\n________________________________________________________________________________________________________\n\n$file_inventory\n"; # Print File inventory
print "Done writing report and preping files.\n";

##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

write_report.pl - a script that compiles final assembly metrics, prepares output files and writes a report for the "best" assembly in all of the possible directories:'strict_t', 'default_t', 'relaxed_t', etc. These assemblies are created using Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/AssembleIrysXeonPhi.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding. The parameter `-b` is the directory with the "contigs" subdirectory created for the "best" assembly.

Copy script into assembly working directory and update other variables for project in "Project variables" section or run original script by adding the equivalent flags and values to your command. To do the former cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP, etc.

=head1 USAGE

perl run_compare.pl [options]

Documentation options:

    -help    brief help message
    -man	    full documentation

Required options:

    -o	     output directory
    -g	     genome map CMAP file
    -p	     project
    -e	     enzyme

Required options (unless de novo project):

    -f	     scaffold (reference) FASTA
    -r	     reference CMAP
 
Required options (for assemble_XeonPhi pipeline):

    -b	     best assembly directory (replaces -o and -g)

Required options (if de novo project):
 
    -d	     add this flag if the project is de novo (has no reference)

Filtering options:

    --alignment_parameters  default or relaxed alignment noise parameters (default = default_alignment)
    --f_con	 first minimum confidence score (default = 20)
    --f_algn	 first minimum % of possible alignment (default = 40)
    --s_con	 second minimum confidence score (default = 15)
    --s_algn	 second minimum % of possible alignment (default = 90)
    --n	         minimum negative gap length allowed (default = 20000 bp)
    -T	         RefAligner p-value threshold (default = 1e-8)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-o, --out_dir>

Path of the user selected output directory without trailing slash (e.g. -o ~/stitch_out ).

=item B<-g, --genome_maps>

Path of the CMAP file containing genome maps assembled from single molecule maps (e.g. -g ~/Irys-scaffolding/KSU_bioinfo_lab/sample_output_directory/BioNano_consensus_cmap/ESCH_COLI_1_2015_000_STRICT_T_150_REFINEFINAL1.cmap ).
 
=item B<-p, --project>

The project name with no spaces, slashes or characters other than underscore (e.g. Trib_cast_0002).

=item B<-e, --enzyme>

A space separated list of the enzymes used to label the molecules and to in silico nick the sequence-based FASTA file. They can include BspQI BbvCI BsrDI bseCI (e.g. BspQI). If multiple enzymes were used enclose the list with quotes (e.g. "BspQI BbvCI").

=item B<-f, --fasta>

The FASTA that will be super-scaffolded based on alignment to the IrysView assembly. It is preferable to use the scaffold FASTA rather than the contigs. Many contigs will not be long enough to align.

=item B<-r, --r_cmap>

The reference CMAP produced from your sequence FASTA file.
 
=item B<-b, --best_dir>

Path of the user selected directory of the "best" assembly without trailing slash (e.g. ~/Esch_coli_1_2015_000/default_t_100 ). This parameter replaces -o and -g when using the assemble_XeonPhi pipeline.

=item B<-d, --de_novo>

Add this flag to the command if a project is de novo (i.e. has no reference). Any step that requires a reference will then be skipped.
 
=item B<--a_p, --alignment_parameters>

The final alignment noise parameters. The options are "default_alignment" (with "-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10") or "relaxed_alignment" (with "-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15"). Generally, default is the best but for some draft genome projects relaxed gives more useful results.

=item B<--f_con, --fc>

The minimum confidence score for alignments for the first round of filtering. This should be the most stringent, highest, of the two scores.

=item B<--f_algn, --fa>

The minimum percent of the full potential length of the alignment allowed for the first round of filtering. This should be lower than the setting for the second round of filtering.

=item B<--s_con, --sc>

The minimum confidence score for alignments for the second round of filtering. This should be the less stringent, lowest, of the two scores.

=item B<--s_algn, --sa>

The minimum percent of the full potential length of the alignment allowed for the second round of filtering. This should be higher than the setting for the first round of filtering.

=item B<-n, --neg_gap>

Allows user to adjust minimum negative gap length allowed (default = 20000 bp).

=item B<-t, --p-value_T>

The RefAligner p-value threshold (default = 1e-8).


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

The script outputs an XMAP with only molecules that scaffold contigs and an XMAP of all high quality alignments. Both XMAPs can be imported and viewed in the IrysView "comparisons" window if the original r.cmap and q.cmap are in the same folder when you import.

The script also lists summary metrics in a csv file.

In the same csv file, scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible are listed. These may represent mis-assembled scaffolds.

In the same csv file, high quality but overlaping alignments in a csv file are listed. These may be candidates for further assembly using the overlaping contigs and paired end reads.

The script also creates a non-redundant (i.e. no scaffold is used twice) super-scaffold from a user-provided scaffold file and a filtered XMAP. If two scaffolds overlap on the superscaffold then a 100 "n" gap is used as a spacer between them. If adjacent scaffolds do not overlap on the super-scaffold than the distance between the begining and end of each scaffold reported in the XMAP is used as the gap length. If a scaffold has two high quality alignments the longest alignment is selected. If both alignments are equally long the alignment with the highest confidence is selected.

The script also outputs contigs, an agp, and a bed file of contigs within superscaffolds from the final super-scaffold fasta file.


B<QUICK START:>

git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90

=cut

