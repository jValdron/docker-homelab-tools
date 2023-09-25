# Common getter stage
FROM debian:bookworm AS getter
WORKDIR /tmp/
RUN apt update && apt install -y unzip wget

# PERCCLI
FROM getter AS perccli
RUN wget https://dl.dell.com/FOLDER07815522M/1/PERCCLI_7.1910.00_A12_Linux.tar.gz --user-agent="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36" \
    && tar -xf /tmp/PERCCLI_7.1910.00_A12_Linux.tar.gz

# sas2flash
FROM getter AS sas2flash
RUN wget https://docs.broadcom.com/docs-and-downloads/host-bus-adapters/host-bus-adapters-common-files/sas_sata_6g_p20/Installer_P20_for_Linux.zip && \
    unzip Installer_P20_for_Linux.zip

# Final stage
FROM ubuntu:focal
LABEL org.opencontainers.image.source=https://github.com/octocat/my-repo
LABEL org.opencontainers.image.description="My container image"
LABEL org.opencontainers.image.licenses=MIT
ENV PATH="$PATH:/opt/MegaRAID/perccli/"
WORKDIR /tmp/

# Copy over tools from other stages
COPY --from=perccli /tmp/PERCCLI_7.1910.00_A12_Linux/perccli_007.1910.0000.0000_all.deb .
RUN dpkg -i perccli_007.1910.0000.0000_all.deb \
    && rm perccli_007.1910.0000.0000_all.deb

COPY --from=sas2flash /tmp/Installer_P20_for_Linux/sas2flash_linux_i686_x86-64_rel/sas2flash /usr/local/bin/sas2flash

# Install additional tools
RUN apt update && \
    apt install libncurses5 pciutils -y

# Setup fish
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --quiet && \
    apt-get install --quiet --yes software-properties-common openssh-client git && \
    add-apt-repository --yes ppa:fish-shell/release-3 && \
    apt-get install --quiet --yes fish

RUN apt-get clean

SHELL ["fish", "--command"]

RUN chsh -s /usr/bin/fish

ENV SHELL /usr/bin/fish
ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8

ENTRYPOINT ["fish"]