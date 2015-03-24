#!/usr/bin/perl
##################################################################################
#
# USAGE: perl  cmap_stats.pl [options]
# Script outputs count of cmaps, cumulative lengths of cmaps and N50 of cmaps. Tested on CMAP File Version: 0.1
#  Created by jennifer shelton 08/26/14
#
##################################################################################
use strict;
use warnings;
# use IO::File;
# use File::Basename; # enable maipulating of the full path
# use File::Slurp;
# use List::Util qw(max);
# use List::Util qw(sum);
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#   cmap_stats.pl Version 1.0                             #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 08/26/14                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl  cmap_stats.pl -help # for usage/options          #\n";
print "#  perl  cmap_stats.pl -man # for more details            #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $input_cmap;
my $man = 0;
my $help = 0;
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    'c|input_cmap:s' => \$input_cmap,

)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
die "Option -c or --input_cmap not specified.\n" unless $input_cmap; # report missing required variables
###############################################################################
##############              run                              ##################
###############################################################################
my @lengths;
my %cmaps;
my $total_length;
my $cmap_count;
open (my $cmap, "<", $input_cmap) or die "Can't open $input_cmap: $!";
while (<$cmap>)
{
    unless (/^#/)
    {
        my @columns = split(/\t/);
        # CMapId       ContigLength    NumSites;
        unless ($cmaps{$columns[0]})
        {
            push (@lengths,$columns[1]);
            $total_length += $columns[1];
            ++$cmap_count;
            $cmaps{$columns[0]} = 1;
        }
        
    }
    
}
##############################################################################
# CALCULATE N50:
# Now calculate the N50 from the array of contig lengths and the total length
##############################################################################
@lengths=sort{$b<=>$a} @lengths; #Sort lengths largest to smallest

my $current_length; #create a new variable for N50
my $fraction=$total_length;
foreach(my $j=0; $fraction>$total_length/2; $j++) #until $fraction is greater than half the total length increment the index value $j for @lengths
{
    $current_length=$lengths[$j];
    $fraction -= $current_length; # subtract current length from $fraction
}
$current_length = $current_length/1000000;
$total_length = $total_length/1000000;
print "cmap N50: $current_length (Mb)\n";
print "Total cmap length: $total_length (Mb)\n";
print "Number of cmaps: $cmap_count\n";
print "done\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME

cmap_stats.pl - Script outputs count of cmaps, cumulative lengths of cmaps and N50 of cmaps. Tested on CMAP File Version: 0.1.

=head1 USAGE

perl  cmap_stats.pl [options]

Documentation options:
 
    -help    brief help message
    -man	    full documentation
 
Required parameters:
 
    -c	    cmap to summarize



=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-c, --input_cmap>

The fullpath for the cmap file. This will be summarized.


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script has no unusual dependencies.
 
 
=cut
