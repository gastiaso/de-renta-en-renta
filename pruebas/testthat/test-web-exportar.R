# Exportación de los datos de la web (R/web_exportar.R), con datos inventados

jer_web <- tibble::tibble(seccion = c("2800101001", "2800101002", "2800201001"),
                          distrito = c("2800101", "2800101", "2800201"), municipio = c("28001", "28001", "28002"),
                          provincia = "28", ccaa = "13")
ter_web <- geo_territorios(jer_web, tibble::tibble(municipio = c("28001", "28002"), nombre = c("Uno", "Dos")),
                           tibble::tibble(provincia = "28", nombre = "Madrid", ccaa = "13"),
                           tibble::tibble(codigo = "13", nombre_ine = "Madrid, Comunidad de", nuts2 = "ES30"))
ind_web <- tibble::tibble(
  id = c(1, 9, 15, 19, 21, 22, 8),
  codigo = c("renta_persona", "alquiler_m2", "peso_alquiler_ingreso", "viviendas_turisticas", "sueldo_necesario", "sobrecarga",
             "alquiler_mes"),
  unidad_es = c("€ por persona y año", "€ por m² y mes", "% del ingreso", "% de las viviendas",
                "€ netos por mes", "%", "€ por mes"),
  nucleo_v01 = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE),
  cortes_web = c("10;20;30;40", "4;5.5;7;9", NA, "0.5;1;2.5;5", "1000;1300;1600;2000;2600", NA, "350;425;500;650"),
  escala_web = c(NA, NA, NA, 100, NA, NA, NA),                    # el 19, con dos decimales
  familia_alquiler = c(NA, "quedarse", "quedarse", NA, "quedarse", NA, "quedarse")   # tarea 34
)
fila_web <- function(geo_id, nivel, anio, indicador, valor, estado = "dato", corte = "total", grupo = "total",
                     fuente = "prueba") {
  tibble::tibble(geo_id = geo_id, nivel = nivel, anio = as.integer(anio), indicador = indicador, valor = valor,
                 estado = estado, corte = corte, grupo = grupo, fuente = fuente, geo_ref = "2021", version = "2026-11-08")
}
larga_web <- bind_rows(
  fila_web(c("2800101001", "2800101002", "2800201001"), "sc", 2020, "renta_persona", c(0.15, NA, 12.34),
           c("dato", "secreto", "estimado")),
  fila_web(c("2800101001", "2800101002"), "sc", 2021, "renta_persona", c(10, 11)),     # 2800201001: ausente
  fila_web("28001", "municipio", 2020, "renta_persona", 9.96),                          # el municipio, sin 2021
  fila_web(c("2800101001", "2800201001"), "sc", 2024, "alquiler_m2", c(10.04, 8), corte = "tipologia", grupo = "VC"),
  fila_web(c("2800101001", "2800201001"), "sc", 2024, "alquiler_mes", c(803.2, 640), corte = "tipologia", grupo = "VC"),
  fila_web("2800101001", "sc", 2024, "alquiler_m2", 12, corte = "tipologia", grupo = "VU"),
  fila_web("2800101001", "sc", 2024, "alquiler_m2", 7, corte = "tipologia_p25", grupo = "VC"),
  fila_web("2800101001", "sc", 2024, "peso_alquiler_ingreso", 40, corte = "ficha", grupo = "tartera"),
  fila_web(c("2800101001", "2800101002"), "sc", 2024, "viviendas_turisticas", c(1.234, 2), corte = "mes", grupo = "M02"),
  fila_web(c("2800101001", "2800101002"), "sc", 2024, "viviendas_turisticas", c(3, 4.5678), corte = "mes", grupo = "M11"),
  fila_web("13", "ccaa", 2024, "sobrecarga", 7.2)
)
perfiles_prueba <- tibble::tibble(
  ficha = c("tartera", "tartera", "mochila", "mochila", "llave"), nivel = c("nacional", "nacional", "provincia", "provincia", "sc"),
  geo_id = c("00", "00", "28", "01", "2800101001"), anio = c(2024L, 2026L, 2024L, 2024L, 2024L),
  ingreso = c(1237.04, 1332.26, 1450.55, NA, 2500), estado = c("dato", "dato", "dato", "ausente", "dato"),
  superficie_m2 = c(50, 50, 50, 50, NA), fuente = "prueba"
)

test_that("valores × 10 con el redondeo de la guía y estados en cifras", {
  expect_equal(valor_web(c(0.15, 25.34, NA, 112163)), c(1L, 253L, NA, 1121630L))
  expect_equal(estado_web(c("dato", "estimado", "secreto", "ausente")), c("0", "1", "2", "3"))
  expect_error(estado_web("raro"), "sin cifra")
  expect_equal(json_valores(c(253L, NA), c("0", "3")), '{"v":[253,null],"e":"03"}')
  expect_equal(json_valores(matrix(c(1L, NA, 3L, 4L), 2), matrix(c("0", "3", "1", "0"), 2)),
               c('{"v":[1,3],"e":"01"}', '{"v":[null,4],"e":"30"}'))
  expect_equal(decimales_web(c("€ por mes", "€ por m² y mes", "% de los hogares")), c(0L, 1L, 1L))
})

test_that("escala propia (escala_web): dos decimales con escala 100 y el redondeo de la guía", {
  expect_equal(escala_web(ind_web, c("viviendas_turisticas", "alquiler_m2", "no_existe")), c(100L, 10L, 10L))
  expect_equal(escala_web(ind_web[, setdiff(names(ind_web), "escala_web")], "viviendas_turisticas"), 10L)
  expect_error(escala_web(dplyr::mutate(ind_web, escala_web = c(NA, 50, NA, 100, NA, NA, NA)), "alquiler_m2"), "50")
  expect_error(escala_web(dplyr::mutate(ind_web, escala_web = c(NA, "cien", NA, 100, NA, NA, NA)), "alquiler_m2"), "cien")
  expect_equal(valor_web(c(1.234, 4.5678, NA, 0.15), 100), c(123L, 457L, NA, 15L))
  expect_equal(valor_web(c(1.234, 1.234), c(10, 100)), c(12L, 123L))
  expect_equal(redondeo_guia(c(1.234, 1.234), c(1, 2)), c(1.2, 1.23))
  expect_equal(decimales_web(c("% de las viviendas", "€ por mes"), c(100, 10)), c(2L, 0L))
})

test_that("series: grupo por defecto con el código, variantes con «.grupo», meses como periodos y otros cortes fuera", {
  s <- series_web(larga_web, ind_web)
  expect_setequal(unique(s$clave), c("renta_persona", "alquiler_m2", "alquiler_m2_vu", "alquiler_mes", "viviendas_turisticas"))
  expect_false(any(s$corte %in% c("tipologia_p25", "ficha")))
  expect_equal(sort(unique(s$periodo[s$clave == "viviendas_turisticas"])), c("2024-02", "2024-11"))
})

test_that("la exportación escribe el contrato de la web y pasa la compuerta de ida y vuelta", {
  dir <- tempfile("web_")
  on.exit(unlink(dir, recursive = TRUE))
  rutas <- exportar_web(larga_web, ind_web, jer_web, ter_web, perfiles = perfiles_prueba,
                        cajas = list(municipio = list("28001" = c(-3.8, 40.3, -3.5, 40.6))), dir_web = dir,
                        fecha = "2026-11-08")
  expect_true(all(file.exists(rutas)))
  m <- jsonlite::fromJSON(file.path(dir, "datos", "manifiesto.json"), simplifyVector = FALSE)
  expect_false(m$ejemplo)
  expect_equal(m$mapa_base$capas$secciones$id, "seccion")
  expect_null(m$mapa_base$capas$sin_seccion$id)                          # sin código: no entra en índices
  expect_equal(unlist(m$mapa_base$capas$sin_seccion$atributos), c("km2", "provincias", "nombre", "tipo"))
  expect_equal(m$mapa_base$atribucion, "INE, IGN")
  expect_equal(m$indices$sc, "datos/indices/sc.json")
  expect_equal(unlist(jsonlite::fromJSON(file.path(dir, m$indices$nacional))), "00")
  expect_equal(unlist(jsonlite::fromJSON(file.path(dir, m$indices$municipio))), c("28001", "28002"))
  expect_setequal(names(m$indicadores), c("renta_persona", "alquiler_m2", "alquiler_m2_vu", "alquiler_mes", "viviendas_turisticas"))
  a <- m$indicadores$alquiler_m2
  expect_equal(c(a$indicador, a$grupo, a$corte, a$ruta), c("alquiler_m2", "VC", "tipologia", "datos/{nivel}/alquiler_m2/{anio}.json"))
  expect_equal(a$variantes$VU, "alquiler_m2_vu")
  expect_equal(a$decimales, 1L)
  expect_equal(m$indicadores$alquiler_m2_vu$ruta, "datos/{nivel}/alquiler_m2_vu/{anio}.json")
  expect_equal(m$indicadores$alquiler_m2_vu$por_defecto, "alquiler_m2")
  expect_null(m$indicadores$renta_persona$indicador)
  r <- m$indicadores$renta_persona
  expect_equal(r$ruta, "datos/{nivel}/renta_persona/{anio}.json")
  expect_equal(unlist(r$anios), c(2020L, 2021L))
  expect_equal(unlist(r$niveles), c("sc", "municipio"))
  expect_equal(r$decimales, 0L)
  expect_null(r$escala)                                                   # la general, la de codificacion
  expect_equal(m$codificacion$escala, 10L)
  v <- m$indicadores$viviendas_turisticas
  expect_equal(unlist(v$periodos), c("2024-02", "2024-11"))
  expect_equal(v$ruta, "datos/{nivel}/viviendas_turisticas/{periodo}.json")
  expect_null(v$anios)
  expect_equal(c(v$escala, v$decimales), c(100L, 2L))
  expect_equal(m$mapas$viviendas_turisticas$decimales, 2L)
  expect_equal(m$mapas$alquiler_m2$decimales, 1L)
  expect_equal(names(m$mapas)[1], "sueldo_necesario")
  # Tarea 40: el sueldo necesario pinta el alquiler mensual real y lleva al lado el mínimo de 50 m²
  expect_equal(m$mapas$sueldo_necesario[c("base", "formula")], list(base = "alquiler_mes", formula = "alquiler_mes_a_sueldo"))
  expect_equal(m$mapas$sueldo_necesario$minimo, list(base = "alquiler_m2", formula = "alquiler_m2_a_sueldo"))
  expect_null(m$mapas$alquiler_m2$minimo)
  expect_equal(unlist(m$mapas$alquiler_m2$cortes), c(4, 5.5, 7, 9))
  expect_equal(unlist(m$mapas$sueldo_necesario$cortes), c(1000, 1300, 1600, 2000, 2600))   # seis tramos
  expect_null(m$mapas$peso_alquiler_ingreso)                         # sin cortes_web, sin mapa (tarea 41)
  expect_equal(m$mapas$renta_persona$formula, "directo")
  # Tarea 34: los mapas de alquiler llevan su familia; los demás, ninguna
  expect_equal(m$mapas$alquiler_m2$familia, "quedarse")
  expect_equal(m$mapas$sueldo_necesario$familia, "quedarse")
  expect_null(m$mapas$renta_persona$familia)

  # Valores en el orden del índice; la sección sin fila, null y ausente; el municipio sin 2021, entero ausente
  leer <- function(r) readLines(file.path(dir, "datos", r))
  expect_equal(leer("sc/renta_persona/2020.json"), '{"v":[1,null,123],"e":"021"}')
  expect_equal(leer("sc/renta_persona/2021.json"), '{"v":[100,110,null],"e":"003"}')
  expect_equal(leer("municipio/renta_persona/2021.json"), '{"v":[null,null],"e":"33"}')
  expect_equal(leer("sc/viviendas_turisticas/2024-11.json"), '{"v":[300,457,null],"e":"003"}')   # × 100
  f <- jsonlite::fromJSON(file.path(dir, "datos/fichas/28001.json"), simplifyVector = FALSE)
  expect_equal(names(f$series), c("2800101001", "2800101002"))
  expect_equal(f$series$`2800101001`$renta_persona, list(v = list(1L, 100L), e = "00"))
  expect_equal(unlist(f$anios$viviendas_turisticas), c("2024-02", "2024-11"))
  expect_equal(f$series$`2800101001`$viviendas_turisticas, list(v = list(123L, 300L), e = "00"))
  expect_equal(f$series_municipio$series$renta_persona, list(v = list(100L, NULL), e = "03"))
  expect_true("alquiler_m2" %in% names(f$anios))
  expect_false("alquiler_m2_vu" %in% names(f$anios))                     # las variantes no van en la ficha

  t <- jsonlite::fromJSON(file.path(dir, "datos/territorios.json"), simplifyVector = FALSE)
  expect_equal(t$ccaa_de_provincia, list("28" = "13"))
  p <- jsonlite::fromJSON(file.path(dir, "datos/perfiles.json"), simplifyVector = FALSE)
  expect_equal(p$tartera$anio, 2026L)
  expect_equal(p$tartera$neto_mensual, list("00" = 1332.3))
  expect_equal(p$mochila$neto_mensual, list("28" = 1450.5))             # sin la provincia ausente
  expect_equal(p$llave$ingreso$serie, "renta_hogar")

  c1 <- comprobar_web(larga_web, ind_web, jer_web, ter_web, dir_web = dir, perfiles = perfiles_prueba)
  expect_setequal(unique(c1$id), c("web_valores", "web_fichas", "web_fuera_indice"))
  expect_true(all(c1$calculado == 0))

  # Un valor tocado, una serie de dos decimales escrita con una (× 10) y una sección borrada de su
  # ficha: la compuerta los ve
  writeLines('{"v":[2,null,123],"e":"021"}', file.path(dir, "datos/sc/renta_persona/2020.json"))
  writeLines('{"v":[30,46,null],"e":"003"}', file.path(dir, "datos/sc/viviendas_turisticas/2024-11.json"))
  f$series$`2800101002` <- NULL
  jsonlite::write_json(f, file.path(dir, "datos/fichas/28001.json"), auto_unbox = TRUE, null = "null")
  c2 <- comprobar_web(larga_web, ind_web, jer_web, ter_web, dir_web = dir)
  expect_equal(c2$calculado[c2$detalle == "datos/sc/renta_persona/2020.json"], 1)
  expect_equal(c2$calculado[c2$detalle == "datos/sc/viviendas_turisticas/2024-11.json"], 2)
  expect_gt(c2$calculado[c2$id == "web_fichas" & c2$detalle == "28001"], 0)
  expect_equal(c2$calculado[c2$id == "web_fichas" & c2$detalle == "28002"], 0)
})

test_that("cortes de los mapas: de uno a cinco valores crecientes (seis tramos como mucho)", {
  expect_equal(cortes_web("700;900;1100;1500;2000"), c(700, 900, 1100, 1500, 2000))
  expect_equal(cortes_web("1;2.5"), c(1, 2.5))
  expect_error(cortes_web("1;2;3;4;5;6"), "de 1 a 5")
  expect_error(cortes_web("1;3;2"), "crecientes")
  expect_error(suppressWarnings(cortes_web("1;x")), "crecientes")
})

test_that("auxiliares del alquiler: contratos y margen van a la web con su tipología y la compuerta los comprueba", {
  ind <- bind_rows(dplyr::mutate(ind_web, auxiliar_de = NA_character_),
                   tibble::tibble(id = NA, codigo = c("contratos_alquiler", "margen_alquiler_m2", "margen_otro"),
                                  unidad_es = c("contratos", "% de la mediana", "% de la mediana"), nucleo_v01 = FALSE,
                                  cortes_web = NA, escala_web = NA,
                                  auxiliar_de = c("alquiler_m2;sueldo_necesario", "alquiler_m2;sueldo_necesario", "sobrecarga")))
  aux <- bind_rows(
    fila_web(c("2800101001", "2800101002", "2800201001"), "sc", 2024, "contratos_alquiler", c(25, 4, 0), corte = "tipologia", grupo = "VC"),
    fila_web(c("2800101001", "2800201001"), "sc", 2024, "contratos_alquiler", c(12, NA), c("dato", "ausente"),
             corte = "tipologia", grupo = "VU"),
    fila_web("28", "provincia", 2024, "contratos_alquiler", 29, corte = "tipologia", grupo = "VC"),
    fila_web(c("2800101001", "2800201001"), "sc", 2024, "margen_alquiler_m2", c(8.36, 11.75), corte = "tipologia", grupo = "VC"),
    fila_web("2800101001", "sc", 2024, "margen_alquiler_m2", 20.04, corte = "tipologia", grupo = "VU"),
    fila_web("13", "ccaa", 2024, "margen_otro", 1)                 # auxiliar de un indicador fuera del núcleo: no va
  )
  larga <- bind_rows(larga_web, aux)
  s <- series_web(larga, ind)
  expect_setequal(unique(s$clave), c("renta_persona", "alquiler_m2", "alquiler_m2_vu", "alquiler_mes", "viviendas_turisticas",
                                     "contratos_alquiler", "contratos_alquiler_vu", "margen_alquiler_m2", "margen_alquiler_m2_vu"))
  expect_error(auxiliares_web(dplyr::mutate(ind, codigo = ifelse(codigo == "margen_otro", "raro_otro", codigo))), "raro_otro")
  expect_equal(nrow(auxiliares_web(ind_web)), 0L)                  # sin la columna, ninguno

  dir <- tempfile("web_")
  on.exit(unlink(dir, recursive = TRUE))
  exportar_web(larga, ind, jer_web, ter_web, perfiles = perfiles_prueba, dir_web = dir, fecha = "2026-11-09")
  m <- jsonlite::fromJSON(file.path(dir, "datos", "manifiesto.json"), simplifyVector = FALSE)
  expect_equal(m$umbral_pocos_contratos, UMBRAL_POCOS_CONTRATOS)
  expect_equal(m$indicadores$alquiler_m2$fiabilidad, list(contratos = "contratos_alquiler", margen = "margen_alquiler_m2"))
  expect_equal(m$indicadores$alquiler_m2_vu$fiabilidad, list(contratos = "contratos_alquiler_vu", margen = "margen_alquiler_m2_vu"))
  expect_null(m$indicadores$renta_persona$fiabilidad)
  expect_null(m$indicadores$contratos_alquiler$id)                   # los auxiliares no tienen número
  expect_equal(m$indicadores$contratos_alquiler$decimales, 0L)
  expect_equal(m$indicadores$margen_alquiler_m2$decimales, 1L)
  expect_equal(m$indicadores$contratos_alquiler$variantes$VU, "contratos_alquiler_vu")
  expect_null(m$mapas$contratos_alquiler)                           # sin mapa propio
  leer <- function(r) readLines(file.path(dir, "datos", r))
  expect_equal(leer("sc/contratos_alquiler/2024.json"), '{"v":[250,40,0],"e":"000"}')   # 0 contratos: dato
  expect_equal(leer("sc/margen_alquiler_m2/2024.json"), '{"v":[84,null,118],"e":"030"}')
  f <- jsonlite::fromJSON(file.path(dir, "datos/fichas/28001.json"), simplifyVector = FALSE)
  expect_false(any(c("contratos_alquiler", "margen_alquiler_m2") %in% names(f$anios)))  # no van en las fichas
  expect_true("alquiler_m2" %in% names(f$anios))
  comp <- comprobar_web(larga, ind, jer_web, ter_web, dir, perfiles = perfiles_prueba)
  expect_true(all(comp$calculado == 0))
  expect_true(any(grepl("contratos_alquiler", comp$detalle)))
})
