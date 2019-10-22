#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2017 ANSSI. All rights reserved.

# Gentoo Hardened upstream development SDK setup script

# Safety settings: do not remove!
set -o errexit -o nounset -o pipefail

# Setup Portage
/mnt/scripts/setup-portage.sh

# Workaround for lz4 build
portage_vars_to_delete=(
    PKGDIR
    BINPKG_COMPRESS
    BINPKG_COMPRESS_FLAGS
)
for var in "${portage_vars_to_delete[@]}"; do
    sed -i -E -e '/^[ \t]*'"${var}"'=/d' /etc/portage/make.conf
done
cat <<EOF >> /etc/portage/make.conf
PKGDIR='/mnt/binpkg/.binpkgs-bz2'
EOF

# Needed for a time-optimal compression of the binpkgs.
emerge app-arch/lz4

# Now reset portage setup:
/mnt/scripts/setup-portage.sh

# Install various tools
emerge app-portage/gentoolkit app-portage/repoman dev-vcs/git

# Update the packages according to profile and overlays (this will install also
# the packages from @sdk-world).
emerge --update --deep --newuse @world

# Remove now unnecessary packages
CLEAN_DELAY=0 emerge --depclean

# Merge all etc updates
etc-update --verbose --automode -5

# vim: set ts=4 sts=4 sw=4 et ft=sh:
