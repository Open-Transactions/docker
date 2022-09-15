FROM fedora:34 AS fedora-base

FROM fedora-base AS fedora-download
RUN dnf install -y git bzip2 lzo p7zip wget xz && rm -rf /var/cache/dnf

FROM fedora-base AS fedora-build
RUN dnf install -y \
    boost-devel \
    boost-json \
    clang \
    clang-analyzer \
    cmake \
    cppcheck \
    gcc \
    gcc-c++ \
    git \
    gnutls-devel \
    harfbuzz \
    libicu \
    libpng \
    libsodium-devel \
    llvm \
    lmdb-devel \
    mesa-libGL \
    mesa-libOSMesa \
    msgpack-devel \
    ninja-build \
    openssl-devel \
    protobuf-compiler \
    protobuf-lite-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    sqlite-devel \
    which \
    zeromq-devel \
    && rm -rf /var/cache/dnf

FROM fedora-download AS gtest-download
ARG GTEST_VERSION="release-1.11.0"
RUN mkdir -p /tmp/gtest/
RUN wget -O /tmp/gtest/gtest.tar.gz https://github.com/google/googletest/archive/refs/tags/${GTEST_VERSION}.tar.gz
RUN cd /tmp/gtest && \
    tar -xf "gtest.tar.gz" && \
    rm -f "gtest.tar.gz" && \
    mkdir -p /usr/src && \
    mv googletest-release-* /usr/src/gtest

FROM fedora-download AS iwyu-download
ARG IWYU_COMMIT="78577f2ba2cd6f486bac92be9716e04cf88db92c"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}"

FROM fedora-build AS fedora-gtest
COPY --from=gtest-download /usr/src/gtest /usr/src/gtest
RUN mkdir -p /tmp/gtest
RUN cd /tmp/gtest && \
    cmake -DBUILD_SHARED_LIBS=ON /usr/src/gtest && \
    make install

FROM fedora-build AS fedora-iwyu
RUN dnf install -y clang-devel llvm-devel && rm -rf /var/cache/dnf
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN mkdir -p /tmp/iwyu && cd /tmp/iwyu \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/iwyu

FROM fedora-build AS opentxs-fedora-ci
COPY --from=fedora-gtest /usr/local /usr
COPY --from=fedora-iwyu /usr/local /usr
RUN ldconfig
COPY ./build-opentxs.sh /usr/bin
COPY ./build-opentxs-clang /usr/bin
COPY ./build-opentxs-gcc /usr/bin
COPY ./test-opentxs /usr/bin
COPY ./opentxs-config.sh /var/lib
RUN chmod a+x /usr/bin/build-opentxs.sh
RUN chmod a+x /usr/bin/build-opentxs-clang
RUN chmod a+x /usr/bin/build-opentxs-gcc
RUN chmod a+x /usr/bin/test-opentxs
RUN git config --global --add safe.directory /home/src
