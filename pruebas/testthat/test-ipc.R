# IPC del INE (tarea 45 del backlog; R/fuente_ine_ipc.R): lectura del CSV de jaxiT3 de la tabla 76144,
# compuerta y datos/ipc.json, con un fichero inventado en el formato del INE.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

csv_ipc_inventado <- function(anios = 2013:2016, indices = c(90, 91.5, 93, 100), variaciones = NULL, quitar = NULL) {
  if (is.null(variaciones)) variaciones <- c(NA, round(100 * (indices[-1] / indices[-length(indices)] - 1), 1))
  coma <- function(x) ifelse(is.na(x), "", gsub(".", ",", format(x, trim = TRUE, nsmall = 0), fixed = TRUE))
  filas <- c(
    "\ufeffGrupos ECOICOP ver.2;Tipo de dato;Periodo;Total",
    sprintf("\u00cdndice general;Media anual;%d;%s", rev(anios), coma(rev(indices))),
    sprintf("\u00cdndice general;Variaci\u00f3n de las medias anuales;%d;%s", rev(anios), coma(rev(variaciones))),
    sprintf("01 Alimentos y bebidas no alcoh\u00f3licas;Media anual;%d;%s", rev(anios), coma(rev(indices) + 1))
  )
  if (!is.null(quitar)) filas <- filas[!grepl(sprintf(";Media anual;%d;", quitar), filas) | !grepl("^\u00cdndice", filas)]
  ruta <- tempfile(fileext = ".csv")
  con <- file(ruta, open = "wb")
  writeLines(enc2utf8(filas), con, useBytes = TRUE)
  close(con)
  ruta
}

test_that("ipc_leer() toma el índice general, con su media anual y su variación", {
  ipc <- ipc_leer(csv_ipc_inventado())
  expect_equal(ipc$anio, 2013:2016)
  expect_equal(ipc$indice, c(90, 91.5, 93, 100))
  expect_equal(ipc$variacion, c(NA, 1.7, 1.6, 7.5))
})

test_that("ipc_leer() se detiene con una serie cortada", {
  expect_error(ipc_leer(csv_ipc_inventado(quitar = 2014)), "serie cortada")
})

test_that("la compuerta del IPC: variación recalculada, años y referencia de 2022", {
  ipc <- ipc_leer(csv_ipc_inventado(anios = 2013:2024, indices = seq(80, 102, by = 2)))
  c1 <- ipc_comprobar(ipc)
  expect_equal(c1$id, c("ipc_variacion", "ipc_serie", "ipc_referencia"))
  expect_lt(c1$calculado[1], 0.06)
  expect_equal(c1$calculado[2], 0)
  # Una variación publicada que no casa con los índices
  mal <- ipc
  mal$variacion[5] <- mal$variacion[5] + 0.5
  expect_gt(ipc_comprobar(mal)$calculado[1], 0.4)
  # Sin 2015
  expect_equal(ipc_comprobar(ipc[ipc$anio != 2015, ])$calculado[2], 1)
})

test_that("datos/ipc.json: índices y año base, ida y vuelta", {
  ipc <- ipc_leer(csv_ipc_inventado())
  dir <- tempfile()
  ruta <- ipc_exportar_web(ipc, dir_web = dir)
  x <- jsonlite::read_json(ruta, simplifyVector = TRUE)
  expect_equal(x$anios, 2013:2016)
  expect_equal(x$indice, c(90, 91.5, 93, 100))
  expect_equal(x$base, 2016)
  expect_true(all(ipc_comprobar_web(ipc, ruta)$calculado == 0))
  otro <- ipc
  otro$indice[2] <- 91.6
  expect_gt(sum(ipc_comprobar_web(otro, ruta)$calculado), 0)
})
