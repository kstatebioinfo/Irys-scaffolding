#NOTE: AssembleIrysCluster.pl is no longer supported. This workflow has been replaced by AssembleIrysXeonPhi.pl.

`AssembleIrysXeonPhi.pl` runs on a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. See the following tutorials for details on the new workflow:

https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_LAB.md

https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_de_novo_LAB.md

SUMMARY

**AssembleIrysCluster.pl -** Adjusts stretch by scan. Merges BNXs and initiate assemblies with a range of parameters. Runs on the Beocat SGE cluster.

Workflow diagram
![Alt text](https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_SGE_cluster/bionano%20assembly%20workflow.png)

 1) The Irys produces tiff files that are converted into BNX text files.
 2) Each chip produces one BNX file for each of two flowcells.
 3) BNX files are split by scan and aligned to the sequence reference. Stretch (bases per pixel) is recalculated from the alignment.
 4) Quality check graphs are created for each pre-adjusted flowcell BNX.
 5) Adjusted flowcell BNXs are merged.
 6) The first assemblies are run with a variety of p-value thresholds.
 7) The best of the first assemblies (red oval) is chosen and a version of this assembly is produced with a variety of minimum molecule length filters.
    
USAGE
    
    perl AssembleIrysCluster.pl -g <genome size in Mb> -r <reference CMAP> -b <directory with BNX files> -p <project name>
    
DEPENDENCIES

    Perl module XML::Simple. This can be installed using CPAN http://search.cpan.org/~grantm/XML-Simple-2.20/lib/XML/Simple.pm;
    Perl module Data::Dumper. This can be installed using CPAN http://search.cpan.org/~smueller/Data-Dumper-2.145/Dumper.pm;
    
UPDATES

####AssembleIrysCluster.pl Version 1.6.1. 

Removed regression for adjust stretch. Deletes new alignment output files from Molecules_X directories. Removes auto-noise until further testing. Add -T and -j back to pipeline call because they are required on top of values in the cluster xml file for threads.

####AssembleIrysCluster.pl Version 1.6. 

Version is faster especially for larger datasets because each molecule quality report is generated from max 10,000 sub-sampled molecules.

####AssembleIrysCluster.pl Version 1.5.1. 

Modified KSU_bioinfo_lab/assemble_SGE_cluster/assemble.pl for new optArguments.xml. Changed KSU_bioinfo_lab/assembly_qc.pl for new informatics reports. Speed up stitch/agp2bed.pl. Modified KSU_bioinfo_lab/stitch/make_contigs_from_fasta.pl to only split at gaps longer than ten bases.

####AssembleIrysCluster.pl Version 1.5

Sets noise parameters based on molecule quality reports (MQR) so that
is auto-noise fails the -y flag can be removed from
assembly_commands.sh and the assemblies can be run with MQR parameters.

####AssembleIrysCluster.pl v. 1.4

Updated for new Assembler with auto noise

####AssembleIrysCluster.pl v.1.3

Fixed bug in lowering minimum lengths. Returned optArguments.xml to
default parameters.

####AssembleIrysCluster.pl Version 1.2

AssembleIrysCluster.pl Version 1.2 fixed a bug in listing split and adjusted bnx files

####AssembleIrys.pl AssembleIrysCluster.pl Version 1.1 04/21/2014

AssembleIrys.pl and AssembleIrysCluster.pl Version 1.1 were updated to
remove an unnecessary file removal step in the first_mqr.pl script

####AssembleIrysCluster.pl Version 1.3 05/01/2014

Fixed bug in lowering minimum lengths. Returned optArguments.xml to default parameters.


SCRIPT DETAILS

**AssembleIrys.pl -** a package of scripts that runs on the Beocat SGE cluster. They adjust the bases per pixel (bpp) by scan for each flowcell BNX file and then merge each flowcell into a single BNX file. Quality by flowcell is poltted in a CSV file "flowcell_summary.csv." Potential issues are reported in the output (e.g if the bpp does not return to ~500 after adjustment). The script creates optArgument.xml files and commands to run assemblies with strict, relaxed, and default p-value thresholds. The best of these along with the best p-value threshold (-T) should be used to run strict and relaxed assemblies with varing minimum lengths. Second assembly commands for each first assembly are written to the assembly_commands.sh script. They must be uncommented to run.

USAGE

       perl script.pl [options]

        Documentation options:
          -help    brief help message
          -man     full documentation
        Required options:
           -b       directory with all BNX's meant for assembly (any BNX in this directory will be used in assembly)
           -g       genome size in Mb
           -r       reference CMAP
           -p       project name for all assemblies

OPTIONS

       -help   Print a brief help message and exits.

       -man    Prints the more detailed manual page with output details and
               exits.

       -b, --bnx_dir
               The directory with all BNX's meant for assembly (any BNX in
               this directory will be used in assembly. Use absolute not relative paths. Do not use a trailing
               / for this directory.

       -g, --genome
               The estimated size of the genome in Mb.

       -r, --ref
               The full path to the reference genome CMAP.

       -p, --project
               The project id. This will be used to name all assemblies

OUTPUT DESCRIPTION

       strict_t - This directory holds the output for the strictest assembly
       (where the p-value threshold is divided by 10).

       relaxed_t - This directory holds the output for the laxest assembly
       (where the p-value threshold is multiplied by 10).

       default_t - This directory holds the output for the default assembly
       (where the p-value threshold is used as-is).

       bestref_effect_summary.csv - this shows the difference between running
       a molecule quality report with and without - BestRef. If the values
       change substantially than your p-value threshold may be too lax.

       assembly_commands.sh - These are the commands to start the first pass
       of assemblies. In these strict, relaxed, and default p-value thresholds
       will be used.

       flowcell_summary.csv - This file can be evaluated to check quality
       (ability to align to reference for each flowcell.

**Test with sample datasets:**

```
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

# no test dataset is available yet but here is an example of a command

perl Irys-scaffolding/KSU_bioinfo_lab/assemble/AssembleIrys.pl -g  -b -r  -p Test_project_name > testing_log.txt

bash assembly_commands.sh
```
    
    
