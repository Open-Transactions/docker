FROM fedora:37 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="1.141.0"
RUN mkdir -p /usr/src && git clone --recursive "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}"

FROM git AS build
RUN dnf install -y \
    boost-devel \
    boost-json \
    cmake \
    gcc \
    gcc-c++ \
    libsodium-devel \
    lmdb-devel \
    ninja-build \
    openssl-devel \
    protobuf-compiler \
    protobuf-lite-devel \
    tbb-devel \
    zeromq-devel

FROM build AS compile
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
RUN cmake \
        -S /usr/src/opentxs \
        -B /tmp/opentxs \
        --preset prod \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_C_FLAGS="-O2" \
        -DCMAKE_CXX_FLAGS="-O2 -Wno-error=null-dereference -Wno-error=stringop-overflow=" \
        -DOT_STORAGE_SQLITE=OFF \
        -DOT_WITH_QT=OFF \
    && cmake --build /tmp/opentxs \
    && cmake --install /tmp/opentxs \
    && rm -rf /tmp/opentxs

FROM base AS run
RUN dnf install -y \
    boost \
    boost-json \
    libsodium \
    lmdb \
    openssl-libs \
    protobuf-lite \
    tbb \
    zeromq \
    && rm -rf /var/cache/dnf

FROM run AS opentxs
COPY --from=compile /usr/local/lib64 /usr/lib64
RUN ldconfig

FROM opentxs AS opentxs-devel
COPY --from=compile /usr/include /usr/include
COPY --from=compile /usr/local/include /usr/include
