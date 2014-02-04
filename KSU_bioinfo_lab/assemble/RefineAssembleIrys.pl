#!/bin/perl
##################################################################################
#   
#	USAGE: perl script.pl [options]
#
#  Created by jennifer shelton
#
##################################################################################
use strict;
use warnings;
# use List::Util qw(max);
# use List::Util qw(sum);
use File::Basename; # enable maipulating of the full path
use Getopt::Long;
use Pod::Usage;
##################################################################################
##############         Print informative message                ##################
##################################################################################
print "###########################################################\n";
print "#  RefineAssembleIrys.pl                                        #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 2/3/14                    #\n";
print "#  github.com/                                            #\n";
print "#  perl AssembleIrys.pl -help # for usage/options         #\n";
print "#  perl AssembleIrys.pl -man # for more details           #\n";
print "###########################################################\n";
#perl /Users/jennifershelton/Desktop/Perl_course_texts/scripts/Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g 230 -b test_bnx - p Oryz_sati_0027

##################################################################################
##############                get arguments                     ##################
##################################################################################
my ($bnx_dir,$genome,$reference,$project);

my $man = 0;
my $help = 0;
GetOptions (
			  'help|?' => \$help, 
			  'man' => \$man,
			  'b|best_assembly_dir:s' => \$best_assembly_dir,    
              'g|genome:i' => \$genome,
              'r|ref:s' => \$reference,
              'p|proj:s' => \$project
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
my $dirname = dirname(__FILE__);
my $T = 0.00001/$genome;
##################################################################################
##############          Create new assembly parameters          ##################
##################################################################################


##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
 script.pl - a package of scripts that ...
 
 =head1 USAGE
 
 perl script.pl [options]
 
 Documentation options:
 -help    brief help message
 -man	    full documentation
 Required options:
 -b	     directory with all BNX's meant for assembly (any BNX in this directory will be used in assembly)
 -g	     genome size in Mb
 -r	     reference CMAP
 -p	     project name for all assemblies
 
 
 =head1 OPTIONS
 
 =over 8
 
 =item B<-help>
 
 Print a brief help message and exits.
 
 =item B<-man>
 
 Prints the more detailed manual page with output details and exits.
 'help|?' => \$help,
 'man' => \$man,
 'b|bnx_dir:s' => \$bnx_dir,
 'g|genome:i' => \$genome,
 'r|ref:s' => \$reference,
 'p|proj:s' => \$project
 
 =item B<-b, --bnx_dir>
 
 The directory with all BNX's meant for assembly (any BNX in this directory will be used in assembly. Do not use a trailing / for this directory.
 
 =item B<-g, --genome>
 
 The estimated size of the genome in Mb.
 
 =item B<-r, --ref>
 
 The full path to the reference genome CMAP.
 
 =item B<-p, --project>
 
 The project id. This will be used to name all assemblies
 
 =back
 
 =head1 DESCRIPTION
 
 B<OUTPUT DETAILS:>
 
 strict_t - This directory holds the output for the strictest assembly (where the p-value threshold is divided by 10).
 
 relaxed_t - This directory holds the output for the laxest assembly (where the p-value threshold is multiplied by 10).
 
 default_t - This directory holds the output for the default assembly (where the p-value threshold is used as-is).
 
 bestref_effect_summary.csv - this shows the difference between running a molecule quality report with and without - BestRef. If the values change substantially than your p-value threshold may be too lax.
 
 assembly_commands.txt - These are the commands to start the first pass of assemblies. In these strict, relaxed, and default p-value thresholds will be used.
 
 flowcell_summary.csv - This file can be evaluated to check quality (ability to align to reference for each flowcell.
 
 B<Test with sample datasets:>
 
 git clone https://github.com/i5K-KINBRE-script-share
 
 # no test dataset is available yet but here is an example of a command
 
 perl Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g  -b  -r  -p Test_project_name > testing_log.txt
 
 =cut





