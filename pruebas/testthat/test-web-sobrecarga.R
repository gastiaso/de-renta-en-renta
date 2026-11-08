# Sección «Sobrecarga» de la web (R/web_sobrecarga.R), con datos y geometrías inventados

europa_sc <- function() {
  fila <- function(conjunto, geo, anio, valor, tenencia = "TOTAL", edad = "TOTAL") {
    tibble::tibble(conjunto = conjunto, geo = geo, tenencia = tenencia, edad = edad, anio = as.integer(anio),
                   valor = valor, bandera = NA_character_)
  }
  bind_rows(
    # Regiones: AA con NUTS 2 (y un código agrupado), BB solo el país, CC con NUTS 1, ES con comunidades
    fila("ilc_lvho07_r", c("AA", "AA1", "AA11", "AA12", "AA13_14", "BB", "CC", "CC1", "CC2", "ES", "ES3", "ES30", "ES61", "ES70"),
         2025, c(10, 10, 20.1, 4.2, 9, 6, 5, 7.3, 3.1, 7.2, 9.9, 9.9, 7, 11.9)),
    fila("ilc_lvho07_r", c("AA11", "AA12", "BB", "ES30", "ES61", "ES70"), 2024, c(19, 4, 6.5, 10.4, 7.6, 12.2)),
    # Países y referencias
    fila("ilc_lvho07a", c("AA", "BB", "CC", "ES", "EU27_2020", "EU"), 2025, c(10, 6, 5, 7.2, 7.6, 7.6)),
    fila("ilc_lvho07a", c("ES", "EU27_2020"), 2024, c(7.8, 8.2)),
    fila("ilc_lvho07a", c("ES", "EU27_2020"), 2023, c(8.2, 8.8)),
    fila("ilc_lvho07c", c("AA", "BB", "CC", "ES", "EU27_2020", "EA20"), 2025, c(30.16, 22, 18, 26.8, 21.4, 22), tenencia = "RENT_MKT"),
    fila("ilc_lvho07c", c("ES", "EU27_2020"), 2024, c(28.1, 22), tenencia = "RENT_MKT"),
    fila("ilc_lvho07a", c("AA", "BB", "ES", "EU27_2020"), 2025, c(12, 9, 8.6, 9.1), edad = "Y_LT18")
  )
}

anual_sc <- tibble::tibble(
  anio = 2025L, indicador = "sobrecarga", umbral = 0.4,
  corte = c("total", "tenencia", "edad", "region", "region", "region"),
  grupo = c("TOTAL", "RENT_MKT", "Y_LT18", "ES30", "ES61", "ES70"),
  valor = c(7.17, 26.84, 8.64, 9.93, 7.04, 11.86),
  n_personas = c(71161L, 8891L, 12271L, 7089L, 6000L, 15L), n_hogares = c(27000L, 3500L, 4000L, 2843L, 2400L, 9L)
)
agrupada_sc <- tibble::tibble(
  fiabilidad = c("normal", "baja", "no publicable"), anio_inicio = 2023L, anio_fin = 2025L, olas = 3L,
  indicador = "sobrecarga", umbral = 0.4, region = c("ES30", "ES61", "ES70"), corte = "tenencia", grupo = "RENT_MKT",
  valor = c(34.21, 20.15, 25), n_personas = c(900L, 30L, 12L), n_hogares = c(400L, 12L, 5L)
)
ccaa_sc <- tibble::tibble(codigo = c("13", "01", "05"), nombre_ine = c("Madrid, Comunidad de", "Andalucía", "Canarias"),
                          nuts2 = c("ES30", "ES61", "ES70"))
modulos_sc <- function() {
  pct <- paste(MEDIDA_BUSQUEDA, "(%)")
  list(
    ccaa = tibble::tibble(`Comunidad Autónoma` = c("Total", "Madrid, Comunidad de", "Andalucía", "Canarias", rep("Total", 4)),
                          medida = c(rep(pct, 4), names(RAZONES_MODULO)), valor = c(7.6, 10.2, 6.9, 8.9, 67.2, 6.6, 6.6, 19.6)),
    edad = tibble::tibble(Sexo = c("Ambos sexos", "Ambos sexos", "Hombres", "Mujeres"),
                          Edad = c("Total", "De 16 a 29 años", "Total", "Total"), medida = pct, valor = c(7.6, 9.6, 7.7, 7.5)),
    tenencia = tibble::tibble(`Régimen de tenencia de la vivienda principal` = c("Total", "Alquiler a precio de mercado"),
                              medida = pct, valor = c(7.6, 17.8))
  )
}

# Geometrías NUTS inventadas en la LAEA de Europa: cuadrados, con Canarias (ES70) como una isla
# fuera del marco, también dentro del país ES.
nuts_sc <- function() {
  caja <- function(x0, y0, x1, y1) sf::st_polygon(list(matrix(c(x0, y0, x1, y0, x1, y1, x0, y1, x0, y0), ncol = 2, byrow = TRUE)))
  isla <- caja(1700000, 1000000, 1900000, 1150000)
  geoms <- list(
    caja(4000000, 2800000, 4400000, 3200000), caja(4000000, 2800000, 4200000, 3200000),
    caja(4000000, 2800000, 4200000, 3200000), caja(4200000, 2800000, 4400000, 3200000),
    caja(4500000, 2800000, 4900000, 3200000),
    caja(5000000, 2800000, 5400000, 3200000), caja(5000000, 2800000, 5200000, 3200000), caja(5200000, 2800000, 5400000, 3200000),
    sf::st_multipolygon(list(caja(3000000, 1800000, 3600000, 2400000), isla)),
    caja(3000000, 2100000, 3600000, 2400000), caja(3000000, 2100000, 3600000, 2400000), caja(3000000, 1800000, 3600000, 2100000),
    isla
  )
  sf::st_sf(NUTS_ID = c("AA", "AA1", "AA11", "AA12", "BB", "CC", "CC1", "CC2", "ES", "ES3", "ES30", "ES61", "ES70"),
            LEVL_CODE = c(0, 1, 2, 2, 0, 0, 1, 1, 0, 1, 2, 2, 2),
            CNTR_CODE = c("AA", "AA", "AA", "AA", "BB", "CC", "CC", "CC", "ES", "ES", "ES", "ES", "ES"),
            NAME_LATN = c("País A", "A uno", "Región A11", "Región A12", "País B", "País C", "C uno", "C dos", "España",
                          "Centro", "Comunidad de Madrid", "Andalucía", "Canarias"),
            geometry = sf::st_sfc(geoms, crs = 3035))
}

test_that("toda la población: la escalera de Eurostat con las cifras y la muestra del INE en España", {
  v <- vista_total_sobrecarga(europa_sc(), anual_sc, 2025L)
  expect_setequal(v$geo, c("AA11", "AA12", "BB", "CC1", "CC2", "ES30", "ES61", "ES70", "ES", "EU27_2020"))
  expect_false("AA13_14" %in% v$geo)                                   # códigos agrupados fuera, como en armar_escalera()
  expect_equal(v$nivel[match(c("BB", "CC1", "ES30"), v$geo)], c(0L, 1L, 2L))
  es30 <- v[v$geo == "ES30", ]
  expect_equal(c(es30$valor, es30$n, es30$hogares), c(9.93, 7089, 2843))
  expect_equal(c(es30$fuente, es30$fiabilidad, es30$bloque), c("ine_ecv", "normal", "comunidad"))
  expect_true(is.na(es30$tabla))
  aa <- v[v$geo == "AA11", ]
  expect_equal(c(aa$fuente, aa$tabla, aa$puesto), c("eurostat_ilc_lvho07_r", "ilc_lvho07_r", "1"))
  expect_true(is.na(aa$n))
  expect_equal(v$fuente[v$geo == "EU27_2020"], "eurostat_ilc_lvho07")
  expect_equal(v$valor[v$geo == "ES"], 7.17)
  # Canarias, con 15 observaciones: sin valor publicable, aunque conserve el puesto de la escalera
  expect_true(is.na(v$valor[v$geo == "ES70"]))
  expect_equal(v$fiabilidad[v$geo == "ES70"], "no publicable")
  expect_equal(v$puesto, armar_escalera(europa_sc(), 2025L)$puesto[match(v$geo, armar_escalera(europa_sc(), 2025L)$geo)])
  # Un año sin microdatos: todo de Eurostat
  v24 <- vista_total_sobrecarga(europa_sc(), anual_sc, 2024L)
  expect_true(all(v24$fuente != "ine_ecv"))
})

test_that("desgloses: países de Eurostat, comunidades agrupadas y referencias, de más a menos", {
  v <- vista_desglose_sobrecarga(europa_sc(), agrupada_sc, anual_sc, "tenencia", "RENT_MKT", 2025L)
  expect_setequal(v$geo, c("AA", "BB", "CC", "EU27_2020", "ES", "ES30", "ES61", "ES70"))   # sin ES ni agregados como país
  expect_equal(v$geo[1:2], c("ES30", "AA"))
  expect_equal(v$puesto[!is.na(v$valor)], seq_len(sum(!is.na(v$valor))))
  expect_equal(v$fiabilidad[v$geo == "ES61"], "baja")
  expect_true(is.na(v$valor[v$geo == "ES70"]) && is.na(v$puesto[v$geo == "ES70"]))
  expect_equal(utils::tail(v$geo, 1), "ES70")                            # sin valor, al final
  expect_equal(v$n[v$geo == "ES"], 8891L)
  expect_equal(v$tabla[v$geo == "AA"], "ilc_lvho07c")
  e <- vista_desglose_sobrecarga(europa_sc(), agrupada_sc, anual_sc, "edad", "Y_LT18", 2025L)
  expect_setequal(e$geo, c("AA", "BB", "EU27_2020", "ES"))
})

test_that("las geometrías se recortan al marco, llevan Canarias al recuadro y salen en coordenadas del mapa", {
  ruta <- tempfile(fileext = ".gpkg")
  on.exit(unlink(ruta))
  sf::st_write(nuts_sc(), ruta, quiet = TRUE)
  g <- geometrias_sobrecarga_web(ruta, "CC1")
  expect_setequal(g$id[g$tipo == "region"], c("AA", "AA11", "AA12", "BB", "CC", "CC1", "ES", "ES30", "ES61", "ES70"))
  expect_equal(g$id[g$tipo == "recuadro"], "recuadro_ES70")
  expect_equal(sf::st_crs(g)$epsg, 4326L)
  lim <- limites_sobrecarga()
  caja <- sf::st_bbox(g)
  expect_true(caja[["xmin"]] >= lim[1] - 1e-3 && caja[["ymin"]] >= lim[2] - 1e-3 &&
                caja[["xmax"]] <= lim[3] + 1e-3 && caja[["ymax"]] <= lim[4] + 1e-3)
  # La isla, en la esquina izquierda del marco y dentro de su recuadro; también la parte del país
  canarias <- sf::st_bbox(g[g$id == "ES70", ])
  marco_rec <- sf::st_bbox(g[g$id == "recuadro_ES70", ])
  expect_true(canarias[["xmin"]] > marco_rec[["xmin"]] && canarias[["xmax"]] < marco_rec[["xmax"]])
  expect_lt(canarias[["xmin"]], lim[1] + 1)
  expect_equal(nrow(suppressWarnings(sf::st_cast(g[g$id == "ES", ], "POLYGON"))), 2L)
  expect_equal(unname(sf::st_coordinates(a_coordenadas_mapa(sf::st_sfc(sf::st_point(CENTRO_SOBRECARGA_3035), crs = 3035)))[1, ]),
               c(0, 0))
})

test_that("la exportación escribe sobrecarga.json y su geometría y pasa la compuerta de ida y vuelta", {
  dir <- tempfile("web_")
  ruta <- tempfile(fileext = ".gpkg")
  on.exit(unlink(c(dir, ruta), recursive = TRUE))
  sf::st_write(nuts_sc(), ruta, quiet = TRUE)
  europa <- filter(europa_sc(), anio >= 2024)
  rutas <- exportar_web_sobrecarga(anual_sc, agrupada_sc, europa, ccaa_sc, modulos_sc(), c("2024" = ruta), dir_web = dir,
                                   fecha = "2026-11-08")
  expect_equal(basename(rutas), c("sobrecarga.json", "nuts_2024.geojson"))
  x <- jsonlite::fromJSON(rutas[1], simplifyVector = FALSE)
  expect_equal(unlist(x$anios), c(2024L, 2025L))
  expect_equal(x$geometrias[["2024"]], "datos/sobrecarga/nuts_2024.geojson")
  expect_equal(vapply(x$vistas, `[[`, "", "clave")[1:3], c("total-2024", "total-2025", "tenencia-RENT_MKT-2025"))
  t25 <- x$vistas[[2]]$filas
  es30 <- t25[[which(vapply(t25, `[[`, "", "geo") == "ES30")]]
  expect_equal(es30[c("v", "n", "hogares", "fiabilidad", "fuente")],
               list(v = 99L, n = 7089L, hogares = 2843L, fiabilidad = "normal", fuente = "ine_ecv"))
  es70 <- t25[[which(vapply(t25, `[[`, "", "geo") == "ES70")]]
  expect_null(es70$v)                                                    # no publicable: null
  mkt <- x$vistas[[3]]$filas
  expect_equal(mkt[[which(vapply(mkt, `[[`, "", "geo") == "AA")]]$v, 302L) # 30,16 → 30,2 (× 10 en entero)
  expect_length(x$espana$serie$anios, 18L)                               # 2008–2025; sin dato, null
  expect_equal(unlist(x$espana$serie$valores$ES_TOTAL), c(78L, 72L))
  expect_equal(x$espana$anual[[1]][c("anio", "corte", "grupo", "v", "n")],
               list(anio = 2025L, corte = "total", grupo = "total", v = 72L, n = 71161L))
  expect_equal(x$modulo$total, 76L)
  expect_equal(x$modulo$ccaa[[1]], list(geo = "ES30", v = 102L))
  expect_equal(x$modulo$razones[[1]], list(grupo = "precio", v = 672L))
  expect_equal(x$nombres$AA11, "Región A11")
  expect_equal(x$comunidades$ES30$codigo, "13")

  escalera <- armar_escalera(europa)
  c1 <- comprobar_web_sobrecarga(anual_sc, agrupada_sc, europa, escalera, ccaa_sc, modulos_sc(), dir_web = dir)
  expect_setequal(unique(c1$id), c("web_sobrecarga_valores", "web_sobrecarga_muestra", "web_sobrecarga_geometria"))
  expect_equal(sum(c1$calculado), 0)

  # Una cifra cambiada, una muestra cambiada y una región sin geometría: la compuerta lo ve
  texto <- readLines(rutas[1], warn = FALSE, encoding = "UTF-8")
  texto <- sub('"geo":"AA11","nivel":2,"bloque":"europa","v":201', '"geo":"AA11","nivel":2,"bloque":"europa","v":202', texto, fixed = TRUE)
  texto <- sub('"n":7089', '"n":7090', texto, fixed = TRUE)
  writeLines(texto, rutas[1], useBytes = TRUE)
  c2 <- comprobar_web_sobrecarga(anual_sc, agrupada_sc, europa, escalera, ccaa_sc, modulos_sc(), dir_web = dir)
  mal <- c2[c2$calculado > 0, ]
  expect_equal(mal$id, c("web_sobrecarga_valores", "web_sobrecarga_muestra"))
  expect_equal(mal$detalle, c("total-2025", "total-2025"))

  g <- sf::st_read(rutas[2], quiet = TRUE)
  sf::st_write(g[g$id != "BB", ], rutas[2], driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
  c3 <- comprobar_web_sobrecarga(anual_sc, agrupada_sc, europa, escalera, ccaa_sc, modulos_sc(), dir_web = dir)
  expect_equal(c3$calculado[c3$id == "web_sobrecarga_geometria" & c3$detalle == "total-2025"], 1)
})

test_that("las comprobaciones nuevas tienen su fila en referencias_validacion.csv", {
  ref <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  filas <- ref[ref$id %in% c("web_sobrecarga_valores", "web_sobrecarga_muestra", "web_sobrecarga_geometria"), ]
  expect_equal(nrow(filas), 3L)
  expect_equal(filas$tipo[match(c("web_sobrecarga_valores", "web_sobrecarga_muestra", "web_sobrecarga_geometria"), filas$id)],
               c("bloqueo", "bloqueo", "alerta"))
})
