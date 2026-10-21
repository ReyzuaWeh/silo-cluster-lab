# Silo Cluste Lab

A local lab for a distributed [Silo](https://github.com/pgsty/silo) cluster (community MinIO fork): 4 nodes x 1 drive (EC:2) behind an nginx load balancer, run with Docker Compose. It tests correctness, failure behaviour, healing, monitoring and rebuild time.

> All performance numbers are indicative, lab scale. Machine: 4 GB RAM + 8 GB swap (Profile C, smaller than the task's Profile B).

## Quick start
```bash
cp .env.example .env
docker compose up -d --wait
```
Console: http://127.0.0.1:9001. S3 API: http://127.0.0.1:9000.

## Results

| # | Step | Result | Key outcome | Doc |
|---|------|--------|-------------|-----|
| 1 | Build cluster | PASS | 4 nodes and 4 drives online, Console login works | [docs/01-build-cluster](docs/01-build-cluster/README.md) |
| 2 | Health checks | PASS | `silo healthcheck`, `/health/live` and `/health/cluster` all return 200 | [docs/02-healthcheck](docs/02-healthcheck/readme.md) |
| 3 | Basic S3 | PASS (1 initial FAIL) | CRUD, 1.2 GB multipart (about 88 MiB/s), presigned URL, metadata, tags, boto3. Checksums MATCH | [docs/03-basic-s3](docs/03-basic-s3/readme.md) |
| 4 | Versioning and object lock | PASS (1 initial FAIL) | Restore old version works. Governance and compliance retention behave as expected | [docs/04-versioning-object-lock](docs/04-versioning-object-lock/readme.md) |
| 5 | Failure and healing | PASS | See the failure table below. Final checksum matches the original | [docs/05-failure-healing](docs/05-failure-healing/readme.md) |
| 6 | Monitoring | PASS | Prometheus scrapes `minio_*`, queries and alert list documented | [docs/06-monitoring](docs/06-monitoring/readme.md) |
| 7 | Benchmark (warp, 3 runs each) | PASS | See the benchmark table below | [docs/07-benchmark](docs/07-benchmark/readme.md) |
| 8 | Rebuild from scratch | PASS | Cold 48 s, warm 20 s, healthy with smoke test OK | [docs/08-rebuild-from-scratch](docs/08-rebuild-from-scratch/readme.md) |

### Failure behaviour

| Condition | Read | List | Write | Delete |
|-----------|------|------|-------|--------|
| 1 node down | OK | OK | OK | OK |
| 2 nodes down | OK | OK | Fails | No response |
| 3 nodes down (extra) | Fails or hangs | Fails or hangs | - | - |

After restart and after wiping one drive, healing completed and the checksum comparison showed 0 differences.

### Benchmark (indicative, mean of 3 runs)

| Test | Throughput | Objects/s |
|------|-----------|-----------|
| Small GET (64 KiB) | 22.7 MiB/s | 363 |
| Small PUT (64 KiB) | 7.6 MiB/s | 121 |
| Big GET (1 GiB) | 136.9 MiB/s | 0.13 |
| Big PUT (1 GiB) | 100.1 MiB/s | 0.10 |

The machine was memory-starved during all runs (about 4 GB swap used, about 100 MB free RAM), so the real capability is likely higher.

## Known problems
- `mcli checksum verify` returns `NO_CHECKSUM` for objects uploaded without a checksum, and `UNKNOWN_UNSUPPORTED_COMPOSITE` for the 1.2 GB multipart object. Upload with `--checksum SHA256` and verify small objects.
- `--with-lock` only enables locking. Without a retention rule, versions could still be deleted in the first two tries.
- Delete anomaly after a 2-node outage: after restart, deletes sometimes reported "object does not exist" for an object that was still listed. Cause unknown (possible timing).
- Prometheus scrape config contains a bearer token. Keep `prometheus.generated.yml` out of git.
- The machine has 4 GB RAM and heavy swap, so benchmark numbers are low and noisy.
- Presigned URLs use host `lb:9000`, so `curl` needs `--connect-to`.
- A 1 GB test object cannot be pushed to GitHub, so it is git-ignored.

## Recommendation
**Layout (4 nodes x 1 drive, EC:2) is sound for lab and dev use.** It survives one full node loss with no impact, and with two nodes down it stays readable but not writable. Healing and rebuild worked with zero checksum differences, and `docker compose up -d --wait` rebuilds the lab in under a minute.

**Not ready for production** as tested: everything runs on one host, there is no TLS, and only 1 drive per node. Before any real use:
- use 8 GB+ RAM per host, or separate hosts
- alert on drive/node offline, S3 error rate, free capacity, and healing drives
- re-run the benchmark on a machine that is not swapping
- check the delete anomaly again on a larger machine

## Alerts to configure
`minio_cluster_drive_offline_total`, `minio_cluster_nodes_offline_total`, `minio_s3_requests_errors_total` (rate), `minio_cluster_capacity_usable_free_bytes`, `minio_s3_requests_waiting_total`, `minio_cluster_health_erasure_set_healing_drives`, `minio_cluster_health_status`. Reasons are in [docs/06-monitoring](docs/06-monitoring/readme.md).

## Clean up
```bash
docker compose --profile bench down -v --remove-orphans
```