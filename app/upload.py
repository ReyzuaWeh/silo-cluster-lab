from common import s3, BUCKET, KEY, SRC

s3.upload_file(str(SRC), BUCKET, KEY,
               ExtraArgs={"Metadata": {"project": "silo-lab"}})
print("uploaded", KEY)
print(s3.head_object(Bucket=BUCKET, Key=KEY)["Metadata"])