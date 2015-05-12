#!/usr/bin/perl
##################################################################################
#
#	USAGE: perl hybridScaffold_finish_fasta.pl [options]
#	TYPICAL USAGE: perl hybridScaffold_finish_fasta.pl -x <HYBRID_SCAFFOLD.xmap> -s <HYBRID_SCAFFOLD.fasta> -f <original.fasta>
#
#   Created by jennifer shelton
#	Script creates new FASTA files including new hybrid sequences output by
#   hybridScaffold and all sequences that were not used by hybridScaffold
#   with their original headers. Also outputs a text file list of the headers
#   for sequences that were used to make the new hybrid sequences.
#
#   Script requires BioPerl.
##################################################################################
use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::DB::Fasta; #makes a searchable db from my fasta file
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable maipulating of the full path
# use File::Slurp;
use Term::ANSIColor;
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "##################################################################\n";
print colored ("#             NOTE: SCRIPT REQUIRES BIOPERL                      #", 'bold white on_blue'), "\n";
print "#  hybridScaffold_finish_fasta.pl Version 1.0                    #\n";
print "#                                                                #\n";
print "#  Created by Jennifer Shelton 02/11/15                          #\n";
print "#  github.com/i5K-KINBRE-script-share                            #\n";
print "#  perl hybridScaffold_finish_fasta.pl -help # for usage/options #\n";
print "#  perl hybridScaffold_finish_fasta.pl -man # for more details   #\n";
print "##################################################################\n";
###############################################################################
##############                get arguments                  ##################
###############################################################################
my ($hybScf_xmap_file,$hybScf_fasta_file,$orig_fasta_file);
my $man = 0;
my $help = 0;
GetOptions (
    'help|?' => \$help,
    'man' => \$man,
    'x|hybScf_xmap_file:s' => \$hybScf_xmap_file,
    's|hybScf_fasta_file:s' => \$hybScf_fasta_file,
    'f|orig_fasta_file:s' => \$orig_fasta_file
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);

###############################################################################
##                  get list of hybridized sequences                         ##
##               fasta records from HYBRID_SCAFFOLD.xmap                     ##
###############################################################################
open (my $hybScf_xmap, "<", $hybScf_xmap_file) or die "Can't open $hybScf_xmap_file: $!";

my %seen_fasta_number; # make a nonredundant list for FASTA sequences that were already added to the HYBRID_SCAFFOLD.fasta
my $remove_count = 0;
while (<$hybScf_xmap>)
{
    unless (/^#/)
    {
        chomp;
        my @xmap_fields = split (/\t/);
        unless ($seen_fasta_number{$xmap_fields[1]}) # unless this sequence number has been seen before count this as "seen" (i.e. as used already in the HYBRID_SCAFFOLD.fasta)
        {
            $seen_fasta_number{$xmap_fields[1]} = 1;
            ++$remove_count; # count number of original sequences already added to HYBRID_SCAFFOLD.fasta
        }
    }
}
###############################################################################
##              get headers from original.fasta sequences                    ##
##            based on query id used in HYBRID_SCAFFOLD.xmap                 ##
###############################################################################
open (my $orig_fasta, "<", $orig_fasta_file) or die "Can't open $hybScf_xmap_file: $!";
my (@grab_id,@skip_id); # list to get FASTA records using headers
my $fasta_count = 1;
my $skipped_count = 0;
while (<$orig_fasta>)
{
    if ((/^>/))
    {
        chomp;
        s/>//;
        unless ($seen_fasta_number{$fasta_count})
        {
            push (@grab_id,$_); # sequence was NOT used already in the HYBRID_SCAFFOLD.fasta
        }
        else
        {
            ++$skipped_count;
            push (@skip_id,$_); # sequence used already in the HYBRID_SCAFFOLD.fasta
        }
        ++$fasta_count;
    }
    
}
close ($orig_fasta);
my $count = scalar(@grab_id);
print "count = $count\n";
#print @grab_id;
###############################################################################
##            add hybrid sequence from HYBRID_SCAFFOLD.fasta                 ##
##                 and unchanged FASTA records to the                        ##
##               genome_post_HYBRID_SCAFFOLD FASTA file                      ##
###############################################################################

my (${filename}, ${directories}, ${suffix}) = fileparse($orig_fasta_file,qr/\.[^.]*/); # directories has trailing slash includes dot in suffix
my $db = Bio::DB::Fasta->new("$orig_fasta_file");
my $out_file_temp = "${directories}${filename}_genome_post_HYBRID_SCAFFOLD_temp.fasta";
my $seq_out = Bio::SeqIO->new('-file' => ">$out_file_temp",'-format' => 'fasta');		#Create new fasta outfile object.

for my $header (@grab_id)
{
    my $seq_obj = $db->get_Seq_by_id($header); # get FASTA records using headers for sequence was NOT used already in the HYBRID_SCAFFOLD.fasta
    $seq_out->write_seq($seq_obj);
}

my $out_file = "${directories}${filename}_genome_post_HYBRID_SCAFFOLD.fasta";
open (my $out, ">", $out_file) or die "Can't open $out_file: $!";
open (my $hybScf_fasta,"<", $hybScf_fasta_file) or die "Can't open $hybScf_fasta_file:$!";
while (<$hybScf_fasta>)
{
    print $out "$_"; # add hybrid sequence from HYBRID_SCAFFOLD.fasta to the genome_post_HYBRID_SCAFFOLD FASTA file
}
open (my $temp_file, "<",$out_file_temp) or die "Can't open $out_file_temp: $!";
while (<$temp_file>)
{
    print $out "$_"; # add non-hybrid sequence from original.fasta to the genome_post_HYBRID_SCAFFOLD FASTA file
}
close ($hybScf_fasta);

my $out_used_file="${directories}${filename}_sequences_used_in_HYBRID_SCAFFOLD.txt";
open (my $out_used, ">", $out_used_file) or die "Can't open $out_used_file: $!";

for my $header (@skip_id)
{
    print $out_used "$header\n"; # make list of FASTA records used in HYBRID_SCAFFOLD.fasta
}


print "remove_count: $remove_count\nskipped_count: $skipped_count\n";
unlink ($out_file_temp);

print "Done\n";
###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME



hybridScaffold_finish_fasta.pl - Script creates new FASTA files including new hybrid sequences output by hybridScaffold and all sequences that were not used by hybridScaffold with their original headers. Also outputs a text file list of the headers for sequences that were used to make the new hybrid sequences.

=head1 DEPENDENCIES

Perl and BioPerl

=head1 USAGE

perl hybridScaffold_finish_fasta.pl [OPTIONS]
 
=head1 EXAMPLE

perl hybridScaffold_finish_fasta.pl -x <HYBRID_SCAFFOLD.xmap> -s <HYBRID_SCAFFOLD.fasta> -f <original.fasta>


Documentation options:

-help    brief help message
-man	    full documentation

Required parameters:

-x	    HYBRID_SCAFFOLD.xmap
-s	    HYBRID_SCAFFOLD.fasta
-f	    original.fasta


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-x, --hybScf_xmap_file>

Filename (including working path) for HYBRID_SCAFFOLD.xmap output with hybridScaffold from BioNano genomics.

=item B<-s, --hybScf_fasta_file>

Filename (including working path) for HYBRID_SCAFFOLD.fasta output with hybridScaffold from BioNano genomics.
 
=item B<-f, --orig_fasta_file>

Filename (including working path) for the user provided genome FASTA file used to create the in silico genome map (CMAP) input into the hybridScaffold pipeline from BioNano genomics.
=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

Script has no dependencies other than Perl and BioPerl.
 
=cut
 


