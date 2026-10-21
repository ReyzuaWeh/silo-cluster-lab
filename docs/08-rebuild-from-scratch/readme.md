# Rebuild from Scratch

## Goal
Prove the Silo lab can be fully destroyed (containers, network, volumes, images) and rebuilt from the repo with `docker compose up -d --wait`, and record the rebuild time (cold and warm).

## Environment
- Images : [Prometheus, MinIO Warp, Silo, and NGINX as Load Balancer](../07-benchmark/evidence/01-compose-images.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-version.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/local-os-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Warp: `quay.io/minio/aistor/warp:v1.8.2`, run as a Compose service (profile `bench`) on the same Docker network as the cluster, targeting the load balancer (`lb:9000`), TLS off.
- Bucket: `warp-bench` (dedicated; warp wipes it before and after each run).
- Date : 21 October 2026

## Steps

> Warning: `down -v` deletes all volumes. All lab data is lost (intended).

### S08.1 Cold rebuild (remove containers, network, volumes, images)
```bash
{ 
    echo "== START $(date -Is)"; T0=$(date +%s)
    docker compose --profile bench down -v --rmi all --remove-orphans
    docker compose up -d --wait
    echo "== READY $(date -Is)"; echo "== ELAPSED $(( $(date +%s)-T0 )) s"
    docker compose ps
    curl -s -o /dev/null -w "live:%{http_code}\n" http://127.0.0.1:9000/minio/health/live
    curl -s -o /dev/null -w "cluster:%{http_code}\n" http://127.0.0.1:9000/minio/health/cluster
} 2>&1 | tee docs/08-rebuild-from-scratch/evidence/01-rebuild-cold.txt
```
- Expected: all services `healthy`, `live:200`, `cluster:200`.
- Actual: ELAPSED 48s. See [01-rebuild-cold.txt](evidence/01-rebuild-cold.txt)
- Result: **PASS**

### S08.2 Warm rebuild (images already present)
```bash
{ 
    echo "== START $(date -Is)"; T0=$(date +%s)
    docker compose --profile bench down -v --remove-orphans
    docker compose up -d --wait
    echo "== READY $(date -Is)"; echo "== ELAPSED $(( $(date +%s)-T0 )) s"
    docker compose ps
    curl -s -o /dev/null -w "live:%{http_code}\n" http://127.0.0.1:9000/minio/health/live
    curl -s -o /dev/null -w "cluster:%{http_code}\n" http://127.0.0.1:9000/minio/health/cluster
} 2>&1 | tee docs/08-rebuild-from-scratch/evidence/02-rebuild-warm.txt
```
- Expected: faster than cold because no image pull.
- Actual: ELAPSED 20s. See [02-rebuild-warm.txt](evidence/02-rebuild-warm.txt)
- Result: **PASS**

### S08.3 All nodes and drives online
```bash
. preused-cli/mcli.bash
mcli admin info lab 2>&1 | tee docs/08-rebuild-from-scratch/evidence/03-admin-info.txt
```
- Expected: 4 nodes online, 4 drives online.
- Actual: All Drives `1/1 OK`. See [03-admin-info.txt](evidence/03-admin-info.txt)
- Result: **PASS**

### S08.4 Smoke test: cluster stores data after rebuild
```bash
echo "rebuild-test" > objects/rebuild.txt
sha256sum objects/rebuild.txt | tee docs/08-rebuild-from-scratch/evidence/04-smoke.txt
mcli mb lab/rebuild-test 2>&1 | tee -a docs/08-rebuild-from-scratch/evidence/04-smoke.txt
mcli cp objects/rebuild.txt lab/rebuild-test/ 2>&1 | tee -a docs/08-rebuild-from-scratch/evidence/04-smoke.txt
mcli cp lab/rebuild-test/rebuild.txt objects/rebuild.out 2>&1 | tee -a docs/08-rebuild-from-scratch/evidence/04-smoke.txt
sha256sum objects/rebuild.out | tee -a docs/08-rebuild-from-scratch/evidence/04-smoke.txt
```
- Expected: both checksums match.
- Actual: `match`. See [04-smoke.txt](evidence/04-smoke.txt)
- Result: **PASS**

## Findings
- Cold rebuild took 48 s and warm rebuild 20 s. The 28 s difference is image pull time.
- Both rebuilds ended with all services healthy, `live:200` and `cluster:200`, and all drives `1/1 OK`.
- The smoke test checksums matched, so the rebuilt cluster stores and returns data correctly.
- No problems or dead ends in this step.
- Numbers are indicative, lab scale (4 GB RAM + 8 GB swap); the cold time depends on bandwidth.

## How to Reproduce and Clean Up
Create `.env` from `.env.example`, start the cluster as described in [Past Configuration](../02-healthcheck/readme.md#how-to-reproduce-and-clean-up), then run S08.1 to S08.4.

Clean up:
```bash
docker compose --profile bench down -v --remove-orphans
```