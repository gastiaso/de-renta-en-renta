# Indicador 11 (plan §11, pregunta 45 revisada): precio de compraventa por m² de Registradores, por
# provincia (R/fuente_registradores.R), con un CSV inventado del mismo formato que el de sus datos
# abiertos (pruebas/datos/registradores_inventado.csv: España, Andalucía con Almería y Cádiz, y la
# Comunidad de Madrid, años 2024 y 2025; cifras inventadas, ninguna es de la fuente). El fichero real
# es manual y no está en el repositorio.

MUESTRA_REGISTRADORES <- file.path("..", "datos", "registradores_inventado.csv")
TERRITORIOS_REGISTRADORES <- tibble::tibble(
  codigo = c("01", "13", "04", "11", "28"),
  nivel = c("ccaa", "ccaa", "provincia", "provincia", "provincia"),
  superior = c("00", "00", "01", "01", "13")
)
REFERENCIA_INVENTADA <- tibble::tibble(anio = 2025L, geo_id = "00", referencia = 2000, detalle = "España inventada")

test_that("la lectura da una fila por territorio y trimestre, con códigos del INE y coma decimal", {
  x <- registradores_leer(MUESTRA_REGISTRADORES)
  expect_equal(nrow(x), 18)
  expect_setequal(unique(x$nivel), c("nacional", "ccaa", "provincia"))
  expect_setequal(unique(x$geo_id), c("00", "01", "13", "04", "11", "28"))
  expect_equal(x$precio_m2[x$anio == 2024 & x$geo_id == "01" & x$nivel == "ccaa"], 1366.67)
  expect_equal(x$precio_m2[x$anio == 2025 & x$trimestre == 4 & x$geo_id == "28"], 2250)   # entero, sin coma
  expect_equal(registradores_numero(c("1961,66", "2392", "", "1.234,5")), c(1961.66, 2392, NA, 1234.5))
})

test_that("el año es el cuarto trimestre, que acumula el año natural", {
  x <- registradores_leer(MUESTRA_REGISTRADORES)
  a <- registradores_anual(x)
  expect_equal(nrow(a), 12)
  expect_equal(a$precio_m2[a$anio == 2025 & a$geo_id == "00"], 2000)        # no el del tercer trimestre (1.950)
  expect_false("trimestre" %in% names(a))
  larga <- registradores_armonizar(x, version = "2099-01-01", anios = 2024:2025)
  expect_named(larga, COLUMNAS_TABLA_LARGA)
  expect_true(all(larga$indicador == "precio_compra_m2" & larga$fuente == "registradores" & larga$estado == "dato"))
  expect_setequal(unique(larga$nivel), c("nacional", "ccaa", "provincia"))
  expect_equal(nrow(registradores_armonizar(x, version = "2099-01-01", anios = 2025L)), 6)
})

test_that("la compuerta pasa con el fichero inventado y salta si una provincia no suma", {
  x <- registradores_leer(MUESTRA_REGISTRADORES)
  v <- registradores_comprobar(x, TERRITORIOS_REGISTRADORES, referencias = REFERENCIA_INVENTADA, desde = 2024L)
  expect_true(all(v$calculado[v$id %in% c("registradores_lectura", "registradores_suma", "registradores_rango")] == 0))
  expect_equal(v$calculado[v$id == "registradores_espana"], 2000)
  expect_true(all(abs(v$calculado[v$id == "registradores_agregado"]) < 0.5))
  # Sin territorios, solo España frente a todas las provincias
  w <- registradores_comprobar(x, NULL, referencias = REFERENCIA_INVENTADA, desde = 2024L)
  expect_true(all(w$calculado[w$id == "registradores_lectura"] > 0))   # faltan las provincias que no son de la muestra
  # Una provincia que no suma, una cifra fuera de rango y otra que falta
  y <- x
  y$compraventas[y$anio == 2025 & y$trimestre == 4 & y$geo_id == "04"] <- 601
  y$precio_m2[y$anio == 2025 & y$trimestre == 3 & y$geo_id == "11"] <- 12000
  y <- y[!(y$anio == 2024 & y$geo_id == "28"), ]
  v2 <- registradores_comprobar(y, TERRITORIOS_REGISTRADORES, referencias = REFERENCIA_INVENTADA, desde = 2024L)
  expect_equal(v2$calculado[v2$id == "registradores_suma" & v2$anio == 2025], 2)   # España y Andalucía
  expect_equal(v2$calculado[v2$id == "registradores_rango" & v2$anio == 2025], 1)
  expect_gt(v2$calculado[v2$id == "registradores_lectura" & v2$anio == 2024], 0)
})

test_that("la coherencia con el valor tasado compara €/m² con €/m², provincia frente a provincia", {
  x <- registradores_leer(MUESTRA_REGISTRADORES)
  tasado <- tibble::tibble(geo_id = c("00", "04", "11", "28", "00", "04", "11", "28"), nivel = rep(c("nacional", rep("provincia", 3)), 2),
                           anio = rep(c(2024L, 2025L), each = 4), indicador = "valor_tasado_m2", corte = "total",
                           valor = c(1700, 1300, 1400, 1900, 1900, 1300, 3000, 2100))
  v <- registradores_coherencia_tasado(x, tasado, anios = 2024:2025)
  expect_equal(v$calculado[v$id == "registradores_tasado_espana"], c(0, 0))
  # 2025: Cádiz, 1.650 / 3.000 = 0,55, fuera de 0,6–1,6 (una de tres provincias) y en el detalle
  expect_equal(v$calculado[v$id == "registradores_tasado_provincias" & v$anio == 2025], 100 / 3)
  expect_equal(v$calculado[v$id == "registradores_tasado_provincias" & v$anio == 2024], 0)
  expect_equal(sum(v$id == "registradores_tasado_detalle"), 1)
  expect_match(v$detalle[v$id == "registradores_tasado_detalle"], "provincia 11")
})

test_that("sin fichero, la descarga manual se detiene y dice dónde dejarlo; con varios, el más reciente", {
  dir <- tempfile("registradores_")
  dir.create(dir)
  expect_error(registradores_descargar(dir), "opendata.registradores.org")
  file.copy(MUESTRA_REGISTRADORES, file.path(dir, "RP_ComprvResid_2007-2t2026.csv"))
  file.copy(MUESTRA_REGISTRADORES, file.path(dir, "RP_ComprvResid_2007-4t2025.csv"))
  expect_equal(basename(registradores_descargar(dir)), "RP_ComprvResid_2007-2t2026.csv")
  unlink(dir, recursive = TRUE)
})

test_that("las comprobaciones de Registradores tienen su fila en el inventario", {
  ref <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  ids <- c("registradores_lectura", "registradores_espana", "registradores_suma", "registradores_agregado",
           "registradores_rango", "registradores_tasado_espana", "registradores_tasado_provincias",
           "registradores_tasado_detalle")
  expect_equal(setdiff(ids, ref$id), character(0))
})
