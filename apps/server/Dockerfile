# ==============================================================================
# Multi-stage Dockerfile for Simo Go Backend Server
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build binary
# ------------------------------------------------------------------------------
FROM golang:alpine AS builder

WORKDIR /build

# Install git and ca-certificates for fetching dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Cache go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy source files
COPY . .

# Build API server binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /build/simo-server ./cmd/server
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /build/simo-migrate ./cmd/migrate

# ------------------------------------------------------------------------------
# Stage 2: Runtime Image
# ------------------------------------------------------------------------------
FROM alpine:3.21

WORKDIR /app

# Install minimal certificates and timezone data
RUN apk --no-cache add ca-certificates tzdata

# Copy built binaries and migration files from builder
COPY --from=builder /build/simo-server /app/simo-server
COPY --from=builder /build/simo-migrate /app/simo-migrate
COPY --from=builder /build/migrations /app/migrations

# Expose API port
EXPOSE 8080

# Default command
CMD ["/app/simo-server"]
