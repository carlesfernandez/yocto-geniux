# SPDX-FileCopyrightText: 2022-2025, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Yocto Geniux base image to help building Geniux.

FROM ubuntu:18.04
LABEL version="1.10" description="Yocto Geniux base image" maintainer="carles.fernandez@cttc.es"

# Install all Linux packages required for Yocto builds, plus other packages used
# in this file below, and in the interactive mode
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
  apt \
  apt-transport-https \
  atop \
  base-files \
  bash \
  bc \
  bsdutils \
  build-essential \
  ca-certificates \
  chrpath \
  cpio \
  curl \
  debianutils \
  diffstat \
  distro-info-data \
  fdisk \
  gawk \
  gcc-multilib \
  git \
  git-lfs \
  gnupg-agent \
  gzip \
  iproute2 \
  iputils-ping \
  libbz2-dev \
  libegl1-mesa \
  libffi-dev \
  libgdbm-dev \
  liblzma5 \
  liblz4-tool \
  libncurses5-dev \
  libnss3-dev \
  libpython2.7-minimal \
  libpython2.7-stdlib \
  libpython3.6 \
  libpython3.6-dev \
  libpython3.6-minimal \
  libpython3.6-stdlib \
  libreadline-dev \
  libsdl1.2-dev \
  libsqlite3-dev \
  libssl-dev \
  libzstd1 \
  libzstd-dev \
  linux-libc-dev \
  locales \
  login \
  mesa-common-dev \
  mount \
  nano \
  networkd-dispatcher \
  passwd \
  pkg-config \
  pwgen \
  pylint3 \
  python \
  python2.7 \
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
  tmux \
  ubuntu-keyring \
  unzip \
  util-linux \
  vim \
  wget \
  whois \
  xterm \
  xxd \
  xz-utils \
  zlib1g \
  zlib1g-dev \
  zstd \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Install docker and upgrade packages
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable" && apt update && DEBIAN_FRONTEND=noninteractive \
  apt install -y docker-ce docker-ce-cli containerd.io \
  && DEBIAN_FRONTEND=noninteractive apt -y upgrade \
  && apt clean && rm -rf /var/lib/apt/lists/*

# Build and install Python 3.11, required by repo
RUN wget https://www.python.org/ftp/python/3.11.4/Python-3.11.4.tgz \
  && tar -xf Python-3.11.*.tgz && cd Python-3.11.*/ \
  && ./configure --enable-optimizations && make && make altinstall \
  && cd .. && rm Python-3.11.*.tgz && rm -rf Python-3.11.*/

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the
# source command needed for setting up Yocto build environments. Use bash as an
# alias for sh.
RUN which dash &> /dev/null && (\
  echo "dash dash/sh boolean false" | debconf-set-selections && \
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash) || \
  echo "Skipping dash reconfigure (not applicable)"

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

