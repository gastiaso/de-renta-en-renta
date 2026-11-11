# Universo del SERPAVI (tarea 42 del backlog; R/serpavi_universo.R): contraste de las viviendas
# alquiladas del SERPAVI con los hogares en alquiler del Censo 2021, con datos inventados.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

larga_inventada <- function() {
  fila <- function(sc, grupo, valor, estado = "dato", anio = 2021L) {
    tibble::tibble(geo_id = sc, nivel = "sc", anio = anio, indicador = "contratos_alquiler", corte = "tipologia",
                   grupo = grupo, valor = valor, estado = estado)
  }
  dplyr::bind_rows(
    # municipio 28001: dos secciones completas
    fila("2800101001", "VC", 60), fila("2800101001", "VU", 20),
    fila("2800101002", "VC", 30), fila("2800101002", "VU", 0),
    # municipio 28002: una sección con la unifamiliar vacía en el SERPAVI
    fila("2800201001", "VC", 50), fila("2800201001", "VU", NA, "ausente"),
    # municipio 08001: completa
    fila("0800101001", "VC", 150), fila("0800101001", "VU", 10),
    # País Vasco: sin SERPAVI en 2021
    fila("4800101001", "VC", NA, "ausente"), fila("4800101001", "VU", NA, "ausente"),
    # otro año, que no entra
    fila("2800101001", "VC", 999, anio = 2020L)
  )
}

censo_inventado <- function() {
  tibble::tibble(seccion = c("2800101001", "2800101002", "2800201001", "0800101001", "4800101001"),
                 alquiler = c(100, 50, 40, 140, 70))
}

test_that("el contraste suma las dos tipologías y solo las secciones con las dos cifras", {
  x <- serpavi_contraste_censo(larga_inventada(), censo_inventado(), minimo = 0)
  expect_equal(x$espana$secciones, 3L)
  expect_equal(x$espana$contratos, 80 + 30 + 160)
  expect_equal(x$espana$hogares, 100 + 50 + 140)
  expect_equal(x$espana$cobertura, 100 * 270 / 290)
  expect_equal(x$provincias$provincia, c("28", "08"))   # de menor a mayor cobertura
  expect_equal(x$provincias$cobertura, c(100 * 110 / 150, 100 * 160 / 140))
})

test_that("los municipios entran solo con todas sus secciones completas y el mínimo de hogares", {
  x <- serpavi_contraste_censo(larga_inventada(), censo_inventado(), minimo = 0)
  expect_equal(sort(x$municipios$municipio), c("08001", "28001"))   # ni 28002 ni el del País Vasco
  expect_equal(x$resumen_municipios$n, 2L)
  expect_equal(x$resumen_municipios$sobre_100, 1L)
  y <- serpavi_contraste_censo(larga_inventada(), censo_inventado(), minimo = 145)
  expect_equal(y$municipios$municipio, "28001")
})

test_that("una sección del Censo en secreto queda fuera", {
  censo <- censo_inventado()
  censo$alquiler[censo$seccion == "2800101002"] <- NA
  x <- serpavi_contraste_censo(larga_inventada(), censo, minimo = 0)
  expect_equal(x$espana$secciones, 2L)
  expect_false("28001" %in% x$municipios$municipio)
})
