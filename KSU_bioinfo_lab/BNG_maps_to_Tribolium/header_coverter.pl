#!/usr/bin/perl
use strict;
use warnings;
#  header_coverter.pl
#
# USAGE: perl header_coverter.pl [list of conflicting contigs file] [bionano header key]
#
# Script to replace bionano ids with the original contig headers.

################ get file names #############################################
my $infile1=$ARGV[0];
my $infile2=$ARGV[1];
my $outfile="$infile1"."_header.csv";

###################### define variables #####################################
my %header_hash;

open (CONFLICTS, "<$infile1")or die "can't open $infile1 $!";
open (HEADER_KEY, "<$infile2") or die "can't open $infile2 $!";
open (NEW_HEADER_KEY, ">$outfile") or die "can't open $outfile $!";
####### loop through key an make hash of bionano id and original id #########
while (<HEADER_KEY>) #make array of molecule contigs and a hash of their lengths
{
    if ($_ !~ /^#/)
    {
        chomp;
        s/\s+/\t/g;
        my @contig=split ("\t");
        $header_hash{$contig[2]}=$contig[0];
    }
}
my $i=0;
while (<CONFLICTS>) #make array of molecule contigs and a hash of their lengths
{
    if (($_ !~ /^#/) && ($i!=0))
    {
        chomp;
        my @conflict=split (',');
        print NEW_HEADER_KEY "$header_hash{$conflict[0]},$conflict[0],$header_hash{$conflict[1]},$conflict[1],$conflict[2]\n";
        
    }
    elsif ($i==0)
    {
        chomp;
        my @conflict=split (',');
        print NEW_HEADER_KEY "$conflict[0],bionano id for scaffold 1,$conflict[1],bionano id for scaffold 2,$conflict[2]\n";
        ++$i;
    }
}
        
