#!/bin/bash

# A script to build and store Geniux releases
# SPDX-FileCopyrightText: 2020-2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

display_usage() {
    echo -e "This script builds and stores Geniux images."
    echo -e "\nUsage:\n./geniux-builder.sh [version] [manifest] [machine]\n"
    echo -e "Options:"
    echo -e " version   Geniux version: rocko, sumo, thud, warrior, zeus, dunfell, gatesgarth, hardknott. Default: dunfell"
    echo -e "           Check available branches at https://github.com/carlesfernandez/meta-gnss-sdr"
    echo -e " manifest  Geniux version manifest: 20.11, 21.02, ..., latest. Default: latest"
    echo -e "           Dated manifests available at https://github.com/carlesfernandez/oe-gnss-sdr-manifest/tags"
    echo -e " machine   Specify your (list of) MACHINE here. By default, zedboard-zynq7 and raspberrypi3 are built.\n"
    echo -e "Environment variables that affect behavior:"
    echo -e " GENIUX_MIRROR_PATH          Base path to local mirror. Only used if set."
    echo -e "                             e.g.: 'export GENIUX_MIRROR_PATH=/home/$USER/mirror'"
    echo -e "                             The mirror is expected to be at '\$GENIUX_MIRROR_PATH/sources/\$version'"
    echo -e " GENIUX_STORE_PATH           Path in which products will be stored. Only used if set."
    echo -e "                             e.g.: 'export GENIUX_STORE_PATH=/home/$USER/geniux-releases'"
    echo -e " GENIUX_STORE_REQUIRES_SUDO  If set, the script will ask for super-user privileges to write in the store."
    echo -e "                             You will be asked only once at the beginning. The password will not be revealed."
    echo -e "                             e.g.: 'export GENIUX_STORE_REQUIRES_SUDO=1'"
}

if [[ ( $1 == "--help") ||  $1 == "-h" ]]
    then
        display_usage
        exit 0
fi

if [ $# -gt 3 ]
    then
        echo -e "Too much arguments!\n"
        display_usage
        exit 1
fi

GENIUX_VERSION=${1:-dunfell}
GENIUX_MANIFEST_DATE=${2:-latest}

MIRROR_PATH=$GENIUX_MIRROR_PATH
STORE_PATH=$GENIUX_STORE_PATH

if [ $STORE_PATH ]
    then
        STORE_REQUIRES_SUDO=$GENIUX_STORE_REQUIRES_SUDO
fi

ListOfMachines="zedboard-zynq7 raspberrypi3"
if [ $# -eq 3 ]
    then
        ListOfMachines="$3"
fi

echo -e "This script will build the Geniux distribution, version $GENIUX_VERSION-$GENIUX_MANIFEST_DATE, for machine(s): $ListOfMachines"
if [ $STORE_PATH ]
    then
        echo -e "Products will be stored at $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE"
fi

if [ $MIRROR_PATH ]
    then
        echo -e "The source files mirror will point to $MIRROR_PATH/sources/$GENIUX_VERSION\n"
fi

if [ $STORE_REQUIRES_SUDO ]
    then
        read -s -p "Enter Password for sudo: " sudoPW
fi

BASEDIR=$PWD

mkdir -p $GENIUX_VERSION

for machine in $ListOfMachines; do
    echo "Building Geniux $GENIUX_VERSION-$GENIUX_MANIFEST_DATE for machine $machine..."
    cd $BASEDIR/$GENIUX_VERSION
    mkdir -p $GENIUX_VERSION-$machine && cd $GENIUX_VERSION-$machine && cp ../../Dockerfile ./
    docker build --no-cache \
      --build-arg "version=$GENIUX_VERSION" \
      --build-arg "manifest_date=$GENIUX_MANIFEST_DATE" \
      --build-arg "MACHINE=$machine" \
      --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" \
      --tag "geniux-$GENIUX_VERSION:$GENIUX_MANIFEST_DATE.$machine" .
    mkdir -p output_$machine
    if [ $MIRROR_PATH ]
        then
            docker run -it --rm -v $PWD/output_$machine:/home/geniux/yocto/output \
              -v $MIRROR_PATH/sources/$GENIUX_VERSION:/source_mirror/sources/$GENIUX_VERSION \
              --privileged=true \
              geniux-$GENIUX_VERSION:$GENIUX_MANIFEST_DATE.$machine
        else
            docker run -it --rm -v $PWD/output_$machine:/home/geniux/yocto/output \
              --privileged=true \
              geniux-$GENIUX_VERSION:$GENIUX_MANIFEST_DATE.$machine
    fi
    cd output_$machine/images
    if [ $STORE_REQUIRES_SUDO ]
        then
            echo $sudoPW | sudo -S zip --symlinks -r image-$GENIUX_VERSION-$machine.zip $machine
            echo $sudoPW | sudo -S mkdir -p $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/images/$machine
            echo $sudoPW | sudo -S cp image-$GENIUX_VERSION-$machine.zip $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/images/$machine
            cd ..
            echo $sudoPW | sudo -S mkdir -p $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/sdk
            echo $sudoPW | sudo -S cp $PWD/sdk/* $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/sdk
            cd ../..
        else
            if [ $STORE_PATH ]
                then
                    zip --symlinks -r image-$GENIUX_VERSION-$machine.zip $machine
                    mkdir -p $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/images/$machine
                    cp image-$GENIUX_VERSION-$machine.zip $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/images/$machine
                    cd ..
                    mkdir -p $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/sdk
                    cp $PWD/sdk/* $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/sdk
                    cd ../..
                else
                    # Do not store products, just leave them at $GENIUX_VERSION/output_$machine
                    cd $BASEDIR/$GENIUX_VERSION
            fi
    fi
done

cd $BASEDIR
