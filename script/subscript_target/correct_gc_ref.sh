#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2
readonly SEX_INFO=$3
readonly LENG_NUM=$4

source ${CONFIG}
source ${UTIL}

check_num_args $# 4

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`

readonly SAMPLE_SEX=`${PERL_PATH} ${COMMAND_CNACS}/subscript_target/sample_sex.pl ${SEX_INFO} ${ID2}`
echo ${SAMPLE_SEX}

LINE_NUM=`expr ${LENG_NUM} \\* 2 - 1`
readonly LENG=`head -n ${LINE_NUM} ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
echo ${LENG}


# calculate %GC for each target position (including flanking regions) for defined fragments' length
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/bait_gc_ref.pl ${ORGDIR}/sequence.fa ${MAX_FRAG_LENGTH} ${LENG} ${SAMPLE_SEX} ${PAR_BED} ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/bait_gc_ref.pl ${ORGDIR}/sequence.fa ${MAX_FRAG_LENGTH} ${LENG} ${SAMPLE_SEX} ${PAR_BED} ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt


# load %GC for each fragment
# calculate GC-stratified coverage
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/stratify_gc_ref.pl ${ORGDIR}/${ID}/tmp/mapped_leng${LENG_NUM}.bed ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt > ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/stratify_gc_ref.pl ${ORGDIR}/${ID}/tmp/mapped_leng${LENG_NUM}.bed ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt > ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt
check_error $?


# predict numbers of mapped fragments for each region
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${LENG} | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/predict_depth_ref.pl ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${LENG} ${SAMPLE_SEX} ${PAR_BED} \
> ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${LENG} | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/predict_depth_ref.pl ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt ${LENG} ${SAMPLE_SEX} ${PAR_BED} \
> ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt

echo "rm ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt"
echo "rm ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt"
rm ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.txt
rm ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
