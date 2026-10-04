# Build Cluster

## Goal
Stand up a 4-node distributed Silo cluster (4 nodes x 1 drive) behind an nginx load balancer, and show all nodes and drives online.

## Environment
- Images : [Silo and NGINX as Load Balancer](./evidence/compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](./evidence/docker-versions.txt)
- OS : [Nix and NixOS Version](./evidence/nix-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](./evidence/free-h.txt)
- Date : 04 Oct 2026

## Steps
### 1. Start Cluster
Command:
```bash
docker compose up -d
```
- Expected  : 4 silo containers + lb (nginx) are Up.
- Result    : PASS
- Evidence  : [evidence/compose-ps.txt](./evidence/compose-ps.txt)

### 2. Create `mcli`
>**NOTE** : You don't have to save it as function but it will be better if you save it
- Access `.env`

To get its variables

```bash
. .env
```

- Create `mcli` function
>**NOTE** : mount it to your `$HOME` because it has credentials
```bash
mcli() { docker run --rm --network silo-cluster_lab -v "$HOME/.mcli-lab:/cfg" --entrypoint mcli "$SILO_IMAGE" --config-dir /cfg "$@"; }
```

### 3. Show Nodes and Drive Online
```bash
mcli admin info lab
```
- Expected  : 4 nodes online, 4 drives online.
- Result    : PASS
- Evidence  : [evidence/admin-info.txt](./evidence/admin-info.txt)

### 3. Console login
Open        : http://127.0.0.1:9001 and log in.
Expected    : dashboard loads.
Result      : PASS
Evidence    : [screenshots/console.png](./screenshots/login-to-console.png)

### 4. Memory check
```bash
docker stats --no-stream
```
Expected    : no node near its memory limit.
Result      : PASS
Evidence    : [evidence/docker-stats.txt](./evidence/docker-stats.txt), [evidence/free-h.txt](./evidence/free-h.txt)

## Finding
1. **Silo setup is simple.** One image for all four nodes, one `server http://silo{1...4}/data` command, and `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`. No extra config files needed like in its documentation. The 4-drive erasure set (EC:2) formed and all nodes came online.

## How to Reproduce and Clean Up
1. Clone the repo and cd into it.
```bash
git clone https://github.com/ReyzuaWeh/silo-cluster-lab.git
cd silo-cluster-lab
```

2. Copy the `.env.example` file to `.env` and edit it to set the `NGINX_IMAGE` variable to a valid NGINX image tag.
```bash
cp .env.example .env
```
>NOTE : The `.env` file contains some variable that hasn't been set yet. Please set its variables first.

3. Run the following command to start the cluster.
```bash
docker-compose up -d
```

4. Stop without delete its data
```bash
docker-compose down
```