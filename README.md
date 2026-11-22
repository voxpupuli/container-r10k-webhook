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
The container runs as `64604:0` (group 0) and works under any UID, the same access model as the r10k container, see its [migration notes](https://github.com/voxpupuli/container-r10k/blob/main/MIGRATION.md).
You can use a shared volume with a Puppet server and mount it at `/etc/puppetlabs/code/environments`.
When sharing a code volume with openvoxserver, run the container as `user: "64604:0"` (the image default) so it can write to a volume owned by `64604:0`.

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
| ---- | ----------- |
| `CERT_JSON` | no default. |
| `CHAT_CHANNEL` | Destination channel to notify for. |
| `CHAT_SERVICE` | Chat type, e.g. slack. |
| `CHAT_TOKEN` | The token for authentication. |
| `CHAT_URL` | Chat server URL. |
| `CHAT_USER` | Login user. |
| `CHAT` | Enable notification for a chat. Defaults to `false` |
| `DEFAULT_BRANCH` | Set the default branch to deploy. Defaults too `production`. |
| `ENABLE_QUEUE` | Enable queuing of requests for background processing. Defaults to `false` |
| `GENERATE_TYPES` | Generate data types after successful deployment. Defaults to `true`. |
| `MAX_CONCURRENT_JOBS` | How many jobs could be stored in queue. Defaults to `10` |
| `MAX_HISTORY_ITEMS` | How many queue items should be stored in the history. Defaults to `50` |
| `PASSWORD` | Required unless `PROTECTED=false`. Password for user to login. |
| `PORT` | Listen on this port. Defaults to `4000`. |
| `PROTECTED` | Require HTTP basic authentication (`USER`/`PASSWORD`) on every request. Defaults to `true`. See [Webhook secrets and authentication](#webhook-secrets-and-authentication). |
| `SECRETS_AZURE_DEVOPS` | Azure DevOps secret, the password of the service hook's basic authentication. Empty by default, which disables verification for this provider. |
| `SECRETS_BITBUCKET_SERVER` | Bitbucket Server / Data Center webhook secret (HMAC-SHA256). Empty by default, which disables verification for this provider. |
| `SECRETS_BITBUCKET` | Bitbucket Cloud webhook secret (HMAC-SHA256). Empty by default, which disables verification for this provider. |
| `SECRETS_GITEA` | Gitea webhook secret (HMAC-SHA256). Empty by default, which disables verification for this provider. |
| `SECRETS_GITHUB` | GitHub webhook secret (HMAC-SHA256). Empty by default, which disables verification for this provider. |
| `SECRETS_GITLAB` | GitLab secret token. Empty by default, which disables verification for this provider. |
| `TLS_CERT` | Path to the certificate file. Only required if TLS=true. |
| `TLS_KEY` | Path to the private key file. Only required if TLS=true. |
| `TLS` | Expect incoming HTTPS. Defaults to `false`. |
| `USER` | Login username to trigger hooks. Defauls to `puppet`. |
| `DEPLOY_ON_SUCCESS_ONLY` | Only run a deploy if checks pass. Defaults to `false` |

### Webhook secrets and authentication

By default the webhook is protected by HTTP basic authentication (`USER`/`PASSWORD`).
Git providers can also sign every payload with a shared secret, and `webhook-go` verifies that signature before it deploys anything.
Set `SECRETS_<PROVIDER>` to the same value you enter in the provider's webhook settings, for example the *Secret* field of a GitHub webhook:

```yaml
services:
  webhook:
    image: ghcr.io/voxpupuli/r10k-webhook:latest
    environment:
      - PUPPET_CONTROL_REPO=https://git.example.org/puppet/control.git
      - USER=puppet
      - PASSWORD=change-me
      - SECRETS_GITHUB=a-long-random-string
```

Only providers with a non-empty secret are written to the generated `webhook.yml`, an unset variable changes nothing.
The secrets end up in `/etc/voxpupuli/webhook/webhook.yml` inside the container, with mode `0660` (not readable by other users, but by group 0, like the rest of this image's files).

How the two mechanisms interact:

* **Both enabled (the default with a secret set)** is defense in depth: a request needs valid basic authentication *and* a valid signature.
  The sender must then be able to send the basic authentication credentials, which not every provider can do.
* **Secrets only** with `PROTECTED=false`: basic authentication is no longer required, so the credentials are not needed in the webhook URL, and `PASSWORD` can be left unset.
  The signature is the only protection, so set a secret for every provider you use.
* Setting any secret enables verification for the whole endpoint: a request that claims a provider without a configured secret is rejected with `401 Unauthorized`, and so is a request with a missing or wrong signature.
* `PROTECTED=false` with no secret leaves the endpoint open to anyone who can reach the port.
  The container only prints a warning in that case, so use it only behind something that authenticates requests, such as a reverse proxy.
* **Azure DevOps** sends the secret as the password of HTTP basic authentication.
  With `PROTECTED=true` the same `Authorization` header is checked twice, so the service hook's username must be `USER` and its password must equal both `PASSWORD` and `SECRETS_AZURE_DEVOPS`.
  With `PROTECTED=false` the username is ignored and the password must equal `SECRETS_AZURE_DEVOPS`.

For GitHub, create the webhook with the content type `application/json`, the same value in its *Secret* field as in `SECRETS_GITHUB`, and the payload URL `https://<your-server>/api/v1/r10k/environment`.
See the [webhook-go documentation](https://github.com/voxpupuli/webhook-go#secrets) for the other providers.
Secrets are supported since webhook-go `2.17.0`.

### Adding additional certificates to the container

If you somehow need own certificates inside the container, you can add them over the entrypoint script.

For example: you want to run the webhook on a target with your own ca certificates.
Export the `CERT_JSON` and the container will import it on runtime.
It is expected that the certificates are a json hash of PEM certificates.
It is preferable that the json is uglified into a onliner.

You may add this as a CI Variable for your runners on Github/Gitlab.

```json
{"certificates":{"root_ca":"-----BEGIN CERTIFICATE-----\n...","signing_ca":"-----BEGIN CERTIFICATE-----\n..."}}
```

## Build

### Build Arguments

| Name | Description |
| ---- | ----------- |
| `R10K_VERSION` | The R10k container version to use as base layer. |
| `WEBHOOK_GO_VERSION` | Version of webhook-go to install. |

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
| webhook-go.major | Describes the contained major webhook-go version |
| webhook-go.minor | Describes the contained minor webhook-go version |
| webhook-go.patch | Describes the contained patch webhook-go version |
| container.major | Describes breaking changes without backward compatibility |
| container.minor | Describes new features or refactoring with backward compatibility |
| container.patch | Describes if minor changes or bugfixes have been implemented |

## How to release?

see [RELEASE.md](RELEASE.md)

## How to contribute?

see [CONTRIBUTING.md](CONTRIBUTING.md)
