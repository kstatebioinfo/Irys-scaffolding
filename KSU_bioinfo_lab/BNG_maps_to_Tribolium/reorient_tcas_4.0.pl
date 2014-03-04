#!/bin/perl
###############################################################################
#   
#	USAGE: perl reorient_tcas_4.0.pl [path to tcas4.0 files]
#   Step 1:cd [path to tcas4.0 files]
#   Step 1: curl -O ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_chromosome_from_component.agp
#   Step 1: curl -O ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_chromosome_from_scaffold.agp
#   Step 1: curl -O ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas_scaffold_from_component.agp
#   Step 1: curl -O ftp://ftp.bioinformatics.ksu.edu/pub/BeetleBase/4.0_draft/tcas.contigs.fasta
#   Step 2: perl reorient_tcas_4.0.pl [path to tcas4.0 files]
#   Step 3: perl /home/irys/Data/Irys-scaffolding/KSU_bioinfo_lab/BNG_maps_to_Tribolium/add_scaffold_to_header.pl tcas.in_silico.fasta tcas_chromosome_from_scaffold.agp
#   Step 3: perl /home/irys/Data/Irys-scaffolding/KSU_bioinfo_lab/BNG_maps_to_Tribolium/agp2bed.pl tcas.in_silico_header.fasta tcas_scaffold_from_component.agp
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
use Bio::SeqIO;
use Bio::Seq;
# use List::Util qw(max);
# use List::Util qw(sum);
###############################################################################
#### reverse tcas_chromosome_from_scaffold.agp find all to be reversed  #######
###############################################################################
my $dir = $ARGV[0];
my %reversed_scaffolds;
open (CHROME_FROM_SCAFF, '<', "${dir}/tcas_chromosome_from_scaffold.agp") or die "can't open ${dir}/tcas_chromosome_from_scaffold.agp !\n";
open (NEW_CHROME_FROM_SCAFF, '>', "${dir}/tcas_chlg_from_scaffold_plus.agp") or die "can't open ${dir}/tcas_chlg_from_scaffold_plus.agp !\n";
while (<CHROME_FROM_SCAFF>)
{
    unless (/^#/)
    {
        chomp;
        my @rows = split("\t");
        if ($rows[8] eq "-")
        {
            $reversed_scaffolds{$rows[4]} = 1;
            print "reversed_scaffolds: $rows[4]\n";
            $rows[8]='+';
            print NEW_CHROME_FROM_SCAFF join("\t", @rows), "\n";
        }
        else
        {
            print NEW_CHROME_FROM_SCAFF;
            print NEW_CHROME_FROM_SCAFF "\n";
        }

    }
    else
    {
        print NEW_CHROME_FROM_SCAFF;
    }
}
###############################################################################
##  reverse tcas_scaffold_from_component.agp find all to be reversed     ####
###############################################################################
open (SCAFF_FROM_COMP, '<', "${dir}/tcas_scaffold_from_component.agp") or die "can't open ${dir}/tcas_scaffold_from_component.agp !\n";
open (NEW_SCAFF_FROM_CONTIG, '>', "${dir}/tcas_scaff_from_contig_plus.agp") or die "can't open ${dir}/tcas_scaff_from_contig_plus.agp !\n"; ## changed name from tcas_scaffold_from_component.agp to tcas_scaff_from_contig_plus.agp because component is the generic name for the forth column in an AGP.
my @minus_scaffold;
my $current_scaffold=0;
while (<SCAFF_FROM_COMP>)
{
    unless (/^#/)
    {
        chomp;
        my @rows = split("\t");
        ###################################################################
        ##########  end a scaffold in the minus orientation ###############
        ###################################################################
        if ($current_scaffold ne '0')
        {
            if (($current_scaffold ne $rows[0]) || (eof))
            {
                if (eof)
                {
                    push (@minus_scaffold,$_); # make an array of the scaffold to be reversed
                }
                my $agp_part_number = 1;
                my $pos =1;
                for my $minus_row (reverse @minus_scaffold)
                {
                    my @minus_rows = split("\t",$minus_row);
                    $minus_rows[2] = ($minus_rows[2] - $minus_rows[1]) + $pos;
                    $minus_rows[1] = $pos;
                    $pos = $minus_rows[2] + 1;
                    $minus_rows[3] = $agp_part_number;
                    ++$agp_part_number;
                    print NEW_SCAFF_FROM_CONTIG join("\t", @minus_rows), "\n";
                }
                $current_scaffold=0;
                undef @minus_scaffold;
            }
        }
        ###################################################################
        ##########  start a scaffold in the minus orientation ###############
        ###################################################################
        if ($reversed_scaffolds{$rows[0]})
        {
            if ($current_scaffold eq '0')
            {
                $current_scaffold = $rows[0]; #initialize $current_scaffold
            }
            push (@minus_scaffold,$_); # make an array of the scaffold to be reversed
        }
        elsif (!$reversed_scaffolds{$rows[0]})
        {
            print NEW_SCAFF_FROM_CONTIG;
            print NEW_SCAFF_FROM_CONTIG "\n";
        }
    }
    else
    {
        print NEW_SCAFF_FROM_CONTIG;
    }
}

###############################################################################
##  reverse tcas_chromosome_from_component.agp find all to be reversed     ####
###############################################################################
open (CHROME_FROM_COMP, '<', "${dir}/tcas_chromosome_from_component.agp") or die "can't open ${dir}/tcas_chromosome_from_component.agp !\n";
open (NEW_CHROME_FROM_CONTIG, '>', "${dir}/tcas_chlg_from_contig_plus.agp") or die "can't open ${dir}/tcas_chlg_from_contig_plus.agp !\n"; ## changed name from tcas_chromosome_from_component.agp to tcas_chlg_from_contig_plus.agp because component is the generic name for the forth column in an AGP.
my %contigs_to_reverse;
while (<CHROME_FROM_COMP>)
{
    unless (/^#/)
    {
        chomp;
        my @rows = split("\t");
        if ($rows[8] eq '-')
        {
            $rows[8] = '+';
            print NEW_CHROME_FROM_CONTIG join("\t", @rows), "\n";
            $contigs_to_reverse{$rows[5]} = 1;
        }
        else
        {
         print NEW_CHROME_FROM_CONTIG;
         print NEW_CHROME_FROM_CONTIG "\n";
        }
    }
    else
    {
        print NEW_CHROME_FROM_CONTIG;
    }
}
###############################################################################
##                         reverse tcas_contigs.fasta                      ####
###############################################################################

open (FASTA, '<', "${dir}/tcas.contigs.fasta") or die "can't open ${dir}tcas.contigs.fasta !\n";
my $out = "${dir}/tcas.contigs_plus.fasta"; ## changed name to plus to indicate that they reversed if aligning in the minus direction to the superscaffold
my $seq_out = Bio::SeqIO->new('-file' => ">$out",'-format' => 'fasta');		#Create new fasta outfile object.
my $header;
$/=">";
while (<FASTA>)
{
    my ($header,@seq)=split/\n/;
    my $seq=join '', @seq;
    if ($header =~ /^>/){next};
    $seq =~ s/>//g;
    $header =~ s/ //g; ## removed white space because bioperl doesn't allow it in headers
    $header =~ /(.*).organism/;
    #######################################################################
    ##              print to  tcas_contigs_plus.fasta                  ####
    #######################################################################
    my $seq_obj = Bio::Seq->new( -display_id => $header, -seq => $seq);
    if ($contigs_to_reverse{$1})
    {
        $seq_out->write_seq($seq_obj->revcom);
        print "contig $header was reversed\n";
    }
    else
    {
        $seq_out->write_seq($seq_obj);
    }
    
}






