import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import json
import boto3
import pandas as pd
from io import BytesIO
from datetime import datetime

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

s3 = boto3.resource('s3')

S3_LANDING_ZONE_BUCKET = s3.Bucket('pismo-landing-zone')
S3_STAGE_ZONE_PATH = "s3://pismo-stage-zone/events/"

def get_pending_files():
    files = []
    for object in S3_LANDING_ZONE_BUCKET.objects.filter(Prefix='pending/'):
        files.append(object.key)
    files.pop(0)
    return files

def parser_to_s3(files):
    for file in files:
        object = s3.Object(S3_LANDING_ZONE_BUCKET.name, file)
        with BytesIO(object.get()['Body'].read()) as object:
            jsons = object.read().decode("utf-8").replace('}{', '}\n{')
            df = pd.read_json(jsons, lines=True)
            sparkDF=spark.createDataFrame(df) 
            sparkDF.write.mode("append").format("parquet").save(S3_STAGE_ZONE_PATH)

def move_pending_files_to_processed(files):
    for file in files:
        move_source = {
            'Bucket': S3_LANDING_ZONE_BUCKET.name,
            'Key': file
        }
        today = datetime.today().strftime('%Y-%m-%d')
        file_name = file.split('/')[1]
        destination_key = f"processed/date={today}/{file_name}"
        s3.meta.client.copy(move_source, S3_LANDING_ZONE_BUCKET.name, destination_key)
        s3.Object(S3_LANDING_ZONE_BUCKET.name, file).delete()

def main():
    files = get_pending_files()
    parser_to_s3(files)
    move_pending_files_to_processed(files)

if __name__ == "__main__":
    main()