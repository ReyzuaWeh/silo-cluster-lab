#!/usr/bin/env bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
. "$ROOT/.env"

mcli() {
docker run --rm -i --network silo-cluster_lab \
    -v "$HOME/.mcli-lab:/cfg" \
    -v "$PWD:/work" -w /work \
    --entrypoint mcli "$SILO_IMAGE" --config-dir /cfg "$@"
}
mcli alias set lab http://lb:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
