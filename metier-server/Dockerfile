FROM fedora:37 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS download
ARG METIER_REPO="https://github.com/Open-Transactions/metier-server"
ARG METIER_COMMIT="23.0"
RUN mkdir -p /usr/src && git clone --recursive "${METIER_REPO}" /usr/src/metier-server && cd /usr/src/metier-server && git reset --hard "${METIER_COMMIT}"

FROM opentransactions/fedora-devel:1.144.1 AS compile
RUN dnf install -y \
    boost-devel \
    boost-devel \
    cmake \
    gcc-c++ \
    libsodium-devel \
    lmdb-devel \
    ninja-build \
    openssl-devel \
    protobuf-compiler \
    protobuf-lite-devel \
    tbb-devel \
    zeromq-devel \
    zlib-devel

COPY --from=download /usr/src/metier-server /usr/src/metier-server
ARG UNITY_BATCH=0
RUN mkdir -p /tmp/metier-server && cd /tmp/metier-server \
    && cmake \
        -GNinja \
        -DCMAKE_C_FLAGS="-O2" \
        -DCMAKE_CXX_FLAGS="-O2" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_UNITY_BUILD=ON \
        -DCMAKE_UNITY_BUILD_BATCH_SIZE="${UNITY_BATCH}" \
        /usr/src/metier-server \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/metier-server*

FROM opentransactions/fedora:1.144.3 AS run
COPY --from=compile /usr/local/bin/metier-server /usr/bin/metier-server
ENTRYPOINT [ "/usr/bin/metier-server", "--data_dir=/metier" ]
CMD []
