# OpenTelemetry specific functions

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi

if [ -z "${BASE_DIR}" ] || [ ! -d $BASE_DIR ]
then
   echo "\$BASE_DIR was empty or not a directory; please set it before calling any function."
fi

function getAgent() {
    if [ ! -d "${BASE_DIR}/pinpoint" ]
    then
        mkdir -p "${BASE_DIR}/pinpoint"
        cd "${BASE_DIR}/pinpoint"
        wget --output-document=pinpoint.tar.gz \
            https://repo1.maven.org/maven2/com/navercorp/pinpoint/pinpoint-agent/3.0.1/pinpoint-agent-3.0.1.tar.gz
        tar -xvf pinpoint.tar.gz
        cd $BASE_DIR
    fi
}

export HBASE_VERSION=2.6.1

function startHBase() {
   echo "Starting HBase $HBASE_VERSION"
   if [ ! -d $BASE_DIR/hbase-$HBASE_VERSION ]
   then
      wget https://dlcdn.apache.org/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz
      tar -xvf hbase-$HBASE_VERSION-bin.tar.gz
   fi

   cd hbase-$HBASE_VERSION
   bin/start-hbase.sh
   
   if [ ! -f hbase-create.hbase ]
   then
      wget https://raw.githubusercontent.com/pinpoint-apm/pinpoint/refs/heads/master/hbase/scripts/hbase-create.hbase
   fi
   
   bin/hbase shell hbase-create.hbase
   
   cd $BASE_DIR
}

function stopHBase(){
   echo "Stopping HBase $HBASE_VERSION"
   cd hbase-$HBASE_VERSION
   bin/stop-hbase.sh
   
   rm tmp -r
   rm logs/*
   rm /tmp/hbase-*
   
   cd $BASE_DIR
}


export KAFKA_VERSION=2.13-3.9.0
function startKafka() {
   if [ ! -d kafka_$KAFKA_VERSION ]
   then
   	wget https://dlcdn.apache.org/kafka/3.9.0/kafka_$KAFKA_VERSION.tgz
   	tar -xvf kafka_$KAFKA_VERSION.tgz
   fi
   cd kafka_$KAFKA_VERSION

   KAFKA_CLUSTER_ID="$(bin/kafka-storage.sh random-uuid)"
   bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c config/kraft/reconfig-server.properties
   bin/kafka-server-start.sh config/kraft/reconfig-server.properties &> ${BASE_DIR}/logs/kafka.log &
   
   echo "Waiting for Kafka start..."
   sleep 3
   bin/kafka-topics.sh --create --topic inspector-stat-agent-00 --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
   bin/kafka-topics.sh --create --topic inspector-stat-app --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
   
   cd $BASE_DIR
}

function stopKafka {
   cd kafka_$KAFKA_VERSION
   bin/kafka-server-stop.sh
   
   rm logs/*
   rm /tmp/kraft-combined-logs/ -rf
   
   cd $BASE_DIR
}


function startPinot() {
   PINOT_VERSION=1.2.0
   echo "Starting Pinot $PINOT_VERSION"
   if [ ! -d apache-pinot-$PINOT_VERSION-bin ]
   then
      wget https://downloads.apache.org/pinot/apache-pinot-$PINOT_VERSION/apache-pinot-$PINOT_VERSION-bin.tar.gz
      tar -zxvf apache-pinot-$PINOT_VERSION-bin.tar.gz
   fi
	
   cd apache-pinot-$PINOT_VERSION-bin
   ./bin/pinot-admin.sh QuickStart -type batch &> ${BASE_DIR}/logs/pinot.log &
   
   sleep 5
   
   cd $BASE_DIR/scripts
   
   ./multi-table.sh 0 1 http://localhost:9000 &> ${BASE_DIR}/logs/pinot_multiTable.log
}

function stopPinot {
   kill -9 $(pgrep -f apache-pinot)
   
   rm /tmp/.pinotAdmin*
   rm /tmp/pinot-* -r
   rm /tmp/PinotMinion
}

function startCollectorAndWeb() {
   PINPOINT_VERSION=3.0.1

   if [ ! -f pinpoint-collector-starter-${PINPOINT_VERSION}-exec.jar ]
   then
      wget https://repo1.maven.org/maven2/com/navercorp/pinpoint/pinpoint-collector-starter/${PINPOINT_VERSION}/pinpoint-collector-starter-${PINPOINT_VERSION}-exec.jar
   fi
   
   java -Dpinpoint.zookeeper.address=localhost -Dpinpoint.modules.realtime.enabled=false -jar pinpoint-collector-starter-${PINPOINT_VERSION}-exec.jar &> ${BASE_DIR}/logs/collector.log &
   
   if [ ! -f pinpoint-web-starter-${PINPOINT_VERSION}-exec.jar ]
   then
      wget https://repo1.maven.org/maven2/com/navercorp/pinpoint/pinpoint-web-starter/${PINPOINT_VERSION}/pinpoint-web-starter-${PINPOINT_VERSION}-exec.jar
   fi
   
   java -Dpinpoint.zookeeper.address=localhost -Dpinpoint.modules.realtime.enabled=false -jar pinpoint-web-starter-${PINPOINT_VERSION}-exec.jar &> ${BASE_DIR}/logs/web-starter.log &
}

function stopCollectorAndWeb() {
   kill -9 $(pgrep -f pinpoint-web-starter)
   kill -9 $(pgrep -f pinpoint-collector-starter)
}

function cleanup {
    sync
    sleep "${SLEEP_TIME}"
}

## Execute Benchmark
function executeBenchmark() {
   for index in $MOOBENCH_CONFIGURATIONS
   do
      case $index in
         0) runNoInstrumentation 0 ;;
         1) runPinpointBasic 1 ;;
      esac
      
      cleanup
   done
}


# experiment setups

function runNoInstrumentation {
    # No instrumentation
    info " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}"
    export BENCHMARK_OPTS="${JAVA_ARGS_NOINSTR}"
    "${MOOBENCH_BIN}" --output-filename "${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv" \
        --total-calls "${TOTAL_NUM_OF_CALLS}" \
        --method-time "${METHOD_TIME}" \
        --total-threads "${THREADS}" \
        --recursion-depth "${RECURSION_DEPTH}" \
        ${MORE_PARAMS} &> "${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
}

function startPinpointServers {
    startHBase
    startPinot
    startKafka
    startCollectorAndWeb
}

function stopPinpointServers {
   stopCollectorAndWeb
   stopKafka
   stopPinot
   stopHBase
}

function setPinpointConfig {
   sed -i 's/DEBUG/INFO/g' pinpoint-agent-3.0.1/log4j2-agent.xml
   sed -i 's|^profiler.pinpoint.base-package=.*|profiler.pinpoint.base-package=moobench.application|' pinpoint-agent-3.0.1/profiles/release/pinpoint.config
   sed -i 's|^profiler.entrypoint=.*|profiler.entrypoint=moobench.application.MonitoredClassSimple.monitoredMethod|' pinpoint-agent-3.0.1/profiles/release/pinpoint.config
   sed -i 's|^profiler.include=.*|profiler.include=moobench.application*|' pinpoint-agent-3.0.1/profiles/release/pinpoint.config
   sed -i 's|^profiler.sampling.counting.sampling-rate=.*|profiler.sampling.counting.sampling-rate=1|' pinpoint-agent-3.0.1/profiles/release/pinpoint.config
}

function runPinpointBasic { 
   k=$1
   info " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
   
   setPinpointConfig
   startPinpointServers
    
   export BENCHMARK_OPTS="${JAVA_ARGS_PINTPOINT_BASIC}"
   "${MOOBENCH_BIN}" --output-filename "${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv" \
        --total-calls "${TOTAL_NUM_OF_CALLS}" \
        --method-time "${METHOD_TIME}" \
        --total-threads "${THREADS}" \
        --recursion-depth "${RECURSION_DEPTH}" \
        ${MORE_PARAMS} &> "${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
   stopPinpointServers
}


# end
