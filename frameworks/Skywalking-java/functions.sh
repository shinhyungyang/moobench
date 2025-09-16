# Kieker specific functions

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi

# Skywalking Java Agent version
AGENT_VERSION="9.5.0"
# Skywalking APM version
APM_VERSION="10.2.0"
# Gets the skywalking agent and APM server
# Commented code uses archive.apache.org which is too slow for Github actions but should be always available.
# The dlcdn.apache.org is much faster but only available for the latest version.
function getAgent {
	mkdir "${BASE_DIR}/skywalking-agent"
	cd "${BASE_DIR}"
  #wget https://archive.apache.org/dist/skywalking/java-agent/${AGENT_VERSION}/apache-skywalking-java-agent-${AGENT_VERSION}.tgz
	wget https://dlcdn.apache.org/skywalking/java-agent/${AGENT_VERSION}/apache-skywalking-java-agent-${AGENT_VERSION}.tgz
	tar -xvzf apache-skywalking-java-agent-${AGENT_VERSION}.tgz
	cp "${BASE_DIR}/skywalking-agent/optional-plugins/apm-customize-enhance-plugin-9.5.0.jar" "${BASE_DIR}/skywalking-agent/plugins/"
	#wget https://archive.apache.org/dist/skywalking/${APM_VERSION}/apache-skywalking-apm-${APM_VERSION}.tar.gz
	wget https://dlcdn.apache.org/skywalking/${APM_VERSION}/apache-skywalking-apm-${APM_VERSION}.tar.gz
	tar -xvzf apache-skywalking-apm-${APM_VERSION}.tar.gz
	cd "${BASE_DIR}"
}

function startSkywalkingServer {
	cd "${BASE_DIR}/apache-skywalking-apm-bin/bin"
	./oapService.sh &
	cd "${BASE_DIR}"
	sleep 10
}

function stopSkywalkingServer {
	pkill -f skywalking
	sleep 3
}



function executeBenchmark {
    for index in $MOOBENCH_CONFIGURATIONS
   	do
      	runExperiment $index
    done
}


function runExperiment {
    # No instrumentation
    k=$1
    info " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}"
    if [[ "$k" -gt 0 ]]
    then
	    startSkywalkingServer
    fi
    export BENCHMARK_OPTS="${SKYWALKING_CONFIG[$k]}"
    "${MOOBENCH_BIN}" \
	--output-filename "${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv" \
        --total-calls "${TOTAL_NUM_OF_CALLS}" \
        --method-time "${METHOD_TIME}" \
        --total-threads "${THREADS}" \
        --recursion-depth "${RECURSION_DEPTH}" \
        ${MORE_PARAMS} &> "${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
    if [[ "$k" -gt 0 ]]
    then
	    stopSkywalkingServer
    fi
}
