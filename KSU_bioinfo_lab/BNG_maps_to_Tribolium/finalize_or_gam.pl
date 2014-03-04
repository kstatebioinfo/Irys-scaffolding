#!/bin/perl
##################################################################################
#   
#	USAGE: perl finalize_or_gam.pl
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############                      notes                       ##################
##################################################################################

my %changed_header = ('>Scaffold0005 | ChLGX:1024246..1487259 | Scaffold128' => 'PairedContig_606'
my %changed_id = ("Scaffold297"=>"PairedContig_307", "Scaffold128"=>"PairedContig_606");

my $header;
$/=">";
my $seq_obj;
while (<FASTA>)
{
    my ($header,@seq)=split/\n/;
    my $seq=join '', @seq;
    if ($header =~ /^>/){next};
    $seq =~ s/>//g;
    $header =~ s/ //g; ## removed white space because bioperl doesn't allow it in headers
    # PairedContig_606
    if 
    $header =~ /Scaffold[0]*.*\|(Scaffold.*)/;