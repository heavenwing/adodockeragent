FROM mcr.microsoft.com/dotnet/sdk:7.0-jammy

ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_IMAGE_NAME_TEMPLATE="heavenwing/adodockeragent/playwright-dotnet:7.0-jammy"

# === INSTALL dependencies ===

RUN apt-get update && \
    # Feature-parity with node.js base images.
    apt-get install -y --no-install-recommends git openssh-client curl gpg && \
    # clean apt cache
    # rm -rf /var/lib/apt/lists/* && \
    # Create the pwuser
    adduser pwuser

# === BAKE BROWSERS INTO IMAGE ===

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# 1. Add tip-of-tree Playwright package to install its browsers.
#    The package should be built beforehand from tip-of-tree Playwright.
#COPY ./dist/* /tmp/

# 2. Bake in browsers & deps.
#    Browsers will be downloaded in `/ms-playwright`.
#    Note: make sure to set 777 to the registry so that any user can access
#    registry.
RUN mkdir /ms-playwright && \
    mkdir /ms-playwright-agent && \
    cd /ms-playwright-agent && \
    dotnet new console && \
    #echo '<?xml version="1.0" encoding="utf-8"?><configuration><packageSources><add key="local" value="/tmp/"/></packageSources></configuration>' > nuget.config && \
    # dotnet add package Microsoft.Playwright --prerelease && \
    dotnet add package Microsoft.Playwright && \
    dotnet build && \
    ./bin/Debug/net7.0/playwright.ps1 install --with-deps && \
    ./bin/Debug/net7.0/playwright.ps1 mark-docker-image "${DOCKER_IMAGE_NAME_TEMPLATE}" && \
    # rm -rf /var/lib/apt/lists/* && \
    # rm -rf /tmp/* && \
    rm -rf /ms-playwright-agent && \
    chmod -R 777 /ms-playwright

# 3. install more softwares
RUN apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    wget

RUN rm -rf /var/lib/apt/lists/*

# NOTE: Workaround for devops agent not supporting OpenSSL 3.0
# https://github.com/microsoft/azure-pipelines-agent/issues/3834#issuecomment-1160576447
RUN curl -sL http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb > libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# https://github.com/microsoft/azure-pipelines-agent/issues/3834#issuecomment-1151874312
RUN sed -i 's/openssl_conf = openssl_init/#openssl_conf = openssl_init/g' /etc/ssl/openssl.cnf

# 4. start to install azure cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]