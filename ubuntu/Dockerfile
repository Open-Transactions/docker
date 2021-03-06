FROM ubuntu:20.04 AS base

FROM base AS git
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -qq install git

# Compile the version we use for the android build since the distro package does not include ecdh support
FROM git AS libsecp256k1-download
ARG LIBSECP256K1_REPO="https://github.com/bitcoin/secp256k1"
ARG LIBSECP256K1_COMMIT="3e5cfc5c73f856010fe646657703faf8d63e7120"
RUN mkdir -p /usr/src && git clone "${LIBSECP256K1_REPO}" /usr/src/secp256k1 && cd /usr/src/secp256k1 && git reset --hard "${LIBSECP256K1_COMMIT}" && git submodule update --init --recursive

FROM git AS boost-download
ARG BOOST_COMMIT="a7090e8ce184501cfc9e80afa6cafb5bfd3b371c"
RUN mkdir -p /usr/src && git clone "https://github.com/boostorg/boost" /usr/src/boost && cd /usr/src/boost && git reset --hard "${BOOST_COMMIT}" && git submodule update --init --recursive

FROM git AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="c4d5a89f65fe91199c63be040fff927fbb8aa3d2"
RUN mkdir -p /usr/src && git clone "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}" && git submodule update --init --recursive

FROM git AS build
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install \
    gcc-10 \
    g++-10 \
    cmake \
    ninja-build \
    libgtest-dev \
    protobuf-compiler \
    liblmdb-dev \
    libprotobuf-dev \
    libsodium-dev \
    libssl-dev \
    libzmq3-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10 --slave /usr/bin/gcov gcov /usr/bin/gcov-10

FROM build AS libsecp256k1
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install autoconf automake file libtool make
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

FROM build AS boost
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN cd /usr/src/boost \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM build AS compile
COPY --from=libsecp256k1 /usr/local /usr/local
COPY --from=boost /usr/local /usr/
RUN ldconfig
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
ARG TEST_JOBS=2
RUN mkdir -p /tmp/opentxs && cd /tmp/opentxs \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOPENTXS_BUILD_TESTS=ON -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON -DOT_CASH_USING_LUCRE=ON /usr/src/opentxs \
    && cmake --build . \
    && ctest -j "${TEST_JOBS}" --repeat until-pass:3 --schedule-random \
    && cmake --install . \
    && rm -rf /tmp/opentxs*

FROM base AS run
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
    liblmdb0 \
    libprotobuf-lite17 \
    libsodium23 \
    libssl1.1 \
    libzmq5 \
    && rm -rf /var/lib/apt/lists/*

FROM run AS opentxs
COPY --from=compile /usr/local/lib /usr/lib
RUN sed -i s~prefix=/usr/local~prefix=/usr~ /usr/lib/pkgconfig/libsecp256k1.pc
RUN ldconfig

FROM opentxs AS opentxs-devel
COPY --from=compile /usr/include /usr/include
COPY --from=compile /usr/local/include /usr/include
