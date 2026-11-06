# Tabla larga y armonización del ADRH (R/comun_exportar.R, R/fuente_ine_adrh.R)

fila <- function(...) {
  base <- list(geo_id = "2800101001", nivel = "sc", anio = 2020L, indicador = "renta_hogar", valor = 30000,
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
