# import bibliotecas
library(reticulate)
library(sparklyr)

# instalar o ambiente do anaconda para o suporte ao MLFlow
install_miniconda()

# instalar um ambiente virtual chamado mlflow com as dependências Python necessárias
conda_install('mlflow', packages=c('mlflow','boto3'), forge = TRUE, pip = FALSE, pip_ignore_installed = TRUE)

# instalar a verão 3.3 do spark com o hadoop 3
spark_install("3.3", hadoop_version = "3")

