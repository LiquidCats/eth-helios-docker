FROM ubuntu:25.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

RUN apt-get update -y && apt-get install -y curl

# Install helios with error handling
RUN curl -fsSL https://raw.githubusercontent.com/a16z/helios/master/heliosup/install | bash && \
    ~/.helios/bin/heliosup

# Final runtime image
FROM ubuntu:25.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV RPC_URL="https://eth-mainnet.g.alchemy.com/v2/"
ENV CONSENSUS_RPC="https://www.lightclientdata.org"
ENV CHECKPOINT="0x91cb79fd1e8120e7ec20ec22dbbee74acec7bba98f50dbfb8abadf7fae7c71a5"
ENV PATH="/home/helios/.helios/bin:${PATH}"

# Install runtime dependencies and create user in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        # Add any other runtime dependencies here
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Create non-root user
RUN groupadd -r helios && useradd -r -g helios -m -d /home/helios -s /bin/bash helios

# Copy helios installation from builder with proper ownership
COPY --from=builder --chown=helios:helios /root/.helios /home/helios/.helios

# Switch to non-root user
USER helios
WORKDIR /home/helios

# Expose port
EXPOSE 8545

CMD ["bash", "-c", "helios ethereum --rpc-bind-ip 0.0.0.0 --execution-rpc ${RPC_URL}$(cat /run/secrets/api_key) --consensus-rpc ${CONSENSUS_RPC} --checkpoint ${CHECKPOINT}"]