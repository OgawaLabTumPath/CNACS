#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2

source ${CONFIG}
source ${UTIL}
readonly RECORDS_IN_RAM=5000000

check_num_args $# 2

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`

check_mkdir ${ORGDIR}/${ID}/tmp
readonly BAMmarkdup=${ORGDIR}/${ID}/tmp/org.bam
readonly BAImarkdup=${ORGDIR}/${ID}/tmp/org.bai
readonly METRICS=${ORGDIR}/${ID}/tmp/metrics.txt


# mark duplicate reads
echo "java MarkDuplicates.jar"
${JAVAPATH}/java -Xms7g -Xmx7g -Djava.io.tmpdir=${TEMPDIR} -jar ${PICARD_PATH}/MarkDuplicates.jar INPUT=${SEQBAM} OUTPUT=${BAMmarkdup} METRICS_FILE=${METRICS} VALIDATION_STRINGENCY=SILENT MAX_RECORDS_IN_RAM=${RECORDS_IN_RAM}
check_error $?

echo "java BuildBamIndex.jar"
${JAVAPATH}/java -Xms7g -Xmx7g -Djava.io.tmpdir=${TEMPDIR} -jar ${PICARD_PATH}/BuildBamIndex.jar INPUT=${BAMmarkdup} VALIDATION_STRINGENCY=SILENT MAX_RECORDS_IN_RAM=${RECORDS_IN_RAM}
check_error $?


readonly CHR=`${SAMTOOLS_PATH}/samtools view -H ${BAMmarkdup} | cut -f 2 | cut -d ":" -f 2 | head -n 2 | tail -n 1`

# remove inappropriately-mapped reads
# extract fragments mapped to target regions
# mask overlapping bases between pair reads

if [[ "${CHR}" =~ ^chr ]]; then
	# A source of reference sequences is UCSF
	echo "${SAMTOOLS_PATH}/samtools view -h -b -q ${MAPPING_QUALITY_THRESHOLD} ${BAMmarkdup} | \
	${BEDTOOLS_PATH}/intersectBed -abam stdin -b ${PROBE_BED} | \
	${SAMTOOLS_PATH}/samtools view -h - | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_bam.pl ${MAX_FRAG_LENGTH} ${ORGDIR}/${ID}/tmp/mapped.bed ${ORGDIR}/${ID}/tmp/length_stats.txt | \
	${SAMTOOLS_PATH}/samtools view -bS -h - \
	> ${ORGDIR}/${ID}/tmp/filt.bam"
	${SAMTOOLS_PATH}/samtools view -h -b -q ${MAPPING_QUALITY_THRESHOLD} ${BAMmarkdup} | \
	${BEDTOOLS_PATH}/intersectBed -abam stdin -b ${PROBE_BED} | \
	${SAMTOOLS_PATH}/samtools view -h - | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_bam.pl ${MAX_FRAG_LENGTH} ${ORGDIR}/${ID}/tmp/mapped.bed ${ORGDIR}/${ID}/tmp/length_stats.txt | \
	${SAMTOOLS_PATH}/samtools view -bS -h - \
	> ${ORGDIR}/${ID}/tmp/filt.bam
	check_error $?
else
	# A source of reference sequences is GRC
	echo "${SAMTOOLS_PATH}/samtools view -h -q ${MAPPING_QUALITY_THRESHOLD} ${BAMmarkdup} | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/h37_to_hg19.pl | \
	${SAMTOOLS_PATH}/samtools view -bS - | \
	${BEDTOOLS_PATH}/intersectBed -abam stdin -b ${PROBE_BED} | \
	${SAMTOOLS_PATH}/samtools view -h - | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_bam.pl ${MAX_FRAG_LENGTH} ${ORGDIR}/${ID}/tmp/mapped.bed ${ORGDIR}/${ID}/tmp/length_stats.txt | \
	${SAMTOOLS_PATH}/samtools view -bS -h - \
	> ${ORGDIR}/${ID}/tmp/filt.bam"
	${SAMTOOLS_PATH}/samtools view -h -q ${MAPPING_QUALITY_THRESHOLD} ${BAMmarkdup} | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/h37_to_hg19.pl | \
	${SAMTOOLS_PATH}/samtools view -bS - | \
	${BEDTOOLS_PATH}/intersectBed -abam stdin -b ${PROBE_BED} | \
	${SAMTOOLS_PATH}/samtools view -h - | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_bam.pl ${MAX_FRAG_LENGTH} ${ORGDIR}/${ID}/tmp/mapped.bed ${ORGDIR}/${ID}/tmp/length_stats.txt | \
	${SAMTOOLS_PATH}/samtools view -bS -h - \
	> ${ORGDIR}/${ID}/tmp/filt.bam
	check_error $?
fi


echo "${SAMTOOLS_PATH}/samtools index ${ORGDIR}/${ID}/tmp/filt.bam"
${SAMTOOLS_PATH}/samtools index ${ORGDIR}/${ID}/tmp/filt.bam

echo "rm ${BAMmarkdup}"
echo "rm ${BAImarkdup}"
echo "rm ${METRICS}"
rm ${BAMmarkdup}
rm ${BAImarkdup}
rm ${METRICS}

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
