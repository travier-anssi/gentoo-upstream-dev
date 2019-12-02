#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2019 ANSSI. All rights reserved.

# Safety settings: do not remove!
set -o errexit -o nounset -o pipefail

emerge_optarray=(
    --tree --unordered-display
    --verbose --verbose-conflicts --verbose-slot-rebuilds=y
    --quiet-build
    --nospinner

    --newrepo
    --newuse
    --changed-deps --with-bdeps=y
    --buildpkg=y
    --usepkg=y
    --binpkg-changed-deps=y
    --binpkg-respect-use=y
    --rebuild-if-unbuilt=y
    --rebuild-if-new-slot=y
    --update
)
readonly EMERGE_OPTS="${emerge_optarray[@]}"

echo "Setting up custom local Portage configuration..."

nproc="$(getconf _NPROCESSORS_ONLN)"  # more portable than nproc
make_jobs="$((${nproc} + 1))"  # + 1 for the main thread of make
emerge_jobs="${nproc}"

system_locale="en_US.UTF-8"
locale_regionalized_language="${system_locale%%.*}"    # e.g. "en_US"
locale_regionless_language="${locale_regionalized_language%%_*}"   # e.g. "en"

if [[ ! -e "/etc/.portage.original-from-stage3" ]]; then
    cp -a "/etc/portage" "/etc/.portage.original-from-stage3"
fi
find /etc/portage -mindepth 1 -delete   # delete contents but preserving parent dir

wanted_portage_features=(
    sandbox
    userfetch
    userpriv usersandbox
    cgroup
    strict unknown-features-warn
    parallel-fetch parallel-install ebuild-locks
    split-elog split-log
    -news
)
# Build the main Portage configuration file for runtime:
cat <<EOF > /etc/portage/make.conf
# Common location settings for Portage:
DISTDIR='/mnt/distfiles'
PKGDIR='/mnt/binpkg'
PORT_LOGDIR='/mnt/logs'

# Binary packages compression settings:
BINPKG_COMPRESS='lz4'
BINPKG_COMPRESS_FLAGS='-1'

# Portage FEATURES that only affects the behavior of Portage and not the
# "emerged" results:
FEATURES='${wanted_portage_features[@]}'

# Build multithreading settings:
MAKEOPTS='-j ${make_jobs}'
EMERGE_DEFAULT_OPTS='--jobs ${emerge_jobs} ${EMERGE_OPTS}'

# Locale and language-related settings:
L10N="${locale_regionless_language} ${locale_regionalized_language//_/-}"

# Portage Q/A enforcement (see make.conf(5) for their meaning)
QA_STRICT_EXECSTACK="set"
QA_STRICT_FLAGS_IGNORED="set"
QA_STRICT_MULTILIB_PATHS="set"
QA_STRICT_PRESTRIPPED="set"
QA_STRICT_TEXTRELS="set"
QA_STRICT_WX_LOAD="set"
EOF

# Declaring the Portage tree overlays
rm -rf /usr/portage
mkdir /etc/portage/repos.conf

repo='/mnt/gentoo'

[[ ! -d "${repo}" ]] && exit 1

# this parses the layout.conf to get the repo-name defined in it
reponame="$(sed -n -E 's/^[ \t]*repo-name[ \t]*=[ \t]*([^ \t]+).*$/\1/p' "${repo}/metadata/layout.conf")"
# if not found, fall back to the old-style repo-name definition
[[ -z "${reponame}" ]] && reponame="$(cat "${repo}/profiles/repo_name")"
# and if still not foun, give up and use the name of the overlay directory
[[ -z "${reponame}" ]] && reponame="$(basename "${repo}")"

repoconf="/etc/portage/repos.conf/${reponame}.conf"
# gentoo is always default
echo "[DEFAULT]" >> "${repoconf}"
echo "main-repo = gentoo" >> "${repoconf}"
echo "" >> "${repoconf}"

echo "[gentoo]" >> "${repoconf}"
echo "location = /mnt/gentoo" >> "${repoconf}"
echo >> "${repoconf}"

rm -rf /etc/portage/make.profile
mkdir -p /etc/portage/make.profile
cat <<EOF > /etc/portage/make.profile/parent
gentoo:default/linux/amd64/17.1/no-multilib/hardened
EOF

if [[ "${#}" -eq 1 && "${1}" == 'systemd' ]]; then
    cat <<EOF >> /etc/portage/make.profile/parent
gentoo:targets/systemd
EOF
fi

# vim: set ts=4 sts=4 sw=4 et ft=sh:
