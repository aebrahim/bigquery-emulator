ARG DEBIAN_VERSION=bookworm
FROM golang:${DEBIAN_VERSION} AS cgo_builder
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y install --no-install-recommends clang

ENV CGO_ENABLED=1
ENV CXX=clang++

WORKDIR /build
# We copy the depenencies first to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY internal ./internal
COPY server ./server
COPY types ./types
RUN go build -o /go/bin/bigquery-emulator ./cmd/bigquery-emulator

FROM debian:${DEBIAN_VERSION}

COPY --from=cgo_builder /go/bin/bigquery-emulator /bin/bigquery-emulator

WORKDIR /work

ENTRYPOINT ["/bin/bigquery-emulator"]
