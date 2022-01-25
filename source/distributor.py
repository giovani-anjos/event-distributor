import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SQLContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import concat_ws
from pyspark.sql import functions
import boto3

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
spark.conf.set("spark.sql.sources.partitionOverwriteMode","dynamic")
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
sqlContext = SQLContext(spark.sparkContext, spark)

s3 = boto3.resource('s3')

S3_STAGE_ZONE_BUCKET = s3.Bucket('pismo-stage-zone')
S3_TRUSTED_ZONE_PATH = "s3://pismo-trusted-zone/events/"

def define_date_columns(datasource):
    datasource = datasource.withColumn("year", functions.year(functions.col("timestamp"))).withColumn("month", functions.month(functions.col("timestamp"))).withColumn("day", functions.dayofmonth(functions.col("timestamp")))
    return datasource

def define_event_type(datasource):
    datasource = datasource.toDF()
    datasource = datasource.withColumn("domain_event_type", concat_ws("-","domain","event_type"))
    return datasource

def save_to_trusted(datasource):
    datasource.write.mode("overwrite").format("parquet").partitionBy("domain_event_type", "year", "month", "day").save(S3_TRUSTED_ZONE_PATH)

def deduplicate(datasource):
    datasource.registerTempTable("events")
    datasource = sqlContext.sql(
        '''
            SELECT 
                *
            FROM (
                SELECT 
                    *,
                    dense_rank() OVER (PARTITION BY event_id ORDER BY timestamp DESC) AS rank
                FROM events
            ) vo WHERE rank = 1
        '''
        )
    datasource = datasource.drop(datasource.rank)
    return datasource
 
def erase_stage():
    files = []
    for object in S3_STAGE_ZONE_BUCKET.objects.filter(Prefix='events/'):
        files.append(object.key)
    files.pop(0)
    for file in files:
        s3.Object(S3_STAGE_ZONE_BUCKET.name, file).delete()

def main():
    datasource = glueContext.create_dynamic_frame.from_catalog(database = "pismo-stage-zone", table_name = "events")
    datasource = define_event_type(datasource)
    datasource = define_date_columns(datasource)
    datasource = deduplicate(datasource)
    save_to_trusted(datasource)
    erase_stage()

if __name__ == "__main__":
    main()