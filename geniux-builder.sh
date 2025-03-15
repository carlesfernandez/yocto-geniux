#!/bin/bash

# A script to build and store Geniux releases
# SPDX-FileCopyrightText: 2020-2025, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

display_usage() {
    echo -e "This script builds and stores Geniux images."
    echo -e "\nUsage:\n./geniux-builder.sh [version] [manifest] [machine] (--image-only / -i)\n"
    echo -e "Options:"
    echo -e " version   Geniux version (from oldest to most recent):"
    echo -e "             rocko, sumo, thud, warrior, zeus, dunfell, gatesgarth, hardknott,"
    echo -e "             honister, kirkstone, langdale, mickledore, nanbield, scarthgap, styhead. Default: dunfell"
    echo -e "           Check available branches at https://github.com/carlesfernandez/meta-gnss-sdr"
    echo -e " manifest  Geniux version manifest: 21.02, 21.08, 22.02, 22.06, 23.04, 24.02, latest. Default: latest"
    echo -e "           Dated manifests available at https://github.com/carlesfernandez/oe-gnss-sdr-manifest/tags"
    echo -e " machine   Specify your (list of) MACHINE here. By default, zedboard-zynq7 and raspberrypi3 are built."
    echo -e "           If more than one, surround them with quotes, e.g.: \"raspberrypi4-64 intel-corei7-64\""
    echo -e " --image-only / -i  (optional) Build the Docker image but do not execute the container.\n"
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

GENIUX_VERSION=${1:-dunfell}
GENIUX_MANIFEST_DATE=${2:-latest}

if [[ $GENIUX_VERSION == "rocko" || $GENIUX_VERSION == "sumo" || $GENIUX_VERSION == "thud" || \
    $GENIUX_VERSION == "warrior" || $GENIUX_VERSION == "zeus" || $GENIUX_VERSION == "dunfell" || \
    $GENIUX_VERSION == "gatesgarth" || $GENIUX_VERSION == "hardknott" || $GENIUX_VERSION == "honister" || \
    $GENIUX_VERSION == "kirkstone"  || $GENIUX_VERSION == "langdale" ]]
    then
        YOCTO_GENIUX_BASE_IMAGE_VERSION="1.10"
    elif [[ $GENIUX_VERSION == "mickledore" ]]
        then
            YOCTO_GENIUX_BASE_IMAGE_VERSION="2.4"
    else
        YOCTO_GENIUX_BASE_IMAGE_VERSION="3.4"
fi

YOCTO_GENIUX_BASE_IMAGE="yocto-geniux-base:v$YOCTO_GENIUX_BASE_IMAGE_VERSION"
BASEDIR=$PWD
MIRROR_PATH=$GENIUX_MIRROR_PATH
STORE_PATH=$GENIUX_STORE_PATH

if [[ ( $1 == "--help") || $1 == "-h" ]]
    then
        display_usage
        exit 0
fi

if [[ ( $4 == "--image-only") || $4 == "-i" ]]
    then
        IMAGE_ONLY=1
    else
        if [[ ! ( $4 == "") ]]
            then
                if [ $# -gt 4 ]
                    then
                        echo -e "Wrong number of arguments!\n"
                    else
                        echo -e "Unknown value for the 4th parameter.\n"
                fi
                display_usage
                exit 1
        fi
fi

if [[ ( $1 == "--image-only") || $1 == "-i" ]]
    then
        echo -e "Wrong arguments!\n"
        display_usage
        exit 1
fi

if [[ ( $2 == "--image-only") || $2 == "-i" ]]
    then
        echo -e "Wrong arguments!\n"
        display_usage
        exit 1
fi

if [[ ( $3 == "--image-only") || $3 == "-i" ]]
    then
        echo -e "Wrong arguments!\n"
        display_usage
        exit 1
fi

if [ $# -gt 4 ]
    then
        echo -e "Too much arguments!\n"
        display_usage
        exit 1
fi

# Workaround for known bugs
if [[ "$GENIUX_MANIFEST_DATE" == "21.06" ]]
    then
        if [[ $GENIUX_VERSION == "zeus" || $GENIUX_VERSION == "dunfell" || $GENIUX_VERSION == "gatesgarth" || $GENIUX_VERSION == "hardknott" ]]
            then
                echo -e "\033[1m\033[35mWARNING: Version $GENIUX_VERSION-$GENIUX_MANIFEST_DATE has a known bug. Bumping to 21.08.\033[0m\n"
                GENIUX_MANIFEST_DATE="21.08"
        fi
fi

if [ "$STORE_PATH" ]
    then
        STORE_REQUIRES_SUDO=$GENIUX_STORE_REQUIRES_SUDO
fi

ListOfMachines="zedboard-zynq7 raspberrypi3"
if [ $# -gt 2 ]
    then
        ListOfMachines="$3"
fi

echo -e "This script will build the Geniux distribution, version $GENIUX_VERSION-$GENIUX_MANIFEST_DATE, for machine(s): $ListOfMachines"
if [ "$STORE_PATH" ]
    then
        echo -e "Products will be stored at $STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE"
fi

if [ "$MIRROR_PATH" ]
    then
        echo -e "The source files mirror will point to $MIRROR_PATH/sources/$GENIUX_VERSION\n"
fi

if [ "$STORE_REQUIRES_SUDO" ]
    then
        read -r -s -p "Enter Password for sudo: " sudoPW
        echo -e "\n"
fi

if test -z "$(docker images -q $YOCTO_GENIUX_BASE_IMAGE)"
    then
        cd base-image || exit
        echo -e "Yocto Geniux base image v$YOCTO_GENIUX_BASE_IMAGE_VERSION does not exist. Building ..."
        if [[ $GENIUX_VERSION == "rocko" || $GENIUX_VERSION == "sumo" || $GENIUX_VERSION == "thud" || \
            $GENIUX_VERSION == "warrior" || $GENIUX_VERSION == "zeus" || $GENIUX_VERSION == "dunfell" || \
            $GENIUX_VERSION == "gatesgarth" || $GENIUX_VERSION == "hardknott" || $GENIUX_VERSION == "honister" || \
            $GENIUX_VERSION == "kirkstone"  || $GENIUX_VERSION == "langdale" ]]
            then
                docker build --tag "$YOCTO_GENIUX_BASE_IMAGE" .
            elif [[ $GENIUX_VERSION == "mickledore" ]]
                then
                    docker build -f Dockerfile2 --tag "$YOCTO_GENIUX_BASE_IMAGE" .
            else
                docker build -f Dockerfile3 --tag "$YOCTO_GENIUX_BASE_IMAGE" .
        fi
        cd ..
fi

mkdir -p "$GENIUX_VERSION"

if [[ "$OSTYPE" == "darwin"* ]]
    then
        SETUID_AUX=""
    else
        SETUID_AUX="--build-arg \"host_uid=$(id -u)\" --build-arg \"host_gid=$(id -g)\""
fi
IFS=" " read -r -a SETUID <<< "$SETUID_AUX"

if [[ $GENIUX_VERSION == "rocko" || $GENIUX_VERSION == "sumo" || $GENIUX_VERSION == "thud" || \
    $GENIUX_VERSION == "warrior" || $GENIUX_VERSION == "zeus" || $GENIUX_VERSION == "dunfell" || \
    $GENIUX_VERSION == "gatesgarth" || $GENIUX_VERSION == "hardknott"|| $GENIUX_VERSION == "honister" || \
    $GENIUX_VERSION == "kirkstone" ]]
    then
        NEW_TEMPLATECONF=""
    else
        NEW_TEMPLATECONF="--build-arg BUILD_NEW_TEMPLATE=1"
fi
IFS=" " read -r -a TEMPLATECONF <<< "$NEW_TEMPLATECONF"

for machine in $ListOfMachines; do
    echo -e "Building Geniux $GENIUX_VERSION-$GENIUX_MANIFEST_DATE for machine $machine...\n"
    cd "$BASEDIR"/"$GENIUX_VERSION" || exit
    mkdir -p "$GENIUX_VERSION"-"$machine" && cd "$GENIUX_VERSION"-"$machine" && cp ../../Dockerfile ./
    docker build --no-cache \
        --build-arg "version=$GENIUX_VERSION" \
        --build-arg "manifest_date=$GENIUX_MANIFEST_DATE" \
        --build-arg "MACHINE=$machine" \
        --build-arg "base_image_version=$YOCTO_GENIUX_BASE_IMAGE_VERSION" \
        "${TEMPLATECONF[@]}" "${SETUID[@]}" \
        --tag "geniux-$GENIUX_VERSION:$GENIUX_MANIFEST_DATE.$machine" .
    if [ ! "$IMAGE_ONLY" ]
        then
            mkdir -p output_"$machine"
            if [ "$MIRROR_PATH" ]
                then
                    docker run -it --rm -v "$PWD"/output_"$machine":/home/geniux/yocto/output \
                    -v "$MIRROR_PATH"/sources/"$GENIUX_VERSION":/source_mirror/sources/"$GENIUX_VERSION" \
                    --privileged=true \
                    geniux-"$GENIUX_VERSION":"$GENIUX_MANIFEST_DATE"."$machine"
                else
                    docker run -it --rm -v "$PWD"/output_"$machine":/home/geniux/yocto/output \
                    --privileged=true \
                    geniux-"$GENIUX_VERSION":"$GENIUX_MANIFEST_DATE"."$machine"
            fi
            cd output_"$machine"/images || exit
            if [ "$STORE_REQUIRES_SUDO" ]
                then
                    echo "$sudoPW" | sudo -S zip --symlinks -r image-"$GENIUX_VERSION"-"$machine".zip "$machine"
                    echo "$sudoPW" | sudo -S mkdir -p "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/images/"$machine"
                    echo "$sudoPW" | sudo -S cp image-"$GENIUX_VERSION"-"$machine".zip "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/images/"$machine"
                    cd ..
                    echo "$sudoPW" | sudo -S mkdir -p "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/sdk
                    echo "$sudoPW" | sudo -S cp "$PWD"/sdk/* "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/sdk
                    cd ../..
                else
                    if [ "$STORE_PATH" ]
                        then
                            zip --symlinks -r image-"$GENIUX_VERSION"-"$machine".zip "$machine"
                            mkdir -p "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/images/"$machine"
                            cp image-"$GENIUX_VERSION"-"$machine".zip "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/images/"$machine"
                            cd ..
                            mkdir -p "$STORE_PATH"/"$GENIUX_VERSION"/"$GENIUX_MANIFEST_DATE"/sdk
                            cp "$PWD"/sdk/* "$STORE_PATH/$GENIUX_VERSION/$GENIUX_MANIFEST_DATE/sdk"
                            cd ../..
                        else
                            # Do not store products, just leave them at $GENIUX_VERSION/output_$machine
                            cd "$BASEDIR/$GENIUX_VERSION" || exit
                    fi
            fi
    fi
done

cd "$BASEDIR" || return
