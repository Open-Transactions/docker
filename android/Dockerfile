FROM fedora:33 AS run
RUN dnf install -y cmake java-devel git ninja-build qemu-user-static swig && rm -rf /var/cache/dnf

FROM run AS tools
RUN dnf install -y automake bzip2 diffutils findutils gcc gcc-c++ libtool make patch python unzip wget which xz && rm -rf /var/cache/dnf

FROM tools as android
ARG ANDROID_TOOLS=7583922
RUN mkdir -p /opt/android && cd /opt/android && wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOLS}_latest.zip" \
    && unzip "commandlinetools-linux-${ANDROID_TOOLS}_latest.zip" && rm "commandlinetools-linux-${ANDROID_TOOLS}_latest.zip"
ENV JAVA_HOME /usr/lib/jvm/java
RUN yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux --update \
    && yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "platform-tools" "tools"
ARG ANDROID_LEVEL=28
RUN yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "platforms;android-${ANDROID_LEVEL}"
ARG ANDROID_BUILD_TOOLS=28.0.3
RUN yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "build-tools;${ANDROID_BUILD_TOOLS}"
ARG NDK=23.0.7599858
RUN yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux --update \
    && yes | /opt/android/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "ndk;${NDK}"
RUN find /opt/android-sdk-linux/ndk -name libz.a -delete

FROM tools AS build_base
ARG NDK=23.0.7599858
COPY --from=android /opt/android-sdk-linux /opt/android-sdk-linux
RUN ln -s "/opt/android-sdk-linux/ndk/${NDK}" /opt/ndk

FROM tools AS boost_download
ARG BOOST=ccfc74f1c9ceb35d304294d4f1ed3abff43d2e01
RUN mkdir -p /usr/src && cd /usr/src \
    && wget "https://github.com/moritz-wundke/Boost-for-Android/archive/${BOOST}.zip" \
    && unzip "${BOOST}.zip" \
    && rm "${BOOST}.zip" \
    && mv "Boost-for-Android-${BOOST}" boost \
    && cd /usr/src/boost \
    && wget https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.bz2

FROM build_base AS boost
COPY --from=boost_download /usr/src/boost /usr/src/boost
ARG ANDROID_LEVEL=28
COPY ./boost.patch /usr/src/boost/patches/boost-1_76_0/suffix.patch
RUN cd /usr/src/boost \
    && sed -i "s/link=static/link=shared/" build-android.sh \
    && ./build-android.sh --boost=1.76.0 --arch=armeabi-v7a,arm64-v8a,x86,x86_64 --target-version="${ANDROID_LEVEL}" --layout=system /opt/ndk \
    && mkdir -p /usr/android \
    && mv /usr/src/boost/build/out/arm64-v8a /usr/android/arm64 \
    && mv /usr/src/boost/build/out/armeabi-v7a /usr/android/arm \
    && mv /usr/src/boost/build/out/x86_64 /usr/android/x64 \
    && mv /usr/src/boost/build/out/x86 /usr/android/x86 \
    && rm -rf /usr/src/boost

FROM tools AS sodium_download
ARG SODIUM=940ef42797baa0278df6b7fd9e67c7590f87744b
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/jedisct1/libsodium/archive/${SODIUM}.zip" \
    && unzip "${SODIUM}.zip" && rm "${SODIUM}.zip" && mv "libsodium-${SODIUM}" sodium

FROM build_base AS sodium
COPY --from=sodium_download /usr/src/sodium /usr/src/sodium
ARG ANDROID_LEVEL=28
ARG ANDROID_LEVEL_TOOLCHAIN=28
ARG JOBS=2
RUN mkdir -p /tmp/build && cd /tmp/build \
    && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" \
    && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as" \
    && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang" \
    && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang++" \
    && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/ld" \
    && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib" \
    && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/arm64 \
        --host=aarch64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --enable-shared \
        --disable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_LEVEL_TOOLCHAIN}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_LEVEL_TOOLCHAIN}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/arm \
        --host=armv7a-linux-androideabi \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --enable-shared \
        --disable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/x64 \
        --host=x86_64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --enable-shared \
        --disable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/x86 \
        --host=i686-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --enable-shared \
        --disable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && rm -rf /usr/src/sodium

FROM tools AS lmdb_download
ARG LMDB=8d0cbbc936091eb85972501a9b31a8f86d4c51a7
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/LMDB/lmdb/archive/${LMDB}.zip" \
    && unzip "${LMDB}.zip" && rm "${LMDB}.zip" && mv "lmdb-${LMDB}" lmdb

FROM build_base AS lmdb
COPY --from=lmdb_download /usr/src/lmdb /usr/src/lmdb
ARG ANDROID_LEVEL_TOOLCHAIN=28
ARG JOBS=2
RUN cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/arm64~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb\$(SOEXT)/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_LEVEL_TOOLCHAIN}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/arm~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb\$(SOEXT)/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/x64~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb\$(SOEXT)/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_LEVEL_TOOLCHAIN}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/x86~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb\$(SOEXT)/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/lmdb

FROM tools AS protobuf_download
ARG PROTOBUF=22d0e265de7d2b3d2e9a00d071313502e7d4cccf
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/protocolbuffers/protobuf/archive/${PROTOBUF}.zip" \
    && unzip "${PROTOBUF}.zip" && rm "${PROTOBUF}.zip" && mv "protobuf-${PROTOBUF}" protobuf

FROM build_base AS protobuf
COPY --from=protobuf_download /usr/src/protobuf /usr/src/protobuf
ARG ANDROID_LEVEL=28
ARG CMAKE_BUILD_TYPE=Release
RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DCMAKE_INSTALL_PREFIX=/usr/local/protobuf \
        -DBUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm64 \
        -DBUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        -DCMAKE_CXX_FLAGS="-Wl,-llog" \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=armeabi-v7a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm \
        -DBUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        -DCMAKE_CXX_FLAGS="-Wl,-llog" \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86_64 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x64 \
        -DBUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        -DCMAKE_CXX_FLAGS="-Wl,-llog" \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x86 \
        -DBUILD_SHARED_LIBS=ON \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=ON \
        -DCMAKE_CXX_FLAGS="-Wl,-llog" \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/protobuf

FROM tools AS libressl_download
ARG LIBRESSL=aa6440a9b086faa9ee555046c2c006534e01eaf7
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/libressl-portable/portable/archive/${LIBRESSL}.zip" \
    && unzip "${LIBRESSL}.zip" && rm "${LIBRESSL}.zip" && mv "portable-${LIBRESSL}" libressl

FROM build_base AS libressl
COPY --from=libressl_download /usr/src/libressl /usr/src/libressl
ARG ANDROID_LEVEL=28
ARG CMAKE_BUILD_TYPE=Release
RUN cd /usr/src/libressl && ./autogen.sh \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm64 \
        -DBUILD_SHARED_LIBS=ON \
        -DLIBRESSL_APPS=OFF \
        -DLIBRESSL_TESTS=OFF \
        -DENABLE_ASM=OFF \
        /usr/src/libressl \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=armeabi-v7a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm \
        -DBUILD_SHARED_LIBS=ON \
        -DLIBRESSL_APPS=OFF \
        -DLIBRESSL_TESTS=OFF \
        -DENABLE_ASM=OFF \
        /usr/src/libressl \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86_64 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x64 \
        -DBUILD_SHARED_LIBS=ON \
        -DLIBRESSL_APPS=OFF \
        -DLIBRESSL_TESTS=OFF \
        -DENABLE_ASM=OFF \
        /usr/src/libressl \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x86 \
        -DBUILD_SHARED_LIBS=ON \
        -DLIBRESSL_APPS=OFF \
        -DLIBRESSL_TESTS=OFF \
        -DENABLE_ASM=OFF \
        /usr/src/libressl \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/libressl

FROM tools AS zeromq_download
ARG ZMQ=4097855ddaaa65ed7b5e8cb86d143842a594eebd
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/zeromq/libzmq/archive/${ZMQ}.zip" \
    && unzip "${ZMQ}.zip" && rm "${ZMQ}.zip" && mv "libzmq-${ZMQ}" zeromq

FROM build_base AS zeromq
COPY --from=zeromq_download /usr/src/zeromq /usr/src/zeromq
COPY --from=sodium /usr/android /usr/android
ARG ANDROID_LEVEL=28
ARG CMAKE_BUILD_TYPE=Release
RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm64 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/arm64 \
        -DBUILD_SHARED_LIBS=ON \
        -DENABLE_ASAN=OFF \
        -DENABLE_INTRINSICS=OFF \
        -DWITH_OPENPGM=OFF \
        -DWITH_VMCI=OFF \
        -DZMQ_BUILD_FRAMEWORK=OFF \
        -DWITH_LIBSODIUM=ON \
        -DENABLE_CURVE=ON \
        -DENABLE_DRAFTS=OFF \
        -DWITH_MILITANT=OFF \
        -DLIBZMQ_PEDANTIC=OFF \
        -DLIBZMQ_WERROR=OFF \
        -DWITH_DOCS=OFF \
        -DBUILD_SHARED=ON \
        -DBUILD_STATIC=OFF \
        -DWITH_PERF_TOOL=OFF \
        -DBUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        /usr/src/zeromq \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=armeabi-v7a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/arm \
        -DBUILD_SHARED_LIBS=ON \
        -DENABLE_ASAN=OFF \
        -DENABLE_INTRINSICS=OFF \
        -DWITH_OPENPGM=OFF \
        -DWITH_VMCI=OFF \
        -DZMQ_BUILD_FRAMEWORK=OFF \
        -DWITH_LIBSODIUM=ON \
        -DENABLE_CURVE=ON \
        -DENABLE_DRAFTS=OFF \
        -DWITH_MILITANT=OFF \
        -DLIBZMQ_PEDANTIC=OFF \
        -DLIBZMQ_WERROR=OFF \
        -DWITH_DOCS=OFF \
        -DBUILD_SHARED=ON \
        -DBUILD_STATIC=OFF \
        -DWITH_PERF_TOOL=OFF \
        -DBUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        /usr/src/zeromq \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86_64 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x64 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/x64 \
        -DENABLE_ASAN=OFF \
        -DENABLE_INTRINSICS=OFF \
        -DWITH_OPENPGM=OFF \
        -DWITH_VMCI=OFF \
        -DZMQ_BUILD_FRAMEWORK=OFF \
        -DWITH_LIBSODIUM=ON \
        -DENABLE_CURVE=ON \
        -DENABLE_DRAFTS=OFF \
        -DWITH_MILITANT=OFF \
        -DLIBZMQ_PEDANTIC=OFF \
        -DLIBZMQ_WERROR=OFF \
        -DWITH_DOCS=OFF \
        -DBUILD_SHARED=ON \
        -DBUILD_STATIC=OFF \
        -DWITH_PERF_TOOL=OFF \
        -DBUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/zeromq \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x86 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/x86 \
        -DENABLE_ASAN=OFF \
        -DENABLE_INTRINSICS=OFF \
        -DWITH_OPENPGM=OFF \
        -DWITH_VMCI=OFF \
        -DZMQ_BUILD_FRAMEWORK=OFF \
        -DWITH_LIBSODIUM=ON \
        -DENABLE_CURVE=ON \
        -DENABLE_DRAFTS=OFF \
        -DWITH_MILITANT=OFF \
        -DLIBZMQ_PEDANTIC=OFF \
        -DLIBZMQ_WERROR=OFF \
        -DWITH_DOCS=OFF \
        -DBUILD_SHARED=ON \
        -DBUILD_STATIC=OFF \
        -DWITH_PERF_TOOL=OFF \
        -DBUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/zeromq \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/zeromq

FROM tools AS gtest_download
ARG GTEST=e2239ee6043f73722e7aa812a459f54a28552929
RUN mkdir -p /usr/src && cd /usr/src && git clone https://github.com/google/googletest.git \
    && cd googletest && git checkout "${GTEST}" && git submodule update --init --recursive

FROM build_base as gtest
COPY --from=gtest_download /usr/src/googletest /usr/src/googletest
ARG ANDROID_LEVEL=28
ARG CMAKE_BUILD_TYPE=Release
ARG JOBS=2
RUN mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm64 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/arm64 \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/googletest \
    && ninja install \
    && ctest --jobs $JOBS \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=armeabi-v7a \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/arm \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/arm \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/googletest \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86_64 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x64 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/x64 \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/googletest \
    && ninja install \
    && rm -rf /tmp/build \
    && mkdir -p /tmp/build \
    && cd /tmp/build \
    && cmake \
        -GNinja \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DANDROID_ABI=x86 \
        -DANDROID_PLATFORM="android-${ANDROID_LEVEL}" \
        -DANDROID_STL="c++_shared" \
        -DCMAKE_TOOLCHAIN_FILE="/opt/ndk/build/cmake/android.toolchain.cmake" \
        -DCMAKE_INSTALL_PREFIX=/usr/android/x86 \
        -DCMAKE_FIND_ROOT_PATH=/usr/android/x86 \
        -DBUILD_SHARED_LIBS=ON \
        /usr/src/googletest \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/googletest

FROM tools AS qt_download
ARG QT_BRANCH=5.15
ARG QT_VERSION=5.15.2
RUN mkdir -p /usr/src && cd /usr/src \
    && wget "https://download.qt.io/official_releases/qt/${QT_BRANCH}/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && tar -xf "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && rm "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && mv qt-everywhere-src-${QT_VERSION} qt

FROM build_base as host_qt
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
ENV JAVA_HOME /usr/lib/jvm/java
COPY --from=qt_download /usr/src/qt /usr/src/qt
ARG JOBS=2
ARG ANDROID_LEVEL_TOOLCHAIN=28
RUN cd /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/ && \
    ln -s llvm-ranlib i686-linux-android-ranlib && \
    ln -s llvm-ranlib x86_64-linux-android-ranlib && \
    ln -s llvm-ranlib arm-linux-androideabi-ranlib && \
    ln -s llvm-ranlib aarch64-linux-android-ranlib
RUN mkdir -p /tmp/build && cd /tmp/build && /usr/src/qt/configure \
    --prefix=/usr \
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

FROM host_qt as qt
ENV JAVA_HOME /usr/lib/jvm/java
ARG JOBS=2
ARG ANDROID_LEVEL_TOOLCHAIN=28
RUN mkdir -p /tmp/build && cd /tmp/build && export PATH=$PATH:$JAVA_HOME/bin && /usr/src/qt/configure \
    --prefix=/usr/qt-for-android \
    --disable-rpath \
    -opensource \
    -confirm-license \
    -linker lld \
    -xplatform android-clang \
    -android-ndk-platform android-${ANDROID_LEVEL_TOOLCHAIN} \
    -android-ndk /opt/ndk \
    -android-sdk /opt/android-sdk-linux \
    -android-abis arm64-v8a,armeabi-v7a,x86_64,x86 \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    -no-zlib \
    -c++std c++17 \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build

FROM run AS final
ARG NDK=23.0.7599858
COPY --from=android /opt/android-sdk-linux/ndk /opt/android-sdk-linux/ndk
RUN ln -s "/opt/android-sdk-linux/ndk/${NDK}" /opt/ndk
COPY --from=qt /usr/qt-for-android /usr/qt-for-android
COPY --from=boost /usr/android /usr/android
COPY --from=sodium /usr/android /usr/android
COPY --from=lmdb /usr/android /usr/android
COPY --from=protobuf /usr/android /usr/android
COPY --from=protobuf /usr/local/protobuf /usr
COPY --from=libressl /usr/android /usr/android
COPY --from=zeromq /usr/android /usr/android
COPY --from=gtest /usr/android /usr/android
COPY ./build /usr/bin
ENV JAVA_HOME /usr/lib/jvm/java
RUN cp /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/jni.h "${JAVA_HOME}/include"
ENTRYPOINT [ "/usr/bin/build" ]
CMD []
