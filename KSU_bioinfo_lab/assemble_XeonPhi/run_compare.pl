#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl run_compare.pl
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: # Copy script into assembly working directory and update other variables for project in "Project variables" section. To do this cd to the assembly working directory and "cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl ." and then edit the new version to point to the best asssembly or the best assembly CMAP.
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
use File::Basename; # enable manipulating of the full path
#####################################################################
########################  Project variables  ########################
#####################################################################
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
      die "File paths in the \"Project variables\" section of run_compare.pl are not valid. Remember to copy the run_compare.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP.\n";
}
unless($enzyme =~ /(BspQI|BbvCI|BsrDI|bseCI)/)
{
    die "Enzymes listed in the \"Project variables\" section of run_compare.pl are not valid. Valid entries would be a space separated list that includes one or more of the following options \"BspQI BbvCI BsrDI bseCI\". Remember to copy the run_compare.pl script into your assembly working directory and update other variables for project in \"Project variables\" section. To do this cd to the assembly working directory and \"cp ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/run_compare.pl .\" and then edit the new version to point to the best asssembly or the best assembly CMAP.\n";
}
###########################################################
#                  Default alignments
###########################################################
my %alignment_parameters;
$alignment_parameters{'default_alignment'} ="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10";
###########################################################
#                  Relaxed alignments
###########################################################
$alignment_parameters{'relaxed_alignment'} ="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15";

my (${genome_map_filename}, ${genome_map_directories}, ${genome_map_suffix}) = fileparse($genome_map_cmap,qr/\.[^.]*/); # directories has trailing slash
my (${filename}, ${directories}, ${suffix}) = fileparse($fasta,qr/\.[^.]*/); # directories has trailing slash
#my (${filename_cmap}, ${directories_cmap}, ${suffix_cmap}) = fileparse($cmap,qr/\.[^.]*/); # directories has trailing slash
my @alignments = qw/default_alignment relaxed_alignment/;

my $alignment_log_file = "$best_dir/../analysis_alignment_log.txt";
open (my $alignment_log, ">", $alignment_log_file) or die "Can't open $alignment_log_file: $!";
my $stitch_log_file = "$best_dir/../analysis_stitch_log.txt";
open (my $stitch_log, ">", $stitch_log_file) or die "Can't open $stitch_log_file: $!";
for my $stringency (@alignments)
{
    unless(mkdir "$best_dir/../$stringency")
    {
        print "Unable to create $best_dir/../$stringency\n";
    }
    ###########################################################
    #                         Align
    ###########################################################
    print "Running first alignments and comparison for $stringency stringency...\n";
    print $alignment_log "Running first alignments and comparison for $stringency stringency...\n";
    my $align = `~/tools/RefAligner -i ${genome_map_cmap} -ref $cmap -o ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem 256`;
    print $alignment_log "$align";
    ###########################################################
    #                 Get most metrics
    ###########################################################
    my $comparison_metrics_file = "${best_dir}/../${filename}_BNGCompare.csv";
    open (my $comparison_metrics, ">>", $comparison_metrics_file) or die "Can't open $comparison_metrics_file: $!";
    print $comparison_metrics "$stringency :\n";
    close($comparison_metrics);
    my $xmap_alignments = `perl ~/BNGCompare/BNGCompare.pl -f $fasta -r $cmap -q ${genome_map_cmap} -x ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap -o $comparison_metrics_file`;
    print $xmap_alignments;
    ###########################################################
    #                      Flip xmap
    ###########################################################
    my $flip =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}`;
    print $flip;
    ###########################################################
    #                 Get flipped metrics
    ###########################################################
    my $flip_align =  `perl ~/BNGCompare/xmap_stats.pl -x ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}.flip -o $comparison_metrics_file`;
    print "$flip_align";
    ###########################################################
    #                       Stitch1
    ###########################################################
    my $stitch_num=1;
    my $failed = 0;
    print "Running iteration of stitch number ${stitch_num}...\n";
    print $stitch_log "Running iteration of stitch number ${stitch_num}...\n";
    my $stitch_dir = "$best_dir/../${stringency}/stitch${stitch_num}";
    unless(mkdir $stitch_dir)
    {
        print "Unable to create $stitch_dir\n";
    }
    my $stitch_out =  `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}_q.cmap -x ${best_dir}/../${stringency}/${genome_map_filename}_to_${filename}.flip -f $fasta -o $stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1 --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
    my $agp_list_file = "$best_dir/../$stringency/agp_list.txt";
    open (my $agp_list, ">", $agp_list_file) or die "Can't open $agp_list_file: $!";
    ###########################################################
    #              Make filtered xmap
    ###########################################################
    my $make_filtered = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/get_passing_xmap.pl -f $best_dir/../${stringency}/stitch1/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1_all_filtered.xmap -o ${best_dir}/../${stringency}/${filename}_to_${genome_map_filename}.xmap`;
    print $make_filtered;
    ###########################################################
    #    Remove stitch directory if no scaffolds were made
    ###########################################################
    if ($stitch_out !~ /Super_scaffold_.*: Scaffolding molecule = .*/)
    {
        my $remove_failed_directory = `rm -r $stitch_dir`;
        print $remove_failed_directory;
        $failed = 1;
    }
    else
    {
        ###########################################################
        #               Add new output to AGP list
        ###########################################################
        print $agp_list "$stitch_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_superscaffold.agp\n";
        ###########################################################
        #              Print log of stitch
        ###########################################################
        print "$stitch_out";
        print $stitch_log "$stitch_out";
#        /home/bionano/bionano/Dros_psue_2014_012_tuesday/default_alignment/stitch1/Dros_psue_2014_012_20_40_15_90_1_all_filtered.xmap

    }
    ###########################################################
    #                    Iterate stitch
    ###########################################################
    while ($failed == 0)
    {
        ++$stitch_num;
        print "Running iteration of stitch number ${stitch_num}...\n";
        print $stitch_log "Running iteration of stitch number ${stitch_num}...\n";
        my $out_dir="${best_dir}/../${stringency}/stitch${stitch_num}/";
        my $previous_stitch= ${stitch_num} - 1;
        my $old_out_dir="${best_dir}/../${stringency}/stitch${previous_stitch}/";
        #Make CMAP
        my $make_cmap = `perl ~/bin/fa2cmap_multi.pl -v -i ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -e ${enzyme}`;
#        print $make_cmap;
        ###########################################################
        #                       Align scripts
        ###########################################################
        unless(mkdir $out_dir)
        {
            print "Unable to create $out_dir\n";
        }
        my $iter_xmap_alignments = `~/tools/RefAligner -i ${genome_map_cmap} -ref ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold*.cmap -o ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename} -res 2.9 $alignment_parameters{$stringency} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -T $T -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 1 -hash -hashdelta 50 -mres 1e-3 -insertThreads 4 -nosplit 2 -biaswt 0 -indel -rres 1.2 -f -maxmem 256`;
        print $alignment_log "$iter_xmap_alignments";
        ###########################################################
        #                       Flip xmap
        ###########################################################
        my $iter_flip_align = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}.xmap ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}`;
        print $iter_flip_align;
        ###########################################################
        #                      Call stitch
        ###########################################################
        my $iter_stitch_out = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${genome_map_filename}_q.cmap -x ${out_dir}${genome_map_filename}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}.flip -f ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num} --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}`;
        ###########################################################
        #    Remove stitch directory if no scaffolds were made
        ###########################################################
        if ($iter_stitch_out !~ /Super_scaffold_.*: Scaffolding molecule = .*/)
        {
            my $remove_failed_directory = `rm -r $out_dir`;
            print $remove_failed_directory;
            $failed = 1;
            ###########################################################
            #                 Get super scaffold metrics
            ###########################################################
            my $superscaffold_metrics =  `perl ~/BNGCompare/N50.pl ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta $comparison_metrics_file`;
            print $superscaffold_metrics;
            my $collapse_agp = `perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/collapse_agp.pl -a $agp_list_file`;
            print $collapse_agp;
            ###########################################################
            #                 Remove intermediate directories
            ###########################################################
            if (${previous_stitch} > 1)
            {
                my $highest_intermediate_stitch = ${previous_stitch} - 1;
                for my $former_stitch_num (1..${highest_intermediate_stitch})
                {
                    my $former_out_dir="${best_dir}/../${stringency}/stitch${former_stitch_num}/";
                    if (-d $former_out_dir)
                    {
                        my $remove_intermediate = `rm -r $former_out_dir`;
                        print $remove_intermediate;
                    }
                }
            }
        }
        else
        {
            ###########################################################
            #               Add new output to AGP list
            ###########################################################
            print $agp_list "$out_dir/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_superscaffold.agp\n";
            ###########################################################
            #              Print log of stitch
            ###########################################################
            print "$iter_stitch_out";
            print $stitch_log "$iter_stitch_out";
        }
        
    }
}

print "Done generating comparisons of BioNano and in silico genome maps\n";
