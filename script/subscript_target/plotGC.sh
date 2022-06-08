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


# plot GC-stratified coverage
echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/gc2rate_leng1.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng2.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng3.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng4.txt ${ORGDIR}/${ID}/tmp/gc2rate.pdf \
< ${COMMAND_CNACS}/subscript_target/plotGC.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/gc2rate_leng1.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng2.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng3.txt ${ORGDIR}/${ID}/tmp/gc2rate_leng4.txt ${ORGDIR}/${ID}/tmp/gc2rate.pdf \
< ${COMMAND_CNACS}/subscript_target/plotGC.R


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
