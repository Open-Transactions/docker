# Open-Transactions Docker image for Continuous Integration

These images construct build environments for compiling and testing Open-Transactions

## Usage

### Building the image

```
docker image build -t opentransactions/ci .
```

### Compiling opentxs

The script for compiling opentxs accepts two mandatory arguments.

The first argument specifies the compiler. The allowed values are: gcc clang

The second argument specifies a preset from CMakePresets.json

#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount readonly,type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    -it opentransactions/ci:35_1 \
    gcc \
    full
```

### Check formatting

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --entrypoint /usr/bin/check-formatting.sh \
    -it opentransactions/ci:35_1
```

### Check includes

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    --entrypoint /usr/bin/run-iwyu.sh \
    -it opentransactions/ci:35_1
```
