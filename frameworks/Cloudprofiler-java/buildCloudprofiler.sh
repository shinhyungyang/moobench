#!/bin/bash

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
MAIN_DIR="${BASE_DIR}/../.."

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

checkDocker
if [[ $? -eq 1 ]]
then
  checkCPFiles
fi
if [[ $? -eq 1 ]]
then
  CPDependencies
  getDependencies
  getCloudprofiler
fi

cp -pr ${CPLIB} /tmp
#getCMake
