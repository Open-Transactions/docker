# Notary Docker image

The notary provides server component of the opentxs protocol.

## Usage

### Building the image

```
docker image build -t opentransactions/notary .
```

### Building the image

Persistent storage must be mounted at /notary inside the image. See the example below for details.

Command line arguments can be obtained by passing --help.

#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/storage,dst=/notary \
    -ti opentransactions/notary:latest
```
