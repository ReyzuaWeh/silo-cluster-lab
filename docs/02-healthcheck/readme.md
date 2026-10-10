# Healthchecks
## Goal
To ensure MinIO is healthy and running, we will use the healthcheck feature in Docker Compose. This will allow us to monitor the health of the MinIO service and take appropriate actions if it becomes unhealthy

## Environment
- Images : [Silo and NGINX as Load Balancer](./evidence/compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-versions.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/nix-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 08 Oct 2026

## Steps
Actually, you just only have to use these command from begining before start and get 200 code. However, it is important to make sure its services work like it should be. You may use these kind of command

### Silo Healthcheck
Command :
```bash
docker compose exec <silo-node> silo healthcheck
```
- Expected result   : Getting 200 status from its node
- Result            : PASS
- Evidence          : [evidence/healthcheck-cli.txt](./evidence/healthcheck-cli.txt)

### MinIO Liveness
Command :
```bash
curl -si http://127.0.0.1:9000/minio/health/live
```
- Expected result   : Getting 200 status from its header
- Result            : PASS
- Evidence          : [evidence/minio-liveness.txt](./evidence/minio-liveness.txt)

### MinIO Cluster Health
Command :
```bash
curl -si http://127.0.0.1:9000/minio/health/cluster
```
- Expected result   : Getting 200 status from its header
- Result            : PASS
- Evidence          : [evidence/minio-clusterhealth.txt](./evidence/minio-clusterhealth.txt)

## How to reproduce and clean up
As for this, healthcheck and liveness has checked in `docker-compose.yml`. So, you may compose it and test cluster.

1. Start Cluster

Command:
```bash
docker compose up -d
```
- Expected  : 4 silo containers + lb (nginx) are Up and Healthy
- Result    : PASS
- Evidence  : [evidence/compose-ps.txt](../01-build-cluster/evidence/compose-ps.txt)

2. Check its Cluster

Use the [MinIO Cluster Health CLI](#minio-cluster-health)

3. Run following command to stop
```bash
docker compose down
```
