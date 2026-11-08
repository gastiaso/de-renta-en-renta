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
  # Sin secciones de todas las provincias de la tabla (Huesca y Asturias), España no se compara
  parcial <- comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t)
  expect_false("Total Nacional" %in% parcial$detalle)
  t <- filter(t, !(nivel == "provincia" & codigo %in% c("22", "33")))
  c <- comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t)
  alquiler <- filter(c, id == "censo2021_alquiler")
  expect_setequal(alquiler$detalle, c("Total Nacional", "07 Balears, Illes", "04 Almería"))
  # Baleares: 60 / 200 en las secciones y en la tabla
  expect_equal(alquiler$calculado[alquiler$detalle == "07 Balears, Illes"], 30)
  expect_equal(alquiler$referencia[alquiler$detalle == "07 Balears, Illes"], 30)
  # Almería: con una sección en secreto, las completas suman 80 de 400; los 450 hogares que faltan
  # dan el intervalo [80 / 850, 530 / 850], y el 200 / 850 publicado cae dentro
  expect_equal(alquiler$calculado[alquiler$detalle == "04 Almería"], 100 * 200 / 850)
  expect_equal(alquiler$referencia[alquiler$detalle == "04 Almería"], 100 * 200 / 850)
  # Fuera del intervalo, el calculado es el extremo más cercano
  t2 <- mutate(t, alquiler = if_else(codigo == "07" & nivel == "provincia", 70, alquiler))
  a2 <- filter(comprobar_ine_censo2021(leer_ine_censo2021(censo_csv()), t2), id == "censo2021_alquiler")
  expect_equal(a2$calculado[a2$detalle == "07 Balears, Illes"], 30)
  expect_equal(a2$referencia[a2$detalle == "07 Balears, Illes"], 35)
  # Hogares: España y las provincias sin secciones en secreto
  principales <- filter(c, id == "censo2021_principales")
  expect_setequal(principales$detalle, c("Total Nacional", "07 Balears, Illes"))
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
               "Total Nacional;04 Balears, Illes;07 Balears, Illes;Viviendas turísticas;2024M11;60"),
             viv, useBytes = TRUE)
  pct <- tempfile(fileext = ".csv")
  writeLines(c("﻿Total Nacional;Comunidades y Ciudades Autónomas;Provincias;Periodo;Total",
               "Total Nacional;;;2024M11;6,07",
               "Total Nacional;01 Andalucía;;2024M11;2,75",
               "Total Nacional;01 Andalucía;04 Almería;2024M11;2,75",
               "Total Nacional;04 Balears, Illes;07 Balears, Illes;2024M11;12,00"),
             pct, useBytes = TRUE)
  c(viv, pct)
}

test_that("las tablas provinciales de VUT se leen sin las comunidades", {
  r <- vut_provincias_csv()
  p <- leer_ine_vut_provincias(r[1], r[2])
  expect_equal(sort(p$codigo), c("00", "04", "07"))
  expect_equal(p$viviendas[p$codigo == "00"], 82)
  expect_equal(p$porcentaje[p$codigo == "00"], 6.07)
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
