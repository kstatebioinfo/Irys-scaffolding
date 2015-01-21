Irys-scaffolding FAQs
=====================

###How can I filter an XMAP by the percent of possible alignment to the observed alignment length?

This can be done with a script that `stitch.pl` uses called `xmap_filter.pl`. You can find out more about this filter by reading the `README.md` in https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch. Because of the algorithm will need to know the length of both CMAPS in an alignment to calculate the CMAP's footprint (part of determining the potential aligned length) you need to run a couple steps before and after `xmap_filter.pl`. You will also be flipping the xmap and then reverting it using the code below.

The basic steps would be...

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl <original_xmap> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_key.pl <fasta> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl <fasta>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl xmap_filter.pl <q.cmap> <numbered fasta> <output_basename.flip> <output_basename> <min confidence> <min % aligned> <second min confidence> <second min % aligned> <fasta_key_file>

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

You can find the observed bpp by aligning molecule maps to your ref and finding the last non-zero bpp value listed in the `.err` file. Then use a slightly different RefAligner command to adjust stretch. Instuctions below use RefAligner contact sheltonj@ksu.edu for a link the software.

```
# Merge your BNX files

~/tools/RefAligner -if sample_dir/bnx_list.txt -o sample_dir/bnx_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads 16

# Subsample alignments with five iterations (T should be about inverse of the genome size)

~/tools/RefAligner -i sample_dir/bnx_merged.bnx -o sample_dir/sample_in_silico_to_bnx_merged -T $T -ref sample_dir/sample_in_silico.cmap -bnx -nosplit 2 -BestRef 1 -M 5 -biaswt 0 -Mfast 0 -FP 1.5 -FN 0.15 -sf 0.2 -sd 0.2 -A 5 -res 3.5 -resSD 0.7 -outlier 1e-4 -endoutlier 1e-4 -minlen 100 -minsites 5 -maxthreads 16 -randomize 1 -subset 1 10000

# Get the empirical bpp (`$bpp`) from `sample_dir/sample_in_silico_to_bnx_merged.err` and use RefAligner to adjust stretch.

~/tools/RefAligner -f -i sample_dir/bnx_merged.bnx -merge -bnx -bpp $bpp -o $sample_dir/bnx_merged_adj -maxthreads 16`;
```

###Are the scripts you are using for a customer's assembly the ones in your github account (Irys scaffolding). If so, should we also try to run it on our server? 

For small to medium genomes (generally this means genomes < 1 Gb) we assemble using AssembleIrysCluster.pl. AssembleIrysCluster.pl and the version we used will be described in your report if we used it on your data. For large genomes (or datasets that are taking too long to run on our cluster) we assemble using the Irys Solve Cloud (although we will have an update about this topic soon).

AssembleIrysCluster.pl was developed to run on our cluster and would probably not be easy to use on a different cluster. We will be rewritting this over the next few weeks but I am not sure yet whether the new pipeline will be easier to use elsewhere or not.

All of our other tools (stitch.pl, cmap_stats.pl, xmap_stats.pl, bnx_stats.pl, etc.) were designed to be portable.
