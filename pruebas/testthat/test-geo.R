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

test_that("la tabla provincia a provincia da lo mismo que de una vez", {
  otra <- function(t) mutate(t, seccion = sub("^28", "08", seccion), municipio = substr(seccion, 1, 5))
  o2 <- bind_rows(origen, otra(origen))
  d2 <- bind_rows(destino, otra(destino))
  topes2 <- bind_rows(topes, mutate(topes, municipio = "08001"))
  a <- geo_tabla_paso_callejero(o2, d2, topes2) |> arrange(origen, destino)
  b <- geo_tabla_paso_callejero_por_provincia(o2, d2, topes2) |> arrange(origen, destino)
  expect_equal(as.data.frame(a), as.data.frame(b), ignore_attr = TRUE)
  expect_equal(nrow(b), 2 * nrow(geo_tabla_paso_callejero(origen, destino, topes)))
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
  expect_true(is.na(medianas$valor[medianas$seccion == "AB"]))       # A y B pesan lo mismo
  expect_equal(medianas$estado[medianas$seccion == "AB"], "ausente")
  expect_equal(medianas$valor[medianas$seccion == "C2"], 5)          # renumerada, misma sección
  expect_equal(medianas$estado[medianas$seccion == "C2"], "dato")
})

test_that("con un origen dominante (≥ 95 % de los portales) se copia su mediana como estimada", {
  tabla <- tibble::tibble(origen = c("A", "B", "B", "C", "D"), destino = c("X", "X", "Y", "Z", "Z"),
                          portales = c(99L, 1L, 49L, 80L, 20L), metodo = "callejero",
                          fraccion = c(1, 0.02, 0.98, 1, 1))
  m <- geo_reproyectar_mediana(tibble::tibble(seccion = c("A", "B", "C", "D"), valor = c(10, 20, 30, 40)), tabla)
  expect_equal(m$valor[m$seccion == "X"], 10)                        # A aporta el 99 %
  expect_equal(m$estado[m$seccion == "X"], "estimado")
  expect_equal(m$estado[m$seccion == "Y"], "estimado")               # único origen, repartido
  expect_equal(m$valor[m$seccion == "Y"], 20)
  expect_equal(m$estado[m$seccion == "Z"], "ausente")                # C aporta el 80 %: no domina
  expect_true(is.na(m$valor[m$seccion == "Z"]))
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

test_that("la cobertura de destino cuenta las secciones de referencia que no reciben nada", {
  tabla <- tibble::tibble(origen = c("O1", "O2"), destino = c("D1", "D2"), portales = 1, fraccion = 1)
  expect_equal(comprobar_cobertura_destino(tabla, c("D1", "D2"), 2021L)$calculado, 0L)
  r <- comprobar_cobertura_destino(tabla, c("D1", "D2", "D3"), 2021L)
  expect_equal(r$calculado, 1L)
  expect_equal(r$detalle, "D3")
})

test_that("la fase de códigos señala las secciones fantasma del mapa", {
  poblacion <- tibble::tibble(anio = 2021L, nivel = "seccion", codigo = c("A", "B"), valor = 1)
  f <- geo_fase_codigos(poblacion, 2021L, mapa = c("A", "B", "G"), callejero = c("A", "B", "B"))
  expect_equal(f$mapa, 3L)
  expect_equal(f$callejero, 2L)
  expect_equal(f$fantasmas, "G")
  expect_equal(f$adrh_sin_callejero, 0L)
  expect_equal(f$callejero_sin_mapa, "")
})

test_that("el zip interno del callejero se encuentra con y sin fecha en el nombre", {
  nombres <- c("TRAMOS-NAL.zip", "TRAMOS-NAL.F191231.zip", "TRAM-NAL.F201231.zip",
               "GJCALLE.TRAM-NAL.F201231.zip", "PSEU-NAL.zip", "UP-NAL.F191231.zip")
  casa <- function(formato) nombres[grepl(patron_zip_interno(FICHEROS_TRAMOS[[formato]]), nombres)]
  expect_equal(casa("antigua_2015"), c("TRAMOS-NAL.zip", "TRAMOS-NAL.F191231.zip"))
  expect_equal(casa("antigua_2021"), "TRAM-NAL.F201231.zip")
  expect_equal(casa("nueva_2021"), "GJCALLE.TRAM-NAL.F201231.zip")
})

test_that("el cierre mide la tabla y la suma de secciones mide la fuente", {
  # El ADRH publica un total municipal (102) que no es la suma de sus secciones (100)
  poblacion <- tibble::tibble(
    anio = 2016L, nivel = c("seccion", "seccion", "municipio"),
    codigo = c("2800101001", "2800101002", "28001"), valor = c(60, 40, 102))
  tabla <- tibble::tibble(origen = c("2800101001", "2800101001", "2800101002"),
                          destino = c("2800101001", "2800101003", "2800101002"),
                          portales = c(1, 1, 1), fraccion = c(0.5, 0.5, 1))
  expect_equal(comprobar_cierre_poblacional(poblacion, tabla, 2016L)$calculado, 0)
  s <- comprobar_suma_secciones(poblacion)
  expect_equal(s$id, "adrh_suma_secciones")
  expect_equal(round(s$calculado, 3), round(100 * (100 - 102) / 102, 3))
})

test_that("las segregaciones forman grupos de municipios y el cierre se mide por grupo", {
  cuadro <- function(x0, y0, x1, y1) sf::st_polygon(list(rbind(c(x0, y0), c(x1, y0), c(x1, y1), c(x0, y1), c(x0, y0))))
  a <- sf::st_sf(seccion = c("2800101001", "2800201001"), municipio = c("28001", "28002"),
                 geometry = sf::st_sfc(cuadro(0, 0, 10, 10), cuadro(10, 0, 20, 10), crs = 25830))
  b <- sf::st_sf(seccion = c("2800101001", "2890101001", "2800201001"), municipio = c("28001", "28901", "28002"),
                 geometry = sf::st_sfc(cuadro(0, 0, 5, 10), cuadro(5, 0, 10, 10), cuadro(10, 0, 20, 10), crs = 25830))
  g <- geo_grupos_municipio(a, b)
  expect_equal(g$municipio, c("28001", "28901"))
  expect_equal(unique(g$grupo), "28001")
  expect_equal(nrow(geo_grupos_municipio(a, a)), 0L)
  expect_equal(agrupar_municipio(c("28901", "28002"), g), c("28001", "28002"))
  # La sección de 28001 se reparte entre 28001 y 28901: sin grupos no cierra; con grupos, sí
  tabla <- tibble::tibble(origen = c("2800101001", "2800101001", "2800201001"),
                          destino = c("2800101001", "2890101001", "2800201001"),
                          portales = c(1L, 1L, 1L), fraccion = c(0.5, 0.5, 1), metodo = "catastro")
  pob <- tibble::tibble(anio = 2018L, nivel = "seccion", codigo = c("2800101001", "2800201001"), valor = c(100, 50))
  sin <- comprobar_cierre_poblacional(pob, tabla, 2018L)
  con <- comprobar_cierre_poblacional(pob, tabla, 2018L, g)
  expect_true(any(is.na(sin$calculado) | abs(sin$calculado) > 0.5))
  expect_true(all(abs(con$calculado) < 1e-9))
})
