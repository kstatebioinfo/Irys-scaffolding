#!/bin/perl
###############################################################################
#
#	USAGE: perl prep_bnx.pl [dataset list] [bnx directory]
#
#  Created by jennifer shelton
#
# Script moves RawMolecules.bnx files into a common bnx directory and renames with auto-incremented numbers. do not include trailing spaces in paths.
# rename 's/ /_/g' /home/irys/Data/Datasets/*
#
###############################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
#
#
###############################################################################
##############                 get arguments                 ##################
###############################################################################
my $raw_bnx_list=$ARGV[0];
my $i=1;
my $directory = $ARGV[1];
unless(mkdir $directory)
{
    print "Unable to create $directory\n";
}
###############################################################################
##############            Move and rename files              ##################
###############################################################################
open (RAW_BNX_LIST, '<',"$raw_bnx_list") or die "can't open $raw_bnx_list!\n";
while (<RAW_BNX_LIST>)
{
    chomp;
    my $file = $_;
    my $link= `ln -s \'${file}/Detect Molecules/Molecules.bnx\' \'${directory}/RawMolecules_${i}.bnx\'`;
    print "$link";
    ++$i;
}
