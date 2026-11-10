# Indicador 13 (F5): capa desmontable de los precios de oferta de los portales (R/fuente_portales.R) y
# mapas de la web sin sección (indicador 20) o por grupo (indicador 13), con datos inventados
# (pruebas/datos/portales_inventado.csv; nunca en datos/brutos/).

MUESTRA_PORTALES <- file.path("..", "datos", "portales_inventado.csv")

jer_p <- tibble::tibble(seccion = c("2800101001", "2800101002", "2800201001"),
                        distrito = c("2800101", "2800101", "2800201"), municipio = c("28001", "28001", "28002"),
                        provincia = "28", ccaa = "13")
ter_p <- geo_territorios(jer_p, tibble::tibble(municipio = c("28001", "28002"), nombre = c("Uno", "Dos")),
                         tibble::tibble(provincia = "28", nombre = "Madrid", ccaa = "13"),
                         tibble::tibble(codigo = "13", nombre_ine = "Madrid, Comunidad de", nuts2 = "ES30"))
voc_p <- readr::read_csv(file.path("..", "..", "inventario", "vocabulario.csv"), show_col_types = FALSE)
ind_p <- tibble::tibble(
  id = c(1, 13, 20, 21),
  codigo = c("renta_persona", "precio_oferta", "zona_tensionada", "sueldo_necesario"),
  unidad_es = c("€ por persona y año", "€ por m² (alquiler: por m² y mes)", "categoría", "€ netos por mes"),
  nucleo_v01 = c(TRUE, FALSE, FALSE, TRUE),
  cortes_web = c("10;20;30;40", "8;10;12;15;20|venta_fotocasa=1000;1500;2000;3000;4000", "0.5;1.5", "700;900;1100;1500;2000"),
  escala_web = NA
)
fila_p <- function(geo_id, nivel, anio, indicador, valor, corte = "total", grupo = "total", fuente = "prueba") {
  tibble::tibble(geo_id = geo_id, nivel = nivel, anio = as.integer(anio), indicador = indicador, corte = corte, grupo = grupo,
                 valor = valor, estado = "dato", fuente = fuente, geo_ref = "2021", version = "2026-11-10")
}
larga_base_p <- dplyr::bind_rows(
  fila_p(c("2800101001", "2800101002", "2800201001"), "sc", 2024, "renta_persona", c(11, 12, 13)),
  fila_p(c("28001", "28002"), "municipio", 2024, "renta_persona", c(11.5, 13))
)

test_that("el interruptor está apagado salvo con PORTALES=TRUE", {
  expect_false(portales_activos("FALSE"))
  expect_false(portales_activos(""))
  expect_false(portales_activos("1"))
  expect_true(portales_activos("TRUE"))
  expect_true(portales_activos(" true "))
})

test_that("encendida sin ficheros, se detiene y dice qué dejar y dónde", {
  vacio <- tempfile("portales_")
  dir.create(vacio)
  on.exit(unlink(vacio, recursive = TRUE))
  expect_error(buscar_ficheros_portales(vacio), "no hay ficheros")
  expect_error(buscar_ficheros_portales(vacio), "nunca anuncios")
})

test_that("la muestra inventada se lee, pasa la compuerta y da una cifra por año", {
  p <- leer_portales(MUESTRA_PORTALES)
  expect_equal(nrow(p), 8L)
  x <- comprobar_portales(p, ter_p)
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))
  larga <- armonizar_portales(p, version = "2026-11-10")
  validar_tabla_larga(larga, vocabulario = voc_p)
  v <- function(cod, anio, grupo) larga$valor[larga$geo_id == cod & larga$anio == anio & larga$grupo == grupo]
  expect_equal(v("28001", 2024, "alquiler_idealista"), 12.2)     # el último mes del año
  expect_equal(v("28001", 2025, "alquiler_idealista"), 13.3)     # el informe anual manda
  expect_equal(v("2800101", 2025, "alquiler_idealista"), 15.5)
  expect_equal(v("28002", 2025, "venta_fotocasa"), 1111.1)
  expect_true(all(larga$corte == "oferta_privada" & larga$fuente == "portales" & larga$indicador == "precio_oferta"))
  expect_true("oferta_privada" %in% voc_p$clave[voc_p$grupo == "corte"])
  expect_equal(voc_p$es[voc_p$grupo == "etiqueta" & voc_p$clave == "portales"], "Dato privado de oferta")
})

test_that("la compuerta de la capa para con códigos, periodos, precios y cifras repetidas", {
  p <- leer_portales(MUESTRA_PORTALES)
  suma <- function(q, id) { x <- comprobar_portales(q, ter_p); sum(x$calculado[x$id == id]) }
  q <- p; q$geo_id[1] <- "28999"
  expect_gt(suma(q, "portales_codigos"), 0)
  q <- p; q$periodo[1] <- "2024-13"
  expect_gt(suma(q, "portales_formato"), 0)
  q <- p; q$valor[7] <- 2.2                                      # venta a 2,2 € el m²: un error de copia
  expect_gt(suma(q, "portales_rango"), 0)
  q <- p; q$url[2] <- ""
  expect_gt(suma(q, "portales_formato"), 0)
  q <- rbind(p, p[1, ])
  expect_gt(suma(q, "portales_repetidas"), 0)
})

# Firma de todos los ficheros de una exportación (ruta relativa y contenido)
firma_web <- function(dir) {
  f <- sort(list.files(dir, recursive = TRUE))
  stats::setNames(vapply(file.path(dir, f), function(r) paste(readLines(r, warn = FALSE), collapse = "\n"), ""), f)
}

test_that("apagada, la web queda exactamente como sin capa; encendida, la capa sale aparte y etiquetada", {
  sin <- tempfile("web_sin_"); apagada <- tempfile("web_apagada_"); con <- tempfile("web_con_")
  on.exit(unlink(c(sin, apagada, con), recursive = TRUE))
  exportar_web(larga_base_p, ind_p, jer_p, ter_p, dir_web = sin, fecha = "2026-11-10", vocabulario = voc_p)
  exportar_web(dplyr::bind_rows(larga_base_p, NULL), ind_p, jer_p, ter_p, dir_web = apagada, fecha = "2026-11-10",
               vocabulario = voc_p)          # PORTALES=FALSE: larga_portales es NULL
  expect_identical(firma_web(apagada), firma_web(sin))
  m_sin <- jsonlite::fromJSON(file.path(sin, "datos", "manifiesto.json"), simplifyVector = FALSE)
  expect_false(any(grepl("precio_oferta", names(m_sin$indicadores))))
  expect_false(any(grepl("precio_oferta", names(m_sin$mapas))))

  capa <- armonizar_portales(leer_portales(MUESTRA_PORTALES), version = "2026-11-10")
  exportar_web(dplyr::bind_rows(larga_base_p, capa), ind_p, jer_p, ter_p, dir_web = con, fecha = "2026-11-10",
               vocabulario = voc_p)
  m <- jsonlite::fromJSON(file.path(con, "datos", "manifiesto.json"), simplifyVector = FALSE)
  expect_setequal(grep("precio_oferta", names(m$mapas), value = TRUE),
                  c("precio_oferta_alquiler_idealista", "precio_oferta_venta_fotocasa"))
  a <- m$mapas$precio_oferta_alquiler_idealista
  expect_equal(c(a$base, a$indicador, a$corte, a$grupo, a$nivel_minimo),
               c("precio_oferta_alquiler_idealista", "precio_oferta", "oferta_privada", "alquiler_idealista", "municipio"))
  expect_equal(unlist(a$cortes), c(8, 10, 12, 15, 20))
  expect_equal(unlist(m$mapas$precio_oferta_venta_fotocasa$cortes), c(1000, 1500, 2000, 3000, 4000))
  s <- m$indicadores$precio_oferta_alquiler_idealista
  expect_equal(s$fuente, "portales")                            # la web pone la etiqueta por la fuente
  expect_null(s$por_defecto)                                    # sin serie por defecto
  expect_equal(unlist(s$niveles), c("distrito", "municipio"))
  expect_equal(readLines(file.path(con, "datos", "municipio", "precio_oferta_alquiler_idealista", "2024.json")),
               '{"v":[122,95],"e":"00"}')
  # lo demás, igual que sin capa
  f_sin <- firma_web(sin)
  f_con <- firma_web(con)
  comunes <- setdiff(names(f_sin), c("datos/manifiesto.json", grep("^datos/fichas/", names(f_sin), value = TRUE)))
  expect_identical(f_con[comunes], f_sin[comunes])
  expect_equal(m[setdiff(names(m), c("indicadores", "mapas"))], m_sin[setdiff(names(m_sin), c("indicadores", "mapas"))])
  expect_equal(m$mapas[names(m_sin$mapas)], m_sin$mapas)
  expect_equal(m$indicadores[names(m_sin$indicadores)], m_sin$indicadores)
})

test_that("un indicador solo municipal tiene mapa con nivel_minimo y, con vocabulario, categorías y declaraciones", {
  dir <- tempfile("web_zt_")
  on.exit(unlink(dir, recursive = TRUE))
  zt <- fila_p(c("28001", "28002"), "municipio", 2025, "zona_tensionada", c(2, 0), fuente = "zonas_tensionadas")
  zonas <- tibble::tibble(boe = "BOE-A-2099-1", fecha_publicacion = as.Date("2025-03-15"), ccaa = "13", municipio = "28001",
                          nombre_ine = "Uno", nombre_boe = "Uno", ambito = "municipio", ambito_texto = "",
                          fecha_inicio = as.Date("2025-03-16"), fecha_fin = as.Date("2028-03-15"), declaracion = "Orden de prueba",
                          url = "https://www.boe.es/diario_boe/txt.php?id=BOE-A-2099-1", url_declaracion = "")
  exportar_web(dplyr::bind_rows(larga_base_p, zt), ind_p, jer_p, ter_p, dir_web = dir, fecha = "2026-11-10",
               vocabulario = voc_p, zonas = zonas)
  m <- jsonlite::fromJSON(file.path(dir, "datos", "manifiesto.json"), simplifyVector = FALSE)
  z <- m$mapas$zona_tensionada
  expect_equal(c(z$base, z$formula, z$nivel_minimo, z$detalle),
               c("zona_tensionada", "directo", "municipio", "datos/zonas_tensionadas.json"))
  expect_equal(unlist(z$cortes), c(0.5, 1.5))
  expect_equal(z$categorias$vocabulario, "zona_tensionada")
  expect_equal(unlist(z$categorias$valores), c(0, 1, 2))
  expect_null(m$mapas$renta_persona$nivel_minimo)               # los mapas con sección, como antes
  expect_null(m$mapas$renta_persona$categorias)
  d <- jsonlite::fromJSON(file.path(dir, "datos", "zonas_tensionadas.json"), simplifyVector = FALSE)
  expect_equal(d[["28001"]][[1]][c("boe", "inicio", "fin", "ambito")],
               list(boe = "BOE-A-2099-1", inicio = "2025-03-16", fin = "2028-03-15", ambito = "municipio"))
  x <- comprobar_zonas_web(zonas, dir)
  expect_true(all(x$calculado == 0))
  x <- comprobar_zonas_web(dplyr::mutate(zonas, fecha_fin = fecha_fin + 1), dir)
  expect_gt(sum(x$calculado), 0)
  expect_equal(readLines(file.path(dir, "datos", "municipio", "zona_tensionada", "2025.json")), '{"v":[20,0],"e":"00"}')
  expect_null(categorias_web(NULL, "zona_tensionada"))
  expect_error(categorias_web(tibble::tibble(grupo = "x", clave = "a"), "x"), "números")
})
