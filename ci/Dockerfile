FROM fedora:32 AS fedora-base

FROM fedora-base AS fedora-download
RUN dnf install -y git bzip2 lzo p7zip wget xz && rm -rf /var/cache/dnf

FROM fedora-base AS fedora-build
RUN dnf install -y \
    clang \
    clang-analyzer \
    cmake \
    cppcheck \
    gcc \
    gcc-c++ \
    git \
    gnutls-devel \
    gtest-devel \
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
    sqlite-devel \
    which \
    zeromq-devel \
    && rm -rf /var/cache/dnf

FROM fedora-download AS iwyu-download
ARG IWYU_COMMIT="aa7c6633218b5ea2a6dbb131448dfd133d600102"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/include-what-you-use/include-what-you-use" /usr/src/iwyu && cd /usr/src/iwyu && git reset --hard "${IWYU_COMMIT}"

FROM fedora-download AS boost-download
ARG BOOST_MAJOR="1"
ARG BOOST_MINOR="75"
ARG BOOST_PATCH="0"
RUN mkdir -p /usr/src \
    && wget -O /usr/src/boost.tar.bz2 "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH}/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}.tar.bz2" \
    && tar -xf /usr/src/boost.tar.bz2 -C /usr/src \
    && rm /usr/src/boost.tar.bz2 \
    && mv "/usr/src/boost_${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}" /usr/src/boost

FROM fedora-download AS cmake-download
ARG CMAKE_VERSION="3.22.2"
RUN mkdir -p /usr/src \
    && cd /usr/src \
    && wget -O /usr/src/cmake.tar.gz "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz" \
    && tar -xf cmake.tar.gz \
    && rm cmake.tar.gz \
    && mv "cmake-${CMAKE_VERSION}" cmake

FROM fedora-download AS qt-download
ARG QT_BRANCH=5.15
ARG QT_VERSION=5.15.2
RUN mkdir -p /usr/src && cd /usr/src \
    && wget "https://download.qt.io/official_releases/qt/${QT_BRANCH}/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && tar -xf "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && rm "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && mv qt-everywhere-src-${QT_VERSION} qt

FROM fedora-download AS opendht-download
ARG OPENDHT_COMMIT="db000a2f8849584f84a26cba8583a188741e0418"
RUN mkdir -p /usr/src && git clone --recursive "https://github.com/savoirfairelinux/opendht" /usr/src/opendht && cd /usr/src/opendht && git reset --hard "${OPENDHT_COMMIT}"

FROM fedora-build AS fedora-iwyu
RUN dnf install -y clang-devel llvm-devel && rm -rf /var/cache/dnf
COPY --from=iwyu-download /usr/src/iwyu /usr/src/iwyu
RUN mkdir -p /tmp/iwyu && cd /tmp/iwyu \
    && cmake -GNinja /usr/src/iwyu \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/iwyu

FROM fedora-build AS fedora-boost
COPY --from=boost-download /usr/src/boost /usr/src/boost
RUN cd /usr/src/boost \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=all \
    && ./b2 \
    && ./b2 install

FROM fedora-build AS fedora-cmake
COPY --from=cmake-download /usr/src/cmake /usr/src/cmake
RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake -GNinja /usr/src/cmake \
    && cmake --build . \
    && cmake --install .

FROM fedora-build as fedora-qt
RUN dnf install -y \
    SDL2-devel \
    assimp-devel \
    bison \
    bluez-libs-devel \
    clang-devel \
    cups-devel \
    dbus-devel \
    egl-wayland-devel \
    expat-devel \
    flex \
    fontconfig-devel \
    freetype-devel \
    gperf \
    harfbuzz-devel \
    jsoncpp-devel \
    lcms2-devel \
    libX11-devel \
    libXext-devel \
    libXfixes-devel \
    libXi-devel \
    libXinerama-devel \
    libXrandr-devel \
    libXrender-devel \
    libevent-devel \
    libicu-devel \
    libjpeg-devel \
    libpng-devel \
    libproxy-devel \
    libstdc++-devel \
    libstdc++-static \
    libtiff-devel \
    libvpx-devel \
    libwebp-devel \
    libxcb-devel \
    libxkbcommon-devel \
    libxkbcommon-x11-devel \
    libxml2-devel \
    libxslt-devel \
    mesa-libOSMesa-devel \
    mysql-devel \
    nss-devel \
    openssl-devel \
    opus-devel \
    pcre2-devel \
    protobuf-devel \
    python2 \
    snappy-devel \
    sqlite-devel \
    vulkan-devel \
    wayland-devel \
    zlib-devel \
    && rm -rf /var/cache/dnf
COPY --from=qt-download /usr/src/qt /usr/src/qt
ARG JOBS=2
RUN mkdir -p /tmp/build && cd /tmp/build && /usr/src/qt/configure \
    --prefix=/usr/local \
    -opensource \
    -confirm-license \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    -c++std c++17 \
    -system-assimp \
    -system-zlib \
    -system-sqlite \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build

FROM fedora-build AS fedora-opendht
RUN dnf install -y libargon2-devel && rm -rf /var/cache/dnf
COPY --from=opendht-download /usr/src/opendht /usr/src/opendht
RUN mkdir -p /tmp/opendht && cd /tmp/opendht \
    && cmake \
        -GNinja \
        -DOPENDHT_STATIC=OFF \
        -DOPENDHT_LOG=OFF \
        -DOPENDHT_TOOLS=OFF \
        -DOPENDHT_PROXY_OPENSSL=OFF \
        -DOPENDHT_PEER_DISCOVERY=OFF \
        -DOPENDHT_TESTS_NETWORK=OFF \
        -DOPENDHT_DOCUMENTATION=OFF \
        /usr/src/opendht \
    && cmake --build . \
    && cmake --install . \
    && rm -rf /tmp/opendht

FROM fedora-build AS opentxs-fedora-ci
COPY --from=fedora-iwyu /usr/local /usr/
COPY --from=fedora-boost /usr/local /usr/local
COPY --from=fedora-cmake /usr/local /usr/local
COPY --from=fedora-qt /usr/local /usr/local
COPY --from=fedora-opendht /usr/local /usr/local
RUN ldconfig
COPY ./build-opentxs /usr/bin
COPY ./build-opentxs-clang /usr/bin
COPY ./build-opentxs-gcc /usr/bin
COPY ./test-opentxs /usr/bin
COPY ./opentxs-config /var/lib
