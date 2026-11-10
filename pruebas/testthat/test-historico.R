# Módulo histórico (F6, «máquina del tiempo»): lectores del Banco de España y de la Contabilidad
# Nacional, tabla del módulo, compuerta y datos de la web, con datos inventados.

# Tabla del Banco de España inventada, con el formato de sus CSV: seis filas de cabecera, un mes
# por fila, «_» sin dato, FUENTE y NOTAS al final, en latin1.
csv_bde <- function(meses, columnas, cierre = TRUE) {
  codigos <- names(columnas)
  cab <- rbind(c("C\u00d3DIGO DE LA SERIE", codigos), c("N\u00daMERO SECUENCIAL", seq_along(codigos)),
               c("ALIAS DE LA SERIE", paste0("X.", seq_along(codigos))), c("DESCRIPCI\u00d3N DE LA SERIE", codigos),
               c("DESCRIPCI\u00d3N DE LAS UNIDADES", rep("Porcentaje", length(codigos))),
               c("FRECUENCIA", rep("TRIMESTRAL", length(codigos))))
  cuerpo <- cbind(meses, do.call(cbind, columnas))
  pie <- rbind(c("FUENTE", rep("Banco de Espa\u00f1a", length(codigos))), c("NOTAS", rep("", length(codigos))))
  todo <- rbind(cab, cuerpo, if (cierre) pie)
  ruta <- tempfile(fileext = ".csv")
  lineas <- apply(todo, 1, function(f) paste0('"', f, '"', collapse = ","))
  con <- file(ruta, open = "w", encoding = "latin1")
  writeLines(lineas, con)
  close(con)
  ruta
}

meses_de <- function(anios) as.vector(t(outer(anios, c("ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"),
                                             function(a, m) paste(m, a))))

test_that("hist_leer_bde lee c\u00f3digos, meses y huecos y detecta la descarga cortada", {
  meses <- meses_de(1986:1987)
  trim <- ifelse(grepl("^(MAR|JUN|SEP|DIC)", meses), sprintf("%.2f", seq_along(meses) / 10), "_")
  ruta <- csv_bde(meses, list(A = trim, B = rep("_", length(meses)), A = rep("9", length(meses))))
  d <- hist_leer_bde(ruta, "A")
  expect_equal(nrow(d), 24L)
  expect_equal(d$valor[d$anio == 1986 & d$mes == 3], 0.3)          # la primera columna del c\u00f3digo repetido
  expect_true(is.na(d$valor[d$anio == 1986 & d$mes == 1]))
  expect_error(hist_leer_bde(ruta, "Z"), "no est")
  cortada <- csv_bde(meses, list(A = trim), cierre = FALSE)
  expect_error(hist_leer_bde(cortada, "A"), "cortada")
})

test_that("hist_leer_bde_tablas: trimestres, desde 1987 y del primer dato al \u00faltimo", {
  meses <- meses_de(1986:1988)
  trim <- ifelse(grepl("^(MAR|JUN|SEP|DIC)", meses), "5.5", "_")
  trim[meses == "DIC 1988"] <- "_"                                 # el \u00faltimo trimestre, sin dato
  trim[meses == "JUN 1987"] <- "_"                                 # un hueco intermedio
  mens <- rep("3.25", length(meses))
  si <- csv_bde(meses, list(T1 = trim))
  be <- csv_bde(meses, list(M1 = mens))
  series <- tibble::tribble(~serie, ~tabla, ~codigo, ~frecuencia, ~unidad, ~fuente,
                            "anios_renta", "si", "T1", "trimestral", "anios", "bde_accesibilidad",
                            "mibor_euribor", "be", "M1", "mensual", "porcentaje", "bde_tipos_referencia")
  x <- hist_leer_bde_tablas(c(si = si, be = be), series, desde = 1987L)
  a <- x[x$serie == "anios_renta", ]
  expect_equal(paste(a$anio, a$subperiodo), c("1987 1", "1987 2", "1987 3", "1987 4", "1988 1", "1988 2", "1988 3"))
  expect_equal(sum(is.na(a$valor)), 1L)
  expect_equal(names(x), HIST_COLUMNAS)
  m <- x[x$serie == "mibor_euribor", ]
  expect_equal(nrow(m), 24L)
  expect_equal(range(m$subperiodo), c(1L, 12L))
  # Una serie trimestral con cifras fuera de fin de trimestre no se acepta
  mal <- csv_bde(meses, list(T1 = rep("1", length(meses))))
  expect_error(hist_leer_bde_tablas(c(si = mal, be = be), series[1, ]), "fuera de fin de trimestre")
})

# Contabilidad Nacional inventada: total y dos ramas A10 (y una A21, que se deja fuera)
csv_cne <- function(empleo = FALSE) {
  ruta <- tempfile(fileext = ".csv")
  if (!empleo) {
    filas <- c("Agregados macroecon\u00f3micos;Total CNAE;CNAE Agrupaci\u00f3n A10;CNAE Agrupaci\u00f3n A21;CNAE Agrupaci\u00f3n A64;Periodo;Total",
               "Sueldos y salarios;Total CNAE;;;;1996;1.100,5", "Sueldos y salarios;Total CNAE;;;;1995;1.000",
               "Sueldos y salarios;Total CNAE;A Agricultura;;;1996;100,5", "Sueldos y salarios;Total CNAE;C Industria;;;1996;1.000",
               "Sueldos y salarios;Total CNAE;A Agricultura;;;1995;100", "Sueldos y salarios;Total CNAE;C Industria;;;1995;900",
               "Sueldos y salarios;Total CNAE;C Industria;C1 Alimentos;;1995;50",
               "Remuneraci\u00f3n de los asalariados;Total CNAE;;;;1996;1.400,5", "Remuneraci\u00f3n de los asalariados;Total CNAE;;;;1995;1.300",
               "Cotizaciones sociales a cargo de los empleadores;Total CNAE;;;;1996;300",
               "Cotizaciones sociales a cargo de los empleadores;Total CNAE;;;;1995;300")
  } else {
    filas <- c("Agregados de empleo;Situacion profesional;Total CNAE;CNAE Agrupaci\u00f3n A10;CNAE Agrupaci\u00f3n A21;CNAE Agrupaci\u00f3n A64;Periodo;Total",
               "Personas;Asalariados;Total CNAE;;;;1995;50", "Personas;Asalariados;Total CNAE;;;;1996;55",
               "Personas;Asalariados;Total CNAE;A Agricultura;;;1995;10", "Personas;Asalariados;Total CNAE;C Industria;;;1995;40",
               "Personas;Asalariados;Total CNAE;A Agricultura;;;1996;10", "Personas;Asalariados;Total CNAE;C Industria;;;1996;45",
               "Personas;Total;Total CNAE;;;;1995;80")
  }
  writeLines(enc2utf8(filas), ruta, useBytes = TRUE)
  ruta
}

test_that("CNE: lectura, sueldo por asalariado y compuerta de sumas", {
  ag <- hist_leer_ine_cne(csv_cne())
  em <- hist_leer_ine_cne(csv_cne(empleo = TRUE))
  expect_false(any(ag$valor == 50))                                 # la rama A21 queda fuera
  expect_equal(sort(unique(ag$rama)), c("A", "C", "total"))
  s <- hist_sueldo_asalariado(ag, em)
  expect_equal(s$anio, c(1995L, 1996L))
  expect_equal(s$valor, c(1000 * 1000 / 50, 1100.5 * 1000 / 55))   # millones / miles -> euros
  expect_equal(s$subperiodo, c(0L, 0L))
  com <- hist_comprobar_ine_cne(ag, em)
  expect_equal(com$calculado, c(0, 0, 0))
  ag$valor[ag$medida == "Sueldos y salarios" & ag$rama == "A" & ag$anio == 1995] <- 90
  expect_equal(hist_comprobar_ine_cne(ag, em)$calculado[2], 10)
})

# Tabla del módulo inventada: las seis series de España y una comunidad del valor tasado
historico_prueba <- function() {
  trim <- function(serie, valores, desde = 1987L, unidad = "anios", fuente = "bde_accesibilidad", geo = "00", nivel = "nacional") {
    k <- seq_along(valores) - 1L
    tibble::tibble(serie = serie, geo_id = geo, nivel = nivel, frecuencia = "trimestral", anio = desde + k %/% 4L,
                   subperiodo = k %% 4L + 1L, valor = valores, unidad = unidad, fuente = fuente, codigo = "X")
  }
  mens <- function(serie, valores, desde = 1987L) {
    k <- seq_along(valores) - 1L
    tibble::tibble(serie = serie, geo_id = "00", nivel = "nacional", frecuencia = "mensual", anio = desde + k %/% 12L,
                   subperiodo = k %% 12L + 1L, valor = valores, unidad = "porcentaje", fuente = "bde_tipos_referencia", codigo = "X")
  }
  bde <- dplyr::bind_rows(
    trim("anios_renta", c(2.9, 3.0, 3.1, 3.3, 4.0, 4.3, 4.2, 4.1)),
    trim("esfuerzo_teorico", c(42, 45, 48, 52, 60, 72.47, 70, 69), unidad = "porcentaje"),
    mens("tipo_hipotecas", c(15, 16, 16.9, 16.5, 16, 15)),
    mens("mibor_euribor", c(12, 13, 16.43, 15, 14, 13, 12, 11, 10, 9, 8, 7)),
    trim("valor_tasado_bde", c(670.8, 686, 682.6, 692.7), desde = 1995L, unidad = "euros_m2")
  )
  vt <- dplyr::bind_rows(
    trim("valor_tasado", c(670.8, 686, 682.6, 692.7), desde = 1995L, unidad = "euros_m2", fuente = "mivau_valor_tasado"),
    trim("valor_tasado", c(500, 510, NA, 530), desde = 1995L, unidad = "euros_m2", fuente = "mivau_valor_tasado", geo = "01", nivel = "ccaa")
  )
  sueldo <- tibble::tibble(serie = "sueldo_asalariado", geo_id = "00", nivel = "nacional", frecuencia = "anual", anio = 1995:1997,
                           subperiodo = 0L, valor = c(15634.9, 16000, 16500), unidad = "euros_anio", fuente = "ine_cne", codigo = "X")
  versiones <- c(bde_accesibilidad = "2026-11-10", bde_tipos_referencia = "2026-11-10", mivau_valor_tasado = "2026-11-09",
                 ine_cne = "2026-11-10")
  list(bde = bde, historico = hist_armar(bde, vt, sueldo, versiones))
}

test_that("hist_completar rellena los periodos que faltan y hist_armar quita las series de la compuerta", {
  x <- historico_prueba()
  h <- x$historico
  expect_equal(names(h), HIST_COLUMNAS_TABLA)
  expect_false("valor_tasado_bde" %in% h$serie)
  hueco <- tibble::tibble(serie = "s", geo_id = "00", nivel = "nacional", frecuencia = "trimestral", anio = c(2000L, 2001L),
                          subperiodo = c(4L, 2L), valor = c(1, 2), unidad = "u", fuente = "f", codigo = "c")
  completo <- hist_completar(hueco)
  expect_equal(paste(completo$anio, completo$subperiodo), c("2000 4", "2001 1", "2001 2"))
  expect_true(is.na(completo$valor[2]))
  expect_equal(h$version[h$serie == "sueldo_asalariado"][1], "2026-11-10")
  expect_error(hist_armar(x$bde, NULL, NULL, c(bde_accesibilidad = "x")), "sin versi")
})

test_that("periodos, valores en un periodo y extremos", {
  h <- historico_prueba()$historico
  expect_equal(hist_periodo("1987-T2")[c("anio", "subperiodo")], list(anio = 1987L, subperiodo = 2L))
  expect_equal(hist_periodo("2026-08")$frecuencia, "mensual")
  expect_null(hist_periodo("1987-T5"))
  expect_equal(hist_valor_en(h, "anios_renta", "00", "1987"), mean(c(2.9, 3.0, 3.1, 3.3)))
  expect_equal(hist_valor_en(h, "esfuerzo_teorico", "00", "1988-T2"), 72.47)
  expect_true(is.na(hist_valor_en(h, "tipo_hipotecas", "00", "1987")))   # a\u00f1o incompleto
  expect_true(is.na(hist_valor_en(h, "anios_renta", "00", "1987-03")))   # frecuencia distinta
  expect_equal(hist_extremo(h, "esfuerzo_teorico", "00", "maximo"), "1988-T2")
  expect_equal(hist_extremo(h, "anios_renta", "00", "minimo"), "1987-T1")
  expect_equal(hist_periodo_texto(1995L, 0L, "anual"), "1995")
})

fechas_prueba <- function() {
  tibble::tribble(
    ~id, ~serie, ~geo_id, ~periodo, ~tipo, ~texto_es, ~texto_en, ~fuente,
    "max_esfuerzo", "esfuerzo_teorico", "00", "1988-T2", "maximo", "M\u00e1ximo", "Peak", "bde",
    "euro", "mibor_euribor", "00", "1987-05", "evento", "Algo", "Something", "bde",
    "rup", "mibor_euribor", "00", "1987-06", "ruptura", "Cambio", "Change", "bde"
  )
}
referencias_prueba <- function() {
  tibble::tribble(
    ~id, ~serie, ~geo_id, ~periodo, ~valor, ~comparacion, ~compuerta, ~fuente, ~fecha,
    "a", "anios_renta", "00", "1987", 3.1, "igual", "hist_publicadas", "pdf", "2026-11-05",
    "b", "esfuerzo_teorico", "00", "1988-T2", 72, "maximo", "hist_prensa", "prensa", "2023",
    "c", "anios_renta", "00", "1987-T1", 3, "menor", "hist_prensa", "prensa", "2023",
    "d", "anios_renta", "00", "1988-T4", 7.6, "igual", "ninguna", "prensa", "2023",
    "e", "valor_tasado_bde", "00", "1995", 683, "igual", "hist_publicadas_enteras", "pdf", "2026-11-05"
  )
}
rupturas_prueba <- function() {
  tibble::tibble(id = c("rup", "otra"), fuente = c("bde_tipos_referencia", "ine_ecv"), indicador = c("historico", "22"),
                 anio = c("1987", "2013"), descripcion = "d", tratamiento = "t", estado = "aplicado")
}
territorios_prueba <- function() {
  tibble::tibble(nivel = c("ccaa", "provincia", "provincia"), codigo = c("01", "04", "11"), nombre = c("A", "B", "C"),
                 superior = c(NA, "01", "01"), secciones = 1L)
}
trim_mivau <- function() {
  tibble::tibble(nivel = "provincia", geo_id = rep(c("04", "11"), each = 4), anio = 1995L, trimestre = rep(1:4, 2),
                 valor = c(400, 400, 400, 400, 600, 600, 600, 600), tasaciones = NA_real_)
}

test_that("la compuerta del m\u00f3dulo pasa con datos coherentes y falla donde debe", {
  x <- historico_prueba()
  h <- x$historico
  com <- hist_comprobar(h, x$bde, trim_mivau(), territorios_prueba(), fechas_prueba(), referencias_prueba(), rupturas_prueba())
  ref <- tibble::tibble(id = c("hist_series", "hist_publicadas", "hist_publicadas_enteras", "hist_prensa", "hist_fechas",
                               "hist_valor_tasado_bde", "hist_valor_tasado_ccaa"),
                        tolerancia = c("exacto", "\u00b10,05", "\u00b10,5", "\u00b10,5", "exacto", "\u00b10,1", "exacto"),
                        tipo = c(rep("bloqueo", 6), "alerta"))
  # Con 4 trimestres comunes, la comparaci\u00f3n con el Banco de Espa\u00f1a no se da por buena
  expect_true(is.na(com$calculado[com$id == "hist_valor_tasado_bde"]))
  com <- com[com$id != "hist_valor_tasado_bde", ]
  expect_warning(v <- validar_referencias(com, ref), "Alertas")     # la comunidad con un trimestre sin cifra
  expect_true(all(v$correcto[v$tipo == "bloqueo"]))
  expect_equal(sum(com$id == "hist_prensa"), 2L)                    # la \u00abninguna\u00bb no se comprueba
  # Un m\u00e1ximo que no est\u00e1 donde dice la fecha clave, o una ruptura sin fila
  f <- fechas_prueba()
  f$periodo[1] <- "1988-T1"
  mal <- hist_comprobar(h, x$bde, trim_mivau(), territorios_prueba(), f, referencias_prueba(), rupturas_prueba()[2, ])
  expect_equal(sum(mal$calculado[mal$id == "hist_fechas"]), 2)
  # Una cifra publicada que no cuadra
  r <- referencias_prueba()
  r$valor[1] <- 3.3
  mal <- hist_comprobar(h, x$bde, trim_mivau(), territorios_prueba(), fechas_prueba(), r, rupturas_prueba())
  expect_error(validar_referencias(mal[mal$id == "hist_publicadas", ], ref), "no pasa")
})

test_that("datos de la web: ida y vuelta, y la compuerta detecta una cifra cambiada", {
  h <- historico_prueba()$historico
  dir <- tempfile("web")
  ccaa <- tibble::tibble(codigo = "01", nombre_ine = "Andaluc\u00eda", nuts2 = "ES61")
  ruta <- hist_exportar_web(h, fechas_prueba(), rupturas_prueba(), ccaa, dir_web = dir, fecha = "2026-11-10")
  x <- jsonlite::read_json(ruta)
  expect_equal(x$series$anios_renta$escala, 100)
  expect_equal(unlist(x$series$anios_renta$territorios$`00`$inicio), c(1987, 1))
  expect_equal(x$series$anios_renta$territorios$`00`$v[[1]], 290)
  expect_null(x$series$valor_tasado$territorios$`01`$v[[3]])
  expect_equal(unlist(x$series$sueldo_asalariado$territorios$`00`$inicio), c(1995, 0))
  expect_equal(unlist(x$rupturas), "rup")
  expect_equal(x$territorios$`01`, "Andaluc\u00eda")
  com <- hist_comprobar_web(h, fechas_prueba(), rupturas_prueba(), dir_web = dir)
  expect_equal(sum(com$calculado), 0)
  x$series$esfuerzo_teorico$territorios$`00`$v[[2]] <- 4566
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, null = "null")
  com <- hist_comprobar_web(h, fechas_prueba(), rupturas_prueba(), dir_web = dir)
  expect_equal(com$calculado[com$detalle == "esfuerzo_teorico"], 1)
})

test_that("valor tasado de las comunidades: solo se compara con sus provincias si est\u00e1n todas", {
  x <- historico_prueba()
  vt <- trim_mivau()
  vt$valor[vt$geo_id == "11" & vt$trimestre == 1L] <- NA         # falta una provincia: no se compara
  vt$valor[vt$geo_id == "04" & vt$trimestre == 2L] <- 520           # 510 queda por debajo de 520 y 600
  com <- hist_comprobar(x$historico, x$bde, vt, territorios_prueba(), fechas_prueba(), referencias_prueba(), rupturas_prueba())
  expect_equal(com$calculado[com$id == "hist_valor_tasado_ccaa"], 2)   # el trimestre 2 fuera y el 3 sin cifra
})

test_that("descargas cortadas: el CSV del INE sin la \u00faltima fila entera y la tabla del Banco de Espa\u00f1a sin cierre", {
  entero <- csv_cne()
  expect_true(hist_csv_ine_entero(entero))
  texto <- readBin(entero, "raw", file.size(entero))
  cortado <- tempfile(fileext = ".csv")
  writeBin(texto[seq_len(length(texto) - 12L)], cortado)            # a mitad de la \u00faltima fila
  expect_false(hist_csv_ine_entero(cortado))
  meses <- meses_de(1987)
  expect_true(hist_csv_bde_entero(csv_bde(meses, list(A = rep("1", 12)))))
  expect_false(hist_csv_bde_entero(csv_bde(meses, list(A = rep("1", 12)), cierre = FALSE)))
  # Tras tres intentos cortados, se borra el fichero y se para
  destino <- tempfile(fileext = ".csv")
  file.copy(cortado, destino)
  expect_error(suppressWarnings(hist_descargar_entera("http://127.0.0.1:9/no", destino, hist_csv_ine_entero)), "cortada")
  expect_false(file.exists(destino))
})
