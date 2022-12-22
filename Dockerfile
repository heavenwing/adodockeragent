FROM ubuntu:22.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    wget \
    python3 \
    python3-pip \
    python3-venv

# TODO: Workaround for devops agent not supporting OpenSSL 3.0
# https://github.com/microsoft/azure-pipelines-agent/issues/3834#issuecomment-1160576447
RUN curl -sL http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb > libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# https://github.com/microsoft/azure-pipelines-agent/issues/3834#issuecomment-1151874312
RUN sed -i 's/openssl_conf = openssl_init/#openssl_conf = openssl_init/g' /etc/ssl/openssl.cnf

RUN curl -ksSL https://httprunner.com/script/install.sh | bash

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]