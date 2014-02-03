#!/bin/perl
##################################################################################
#   
#	USAGE: perl prep_data.pl [dataset list]
#
#  Created by jennifer shelton
#
# moves RawMolecules.bnx files into a common directory and renames with auto-incremented numbers
# rename 's/ /_/g' /home/irys/Data/Datasets/*
# 
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
# 
##################################################################################
##############                 get arguments                    ##################
##################################################################################
my $raw_bnx_list=$ARGV[0];
my $i=1;
my $directory = "/home/irys/Data/Trib_cast_0002";
unless(mkdir $directory) 
{
	die "Unable to create $directory\n";
}
##################################################################################
##############            Move and rename files                 ##################
##################################################################################
open (RAW_BNX_LIST, '<',"$raw_bnx_list") or die "can't open $raw_bnx_list!\n";
while (<RAW_BNX_LIST>) 
{
	my $file = $_;
	`mv $file $directory/RawMolecules_${i}.bnx`;
    ++$i;
}