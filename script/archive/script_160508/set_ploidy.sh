#! /bin/bash
#$ -S /bin/bash
#$ -cwd

write_usage() {
	echo ""
	echo "Usage: `basename $0` [options] <tag of an input directory> <a name of a sample> <region> <ploidy> [<config>]"
	echo ""
}


readonly TAG=$1
readonly ID=$2
readonly TMP_REGION=$3
readonly PLOIDY=$4
CONFIG=$5

DIR=`dirname ${0}`

# confirm right number of arguments
if [ $# -le 3 -o $# -ge 6 ]; then
	echo "wrong number of arguments"
	write_usage
	exit 1
fi

if [ $# -eq 4 ]; then
	CONFIG=${DIR}/../conf/hg19.env
fi

if [ $# -eq 5 ]; then
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

# check whether a region and ploidy are appropriately assigned
REGION=`${PERL_PATH} ${COMMAND_CNACS}/subscript_target/check_region.pl ${TMP_REGION} ${CYTOBAND_DIR}/arm_length.txt`
${PERL_PATH} ${COMMAND_CNACS}/subscript_target/check_ploidy.pl ${PLOIDY}

# check an input directory
readonly OUTPUTDIR=${OUTDIR}/${TAG}
if [ ! -e  ${OUTPUTDIR} ]; then
	echo "${OUTPUTDIR} does not exist"
	write_usage
	exit 1
fi
check_file_exists ${OUTPUTDIR}/config.txt

readonly CONTROL=`head -n 1 ${OUTPUTDIR}/config.txt`
readonly PROBE_BED=`head -n 2 ${OUTPUTDIR}/config.txt | tail -n 1`
check_file_exists ${PROBE_BED}

# check BED files
readonly REP_TIME=${CNACSDIR}/control/${CONTROL}/repli_time.txt
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
readonly ALL_DEPTH=${CNACSDIR}/control/${CONTROL}/stats/all_depth.txt
check_file_exists ${ALL_DEPTH}


# make a log directory
readonly CURLOGDIR=${LOGDIR}/cnacs/${TAG}
check_mkdir ${CURLOGDIR}
readonly LOGSTR=-e\ ${CURLOGDIR}\ -o\ ${CURLOGDIR}


### define job names

# MAIN
readonly SET_PLOIDY=set_ploidy.${TAG}_${ID}
readonly PLOT=plot.${TAG}_${ID}

# MAIN (MEAN DEPTH FOR EACH GENE)
readonly SET_PLOIDY_GENE=set_ploidy_gene.${TAG}_${ID}
readonly PLOT_GENE=plot_gene.${TAG}_${ID}


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

echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -N ${SET_PLOIDY} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/set_ploidy_main.sh ${OUTPUTDIR} ${ID} ${ALL_DEPTH} ${REP_TIME} ${REGION} ${PLOIDY}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=${MEMORY}G,mem_req=${MEMORY}G -N ${SET_PLOIDY} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/set_ploidy_main.sh ${OUTPUTDIR} ${ID} ${ALL_DEPTH} ${REP_TIME} ${REGION} ${PLOIDY}

# draw a plot
echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hold_jid ${SET_PLOIDY} -N ${PLOT} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/plot_adjust.sh ${OUTPUTDIR} ${ID}"
qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hold_jid ${SET_PLOIDY} -N ${PLOT} ${LOGSTR} ${COMMAND_CNACS}/${SUBSCRIPT}/plot_adjust.sh ${OUTPUTDIR} ${ID}

##### END OF MAIN #####



##### MAIN (MEAN DEPTH FOR EACH GENE) #####

if [ ${MODE} == "Exome-seq" ]; then
	
	readonly ALL_DEPTH_GENE=${CNACSDIR}/control/${CONTROL}/stats/all_gene_depth.txt
	check_file_exists ${ALL_DEPTH_GENE}
	
	# filter out low quality probes
	# make appropriate signals for control from control samples
	# calculate signals for CBS
	# perform CBS
	
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=2G,mem_req=2G -N ${SET_PLOIDY_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/set_ploidy_gene.sh ${OUTPUTDIR} ${ID} ${ALL_DEPTH_GENE} ${REP_TIME} ${REGION} ${PLOIDY}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hard -l s_vmem=2G,mem_req=2G -N ${SET_PLOIDY_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/set_ploidy_gene.sh ${OUTPUTDIR} ${ID} ${ALL_DEPTH_GENE} ${REP_TIME} ${REGION} ${PLOIDY}
	
	# draw a plot
	echo "qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hold_jid ${SET_PLOIDY_GENE} -N ${PLOT_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/plot_gene_adjust.sh ${OUTPUTDIR} ${ID}"
	qsub -soft -l ljob,lmem -v CONFIG=${CONFIG} -hold_jid ${SET_PLOIDY_GENE} -N ${PLOT_GENE} ${LOGSTR} ${COMMAND_CNACS}/subscript_exome/plot_gene_adjust.sh ${OUTPUTDIR} ${ID}
fi

##### END OF MAIN (MEAN DEPTH FOR EACH GENE) #####
