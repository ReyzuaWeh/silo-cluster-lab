# Monitoring

## Goal
Scrape the Silo `minio_*` metrics with a local Prometheus container. Show queries for capacity, nodes and drives online, request rate and errors, healing status, and list the metrics worth alerting on.

## Environment
- Images : [Prometheus, Silo, and NGINX as Load Balancer](./evidence/01-compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-version.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/local-os-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 19 Oct 2026

## Steps

### Process
1. Create local scrape cluster
- Command:
```bash
. ./preused-cli/mcli.bash
mcli admin prometheus generate lab > monitoring/prometheus.generated.yml
```
- Expected  : Created `prometheus.generated.yml` for prometheus config
- Evidence  : [./evidence/00-generate.txt](./evidence/00-generate.txt)
- Result    : PASS

2. Create prometheus

You may use this command on the project root because prometheus already in `docker-compose.yml`

- Command:
```bash
docker compose up -d prometheus
```
- Expected  : Created prometheus services
- Evidence  : [./evidence/01-up-prometheus.txt](./evidence/01-up-prometheus.txt), [./evidence/01-compose-ps.txt](./evidence/01-compose-ps.txt)
- Result    : PASS

3. Verify and Testing
- Command:
```bash
curl -s --data-urlencode "query=up" http://127.0.0.1:9090/api/v1/query
```
- Expected  : Geting 200 status, get metrics instance, job config, result 1
- Evidence  : [./evidence/02-prometheus-status.txt](./evidence/02-prometheus-status.txt)
- Result    : PASS

4. Useful panels or queries
- Command:
```bash
curl -s -H "Authorization: Bearer <TOKEN-FROM-FIRST-STEP>" http://127.0.0.1:9000/minio/v2/metrics/cluster | grep ^minio_ | cut -d'{' -f1 | sort -u 
q() { curl -sS --data-urlencode "query=$1" http://127.0.0.1:9090/api/v1/query; echo; }
q 'minio_cluster_capacity_usable_total_bytes'
q 'minio_cluster_capacity_usable_free_bytes'
q 'minio_cluster_capacity_usable_total_bytes - minio_cluster_capacity_usable_free_bytes'
q 'minio_cluster_usage_total_bytes'
q 'minio_cluster_nodes_online_total'
q 'minio_cluster_drive_online_total'
q 'sum(rate(minio_s3_requests_total[1m]))'
q 'sum(rate(minio_s3_requests_errors_total[1m]))'
q 'minio_cluster_health_erasure_set_healing_drives'
q 'minio_cluster_health_status'
```
- Expected  : Getting list of metrics and result of some of it
- Evidence  : [./evidence/03-metric-names.txt](./evidence/03-metric-names.txt), [./evidence/04-queries-healthy.txt](./evidence/04-queries-healthy.txt)
- Result    : PASS

5. Alert metric and its reasons
- Command:
```bash
printf '\nrule_files:\n  - /etc/prometheus/alerts.yml\n' >> monitoring/prometheus.generated.yml
docker compose down prometheus
docker compose up -d prometheus
```
- Expected  : Rule files added in `prometheus.generated.yml` and ready to use alert
- Evidence  : [./evidence/05-prometheus-config-redacted.txt](./evidence/05-prometheus-config-redacted.txt)
- Result    : PASS
- Reasons   :
    - `minio_cluster_drive_offline_total` > 0: redundancy is reduced, and losing another drive could make data unreadable
    - `minio_cluster_nodes_offline_total` > 0: capacity and quorum drop, and with two nodes down writes fail
    - `minio_s3_requests_errors_total` (rate): the most direct signal of client-facing impact
    - `minio_cluster_capacity_usable_free_bytes` < 20%: a full cluster rejects writes, and adding capacity takes time
    - `minio_s3_requests_waiting_total`: requests are queuing, which indicates saturation or a bottleneck
    - `minio_cluster_health_erasure_set_healing_drives` > 0: a drive is being healed, so redundancy is not yet fully restored
    - `minio_cluster_health_status` == 0: the cluster reports itself as unhealthy

### Preused CLI
1. Activate all bashes
```bash
chmod +x preused-cli/06-monitoring/*.bash
```
2. Order to used
- [Generate prometheus.generated.yml](../../preused-cli/06-monitoring/00-create-prometheus-config.bash)
- [Up prometheus service](../../preused-cli/06-monitoring/01-up-prometheus.bash)
- [Run Useful Panels](../../preused-cli/06-monitoring/02-run-useful-panels.bash)

## Findings
1. If you using scrape method, then it may give you a token to access your S3 with Prometheus. So, you have to write in ignore and use CI/CD to auto configurate

## How to Reproduce and Clean Up
Same as [Past Configuration](../02-healthcheck/readme.md#how-to-reproduce-and-clean-up)