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
  expect_false(anyDuplicated(stats::na.omit(indicadores$id)) > 0)
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
  citados <- setdiff(separar(referencias$indicador), c("geo", "web", "historico", "calendario"))   # F6, histórico (también el CIS) y calendario: sin indicador
  expect_equal(setdiff(citados, indicadores$id), character(0))
  expect_true(all(referencias$tipo %in% c("bloqueo", "alerta")))
})

test_that("cada indicador tiene su ficha completa en castellano e inglés (tarea 8)", {
  indicadores <- leer_inventario("indicadores.csv")
  campos <- as.vector(outer(c("nombre", "unidad", "definicion", "calculo", "lectura"), c("es", "en"), paste, sep = "_"))
  vacios <- vapply(campos, function(cmp) sum(is.na(indicadores[[cmp]]) | !nzchar(trimws(indicadores[[cmp]]))), integer(1))
  expect_equal(sum(vacios), 0L, info = paste(names(vacios)[vacios > 0], collapse = ", "))
  auxiliar <- !is.na(indicadores$auxiliar_de)
  expect_equal(sum(!auxiliar), 23L)
})

test_that("los indicadores auxiliares van sin número, fuera del núcleo y acompañan a indicadores que existen", {
  indicadores <- leer_inventario("indicadores.csv")
  aux <- indicadores[!is.na(indicadores$auxiliar_de), ]
  expect_setequal(aux$codigo, c("contratos_alquiler", "margen_alquiler_mes", "margen_alquiler_m2"))
  expect_true(all(is.na(aux$id)))
  expect_true(all(!is.na(indicadores$id[is.na(indicadores$auxiliar_de)])))
  expect_true(all(aux$nucleo_v01 == "FALSE"))
  expect_true(all(is.na(aux$cortes_web)))                     # sin mapa propio: van a la ficha y al CSV
  acompanados <- separar(aux$auxiliar_de)
  expect_equal(setdiff(acompanados, indicadores$codigo[is.na(indicadores$auxiliar_de)]), character(0))
  expect_true(all(sub("_.*$", "", aux$codigo) %in% c("contratos", "margen")))   # su papel en la web
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
