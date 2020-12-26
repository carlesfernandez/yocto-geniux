<!-- prettier-ignore-start -->
[comment]: # (
SPDX-License-Identifier: Apache-2.0
)

[comment]: # (
SPDX-FileCopyrightText: 2020 Carles Fernandez-Prades <carles.fernandez@cttc.es>
)
<!-- prettier-ignore-end -->

# yocto-geniux

The purpose of this repository is to automate the generation in a virtualized
environment of Geniux images and their corresponding Software Development Kit
(SDK) for the cross-compilation and usage of [GNSS-SDR](https://gnss-sdr.org) on
embedded devices.

The Docker images generated by the `Dockerfile` file of this repository can run
the building process defined by the
[meta-gnss-sdr](https://github.com/carlesfernandez/meta-gnss-sdr) Yocto layer.

More info at
[Cross-compiling GNSS-SDR](https://gnss-sdr.org/docs/tutorials/cross-compiling/).

The name Geniux comes from **G**NSS-SDR for **E**mbedded G**N**U/L**i**n**ux**.

## Building Geniux releases in a virtualized environment

Get a powerful machine (as much RAM, storage capacity and CPU cores as you can)
and [install the Docker engine](https://docs.docker.com/engine/install/) on it.
Make sure that it is up and running.

> Note: the `geniux-builder.sh` script makes use of the `zip` and `unzip` tools.
> On Debian/Ubuntu machines, you can install them by doing:
>
> ```
> $ sudo apt-get install zip unzip
> ```

Then, get the source code of this repository and go to its base path:

```
$ git clone https://github.com/carlesfernandez/yocto-geniux
$ cd yocto-geniux
```

Now you are ready to build Geniux images for the release you want with a single
command, by using the `geniux-builder.sh` script. Taking a look at its help
message:

```
$ ./geniux-builder.sh --help
This script builds and stores Geniux images.

Usage:
./geniux-builder.sh [version] [manifest] [machine]

Options:
 version   Geniux version: rocko, sumo, thud, warrior, zeus, dunfell, gatesgarth. Default: warrior
           Check available branches at https://github.com/carlesfernandez/meta-gnss-sdr
 manifest  Geniux version manifest: 20.11, ..., latest. Default: latest
           Dated manifests available at https://github.com/carlesfernandez/oe-gnss-sdr-manifest/tags
 machine   Specify your (list of) MACHINE here. By default, zedboard-zynq7 and raspberrypi3 are built.

Environment variables that affect behavior:
 GENIUX_MIRROR_PATH          Base path to local mirror. Only used if set.
                             e.g.: 'export GENIUX_MIRROR_PATH=/home/user/mirror'
                             The mirror is expected to be at '$GENIUX_MIRROR_PATH/sources/$version'
 GENIUX_STORE_PATH           Path in which products will be stored. Only used if set.
                             e.g.: 'export GENIUX_STORE_PATH=/home/user/geniux-releases'
 GENIUX_STORE_REQUIRES_SUDO  If set, the script will ask for super-user privileges to write in the store.
                             You will be asked only once at the beginning. The password will not be revealed.
                             e.g.: 'export GENIUX_STORE_REQUIRES_SUDO=1'
```

Before calling the script, you might want to set some (optional) environment
variables on your host machine:

```
$ export GENIUX_MIRROR_PATH=/home/user/mirror
$ export GENIUX_STORE_PATH=/home/user/geniux-releases
$ export GENIUX_STORE_REQUIRES_SUDO=1
```

Examples of usage:

> NOTE: if you are operating on a remote host through `ssh`, you might want to
> run `screen` at this point, so the work won't be lost in case of a session
> drop.

- Build Geniux release `warrior`, with manifest date `latest`, for machines
  `zedboard-zynq7` and `raspberrypi3`:

  ```
  $ ./geniux-builder.sh
  ```

- Build Geniux release `thud`, with manifest date `latest`, for machines
  `zedboard-zynq7` and `raspberrypi3`:

  ```
  $ ./geniux-builder.sh thud
  ```

- Build Geniux release `thud`, with manifest date `20.09`, for machines
  `zedboard-zynq7` and `raspberrypi3`:

  ```
  $ ./geniux-builder.sh thud 20.09
  ```

- Build Geniux release `warrior`, with manifest date `latest`, only for machine
  `zedboard-zynq7`:

  ```
  $ ./geniux-builder.sh warrior latest zedboard-zynq7
  ```

- Build Geniux release `warrior`, with manifest date `20.09`, only for machine
  `raspberrypi3`:

  ```
  $ ./geniux-builder.sh warrior 20.09 raspberrypi3
  ```

- Build Geniux release `rocko`, with manifest date `latest`, for machines
  `zedboard-zynq7` and `zcu102-zynqmp`:

  ```
  $ ./geniux-builder.sh rocko latest "zedboard-zynq7 zcu102-zynqmp"
  ```

If you want to have more detailed control of the whole process, or you are
interested on further development (making changes to the Yocto layers, adding
new features or recipes, fixing bugs, etc.), then you can skip the usage of the
`geniux-builder.sh` script and follow the instructions below.

## Getting ready for building Geniux with manual steps

Get a powerful machine (as much RAM, storage capacity and CPU cores as you can),
[install the Docker engine](https://docs.docker.com/engine/install/) and make
sure it is up and running. Then, get the source code of this repository and go
to its base path:

```
$ git clone https://github.com/carlesfernandez/yocto-geniux
$ cd yocto-geniux
```

You are now ready to generate the Docker container, and then running it in order
to obtain the image files and the SDK installer.

## Building the container

The container can be built by doing (parameters `--build-arg "whatever"` are
optional, the last dot `.` is not):

```
$ docker build --no-cache \
   --build-arg "version=warrior" \
   --build-arg "manifest_date=20.09" \
   --build-arg "MACHINE=raspberrypi3" \
   --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" \
   --tag "geniux-image:latest" .
```

If the `--build-arg` parameters are not specified, the default values are
`version=thud`, `manifest_date=latest`, `MACHINE=zedboard-zynq7`,
`host_uid=1001` and `host_gid=1001`.

- The possible options for `version` names are those of the
  [Yocto Project Releases](https://wiki.yoctoproject.org/wiki/Releases),
  starting from Rocko (Yocto version 2.4):

  - `rocko`, `sumo`, `thud`, `warrior`, `zeus`, `dunfell`, `gatesgarth`.

- The possible options for `manifest_date` are those of the tags found at the
  https://github.com/carlesfernandez/oe-gnss-sdr-manifest repository. If not
  set, or set to `latest`, it will pick up the current version of the manifest
  in the branch specified by `version`. In order to get a tagged manifest (for
  instance, `warrior-20.09`), you can set `version=warrior` and
  `manifest_date=20.09`.

- The possible options for `MACHINE` names are those defined by the Yocto
  Project, plus those defined by the `meta-xilinx-bsp` and the
  `meta-raspberrypi` layers:

  - List of machines supported by the Yocto Project: `qemuarm`, `qemuarm64`,
    `qemumips`, `qemumips64`, `qemuppc`, `qemux86`, `qemux86-64`.
  - List of machines defined by the
    [`meta-xilinx-bsp` layer](https://github.com/Xilinx/meta-xilinx/tree/master/meta-xilinx-bsp)
    (please check your specific branch for a list of options available).
  - List of machines defined by the
    [`meta-raspberrypi` layer](http://git.yoctoproject.org/cgit/cgit.cgi/meta-raspberrypi/tree/conf/machine)
    (please check your specific branch for a list of options available).

- If you have user permission restrictions, you can use
  `--build-arg "host_uid=$(id -u)"` and `--build-arg "host_gid=$(id -g)"` to
  provide specific user and group id to the internal container user that will be
  able to write outside the container. By default, both `host_uid` and
  `host_gid` are set to `1001`. If you do not use these arguments, you might
  need `sudo` access in order to copy files outside the container.

## Getting the development image and the SDK installer

### Non-interactive method

> NOTE: if you are operating on a remote host through `ssh`, you might want to
> run `screen` at this point, so the work won't be lost in case of a session
> drop.

Create an output folder and run the container:

```
$ mkdir -p output
$ docker run -it --rm \
  -v $PWD/output:/home/geniux/yocto/output \
  --privileged=true \
  geniux-image:latest
```

If you have a local mirror available, you can provide access from within the
container as:

```
$ mkdir -p output
$ docker run -it --rm \
  -v $PWD/output:/home/geniux/yocto/output \
  -v $my_mirror:/source_mirror/sources/$version \
  --privileged=true \
  geniux-image:latest
```

replacing `$my_mirror` by the actual path of your mirror and `$version` by the
actual version name you used when building the container. If you do not have any
local mirror, just omit the `-v $my_mirror:...` line.

The build process will take several hours. At its ending, the image files will
be under your `./output` folder, so _outside_ the container. The `./output`
folder must be empty before starting the run. The container itself will be
erased after completion.

### Interactive method

> NOTE: if you are operating on a remote host through `ssh`, you might want to
> run `screen` at this point, so the work won't be lost in case of a session
> drop.

```
$ mkdir -p output
$ docker run -it --rm \
   -v $PWD/output:/home/geniux/yocto/output \
   -v $my_mirror:/source_mirror/sources/$version \
   --privileged=true \
   geniux-image:latest bash
```

Notice the final `bash`, that will take you to the bash console without
executing the predefined commands.

Now, inside the container, prepare the building environment:

```
$ source ./oe-core/oe-init-build-env ./build ./bitbake
```

At this point, you can modify the `conf/local.conf` file, add new recipes and
experiment as you want. The `nano` editor is available for that. When you are
ready to build the image:

```
$ bitbake gnss-sdr-dev-image
```

and the corresponding SDK script installer:

```
$ bitbake -c populate_sdk gnss-sdr-dev-image
```

If you want to build the Docker images, you need to run the container with the
flag `--privileged=true` and the start the Docker daemon inside the container:

```
$ sudo service docker start
$ bitbake gnss-sdr-dev-docker
```

The build process will take several hours. At its ending, the image files will
be under `./build/tmp-glibc/deploy` folder. Move them to the
`/home/geniux/yocto/output` folder:

```
$ mv ./tmp-glibc/deploy/images /home/geniux/yocto/output/
$ mv ./tmp-glibc/deploy/sdk /home/geniux/yocto/output/
```

Now, when doing `exit` from the container, the build artifacts will be at the
`./output` folder you created in your machine, so _outside_ the container. The
container itself will be erased at exit.
