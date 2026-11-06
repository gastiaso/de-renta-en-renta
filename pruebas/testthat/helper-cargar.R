# Carga las funciones del proyecto antes de las pruebas (testthat ejecuta helper-*.R primero).

suppressPackageStartupMessages(library(dplyr))
for (fichero in list.files(file.path("..", "..", "R"), pattern = "\\.R$", full.names = TRUE)) {
  source(fichero, encoding = "UTF-8")
}
