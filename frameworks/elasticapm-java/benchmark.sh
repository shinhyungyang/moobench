#!/bin/bash

#
# Kieker benchmark script
#
# Usage: benchmark.sh

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
MAIN_DIR="${BASE_DIR}/../.."

# Hotfix for ASPECTJ
# https://stackoverflow.com/questions/70411097/instrument-java-17-with-aspectj
JAVA_VERSION=$(java -version 2>&1 | grep version | sed 's/^.* "\([0-9\.]*\).*/\1/g')
if [ "${JAVA_VERSION}" != "1.8.0" ] ; then
	export JAVA_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED"
	echo "Setting \$JAVA_OPTS, since Java version is bigger than 8"
fi

#
# source functionality
#

if [ ! -d "${BASE_DIR}" ] ; then
	echo "Base directory ${BASE_DIR} does not exist."
	exit 1
fi

if [ -f "${MAIN_DIR}/common-functions.sh" ] ; then
	source "${MAIN_DIR}/common-functions.sh"
else
	echo "Missing library: ${MAIN_DIR}/common-functions.sh"
	exit 1
fi

# load configuration and common functions
if [ -f "${BASE_DIR}/config.rc" ] ; then
	source "${BASE_DIR}/config.rc"
else
	echo "Missing configuration: ${BASE_DIR}/config.rc"
	exit 1
fi

if [ -f "${BASE_DIR}/functions.sh" ] ; then
	source "${BASE_DIR}/functions.sh"
else
	echo "Missing: ${BASE_DIR}/functions.sh"
	exit 1
fi
if [ -f "${BASE_DIR}/labels.sh" ] ; then
	source "${BASE_DIR}/labels.sh"
else
	echo "Missing file: ${BASE_DIR}/labels.sh"
	exit 1
fi

if [ -z "$MOOBENCH_CONFIGURATIONS" ]
then
	MOOBENCH_CONFIGURATIONS="0 1 2 3"
	echo "Setting default configuration $MOOBENCH_CONFIGURATIONS"
fi
echo "Running configurations: $MOOBENCH_CONFIGURATIONS"

#
# Setup
#

info "----------------------------------"
info "Setup..."
info "----------------------------------"

cd "${BASE_DIR}"

# load agent
if [ ! -f $AGENT ]
then
	getAgent
fi

checkDirectory data-dir "${DATA_DIR}" create
checkFile log "${DATA_DIR}/kieker.log" clean
cleanupResults
mkdir -p $RESULTS_DIR
PARENT=`dirname "${RESULTS_DIR}"`
checkDirectory result-base "${PARENT}"

checkFile AspectJ-Agent "${AGENT}"

checkExecutable java "${JAVA_BIN}"
checkExecutable moobench "${MOOBENCH_BIN}"
checkFile R-script "${RSCRIPT_PATH}"

showParameter

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
info "Experiment will take circa ${TIME} seconds."

# general server arguments
JAVA_ARGS="-Xms1G -Xmx2G"

LTW_ARGS="-javaagent:elastic-apm-agent.jar"

# JAVA_ARGS used to configure and setup a specific writer
declare -a WRITER_CONFIG
# Receiver setup if necessary
declare -a RECEIVER
# Title
declare -a TITLE

#
# Different writer setups
#

ELASTIC_ARGS="-Delastic.apm.service_name=moobench-benchmark -Delastic.apm.service_name=moobench-benchmark -Delastic.apm.trace_methods=moobench.application.* -Delastic.apm.application_packages=moobench.application -Delastic.apm.server_url=http://127.0.0.1:8200"
WRITER_CONFIG[0]=""
WRITER_CONFIG[1]="-Delastic.apm.recording=false $ELASTIC_ARGS"
WRITER_CONFIG[2]="$ELASTIC_ARGS"
WRITER_CONFIG[3]="-Delastic.apm.sanitize_field_names= $ELASTIC_ARGS"


writeConfiguration
checkMoobenchConfiguration
#
# Run benchmark
#

info "----------------------------------"
info "Running benchmark..."
info "----------------------------------"

for ((i=1;i<=${NUM_OF_LOOPS};i+=1))
do
    info "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >> "${DATA_DIR}/kieker.log"

    executeBenchmark
    printIntermediaryResults "${i}"
done

# Create R labels
LABELS=$(createRLabels)
runStatistics

cleanupResults

mv "${DATA_DIR}/kieker.log" "${RESULTS_DIR}/kieker.log"
[ -f "${RESULTS_DIR}/hotspot-1-${RECURSION_DEPTH}-1.log" ] && grep "<task " "${RESULTS_DIR}/"hotspot-*.log > "${RESULTS_DIR}/java.log"
[ -f "${DATA_DIR}/errorlog.txt" ] && mv "${DATA_DIR}/errorlog.txt" "${RESULTS_DIR}"

checkFile results.yaml "${RESULTS_DIR}/results.yaml"
checkFile results.yaml "${RESULTS_DIR}/results.zip"

info "Done."

exit 0
# end
