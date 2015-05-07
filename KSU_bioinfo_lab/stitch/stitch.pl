#!/usr/bin/perl
#################################################################################
#
#	USAGE: perl stitch.pl [options]
#
#  Created by jennifer shelton
#
#################################################################################
use strict;
use warnings;
use File::Basename; # enable maipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
use Getopt::Long;
use Pod::Usage;
#################################################################################
##############         Print informative message               ##################
#################################################################################
print "###########################################################\n";
print "#  stitch.pl Version 1.4.7                                #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 12/12/13                   #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl stitch.pl -help # for usage/options               #\n";
print "#  perl stitch.pl -man # for more details                 #\n";
print "###########################################################\n";

#################################################################################
##############           get arguments and set defaults        ##################
#################################################################################
my ($r_cmap,$xmap,$scaffold_fasta,$output_basename); # Required
my $first_min_confidence=0; ## Default: No filter
my $first_min_per_aligned=0; ## Default: No filter
my $second_min_confidence=0; ## Default: No filter
my $second_min_per_aligned=0; ## Default: No filter
my $neg_gap = 20000; ## Default: Filter fails overlaps less than -20,000 (bp)
my $man = 0;
my $help = 0;
my $version = 0;
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    'version' => \$version,
    'r|r_cmap:s' => \$r_cmap,
    'x|xmap:s'  => \$xmap,
    'f|scaffold_fasta:s' => \$scaffold_fasta,
    'o|output_basename:s' => \$output_basename,
    'f_con|fc:f' => \$first_min_confidence,
    'f_algn|fa:f' => \$first_min_per_aligned,
    's_con|sc:f' => \$second_min_confidence,
    's_algn|sa:f' => \$second_min_per_aligned,
    'n|neg_gap:f'=> \$neg_gap
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version)
{
    print "stitch.pl Version 1.4.7\n";
    exit;
}
## convert percent aligned to decimal ##
$first_min_per_aligned=$first_min_per_aligned/100;
$second_min_per_aligned=$second_min_per_aligned/100;
my $dirname = dirname(__FILE__);
#################################################################################
##############                correct xmap order               ##################
#################################################################################
print "Correcting xmap order ...\n";
open (XMAP, "<", $xmap) or die "Can't open $xmap: $!";
my $sort_xmap = "${output_basename}_sort.xmap";
open (SORT_XMAP,">", $sort_xmap) or die "Can't open $sort_xmap: $!";
my @xmap_table;
while (<XMAP>) #make array of contigs from the customer and a hash of their lengths
{
	if ($_ =~ /^#/)
	{
		print SORT_XMAP;
	}
    elsif ($_ !~ /^#/)
	{
        chomp;
        unless ($_ eq '')
        {
            my @xmap=split ("\t");
            s/\s+//g foreach @xmap;
            push (@xmap_table, [@xmap]);
        }
        
	}
}
#################################################################################
my @a = ([1,2], [3,4]);
my @xmap_table_sorted = sort {
    
    $a->[2] <=> $b->[2] || # the result is -1,0,1 ...
    $a->[5] <=> $b->[5]    # so [1] when [0] is same
    
} @xmap_table;

print SORT_XMAP (join("\t", @$_), "\n") for @xmap_table_sorted;
close (SORT_XMAP);
$xmap = $sort_xmap;
#################################################################################
##############    make key (original headers to bionano cmap id)   ##############
#################################################################################
print "Making key for original fasta headers...\n";
my $makekey=`perl ${dirname}/make_key.pl $scaffold_fasta ${output_basename}`;
print "$makekey"; # print errors
#################################################################################
##########   make fasta with original headers changed to to bionano cmap id) ####
#################################################################################
my (${fasta_filename}, ${fasta_directories}, ${fasta_suffix}) = fileparse($scaffold_fasta,qr/\.[^.]*/); # directories has trailing slash
print "Converting original fasta headers to headers that match bionano output...\n";
my $out_number=`perl ${dirname}/number_fasta.pl $scaffold_fasta`;
print "$out_number";
#################################################################################
##################     filter xmap and create stitchmap        ##################
#################################################################################
print "Making filtered XMAP...\n";
my $filter=`perl ${dirname}/xmap_filter.pl $r_cmap ${fasta_directories}${fasta_filename}_numbered_scaffold.fasta $xmap $output_basename $first_min_confidence $first_min_per_aligned $second_min_confidence $second_min_per_aligned ${output_basename}_key $neg_gap`;
print "$filter"; # print errors
#################################################################################
#########      create fasta file and report "stitching contigs"        ##########
#################################################################################
print "Making super-scaffold fasta file with new super-scaffolds. Unused sequences are printed with original fasta headers...\n";
my $out_x_to_fasta=`perl ${dirname}/xmap_to_fasta.pl ${output_basename}_scaffolds.stitchmap ${fasta_directories}${fasta_filename}_numbered_scaffold.fasta ${output_basename}_key`;
print "$out_x_to_fasta";
if ($out_x_to_fasta !~ /Super_scaffold_.*: Scaffolding molecule = .*/)
{
    print "Removing temp files...\n";
    unlink glob "${fasta_directories}${fasta_filename}_numbered_scaffold*";
    die "No alignments produced superscaffolds therefore no super scaffold fasta was created\n";
}
if (-e "${output_basename}_data_summary.csv") {print "${output_basename}_data_summary.csv file Exists$!\n"; exit;}

#############################################################################
#########                     create new AGP                       ##########
#############################################################################
print "Making new AGP and contig file for super-scaffolded fasta file...\n";
my $make_agp=`perl ${dirname}/make_contigs_from_fasta.pl ${output_basename}_superscaffold.fasta`;
print "$make_agp";
#############################################################################
#########              create a BNG compatible contig BED file     ##########
#############################################################################
print "Making new BED file of contigs for super-scaffolded fasta file...\n";
my $make_contig_bed=`perl ${dirname}/agp2bed.pl ${output_basename}_superscaffold.fasta_contig.agp`;
print "$make_contig_bed";
#############################################################################
#########              create a BNG compatible GAP BED file        ##########
#############################################################################
print "Making new BED file of gaps for super-scaffolded fasta file...\n";
my $make_gap_bed=`perl ${dirname}/../sv_detect/agp2_gap_bed.pl ${output_basename}_superscaffold.fasta_contig.agp`;
print "$make_gap_bed";
#################################################################################
##############  compress summary files and delete temp files  ###################
#################################################################################
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
print SUMMARY "List of scaffolds that overlap on the super-scaffold. These are separated by 100 \"n\" gaps.\n";
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
unlink glob "${fasta_directories}${fasta_filename}_numbered_scaffold*";
unlink "${output_basename}_overlaps.csv","${output_basename}_weakpoints.csv","${output_basename}_report.csv";
print "Done running stitch\n";

#################################################################################
##############                  Documentation                  ##################
#################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

 stitch.pl - Stitch filters alignment XMAP files by confidence and the percent of the maximum potential length of the alignment. The first settings for confidence and the minimum percent of the full potential length of the alignment should be set to include the range that the researcher decides represent high quality alignments after viewing raw XMAPs. Some alignments have lower than optimal confidence scores because of low label density or short sequence-based scaffold length. The second set of filters should have a user-defined lower minimum confidence score, but a much higher percent of the maximum potential length of the alignment in order to capture these alignments. Resultant filtered XMAPs should be examined in IrysView to see that the alignments agree with what the user would manually select. Stitch finds the best super-scaffolding alignments each run. It is run iteratively by `sewing_machine.pl` until all super-scaffolds have been found.
 
 Start with the default filtering parameters for confidence scores (`--f_con` and `--s_con`) and percent of possible alignment thresholds (`--f_algn` and `--s_algn`). Test more or less strict options if your first results are not satisfactory.
 


=head1 USAGE

perl stitch.pl [options]

Documentation options:
 
    -help    brief help message
    -man	    full documentation
 
Required options:
 
    -r	     reference CMAP
    -x	     comparison XMAP
    -f	     scaffold FASTA
    -o	     base name for the output files
 
Filtering options:
 
    --f_con	 first minimum confidence score (default = 0)
    --f_algn	 first minimum % of possible alignment (default = 0)
    --s_con	 second minimum confidence score (default = 0)
    --s_algn	 second minimum % of possible alignment (default = 0)
    --n	         minimum negative gap length allowed (default = 20000 bp)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-r, --r_cmap>

The reference CMAP produced by IrysView when you create an XMAP. In this case the reference should have been set to the BNG consensus map. It can be found in the "Imports" folder within a workspace.

=item B<-x, --xmap>

The XMAP produced by IrysView. In this case the reference (also called "Anchor" by BNG) should have been set to the BNG consensus map and the query should be the in silico map. It can also be found in the "Imports" folder within a workspace.

=item B<-f, --fasta>

The FASTA that will be super-scaffolded based on alignment to the IrysView assembly. It is preferable to use the scaffold FASTA rather than the contigs. Many contigs will not be long enough to align.

=item B<-o, --output_basename>

This is the basename for all output files. Output file include an XMAP with only high quality alignments of molecules that scaffold contigs, an XMAP of all high quality alignments, a csv file with summary metrics, and a non-redundant (i.e. no scaffold is used twice) super-scaffold from a user-provided scaffold file and a filtered XMAP.

=item B<--f_con, --fc>

The minimum confidence score for alignments for the first round of filtering. This should be the most stringent, highest, of the two scores.

=item B<--f_algn, --fa>

The minimum percent of the full potential length of the alignment allowed for the first round of filtering. This should be lower than the setting for the second round of filtering.

=item B<--s_con, --sc>

The minimum confidence score for alignments for the second round of filtering. This should be the less stringent, lowest, of the two scores.

=item B<--s_algn, --sa>

The minimum percent of the full potential length of the alignment allowed for the second round of filtering. This should be higher than the setting for the first round of filtering.

=item B<-n, --neg_gap>

Allows user to adjust minimum negative gap length allowed (default = 20000 bp).

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

The script outputs an XMAP with only molecules that scaffold contigs and an XMAP of all high quality alignments. Both XMAPs can be imported and viewed in the IrysView "comparisons" window if the original r.cmap and q.cmap are in the same folder when you import.

The script also lists summary metrics in a csv file.

In the same csv file, scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible are listed. These may represent mis-assembled scaffolds.

In the same csv file, high quality but overlaping alignments in a csv file are listed. These may be candidates for further assembly using the overlaping contigs and paired end reads.

The script also creates a non-redundant (i.e. no scaffold is used twice) super-scaffold from a user-provided scaffold file and a filtered XMAP. If two scaffolds overlap on the superscaffold then a 100 "n" gap is used as a spacer between them. If adjacent scaffolds do not overlap on the super-scaffold than the distance between the begining and end of each scaffold reported in the XMAP is used as the gap length. If a scaffold has two high quality alignments the longest alignment is selected. If both alignments are equally long the alignment with the highest confidence is selected.

The script also outputs contigs, an agp, and a bed file of contigs within superscaffolds from the final super-scaffold fasta file. 


B<Test with sample datasets:>

git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90

=cut
