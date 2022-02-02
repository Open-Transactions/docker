FROM fedora:32 AS fedora-base

FROM fedora-base AS fedora-download
RUN dnf install -y git wget

FROM fedora-base AS fedora-build
RUN dnf install -y \
    clang \
    clang-analyzer \
    cmake \
    cppcheck \
    gcc \
    gcc-c++ \
    git \
    gtest-devel \
    libsodium-devel \
    llvm \
    lmdb-devel \
    ninja-build \
    openssl-devel \
    protobuf-compiler \
    protobuf-lite-devel \
    sqlite-devel \
    which \
    zeromq-devel \
    && rm -rf /var/cache/dnf

FROM fedora-download AS iwyu-download
ARG IWYU_COMMIT="aa7c6633218b5ea2a6dbb131448dfd133d600102"
RUN mkdir -p /usr/src && git clone "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}" && git submodule update --init --recursive

FROM fedora-download AS boost-download
ARG BOOST_COMMIT="b7b1371294b4bdfc8d85e49236ebced114bc1d8f"
RUN mkdir -p /usr/src && git clone "https://github.com/boostorg/boost" /usr/src/boost && cd /usr/src/boost && git reset --hard "${BOOST_COMMIT}" && git submodule update --init --recursive

FROM fedora-download AS cmake-download
ARG CMAKE_VERSION="3.22.2"
RUN mkdir -p /usr/src \
    && cd /usr/src \
    && wget -O /usr/src/cmake.tar.gz "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz" \
    && tar -xf cmake.tar.gz \
    && rm cmake.tar.gz \
    && mv "cmake-${CMAKE_VERSION}" cmake

FROM fedora-build AS fedora-iwyu
COPY --from=fedora-download /var/cache/dnf /var/cache/dnf
RUN dnf install -y clang-devel llvm-devel
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN mkdir -p /tmp/iwyu && cd /tmp/iwyu \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/iwyu

FROM fedora-build AS fedora-boost
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN cd /usr/src/boost \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM fedora-build AS fedora-cmake
COPY --from=cmake-download /usr/src/cmake /usr/src/cmake
RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake -GNinja /usr/src/cmake \
    && cmake --build . \
    && cmake --install .

FROM fedora-build AS opentxs-fedora-ci
COPY --from=fedora-iwyu /usr/local /usr/
COPY --from=fedora-boost /usr/local /usr/
COPY --from=fedora-cmake /usr/local /usr/local
RUN ldconfig
COPY ./build-opentxs /usr/bin
COPY ./build-opentxs-clang /usr/bin
COPY ./build-opentxs-gcc /usr/bin
COPY ./test-opentxs /usr/bin
