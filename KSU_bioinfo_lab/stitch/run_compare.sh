#!/bin/bash

# Before running: qrsh -P KSU-GEN-BIOINFO -l avx=true -pe single 16
# Before running: qrsh -P KSU-GEN-BIOINFO -l avx=true -pe single 4
# replace project_directory with the name of the working directory update other variables for project in "Project variables" section
# USAGE : bash run_compare.sh

########################  Project variables  ########################

# Working directory with trailing slash
DIR="/homes/bioinfo/bionano/project_directory/"
FASTA="fasta_basename"
ENZYME="enzyme_in_in_silico_cmap_filename"
bng_assembly="BNG_assembly_basename"
FASTA_EXT="fasta_extension_without_dot"

f_con="13"
f_algn="30"
s_con="8"
s_algn="90"

# Strict alignments
#align_para="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10"
# Relaxed alignments
align_para="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15"

project="project_name"

########################  End project variables  ########################

#Align scripts
#/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${DIR}${bng_assembly}.cmap -ref ${DIR}${FASTA}_${ENZYME}.cmap -o ${DIR}${FASTA}_to_${bng_assembly} -res 2.9 ${align_para} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T 1e-8 -maxthreads 16
/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${DIR}${bng_assembly}.cmap -ref ${DIR}${FASTA}_${ENZYME}.cmap -o ${DIR}${FASTA}_to_${bng_assembly} -res 2.9 ${align_para} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T 1e-8 -maxthreads 4

#Get most metrics
/homes/bioinfo/bioinfo_software/bionano/BNGCompare/BNGCompare.pl -f ${DIR}${FASTA}.${FASTA_EXT} -r ${DIR}${FASTA}_${ENZYME}.cmap -q ${DIR}${bng_assembly}.cmap -x ${DIR}${FASTA}_to_${bng_assembly}.xmap


#Flip xmap
perl /homes/bioinfo/bioinfo_software/bionano/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${DIR}${FASTA}_to_${bng_assembly}.xmap ${DIR}${bng_assembly}_to_${FASTA}

perl /homes/bioinfo/bioinfo_software/bionano/BNGCompare/xmap_stats.pl -x ${DIR}${bng_assembly}_to_${FASTA}.flip -o ${DIR}${FASTA}_BNGCompare.csv

#Stitch1

mkdir ${DIR}stitch1

export PERL5LIB=/usr/lib/perl5:/usr/lib/perl5/site_perl:/usr/lib/perl5/vendor_perl:/usr/lib64/perl5:/usr/lib64/perl5/site_perl:/usr/lib64/perl5/vendor_perl:/homes/bioinfo/perl5/lib/perl5:/homes/bioinfo/perl5/lib/perl5/x86_64-linux::/homes/bioinfo/bioinfo_software/perl/lib64/perl5:/homes/bioinfo/bioinfo_software/perl/lib64/perl5/site_perl:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl/5.8.8/Bio:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl/5.8.8/x86_64-linux


perl /homes/bioinfo/bioinfo_software/bionano/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${DIR}${FASTA}_to_${bng_assembly}_q.cmap -x ${DIR}${bng_assembly}_to_${FASTA}.flip -f ${DIR}${FASTA}.${FASTA_EXT} -o ${DIR}stitch1/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1 --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}

echo "${DIR}stitch1/${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_1_superscaffold.agp" > ${DIR}agp_list.txt



