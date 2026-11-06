# Tablas de paso por el callejero (R/comun_geo.R)

tramo <- function(seccion, via, pseudovia = "00000", tinum = 1L, ein = 0L, esn = 0L) {
  tibble::tibble(seccion = seccion, municipio = substr(seccion, 1, 5), via = via,
                 pseudovia = pseudovia, tinum = tinum, ein = ein, esn = esn)
}

origen <- bind_rows(
  tramo("2800101001", "00001", ein = 1L, esn = 19L),
  tramo("2800101001", "00001", tinum = 2L, ein = 2L, esn = 20L),
  tramo("2800101001", "00000", pseudovia = "00010", ein = 1L, esn = 5L),
  tramo("2800101001", "00002", tinum = 0L),
  tramo("2800101002", "00000", pseudovia = "00020", ein = 1L, esn = 5L),
  tramo("2800101003", "00003", ein = 1L, esn = 9999L),            # rango genérico (aplicación antigua)
  tramo("2800101004", "00009", ein = 1L, esn = 9L)                # vía que no existe en el destino
)
destino <- bind_rows(
  tramo("2800101001", "00001", ein = 1L, esn = 9L),
  tramo("2800101001", "00001", tinum = 2L, ein = 2L, esn = 10L),
  tramo("2800101001", "00002", tinum = 0L),
  tramo("2800101005", "00001", ein = 11L, esn = 19L),
  tramo("2800101005", "00001", tinum = 2L, ein = 12L, esn = 20L),
  tramo("2800101005", "00000", pseudovia = "00010", ein = 1L, esn = 5L),
  tramo("2800101002", "00000", pseudovia = "00020", ein = 1L, esn = 5L),
  tramo("2800101003", "00003", ein = 1L, esn = 49L),
  tramo("2800101006", "00003", ein = 51L, esn = 9999L),
  tramo("2800101004", "00008", ein = 1L, esn = 9L)
)
topes <- tibble::tibble(municipio = "28001", clave_via = "00003-00000", paridad = 1L, tope = 99L)

test_that("se cuentan los números de portal de cada lado", {
  expect_equal(contar_portales(1L, 9L, 1L), 5L)
  expect_equal(contar_portales(2L, 9L, 1L), 4L)
  expect_equal(contar_portales(2L, 8L, 0L), 4L)
  expect_equal(contar_portales(10L, 9L, 1L), 0L)
})

test_that("la tabla reparte por portales compartidos y no cruza pseudovías distintas", {
  t <- geo_tabla_paso_callejero(origen, destino, topes)
  f <- function(o, d) t$fraccion[t$origen == o & t$destino == d]
  # 2800101001: 5 + 5 + 1 (sin número) hacia 001; 5 + 5 + 3 (pseudovía) hacia 005
  expect_equal(f("2800101001", "2800101001"), 11 / 24)
  expect_equal(f("2800101001", "2800101005"), 13 / 24)
  expect_equal(f("2800101002", "2800101002"), 1)
  expect_equal(nrow(filter(t, origen == "2800101002")), 1L)
  # El 0001–9999 se recorta al último portal real (99): mitad y mitad
  expect_equal(f("2800101003", "2800101003"), 0.5)
  expect_equal(f("2800101003", "2800101006"), 0.5)
  # Sin tramos casados pero con el mismo código en el destino
  expect_equal(t$metodo[t$origen == "2800101004"], "codigo")
  expect_equal(attr(t, "sin_paso"), character(0))
  expect_true(all(abs(tapply(t$fraccion, t$origen, sum) - 1) < 1e-12))
})

test_that("el estado es dato solo si los orígenes caen enteros (medianas: un único origen)", {
  e <- geo_estado_paso(geo_tabla_paso_callejero(origen, destino, topes))
  est <- function(s, col) e[[col]][e$seccion == s]
  expect_equal(est("2800101002", "estado_recuento"), "dato")        # misma sección
  expect_equal(est("2800101002", "estado_mediana"), "dato")
  expect_equal(est("2800101004", "estado_recuento"), "dato")        # por código
  expect_equal(est("2800101001", "estado_recuento"), "estimado")    # recibe parte de una sección repartida
  expect_equal(est("2800101001", "estado_mediana"), "estimado")
  expect_equal(est("2800101006", "estado_media"), "estimado")
  # Dos secciones enteras que se juntan: recuento y media exactos; mediana, sin dato
  union <- tibble::tibble(origen = c("A", "B"), destino = "AB", portales = c(3L, 9L),
                          metodo = "callejero", fraccion = 1)
  eu <- geo_estado_paso(union)
  expect_equal(c(eu$estado_recuento, eu$estado_media, eu$estado_mediana), c("dato", "dato", "ausente"))
})

test_that("medias ponderadas y medianas se reproyectan según su estado", {
  union <- tibble::tibble(origen = c("A", "B", "C"), destino = c("AB", "AB", "C2"),
                          portales = 1L, metodo = "callejero", fraccion = 1)
  medias <- geo_reproyectar_media(tibble::tibble(seccion = c("A", "B", "C"), valor = c(10, 20, 5),
                                                 peso = c(1, 3, 2)), union)
  expect_equal(medias$valor[medias$seccion == "AB"], 17.5)
  expect_equal(medias$estado[medias$seccion == "AB"], "dato")
  medianas <- geo_reproyectar_mediana(tibble::tibble(seccion = c("A", "B", "C"), valor = c(10, 20, 5)), union)
  expect_true(is.na(medianas$valor[medianas$seccion == "AB"]))
  expect_equal(medianas$estado[medianas$seccion == "AB"], "ausente")
  expect_equal(medianas$valor[medianas$seccion == "C2"], 5)          # renumerada, misma sección
  expect_equal(medianas$estado[medianas$seccion == "C2"], "dato")
})

test_that("los recuentos se conservan al reproyectar", {
  t <- geo_tabla_paso_callejero(origen, destino, topes)
  valores <- tibble::tibble(seccion = c("2800101001", "2800101002", "2800101003", "2800101004"),
                            valor = c(240, 10, 100, 7))
  r <- geo_reproyectar_recuento(valores, t)
  expect_equal(sum(r$valor), 357)
  expect_equal(r$valor[r$seccion == "2800101005"], 130)
  cierre <- geo_cierre_poblacional(r, tibble::tibble(codigo = "28001", valor = 357))
  expect_equal(cierre$desviacion_pct, 0)
})
