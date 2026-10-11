#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
VERSION_ID=$(mcli ls --versions lab/version-bucket | awk '$NF=="obj-first-version.bin" && $(NF-2)=="v2" {print $(NF-3)}')

mcli rm --version-id "$VERSION_ID" lab/version-bucket/obj-first-version.bin
