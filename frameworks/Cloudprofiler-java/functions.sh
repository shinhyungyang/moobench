# Cloudprofiler specific functions

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi


function prepareFolders() {
  OPT_DIR="/opt"
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

  DEPNAME_CMAKE="CMake"
  DEPVER_CMAKE="3.30.2"
  DEPHOME_CMAKE="${OPT_DIR}/${DEPNAME_CMAKE}/${DEPVER_CMAKE}"

  DEPNAME_LIBZMQ="libzmq"
  DEPVER_LIBZMQ="4.3.4"
  DEPHOME_LIBZMQ="${OPT_DIR}/${DEPNAME_LIBZMQ}/${DEPVER_LIBZMQ}"

  DEPNAME_CPPZMQ="cppzmq"
  DEPVER_CPPZMQ="4.10.0"
  DEPHOME_CPPZMQ="${OPT_DIR}/${DEPNAME_CPPZMQ}/${DEPVER_CPPZMQ}"

  DEPNAME_BISON="bison"
  DEPVER_BISON="3.8.2"
  DEPHOME_BISON="${OPT_DIR}/${DEPNAME_BISON}/${DEPVER_BISON}"

  DEPNAME_SWIG="swig"
  DEPVER_SWIG="4.2.1"
  DEPHOME_SWIG="${OPT_DIR}/${DEPNAME_SWIG}/${DEPVER_SWIG}"

  DEPNAME_BOOST="boost"
  DEPVER_BOOST="1.85.0"
  DEPHOME_BOOST="${OPT_DIR}/${DEPNAME_BOOST}/${DEPVER_BOOST}"

  DEPNAME_SQUASH="squash"
  DEPVER_SQUASH="0.8"
  DEPHOME_SQUASH="${OPT_DIR}/${DEPNAME_SQUASH}/${DEPVER_SQUASH}"
}

function getCMake() {
  CMAKE="cmake"
  if ! command -v "${CMAKE}" > /dev/null 2>&1
  then
    info "Installing CMake.."

    DEPNAME="${DEPNAME_CMAKE}"
    DEPVER="${DEPVER_CMAKE}"
    REPO_DIR="${GITREPOS}/${DEPNAME}"
    INST_DIR="${DEPHOME_CMAKE}"
    MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
    mkdir -p "${INST_DIR}"
    mkdir -p "${MY_BUILD}"
    cd "${GITREPOS}"
    git clone https://github.com/Kitware/${DEPNAME}.git --branch "v${DEPVER}" --depth 1
    cd "${MY_BUILD}"
    ${REPO_DIR}/configure --prefix=${INST_DIR} --parallel=$(nproc)
    make -j$(nproc) install

    CMAKE="${INST_DIR}/bin/cmake"
    cd "${BASE_DIR}"
  else
    CMAKE=`command -v cmake`
  fi
}

function getDependencies() {
  PKG_CONFIG_PATH="/usr/lib/pkgconfig"

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
  ${CMAKE} ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR}
  make -j$(nproc) install
  ZMQ_ROOT="${INST_DIR}"
  PKG_CONFIG_PATH=${INST_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}

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
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH} \
    ${CMAKE} ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR}
  make -j$(nproc) install
  PKG_CONFIG_PATH=${INST_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}

  # bison (swig dependency)
  DEPNAME="${DEPNAME_BISON}"
  DEPVER="${DEPVER_BISON}"
  INST_DIR="${DEPHOME_BISON}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${TARBALLS}"
  wget https://ftpmirror.gnu.org/${DEPNAME}/${DEPNAME}-${DEPVER}.tar.gz
  cd "${EXTRACTS}"
  tar -xf ${TARBALLS}/${DEPNAME}-${DEPVER}.tar.gz
  cd "${MY_BUILD}"
  ${EXTRACTS}/${DEPNAME}-${DEPVER}/configure --prefix=${INST_DIR}
  make -j$(nproc) install
  BISON_ROOT="${INST_DIR}"

  # swig
  DEPNAME="${DEPNAME_SWIG}"
  DEPVER="${DEPVER_SWIG}"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${DEPHOME_SWIG}"
  MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  mkdir -p "${MY_BUILD}"
  cd "${GITREPOS}"
  git clone https://github.com/swig/${DEPNAME}.git --branch "v${DEPVER}" --depth 1
  cd "${MY_BUILD}"
  ${CMAKE} ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR} -DBISON_ROOT=${BISON_ROOT}
  make -j$(nproc) install
  SWIG_ROOT="${INST_DIR}"

  # boost (built in the source directory)
  DEPNAME="${DEPNAME_BOOST}"
  DEPVER="${DEPVER_BOOST}"
  ALTVER="$(echo "${DEPVER}" | tr "." "_")"
  REPO_DIR="${GITREPOS}/${DEPNAME}"
  INST_DIR="${DEPHOME_BOOST}"
  #MY_BUILD="${BASE_DIR}/build/build_release-${DEPNAME}-${DEPVER}"
  mkdir -p "${INST_DIR}"
  #mkdir -p "${MY_BUILD}"
  cd "${TARBALLS}"
  wget https://archives.boost.io/release/${DEPVER}/source/boost_${ALTVER}.tar.gz
  cd "${EXTRACTS}"
  tar -xf ${TARBALLS}/boost_${ALTVER}.tar.gz
  cd "${EXTRACTS}/boost_${ALTVER}"
  ./bootstrap.sh --prefix=${INST_DIR} --with-libraries=atomic,chrono,serialization,system
  ./b2 install -j$(nproc)
  BOOST_ROOT="${INST_DIR}"

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
  ${CMAKE} ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR}
  make -j$(nproc) install
  SQUASH_ROOT="${INST_DIR}"

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
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH} \
    ${CMAKE} ${REPO_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${INST_DIR} \
    -DBOOST_ROOT=${BOOST_ROOT} \
    -DSWIG_ROOT=${SWIG_ROOT} \
    -DSQUASH_ROOT=${SQUASH_ROOT}
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
