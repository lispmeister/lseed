FROM golang:1.13-alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Pass a tag, branch or a commit using build-arg.  This allows a docker
# image to be built from a specified Git state.  The default image
# will use the Git tip of master by default.
ARG checkout="master"

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk \
    git \
&&  git clone https://github.com/lispmeister/lseed /go/src/github.com/lispmeister/lseed \
&&  cd /go/src/github.com/lispmeister/lseed \
&&  git checkout $checkout \
&&  go build .

# Start a new, final image.
FROM alpine as final

# Define a root volume for data persistence.
VOLUME /root/.lseed

# Add bash and ca-certs, for quality of life and SSL-related reasons.
RUN apk --no-cache add \
    bash \
    ca-certificates

# Copy the binaries from the builder image.
COPY --from=builder /go/src/github.com/lispmeister/lseed/lseed /lseed

# Expose lnd ports (p2p, rpc).
EXPOSE 53/udp 53/tcp

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["/lseed"]
