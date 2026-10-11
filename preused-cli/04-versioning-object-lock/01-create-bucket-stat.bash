#!/usr/bin/env bash
. "$(dirname "${BASH_SOURCE[0]}")/../mcli.bash"
mcli mb lab/version-bucket
mcli mb --with-lock lab/locked-bucket
mcli stat lab/version-bucket
mcli version enable lab/version-bucket
mcli stat lab/locked-bucket
