# Small Benchmark

## Goal
Run warp for small-object PUT/GET and large-object PUT/GET (3 runs each) against the Silo cluster through the load balancer, and record machine load at the same time.

> **All numbers in this document are indicative, lab scale (4 GB RAM, heavy swap use, everything on one machine). They are not production figures.**

## Environment
- Images : [Prometheus, MinIO Warp, Silo, and NGINX as Load Balancer](./evidence/01-compose-images.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-version.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/local-os-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Warp: `quay.io/minio/aistor/warp:v1.8.2`, run as a Compose service (profile `bench`) on the same Docker network as the cluster, targeting the load balancer (`lb:9000`), TLS off.
- Bucket: `warp-bench` (dedicated; warp wipes it before and after each run).
- Date : 21 October 2026

Benchmark parameters (from `bench/*.yml`):

| Test | Object size | Concurrency | Duration | Pre-uploaded objects (GET) |
|------|-------------|-------------|----------|----------------------------|
| small-put / small-get | 64 KiB | 8 | 1m | 500 |
| big-put / big-get | 1 GiB | 1 | 3m | 2 |

Large objects were limited to 1 GiB with concurrency 1 because the machine has only 4 GB RAM.

## Steps

### 1. Small-object PUT/GET
- Command (run from the repo root):
```bash
{
BENCH=get-small docker compose run --rm -T warp;
BENCH=get-small docker compose run --rm -T warp;
BENCH=get-small docker compose run --rm -T warp;
BENCH=put-small docker compose run --rm -T warp;
BENCH=put-small docker compose run --rm -T warp;
BENCH=put-small docker compose run --rm -T warp;
} 2>&1 | tee docs/07-benchmark/evidence/02-getput-small.txt
```
- Expected  : All 6 runs complete and print a final `Report` with no error message. Based on earlier single-run test (about 130 obj/s PUT), PUT is expected to be slower than GET.
- Actual    : All 6 runs completed (3 GET, then 3 PUT; the order is the order of the blocks in the file). Every run printed a full report and no error message appears in the file. See the results table in Findings.
- Evidence  : [./evidence/02-getput-small.txt](./evidence/02-getput-small.txt)
- Result    : PASS

### 2. Large-object PUT/GET
- Command (run from the repo root):
```bash
{
BENCH=get-big docker compose run --rm -T warp;
BENCH=get-big docker compose run --rm -T warp;
BENCH=get-big docker compose run --rm -T warp;
BENCH=put-big docker compose run --rm -T warp;
BENCH=put-big docker compose run --rm -T warp;
BENCH=put-big docker compose run --rm -T warp;
} 2>&1 | tee docs/07-benchmark/evidence/04-getput-big.txt
```
- Expected  : All 6 runs complete with a final `Report`, no error message. Throughput in MiB/s should be much higher than small objects, while obj/s is near 0.1.
- Actual    : All 6 runs completed (3 GET, then 3 PUT). Throughput is about 137 MiB/s for GET and 100 MiB/s for PUT. See the results table in Findings.
- Evidence  : [./evidence/04-getput-big.txt](./evidence/04-getput-big.txt)
- Result    : PASS

### 3. Machine load during runs
- Command (started in a second terminal before the first run, stopped with Ctrl+C after the last run):
```bash
vmstat 2 | tee docs/07-benchmark/evidence/03-load-vmstat.txt        # step 1
vmstat 2 | tee docs/07-benchmark/evidence/05-load-big-vmstat.txt    # step 2
```
- Expected  : Machine stays usable, no OOM, and swap use is visible in the record.
- Actual    : The machine stayed usable and no run failed. However, swap was already heavily used and free RAM stayed very low during both sessions (details in Findings).
- Evidence  : [./evidence/03-load-vmstat.txt](./evidence/03-load-vmstat.txt), [./evidence/05-load-big-vmstat.txt](./evidence/05-load-big-vmstat.txt)
- Result    : PASS (the high swap use is documented as a limitation, not a failure)

## Findings

### Results (3 runs each, indicative)

| Test | Run 1 | Run 2 | Run 3 | Mean throughput | Mean obj/s |
|------|-------|-------|-------|-----------------|------------|
| Small GET (64 KiB) | 22.90 MiB/s, 366.47 obj/s | 22.35 MiB/s, 357.60 obj/s | 22.82 MiB/s, 365.18 obj/s | 22.69 MiB/s | 363.1 |
| Small PUT (64 KiB) | 6.09 MiB/s, 97.37 obj/s | 8.11 MiB/s, 129.74 obj/s | 8.52 MiB/s, 136.35 obj/s | 7.57 MiB/s | 121.2 |
| Big GET (1 GiB) | 134.64 MiB/s | 141.42 MiB/s | 134.69 MiB/s | 136.92 MiB/s | 0.13 |
| Big PUT (1 GiB) | 96.46 MiB/s | 99.12 MiB/s | 104.68 MiB/s | 100.09 MiB/s | 0.10 |

Latency (small objects, per run, 1 to 3):

| Test | Average latency | p99 latency |
|------|-----------------|-------------|
| Small GET | 23.4 / 22.5 / 21.6 ms | 54.4 / 55.0 / 54.3 ms |
| Small PUT | 92.5 / 68.4 / 58.4 ms | 395.4 / 359.6 / 363.3 ms |

### Observations
- **GET is consistent, PUT is not.** Small GET varies by only about 2 percent between runs. Small PUT varies from 6.09 to 8.52 MiB/s, and its p99 latency (about 360 to 395 ms) is roughly 7 times that of GET. Run 1 of small PUT was the slowest; the cause is not known from this data.
- **PUT is slower than GET** in both sizes (about 3x for small, about 1.4x for big). This is expected, since a write must be erasure-coded and written to all 4 nodes.
- **Large objects:** the cluster reached about 137 MiB/s read and 100 MiB/s write with a single stream of 1 GiB objects.
- Each reported run lasts a little less than the configured duration (for example 57s for 1m). Warp excludes warm-up and tail time from the analysis.

### Machine load (from vmstat, units in KiB)
| Session | Samples | Swap used (swpd) | Lowest free RAM | Max swap-in / swap-out | Max I/O wait |
|---------|---------|------------------|-----------------|------------------------|--------------|
| Small runs (`03`) | 250 | 4.0 to 4.65 GB | about 98 MB | 33,726 / 54,732 KiB/s | 26 |
| Big runs (`05`) | 667 | 4.1 to 4.58 GB | about 101 MB | 62,558 / 61,080 KiB/s | 13 |

- The machine was **memory-starved the whole time**. Swap was already about 4 GB used in the first sample, free RAM stayed near 100 MB, and swap-in/out reached tens of MB/s. So the benchmark partly measured swapping, and the real capability of the cluster is likely higher than shown here.
- No container restart or OOM was observed, and warp reported complete results for all 12 runs.
- CPU reached near full use in some samples (for example `us 61 / sy 33 / id 3` in the big-object session). The load generator (warp), nginx, Prometheus and 4 Silo nodes share one machine, so they compete for CPU and RAM.

## How to Reproduce and Clean Up
Start the cluster as described in [Past Configuration](../02-healthcheck/readme.md#how-to-reproduce-and-clean-up)