library(sparklyr)
library(dplyr)
library(ggplot2)
library(carrier)
library(mlflow)
library(dplyr)
library(reticulate)
library(stats)

use_condaenv('mlflow')

# alterar caminho da variável de ambiente do mlflow no python
Sys.setenv(MLFLOW_BIN="/home/rstudio/.local/share/r-miniconda/envs/mlflow/bin/mlflow")

# alterar caminho da variável de ambiente do python
Sys.setenv(MLFLOW_PYTHON_BIN="/home/rstudio/.local/share/r-miniconda/envs/mlflow/bin/python")

# inicializar o mlflow
mlflow_set_tracking_uri('http://mlflow:5000')

# coletar modelo para fazer predict
airline_predict <- mlflow_load_model('models:/airline_tempo_distancia/production')

#* @post /predict
#* @param DISTANCE:int 
predict <- function(DISTANCE) {
  
  dataframe <- data.frame(DISTANCE = as.numeric(c(DISTANCE)))
  
  fitted <-  as.vector(airline_predict(dataframe))
  
  paste("A média da sua viagem é de: ",sub("\"","",round(fitted[1], digits = 0))," minutos.")
  
}
