FROM fedora:33 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS download
ARG METIER_REPO="https://github.com/justusranvier/otblockchain"
ARG METIER_COMMIT="c43be765270ac6e9a8e772ff9584d00d636f49eb"
RUN mkdir -p /usr/src && git clone "${METIER_REPO}" /usr/src/metier-server && cd /usr/src/metier-server && git reset --hard "${METIER_COMMIT}" && git submodule update --init --recursive

FROM opentransactions/fedora-devel:10 AS compile
RUN dnf install -y \
    gcc-c++ \
    cmake \
    ninja-build \
    boost-devel \
    protobuf-compiler \
    lmdb-devel \
    protobuf-lite-devel \
    libsodium-devel \
    openssl-devel \
    zeromq-devel \
    boost-devel \
    zlib-devel

COPY --from=download /usr/src/metier-server /usr/src/metier-server
RUN mkdir -p /tmp/metier-server && cd /tmp/metier-server \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release /usr/src/metier-server \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/metier-server*

FROM opentransactions/fedora:10 AS run
COPY --from=compile /usr/local/bin/otblockchain /usr/bin/metier-server
ENTRYPOINT [ "/usr/bin/metier-server", "--data_dir=/metier" ]
CMD []
