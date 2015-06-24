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
use File::Spec;
###############################################################################
##############         Print informative message             ##################
###############################################################################
print "###########################################################\n";
print "#  assembly_qcXeonPhi.pl Version 1.0.1                    #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 03/03/15                   #\n";
print "#  https://github.com/i5K-KINBRE-script-share             #\n";
print "#  perl assembly_qcXeonPhi.pl -help # for usage/options   #\n";
print "#  perl assembly_qcXeonPhi.pl -man # for more details     #\n";
print "###########################################################\n";

###############################################################################
##############             get arguments                     ##################
###############################################################################
my ($assembly_directory,$project,$genome,$de_novo);
my $man = 0;
my $help = 0;
GetOptions (
			  'help|?' => \$help, 
			  'man' => \$man,
			  'a|assembly_dir:s' => \$assembly_directory,
			  'p|proj:s' => \$project,
			  'g|genome:i' => \$genome,
			  'd|de_novo' => \$de_novo
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
die "Option -a or --assembly_dir not specified.\n" unless $assembly_directory; # report missing required variables
die "Option -p or --proj not specified.\n" unless $project; # report missing required variables
die "Option -g or --genome not specified.\n" unless $genome; # report missing required variables
$assembly_directory = File::Spec->rel2abs($assembly_directory);
###############################################################################
########## create array with all default assembly directories #################
###############################################################################
#my @directories = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180 default_t_default_noise/;
#my @directories = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180 default_t_default_noise default_t_150_no_rescale default_t_150_adj_stretch\/default_t_150_adj_stretch/;
my @directories = qw/default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180/;
unless($de_novo) # if the project is not de novo then make no assembly with default noise parameters as a directory name was run because all assemblies do not have this
{
    push(@directories, 'default_t_default_noise');
}
my $qc_metrics_file = "${assembly_directory}/Assembly_quality_metrics.csv";
open (my $qc_metrics,'>',$qc_metrics_file) or die "Couldn't open $qc_metrics_file!";
print $qc_metrics "Assembly name,Number of BioNano genome map contigs,Total BioNano genome map length(Mb),Avg. BioNano genome map contig length(Mb),BioNano genome map contig N50(Mb)";
unless($de_novo)
{
    print $qc_metrics ",Total in silico genome map length(Mb),Total BioNano genome map length / in silico genome map length,Number BioNano genome map contigs aligned I,Total aligned length(Mb) I,Total aligned length / in silico genome map length I,Total Unique aligned length(Mb) I,Total unique aligned length / in silico genome map length I,Number BioNano genome map contigs aligned II,Total aligned length(Mb) II,Total aligned length / in silico genome map length II,Total unique aligned length(Mb) II,Total unique aligned length / in silico genome map length II\n";
}
else
{
    print $qc_metrics "\n";
}

###############################################################################
##########            open all assembly directories           #################
###############################################################################
my $Assembly_parameter_tests_file = "${assembly_directory}/Assembly_parameter_tests.csv";
my $assembly_count =1;
my $Assembly_parameter_tests;
unless($de_novo)
{
    open ( $Assembly_parameter_tests, ">", $Assembly_parameter_tests_file) or die "Can't open $Assembly_parameter_tests_file: $!";
    print $Assembly_parameter_tests "Number,Genome_map,Breadth_of_alignment,Total_alignment_length,Cumulative_length\n"; # print headers to csv file
}
for my $assembly_dir (@directories)
{
    if (-d "${assembly_directory}/${assembly_dir}/contigs")
    {
        ###################################################################
        #####            pull QC metrics from CMAP             ############
        ###################################################################
    #    /home/bionano/bionano/Gram_nega_2014_055/strict_t_150/contigs/Gram_nega_2014_055_strict_t_150_refineFinal1
        my @cmap = glob("${assembly_directory}/${assembly_dir}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap"); # BioNano genome map assembly CMAP
        my $cmap_length;
        for my $cmap (@cmap)
        {
            if (-f $cmap)
            {
                my $cmap_stats_out = `perl ${dirname}/../map_tools/cmap_stats.pl -c $cmap`;
                if ($cmap_stats_out !~ /cmap N50:/)
                {
                    print "The $assembly_dir assembly may be in progress, skipping this assembly.\n\n";
                    next;
                }
                $cmap_stats_out =~ /.*Total cmap length: (.*) \(Mb\).*/;
                $cmap_length = $1;
            }
        }
        ###################################################################
        #####            pull QC metrics from XMAP             ############
        ###################################################################
        #    /home/bionano/bionano/Gram_nega_2014_055/strict_t_150/contigs/Gram_nega_2014_055_strict_t_150_refineFinal1/alignref_final/GRAM_NEGA_2014_055_STRICT_T_150_REFINEFINAL1.xmap
        unless ($de_novo) # an xmap should exist if a project is not de novo)
        {
            my @xmap = glob("${assembly_directory}/${assembly_dir}/contigs/*_refineFinal1/alignref/*_REFINEFINAL1.xmap"); # in silico genome map to BioNano genome map XMAP
            for my $xmap (@xmap)
            {
                if (-f $xmap)
                {
                    my $xmap_stats_out = `perl ${dirname}/../map_tools/xmap_stats.pl -x $xmap`;
                    $xmap_stats_out =~ /Breadth of alignment coverage = (.*) \(Mb\)\nTotal alignment length = (.*) \(Mb\)/;
                    my $breadth = $1;
                    my $total_aligned_length = $2;
                    ##########################################################
                    #####      print QC metrics from CMAP and XMAP    ########
                    ##########################################################
                    print $Assembly_parameter_tests "${assembly_count},${assembly_dir},${breadth},${total_aligned_length},${cmap_length}\n";
                }
            }
        }
        ++$assembly_count;
    }
    ###################################################################
    #####    Get metrics from BioNano informatics report   ############
    ###################################################################
    my $final = 0;
    unless (opendir(DIR, "${assembly_directory}/${assembly_dir}"))
    {
        print "Can't open the directory ${assembly_directory}/${assembly_dir}\n"; # open directory full of assembly files
        next;
    }
    while (my $file = readdir(DIR))
    {
        next if ($file =~ m/^\./); # ignore files beginning with a period
        next if ($file !~ m/\_informaticsReport.txt$/); # ignore files not ending with a "_informaticsReport.txt"
        my $report = $file;
        print $qc_metrics "$project: $assembly_dir,";
        my $bioinfo_report_file = "${assembly_directory}/${assembly_dir}/$report";
        open (my $bioinfo_report,'<',$bioinfo_report_file) or die "Can't open $bioinfo_report_file : $!";
        ###################################################################
        #####  pull QC metrics from assembly bioinfo reports   ############
        ###################################################################
        while (<$bioinfo_report>)
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
            #########################################################
            ##  pull all metrics from final stage of assembly  ######
            #########################################################
            if ($final == 1) # grab most finished stats
            {
                if (/N Genome Maps:/i)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Genome Map Len \(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Avg\. Genome Map Len\s+\(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Genome Map n50.*:/i)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Ref Len\s+\(Mb\):/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Genome Map Len \/ Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
            }
            if (($final == 1)||($final ==2)) # grab the alignment stats for with and without best ref
            {
                if (/N Genome Maps total align/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Aligned Len\s+\(Mb\)/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Aligned Len.*Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Unique Aligned Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";
                }
                elsif (/Total Unique Len.*Ref Len/)
                {
                    s/(.*:\s+)(.*)/$2/;
                    print $qc_metrics "$_";
                    print $qc_metrics ",";

                }
            }
        }
        close($bioinfo_report);
        print $qc_metrics "\n";
    }
}
###############################################################################
##########                Plot assembly metrics               #################
###############################################################################
unless ($de_novo)
{
    close ($Assembly_parameter_tests);
}
close($qc_metrics);
open ($qc_metrics,'<',$qc_metrics_file) or die "Couldn't open $qc_metrics_file!";
########## Check that any informatics report included output in the final iteration (check that the assembly did not fail) (if so line count will be greater than 2)
my $qc_metrics_line_count = 0;
while (<$qc_metrics>)
{
    if (eof)
    {
        $qc_metrics_line_count = $. ;
    }
}
unless($de_novo)
{
    if ($qc_metrics_line_count > 2)
    {
        my $Assembly_parameter_tests_plot = "${assembly_directory}/Assembly_parameter_tests.pdf";
        my $title = "Assembly metrics for selection of best $project assembly";
        my $assembly_plot_out = `Rscript ${dirname}/graph_assemblies.R $Assembly_parameter_tests_file $Assembly_parameter_tests_plot $genome '$title'`;
        print $assembly_plot_out;
    }
    else
    {
        print "Currently no assemblies have produced results therefore no graph was plotted\n";
    }
}
else
{
    if ($qc_metrics_line_count > 1)
    {
        #add graph of de novo assemblies here
#        my $assembly_plot_out = `Rscript ${dirname}/graph_assemblies.R $Assembly_parameter_tests_file $Assembly_parameter_tests_plot $genome '$title'`;
#        print $assembly_plot_out;
    }
    else
    {
        print "Currently no assemblies have produced results therefore no metrics were generated\n";
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

assembly_qcXeonPhi.pl - a package of scripts that compile assembly metrics for assemblies in all of the possible subdirectories of the assembly directory: default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180 default_t_default_noise.

The assemblies are created using AssembleIrysXeonPhi.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab.

The parameter -a should be the same as the -a parameter used for the assembly script. It is the assembly working directory for a project.
 
=head1 UPDATES
B<assembly_qcXeonPhi.pl Version 1.0.1>
 
Fixed typo in help menu to replace -b parameter with the correct -a parameter.

=head1 USAGE

perl assembly_qcXeonPhi.pl [options]

Documentation options:
 
   -help    brief help message
   -man	    full documentation
 
Required options:
 
   -a	     assembly working directory
   -p	     project name for all assemblies
   -g	     genome size in Mb
 
Optional options:
 
   -d	     add this flag if the project is de novo (has no reference)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and examples and exits.

=item B<-a, --assembly_dir>

The assembly working directory for a project. This should include the subdirectory "bnx" (any BNX in this directory will be used in assembly). Use absolute not relative paths. Do not use a trailing "/" for this directory.
 
=item B<-p, --project>
 
The project id. The parameter -p should be the same as the -p parameter used for the assembly script. This was used to name all assemblies.
 
=item B<-g, --genome>

The estimated size of the genome in Mb.
 
=item B<-d, --de_novo>

Add this flag to the command if a project is de novo (i.e. has no reference). Any step that requires a reference will then be skipped.


=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

B<Assembly_quality_metrics.csv:>
This is a CSV file of assembly metrics for each of the existing assemblies in one of the possible assembly subdirectories: default_t_150 relaxed_t_150 strict_t_150 default_t_100 relaxed_t_100 strict_t_100 default_t_180 relaxed_t_180 strict_t_180 default_t_default_noise.

B<QUICK START:>

get clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding
 
# Reference-based project:

perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/assembly_qcXeonPhi.pl -a <assembly_dir> -p <project> -g <genome_size>
 
# De novo project:
 
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/assembly_qcXeonPhi.pl -a <assembly_dir> -p <project> -g <genome_size> --de_novo


=cut
