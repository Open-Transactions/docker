#!/bin/bash

set -e

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

rm -rf "${WORK}/"*
/usr/local/bin/cmake \
    -S "${SRC}" \
    -B "${WORK}" \
    --preset nopch \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_C_COMPILER="/usr/bin/clang" \
    -DCMAKE_CXX_COMPILER="/usr/bin/clang++" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DOPENTXS_PEDANTIC_BUILD=OFF \
    -DOT_IWYU=ON
/usr/local/bin/cmake \
    --build "${WORK}" \
    -- -k 0 \
    | tee "${WORK}/iwyu.txt"
cd "${SRC}"
/usr/bin/fix_includes.py --blank_lines --nocomments --safe_headers --reorder < "${WORK}/iwyu.txt"

output=$(/usr/bin/git --no-pager diff)

if [ -z "$output" ]; then
  echo "IWYU check successful"

  exit 0
else
  echo "IWYU error(s) found:"
  echo "${output}"

  exit 1
fi
