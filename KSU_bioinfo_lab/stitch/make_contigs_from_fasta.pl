#!/usr/bin/perl

use strict;
use warnings;

# this script breaks scaffolds at Ns and outputs a new multi fasta file with one entry per contig and creates an agp for this
# USAGE: perl make_contigs_from_fasta.pl [fasta]

open FASTA, '<', $ARGV[0] or die "Couldn't open $ARGV[0]: $!";
open CONTIGFA, '>', "$ARGV[0]"."_contig.fasta" or die "Couldn't create $ARGV[0]_contig.fasta: $!";
open AGP, '>', "$ARGV[0]"."_contig.agp" or die "Couldn't create $ARGV[0]_contig.agp: $!";


my $counter=-1;
my $sum=0;
my $tcas_id = 1;
$/=">";
while (<FASTA>)
{
    ++$counter;
    if ($counter >= 1)
    {
        my ($header,@seq)=split/\n/;
        my $seq=join '', @seq;
        $seq =~ s/>//g;
        my @contigs= split(/N+/i,$seq);
        my @gaps=split(/[AGCT]+/i,$seq);
        my $gap_count = (scalar(@gaps)-1);
        print "GAP COUNT: $gap_count\n";
        for my $gap (@gaps)
        {
            #            print "Gap: $gap\n\n";
        }
        my $gap_counter=1;
        my $pos = 1;
        my $agp_element=1;
        foreach my $broken (@contigs)
        {
            print CONTIGFA ">tcas_${tcas_id}".'[organism=Triboliumcastaneum][strain=GeorgiaGA2][country=USA:Kansas][collection-date=Apr-2003]'."\n";
            #            >tcas_1000[organism=Triboliumcastaneum][strain=GeorgiaGA2][country=USA:Kansas][collection-date=Apr-2003]
            print CONTIGFA "$broken\n";
            my $contig_length = length($broken);
            my $stop = $pos + $contig_length - 1;
            print AGP "${header}\t$pos\t$stop\t$agp_element\tW\ttcas_${tcas_id}\t1\t${contig_length}\t+\n";
            ++$agp_element;
            if ($gaps[$gap_counter])
            {
                $pos = $stop + 1;
                my $gap_length = length($gaps[$gap_counter]);
                $stop = $pos + $gap_length - 1;
                print AGP "${header}\t$pos\t$stop\t$agp_element\tN\t${gap_length}\tscaffold\tyes\tunspecified\n";
                ++$agp_element;
                ++$gap_counter;
            }
            ++$tcas_id;
            $pos = $stop + 1;
        }
        
    }
    
}
