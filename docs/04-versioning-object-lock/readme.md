# Versioning & Object Lock
## Goal
Versioning is to save the version of object (Not only the new ones). Delete and overwrite create new version. With this, you can track the object history and create its recovery

Object lock is to make sure certain object can't be changed

## Environment
- Images : [Silo and NGINX as Load Balancer](./evidence/compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-versions.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/nix-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 10 Oct 2026

## Steps
### Create 2 Buckets
1. Versioning bucket
- Command:
```bash
mcli mb lab/version-bucket
```
- Expected  : Version Bucket Created
- Evidence  : [evidence/version-bucket-created.txt](./evidence/version-bucket-created.txt)
- Result    : PASS

2. Object lock bucket
- Command:
```bash
mcli mb --with-lock lab/lock-bucket
```
- Expected  : Lock Bucket Created
- Evidence  : [evidence/lock-bucket-created.txt](./evidence/lock-bucket-created.txt)
- Result    : PASS

3. Check First Status
- Command:
```bash
mcli stat lab/version-bucket
mcli stat lab/lock-bucket
```
- Expected  : Versioning `lab/version-bucket` is `Un-Versioned`. Versioning `lab/lock-bucket` is `Enabled`
- Evidence  : [evidence/bucket-stat.txt](./evidence/bucket-stat.txt)
- Result    : PASS

>**NOTE** : RUN IT EXACTLY AFTER CREATED BUCKET TO RECHIEVE ITS EXPECTED RESULT

### Get Ready with Object
To prepare object like how it's tested when develop

#### Create Object
You may use this command if you want to try the exact file while this document created
- Command:
```bash
echo "Version 1" > objects/obj-first-version.bin
```

#### Updated Object

### Upload Object

### Differences

#### Versioning

#### Object Lock

## How to reproduce and clean up

