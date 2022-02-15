# SPDX-FileCopyrightText: 2020-2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Docker image to build Geniux images.

FROM yocto-geniux-base:v1.2
LABEL version="2.1" description="Geniux builder" maintainer="carles.fernandez@cttc.es"

ARG version=dunfell
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

# The running container writes all the build artefacts to a host directory
# (outside the container). The container can only write files to host
# directories, if it uses the same user ID and group ID owning the host
# directories. The host_uid and group_uid are passed to the docker build command
# with the --build-arg option. By default, they are both 1001. The docker image
# creates a group with host_gid and a user with host_uid and adds the user to
# the group. The symbolic name of the group and user is geniux.
RUN groupadd -g $host_gid $USER_NAME && useradd -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# Always get latest packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && apt-get clean && rm -rf /var/lib/apt/lists/*

# Perform the Yocto build as user geniux (not as root).
# By default, docker runs as root. However, Yocto builds should not be run as
# root, but as a normal user. Hence, we switch to the newly created user geniux.
USER $USER_NAME
ENV BUILD_INPUT_DIR /home/$USER_NAME/yocto/input
ENV BUILD_OUTPUT_DIR /home/$USER_NAME/yocto/output
RUN mkdir -p $BUILD_INPUT_DIR $BUILD_OUTPUT_DIR

RUN sudo usermod -aG docker $USER_NAME && newgrp docker

WORKDIR $BUILD_INPUT_DIR

RUN if [ "$manifest_date" = "latest" ] ; then \
  repo init -u https://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b $version --repo-url=https://gerrit.googlesource.com/git-repo --repo-rev=stable ; \
  else \
  repo init -u https://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b refs/tags/$version-$manifest_date --repo-url=https://gerrit.googlesource.com/git-repo --repo-rev=stable ; \
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
  echo "" | sudo -S mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/ && \
  rm ./downloads/*.done && \
  rm -rf ./downloads/git2 && \
  sudo mv ./downloads /home/geniux/yocto/output/ && \
  sudo mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/ ; \
  fi
