# Build stage
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder

RUN apk add --no-cache gcc musl-dev

WORKDIR /build

COPY go.mod ./
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod tidy

ARG TARGETOS
ARG TARGETARCH
ARG BUILDPLATFORM

RUN --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" \
    -o milky-ob11-bridge \
    ./cmd/milky-ob11-bridge

# Final stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /build/milky-ob11-bridge .
COPY config.example.json .

RUN adduser -D -u 1000 appuser

USER appuser

ENTRYPOINT ["/app/milky-ob11-bridge"]
