#!/usr/bin/env bash

podman run --rm --tty --interactive \
    --volume "${PWD}:/mnt" \
    --workdir '/mnt' \
    'gentoo/hardened' \
    bash
