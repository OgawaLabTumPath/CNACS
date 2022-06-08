#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly BAF_FACTOR=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`

# decide scaling factors for SNP-overlapping fragments
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/scaling_factor.pl ${BAF_FACTOR} ${ORGDIR}/${ID}/tmp/raw_baf.txt \
> ${ORGDIR}/${ID}/tmp/scaling_factor.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/scaling_factor.pl ${BAF_FACTOR} ${ORGDIR}/${ID}/tmp/raw_baf.txt \
> ${ORGDIR}/${ID}/tmp/scaling_factor.txt
check_error $?


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
