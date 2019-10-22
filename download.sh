#!/usr/bin/env bash

# FIXME
# See: http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-hardened+nomultilib.txt
url="http://distfiles.gentoo.org/releases/amd64/autobuilds/20191020T214501Z/hardened/"

kind="stage3-amd64-hardened+nomultilib"
version="20191020T214501Z"

wget $url/$kind-$version.tar.xz
wget $url/$kind-$version.tar.xz.DIGESTS.asc

gpg --verify $kind-$version.tar.xz.DIGESTS.asc
sha512sum -c --ignore-missing $kind-$version.tar.xz.DIGESTS.asc

xz --decompress --keep --stdout \
    stage3-amd64-hardened+nomultilib-$version.tar.xz \
    | podman import - localhost/gentoo/hardened:$version

podman tag localhost/gentoo/hardened:$version localhost/gentoo/hardened:latest
