#!/usr/bin/perl
################################################################################
#   
#	USAGE: perl assemble.pl <assembly_directory> <p_value Threshold> <project prefix> <genome size> <reference>
#
#  Created by Jennifer Shelton
#
################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
#use XML::Simple;
#use Data::Dumper;
use File::Basename; # enable manipulating of the full path
################################################################################
##############       Customize BioNano Script Settings        ##################
################################################################################
# This pipeline was designed to run on a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization of this section may be required to run the BioNano Assembler on a different machine. Customization of Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/clusterArguments.xml may also be required for assembly to run successfully on a different cluster.
my $pipelineCL = $ENV{"HOME"} ."/scripts/pipelineCL.py"; #Change if not ~/scripts/pipelineCL.py
unless (-f $pipelineCL)
{
    die "Can't find pipelineCL.py at $pipelineCL . Please add correct path to assemble.pl and retry:\n $!";
}
my $tools = $ENV{"HOME"} ."/tools/"; #Change if not ~/tools
unless (-d $tools)
{
    die "Can't find the BioNano directory \"tools\" at $tools . Please add correct path to assemble.pl and retry:\n $!";
}
################################################################################
##############                     get arguments              ##################
################################################################################
my $assembly_directory = $ARGV[0];
my $T = $ARGV[1];
my $project = $ARGV[2];
my $genome = $ARGV[3];
my $de_novo=1; # project is de novo
if ($ARGV[4])
{
    if (-f "$ARGV[4]")
    {
        $de_novo=0; # change project is not de novo because a reference CMAP exists
        print "de_novo = false\n";

    }
}
else
{
    print "de_novo = true\n";
}
my $ref;
unless($de_novo == 1)
{
    $ref = $ARGV[4];
    print "ref = $ARGV[4]\n";
}
print "assembly_directory = $ARGV[0]\n";
print "T = $ARGV[1]\n";
my $dirname = dirname(__FILE__); # has no trailing slash
################################################################################
##############              get parameters for XML            ##################
################################################################################
my $T_relaxed = $T * 10;
my $T_strict = $T/10;
my ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square,$LabelDensity);
my $merged_error_file = "${assembly_directory}/all_flowcells/bnx_merged_rescaled_final.err";
#0Iteration	1FP(/100kb)	2FNrate	3SiteSD(Kb)	4ScalingSD(Kb^1/2)	5bpp	6res(pixels)	7Maps	8Log10LR(/Maps)	9GoodMaps	10log10LR(/GoodMaps)	11bppSD	12FPrate	13RelativeSD	14ResolutionSD	15LabelDensity(/100kb)	16resSD	17mres	18mresSD
unless($de_novo == 1)
{
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
    print "Label Density for aligned molecule maps per 100 kb: $LabelDensity\n";
}
################################################################################
##############  Select optArguments.xml file based on genome size ##############
################################################################################
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
################################################################################
##############                 parse XML                      ##################
################################################################################
my %p_value = (
    'default_t_150' => "$T",
    'relaxed_t_150' => "$T_relaxed",
    'strict_t_150' => "$T_strict",
    'default_t_100' => "$T",
    'relaxed_t_100' => "$T_relaxed",
    'strict_t_100' => "$T_strict",
    'default_t_180' => "$T",
    'relaxed_t_180' => "$T_relaxed",
    'strict_t_180' => "$T_strict"
);
my @commands = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180/;
unless($de_novo == 1) # if the project is not de novo then make one assembly to test the effect of the default noise parameters
{
    $p_value{'default_t_default_noise'} = "$T";
    push(@commands, 'default_t_default_noise');
}
open (my $out_assemble, '>',"${assembly_directory}/assembly_commands.sh"); # for assembly commands
##################################################################
##############        Write bash scripts        ##################
##################################################################
print $out_assemble "#!/bin/bash\n";
print $out_assemble "##################################################################\n";
print $out_assemble "#####                  ASSEMBLY COMMANDS                     #####\n";
print $out_assemble "##################################################################\n";
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
    unless ($stringency eq 'default_t_default_noise')# skip adjusting molecule length parameter based on the assembly name for the default_noise assembly
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
#            print "Yes#6\n";
            next CUSTOMXML;
        }
        elsif (/<flag attr=\"-T\".*group=\"Extension and Refinement\"/)
        {
            my $new_p=$p_value{$stringency}/10;
            s/(val0=\")(.*)(\"\s+display.*group=\"Extension and Refinement\".*)/$1${new_p}$3/;
            print $optarg_final "$_";
#            print "Yes#7\n";
            next CUSTOMXML;
        }
        elsif (/<flag attr=\"-T\".*group=\"Merge\"/)
        {
            my $final_p=$p_value{$stringency}/10000;
            s/(val0=\")(.*)(\"\s+display.*group=\"Merge\".*)/$1${final_p}$3/;
            print $optarg_final "$_";
#            print "Yes#8\n";
            next CUSTOMXML;
        }
        elsif (/<flag attr=\"-minlen\".*group=\"BNX Sort\"/)
        {
#            <flag attr="-minlen"      val0="150" display="Molecule Length Threshold (Kb)" group="BNX Sort" default0="150" description="Minimum length of molecules (kb) that are used in BNX sort. This will also be the minimum length used for all downstream Pipeline stages (entire assembly)." />
            s/(.*val0=\")(.*)(\"\s+display=\"Molecule Length Threshold.*)/$1${min_length}$3/;
            print $optarg_final "$_";
#            print "Yes#1\n";
            next CUSTOMXML;
        }
        elsif ($stringency ne 'default_t_default_noise')# skip adjusting molecule length and noise parameters for the default_noise assembly or any de novo assembly
        {
            if ($de_novo == 0)
            {

                if (/<flag attr=\"-FP\".*group=\"DeNovo Assembly Noise\"/)
                {
                    s/(<flag attr=\"-FP\" val0=\")(.*)(\"\s+display.*)/$1${FP}$3/;
                    print $optarg_final "$_";
#                    print "Yes#2\n";
                    next CUSTOMXML;
                }
                elsif (/<flag attr=\"-FN\".*group=\"DeNovo Assembly Noise\"/)
                {
                    s/(<flag attr=\"-FN\" val0=\")(.*)(\"\s+display.*)/$1${FN}$3/;
                    print $optarg_final "$_";
#                    print "Yes#3\n";
                    next CUSTOMXML;
                }
                elsif (/<flag attr=\"-sd\".*group=\"DeNovo Assembly Noise\"/)
                {
                    s/(val0=\")(.*)(\"\s+display.*)/$1${ScalingSD_Kb_square}$3/;
                    print $optarg_final "$_";
#                    print "Yes#4\n";
                    next CUSTOMXML;
                }
                elsif (/<flag attr=\"-sf\".*group=\"DeNovo Assembly Noise\"/)
                {
                    s/(val0=\")(.*)(\"\s+display.*)/$1${SiteSD_Kb}$3/;
                    print $optarg_final "$_";
#                    print "Yes#5\n";
                    next CUSTOMXML;
                }
            }
        }
        print $optarg_final "$_"; # print any unchanged line
    }
    ##################################################################
    ##############        Write assembly command    ##################
    ##################################################################
    print $out_assemble "##################################################################\n";
    print $out_assemble "#####             ASSEMBLY: ${stringency}                \n";
    print $out_assemble "##################################################################\n";
#    /home/mic_common/scripts_fresh/pipelineCL.py -y -d -U -T 240 -N 6 -j 240 -i 5 -l /home/irys/data/human_100x_test/output/ -t /usr/src/genome_grid/configurations/Human_hg19/tools -C /home/irys/data/human_100x_test/clusterArguments.xml -b /home/irys/data/human_100x_test/input.bnx -r /home/irys/data/human_100x_test/ref.cmap -a /home/irys/data/human_100x_test/optArguments.xml
    if ($min_length != 150)
    {
        print $out_assemble "#"; #start with default min length assemblies by commenting other assemblies
    }
    if ($de_novo == 1)
    {
        print $out_assemble "python2 $pipelineCL -T 240 -j 240 -N 6 -i $iterations -a $xml_final -w -t $tools -l $out_dir -b ${assembly_directory}/all_flowcells/bnx_merged.bnx -V 1 -e ${project}_${stringency} -p 0 -U -C ${dirname}/clusterArguments.xml\n";
    }
    else
    {
        print $out_assemble "python2 $pipelineCL -T 240 -j 240 -N 6 -i $iterations -a $xml_final -w -t $tools -l $out_dir -b ${assembly_directory}/all_flowcells/bnx_merged_adj_rescaled.bnx -V 1 -e ${project}_${stringency} -p 0 -r $ref -U -C ${dirname}/clusterArguments.xml\n";
    }
    if ($min_length != 150)
    {
        print $out_assemble "#"; #start with default min length assemblies by commenting other assemblies
    }
    print $out_assemble "bash ${dirname}/rm_intermediate_files.sh ${assembly_directory} ${stringency} ${project}\n";
}

print "Done writing assembly scripts.\n";

