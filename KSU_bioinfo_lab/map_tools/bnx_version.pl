#!/usr/bin/perl
##################################################################################
#
# USAGE: perl  bnx_version.pl [OPTIONS] BNX_FILES...
# Script reports version of BNX files.
#
# Script has no options other than help menus currently.
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
#use Term::ANSIColor;
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#   bnx_version.pl Version 1.0                            #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 02/26/15                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl  bnx_version.pl -help # for usage/options         #\n";
print "#  perl  bnx_version.pl -man # for more details           #\n";
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
    'i|input_bnx:s' => \$input_bnx,
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);

###############################################################################
##############              run                              ##################
###############################################################################

print "Checking BNX files of version...\n";
open (my $bnx, "<", $input_bnx) or die "Can't open $input_bnx: $!";

while (<$bnx>)
{
    if (/^# BNX File Version:/)
    {
        /# BNX File Version:\t(.*)\n/;
        my $bnx_version = $1;
        #                print "$bnx_version $total_length $input_bnx \n";
        unless ($bnx_version >= 1)
        {
            print "Warning bnx_version.pl was only tested on BNX version 1.0 and 1.2 files.\n";
        }
        print "$input_bnx version: $bnx_version\n";
        exit;
    }
}

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 bnx_version.pl - Script reports version of BNX files. Script has no options other than help menus currently.
 
 
=head1 DEPENDENCIES
 
 Perl
 
=head1 USAGE
 
perl  bnx_version.pl -i <BNX_FILE>

Documentation options:

    -help    brief help message
    -man	    full documentation

Required parameters:

    -i	    bnx file

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-i, --input_bnx>

Input BNX filename.

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script outputs BNX version and warns if version is below 1.


=cut
