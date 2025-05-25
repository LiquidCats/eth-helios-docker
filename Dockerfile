FROM ubuntu:latest

ENV VERSION="0.8.8"
ENV ARCH="linux_amd64"

ENV ETH_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/XXXXX"
ENV ETH_CONSENSUS_RPC="https://www.lightclientdata.org"
ENV ETH_CHECKPOINT="0xb7ffa93f3d9aa50ca39de19a6a8a94dc9be91a89d0848dd3526eb3ce1fcaa601"

WORKDIR /app
RUN apt update -y
RUN apt install -y wget
RUN wget -O helios.tar.gz https://github.com/a16z/helios/releases/download/${VERSION}/helios_${ARCH}.tar.gz
RUN tar -xvzf helios.tar.gz -C /app
RUN rm -rf /app/helios.tar.gz

CMD ["bash", "-c", "/app/helios ethereum --rpc-bind-ip 0.0.0.0 --execution-rpc ${ETH_RPC_URL} --consensus-rpc ${ETH_CONSENSUS_RPC} --checkpoint ${ETH_CHECKPOINT}"]