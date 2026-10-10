#!/usr/bin/env bash
mcli mb lab/version-bucket
mcli mb --with-lock lab/lock-bucket
mcli stat lab/version-bucket
mcli stat lab/lock-bucket
