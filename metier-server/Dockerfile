FROM fedora:34 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS download
ARG METIER_REPO="https://github.com/Open-Transactions/metier-server"
ARG METIER_COMMIT="39c911103acb80da82982d18d38aa33a7e72438f"
RUN mkdir -p /usr/src && git clone "${METIER_REPO}" /usr/src/metier-server && cd /usr/src/metier-server && git reset --hard "${METIER_COMMIT}" && git submodule update --init --recursive

FROM opentransactions/fedora-devel:18 AS compile
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

FROM opentransactions/fedora:18 AS run
COPY --from=compile /usr/local/bin/metier-server /usr/bin/metier-server
ENTRYPOINT [ "/usr/bin/metier-server", "--data_dir=/metier" ]
CMD []
