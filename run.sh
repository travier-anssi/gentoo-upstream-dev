#!/usr/bin/env bash

podman run --rm --tty --interactive \
    --volume "${PWD}:/mnt" \
    --tmpfs '/tmp' \
    --tmpfs '/var/tmp' \
    --workdir '/mnt' \
    'gentoo/hardened' \
    bash
