# Tabla larga y armonización del ADRH (R/comun_exportar.R, R/fuente_ine_adrh.R)

fila <- function(...) {
  base <- list(geo_id = "2800101001", nivel = "sc", anio = 2020L, indicador = "renta_hogar",
               corte = "total", grupo = "total", valor = 30000,
               estado = "dato", fuente = "ine_adrh", geo_ref = "2021", version = "2026-11-06")
  tibble::as_tibble(utils::modifyList(base, list(...)))
}

test_that("la tabla larga rechaza códigos, estados y combinaciones incoherentes", {
  expect_silent(validar_tabla_larga(fila()))
  expect_error(validar_tabla_larga(fila(geo_id = "280010100")), "longitud")
  expect_error(validar_tabla_larga(fila(estado = "provisional")), "Estado")
  expect_error(validar_tabla_larga(fila(valor = NA_real_)), "vacío")
  expect_error(validar_tabla_larga(fila(estado = "secreto")), "secreto")
  expect_error(validar_tabla_larga(bind_rows(fila(), fila())), "repetidas")
  expect_error(validar_tabla_larga(fila(indicador = "otro"), indicadores = tibble::tibble(codigo = "renta_hogar")),
               "catálogo")
})

test_that("corte y grupo: «total» va en pareja, la clave los incluye y el vocabulario manda", {
  voc <- tibble::tibble(grupo = c("corte", "corte", "tenencia"), clave = c("total", "tenencia", "RENT_MKT"))
  desglose <- fila(corte = "tenencia", grupo = "RENT_MKT")
  expect_silent(validar_tabla_larga(bind_rows(fila(), desglose), vocabulario = voc))
  expect_error(validar_tabla_larga(fila(grupo = "RENT_MKT")), "descasados")
  expect_error(validar_tabla_larga(fila(corte = "tenencia")), "descasados")
  expect_error(validar_tabla_larga(fila(corte = NA_character_)), "vacío")
  expect_error(validar_tabla_larga(fila(corte = "edad", grupo = "Y16-29"), vocabulario = voc), "Corte fuera")
  expect_error(validar_tabla_larga(fila(corte = "tenencia", grupo = "OWN"), vocabulario = voc), "Grupo fuera")
  expect_error(validar_tabla_larga(bind_rows(desglose, desglose)), "repetidas")
})

ccaa_prueba <- tibble::tibble(codigo = c("13", "04"), nombre_ine = c("Madrid, Comunidad de", "Balears, Illes"),
                              nuts2 = c("ES30", "ES53"))

test_that("el módulo de acceso se lee en formato español y pasa a comunidades y nacional", {
  ruta <- tempfile(fileext = ".csv")
  writeLines(c("﻿Comunidad Autónoma;Razón principal;Total",
               "Total;Ha buscado vivienda activamente pero no se ha cambiado (%);7,6",
               "Total;Ha buscado vivienda activamente pero no se ha cambiado (miles);3.182,4",
               "Madrid, Comunidad de;Ha buscado vivienda activamente pero no se ha cambiado (%);10,2",
               "Madrid, Comunidad de;Ha buscado vivienda activamente pero no se ha cambiado (miles);2.000,0",
               "Balears, Illes;Ha buscado vivienda activamente pero no se ha cambiado (%);10,6",
               "Balears, Illes;Ha buscado vivienda activamente pero no se ha cambiado (miles);1.182,4"),
             ruta, useBytes = TRUE)
  m <- leer_ine_ecv_modulo(ruta)
  expect_equal(m$valor[2], 3182.4)
  expect_equal(comprobar_ine_ecv_modulo(m)$calculado, 0)
  # Tablas por edad (con sexo) y por tenencia: cortes de España y su total frente al de comunidades
  ruta_edad <- tempfile(fileext = ".csv")
  writeLines(c("Sexo;Edad;Razón principal;Total",
               "Ambos sexos;Total;Ha buscado vivienda activamente pero no se ha cambiado (%);7,6",
               "Ambos sexos;Total;Ha buscado vivienda activamente pero no se ha cambiado (miles);3.182,4",
               "Ambos sexos;De 16 a 29 años;Ha buscado vivienda activamente pero no se ha cambiado (%);9,6",
               "Hombres;Total;Ha buscado vivienda activamente pero no se ha cambiado (%);7,7",
               "Hombres;De 16 a 29 años;Ha buscado vivienda activamente pero no se ha cambiado (%);8,7"),
             ruta_edad, useBytes = TRUE)
  ruta_ten <- tempfile(fileext = ".csv")
  writeLines(c("Régimen;Razón principal;Total",
               "Total;Ha buscado vivienda activamente pero no se ha cambiado (miles);3.150,0",
               "Alquiler a precio de mercado;Ha buscado vivienda activamente pero no se ha cambiado (%);17,8"),
             ruta_ten, useBytes = TRUE)
  e <- leer_ine_ecv_modulo(ruta_edad); te <- leer_ine_ecv_modulo(ruta_ten)
  comp <- comprobar_ine_ecv_modulo(m, e, te)
  expect_equal(comp$calculado[2], 0)
  expect_equal(comp$calculado[3], 100 * (3150 - 3182.4) / 3182.4)
  cortes <- armonizar_ine_ecv_modulo_cortes(e, te, version = "prueba")
  expect_equal(paste(cortes$corte, cortes$grupo), c("edad Y16-29", "sexo M", "tenencia RENT_MKT"))
  expect_equal(cortes$valor, c(9.6, 7.7, 17.8))
  expect_silent(validar_tabla_larga(cortes))
  t <- armonizar_ine_ecv_modulo(m, ccaa_prueba, version = "prueba")
  expect_equal(t$geo_id, c("00", "13", "04"))
  expect_equal(t$nivel, c("nacional", "ccaa", "ccaa"))
  expect_silent(validar_tabla_larga(t))
})

test_that("la sobrecarga entra en la tabla larga: España con cortes, comunidades y cruces agrupados", {
  s <- tibble::tibble(anio = 2025L, indicador = "sobrecarga", umbral = 0.4,
                      corte = c("total", "region", "region", "tenencia"), grupo = c("TOTAL", "ES30", "ES53", "RENT_MKT"),
                      valor = c(7.2, 9.9, 6.4, 26.8), n_personas = c(60000L, 5000L, 3000L, 8000L))
  a <- tibble::tibble(anio_inicio = 2023L, anio_fin = 2025L, region = c("ES30", "ES53"), corte = "tenencia",
                      grupo = "RENT_MKT", valor = c(30.1, 35.2), n_personas = c(900L, 15L))
  t <- armonizar_sobrecarga_ecv(s, a, ccaa_prueba, version = "prueba")
  expect_equal(t$geo_id, c("00", "00", "13", "04", "13", "04"))
  expect_equal(paste(t$corte, t$grupo)[1:3], c("total total", "tenencia RENT_MKT", "total total"))
  expect_equal(unique(t$anio), 2025L)
  # Menos de 20 observaciones: no se publica
  expect_equal(t$estado[6], "secreto")
  expect_true(is.na(t$valor[6]))
  expect_silent(validar_tabla_larga(t))
})

test_that("la renta se lleva a 2021 con su estado: secreto, estimado y dato", {
  renta <- tibble::tribble(
    ~anio, ~nivel,      ~codigo,      ~indicador,         ~valor,
    2024L, "seccion",   "2800101001", "renta_persona",    10000,
    2024L, "seccion",   "2800101002", "renta_persona",    20000,
    2024L, "seccion",   "2800101001", "renta_hogar",      25000,
    2024L, "seccion",   "2800101002", "renta_hogar",      50000,
    2024L, "seccion",   "2800101001", "renta_uc_mediana", 15000,
    2024L, "municipio", "28001",      "renta_persona",    15000
  )
  pesos <- tibble::tibble(anio = 2024L, seccion = c("2800101001", "2800101002", "2800101003"),
                          poblacion = c(100, 300, 50), hogares = c(40, 120, 20))
  # 001 y 002 se juntan en 001 (2021); 003 (sin renta: secreto) pasa a 003
  tabla <- tibble::tibble(origen = c("2800101001", "2800101002", "2800101003"),
                          destino = c("2800101001", "2800101001", "2800101003"),
                          portales = c(30L, 1L, 5L), metodo = "callejero", fraccion = 1)
  t <- armonizar_ine_adrh(renta, pesos, list("2024" = tabla), version = "prueba")
  v <- function(g, ind) t[t$geo_id == g & t$indicador == ind & t$nivel == "sc", ]
  expect_equal(v("2800101001", "renta_persona")$valor, (10000 * 100 + 20000 * 300) / 400)
  expect_equal(v("2800101001", "renta_persona")$estado, "dato")
  expect_equal(v("2800101001", "renta_hogar")$valor, (25000 * 40 + 50000 * 120) / 160)
  # Mediana: 001 domina (30 de 31 portales) y se copia; como a 002 le falta, queda estimada
  expect_equal(v("2800101001", "renta_uc_mediana")$valor, 15000)
  expect_equal(v("2800101001", "renta_uc_mediana")$estado, "estimado")
  expect_equal(v("2800101003", "renta_persona")$estado, "secreto")
  expect_true(is.na(v("2800101003", "renta_persona")$valor))
  expect_equal(nrow(t[t$nivel == "municipio", ]), 1L)
  expect_silent(validar_tabla_larga(t))
})

test_that("los diccionarios se generan del inventario y conservan lo escrito a mano", {
  dir <- tempfile("i18n_")
  dir.create(dir)
  jsonlite::write_json(list(sitio = list(titulo = "Casilla")), file.path(dir, "es.json"), auto_unbox = TRUE)
  jsonlite::write_json(list(sitio = list(titulo = "Square")), file.path(dir, "en.json"), auto_unbox = TRUE)
  ind <- tibble::tibble(codigo = "sobrecarga", nombre_es = "Sobrecarga", nombre_en = "Overburden",
                        unidad_es = "%", unidad_en = "%", definicion_es = "d", definicion_en = "d",
                        calculo_es = "c", calculo_en = "c", lectura_es = "l", lectura_en = "l")
  fue <- tibble::tibble(id = "ine_ecv", nombre = "Encuesta", nombre_en = "Survey")
  voc <- tibble::tibble(grupo = "estado", clave = "dato", es = "Dato", en = "Value")
  rutas <- exportar_i18n(ind, fue, voc, dir)
  en <- jsonlite::read_json(rutas[2])
  expect_equal(en$sitio$titulo, "Square")
  expect_equal(en$indicadores$sobrecarga$nombre, "Overburden")
  expect_equal(en$vocabulario$estado$dato, "Value")
  expect_true(all(comprobar_i18n(rutas)$calculado == 0))
  # Una clave que solo está en un idioma se detecta
  jsonlite::write_json(c(jsonlite::read_json(rutas[1]), list(extra = "x")), rutas[1], auto_unbox = TRUE)
  expect_equal(comprobar_i18n(rutas)$calculado[1], 1)
})
