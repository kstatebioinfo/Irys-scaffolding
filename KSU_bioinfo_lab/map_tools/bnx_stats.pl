#!/usr/bin/perl
##################################################################################
#
# USAGE: perl  bnx_stats.pl [OPTIONS] BNX_FILES...
# Script outputs count of molecule maps in BNX files, cummulative lengths of molecule maps and N50 of molecule maps. Tested on BNX File Version 1 however it should work on Version 1.2 as well. The user inputs a list of BNX files or a glob as the final arguments to script.
# Script has no options other than help menus currently but it was designed to be adapted into a molecule cleaning script similar to prinseq or fastx. Feel free to fork this and add your own filters.
#  Created by jennifer shelton 01/15/15
#
##################################################################################
use strict;
use warnings;
# use IO::File;
# use File::Basename; # enable maipulating of the full path
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
print colored ("#   !!!!!WARNING UNDER DEVELOPMENT!!!!                    #", 'bold white on_blue'), "\n";
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
GetOptions (
'help|?' => \$help,
'man' => \$man,
's|snr:s' => \$input_bnx,

)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
###############################################################################
##############                Subroutines                    ##################
###############################################################################
sub mean { return @_ ? sum(@_) / @_ : 0 } # calculate mean of array
###############################################################################
##############              run                              ##################
###############################################################################
open (my $temp_bnx_lengths, ">", 'temp_bnx_lengths.tab') or die "Can't open temp_bnx_lengths.tab: $!"; # Open temp files
open (my $temp_mol_intensities, ">", 'temp_bnx_mol_intensities.tab') or die "Can't open temp_mol_intensities.tab: $!"; # Open temp files
open (my $temp_mol_snrs, ">", 'temp_bnx_mol_snrs.tab') or die "Can't open temp_mol_snrs.tab: $!"; # Open temp files
open (my $temp_mol_NumberofLabels, ">", 'temp_bnx_mol_NumberofLabels.tab') or die "Can't open temp_mol_NumberofLabels.tab: $!"; # Open temp files
open (my $temp_mean_label_snr, ">", 'temp_mean_label_snr.tab') or die "Can't open temp_mean_label_snr.tab: $!"; # Open temp files
open (my $temp_mean_label_intensity, ">", 'temp_mean_label_intensity.tab') or die "Can't open temp_mean_label_intensity.tab: $!"; # Open temp files
my (@lengths,@mol_intensities,@mol_snrs,@mol_NumberofLabels);
my $total_length;
my ($bnx_count,$scan_count);
print "Reading BNX files of molecule maps...\n";
print "\tBNX Versions\n";
for my $input_bnx (@ARGV)
{
    open (my $bnx, "<", $input_bnx) or die "Can't open $input_bnx: $!";
    my $first_line = 1;
    my $bnx_version;
    while (<$bnx>)
    {
        #0h	LabelChannel	MoleculeId	Length	AvgIntensity	SNR	NumberofLabels	OriginalMoleculeId	ScanNumber	ScanDirection	ChipId	Flowcell
        if (/^# BNX File Version:/)
        {
            /# BNX File Version:\t(.*)\n/;
            my $bnx_version = $1;
            print "\t\tBNX Version: $bnx_version\n";
            unless ($bnx_version >= 1)
            {
                print "Warning bnx_stats.pl was only tested on BNX version 1.0 and 1.2 files.\n";
            }
        }
        ###############################################################################
        ##############              Log Molecule metrics             ##################
        ###############################################################################
        if (/^0\t/) #if the line for a backbone
        {
            my ($LabelChannel,$MoleculeId,$Length,$AvgIntensity,$SNR,$NumberofLabels,$OriginalMoleculeId,$ScanNumber,$ScanDirection,$ChipId,$Flowcell) = split(/\t/);
            $total_length += $Length;
            ++$bnx_count;
            ++$scan_count;
            my $Lengthkb = $Length/1000;
            push (@lengths,$Length);
            print $temp_bnx_lengths "$Lengthkb\n";
            print $temp_mol_intensities "$AvgIntensity\n";
            print $temp_mol_snrs "$SNR\n";
            print $temp_mol_NumberofLabels "$NumberofLabels\n";
            push (@mol_intensities,$AvgIntensity);
            push (@mol_snrs, $SNR);
            push (@mol_NumberofLabels,$NumberofLabels);
        }
        if (/^QX11\t/) #if the line for a Label SNR
        {
            chomp;
            my @label_snr = split (/\t/);
            shift (@label_snr);
            my $mean_snr = &mean(@label_snr);
            print $temp_mean_label_snr "$mean_snr\n"; #PRINT AFTER ADDING MEAN SNR CALC
        }
        if (/^QX12\t/) #if the line for a Label intensity
        {
            chomp;
            my @label_intensity = split (/\t/);
            shift (@label_intensity);
            my $mean_intensity = &mean(@label_intensity);
            print $temp_mean_label_intensity "$mean_intensity\n"; #PRINT AFTER ADDING MEAN INTENSITY CALC
        }
    }
}
##############################################################################
# CALCULATE N50:
# Now calculate the N50 from the array of map lengths and the total length
##############################################################################
@lengths=sort{$b<=>$a} @lengths; #Sort lengths largest to smallest

my $current_length=0; #create a new variable for N50
my $fraction=$total_length;
foreach(my $j=0; $fraction>$total_length/2; $j++) #until $fraction is greater than half the total length increment the index value $j for @lengths
{
    $current_length=$lengths[$j];
    $fraction -= $current_length; # subtract current length from $fraction
}
$current_length = $current_length/1000;
$total_length = $total_length/1000000;

#print "Molecule map N50: $current_length (kb)\n";
#print "Cummulative length of molecule maps: $total_length (Mb)\n";
#print "Number of molecule maps: $bnx_count\n";

###############################################################################
##############               Graph data                      ##################
###############################################################################
print "Graphing data...\n";

my $graph_data = `Rscript ${dirname}/histograms.R temp_bnx_lengths.tab temp_bnx_mol_intensities.tab temp_bnx_mol_snrs.tab temp_bnx_mol_NumberofLabels.tab temp_mean_label_snr.tab temp_mean_label_intensity.tab 'Molecule map N50: $current_length (kb)' 'Cummulative length of molecule maps: $total_length (Mb)' 'Number of molecule maps: $bnx_count'`;
print "$graph_data\n";
#unlink qw/temp_bnx_lengths.tab temp_bnx_mol_intensities.tab temp_bnx_mol_snrs.tab temp_bnx_mol_NumberofLabels.tab temp_mean_label_snr.tab temp_mean_label_intensity.tab/;


print "Done\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 bnx_stats.pl - Script outputs count of molecule maps in BNX files, cummulative lengths of molecule maps and N50 of molecule maps. Tested on BNX File Version 1 however it should work on Version 1.2 as well. The user inputs a list of BNX files or a glob as the final arguments to script. 
 Script has no options other than help menus currently but it was designed to be adapted into a molecule cleaning script similar to prinseq or fastx. Feel free to fork this and add your own filters.
DEPENDENCIES
 
 Perl and R
 
=head1 USAGE
 
perl  bnx_stats.pl [OPTIONS] BNX_FILES...

Documentation options:

    -help    brief help message
    -man	    full documentation

Required parameters:

    -x	    no additional options currently



=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-x, --x>

No additional options currently.


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script has no dependencies other than Perl and R.


=cut
