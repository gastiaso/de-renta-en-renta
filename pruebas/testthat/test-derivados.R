# Indicadores derivados 14, 15 y 21 y perfiles de las fichas (R/derivados.R). Datos inventados.

# SERPAVI en formato largo: dos secciones de Madrid (una en secreto), una de Álava, un municipio y
# una comunidad, en 2023 y 2024. Las filas de vivienda unifamiliar (VU) no deben usarse.
serpavi_largo <- function() {
  base <- tibble::tribble(
    ~geo_id,      ~nivel,      ~mes, ~m2, ~estado,
    "2800101001", "sc",        900,  15,  "dato",
    "2800101002", "sc",        NA,   NA,  "secreto",
    "0100101001", "sc",        700,  10,  "dato",
    "28001",      "municipio", 850,  14,  "dato",
    "13",         "ccaa",      800,  12,  "dato"
  )
  bind_rows(lapply(c(2023L, 2024L), function(a) bind_rows(
    transmute(base, geo_id, nivel, anio = a, indicador = "alquiler_mes", corte = "tipologia", grupo = "VC", valor = mes, estado),
    transmute(base, geo_id, nivel, anio = a, indicador = "alquiler_m2", corte = "tipologia", grupo = "VC", valor = m2, estado),
    transmute(base, geo_id, nivel, anio = a, indicador = "alquiler_m2", corte = "tipologia", grupo = "VU", valor = 1, estado = "dato"),
    transmute(base, geo_id, nivel, anio = a, indicador = "alquiler_m2", corte = "tipologia_p25", grupo = "VC", valor = 1, estado = "dato")
  ))) |>
    mutate(fuente = "mivau_serpavi", geo_ref = "2021", version = "2026-11-06")
}

# ADRH: renta por hogar de 2022 a 2024 (2022 no tiene alquiler) y una renta por persona que no se usa.
adrh_largo <- function() {
  base <- tibble::tribble(
    ~geo_id,      ~nivel,      ~valor, ~estado,
    "2800101001", "sc",        36000,  "dato",
    "2800101002", "sc",        30000,  "dato",
    "0100101001", "sc",        40000,  "estimado",
    "28001",      "municipio", 34000,  "dato"
  )
  bind_rows(lapply(2022:2024, function(a) bind_rows(
    mutate(base, anio = a, indicador = "renta_hogar"),
    mutate(base, anio = a, indicador = "renta_persona", valor = 1)
  ))) |>
    mutate(corte = "total", grupo = "total", fuente = "ine_adrh", geo_ref = "2021", version = "2026-11-07")
}

mochila_inventada <- tibble::tibble(provincia = c("Madrid, Comunidad de", "Albacete"), neto_mensual = c(1500, 1200))
provincias_inventadas <- tibble::tibble(provincia = c("01", "02", "28"), nombre_ine = c("Araba/Álava", "Albacete", "Madrid"),
                                        nombre_aeat = c(NA, "Albacete", "Madrid, Comunidad de"))

inventario <- function(f) readr::read_csv(file.path("..", "..", "inventario", f), show_col_types = FALSE)

fila <- function(x, geo, a, ind, grupo = "total") {
  filter(x, geo_id == geo, anio == a, indicador == ind, grupo == !!grupo)
}

test_that("el peor estado manda y un término que falta cuenta como ausente", {
  expect_equal(peor_estado(c("dato", "estimado", "dato"), c("secreto", "dato", NA)), c("secreto", "estimado", "ausente"))
  expect_error(peor_estado("provisional"), "desconocido")
})

test_that("perfiles: tartera con el SMI de cada año, mochila por provincia y llave por sección", {
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, adrh_largo(), anio_mochila = 2024L)
  tartera <- filter(p, ficha == "tartera")
  expect_equal(tartera$anio, 2015:2026)
  neto <- function(a) tartera$ingreso[tartera$anio == a]
  expect_equal(neto(2015L), 648.6 * 14 * (1 - 0.0635) / 12)
  expect_equal(neto(2021L), (950 * 8 + 965 * 4) / 12 * 14 * (1 - 0.0635) / 12)   # pregunta 18: 955 € ponderados
  expect_equal(neto(2023L), 1080 * 14 * (1 - 0.0645) / 12)                       # con el MEI (0,10 %)
  expect_equal(c(neto(2024L), neto(2026L)), c(1134 * 14 * (1 - 0.0647) / 12, 1221 * 14 * (1 - 0.065) / 12))
  expect_equal(round(neto(2026L)), 1332)
  expect_true(all(!is.na(SMI_FICHAS$norma) & !is.na(SMI_FICHAS$norma_cotizacion)))
  mochila <- filter(p, ficha == "mochila") |> arrange(geo_id)
  expect_equal(mochila$estado, c("ausente", "estimado", "estimado"))   # Álava: foral, sin mochila; método B, estimación
  expect_equal(mochila$ingreso[mochila$geo_id == "28"], 1500)
  expect_equal(filter(p, ficha == "llave", geo_id == "2800101001", anio == 2024L)$ingreso, 3000)
  expect_true(all(is.na(p$superficie_m2[p$ficha == "llave"])))
})

test_that("14: alquiler de vivienda colectiva × 12 / renta por hogar, solo en los años con los dos términos", {
  e <- calcular_esfuerzo_residentes(serpavi_largo(), adrh_largo())
  expect_equal(sort(unique(e$anio)), c(2023L, 2024L))
  expect_equal(fila(e, "2800101001", 2024L, "esfuerzo_residentes")$valor, 30)
  estimado <- fila(e, "0100101001", 2024L, "esfuerzo_residentes")
  expect_equal(c(estimado$valor, estimado$estado), c(21, "estimado"))
  secreto <- fila(e, "2800101002", 2024L, "esfuerzo_residentes")
  expect_equal(secreto$estado, "secreto")
  expect_true(is.na(secreto$valor))
  expect_equal(fila(e, "28001", 2024L, "esfuerzo_residentes")$valor, 30)
  expect_false("ccaa" %in% e$nivel)
  # Sin renta de una sección: ausente
  sin_renta <- calcular_esfuerzo_residentes(serpavi_largo(), filter(adrh_largo(), geo_id != "2800101001"))
  expect_equal(fila(sin_renta, "2800101001", 2024L, "esfuerzo_residentes")$estado, "ausente")
})

test_that("21: alquiler por m² × 50 / 0,30 en todos los niveles, con el estado del alquiler", {
  s <- calcular_sueldo_necesario(serpavi_largo())
  expect_equal(fila(s, "2800101001", 2024L, "sueldo_necesario")$valor, 15 * 50 / 0.3)
  expect_equal(fila(s, "13", 2023L, "sueldo_necesario")$valor, 2000)
  expect_equal(fila(s, "2800101002", 2024L, "sueldo_necesario")$estado, "secreto")
  expect_equal(nrow(s), 10L)   # solo la mediana VC: 5 territorios × 2 años
  expect_equal(calcular_sueldo_necesario(serpavi_largo(), superficie = 70, umbral = 0.4) |>
                 fila("2800101001", 2024L, "sueldo_necesario") |> pull(valor), 15 * 70 / 0.4)
})

test_that("los derivados parten de los términos redondeados a un decimal, como la web (pregunta 19)", {
  s <- serpavi_largo() |>
    mutate(valor = case_when(geo_id == "2800101001" & indicador == "alquiler_m2" & grupo == "VC" & corte == "tipologia" ~ 12.3456,
                             geo_id == "2800101001" & indicador == "alquiler_mes" ~ 900.06,
                             TRUE ~ valor))
  a <- adrh_largo() |> mutate(valor = ifelse(geo_id == "2800101001" & indicador == "renta_hogar", 36000.04, valor))
  expect_equal(fila(calcular_sueldo_necesario(s), "2800101001", 2024L, "sueldo_necesario")$valor, 12.3 * 50 / 0.3)
  expect_equal(fila(calcular_esfuerzo_residentes(s, a), "2800101001", 2024L, "esfuerzo_residentes")$valor,
               100 * 900.1 * 12 / 36000)
  # El redondeo de la guía (sprintf) y sin aviso con los NA
  expect_equal(termino_publicado(c(0.15, 1237.4049, NA)), c(as.numeric(sprintf("%.1f", c(0.15, 1237.4049))), NA))
  expect_silent(termino_publicado(c(NA_real_, 2)))
  p <- perfiles_fichas(tibble::tibble(provincia = "Madrid, Comunidad de", neto_mensual = 1500.04), provincias_inventadas, a,
                       anio_mochila = 2024L)
  b <- calcular_peso_alquiler_ingreso(s, p)
  expect_equal(fila(b, "28001", 2024L, "peso_alquiler_ingreso", "mochila")$valor, 100 * 14 * 50 / 1500)
  comp <- comprobar_derivados(armonizar_derivados(s, a, p), s, a, p, provincias_inventadas,
                              tibble::tibble(provincia = "Madrid, Comunidad de", neto_mensual = 1500.04))
  expect_true(all(comp$calculado[comp$id == "derivados_terminos"] < 1e-9))
})

test_that("15 en R: tartera y mochila con el ingreso del mismo año que el alquiler", {
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, adrh_largo(), anio_mochila = 2024L)
  b <- calcular_peso_alquiler_ingreso(serpavi_largo(), p)
  expect_equal(sort(unique(b$anio)), c(2023L, 2024L))           # 2026 no tiene alquiler
  expect_equal(unique(b$anio[b$grupo == "mochila"]), 2024L)     # la mochila, solo su año
  tartera <- as.numeric(sprintf("%.1f", 1134 * 14 * (1 - 0.0647) / 12))   # como en perfiles.json
  expect_equal(fila(b, "2800101001", 2024L, "peso_alquiler_ingreso", "tartera")$valor, 100 * 15 * 50 / tartera)
  expect_equal(fila(b, "13", 2024L, "peso_alquiler_ingreso", "tartera")$valor, 100 * 12 * 50 / tartera)
  tartera_2023 <- as.numeric(sprintf("%.1f", 1080 * 14 * (1 - 0.0645) / 12))   # el SMI del mismo año
  expect_equal(fila(b, "2800101001", 2023L, "peso_alquiler_ingreso", "tartera")$valor, 100 * 15 * 50 / tartera_2023)
  expect_equal(fila(b, "2800101001", 2024L, "peso_alquiler_ingreso", "mochila")$valor, 50)
  expect_equal(fila(b, "28001", 2024L, "peso_alquiler_ingreso", "mochila")$valor, 100 * 14 * 50 / 1500)
  expect_equal(fila(b, "0100101001", 2024L, "peso_alquiler_ingreso", "mochila")$estado, "ausente")   # foral, sin mochila
  expect_equal(nrow(fila(b, "13", 2024L, "peso_alquiler_ingreso", "mochila")), 0L)   # la comunidad no tiene una sola provincia
  expect_equal(unique(b$corte), "ficha")
})

test_that("15 en R: el transistor de cada año y provincia, con su estado, y la compuerta cuadra", {
  transistor <- tibble::tibble(provincia = c("28", "28", "01"), anio = c(2023L, 2024L, 2024L),
                               neto_mensual = c(1450.04, 1500.04, 1800), estado = c("dato", "dato", "estimado"))
  s <- serpavi_largo(); a <- adrh_largo()
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, a, anio_mochila = 2024L, transistor = transistor)
  tr <- filter(p, ficha == "transistor")
  expect_equal(nrow(tr), 3L)
  expect_equal(unique(tr$fuente), "inss_pensiones")
  expect_equal(unique(tr$superficie_m2), 50)
  b <- calcular_peso_alquiler_ingreso(s, p)
  expect_equal(fila(b, "2800101001", 2023L, "peso_alquiler_ingreso", "transistor")$valor, 100 * 15 * 50 / 1450)
  expect_equal(fila(b, "28001", 2024L, "peso_alquiler_ingreso", "transistor")$valor, 100 * 14 * 50 / 1500)
  expect_equal(fila(b, "0100101001", 2024L, "peso_alquiler_ingreso", "transistor")$estado, "dato")      # foral estimado: el del alquiler
  expect_equal(fila(b, "0100101001", 2023L, "peso_alquiler_ingreso", "transistor")$estado, "ausente")   # sin ingreso ese año
  expect_equal(nrow(fila(b, "13", 2024L, "peso_alquiler_ingreso", "transistor")), 0L)
  d <- armonizar_derivados(s, a, p)
  comp <- comprobar_derivados(d, s, a, p, provincias_inventadas, mochila_inventada)
  expect_true(all(comp$calculado[comp$id == "derivados_terminos"] < 1e-9))
  expect_equal(sum(comp$calculado[comp$id == "derivados_estado"]), 0)
  expect_true("peso_alquiler_ingreso transistor" %in% comp$detalle)
})

test_that("estado del 15: el del alquiler; el ingreso de la ficha solo aporta ausente (pregunta 15 ampliada)", {
  # Mochila «estimado» y alquiler «dato»: la barrera es «dato»
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, adrh_largo(), anio_mochila = 2024L)
  b <- calcular_peso_alquiler_ingreso(serpavi_largo(), p)
  expect_equal(fila(b, "2800101001", 2024L, "peso_alquiler_ingreso", "mochila")$estado, "dato")
  expect_equal(fila(b, "2800101002", 2024L, "peso_alquiler_ingreso", "mochila")$estado, "secreto")   # el del alquiler
  # Sin ingreso de la ficha: ausente, aunque el alquiler sea dato
  expect_equal(fila(b, "0100101001", 2024L, "peso_alquiler_ingreso", "mochila")$estado, "ausente")
  expect_equal(estado_peso_alquiler(c("dato", "estimado", "secreto", "dato", NA), c("estimado", "dato", "estimado", "ausente", "dato")),
               c("dato", "estimado", "secreto", "ausente", "ausente"))
  expect_equal(estado_peso_alquiler("dato", NA_character_), "ausente")
  # Y la compuerta lo acepta: el estado esperado del 15 sigue la misma regla
  d <- armonizar_derivados(serpavi_largo(), adrh_largo(), p)
  comp <- comprobar_derivados(d, serpavi_largo(), adrh_largo(), p, provincias_inventadas, mochila_inventada)
  expect_equal(sum(comp$calculado[comp$id == "derivados_estado"]), 0)
  mal <- mutate(d, estado = ifelse(indicador == "peso_alquiler_ingreso" & grupo == "mochila" & geo_id == "2800101001" & anio == 2024L,
                                   "estimado", estado))
  c2 <- comprobar_derivados(mal, serpavi_largo(), adrh_largo(), p, provincias_inventadas, mochila_inventada)
  expect_equal(filter(c2, id == "derivados_estado", detalle == "peso_alquiler_ingreso mochila")$calculado, 1)
})

test_that("la tabla larga de los derivados pasa la validación y la compuerta cuadra", {
  s <- serpavi_largo(); a <- adrh_largo()
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, a, anio_mochila = 2024L)
  d <- armonizar_derivados(s, a, p)
  expect_silent(validar_tabla_larga(d, indicadores = inventario("indicadores.csv"), fuentes = inventario("fuentes.csv"),
                                    vocabulario = inventario("vocabulario.csv")))
  expect_equal(unique(d$fuente), "calculo_propio")
  expect_equal(unique(d$version), "2026-11-07")
  comp <- comprobar_derivados(d, s, a, p, provincias_inventadas, mochila_inventada)
  expect_true(all(comp$calculado[comp$id == "derivados_terminos"] < 1e-9))
  expect_true(all(comp$calculado[comp$id %in% c("derivados_estado", "derivados_rango", "perfiles_mochila")] == 0))
  expect_equal(nrow(filter(comp, id == "derivados_rango_detalle")), 0L)
  expect_lt(abs(comp$calculado[comp$id == "smi_neto"] - 1332), 1)

  # Una cifra cambiada, un estado cambiado, un valor imposible y una provincia sin código: la compuerta lo ve
  roto <- d |>
    mutate(valor = ifelse(geo_id == "2800101001" & anio == 2024L & indicador == "esfuerzo_residentes", 31, valor),
           estado = ifelse(geo_id == "0100101001" & anio == 2024L & indicador == "esfuerzo_residentes", "dato", estado),
           valor = ifelse(geo_id == "13" & anio == 2023L & indicador == "sueldo_necesario", 20000, valor))
  c2 <- comprobar_derivados(roto, s, a, p, provincias_inventadas,
                            bind_rows(mochila_inventada, tibble::tibble(provincia = "Teruel", neto_mensual = 1100)))
  expect_gt(filter(c2, id == "derivados_terminos", anio == 2024L, detalle == "esfuerzo_residentes")$calculado, 1)
  expect_equal(filter(c2, id == "derivados_estado", anio == 2024L, detalle == "esfuerzo_residentes")$calculado, 1)
  expect_equal(filter(c2, id == "derivados_rango", anio == 2023L, detalle == "sueldo_necesario")$calculado, 1)
  expect_equal(nrow(filter(c2, id == "derivados_rango_detalle")), 1L)
  expect_equal(filter(c2, id == "perfiles_mochila")$calculado[1], 1)
})

test_that("el resumen da estados y percentiles por indicador, nivel y año", {
  s <- serpavi_largo(); a <- adrh_largo()
  p <- perfiles_fichas(mochila_inventada, provincias_inventadas, a, anio_mochila = 2024L)
  r <- resumen_derivados(armonizar_derivados(s, a, p))
  expect_equal(filter(r$estados, indicador == "sueldo_necesario", nivel == "sc", anio == 2024L)$secreto, 1L)
  expect_true("peso_alquiler_ingreso tartera" %in% r$rangos$indicador)
  expect_equal(resumen_llave(p)$p50[resumen_llave(p)$anio == 2024L], 3000)
})
