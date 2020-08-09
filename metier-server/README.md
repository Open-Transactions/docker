# Métier-server Docker image

Métier-server is a multi-chain blockchain indexer and client-side filter server.

## Usage

### Building the image

```
docker image build -t opentransactions/metier-server .
```

### Building the image

Persistent storage must be mounted at /metier inside the image. See the example below for details.

The list of supported chains and their associated command line arguments can be obtained by passing --help.

#### Example

```
docker run \
    --read-only \
    --tmpfs /tmp/build:rw,nosuid,size=2g \
    --mount type=bind,src=/path/to/storage,dst=/metier \
    -ti opentransactions/metier-server:latest
```
