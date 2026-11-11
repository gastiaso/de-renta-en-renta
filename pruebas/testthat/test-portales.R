# Indicador 13: capa desmontable de los precios de oferta de los portales (R/fuente_portales.R y
# R/web_portales.R; F5 y tarea 35), con datos inventados (pruebas/datos/; nunca en datos/brutos/):
#   - portales_inventado.csv: el formato de la capa, escrito a mano (también venta y Fotocasa);
#   - idealista/: una extracción de Idealista inventada, con la correspondencia
#     portales_idealista_territorios.csv (el formato de la de inventario/);
# y mapas de la web sin sección (indicador 20).

MUESTRA_PORTALES <- file.path("..", "datos", "portales_inventado.csv")
DIR_MUESTRA_IDEALISTA <- file.path("..", "datos", "idealista")
CORRESPONDENCIA_PRUEBA <- file.path("..", "datos", "portales_idealista_territorios.csv")

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
  escala_web = c(NA, 100, NA, NA)
)
fila_p <- function(geo_id, nivel, anio, indicador, valor, corte = "total", grupo = "total", fuente = "prueba") {
  tibble::tibble(geo_id = geo_id, nivel = nivel, anio = as.integer(anio), indicador = indicador, corte = corte, grupo = grupo,
                 valor = valor, estado = "dato", fuente = fuente, geo_ref = "2021", version = "2026-11-10")
}
larga_base_p <- dplyr::bind_rows(
  fila_p(c("2800101001", "2800101002", "2800201001"), "sc", 2024, "renta_persona", c(11, 12, 13)),
  fila_p(c("28001", "28002"), "municipio", 2024, "renta_persona", c(11.5, 13))
)
# Extracción inventada de Idealista en un directorio temporal con la estructura de datos/brutos/portales/
copia_portales <- function(env = parent.frame(), manual = FALSE) {
  dir <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(dir, "idealista"))
  file.copy(list.files(DIR_MUESTRA_IDEALISTA, full.names = TRUE), file.path(dir, "idealista"))
  if (manual) file.copy(MUESTRA_PORTALES, dir)
  dir
}
territorios_idealista_p <- idealista_leer_territorios(CORRESPONDENCIA_PRUEBA)

test_that("el interruptor está apagado salvo con PORTALES=TRUE", {
  expect_false(portales_activos("FALSE"))
  expect_false(portales_activos(""))
  expect_false(portales_activos("1"))
  expect_true(portales_activos("TRUE"))
  expect_true(portales_activos(" true "))
})

test_that("encendida sin ficheros, se detiene y dice qué dejar y dónde", {
  vacio <- withr::local_tempdir()
  expect_error(buscar_ficheros_portales(vacio), "no hay ficheros")
  expect_error(buscar_ficheros_portales(vacio), "nunca anuncios")
  expect_error(buscar_ficheros_portales(vacio), "idealista")
})

test_that("la muestra manual se lee, pasa la compuerta y da un valor por año: media de 9 meses o más", {
  p <- leer_portales(MUESTRA_PORTALES)
  expect_equal(nrow(p), 33L)
  x <- comprobar_portales(p, ter_p)
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))
  a <- anualizar_portales(p, desde = 2024L)
  v <- function(cod, anio, grupo, nivel = "municipio") {
    a[a$geo_id == cod & a$anio == anio & paste(a$operacion, a$portal, sep = "_") == grupo & a$nivel == nivel, ]
  }
  expect_equal(v("28001", 2024, "alquiler_idealista")$valor, 11.1)         # los 12 meses
  expect_equal(v("28001", 2024, "alquiler_idealista")$meses, 12L)
  expect_true(is.na(v("28002", 2024, "alquiler_idealista")$valor))         # 8 meses: ausente
  expect_equal(v("28002", 2024, "alquiler_idealista")$estado, "ausente")
  expect_equal(v("28001", 2025, "alquiler_idealista")$valor, 13.3)         # la cifra anual manda
  expect_equal(v("28002", 2025, "venta_fotocasa")$valor, 1111.1)
  expect_equal(v("28001", 2025, "alquiler_idealista", "zona")$valor, 15.5) # zona con 9 meses
  larga <- armonizar_portales(a, version = "2026-11-10")
  validar_tabla_larga(larga, vocabulario = voc_p)
  expect_false("zona" %in% larga$nivel)                                    # las zonas, aparte
  expect_true(all(larga$corte == "oferta_privada" & larga$fuente == "portales" & larga$indicador == "precio_oferta"))
  expect_true("oferta_privada" %in% voc_p$clave[voc_p$grupo == "corte"])
  expect_equal(voc_p$es[voc_p$grupo == "etiqueta" & voc_p$clave == "portales"], "Dato privado de oferta")
  z <- portales_zonas(a)
  expect_equal(z$zona, "centro")
  expect_equal(z$grupo, "alquiler_idealista")
})

test_that("la media anual redondea los empates hacia arriba y exige 9 meses", {
  expect_equal(redondear_empate_arriba(c(7.575, 13.058333, 7.574999, 100.005)), c(7.58, 13.06, 7.57, 100.01))
  mes <- function(n, valor) tibble::tibble(portal = "idealista", operacion = "alquiler", nivel = "municipio", geo_id = "28001",
                                           zona = NA_character_, nombre = "Uno", periodo = sprintf("2020-%02d", seq_len(n)),
                                           valor = valor, informe = "i", url = "https://ejemplo.invalid")
  expect_equal(anualizar_portales(mes(9, 10))$estado, "dato")
  expect_equal(anualizar_portales(mes(8, 10))$estado, "ausente")
  expect_equal(anualizar_portales(dplyr::bind_rows(mes(9, 10), mes(9, 10)))$meses, 9L)   # un mes repetido cuenta una vez
  expect_equal(nrow(anualizar_portales(mes(12, 10), desde = 2021L)), 0L)
})

test_that("la compuerta de la capa para con códigos, zonas, periodos, precios y meses repetidos", {
  p <- leer_portales(MUESTRA_PORTALES)
  suma <- function(q, id) { x <- comprobar_portales(q, ter_p); sum(x$calculado[x$id == id]) }
  q <- p; q$geo_id[1] <- "28999"
  expect_gt(suma(q, "portales_codigos"), 0)
  q <- p; q$geo_id[1] <- "2800101"                                          # un distrito del INE no es un nivel de la capa
  expect_gt(suma(q, "portales_formato"), 0)
  q <- p; q$periodo[1] <- "2024-13"
  expect_gt(suma(q, "portales_formato"), 0)
  q <- p; q$zona[1] <- "centro"                                             # zona en una fila de municipio
  expect_gt(suma(q, "portales_formato"), 0)
  q <- p; q$valor[nrow(q)] <- 2.2                                           # venta a 2,2 € el m²: un error de copia
  expect_gt(suma(q, "portales_rango"), 0)
  q <- p; q$url[2] <- ""
  expect_gt(suma(q, "portales_formato"), 0)
  q <- rbind(p, p[1, ])
  expect_gt(suma(q, "portales_repetidas"), 0)
})

test_that("Idealista: la extracción más reciente, convertida al formato de la capa", {
  dir <- copia_portales(manual = TRUE)
  rutas <- buscar_ficheros_portales(dir)
  expect_equal(basename(rutas), c("portales_inventado.csv", "alquiler_historico_2099-01.csv", "alquiler_zonas_2099-01.csv"))
  expect_error(leer_portales(rutas), "portales_idealista_territorios")
  p <- leer_portales(rutas, territorios_idealista_p)
  i <- p[p$fichero == "alquiler_historico_2099-01.csv", ]
  expect_equal(nrow(i), 118L)
  expect_setequal(unique(i$nivel), c("nacional", "ccaa", "provincia", "municipio", "zona", "localidad"))
  expect_equal(unique(i$zona[i$nivel == "zona"]), "centro")
  expect_setequal(unique(i$zona[i$nivel == "localidad"]), c("la-urbanizacion", "entre-dos"))
  expect_true(all(is.na(i$zona[!i$nivel %in% c("zona", "localidad")])))
  expect_true(all(startsWith(i$url, "https://ejemplo.invalid/sala-de-prensa/")))   # el enlace del fichero de territorios
  expect_equal(unique(i$informe), IDEALISTA_INFORMES[["alquiler"]])
  x <- comprobar_portales(p, ter_p)
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))

  a <- anualizar_portales(p)
  esp <- a[a$nivel == "nacional", ]
  expect_equal(esp$valor, c(7.58, 8.45))                                    # 2015: 7,575 sube a 7,58
  expect_equal(esp$meses, c(12L, 10L))
  prov <- a[a$nivel == "provincia", ]
  expect_equal(prov$estado, c("dato", "ausente"))                           # 9 y 8 meses
  ck <- idealista_comprobar(p, a, territorios_idealista_p)
  expect_equal(ck$calculado[ck$id == "portales_idealista_casados"], c(0, 0))
  expect_equal(ck$calculado[ck$id == "portales_idealista_espana"], c(7.58, NA))   # sin 2024 en la muestra
  expect_equal(ck$calculado[ck$id == "portales_idealista_municipios"], c(1, 1))
  # Una dirección sin correspondencia queda sin nivel: la compuerta la cuenta dos veces
  t2 <- territorios_idealista_p[territorios_idealista_p$nivel != "zona", ]
  p2 <- leer_portales(rutas, t2)
  expect_gt(sum(comprobar_portales(p2, ter_p)$calculado), 0)
  expect_gt(sum(idealista_comprobar(p2, anualizar_portales(p2), t2)$calculado[1]), 0)
  # Las localidades: la de un municipio, con las zonas; la repartida entre dos, en ninguna parte
  z <- portales_zonas(a)
  expect_setequal(paste(z$nivel, z$geo_id, z$zona), c("zona 28001 centro", "localidad 28002 la-urbanizacion"))
  larga <- armonizar_portales(a, version = "2099-01-15")
  validar_tabla_larga(larga, vocabulario = voc_p)
  expect_setequal(unique(larga$nivel), c("nacional", "ccaa", "provincia", "municipio"))
  expect_equal(portales_ultimo_mes(p[p$fichero != "portales_inventado.csv", ])$alquiler_idealista, "2016-12")
})

test_that("Idealista: un histórico sin su fichero de territorios se detiene", {
  dir <- copia_portales()
  file.remove(file.path(dir, "idealista", c("alquiler_zonas_2099-01.csv", "alquiler_zonas_2098-12.csv")))
  expect_error(buscar_ficheros_portales(dir), "territorios")
})

# Firma de todos los ficheros de una exportación (ruta relativa y contenido)
firma_web <- function(dir) {
  f <- sort(list.files(dir, recursive = TRUE))
  stats::setNames(vapply(file.path(dir, f), function(r) paste(readLines(r, warn = FALSE), collapse = "\n"), ""), f)
}

test_that("la capa sale en su carpeta, con su compuerta, y no toca la exportación general", {
  dir <- withr::local_tempdir()
  exportar_web(larga_base_p, ind_p, jer_p, ter_p, dir_web = dir, fecha = "2026-11-10", vocabulario = voc_p)
  general <- firma_web(file.path(dir, "datos"))

  # Apagada: solo el manifiesto vacío
  portales_apagar_web(dir)
  expect_equal(list.files(file.path(dir, "datos", "portales"), recursive = TRUE), "manifiesto.json")
  expect_equal(jsonlite::fromJSON(file.path(dir, "datos", "portales", "manifiesto.json")), list(capa = "portales", activa = FALSE))

  # Encendida
  p <- leer_portales(c(MUESTRA_PORTALES, buscar_ficheros_portales(copia_portales())), territorios_idealista_p)
  a <- anualizar_portales(p)
  larga <- armonizar_portales(a, version = "2026-11-10")
  rutas <- portales_exportar_web(larga, a, p, ind_p, jer_p, ter_p, vocabulario = voc_p, dir_web = dir, fecha = "2026-11-10")
  expect_true(all(startsWith(rutas, file.path(dir, "datos", "portales"))))
  ahora <- firma_web(file.path(dir, "datos"))
  expect_identical(ahora[names(general)], general)                          # lo general, igual
  expect_true(all(startsWith(setdiff(names(ahora), names(general)), "portales/")))

  m <- jsonlite::fromJSON(file.path(dir, "datos", "portales", "manifiesto.json"), simplifyVector = FALSE)
  expect_true(m$activa)
  expect_setequal(names(m$mapas), c("precio_oferta_alquiler_idealista", "precio_oferta_venta_fotocasa"))
  a_m <- m$mapas$precio_oferta_alquiler_idealista
  expect_equal(c(a_m$base, a_m$indicador, a_m$corte, a_m$grupo, a_m$nivel_minimo),
               c("precio_oferta_alquiler_idealista", "precio_oferta", "oferta_privada", "alquiler_idealista", "municipio"))
  expect_equal(unlist(a_m$cortes), c(8, 10, 12, 15, 20))
  expect_equal(unlist(m$mapas$precio_oferta_venta_fotocasa$cortes), c(1000, 1500, 2000, 3000, 4000))
  s <- m$indicadores$precio_oferta_alquiler_idealista
  expect_equal(s$fuente, "portales")                                        # la web pone la etiqueta por la fuente
  expect_null(s$por_defecto)
  expect_equal(unlist(s$niveles), c("municipio", "provincia", "ccaa", "nacional"))
  expect_equal(s$escala, 100)
  expect_equal(s$ruta, "datos/portales/{nivel}/precio_oferta_alquiler_idealista/{anio}.json")
  expect_equal(s$ultimo_mes, "2025-12")                                     # la muestra manual llega más lejos
  expect_equal(s$meses_minimos, 9L)
  expect_equal(unlist(s$anios), c(2015L, 2016L, 2024L, 2025L))
  expect_equal(readLines(file.path(dir, "datos", "portales", "nacional", "precio_oferta_alquiler_idealista", "2015.json")),
               '{"v":[758],"e":"0"}')
  expect_equal(readLines(file.path(dir, "datos", "portales", "municipio", "precio_oferta_alquiler_idealista", "2024.json")),
               '{"v":[1110,null],"e":"03"}')
  enlaces <- jsonlite::fromJSON(file.path(dir, s$enlaces), simplifyVector = FALSE)
  expect_equal(enlaces$nacional[["00"]], "https://ejemplo.invalid/sala-de-prensa/informes-precio-vivienda/alquiler/")
  zonas <- jsonlite::fromJSON(file.path(dir, s$zonas), simplifyVector = FALSE)
  expect_equal(unlist(zonas$anios), c(2015L, 2016L, 2024L, 2025L))
  expect_setequal(names(zonas$municipios), c("28001", "28002"))
  centro <- zonas$municipios[["28001"]]
  expect_equal(vapply(centro, `[[`, "", "zona"), "centro")
  expect_equal(centro[[1]]$v[[1]], 1500)                                    # 2015, de la extracción
  expect_equal(substr(centro[[1]]$e, 1, 2), "03")

  x <- portales_comprobar_web(larga, a, ind_p, jer_p, ter_p, dir_web = dir)
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))
  writeLines('{"v":[700],"e":"0"}', file.path(dir, "datos", "portales", "nacional", "precio_oferta_alquiler_idealista", "2015.json"))
  x <- portales_comprobar_web(larga, a, ind_p, jer_p, ter_p, dir_web = dir)
  expect_equal(sum(x$calculado), 1)

  # Apagarla de nuevo borra lo exportado
  portales_apagar_web(dir)
  expect_equal(list.files(file.path(dir, "datos", "portales"), recursive = TRUE), "manifiesto.json")
  expect_identical(firma_web(file.path(dir, "datos"))[names(general)], general)
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
