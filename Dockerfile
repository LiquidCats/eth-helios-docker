# Use a specific version for reproducibility
FROM ubuntu:22.04 AS builder

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

WORKDIR /build

# Install dependencies in a single layer to reduce image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create helios user early to avoid permission issues
RUN groupadd -r helios && useradd -r -g helios -m -d /home/helios -s /bin/bash helios

# Switch to helios user for installation
USER helios
WORKDIR /home/helios

# Install helios with error handling
RUN curl -fsSL https://raw.githubusercontent.com/a16z/helios/master/heliosup/install | bash && \
    ~/.helios/bin/heliosup

# Final runtime image
FROM ubuntu

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Build arguments with better defaults
ARG ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/"
ARG ETH_CONSENSUS_RPC="https://www.lightclientdata.org"
ARG ETH_CHECKPOINT="0x91cb79fd1e8120e7ec20ec22dbbee74acec7bba98f50dbfb8abadf7fae7c71a5"

# Environment variables
ENV ETH_RPC_URL=$ETH_RPC_URL \
    ETH_CONSENSUS_RPC=$ETH_CONSENSUS_RPC \
    ETH_CHECKPOINT=$ETH_CHECKPOINT \
    PATH="/home/helios/.helios/bin:${PATH}"

# Install runtime dependencies and create user in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        # Add any other runtime dependencies here
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Create non-root user
    groupadd -r helios && \
    useradd -r -g helios -m -d /home/helios -s /bin/bash helios

# Set working directory
WORKDIR /app

# Copy helios installation from builder with proper ownership
COPY --from=builder --chown=helios:helios /home/helios/.helios /home/helios/.helios

# Switch to non-root user
USER helios

# Expose port
EXPOSE 8545

CMD ["bash", "-c", "helios ethereum --rpc-bind-ip 0.0.0.0 --execution-rpc ${ETH_RPC_URL}$(cat /run/secrets/api_key) --consensus-rpc ${ETH_CONSENSUS_RPC} --checkpoint ${ETH_CHECKPOINT}"]