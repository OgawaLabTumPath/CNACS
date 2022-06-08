#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2
readonly LENG_NUM=$3
readonly BAIT_FA=$4

source ${CONFIG}
source ${UTIL}

check_num_args $# 4

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`

LINE_NUM=`expr ${LENG_NUM} \\* 2 - 1`
readonly LENG=`head -n ${LINE_NUM} ${ORGDIR}/${ID}/tmp/length_stats.txt | tail -n 1`
echo ${LENG}


# calculate %GC for each target position (including flanking regions) for defined fragments' length
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/bait_gc.pl ${BAIT_FA} ${MAX_FRAG_LENGTH} ${LENG} ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM} ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/bait_gc.pl ${BAIT_FA} ${MAX_FRAG_LENGTH} ${LENG} ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM} ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt


# load %GC for each fragment
# calculate GC-stratified coverage
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/stratify_gc.pl ${ORGDIR}/${ID}/tmp/mapped_leng${LENG_NUM}.bed ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM} ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt > ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/stratify_gc.pl ${ORGDIR}/${ID}/tmp/mapped_leng${LENG_NUM}.bed ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM} ${ORGDIR}/${ID}/tmp/gc2num_leng${LENG_NUM}.txt > ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt
check_error $?


# predict numbers of mapped fragments for each region
echo -n > ${ORGDIR}/${ID}/tmp/predicted_depth.txt

for i in `seq 1 23`
do
	if [ ${i} -eq 23 ]; then
		CHR="chrX"
	else
		CHR="chr"${i}
	fi
	
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${LENG} | \
	grep ${CHR}$'\t' | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/predict_depth.pl ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.${i}.txt ${LENG} \
	>> ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/extend_bed.pl ${PROBE_BED} ${LENG} | \
	grep ${CHR}$'\t' | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/predict_depth.pl ${ORGDIR}/${ID}/tmp/gc2rate_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/pos2gc_leng${LENG_NUM}.${i}.txt ${LENG} \
	>> ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt
done


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
