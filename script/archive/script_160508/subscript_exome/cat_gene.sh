#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1

source ${CONFIG}
source ${UTIL}

check_num_args $# 1
check_mkdir ${ORGDIR}/stats

files=()
while read file
do
	files+=("$file")
done < <(find ${ORGDIR} -name "combined_gene_normdep.txt")


echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/cat_gene.pl "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/snp_statistics.pl \
> ${ORGDIR}/stats/depth_summary.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/cat_gene.pl "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/snp_statistics.pl \
> ${ORGDIR}/stats/depth_summary.txt
check_error $?


# Mean of depth
echo "cut -f 5 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 10 )' > ${ORGDIR}/stats/depth_mean.txt"
cut -f 5 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 10 )' > ${ORGDIR}/stats/depth_mean.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_mean.txt ${ORGDIR}/stats/depth_mean.pdf Mean_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_mean.txt ${ORGDIR}/stats/depth_mean.pdf Mean_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/depth_mean.txt"
rm ${ORGDIR}/stats/depth_mean.txt


# Coefficient of variation of depth
echo "cut -f 6 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 1 )' > ${ORGDIR}/stats/depth_coefvar.txt"
cut -f 6 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 1 )' > ${ORGDIR}/stats/depth_coefvar.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_coefvar.txt ${ORGDIR}/stats/depth_coefvar.pdf CoefVar_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_coefvar.txt ${ORGDIR}/stats/depth_coefvar.pdf CoefVar_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/depth_coefvar.txt"
rm ${ORGDIR}/stats/depth_coefvar.txt


echo "cp ${COMMAND_CNACS}/subscript_exome/threshold.txt ${ORGDIR}/stats"
cp ${COMMAND_CNACS}/subscript_exome/threshold.txt ${ORGDIR}/stats

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
