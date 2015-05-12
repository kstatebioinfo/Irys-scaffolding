##Sewing Machine pipeline: iteratively super scaffold genome FASTA files with BioNano genome maps using `stitch.pl`

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/pipelines_for_bionano_data_wide.png" align="left" width="348" ></a>

All of the scripts you will need to complete this lab as well as the sample datasets will be copied to your computer as you follow the instructions below. You should type or paste the text in the beige code block into your terminal as you follow along with the instructions below. If you are not used to commandline, practice with real data is one of the best ways to learn.

If you would like a quick primer on basic linux commands try these 10 minute lessons from Software Carpentry http://software-carpentry.org/v4/shell/index.html. 

We will be using a CMAP file of genome maps assembled from single molecule maps. The molecule maps were genrated from Escherichia coli genomic DNA. We will also be using a CMAP file of in silico maps and a FASTA file (both of which represent a fragmented copy of the Escherichia coli str. K-12 substr. DH10B genome).

The sewing machine pipeline will align the genome maps and the in silico maps using both a default and relaxed set of alignment parameters. These alignments will be used by `stitch.pl` to superscaffold the fragmented E. coli str. K-12 substr. DH10B genome.

![Alt text](https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/stitch/Fig_3_detailed_stitch_steps.png)
**Steps of the stitch.pl algorithm.** Consensus genome maps (blue) are shown aligned to in silico maps (green). Alignments are indicated with grey lines. CMAP orientation for in silico maps is indicated with a ”+” or ”-” for positive or negative orientation respectively. (A) The in silico maps are used as the reference. (B) The alignment is inverted and used as input for stitch.pl. (C) The alignments are filtered based on alignment length (purple) relative to total possible alignment length (black) and confidence. Here assuming all alignments have high confidence scores and the minimum percent aligned is 40% two alignments fail for aligning over less than 40% of the potential alignment length for that alignment. (D) Filtering produces an XMAP of high quality alignments with short (local) alignments removed. (E) High quality scaffolding alignments are filtered for longest and highest confidence alignment for each in silico map. The third alignment (unshaded) is filtered because the second alignment is the longest alignment for in silico map 2. (F) Passing alignments are used to super scaffold (captured gaps indicated in dark green). (G) Stitch is iterated and additional super scaffolding alignments are found using second best scaffolding alignments. (H) Iteration takes advantage of cases where in silico maps scaffold consensus genome maps as in silico map 2 does. Stitch is run iteratively until all super scaffolding alignments are found.

Before inferring super scaffolds from XMAP alignment files, `stitch.pl` filters low quality alignments by confidence score.

Super scaffolds are built from overlapping alignments. Overlapping alignments are similar to global alignments, i.e., alignments spanning from end to end for two maps of roughly equal length, but to search for overlap alignment gaps after the ends of either map are not penalized. The genome map aligner we will be using, RefAligner, has a scoring scheme that does not currently have a parameter to favor overlapping alignments, e.g., to initialize the dynamic programming matrix with no penalties and take the maximum score of the final row or column in the matrix. RefAligner reports local alignments between two maps and applies a fixed penalty based on the user-defined likelihood of unaligned labels at the ends of the alignment. Raising or lowering this penalty selects for local or global alignments, respectively, but neither option favors overlapping alignments specifically. `stitch.pl` filters by the percent of the total possible alignment length that is aligned (see figure above). To approximate scoring that favors overlapping alignments, `stitch.pl` uses thresholds for minimum percent of total possible aligned length, the percent aligned threshold (PAT).

Similar to scoring structures that favor overlapping alignments, PAT filters out local alignments. However, unlike a scoring structure, PAT is applied after alignment and therefore cannot result in the aligner exploring possible extensions into an overlap but instead favors a shorter local alignment with a higher cumulative score. Therefore Stitch accepts alignments with less than 100% PAT.
In practice we used two sets of alignment filters and kept alignments that passed one or both sets. The first set had a low PAT (by default 40%) and a high confidence score threshold (by default 20). The second set had a higher PAT (by default 90%) and a lower confidence score (by default 15) and was intended to identify longer overlaps especially in regions of the genome where label density is low.

After filtering, scaffolding alignments are selected from the remaining high quality alignments (i.e., more than one in silico map aligns to the same consensus genome map). For each in silico map with more than one high quality, scaffolding alignment the longest alignment for the in silico map is selected. If alignment length is identical then the highest confidence alignment is selected. If confidence scores are identical then an alignment is chosen arbitrarily.

Gap lengths between in silico maps are inferred from scaffolding alignments and used to create new super scaffolds in a new genome FASTA file and associated AGP file. If gap lengths are estimated to be negative, `stitch.pl` adds a 100 bp spacer gap to the sequence file and indicates that the gap is type ”U” for unknown in the AGP. These negative gap lengths may indicated that local reassembly may be required to join the two original sequence scaffolds. For extremely small negative gap lengths, `stitch.pl` (version 1.4.5+) allows the user to set a minimum negative gap length filter for alignments (by default 20 kb). In the event that two in silico maps have a negative gap length smaller than this value, which is equivalent to a longer overlap of the sequence scaffolds, `stitch.pl` will automatically exclude both in silico maps from consideration when super scaffolding.

`stitch.pl` only makes use of one alignment per in silico map each iteration. The sewing machine pipeline runs `stitch.pl` iteratively such that each successive output FASTA file is converted into in silico maps and aligned to the original consensus genome maps. This alignment is used as input for the next iteration until no new super scaffolds are created. Iterations of `stitch.pl` make use of any in silico maps that join growing super scaffolds, effectively using both sequence data and genome maps to stitch together the final super scaffolds.

As you work through this lab your should read about the software are using by generating and reading the help menus. 

Try the `-man` flag instead of the `-help` flag for a more detailed description of the program (you type `q` to exit from a manual screen).

###Step 1: Clone the Git repositories 

The following workflow requires that you install BioNano scripts and executables in `~/scripts` and `~/tools` directories respectively. Follow the Linux installation instructions in the "2.5.1 IrysSolve server RefAligner and Assembler" section of http://www.bnxinstall.com/training/docs/IrysViewSoftwareInstallationGuide.pdf.

Test that `RefAligner` is installed correctly by generating a help menu:

```
~/tools/RefAligner -help
```

When this is done install the KSU custom software using the code below:

```
cd ~
git clone https://github.com/i5K-KINBRE-script-share/Irys-scaffolding.git
git clone https://github.com/i5K-KINBRE-script-share/BNGCompare.git
```


###Step 2: Compare your assembled genome maps to your reference in silico maps with sewing machine

Read about the software in this section:

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/sewing_machine.pl -help
```

`sewing_machine.pl` is a script that compiles assembly metrics and runs Stitch for the assembled genome maps.

Stitch filters alignment XMAP files by confidence and the percent of the maximum potential length of the alignment. The first settings for confidence and the minimum percent of the full potential length of the alignment should be set to include the range that the researcher decides represent high quality alignments after viewing raw XMAPs. Some alignments have lower than optimal confidence scores because of low label density or short sequence-based scaffold length. The second set of filters should have a user-defined lower minimum confidence score, but a much higher percent of the maximum potential length of the alignment in order to capture these alignments. Resultant filtered XMAPs should be examined in IrysView to see that the alignments agree with what the user would manually select. Stitch finds the best super-scaffolding alignments each run. It is run iteratively by `sewing_machine.pl` until all super-scaffolds have been found.

We will start with the default filtering parameters for confidence scores (`--f_con` and `--s_con`) and percent of possible alignment thresholds (`--f_algn` and `--s_algn`). Generally we start with default parameters and then test more or less strict options if our first results are not satisfactory.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/sewing_machine.pl -o ~/test-sewing-machine-out -g ~/dev/Irys-scaffolding/KSU_bioinfo_lab/sample_output_directory/BioNano_consensus_cmap/ESCH_COLI_1_2015_000_STRICT_T_150_REFINEFINAL1.cmap -p Esch_coli_1_2015_000 -e BspQI -f ~/Irys-scaffolding/KSU_bioinfo_lab/sample_assembly_working_directory/fasta_and_cmap/NC_010473_mock_scaffolds.fna -r ~/Irys-scaffolding/KSU_bioinfo_lab/sample_output_directory/in_silico_cmap/NC_010473_mock_scaffolds_BspQI.cmap
```

#####Note: If you need to create a new CMAP file of in silico maps from a genome FASTA for your `-r` reference argument you can run the following command to create in silico maps.

Use whichever enzyme was used to label the genomic DNA when creating the single molecule maps on the Irys system for the `-e` parameter. Possible enzymes are `BspQI BbvCI BsmI BsrDI` and `bseCI`. Below is an example of a command to create an in silico map CMAP.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/third-party/fa2cmap_multi.pl -v -i ~/sample_assembly_working_directory/fasta_and_cmap/NC_010473_mock_scaffolds.fna -e BspQI
```

If dual nicking (e.g. with BspQI and BbvCI) was done use a space separated list of enzymes. Below is an example of a command to create an in silico map CMAP using two enzymes.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/third-party/fa2cmap_multi.pl -v -i ~/sample_assembly_working_directory/fasta_and_cmap/NC_010473_mock_scaffolds.fna -e BspQI BbvCI
```

###Step 3: Choose your best alignment parameters and explore your results

Read about the software in this section:

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/write_report.pl -help
```

Open the `~/test-sewing-machine-out/NC_010473_mock_scaffolds_BNGCompare.csv` file to find the best alignment parameters. Like choosing the best assembly you want to find a result that balances sensitivity (i.e. long total aligned length) without increasing alignment redundancy excessively.

###Step 4: Explore your results in IrysView

Read your `~/sample_assembly_working_directory/report.txt` file or explore files in your `~/sample_assembly_working_directory/Esch_coli_1_2015_000` output directory. The contents of the `~/sample_assembly_working_directory/Esch_coli_1_2015_000` directory are also compressed in the `~/sample_assembly_working_directory/Esch_coli_1_2015_000.tar.gz` file. Move this to a windows machine and follow instructions in the https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/README.pdf file to view alignments in IrysView.

Following the instructions for loading an XMAP, first import the XMAP file of the alignment of the original in silico maps to the assembled genome maps. This will be in the `Esch_coli_1_2015_000/align_in_silico_xmap` directory.

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/images/result_pre_scaffolding.png" align="center" width="750" ></a>

Above is a screen shot of the first alignment (after ordering the anchors "in silico map #2", "in silico map #3", "in silico map #4", "in silico map #1").

Next import the XMAP file of the alignment of the super scaffolded in silico map to the assembled genome maps. This will be in the `Esch_coli_1_2015_000/align_in_silico_super_scaffold_xmap` directory.

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/images/result_post_scaffolding.png" align="center" width="830" ></a>

Above is a screen shot of the second alignment (of the super scaffolded in silico map aligned to the genome maps).

Next load the BED file of the contigs for the super scaffolded in silico maps. This will be `Esch_coli_1_2015_000/super_scaffold/Esch_coli_1_2015_000_20_40_15_90_2_superscaffold.fasta_contig.bed`. There is also a BED file of the gaps for the super scaffolded in silico maps but the gaps for this sample genome are very small and therefore more difficult to view in the alignment `Esch_coli_1_2015_000/super_scaffold/Esch_coli_1_2015_000_20_40_15_90_2_superscaffold.fasta_contig_gaps.bed`. 

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/images/add_bed_file.png" align="center" width="830" ></a>
Above is a screen shot of the menus that you will need to follow to begin to load the BED file.

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/images/locate_bed_file.png" align="center" width="830" ></a>
Above is a screen shot of the menus that you will need to follow to find the contig BED file for the super scaffolded in silico map.

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/images/result_post_scaffolding_with_bed.png" align="center" width="830" ></a>
Above is a screen shot of the second alignment with the contig BED file loaded.

