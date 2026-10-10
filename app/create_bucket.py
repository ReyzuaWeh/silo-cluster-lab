from common import s3, BUCKET

try:
    s3.create_bucket(Bucket=BUCKET)
    print(f"bucket {BUCKET} created")
except s3.exceptions.BucketAlreadyOwnedByYou:
    print(f"bucket {BUCKET} already exists")