FROM fedora:34 AS base

FROM base AS git
RUN dnf install -y git

FROM git AS download
ARG NOTARY_REPO="https://github.com/Open-Transactions/opentxs-notary"
ARG NOTARY_COMMIT="2305007c5251be6e8f78250653df7d45760eee98"
RUN mkdir -p /usr/src && git clone "${NOTARY_REPO}" /usr/src/opentxs-notary && cd /usr/src/opentxs-notary && git reset --hard "${NOTARY_COMMIT}" && git submodule update --init --recursive

FROM opentransactions/fedora-devel:15 AS compile
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

COPY --from=download /usr/src/opentxs-notary /usr/src/opentxs-notary
RUN mkdir -p /tmp/opentxs-notary && cd /tmp/opentxs-notary \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release /usr/src/opentxs-notary \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/opentxs-notary*

FROM opentransactions/fedora:15 AS run
COPY --from=compile /usr/local/bin/opentxs-notary /usr/bin/opentxs-notary
ENTRYPOINT [ "/usr/bin/opentxs-notary", "--data_dir=/notary" ]
CMD []
