#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1

source ${CONFIG}
source ${UTIL}

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`

readonly BAM=${ORGDIR}/${ID}/tmp/filt.bam

readonly FIRST_QUANT=`head -n 2 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
readonly MEDIAN=`head -n 4 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
readonly THIRD_QUANT=`head -n 6 ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`


# count %duplicate for fragments with binned length
echo "${SAMTOOLS_PATH}/samtools view ${BAM} | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/count_dup.pl ${FIRST_QUANT} ${MEDIAN} ${THIRD_QUANT} \
> ${ORGDIR}/${ID}/tmp/duplicate_stats.txt"
${SAMTOOLS_PATH}/samtools view ${BAM} | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/count_dup.pl ${FIRST_QUANT} ${MEDIAN} ${THIRD_QUANT} \
> ${ORGDIR}/${ID}/tmp/duplicate_stats.txt

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
