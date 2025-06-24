FROM ubuntu

ARG TARGETPLATFORM

ARG VERSION="0.9.0"

ARG ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/"
ARG ETH_CONSENSUS_RPC="https://www.lightclientdata.org"
ARG ETH_CHECKPOINT="0x4ac4e558e522d43588f743cd81f85785b12da5b704b4cd03c259ff98ff56227e"

ENV VERSION=$VERSION

ENV ETH_RPC_URL=$ETH_RPC_URL
ENV ETH_CONSENSUS_RPC=$ETH_CONSENSUS_RPC
ENV ETH_CHECKPOINT=$ETH_CHECKPOINT

WORKDIR /app

RUN case "${TARGETPLATFORM}" in \
       "linux/amd64") export ARCH=linux_amd64 ;; \
       "linux/arm64") export ARCH=linux_arm64 ;; \
       "linux/arm64/v8") export ARCH=linux_arm64 ;; \
       *) echo "Unsupported platform ${TARGETPLATFORM}" && exit 1 ;; \
    esac && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    wget -qO helios.tar.gz \
         "https://github.com/a16z/helios/releases/download/${VERSION}/helios_${ARCH}.tar.gz" && \
    tar -xzf helios.tar.gz -C /usr/local/bin && \
    rm -rf /var/lib/apt/lists/* helios.tar.gz

EXPOSE 8545

CMD ["bash", "-c", "helios ethereum --rpc-bind-ip 0.0.0.0 --execution-rpc ${ETH_RPC_URL}$(cat /run/secrets/api_key) --consensus-rpc ${ETH_CONSENSUS_RPC} --checkpoint ${ETH_CHECKPOINT}"]