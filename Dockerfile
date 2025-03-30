FROM ubuntu:latest

ENV VERSION="0.8.5"
ENV ARCH="linux_amd64"

WORKDIR /app
RUN apt update -y
RUN apt install -y wget
RUN wget -O helios.tar.gz https://github.com/a16z/helios/releases/download/${VERSION}/helios_${ARCH}.tar.gz
RUN tar -xvzf helios.tar.gz -C /app
RUN rm -rf /app/helios.tar.gz

CMD ["/app/helios", "ethereum", "--rpc-bind-ip", "0.0.0.0", "--execution-rpc", "${ETH_RPC_URL}", "--consensus-rpc", "${CONSENSUS_RPC}"]