import airflow
from datetime import datetime
from airflow.operators.python_operator import PythonOperator
from pyspark.sql import SparkSession
import os
from airflow.models import DAG


def elt_raw_silver():
    spark = SparkSession.builder \
        .appName("etl-raw-silver") \
        .config("spark.hadoop.fs.s3.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider") \
        .config("spark.hadoop.fs.s3a.access.key", os.environ['AWS_ACCESS_KEY_ID']) \
        .config("spark.hadoop.fs.s3a.secret.key", os.environ['AWS_SECRET_ACCESS_KEY']) \
        .config("spark.hadoop.fs.s3a.proxy.host", "s3") \
        .config("spark.hadoop.fs.s3a.endpoint", "s3") \
        .config("spark.hadoop.fs.s3a.proxy.port", "9000") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .getOrCreate()

    start = datetime.now()

    print(start)

    df = spark.read.csv("s3a://raw/2018.csv", header=True, inferSchema=True)

    print(df.printSchema())

    df.write.parquet("s3a://silver/airplane-delay/2018", mode="overwrite")

    end = datetime.now()
    print(end)

    print(end - start)


args = {
    'owner': 'Helder',
    'start_date': airflow.utils.dates.days_ago(1)
}


dag = DAG(
    dag_id='etl-raw-silver',
    default_args=args,
    schedule_interval=None
)

A = PythonOperator(
    task_id='collect-and-land-data-to-silver',
    python_callable=elt_raw_silver,
    dag=dag
)

A
