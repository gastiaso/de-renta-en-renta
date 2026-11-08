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
  ) |>
    # Marcas de Eurostat: ruptura en España 2025 (total) y poca fiabilidad en AA12 (2025)
    mutate(bandera = case_when(conjunto == "ilc_lvho07a" & geo == "ES" & anio == 2025 & edad == "TOTAL" ~ "b",
                               conjunto == "ilc_lvho07_r" & geo == "AA12" & anio == 2025 ~ "u",
                               TRUE ~ NA_character_))
}

# Cortes del mapa como en inventario/indicadores.csv y sobrecarga por quintil de renta
ind_sc <- tibble::tibble(codigo = c("renta_hogar", "sobrecarga"), cortes_web = c("1;2", "4;6;8;10;15|RENT_MKT=15;20;25;30;40"))
quintil_sc <- tibble::tibble(anio = 2025L, indicador = "sobrecarga", umbral = 0.4, corte = "quintil",
                             grupo = c("QU1", "QU2", "QU3", "QU4", "QU5"), valor = c(27.8, 5.2, 1.89, 0.89, 0.21),
                             n_personas = c(12006L, 13299L, 14665L, 15345L, 15846L), n_hogares = c(5120L, 5477L, 5844L, 6130L, 6692L),
                             peso = 1, poblacion = 20, fiabilidad = "normal")

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
  rupturas <- list(ES_TOTAL = c(2013L, 2025L), ES_RENT_MKT = c(2013L, 2025L), EU27_TOTAL = integer(), EU27_RENT_MKT = integer())
  rutas <- exportar_web_sobrecarga(anual_sc, agrupada_sc, europa, ccaa_sc, modulos_sc(), c("2024" = ruta), ind_sc,
                                   quintil = quintil_sc, rupturas = rupturas, dir_web = dir, fecha = "2026-11-08")
  expect_equal(basename(rutas), c("sobrecarga.json", "nuts_2024.geojson"))
  x <- jsonlite::fromJSON(rutas[1], simplifyVector = FALSE)
  expect_equal(unlist(x$anios), c(2024L, 2025L))
  expect_equal(lapply(x$cortes, unlist), list(general = c(4L, 6L, 8L, 10L, 15L), RENT_MKT = c(15L, 20L, 25L, 30L, 40L)))
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
  # La serie empieza en el primer año publicado y lleva las marcas de Eurostat
  expect_equal(unlist(x$espana$serie$anios), c(2024L, 2025L))
  expect_equal(unlist(x$espana$serie$valores$ES_TOTAL), c(78L, 72L))
  expect_equal(x$espana$serie$marcas$ES_TOTAL, list(NULL, "b"))
  # Rupturas del atlas, solo las de dentro de la serie (2013 queda fuera); la UE-27, sin ninguna
  expect_equal(x$espana$serie$rupturas_atlas$ES_TOTAL, list(2025L))
  expect_equal(x$espana$serie$rupturas_atlas$EU27_TOTAL, list())
  aa12 <- t25[[which(vapply(t25, `[[`, "", "geo") == "AA12")]]
  expect_equal(aa12$bandera, "u")
  expect_equal(x$espana$anual[[1]][c("anio", "corte", "grupo", "v", "n")],
               list(anio = 2025L, corte = "total", grupo = "total", v = 72L, n = 71161L))
  q1 <- Filter(function(f) f$corte == "quintil" && f$grupo == "QU1", x$espana$anual)[[1]]
  expect_equal(q1[c("v", "n", "hogares", "fiabilidad")], list(v = 278L, n = 12006L, hogares = 5120L, fiabilidad = "normal"))
  expect_equal(x$modulo$total, 76L)
  expect_equal(x$modulo$ccaa[[1]], list(geo = "ES30", v = 102L))
  expect_equal(x$modulo$razones[[1]], list(grupo = "precio", v = 672L))
  expect_equal(x$nombres$AA11, "Región A11")
  expect_equal(x$comunidades$ES30$codigo, "13")

  escalera <- armar_escalera(europa)
  comprobar <- function(r = rupturas) comprobar_web_sobrecarga(anual_sc, agrupada_sc, europa, escalera, ccaa_sc, modulos_sc(),
                                                                ind_sc, quintil = quintil_sc, rupturas = r, dir_web = dir)
  c1 <- comprobar()
  expect_setequal(unique(c1$id), c("web_sobrecarga_valores", "web_sobrecarga_muestra", "web_sobrecarga_geometria"))
  expect_equal(sum(c1$calculado), 0)
  # Sin las rupturas del inventario, la de 2025 sobra en la página
  sin <- comprobar(NULL)
  expect_equal(sin$calculado[sin$detalle == "rupturas del atlas en la serie de Espa\u00f1a"], 2)

  # Una cifra cambiada, una muestra cambiada, una marca quitada y una región sin geometría: la compuerta lo ve
  texto <- readLines(rutas[1], warn = FALSE, encoding = "UTF-8")
  texto <- sub('"geo":"AA11","nivel":2,"bloque":"europa","v":201', '"geo":"AA11","nivel":2,"bloque":"europa","v":202', texto, fixed = TRUE)
  texto <- sub('"n":7089', '"n":7090', texto, fixed = TRUE)
  writeLines(texto, rutas[1], useBytes = TRUE)
  c2 <- comprobar()
  mal <- c2[c2$calculado > 0, ]
  expect_equal(mal$id, c("web_sobrecarga_valores", "web_sobrecarga_muestra"))
  expect_equal(mal$detalle, c("total-2025", "total-2025"))

  texto <- sub(',"bandera":"u"', "", readLines(rutas[1], warn = FALSE, encoding = "UTF-8"), fixed = TRUE)
  texto <- sub('"n":7090', '"n":7089', sub('"v":202', '"v":201', texto, fixed = TRUE), fixed = TRUE)
  texto <- sub('"cortes":{"general":[4,6,8,10,15]', '"cortes":{"general":[4,6,8,10,16]', texto, fixed = TRUE)
  writeLines(texto, rutas[1], useBytes = TRUE)
  c3 <- comprobar()
  expect_equal(c3$detalle[c3$calculado > 0], c("cortes del mapa", "total-2025"))
  expect_equal(c3$id[c3$calculado > 0], c("web_sobrecarga_valores", "web_sobrecarga_muestra"))

  g <- sf::st_read(rutas[2], quiet = TRUE)
  sf::st_write(g[g$id != "BB", ], rutas[2], driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
  c4 <- comprobar()
  expect_equal(c4$calculado[c4$id == "web_sobrecarga_geometria" & c4$detalle == "total-2025"], 1)
})

test_that("las rupturas del atlas en la serie salen de inventario/rupturas.csv (pregunta abierta 34)", {
  r <- tibble::tibble(id = c("a", "b", "c", "d"), fuente = c("ine_ecv", "ine_ecv", "ine_ecv", "ine_vut"),
                      indicador = c("22", "22", "21;22", "19"), anio = c("2013", "2020", "2008;2009", "2024"),
                      estado = c("aplicado", "por revisar", "aplicado", "aplicado"))
  s <- rupturas_serie_sobrecarga(r)
  expect_equal(names(s), names(SERIES_ESPANA_SOBRECARGA))
  expect_equal(s$ES_TOTAL, c(2008L, 2009L, 2013L))         # solo las aplicadas del 22 de la ECV
  expect_equal(s$ES_RENT_MKT, c(2008L, 2009L, 2013L))
  expect_equal(s$EU27_TOTAL, integer())
  expect_equal(rupturas_en_serie(s, 2010:2025)$ES_TOTAL, 2013L)
  expect_equal(rupturas_en_serie(NULL, 2010:2025)$ES_TOTAL, integer())
})

test_that("cortes del mapa: los generales y, tras «|», los de un grupo; como cortes_web()", {
  expect_equal(cortes_sobrecarga_web("4;6;8;10;15|RENT_MKT=15;20;25;30;40"),
               list(general = c(4, 6, 8, 10, 15), RENT_MKT = c(15, 20, 25, 30, 40)))
  expect_equal(cortes_sobrecarga_web("4;6"), list(general = c(4, 6)))
  expect_error(cortes_sobrecarga_web("4;6|15;20"), "GRUPO=")
  expect_error(cortes_sobrecarga_web("4;6|RENT_MKT=20;15"), "crecientes")
  expect_error(cortes_sobrecarga_web(NA), "vac")
  # La fila 22 del inventario se lee así
  ind <- readr::read_csv(file.path("..", "..", "inventario", "indicadores.csv"), show_col_types = FALSE)
  expect_named(cortes_de_indicadores(ind), c("general", "RENT_MKT"))
})

test_that("geometría de respaldo: lo que una versión NUTS no trae sale de una posterior", {
  codigos <- list("2021" = c("AA", "AA11"), "2024" = c("AA", "AA11", "BA", "BA0"))
  expect_equal(version_geometria(c("AA11", "BA0", "FI19_20", "AA"), c("2021", "2021", "2021", "2024"), codigos),
               c("2021", "2024", NA, "2024"))
  r21 <- tempfile(fileext = ".gpkg")
  r24 <- tempfile(fileext = ".gpkg")
  on.exit(unlink(c(r21, r24)))
  n <- nuts_sc()
  sf::st_write(n[n$NUTS_ID != "BB", ], r21, quiet = TRUE)
  sf::st_write(n, r24, quiet = TRUE)
  g <- geometrias_sobrecarga_web(r21, respaldo = c(BB = r24))
  expect_true("BB" %in% g$id)
  expect_equal(sum(g$id == "BB"), 1L)
  # La comprobación nuts_geometria acepta el respaldo y sigue marcando lo que no está en ninguna
  europa <- tibble::tibble(conjunto = "ilc_lvho07_r", geo = c("BB", "AA11", "FI19_20"), tenencia = "TOTAL", edad = "TOTAL",
                           anio = 2022L, valor = 5, bandera = NA_character_)
  ch <- comprobar_geometrias_nuts(europa, c("2021" = r21, "2024" = r24))
  expect_equal(c(ch$calculado, ch$detalle), c("1", "FI19_20"))
})

test_that("las comprobaciones nuevas tienen su fila en referencias_validacion.csv", {
  ref <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  ids <- c("web_sobrecarga_valores", "web_sobrecarga_muestra", "web_sobrecarga_geometria", "sobrecarga_quintil_total",
           "sobrecarga_quintil_reparto", "sobrecarga_quintil_eurostat")
  filas <- ref[ref$id %in% ids, ]
  expect_equal(nrow(filas), 6L)
  expect_equal(filas$tipo[match(ids, filas$id)], c("bloqueo", "bloqueo", "alerta", "bloqueo", "alerta", "bloqueo"))
  expect_equal(leer_tolerancia(filas$tolerancia[filas$id == "sobrecarga_quintil_eurostat"]), 0.1)
  expect_false(anyNA(leer_tolerancia(filas$tolerancia)))
})
