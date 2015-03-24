#!/usr/bin/perl
##################################################################################
#
# USAGE: perl  CmapById.pl [options]
# Script outputs new CMAP with only maps with user specified IDs. Tested on CMAP File Version: 0.1. Call with "-help" flag for detailed instructions.
#  Created by jennifer shelton 02/05/15
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
print "#   CmapById.pl Version 1.0                               #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 02/05/15                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl  CmapById.pl -help # for usage/options            #\n";
print "#  perl  CmapById.pl -man # for more details              #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my ($input_cmap,$cmap_ids,$out);
my $man = 0;
my $help = 0;
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    'c|input_cmap:s' => \$input_cmap,
    'i|cmap_ids:s' => \$cmap_ids,
    'o|out:s' => \$out
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
die "Option -c or --input_cmap not specified.\n" unless $input_cmap; # report missing required variables
die "Option -i or --cmap_ids not specified.\n" unless $cmap_ids; # report missing required variables
die "Option -o or --out not specified.\n" unless $out; # report missing required variables
###############################################################################
##############              run                              ##################
###############################################################################
my ($min,$max);
my %cmaps;

if ($cmap_ids =~ /(.*)\.\.(.*)/) # if ids are given as a range
{
    $min = $1;
    $max = $2;
    for my $id ($min .. $max)
    {
        $cmaps{$id} = 1;
    }
}
else
{
    my @list_cmap_ids = split(/,/ , $cmap_ids);
    for my $id (@list_cmap_ids)
    {
        $cmaps{$id} = 1;
    }

}

my (${filename}, ${directories}, ${suffix}) = fileparse($input_cmap,'\..*'); #grab parts of the filename without trailing slash
unless ($out)
{
    $out = "${directories}/${filename}_by_id.cmap"; # default output filename
}
else
{
    $out = "${out}_by_id.cmap"; # custom output filename
}
open (my $cmap_out, ">", $out) or die "Can't open $out: $!";
open (my $cmap, "<", $input_cmap) or die "Can't open $input_cmap: $!";
while (<$cmap>)
{
    unless (/^s+$/) # skip blank lines
    {
        #h CMapId	ContigLength	NumSites	SiteID	LabelChannel	Position	StdDev	Coverage	Occurrence
        if (/^# CMAP File Version:/)
        {
            /# CMAP File Version:\t(.*)\n/;
            my $cmap_version = $1;
            #                print "$cmap_version\n";
            print "Reading CMAP file $input_cmap... \n";
            unless ($cmap_version == '0.1')
            {
                print "Warning CmapById.pl was only tested on CMAP version 0.1 files. Your file is ${cmap_version}. This may not be a problem but you may want to double check.\n";
            }
        }
        unless (/^#/)
        {
            my @columns = split(/\t/);
            # CMapId       ContigLength    NumSites;
            if ($cmaps{$columns[0]})
            {
                print $cmap_out "$_";
            }
        }
        else
        {
            print $cmap_out "$_";
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
 
 CmapById.pl - Script outputs new CMAP with only maps with user specified IDs. Tested on CMAP File Version: 0.1. Call with "-help" flag for detailed instructions.
 
 
=head1 USAGE
 
 perl  CmapById.pl [options]
 
 Documentation options:
 
 -help    brief help message
 -man	    full documentation
 
 Required parameters:
 
 -c	    CMAP to extract individual maps from
 -i	    CMAP IDs (either a single ID, a comma separated list or a min and max ID separated with "..")
 -o	    optional output file prefix
 
=head1 OPTIONS
 
=over 8
 
=item B<-help>
 
 Print a brief help message and exits.
 
=item B<-man>
 
 Prints the more detailed manual page with output details and examples and exits.
 
=item B<-c, --input_cmap>
 
 The fullpath for the CMAP file to extract individual maps from.

=item B<-i, --cmap_ids>
 
 Either a single CMAP ID (e.g. "-i 2"), a comma separated list of CMAP IDs (e.g. "-i 2,4,6,7") or a range of CMAP IDs (e.g. "-i 2..10").
 
=item B<-o, --out>
 
 Optional output CMAP file prefix. The suffix "_by_id.cmap" will be added to the end of all output files.

 
=back
 
=head1 DESCRIPTION
 
B<OUTPUT DETAILS:>
 
 Script has no unusual dependencies.
 
 
=cut
