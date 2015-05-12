#!/usr/bin/perl
##################################################################################
#
# USAGE: perl get_passing_xmap.pl [options]
# Script finds passing inverted alignments in original (in silico = reference) xmap and exports an XMAP to view in in IrysView.
#  Created by jennifer shelton 12/04/14
#
##################################################################################
use strict;
use warnings;
# use IO::File;
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
# use List::Util qw(max);
# use List::Util qw(sum);
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#  get_passing_xmap.pl Version 1.0                        #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 12/04/14                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl get_passing_xmap.pl -help # for usage/options     #\n";
print "#  perl get_passing_xmap.pl -man # for more details       #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $input_fasta;
my $filtered_xmap_file;
my $original_xmap_file;
my $man = 0;
my $help = 0;
GetOptions (
'help|?' => \$help,
'man' => \$man,
'f|filtered_xmap:s' => \$filtered_xmap_file,
'o|original_xmap:s' => \$original_xmap_file,

)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__); # github directories (all github directories must be in the same directory)
###############################################################################
##############              run                              ##################
###############################################################################

#h XmapEntryID	QryContigID	RefContigID	QryStartPos	QryEndPos	RefStartPos	RefEndPos	Orientation	Confidence	HitEnum
my %passed;
open (my $filtered_xmap, "<", $filtered_xmap_file) or die "Can't open $filtered_xmap_file: $!";
while (<$filtered_xmap>)
{
    unless ((/^\s*$/)||(/^#/))
    {
        chomp;
        my ($QryContigID,$RefContigID,$QryStartPos,$QryEndPos,$RefStartPos,$RefEndPos)=(split(/\t/))[1,2,3,4,5,6];
        my $pass = "$RefContigID\t$QryContigID\t$RefStartPos\t$RefEndPos\t$QryStartPos\t$QryEndPos";
        $passed{$pass}=1;
    }
}
my ($basename, $directories, $suffix) = fileparse($original_xmap_file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
my $output_xmap_file = "${directories}${basename}_filtered.xmap";
open (my $output_xmap, ">", $output_xmap_file) or die "Can't open $output_xmap_file: $!";

open (my $original_xmap, "<", $original_xmap_file) or die "Can't open $original_xmap_file: $!";
while (<$original_xmap>)
{
    unless (/^\s*$/)
    {
        unless (/^#/)
        {
            my @current=(split(/\t/))[1,2,3,4,5,6];
            my $test = join("\t",@current);
            if ($passed{$test})
            {
                print $output_xmap "$_";
            }
        }
        else
        {
            print $output_xmap "$_";
        }
    }
}
print "Done\n";

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 get_passing_xmap.pl - Script finds passing inverted alignments in original (in silico = reference) xmap and exports an XMAP to view in in IrysView (e.g. perl get_passing_xmap.pl -f /path_to/filtered.xmap -o /path_to/original.xmap)
 
=head1 USAGE
 
 perl get_passing_xmap.pl [options]
 
 Documentation options:
     -help    brief help message
     -man	    full documentation
 Required parameters:
     -f	    Path of filtered inverted XMAP alignment. XMAPs ending in "_scaffolds.xmap" or "_all_filtered.xmap"
     -o	    Path of original XMAP (with in silico CMAP as reference as recommended by BioNano)
 
 
=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.


=item B<-f, --filtered_xmap>

The fullpath for the of filtered inverted XMAP alignment. XMAPs ending in "_scaffolds.xmap" or "_all_filtered.xmap"

=item B<-o, --original_xmap>

The fullpath for the original XMAP (with in silico CMAP as reference as recommended by BioNano).

=back

 
=cut
