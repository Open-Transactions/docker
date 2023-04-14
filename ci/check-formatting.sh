#!/bin/bash

set -e

SRC="/home/src"

if [ ! -d "${SRC}" ]; then
    echo "Source tree missing. Mount opentxs source directory at ${SRC}"
    exit 1
fi

find "${SRC}" \
    -name "*.*pp" \
    -not -path '*/.git/*' \
    -not -path '*/cmake/*' \
    -not -path '*/deps/ChaiScript/*' \
    -not -path '*/deps/SHA1/*' \
    -not -path '*/deps/bech32/*' \
    -not -path '*/deps/cs_libguarded/*' \
    -not -path '*/deps/frozen/*' \
    -not -path '*/deps/irrxml/*' \
    -not -path '*/deps/lucre/*' \
    -not -path '*/deps/packetcrypt/packetcrypt_rs/*' \
    -not -path '*/deps/robin-hood/*' \
    -not -path '*/deps/secp256k1/*' \
    -not -path '*/deps/simpleini/*' \
    -not -path '*/deps/smhasher/*' \
    -not -path '*/deps/unordered_dense/*' \
    -not -path '*/deps/vcpkg/*' \
    -not -path '*/deps/vcpkg_installed/*' \
    -not -path '*/tests/ottest/data/blockchain/ethereum/*' \
    -not -path '*/tests/ottest/data/blockchain/cashtoken/*' \
    -exec clang-format -i {} +
find "${SRC}" \
    -name "*.*json" \
    -not -path '*/.git/*' \
    -not -path '*/cmake/*' \
    -not -path '*/deps/ChaiScript/*' \
    -not -path '*/deps/SHA1/*' \
    -not -path '*/deps/bech32/*' \
    -not -path '*/deps/cs_libguarded/*' \
    -not -path '*/deps/frozen/*' \
    -not -path '*/deps/irrxml/*' \
    -not -path '*/deps/lucre/*' \
    -not -path '*/deps/packetcrypt/packetcrypt_rs/*' \
    -not -path '*/deps/robin-hood/*' \
    -not -path '*/deps/secp256k1/*' \
    -not -path '*/deps/simpleini/*' \
    -not -path '*/deps/smhasher/*' \
    -not -path '*/deps/unordered_dense/*' \
    -not -path '*/deps/vcpkg/*' \
    -not -path '*/deps/vcpkg_installed/*' \
    -not -path '*/tests/ottest/data/blockchain/ethereum/*' \
    -not -path '*/tests/ottest/data/blockchain/cashtoken/*' \
    -exec clang-format -i {} +
find "${SRC}" \
    -name "CMakeLists.txt" \
    -not -path '*/.git/*' \
    -not -path '*/cmake/*' \
    -not -path '*/deps/ChaiScript/*' \
    -not -path '*/deps/SHA1/*' \
    -not -path '*/deps/bech32/*' \
    -not -path '*/deps/cs_libguarded/*' \
    -not -path '*/deps/frozen/*' \
    -not -path '*/deps/lucre/*' \
    -not -path '*/deps/packetcrypt/packetcrypt_rs/*' \
    -not -path '*/deps/robin-hood/*' \
    -not -path '*/deps/secp256k1/*' \
    -not -path '*/deps/simpleini/*' \
    -not -path '*/deps/smhasher/*' \
    -not -path '*/deps/unordered_dense/*' \
    -not -path '*/deps/vcpkg/*' \
    -not -path '*/deps/vcpkg_installed/*' \
    -not -path '*/tests/ottest/data/blockchain/ethereum/*' \
    -not -path '*/tests/ottest/data/blockchain/cashtoken/*' \
    -exec cmake-format -i {} +
find "${SRC}" \
    -name "*.*pp" \
    -not -path '*/.git/*' \
    -not -path '*/cmake/*' \
    -not -path '*/deps/ChaiScript/*' \
    -not -path '*/deps/SHA1/*' \
    -not -path '*/deps/bech32/*' \
    -not -path '*/deps/cs_libguarded/*' \
    -not -path '*/deps/frozen/*' \
    -not -path '*/deps/irrxml/*' \
    -not -path '*/deps/lucre/*' \
    -not -path '*/deps/packetcrypt/packetcrypt_rs/*' \
    -not -path '*/deps/robin-hood/*' \
    -not -path '*/deps/secp256k1/*' \
    -not -path '*/deps/simpleini/*' \
    -not -path '*/deps/smhasher/*' \
    -not -path '*/deps/unordered_dense/*' \
    -not -path '*/deps/vcpkg/*' \
    -not -path '*/deps/vcpkg_installed/*' \
    -not -path '*/tests/ottest/data/blockchain/ethereum/*' \
    -not -path '*/tests/ottest/data/blockchain/cashtoken/*' \
    -exec /usr/bin/fix_includes.py --blank_lines --nocomments --safe_headers --reorder --sort_only {} +

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
