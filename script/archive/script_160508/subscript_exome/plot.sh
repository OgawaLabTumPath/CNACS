#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly OUTPUTDIR=$1

source ${CONFIG}
source ${UTIL}

check_num_args $# 1

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${OUTPUTDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`


readonly INPUT=${OUTPUTDIR}/${ID}/${ID}_signal.high_res.txt
readonly SEGMENT=${OUTPUTDIR}/${ID}/${ID}_result.high_res.txt
readonly BAF=${OUTPUTDIR}/${ID}/tmp/baf_all.all.txt
readonly OUTPUT_ALL=${OUTPUTDIR}/${ID}/${ID}_all.high_res.pdf

readonly CENTROMERE=${CYTOBAND_DIR}/centromere_pos.txt


# draw figures
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_input_all.pl ${INPUT} ${SEGMENT} ${BAF} ${INPUT}.tmp_all ${SEGMENT}.tmp_all"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_input_all.pl ${INPUT} ${SEGMENT} ${BAF} ${INPUT}.tmp_all ${SEGMENT}.tmp_all

echo "${R_PATH} --vanilla --slave --args ${INPUT}.tmp_all ${SEGMENT}.tmp_all ${CENTROMERE} ${OUTPUT_ALL} < ${COMMAND_CNACS}/subscript_target/plot_all.R"
${R_PATH} --vanilla --slave --args ${INPUT}.tmp_all ${SEGMENT}.tmp_all ${CENTROMERE} ${OUTPUT_ALL} < ${COMMAND_CNACS}/subscript_target/plot_all.R

MAX=`cut -f 3 ${INPUT} | sort -n | tail -n 1`
if [ ${MAX%.*} -gt 3 ]; then
	readonly OUTPUT_SCALED=${OUTPUTDIR}/${ID}/${ID}_scaled.high_res.pdf
	
	echo "${R_PATH} --vanilla --slave --args ${INPUT}.tmp_all ${SEGMENT}.tmp_all ${CENTROMERE} ${OUTPUT_SCALED} < ${COMMAND_CNACS}/subscript_target/plot_scaled.R"
	${R_PATH} --vanilla --slave --args ${INPUT}.tmp_all ${SEGMENT}.tmp_all ${CENTROMERE} ${OUTPUT_SCALED} < ${COMMAND_CNACS}/subscript_target/plot_scaled.R
fi

echo "rm ${INPUT}.tmp_all"
echo "rm ${SEGMENT}.tmp_all"
rm ${INPUT}.tmp_all
rm ${SEGMENT}.tmp_all

# move all the files to another directory
check_mkdir ${OUTPUTDIR}/${ID}/high_res

echo "mv ${OUTPUTDIR}/${ID}/*.high_res.* ${OUTPUTDIR}/${ID}/high_res"
mv ${OUTPUTDIR}/${ID}/*.high_res.* ${OUTPUTDIR}/${ID}/high_res


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
