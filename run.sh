#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2019 ANSSI. All rights reserved.

# Safety settings: do not remove!
set -o errexit -o nounset -o pipefail

# TODO:
# * Additionnal capabilities potentially required to build the GCC package:
#   CAP_SYS_PTRACE

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

    ${runtime} run --rm --tty --interactive \
        --volume "${PWD}:/mnt" \
        --tmpfs '/tmp:exec' \
        --tmpfs '/var/tmp:exec' \
        --workdir '/mnt' \
        'gentoo/hardened' \
        bash
}

main "${@}"

# vim: set ts=4 sts=4 sw=4 et ft=sh tw=79:
