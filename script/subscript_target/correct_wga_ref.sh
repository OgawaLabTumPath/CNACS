#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly BAIT_GC=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`


echo "cp ${ORGDIR}/${ID}/tmp/combined_depth.txt ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt"
cp ${ORGDIR}/${ID}/tmp/combined_depth.txt ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/correct_wga.pl ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt ${BAIT_GC} ${ORGDIR}/${ID}/tmp/combined_depth.txt ${ORGDIR}/${ID}/tmp/gc2rate_wga.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/correct_wga.pl ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt ${BAIT_GC} ${ORGDIR}/${ID}/tmp/combined_depth.txt ${ORGDIR}/${ID}/tmp/gc2rate_wga.txt

echo "rm ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt"
rm ${ORGDIR}/${ID}/tmp/combined_depth.pre_wga.txt


# plot GC-stratified coverage
echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/gc2rate_wga.txt ${ORGDIR}/${ID}/tmp/gc2rate_wga.pdf \
< ${COMMAND_CNACS}/subscript_target/plotGC_wga.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/gc2rate_wga.txt ${ORGDIR}/${ID}/tmp/gc2rate_wga.pdf \
< ${COMMAND_CNACS}/subscript_target/plotGC_wga.R


# log_transformation
# normalization
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/norm_depth_ref.pl ${ORGDIR}/${ID}/tmp/combined_depth.txt \
> ${ORGDIR}/${ID}/tmp/combined_normdep.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/norm_depth_ref.pl ${ORGDIR}/${ID}/tmp/combined_depth.txt \
> ${ORGDIR}/${ID}/tmp/combined_normdep.txt


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
