#!/usr/bin/perl
###############################################################################
#   
#	USAGE: perl assembly_qcXeonPhi.pl [options]
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
use File::Basename; # enable manipulating of the full path
# use List::Util qw(max);
# use List::Util qw(sum);
use Getopt::Long;
use Pod::Usage;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#  assembly_qcXeonPhi.pl                                  #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 03/03/15                   #\n";
print "#  https://github.com/i5K-KINBRE-script-share             #\n";
print "#  perl assembly_qcXeonPhi.pl -help # for usage/options   #\n";
print "#  perl assembly_qcXeonPhi.pl -man # for more details     #\n";
print "###########################################################\n";

###############################################################################
##############             get arguments                     ##################
###############################################################################
my ($bnx_dir,$project);

my $man = 0;
my $help = 0;
GetOptions (
			  'help|?' => \$help, 
			  'man' => \$man,
			  'b|bnx_dir:s' => \$bnx_dir,
			  'p|proj:s' => \$project
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

###############################################################################
########## create array with all default assembly directories #################
###############################################################################
my @directories = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180/;

open (QC_METRICS,'>',"$bnx_dir/../Assembly_quality_metrics.csv") or die "couldn't open $bnx_dir/../Assembly_quality_metrics.csv!";
print QC_METRICS "Assembly name,Number of BioNano genome map contigs,Total BioNano genome map length(Mb),Avg. BioNano genome map contig length(Mb),BioNano genome map contig N50(Mb),Total in silico genome map length(Mb),Total BioNano genome map length / in silico genome map length,Number BioNano genome map contigs aligned I,Total aligned length(Mb) I,Total aligned length / in silico genome map length I,Total Unique aligned length(Mb) I,Total unique aligned length / in silico genome map length I,Number BioNano genome map contigs aligned II,Total aligned length(Mb) II,Total aligned length / in silico genome map length II,Total unique aligned length(Mb) II,Total unique aligned length / in silico genome map length II\n";
#print QC_METRICS "Assembly Name,Assembly N50,refineB1 N50,Merge 0 N50,Extension 1 N50,Merge 1 N50,Extension 2 N50,Merge 2 N50,Extension 3 N50,Merge 3 N50,Extension 4 N50,Merge 4 N50,Extension 5 N50,Merge 5 N50,N contigs,Total Contig Len(Mb),Avg. Contig Len(Mb),Contig N50(Mb),Total Ref Len(Mb),Total Contig Len / Ref Len,N contigs total align I,Total Aligned Len(Mb) I,Total Aligned Len / Ref Len I,Total Unique Aligned Len(Mb) I,Total Unique Len / Ref Len I,N contigs total align II,Total Aligned Len(Mb) II,Total Aligned Len / Ref Len II,Total Unique Aligned Len(Mb) Final,Total Unique Len / Ref Len II\n";


###############################################################################
##########            open all assembly directories           #################
###############################################################################
for my $assembly_dir (@directories)
{
    my $final = 0;
    unless (opendir(DIR, "${bnx_dir}/${assembly_dir}"))
    {
        print "Can't open the directory ${bnx_dir}/${assembly_dir}\n"; # open directory full of assembly files
        next;
    }
    while (my $file = readdir(DIR))
    {
        next if ($file =~ m/^\./); # ignore files beginning with a period
        next if ($file !~ m/\_informaticsReport.txt$/); # ignore files not ending with a "_informaticsReport.txt"
        my $report = $file;
        print QC_METRICS "$project: $assembly_dir,";
        print  "$project: $assembly_dir,";
        open (BIOINFO_REPORT,'<',"${bnx_dir}/${assembly_dir}/$report");
        
        ###################################################################
        #####  pull QC metrics from assembly bioinfo reports   ############
        ###################################################################
        while (<BIOINFO_REPORT>)
        {
            chomp;
            if (/SV detect:/)
            {
                last;
            }
            if (/Stage\s+Summary:\s+Characterize.*\s+refineFinal1/i)
            {
                ++$final;
            }
#            #########################################################
#            #####  pull N50 from each stage of assembly  ############
#            #########################################################
#            if (($final == 0) && (/Contig N50/i))
#            {
#                s/(.*:\s+)(.*)/$2/;
#                print QC_METRICS;
#                print QC_METRICS ",";
#            }
            #########################################################
            ##  pull all metrics from final stage of assembly  ######
            #########################################################
            if ($final == 1)
            {
                if (/N Genome Maps:/i)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Genome Map Len \(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Avg\. Genome Map Len\s+\(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Genome Map n50.*:/i)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Ref Len\s+\(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Genome Map Len \/ Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
            }
            if (($final == 1)||($final ==2))
            {
                if (/N Genome Maps total align/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Aligned Len\s+\(Mb\)/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Aligned Len.*Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Unique Aligned Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Unique Len.*Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";

                }
            }
        }
        print QC_METRICS "\n";
    }
}
###############################################################################
print "Done generating assembly metrics\n";

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861 
__END__

=head1 NAME

assembly_qcXeonPhi.pl - a package of scripts that compile assembly metrics for assemblies in all of the possible subdirectories of the assembly directory: default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180.

The assemblies are created using AssembleIrysXeonPhi.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab.

The parameter -b should be the same as the -b parameter used for the assembly script. It is the directory with the BNX files used for assembly.
 
 

=head1 USAGE

perl assembly_qcXeonPhi.pl [options]

 Documentation options:
   -help    brief help message
   -man	    full documentation
 Required options:
   -b	     bnx directory
   -p	     project name for all assemblies
  
 
=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-b, --bnx_dir>

The BNX directory. The parameter -b should be the same as the -b parameter used for the assembly script. It is the directory with the BNX files used for assembly.
 
=item B<-p, --project>
 
The project id. The parameter -p should be the same as the -p parameter used for the assembly script. This was used to name all assemblies.


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

B<Assembly_quality_metrics.csv:>
This is a CSV file of assembly metrics for each of the existing assemblies in one of the possible assembly subdirectories: default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180.

B<Test with sample datasets:>

get clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/assembly_qcXeonPhi.pl -b [bnx_dir]

=cut
