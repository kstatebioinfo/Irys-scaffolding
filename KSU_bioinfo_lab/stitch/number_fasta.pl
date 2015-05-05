#!/usr/bin/perl
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
use File::Basename; # enable maipulating of the full path
##################################################################################
##############                      notes                       ##################
##################################################################################
my $fasta_in=$ARGV[0];
open (FASTA_IN,"<",$fasta_in) or die "can't open $fasta_in !";
my (${fasta_filename}, ${fasta_directories}, ${fasta_suffix}) = fileparse($fasta_in,qr/\.[^.]*/); # directories has trailing slash
my $fasta_out = "${fasta_directories}${fasta_filename}_numbered_scaffold.fasta";
#print "FASTA_OUT: ${fasta_directories}${fasta_filename}_numbered_scaffold.fasta\n";
if (-e "$fasta_out") {print "$fasta_out file Exists!\n"; exit;}

open (FASTA_OUT,">",$fasta_out) or die "can't open $fasta_out !";
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
