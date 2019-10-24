#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2019 ANSSI. All rights reserved.

# Safety settings: do not remove!
set -o errexit -o nounset -o pipefail

# TODO:
# * Import Gentoo GPG keys (see gentoo_release.asc)

main() {
    # Figure out which runtime (podman or docker) to use and if root is needed
    local runtime=""
    if [[ -n "$(command -v podman)" ]]; then
        if [[ -n "$(grep "$(id --user --name):" /etc/subuid)" ]]; then
            runtime="podman"
        else
            runtime="sudo ${runtime}"
        fi
    elif [[ -n "$(command -v docker)" ]]; then
        runtime="sudo docker"
    else
        >&2 echo "Could not find either podman or docker in PATH."
        exit 1
    fi

    local -r base_url='http://distfiles.gentoo.org/releases/amd64/autobuilds'

    local -r kind='stage3-amd64-hardened+nomultilib'
    local -r image='localhost/gentoo/hardened'

    local -r latest_url="${base_url}/latest-${kind}.txt"

    echo "[*] Looking for latest version for ${kind}..."
    local -r url="$(curl -sSf "${latest_url}" | grep -v "^#" | cut -d\  -f 1)"
    local -r version="$(echo ${url} | cut -d/ -f 1)"

    # Is there already an image available?
    ${runtime} inspect "${image}:${version}" > /dev/null && rc=${?} || rc=${?}
    if [[ ${rc} -eq 0 ]]; then
        echo "[*] ${kind} image for version ${version} already available"
        echo "[*] Done"
        exit 0
    fi

    echo "[*] Downloading ${kind} ${version}..."
    curl -O "${base_url}/${url}"
    curl -O "${base_url}/${url}.DIGESTS.asc"

    echo "[*] Verifying ${kind} ${version}..."
    gpg --verify "${kind}-${version}.tar.xz.DIGESTS.asc"
    # Ignore WHIRLPOOL hashes & check only the file that matter
    sed '/WHIRLPOOL/,+1 d' "${kind}-${version}.tar.xz.DIGESTS.asc" \
        | grep "${kind}-${version}.tar.xz" \
        | sha512sum -c --ignore-missing

    echo "[*] Importing ${kind} ${version}..."
    xz --decompress --keep --stdout \
        "${kind}-${version}.tar.xz" \
        | ${runtime} import - "${image}:${version}"

    echo "[*] Tagging ${image}:latest..."
    ${runtime} tag "${image}:${version}" "${image}:latest"

    echo "[*] Success!"
}

main "${@}"

# vim: set ts=4 sts=4 sw=4 et ft=sh tw=79:
