#Pipelines for BioNano data

<a href="url"><img src="https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/pipelines_for_bionano_data_wide.png" align="left" width="348" ></a>

The K-INBRE Bioinformatics Core has created easy to use pipelines for BioNano molecule maps or pre-assembled BioNano genome maps for several common assembly and/or alignment experiments.

All pipelines have sample datasets and tutorials. Pipelines take you from either raw data received from your mapping facility or assembled genome maps to finished analysis. 

No experience with command line is necessary before using these scripts.

##"Raw data-to-finished assembly and assembly analysis" pipeline for BioNano molecule maps with a sequence-based genome FASTA

The assemble XeonPhi pipeline preps raw molecule maps and writes and runs a series of assemblies for them. Then the user selects the best assembly and uses this to super scaffold the reference FASTA genome file and summarize the final assembly metrics and alignments.

The basic steps are to first merge multiple BNXs from a single directory and plot single molecule map quality metrics. Then rescale single molecule maps and plot rescaling factor per scan if reference is available. The rescaling step is analogous to the former "adjusting stretch scan by scan step". Next it writes scripts for assemblies with a range of parameters. After assemblies finish assembly metrics are generated and the best results are analyzed.

This pipeline uses the same basic workflow as AssembleIrys.pl and AssembleIrysCluster.pl but it runs a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization may be required to run the BioNano `Assembler` on a different machine.

See tutorial lab to run the assemble XeonPhi pipeline with sample data https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_LAB.md.

##"Raw data-to-finished de novo assembly and assembly analysis" pipeline for BioNano molecule maps

The assemble XeonPhi de novo pipeline preps raw molecule maps and writes and runs a series of assemblies for them. Then the user selects the best assembly then summarizes the final assembly metrics.

The basic steps are to first merge multiple BNXs from a single directory and plot single molecule map quality metrics. Next it writes scripts for assemblies with a range of parameters. After assemblies finish assembly metrics are generated and the best results are analyzed.

This pipeline uses the same basic workflow as AssembleIrys.pl and AssembleIrysCluster.pl but it runs a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization may be required to run the BioNano `Assembler` on a different machine.

See tutorial lab to run the assemble XeonPhi pipeline with sample data https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_de_novo_LAB.md. 

#Main custom script for BioNano data assembly

**AssembleIrysXeonPhi.pl -**  The assemble XeonPhi script preps raw molecule maps and writes and runs a series of assemblies for them. Then the user selects the best assembly and uses this to super scaffold the reference FASTA genome file and summarize the final assembly metrics and alignments.

The basic steps are to first merge multiple BNXs from a single directory and plot single molecule map quality metrics. Then rescale single molecule maps and plot rescaling factor per scan if reference is available. The rescaling step is analogous to the former "adjusting stretch scan by scan step". Next it writes scripts for assemblies with a range of parameters. After assemblies finish assembly metrics are genrated and the best results are analyzed.

This pipeline uses the same basic workflow as AssembleIrys.pl and AssembleIrysCluster.pl but it runs a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system. Customization may be required to run the BioNano Assembler on a different machine.

See tutorial lab to run the assemble XeonPhi pipeline with sample data https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_LAB.md.

For de novo projects see this tutorial lab to run the assemble XeonPhi pipeline with sample data
https://github.com/i5K-KINBRE-script-share/Irys-scaffolding/blob/master/KSU_bioinfo_lab/assemble_XeonPhi/assemble_XeonPhi_de_novo_LAB.md

**New features (relative to AssembleIrys.pl and AssembleIrysCluster.pl):**

Automatically adjust optArguments file and number of iterations to match genome size

Plots BNX metrics

Reduced number of arguments 

Includes an assembly with default noise parameters

Includes new graphs and reduced detail in assembly QC files to make selecting the best assembly easier to read (assembly_qcXeonPhi.pl)

Automatically organizes data for researcher where possible


Workflow diagram
![Alt text](https://raw.githubusercontent.com/i5K-KINBRE-script-share/Irys-scaffolding/master/KSU_bioinfo_lab/assemble_XeonPhi/XeonPhibionano_assembly_workflow.png)

A) The Irys produces TIFF files that are converted into BNX text files of molecule maps.

B) Each IrysChip produces one BNX file for each of two flowcells.

C) Each BNX file in the `bnx/` subdirectory of the `-a` assembly working directory is merged and molecule map quality metrics are summarized and plotted.

D) If a reference is provided, merged BNX file is aligned to the in silico maps from the sequence reference. Stretch is rescaled from the alignment and the rescaling factor is ploted for each scan. Rescaled molecule maps are aligned to the reference and noise parameters are estimated. 
E) Base assembly code is determined based on estimated genome size and noise parameters.

F) The first assemblies are run with a variety of p-value thresholds (at least one assembly is also run with defult noise parameters).

G) The best of the first assemblies (red oval) is chosen and a version of this assembly is produced with a variety of minimum molecule length filters.


TYPICAL USAGE

```
perl AssembleIrysXeonPhi.pl -g [genome size in Mb] -r [reference CMAP] -a [the assembly working directory for a project] -p [project name]
```

```
Usage:
    perl AssembleIrysXeonPhi.pl [options]

     Documentation options:

       -help    brief help message
       -man     full documentation

     Required options:

        -a       the assembly working directory for a project
        -g       genome size in Mb
        -r       reference CMAP
        -p       project name for all assemblies

     Optional options:

        -d       add this flag if the project is de novo (has no refernce)

Options:
    -help   Print a brief help message and exits.

    -man    Prints the more detailed manual page with output details and
            exits.

    -a, --assembly_dir
            The assembly working directory for a project. This should
            include the subdirectory "bnx" (any BNX in this directory will
            be used in assembly). Use absolute not relative paths. Do not
            use a trailing "/" for this directory.

    -g, --genome
            The estimated size of the genome in Mb.

    -r, --ref
            The full path to the reference genome CMAP.

    -p, --project
            The project id. This will be used to name all assemblies

    -d, --de_novo
            Add this flag to the command if a project is de novo (i.e. has
            no reference). Any step that requires a reference will then be
            skipped.
```

DEPENDENCIES

Perl, R and BioPerl

