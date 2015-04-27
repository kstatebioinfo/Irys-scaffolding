SUMMARY

**AssembleIrysXeonPhi.pl -**  Merges multiple BNXs from a single directory and plots single molecule map quality metrics. Rescales single molecule maps and plots rescaling factor per scan (adjusts stretch scan by scan) if reference is available. Writes scripts for assemblies with a range of parameters. This script uses the same basic workflow as AssembleIrys.pl and AssembleIrysCluster.pl but it runs a Xeon Phi server with 576 cores (48x12-core Intel Xeon CPUs), 256GB of RAM, and Linux CentOS 7 operating system.

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
perl AssembleIrys.pl -g [genome size in Mb] -r [reference CMAP] -a [the assembly working directory for a project] -p [project name]
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

```

DEPENDENCIES

Perl and R

