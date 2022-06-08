#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly PROBE_BED=$2
SNP_PROBE_BED=${ORGDIR}/overlapping_snp.bed

source ${CONFIG}
source ${UTIL}

check_num_args $# 2
check_mkdir ${ORGDIR}/stats

echo "cp ${COMMAND_CNACS}/subscript_target/threshold.txt ${ORGDIR}/stats"
cp ${COMMAND_CNACS}/subscript_target/threshold.txt ${ORGDIR}/stats

files=()
while read file
do
	files+=("$file")
done < <(find ${ORGDIR} -name "*raw_baf.txt")

# Integrate information on BAF
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_baf_info.pl ${SNP_PROBE_BED} "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/filt_snp.pl | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/snp_statistics.pl \
> ${ORGDIR}/stats/hetero_snp_info.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/cat_baf_info.pl ${SNP_PROBE_BED} "${files[@]}" | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/filt_snp.pl | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/snp_statistics.pl \
> ${ORGDIR}/stats/hetero_snp_info.txt
check_error $?


# Calculate statistics of BAF
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/baf_stats.pl ${ORGDIR}/stats/hetero_snp_info.txt ${ORGDIR}/stats/baf_stats.org.txt ${ORGDIR}/stats/baf_factor.tmp.bed"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/baf_stats.pl ${ORGDIR}/stats/hetero_snp_info.txt ${ORGDIR}/stats/baf_stats.org.txt ${ORGDIR}/stats/baf_factor.tmp.bed

echo "rm ${ORGDIR}/stats/hetero_snp_info.txt"
rm ${ORGDIR}/stats/hetero_snp_info.txt

echo "cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${ORGDIR}/stats/baf_factor.tmp.bed -wa -wb \
> ${ORGDIR}/stats/baf_factor.all.bed"
cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${ORGDIR}/stats/baf_factor.tmp.bed -wa -wb \
> ${ORGDIR}/stats/baf_factor.all.bed


# Define adjustment factors for probes
echo "cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${ORGDIR}/stats/baf_factor.tmp.bed -wa -wb | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/probe2factor.pl > ${ORGDIR}/stats/baf_factor.bed"
cut -f 1-3 ${PROBE_BED} | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${ORGDIR}/stats/baf_factor.tmp.bed -wa -wb | \
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/probe2factor.pl > ${ORGDIR}/stats/baf_factor.bed

echo "rm ${ORGDIR}/stats/baf_factor.tmp.bed"
rm ${ORGDIR}/stats/baf_factor.tmp.bed


# Mean of BAF
echo "grep -v FACTOR ${ORGDIR}/stats/baf_stats.org.txt | cut -f 5 > ${ORGDIR}/stats/baf_mean.txt"
grep -v FACTOR ${ORGDIR}/stats/baf_stats.org.txt | cut -f 5 > ${ORGDIR}/stats/baf_mean.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/baf_mean.txt ${ORGDIR}/stats/baf_mean.pdf B-allele-frequency < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/baf_mean.txt ${ORGDIR}/stats/baf_mean.pdf B-allele-frequency < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/baf_mean.txt"
rm ${ORGDIR}/stats/baf_mean.txt


# Coefficient of variation of BAF
echo "grep -v FACTOR ${ORGDIR}/stats/baf_stats.org.txt | cut -f 6 > ${ORGDIR}/stats/baf_coefvar.txt"
grep -v FACTOR ${ORGDIR}/stats/baf_stats.org.txt | cut -f 6 > ${ORGDIR}/stats/baf_coefvar.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/baf_coefvar.txt ${ORGDIR}/stats/baf_coefvar.pdf CoefVar < ${COMMAND_CNACS}/subscript_target/hist.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/baf_coefvar.txt ${ORGDIR}/stats/baf_coefvar.pdf CoefVar < ${COMMAND_CNACS}/subscript_target/hist.R

echo "rm ${ORGDIR}/stats/baf_coefvar.txt"
rm ${ORGDIR}/stats/baf_coefvar.txt

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
