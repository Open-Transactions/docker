FROM fedora:38 AS base

FROM base AS download
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
    bzip2 \
    git \
    lzo \
    p7zip \
    rsync \
    wget \
    xz

FROM download AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="1.167.0"
RUN mkdir -p /usr/src && git clone --recursive "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}"

FROM download AS iwyu-download
ARG IWYU_COMMIT="35fed15e53d92c8c540f0c00ac10077043126c4d"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}"

FROM download AS boost-download
ARG BOOST_MAJOR="1"
ARG BOOST_MINOR="82"
ARG BOOST_PATCH="0"
RUN --mount=type=tmpfs,target=/tmp/download/ cd /tmp/download \
    && wget -O /tmp/download/boost.tar.bz2 "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH}/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.bz2" \
    && tar -xf /tmp/download/boost.tar.bz2 -C /tmp/download \
    && mkdir -p /tmp/download \
    && mv "/tmp/download/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}" /usr/src/boost

FROM download AS build
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
    clang-devel \
    cmake \
    gcc \
    gcc-c++ \
    libsodium-devel \
    llvm-devel \
    lmdb-devel \
    ninja-build \
    openssl-devel \
    protobuf-compiler \
    protobuf-lite-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtsvg-devel \
    tbb-devel \
    zeromq-devel

FROM build AS boost
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN --mount=type=tmpfs,target=/tmp/build rsync -a /usr/src/boost/ /tmp/build/ \
    && cd /tmp/build \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM boost AS compile
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
RUN --mount=type=tmpfs,target=/tmp/opentxs cmake \
        -S /usr/src/opentxs \
        -B /tmp/opentxs \
        --preset prod \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_C_FLAGS="-O2" \
        -DCMAKE_CXX_FLAGS="-O2" \
        -DOT_STORAGE_SQLITE=OFF \
    && cmake --build /tmp/opentxs \
    && cmake --install /tmp/opentxs

FROM base AS run
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
    libsodium \
    lmdb \
    openssl-libs \
    protobuf-lite \
    qt6-qtbase \
    qt6-qtdeclarative \
    qt6-qtsvg \
    tbb \
    zeromq

FROM run AS opentxs
COPY --from=boost /usr/local/lib64 /usr/lib64
COPY --from=compile /usr/local/lib64 /usr/lib64
RUN ldconfig

FROM build AS iwyu
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN --mount=type=tmpfs,target=/tmp/build cd /tmp/build \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install .

FROM opentransactions/ci:37_9 AS ci

FROM build AS opentxs-devel
COPY --from=boost /usr/local /usr/local
COPY --from=compile /usr/local /usr/local
COPY --from=iwyu /usr/local /usr
RUN ldconfig
COPY --from=ci /usr/bin/run-iwyu.sh /usr/bin/run-iwyu.sh
COPY --from=ci /usr/bin/build-opentxs.sh /usr/bin/build-opentxs.sh
