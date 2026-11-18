# CIS por comunidad autónoma (R/fuente_cis_ccaa.R; tarea 63): intervalo de Wilson y efecto de diseño,
# base y menciones, tabla anual con Ceuta agrupada de dos en dos años, rupturas y año en curso,
# compuertas, suma de la descarga y JSON y CSV de la web. Microdatos inventados con la forma de los
# de Barómetro a barómetro (nunca el Parquet real).

comunidades_inventadas <- function() {
  tibble::tibble(codigo = c("01", "13", "18"), nombre_cis = c("Andalucía", "Madrid (Comunidad de)", "Ceuta (Ciudad Autónoma de)"),
                 agrupar_anios = c(1L, 1L, 2L))
}

nombres_inventados <- function() {
  tibble::tibble(codigo = c("01", "13", "18"), nombre_ine = c("Andalucía", "Madrid, Comunidad de", "Ceuta"), nuts2 = NA_character_)
}

# Entrevistas de un mes: `n` por comunidad, con `vivienda` de ellas citando PROB_007 (en la segunda
# mención en España y en la primera en la personal), una con «no procede» y pesos alternos 0,5 y 1,5.
mes_inventado <- function(mes, estudio, ccaa, n, vivienda, np = 0L) {
  prob <- rep("PROB_008", n)
  prob[seq_len(vivienda)] <- CIS_CCAA_VIVIENDA
  primera <- rep("PROB_001", n)
  primera[seq_len(np) + vivienda] <- CIS_CCAA_NO_PROCEDE
  tibble::tibble(estudio = estudio, mes = mes, peso = rep(c(0.5, 1.5), length.out = n), peso_ccaa = 1, ccaa = ccaa,
                 prob_esp_1 = primera, prob_esp_2 = prob, prob_esp_3 = "NC",
                 prob_per_1 = prob, prob_per_2 = "NS", prob_per_3 = "PROB_081")
}

microdatos_inventados <- function() {
  dplyr::bind_rows(
    mes_inventado("2022-10", "3001", "Andalucía", 40L, 10L),
    mes_inventado("2022-10", "3001", "Madrid (Comunidad de)", 40L, 20L),
    mes_inventado("2022-10", "3001", "Ceuta (Ciudad Autónoma de)", 30L, 3L),
    mes_inventado("2023-10", "3002", "Andalucía", 30L, 12L, np = 2L),
    mes_inventado("2023-10", "3002", "Madrid (Comunidad de)", 30L, 15L),
    mes_inventado("2023-10", "3002", "Ceuta (Ciudad Autónoma de)", 30L, 6L),
    mes_inventado("2023-11", "3003", "Andalucía", 30L, 9L),
    mes_inventado("2023-11", "3003", "Madrid (Comunidad de)", 30L, 9L),
    mes_inventado("2023-11", "3003", "Ceuta (Ciudad Autónoma de)", 30L, 9L))
}

metadatos_inventados <- function(etiqueta = "La vivienda") {
  cats <- function() list(list(id = "PROB_007", etiqueta = etiqueta, no_respuesta = FALSE),
                          list(id = "PROB_008", etiqueta = "El paro", no_respuesta = FALSE))
  ccaa <- lapply(comunidades_inventadas()$nombre_cis, function(x) list(id = x, etiqueta = x, no_respuesta = FALSE))
  list(fuente = "CIS (inventado)", generado = "2026-11-06 18:55",
       estudios = list(list(estudio = "3001", mes = "2022-10", n = 110L, deff = 1.1),
                       list(estudio = "3002", mes = "2023-10", n = 90L, deff = 1.1),
                       list(estudio = "3003", mes = "2023-11", n = 90L, deff = 2)),
       conceptos = list(prob_esp_1 = list(categorias = cats()), prob_per_1 = list(categorias = cats()),
                        ccaa = list(categorias = ccaa)),
       rupturas = list(list(ruptura_id = "R10", mes = "2023-11", estudio = "3003", tipo = "C", conceptos_afectados = "todas",
                            estado = "confirmada", descripcion = "Ponderación por estudios"),
                       list(ruptura_id = "R19", mes = "2023-10", estudio = "3002", tipo = "C",
                            conceptos_afectados = "intencion_voto", estado = "confirmada", descripcion = "Voto"),
                       list(ruptura_id = "R05", mes = "2022-06 y 2022-10", estudio = "3366 y 3380", tipo = "tecnica",
                            conceptos_afectados = "prob_*", estado = "confirmada", descripcion = "Códigos")))
}

edicion_inventada <- function(dir = withr::local_tempdir(.local_envir = parent.frame()), etiqueta = "La vivienda") {
  rutas <- c(microdatos = file.path(dir, "barometros.parquet"), metadatos = file.path(dir, "metadatos.json"))
  arrow::write_parquet(microdatos_inventados(), rutas[["microdatos"]])
  jsonlite::write_json(metadatos_inventados(etiqueta), rutas[["metadatos"]], auto_unbox = TRUE)
  rutas
}

test_that("Wilson y el efecto de diseño de Kish dan las cifras de la fórmula", {
  w <- cis_ccaa_wilson(0.5, 100)
  expect_equal(w$inferior, 0.4038315, tolerance = 1e-6)
  expect_equal(w$superior, 0.5961685, tolerance = 1e-6)
  # pesos 0,5 y 1,5 alternos: deff = n·Σw²/(Σw)² = 1,25
  e <- cis_ccaa_estimar(c(TRUE, FALSE, TRUE, FALSE), c(0.5, 1.5, 0.5, 1.5))
  expect_equal(e$valor, 25)
  expect_equal(e$deff, 1.25)
  expect_equal(e$n_efectivo, 3.2)
  expect_equal(e$entrevistas, 4L)
  expect_equal(e$margen, (e$superior - e$inferior) / 2)
  w2 <- cis_ccaa_wilson(0.25, 3.2)
  expect_equal(e$inferior, 100 * w2$inferior)
  # el intervalo de Wilson no es simétrico ni sale de 0-100
  expect_gt(e$inferior, 0)
  expect_false(isTRUE(all.equal(e$valor - e$inferior, e$superior - e$valor)))
  vacio <- cis_ccaa_estimar(logical(0), numeric(0))
  expect_true(is.na(vacio$valor))
  expect_equal(vacio$entrevistas, 0L)
})

test_that("la base deja fuera «no procede» y cuenta la vivienda en cualquiera de las tres menciones", {
  rutas <- edicion_inventada()
  le <- cis_ccaa_leer(rutas)
  expect_equal(nrow(le$microdatos), 290L)
  expect_equal(le$estudios$n, c(110, 90, 90))
  expect_equal(cis_ccaa_rupturas(le$rupturas)$mes, "2023-11")   # R19 es de voto y R05 no es de tipo C
  m <- cis_ccaa_menciones(le, comunidades_inventadas())
  expect_equal(nrow(m), 580L)
  expect_false(anyNA(m$codigo))
  # dos «no procede» en la primera mención de España de Andalucía (2023-10): fuera de la base
  expect_equal(sum(!m$en_base), 2L)
  expect_true(all(m$en_base[m$pregunta == "personal"]))
  # España: la vivienda va en la segunda mención; personal, en la primera; PROB_081 no cuenta
  and23 <- m[m$codigo == "01" & m$mes == "2023-10", ]
  expect_equal(sum(and23$menciona[and23$pregunta == "espana"]), 12L)
  expect_equal(sum(and23$menciona[and23$pregunta == "personal"]), 12L)
  # una comunidad que no está en la tabla fija se queda sin código (compuerta cis_ccaa_codigos)
  expect_equal(sum(is.na(cis_ccaa_menciones(le, comunidades_inventadas()[1:2, ])$codigo)), 180L)
})

test_that("la tabla anual agrupa Ceuta de dos en dos años, marca la ruptura y el año en curso y deja fuera lo de menos de 50 entrevistas", {
  le <- cis_ccaa_leer(edicion_inventada())
  m <- cis_ccaa_menciones(le, comunidades_inventadas())
  tab <- cis_ccaa_tabla(m, comunidades_inventadas(), le$rupturas, nombres_inventados())
  expect_equal(nrow(tab), 4L * 2L * 2L)   # 3 comunidades y España, 2 años, 2 preguntas
  fila <- function(codigo, anio, pregunta = "espana") tab[tab$codigo == codigo & tab$anio == anio & tab$pregunta == pregunta, ]
  # Andalucía 2022: 40 entrevistas, menos de 50: ausente y sin cifra
  expect_equal(fila("01", 2022)$estado, "ausente")
  expect_true(is.na(fila("01", 2022)$valor))
  expect_equal(fila("01", 2022)$entrevistas, 40L)
  # Andalucía 2023: 58 en la base (dos «no procede» fuera); dos meses
  a23 <- fila("01", 2023)
  expect_equal(a23$entrevistas, 58L)
  expect_equal(a23$meses, 2L)
  expect_equal(a23$estado, "dato")
  base <- m[m$codigo == "01" & m$anio == 2023 & m$pregunta == "espana" & m$en_base, ]
  # Las comunidades, con peso_ccaa (revisión del 18-nov-2026)
  expect_equal(a23$valor, 100 * sum(base$peso_ccaa * base$menciona) / sum(base$peso_ccaa))
  # Ceuta 2023: 2022 y 2023 juntos (90 entrevistas); 2022, solo (30), ausente
  c23 <- fila("18", 2023)
  expect_equal(c(c23$anios, c23$entrevistas, c23$desde, c23$hasta), c("2", "90", "2022-10", "2023-11"))
  expect_equal(fila("18", 2022)$estado, "ausente")
  expect_equal(fila("18", 2023)$nombre, "Ceuta")
  # la ruptura de 2023-11 marca 2023 (mezcla los dos métodos) y no 2022
  expect_true(all(tab$ruptura[tab$anio == 2023]))
  expect_false(any(tab$ruptura[tab$anio == 2022]))
  # el último mes es 2023-11: 2023 está en curso
  expect_true(all(tab$en_curso[tab$anio == 2023]))
  expect_false(any(tab$en_curso[tab$anio == 2022]))
  # España junta todas las entrevistas de la base del año
  e22 <- fila("00", 2022)
  expect_equal(c(e22$nombre, e22$entrevistas), c("España", "110"))
})

test_that("las compuertas contrastan España mes a mes, la suma de las comunidades, las entrevistas y los códigos", {
  le <- cis_ccaa_leer(edicion_inventada())
  com <- comunidades_inventadas()
  m <- cis_ccaa_menciones(le, com)
  mens <- cis_ccaa_mensual(m)
  pa <- cis_ccaa_por_anio(m)
  tab <- cis_ccaa_tabla(m, com, le$rupturas, nombres_inventados())
  espana <- mens[mens$mes == "2022-10", ]
  cis_vivienda <- tibble::tibble(periodo = c("2022-10", "2022-10", "2023-10", "2023-10"), pregunta = c("espana", "personal", "espana", "personal"),
                                 total = c(espana$valor[espana$pregunta == "espana"] + 0.04, espana$valor[espana$pregunta == "personal"], 99, 1),
                                 n = c(110, 110, 90, 90))
  comp <- cis_ccaa_comprobar(le, m, mens, pa, tab, com, cis_vivienda)
  esp <- comp[comp$id == "cis_ccaa_espana", ]
  expect_equal(nrow(esp), 4L)
  # 2022-10 cuadra (a un decimal); 2023-10 no (99 publicado)
  dif <- abs(esp$calculado - esp$referencia)
  expect_equal(sum(dif > 0.1 + 1e-9), 2L)
  expect_true(all(dif[grepl("2022-10", esp$detalle)] <= 0.1 + 1e-9))
  # 2023-11 no tiene cifra nacional: alerta de meses
  expect_equal(sum(grepl("2023-11", comp$detalle[comp$id == "cis_ccaa_meses"])), 2L)
  # la suma de las comunidades ponderadas por sus pesos es España
  expect_true(all(comp$calculado[comp$id == "cis_ccaa_suma"] < 1e-9))
  expect_equal(comp$calculado[comp$id == "cis_ccaa_muestra"], c(0, 0))
  codigos <- comp[comp$id == "cis_ccaa_codigos", ]
  expect_equal(codigos$calculado[grepl("PROB_007", codigos$detalle)], 0)
  # con 3 comunidades en lugar de 19, la compuerta de códigos lo dice
  expect_gt(sum(codigos$calculado), 0)
  # «La vivienda» con otra etiqueta
  le2 <- cis_ccaa_leer(edicion_inventada(etiqueta = "La ocupación de viviendas"))
  comp2 <- cis_ccaa_comprobar(le2, m, mens, pa, tab, com, cis_vivienda)
  expect_equal(comp2$calculado[comp2$id == "cis_ccaa_codigos" & grepl("PROB_007", comp2$detalle)], 2)
  # el (N) publicado distinto de las entrevistas del Parquet
  cis_vivienda$n[1:2] <- 111
  comp3 <- cis_ccaa_comprobar(le, m, mens, pa, tab, com, cis_vivienda)
  expect_equal(comp3$calculado[comp3$id == "cis_ccaa_muestra"], c(0, 1))
  # todas las filas tienen su referencia en el inventario
  refs <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  expect_true(all(c(unique(comp$id), "cis_ccaa_fichero", "web_cis_ccaa") %in% refs$id))
})

test_that("la descarga se para si el fichero no tiene la suma del inventario", {
  dir <- withr::local_tempdir()
  ed <- file.path(dir, "v2099-01")
  dir.create(ed)
  writeLines("parquet", file.path(ed, "b.parquet"))
  writeLines("{}", file.path(ed, "m.json"))
  ficheros <- tibble::tibble(edicion = "v2099-01", tipo = c("microdatos", "metadatos"), fichero = c("b.parquet", "m.json"),
                             url = c("https://ejemplo.invalid/b.parquet", "https://ejemplo.invalid/m.json"),
                             bytes = file.size(file.path(ed, c("b.parquet", "m.json"))),
                             sha256 = c(cis_ccaa_sha256(file.path(ed, "b.parquet")), "0000"))
  expect_error(cis_ccaa_descargar(ficheros, dir = dir), "no es el de la edici")
  ficheros$sha256[2] <- cis_ccaa_sha256(file.path(ed, "m.json"))
  rutas <- cis_ccaa_descargar(ficheros, dir = dir)   # en la caché: no baja nada
  expect_equal(names(rutas), c("microdatos", "metadatos"))
  expect_equal(cis_ccaa_comprobar_ficheros(rutas, ficheros)$calculado, c(0, 0))
  expect_equal(cis_ccaa_comprobar_ficheros(unname(rutas), ficheros)$calculado, c(0, 0))   # sin nombres, por la extensión
  # una edición anterior en el inventario no se usa; una sin metadatos, error
  viejo <- dplyr::mutate(ficheros, edicion = "v2098-12")
  expect_equal(cis_ccaa_edicion(dplyr::bind_rows(viejo, ficheros))$edicion, c("v2099-01", "v2099-01"))
  expect_error(cis_ccaa_edicion(ficheros[1, ]), "microdatos y uno de metadatos")
})

test_that("el JSON y el CSV de la web dan la tabla redondeada, con la fuente y la licencia", {
  le <- cis_ccaa_leer(edicion_inventada())
  m <- cis_ccaa_menciones(le, comunidades_inventadas())
  tab <- cis_ccaa_tabla(m, comunidades_inventadas(), le$rupturas, nombres_inventados())
  ficheros <- tibble::tibble(edicion = "v2099-01", tipo = c("microdatos", "metadatos"), fichero = c("b.parquet", "m.json"),
                             url = c("https://ejemplo.invalid/b.parquet", "https://ejemplo.invalid/m.json"), bytes = 1, sha256 = "x")
  dir <- withr::local_tempdir()
  rutas <- cis_ccaa_exportar(tab, le$rupturas, ficheros, dir_web = dir)
  expect_true(all(file.exists(rutas)))
  expect_equal(cis_ccaa_comprobar_web(tab, rutas)$calculado, c(0, 0))
  x <- jsonlite::read_json(rutas[["json"]], simplifyVector = TRUE)
  expect_match(x$fuente, "Centro de Investigaciones Sociol")
  expect_match(x$fuente, "Barómetro a barómetro")
  expect_match(x$licencia, "CC BY 4.0")
  expect_equal(x$edicion, "v2099-01")
  expect_equal(x$ultimo_mes, "2023-11")
  expect_equal(x$rupturas$mes, "2023-11")
  expect_equal(length(x$filas$valor), nrow(tab))
  # los ausentes van sin cifra (null en el JSON, vacío en el CSV)
  expect_true(all(is.na(x$filas$valor[x$filas$estado == "ausente"])))
  csv <- readr::read_csv(rutas[["csv"]], col_types = readr::cols(codigo = "c", .default = readr::col_guess()))
  expect_equal(csv$valor, cis_un_decimal(tab$valor))
  # una cifra cambiada en el JSON: la ida y vuelta lo ve
  x$filas$valor[which(!is.na(x$filas$valor))[1]] <- 0
  jsonlite::write_json(x, rutas[["json"]], auto_unbox = TRUE, digits = NA, na = "null")
  expect_equal(cis_ccaa_comprobar_web(tab, rutas)$calculado, c(1, 0))
})

test_that("las comunidades se ponderan con peso_ccaa y España con peso (18-nov-2026)", {
  # Sin el Parquet: menciones con la forma de cis_ccaa_menciones(). En Madrid, peso y peso_ccaa no
  # coinciden (como desde la ruptura R10, con el ajuste por nivel educativo dentro de cada comunidad)
  n <- 60L
  m <- tibble::tibble(estudio = "3500", mes = "2025-10", anio = 2025L, codigo = "13", pregunta = "espana",
                      peso = rep(c(0.5, 1.5), length.out = n), peso_ccaa = rep(c(1.5, 0.5), length.out = n),
                      en_base = TRUE, menciona = rep(c(TRUE, FALSE), length.out = n))
  rupturas <- tibble::tibble(ruptura = character(), mes = character(), estudio = character(), tipo = character(),
                             conceptos = character(), estado = character(), descripcion = character())
  tab <- cis_ccaa_tabla(m, comunidades_inventadas()[2, ], rupturas, nombres_inventados())
  madrid <- tab[tab$codigo == "13" & tab$pregunta == "espana", ]
  espana <- tab[tab$codigo == "00" & tab$pregunta == "espana", ]
  expect_equal(madrid$valor, 100 * sum(m$peso_ccaa * m$menciona) / sum(m$peso_ccaa))   # 75 %
  expect_equal(espana$valor, 100 * sum(m$peso * m$menciona) / sum(m$peso))              # 25 %
  expect_equal(madrid$valor, 75)
  expect_equal(espana$valor, 25)
})

test_that("un peso 0 deja fuera a la persona y no para la compuerta (18-nov-2026)", {
  con_cero <- cis_ccaa_estimar(c(TRUE, FALSE, TRUE, TRUE), c(0.5, 1.5, 0.5, 0))
  sin <- cis_ccaa_estimar(c(TRUE, FALSE, TRUE), c(0.5, 1.5, 0.5))
  expect_equal(con_cero, sin)
  expect_equal(con_cero$entrevistas, 3L)
})
