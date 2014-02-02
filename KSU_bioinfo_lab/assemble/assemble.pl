#!/bin/perl
##################################################################################
#   
#	USAGE: perl assemble.pl [bnx_dir] [reference] [p_value Threshold] [script directory]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use XML::Simple;
##################################################################################
##############                     get arguments                ##################
##################################################################################
my $bnx_dir = $ARGV[0];
my $ref = $ARGV[1];
my $T = $ARGV[2];
my $dirname = $ARGV[3];
my $err="${bnx_dir}/all_flowcells_adj_merged_bestref.err";
##################################################################################
##############              get parameters for XML              ##################
##################################################################################
my $T_relaxed = $T * 10;
my $T_strict = $T/10;
my $pairmerge=75;
my ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square);
open (ERR,'<',"$err") or die "can't open $err!\n";
while (<ERR>) # get noise parameters
{
    if (eof)
    {
        my @values=split/\t/;
        for my $value (@values)
        {
            s/\s+//g;
        }
        my $map_ratio = $values[9]/$values[7];
        ($FP,$FN,$SiteSD_Kb,$ScalingSD_Kb_square)=($values[1],$values[2],$values[3],$values[4]);
    }
}

##################################################################################
##############                 parse XML                        ##################
##################################################################################

my %p_value = (
'strict_t' => "$T_strict",
'default_t' => '$T',
'relaxed_t' => '$T_relaxed',
);

for my $stringency (keys %p_value)
{
    my $xml_infile = "${dirname}/optArguments.xml";
    my $xml_outfile = "${bnx_dir}/${stringency}_optArguments.xml";
    my $xml = XMLin($xml_infile,KeepRoot => 1,ForceArray => 1,);
    
    ########################################
    ##             Pairwise               ##
    ########################################
    $xml->{pairwise}->{flag}->[0]->{val0} = $p_value{$stringency};
    ########################################
    ##               Noise                ##
    ########################################
    $xml->{noise0}->{flag}->[0]->{val0} = $FP;
    $xml->{noise0}->{flag}->[1]->{val0} = $FN;
    $xml->{noise0}->{flag}->[2]->{val0} = $ScalingSD_Kb_square;
    $xml->{noise0}->{flag}->[3]->{val0} = $SiteSD_Kb;
    ########################################
    ##            Assembly                ##
    ########################################
    $xml->{assembly}->{flag}->[0]->{val0} = $p_value{$stringency};
    ########################################
    ##              RefineA               ##
    ########################################
    $xml->{refineA}->{flag}->[2]->{val0} = $p_value{$stringency};
    ########################################
    ##              RefineB               ##
    ########################################
    $xml->{refineB}->{flag}->[2]->{val0} = $p_value{$stringency}/10;
    $xml->{refineB}->{flag}->[9]->{val0} = 25; #min split length
    ########################################
    ##              RefineFinal           ##
    ########################################
    $xml->{refineFinal}->{flag}->[2]->{val0} = $p_value{$stringency}/10;
    $xml->{refineFinal}->{flag}->[16]->{val0} = 1e-5;
    $xml->{refineFinal}->{flag}->[17]->{val0} = 1e-5;
    ########################################
    ##              Extension             ##
    ########################################
    $xml->{extension}->{flag}->[3]->{val0} = $p_value{$stringency}/10;
    $xml->{extension}->{flag}->[20]->{val0} = 1e-5;
    $xml->{extension}->{flag}->[20]->{val0} = 1e-5;
    ########################################
    ##               Merge                ##
    ########################################
    $xml->{merge}->{flag}->[0]->{val0} = 75;
    $xml->{merge}->{flag}->[1]->{val0} = $p_value{$stringency}/1000;
    XMLout($xml,KeepRoot => 1,NoAttr => 1,OutputFile => $xml_outfile,);
}