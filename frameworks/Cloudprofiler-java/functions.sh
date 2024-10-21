# Cloudprofiler specific functions

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi


function checkOSVersion() {
  VENV_DIR="${HOME}/venv/query-distro"
  python3 -m venv ${VENV_DIR}
  source ${VENV_DIR}/bin/activate
  pip install --upgrade pip distro
  OS_VER=$(python3 <<< 'import distro ; print("{0} {1}".format(distro.id(), distro.version()))')
  deactivate
}

function prepareFolders() {
  OPT_DIR="${BASE_DIR}/opt"
  TARBALLS="${BASE_DIR}/build/tarballs"
  EXTRACTS="${BASE_DIR}/build/extracts"
  GITREPOS="${BASE_DIR}/build/gitrepos"
  mkdir -p "${OPT_DIR}"
  mkdir -p "${TARBALLS}"
  mkdir -p "${EXTRACTS}"
  mkdir -p "${GITREPOS}"
}

function CPDependencies() {
  prepareFolders

  DEPNAME_CP="cloud_profiler"
  DEPVER_CP="0.3.2"
  DEPHOME_CP="${OPT_DIR}/${DEPNAME_CP}/${DEPVER_CP}"

  DEPNAME_LIBZMQ="libzmq"
  DEPVER_LIBZMQ="4.3.4"
  DEPHOME_LIBZMQ="${OPT_DIR}/${DEPNAME_LIBZMQ}/${DEPVER_LIBZMQ}"

  DEPNAME_CPPZMQ="cppzmq"
  DEPVER_CPPZMQ="4.10.0"
  DEPHOME_CPPZMQ="${OPT_DIR}/${DEPNAME_CPPZMQ}/${DEPVER_CPPZMQ}"

  DEPNAME_SQUASH="squash"
  DEPVER_SQUASH="0.8"
  DEPHOME_SQUASH="${OPT_DIR}/${DEPNAME_SQUASH}/${DEPVER_SQUASH}"
}

function getDependencies() {
  PKG_CONFIG_PATH="/usr/lib/pkgconfig"
  PKG_LIST=""

  case "${OS_VER}" in
    "fedora 40")
      PKG_LIST="boost-devel cmake cppzmq-devel gcc-c++ papi-devel pkgconf swig"
      sudo dnf -y install "${PKG_LIST}"
      ;;
    "debian 12")
      PKG_LIST="libboost-all-dev cmake cppzmq-dev g++ libpapi-dev pkgconf swig"
      sudo apt -y install "${PKG_LIST}"
      ;;
    "ubuntu 22.04")
      buildZeroMQ
      PKG_LIST="libboost-all-dev cmake g++ libpapi-dev pkgconf swig"
      sudo apt -y install "${PKG_LIST}"
      ;;
    "ubuntu 24.04")
      PKG_LIST="libboost-all-dev cmake cppzmq-dev g++ libpapi-dev pkgconf swig"
      sudo apt -y install "${PKG_LIST}"
      ;;
    *)
      >&2 echo "Could not resolve distribution information"
      exit 1
      ;;
  esac

  # squash compression benchmark
  DEPNAME="${DEPNAME_SQUASH}"
  DEPVER="${DEPVER_SQUASH}"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${DEPHOME_SQUASH}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${GITREPOS}"
  git clone https://github.com/shinhyungyang/${DEPNAME}.git --depth 1 --recursive
  cd "${MY_BUILD}"
  cmake ${REPO_DIR}
  make -j$(nproc) install
  SQUASH_ROOT="${INST_DIR}"

  cd "${BASE_DIR}"
}

function buildZeroMQ() {
  # libzmq
  DEPNAME="${DEPNAME_LIBZMQ}"
  DEPVER="${DEPVER_LIBZMQ}"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${DEPHOME_LIBZMQ}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${GITREPOS}"
  git clone https://github.com/zeromq/${DEPNAME}.git --branch "v${DEPVER}" --depth 1
  cd "${MY_BUILD}"
  cmake ${REPO_DIR}
  make -j$(nproc) install

  # cppzmq
  DEPNAME="${DEPNAME_CPPZMQ}"
  DEPVER="${DEPVER_CPPZMQ}"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${DEPHOME_CPPZMQ}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${GITREPOS}"
  git clone https://github.com/zeromq/${DEPNAME}.git --branch "v${DEPVER}" --depth 1
  cd "${MY_BUILD}"
  cmake ${REPO_DIR}
  make -j$(nproc) install

  cd "${BASE_DIR}"
}

function getCloudprofiler() {
  DEPNAME="${DEPNAME_CP}"
  DEPVER="${DEPVER_CP}"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${OPT_DIR}/${DEPNAME}/${DEPVER}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${GITREPOS}"
  git clone https://github.com/shinhyungyang/${DEPNAME}.git --branch "moobench-ci" --depth 1
  cd "${MY_BUILD}"
  cmake ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR}
  make -j$(nproc) install
}

function checkCPFiles() {
  CPLIB_DIR="${OPT_DIR}/${DEPNAME_CP}/${DEPVER_CP}/lib"
  CPLIB="${CPLIB_DIR}/lib${DEPNAME_CP}.so"
  CPJAR="${CPLIB_DIR}/${DEPNAME_CP}JNI.jar"
  CPNET="${CPLIB_DIR}/libnet_conf.so"

  if [ \( -f "${CPLIB}" -a -f "${CPJAR}" -a -f "${CPNET}" \) ]
  then
    echo "Cloudprofiler is available."
    exit 0
  fi
}

# experiment setups

#################################
# function: execute an experiment
#
# $1 = i iterator
# $2 = j iterator
# $3 = k iterator
# $4 = title
# $5 = writer parameters
function executeExperiment() {
    loop="$1"
    recursion="$2"
    index="$3"
    title="${TITLE[$index]}"

    info " # ${loop}.${recursion}.${index} ${title}"
    echo " # ${loop}.${recursion}.${index} ${title}" >> "${DATA_DIR}/Cloudprofiler.log"

    if [  "${CONF_SERVER[$index]}" == "" ] ; then
       export BENCHMARK_OPTS="${JAVA_ARGS}"
    else
       export BENCHMARK_OPTS="${JAVA_ARGS} ${CP_ARGS}"
    fi

    debug "Run options: ${BENCHMARK_OPTS}"

    RESULT_FILE="${RAWFN}-${loop}-${recursion}-${index}.csv"
    LOG_FILE="${RESULTS_DIR}/output_${loop}_${RECURSION_DEPTH}_${index}.txt"


    if [ $index == 0 ]
    then
      application=moobench.application.MonitoredClassSimple
      APP_HOME=../../benchmark
      CLASSPATH=$APP_HOME/lib/benchmark.jar:$APP_HOME/lib/jcommander-1.72.jar
    else
      application=moobench.application.MonitoredClassInstrumented
      APP_HOME=../../benchmark-cp-instrumented
      CLASSPATH=${DEPHOME_CP}/lib/cloud_profilerJNI.jar:$APP_HOME/lib/benchmark-cp-instrumented.jar:$APP_HOME/lib/jcommander-1.72.jar:$APP_HOME/lib/jctools-core-3.3.0.jar:$APP_HOME/lib/slf4j-api-1.7.30.jar
    fi

    ps -aef | grep "[c]onfig_server --cnf" >/dev/null 2>&1
    [ ${?} = "0" ] && {
      kill $(ps -aef | grep "[c]onfig_server --cnf" | tr -s " " | cut -d" " -f2)
    }

    if [ $index != 0 ]
    then
    LD_LIBRARY_PATH=${DEPHOME_CP}/lib \
      ${DEPHOME_CP}/bin/config_server \
      --cnf "${CONF_SERVER[$index]}" &
    fi

    LD_LIBRARY_PATH=${DEPHOME_CP}/lib \
    java $BENCHMARK_OPTS -cp $CLASSPATH \
      moobench.benchmark.BenchmarkMain \
      --application $application \
      --output-filename "${RESULT_FILE}" \
      --total-calls "${TOTAL_NUM_OF_CALLS}" \
      --method-time "${METHOD_TIME}" \
      --total-threads $THREADS \
      --recursion-depth "${recursion}" &> "${LOG_FILE}"

    if [ ! -f "${RESULT_FILE}" ] ; then
        info "---------------------------------------------------"
        cat "${LOG_FILE}"
        error "Result file '${RESULT_FILE}' is empty."
    else
       size=`wc -c "${RESULT_FILE}" | awk '{ print $1 }'`
       if [ "${size}" == "0" ] ; then
           info "---------------------------------------------------"
           cat "${LOG_FILE}"
           error "Result file '${RESULT_FILE}' is empty."
       fi
    fi

    if [ $index != 0 ]
    then
      for f in /tmp/{cloud_profiler,conf_server}*txt
      do
        FNAME="${f##*/}"
        mv "${f}" "${DATA_DIR}/${FNAME%.txt}-${loop}-${recursion}-${index}.txt"
      done
    fi

    rm -rf "${DATA_DIR}"/{cloud_profiler,config_server}*.txt

    [ -f "${DATA_DIR}/hotspot.log" ] && mv "${DATA_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${loop}-${recursion}-${index}.log"
    echo >> "${DATA_DIR}/Cloudprofiler.log"
    echo >> "${DATA_DIR}/Cloudprofiler.log"

    sync
    sleep "${SLEEP_TIME}"
}

function executeBenchmarkBody() {
  index="$1"
  loop="$2"
  recursion="$3"

  executeExperiment "$loop" "$recursion" "$index"

  if [[ "${RECEIVER_PID}" ]] ; then
     kill -TERM "${RECEIVER_PID}"
     unset RECEIVER_PID
  fi
}

## Execute Benchmark
function executeBenchmark() {
    recursion="${RECURSION_DEPTH}"

    for index in $MOOBENCH_CONFIGURATIONS
    do
      executeBenchmarkBody $index $i $recursion
    done
}


# end
