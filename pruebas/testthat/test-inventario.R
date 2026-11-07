# Coherencia del inventario (inventario/*.csv)
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

leer_inventario <- function(nombre) {
  ruta <- file.path("..", "..", "inventario", nombre)
  readr::read_csv(ruta, show_col_types = FALSE, col_types = readr::cols(.default = "c"))
}

separar <- function(x) unique(trimws(unlist(strsplit(stats::na.omit(x), ";"))))

test_that("los CSV del inventario se leen sin filas descuadradas", {
  for (f in list.files(file.path("..", "..", "inventario"), pattern = "[.]csv$")) {
    expect_equal(nrow(readr::problems(leer_inventario(f))), 0L, info = f)
  }
})

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
  citados <- setdiff(separar(referencias$indicador), c("geo", "web"))
  expect_equal(setdiff(citados, indicadores$id), character(0))
  expect_true(all(referencias$tipo %in% c("bloqueo", "alerta")))
})

test_that("cada indicador tiene su ficha completa en castellano e inglés (tarea 8)", {
  indicadores <- leer_inventario("indicadores.csv")
  campos <- as.vector(outer(c("nombre", "unidad", "definicion", "calculo", "lectura"), c("es", "en"), paste, sep = "_"))
  vacios <- vapply(campos, function(cmp) sum(is.na(indicadores[[cmp]]) | !nzchar(trimws(indicadores[[cmp]]))), integer(1))
  expect_equal(sum(vacios), 0L, info = paste(names(vacios)[vacios > 0], collapse = ", "))
  expect_equal(nrow(indicadores), 23L)
})

test_that("fuentes y vocabulario tienen su texto en los dos idiomas", {
  fuentes <- leer_inventario("fuentes.csv")
  expect_false(any(is.na(fuentes$nombre_en) | !nzchar(fuentes$nombre_en)))
  voc <- leer_inventario("vocabulario.csv")
  expect_false(any(is.na(voc$es) | is.na(voc$en)))
  expect_false(anyDuplicated(voc[c("grupo", "clave")]) > 0)
  familias <- unique(substr(leer_inventario("indicadores.csv")$familia, 1, 1))
  expect_true(all(familias %in% voc$clave[voc$grupo == "familia"]))
})
