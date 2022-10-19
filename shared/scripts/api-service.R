install.packages("plumber")

p <- plumber::plumb("shared/scripts/api-rotas.R")
p$run(host = "0.0.0.0", port = 8000)
