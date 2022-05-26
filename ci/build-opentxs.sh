#!/bin/bash

C_COMPILER="${1}"
CXX_COMPILER="${2}"
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

if [ "${C_COMPILER}" == "" ]; then
    echo "C compiler not set"
    exit 1
fi

if [ "${CXX_COMPILER}" == "" ]; then
    echo "C++ compiler not set"
    exit 1
fi

set -e
source /var/lib/opentxs-config.sh "${3}"
rm -rf "${WORK}/"*
cd "${WORK}"
/usr/local/bin/cmake \
    -GNinja \
    -DCMAKE_C_COMPILER="${C_COMPILER}" \
    -DCMAKE_CXX_COMPILER="${CXX_COMPILER}" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_SHARED_LIBS=ON \
    -DOT_LUCRE_DEBUG=OFF \
    ${OT_OPTIONS} \
    "${SRC}"
/usr/local/bin/cmake --build . -- -k 0
