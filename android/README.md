# Open-Transactions Docker image for Android

This image creates an Android NDK development environment and compiles all opentxs dependencies. A build script is included which will compile opentxs for a specified architecture and bindings.

## Contents

* Android SDK
  * Platform (android-25)
  * Android NDK (21.0.6113669)
* Boost (1.70)
* Libsodium (1.0.18)
* Secp256k1 (452d8e4)
* LMDB (5c012bb)
* Protocol Buffers (3.11.4)
* LibreSSL (3.0.2)
* ZeroMQ (4.3.2)
* Googletest (1.10.0)
* Qt (5.12.7)

## Usage

### Building the image

Set the JOBS build argument to match the available number of cores on the host to speed up the image creation process.

```
docker image build -t opentransactions/android --build-arg JOBS=8 .
```

#### Optional arguments for customizing the image contents

* JOBS
* CMAKE_BUILD_TYPE
* ANDROID_TOOLS
* ANDROID_LEVEL
* ANDROID_CLANG
* ANDROID_BUILD_TOOLS
* NDK
* BOOST
* SODIUM
* SECP256K1
* LMDB
* PROTOBUF
* LIBRESSL
* ZMQ
* QT_BRANCH
* QT_VERSION

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
