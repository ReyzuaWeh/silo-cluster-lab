import os
from pathlib import Path
import boto3
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

OBJ_DIR = ROOT / "objects"
BUCKET = "sdk-bucket"
KEY = "obj-10m.bin"
SRC = OBJ_DIR / "obj-10m.bin"
DST = OBJ_DIR / "obj-10m.sdk.bin"

s3 = boto3.client(
    "s3",
    endpoint_url=os.environ.get("S3_ENDPOINT", "http://127.0.0.1:9000"),
    aws_access_key_id=os.environ["MINIO_ROOT_USER"],
    aws_secret_access_key=os.environ["MINIO_ROOT_PASSWORD"],
    region_name="us-east-1",
)