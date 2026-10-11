#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
mcli ls --versions lab/version-bucket
mcli ls --versions lab/locked-bucket
