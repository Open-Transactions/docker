#!/bin/bash

#e.g. "-j 10 --output-on-failure --repeat until-pass:5 --timeout 300 --schedule-random"
CTEST_PARAMS="${1}"
SRC="/home/src"
WORK="/home/output"

if [ ! -d "${SRC}" ]; then
    echo "Source tree missing. Mount opentxs source directory at ${SRC}"
    exit 1
fi

if [ ! -d "${WORK}" ]; then
    echo "Work directory missing. Mount build directory at ${WORK}"
    exit 1
fi

if [ "${CTEST_PARAMS}" == "" ]; then
    echo "ctest params not set"
    exit 1
fi

set -e

cd "${WORK}"

echo ${CTEST_PARAMS}
#cmake --install .  #no need to install
ctest ${CTEST_PARAMS}
