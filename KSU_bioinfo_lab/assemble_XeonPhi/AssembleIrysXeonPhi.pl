#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl AssembleIrysXeonPhi.pl [options]
#   WARNING: SCRIPT CURRENTLY UNDER DEVELOPMENT!!!!
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
use Term::ANSIColor;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable manipulating of the full path
use Getopt::Long;
use Pod::Usage;
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print colored ("#      WARNING: SCRIPT CURRENTLY UNDER DEVELOPMENT        #", 'bold white on_blue'), "\n";
print "#  AssembleIrysXeonPhi.pl Version 1.0.0                   #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/26/15                    #\n";
print "#  github.com/i5K-KINBRE-script-share/Irys-scaffolding    #\n";
print "#  perl AssembleIrysXeonPhi.pl -help # for usage/options  #\n";
print "#  perl AssembleIrysXeonPhi.pl -man # for more details    #\n";
print "###########################################################\n";
#perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrysXeonPhi.pl -g 230 -a test_assembly_dir - p Oryz_sati_0027

##################################################################################
##############                get arguments                     ##################
##################################################################################
my ($assembly_directory,$genome,$reference,$project);

my $man = 0;
my $help = 0;
GetOptions (
			  'help|?' => \$help, 
			  'man' => \$man,
			  'a|assembly_dir:s' => \$assembly_directory,
              'g|genome:i' => \$genome,
              'r|ref:s' => \$reference,
              'p|proj:s' => \$project
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
my $T = 0.00001/$genome;
###################################################################################
############          Generate BNX file summaries                ##################
###################################################################################
print "##################################################################################\n";
print "Generating BNX stats...\n";
print "##################################################################################\n";
my $directory = "${assembly_directory}/${project}";
unless(mkdir $directory)
{
    print "Warning unable to create $directory. Directory exists\n";
}
chdir $directory;
my $linked= `ln -s \'${assembly_directory}/Datasets\' \'${directory}/\'`; # link Datasets directories to customers directory
print "$linked";
my $bnx_dir = "${assembly_directory}/bnx";
my $bnx_stats=`perl ${dirname}/../map_tools/bnx_stats.pl -l 100 ${bnx_dir}/Molecules_*.bnx`;
print "$bnx_stats";

###################################################################################
############          Rescaling molecules in BNX files         ##################
###################################################################################
print "##################################################################################\n";
print "Rescaling molecules in BNX files (formerly the adjusting stretch (bpp) step)...\n";
print "##################################################################################\n";
my $rescale_stretch=`perl ${dirname}/rescale_stretch.pl $assembly_directory $reference $T $project`;
print "$rescale_stretch";

###################################################################################
############                Writing assembly scripts               ################
###################################################################################
print "##################################################################################\n";
print "Writing assembly scripts...\n";
print "##################################################################################\n";
my $writing_assemblies=`perl ${dirname}/assemble.pl $assembly_directory $reference $T $project $genome`;
print "$writing_assemblies";



###################################################################################
###############  Run first molecule quality report and replace old bpp  ###########
###################################################################################
#print "##################################################################################\n";
#print "Generating first Molecule Quality Reports...\n";
#print "##################################################################################\n";
#my $first_mqr=`perl ${dirname}/first_mqr.pl $bnx_dir $reference $T`;
#print "$first_mqr";
###################################################################################
###############  Merge each split adjusted flowcells BNXs                    ######
###################################################################################
#print "##################################################################################\n";
#print "Merging split, adjusted BNX files for each flowcell...\n";
#print "##################################################################################\n";
#my $second_mqr=`perl ${dirname}/merge_split_by_scan.pl $bnx_dir $reference $T`;
#print "$second_mqr";
###################################################################################
############ Merge each BNX foreach flowcell and run second molecule quality ######
############     report on merged file with and without BestRef.             ######
###################################################################################
#print "##################################################################################\n";
#print "Merging the merged BNX for each flowcell. Generating second Molecule Quality Report for final merged BNX file...\n";
#print "##################################################################################\n";
#my $third_mqr=`perl ${dirname}/third_mqr.pl $bnx_dir $reference $T`;
#print "$third_mqr";
###################################################################################
### Write assembly scripts with a range of p-value thresholds and minimum lengths##
###################################################################################
#print "##################################################################################\n";
#print " Write assembly scripts with a range of p-value thresholds and minimum lengths...\n";
#print "##################################################################################\n";
#my $assemble=`perl ${dirname}/assemble.pl $bnx_dir $reference $T $dirname $project`;
#print "$assemble";
#print "Finished running AssembleIrysXeonPhi.pl\n";

##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861 
__END__

=head1 NAME

AssembleIrysXeonPhi.pl - a package of scripts run on the Beocat SGE cluster. They adjust the bases per pixel (bpp) by scan for each flowcell BNX file and then merge each flowcell into a single BNX file. Quality by flowcell is poltted in a CSV file "flowcell_summary.csv." Potential issues are reported in the output (e.g if the bpp does not return to ~500 after adjustment). The script creates optArgument.xml files and commands to run assemblies with strict, relaxed, and default p-value thresholds. The best of these along with the best p-value threshold (-T) should be used to run strict and relaxed assemblies with varing minimum lengths. Second assembly commands for each first assembly are written to the assembly_commands.sh script. They must be uncommented to run.

=head1 USAGE

perl AssembleIrysXeonPhi.pl [options]

 Documentation options:
   -help    brief help message
   -man	    full documentation
 Required options:
    -a	     the assembly working directory for a project
    -g	     genome size in Mb
    -r	     reference CMAP
    -p	     project name for all assemblies
  
   
=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the more detailed manual page with output details and exits.


=item B<-a, --assembly_dir>

The assembly working directory for a project. This should include the subdirectory "bnx" (any BNX in this directory will be used in assembly). Use absolute not relative paths. Do not use a trailing "/" for this directory.

=item B<-g, --genome>

The estimated size of the genome in Mb.
 
=item B<-r, --ref>
 
The full path to the reference genome CMAP.

=item B<-p, --project>
 
The project id. This will be used to name all assemblies

=back

=head1 DESCRIPTION

B<OUTPUT DETAILS:>

strict_t - These directories hold the output for the strictest assemblies (where the p-value threshold is divided by 10).
 
relaxed_t - These directories hold the output for the laxest assemblies (where the p-value threshold is multiplied by 10).
 
default_t - These directories hold the output for the default assemblies (where the p-value threshold is used as-is).
 
assembly_commands.sh - These are the commands to start the first pass of assemblies. In these strict, relaxed, and default p-value thresholds will be used all will the default minimum molecule length of 150kb.
 
bnx_rescaling_factors.pdf - This graph can be evaluated to check flowcell and alignment quality (ability to align to reference for each flowcell (you should see a consistant pattern.
 
MapStatsHistograms.pdf - This file can be evaluated to check molecule map quality.

B<Test with sample datasets:>

git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

# no test dataset is available yet but here is an example of a command
 
perl Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrysXeonPhi.pl -g  -a  -r  -p Test_project_name > testing_log.txt
 
bash assembly_commands.sh

=cut
