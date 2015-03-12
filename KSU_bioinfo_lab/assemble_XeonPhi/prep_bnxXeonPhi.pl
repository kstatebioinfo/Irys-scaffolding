#!/usr/bin/perl
###############################################################################
#
#	USAGE: perl prep_bnxXeonPhi.pl -a <assembly working directory>
#
#  Created by Jennifer Shelton 2/26/15
#
# DESCRIPTION: Script makes links to all Molecules.bnx files in a common bnx directory and renames with auto-incremented numbers. Make paths absolute. Do not include trailing spaces in paths.

# Make an assembly working directory for a project. Transfer the "Datasets" directory transfered from the IrysView workspace to the assembly working directory for your project. The script then takes the path of the assembly working directory for your project as input and organizes the raw data in the correct format to run AssembleIrysXeonPhi.pl. The script also writes a key with the original file path and the new link for all BNX files.

#
# Example: perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble/prep_bnxXeonPhi.pl -a /home/irys/Data/Esch_coli_0000
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
print "#  prep_bnxXeonPhi.pl Version 1.0.0                       #\n";
print "#                                                         #\n";
print "#  Created by Jennifer Shelton 02/26/15                   #\n";
print "#  https://github.com/i5K-KINBRE-script-share             #\n";
print "#  perl prep_bnxXeonPhi.pl -help # for usage/options      #\n";
print "#  perl prep_bnxXeonPhi.pl -man # for more details        #\n";
print "###########################################################\n";

###############################################################################
##############             get arguments                     ##################
###############################################################################
my ($assembly_directory,$project);

my $man = 0;
my $help = 0;
my $extra_bnxs = 0;
GetOptions (
        'help|?' => \$help,
        'man' => \$man,
        'a|assembly_dir:s' => \$assembly_directory,
        'e|extra_bnxs' => \$extra_bnxs
)
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $bnx_directory = "${assembly_directory}/bnx";
unless(mkdir $bnx_directory)
{
    print "Unable to create $assembly_directory\n";
    if (!$extra_bnxs)
    {
        die "Exiting because the bnx directory may already exist. If you intend to add new bnx files to an existing directory check that these are not already linked to the current bnx directory and then use the -extra_bnxs flag to continue.\n";
    }
    
}
###############################################################################
##############            Move and rename files              ##################
###############################################################################
#my @dir_array = ('/homes', grep -d, glob "$dataset_directory/*");
my $logfile = "$bnx_directory/bnx_key.txt";
open (my $log, ">", $logfile) or die "Can't open $logfile\n";
my $dataset_directory = "${assembly_directory}/Datasets";
opendir (my $data, $dataset_directory) or die "Can't open $dataset_directory. Transfer the Dataset directory from Irysview after generating the run report.\n";
print "Creating links to all Molecules.bnx files in a common bnx directory and renaming with auto-incremented numbers...\n";
my $i=1;
while (my $entry = readdir $data )
{
    if (-d "${dataset_directory}/${entry}")
    {
        unless (($entry eq '..') || ($entry eq '.'))
        {
            my $link = "$bnx_directory/Molecules_${i}.bnx";
            while (-e $link)
            {
                ++$i;
                $link = "$bnx_directory/Molecules_${i}.bnx";
                
            }
#            my $linked= `ln -s \'${dataset_directory}/${entry}/Molecules.bnx\' $link`; # code for new Datasets directories
            my $linked= `ln -s \'${dataset_directory}/${entry}/Detect Molecules/Molecules.bnx\' $link`; # code for older Datasets directories
            print "$linked";
            print $log "Molecules_${i}.bnx\t${entry}\n";
            ++$i;
        }
        
    }
}


print "Done preping the working directory for AssembleIrysXeonPhi.pl\n";

###############################################################################
##############                  Documentation                ##################
###############################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861
__END__

=head1 NAME
 
Script makes links to all Molecules.bnx files in a common bnx directory and renames with auto-incremented numbers. Make paths absolute. Do not include trailing spaces in paths.
 
To use first make an assembly working directory for a project. Transfer the "Datasets" directory from the IrysView workspace to the assembly working directory for your project. The script then takes the path of the assembly working directory for your project as input and organizes the raw data in the correct format to run AssembleIrysXeonPhi.pl. The script also writes a key with the original file path and the new link for all BNX files.
 
 Then assemble using AssembleIrysXeonPhi.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab.
 
 The parameter -a should be the same as the -a parameter that you will use for the assembly script. It is the assembly working directory for a project.
 
 
=head1 USAGE
 
perl prep_bnxXeonPhi.pl [options]
 
Documentation options:
 
     -help    brief help message
     -man	    full documentation
 
Required options:
 
     -a	     assembly working directory for a project
     -e	     add new bnx files to bnx directory even though it already exists
 
 
=head1 OPTIONS

=over 8

=item B<-help>
 
 Print a brief help message and exits.
 
=item B<-man>
 
Prints the more detailed manual page with output details and examples and exits.
 
=item B<-a, --assembly_dir>
 
The assembly working directory for a project. The parameter -a should be the same as the -a parameter used for the assembly script.

=item B<-e, --extra_bnxs>
 
Prevents script from exiting if bnx directory already exists in assembly working directory. If you do intend to add new bnx files to an existing directory check that these are not already linked to the current bnx directory and then use the -extra_bnxs flag to continue.
 

 
=cut