#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
mcli cp objects/obj-first-version.bin lab/version-bucket
mcli cp objects/obj-first-version.bin lab/locked-bucket 
mcli cp objects/obj-second-version.bin lab/version-bucket/obj-first-version.bin
mcli cp objects/obj-second-version.bin lab/locked-bucket/obj-first-version.bin
mcli rm lab/version-bucket/obj-first-version.bin
mcli rm lab/locked-bucket/obj-first-version.bin
