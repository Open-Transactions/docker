# Open-Transactions Docker image for Android

This image creates an Android NDK development environment and compiles all opentxs dependencies. A build script is included which will compile opentxs for a specified architecture and bindings.

## Contents

* Android SDK
  * Platform (android-33)
  * Android NDK (26.0.10792818)
* Boost (1.82)
* Googletest (1.14.0)
* LMDB (8d0cbbc)
* OpenSSL (3.1.2)
* Libsodium (1.0.18)
* Protocol Buffers (23.4)
* Qt (6.6.0-rc)
* ZeroMQ (4.3.4)

## Usage

### Building the image

Set the JOBS build argument to match the available number of cores on the host to speed up the image creation process.

```
docker image build -t opentransactions/android --build-arg JOBS=8 .
```

#### Optional arguments for customizing the image contents

* ANDROID_BUILD_TOOLS
* ANDROID_LEVEL
* ANDROID_LEVEL_TOOLCHAIN
* ANDROID_TOOLS
* BOOST
* CMAKE_BUILD_TYPE
* CMAKE_VERSION
* GTEST
* JOBS
* LMDB
* NDK
* OPENSSL_VER
* PROTOBUF
* QT_BRANCH
* QT_RELEASE
* QT_VERSION
* SODIUM
* ZMQ

### Compiling opentxs

Valid architectures (first argument, mandatory): arm64 arm x64 x86

Valid bindings (second argument, optional): none qt all


#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/desired/output/directory,dst=/home/output \
    -it opentransactions/android:latest \
    arm64 \
    all
```
