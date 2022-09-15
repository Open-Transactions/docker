FROM fedora:36 AS fedora-base

FROM fedora-base AS fedora-download
RUN dnf install -y git bzip2 lzo p7zip wget xz && rm -rf /var/cache/dnf

FROM fedora-base AS fedora-build
RUN dnf install -y \
    boost-devel \
    boost-json \
    clang \
    clang-analyzer \
    clang-tools-extra \
    cmake \
    cppcheck \
    findutils \
    gcc \
    gcc-c++ \
    git \
    gmock-devel \
    gtest-devel \
    libsodium-devel \
    lmdb-devel \
    ninja-build \
    openssl-devel \
    pip \
    protobuf-compiler \
    protobuf-lite-devel \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    sqlite-devel \
    tbb-devel \
    which \
    zeromq-devel \
    && rm -rf /var/cache/dnf
RUN pip install cmakelang
RUN git config --global --add safe.directory /home/src

FROM fedora-download AS iwyu-download
ARG IWYU_COMMIT="abd5d2bd6320867d3605227a7f798a4e08fef896"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}"

FROM fedora-build AS fedora-iwyu
RUN dnf install -y clang-devel llvm-devel && rm -rf /var/cache/dnf
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN mkdir -p /tmp/iwyu && cd /tmp/iwyu \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/iwyu

FROM fedora-build AS opentxs-fedora-ci
RUN ln -s /usr/bin/python3 /usr/bin/python
COPY --from=fedora-iwyu /usr/local /usr
RUN ldconfig
COPY ./build-opentxs.sh /usr/bin
COPY ./check-formatting.sh /usr/bin
COPY ./run-iwyu.sh /usr/bin
RUN chmod a+x /usr/bin/build-opentxs.sh
RUN chmod a+x /usr/bin/check-formatting.sh
RUN chmod a+x /usr/bin/run-iwyu.sh
ENTRYPOINT [ "/usr/bin/build-opentxs.sh" ]
CMD []
