#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl CheckHeaders.pl [fasta]
#	Script to find redundant Super-scaffold ids in a Fasta file and rename each fasta with unique ids. This script fixes Fasta files after iterative use of Stitch.pl
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
use File::Basename; # enable manipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
# use Bio::SeqIO;
# use Bio::Seq;
# use Bio::DB::Fasta;
###############################################################################
##############                Initialize variables           ##################
###############################################################################
# my $dirname = dirname(__FILE__);
my $fasta_in = $ARGV[0];
my (${filename},${directories},${suffix}) = fileparse($fasta_in,'\..*'); #trailing slash
my $fasta_out = "${directories}${filename}_temp.${suffix}";
my %super_scaffold_hash;
###############################################################################
##############                      Run                      ##################
###############################################################################
open (FASTAOUT, ">", $fasta_out) or die "can't open $fasta_out\n";
open (FASTAIN, "<", $fasta_in) or die "can't open $fasta_in\n!";
while (<FASTAIN>)
{
    if (/>Super_scaffold_/)
    {
        chomp;
        /^>Super_scaffold_(.*)/;
        my $ss = $1;
        while ($super_scaffold_hash{$ss})
        {
            $ss++;
        }
        $super_scaffold_hash{$ss} = 1;
        print FASTAOUT ">Super_scaffold_$ss\n";
    }
    else
    {
        print FASTAOUT;
    }
}

my $rm = `rm $fasta_in`;
print "$rm\n";
my $mv = `mv $fasta_out $fasta_in`;
print "$mv";
print "done\n";

