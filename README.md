Irys-scaffolding
================

scripts to parse IrysView output

KSU_bioinfo_lab
---------------
### map_editing/flip.pl 

**flip.pl -** This utility script reads from a list of maps to flip from a txt file (one CMmap id per line) and creates a CMap with the requested flips.

### assemble_SGE_cluster/AssembleIrysCluster.pl 

SUMMARY

**AssembleIrysCluster.pl -** Adjusts stretch by scan. Merges BNXs and initiate assemblies with a range of parameters. This script uses the same workflow as AssembleIrys.pl but it runs on the Beocat SGE cluster.

###assemble/AssembleIrys.pl

SUMMARY

**AssembleIrys.pl -** Adjusts stretch by scan. Merges BNXs and initiate assemblies with a range of parameters.

Workflow diagram
![Alt text](https://raw.github.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble/bionano%20assembly%20workflow.png)

1) The Irys produces tiff files that are converted into BNX text files.
2) Each chip produces one BNX file for each of two flowcells.
3) BNX files are split by scan and aligned to the sequence reference. Stretch (bases per pixel) is recalculated from the alignment.
4) Quality metrics are reported in a CSV file for each adjusted flowcell BNX.
5) Adjusted flowcell BNXs are merged and aligned to the reference with and without “-BestRef”. If alignment quality changes dramatically your p-value threshold may be lax.
6) The first assemblies are run with a variety of p-value thresholds.
7) The best of the first assemblies (red oval) is chosen and a version of this assembly is produced with a variety of minimum molecule length filters.
    
USAGE
    
    perl AssembleIrys.pl -g [genome size in Mb] -r [reference CMAP] -b [directory with BNX files] -p [project name]
    
DEPENDENCIES

    Perl module Statistics::LineFit. This can be installed using CPAN http://search.cpan.org/dist/Statistics-LineFit/lib/Statistics/LineFit.pm.
    Perl module XML::Simple. This can be installed using CPAN http://search.cpan.org/~grantm/XML-Simple-2.20/lib/XML/Simple.pm;
    Perl module Data::Dumper. This can be installed using CPAN http://search.cpan.org/~smueller/Data-Dumper-2.145/Dumper.pm;
    
### stitch/stitch.pl

**stitch.pl -** This script will replace analyze_irys_output.pl. The major 
       difference is that though no in silico map's sequence is added to the final 
       fasta twice, if the first and second best alignment for an in silico map align 
       to the ends of two molecule maps that each super-scaffold > 1 in silico map than 
       these alignments are all used to "stitch" together the final super-scaffold. See 
       README.md for more details: https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch


**Test with sample datasets**
```
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90
```

### analyze_irys_output/analyze_irys_output.pl

SUMMARY

**analyze_irys_output.pl -** a package of scripts that analyze IrysView
       output (i.e. XMAPs). The script filters XMAPs by confidence and the
       percent of the maximum potential length of the alignment and generates
       summary stats of the more stringent alignments. The first settings for
       confidence and the minimum percent of the full potential length of the
       alignment should be set to include the range that the researcher
       decides represent high quality alignments after viewing raw XMAPs. Some
       alignments have lower than optimal confidence scores because of low
       label density or short sequence-based scaffold length. The second set
       of filters should have a user-defined lower minimum confidence score,
       but a much higher percent of the maximum potential length of the
       alignment in order to capture these alignments. Resultant XMAPs should
       be examined in IrysView to see that the alignments agree with what the
       user would manually select. See README.md for more details:          https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/analyze_irys_output.
       
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
          -q        query CMAP
          -x        comparison XMAP
          -f        scaffold FASTA
          -o        base name for the output files
        Filtering options:
          --f_con       first minimum confidence score
          --f_algn      first minimum % of possible alignment
          --s_con       second minimum confidence score
          --s_algn      second minimum % of possible alignment

**Test with sample datasets**
```
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/analyze_irys_output

mkdir results

perl analyze_irys_output.pl -r sample_data/sample.r.cmap -q sample_data/sample_q.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90
```


