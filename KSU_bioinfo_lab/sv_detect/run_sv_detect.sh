#!/bin/bash
. /usr/bin/virtualenvwrapper.sh
workon bionano
export DRMAA_LIBRARY_PATH=/opt/sge/lib/lx3-amd64/libdrmaa.so.1.0

# Run first: qrsh -P KSU-GEN-BIOINFO -l avx=true -pe single 16

# cp /homes/bioinfo/bioinfo_software/bionano/test_3265_release/scripts/optArguments_human.xml and adjust sv detect section

# Strict alignments
#   align_para="-FP 0.8 -FN 0.08 -sf 0.20 -sd 0.10"
# Relaxed alignments
#   align_para="-FP 1.2 -FN 0.15 -sf 0.10 -sd 0.15"

# "-T" parameter should be between 8 and 13

# USAGE: bash run_sv_detect.sh

# HELP MENU: python runSV.py -h
# USAGE: runSV.py [-h] [-t REFALIGNER] [-r REFERENCEMAP] [-q QUERYDIR]
#[-p PIPELINEDIR] [-a OPTARGUMENTS] [-T NUMTHREADS]
#[-j MAXTHREADS] [-b BEDFILE]


python2 /homes/bioinfo/bioinfo_software/bionano/test_3265_release/scripts/runSV.py -r in_silico_CMAP.cmap -q path_to_BNG_assembly/contigs/ -p /homes/bioinfo/bioinfo_software/bionano/test_3265_release/scripts/ -t /homes/bioinfo/bioinfo_software/bionano/test_3265_release/tools/RefAligner -a path_to_customized/optArguments_human.xml -T 16 -j 8
