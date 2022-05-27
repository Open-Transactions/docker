# Open-Transactions Docker image for Android

This image creates an Android NDK development environment and compiles all opentxs dependencies. A build script is included which will compile opentxs for a specified architecture and bindings.

## Contents

* Android SDK
  * Platform (android-31)
  * Android NDK (24.0.8215888)
* Boost (1.78)
* Googletest (1.10.0)
* LMDB (8d0cbbc)
* LibreSSL (3.1.3)
* Libsodium (1.0.18)
* Protocol Buffers (3.19.4)
* Qt (6.3.0)
* ZeroMQ (4.3.4)

## Usage

### Building the image

Set the JOBS build argument to match the available number of cores on the host to speed up the image creation process.

```
docker image build -t opentransactions/android --build-arg JOBS=8 .
```

#### Optional arguments for customizing the image contents

* ANDROID_BUILD_TOOLS
* ANDROID_CLANG
* ANDROID_LEVEL
* ANDROID_TOOLS
* BOOST
* CMAKE_BUILD_TYPE
* JOBS
* LIBRESSL
* LMDB
* NDK
* PROTOBUF
* QT_BRANCH
* QT_VERSION
* SECP256K1
* SODIUM
* ZMQ

### Compiling opentxs

Valid architectures (first argument, mandatory): arm64 arm x64 x86

Valid bindings (second argument, optional): java qt both


#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/desired/output/directory,dst=/home/output \
    -it opentransactions/android:latest \
    arm64 \
    qt
```
