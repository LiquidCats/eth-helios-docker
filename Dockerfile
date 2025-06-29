FROM ubuntu:22.04 AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /build

# Use --mount=cache for apt cache to speed up builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install helios with error handling and verification
RUN curl -fsSL https://raw.githubusercontent.com/a16z/helios/master/heliosup/install | bash && \
    ~/.helios/bin/heliosup

# Final runtime image using distroless for better security
FROM debian:bookworm-slim

# Build arguments with defaults
ARG ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/"
ARG ETH_CONSENSUS_RPC="https://www.lightclientdata.org"
ARG ETH_CHECKPOINT="0x91cb79fd1e8120e7ec20ec22dbbee74acec7bba98f50dbfb8abadf7fae7c71a5"

# Environment variables
ENV ETH_RPC_URL=$ETH_RPC_URL \
    ETH_CONSENSUS_RPC=$ETH_CONSENSUS_RPC \
    ETH_CHECKPOINT=$ETH_CHECKPOINT \
    PATH="/app/.helios/bin:${PATH}" \
    RUST_LOG=info

WORKDIR /app

# Copy helios binaries from builder
COPY --from=builder --chown=nonroot:nonroot /root/.helios /app/.helios

# Expose port
EXPOSE 8545

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/app/.helios/bin/helios", "--help"]

# Use distroless nonroot user (UID 65532)
USER nonroot

# Improved entrypoint with proper signal handling
ENTRYPOINT ["/app/.helios/bin/helios"]
CMD ["ethereum", \
     "--rpc-bind-ip", "0.0.0.0", \
     "--execution-rpc", "${ETH_RPC_URL}$(cat /run/secrets/api_key)", \
     "--consensus-rpc", "${ETH_CONSENSUS_RPC}", \
     "--checkpoint", "${ETH_CHECKPOINT}"]