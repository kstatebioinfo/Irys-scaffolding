#!/bin/perl
##################################################################################
#   
#	USAGE: perl analyze_irys_output.pl [r.cmap] [q.cmap] [xmap] [scaffold.fasta] [output_basename] [first min confidence] [first min % aligned] [second min confidence] [second min % aligned]
#	perl analyze_irys_output.pl sample.r.cmap sample_q.cmap sample.xmap sample_scaffold.fasta test_output 15 .3 6 .9
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
##################################################################################
##############            define variables                      ##################
##################################################################################

my ($r_cmap,$q_cmap,$xmap,$scaffold_fasta,$output_basename,$first_min_confidence,$first_min_per_aligned,$second_min_confidence,$second_min_per_aligned) = @ARGV;

my $path_to_scripts='';
my $path_to_data='';
##################################################################################
##############       call programs and report if files exist    ##################
##################################################################################
print "Making key for original fasta headers...\n";
my $makekey=`perl make_key.pl $scaffold_fasta`;
print "$makekey"; # print errors
print "Making filtered XMAP...\n";
my $filter=`perl xmap_filter.pl $r_cmap $q_cmap $xmap $output_basename $first_min_confidence $first_min_per_aligned $second_min_confidence $second_min_per_aligned ${scaffold_fasta}_key`;
print "$filter"; # print errors
$scaffold_fasta =~ /(.*).fa/;
print "Converting original fasta headers to headers that match bionano output...\n";
my $out_number=`perl number_fasta.pl $scaffold_fasta`;
print "$out_number";
print "Making super-scaffold fasta file with new super-scaffolds. Unused sequences are printed with original fasta headers...\n";
my $out_x_to_fasta=`perl xmap_to_fasta.pl ${output_basename}_scaffolds.xmap ${1}_numbered_scaffold.fasta ${scaffold_fasta}_key`;
print "$out_x_to_fasta";
if (-e "${output_basename}_data_summary.csv") {print "${output_basename}_data_summary.csv file Exists$!\n"; exit;}
##################################################################################
##############  compress summary files and delete temp files    ##################
##################################################################################
print "Removing temp files...\n";
open (SUMMARY,'>',"${output_basename}_data_summary.csv") or die "couldn't open ${output_basename}_data_summary.csv $!";
open (REPORT,'<',"${output_basename}_report.csv") or die "couldn't open ${output_basename}_report.csv $!";
print SUMMARY "Summary metrics from the filtered XMAP\n";
while (<REPORT>)
{
    print SUMMARY;
}
close (REPORT);
open (OVERLAPS,'<',"${output_basename}_overlaps.csv") or die "couldn't open ${output_basename}_overlaps.csv $!";
print SUMMARY "List of scaffolds that overlap on the super-scaffold. These are separated by 30 \"n\" gaps.\n";
while (<OVERLAPS>)
{
    print SUMMARY;
}
close (OVERLAPS);
open (WEAKPOINTS,'<',"${output_basename}_weakpoints.csv") or die "couldn't open ${output_basename}_weakpoints.csv $!";
print SUMMARY "List of scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible. These may represent mis-assembled scaffolds.\n";
while (<WEAKPOINTS>)
{
    print SUMMARY;
}
close (WEAKPOINTS);
unlink "${output_basename}_overlaps.csv","${output_basename}_weakpoints.csv","${output_basename}_report.csv","${1}_numbered_scaffold.fasta.index","${1}_numbered_scaffold.fasta";
print "Done\n";



