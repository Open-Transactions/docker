FROM fedora:38 AS fedora-base

FROM fedora-base AS fedora-download
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
    git \
    bzip2 \
    lzo \
    p7zip \
    wget \
    xz

FROM fedora-base AS fedora-build
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
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
    rsync \
    sqlite-devel \
    tbb-devel \
    which \
    zeromq-devel
RUN pip install cmakelang
RUN git config --global --add safe.directory '*'

FROM fedora-download AS iwyu-download
ARG IWYU_COMMIT="35fed15e53d92c8c540f0c00ac10077043126c4d"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}"

FROM fedora-download AS boost-download
ARG BOOST_MAJOR="1"
ARG BOOST_MINOR="82"
ARG BOOST_PATCH="0"
RUN --mount=type=tmpfs,target=/tmp/download/ cd /tmp/download \
    && wget -O /tmp/download/boost.tar.bz2 "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH}/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.bz2" \
    && tar -xf /tmp/download/boost.tar.bz2 -C /tmp/download \
    && mkdir -p /tmp/download \
    && mv "/tmp/download/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}" /usr/src/boost

FROM fedora-build AS fedora-iwyu
RUN --mount=type=tmpfs,target=/var/cache/dnf dnf install -y \
    clang-devel \
    llvm-devel
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN --mount=type=tmpfs,target=/tmp/build cd /tmp/build \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install .

FROM fedora-build AS fedora-boost
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN --mount=type=tmpfs,target=/tmp/build rsync -a /usr/src/boost/ /tmp/build/ \
    && cd /tmp/build \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM fedora-build AS opentxs-fedora-ci
RUN ln -s /usr/bin/python3 /usr/bin/python
COPY --from=fedora-iwyu /usr/local /usr
COPY --from=fedora-boost /usr/local /usr
RUN ldconfig
COPY ./build-opentxs.sh /usr/bin
COPY ./check-formatting.sh /usr/bin
COPY ./run-iwyu.sh /usr/bin
RUN chmod a+x /usr/bin/build-opentxs.sh
RUN chmod a+x /usr/bin/check-formatting.sh
RUN chmod a+x /usr/bin/run-iwyu.sh
ENTRYPOINT [ "/usr/bin/build-opentxs.sh" ]
CMD []
