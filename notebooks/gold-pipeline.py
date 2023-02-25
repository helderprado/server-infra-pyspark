import airflow
from datetime import datetime
from airflow.operators.python_operator import PythonOperator
from pyspark.sql import SparkSession
import os
from airflow.models import DAG


def elt_silver_gold():
    spark = SparkSession.builder \
        .appName("etl-silver-gold") \
        .config("spark.hadoop.fs.s3.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider") \
        .config("spark.hadoop.fs.s3a.access.key", os.environ['AWS_ACCESS_KEY_ID']) \
        .config("spark.hadoop.fs.s3a.secret.key", os.environ['AWS_SECRET_ACCESS_KEY']) \
        .config("spark.hadoop.fs.s3a.proxy.host", "minio1") \
        .config("spark.hadoop.fs.s3a.endpoint", "minio1") \
        .config("spark.hadoop.fs.s3a.proxy.port", "9000") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .getOrCreate()

    start = datetime.now()

    print(start)

    df = spark.read.parquet("s3a://silver/airplane-delay/2018")

    print(df.printSchema())

    df.write.partitionBy("ORIGIN").parquet(
        "s3a://gold/airplane-delay", mode="overwrite")

    end = datetime.now()
    print(end)

    print(end - start)


args = {
    'owner': 'Helder',
    'start_date': airflow.utils.dates.days_ago(1)
}


dag = DAG(
    dag_id='etl-silver-gold',
    default_args=args,
    schedule_interval=None
)

A = PythonOperator(
    task_id='collect-and-land-data-to-silver',
    python_callable=elt_silver_gold,
    dag=dag
)

A
