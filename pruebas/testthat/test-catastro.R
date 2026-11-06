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
  origen <- sf::st_sf(seccion = "A", geometry = sf::st_sfc(cuadro(0, 0, 10, 10), crs = crs))
  destino <- sf::st_sf(seccion = c("D1", "D2"), geometry = sf::st_sfc(cuadro(0, 0, 5, 10), cuadro(5, 0, 10, 10), crs = crs))
  edificios <- sf::st_sf(viviendas = c(30, 10, 60),
                         geometry = sf::st_sfc(sf::st_point(c(2, 2)), sf::st_point(c(3, 8)), sf::st_point(c(7, 5)), crs = crs))
  t <- geo_tabla_paso_catastro(edificios, origen, destino)
  expect_equal(t$fraccion[t$destino == "D1"], 0.4)
  expect_equal(t$fraccion[t$destino == "D2"], 0.6)
  expect_equal(unique(t$metodo), "catastro")
  # Combinada con la vía (a): el origen sin edificios toma la del callejero
  a <- tibble::tibble(origen = c("A", "B"), destino = c("D1", "D3"), portales = 1L, metodo = "callejero", fraccion = 1)
  comb <- combinar_vias(t, a)
  expect_equal(sort(comb$origen), c("A", "A", "B"))
  expect_equal(comb$metodo[comb$origen == "B"], "callejero")
})
