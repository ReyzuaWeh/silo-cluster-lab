# Small Benchmark

## Goal
Run warp for small-object PUT/GET and large-object PUT/GET (3 runs each) against the Silo cluster through the load balancer, and record machine load at the same time.


## Environment
- Images : [Prometheus, Silo, and NGINX as Load Balancer](../06-monitoring//evidence/01-compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-version.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/local-os-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 

## Steps
1. Prepare warp
- Nixos
    - Commands  :
```bash
nix-shell
```
    - Expected  : Wrap installed temporary
    - Evidence  :
    - Result    :

2. Small-object PUT/GET

3. Large-object PUT/GET

4. Machine load during runs

## How to Reproduce and Clean Up
Same as [Past Configuration](../02-healthcheck/readme.md#how-to-reproduce-and-clean-up)