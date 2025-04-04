ARG R10K_VERSION=5.0.0

FROM docker.io/library/golang:alpine AS builder
ARG WEBHOOK_GO_VERSION=2.9.0

RUN apk add --no-cache ca-certificates

WORKDIR /build

RUN wget -qO - https://github.com/voxpupuli/webhook-go/archive/refs/tags/v$WEBHOOK_GO_VERSION.tar.gz | tar xfz - -C ./ --strip-components 1
RUN go mod download
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o ./webhook-go

FROM ghcr.io/voxpupuli/r10k:$R10K_VERSION-latest

ENV USER="puppet"
ENV PASSWORD
ENV PORT=4000
ENV TLS=false
ENV DEFAULT_BRANCH="production"
ENV GENERATE_TYPES=true

USER root

COPY --from=builder --chmod=755 /build/webhook-go /usr/sbin/webhook-go
COPY --chmod=755 webhook/docker-entrypoint.sh /docker-entrypoint.sh
COPY webhook/docker-entrypoint.d /docker-entrypoint.d
COPY Dockerfile /

EXPOSE 4000
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ "server", "--config", "/etc/webhook.yml" ]
