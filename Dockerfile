# ---------- build stage ----------
    FROM --platform=$BUILDPLATFORM golang:1.26.1 AS builder

    ARG TARGETOS
    ARG TARGETARCH
    ARG GOBUSTER_VERSION=v3.8.2
    
    WORKDIR /app
    
    ENV GOPROXY=https://proxy.golang.org,direct
    ENV CGO_ENABLED=0
    
    # install deps
    RUN apt-get update \
        && apt-get install -y --no-install-recommends ca-certificates git \
        && rm -rf /var/lib/apt/lists/*
    
    # cache go mod
    COPY go.mod go.sum ./
    RUN go mod download
    
    # copy source
    COPY . .
    
    # build gobuster (strict version) + burstui
    RUN git clone --depth 1 --branch ${GOBUSTER_VERSION} https://github.com/OJ/gobuster.git /tmp/gobuster \
        && GOOS=$TARGETOS GOARCH=$TARGETARCH go build -C /tmp/gobuster -o /usr/local/bin/gobuster . \
        && GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/burstui .
    
    # ---------- runtime stage ----------
    FROM debian:bookworm-slim
    
    WORKDIR /app
    
    ENV DEBIAN_FRONTEND=noninteractive
    
    RUN apt-get update \
        && apt-get install -y --no-install-recommends ca-certificates \
        && rm -rf /var/lib/apt/lists/*
    
    # copy binaries
    COPY --from=builder /usr/local/bin/gobuster /usr/local/bin/gobuster
    COPY --from=builder /usr/local/bin/burstui /usr/local/bin/burstui
    
    CMD ["burstui"]
    