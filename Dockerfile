# We do not use --platform feature to auto fill this ARG because of incompatibility between podman and docker
ARG TARGETARCH=amd64

# Build the manager binary
FROM docker.io/library/golang:1.22 as builder

ARG TARGETARCH
ARG TARGETPLATFORM
ARG VERSION="unknown"

WORKDIR /opt/app-root

COPY cmd cmd
COPY main.go main.go
COPY go.mod go.mod
COPY go.sum go.sum
COPY commands/ commands/
COPY res/ res/
COPY scripts/ scripts/
COPY vendor/ vendor/
COPY Makefile Makefile
COPY .mk/ .mk/

# Build collector
RUN GOARCH=$TARGETARCH make compile

# Embedd commands in case users want to pull it from collector image
RUN USER=netobserv VERSION=main make oc-commands

# Prepare output dir
RUN mkdir -p output

# Create final image from ubi + built binary and command
FROM --platform=linux/$TARGETARCH registry.access.redhat.com/ubi9/ubi:9.4
WORKDIR /
COPY --from=builder /opt/app-root/build .
COPY --from=builder --chown=65532:65532 /opt/app-root/output /output
USER 65532:65532

ENTRYPOINT ["/network-observability-cli"]
