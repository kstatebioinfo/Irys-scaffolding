##################################################
#        THIS IS NOT A WORKING SCRIPT BUT        #
#        A SERIES OF EXAMPLES OF CODE FOR        #
#        ALIGNMENT AND ASSEMBLY PARAMETERS       #
##################################################

# GET RefAligner AND THE ASSEMBLY SCRIPTS FROM LINKS DESCRIBED IN http://www.bnxinstall.com/training/docs/.

##################################################
#           CREATING AN IN SILICO CMAP           #
##################################################

    #    fa2cmap_multi.pl HELP MENU:

    #    Usage: ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/third-party/fa2cmap_multi.pl [options] <Args>
    #    Options:
    #    -h    : This help message
    #    -v    : Verbose output  (Default: OFF)
    #    -i    : Input fasta file
    #    -o    : Output folder  (Default: the same as the input file)
    #    -e    : Names or the sequences of the enzymes  (Can be A space separated list of multiple enzymes including: BspQI BbvCI BsmI BsrDI and/or bseCI)
    #    -m    : Filter: Minimum labels  (Default: 5)
    #    -M    : Filter: Minimum size (Kb)  (Default: 20)
    #
    #    NOTE: CMAP index is 1-based

    #    EXAMPLE:

    perl ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/third-party/fa2cmap_multi.pl -v -i REFERENCE.fasta -e BspQI

##################################################
#                ALIGNING TWO CMAPS              #
#        ALWAYS ALIGN WITH THE IN SILICO CMAP    #
#              AS THE REFERENCE/ANCHOR!          #
##################################################

    # MOLECULE-TO-REFERENCE ALIGNMENT PARAMETER RECOMMENDATIONS FROM BIONANO IrysView-v2.0-Software-Training-Guide. AVAILABLE AT http://www.bnxinstall.com/training/docs/.. ALTHOUGH THESE ARE MOLECULE-TO-REFERENCE ALIGNMENT PARAMETER RECOMMENDATIONS THEY ARE ALSO USED AS STARTING PARAMETERS FOR ANCHOR-TO-QUERY ALIGNMENTS AND ASSEMBLY.

    #    i. The performance of the RefAligner algorithm is set by the -maxmem option. Its
    #    value is set to the total memory on the host computer divided by the expected
    #    number of concurrent executions. For example, if the host memory is 256GB
    #    and two instances are expected to run at a time, then set -maxmem 128.
    #
    #    ii. The ‘-M’ option designates how many iterations to run. The number of iterations
    #    is a tradeoff of computational time and potentially more accurate Molecule
    #    Quality Report. Larger genomes take significant computation. Thus, a lower
    #    value than the default may be preferred (e.g., 3 rather than 5), when analyzing
    #    a large genome, such as human. Increasing M values (5-10) will not make a
    #    significant difference in processing time and accuracy for a small genome like
    #    E. Coli.
    #
    #    iii. The ‘-T’ option defines the P-value cutoff. Genome complexity approximately
    #    scales with the genome size, so to correct for multiple comparisons, the Pvalue
    #    can be adjusted for the size of genome being analyzed. It should be
    #    approximately 1e-5/genome size (in Mb). For example, use 1e-6 for E. coli, 1e-
    #    7 for drosophila, and 1e-9 for human.
    #
    #    iv. The ‘-minlen’ defines the minimum molecule length in Kb to use for alignment.
    #    The minimum recommended value is 100 Kb.
    #
    #    v. Other options are preset to recommended values.

    # ALIGNMENT PARAMETERS USED BY KSU:

    #    WE BEGIN USING THE FOLLOWING ALIGNMENT PARAMETERS:
    #
    #    1) SET P-VALUE THRESHOLD BY GENOME SIZE IN (Mb):

    genome_size_Mb=3000

    T=`echo "scale=15; 0.00001 / $genome_size_Mb" | bc`

    echo $T

    #    2) RUN FIRST ALIGNMENT OF IN SILICO CMAP TO BNG ASSEMBLED CMAP (REFERENCE_basename_ENZYME.cmap = IN SILICO CMAP):

    ~/RefAligner -i bng_assembly_basename.cmap -ref REFERENCE_basename_ENZYME.cmap -o REFERENCE_basename_to_bng_assembly_basename -res 2.9 -FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10 -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T ${T} -maxthreads 16

    #   OPTIONAL: FOR SOME NON-MODEL ORGANISMS WE HAVE FOUND RELAXED PARAMETERS GIVE BETTER ALIGNMENTS. IF YOUR FIRST ATTEMPTS FAIL TO ALIGN YOU MAY TEST SOMETHING LIKE THIS. REVIEW YOUR RESULTS IN IRYSVIEW ZOOMING IN ON ALIGNMENTS TO SEE IF THESE PARAMTERS SUIT YOUR PROJECT:

    ~/RefAligner -i bng_assembly_basename.cmap -ref REFERENCE_basename_ENZYME.cmap -o REFERENCE_basename_to_bng_assembly_basename -res 2.9 -FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15 -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T ${T} -maxthreads 16

    #   OPTIONAL: YOU MAY ALSO WANT TO TEST THE EFFECT OF INCREASING OR DECREASING P-VALUE THRESHOLDS (THE "-T" PARAMETER) ON YOUR ALIGNMENTS

##################################################
#          ASSEMBLING MOLECULE.BNX FILES         #
##################################################

#    1) IF YOU HAVE MULTIPLE BNX FILES YOU CAN MERGE THEM WITH THE COMMAND BELOW ( THE "-if" PARAMETER SHOULD POINT TO A PLAIN TEXT LIST OF YOUR "Molecules.bnx" FILES):

    ~/tools/RefAligner -if my_bnx_list.txt -o ~/my_merged_bnx_dir/all_flowcells_merged -merge -bnx -minsites 5 -minlen 100 -maxthreads 16

#    2) ATTEMPT A REFERENCE GUIDED ASSEMBLY USING AUTONOISE (THE "-y" PARAMETER). THIS WILL SET ASSEMBLY PARAMETERS AND ADJUST MOLECULE STRETCH BASED ON MOLECULE ALIGNMENT TO THE REFERENCE.

    python2 ~/scripts/pipelineCL.py -y -T 16 -j 8 -N 2 -w -i 5 -a ~/scripts/optArguments_human.xml -t ~/tools/ -l ~/my_out_dir/ -b ~/my_merged_bnx_dir/all_flowcells_merged.bnx -V 1 -e project_name -p 0 -r REFERENCE_basename_ENZYME.cmap -U -C ~/scripts/clusterArguments.xml

#    NOTE: YOU MAY NEED TO ADD THE PATH TO THE DRMAA LIBRARY AT THE TOP OF YOU BASH ASSEMBLY SCRIPT E.G. :

    #!/bin/bash
    export DRMAA_LIBRARY_PATH=/opt/sge/lib/lx3-amd64/libdrmaa.so.1.0

#    NOTE: THE "-C" PARAMETER IS ONLY FOR ASSEMBLIES ON CLUSTERS. IF YOU ARE WORKING ON A CLUSTER YOU NEED TO INCLUDE THIS PARAMETER AND YOU MAY ALSO NEED TO CUSTOMIZE ~/scripts/clusterArguments.xml FOR YOUR CLUSTER.

#    OPTIONAL: WHEN WORKING WITH NON-MODEL ORGANISMS OR UNSUPPORTED SAMPLES SOMETIMES AUTONOISE FAILS. IN THAT CASE THE ASSEMBLY HALTS AND NO STEP PAST THE "Molecules Aligned to Assembly" STEP IS DESCRIBED IN THE "_informaticsReport.txt" FILE.
#    YOU CAN REMOVE THE "-y" AUTONOISE PARAMETER FROM YOUR ASSEMBLY COMMAND AND CUSTOMIZE YOUR "~/scripts/optArguments_human.xml", "~/scripts/optArguments_medium.xml" OR "~/scripts/optArguments_small.xml" MANUALLY:

    WE TYPICALLY TEST THREE "-minlen" PARAMETERS IN THE "<bnx_sort>" SECTION (100, 150 AND 180).

    WE SET THE "-T" PARAMETER IN THE "<Initial Assembly>" SECTION TO 1e-5/$genome_size_Mb

    WE SET THE "-T" PARAMETER IN THE "<Extension and Refinement>" SECTION TO 1e-6/$genome_size_Mb

    WE SET THE "-T" PARAMETER IN THE "<Merge>" SECTION TO 1e-9/$genome_size_Mb





