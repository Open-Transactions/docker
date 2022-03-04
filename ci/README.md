# Open-Transactions Docker image for Continuous Integration

These images construct build environments for compiling and testing Open-Transactions

## Usage

### Building the image

```
docker image build -t opentransactions/ci .
```

### Compiling opentxs

Compile scripts are located in the image /usr/bin/build-opentxs-clang and /usr/bin/build-opentxs-gcc and should be used as the image entrypoint

The entrypoint scripts one parameter for the named opentxs configuration from /var/lib/opentxs-config.sh.

Valid values are: test01 test02 test03 test04 test05 test06 test07 test08 prod nopch full

#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    --entrypoint /usr/bin/build-opentxs-gcc \
    -it opentransactions/ci:latest \
    full
```

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/opentxs,dst=/home/src \
    --mount type=bind,src=/path/to/build/directory,dst=/home/output \
    --entrypoint /usr/bin/build-opentxs-clang \
    -it opentransactions/ci:latest \
    full
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
    --entrypoint /usr/bin/test-opentxs \
    -it opentransactions/ci:latest \
    2
```
