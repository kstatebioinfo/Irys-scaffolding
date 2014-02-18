#!/bin/perl
###############################################################################
#   
#	USAGE: perl assembly_qc.pl [options]
#
#  Created by jennifer shelton
#
###############################################################################
use strict;
use warnings;
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
			  'p|proj:s' => \$project,
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

###############################################################################
########## create array with all default assembly directories #################
###############################################################################
my @directories = ( "strict_t", "default_t", "relaxed_t", "strict_t/strict_ml", "strict_t/relaxed_ml", "default_t/strict_ml", "default_t/relaxed_ml", "relaxed_t/strict_ml", "relaxed_t/relaxed_ml");
open (QC_METRICS,'>>',"$bnx_dir/Assembly_quality_metrics.csv") or die "couldn't open $bnx_dir/Assembly_quality_metrics.csv!";
print QC_METRICS "Assembly Name,Assembly,refineB,Extension 1,Merge 1,Extension 2,Merge 2,Extension 3,Merge 3,Extension 4,Merge 4,Extension 5,Merge 5,refineFinal,N contigs,Total Contig Len(Mb),Avg. Contig Len(Mb),Contig n50(Mb),Total Ref Len(Mb),Total Contig Len / Ref Len,N contigs total align,Total Aligned Len(Mb),Total Aligned Len / Ref Len,Total Unique Aligned Len(Mb),Total Unique Len / Ref Len\n";
###############################################################################
##########            open all assembly directories           #################
###############################################################################
my $final=0;
for my $assembly_dir (@directories)
{
    my $report= "$bnx_dir/$assembly_dir/${project}_informaticsReport.txt";
    if (-e $report)
    {
        print QC_METRICS "$project: $assembly_dir,";
        open (BIOINFO_REPORT,'<',"$report");
        
        ###################################################################
        #####  pull QC metrics from assembly bioinfo reports   ############
        ###################################################################
        while (<BIOINFO_REPORT>)
        {
            if (/Stage Complete: refineFinal/)
            {
                $final = 1;
            }
            #########################################################
            #####  pull N50 from each stage of assembly  ############
            #########################################################
            if (($final == 0) && (/Contig n50/))
            {
                chomp;
                s/(Contig n50.*(Mb):\s+)(.*)/$2/;
                print QC_METRICS;
                print QC_METRICS ",";
            }
            #########################################################
            ##  pull all metrics from final stage of assembly  ######
            #########################################################
            if ($final == 1)
            {
                chomp;
                if (/N contigs:/)
                {
                    s/(N contigs:\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Contig Len (Mb):/)
                {
                    s/(Total Contig Len (Mb):\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Avg. Contig Len  (Mb):/)
                {
                    s/(Avg. Contig Len  (Mb):\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Contig n50       (Mb):/)
                {
                    s/(Contig n50       (Mb):\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Ref Len    (Mb):/)
                {
                    s/(Total Ref Len    (Mb):\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Contig Len \/ Ref Len  :/)
                {
                    s/(Total Contig Len \/ Ref Len  :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/N contigs total align       :/)
                {
                    s/(N contigs total align       :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Aligned Len             (Mb) :/)
                {
                    s/(Total Aligned Len             (Mb) :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Aligned Len \/ Ref Len        :/)
                {
                    s/(Total Aligned Len \/ Ref Len        :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Unique Aligned Len      (Mb) :/)
                {
                    s/(Total Unique Aligned Len      (Mb) :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS ",";
                }
                if (/Total Unique Len \/ Ref Len         :/)
                {
                    s/(Total Unique Len \/ Ref Len         :\s+)(.*)/$2/;
                    print QC_METRICS;
                    print QC_METRICS "\n";
                }
            }
                
        }
    }
}
#            N contigs: 216
#            Total Contig Len (Mb):   200.473
#            Avg. Contig Len  (Mb):    0.928
#            Contig n50       (Mb):    1.350
#            Total Ref Len    (Mb):   157.186
#            Total Contig Len / Ref Len  : 1.275
#            N contigs total align       :   147 (0.68)
#            Total Aligned Len             (Mb) : 114.090
#            Total Aligned Len / Ref Len        :  0.726
#            Total Unique Aligned Len      (Mb) : 110.120
#            Total Unique Len / Ref Len         :  0.701
#Stage Complete: Assembly
#Stage Complete: refineB
#Stage Complete: Extension 1
#Stage Complete: Merge 1
#Stage Complete: Extension 2
#Stage Complete: Merge 2
#Stage Complete: Extension 3
#Stage Complete: Merge 3
#Stage Complete: Extension 4
#Stage Complete: Merge 4
#Stage Complete: Extension 5
#Stage Complete: Merge 5
#Stage Complete: refineFinal



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