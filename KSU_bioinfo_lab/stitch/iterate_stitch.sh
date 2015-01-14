#!/bin/bash

# Before running: qrsh -P KSU-GEN-BIOINFO -l avx=true -pe single 16
# Before running: qrsh -P KSU-GEN-BIOINFO -l avx=true -pe single 4
# replace project_directory with the name of the working directory update other variables for project in "Project variables" section. Stitch number begins with 2
# USAGE: bash iterate_stitch.sh <stitch number>

#Current stitch
stitch_num=$1
########################  Project variables  ########################

# Working directory with trailing slash
DIR="/homes/bioinfo/bionano/project_directory/"
bng_assembly="BNG_assembly_basename"

# space separated list of enzymes used. Can be: BspQI BbvCI BsmI BsrDI and/or bseCI
ENZYME="BspQI"

#Stringency variables
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

#Auto variables
out_dir="${DIR}stitch${stitch_num}/"
previous_stitch=`expr ${stitch_num} - 1`
old_out_dir="${DIR}stitch${previous_stitch}/"


#Make CMAP
perl /homes/bioinfo/bioinfo_software/bionano/fa2cmap_multi.pl -v -i ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -e ${ENZYME} >> ${DIR}log.txt

#Align scripts

mkdir ${out_dir}
#/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${DIR}${bng_assembly}.cmap -ref ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold*.cmap -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${bng_assembly} -res 2.9 ${align_para} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T 1e-8 -maxthreads 16 >> ${DIR}log.txt
/homes/bioinfo/bioinfo_software/bionano/tools/RefAligner -i ${DIR}${bng_assembly}.cmap -ref ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold*.cmap -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${bng_assembly} -res 2.9 ${align_para} -extend 1 -outlier 1e-4 -endoutlier 1e-2 -deltaX 12 -deltaY 12 -xmapchim 14 -mres 1.2 -insertThreads 4 -nosplit 2 -f -T 1e-8 -maxthreads 4 >> ${DIR}log.txt

#Flip xmap
perl /homes/bioinfo/bioinfo_software/bionano/Irys-scaffolding/KSU_bioinfo_lab/stitch/flip_xmap.pl ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${bng_assembly}.xmap ${out_dir}${bng_assembly}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}


#StitchX

export PERL5LIB=/usr/lib/perl5:/usr/lib/perl5/site_perl:/usr/lib/perl5/vendor_perl:/usr/lib64/perl5:/usr/lib64/perl5/site_perl:/usr/lib64/perl5/vendor_perl:/homes/bioinfo/perl5/lib/perl5:/homes/bioinfo/perl5/lib/perl5/x86_64-linux::/homes/bioinfo/bioinfo_software/perl/lib64/perl5:/homes/bioinfo/bioinfo_software/perl/lib64/perl5/site_perl:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl/5.8.8/Bio:/homes/bioinfo/bioinfo_software/BioPerl/lib64/perl5/site_perl/5.8.8/x86_64-linux


perl /homes/bioinfo/bioinfo_software/bionano/Irys-scaffolding/KSU_bioinfo_lab/stitch/stitch.pl -r ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_to_${bng_assembly}_q.cmap -x ${out_dir}${bng_assembly}_to_${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}.flip -f ${old_out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${previous_stitch}_superscaffold.fasta -o ${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num} --f_con ${f_con} --f_algn ${f_algn} --s_con ${s_con} --s_algn ${s_algn}


echo "${out_dir}${project}_${f_con}_${f_algn}_${s_con}_${s_algn}_${stitch_num}_superscaffold.agp" >> ${DIR}agp_list.txt

