FROM golang:bullseye as builder

#------------------------------------------------------------------------------
# Create a statically linked Oniguruma library for Linux amd64
#------------------------------------------------------------------------------

# This will create /usr/local/lib/libonig.a

RUN cd /tmp && \
    curl -sLO https://github.com/kkos/oniguruma/releases/download/v6.9.9/onig-6.9.9.tar.gz && \
    tar xfz onig-6.9.9.tar.gz && \
    rm onig-6.9.9.tar.gz && \
    cd /tmp/onig-6.9.9 && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -r /tmp/onig-6.9.9

WORKDIR /go/src/github.com/fstab/grok_exporter
COPY . .
RUN ls /usr/local/lib/libonig.a
ENV CGO_LDFLAGS=/usr/local/lib/libonig.a
RUN go mod download
RUN go build -o /bin/grok-exporter
RUN git submodule update --init --recursive

FROM  gcr.io/distroless/base:nonroot

USER 65532:65532
COPY --from=builder /go/src/github.com/fstab/grok_exporter/logstash-patterns-core/patterns /patterns
COPY --from=builder /bin/grok-exporter /bin/grok-exporter
EXPOSE 9144

ENTRYPOINT [ "/bin/grok-exporter", "-config", "/grok/config.yml" ]