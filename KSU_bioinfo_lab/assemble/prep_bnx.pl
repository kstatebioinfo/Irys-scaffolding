#!/bin/perl
###############################################################################
#
#	USAGE: perl prep_bnx.pl [dataset list] [bnx directory]
#
#  Created by jennifer shelton
#
# Script moves Molecules.bnx files into a common bnx directory and renames with auto-incremented numbers. Make paths absolute and do not include trailing spaces in paths.

# The script takes a list of flowcell directories (e.g. one directory up from the Molecules.bnx files) and the new BNX directory name. This organizes the raw data in the correct format to run AssembleIrys.pl.

# rename 's/ /_/g' /home/irys/Data/Datasets/*
#
# Example: perl /home/irys/Data/Goni_pect_0004/Irys-scaffolding/KSU_bioinfo_lab/assemble/prep_bnx.pl /home/irys/Data/Goni_pect_0004/bnx_original_list.txt /home/irys/Data/Goni_pect_0004/bnx
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
    my $link= `ln -s \'${file}/Detect Molecules/Molecules.bnx\' \'${directory}/Molecules_${i}.bnx\'`;
    print "$link";
    ++$i;
}
