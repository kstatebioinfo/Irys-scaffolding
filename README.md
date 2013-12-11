Irys-scaffolding
================

scripts to parse IrysView output

KSU bioinfo
___________

**xmap_to_fasta.pl** - This script creates a non-redundant (i.e. no scaffold is used twice) super scaffold from a scaffold file (ordered so that the scaffold id is the numeric order in the fasta file starting with ">1") and the filtered xmap
Run number_fast.pl on your fasta file to create the correct fasta to pass as an arguement to this script. If two scaffolds overlap on the superscaffold than a 30 "n" gap is used as a spacer between them. If a scaffold has two high quality alignments the longest alignment is sellected. If both alignments are equally long the alignment with the highest confidence is sellected. 

USAGE: perl xmap_to_fasta.pl [scaff_xmap] [scaffold_fasta]
