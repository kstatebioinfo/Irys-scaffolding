#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl assemble.pl <assembly_directory> <reference> <p_value Threshold> <project prefix> <genome size>
#
#  Created by Jennifer Shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
#use XML::Simple;
#use Data::Dumper;
use File::Basename; # enable manipulating of the full path
##################################################################################
##############                     get arguments                ##################
##################################################################################
my $assembly_directory = $ARGV[0];
my $ref = $ARGV[1];
my $T = $ARGV[2];
my $project = $ARGV[3];
my $genome = $ARGV[4];
print "assembly_directory = $ARGV[0]\n";
print "ref = $ARGV[1]\n";
print "T = $ARGV[2]\n";
my $dirname = dirname(__FILE__); # has no trailing slash
##################################################################################
##############              get parameters for XML              ##################
##################################################################################
my $T_relaxed = $T * 10;
my $T_strict = $T/10;
my ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square,$LabelDensity);

my $merged_error_file = "${assembly_directory}/all_flowcells/bnx_merged_rescaled_final.err";

#0Iteration	1FP(/100kb)	2FNrate	3SiteSD(Kb)	4ScalingSD(Kb^1/2)	5bpp	6res(pixels)	7Maps	8Log10LR(/Maps)	9GoodMaps	10log10LR(/GoodMaps)	11bppSD	12FPrate	13RelativeSD	14ResolutionSD	15LabelDensity(/100kb)	16resSD	17mres	18mresSD
open (my $merged_error, "<", $merged_error_file) or die "Can't open $merged_error_file!\n";
while (<$merged_error>)
{
    if (/^4\t/)
    {
        ($LabelDensity)=(split/\t/)[15]; # because the final label density is reported as 0
    }
    elsif (/^5\t/)
    {
        ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square)=(split/\t/)[1,2,3,4];
    }
}
print "Label Density per 100 kb: $LabelDensity\n";
##################################################################################
##############  Select optArguments.xml file based on genome size ################
##################################################################################
my $xml_infile;
my $iterations = 5;
if ( $genome < 100 )
{
    $xml_infile = "${dirname}/optArguments_small.xml";
}
elsif ( $genome < 1000 )
{
    $xml_infile = "${dirname}/optArguments_medium.xml";
}
else
{
    $xml_infile = "${dirname}/optArguments_human.xml";
    $iterations = 2; # Can lower the number of itereations for large genomes in future if needed

}

##################################################################################
##############                 parse XML                        ##################
##################################################################################

my %p_value = (
    'default_t_150' => "$T",
    'relaxed_t_150' => "$T_relaxed",
    'strict_t_150' => "$T_strict",
    'default_t_100' => "$T",
    'relaxed_t_100' => "$T_relaxed",
    'strict_t_100' => "$T_strict",
    'default_t_180' => "$T",
    'relaxed_t_180' => "$T_relaxed",
    'strict_t_180' => "$T_strict",
    'default_t_default_noise' => "$T"

);
open (my $out_assemble, '>',"${assembly_directory}/assembly_commands.sh"); # for assembly commands
##################################################################
##############        Write bash scripts        ##################
##################################################################

print $out_assemble "#!/bin/bash\n";
print $out_assemble "##################################################################\n";
print $out_assemble "#####             ASSEMBLY COMMANDS                    #####\n";
print $out_assemble "##################################################################\n";
my @commands = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180 default_t_default_noise/;
for my $stringency (@commands)
{
    my $current_p_value = $p_value{$stringency};
    ##################################################################
    ##############     Create assembly directories  ##################
    ##################################################################
    my $out_dir = "${assembly_directory}/${stringency}";
    unless(mkdir $out_dir)
    {
		die "Exiting because unable to create $out_dir\n";
	}
    ##################################################################
    ##############        Set assembly parameters   ##################
    ##################################################################
    my $xml_final = "${assembly_directory}/${stringency}/${stringency}_final_optArguments.xml";
    my $min_length = 150;
    unless ($stringency eq 'default_t_default_noise') # skip adjusting molecule length parameter based on the assembly name for the default_noise assembly
    {
        $stringency =~ /.*_t_(.*)/;
        $min_length = $1;
    }
    open (my $optarg_final, '>', $xml_final) or die "Can't open $xml_final\n";
    open (my $optarg, '<', $xml_infile ) or die "Can't open $xml_infile\n";
    
    CUSTOMXML: while (<$optarg>)
    {
        if (/<flag attr=\"-T\".*group=\"Initial Assembly\"/)
        {
            s/(val0=\")(.*)(\"\s+display.*group=\"Initial Assembly\".*)/$1$p_value{$stringency}$3/;
            print $optarg_final "$_";
            next CUSTOMXML;
        }
        elsif (/<flag attr=\"-T\".*group=\"Extension and Refinement\"/)
        {
            my $new_p=$p_value{$stringency}/10;
            s/(val0=\")(.*)(\"\s+display.*group=\"Extension and Refinement\".*)/$1${new_p}$3/;
            print $optarg_final "$_";
            next CUSTOMXML;
#                        print "Yes#6\n";
        }
        elsif (/<flag attr=\"-T\".*group=\"Merge\"/)
        {
            my $final_p=$p_value{$stringency}/10000;
            s/(val0=\")(.*)(\"\s+display.*group=\"Merge\".*)/$1${final_p}$3/;
            print $optarg_final "$_";
            next CUSTOMXML;
#                        print "Yes#7\n";
        }
        elsif (/<flag attr=\"-minlen\".*group=\"BNX Sort\"/)
        {
#            <flag attr="-minlen"      val0="150" display="Molecule Length Threshold (Kb)" group="BNX Sort" default0="150" description="Minimum length of molecules (kb) that are used in BNX sort. This will also be the minimum length used for all downstream Pipeline stages (entire assembly)." />
            s/(.*val0=\")(.*)(\"\s+display=\"Molecule Length Threshold.*)/$1${min_length}$3/;
            print $optarg_final "$_";
            next CUSTOMXML;
#                        print "Yes#1\n";
        }
        elsif ($stringency ne 'default_t_default_noise') # skip adjusting molecule length and noise parameters for the default_noise assembly
        {

            if (/<flag attr=\"-FP\".*group=\"DeNovo Assembly Noise\"/)
            {
                s/(<flag attr=\"-FP\" val0=\")(.*)(\"\s+display.*)/$1${FP}$3/;
                print $optarg_final "$_";
    #            print "Yes#2\n";
                next CUSTOMXML;
            }
            elsif (/<flag attr=\"-FN\".*group=\"DeNovo Assembly Noise\"/)
            {
                s/(<flag attr=\"-FN\" val0=\")(.*)(\"\s+display.*)/$1${FN}$3/;
                print $optarg_final "$_";
    #            print "Yes#3\n";
                next CUSTOMXML;
            }
            elsif (/<flag attr=\"-sd\".*group=\"DeNovo Assembly Noise\"/)
            {
                s/(val0=\")(.*)(\"\s+display.*)/$1${ScalingSD_Kb_square}$3/;
                print $optarg_final "$_";
    #            print "Yes#4\n";
                next CUSTOMXML;
            }
            elsif (/<flag attr=\"-sf\".*group=\"DeNovo Assembly Noise\"/)
            {
                s/(val0=\")(.*)(\"\s+display.*)/$1${SiteSD_Kb}$3/;
                print $optarg_final "$_";
                next CUSTOMXML;
            }
        }
        print $optarg_final "$_"; # print any unchanged line
    }
    ##################################################################
    ##############        Write assembly command    ##################
    ##################################################################
    print $out_assemble "##################################################################\n";
    print $out_assemble "#####           ASSEMBLY: ${stringency}                \n";
    print $out_assemble "##################################################################\n";
#    /home/mic_common/scripts_fresh/pipelineCL.py -y -d -U -T 240 -N 6 -j 240 -i 5 -l /home/irys/data/human_100x_test/output/ -t /usr/src/genome_grid/configurations/Human_hg19/tools -C /home/irys/data/human_100x_test/clusterArguments.xml -b /home/irys/data/human_100x_test/input.bnx -r /home/irys/data/human_100x_test/ref.cmap -a /home/irys/data/human_100x_test/optArguments.xml
    if ($min_length != 150)
    {
        print $out_assemble "#"; #start with default min length assemblies by commenting other assemblies
    }
    print $out_assemble "python2 ~/scripts/pipelineCL.py -T 240 -j 240 -N 6 -i $iterations -a $xml_final -w -t ~/tools/ -l $out_dir -b ${assembly_directory}/all_flowcells/bnx_merged_adj_rescaled.bnx -V 1 -e ${project}_${stringency} -p 0 -r $ref -U -C ${dirname}/clusterArguments.xml\n";
    print $out_assemble "bash ${dirname}/rm_intermediate_files.sh ${assembly_directory} ${stringency} ${project}\n";
}

print "Done writing assembly scripts.\n";

