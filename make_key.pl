#!/usr/bin/perl

use strict;
use warnings;

# STEP 1
# this script outputs a cmap_key for the ./query_agp.pl script
# USAGE: perl make_key.pl [fasta]

open FASTA, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: !";
if (-e "$ARGV[0]"."_key") {print "$ARGV[0]_key file Exists!\n"; exit;}
open KEY, '>', "$ARGV[0]"."_key" or die "Couldn't open $ARGV[0]_key: $!";
print KEY "# Chromosome\tKnown(K) or Unknown (U)\tfastaHead\tfastaID\tcontigID\total length of contigs\tfastaStart\tfastaStop\n";

my $counter=-1;
my $sum=0;
$/=">";
while (<FASTA>)
{
    ++$counter;
    if ($counter >= 1)
    {
        my ($header,@seq)=split/\n/;
        my $seq=join '', @seq;
        my $scaffold_stop=(length($seq))-1;
        $seq =~ s/N//g;
        my $cumulative_length=(length($seq))-1;
        my @contigs= split(/N+/,$seq);
        $sum+=scalar(@contigs);
        print KEY "NA\tNA\t$header\tNA\t$counter\t$cumulative_length\t0\t$scaffold_stop\n";
        
    }
    
}
print "$sum contigs read\n";

