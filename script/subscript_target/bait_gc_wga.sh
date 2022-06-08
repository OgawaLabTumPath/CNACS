#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2

# obtain sequences of target regions (including flanking regions)
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed_wga.pl ${PROBE_BED} ${WGA_LENGTH} | \
${BEDTOOLS_PATH}/fastaFromBed -fi ${GENREF} -bed stdin -fo ${ORGDIR}/sequence_wga.fa -name"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed_wga.pl ${PROBE_BED} ${WGA_LENGTH} | \
${BEDTOOLS_PATH}/fastaFromBed -fi ${GENREF} -bed stdin -fo ${ORGDIR}/sequence_wga.fa -name


# calculate %GC for each probe
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/bait_gc_wga.pl ${ORGDIR}/sequence_wga.fa > ${ORGDIR}/bait_gc.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/bait_gc_wga.pl ${ORGDIR}/sequence_wga.fa > ${ORGDIR}/bait_gc.txt


echo "rm ${ORGDIR}/sequence_wga.fa"
rm ${ORGDIR}/sequence_wga.fa

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
