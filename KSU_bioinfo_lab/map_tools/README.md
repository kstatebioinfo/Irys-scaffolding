### map_tools 

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

**CmapById.pl** - Script outputs new CMAP with only maps with user specified IDs. Tested on CMAP File Version: 0.1. Call with "-help" flag for detailed instructions.

```
perl  ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/CmapById.pl -c sample_data/sample.cmap -i 1,3,6 -o sample_data/sample_out_file

perl  ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/CmapById.pl -c sample_data/sample.cmap -i 3..10 -o sample_data/sample_out_3_10

perl  ~/Irys-scaffolding/KSU_bioinfo_lab/map_tools/CmapById.pl -c sample_data/sample.cmap -i 2 -o sample_data/sample_out_cmap_2
```

**flip.pl -** This utility script reads from a list of maps to flip from a txt file (one CMAP id per line) and creates a CMAP with the requested flips.
