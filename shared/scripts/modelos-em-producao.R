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

airline_predict <- mlflow_load_model('models:/airline_tempo_distancia/staging')

# dataframe predict
df <- data.frame(DISTANCE = c(500))

# predict da modelagem em produção
resultado <- as.vector(airline_predict(df))

