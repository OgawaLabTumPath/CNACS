#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2

source ${CONFIG}
source ${UTIL}

check_num_args $# 2
check_mkdir ${ORGDIR}/stats

files=()
while read file
do
	files+=("$file")
done < <(find ${ORGDIR} -name "combined_normdep.txt")

dup_files=()
while read dup_file
do
	dup_files+=("$dup_file")
done < <(find ${ORGDIR} -name "duplicate_stats.txt")

bias_files=()
while read bias_file
do
	bias_files+=("$bias_file")
done < <(find ${ORGDIR} -name "length_bias.txt")


echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_case_header.pl "${files[@]}" > ${ORGDIR}/stats/header.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_case_header.pl "${files[@]}" > ${ORGDIR}/stats/header.txt

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_depth.pl ${PROBE_BED} "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/snp_statistics2.pl \
> ${ORGDIR}/stats/depth_summary.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_depth.pl ${PROBE_BED} "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/snp_statistics2.pl \
> ${ORGDIR}/stats/depth_summary.txt
check_error $?


# Mean of depth
echo "cut -f 4 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 10 )' > ${ORGDIR}/stats/depth_mean.txt"
cut -f 4 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 10 )' > ${ORGDIR}/stats/depth_mean.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_mean.txt ${ORGDIR}/stats/depth_mean.pdf Mean_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_mean.txt ${ORGDIR}/stats/depth_mean.pdf Mean_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/depth_mean.txt"
rm ${ORGDIR}/stats/depth_mean.txt


# Coefficient of variation of depth
echo "cut -f 5 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 1 )' > ${ORGDIR}/stats/depth_coefvar.txt"
cut -f 5 ${ORGDIR}/stats/depth_summary.txt | grep -v NA | perl -nle 'print $_ if ( $_ < 1 )' > ${ORGDIR}/stats/depth_coefvar.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_coefvar.txt ${ORGDIR}/stats/depth_coefvar.pdf CoefVar_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/depth_coefvar.txt ${ORGDIR}/stats/depth_coefvar.pdf CoefVar_of_normalized_depth < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/depth_coefvar.txt"
rm ${ORGDIR}/stats/depth_coefvar.txt


echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_amp.pl "${dup_files[@]}" \
> ${ORGDIR}/stats/duplicate_stats.csv"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_amp.pl "${dup_files[@]}" \
> ${ORGDIR}/stats/duplicate_stats.csv
check_error $?

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_amp.pl "${bias_files[@]}" \
> ${ORGDIR}/stats/length_bias.csv"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_amp.pl "${bias_files[@]}" \
> ${ORGDIR}/stats/length_bias.csv
check_error $?

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/duplicate_stats.csv ${ORGDIR}/stats/duplicate_stats.pdf \
< ${COMMAND_CNACS}/subscript_target/barplot.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/duplicate_stats.csv ${ORGDIR}/stats/duplicate_stats.pdf \
< ${COMMAND_CNACS}/subscript_target/barplot.R

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/length_bias.csv ${ORGDIR}/stats/length_bias.pdf \
< ${COMMAND_CNACS}/subscript_target/barplot.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/length_bias.csv ${ORGDIR}/stats/length_bias.pdf \
< ${COMMAND_CNACS}/subscript_target/barplot.R


echo "rm ${ORGDIR}/stats/duplicate_stats.csv"
echo "rm ${ORGDIR}/stats/length_bias.csv"
rm ${ORGDIR}/stats/duplicate_stats.csv
rm ${ORGDIR}/stats/length_bias.csv

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
