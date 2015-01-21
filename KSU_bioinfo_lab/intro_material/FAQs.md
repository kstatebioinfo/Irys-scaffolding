Irys-scaffolding FAQs
=====================

###How can I filter an XMAP by the percent of possible alignment to the observed alignment length?

This can be done with a script that `stitch.pl` uses called `xmap_filter.pl`. You can find out more about this filter by reading the `README.md` in https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/tree/master/KSU_bioinfo_lab/stitch. 

The basic steps would be...

```
perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/make_key.pl <fasta> <output_basename>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl <fasta>

perl ~/Irys-scaffolding/KSU_bioinfo_lab/stitch/number_fasta.pl xmap_filter.pl <r.cmap> <numbered fasta> <xmap> <output_basename> [min confidence] [min % aligned] [second min confidence] [second min % aligned] <fasta_key_file>
```

If your starting FASTA file was called `sample_dir/sample.fasta` then your numbered FASTA file will be called `sample_dir/sample_numbered_scaffold.fasta`. If your output_basename was `sample_dir/sample_out` your fasta_key_file will be `sample_dir/sample_out_key`.






