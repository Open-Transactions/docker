FROM fedora:31 AS base

FROM base AS git
RUN dnf install -y git

# Compile the version we use for the android build since the Fedora package does not include ecdh support
FROM git AS libsecp256k1-download
ARG LIBSECP256K1_REPO="https://github.com/bitcoin/secp256k1"
ARG LIBSECP256K1_COMMIT="452d8e4d2a2f9f1b5be6b02e18f1ba102e5ca0b4"
RUN mkdir -p /usr/src && git clone "${LIBSECP256K1_REPO}" /usr/src/secp256k1 && cd /usr/src/secp256k1 && git reset --hard "${LIBSECP256K1_COMMIT}" && git submodule update --init --recursive

FROM git AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="ec61a015c7edc9fd10844c633a0fdacd849d0861"
RUN mkdir -p /usr/src && git clone "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}" && git submodule update --init --recursive

FROM git AS build
RUN dnf install -y gcc gcc-c++ cmake ninja-build boost-devel gtest-devel lmdb-devel protobuf-lite-devel protobuf-compiler libsodium-devel openssl-devel zeromq-devel

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
COPY --from=libsecp256k1 /usr/local /usr/local
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
RUN mkdir -p /tmp/opentxs && cd /tmp/opentxs \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON -DOT_CASH_USING_LUCRE=ON /usr/src/opentxs \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/opentxs*

FROM base AS run
RUN dnf install -y boost lmdb protobuf-lite libsodium openssl-libs zeromq && rm -rf /var/cache/dnf

FROM run AS opentxs
COPY --from=compile /usr/local/lib /usr/lib
COPY --from=compile /usr/local/lib64 /usr/lib64

FROM opentxs AS opentxs-devel
COPY --from=compile /usr/include /usr/include
COPY --from=compile /usr/local/include /usr/include
