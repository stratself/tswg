# syntax=docker/dockerfile:1

# Copied and modified from
# https://github.com/erisa/ts-derp-docker
# Thank you!

# Global arguments
ARG ALPINE_VERSION=3.23

## Build container
FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS builder

### Build argument(s)
ARG TARGETOS TARGETARCH TAILSCALE_VERSION=v1.92.3

WORKDIR /build

### Build
RUN <<HEREDOC

# install dependencies
apk -U add --no-cache git bash curl
# clone repo on defined version branch
git clone --depth=1 --branch ${TAILSCALE_VERSION} https://github.com/tailscale/tailscale .
mkdir binout

# build tailscaled and containerboot
GOOS=${TARGETOS} GOARCH=${TARGETARCH} ./tool/go build -o ./binout . ./cmd/tailscale ./cmd/tailscaled ./cmd/containerboot 

HEREDOC

## Runtime container
FROM alpine:${ALPINE_VERSION}

### Runtime dependancies
RUN apk add --no-cache wireguard-tools nftables dante-server

### Copy files
COPY --from=builder /build/binout/* /usr/local/bin/
COPY --chmod=+x ./wg-quick /usr/bin/wg-quick
COPY --chmod=+x init.sh /init.sh
COPY sockd.conf /etc/sockd.conf

### Define default env vars and entrypoint
ENV TS_USERSPACE=false TS_DEBUG_FIREWALL_MODE=nftables
ENTRYPOINT ["/init.sh"]

### Add labels
LABEL org.opencontainers.image.title="tswg"
LABEL org.opencontainers.image.description="Tailscale + WireGuard exit node"
LABEL org.opencontainers.image.authors="https://github.com/stratself"
LABEL org.opencontainers.image.source="https://github.com/stratself/tswg"
