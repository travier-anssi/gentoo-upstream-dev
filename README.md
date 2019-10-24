# Scripts for upstream Gentoo development using containers

You need either podman or Docker.

Import the latest Gentoo Hardened nomultilib stage3 with:

```
$ ./import_stage3.sh
```

Clone the Gentoo upstream portage repository:

```
$ git clone https://anongit.gentoo.org/git/repo/gentoo.git
```

Start an ephemeral Gentoo container with:

```
$ ./run.sh
```

Setup Gentoo container & profile with:

```
abcdefgh /mnt # ./scripts/setup.sh
```

To setup a systemd aware profile, use:

```
abcdefgh /mnt # ./scripts/setup.sh systemd
```

This folder is bind mounted at `/mnt` in the container and all emerged
packages, downloaded distfiles and logs are kept in their respective folders
under `/mnt`.
