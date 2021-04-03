# SPDX-FileCopyrightText: 2020, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: Apache-2.0
#
# Docker image to build Yocto images for GNSS-SDR.
# Adapted from https://github.com/bstubert/dr-yocto, by Burkhard Stubert

FROM ubuntu:18.04

# Install all Linux packages required for Yocto builds, plus other packages used
# in this file below, and in the interactive mode
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    pylint3 xterm git-lfs locales sudo apt-transport-https ca-certificates curl xdd \
    gnupg-agent software-properties-common nano && apt-get clean && rm -rf /var/lib/apt/lists/*

# By default, Ubuntu uses dash as an alias for sh. Dash does not support the source command
# needed for setting up Yocto build environments. Use bash as an alias for sh.
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

ARG version=thud
ARG manifest_date=latest
ARG MACHINE=zedboard-zynq7
ARG host_uid=1001
ARG host_gid=1001

# Set up a local mirror
ENV LOCAL_MIRROR /source_mirror/sources/$version
RUN mkdir -p $LOCAL_MIRROR

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Add user "geniux" to sudoers. Then, the user can install Linux packages in the container.
ENV USER_NAME geniux
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
    chmod 0440 /etc/sudoers.d/${USER_NAME}

# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The host_uid and group_uid are passed to the docker build
# command with the --build-arg option. By default, they are both 1001. The docker image creates
# a group with host_gid and a user with host_uid and adds the user to the group. The symbolic
# name of the group and user is geniux.
RUN groupadd -g $host_gid $USER_NAME && useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# Perform the Yocto build as user geniux (not as root).
# By default, docker runs as root. However, Yocto builds should not be run as root, but as a
# normal user. Hence, we switch to the newly created user geniux.
USER $USER_NAME
ENV BUILD_INPUT_DIR /home/$USER_NAME/yocto/input
ENV BUILD_OUTPUT_DIR /home/$USER_NAME/yocto/output
RUN mkdir -p $BUILD_INPUT_DIR $BUILD_OUTPUT_DIR

RUN sudo usermod -aG docker $USER_NAME && newgrp docker

WORKDIR $BUILD_INPUT_DIR

RUN if [ "$manifest_date" = "latest" ] ; then \
    repo init -u git://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b $version ; \
    else \
    repo init -u git://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b refs/tags/$version-$manifest_date ; \
    fi

RUN repo sync
ENV MACHINE=$MACHINE
ENV TEMPLATECONF=$BUILD_INPUT_DIR/meta-gnss-sdr/conf
RUN echo "/bin/echo -e \"\nWelcome to the Yocto-Geniux container.\nRelease version: $version $manifest_date\n\nThis is the interactive mode. Warm hugs, you brave developer!\nYou are still on time to change the MACHINE environment variable (default: $MACHINE), change and/or add recipes, etc.\nTo set up the building environment, type:\n  source ./oe-core/oe-init-build-env ./build ./bitbake\nand you will be ready to bitbake like there is no tomorrow.\nSee https://github.com/carlesfernandez/yocto-geniux/blob/main/README.md for details.\n\n\"" \
    >> /home/$USER_NAME/.bashrc

CMD if [ "$host_git" = "1001" ]; then \
    source ./oe-core/oe-init-build-env ./build ./bitbake && \
    sudo service docker start && \
    bitbake gnss-sdr-dev-image && \
    bitbake -c populate_sdk gnss-sdr-dev-image && \
    bitbake gnss-sdr-demo-image && \
    bitbake gnss-sdr-dev-docker && \
    sudo mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/ && \
    rm ./downloads/*.done && \
    rm -rf ./downloads/git2 && \
    sudo mv ./downloads /home/geniux/yocto/output/ && \
    sudo mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/ ; \
      else \
    source ./oe-core/oe-init-build-env ./build ./bitbake && \
    echo "" | sudo -S service docker start && \
    bitbake gnss-sdr-dev-image && \
    bitbake -c populate_sdk gnss-sdr-dev-image && \
    bitbake gnss-sdr-demo-image && \
    bitbake gnss-sdr-dev-docker && \
    mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/ && \
    rm ./downloads/*.done && \
    rm -rf ./downloads/git2 && \
    mv ./downloads /home/geniux/yocto/output/ && \
    mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/ ; \
    fi
