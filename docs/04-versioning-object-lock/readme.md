# Versioning & Object Lock
## Goal
Versioning is to save the version of object (Not only the new ones). Delete and overwrite create new version. With this, you can track the object history and create its recovery

Object lock is to make sure certain object can't be changed for its version. This feature also including versioning feature

## Environment
- Images : [Silo and NGINX as Load Balancer](./evidence/compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-versions.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/nix-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 10 Oct 2026
---
- Images : [Silo and NGINX as Load Balancer](./evidence/compose-ps.txt)
- Docker and Docker Compose versions : [Docker and Docker Compose Versions](../01-build-cluster/evidence/docker-versions.txt)
- OS : [Nix and NixOS Version](../01-build-cluster/evidence/nix-version.txt)
- Topology :
    - Profile C (more small machines, 4GB RAM and 8GB Swap): 4 nodes x 1 drive [Topology](../01-build-cluster/evidence/free-h.txt)
- Date : 11 Oct 2026

## Steps
### Create 2 Buckets
1. Versioning bucket
- Command:
```bash
mcli mb lab/version-bucket
mcli version enable lab/version-bucket
```
- Expected  : Version Bucket Created and Versioning is Enabled
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
- Expected  : Versioning `lab/version-bucket` is `Un-Versioned` If you haven't enable it. Versioning `lab/lock-bucket` is `Enabled`
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
echo "Update Version 1.2" > objects/obj-second-version.bin
```

#### Upload Object
- Command:
```bash
mcli cp objects/obj-first-version.bin lab/version-bucket
mcli cp objects/obj-first-version.bin lab/lock-bucket 
```
- Expected  : File is uploaded to both bucket
- Evidence  : [evidence/object-upload.txt](./evidence/object-upload.txt)
- Result    : PASS


#### Updated Object
- Command:
```bash
mcli cp objects/obj-second-version.bin lab/version-bucket/obj-first-version.bin
mcli cp objects/obj-second-version.bin lab/lock-bucket/obj-first-version.bin
```
- Expected  : File is updating the first version of both buckets
- Evidence  : [evidence/object-updated.txt](./evidence/object-updated.txt)
- Result    : PASS

#### Remove Object
```bash
mcli rm lab/version-bucket/obj-first-version.bin
mcli rm lab/lock-bucket/obj-first-version.bin
```
- Expected  : Created delete marker for both buckets
- Evidence  : [evidence/object-remove.txt](./evidence/object-remove.txt)
- Result    : PASS

#### Listing Object Version
```bash
mcli ls --versions lab/version-bucket
mcli ls --versions lab/lock-bucket
```
- Expected  : Listing object version of the bucket
- Evidence  : [evidence/object-list.txt](./evidence/object-list.txt)
- Result    : PASS

#### Restore Object Version
```bash
mcli cp --version-id "$VERSION_ID"  lab/version-bucket/obj-first-version.bin  lab/version-bucket/obj-first-version.bin
mcli cp --version-id "$VERSION_ID_LOCK"  lab/lock-bucket/obj-first-version.bin  lab/lock-bucket/obj-first-version.bin
```
- Expected  : Restore object to certain version
- Evidence  : [evidence/object-restore.txt](./evidence/object-restore.txt)
- Result    : PASS

You may set its variable using awk
```bash
VERSION_ID=$(mcli ls --versions lab/version-bucket | awk '$NF=="obj-first-version.bin" && $(NF-2)=="v2" {print $(NF-3)}')
VERSION_ID_LOCK=$(mcli ls --versions lab/lock-bucket | awk '$NF=="obj-first-version.bin" && $(NF-2)=="v2" {print $(NF-3)}')
# NF is the last column value
```

>**NOTE**: You will create new version of it whenever you restore. You can see on [this image](./screenshots/object-versions.png)

### Differences
The exact differences between these two are about how they treat versioniong of their objects

#### Versioning
In this, you may delete a version of object in the bucket

- Command
```bash
mcli rm --version-id "$VERSION_ID" lab/version-bucket/obj-first-version.bin
```
- Expected  : Deleted Version of Object
- Evidence  : [evidence/object-version-delete.txt](./evidence/object-version-delete.txt), [evidence/object-before-after-version-delete.txt](./evidence/object-before-after-version-delete.txt)
- Result    : PASS

#### Object Lock
In this, you can't delete version of object in the bucket

1. Delete
- Command
```bash
mcli rm --version-id "$VERSION_ID_LOCK" lab/lock-bucket/obj-first-version.bin
```
- Expected  : Can't Delete Version
- Evidence  : [evidence/object-version-lock-delete(1stfail).txt](./evidence/object-version-lock-delete(1stfail).txt), [evidence/object-version-lock-delete(2ndfail).txt](./evidence/object-version-lock-delete(2ndfail).txt), [evidence/object-version-lock-delete.txt](./evidence/object-version-lock-delete.txt), 
- Result    : FAIL because it can delete in first 2 tries, PASS after that.([Detail](#findings))

2. Activate Retention

FYI, lock isn't active for the first time even though you have set `--with-lock`. It only states that the bucket can use lock. You still have to activate and choose its types of lock. Also, you have to set its duration whether with countdown or with date
- Command
```bash
mcli retention set --default GOVERNANCE 1d lab/lock-bucket

# You may choose between GOVERNANCE or COMPLIANCE
# Use --default if you want to set the bucket
```
- Expected  : Retention of bucket set to GOVERNANCE
- Evidence  : [evidence/retention-set.txt](./evidence/retention-set.txt), [evidence/retention-before-after.txt](./evidence/retention-before-after.txt)
- Result    : PASS

3. Retention GOVERNANCE

In this status, you may still delete the version. If only you have root or admin access using `--bypass`.

- Command
```bash
mcli rm --bypass --version-id "$VERSION_ID_LOCK" lab/lock-bucket/obj-first-version.bin
```
- Expected  : Success to delete as long using admin
- Evidence  : [evidence/lock-governance-bypass.txt](./evidence/lock-governance-bypass.txt)
- Result    : PASS

4. Retention COMPLIANCE

In this status, you can't do anything to its version. Even, if you admin, you still can't

- Command
```bash
mcli rm --bypass --version-id "$VERSION_ID_LOCK" lab/lock-bucket/obj-first-version.bin
```
- Expected  : Fail to delete even when using admin
- Evidence  : [evidence/lock-compliance-bypass.txt](./evidence/lock-compliance-bypass.txt)
- Result    : PASS

### Preused CLI
From this part, you may use preused CLI that's been try while docummenting it. It's to help you testing exactly while its documented and has been justified

#### Prerequisite
You must give acces to its bash script and use mcli bash. Run these command on root of directory

1. Activate MCLI
```bash
chmod +x preused-cli/mcli.bash
```

2. Activate Versioning Object Lock Bashes
```bash
chmod +x preused-cli/04-versioning-object-lock/*.bash
```

#### CLI Order to Use
1. [Create Bucket](../../preused-cli/04-versioning-object-lock/01-create-bucket-stat.bash)
2. [Manage Object](../../preused-cli/04-versioning-object-lock/02-upload-update-rm-object.bash)
3. [Listing Object Version](../../preused-cli/04-versioning-object-lock/03-list-object-version.bash)
4. [Restore Object Version](../../preused-cli/04-versioning-object-lock/04-restore-object-version.bash)
5. [Versioning Delete Version](../../preused-cli/04-versioning-object-lock/05-versioning-delete-version.bash)
6. [Retention Governance](../../preused-cli/04-versioning-object-lock/06-retention-governance.bash)
7. [Retention Compliance](../../preused-cli/04-versioning-object-lock/06-retention-compliance.bash)

## Findings
- **Version Deleted in Object Lock**. It happens because we only stated the bucket to be able locking it and we have to set it directly to its object. We haven't activate it. Follow [this](#object-lock) on second step to handle it.

```bash
mcli retention set --version-id <ID> GOVERNANCE 1d lab/lock-bucket/obj-first-version.bin
```

## How to reproduce and clean up
Same as [Past Configuration](../02-healthcheck/readme.md#how-to-reproduce-and-clean-up)