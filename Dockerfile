# Copied and modified from
# https://github.com/erisa/ts-derp-docker
# Thank you!

# Global arguments
ARG ALPINE_VERSION=3.22

## Build container

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS builder
LABEL org.opencontainers.image.source = https://github.com/skedastically/tswg

### Build argument(s)
ARG TAILSCALE_VERSION=v1.90.6

### Build dependancies
RUN apk add git bash curl --no-cache

ARG TARGETOS
ARG TARGETARCH

WORKDIR /build

### Clone the right version of Tailscale
RUN git clone https://github.com/tailscale/tailscale --depth=1 --branch ${TAILSCALE_VERSION} .

### Build all the needed binaries
RUN mkdir binout && GOOS=${TARGETOS} GOARCH=${TARGETARCH} ./tool/go build -o ./binout . ./cmd/tailscale ./cmd/tailscaled ./cmd/containerboot 

## Runtime container

FROM alpine:${ALPINE_VERSION}

### Runtime dependancies
RUN apk add --no-cache \
    nftables \
    iproute2 \
    wireguard-tools

COPY --from=builder /build/binout/* /usr/local/bin/
ENV TS_USERSPACE=false
ENV TS_DEBUG_FIREWALL_MODE=nftables

COPY ./wg-quick /usr/bin/wg-quick
COPY init.sh /init.sh
RUN chmod +x /usr/bin/wg-quick /init.sh

ENTRYPOINT ["/init.sh"]
