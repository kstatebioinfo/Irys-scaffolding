Irys-scaffolding FAQs
=====================

###How can I filter an XMAP by the percent of possible alignment to the observed alignment length?

This can be done with a script that `stitch.pl` uses called `xmap_filter.pl`. You can find out more about this filter by reading the `README.md` in https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch. Because of the algorithm will need to know the length of both CMAPS in an alignment to calculate the CMAP's footprint (part of determining the potential aligned length) you need to run a couple steps before and after `xmap_filter.pl`. You will also be flipping the xmap and then reverting it using the code below.

The basic steps would be...

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl <original_xmap> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_key.pl <fasta> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl <fasta>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl xmap_filter.pl <q.cmap> <numbered fasta> <output_basename.flip> <output_basename> [min confidence] [min % aligned] [second min confidence] [second min % aligned] <fasta_key_file>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/get_passing_xmap.pl -f <filtered_fliped_xmap> -o <original_xmap>
```

If your starting FASTA file was called `sample_dir/sample.fasta` then your numbered FASTA file will be called `sample_dir/sample_numbered_scaffold.fasta`. If your output_basename was `sample_dir/sample_out` your fasta_key_file will be `sample_dir/sample_out_key`.




