# SPDX-FileCopyrightText: 2020-2025, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Docker image to build Geniux images.

ARG base_image_version=1.10
FROM yocto-geniux-base:v${base_image_version}
LABEL version="3.4" description="Geniux builder" maintainer="carles.fernandez@cttc.es"

ARG version=scarthgap
ARG manifest_date=latest
ARG MACHINE=raspberrypi5
ARG host_uid=1001
ARG host_gid=1001
ARG BUILD_NEW_TEMPLATE

# Set up a local mirror
ENV LOCAL_MIRROR=/source_mirror/sources/$version
RUN mkdir -p $LOCAL_MIRROR

# Add user "geniux" to sudoers. Then, the user can install Linux packages in the container.
ENV USER_NAME=geniux
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
RUN apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y && apt clean && rm -rf /var/lib/apt/lists/*

# Install the repo tool to handle git submodules (meta layers) comfortably.
ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/
RUN chmod 777 /usr/local/bin/repo

# Remove hard limit in Docker ulimit
RUN sed -i -r 's/ulimit \-Hn/ulimit \-n/g' /etc/init.d/docker

# Perform the Yocto build as user geniux (not as root).
# By default, docker runs as root. However, Yocto builds should not be run as
# root, but as a normal user. Hence, we switch to the newly created user geniux.
USER $USER_NAME
ENV BUILD_INPUT_DIR=/home/$USER_NAME/yocto/input
ENV BUILD_OUTPUT_DIR=/home/$USER_NAME/yocto/output
RUN mkdir -p $BUILD_INPUT_DIR $BUILD_OUTPUT_DIR

RUN sudo usermod -aG docker $USER_NAME && newgrp docker

# Force git to use https:// instead of git:// for GitHub
RUN git config --global url."https://github.com".insteadOf git://github.com

WORKDIR $BUILD_INPUT_DIR

RUN if [ "$manifest_date" = "latest" ] ; then \
  /usr/local/bin/python3.11 /usr/local/bin/repo init -u https://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b $version --repo-url=https://gerrit.googlesource.com/git-repo --repo-rev=stable ; \
  else \
  /usr/local/bin/python3.11 /usr/local/bin/repo init -u https://github.com/carlesfernandez/oe-gnss-sdr-manifest.git -b refs/tags/$version-$manifest_date --repo-url=https://gerrit.googlesource.com/git-repo --repo-rev=stable ; \
  fi

RUN sed -i -r 's/git\:/https\:/g' /home/$USER_NAME/yocto/input/.repo/manifests/default.xml
RUN /usr/local/bin/python3.11 /usr/local/bin/repo sync
ENV MACHINE=$MACHINE
ENV TEMPLATECONF=${BUILD_NEW_TEMPLATE:+$BUILD_INPUT_DIR/meta-gnss-sdr/conf/templates/default}
ENV TEMPLATECONF=${TEMPLATECONF:-$BUILD_INPUT_DIR/meta-gnss-sdr/conf}

RUN echo "/bin/echo -e \"\nWelcome to the Yocto-Geniux container.\nRelease version: $version $manifest_date\n\nThis is the interactive mode. Warm hugs, you brave developer!\nYou are still on time to change the MACHINE environment variable (default: $MACHINE), change and/or add recipes, etc.\nTo set up the building environment, type:\n  source ./oe-core/oe-init-build-env ./build ./bitbake\nand you will be ready to bitbake like there is no tomorrow.\nSee https://github.com/carlesfernandez/yocto-geniux/blob/main/README.md for details.\n\n\"" \
  >> /home/$USER_NAME/.bashrc

CMD if [ "$host_git" = "1001" ]; then \
  source ./oe-core/oe-init-build-env ./build ./bitbake && \
  sudo service docker start && \
  bitbake gnss-sdr-dev-image && \
  bitbake -c populate_sdk gnss-sdr-dev-image && \
  bitbake gnss-sdr-demo-image && \
  bitbake gnss-sdr-dev-docker && \
  rm ./downloads/*.done && \
  rm -rf ./downloads/git2 && \
  sudo mv ./downloads /home/geniux/yocto/output/ && \
  if [ "$version" = "rocko" ] || [ "$version" = "sumo" ] || [ "$version" = "thud" ] || [ "$version" = "warrior" ] || [ "$version" = "zeus" ] || [ "$version" = "dunfell" ] || [ "$version" = "gatesgarth" ] || [ "$version" = "hardknott" ] || [ "$version" = "honister" ] || [ "$version" = "kirkstone" ] || [ "$version" = "langdale" ] || [ "$version" = "mickledore" ] || [ "$version" = "nanbield" ] || [ "$version" = "scarthgap" ]; then \
  sudo mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/ && \
  sudo mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/ ; \
  else \
  sudo mv ./tmp/deploy/images /home/geniux/yocto/output/ && \
  sudo mv ./tmp/deploy/sdk /home/geniux/yocto/output/ ; \
  fi \
  else \
  source ./oe-core/oe-init-build-env ./build ./bitbake && \
  echo "" | sudo -S service docker start && \
  bitbake gnss-sdr-dev-image && \
  bitbake -c populate_sdk gnss-sdr-dev-image && \
  bitbake gnss-sdr-demo-image && \
  bitbake gnss-sdr-dev-docker && \
  rm ./downloads/*.done && \
  rm -rf ./downloads/git2 && \
  if [ "$version" = "rocko" ] || [ "$version" = "sumo" ] || [ "$version" = "thud" ] || [ "$version" = "warrior" ] || [ "$version" = "zeus" ] || [ "$version" = "dunfell" ] || [ "$version" = "gatesgarth" ] || [ "$version" = "hardknott" ] || [ "$version" = "honister" ] || [ "$version" = "kirkstone" ] || [ "$version" = "langdale" ] || [ "$version" = "mickledore" ] || [ "$version" = "nanbield" ] || [ "$version" = "scarthgap" ]; then \
  echo "" | sudo -S mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/ && \
  sudo mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/ && \
  sudo mv ./downloads /home/geniux/yocto/output/ ; \
  else \
  echo "" | sudo -S mv ./tmp/deploy/images /home/geniux/yocto/output/ && \
  sudo mv ./tmp/deploy/sdk /home/geniux/yocto/output/ && \
  sudo mv ./downloads /home/geniux/yocto/output/ ; \
  fi \
  fi
