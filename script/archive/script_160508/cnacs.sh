#! /bin/bash
#$ -S /bin/bash
#$ -cwd

write_usage() {
	echo ""
	echo "Usage: `basename $0` [options] <tag of an input directory> <tag of control samples> <BED file of probes> [<config>]"
	echo ""
	echo "Options: -r process samples with whole-genome amplification"
	echo ""
}

flg_repliG="FALSE"
while getopts r opt
do
	case ${opt} in
	r) flg_repliG="TRUE";;
	\?)
		echo "invalid option"
		write_usage
		exit 1;;
	esac
done
shift `expr $OPTIND - 1`


readonly TAG=$1
readonly CONTROL=$2
PROBE_BED=$3
CONFIG=$4

DIR=`dirname ${0}`

# confirm right number of arguments
if [ $# -le 2 -o $# -ge 5 ]; then
	echo "wrong number of arguments"
	write_usage
	exit 1
fi

if [ $# -eq 3 ]; then
	CONFIG=${DIR}/../conf/hg19.env
fi

if [ $# -eq 4 ]; then
	if [ ! -f ${CONFIG} ]; then
		echo "${CONFIG} does not exist"
		write_usage
		exit 1
	fi
fi

# change the path name into absolute path
CONF_DIR=`dirname ${CONFIG}`
CONF_DIR=`echo $(cd ${CONF_DIR} && pwd)`
CONF_FILE="${CONFIG##*/}"
CONFIG=${CONF_DIR}/${CONF_FILE}

# import configuration files
source ${CONFIG}
source ${UTIL}

# check BED files
PROBE_DIR=`dirname ${PROBE_BED}`
PROBE_DIR=`echo $(cd ${PROBE_DIR} && pwd)`
PROBE_FILE="${PROBE_BED##*/}"
PROBE_BED=${PROBE_DIR}/${PROBE_FILE}
check_file_exists ${PROBE_BED}

readonly SNP_BED=${CNACSDIR}/control/${CONTROL}/overlapping_snp.bed
readonly REP_TIME=${CNACSDIR}/control/${CONTROL}/repli_time.txt
check_file_exists ${SNP_BED}
check_file_exists ${REP_TIME}

# check format of a BED file
${PERL_PATH} ${COMMAND_CNACS}/subscript_design/check_bed.pl ${PROBE_BED} ${AUTOSOME}

# check a bait size
BAIT_SIZE=`${PERL_PATH} ${COMMAND_CNACS}/subscript_target/bait_size.pl ${PROBE_BED} ${MODE_THRES}`
if [ ${BAIT_SIZE} -lt ${MODE_THRES} ]; then
	MODE=Targeted-seq
	SUBSCRIPT=subscript_target
else
	MODE=Exome-seq
	SUBSCRIPT=subscript_exome
fi
echo "${MODE} mode will be applied."


# check required files
readonly BAIT_FA=${CNACSDIR}/control/${CONTROL}/sequence.fa
readonly BAF_INFO=${CNACSDIR}/control/${CONTROL}/stats/baf_stats.txt
readonly BAF_FACTOR_ALL=${CNACSDIR}/control/${CONTROL}/stats/baf_factor.all.bed
readonly BAF_FACTOR=${CNACSDIR}/control/${CONTROL}/stats/baf_factor.bed
readonly ALL_DEPTH=${CNACSDIR}/control/${CONTROL}/stats/all_depth.txt
check_file_exists ${BAIT_FA}
check_file_exists ${BAF_INFO}
check_file_exists ${BAF_FACTOR_ALL}
check_file_exists ${BAF_FACTOR}
check_file_exists ${ALL_DEPTH}

readonly BAIT_GC=${CNACSDIR}/control/${CONTROL}/bait_gc.txt
if [ ${flg_repliG} = "TRUE" ]; then
	check_file_exists ${BAIT_GC}
fi


# check an input directory
readonly INPUTDIR=${INDIR}/${TAG}

if [ ! -e  ${INPUTDIR} ]; then
	echo "${INPUTDIR} does not exist"
	write_usage
	exit 1
fi

# make an output directory
OUTPUTDIR=${OUTDIR}/${TAG}
check_mkdir ${OUTPUTDIR}

# write information on configuration
echo -n > ${OUTPUTDIR}/config.txt
echo ${CONTROL} >> ${OUTPUTDIR}/config.txt
echo ${PROBE_BED} >> ${OUTPUTDIR}/config.txt
echo ${CONFIG} >> ${OUTPUTDIR}/config.txt


# make a log directory
readonly CURLOGDIR=${LOGDIR}/cnacs/${TAG}
check_mkdir ${CURLOGDIR}
readonly LOGSTR=-e\ ${CURLOGDIR}\ -o\ ${CURLOGDIR}

# collect information on sample names
find ${INPUTDIR} -name "*.bam" | grep -v filt | grep -v org | grep -v rm_dup | grep -v rmdup > ${OUTPUTDIR}/bam_list.txt
FILECOUNT=`wc -l ${OUTPUTDIR}/bam_list.txt | cut -d " " -f 1`


### define job names
# PREPROCESSING
readonly PROC_BAM=proc_bam.${TAG}
readonly DIVIDE_BED=divide_bed.${TAG}

# PROCESSING INFORMATION ON BAF
readonly BAM2HETERO=bam2hetero.${TAG}

# COMPENSATION FOR LOW CAPTURE EFFICIENCY DUE TO MINOR ALLELE
readonly PROBE2SCALE=probe2scale.${TAG}
readonly CORRECT_BAF=correct_baf.${TAG}

# GC BIAS CORRECTION
readonly CORRECT_GC=correct_gc.${TAG}
readonly PLOT_GC=plot_gc.${TAG}

# CORRECTION OF FRAGMENT LENGTH BIAS
readonly COUNT_DUP=count_dup.${TAG}
readonly CORRECT_LENGTH=correct_length.${TAG}

# CORRECTION OF BIAS FROM WGA
readonly CORRECT_WGA=correct_wga.${TAG}

# CALCULATION OF MEAN DEPTH FOR EACH GENE
readonly GENE_DEPTH=gene_depth.${TAG}

# MAIN
readonly CNACS_MAIN=cnacs_main.${TAG}
readonly PLOT=plot.${TAG}

# MAIN (MEAN DEPTH FOR EACH GENE)
readonly CNACS_MAIN_GENE=cnacs_main_gene.${TAG}
readonly PLOT_GENE=plot_gene.${TAG}

# SUMMARIZE
readonly CAT_RESULT=cat_result.${TAG}

##### PREPROCESSING #####

# process BAM files
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=8G,mem_req=8G -N ${PROC_BAM} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/proc_bam.sh ${OUTPUTDIR} ${PROBE_BED}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=8G,mem_req=8G -N ${PROC_BAM} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/proc_bam.sh ${OUTPUTDIR} ${PROBE_BED}


# divide BED files according to fragments' length
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROC_BAM} -N ${DIVIDE_BED} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/divide_bed.sh ${OUTPUTDIR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROC_BAM} -N ${DIVIDE_BED} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/divide_bed.sh ${OUTPUTDIR}

##### END OF PREPROCESSING #####



##### PROCESSING INFORMATION ON BAF #####

# SNP typing
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROC_BAM} -N ${BAM2HETERO} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/bam2hetero.sh ${OUTPUTDIR} ${SNP_BED} ${BAF_INFO}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROC_BAM} -N ${BAM2HETERO} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/bam2hetero.sh ${OUTPUTDIR} ${SNP_BED} ${BAF_INFO}

##### END OF PROCESSING INFORMATION ON BAF #####



##### COMPENSATION FOR LOW CAPTURE EFFICIENCY DUE TO MINOR ALLELES  #####

# decide scaling factors for SNP-overlapping fragments
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${BAM2HETERO} -N ${PROBE2SCALE} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/probe2scale.sh ${OUTPUTDIR} ${BAF_FACTOR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${BAM2HETERO} -N ${PROBE2SCALE} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/probe2scale.sh ${OUTPUTDIR} ${BAF_FACTOR}


# compensate for low capture efficiency of fragments containing minor alleles
for i in `seq 1 4`
do
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROBE2SCALE} -N ${CORRECT_BAF}_${i} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_baf.sh ${OUTPUTDIR} ${PROBE_BED} ${i} ${BAF_FACTOR_ALL}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${PROBE2SCALE} -N ${CORRECT_BAF}_${i} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_baf.sh ${OUTPUTDIR} ${PROBE_BED} ${i} ${BAF_FACTOR_ALL}
done

##### END OF COMPENSATION FOR LOW CAPTURE EFFICIENCY DUE TO MINOR ALLELES  #####



##### GC BIAS CORRECTION #####

if [ ${MODE} == "Targeted-seq" ]; then
	MEMORY=2
else
	MEMORY=5
fi

for i in `seq 1 4`
do
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -hold_jid ${DIVIDE_BED} -N ${CORRECT_GC}_${i} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/correct_gc.sh ${OUTPUTDIR} ${PROBE_BED} ${i} ${BAIT_FA}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -hold_jid ${DIVIDE_BED} -N ${CORRECT_GC}_${i} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/correct_gc.sh ${OUTPUTDIR} ${PROBE_BED} ${i} ${BAIT_FA}
done

echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${CORRECT_GC}_1,${CORRECT_GC}_2,${CORRECT_GC}_3,${CORRECT_GC}_4 -N ${PLOT_GC} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/plotGC.sh ${OUTPUTDIR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${CORRECT_GC}_1,${CORRECT_GC}_2,${CORRECT_GC}_3,${CORRECT_GC}_4 -N ${PLOT_GC} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/plotGC.sh ${OUTPUTDIR}

##### END OF GC BIAS CORRECTION #####



##### CORRECTION OF FRAGMENT LENGTH BIAS #####

# count %duplicate for fragments with binned length
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${PROC_BAM} -N ${COUNT_DUP} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/count_dup.sh ${OUTPUTDIR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${PROC_BAM} -N ${COUNT_DUP} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/count_dup.sh ${OUTPUTDIR}


# correct fragment length bias
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${CORRECT_BAF}_1,${CORRECT_BAF}_2,${CORRECT_BAF}_3,${CORRECT_BAF}_4,${CORRECT_GC}_1,${CORRECT_GC}_2,${CORRECT_GC}_3,${CORRECT_GC}_4,${COUNT_DUP} -N ${CORRECT_LENGTH} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_length.sh ${OUTPUTDIR} ${PROBE_BED}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=1G,mem_req=1G -hold_jid ${CORRECT_BAF}_1,${CORRECT_BAF}_2,${CORRECT_BAF}_3,${CORRECT_BAF}_4,${CORRECT_GC}_1,${CORRECT_GC}_2,${CORRECT_GC}_3,${CORRECT_GC}_4,${COUNT_DUP} -N ${CORRECT_LENGTH} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_length.sh ${OUTPUTDIR} ${PROBE_BED}

##### END OF FRAGMENT LENGTH BIAS CORRECTION #####



##### CORRECTION OF BIAS FROM WGA #####

if [ ${flg_repliG} = "TRUE" ]; then
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=2G,mem_req=2G -hold_jid ${CORRECT_LENGTH} -N ${CORRECT_WGA} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_wga.sh ${OUTPUTDIR} ${BAIT_GC}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=2G,mem_req=2G -hold_jid ${CORRECT_LENGTH} -N ${CORRECT_WGA} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/correct_wga.sh ${OUTPUTDIR} ${BAIT_GC}
fi

##### END OF CORRECTION OF BIAS FROM WGA #####



##### CALCULATION OF MEAN DEPTH FOR EACH GENE #####

if [ ${MODE} == "Exome-seq" ]; then
	GENE_BED=${PROBE_DIR}/gene2exon.bed
	check_file_exists ${GENE_BED}
	
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=4G,mem_req=4G -hold_jid ${CORRECT_LENGTH},${CORRECT_WGA} -N ${GENE_DEPTH} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/gene_depth.sh ${OUTPUTDIR} ${GENE_BED}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=4G,mem_req=4G -hold_jid ${CORRECT_LENGTH},${CORRECT_WGA} -N ${GENE_DEPTH} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/gene_depth.sh ${OUTPUTDIR} ${GENE_BED}
fi

##### END OF MEAN DEPTH CALCULATION #####



##### MAIN #####

# filter out low quality probes
# make appropriate signals for control from control samples
# calculate signals for CBS
# perform CBS

if [ ${MODE} == "Targeted-seq" ]; then
	MEMORY=2
else
	MEMORY=8
fi

echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -hold_jid ${CORRECT_LENGTH},${CORRECT_WGA} -N ${CNACS_MAIN} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/cnacs_main.sh ${OUTPUTDIR} ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH} ${REP_TIME}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -hold_jid ${CORRECT_LENGTH},${CORRECT_WGA} -N ${CNACS_MAIN} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/cnacs_main.sh ${OUTPUTDIR} ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH} ${REP_TIME}


# draw a plot
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hold_jid ${CNACS_MAIN} -N ${PLOT} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/plot.sh ${OUTPUTDIR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hold_jid ${CNACS_MAIN} -N ${PLOT} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/plot.sh ${OUTPUTDIR}

##### END OF MAIN #####



##### MAIN (MEAN DEPTH FOR EACH GENE) #####

if [ ${MODE} == "Exome-seq" ]; then
	
	readonly ALL_DEPTH_GENE=${CNACSDIR}/control/${CONTROL}/stats/all_gene_depth.txt
	check_file_exists ${ALL_DEPTH_GENE}
	
	# filter out low quality probes
	# make appropriate signals for control from control samples
	# calculate signals for CBS
	# perform CBS
	
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=2G,mem_req=2G -hold_jid ${GENE_DEPTH} -N ${CNACS_MAIN_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/cnacs_main_gene.sh ${OUTPUTDIR} ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH_GENE} ${REP_TIME}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hard -l s_vmem=2G,mem_req=2G -hold_jid ${GENE_DEPTH} -N ${CNACS_MAIN_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/cnacs_main_gene.sh ${OUTPUTDIR} ${BAF_INFO} ${BAF_FACTOR} ${BAF_FACTOR_ALL} ${ALL_DEPTH_GENE} ${REP_TIME}
	
	
	# draw a plot
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hold_jid ${CNACS_MAIN_GENE} -N ${PLOT_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/plot_gene.sh ${OUTPUTDIR}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -t 1-${FILECOUNT}:1 -hold_jid ${CNACS_MAIN_GENE} -N ${PLOT_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/plot_gene.sh ${OUTPUTDIR}
fi


##### END OF MAIN (MEAN DEPTH FOR EACH GENE) #####



##### SUMMARIZATION #####

echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${CNACS_MAIN},${CNACS_MAIN_GENE} -N ${CAT_RESULT} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/cat_result.sh ${OUTPUTDIR}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=0.5G,mem_req=0.5G -hold_jid ${CNACS_MAIN},${CNACS_MAIN_GENE} -N ${CAT_RESULT} ${LOGSTR} ${COMMAND_CNACS}/subscript_target/cat_result.sh ${OUTPUTDIR}

##### END OF SUMMARIZATION #####
