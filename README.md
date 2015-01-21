Irys-scaffolding
================

scripts to parse IrysView output

KSU_bioinfo_lab
---------------

###intro_material

Examples of how work with BioNano software from the KSU Bioinformatics Core.

**FAQs -** Discussions or code that we are frequently asked about. Many of our tools are built out of smaller scripts that can also be used by themselves in the FAQ markdown we discuss things like generating an XMAP filtered by minimum percent alignment and what a CMAP is.

**Windows_in_silico_labeling.md -** How to install software on a Windows machine and videos of how to in silico label sequence data for alignment or to determine which enzymes to use for a BioNano project.

**code_examples.sh -** these are usage notes and general steps taken by the KSU Bioinformatics Core to assemble molecules or align assemblies. These can be  used as a template for your own experiments with your BioNano data in a Linux environment.

**IrysView_Troubleshooting.pdf -** instructions on how to view all labels in an alignment if they do not automatically load.

        
### map_editing 

**cmap_stats.pl -** Script outputs count of cmaps, cummulative lengths of cmaps and N50 of cmaps. Tested on CMAP File Version: 0.1.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/cmap_stats.pl -c sample_data/sample.cmap
```

**xmap_stats.pl -** Script outputs breadth of alignment coverage and total aligned length from an xmap. Tested on XMAP File Version: 0.1. "Breadth of alignment coverage" is the number of bases covered by aligned maps. This is equivalent to "Total Unique Aligned Len(Mb)". "Total alignment length is the total length of the alignment. This is equivalent to "Total Aligned Len(Mb)".

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/xmap_stats.pl -x sample_data/sample.xmap
```

**bnx_stats.pl - **Script outputs count of molecule maps in BNX files, cummulative lengths of molecule maps and N50 of molecule maps. Script also outputs a PDF with these metrics as well as histograms of molecule map quality metrics. Tested on BNX File Version 1.0 however it should work on Version 1.2. The user inputs a list of BNX files or a glob as the final arguments to script. Users can filter results by min molecule length in kb using the `-l` flag. Things to add include switching between QC and cleaning.
 
Script has no options other than help menus and min length currently but it was designed to be adapted into a molecule cleaning script similar to prinseq or fastx. Feel free to fork this and add your own filters.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/bnx_stats.pl -l 150 sample_data/Molecules*.bnx
```

**flip.pl -** This utility script reads from a list of maps to flip from a txt file (one CMAP id per line) and creates a CMAP with the requested flips.

### assemble_SGE_cluster/AssembleIrysCluster.pl 

SUMMARY

**AssembleIrysCluster.pl -** Adjusts stretch by scan. Merges BNXs and writes scripts for assemblies with a range of parameters. This script uses the same workflow as AssembleIrys.pl but it runs on the Beocat SGE cluster.

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
    
    perl AssembleIrys.pl -g [genome size in Mb] -r [reference CMAP] -b [directory with BNX files] -p [project name]
    
DEPENDENCIES


    Perl module XML::Simple. This can be installed using CPAN http://search.cpan.org/~grantm/XML-Simple-2.20/lib/XML/Simple.pm;
    Perl module Data::Dumper. This can be installed using CPAN http://search.cpan.org/~smueller/Data-Dumper-2.145/Dumper.pm;
    
    
### stitch/stitch.pl

**stitch.pl -**  a package of scripts that analyze IrysView output (i.e. XMAPs). The script filters XMAPs
       by confidence and the percent of the maximum potential length of the alignment and generates summary
       stats of the more stringent alignments. The first settings for confidence and the minimum percent of
       the full potential length of the alignment should be set to include the range that the researcher
       decides represent high quality alignments after viewing raw XMAPs. Some alignments have lower than
       optimal confidence scores because of low label density or short sequence-based scaffold length. The
       second set of filters should have a user-defined lower minimum confidence score, but a much higher
       percent of the maximum potential length of the alignment in order to capture these alignments.
       Resultant XMAPs should be examined in IrysView to see that the alignments agree with what the user
       would manually select.

stitch.pl finds the best super-scaffolding alignments each run. It can be run iteratively until all
       super-scaffolds have been found by creating a new cmap from the output super-scaffold fasta, aligning
       this cmap as the query with the BNG consensus map as the reference and using the x_map, r_cmap and
       the super-scaffold fasta as input for another run of stitch.pl. See [KSU_bioinfo_lab/stitch](https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch) for more details.

       
![Alt text](https://raw.github.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/scaffolding.png)


DEPENDENCIES

       git - see http://git-scm.com/book/ch1-4.html for instructions
       bioperl - see http://www.bioperl.org/wiki/Installing_BioPerl (the scripts will run without BioPerl it is only required only to create a super-scaffold FASTA)
       

USAGE

       perl analyze_irys_output.pl [options]

        Documentation options:
          -help    brief help message
          -man     full documentation
        Required options:
          -r        reference CMAP
          -x        comparison XMAP
          -f        scaffold FASTA
          -o        basename for the output files
        Filtering options:
          --f_con       first minimum confidence score
          --f_algn      first minimum % of possible alignment
          --s_con       second minimum confidence score
          --s_algn      second minimum % of possible alignment

**Test with sample datasets**
```
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90
```

### assembly_qc.pl 

**assembly_qc.pl -** a script that compiles assembly metrics for assemblies in all of the possible directories:'strict_t', 'default_t', 'relaxed_t', 'strict_t/strict_ml', 'strict_t/relaxed_ml', 'default_t/strict_ml', 'default_t/relaxed_ml', 'relaxed_t/strict_ml', and 'relaxed_t/relaxed_ml'. The assemblies are created using assemble_SGE_cluster/AssembleIrysCluster.pl from https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab. The parameter -b should be the same as the -b parameter used for the assembly script. It is the directory with the BNX files used for assembly.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assembly_qc.pl -b ~/sample_data -p My_project_ID
```

###sv_detect

These scripts were created to generate BED files of gaps in sequence-based assemblies and to run sv_detect from BioNano as a standalone pipeline but the scripts may be redundant now with the new IrysView release. If we find that they are they will be removed.

### CURRENTLY UNSUPPORTED PROGRAMS:

###assemble/AssembleIrys.pl

SUMMARY

**AssembleIrys.pl -** Adjusts stretch by scan. Merges BNXs and initiate assemblies with a range of parameters. This script uses the same workflow as AssembleIrysCluster.pl but it runs on local Linux machines. This script has not been updated to account for frequent changes in Bionano output format. See **AssembleIrysCluster.pl** for fequently updated scripts.

### analyze_irys_output/analyze_irys_output.pl

SUMMARY

**analyze_irys_output.pl - This script was replaced by stitch.pl**


