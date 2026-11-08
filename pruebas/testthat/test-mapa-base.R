# Jerarquía territorial y mapa base (R/geo_mapa_base.R), con datos inventados

provincias_prueba <- tibble::tibble(provincia = c("05", "28"), nombre = c("Avila", "Madrid"), ccaa = c("07", "13"))
ccaa_prueba <- tibble::tibble(codigo = c("07", "13"), nombre_ine = c("Castilla y Leon", "Madrid, Comunidad de"),
                              nuts2 = c("ES41", "ES30"))
nombres_prueba <- tibble::tibble(municipio = c("05001", "28001", "28002"), nombre = c("Uno", "Dos", "Tres"))
secciones_prueba <- tibble::tibble(
  seccion = c("2800101001", "2800101002", "2800102001", "2800201001", "0500101001")
) |> mutate(municipio = substr(seccion, 1, 5))

test_that("cada sección cuelga de un solo distrito, municipio, provincia y comunidad", {
  j <- geo_jerarquia(secciones_prueba, provincias_prueba)
  expect_equal(names(j), c("seccion", "distrito", "municipio", "provincia", "ccaa"))
  expect_equal(nrow(j), 5L)
  expect_equal(j$seccion, sort(secciones_prueba$seccion))
  expect_equal(j$ccaa[j$seccion == "0500101001"], "07")
  expect_equal(unique(j$ccaa[j$provincia == "28"]), "13")
  expect_equal(j$distrito[j$seccion == "2800102001"], "2800102")
})

test_that("los territorios cuentan sus secciones y las sumas cuadran", {
  j <- geo_jerarquia(secciones_prueba, provincias_prueba)
  t <- geo_territorios(j, nombres_prueba, provincias_prueba, ccaa_prueba)
  expect_equal(unique(t$nivel), c("ccaa", "provincia", "municipio", "distrito"))
  fila <- function(nivel, codigo) t[t$nivel == nivel & t$codigo == codigo, ]
  expect_equal(fila("ccaa", "13")$secciones, 4L)
  expect_equal(fila("provincia", "28")$superior, "13")
  expect_equal(fila("municipio", "28001")$secciones, 3L)
  expect_equal(fila("municipio", "28001")$nombre, "Dos")
  expect_equal(fila("distrito", "2800101")$secciones, 2L)
  expect_true(is.na(fila("distrito", "2800101")$nombre))
  expect_equal(sum(t$secciones[t$nivel == "ccaa"]), nrow(secciones_prueba))
  c <- comprobar_jerarquia(j, t, secciones_prueba$seccion)
  expect_setequal(unique(c$id), c("jerarquia_unica", "jerarquia_sumas", "jerarquia_nombres"))
  expect_true(all(c$calculado == 0))
})

test_that("la compuerta detecta provincias en dos comunidades, códigos que no encajan y huecos", {
  # Provincia en dos comunidades: la sección sale repetida
  mal <- bind_rows(provincias_prueba, tibble::tibble(provincia = "28", nombre = "Madrid", ccaa = "07"))
  j <- geo_jerarquia(secciones_prueba, mal)
  t <- geo_territorios(j, nombres_prueba, mal, ccaa_prueba)
  c <- comprobar_jerarquia(j, t, secciones_prueba$seccion)
  valor <- function(c, id, patron) c$calculado[c$id == id & grepl(patron, c$detalle)]
  expect_gt(valor(c, "jerarquia_unica", "repetida"), 0)
  expect_gt(valor(c, "jerarquia_unica", "provincia en mas"), 0)

  # El municipio de la tabla de atributos no es el del código
  s <- secciones_prueba
  s$municipio[1] <- "28009"
  j <- geo_jerarquia(s, provincias_prueba)
  c <- comprobar_jerarquia(j, geo_territorios(j, nombres_prueba, provincias_prueba, ccaa_prueba), s$seccion)
  expect_equal(valor(c, "jerarquia_unica", "no encajan"), 1)
  expect_equal(valor(c, "jerarquia_nombres", "municipio"), 1)        # 28009 no tiene nombre

  # Una sección del seccionado sin jerarquía y un territorio que no suma sus partes
  j <- geo_jerarquia(secciones_prueba[-5, ], provincias_prueba)
  t <- geo_territorios(j, nombres_prueba, provincias_prueba, ccaa_prueba)
  t$secciones[t$nivel == "municipio" & t$codigo == "28001"] <- 9L
  c <- comprobar_jerarquia(j, t, secciones_prueba$seccion)
  expect_equal(valor(c, "jerarquia_sumas", "sin jerarquia"), 1)
  expect_equal(valor(c, "jerarquia_sumas", "del total"), -1)
  expect_equal(valor(c, "jerarquia_sumas", "partes: municipio"), 1)  # 28001 dice 9 y sus distritos, 3
  expect_equal(valor(c, "jerarquia_sumas", "partes: provincia"), 1)  # y 28 (4) ya no suma 28001 + 28002
  expect_equal(valor(c, "jerarquia_sumas", "partes: ccaa"), 0)
})

test_that("los varint y el directorio del PMTiles se leen como dice la especificación (v3)", {
  expect_equal(pmtiles_varints(as.raw(c(0x01, 0xac, 0x02, 0x00))), c(1, 300, 0))
  expect_equal(pmtiles_zoom(c(0, 1, 4, 5, 20, 21, 84, 85)), c(0L, 1L, 1L, 2L, 2L, 3L, 3L, 4L))
  # Tres entradas: ids 0, 1, 2; la segunda va pegada a la primera (posición 0 = consecutiva);
  # la tercera se repite en dos teselas y empieza en el byte 500 (se guarda 501)
  directorio <- as.raw(c(3, 0, 1, 1, 1, 1, 2, 100, 50, 70, 1, 0, 0xf5, 0x03))
  d <- pmtiles_directorio(directorio)
  expect_equal(d$id, c(0, 1, 2))
  expect_equal(d$repeticiones, c(1, 1, 2))
  expect_equal(d$posicion, c(0, 100, 500))
  expect_equal(d$longitud, c(100, 50, 70))
})

test_that("las capas se disuelven por nivel y el PMTiles sale con sus zooms", {
  skip_if_not("PMTiles" %in% sf::st_drivers("vector")$name, "GDAL sin el controlador PMTiles")
  cuadrado <- function(x, y, lado = 500) {
    sf::st_polygon(list(rbind(c(x, y), c(x + lado, y), c(x + lado, y + lado), c(x, y + lado), c(x, y))))
  }
  s <- sf::st_sf(
    seccion = secciones_prueba$seccion,
    geometry = sf::st_sfc(cuadrado(440000, 4470000), cuadrado(440500, 4470000), cuadrado(441000, 4470000),
                          cuadrado(441500, 4470000), cuadrado(360000, 4500000), crs = 25830)
  )
  j <- geo_jerarquia(s, provincias_prueba)
  t <- geo_territorios(j, nombres_prueba, provincias_prueba, ccaa_prueba)
  capas <- geo_capas_mapa_base(s, j, t)
  expect_equal(names(capas), c("comunidades", "provincias", "municipios", "secciones"))
  expect_equal(vapply(capas, nrow, 1L), c(comunidades = 2L, provincias = 2L, municipios = 3L, secciones = 5L))
  m <- capas$municipios[capas$municipios$municipio == "28001", ]
  expect_equal(as.numeric(sf::st_area(m)), 3 * 500^2)
  expect_equal(m$nombre, "Dos")

  ruta <- tempfile(fileext = ".pmtiles")
  on.exit(unlink(ruta))
  zooms <- list(comunidades = c(0L, 6L), provincias = c(0L, 6L), municipios = c(2L, 8L), secciones = c(4L, 8L))
  generar_pmtiles(capas, ruta, zooms = zooms)
  cab <- pmtiles_cabecera(ruta)
  expect_equal(cab$version, 3L)
  expect_equal(c(cab$zoom_min, cab$zoom_max), c(0L, 8L))
  expect_equal(cab$tipo, 1L)                                          # MVT
  # Con cuadrados de 500 m, los zooms bajos quedan vacíos: un polígono de menos de una unidad
  # de la rejilla de la tesela desaparece al cuantificar
  r <- pmtiles_resumen(ruta)
  expect_true(all(r$zoom %in% 0:8))
  expect_equal(max(r$zoom), 8L)
  expect_equal(sum(r$teselas), cab$teselas)
})
