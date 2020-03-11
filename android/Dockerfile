FROM fedora:31 AS run
RUN dnf install -y cmake java-devel git ninja-build qemu-user-static swig

FROM run AS tools
RUN dnf install -y automake bzip2 diffutils findutils gcc gcc-c++ libtool make patch python unzip wget which xz

FROM tools as android
ARG ANDROID_TOOLS=6200805
RUN mkdir -p /opt/android && cd /opt/android && wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOLS}_latest.zip" \
    && unzip "commandlinetools-linux-${ANDROID_TOOLS}_latest.zip" && rm "commandlinetools-linux-${ANDROID_TOOLS}_latest.zip"
ENV JAVA_HOME /usr/lib/jvm/java
RUN yes | /opt/android/tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux --update \
    && yes | /opt/android/tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "platform-tools" "tools"
ARG ANDROID_LEVEL=25
RUN yes | /opt/android/tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "platforms;android-${ANDROID_LEVEL}"
ARG ANDROID_BUILD_TOOLS=25.0.3
RUN yes | /opt/android/tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "build-tools;${ANDROID_BUILD_TOOLS}"
ARG NDK=21.0.6113669
RUN yes | /opt/android/tools/bin/sdkmanager --sdk_root=/opt/android-sdk-linux "ndk;${NDK}"

FROM tools AS build_base
ARG NDK=21.0.6113669
COPY --from=android /opt/android-sdk-linux /opt/android-sdk-linux
RUN ln -s "/opt/android-sdk-linux/ndk/${NDK}" /opt/ndk

FROM build_base AS boost
ARG BOOST=dfd133fe68e07c0e1d56195a1df18b6766014fe0
RUN mkdir -p /usr/src && cd /usr/src \
    && wget "https://github.com/moritz-wundke/Boost-for-Android/archive/${BOOST}.zip" \
    && unzip "${BOOST}.zip" \
    && rm "${BOOST}.zip" \
    && mv "Boost-for-Android-${BOOST}" boost \
    && cd /usr/src/boost \
    && ./build-android.sh --download /opt/ndk
ARG ANDROID_LEVEL=25
RUN cd /usr/src/boost \
    && sed -i "s/--layout=versioned/--layout=system/" build-android.sh \
    && sed -i "s/link=static/link=shared/" build-android.sh \
    && ./build-android.sh --arch=armeabi-v7a,arm64-v8a,x86,x86_64 --target-version="${ANDROID_LEVEL}" /opt/ndk \
    && mkdir -p /usr/android \
    && mv /usr/src/boost/build/out/arm64-v8a /usr/android/arm64 \
    && mv /usr/src/boost/build/out/armeabi-v7a /usr/android/arm \
    && mv /usr/src/boost/build/out/x86_64 /usr/android/x64 \
    && mv /usr/src/boost/build/out/x86 /usr/android/x86 \
    && rm -rf /usr/src/boost

FROM build_base AS sodium
ARG SODIUM=940ef42797baa0278df6b7fd9e67c7590f87744b
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/jedisct1/libsodium/archive/${SODIUM}.zip" \
    && unzip "${SODIUM}.zip" && rm "${SODIUM}.zip" && mv "libsodium-${SODIUM}" sodium
ARG ANDROID_LEVEL=25
ARG ANDROID_CLANG=24
ARG JOBS=2
RUN mkdir -p /tmp/build && cd /tmp/build \
    && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ar" \
    && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-as" \
    && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_CLANG}-clang" \
    && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_CLANG}-clang++" \
    && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ld" \
    && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ranlib" \
    && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/arm64 \
        --host=aarch64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --disable-shared \
        --enable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/arm \
        --host=armv7a-linux-androideabi \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --disable-shared \
        --enable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/x64 \
        --host=x86_64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --disable-shared \
        --enable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-strip" \
    && /usr/src/sodium/configure \
        --prefix=/usr/android/x86 \
        --host=i686-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --disable-asm \
        --disable-minimal \
        --disable-soname-versions \
        --disable-shared \
        --enable-static \
    && make -j$JOBS install && rm -rf /tmp/build \
    && rm -rf /usr/src/sodium

FROM build_base AS secp256k1
ARG SECP256K1=452d8e4d2a2f9f1b5be6b02e18f1ba102e5ca0b4
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/bitcoin/secp256k1/archive/${SECP256K1}.zip" \
    && unzip "${SECP256K1}.zip" && rm "${SECP256K1}.zip" && mv "secp256k1-${SECP256K1}" secp256k1
ARG ANDROID_LEVEL=25
ARG ANDROID_CLANG=24
ARG JOBS=2
RUN cd /usr/src/secp256k1 && ./autogen.sh \
    && mkdir -p /tmp/build && cd /tmp/build \
    && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ar" \
    && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-as" \
    && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_CLANG}-clang" \
    && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_CLANG}-clang++" \
    && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ld" \
    && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ranlib" \
    && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip" \
    && /usr/src/secp256k1/configure \
        --prefix=/usr/android/arm64 \
        --host=aarch64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --enable-static \
        --disable-shared \
        --disable-openssl-tests \
        --enable-experimental \
        --disable-exhaustive-tests \
        --enable-module-ecdh \
        --enable-module-recovery \
        --with-bignum=no \
        --with-asm=no \
        --disable-tests \
        --disable-benchmark \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip" \
    && /usr/src/secp256k1/configure \
        --prefix=/usr/android/arm \
        --host=armv7a-linux-androideabi \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --enable-static \
        --disable-shared \
        --disable-openssl-tests \
        --enable-experimental \
        --disable-exhaustive-tests \
        --enable-module-ecdh \
        --enable-module-recovery \
        --with-bignum=no \
        --with-asm=no \
        --disable-tests \
        --disable-benchmark \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-strip" \
    && /usr/src/secp256k1/configure \
        --prefix=/usr/android/x64 \
        --host=x86_64-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --enable-static \
        --disable-shared \
        --disable-openssl-tests \
        --enable-experimental \
        --disable-exhaustive-tests \
        --enable-module-ecdh \
        --enable-module-recovery \
        --with-bignum=no \
        --with-asm=no \
        --disable-tests \
        --disable-benchmark \
    && make -j$JOBS install && rm -rf /tmp/build \
    && mkdir -p /tmp/build && cd /tmp/build \
        && export AR="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ar" \
        && export AS="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-as" \
        && export CC="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_CLANG}-clang" \
        && export CXX="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_CLANG}-clang++" \
        && export LD="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ld" \
        && export RANLIB="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ranlib" \
        && export STRIP="/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-strip" \
    && /usr/src/secp256k1/configure \
        --prefix=/usr/android/x86 \
        --host=i686-linux-android \
        --with-sysroot="/opt/ndk/sysroot/usr" \
        --enable-static \
        --disable-shared \
        --disable-openssl-tests \
        --enable-experimental \
        --disable-exhaustive-tests \
        --enable-module-ecdh \
        --enable-module-recovery \
        --with-bignum=no \
        --with-asm=no \
        --disable-tests \
        --disable-benchmark \
    && make -j$JOBS install && rm -rf /tmp/build \
    && rm -rf /usr/src/secp256k1

FROM build_base AS lmdb
ARG LMDB=5c012bbe033f9bbb273078b07dded59f080d348d
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/LMDB/lmdb/archive/${LMDB}.zip" \
    && unzip "${LMDB}.zip" && rm "${LMDB}.zip" && mv "lmdb-${LMDB}" lmdb
ARG ANDROID_CLANG=24
ARG JOBS=2
RUN cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_CLANG}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/arm64~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb.a/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi${ANDROID_CLANG}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/arm~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb.a/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android${ANDROID_CLANG}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/x64~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb.a/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && cp -a /usr/src/lmdb/libraries/liblmdb/ /tmp/build \
    && sed -i "s~gcc~/opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android${ANDROID_CLANG}-clang~" /tmp/build/Makefile \
    && sed -i "s~= ar~= /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-ar~" /tmp/build/Makefile \
    && sed -i "s~/usr/local~/usr/android/x86~" /tmp/build/Makefile \
    && sed -i "s/liblmdb.a liblmdb\$(SOEXT)/liblmdb.a/" /tmp/build/Makefile \
    && cd /tmp/build \
    && make -j$JOBS install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/lmdb

FROM build_base AS protobuf
ARG PROTOBUF=d0bfd5221182da1a7cc280f3337b5e41a89539cf
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/protocolbuffers/protobuf/archive/${PROTOBUF}.zip" \
    && unzip "${PROTOBUF}.zip" && rm "${PROTOBUF}.zip" && mv "protobuf-${PROTOBUF}" protobuf
ARG ANDROID_LEVEL=25
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
        -DBUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_BUILD_CONFORMANCE=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES=OFF \
        -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_BUILD_SHARED_LIBS=OFF \
        -DCMAKE_CXX_FLAGS="-Wl,-llog" \
        /usr/src/protobuf/cmake \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/protobuf

FROM build_base AS libressl
ARG LIBRESSL=9371ddb5525f69f43a328419d09eb49a439d7c0f
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/libressl-portable/portable/archive/${LIBRESSL}.zip" \
    && unzip "${LIBRESSL}.zip" && rm "${LIBRESSL}.zip" && mv "portable-${LIBRESSL}" libressl
ARG ANDROID_LEVEL=25
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        -DLIBRESSL_APPS=OFF \
        -DLIBRESSL_TESTS=OFF \
        -DENABLE_ASM=OFF \
        /usr/src/libressl \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/libressl

FROM build_base AS zeromq
ARG ZMQ=a84ffa12b2eb3569ced199660bac5ad128bff1f0
RUN mkdir -p /usr/src && cd /usr/src && wget "https://github.com/zeromq/libzmq/archive/${ZMQ}.zip" \
    && unzip "${ZMQ}.zip" && rm "${ZMQ}.zip" && mv "libzmq-${ZMQ}" zeromq
COPY --from=sodium /usr/android /usr/android
ARG ANDROID_LEVEL=25
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        /usr/src/zeromq \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/zeromq

FROM build_base as gtest
ARG GTEST=703bd9caab50b139428cea1aaff9974ebee5742e
RUN mkdir -p /usr/src && cd /usr/src && git clone https://github.com/google/googletest.git \
    && cd googletest && git checkout "${GTEST}" && git submodule update --init --recursive
ARG ANDROID_LEVEL=25
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
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
        -DBUILD_SHARED_LIBS=OFF \
        /usr/src/googletest \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/googletest

FROM build_base as otproto
ARG OTPROTO=0e0fbe60c632ccc0a13038a41bdf986a5e8770f5
RUN mkdir -p /usr/src && cd /usr/src && git clone https://github.com/Open-Transactions/opentxs-proto.git \
    && cd opentxs-proto && git checkout "${OTPROTO}" && git submodule update --init --recursive
COPY --from=protobuf /usr/android /usr/android
COPY --from=protobuf /usr/local/protobuf /usr
COPY --from=gtest /usr/android /usr/android
ARG ANDROID_LEVEL=25
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
        -DCMAKE_CROSSCOMPILING_EMULATOR="/usr/bin/qemu-aarch64-static" \
        -DBUILD_SHARED_LIBS=OFF \
        -DProtobuf_PROTOC_EXECUTABLE=/usr/bin/protoc \
        -DOPENTXS_PROTO_BUILD_TESTS=ON \
        /usr/src/opentxs-proto \
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
        -DCMAKE_CROSSCOMPILING_EMULATOR="/usr/bin/qemu-arm-static" \
        -DBUILD_SHARED_LIBS=OFF \
        -DProtobuf_PROTOC_EXECUTABLE=/usr/bin/protoc \
        -DOPENTXS_PROTO_BUILD_TESTS=ON \
        /usr/src/opentxs-proto \
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
        -DBUILD_SHARED_LIBS=OFF \
        -DProtobuf_PROTOC_EXECUTABLE=/usr/bin/protoc \
        -DOPENTXS_PROTO_BUILD_TESTS=ON \
        /usr/src/opentxs-proto \
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
        -DBUILD_SHARED_LIBS=OFF \
        -DProtobuf_PROTOC_EXECUTABLE=/usr/bin/protoc \
        -DOPENTXS_PROTO_BUILD_TESTS=ON \
        /usr/src/opentxs-proto \
    && ninja install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/opentxs-proto

FROM build_base as qt
ENV JAVA_HOME /usr/lib/jvm/java
ARG QT_BRANCH=5.12
ARG QT_VERSION=5.12.7
RUN mkdir -p /usr/src && cd /usr/src \
    && wget "https://download.qt.io/official_releases/qt/${QT_BRANCH}/${QT_VERSION}/single/qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && tar -xf "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && rm "qt-everywhere-src-${QT_VERSION}.tar.xz" \
    && mv qt-everywhere-src-${QT_VERSION} qt
ARG JOBS=2
RUN mkdir -p /tmp/build && cd /tmp/build && export PATH=$PATH:$JAVA_HOME/bin && /usr/src/qt/configure \
    --prefix=/usr/android/arm64 \
    --disable-rpath \
    -xplatform android-clang \
    -android-ndk /opt/ndk \
    -android-sdk /opt/android-sdk-linux \
    -android-arch arm64-v8a \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build
RUN mkdir -p /tmp/build && cd /tmp/build && export PATH=$PATH:$JAVA_HOME/bin && /usr/src/qt/configure \
    --prefix=/usr/android/arm \
    --disable-rpath \
    -xplatform android-clang \
    -android-ndk /opt/ndk \
    -android-sdk /opt/android-sdk-linux \
    -android-arch armeabi-v7a \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build
RUN mkdir -p /tmp/build && cd /tmp/build && export PATH=$PATH:$JAVA_HOME/bin && /usr/src/qt/configure \
    --prefix=/usr/android/x64 \
    --disable-rpath \
    -xplatform android-clang \
    -android-ndk /opt/ndk \
    -android-sdk /opt/android-sdk-linux \
    -android-arch x86_64 \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build
RUN mkdir -p /tmp/build && cd /tmp/build && export PATH=$PATH:$JAVA_HOME/bin && /usr/src/qt/configure \
    --prefix=/usr/android/x86 \
    --disable-rpath \
    -xplatform android-clang \
    -android-ndk /opt/ndk \
    -android-sdk /opt/android-sdk-linux \
    -android-arch x86 \
    -nomake tests \
    -nomake examples \
    -no-warnings-are-errors \
    && make -j$JOBS \
    && make install \
    && rm -rf /tmp/build \
    && rm -rf /usr/src/qt

FROM run
ARG NDK=21.0.6113669
COPY --from=android /opt/android-sdk-linux/ndk /opt/android-sdk-linux/ndk
RUN ln -s "/opt/android-sdk-linux/ndk/${NDK}" /opt/ndk
COPY --from=boost /usr/android /usr/android
COPY --from=sodium /usr/android /usr/android
COPY --from=secp256k1 /usr/android /usr/android
COPY --from=lmdb /usr/android /usr/android
COPY --from=protobuf /usr/android /usr/android
COPY --from=protobuf /usr/local/protobuf /usr
COPY --from=libressl /usr/android /usr/android
COPY --from=zeromq /usr/android /usr/android
COPY --from=gtest /usr/android /usr/android
COPY --from=otproto /usr/android /usr/android
COPY --from=qt /usr/android /usr/android
COPY ./build /usr/bin
ENV JAVA_HOME /usr/lib/jvm/java
RUN cp /opt/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/jni.h "${JAVA_HOME}/include"
ENTRYPOINT [ "/usr/bin/build" ]
CMD []
