Irys-scaffolding FAQs
=====================

###How can I take a single map contig from the BNG consensus map, convert it into a cmap and then map it against a the in silico map of a single scaffold? 

So both an in silico and a BioNano CMAP file are tab delimited files. Any line that does not start with a `#` (a comment line) will begin with a CMAP ID as the first field. You can use `CmapById.pl` to grab any individual map using one or more CMAP IDs. Read more about CmapById.pl here: https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/map_tools

Below is an example of the first 12 lines of a CMAP file:

```
# CMAP File Version:	0.1
# Label Channels:	1
# Nickase Recognition Site 1:	cctcagc
# Nickase Recognition Site 2:	gctcttc
# Enzyme1:	Nt.BbvCI
# Enzyme2:	Nt.BspQI
# Number of Consensus Nanomaps:	223
#h CMapId	ContigLength	NumSites	SiteID	LabelChannel	Position	StdDev	Coverage	Occurrence
#f int	float	int	int	int	float	float	int	int
1	255324.0	28	1	1	13448.0	1.0	1	1
1	255324.0	28	2	1	13774.0	1.0	1	1
1	255324.0	28	3	1	20282.0	1.0	1	1
```

###Do you usually explore different sets of nicking enzymes in silico if you have the sequence fasta file before you attempt a map of a new organism you haven't done before?

We generally estimate "label density" from contigs so that gaps don't artificially reduce the estimate. Here is our break down of how to do that: https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/intro_material/Windows_in_silico_labeling.md.


###How can I filter an XMAP by the percent of possible alignment to the observed alignment length?

This can be done with a script that `stitch.pl` uses called `xmap_filter.pl`. You can find out more about this filter by reading the `README.md` in https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch. Because of the algorithm will need to know the length of both CMAPS in an alignment to calculate the CMAP's footprint (part of determining the potential aligned length) you need to run a couple steps before and after `xmap_filter.pl`. You will also be flipping the xmap and then reverting it using the code below.

The basic steps would be...

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl <original_xmap> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_key.pl <fasta> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl <fasta>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/xmap_filter.pl <q.cmap> <numbered fasta> <output_basename.flip> <output_basename> <min confidence> <min % aligned> <second min confidence> <second min % aligned> <fasta_key_file>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/get_passing_xmap.pl -f <filtered_fliped_xmap> -o <original_xmap>
```

If your starting FASTA file was called `sample_dir/sample.fasta` then your numbered FASTA file will be called `sample_dir/sample_numbered_scaffold.fasta`. If your output_basename was `sample_dir/sample_out` your fasta_key_file will be `sample_dir/sample_out_key`.

###If I should always use RefAligner with the in silico genome maps as the reference how can I invert an XMAP for my analysis? 

Currently I have not heard of a method for inverting the alignment cigar string. However inverting the rest of the XMAP is fairly straight forward. So I invert the rest of the XMAP and ignore the cigar string. I give the file the extension `.flip` so that I do not confuse it for a complete XMAP. When I have filtered my XMAP I find the original XMAP entries for passing alignments in the original file. The method for flipping and reverting alignments is shown below...

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl <original_xmap> <output_basename>

# Do your analysis (ignoring the cigar!!)

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/get_passing_xmap.pl -f <filtered_fliped_xmap> -o <original_xmap>
```

###The first column in the Bionano assembled genome map (a CMAP file) is named CMapID; does this correspond to the QryContigID column in the XMAP comparison file?

Yes it does infact the query should always be an assembled BioNano genome map rather than the in silico genome map created from your sequence assembly (also a CMAP). This number is also the number displayed in IrysView.

###Is the BioNano assembled genome map (CMAP) in any particular order? 

No, the CMAP is printed in the order individual genome maps are reported by the assembler. This is basically random order. A BioNano genome map CMAP is a consensus map (in the same way that a sequence based contig can be a consensus of the sequence from many reads). The CMAP is inferred by the assembler from overlapping molecule maps. The BioNano assembler is basically an overlap layout consensus assembler.

###Comparing the size distribution of these 'fragments' with the ones from the in silico genome map, we noticed a difference (map fragments on average smaller than in silico fragments). Does that matter somehow?

Yes and it can be corrected using RefAligner. Stretch or bpp is 500 bases per pixel under ideal conditions. Where possible we adjust stretch based on alignment of you molecule maps (BNX files) to an in silico genome map (CMAP) because observed bpp is generally not 500. This sounds like what you are describing.

You can find the observed bpp by aligning molecule maps to your ref and finding the last non-zero bpp value listed in the `.err` file. Then use a slightly different RefAligner command to adjust stretch. Instuctions below use RefAligner contact sheltonj@ksu.edu for a link the software. (Note: you may need to adjust the last four parameter in the last three steps below depending on how many threads and how much memory your machine has available.)

```
# Merge your BNX files

~/tools/RefAligner -if sample_dir/bnx_list.txt -o sample_dir/bnx_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads 16

# Subsample 50,000 molecules and run alignment with very loose alignment parameters (T should be about inverse of the genome size).

~/tools/RefAligner -o sample_dir/bnx_merged_errA -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -minlen 180 -minsites 9 -refine 0 -id 1 -mres 0.9 -res 3.4 -resSD 0.75 -FP 1.0 -FN 0.1 -sf 0.2 -sd 0 -sr 0.02 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 50000 -BestRef 1 -BestRefPV 1 -hashoffset 1 -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16 -maxthreads 64

# The error metrics returned are refined in the following step using 100000 molecules and more stringent alignments.

~/tools/RefAligner -o sample_dir/bnx_merged_errB -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -readparameters sample_dir/bnx_merged_errA_id1.errbin -minlen 180 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -999 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -randomize -subset 1 100000 -BestRef 1 -BestRefPV 1 -hashoffset 1  -AlignRes 1.5 -resEstimate -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64

# Finally the original BNX set is rescaled per the noise parameters from the second step. In this step, after noise parameters have be estimated using long molecules the minimum molecule length is set back to 100 kb.

~/tools/RefAligner -o sample_dir/bnx_merged_adj -i sample_dir/bnx_merged.bnx -ref sample_dir/sample_in_silico.cmap -readparameters sample_dir/bnx_merged_errB_id1.errbin -minlen 100 -minsites 9 -refine 0 -id 1 -resbias 4.0 64 -outlier 1e-4 -endoutlier 1e-4 -S -9 -T 1e-4 -MapRate 0.7 -A 5 -nosplit 2 -biaswt 0 -deltaX 4 -deltaY 6 -extend 1 -PVres 2 -f -BestRef 1 -BestRefPV 1 -maptype 1 -hashoffset 1 -AligneRes 1.5  -resEstimate -ScanScaling 2 -M 5 -hashgen 5 3 2.4 1.5 0.05 5.0 1 1 2 -hash -hashdelta 10 -maxmem 240 -hashmaxmem 120 -insertThreads 16  -maxthreads 64

```

###Are the scripts you are using for a customer's assembly the ones in your github account (Irys scaffolding). If so, should we also try to run it on our server? 

For small to medium genomes (generally this means genomes < 1 Gb) we assemble using AssembleIrysCluster.pl. AssembleIrysCluster.pl and the version we used will be described in your report if we used it on your data. For large genomes (or datasets that are taking too long to run on our cluster) we assemble using the Irys Solve Cloud (although we will have an update about this topic soon).

AssembleIrysCluster.pl was developed to run on our cluster and would probably not be easy to use on a different cluster. We will be rewritting this over the next few weeks but I am not sure yet whether the new pipeline will be easier to use elsewhere or not.

All of our other tools (stitch.pl, cmap_stats.pl, xmap_stats.pl, bnx_stats.pl, etc.) were designed to be portable.

###How can I recover a new genome FASTA file from the BioNano hybridScaffold pipeline FASTA file (my HYBRID_SCAFFOLD.fasta)?

The hybridScaffold_finish_fasta.pl script creates new FASTA files including new hybrid sequences output by hybridScaffold and all sequences that were not used by hybridScaffold with their original headers. Also outputs a text file list of the headers for sequences that were used to make the new hybrid sequences.

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/hybridScaffold_finish_fasta.pl -x HYBRID_SCAFFOLD.xmap -s HYBRID_SCAFFOLD.fasta -f original.fasta
```

