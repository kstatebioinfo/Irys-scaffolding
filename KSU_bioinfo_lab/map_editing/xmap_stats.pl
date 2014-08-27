#!/usr/bin/perl
##################################################################################
#
# USAGE: perl xmap_stats.pl [options]
# Script outputs breadth of alignment coverage and total aligned length from an xmap.
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
print "#  xmap_stats.pl Version 1.0                              #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 08/26/14                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl xmap_stats.pl -help # for usage/options           #\n";
print "#  perl xmap_stats.pl -man # for more details             #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $input_xmap;
my $man = 0;
my $help = 0;
GetOptions (
'help|?' => \$help,
'man' => \$man,
'x|input_xmap:s' => \$input_xmap,

)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

###############################################################################
##############              run                              ##################
###############################################################################
#h XmapEntryID  QryContigID     RefContigID     QryStartPos     QryEndPos       RefStartPos     RefEndPos       Orientation     Confidence      HitEnum

my ($breadth,$total_length,%refs);
open (my $xmap, "<", $input_xmap) or die "Can't open $input_xmap: $!";
my $start_cov = -1;
my $end_cov = 0;

while (<$xmap>)
{
    unless (/^#/)
    {
        unless (/^\s+$/) # unless the line is blank
        {
            my ($RefContigID, $start, $end, $Confidence) = (split(/\t/))[2,5,6,8];
            $total_length += $end - $start +1;
            unless ($refs{$RefContigID})#if (new contig)
            {
                $refs{$RefContigID} = 1;
                $breadth += $end_cov - $start_cov +1;
                $start_cov = $start;
                $end_cov = $end;
            }
            elsif ((($start >= $start_cov) && ($start <= $end_cov)) && ($end > $end_cov))# if alignment overlaps and extends coverage
            {
                $end_cov = $end;
            }
            elsif ($start > $end_cov) # if next alignment on same reference but not overlapping
            {
                $breadth += $end_cov - $start_cov +1;
                $start_cov = $start;
                $end_cov = $end;
            }
        }
        if (eof)
        {
            $breadth += $end_cov - $start_cov +1;
        }
    }
}
$breadth = $breadth/1000000;
$total_length = $total_length/1000000;
print "Breadth of alignment coverage = $breadth (Mp)\n";
print "Total alignment length = $total_length (Mp)\n";
print "done\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
xmap_stats.pl - Script outputs breadth of alignment coverage and total aligned length from an xmap.
 
"Breadth of alignment coverage" is the number of bases covered by aligned maps. This is equivalent to "Total Unique Aligned Len(Mb)". 
 
"Total alignment length is the total length of the alignment. This is equivalent to "Total Aligned Len(Mb)".
 
Occasionally "Total Unique Aligned Len(Mb)" and "Total Aligned Len(Mb)" are slightly lower than values reported by xmap_stats.pl. This is because the length of an alignment is the end position minus the start position plus one base. For example is a map aligns from position 4 to position 5 the length of the alignment is 2 bases (5-4+1) rather than 1 (5-4). This value is off slightly when reported as "Total Unique Aligned Len(Mb)" or "Total Aligned Len(Mb)".

=head1 USAGE

perl xmap_stats.pl [options]

Documentation options:
 
    -help    brief help message
    -man	    full documentation
     
Required parameters:
 
    -x	    xmap to summarize


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-x, --input_xmap>

The fullpath for the xmap file. This will be summarized.


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script has no unusual dependencies.

=cut


