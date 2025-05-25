FROM debian:stable-slim

ARG TARGETPLATFORM

ARG VERSION="0.8.8"

ARG ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/XXXXX"
ARG ETH_CONSENSUS_RPC="https://www.lightclientdata.org"
ARG ETH_CHECKPOINT="0x0d1439c329e16197e96307285519f3a5c3f936a0eb9be635fd337c8c2b656e4e"

ENV VERSION=$VERSION

ENV ETH_RPC_URL=$ETH_RPC_URL
ENV ETH_CONSENSUS_RPC=$ETH_CONSENSUS_RPC
ENV ETH_CHECKPOINT=$ETH_CHECKPOINT

WORKDIR /app

RUN case "${TARGETPLATFORM}" in \
        "linux/amd64") HELIOS_ARCH=linux_amd64 ;; \
        "linux/arm64") HELIOS_ARCH=linux_arm64 ;; \
        *) echo "unsupported ${TARGETPLATFORM}" && exit 1 ;; \
    esac
RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y wget ca-certificates

RUN echo "https://github.com/a16z/helios/releases/download/${VERSION}/helios_${HELIOS_ARCH}.tar.gz"

RUN wget -O helios.tar.gz https://github.com/a16z/helios/releases/download/${VERSION}/helios_${HELIOS_ARCH}.tar.gz
RUN tar -xvzf helios.tar.gz -C /app
RUN rm -rf /app/helios.tar.gz

CMD ["bash", "-c", "/app/helios ethereum --rpc-bind-ip 0.0.0.0 --execution-rpc ${ETH_RPC_URL} --consensus-rpc ${ETH_CONSENSUS_RPC} --checkpoint ${ETH_CHECKPOINT}"]