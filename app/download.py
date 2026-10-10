from common import s3, BUCKET, KEY, DST

s3.download_file(BUCKET, KEY, str(DST))
print("downloaded to", DST.name)