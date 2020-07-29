# Open-Transactions Docker image for Continuous Integration

These images construct build environments for compiling and testing Open-Transactions

## Usage

### Building the image

```
docker image build -t opentransactions/ci .
```

### Compiling opentxs

Compile scripts are located in the image /usr/bin/build-opentxs-clang and /usr/bin/build-opentxs-gcc

#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    -it opentransactions/ci:latest \
    /usr/bin/build-opentxs-gcc
```

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    -it opentransactions/ci:latest \
    /usr/bin/build-opentxs-clang
```

### Executing unit tests

Unit test scripts is located in the image at /usr/bin/test-opentxs

Pass a numeric jobs argument to these scripts that matches the number of available cores.

#### Example

```
docker run \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    -it opentransactions/ci:latest \
    /usr/bin/test-opentxs 2
```
