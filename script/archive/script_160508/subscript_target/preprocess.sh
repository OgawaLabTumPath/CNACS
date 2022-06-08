#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2

# select SNPs in the target regions
echo "cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a ${ALL_BED} -b stdin -wa -wb \
> ${ORGDIR}/overlapping_snp.bed"
cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a ${ALL_BED} -b stdin -wa -wb \
> ${ORGDIR}/overlapping_snp.bed


# obtain sequences of target regions (including flanking regions)
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${MAX_FRAG_LENGTH} | \
${BEDTOOLS_PATH}/fastaFromBed -fi ${GENREF} -bed stdin -fo ${ORGDIR}/sequence.fa -name"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${MAX_FRAG_LENGTH} | \
${BEDTOOLS_PATH}/fastaFromBed -fi ${GENREF} -bed stdin -fo ${ORGDIR}/sequence.fa -name


# obtain information on replication timing
echo "cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${REPLI_TIME} -wa -wb | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/repli_time.pl ${PROBE_BED} \
> ${ORGDIR}/repli_time.txt"
cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${REPLI_TIME} -wa -wb | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/repli_time.pl ${PROBE_BED} \
> ${ORGDIR}/repli_time.txt

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
