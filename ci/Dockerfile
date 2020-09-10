FROM fedora:32 AS fedora-base

FROM fedora-base AS fedora-git
RUN dnf install -y git

FROM fedora-base AS fedora-build
RUN dnf install -y \
    git \
    gcc \
    gcc-c++ \
    clang \
    cmake \
    ninja-build \
    llvm \
    gtest-devel \
    protobuf-compiler \
    clang-analyzer \
    cppcheck \
    lmdb-devel \
    protobuf-lite-devel \
    libsodium-devel \
    openssl-devel \
    zeromq-devel \
    sqlite-devel \
    && rm -rf /var/cache/dnf

# Compile the version we use for the android build since the distro package does not include ecdh support
FROM fedora-git AS libsecp256k1-download
ARG LIBSECP256K1_REPO="https://github.com/bitcoin/secp256k1"
ARG LIBSECP256K1_COMMIT="3e5cfc5c73f856010fe646657703faf8d63e7120"
RUN mkdir -p /usr/src && git clone "${LIBSECP256K1_REPO}" /usr/src/secp256k1 && cd /usr/src/secp256k1 && git reset --hard "${LIBSECP256K1_COMMIT}" && git submodule update --init --recursive

FROM fedora-git AS lwyu-download
ARG IWYU_COMMIT="aa7c6633218b5ea2a6dbb131448dfd133d600102"
RUN mkdir -p /usr/src && git clone "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}" && git submodule update --init --recursive

FROM fedora-git AS boost-download
ARG BOOST_COMMIT="a7090e8ce184501cfc9e80afa6cafb5bfd3b371c"
RUN mkdir -p /usr/src && git clone "https://github.com/boostorg/boost" /usr/src/boost && cd /usr/src/boost && git reset --hard "${BOOST_COMMIT}" && git submodule update --init --recursive

FROM fedora-build AS fedora-libsecp256k1
COPY --from=fedora-git /var/cache/dnf /var/cache/dnf
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

FROM fedora-build AS fedora-iwyu
COPY --from=fedora-git /var/cache/dnf /var/cache/dnf
RUN dnf install -y clang-devel llvm-devel
COPY --from=lwyu-download /usr/src/iwyu /usr/src/lwyu
RUN mkdir -p /tmp/lwyu && cd /tmp/lwyu \
    && cmake -GNinja /usr/src/lwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/lwyu

FROM fedora-build AS fedora-boost
COPY --from=fedora-git /var/cache/dnf /var/cache/dnf
RUN dnf install -y which
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN cd /usr/src/boost \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM fedora-build AS opentxs-fedora-ci
COPY --from=fedora-libsecp256k1 /usr/local /usr/
COPY --from=fedora-iwyu /usr/local /usr/
COPY --from=fedora-boost /usr/local /usr/
RUN ldconfig
COPY ./build-opentxs /usr/bin
COPY ./build-opentxs-clang /usr/bin
COPY ./build-opentxs-gcc /usr/bin
COPY ./test-opentxs /usr/bin
