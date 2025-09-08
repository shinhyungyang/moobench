#!/bin/bash

function runAll {
	start=$(pwd)
	for benchmark in inspectIT-java 
	#OpenTelemetry-java Kieker-java Scouter-java elasticapm-java pinpoint-java
	do
		echo "Running $benchmark"
		runSingle $benchmark 
		# &> "${start}/exponential_${benchmark}.txt"
	done
}

function runSingle {
        benchmark=$1
        cd "${benchmark}"

	RESULTS_DIR="${BASE_DIR}/exp-results"
	checkDirectory RESULTS_DIR "${RESULTS_DIR}" create
	
	for depth in 2 4 8 16 32 64 128
	do
		export RECURSION_DEPTH=$depth
		echo "Running $depth"
		./benchmark.sh &> ${RESULTS_DIR}/$depth.txt
		mv results-$benchmark/results.zip ${RESULTS_DIR}/results-$RECURSION_DEPTH.zip
	done
	
	cd "${start}"
}

if [ -z "$JAVA_HOME" ]
then
    echo "Pinpoint dependencies need JAVA_HOME to be set; please set it before starting all benchmarks"
    exit 1
fi


# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ -f "${BASE_DIR}/../common-functions.sh" ] ; then
	. "${BASE_DIR}/../common-functions.sh"
else
	echo "Missing configuration: ${BASE_DIR}/../common-functions.sh"
	exit 1
fi

if [[ -z "$1" ]]; then
	echo "Usage: $0 <ALL|foldername>"
	exit 1
fi

case "$1" in
	ALL)
		runAll
	;;
	*)
		runSingle "$param"
	;;
esac
