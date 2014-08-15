#!/usr/bin/perl
###############################################################################
#   
#	USAGE: perl assembly_qc.pl [options]
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
print "#  assembly_qc.pl                                         #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 02/17/14                   #\n";
print "#  https://github.com/i5K-KINBRE-script-share             #\n";
print "#  perl assembly_qc.pl -help # for usage/options          #\n";
print "#  perl assembly_qc.pl -man # for more details            #\n";
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
my @directories = (
    "strict_t/strict_ml",
    "strict_t",
    "strict_t/relaxed_ml",
    "default_t/strict_ml",
    "default_t",
    "default_t/relaxed_ml",
    "relaxed_t/strict_ml",
    "relaxed_t",
    "relaxed_t/relaxed_ml"
);
open (QC_METRICS,'>',"$bnx_dir/Assembly_quality_metrics.csv") or die "couldn't open $bnx_dir/Assembly_quality_metrics.csv!";
print QC_METRICS "Assembly Name,Assembly N50,refineB1 N50,Merge 0 N50,Extension 1 N50,Merge 1 N50,Extension 2 N50,Merge 2 N50,Extension 3 N50,Merge 3 N50,Extension 4 N50,Merge 4 N50,Extension 5 N50,Merge 5 N50,N contigs,Total Contig Len(Mb),Avg. Contig Len(Mb),Contig N50(Mb),Total Ref Len(Mb),Total Contig Len / Ref Len,N contigs total align I,Total Aligned Len(Mb) I,Total Aligned Len / Ref Len I,Total Unique Aligned Len(Mb) I,Total Unique Len / Ref Len I,N contigs total align II,Total Aligned Len(Mb) II,Total Aligned Len / Ref Len II,Total Unique Aligned Len(Mb) Final,Total Unique Len / Ref Len II\n";


###############################################################################
##########            open all assembly directories           #################
###############################################################################
my $final = 0;

my $single_mol_breadth_of_coverage = 0;
for my $assembly_dir (@directories)
{
    my $final = 0;
    unless (opendir(DIR, "${bnx_dir}/${assembly_dir}"))
    {
        print "can't open the directory ${bnx_dir}/${assembly_dir}\n"; # open directory full of assembly files
        next;
    }
    while (my $file = readdir(DIR))
    {
        next if ($file =~ m/^\./); # ignore files beginning with a period
        next if ($file !~ m/\_informaticsReport.txt$/); # ignore files not ending with a "_informaticsReport.txt"
        my $report = $file;
        print QC_METRICS "$project: $assembly_dir,";
        open (BIOINFO_REPORT,'<',"${bnx_dir}/${assembly_dir}/$report");
        
        ###################################################################
        #####  pull QC metrics from assembly bioinfo reports   ############
        ###################################################################
        while (<BIOINFO_REPORT>)
        {
            chomp;
            if (/SV detect:/)
            {
                next;
            }
            if (/Stage\s+Summary:\s+Characterize.*\s+refineFinal1/i)
            {
                ++$final;
            }
            #########################################################
            #####  pull N50 from each stage of assembly  ############
            #########################################################
            if (($final == 0) && (/Contig N50/i))
            {
                s/(.*:\s+)(.*)/$2/;
                print QC_METRICS;
                print QC_METRICS ",";
            }
            #########################################################
            ##  pull all metrics from final stage of assembly  ######
            #########################################################
            if ($final == 1)
            {
                if (/N contigs:/i)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Total Contig Len \(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Avg. Contig Len\s+\(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                elsif (/Contig n50.*:/i)
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
                elsif (/Total Contig Len \/ Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
            }
            if (($final == 1)||($final ==2))
            {
                if (/N contigs total align/)
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
#    print QC_METRICS "\n";
#    my $report= "$bnx_dir/$assembly_dir/all_flowcells/all_flowcells_adj_merged_bestref.xmap";
#    if (-e $report)
#    {
#        # ADD SCRIPT TO CALCULATE SINGLE MOLECULE BREADTH OF COVERAGE FROM XMAP
#    }
}
###############################################################################
print "Done\n";

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861 
__END__

=head1 NAME

 assembly_qc.pl - a package of scripts that compile assembly metrics for assemblies in all of the possible directories:'strict_t', 'default_t', 'relaxed_t', 'strict_t/strict_ml', 'strict_t/relaxed_ml', 'default_t/strict_ml', 'default_t/relaxed_ml', 'relaxed_t/strict_ml', and 'relaxed_t/relaxed_ml'.
 
 The assemblies are created using either of the following scripts assemble/AssembleIrys.pl or assemble_SGE_cluster/AssembleIrysCluster.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab. 
 
 The parameter -b should be the same as the -b parameter used for the assembly script. It is the directory with the BNX files used for assembly.
 
 

=head1 USAGE

perl assembly_qc.pl [options]

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
This file is a CSV file for each of the existing assemblies out of the existing assemblies out of the nine possible stringency parameters.

B<Test with sample datasets:>

get clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

perl Irys-scaffolding/KSU_bioinfo_lab/assembly_qc.pl -b [bnx_dir]

=cut
