# Coherencia del inventario (inventario/*.csv)
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

leer_inventario <- function(nombre) {
  ruta <- file.path("..", "..", "inventario", nombre)
  readr::read_csv(ruta, show_col_types = FALSE, col_types = readr::cols(.default = "c"))
}

separar <- function(x) unique(trimws(unlist(strsplit(stats::na.omit(x), ";"))))

test_that("los identificadores de fuentes e indicadores son únicos", {
  fuentes <- leer_inventario("fuentes.csv")
  indicadores <- leer_inventario("indicadores.csv")
  expect_false(anyDuplicated(fuentes$id) > 0)
  expect_false(anyDuplicated(indicadores$id) > 0)
  expect_false(anyDuplicated(indicadores$codigo) > 0)
})

test_that("cada indicador cita fuentes que existen en el inventario", {
  fuentes <- leer_inventario("fuentes.csv")
  indicadores <- leer_inventario("indicadores.csv")
  citadas <- separar(indicadores$fuentes)
  expect_equal(setdiff(citadas, fuentes$id), character(0))
})

test_that("el núcleo de la v0.1 tiene diez indicadores", {
  indicadores <- leer_inventario("indicadores.csv")
  expect_equal(sum(indicadores$nucleo_v01 == "TRUE"), 10L)
})

test_that("las referencias de validación apuntan a indicadores existentes", {
  indicadores <- leer_inventario("indicadores.csv")
  referencias <- leer_inventario("referencias_validacion.csv")
  citados <- setdiff(separar(referencias$indicador), "geo")
  expect_equal(setdiff(citados, indicadores$id), character(0))
  expect_true(all(referencias$tipo %in% c("bloqueo", "alerta")))
})
