from common import s3, BUCKET, KEY

s3.delete_object(Bucket=BUCKET, Key=KEY)
print("deleted", KEY)
objs = s3.list_objects_v2(Bucket=BUCKET).get("Contents", [])
print("objects left:", [o["Key"] for o in objs])