#!/bin/perl
##################################################################################
#   
#	USAGE: perl number_fasta.pl [fasta] 
# converts headers to autoincremented numbers
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
##################################################################################
##############                      notes                       ##################
##################################################################################
my $fasta_in=$ARGV[0];
open (FASTA_IN,"<",$fasta_in) or die "can't open $fasta_in $!";
$fasta_in =~ /(.*).fa/;
my $fasta_out="$1_super_scaffold.fasta";
open (FASTA_OUT,">",$fasta_out) or die "can't open $fasta_out $!";
my $n=1;
while (<FASTA_IN>)
{
	chomp;
	if (/>/)
	{
		print FASTA_OUT ">$n\n";
		++$n;
	}
	else
	{
		print FASTA_OUT "$_\n";
	}
}
