SCRIPT (WARNING STRIPT IS CURRENTLY INCOMPLETE. THIS WARNING WILL BE REMOVED WJEN THE SCRIPT IS FINISHED)

**stitch.pl -**
       a package of scripts that analyze IrysView
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
       user would manually select. 

![Alt text](https://raw.github.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/scaffolding.png)


DEPENDENCIES

       git - see http://git-scm.com/book/ch1-4.html for instructions
       bioperl - see http://www.bioperl.org/wiki/Installing_BioPerl 
       

USAGE

       perl analyze_irys_output.pl [options]

        Documentation options:
          -help    brief help message
          -man     full documentation
        Required options:
          -r        reference CMAP
          -x        comparison XMAP
          -f        scaffold FASTA
          -o        base name for the output files
        Filtering options:
          --f_con       first minimum confidence score
          --f_algn      first minimum % of possible alignment
          --s_con       second minimum confidence score
          --s_algn      second minimum % of possible alignment
OPTIONS

       -help   Print a brief help message and exits.

       -man    Prints the more detailed manual page with output details and
               examples and exits.

       -r, --r_cmap
               The reference CMAP produced by IrysView when you create an
               XMAP. It can be found in the "Imports" folder within a
               workspace.

       -x, --xmap
               The XMAP produced by IrysView. It can also be found in the
               "Imports" folder within a workspace.

       -f, --fasta
               The FASTA that will be super-scaffolded based on alignment to
               the IrysView assembly. It is preferable to use the scaffold
               FASTA rather than the contigs. Many contigs will not be long
               enough to align.

       -o, --output_basename
               This is the basename for all output files. Output file include
               an XMAP with only high quality alignments of molecule maps that
               scaffold contigs, an XMAP of all high quality alignments, a csv
               file with summary metrics, and a non-redundant (i.e. no
               scaffold is used twice) super-scaffold from a user-provided
               scaffold file and a filtered XMAP.

       --f_con, --fc
               The minimum confidence score for alignments for the first round
               of filtering. This should be the most stringent, highest, of
               the two scores.

       --f_algn, --fa
               The minimum percent of the full potential length of the
               alignment allowed for the first round of filtering. This should
               be lower than the setting for the second round of filtering.

       --s_con, --sc
               The minimum confidence score for alignments for the second
               round of filtering. This should be the less stringent, lowest,
               of the two scores.

       --f_algn, --sa
               The minimum percent of the full potential length of the
               alignment allowed for the second round of filtering. This
               should be higher than the setting for the first round of
               filtering.

DESCRIPTION

       OUTPUT DETAILS:

       The script outputs an XMAP with only molecule maps that scaffold in 
       silico maps and an XMAP of all high quality alignments. Both XMAPs can 
       be imported and viewed in the IrysView "comparisons" window if the 
       original r.cmap and q.cmap are in the same folder when you import.

       The script also lists summary metrics in a csv file.

       In the same csv file, in silico maps that have alignments passing the user-
       defined length and confidence thresholds that align over less than 60%
       of the total length possible are listed. These may represent mis-
       assembled scaffolds.

       In the same csv file, high quality but overlaping alignments in a csv
       file are listed. These may be candidates for further assembly using the
       overlaping contigs and paired end reads.

       The script also creates a non-redundant (i.e. no in silico map is used
       twice) super-scaffold from a user-provided fasta file and a filtered       
       XMAP. If two in silico maps overlap on the superscaffold then a 30 "n" gap
       is used as a spacer between them. If adjacent in silico map do not overlap
       on the super-scaffold than the distance between the begining and end of
       each in silico map is reported in the XMAP is used as the gap length. If 
       a scaffold has two high quality alignments the longest alignment is
       selected. If both alignments are equally long the alignment with the
       highest confidence is selected. 
       
       No in silico map's sequence is added to the final fasta twice; however, 
       if the first and second best alignment for an in silico map align to the 
       ends of two molecule maps that each super-scaffold > 1 in silico map than 
       these alignments are all used to "stitch" together the final super-scaffold.


**Test with sample datasets**
```
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding

cd Irys-scaffolding/KSU_bioinfo_lab/stitch

mkdir results

perl stitch.pl -r sample_data/sample.r.cmap -x sample_data/sample.xmap -f sample_data/sample_scaffold.fasta -o results/test_output --f_con 15 --f_algn 30 --s_con 6 --s_algn 90
```
