#!/bin/perl
##################################################################################
#   
#	USAGE: perl assemble.pl [bnx_dir] [reference] [p-value Threshold] [script directory]
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
my pairmerge=75;
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
        ($FP,$FN,SiteSD_Kb,ScalingSD_Kb_square)=($values[1],$values[2],$values[3],$values[4]);
    }
}

##################################################################################
##############                 parse XML                        ##################
##################################################################################
my %p-value;
%hash = (
key1 => "$T_strict",
key2 => 'value2',
key3 => 'value3',
);

for my $stringency (keys %p-value)
{
    my $xml_infile = "${dirname}/optArguments.xml";
    my $xml_outfile = "${dirname}/${stringency}_optArguments.xml";
    my $xml = XMLin($xml_infile,KeepRoot => 1,ForceArray => 1,);
    
    $xml->{outer1}->[0]->{inner1}->[1]->{name} = 'hello';

    XMLout($xml,KeepRoot => 1,NoAttr => 1,OutputFile => $xml_outfile,);
}