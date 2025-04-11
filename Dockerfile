ARG DEBIAN_VERSION=bookworm
FROM golang:${DEBIAN_VERSION} AS cgo_builder
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install --no-install-recommends clang

WORKDIR /build
# We copy the depenencies first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY internal ./internal
COPY server ./server
COPY types ./types

ENV CGO_ENABLED=1
ENV CC=clang
ENV CGO_CFLAGS="-fPIC"
ENV CXX=clang++
ENV CGO_CPPFLAGS="-fPIC"
ENV CGO_CXXFLAGS="-fPIC"

RUN go build -x -o /go/bin/bigquery-emulator \
    # We removed this to fix static link bugs on arm.
    -ldflags "-s -w -linkmode=external" \
    ./cmd/bigquery-emulator
RUN rm -rf /tmp/*

FROM debian:${DEBIAN_VERSION}

COPY --from=cgo_builder /go/bin/bigquery-emulator /bin/bigquery-emulator
# COPY --from=cgo_builder /tmp /tmp
# COPY --from=cgo_builder /usr/share/zoneinfo/ /usr/share/zoneinfo

WORKDIR /work

ENTRYPOINT ["/bin/bigquery-emulator"]
