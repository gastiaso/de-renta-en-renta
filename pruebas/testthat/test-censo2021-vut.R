# Indicadores 18 (Censo 2021, hogares en alquiler) y 19 (viviendas de uso turístico).
# R/fuente_ine_censo2021.R y R/fuente_ine_vut.R. Datos inventados.

vocabulario_prueba <- tibble::tibble(
  grupo = c("corte", "corte", "mes", "mes", "mes", "mes"),
  clave = c("total", "mes", "M02", "M05", "M08", "M11")
)

censo_csv <- function() {
  ruta <- tempfile(fileext = ".csv")
  writeLines(c(
    "ccaa,cpro,cmun,dist,secc,t1_1,t18_1,t19_1,t19_2,t20_1,t20_2,t20_3,t21_1",
    "01,04,013,01,001,1000,500,400,100,300,80,20,400",
    "01,04,013,01,002,800,300,250,50,200,,30,250",
    "01,04,013,01,003,0,10,0,10,0,0,0,0",
    "04,07,040,02,010,600,400,200,200,120,60,20,200"
  ), ruta)
  ruta
}

test_that("el Censo 2021 se lee con códigos de 10 dígitos y celdas sin número en NA", {
  censo <- leer_ine_censo2021(censo_csv())
  expect_equal(censo$seccion, c("0401301001", "0401301002", "0401301003", "0704002010"))
  expect_equal(censo$alquiler, c(80, NA, 0, 60))
  expect_equal(censo$principales[1], 400)
  expect_equal(nrow(leer_ine_censo2021(censo_csv(), ambito = "07")), 1L)
  # Con el vector de descargar_ine_censo2021() (CSV y diccionario) toma el CSV
  expect_equal(nrow(leer_ine_censo2021(c(censo_csv(), "diccionario.xlsx"))), 4L)
})

test_that("el indicador 18 distingue dato, secreto y ausente", {
  larga <- armonizar_ine_censo2021(leer_ine_censo2021(censo_csv()), version = "2023-06-30")
  expect_equal(larga$estado, c("dato", "secreto", "ausente", "dato"))
  expect_equal(larga$valor, c(20, NA, NA, 30))
  expect_true(all(larga$anio == 2021L & larga$corte == "total" & larga$grupo == "total"))
  expect_silent(validar_tabla_larga(larga, vocabulario = vocabulario_prueba))
})

test_that("las etiquetas del INE se reparten entre España, comunidades y provincias", {
  n <- nivel_territorios_ine(c("Total Nacional", "01 Andalucía", "04 Almería", "41 Sevilla",
                               "02 Aragón", "22 Huesca", "03 Asturias, Principado de", "33 Asturias",
                               "04 Balears, Illes", "07 Balears, Illes"))
  expect_equal(n$nivel, c("nacional", "ccaa", "provincia", "provincia", "ccaa", "provincia",
                          "ccaa", "provincia", "ccaa", "provincia"))
  expect_equal(n$codigo[c(1, 9, 10)], c("00", "04", "07"))
  expect_equal(n$ccaa, c(NA, "01", "01", "01", "02", "02", "03", "03", "04", "04"))
})

test_that("Ceuta y Melilla salen como comunidad (18, 19) y como provincia (51, 52) aunque Granada sea la 18", {
  ccaa <- sprintf("%02d Comunidad %d", 1:19, 1:19)
  ccaa[18:19] <- c("18 Ceuta", "19 Melilla")
  provincias <- c(list("18 Granada"), as.list(sprintf("%02d Provincia", 20:35)), list("51 Ceuta", "52 Melilla"))
  etiquetas <- c("Total Nacional", unlist(Map(c, ccaa, provincias)))
  n <- nivel_territorios_ine(etiquetas)
  expect_equal(sum(n$nivel == "ccaa"), 19L)
  expect_equal(sum(n$nivel == "provincia"), 19L)
  de <- function(t, col) n[[col]][n$territorio == t]
  expect_equal(c(de("18 Granada", "nivel"), de("18 Granada", "ccaa")), c("provincia", "01"))
  expect_equal(c(de("18 Ceuta", "nivel"), de("18 Ceuta", "codigo")), c("ccaa", "18"))
  expect_equal(c(de("51 Ceuta", "nivel"), de("51 Ceuta", "ccaa")), c("provincia", "18"))
  expect_equal(c(de("52 Melilla", "nivel"), de("52 Melilla", "ccaa")), c("provincia", "19"))
})

test_that("los recuentos provinciales se suman a comunidades completas y a España", {
  mapa <- tibble::tibble(codigo = c("04", "41", "07", "22"), ccaa = c("01", "01", "04", "02"))
  d <- tibble::tibble(codigo = c("04", "41", "07"), a = c(1, 2, 10), b = c(5, 5, 5))
  s <- sumar_territorios_ine(d, mapa)
  expect_equal(s$nivel, c("provincia", "provincia", "provincia", "ccaa", "ccaa"))
  expect_equal(s$codigo[s$nivel == "ccaa"], c("01", "04"))            # Aragón (22) no está entera
  expect_equal(s$a[s$nivel == "ccaa"], c(3, 10))
  t <- sumar_territorios_ine(bind_rows(d, tibble::tibble(codigo = "22", a = 100, b = 0)), mapa)
  expect_equal(unlist(t[t$nivel == "nacional", c("codigo", "a", "b")], use.names = FALSE), c("00", "113", "15"))
  # Con periodos: una fila por territorio y periodo
  p <- sumar_territorios_ine(bind_rows(mutate(d, mes = "M05"), mutate(d, mes = "M11")), mapa, por = "mes")
  expect_equal(nrow(p), 10L)
})

tenencia_csv <- function() {
  ruta <- tempfile(fileext = ".csv")
  filas <- function(territorio, total, propiedad, alquiler, otro) {
    c(paste0(territorio, ";Total (régimen de tenencia);Total (tamaño de municipio);", total),
      paste0(territorio, ";Total (régimen de tenencia);Menos de 101 habitantes;1"),
      paste0(territorio, ";En propiedad;Total (tamaño de municipio);", propiedad),
      paste0(territorio, ";En alquiler;Total (tamaño de municipio);", alquiler),
      paste0(territorio, ";Otro régimen de tenencia;Total (tamaño de municipio);", otro))
  }
  writeLines(c("﻿Comunidad Autónoma y Provincia;Régimen de tenencia de la vivienda;Tamaño del municipio;Total",
               filas("Total Nacional", "1.050", "720", "260", "70"),
               filas("01 Andalucía", "850", "600", "200", "50"),
               filas("04 Almería", "850", "600", "200", "50"),
               filas("02 Aragón", "0", "0", "0", "0"),
               filas("22 Huesca", "0", "0", "0", "0"),
               filas("03 Asturias, Principado de", "0", "0", "0", "0"),
               filas("33 Asturias", "0", "0", "0", "0"),
               filas("04 Balears, Illes", "200", "120", "60", "20"),
               filas("07 Balears, Illes", "200", "120", "60", "20")), ruta, useBytes = TRUE)
  ruta
}

test_that("la tabla de tenencia del Censo se lee y la compuerta compara provincias y España", {
  t <- leer_ine_censo2021_tenencia(tenencia_csv())
  expect_equal(t$nivel, c("nacional", rep(c("ccaa", "provincia"), 4)))
  expect_equal(t$principales[1], 1050)
  expect_equal(t$alquiler[t$codigo == "04" & t$nivel == "provincia"], 200)
  expect_equal(t$alquiler[t$codigo == "04" & t$nivel == "ccaa"], 60)
  # Sin secciones de todas las provincias de la tabla (Huesca y Asturias), ni España ni sus
  # comunidades se comparan
  parcial <- comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t)
  expect_setequal(parcial$detalle[parcial$id == "censo2021_alquiler"],
                  c("01 Andalucía", "04 Almería", "04 Balears, Illes", "07 Balears, Illes"))
  t <- filter(t, !(nivel == "provincia" & codigo %in% c("22", "33")))
  c <- comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t)
  alquiler <- filter(c, id == "censo2021_alquiler")
  expect_setequal(alquiler$detalle, c("Total Nacional", "01 Andalucía", "04 Almería", "04 Balears, Illes",
                                      "07 Balears, Illes"))
  # Baleares: 60 / 200 en las secciones y en la tabla, como provincia y como comunidad
  expect_equal(alquiler$calculado[alquiler$detalle == "07 Balears, Illes"], 30)
  expect_equal(alquiler$referencia[alquiler$detalle == "07 Balears, Illes"], 30)
  expect_equal(alquiler$calculado[alquiler$detalle == "04 Balears, Illes"], 30)
  # Almería: con una sección en secreto, las completas suman 80 de 400; los 450 hogares que faltan
  # dan el intervalo [80 / 850, 530 / 850], y el 200 / 850 publicado cae dentro
  expect_equal(alquiler$calculado[alquiler$detalle == "04 Almería"], 100 * 200 / 850)
  expect_equal(alquiler$referencia[alquiler$detalle == "04 Almería"], 100 * 200 / 850)
  expect_equal(alquiler$calculado[alquiler$detalle == "01 Andalucía"], 100 * 200 / 850)
  # Fuera del intervalo, el calculado es el extremo más cercano
  t2 <- mutate(t, alquiler = if_else(codigo == "07" & nivel == "provincia", 70, alquiler))
  a2 <- filter(comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t2), id == "censo2021_alquiler")
  expect_equal(a2$calculado[a2$detalle == "07 Balears, Illes"], 30)
  expect_equal(a2$referencia[a2$detalle == "07 Balears, Illes"], 35)
  # Hogares: España y las comunidades y provincias sin secciones en secreto
  principales <- filter(c, id == "censo2021_principales")
  expect_setequal(principales$detalle, c("Total Nacional", "04 Balears, Illes", "07 Balears, Illes"))
  expect_equal(principales$calculado[principales$detalle == "07 Balears, Illes"], 0)
  expect_false("censo2021_seccionado" %in% c$id)
  # Con el seccionado: una sección del CSV fuera (Baleares) y dos del seccionado sin fila
  s <- comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t,
                               secciones_2021 = c("0401301001", "0401301002", "0401301003", "0401301004", "0401301005"))
  expect_equal(s$calculado[s$id == "censo2021_seccionado"], c(1, 2))
})

test_that("los periodos de VUT dan año y mes de referencia", {
  p <- periodo_vut(c("AGO2020", "FEB2024", "NOV2024", "MAY2026", "2024M08"))
  expect_equal(p$anio, c(2020L, 2024L, 2024L, 2026L, 2024L))
  expect_equal(p$mes, c("M08", "M02", "M11", "M05", "M08"))
})

hoja_vut <- function() {
  tibble::tibble(
    a = c("Tabla 5. Viviendas turísticas", NA, "CUSEC", "0401301001", "0401301002", "0704002010", "Fuente: INE"),
    b = c(NA, NA, "Viviendas turísticas", "12", ".", "40", NA),
    c = c(NA, NA, "Plazas", "48", ".", "160", NA),
    d = c(NA, NA, "Plazas por vivienda turística", "4", ".", "4", NA),
    e = c(NA, NA, "Porcentaje vivienda turística", "2.4", ".", "10", NA)
  )
}

test_that("la hoja de secciones de VUT se lee desde su cabecera", {
  v <- secciones_vut(hoja_vut(), "AGO2023")
  expect_equal(v$seccion, c("0401301001", "0401301002", "0704002010"))
  expect_equal(v$viviendas, c(12, NA, 40))
  expect_equal(v$porcentaje, c(2.4, NA, 10))
  expect_true(all(v$anio == 2023L & v$mes == "M08"))
  expect_equal(nrow(secciones_vut(hoja_vut(), "AGO2023", ambito = "04")), 2L)
  sin_cabecera <- hoja_vut()[-3, ]
  expect_error(secciones_vut(sin_cabecera, "AGO2023"), "cabecera")
})


# Seccionado de 2024 inventado y su paso a 2021:
#   0401301001 -> igual (1:1, mismo código); 0401301002 y 0401301004 -> 0401301002 (se juntan
#   enteras); 0401301003 -> igual (1:1, viviendas del Censo en secreto); 0704002010 -> igual y
#   0704002011 -> mitad a 0704002010 y mitad a 0704002012 (reparto). 0704002013 no recibe nada.
paso_vut <- tibble::tibble(
  origen   = c("0401301001", "0401301002", "0401301004", "0401301003", "0704002010", "0704002011", "0704002011"),
  destino  = c("0401301001", "0401301002", "0401301002", "0401301003", "0704002010", "0704002010", "0704002012"),
  portales = c(100L, 50L, 30L, 10L, 80L, 10L, 10L),
  metodo   = "callejero",
  fraccion = c(1, 1, 1, 1, 1, 0.5, 0.5)
)
censo_vut <- tibble::tibble(seccion = c("0401301001", "0401301002", "0401301003", "0704002010", "0704002012", "0704002013"),
                            viviendas = c(500, 300, NA, 400, 100, 50))
vut_2024 <- function(pct_1001 = "2.4") {
  bruto <- tibble::tibble(
    a = c("cusec", "0401301001", "0401301002", "0401301004", "0401301003", "0704002010", "0704002011", "0704002099"),
    b = c("vivienda turistica", "12", "6", "3", "1", "40", "20", "0"),
    c = c("plazas", "48", "24", "12", "4", "160", "80", "0"),
    d = c("Porcentaje vivienda turistica", pct_1001, "3", "3", NA, "10", "20", "0")
  )
  secciones_vut(bruto, "NOV2024")
}

test_that("el indicador 19 pasa al seccionado de 2021: copia el % 1:1 y rehace el resto con el Censo", {
  r <- reproyectar_ine_vut(vut_2024(), paso_vut, censo_vut, periodos = "NOV2024")
  de <- function(s, col) r[[col]][r$seccion == s]
  expect_equal(nrow(r), 6L)
  expect_equal(de("0401301001", "valor"), 2.4)               # % del INE
  expect_equal(de("0401301001", "estado"), "dato")
  expect_equal(de("0401301002", "viviendas"), 9)             # 6 + 3, enteras
  expect_equal(de("0401301002", "valor"), 100 * 9 / 300)
  expect_equal(de("0401301002", "estado"), "dato")
  expect_equal(de("0401301003", "estado"), "secreto")        # % protegido por el INE
  expect_true(is.na(de("0401301003", "valor")))
  expect_equal(de("0704002010", "viviendas"), 50)            # 40 + la mitad de 20
  expect_equal(de("0704002010", "valor"), 100 * 50 / 400)
  expect_equal(de("0704002010", "estado"), "estimado")
  expect_equal(de("0704002012", "valor"), 100 * 10 / 100)    # un solo origen, pero repartido
  expect_equal(de("0704002012", "estado"), "estimado")
  expect_equal(de("0704002013", "estado"), "ausente")
  expect_true(all(r$anio == 2024L & r$mes == "M11"))
})

test_that("el indicador 19 lleva el mes en corte y grupo y pasa la validación de la tabla larga", {
  r <- reproyectar_ine_vut(bind_rows(vut_2024(), mutate(vut_2024(), periodo = "MAY2025", anio = 2025L, mes = "M05")),
                           paso_vut, censo_vut, periodos = c("NOV2024", "MAY2025"))
  larga <- armonizar_ine_vut(r, version = "2026-06-24")
  expect_equal(unique(larga$corte), "mes")
  expect_setequal(unique(larga$grupo), c("M11", "M05"))
  expect_equal(nrow(larga), 12L)
  expect_silent(validar_tabla_larga(larga, vocabulario = vocabulario_prueba))
  expect_error(validar_tabla_larga(larga, vocabulario = filter(vocabulario_prueba, clave != "M11")), "Grupo fuera")
})

vut_provincias_csv <- function() {
  viv <- tempfile(fileext = ".csv")
  writeLines(c("﻿Total Nacional;Comunidades y Ciudades Autónomas;Provincias;Viviendas y plazas;Periodo;Total",
               "Total Nacional;;;Viviendas turísticas;2024M11;82",
               "Total Nacional;;;Plazas;2024M11;328",
               "Total Nacional;01 Andalucía;;Viviendas turísticas;2024M11;22",
               "Total Nacional;01 Andalucía;04 Almería;Viviendas turísticas;2024M11;22",
               "Total Nacional;04 Balears, Illes;;Viviendas turísticas;2024M11;60",
               "Total Nacional;04 Balears, Illes;07 Balears, Illes;Viviendas turísticas;2024M11;60"),
             viv, useBytes = TRUE)
  pct <- tempfile(fileext = ".csv")
  writeLines(c("﻿Total Nacional;Comunidades y Ciudades Autónomas;Provincias;Periodo;Total",
               "Total Nacional;;;2024M11;6,07",
               "Total Nacional;01 Andalucía;;2024M11;2,75",
               "Total Nacional;01 Andalucía;04 Almería;2024M11;2,75",
               "Total Nacional;04 Balears, Illes;;2024M11;12,00",
               "Total Nacional;04 Balears, Illes;07 Balears, Illes;2024M11;12,00"),
             pct, useBytes = TRUE)
  c(viv, pct)
}

test_that("las tablas provinciales de VUT se leen con España, comunidades y provincias", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  expect_equal(p$nivel, c("nacional", "ccaa", "provincia", "ccaa", "provincia"))
  expect_equal(p$codigo, c("00", "01", "04", "04", "07"))
  expect_equal(p$ccaa, c(NA, "01", "01", "04", "04"))
  expect_equal(p$territorio[p$nivel == "ccaa"], c("01 Andalucía", "04 Balears, Illes"))
  expect_equal(p$viviendas[p$codigo == "00"], 82)
  expect_equal(p$porcentaje[p$codigo == "00"], 6.07)
  expect_equal(p$viviendas[p$codigo == "04"], c(22, 60))      # Almería (provincia) y Baleares (comunidad)
  expect_true(all(p$anio == 2024L & p$mes == "M11"))
})

test_that("la compuerta de VUT suma secciones, mira el seccionado y el denominador", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  s2024 <- unique(paso_vut$origen)
  comprobar <- function(v, secciones = s2024) {
    comprobar_ine_vut(v, reproyectar_ine_vut(v, paso_vut, censo_vut, periodos = "NOV2024"), p, censo_vut,
                      secciones, paso_vut)
  }
  c <- comprobar(vut_2024())
  expect_equal(c$calculado[c$id == "vut_viviendas_provincia"], c(0, 0, 0))
  expect_equal(c$calculado[c$id == "vut_paso_2021"], c(0, 0, 0))
  # El código antiguo sin viviendas turísticas no cuenta; una sección de 2024 que falta, sí
  expect_equal(c$calculado[c$id == "vut_seccionado"], 0)
  expect_equal(comprobar(vut_2024(), c(s2024, "0704002014"))$calculado[c$id == "vut_seccionado"], 1)
  # Denominador: en 0401301001 (1:1, mismo código) el INE da 12 / 500
  expect_equal(c$calculado[c$id == "vut_denominador"], 0)
  expect_false("vut_denominador_detalle" %in% c$id)
  d <- comprobar(vut_2024(pct_1001 = "2.5"))
  expect_equal(d$calculado[d$id == "vut_denominador_detalle"], 0.1)
  expect_equal(d$detalle[d$id == "vut_denominador_detalle"], "M11 0401301001")
})

# --- España (nivel nacional) ---------------------------------------------------------------

referencias_nacional <- tibble::tibble(
  id = c("censo2021_nacional", "vut_nacional_viviendas", "vut_nacional_porcentaje"),
  tolerancia = c("exacto", "exacto", "±0,02 puntos"), tipo = "bloqueo"
)

test_that("España del indicador 18 es la cifra publicada de la tabla 59523", {
  t <- leer_ine_censo2021_tenencia(tenencia_csv())
  n <- nacional_ine_censo2021(t, version = "2023-06-30")
  expect_equal(nrow(n), 1L)
  expect_equal(c(n$geo_id, n$nivel, n$estado, n$corte), c("00", "nacional", "dato", "total"))
  expect_equal(n$valor, 100 * 260 / 1050)
  expect_true(is.na(n$geo_ref))
  larga <- bind_rows(armonizar_ine_censo2021(leer_ine_censo2021(censo_csv()), version = "2023-06-30"), n)
  expect_silent(validar_tabla_larga(larga, vocabulario = vocabulario_prueba))
  expect_equal(nrow(nacional_ine_censo2021(filter(t, nivel != "nacional"), "x")), 0L)
})

test_that("la compuerta de España del Censo pondera provincias y comunidades de la misma tabla", {
  t <- leer_ine_censo2021_tenencia(tenencia_csv())
  censo <- leer_ine_censo2021(censo_csv())
  c <- filter(comprobar_ine_censo2021(censo, t), id == "censo2021_nacional")
  expect_equal(c$detalle, c("media ponderada de las comunidades", "media ponderada de las provincias"))
  # Provincias y comunidades suman 1.050 hogares y 260 en alquiler, como España
  expect_equal(c$calculado, rep(100 * 260 / 1050, 2))
  expect_equal(c$referencia, rep(100 * 260 / 1050, 2))
  expect_silent(validar_referencias(c, referencias_nacional))
  # España que no cuadra con sus provincias: la compuerta para
  t2 <- mutate(t, alquiler = if_else(nivel == "nacional", 270, alquiler))
  c2 <- filter(comprobar_ine_censo2021(censo, t2), id == "censo2021_nacional")
  expect_error(validar_referencias(c2, referencias_nacional), "compuerta")
  # Sin fila de España, referencia NA: tampoco pasa
  c3 <- filter(comprobar_ine_censo2021(censo, filter(t, nivel != "nacional")), id == "censo2021_nacional")
  expect_true(all(is.na(c3$referencia)))
  expect_error(validar_referencias(c3, referencias_nacional), "compuerta")
})

test_that("España del indicador 19 es el porcentaje publicado de la tabla 39365, en los periodos de las secciones", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  n <- nacional_ine_vut(p, version = "2026-06-24", periodos = c("NOV2024", "MAY2025"))
  expect_equal(n$geo_id, c("00", "00"))
  expect_equal(n$anio, c(2024L, 2025L))
  expect_equal(n$grupo, c("M11", "M05"))
  expect_equal(n$valor, c(6.07, NA))                   # mayo de 2025 no está en la tabla
  expect_equal(n$estado, c("dato", "ausente"))
  expect_true(all(n$corte == "mes" & n$nivel == "nacional" & is.na(n$geo_ref)))
  expect_silent(validar_tabla_larga(n, vocabulario = vocabulario_prueba))
})

test_that("la compuerta de España de VUT suma las provincias y pondera sus porcentajes con el Censo", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  # Porcentajes provinciales coherentes con el Censo inventado: Almería 22 / 800 (la sección en
  # secreto no pesa) y Baleares 60 / 550
  p <- mutate(p, porcentaje = if_else(codigo == "07", 100 * 60 / 550, porcentaje))
  c <- nacional_vut(p, censo_vut, periodos = "NOV2024")
  expect_equal(c$id, c("vut_nacional_viviendas", "vut_nacional_porcentaje"))
  expect_equal(c$calculado[1], 0)                                  # 22 + 60 = 82
  expect_equal(c$calculado[2], (2.75 * 800 + 100 * 60 / 550 * 550) / 1350)
  expect_equal(c$referencia[2], 6.07)
  expect_silent(validar_referencias(c, referencias_nacional))
  # Un porcentaje provincial que no cuadra con España se ve
  mal <- nacional_vut(mutate(p, porcentaje = if_else(codigo == "07", 12, porcentaje)), censo_vut, periodos = "NOV2024")
  expect_equal(mal$calculado[2], (2.75 * 800 + 12 * 550) / 1350)
  expect_error(validar_referencias(mal, referencias_nacional), "compuerta")
  # Un periodo sin cifra de España sale con NA y no pasa
  c2 <- nacional_vut(p, censo_vut, periodos = c("NOV2024", "MAY2025"))
  expect_true(is.na(c2$calculado[c2$detalle == "M05"]))
  expect_error(validar_referencias(c2, referencias_nacional), "compuerta")
  # Sin todas las provincias en el Censo (PROVINCIA), solo la suma de viviendas
  c3 <- nacional_vut(p, filter(censo_vut, startsWith(seccion, "04")), periodos = "NOV2024")
  expect_equal(c3$id, "vut_nacional_viviendas")
  # comprobar_ine_vut() las incluye
  v <- vut_2024()
  todo <- comprobar_ine_vut(v, reproyectar_ine_vut(v, paso_vut, censo_vut, periodos = "NOV2024"), p, censo_vut,
                            unique(paso_vut$origen), paso_vut, periodos = "NOV2024")
  expect_true(all(c("vut_nacional_viviendas", "vut_nacional_porcentaje") %in% todo$id))
})

# --- Comunidades y provincias ------------------------------------------------------------

referencias_territorios <- tibble::tibble(
  id = c("censo2021_alquiler", "vut_territorios"), tolerancia = c("±0,1 puntos", "±0,01 puntos"), tipo = "bloqueo"
)

test_that("comunidades y provincias del indicador 18 son las cifras publicadas de la tabla 59523", {
  t <- leer_ine_censo2021_tenencia(tenencia_csv())
  n <- territorios_ine_censo2021(t, version = "2023-06-30")
  expect_equal(nrow(n), 9L)                                  # España, 4 comunidades y 4 provincias
  expect_equal(as.vector(table(n$nivel)[c("nacional", "ccaa", "provincia")]), c(1L, 4L, 4L))
  de <- function(nivel, codigo, col) n[[col]][n$nivel == nivel & n$geo_id == codigo]
  expect_equal(de("provincia", "04", "valor"), 100 * 200 / 850)   # Almería
  expect_equal(de("ccaa", "04", "valor"), 30)                      # Baleares, con el mismo código
  expect_equal(de("ccaa", "02", "estado"), "ausente")              # Aragón: sin hogares en la tabla
  expect_true(all(is.na(n$geo_ref) & n$corte == "total"))
  larga <- bind_rows(armonizar_ine_censo2021(leer_ine_censo2021(censo_csv()), version = "2023-06-30"), n)
  expect_silent(validar_tabla_larga(larga, vocabulario = vocabulario_prueba))
  expect_equal(nacional_ine_censo2021(t, "x"), filter(territorios_ine_censo2021(t, "x"), nivel == "nacional"))
})

test_that("la compuerta del Censo para con una comunidad que no cuadra con sus secciones", {
  t <- filter(leer_ine_censo2021_tenencia(tenencia_csv()), !(nivel == "provincia" & codigo %in% c("22", "33")))
  censo <- leer_ine_censo2021(censo_csv())
  ok <- filter(comprobar_ine_censo2021(censo, t), id == "censo2021_alquiler")
  expect_silent(validar_referencias(ok, referencias_territorios))
  # Baleares como comunidad, 70 en alquiler de 200 (35 %) frente al 30 % de sus secciones
  mal <- mutate(t, alquiler = if_else(nivel == "ccaa" & codigo == "04", 70, alquiler))
  a <- filter(comprobar_ine_censo2021(censo, mal), id == "censo2021_alquiler")
  expect_equal(a$referencia[a$detalle == "04 Balears, Illes"], 35)
  expect_error(validar_referencias(a, referencias_territorios), "compuerta")
})

test_that("comunidades y provincias del indicador 19 son los porcentajes publicados de la tabla 39365", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  n <- territorios_ine_vut(p, version = "2026-06-24", periodos = c("NOV2024", "MAY2025"))
  expect_equal(nrow(n), 10L)                                 # 5 territorios por 2 periodos
  expect_equal(n$valor[n$nivel == "ccaa" & n$geo_id == "04" & n$grupo == "M11"], 12)
  expect_equal(n$valor[n$nivel == "provincia" & n$geo_id == "04" & n$grupo == "M11"], 2.75)
  expect_true(all(n$estado[n$grupo == "M05"] == "ausente"))  # mayo de 2025 no está en la tabla
  expect_true(all(n$corte == "mes" & is.na(n$geo_ref)))
  expect_silent(validar_tabla_larga(n, vocabulario = vocabulario_prueba))
  expect_equal(nacional_ine_vut(p, "x", "NOV2024"), filter(territorios_ine_vut(p, "x", "NOV2024"), nivel == "nacional"))
  # España sale aunque la tabla no la traiga
  sin_espana <- territorios_ine_vut(filter(p, nivel != "nacional"), "x", "NOV2024")
  expect_equal(sin_espana$estado[sin_espana$nivel == "nacional"], "ausente")
})

test_that("la compuerta de VUT compara comunidades y provincias con el cociente de las sumas de sus secciones", {
  r <- vut_provincias_csv()
  # Baleares (07 y comunidad 04): 60 viviendas turísticas / 550 viviendas, sin secciones en secreto:
  # 10,909 %, que el INE publicaría como 10,91
  p <- mutate(leer_ine_vut_provincias(r[1], r[2]), porcentaje = if_else(codigo %in% c("04", "07") & ccaa == "04", 10.91, porcentaje))
  v21 <- reproyectar_ine_vut(vut_2024(), paso_vut, censo_vut, periodos = "NOV2024")
  c <- territorios_vut(v21, p, periodos = "NOV2024")
  expect_setequal(c$detalle, c("M11 01 Andalucía", "M11 04 Almería", "M11 04 Balears, Illes", "M11 07 Balears, Illes"))
  baleares <- c[c$detalle == "M11 07 Balears, Illes", ]
  expect_equal(baleares$calculado, 100 * 60 / 550)
  expect_equal(baleares$referencia, 10.91)
  # Almería (y Andalucía): 22 viviendas turísticas (una en la sección en secreto) / 800; el 2,75
  # publicado no pasa del cociente
  expect_equal(c$calculado[c$detalle == "M11 04 Almería"], 2.75)
  expect_silent(validar_referencias(c, referencias_territorios))
  # Por encima del cociente no pasa; por debajo, con secciones en secreto, sí (solo hay cota superior)
  alto <- territorios_vut(v21, mutate(p, porcentaje = if_else(codigo == "04" & nivel == "provincia", 3, porcentaje)), "NOV2024")
  expect_equal(alto$calculado[alto$detalle == "M11 04 Almería"], 2.75)
  expect_error(validar_referencias(alto, referencias_territorios), "compuerta")
  bajo <- territorios_vut(v21, mutate(p, porcentaje = if_else(codigo == "04" & nivel == "provincia", 1, porcentaje)), "NOV2024")
  expect_silent(validar_referencias(bajo, referencias_territorios))
  # Sin secciones en secreto, las dos direcciones cuentan
  mal <- territorios_vut(v21, mutate(p, porcentaje = if_else(codigo == "07", 10.5, porcentaje)), "NOV2024")
  expect_error(validar_referencias(mal, referencias_territorios), "compuerta")
  # Con las secciones de una sola provincia (PROVINCIA), su comunidad entra solo si está entera
  solo_almeria <- territorios_vut(filter(v21, startsWith(seccion, "04")), p, "NOV2024")
  expect_setequal(solo_almeria$detalle, c("M11 01 Andalucía", "M11 04 Almería"))
  # comprobar_ine_vut() la incluye
  todo <- comprobar_ine_vut(vut_2024(), v21, p, censo_vut, unique(paso_vut$origen), paso_vut, periodos = "NOV2024")
  expect_equal(sum(todo$id == "vut_territorios"), 4L)
})
