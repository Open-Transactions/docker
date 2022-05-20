#!/bin/bash

SRC="/home/src"
BUILD="/home/flatpak-host"  #IMPORTANT! building takes place inside this dir
                            #for ease of use, this should be mounter to host system
SUB_BUILD="fb-build"
SUB_CACHE="fb-cache"
SUB_REPO="fb-repo"
SUB_RELEASE="fb-release"

#the same as METIER_APPSTREAM_ID in cmake
APP_NAME="io.matterfi.wallet"
FILE_CACHE="fb-cache.tar.gz"

#we need input from host system
if [ ! -d "${SRC}" ]; then
    echo "src dir missing. Mount opentxs source directory at ${SRC}"
    exit 1
fi

#we need output storage on the host system
if [ ! -d "${BUILD}" ]; then
    echo "build dir missing. Mount build directory at ${BUILD}"
    exit 1
fi

set -e
cd $BUILD
pwd

#prepare build dir structure
rm -rf $SUB_BUILD
#rm -rf $SUB_CACHE
rm -rf $SUB_REPO
mkdir -p $SUB_RELEASE

#unpack cache
#tar -xvzf $FILE_CACHE

#debugging info
flatpak --version
flatpak-builder --version

#build and store to local repo
flatpak-builder \
    --repo=$SUB_REPO \
    --keep-build-dirs \
    --state-dir=$SUB_CACHE \
    --disable-rofiles-fuse \
    --ccache \
    --force-clean \
    $SUB_BUILD \
    $SRC/package/gui.flatpak.json

#prepare flatpak
flatpak \
    build-bundle \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    $SUB_REPO \
    $SUB_RELEASE/$APP_NAME.flatpak \
    $APP_NAME \
    master

#pack cache
rm $FILE_CACHE
tar -zcvf $FILE_CACHE $SUB_CACHE