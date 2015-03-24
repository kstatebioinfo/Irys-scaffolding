#!/usr/bin/perl
##################################################################################
#
# USAGE: perl nick_density.pl [OPTIONS] FASTA_FILES...
# Script reports label density for various enzymes for FASTA files. Script requires fa2cmap_multi.pl from BioNano Genomics.
#
#
#  Created by jennifer shelton 01/15/15
#
##################################################################################
use strict;
use warnings;
use Math::BigFloat;
# use IO::File;
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
#use List::Util qw(max);
#use List::Util qw(sum);
#use Term::ANSIColor;
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#   nick_density.pl Version 1.0                           #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 03/13/15                   #\n";
print "#  github.com/i5K-KINBRE-script-share                     #\n";
print "#  perl  nick_density.pl -help # for usage/options        #\n";
print "#  perl  nick_density.pl -man # for more details          #\n";
print "###########################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my $two_enzyme;
my $man = 0;
my $help = 0;
my $path_to_fa2cmap_multi = '~/bin/fa2cmap_multi.pl';
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    't|two_enzyme' => \$two_enzyme,
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
if (scalar(@ARGV) == 0)
{
    die "No FASTA flies were selected.\n";
}
###############################################################################
##############              run                              ##################
###############################################################################
my @enzymes = qw/BspQI BbvCI BsmI BsrDI bseCI/;
if ($two_enzyme)
{
    @enzymes = qw/BspQI BbvCI/;
}
print "FASTA Enzyme : Nick density\n";
for my $fasta (@ARGV)
{
    my (${filename}, ${directories}, ${suffix}) = fileparse($fasta,'\.[^.]+$'); # requires File::Basename and adds trailing slash to $directories
    ##################################################################
    ##############     Create cmap directory  ##################
    ##################################################################
    my $out_dir = "${directories}cmaps";
    unless (-d $out_dir)
    {
        unless(mkdir $out_dir)
        {
            print "Warning unable to create $out_dir: $!";
        }
    }
    my $file_out = "${out_dir}/${filename}_nick_density.csv";
    open (my $out, ">", $file_out) or die "Can't open $file_out: $!";
    print $out "FASTA,Enzyme,Nick density\n";
    for my $enzyme (@enzymes)
    {
        my $run_check = `perl $path_to_fa2cmap_multi -v -i $fasta -e $enzyme`;
#        print $run_check;
        $run_check =~ /Global nick frequency:\s+(.*)\s+nick\(s\)\s+\/100KB/;
        print "$filename $enzyme : $1\n";
        print $out "$filename,$enzyme,$1\n";
    }
    ###############################################################################
    ##############              Clean up files                   ##################
    ###############################################################################
    opendir (my $temp_out_dir, $directories) or die "Can't open $directories: $!";
    while (my $entry = readdir $temp_out_dir )
    {
        if (($entry =~ /\.cmap$/) || ($entry =~ /_key\.txt$/))
        {
            my (${cmap_filename}, ${cmap_directories}, ${cmap_suffix}) = fileparse($entry,'\.[^.]+$'); # requires File::Basename and adds trailing slash to $directories
            my $moved_cmap = "${out_dir}/${cmap_filename}${cmap_suffix}";
            rename("${directories}$entry",$moved_cmap); # move cmaps and keys to a subdirectory
        }
    }
    closedir ($temp_out_dir);
    
}
#perl ~/bin/fa2cmap_multi.pl -v -i GCF_000002825.2_ASM282v1_genomic.fna -e BspQI BbvCI BsmI BsrDI bseCI
#perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/nick_density.pl --two_enzyme /home/bionano/bionano/Trit_foet_2014_042/GCF_000002825.2_ASM282v1_genomic.fna
print "Done reporting nick density estimates\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
nick_density.pl - Script reports label density for various enzymes for FASTA files. Script requires fa2cmap_multi.pl from BioNano Genomics. Script logs the label density values in the project's directory with the file suffix "_nick_density.csv" as well as printing the results to the screen. You could also run the following if you just wanted to quickly check density for BspQI and BbvCI with the "--two_enzyme" flag.

Script can also determine label density for multiple FASTA files.


=head1 UPDATES:

None to date

=head1 DEPENDENCIES

Perl and R

=head1 USAGE

perl nick_density.pl [OPTIONS] FASTA_FILES...

Documentation options:

    -help    brief help message
    -man	    full documentation

Required parameters:

    -t	    quickly check only two enzymes (BspQI and BbvCI)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-t, --two_enzyme>

Quickly check density for only the two most commonly used enzymes, BspQI and BbvCI (Default = off).

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script requires Perl and fa2cmap_multi.pl from BioNano Genomics. Change line 39 to change the path to fa2cmap_multi.pl from ~/bin/fa2cmap_multi.pl if needed.


=cut
