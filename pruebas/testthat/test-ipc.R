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

# --- Euros constantes (decisión del autor, 12-nov-2026) ---------------------------------------------

test_that("ipc_deflactar(): euros del año base con la media anual de cada año; NA sin índice", {
  ipc <- tibble::tibble(anio = 2002:2005, indice = c(50, 60, 80, 100), variacion = NA_real_)
  expect_equal(ipc_anio_base(ipc), 2005L)
  expect_equal(ipc_deflactar(c(10, 10, 10, 10), 2002:2005, ipc), c(20, 100 / 6, 12.5, 10))
  # Antes del primer año del índice y el año en curso, sin media anual: NA
  expect_true(all(is.na(ipc_deflactar(c(10, 10), c(2001L, 2006L), ipc))))
  # Otro año base
  expect_equal(ipc_deflactar(30, 2005L, ipc, base = 2003L), 18)
})

test_that("la compuerta de los euros constantes: años, año base y variaciones de 2008 y 2009", {
  ipc <- tibble::tibble(anio = 2002:2025, indice = seq(60, 100, length.out = 24), variacion = NA_real_)
  ipc$indice[ipc$anio == 2007] <- 70.105
  ipc$indice[ipc$anio == 2008] <- 72.962
  ipc$indice[ipc$anio == 2009] <- 72.752
  c1 <- ipc_comprobar_deflactor(ipc)
  expect_equal(c1$id, c("ipc_deflactor_anios", "ipc_deflactor_base", "ipc_referencia_2008", "ipc_referencia_2009"))
  expect_equal(c1$calculado, c(0, 0, 4.1, -0.3))
  expect_equal(c1$anio[2], 2025L)
  # Un año sin media anual dentro de la serie
  hueco <- ipc
  hueco$indice[hueco$anio == 2010] <- NA
  expect_equal(ipc_comprobar_deflactor(hueco)$calculado[1], 1)
  # El año en curso, en la tabla sin media anual: el año base sigue siendo el último con ella
  en_curso <- dplyr::bind_rows(ipc, tibble::tibble(anio = 2026L, indice = NA_real_, variacion = NA_real_))
  expect_equal(ipc_anio_base(en_curso), 2025L)
  expect_equal(ipc_comprobar_deflactor(en_curso)$calculado[2], 1)
})

test_that("ipc_control.json: el valor tasado y el sueldo de España en euros del año base, ida y vuelta", {
  historico <- tibble::tibble(
    serie = c(rep("valor_tasado", 6), rep("sueldo_asalariado", 3), "valor_tasado"),
    geo_id = c(rep("00", 9), "13"),
    anio = c(2001L, 2002L, 2002L, 2003L, 2003L, 2004L, 2002L, 2003L, 2004L, 2003L),
    subperiodo = c(4L, 1L, 2L, 1L, 2L, 1L, 0L, 0L, 0L, 1L),
    valor = c(900, 1000.04, 1010, 1100, 1120, 1300, 20000, 21000, 22000, 5000)
  )
  ipc <- tibble::tibble(anio = 2002:2003, indice = c(80, 100), variacion = NA_real_)
  s <- ipc_control_deflactado(historico, ipc)
  expect_equal(names(s), c("valor_tasado", "sueldo_asalariado"))
  expect_equal(as.integer(unclass(s$valor_tasado$inicio)), c(2001L, 4L))
  # Sin índice en 2001 ni en 2004 (año en curso): null; 1000,0 × 100 / 80 = 1250,0
  expect_equal(unclass(s$valor_tasado$v), c(NA, 12500L, 12625L, 11000L, 11200L, NA))
  expect_equal(unclass(s$sueldo_asalariado$v), c(25000L, 21000L, NA))
  dir <- tempfile()
  ruta <- ipc_exportar_control(historico, ipc, dir_web = dir)
  x <- jsonlite::read_json(ruta)
  expect_equal(x$anio_base, 2003L)
  expect_true(all(ipc_comprobar_control(historico, ipc, ruta)$calculado == 0))
  otro <- historico
  otro$valor[2] <- 1001
  expect_gt(sum(ipc_comprobar_control(otro, ipc, ruta)$calculado), 0)
})

test_that("datos/ipc.json lleva el año base de los euros constantes", {
  ipc <- ipc_leer(csv_ipc_inventado())
  x <- jsonlite::read_json(ipc_exportar_web(ipc, dir_web = tempfile()), simplifyVector = TRUE)
  expect_equal(x$anio_base, 2016L)
})
