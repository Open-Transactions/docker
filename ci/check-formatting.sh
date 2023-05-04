#!/bin/bash

set -e

SRC="/home/src"
EXCLUDE_FILE="${SRC}/.format-exclude"

if [ ! -d "${SRC}" ]; then
    echo "Source tree missing. Mount source directory at ${SRC}"
    exit 1
fi

CLANG_FORMAT_COMMAND="find ${SRC} \( -name '*.*pp' -o -name '*.json' \)"

if [[ -f "${EXCLUDE_FILE}" ]]; then
    while read p; do
        CLANG_FORMAT_COMMAND="${CLANG_FORMAT_COMMAND} -not -path '${SRC}/${p}/*'"
    done < "${EXCLUDE_FILE}"
fi

CLANG_FORMAT_COMMAND="${CLANG_FORMAT_COMMAND} -exec clang-format -i {} +"

CMAKE_FORMAT_COMMAND="find ${SRC} -name CMakeLists.txt"

if [[ -f "${EXCLUDE_FILE}" ]]; then
    while read p; do
        CMAKE_FORMAT_COMMAND="${CMAKE_FORMAT_COMMAND} -not -path '${SRC}/${p}/*'"
    done < "${EXCLUDE_FILE}"
fi

CMAKE_FORMAT_COMMAND="${CMAKE_FORMAT_COMMAND} -exec cmake-format -i {} +"

FIX_INCLUDES_COMMAND="find ${SRC} -name '*.*pp'"

if [[ -f "${EXCLUDE_FILE}" ]]; then
    while read p; do
        FIX_INCLUDES_COMMAND="${FIX_INCLUDES_COMMAND} -not -path '${SRC}/${p}/*'"
    done < "${EXCLUDE_FILE}"
fi

FIX_INCLUDES_COMMAND="${FIX_INCLUDES_COMMAND} -exec /usr/bin/fix_includes.py --blank_lines --nocomments --safe_headers --reorder --sort_only {} +"

eval "${CLANG_FORMAT_COMMAND}"
eval "${CMAKE_FORMAT_COMMAND}"
eval "${FIX_INCLUDES_COMMAND}"

cd "${SRC}"
output=$(/usr/bin/git --no-pager diff)

if [ -z "$output" ]; then
  echo "Formatting check successful"

  exit 0
else
  echo "Formatting error(s) found:"
  echo "${output}"

  exit 1
fi
