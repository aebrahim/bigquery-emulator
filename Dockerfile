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
ENV CFLAGS="-fPIC"
ENV CXX=clang++
ENV CXXFLAGS="-fPIC"

RUN go build -o /go/bin/bigquery-emulator \
    -ldflags "-linkmode=external -extldflags -static" \
    ./cmd/bigquery-emulator
RUN rm -rf /tmp/*

FROM scratch

COPY --from=cgo_builder /go/bin/bigquery-emulator /bin/bigquery-emulator
COPY --from=cgo_builder /tmp /tmp
COPY --from=cgo_builder /usr/share/zoneinfo/ /usr/share/zoneinfo

WORKDIR /work

ENTRYPOINT ["/bin/bigquery-emulator"]
