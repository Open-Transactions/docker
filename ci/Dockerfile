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

FROM fedora-git AS iwyu-download
ARG IWYU_COMMIT="aa7c6633218b5ea2a6dbb131448dfd133d600102"
RUN mkdir -p /usr/src && git clone "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}" && git submodule update --init --recursive

FROM fedora-git AS boost-download
ARG BOOST_COMMIT="b7b1371294b4bdfc8d85e49236ebced114bc1d8f"
RUN mkdir -p /usr/src && git clone "https://github.com/boostorg/boost" /usr/src/boost && cd /usr/src/boost && git reset --hard "${BOOST_COMMIT}" && git submodule update --init --recursive

FROM fedora-build AS fedora-iwyu
COPY --from=fedora-git /var/cache/dnf /var/cache/dnf
RUN dnf install -y clang-devel llvm-devel
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN mkdir -p /tmp/iwyu && cd /tmp/iwyu \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/iwyu

FROM fedora-build AS fedora-boost
COPY --from=fedora-git /var/cache/dnf /var/cache/dnf
RUN dnf install -y which
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN cd /usr/src/boost \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM fedora-build AS opentxs-fedora-ci
COPY --from=fedora-iwyu /usr/local /usr/
COPY --from=fedora-boost /usr/local /usr/
RUN ldconfig
COPY ./build-opentxs /usr/bin
COPY ./build-opentxs-clang /usr/bin
COPY ./build-opentxs-gcc /usr/bin
COPY ./test-opentxs /usr/bin
