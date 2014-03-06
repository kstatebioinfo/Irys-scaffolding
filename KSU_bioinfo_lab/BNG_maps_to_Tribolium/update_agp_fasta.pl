#!/bin/perl
##################################################################################
#
#	USAGE: perl update_agp_fasta.pl
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
use Bio::SeqIO;
use Bio::Seq;
use Bio::DB::Fasta;
# use List::Util qw(max);
# use List::Util qw(sum);
###############################################################################
##############                      notes                    ##################
###############################################################################
open (REORIENTED_AGP, '<', 'tcas_scaff_from_contig_plus.agp')or die "can't open tcas_scaff_from_contig_plus.agp!\n";
open (GAM_AGP, '<', 'original_files/tcas.scaffolds_gam_only.fasta_contig.agp')or die "can't open original_files/tcas.scaffolds_gam_only.fasta_contig.agp!\n";
open (SCAFF_CONTIG_GAM_AGP,'>', "tcas_scaff_from_contig_gam_plus.agp") or die "can't open tcas_scaff_from_contig_gam_plus.agp!\n";
my %altered_scaffold=('Scaffold128' => 'PairedContig_606', 'Scaffold297'=>'PairedContig_307');
my %altered_scaffold_length = ('Scaffold128' => 460603, 'Scaffold297' => 12967);
my %new_scaffold = ('Scaffold1655' => undef, 'Scaffold661'=>undef, 'Scaffold1773' => undef, 'Scaffold378' => undef);
my %former_scaffolds = ('Scaffold128' => undef, 'Scaffold297' => undef, 'Scaffold1655' => undef, 'Scaffold661' => undef, 'Scaffold1773' => undef, 'Scaffold378' => undef);
#for my $former_scaffold (keys %former_scaffolds)
#{
#    print "|$former_scaffold|\n";
#}
my %contigs_to_remove;
my @gam_agp_array=<GAM_AGP>;
#######################################################################
##                      CORRECT CONTIG AGP                         ####
#######################################################################
while (<REORIENTED_AGP>)
{
    unless (/^#/)
    {
        chomp;
        my @row = split("\t");
        #        print "$row[0]\n";
        ###################################################################
        ##############          list contigs to remove   ##################
        ###################################################################
        if ((exists $former_scaffolds{$row[0]}) && ($row[4] eq 'W'))
        {
            undef $contigs_to_remove{$row[5]};
            print "$row[5]\n";
        }
        ###################################################################
        ##############      change altered scaffolds     ##################
        ###################################################################
        if ($altered_scaffold{$row[0]})
        {
            if ($altered_scaffold{$row[0]} ne '0')
            {
                for my $line (@gam_agp_array)
                {
                    chomp;
                    my @inner_row= split ("\t",$line);
                    if ($inner_row[0] eq $altered_scaffold{$row[0]})
                    {
                        $inner_row[0]=$row[0];
                        print SCAFF_CONTIG_GAM_AGP join("\t", @inner_row), "\n";
                    }
                }
                $altered_scaffold{$row[0]}= 0;
            }
            if ($altered_scaffold{$row[0]} eq '0')
            {
                next;
            }
        }
        ###################################################################
        ##############      change joined  scaffolds     ##################
        ###################################################################
        elsif (exists $new_scaffold{$row[0]})
        {
            next;
        }
        ###################################################################
        ##############      print unchanged scaffolds    ##################
        ###################################################################
        else
        {
            print SCAFF_CONTIG_GAM_AGP;
            print SCAFF_CONTIG_GAM_AGP "\n";
        }
    }
    ###################################################################
    ##############           print comments          ##################
    ###################################################################
    print SCAFF_CONTIG_GAM_AGP;
}

#######################################################################
##                    CORRECT CONTIG FASTA                         ####
#######################################################################
my $skipped=0;
open (REORIENTED_CONTIGS, '<', "tcas.contigs_plus.fasta") or die "couldn't open tcas.contigs_plus.fasta!\n";
my $out = "tcas.contigs_gam_plus.fasta";
my $seq_out = Bio::SeqIO->new('-file' => ">$out",'-format' => 'fasta');
$/=">";
while (<REORIENTED_CONTIGS>)
{
    my ($header,@seq)=split/\n/;
    my $seq=join '', @seq;
    $seq =~ s/>//g; ## removed the > used as record seperator
    $header =~ s/ //g; ## removed white space because bioperl doesn't allow it in headers
	if ($header =~ />/){next}; ## skip blank first record
    $header =~ /(.*).organism/;
    #######################################################################
    ##     print unchanged to  tcas_contigs_gam_plus.fasta             ####
    #######################################################################
    my $seq_obj = Bio::Seq->new( -display_id => $header, -seq => $seq);
    if (exists $contigs_to_remove{$1})
    {
        ++$skipped;
    }
    else
    {
        $seq_out->write_seq($seq_obj);
    }
}
#######################################################################
##       print changed to  tcas_contigs_gam_plus.fasta             ####
#######################################################################
my $added=0;
open (FASTA, '<', "original_files/tcas.scaffolds_gam_only.fasta_contig.fasta") or die "can't open original_files/tcas.scaffolds_gam_only.fasta_contig.fasta!\n";
$/=">";
while (<FASTA>)
{
    my ($header,@seq)=split/\n/;
    my $seq=join '', @seq;
    $seq =~ s/>//g; ## removed the > used as record seperator
    $header =~ s/ //g; ## removed white space because bioperl doesn't allow it in headers
	if ($header =~ />/){next}; ## skip blank first record
    #######################################################################
    ##              print to  tcas_contigs_plus.fasta                  ####
    #######################################################################
    my $seq_obj = Bio::Seq->new( -display_id => $header, -seq => $seq);
    $seq_out->write_seq($seq_obj);
    ++$added;
}

print "contigs skipped: $skipped and added: $added\n";











