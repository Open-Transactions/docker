FROM fedora:32 AS base

FROM base AS git
RUN dnf install -y git

# Compile the version we use for the android build since the distro package does not include ecdh support
FROM git AS libsecp256k1-download
ARG LIBSECP256K1_REPO="https://github.com/bitcoin/secp256k1"
ARG LIBSECP256K1_COMMIT="3e5cfc5c73f856010fe646657703faf8d63e7120"
RUN mkdir -p /usr/src && git clone "${LIBSECP256K1_REPO}" /usr/src/secp256k1 && cd /usr/src/secp256k1 && git reset --hard "${LIBSECP256K1_COMMIT}" && git submodule update --init --recursive

FROM git AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="6b15ec062f6fa5b041721529a0bf98a951cf2309"
RUN mkdir -p /usr/src && git clone "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}" && git submodule update --init --recursive

FROM git AS build
RUN dnf install -y \
    gcc \
    gcc-c++ \
    cmake \
    ninja-build \
    gtest-devel \
    protobuf-compiler \
    boost-devel \
    lmdb-devel \
    protobuf-lite-devel \
    libsodium-devel \
    openssl-devel \
    zeromq-devel

FROM build AS libsecp256k1
RUN dnf install -y autoconf automake file libtool make
COPY --from=libsecp256k1-download /usr/src/secp256k1 /usr/src/secp256k1
RUN cd /usr/src/secp256k1 && ./autogen.sh
RUN mkdir -p /tmp/secp256k1 && cd /tmp/secp256k1 && /usr/src/secp256k1/configure \
        --prefix=/usr/local \
        --disable-static \
        --enable-shared \
        --disable-openssl-tests \
        --enable-experimental \
        --disable-exhaustive-tests \
        --enable-module-ecdh \
        --enable-module-recovery \
        --with-bignum=no \
        --with-asm=no \
        --disable-tests \
        --disable-benchmark \
    && make -j install \
    && rm -rf /tmp/secp256k1

FROM build AS compile
COPY --from=libsecp256k1 /usr/local/include /usr/local/include
COPY --from=libsecp256k1 /usr/local/lib /usr/local/lib64
RUN sed -i s~${exec_prefix}/lib~${exec_prefix}/lib64~ /usr/local/lib64/pkgconfig/libsecp256k1.pc
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
ARG TEST_JOBS=2
RUN mkdir -p /tmp/opentxs && cd /tmp/opentxs \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOPENTXS_BUILD_TESTS=ON -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON -DOT_CASH_USING_LUCRE=ON /usr/src/opentxs \
    && cmake --build . \
    && ctest -j "${TEST_JOBS}" --repeat until-pass:3 --schedule-random \
    && cmake --install . \
    && rm -rf /tmp/opentxs*

FROM base AS run
RUN dnf install -y \
    boost \
    lmdb \
    protobuf-lite \
    libsodium \
    openssl-libs \
    zeromq \
    && rm -rf /var/cache/dnf

FROM run AS opentxs
COPY --from=compile /usr/local/lib64 /usr/lib64
RUN sed -i s~prefix=/usr/local~prefix=/usr~ /usr/lib64/pkgconfig/libsecp256k1.pc
RUN ldconfig

FROM opentxs AS opentxs-devel
COPY --from=compile /usr/include /usr/include
COPY --from=compile /usr/local/include /usr/include
