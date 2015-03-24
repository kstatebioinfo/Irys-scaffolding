#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl run_compare.pl
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: # Copy script into assembly working directory and update other variables for project in "Project variables" section. To do this cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl ." and then edit the new version to point to the best asssembly.
# REQUIREMENTS: Requires BNGCompare from https://github.com/i5K-KINBRE-script-share/BNGCompare in your home directory. Also requires BioPerl.
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
my $cmap = "reference cmap full path";
my $enzyme= "enzyme or enzymes"; # space separated list that can include BspQI BbvCI BsrDI bseCI
#bng_assembly="BNG_assembly_basename"
#FASTA_EXT="fasta_extension_without_dot"

my $f_con="13";
my $f_algn="30";
my $s_con="8";
my $s_algn="90";
my $T = 1e-8;
my $project="project_name";


########################  End project variables  ########################

my %alignment_parameters;
# Default alignments
my $alignment_parameters{'default_alignment'} ="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10";
# Relaxed alignments
my $alignment_parameters{'relaxed_alignment'} ="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15";

my (${filename}, ${directories}, ${suffix}) = fileparse($fasta,qr/\.[^.]*/); # directories has trailing slash
my (${filename_cmap}, ${directories_cmap}, ${suffix_cmap}) = fileparse($cmap,qr/\.[^.]*/); # directories has trailing slash
my @alignments = qw/default_alignment relaxed_alignment/;
open (
for my $stringency (@alignments)
{
    unless(mkdir "$best_dir/../$stringency")
    {
        print "Unable to create $best_dir/../$stringency\n";
    }
    #Align
    my $align = `~/tools/RefAligner -i ${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap -ref $cmap -o ${best_dir}/../${stringency}/${filename}_to_${filename_cmap} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem 256`;
    #Get most metrics
    my $xmap_alignments = `perl ~/BNGCompare/BNGCompare.pl -f $fasta -r $cmap -q ${best_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap -x ${best_dir}/../${stringency}/${filename}_to_${filename_cmap}.xmap`;
    print $xmap_alignments;
    #Flip xmap
    my $flip =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${best_dir}/../${stringency}/${filename}_to_${filename_cmap}.xmap ${best_dir}/../${stringency}/${filename_cmap}_to_${filename}`;
    print $flip;
    #Get flipped metrics
    my $flip_align =  `perl ~/BNGCompare/xmap_stats.pl -x ${best_dir}/../${stringency}/${filename_cmap}_to_${filename}.flip -o ${best_dir}/../${stringency}/${filename}_BNGCompare.csv`;
    print "$flip_align";
    #Stitch1
    my $stitch_dir = "$best_dir/../$stringency/stitch1";
    unless(mkdir $stitch_dir)
    {
        print "Unable to create $stitch_dir\n";
    }
    my $stitch_out =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${best_dir}/../${stringency}/${filename}_to_${filename_cmap}_q.cmap -x ${best_dir}/../${stringency}/${filename_cmap}_to_${filename}.flip -f $fasta -o $stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1 --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
    print $stitch_out;
    my $agp_list_file = "$best_dir/../$stringency/agp_list.txt";
    open (my $agp_list, ">", $agp_list_file) or die "Can't open $agp_list_file: $!";
    print $agp_list "$stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1_superscaffold.agp\n";
#    /home/bionano/bionano/Gram_nega_2014_055/strict_t_150/contigs/Gram_nega_2014_055_strict_t_150_refineFinal1/alignref_final/GRAM_NEGA_2014_055_STRICT_T_150_REFINEFINAL1.xmap
}

print "Done generating comparisons of BioNano and in silico genome maps\n";