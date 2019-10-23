#!/usr/bin/env bash

podman run --rm --tty --interactive \
    --volume "${PWD}:/mnt" \
    --tmpfs '/tmp:exec' \
    --tmpfs '/var/tmp:exec' \
    --workdir '/mnt' \
    'gentoo/hardened' \
    bash
