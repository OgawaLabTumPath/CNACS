#!/bin/bash
#$ -S /bin/bash
#$ -cwd

readonly OUTPUTDIR=$1
readonly BAF_INFO=$2
readonly BAF_FACTOR=$3
readonly BAF_FACTOR_ALL=$4
readonly ALL_DEPTH=$5
readonly REP_TIME=$6

source ${CONFIG}
source ${UTIL}

check_num_args $# 6


readonly SEQBAM=`head -n ${SGE_TASK_ID} ${OUTPUTDIR}/bam_list.txt | tail -n 1`
TMP_ID="${SEQBAM##*/}"
ID=`echo ${TMP_ID} | sed -e "s/\.bam//"`


# filter out low-quality probes
# make an input file for CBS (BAF)
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input.pl ${OUTPUTDIR}/${ID}/tmp/combined_normdep.txt ${OUTPUTDIR}/${ID}/tmp/adjusted_baf.txt ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH} ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv ${OUTPUTDIR}/${ID}/tmp/baf_all.all.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input.pl ${OUTPUTDIR}/${ID}/tmp/combined_normdep.txt ${OUTPUTDIR}/${ID}/tmp/adjusted_baf.txt ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH} ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv ${OUTPUTDIR}/${ID}/tmp/baf_all.all.txt
check_error $?


# circular binary segmentation (BAF)
echo "${R_PATH} --vanilla --slave --args ${ID} ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.txt ${CBS_ALPHA_BAF} < ${COMMAND_CNACS}/subscript_target/cbs.R"
${R_PATH} --vanilla --slave --args ${ID} ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.txt ${CBS_ALPHA_BAF} < ${COMMAND_CNACS}/subscript_target/cbs.R
check_error $?

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/seg2bed.pl ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.txt \
> ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.bed"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/seg2bed.pl ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.txt \
> ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.bed
check_error $?


### start a recursive process ###

# count
LOOP=0

# differences from a former loop
echo -n > ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt
echo start! > ${OUTPUTDIR}/${ID}/tmp/diff.all.txt

echo "cp ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt"
cp ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt

while [ ${LOOP} -lt 10 -a -s ${OUTPUTDIR}/${ID}/tmp/diff.all.txt ]
do
	LOOP=`expr ${LOOP} + 1`
	echo Start Loop ${LOOP}
	
	echo "cp ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.bed ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed"
	cp ${OUTPUTDIR}/${ID}/tmp/segment_baf.all.bed ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed
	
	echo "mv ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/result_pre.all.txt"
	mv ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/result_pre.all.txt
	
	# make temporary control signals from control samples
	# calculate temporary signals for CBS
	echo "${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt ${ALL_DEPTH} ${ID} ${OUTPUTDIR}/${ID}/tmp/signal_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/signal_dip.all.txt ${OUTPUTDIR}/${ID}/tmp/control_depth.tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/control_info.tmp.all.txt < ${COMMAND_CNACS}/subscript_target/make_control.R"
	${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt ${ALL_DEPTH} ${ID} ${OUTPUTDIR}/${ID}/tmp/signal_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/signal_dip.all.txt ${OUTPUTDIR}/${ID}/tmp/control_depth.tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/control_info.tmp.all.txt < ${COMMAND_CNACS}/subscript_target/make_control.R
	check_error $?
	
	
	# correct differences in replication timing
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/reptime2depth.pl ${OUTPUTDIR}/${ID}/tmp/signal_tmp.all.txt ${REP_TIME} \
	> ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/reptime2depth.pl ${OUTPUTDIR}/${ID}/tmp/signal_tmp.all.txt ${REP_TIME} \
	> ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.txt
	
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/reptime2depth.pl ${OUTPUTDIR}/${ID}/tmp/signal_dip.all.txt ${REP_TIME} \
	> ${OUTPUTDIR}/${ID}/tmp/reptime2depth_dip.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/reptime2depth.pl ${OUTPUTDIR}/${ID}/tmp/signal_dip.all.txt ${REP_TIME} \
	> ${OUTPUTDIR}/${ID}/tmp/reptime2depth_dip.all.txt
	
	echo "${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.txt ${OUTPUTDIR}/${ID}/tmp/reptime2depth_dip.all.txt ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.txt ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.pdf < ${COMMAND_CNACS}/subscript_target/adjust_reptime.R"
	${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.txt ${OUTPUTDIR}/${ID}/tmp/reptime2depth_dip.all.txt ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.txt ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.pdf < ${COMMAND_CNACS}/subscript_target/adjust_reptime.R
	
	
	# make an input file for CBS (depth)
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input_CBS.pl ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input_CBS.pl ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv
	
	
	# circular binary segmentation (depth)
	echo "${R_PATH} --vanilla --slave --args ${ID} ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.txt ${CBS_ALPHA_DEP} < ${COMMAND_CNACS}/subscript_target/cbs.R"
	${R_PATH} --vanilla --slave --args ${ID} ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.txt ${CBS_ALPHA_DEP} < ${COMMAND_CNACS}/subscript_target/cbs.R
	check_error $?
	
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/seg2bed.pl ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.bed
	check_error $?"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/seg2bed.pl ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.bed
	check_error $?
	
	
	# merge signals of depth and BAF
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/merge_signals.pl ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv \
	> ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/merge_signals.pl ${OUTPUTDIR}/${ID}/tmp/signal_adjusted.all.csv ${OUTPUTDIR}/${ID}/tmp/baf_input.all.csv \
	> ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt
	
	
	# define diploid regions
	if [ ${LOOP} -eq 1 ]; then
		export R_LIBS=${R_LIBS_PATH}
		
		echo "${R_PATH} --vanillla --slave --args ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${OUTPUTDIR}/${ID}/${ID}_diploid_region.high_res.txt < ${COMMAND_CNACS}/subscript_target/define_diploid.R"
		${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${OUTPUTDIR}/${ID}/${ID}_diploid_region.high_res.txt < ${COMMAND_CNACS}/subscript_target/define_diploid.R
		check_error $?
	fi
	
	
	# merge temporary segments
	echo "cat ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.bed >> ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed"
	cat ${OUTPUTDIR}/${ID}/tmp/segment_depth.all.bed >> ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed
	
	echo "${BEDTOOLS_PATH}/sortBed -i ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed | \
	${BEDTOOLS_PATH}/mergeBed -i stdin | \
	${BEDTOOLS_PATH}/intersectBed -a stdin -b ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed -wa -wb | sort -u | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/merge_seg.pl ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/segment_tmp_pre.all.txt"
	${BEDTOOLS_PATH}/sortBed -i ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed | \
	${BEDTOOLS_PATH}/mergeBed -i stdin | \
	${BEDTOOLS_PATH}/intersectBed -a stdin -b ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.bed -wa -wb | sort -u | \
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/merge_seg.pl ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt \
	> ${OUTPUTDIR}/${ID}/tmp/segment_tmp_pre.all.txt
	
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_end.pl ${OUTPUTDIR}/${ID}/tmp/segment_tmp_pre.all.txt ${ID} \
	> ${OUTPUTDIR}/${ID}/tmp/segment_pre.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/proc_end.pl ${OUTPUTDIR}/${ID}/tmp/segment_tmp_pre.all.txt ${ID} \
	> ${OUTPUTDIR}/${ID}/tmp/segment_pre.all.txt
	
	
	# filter candidate CNAs
	echo "${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/segment_pre.all.txt ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.txt < ${COMMAND_CNACS}/subscript_target/filt_cna.R"
	${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/segment_pre.all.txt ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.txt < ${COMMAND_CNACS}/subscript_target/filt_cna.R
	
	
	# depth normalization using depth of diploid regions
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/norm_depth_cnacs.pl ${OUTPUTDIR}/${ID}/${ID}_diploid_region.high_res.txt ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${PAR_BED} ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/summary.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/norm_depth_cnacs.pl ${OUTPUTDIR}/${ID}/${ID}_diploid_region.high_res.txt ${OUTPUTDIR}/${ID}/tmp/segment_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${PAR_BED} ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/summary.all.txt
	check_error $?
	
	# difference from a former loop
	if [ ${LOOP} -gt 1 ]; then
		echo -n > ${OUTPUTDIR}/${ID}/tmp/diff.all.txt
		
		echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/compare_result.pl ${OUTPUTDIR}/${ID}/tmp/result_pre.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt >> ${OUTPUTDIR}/${ID}/tmp/diff.all.txt"
		${PERL_PATH} ${COMMAND_CNACS}/subscript_target/compare_result.pl ${OUTPUTDIR}/${ID}/tmp/result_pre.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt >> ${OUTPUTDIR}/${ID}/tmp/diff.all.txt
		check_error $?
	fi
	
	# make an input file for a next step
	echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input_recursion.pl ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt\
	> ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt"
	${PERL_PATH} ${COMMAND_CNACS}/subscript_target/make_input_recursion.pl ${OUTPUTDIR}/${ID}/tmp/depth_input.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt\
	> ${OUTPUTDIR}/${ID}/tmp/current_depth.all.txt
	check_error $?
done


# additional CNAs
echo "${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/cna_region.all.txt ${OUTPUTDIR}/${ID}/${ID}_scatter_plot.high_res.pdf < ${COMMAND_CNACS}/subscript_target/add_cna.R"
${R_PATH} --vanilla --slave --args ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/cna_region.all.txt ${OUTPUTDIR}/${ID}/${ID}_scatter_plot.high_res.pdf  < ${COMMAND_CNACS}/subscript_target/add_cna.R
check_error $?

echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/add_cna.pl ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/cna_region.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${ID}\
> ${OUTPUTDIR}/${ID}/tmp/result_tmp2.all.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/add_cna.pl ${OUTPUTDIR}/${ID}/tmp/result_tmp.all.txt ${OUTPUTDIR}/${ID}/tmp/cna_region.all.txt ${OUTPUTDIR}/${ID}/tmp/merged_signal.all.txt ${ID}\
> ${OUTPUTDIR}/${ID}/tmp/result_tmp2.all.txt


# additional UPDs
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/add_upd.pl ${OUTPUTDIR}/${ID}/tmp/baf_all.all.txt ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp2.all.txt ${ID} > ${OUTPUTDIR}/${ID}/tmp/result_tmp3.all.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_exome/add_upd.pl ${OUTPUTDIR}/${ID}/tmp/baf_all.all.txt ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp2.all.txt ${ID} > ${OUTPUTDIR}/${ID}/tmp/result_tmp3.all.txt


# final output
echo "${PERL_PATH} ${COMMAND_CNACS}/subscript_target/filt_cna.pl ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp3.all.txt \
> ${OUTPUTDIR}/${ID}/${ID}_result.high_res.txt"
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/filt_cna.pl ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/tmp/result_tmp3.all.txt \
> ${OUTPUTDIR}/${ID}/${ID}_result.high_res.txt


echo "mv ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/${ID}_signal.high_res.txt"
echo "mv ${OUTPUTDIR}/${ID}/tmp/control_info.tmp.all.txt ${OUTPUTDIR}/${ID}/${ID}_control.high_res.txt"
echo "mv ${OUTPUTDIR}/${ID}/tmp/summary.all.txt ${OUTPUTDIR}/${ID}/${ID}_summary.high_res.txt"
echo "mv ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.pdf ${OUTPUTDIR}/${ID}/${ID}_reptime2depth.high_res.pdf"
mv ${OUTPUTDIR}/${ID}/tmp/proc_signal.all.txt ${OUTPUTDIR}/${ID}/${ID}_signal.high_res.txt
mv ${OUTPUTDIR}/${ID}/tmp/control_info.tmp.all.txt ${OUTPUTDIR}/${ID}/${ID}_control.high_res.txt
mv ${OUTPUTDIR}/${ID}/tmp/summary.all.txt ${OUTPUTDIR}/${ID}/${ID}_summary.high_res.txt
mv ${OUTPUTDIR}/${ID}/tmp/reptime2depth.all.pdf ${OUTPUTDIR}/${ID}/${ID}_reptime2depth.high_res.pdf

: <<'#__COMMENT_OUT__'
#__COMMENT_OUT__
