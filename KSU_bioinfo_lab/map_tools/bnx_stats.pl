#!/usr/bin/perl
##################################################################################
#
# USAGE: perl  bnx_stats.pl [OPTIONS] BNX_FILES...
# Script outputs count of molecule maps in BNX files, cummulative lengths of molecule maps and N50 of molecule maps. Script also outputs a PDF with these metrics as well as histograms of molecule map quality metrics. Tested on BNX File Version 1.0 however it should work on Version 1.2 as well. The user inputs a list of BNX files or a glob as the final arguments to script. Things to add include filtering by min molecule length and switching between QC and cleaning.
#
# Script has no options other than help menus currently but it was designed to be adapted into a molecule cleaning script similar to prinseq or fastx. Feel free to fork this and add your own filters.
#  Created by jennifer shelton 01/15/15
#
##################################################################################
use strict;
use warnings;
use Math::BigFloat;
# use IO::File;
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
use List::Util qw(max);
use List::Util qw(sum);
use Term::ANSIColor;
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print colored ("#           !!!!!WARNING UNDER DEVELOPMENT!!!!            #", 'bold white on_blue'), "\n";
print colored ("#             NOTE: SCRIPT ASSUMES DATA WITH              #", 'bold white on_blue'), "\n";
print colored ("#     BACKBONE & A SINGLE CHANNEL OF LABEL INFORMATION    #", 'bold white on_blue'), "\n";
print "#   bnx_stats.pl Version 1.0                              #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 01/15/15                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl  bnx_stats.pl -help # for usage/options           #\n";
print "#  perl  bnx_stats.pl -man # for more details             #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $input_bnx;
my $man = 0;
my $help = 0;
my $min_length_kb = 0;
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    'l|min_length_kb:s' => \$min_length_kb,
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
###############################################################################
##############                Subroutines                    ##################
###############################################################################
sub mean { return @_ ? sum(@_) / @_ : 0 } # calculate mean of array

sub next_three # take the next three lines in a subroutine
{
    my $sub_fh=shift;
    my $next_lines;
    foreach (1..3)
    {
        $next_lines .= <$sub_fh>;
    }
    return $next_lines;
}
###############################################################################
##############              run                              ##################
###############################################################################
use bignum;
open (my $temp_bnx_lengths, ">", 'temp_bnx_lengths.tab') or die "Can't open temp_bnx_lengths.tab: $!"; # Open temp files
open (my $temp_mol_intensities, ">", 'temp_bnx_mol_intensities.tab') or die "Can't open temp_mol_intensities.tab: $!"; # Open temp files
open (my $temp_mol_snrs, ">", 'temp_bnx_mol_snrs.tab') or die "Can't open temp_mol_snrs.tab: $!"; # Open temp files
open (my $temp_mol_NumberofLabels, ">", 'temp_bnx_mol_NumberofLabels.tab') or die "Can't open temp_mol_NumberofLabels.tab: $!"; # Open temp files
open (my $temp_mean_label_snr, ">", 'temp_mean_label_snr.tab') or die "Can't open temp_mean_label_snr.tab: $!"; # Open temp files
open (my $temp_mean_label_intensity, ">", 'temp_mean_label_intensity.tab') or die "Can't open temp_mean_label_intensity.tab: $!"; # Open temp files
my (@lengths,@mol_intensities,@mol_snrs,@mol_NumberofLabels);
my $total_length =0;
my ($bnx_count,$scan_count);
print "Reading BNX files of molecule maps...\n";
my $file_count = scalar(@ARGV); # get number of bnx files
my $current_file_count = $file_count;
if ($file_count == 0)
{
    print "No BNX files have been given exiting.\n";
    exit;
}
for my $input_bnx (@ARGV)
{
    my $total_flowcell_length;
    open (my $bnx, "<", $input_bnx) or die "Can't open $input_bnx: $!";
    my $bnx_version;
    while (<$bnx>)
    {
        unless (/^s+$/)
        {
            #0h	LabelChannel	MoleculeId	Length	AvgIntensity	SNR	NumberofLabels	OriginalMoleculeId	ScanNumber	ScanDirection	ChipId	Flowcell
            if (/^# BNX File Version:/)
            {
                /# BNX File Version:\t(.*)\n/;
                my $bnx_version = $1;
                #                print "$bnx_version $total_length $input_bnx \n";
                print "Reading BNX file $current_file_count of $file_count files\n";
                --$current_file_count;
                unless ($bnx_version >= 1)
                {
                    print "Warning bnx_stats.pl was only tested on BNX version 1.0 and 1.2 files.\n";
                }
            }
            ###############################################################################
            ##############              Log Molecule metrics NEW            ##################
            ###############################################################################
            unless (/^#/)
            {
                #########################################################################
                ##############              Backbone line              ##################
                #########################################################################
                my ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell) = split(/\t/);
                if ($LabelChannel != 0) # Test for number of lines agrees with expected number of lines per molecule.
                {
                    print "Warning BNX file $input_bnx appears to be corrupt. Each record should be four lines if only the backbone and one label channel are described in a BNX file. Skipping this file.\n";
                    last;
                }
                my $three_lines = &next_three($bnx);
                my($label_pos_line, $label_snr_line, $label_intensity_line) = split(/\n/,$three_lines);
                if ($Length =~ /Infinity/) #exit if the molecule have no recorded length
                {
                    next;
                }
                my $Lengthkb = $Length/1000; # use length data (removed int)
                if ($Lengthkb < $min_length_kb) #skip molecule map if min length if greater than length of current molecule map
                {
                    next;
                }
                ++$bnx_count; # count molecules
                $total_flowcell_length += $Lengthkb;
                push (@lengths,$Lengthkb);
                print $temp_bnx_lengths "$Lengthkb\n";
                
                print $temp_mol_intensities "$AvgIntensity\n";
                print $temp_mol_snrs "$SNR\n";
                print $temp_mol_NumberofLabels "$NumberofLabels\n";
                #########################################################################
                ##############              Label SNR line             ##################
                #########################################################################
                my @label_snr = split (/\t/,$label_snr_line);
                shift (@label_snr);
                unless (scalar(@label_snr) == 0)
                {
                    my $mean_snr = &mean(@label_snr);
                    print $temp_mean_label_snr "$mean_snr\n"; #PRINT AFTER ADDING MEAN SNR CALC
                }
                #########################################################################
                ##############           Label intensity line          ##################
                #########################################################################
                my @label_intensity = split (/\t/,$label_intensity_line);
                shift (@label_intensity);
                unless (scalar(@label_intensity) == 0)
                {
                    my $mean_intensity = &mean(@label_intensity);
                    print $temp_mean_label_intensity "$mean_intensity\n"; #PRINT AFTER ADDING MEAN INTENSITY CALC
                }
            }
        }
    }
    my $new_total_length = $total_length + $total_flowcell_length;
    $total_length = $new_total_length;
}
##############################################################################
# CALCULATE N50:
# Now calculate the N50 from the array of map lengths and the total length
##############################################################################
@lengths=sort{$b<=>$a} @lengths; #Sort lengths largest to smallest
#print scalar(@lengths)."\n";
#print "$total_length\n";
my $current_length; #create a new variable for N50
my $fraction=$total_length;
foreach(my $j=0; $fraction>$total_length/2; $j++) #until $fraction is greater than half the total length increment the index value $j for @lengths
{
    $current_length=$lengths[$j];
    $fraction -= $current_length; # subtract current length from $fraction
}
$current_length = $current_length;
$total_length = $total_length/1000;

print "Molecule map N50: $current_length (kb)\n";
print "Cummulative length of molecule maps: $total_length (Mb)\n";
print "Number of molecule maps: $bnx_count\n";

###############################################################################
##############               Graph data                      ##################
###############################################################################
print "Graphing data...\n";

my $graph_data = `Rscript ${dirname}/histograms.R temp_bnx_lengths.tab temp_bnx_mol_intensities.tab temp_bnx_mol_snrs.tab temp_bnx_mol_NumberofLabels.tab temp_mean_label_snr.tab temp_mean_label_intensity.tab 'Molecule map N50: $current_length (kb)' 'Cummulative length of molecule maps: $total_length (Mb)' 'Number of molecule maps: $bnx_count'`;
print "$graph_data\n";
unlink qw/temp_bnx_lengths.tab temp_bnx_mol_intensities.tab temp_bnx_mol_snrs.tab temp_bnx_mol_NumberofLabels.tab temp_mean_label_snr.tab temp_mean_label_intensity.tab Rplots.pdf/;

print "Done\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
bnx_stats.pl - Script outputs count of molecule maps in BNX files, cummulative lengths of molecule maps and N50 of molecule maps. Script also outputs a PDF with these metrics as well as histograms of molecule map quality metrics. Tested on BNX File Version 1.0 however it should work on Version 1.2 as well. The user inputs a list of BNX files or a glob as the final arguments to script. Things to add include filtering by min molecule length and switching between QC and cleaning.
 
Script has no options other than help menus currently but it was designed to be adapted into a molecule cleaning script similar to prinseq or fastx. Feel free to fork this and add your own filters.
 
=head1 DEPENDENCIES
 
 Perl and R
 
=head1 USAGE
 
perl  bnx_stats.pl [OPTIONS] BNX_FILES...

Documentation options:

    -help    brief help message
    -man	    full documentation

Required parameters:

    -l	    minimum molecule map length

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-l, --min_length_kb>

Minimum molecule length in kb. Molecules shorter than this are not analyzed. Currently this script does not produce filtered BNX files so this value will cause reports to include only molecule maps longer than the value but will not change the BNX file (Default = 0).

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script has no dependencies other than Perl and R.


=cut
