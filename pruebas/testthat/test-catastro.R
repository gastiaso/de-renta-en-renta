# Vía (b): tablas de paso por viviendas del Catastro (R/fuente_catastro_inspire.R)

cuadro <- function(x0, y0, x1, y1) sf::st_polygon(list(rbind(c(x0, y0), c(x1, y0), c(x1, y1), c(x0, y1), c(x0, y0))))

test_that("los nombres del INE y del Catastro se casan", {
  expect_equal(normalizar_nombre_municipio("Rozas de Madrid, Las"), normalizar_nombre_municipio("LAS ROZAS DE MADRID"))
  expect_equal(normalizar_nombre_municipio("Morata de Tajuña"), normalizar_nombre_municipio("MORATA DE TAJUÑA"))
  expect_false(normalizar_nombre_municipio("Madrid") == normalizar_nombre_municipio("Las Rozas de Madrid"))
})

test_that("los municipios del INE se casan con los zips del Catastro aunque cambie el nombre", {
  ine <- tibble::tibble(
    municipio = c("15030", "03105", "36008", "15902", "28079", "17092", "08107"),
    nombre    = c("Coruña, A", "Pinós, el/Pinoso", "Cangas", "Oza-Cesuras", "Madrid", "Llançà", "Lliçà d'Amunt"))
  catastro <- tibble::tibble(
    provincia       = c("15", "03", "36", "15", "15", "28", "17", "17", "08"),
    nombre_catastro = c("A CORUÑA", "EL PINOS PINOSO", "CANGAS DE MORRAZO", "CESURAS", "OZA DOS RIOS",
                        "MADRID", "LLAN A", "LLANARS", "LLI A D AMUNT"),
    url = paste0("u", 1:9))
  r <- casar_municipios_catastro(ine, catastro)
  url_de <- function(m) sort(r$url[r$municipio == m])
  expect_equal(url_de("15030"), "u1")
  expect_equal(url_de("03105"), "u2")
  expect_equal(url_de("36008"), "u3")
  expect_equal(url_de("15902"), c("u4", "u5"))   # fusión: dos zips
  expect_equal(url_de("28079"), "u6")
  expect_equal(url_de("17092"), "u7")
  expect_equal(url_de("08107"), "u9")
  expect_false(anyNA(r$url))
})

test_that("los feeds del Catastro incluyen las gerencias propias y dejan fuera los forales", {
  f <- feeds_catastro(c("30", "51", "01"))
  expect_setequal(f$feed, c("30", "51", "55"))          # 51 del Catastro = Cartagena; 55 = Ceuta
  expect_equal(f$provincia[f$feed == "51"], "30")
  expect_equal(f$provincia[f$feed == "55"], "51")
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
  # C: cae entera y hay edificios (callejero, con el peso en viviendas); E: el callejero la deja
  # entera, pero el Catastro la lleva en parte a un municipio segregado de su grupo (Catastro)
  A <- "2800101001"; B <- "2800101002"; C <- "2800101003"; E <- "2800101005"
  D <- sprintf("28001010%02d", 11:15); S <- "2890101001"
  a <- tibble::tibble(origen = c(A, A, B, C, E), destino = D[c(1, 2, 3, 4, 5)],
                      portales = c(5L, 5L, 7L, 9L, 4L), metodo = "callejero", fraccion = c(0.5, 0.5, 1, 1, 1))
  b <- tibble::tibble(origen = c(A, A, C, E, E), destino = c(D[1], D[2], D[4], D[5], S),
                      portales = c(40, 60, 120, 30, 10), metodo = "catastro", fraccion = c(0.4, 0.6, 1, 0.75, 0.25))
  comb <- combinar_vias(b, a)
  expect_equal(comb$metodo[comb$origen == A], c("catastro", "catastro"))
  expect_equal(comb$fraccion[comb$origen == A & comb$destino == D[2]], 0.6)
  expect_equal(comb$metodo[comb$origen == B], "callejero")
  expect_equal(comb$portales[comb$origen == B], 7)
  expect_equal(comb$metodo[comb$origen == C], "callejero")
  expect_equal(comb$portales[comb$origen == C], 120)
  expect_equal(sort(comb$destino[comb$origen == E]), sort(c(D[5], S)))
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

test_that("los edificios de una sección fantasma del mapa pasan al origen de los datos que la cubre", {
  # Los datos han fusionado la 019 en la 027; el mapa aún dibuja la 019
  a <- tibble::tibble(origen = "2800505027", destino = c("2800505019", "2800505027"),
                      portales = c(10L, 12L), metodo = "callejero", fraccion = c(10, 12) / 22)
  b <- tibble::tibble(origen = c("2800505027", "2800505019"), destino = c("2800505027", "2800505019"),
                      portales = c(300, 100), fraccion = 1, metodo = "catastro")
  comb <- combinar_vias(b, a)
  expect_setequal(comb$destino, c("2800505019", "2800505027"))
  expect_equal(unique(comb$origen), "2800505027")
  expect_equal(comb$fraccion[comb$destino == "2800505019"], 0.25)
  expect_equal(unique(comb$metodo), "catastro")
})

test_that("si varios orígenes cubren el destino de un fantasma, siguen por el callejero", {
  a <- tibble::tibble(origen = c("A", "A", "B"), destino = c("D1", "D2", "D1"),
                      portales = c(5L, 5L, 8L), metodo = "callejero", fraccion = c(0.5, 0.5, 1))
  b <- tibble::tibble(origen = c("A", "A", "G"), destino = c("D1", "D2", "D1"),
                      portales = c(40, 60, 30), fraccion = c(0.4, 0.6, 1), metodo = "catastro")
  comb <- combinar_vias(b, a)
  expect_equal(unique(comb$metodo), "callejero")
  expect_false("G" %in% comb$origen)
})

test_that("el Catastro decide cuando la tabla combinada deja una sección de 2021 sin nada", {
  # O1: el callejero la da entera a D1; el Catastro reparte con D2, que nadie más alcanza
  O1 <- "2800101001"; O2 <- "2800101002"; D1 <- "2800101011"; D2 <- "2800101012"; D3 <- "2800101013"
  a <- tibble::tibble(origen = c(O1, O2, O2), destino = c(D1, D2, D3), portales = c(9L, 5L, 5L),
                      metodo = "callejero", fraccion = c(1, 0.5, 0.5))
  b <- tibble::tibble(origen = c(O1, O1, O2), destino = c(D1, D2, D3), portales = c(60, 40, 50),
                      metodo = "catastro", fraccion = c(0.6, 0.4, 1))
  comb <- combinar_vias(b, a)
  expect_true(D2 %in% comb$destino)
  expect_equal(unique(comb$metodo[comb$origen == O1]), "catastro")
})

test_that("las secciones con datos fuera del callejero van por el Catastro o por su código", {
  O1 <- "2800101001"; O3 <- "2800101003"; O4 <- "2800101004"
  a <- tibble::tibble(origen = O1, destino = O1, portales = 9L, metodo = "callejero", fraccion = 1)
  b <- tibble::tibble(origen = c(O1, O3), destino = c(O1, O1), portales = c(10, 5), metodo = "catastro", fraccion = 1)
  # O3 está en el mapa y en los datos, no en el callejero: Catastro (no es una fantasma)
  comb <- combinar_vias(b, a, datos = c(O1, O3, O4))
  expect_equal(comb$metodo[comb$origen == O3], "catastro")
  # O4 no tiene edificios ni callejero, pero su código existe en 2021
  t <- completar_por_codigo(comb, c(O1, O3, O4), c(O1, O4))
  expect_equal(t$destino[t$origen == O4], O4)
  expect_equal(t$metodo[t$origen == O4], "codigo")
  # Sin `datos`, O3 sería una fantasma y sus viviendas pasarían a O1
  expect_false(O3 %in% combinar_vias(b, a)$origen)
})

test_that("las huérfanas salen del cierre y las excepciones de cobertura no bloquean", {
  pob <- tibble::tibble(anio = 2015L, nivel = "seccion", codigo = c("2800101001", "2800101009"), valor = c(100, 40))
  h <- seccion_huerfanas(pob, c("2800101001"))
  expect_equal(h$codigo, "2800101009")
  tabla <- tibble::tibble(origen = "2800101001", destino = "2800101001", portales = 1L, fraccion = 1, metodo = "callejero")
  expect_true(all(abs(comprobar_cierre_poblacional(pob, tabla, 2015L, excluir = h$codigo)$calculado) < 1e-9))
  exc <- tibble::tibble(seccion = "2800101002", anios = "2015;2016", motivo = "x")
  c1 <- comprobar_cobertura_destino(tabla, c("2800101001", "2800101002"), 2015L, exc)
  expect_equal(c1$calculado[c1$id == "cobertura_destino"], 0)
  expect_equal(c1$detalle[c1$id == "cobertura_destino_excepcion"], "2800101002")
  c2 <- comprobar_cobertura_destino(tabla, c("2800101001", "2800101002"), 2017L, exc)
  expect_equal(c2$calculado[c2$id == "cobertura_destino"], 1)
})
