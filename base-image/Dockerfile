# SPDX-FileCopyrightText: 2022, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Yocto Geniux base image to help building Geniux.

FROM ubuntu:18.04
LABEL version="1.4" description="Yocto Geniux base image" maintainer="carles.fernandez@cttc.es"

# Install all Linux packages required for Yocto builds, plus other packages used
# in this file below, and in the interactive mode
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
  apt-transport-https \
  base-files \
  bc \
  build-essential \
  ca-certificates \
  chrpath \
  cpio \
  curl \
  debianutils \
  diffstat \
  gawk \
  gcc-multilib \
  git \
  git-lfs \
  gnupg-agent \
  gzip \
  iproute2 \
  iputils-ping \
  libegl1-mesa \
  liblz4-tool \
  libsdl1.2-dev \
  locales \
  mesa-common-dev \
  nano \
  pwgen \
  pylint3 \
  python \
  python3 \
  python3-git \
  python3-jinja2 \
  python3-pexpect \
  python3-pip \
  python3-subunit \
  socat \
  software-properties-common \
  sudo \
  tar \
  texinfo \
  unzip \
  util-linux \
  wget \
  whois \
  xterm \
  xxd \
  xz-utils \
  zstd \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the
# source command needed for setting up Yocto build environments. Use bash as an
# alias for sh.
RUN which dash &> /dev/null && (\
  echo "dash dash/sh boolean false" | debconf-set-selections && \
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash) || \
  echo "Skipping dash reconfigure (not applicable)"

# Install docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable" && apt-get update && DEBIAN_FRONTEND=noninteractive \
  apt-get -y install docker-ce docker-ce-cli containerd.io \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install the repo tool to handle git submodules (meta layers) comfortably.
ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 755 /usr/local/bin/repo
