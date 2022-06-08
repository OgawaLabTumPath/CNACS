#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1

source ${CONFIG}
source ${UTIL}

check_num_args $# 1

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`

readonly FIRST_QUANT=`head -n 2 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
readonly MEDIAN=`head -n 4 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
readonly THIRD_QUANT=`head -n 6 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`


# divide a BED file according to fragments' length
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/divide_bed.pl ${ORGDIR}/${ID}/tmp/mapped.bed ${FIRST_QUANT} ${MEDIAN} ${THIRD_QUANT} ${ORGDIR}/${ID}/tmp/mapped_leng1.bed ${ORGDIR}/${ID}/tmp/mapped_leng2.bed ${ORGDIR}/${ID}/tmp/mapped_leng3.bed ${ORGDIR}/${ID}/tmp/mapped_leng4.bed"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/divide_bed.pl ${ORGDIR}/${ID}/tmp/mapped.bed ${FIRST_QUANT} ${MEDIAN} ${THIRD_QUANT} ${ORGDIR}/${ID}/tmp/mapped_leng1.bed ${ORGDIR}/${ID}/tmp/mapped_leng2.bed ${ORGDIR}/${ID}/tmp/mapped_leng3.bed ${ORGDIR}/${ID}/tmp/mapped_leng4.bed

echo "${ORGDIR}/${ID}/tmp/mapped.bed"
rm ${ORGDIR}/${ID}/tmp/mapped.bed

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
