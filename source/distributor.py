import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import concat_ws
from pyspark.sql import functions

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

def define_date_columns(datasource):
    datasource = datasource.withColumn("year", functions.year(functions.col("timestamp"))).withColumn("month", functions.month(functions.col("timestamp"))).withColumn("day", functions.dayofmonth(functions.col("timestamp")))
    return datasource

def define_event_type(datasource):
    datasource = datasource.toDF()
    datasource = datasource.withColumn("domain_event_type", concat_ws("-","domain","event_type"))
    return datasource

def save_to_trusted(datasource):
    datasource.write.mode("overwrite").format("parquet").partitionBy("domain_event_type", "year", "month", "day").save("s3://pismo-trusted-zone/events/")

def erase_stage():
    print('todo')

def deduplicate(datasource):
    return datasource
 
def main():
    datasource = glueContext.create_dynamic_frame.from_catalog(database = "pismo-stage-zone", table_name = "events")
    datasource = define_event_type(datasource)
    datasource = define_date_columns(datasource)
    save_to_trusted(datasource)

if __name__ == "__main__":
    main()