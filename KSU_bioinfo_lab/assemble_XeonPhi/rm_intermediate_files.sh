#!/bin/bash
# USAGE: bash ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/rm_intermediate_files.sh ASSEMBLY_DIRECTORY STRINGENCY PROJECT

# DESCRIPTION: Script removes unneeded intermediate files after the BioNano assembler finishes.

# bash ~/Irys-scaffolding/KSU_bioinfo_lab/assemble_XeonPhi/rm_intermediate_files.sh /home/bionano/bionano/Gast_acul_2014_057_tuesday default_t_150 Gast_acul_2014_057

assembly_directory=$1
stringency=$2
project=$3

## TEST if assembly is finished:
echo "Testing if assembly is complete..."
if [ -f ${assembly_directory}/${stringency}/contigs/*_refineFinal1/*_REFINEFINAL1.cmap ]; then
    echo "Assembly complete"
    ## EMAIL #1
    echo "Removing files in align directory..."
    for align_directory_file in $(find ${assembly_directory}/${stringency}/align -type f)
    do
        rm $align_directory_file
    done
    rmdir ${assembly_directory}/${stringency}/align
    ## EMAIL #2
    echo "Removing files in intermediate assembly directories..."
    for intermediate_alignref_directory in $(find ${assembly_directory}/${stringency}/contigs/${project}_${stringency}_*/alignref -type d | egrep -v refineFinal)
    do
    #        rm -r ${intermediate_directory}/alignref
        rm -r ${intermediate_alignref_directory}
    done
    for intermediate_directory in $(find ${assembly_directory}/${stringency}/contigs/${project}_${stringency}_* -type d | egrep -v refineFinal)
    do
    #        rm -r ${intermediate_directory}/alignref
        rm -r ${intermediate_directory}
    done

    ## EMAIL #3
    echo "Removing files in intermediate SV directory..."
    for intermediate_sv_file in $(find ${assembly_directory}/${stringency}/contigs/${project}_${stringency}_*_sv -maxdepth 1 -type f)
    do
        rm $intermediate_sv_file
    done
    ## EMAIL #4
    echo "Removing temp BNX files in main assembly directory..."
    for intermediate_bnx in $(find ${assembly_directory}/${stringency}/all_* -type f )
    do
        rm $intermediate_bnx
    done
else
    echo "Assembly not complete exiting."
fi



