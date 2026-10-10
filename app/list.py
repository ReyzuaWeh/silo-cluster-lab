from common import s3, BUCKET

print("buckets:", [b["Name"] for b in s3.list_buckets()["Buckets"]])
objs = s3.list_objects_v2(Bucket=BUCKET).get("Contents", [])
print("objects:", [o["Key"] for o in objs])