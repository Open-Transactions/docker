FROM fedora:34 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS opentxs-download
ARG OPENTXS_REPO="https://github.com/open-transactions/opentxs"
ARG OPENTXS_COMMIT="432a8d62c21fd0c91cb0a0044869b95c41fcd337"
RUN mkdir -p /usr/src && git clone "${OPENTXS_REPO}" /usr/src/opentxs && cd /usr/src/opentxs && git reset --hard "${OPENTXS_COMMIT}" && git submodule update --init --recursive

FROM git AS build
RUN dnf install -y \
    gcc \
    gcc-c++ \
    cmake \
    ninja-build \
    gtest-devel \
    protobuf-compiler \
    lmdb-devel \
    protobuf-lite-devel \
    libsodium-devel \
    openssl-devel \
    zeromq-devel \
    boost-devel

FROM build AS compile
COPY --from=opentxs-download /usr/src/opentxs /usr/src/opentxs
ARG TEST_JOBS=2
RUN mkdir -p /tmp/opentxs && cd /tmp/opentxs \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOPENTXS_BUILD_TESTS=OFF -DOT_CRYPTO_SUPPORTED_KEY_RSA=ON -DOT_CASH_USING_LUCRE=ON /usr/src/opentxs \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/opentxs*

FROM base AS run
RUN dnf install -y \
    lmdb \
    protobuf-lite \
    libsodium \
    openssl-libs \
    zeromq \
    boost \
    && rm -rf /var/cache/dnf

FROM run AS opentxs
COPY --from=compile /usr/local/lib64 /usr/lib64
RUN ldconfig

FROM opentxs AS opentxs-devel
COPY --from=compile /usr/include /usr/include
COPY --from=compile /usr/local/include /usr/include
