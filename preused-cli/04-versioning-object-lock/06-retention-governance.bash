#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
VERSION_ID_LOCK=$(mcli ls --versions lab/locked-bucket | awk '$NF=="obj-first-version.bin" && $(NF-2)=="v1" {print $(NF-3)}')
mcli retention set GOVERNANCE 1d lab/locked-bucket/obj-first-version.bin

mcli rm --version-id "$VERSION_ID_LOCK" lab/locked-bucket/obj-first-version.bin
mcli rm --bypass --version-id "$VERSION_ID_LOCK" lab/locked-bucket/obj-first-version.bin