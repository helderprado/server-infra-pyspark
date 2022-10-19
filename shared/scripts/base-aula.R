library(sparklyr)
library(dplyr)
library(ggplot2)
library(carrier)
library(mlflow)
library(dplyr)
library(reticulate)
library(stats)
library(glue)

use_condaenv('mlflow')

# alterar caminho da variável de ambiente do mlflow no python
Sys.setenv(MLFLOW_BIN="/home/rstudio/.local/share/r-miniconda/envs/mlflow/bin/mlflow")

# alterar caminho da variável de ambiente do python
Sys.setenv(MLFLOW_PYTHON_BIN="/home/rstudio/.local/share/r-miniconda/envs/mlflow/bin/python")

# Desconectar alguma conexão ativa com o spark
spark_disconnect_all()

# instanciar a configuração do spark
conf <- spark_config()

# aumentar o timeout da conexão do spark para dar tempo de fazer os downloads dos packages
conf$sparklyr.gateway.start.timeout <- 60 * 5

# adicionar os pacotes necessários para utilizar os buckets s3
conf$sparklyr.defaultPackages <- c("com.amazonaws:aws-java-sdk-bundle:1.11.819",
                                   "org.apache.hadoop:hadoop-aws:3.2.3",
                                   "org.apache.hadoop:hadoop-common:3.2.3")


# alterar memória utilizada pelo núcleo spark
conf$`sparklyr.shell.driver-memory` <- '8G'
conf$`sparklyr.shell.executor-memory` <- '8G'

# conectar ao spark
sc <- spark_connect(master = "local", config = conf, spark_home="/home/rstudio/spark/spark-3.3.0-bin-hadoop3")

# atribuir o contexto do spark papra iniciar as configurações do s3
ctx <- spark_context(sc)

jsc <- invoke_static(sc, 
                     "org.apache.spark.api.java.JavaSparkContext", 
                     "fromSparkContext", 
                     ctx)

# adicionar as configurações para acessar os buckets do minio
hconf <- jsc %>% invoke("hadoopConfiguration")
hconf %>% invoke("set", "fs.s3a.access.key", "admin")
hconf %>% invoke("set", "fs.s3a.secret.key", "sample_key")
hconf %>% invoke("set", "fs.s3a.endpoint", "s3:9000")
hconf %>% invoke("set", "fs.s3a.path.style.access", "true")
hconf %>% invoke("set", "fs.s3a.connection.ssl.enabled", "false")
hconf %>% invoke("set", "fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")

# verificar o tempo de processamento para coletar os dados do dataset inteiro
system.time(df_completo <- spark_read_parquet(sc, name="df", path="s3a://gold/airline.parquet"))

# contagem de linhas
sdf_nrow(df_completo)

# verificar o tempo de processamento para coletar os dados do dataset do ano de 2017
system.time(df_2017 <- spark_read_parquet(sc, name="df", path="s3a://gold/airline.parquet/YEAR=2017"))

# contagem de linhas
sdf_nrow(df_2017)

# verificar o tempo de processamento para coletar os dados do dataset do ano de 2017 e mês 10
system.time(df_2017_10 <- spark_read_parquet(sc, name="df", path="s3a://gold/airline.parquet/YEAR=2017/MONTH=10"))

# contagem de linhas
sdf_nrow(df_2017_10)

# ler o dataset utilizando o spark diretamente no bucket s3
df <- spark_read_parquet(sc, name="df", path="s3a://gold/airline.parquet")

# contagem do número de linhas do dataset
sdf_nrow(df)

# visualizar as variáveis em formato de linha com as observações
glimpse(df)

# coletar a última data do dataset como vector
ultima_data <- df %>% 
  summarise(max_date = max(FL_DATE)) %>% 
  collect()

# coletar o valor da última data
ultima_data <- ultima_data[[1]]

# coletar a data que é 3 meses antes à última data
tres_meses_antes <- seq(ultima_data, length = 2, by = "-3 months")[2]

# filtrar o dataset no período entre essas duas datas
df <- df %>% filter(
  FL_DATE >= tres_meses_antes,
  FL_DATE <= ultima_data
)

# contagem do número de linhas do dataset
sdf_nrow(df)

# verificar as 5 primeiras linhas do dataset
head(df)

#selecionar algumas colunas
df <- select(df, ACTUAL_ELAPSED_TIME, DISTANCE)

# retirar missing values do dataset
df <- df %>% 
  na.omit

# trazer o dataframe para o driver
df <- collect(df)

# verificar correlação das variáveis
cor(df)

# Give the chart file a name.
png(file = "scatterplot.png")

# plotando o gráfico de dispersão com a variável ACTUAL_ELAPSED_TIME e DISTANCE
plot(x = df$ACTUAL_ELAPSED_TIME,
     y = df$DISTANCE,
     xlab = "ACTUAL_ELAPSED_TIME",
     ylab = "DISTANCE",
     main = "ACTUAL_ELAPSED_TIME vs DISTANCE"
)

# salvar a imagem
dev.off()

# inicializar o mlflow
mlflow_set_tracking_uri('http://mlflow:5000')

# criar o experimento
mlflow_set_experiment("/regressao-linear")

with(mlflow_start_run(), {
  
  mlflow_log_artifact("scatterplot.png", artifact_path = "graficos")

  # ultima data do dataframe
  mlflow_log_param("ultima data", ultima_data)
  
  # adicionar a fórmula utilizada como parâmetro no experimento
  mlflow_log_param("fórmula", "ACTUAL_ELAPSED_TIME ~ DISTANCE")
  
  # refazer o modelo dentro do encapsulamento do mlflow
  airline_lm <- lm(formula=ACTUAL_ELAPSED_TIME ~ DISTANCE, data=df)
  
  # sumário do modelo
  summary <- summary(airline_lm)
  
  # valores fitted do modelo
  fitted <- predict(airline_lm, df)
  
  # armazenar o r2 e r2 ajsutado
  r2 <- summary$r.squared
  r2_ajustado <- summary$adj.r.squared
  
  # printar mensagens no log do mlflow
  message("  r2: ", r2)
  message("  r2_ajustado: ", r2_ajustado)
  
  # logar as métricas do run atual do mlflow
  mlflow_log_metric("r2", r2)
  mlflow_log_metric("r2_ajustado", r2_ajustado)
  
  # criar uma função customizada que vai receber o modelo para fazer um futuro predict
  packaged_airline_lm <- carrier::crate(~ stats::predict.lm(object=!!airline_lm, .x), airline_lm)
  
  # fazer o log do modelo gerado pela função customizada no mlflow
  mlflow_log_model(packaged_airline_lm, "airline")

})

# listagem dos experimentos no mlflow
mlflow_list_experiments()

# listagem dos runs no mlflow
mlflow_list_run_infos()

# listar modelos registrados no mlflow
mlflow_list_registered_models()

# desconectar todas as conexões com o spark
spark_disconnect_all()
