#!/usr/bin/perl
##################################################################################
#   
#	USAGE: perl AssembleIrysXeonPhi.pl [options]
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
my $version = 0;
my $de_novo = 0;
GetOptions (
			  'help|?' => \$help,
              'version' => \$version,
			  'man' => \$man,
			  'a|assembly_dir:s' => \$assembly_directory,
              'g|genome:i' => \$genome,
              'r|ref:s' => \$reference,
              'p|proj:s' => \$project,
              'd|de_novo' => \$de_novo
              )  
or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
if ($version)
{
    print "AssembleIrysXeonPhi.pl Version 1.0.0\n";
    exit;
}
my $dirname = dirname(__FILE__);
die "Option -a or --assembly_dir not specified.\n" unless $assembly_directory; # report missing required variables
die "Option -p or --proj not specified.\n" unless $project; # report missing required variables
die "Option -g or --genome not specified.\n" unless $genome; # report missing required variables
unless ($de_novo)
{
    die "Option -r or --ref not specified.\n" unless $reference; # report missing required variables
}
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
chdir $directory; # becasue bnx_stats.pl prints out to the current directory
my $linked= `ln -s \'${assembly_directory}/Datasets\' \'${directory}/\'`; # link Datasets directories to final report directory
print "$linked";
my $bnx_dir = "${assembly_directory}/bnx";
my $bnx_stats=`perl ${dirname}/../map_tools/bnx_stats.pl -l 100 ${bnx_dir}/Molecules_*.bnx`;
print "$bnx_stats";
###################################################################################
############    Make reference CMAP available for final report   ##################
###################################################################################
unless ($de_novo)
{
    my $ref_directory = "${assembly_directory}/${project}/in_silico_cmap";
    unless(mkdir $ref_directory)
    {
        print "Warning unable to create $ref_directory. Directory exists\n";
    }
    my (${cmap_filename}, ${cmap_directories}, ${cmap_suffix}) = fileparse($reference,'\.[^.]+$'); # requires File::Basename and adds trailing slash to $directories and keeps dot in file extension
    my $cmap_linked= `ln -s \'$reference\' \'${ref_directory}/${cmap_filename}${cmap_suffix}\'`; # link reference cmap directories to final report directory
    print "$cmap_linked";
    my $cmap_key_linked= `ln -s \'${cmap_directories}${cmap_filename}_key.txt\' \'${ref_directory}/${cmap_filename}_key.txt\'`; # link reference cmap key to final report directory
    print "$cmap_key_linked";
}
###################################################################################
############          Rescaling molecules in BNX files         ##################
###################################################################################
if ($de_novo)
{
    print "##################################################################################\n";
    print "Merging molecules in BNX files for de novo assembly...\n";
    print "##################################################################################\n";
    my $merge_bnx=`perl ${dirname}/rescale_stretch.pl $assembly_directory $T $project`;
    print "$merge_bnx";
}
else
{
    print "##################################################################################\n";
    print "Rescaling molecules in BNX files (formerly the adjusting stretch (bpp) step)...\n";
    print "##################################################################################\n";
    my $rescale_stretch=`perl ${dirname}/rescale_stretch.pl $assembly_directory $T $project $reference`;
    print "$rescale_stretch";
}
###################################################################################
############                Writing assembly scripts               ################
###################################################################################
print "##################################################################################\n";
print "Writing assembly scripts...\n";
print "##################################################################################\n";
unless ($de_novo)
{
    my $writing_assemblies=`perl ${dirname}/assemble.pl $assembly_directory $T $project $genome $reference`;
    print "$writing_assemblies";
}
else
{
    my $writing_assemblies=`perl ${dirname}/assemble.pl $assembly_directory $T $project $genome`;
    print "$writing_assemblies";

}

print "Finished running AssembleIrysXeonPhi.pl\n";

##################################################################################
##############                  Documentation                   ##################
##################################################################################
## style adapted from http://www.perlmonks.org/?node_id=489861 
__END__

=head1 NAME

AssembleIrysXeonPhi.pl - the package of scripts preps raw molecule maps and writes and runs a series of assemblies for them. Then the user selects the best assembly and uses this to super scaffold the reference FASTA genome file and summarize the final assembly metrics and alignments.

The basic steps are to first merge multiple BNXs from a single directory and plot single molecule map quality metrics. Then Rescale single molecule maps and plot rescaling factor per scan (adjusting stretch scan by scan) if reference is available. Writes scripts for assemblies with a range of parameters.

This pipeline uses the same basic workflow as AssembleIrys.pl and AssembleIrysCluster.pl but it runs a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization may be required to run the BioNano Assembler on a different machine.

See tutorial lab to run the assemble XeonPhi pipeline with sample data https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_LAB.md.


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
 
 Optional options:
 
    -d	     add this flag if the project is de novo (has no reference)
   
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
 
=item B<-d, --de_novo>

Add this flag to the command if a project is de novo (i.e. has no reference). Any step that requires a reference will then be skipped.


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

See tutorial lab to run the assemble XeonPhi pipeline with sample data https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_LAB.md.

=cut
