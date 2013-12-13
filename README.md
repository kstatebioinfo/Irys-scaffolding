Irys-scaffolding
================

scripts to parse IrysView output

KSU bioinfo lab
---------------

**number_fasta.pl**	- This script converts headers to autoincremented numbers

USAGE: perl number_fasta.pl [fasta] 

**xmap_to_fasta.pl** - This script creates a non-redundant (i.e. no scaffold is used twice) super scaffold from a scaffold file (ordered so that the scaffold id is the numeric order in the fasta file starting with ">1") and the filtered xmap
Run number_fast.pl on your fasta file to create the correct fasta to pass as an arguement to this script. If two scaffolds overlap on the superscaffold than a 30 "n" gap is used as a spacer between them. If a scaffold has two high quality alignments the longest alignment is sellected. If both alignments are equally long the alignment with the highest confidence is selected. 

USAGE: perl xmap_to_fasta.pl [scaff_xmap] [scaffold_fasta]

**analyze_irys_output/analyze_irys_output.pl** - a package of scripts that analyze IrysView output (i.e. XMAPs). The script filters XMAPs by confidence and the percent of the maximum potential length of the alignment and generates summary stats of the more stringent alignements. The first settings for confidence and the percent of the maximum potential length of the alignment should be set to include the range that the researcher decides represent high quality alignments after viewing raw XMAPs. Some alignments have lower than optimal confidence scores because of low label density or short sequence-based scaffold length. The second set of filters should have a user-defined lower minimum confidence score, but a much higher percent of the maximum potential length of the alignment in order to capture these alignments. Resultant XMAPs should be examined in IrysView to see that the alignments agree with what the user would manually select.

USAGE: perl analyze_irys_output.pl [r.cmap] [q.cmap] [xmap] [scaffold.fasta] [output_basename] [first min confidence] [first min % aligned] [second min confidence] [second min % aligned]

**OUTPUT DETAILS:**

The script outputs an XMAP with only molecules that scaffold contigs and an XMAP of all high quality alignments. Both XMAPs can be imported and viewed in the IrysView "comparisons" window if the original r.cmap and q.cmap are in the same folder when you import.

The script also lists summary metrics in a csv file.

In the same csv file, scaffolds that have alignments passing the user-defined length and confidence thresholds that align over less than 60% of the total length possible are listed. These may represent mis-assembled scaffolds.

In the same csv file, high quality but overlaping alignments in a csv file are listed. These may be candidates for further assembly using the overlaping contigs and paired end reads.

The script also creates a non-redundant (i.e. no scaffold is used twice) super-scaffold from a user-provided scaffold file and a filtered XMAP. If two scaffolds overlap on the superscaffold then a 30 "n" gap is used as a spacer between them. If adjacent scaffolds do not overlap on the super-scaffold than the distance between the begining and end of each scaffold reported in the XMAP is used as the gap length. If a scaffold has two high quality alignments the longest alignment is selected. If both alignments are equally long the alignment with the highest confidence is selected. 

`git clone https://github.com/kstatebioinfo/Irys-scaffolding`

`cd Irys-scaffolding/KSU_bioinfo_lab/analyze_irys_output/`

`mkdir results`

`perl analyze_irys_output.pl sample_data/sample.r.cmap sample_data/sample_q.cmap sample_data/sample.xmap sample_data/sample_scaffold.fasta results/test_output 15 .3 6 .9`

