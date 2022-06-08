#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly ORGDIR=$1
readonly TARGET_BED=$2
readonly THRESHOLD=$3

source ${CONFIG}
source ${UTIL}

check_num_args $# 3


# input files
readonly BAF_INFO=${ORGDIR}/stats/baf_stats.org.txt
readonly DEPTH_INFO=${ORGDIR}/stats/exon_summary.txt
readonly GENE_INFO=${ORGDIR}/stats/depth_summary.txt
readonly CYTOBAND=${CYTOBAND_DIR}/cytoBand_rgb2.csv
readonly CENTROMERE=${CYTOBAND_DIR}/centromere_pos.txt

# Output files
readonly BAF_INFO_FILT=${ORGDIR}/stats/baf_stats.txt

ALL_DEPTH=${ORGDIR}/stats/all_depth.txt
GENE_DEPTH=${ORGDIR}/stats/all_gene_depth.txt
cp ${ORGDIR}/stats/header.txt ${ALL_DEPTH}
cp ${ORGDIR}/stats/header.txt ${GENE_DEPTH}

TARGETED_PROBES1=${ORGDIR}/stats/targeted_probes.tmp1.txt
TARGETED_PROBES2=${ORGDIR}/stats/targeted_probes.tmp2.txt
TARGETED_PROBES3=${ORGDIR}/stats/targeted_probes.txt


### Processing all signals ###

# thresholds
readonly BAF_MEAN_LOWER=`head -n 1 ${THRESHOLD} | tail -n 1 | cut -f 2`
readonly BAF_MEAN_UPPER=`head -n 2 ${THRESHOLD} | tail -n 1 | cut -f 2`
readonly BAF_COEFVAR_UPPER=`head -n 3 ${THRESHOLD} | tail -n 1 | cut -f 2`
DEPTH_MEAN_LOWER=0.15
DEPTH_MEAN_UPPER=3
PROBE_TOTAL=`wc -l ${DEPTH_INFO} | cut -d " " -f 1`
PROBE_NUM=$(expr ${PROBE_TOTAL} / 5)
DEPTH_COEFVAR_UPPER=`cut -f 5 ${DEPTH_INFO} | grep -v NA | sort -n | head -n ${PROBE_NUM} | tail -n 1`

# 1st probe selection
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install1.pl \
	${BAF_INFO} \
	${DEPTH_INFO} \
	${TARGET_BED} \
	${BAF_INFO_FILT} \
	${ALL_DEPTH} \
	${TARGETED_PROBES1} \
	${BAF_MEAN_LOWER} \
	${BAF_MEAN_UPPER} \
	${BAF_COEFVAR_UPPER} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install1.pl \
	${BAF_INFO} \
	${DEPTH_INFO} \
	${TARGET_BED} \
	${BAF_INFO_FILT} \
	${ALL_DEPTH} \
	${TARGETED_PROBES1} \
	${BAF_MEAN_LOWER} \
	${BAF_MEAN_UPPER} \
	${BAF_COEFVAR_UPPER} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}


# 2nd probe selection
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install2.pl \
	${DEPTH_INFO} \
	${ALL_DEPTH} \
	${TARGETED_PROBES1} \
	${TARGETED_PROBES2} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install2.pl \
	${DEPTH_INFO} \
	${ALL_DEPTH} \
	${TARGETED_PROBES1} \
	${TARGETED_PROBES2} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}

# 3rd probe selection
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install3.pl \
	${DEPTH_INFO} \
	${ALL_DEPTH} \
	${TARGETED_PROBES2} \
	${TARGETED_PROBES3} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install3.pl \
	${DEPTH_INFO} \
	${ALL_DEPTH} \
	${TARGETED_PROBES2} \
	${TARGETED_PROBES3} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}

echo "rm ${TARGETED_PROBES1}"
echo "rm ${TARGETED_PROBES2}"
rm ${TARGETED_PROBES1}
rm ${TARGETED_PROBES2}

### End of processing all signals ###


### Processing mean signals for each gene ###

# thresholds
DEPTH_MEAN_LOWER=`head -n 4 ${THRESHOLD} | tail -n 1 | cut -f 2`
DEPTH_MEAN_UPPER=`head -n 5 ${THRESHOLD} | tail -n 1 | cut -f 2`
DEPTH_COEFVAR_UPPER=`head -n 6 ${THRESHOLD} | tail -n 1 | cut -f 2`

echo "cat ${GENE_INFO} | perl -nle 'my @curRow = split(/\t/, $_); print $_ . "\n" if ( $curRow[1] < $curRow[2] )' | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${TARGET_BED} -wa \
> ${GENE_INFO}.targeted"
cat ${GENE_INFO} | perl -nle 'my @curRow = split(/\t/, $_); print $_ . "\n" if ( $curRow[1] < $curRow[2] )' | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${TARGET_BED} -wa \
> ${GENE_INFO}.targeted

echo "cat ${GENE_INFO} | perl -nle 'my @curRow = split(/\t/, $_); print $_ . "\n" if ( $curRow[1] < $curRow[2] )' | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${TARGET_BED} -v -wa \
> ${GENE_INFO}.non_targeted"
cat ${GENE_INFO} | perl -nle 'my @curRow = split(/\t/, $_); print $_ . "\n" if ( $curRow[1] < $curRow[2] )' | \
${BEDTOOLS_PATH}/intersectBed -a stdin -b ${TARGET_BED} -v -wa \
> ${GENE_INFO}.non_targeted

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install_gene.pl \
	${GENE_INFO}.targeted \
	${GENE_INFO}.non_targeted \
	${GENE_DEPTH} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/ref_install_gene.pl \
	${GENE_INFO}.targeted \
	${GENE_INFO}.non_targeted \
	${GENE_DEPTH} \
	${DEPTH_MEAN_LOWER} \
	${DEPTH_MEAN_UPPER} \
	${DEPTH_COEFVAR_UPPER}

### End of processing mean signals ###



### Plot distribution of probes ###

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/dist_input_all.pl ${ALL_DEPTH} ${BAF_INFO_FILT} > ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/dist_input_all.pl ${ALL_DEPTH} ${BAF_INFO_FILT} > ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt

echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt ${CENTROMERE} ${ORGDIR}/stats/bait_dist/dist_all.pdf < ${COMMAND_CNACS}/subscript_target/plot_bait_all.R"
${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt ${CENTROMERE} ${ORGDIR}/stats/bait_dist/dist_all.pdf < ${COMMAND_CNACS}/subscript_target/plot_bait_all.R

echo "rm ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt"
rm ${ORGDIR}/stats/bait_dist/bait_dist.tmp1.txt


for i in `seq 1 23`
do
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/dist_input_chr.pl ${ALL_DEPTH} ${BAF_INFO_FILT} ${i} > ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/dist_input_chr.pl ${ALL_DEPTH} ${BAF_INFO_FILT} ${i} > ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt
	
	echo "${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt ${CYTOBAND} ${ORGDIR}/stats/bait_dist/dist_chr${i}.pdf ${i} < ${COMMAND_CNACS}/subscript_target/plot_bait_chr.R"
	${R_PATH} --vanilla --slave --args ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt ${CYTOBAND} ${ORGDIR}/stats/bait_dist/dist_chr${i}.pdf ${i} < ${COMMAND_CNACS}/subscript_target/plot_bait_chr.R
	
	echo "rm ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt"
	rm ${ORGDIR}/stats/bait_dist/bait_dist.tmp2.txt
done

### End of plot ###


: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
