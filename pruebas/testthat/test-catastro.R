# Vía (b): tablas de paso por viviendas del Catastro (R/fuente_catastro_inspire.R)

cuadro <- function(x0, y0, x1, y1) sf::st_polygon(list(rbind(c(x0, y0), c(x1, y0), c(x1, y1), c(x0, y1), c(x0, y0))))

test_that("los nombres del INE y del Catastro se casan", {
  expect_equal(normalizar_nombre_municipio("Rozas de Madrid, Las"), normalizar_nombre_municipio("LAS ROZAS DE MADRID"))
  expect_equal(normalizar_nombre_municipio("Morata de Tajuña"), normalizar_nombre_municipio("MORATA DE TAJUÑA"))
  expect_false(normalizar_nombre_municipio("Madrid") == normalizar_nombre_municipio("Las Rozas de Madrid"))
})

test_that("la tabla por viviendas reparte cada sección de origen según dónde caen sus edificios", {
  crs <- 25830
  # Origen: una sección (A) que en el destino se parte en dos (D1 a la izquierda, D2 a la derecha)
  origen <- sf::st_sf(seccion = "2800101001", geometry = sf::st_sfc(cuadro(0, 0, 10, 10), crs = crs))
  destino <- sf::st_sf(seccion = c("2800101002", "2800101003"),
                       geometry = sf::st_sfc(cuadro(0, 0, 5, 10), cuadro(5, 0, 10, 10), crs = crs))
  edificios <- sf::st_sf(viviendas = c(30, 10, 60),
                         geometry = sf::st_sfc(sf::st_point(c(2, 2)), sf::st_point(c(3, 8)), sf::st_point(c(7, 5)), crs = crs))
  t <- geo_tabla_paso_catastro(edificios, origen, destino)
  expect_equal(t$fraccion[t$destino == "2800101002"], 0.4)
  expect_equal(t$fraccion[t$destino == "2800101003"], 0.6)
  expect_equal(unique(t$metodo), "catastro")
})

test_that("la combinación usa el Catastro solo donde el callejero reparte", {
  # A: el callejero la reparte (pasa al Catastro); B: cae entera y no hay edificios (callejero);
  # C: cae entera y hay edificios (callejero, con el peso en viviendas)
  a <- tibble::tibble(origen = c("A", "A", "B", "C"), destino = c("D1", "D2", "D3", "D4"),
                      portales = c(5L, 5L, 7L, 9L), metodo = "callejero", fraccion = c(0.5, 0.5, 1, 1))
  b <- tibble::tibble(origen = c("A", "A", "C"), destino = c("D1", "D2", "D4"),
                      portales = c(40, 60, 120), metodo = "catastro", fraccion = c(0.4, 0.6, 1))
  comb <- combinar_vias(b, a)
  expect_equal(comb$metodo[comb$origen == "A"], c("catastro", "catastro"))
  expect_equal(comb$fraccion[comb$origen == "A" & comb$destino == "D2"], 0.6)
  expect_equal(comb$metodo[comb$origen == "B"], "callejero")
  expect_equal(comb$portales[comb$origen == "B"], 7)
  expect_equal(comb$metodo[comb$origen == "C"], "callejero")
  expect_equal(comb$portales[comb$origen == "C"], 120)
})

test_that("la tabla por viviendas no cruza municipios", {
  crs <- 25830
  origen <- sf::st_sf(seccion = "2800101001", geometry = sf::st_sfc(cuadro(0, 0, 10, 10), crs = crs))
  # En el destino, el límite municipal se dibuja un poco más a la izquierda
  destino <- sf::st_sf(seccion = c("2800101001", "2800201001"),
                       geometry = sf::st_sfc(cuadro(0, 0, 9, 10), cuadro(9, 0, 20, 10), crs = crs))
  edificios <- sf::st_sf(viviendas = c(30, 5),
                         geometry = sf::st_sfc(sf::st_point(c(2, 2)), sf::st_point(c(9.5, 5)), crs = crs))
  t <- geo_tabla_paso_catastro(edificios, origen, destino)
  expect_equal(t$destino, "2800101001")
  expect_equal(t$fraccion, 1)
})

test_that("con año máximo solo cuentan los edificios ya construidos", {
  crs <- 25830
  origen <- sf::st_sf(seccion = "2800101001", geometry = sf::st_sfc(cuadro(0, 0, 10, 10), crs = crs))
  destino <- sf::st_sf(seccion = c("2800101002", "2800101003"),
                       geometry = sf::st_sfc(cuadro(0, 0, 5, 10), cuadro(5, 0, 10, 10), crs = crs))
  edificios <- sf::st_sf(viviendas = c(30, 70), anio_construccion = c(1990L, 2020L),
                         geometry = sf::st_sfc(sf::st_point(c(2, 2)), sf::st_point(c(7, 5)), crs = crs))
  t <- geo_tabla_paso_catastro(edificios, origen, destino, anio_max = 2015L)
  expect_equal(t$destino, "2800101002")
  expect_equal(t$fraccion, 1)
})
