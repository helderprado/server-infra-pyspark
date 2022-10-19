library(sparklyr)
library(dplyr)

# Desconectar alguma conexão ativa com o spark
spark_disconnect_all()

# Set configuration:
conf <- spark_config()

conf$sparklyr.gateway.start.timeout <- 60 * 5

# Bypass the JAR's issues:

conf$sparklyr.defaultPackages <- c("com.amazonaws:aws-java-sdk-bundle:1.11.819",
                                   "org.apache.hadoop:hadoop-aws:3.2.3",
                                   "org.apache.hadoop:hadoop-common:3.2.3")

# alterar memória utilizada pelo núcleo spark
conf$`sparklyr.shell.driver-memory` <- '8G'
conf$`sparklyr.shell.executor-memory` <- '8G'

# conectar ao spark
sc <- spark_connect(master = "local", config = conf, spark_home="/usr/local/airflow/spark/spark-3.3.0-bin-hadoop3")

ctx <- spark_context(sc)

jsc <- invoke_static(sc, 
                     "org.apache.spark.api.java.JavaSparkContext", 
                     "fromSparkContext", 
                     ctx)

# Set the S3 configs: 

hconf <- jsc %>% invoke("hadoopConfiguration")

hconf %>% invoke("set", "fs.s3a.access.key", "admin")
hconf %>% invoke("set", "fs.s3a.secret.key", "sample_key")
hconf %>% invoke("set", "fs.s3a.endpoint", "s3:9000")
hconf %>% invoke("set", "fs.s3a.path.style.access", "true")
hconf %>% invoke("set", "fs.s3a.connection.ssl.enabled", "false")
hconf %>% invoke("set", "fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")

# ler o arquivo csv e atribuir o dataframe
df <- spark_read_parquet(sc, name = "df", path="s3a://silver/airline.parquet")

glimpse(df)

# carregar o dataframe tratado para a camada silver
spark_write_parquet(df, path = "s3a://gold/airline.parquet", mode = "overwrite", partition_by = c('YEAR','MONTH'))

# desconectar o spark context
spark_disconnect(sc)


