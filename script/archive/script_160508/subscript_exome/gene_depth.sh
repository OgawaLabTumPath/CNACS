#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly GENE_BED=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2

readonly SEQBAM=`head -n ${SGE_TASK_ID} ${ORGDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`
ID2=`echo ${ID} | sed -e "s/s_//"`


# calculate mean signals for each gene
for LENG_NUM in `seq 1 4`
do
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/gene_depth.pl ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/actual_depth_leng${LENG_NUM}.txt ${GENE_BED} \
	> ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng${LENG_NUM}.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/gene_depth.pl ${ORGDIR}/${ID}/tmp/predicted_depth_leng${LENG_NUM}.txt ${ORGDIR}/${ID}/tmp/actual_depth_leng${LENG_NUM}.txt ${GENE_BED} \
	> ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng${LENG_NUM}.txt
done

# combine depths
echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng1.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng2.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng3.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng4.txt ${ORGDIR}/${ID}/tmp/length_bias.txt ${ORGDIR}/${ID}/tmp/combined_gene_depth.csv \
< ${COMMAND_CNACS}/subscript_exome/combine_rate.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng1.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng2.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng3.txt ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng4.txt ${ORGDIR}/${ID}/tmp/length_bias.txt ${ORGDIR}/${ID}/tmp/combined_gene_depth.csv \
< ${COMMAND_CNACS}/subscript_exome/combine_rate.R

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/combine_depth.pl ${ORGDIR}/${ID}/tmp/combined_gene_depth.csv ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng1.txt \
> ${ORGDIR}/${ID}/tmp/combined_gene_depth.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/combine_depth.pl ${ORGDIR}/${ID}/tmp/combined_gene_depth.csv ${ORGDIR}/${ID}/tmp/depth_ratio_gene_leng1.txt \
> ${ORGDIR}/${ID}/tmp/combined_gene_depth.txt


# log_transformation
# normalization
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/norm_depth.pl ${ORGDIR}/${ID}/tmp/combined_gene_depth.txt \
> ${ORGDIR}/${ID}/tmp/combined_gene_normdep.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/norm_depth.pl ${ORGDIR}/${ID}/tmp/combined_gene_depth.txt \
> ${ORGDIR}/${ID}/tmp/combined_gene_normdep.txt


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
