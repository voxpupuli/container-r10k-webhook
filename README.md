# Vox Pupuli R10k Webhook

[![CI](https://github.com/voxpupuli/container-r10k-webhook/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-r10k-webhook/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-r10k-webhook.svg)](https://github.com/voxpupuli/container-r10k-webhook/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container is designed for deploying Puppet code using r10k triggered by webhooks.
It includes the webhook-go daemon and r10k gem along with all necessary dependencies pre-installed, ensuring a seamless deployment process.

## Usage

To run r10k, simply execute the container.
The r10k binary is set as the default entrypoint.
The container operates as the puppet user with a UID/GID of 999.
You can use a shared volume with a Puppet server and mount it at `/etc/puppetlabs/code/environments`.

```yaml
services:
  webhook:
    image: image: ghcr.io/voxpupuli/r10k-webhook:2.9.0
    ports:
      - 4000:4000
    environment:
      - PUPPET_CONTROL_REPO="https://git.example.org/puppet/control.git"
      - USER="puppet
      - PASSWORD="puppet
      # For using HTTPS enable tls and uncomment the following lines
      #- TLS=true
      #- TLS_CERT="/etc/puppetlabs/puppet/ssl/certs/puppet.pem"
      #- TLS_KEY="/etc/puppetlabs/puppet/ssl/private_keys/puppet.pem"
    volumes:
      - ./code:/etc/puppetlabs/code
      # For using HTTPS enable tls above and mount your key/cert directory
      #- openvoxserver-ssl:/etc/puppetlabs/puppet/ssl
```

### Environment Variables

This container is based on the [r10k container](https://github.com/voxpupuli/container-r10k) and therefore all its environment variables also apply here.

| Name | Description |
| ---- | ------------|
| `USER` | Login username to trigger hooks. Defauls to `puppet`. |
| `PASSWORD` | Required. Password for user to login. |
| `PORT` | Listen on this port. Defaults to `4000`. |
| `TLS` | Expect incoming HTTPS. Defaults to `false`. |
| `TLS_CERT` | Path to the certificate file. Only required if TLS=true. |
| `TLS_KEY` | Path to the private key file. Only required if TLS=true. |
| `ENABLE_QUEUE` | Enable queuing of requests for background processing. Defaults to `false` |
| `MAX_CONCURRENT_JOBS` | How many jobs could be stored in queue. Defaults to `10` |
| `MAX_HISTORY_ITEMS` | How many queue items should be stored in the history. Defaults to `50` |
| `DEFAULT_BRANCH` | Set the default branch to deploy. Defaults too `production`. |
| `GENERATE_TYPES` | Generate data types after successful deployment. Defaults to `true`. |
| `CHAT` | Enable notification for a chat. Defaults to `false` |
| `CHAT_SEREVICE` | Chat type, e.g. slack. |
| `CHAT_URL` | Chat server URL. |
| `CHAT_CHANNEL` | Destination channel to notify for. |
| `CHAT_USER` | Login user. |
| `CHAT_TOKEN` | The token for authentication. |

## Build

### Build Arguments

| Name | Description |
| ---- | ------------|
|`R10K_VERSION`| The R10k container version to use as base layer. |
|`WEBHOOK_GO_VERSION`| Version of webhook-go to install. |

## Version Schema

The version schema has the following layout:

```text
<webhook-go.major>.<webhook-go.minor>.<webhook-go.patch>-v<container.major>.<container.minor>.<container.patch>
<webhook-go.major>.<webhook-go.minor>.<webhook-go.patch>-latest
latest
```

Example usage:

```shell
docker pull ghcr.io/voxpupuli/r10k-webhook:2.9.0-v1.0.1
docker pull ghcr.io/voxpupuli/r10k-webhook:2.9.0-latest
docker pull ghcr.io/voxpupuli/r10k-webhook:latest
```

| Name | Description |
| --- | --- |
| webhook-go.major    | Describes the contained major webhook-go version |
| webhook-go.minor    | Describes the contained minor webhook-go version |
| webhook-go.patch    | Describes the contained patch webhook-go version |
| container.major | Describes breaking changes without backward compatibility |
| container.minor | Describes new features or refactoring with backward compatibility |
| container.patch | Describes if minor changes or bugfixes have been implemented |

## How to release?

see [RELEASE.md](RELEASE.md)

## How to contribute?

see [CONTRIBUTING.md](CONTRIBUTING.md)
