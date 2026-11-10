# F4, compraventa: IPVA (10), valor tasado (12), tipo hipotecario, derivados 16 y 17, coherencia
# entre tasación y escrituras y tabla de paso código postal ↔ municipio. Datos inventados.

escribir_tmp <- function(lineas, ext = ".csv") {
  ruta <- tempfile(fileext = ext)
  writeLines(enc2utf8(lineas), ruta, useBytes = TRUE)
  ruta
}

territorios_prueba <- tibble::tribble(
  ~nivel,      ~codigo,   ~nombre,                  ~superior, ~secciones,
  "ccaa",      "01",      "Andalucía",          NA,        30L,
  "ccaa",      "13",      "Madrid, Comunidad de",    NA,        40L,
  "provincia", "13",      "Ciudad Real",             "08",      10L,
  "provincia", "04",      "Almería",            "01",      12L,
  "provincia", "11",      "Cádiz",              "01",      18L,
  "provincia", "28",      "Madrid",                  "13",      40L,
  "municipio", "04902",   "Ejido, El",               "04",      12L,
  "municipio", "11020",   "Jerez de la Frontera",    "11",      18L,
  "municipio", "28079",   "Madrid",                  "28",      30L,
  "municipio", "28005",   "Alcalá de Henares",  "28",      10L,
  "distrito",  "2807901", NA,                        "28079",   10L
)

test_that("numero_jaxi lee coma decimal, miles y '..'", {
  expect_equal(numero_jaxi(c("3,5", "1.234,5", "..", "", "-0,7")), c(3.5, 1234.5, NA, NA, -0.7))
})

test_that("leer_ine_ipva descarta el resto de la provincia y detecta series cortadas", {
  lineas <- c("﻿Municipio;Tipo de dato;Periodo;Total",
              "Total Nacional;Índice;2024;110,0", "Total Nacional;Índice;2023;100,0",
              "Total Nacional;Variación anual;2024;10,0", "Total Nacional;Variación anual;2023;..",
              "28079 Madrid;Índice;2024;105,0", "28079 Madrid;Índice;2023;100,0",
              "28079 Madrid;Variación anual;2024;5,0", "28079 Madrid;Variación anual;2023;..",
              "Resto Madrid;Índice;2024;101,0", "Resto Madrid;Índice;2023;100,0")
  x <- leer_ine_ipva(escribir_tmp(lineas))
  expect_setequal(unique(x$geo_id), c("00", "28079"))
  expect_equal(unique(x$nivel[x$geo_id == "28079"]), "municipio")
  expect_equal(x$valor[x$geo_id == "28079" & x$medida == "variacion" & x$anio == 2024], 5)
  expect_error(leer_ine_ipva(escribir_tmp(lineas[-3])), "cortada")
})

test_that("leer_ine_ipva lee la antigüedad del contrato (tablas 59004 y 59005)", {
  lineas <- c("﻿Total Nacional;Comunidades y Ciudades Autónomas;Antigüedad del contrato de arrendamiento;Tipo de dato;Periodo;Total",
              "Total Nacional;;Total;Índice;2022;115,684", "Total Nacional;;Total;Índice;2021;112,694",
              "Total Nacional;;Nuevo contrato;Índice;2022;120,958", "Total Nacional;;Nuevo contrato;Índice;2021;114,871",
              "Total Nacional;;Contrato existente;Índice;2022;114,639", "Total Nacional;;Contrato existente;Índice;2021;112,229",
              "Total Nacional;13 Madrid, Comunidad de;Nuevo contrato;Índice;2022;121,0",
              "Total Nacional;13 Madrid, Comunidad de;Nuevo contrato;Índice;2021;115,0")
  x <- leer_ine_ipva(escribir_tmp(lineas))
  expect_setequal(unique(x$contrato), c("total", "nuevo", "existente"))
  expect_setequal(unique(x$geo_id), c("00", "13"))
  expect_equal(unique(x$nivel[x$geo_id == "13"]), "ccaa")
  expect_equal(x$valor[x$geo_id == "00" & x$contrato == "nuevo" & x$anio == 2021], 114.871)
  expect_true(all(x$tipologia == "total"))
  expect_error(leer_ine_ipva(escribir_tmp(sub("Contrato existente", "Otro", lineas))), "contrato desconocida")
  expect_error(leer_ine_ipva(escribir_tmp(lineas[-8])), "cortada")
})

ipva_prueba <- function() {
  base <- tibble::tribble(
    ~nivel,      ~geo_id,   ~anio, ~medida,      ~valor,
    "nacional",  "00",      2023L, "indice",     100,
    "nacional",  "00",      2024L, "indice",     103.5,
    "nacional",  "00",      2024L, "variacion",  3.5,
    "municipio", "28079",   2023L, "indice",     100,
    "municipio", "28079",   2024L, "indice",     103.6,
    "municipio", "28079",   2024L, "variacion",  3.6,
    "distrito",  "2807901", 2023L, "indice",     100,
    "distrito",  "2807901", 2024L, "indice",     102.04,
    "distrito",  "2807901", 2024L, "variacion",  2.0
  ) |> dplyr::mutate(tipologia = "total", contrato = "total", territorio = "x",
                     tabla = c(rep("59056", 3), rep("59060", 3), rep("59061", 3)))
  base
}

# España en la 59056 de ipva_prueba() y en la 59004, con el desglose por contrato desde 2024,
# encadenado desde el índice general de 2023 (100); el total de la 59004 repite el de la 59056
ipva_prueba_contrato <- function() {
  contrato <- tibble::tribble(
    ~contrato,   ~anio, ~medida,     ~valor,
    "total",     2024L, "indice",    103.5,
    "total",     2024L, "variacion", 3.5,
    "nuevo",     2024L, "indice",    105.02,
    "nuevo",     2024L, "variacion", 5.0,
    "existente", 2024L, "indice",    99.0,
    "existente", 2024L, "variacion", -1.0
  ) |> dplyr::mutate(nivel = "nacional", geo_id = "00", tipologia = "total", territorio = "x", tabla = "59004")
  dplyr::bind_rows(dplyr::filter(ipva_prueba(), tabla == "59056"), contrato)
}

test_that("comprobar_ine_ipva recalcula la variación y casa los territorios", {
  c0 <- comprobar_ine_ipva(ipva_prueba(), territorios_prueba)
  v <- c0[c0$id == "ipva_variacion", ]
  expect_true(all(v$calculado <= 0.05))
  expect_equal(c0$calculado[c0$id == "ipva_territorios"], c(0, 0))
  nota <- c0[c0$id == "ipva_nota" & c0$detalle %in% c("España", "Madrid"), ]
  expect_equal(nota$calculado, nota$referencia)
  expect_false("ipva_contrato_enlace" %in% c0$id)   # sin desglose por contrato
})

test_that("comprobar_ine_ipva encadena el desglose por contrato desde el índice general", {
  de <- function(c, id) c[c$id == id, ]
  c0 <- comprobar_ine_ipva(ipva_prueba_contrato(), territorios_prueba)
  enlace <- de(c0, "ipva_contrato_enlace")
  expect_equal(enlace$anio, 2024L)
  # nuevo: 105,02 / 100 da 5,02 frente a 5,0 publicado; existente: 99,0 / 100, -1,0 exacto
  expect_equal(enlace$calculado, 0.02, tolerance = 1e-6)
  # una comunidad sin índice general del año anterior: NA, y la compuerta no puede pasar
  sin_general <- dplyr::bind_rows(ipva_prueba_contrato(), tibble::tibble(
    nivel = "ccaa", geo_id = "13", tipologia = "total", contrato = "nuevo", anio = 2024L,
    medida = c("indice", "variacion"), valor = c(105, 5), territorio = "x", tabla = "59004"))
  e1 <- de(comprobar_ine_ipva(sin_general, territorios_prueba), "ipva_contrato_enlace")
  expect_true(is.na(e1$calculado[e1$detalle == "59004 ccaa"]))
  expect_equal(e1$calculado[e1$detalle == "59004 nacional"], 0.02, tolerance = 1e-6)
  # España repetida en la 59004 y en la 59056, con la misma cifra; si cambia, la compuerta lo ve
  expect_true(all(de(c0, "ipva_tablas")$calculado == 0))
  distinta <- ipva_prueba_contrato()
  distinta$valor[distinta$tabla == "59004" & distinta$contrato == "total" & distinta$medida == "indice"] <- 103.6
  expect_equal(sum(de(comprobar_ine_ipva(distinta, territorios_prueba), "ipva_tablas")$calculado), 1)
  # cifras de referencia de España: 2021 y 2022 no están en la prueba (NA)
  ref <- de(c0, "ipva_contrato")
  expect_equal(nrow(ref), nrow(REFERENCIAS_IPVA_CONTRATO))
  expect_true(all(is.na(ref$calculado[ref$anio != 2024L])))
  expect_equal(ref$calculado[ref$anio == 2024L & grepl("total", ref$detalle)], 103.5)
})

test_that("armonizar_ine_ipva da el indicador 10 de cada nivel desde su tabla", {
  l <- armonizar_ine_ipva(ipva_prueba(), version = "2026-05-11", anios = 2024L)
  expect_equal(nrow(l), 3)
  expect_true(all(l$indicador == "var_alquiler" & l$estado == "dato" & l$corte == "total"))
  expect_equal(names(l), COLUMNAS_TABLA_LARGA)
})

test_that("armonizar_ine_ipva añade el corte contrato desde las tablas por antigüedad", {
  l <- armonizar_ine_ipva(ipva_prueba_contrato(), version = "2026-05-11", anios = 2024L)
  contrato <- l[l$corte == "contrato", ]
  expect_setequal(contrato$grupo, c("nuevo", "existente"))
  expect_equal(contrato$valor[contrato$grupo == "nuevo"], 5.0)
  # el total de España sigue saliendo de la tabla general, una sola vez
  expect_equal(sum(l$nivel == "nacional" & l$corte == "total"), 1)
  expect_false(any(duplicated(l[CLAVE_TABLA_LARGA])))
})

test_that("tipo hipotecario: lectura, serie y coherencia anual frente a los meses", {
  anual <- escribir_tmp(c("﻿Tipo de interés;Naturaleza de la finca;Periodo;Total",
                          "Total;Viviendas;2024;3,26", "Total;Viviendas;2023;3,11",
                          "Total;Total fincas;2024;3,62", "Total;Total fincas;2023;3,50"))
  meses <- c("﻿Tipo de interés;Naturaleza de la finca;Periodo;Total",
             sprintf("Total;Viviendas;2024M%02d;%s", 1:12, "3,26"), sprintf("Total;Total fincas;2024M%02d;%s", 1:12, "3,6"))
  a <- leer_ine_hipotecas(anual)
  m <- leer_ine_hipotecas(escribir_tmp(meses))
  expect_equal(tipo_hipotecario(a)$tipo, c(3.11, 3.26))
  c0 <- comprobar_ine_hipotecas(a, m, 2023:2025)
  expect_equal(c0$calculado[c0$id == "hipotecas_tipo_anual"], 0, tolerance = 1e-9)
  expect_equal(c0$calculado[c0$id == "hipotecas_serie"], 1)   # 2025 falta
})

test_that("normalizar_nombre pone el artículo delante y quita tildes y paréntesis", {
  expect_equal(normalizar_nombre(c("Ejido (El)", "Ejido, El", "Asturias (Principado de )", "Córdoba",
                                   "Hospitalet de Llobregat (L')")),
               c("elejido", "elejido", "asturias", "cordoba", "lhospitaletdellobregat"))
})

test_that("casar_nombres_mivau: provincia antes que comunidad, manual y respaldo nacional", {
  manual <- tibble::tibble(nivel_ine = c("provincia", "ninguno"), provincia = NA_character_,
                           nombre_mivau = c("Cádiz (errata)", "Ceuta y Melilla"), codigo = c("11", NA), nota = "")
  mun <- tibble::tribble(
    ~provincia_mivau,     ~municipio_mivau,
    "Almería",       "Ejido (El)",
    "Cádiz (errata)", "Jerez de la Frontera",
    "Almería",       "Alcalá de Henares"      # provincia mal arrastrada
  )
  c0 <- casar_nombres_mivau(c("TOTAL NACIONAL", "Madrid (Comunidad de)", "Andalucía", "Ceuta y Melilla"),
                            mun, territorios_prueba, manual)
  cod <- function(n) c0$codigo[c0$nombre_mivau == n]
  expect_equal(cod("TOTAL NACIONAL"), "00")
  expect_equal(c0$nivel_ine[c0$nombre_mivau == "Madrid (Comunidad de)"], "provincia")
  expect_equal(cod("Madrid (Comunidad de)"), "28")
  expect_equal(cod("Andalucía"), "01")
  expect_equal(cod("Ejido (El)"), "04902")
  expect_equal(cod("Jerez de la Frontera"), "11020")
  expect_equal(cod("Alcalá de Henares"), "28005")
  expect_equal(c0$origen[c0$nombre_mivau == "Alcalá de Henares"], "nacional")
  n <- niveles_mivau(c0, territorios_prueba)
  expect_true(all(c("ccaa", "provincia") %in% n$nivel_atlas[n$nombre_mivau == "Madrid (Comunidad de)"]))
  expect_false("Ceuta y Melilla" %in% n$nombre_mivau)
})

test_that("valor_tasado_anual pondera por tasaciones y exige los cuatro trimestres", {
  t <- tibble::tibble(nivel = "municipio", geo_id = rep(c("28079", "28005"), each = 4), anio = 2024L,
                      trimestre = rep(1:4, 2), valor = c(1000, 2000, 1000, 2000, 1500, NA, 1500, 1500),
                      tasaciones = c(1, 3, 1, 3, 10, 10, 10, 10))
  a <- valor_tasado_anual(t)
  expect_equal(a$valor[a$geo_id == "28079"], (1000 * 2 + 2000 * 6) / 8)
  expect_true(is.na(a$valor[a$geo_id == "28005"]))
  t$valor[1] <- 15     # error de la fuente: fuera de rango, como si faltara
  a2 <- valor_tasado_anual(t)
  expect_true(is.na(a2$valor[a2$geo_id == "28079"]))
  l <- armonizar_mivau_valor_tasado(a, version = "x", anios = 2024L)
  expect_equal(sort(l$estado), c("ausente", "dato"))
})

test_that("comprobar_mivau_valor_tasado: comunidades dentro de sus provincias y tasaciones que suman", {
  t <- tibble::tibble(
    nivel = c("provincia", "provincia", "ccaa", "nacional", "provincia"),
    geo_id = c("04", "11", "01", "00", "28"), anio = 2026L, trimestre = 1L,
    valor = c(1000, 2000, 1600, 2315.7, 4000), tasaciones = c(10, 30, 40, 50, 10))
  cas <- tibble::tibble(nivel = "territorio", provincia = "", nombre_mivau = "x", codigo = "04", nivel_ine = "provincia", origen = "auto")
  c0 <- comprobar_mivau_valor_tasado(t, cas, territorios_prueba, desde = 2026L)
  expect_equal(c0$calculado[c0$id == "valor_tasado_ccaa"], 0)
  expect_equal(c0$calculado[c0$id == "valor_tasado_tasaciones"], 0)
  expect_equal(c0$calculado[c0$id == "valor_tasado_nota"], 2315.7)
  t$valor[3] <- 2500
  expect_equal(comprobar_mivau_valor_tasado(t, cas, territorios_prueba, desde = 2026L) |>
                 dplyr::filter(id == "valor_tasado_ccaa") |> dplyr::pull(calculado), 1)
})

test_that("cuota_hipoteca reproduce el préstamo francés", {
  expect_equal(round(cuota_hipoteca(100000, 3, 25), 2), 474.21)
  expect_equal(cuota_hipoteca(1200, 0, 1), 100)
})

larga_vt_prueba <- function() {
  tibble::tibble(geo_id = c("28079", "28", "13", "00", "04902"), nivel = c("municipio", "provincia", "ccaa", "nacional", "municipio"),
                 anio = 2024L, indicador = "valor_tasado_m2", corte = "total", grupo = "total",
                 valor = c(4000, 3000, 3000, 2000, NA), estado = c("dato", "dato", "dato", "dato", "ausente"),
                 fuente = "mivau_valor_tasado", geo_ref = "2021", version = "2026-09-17")
}
larga_sal_prueba <- function() {
  tibble::tibble(geo_id = c("28", "13", "00", "04"), nivel = c("provincia", "ccaa", "nacional", "provincia"), anio = 2024L,
                 indicador = "salario_medio", corte = "total", grupo = "total", valor = c(32000, 32000, 25000, NA),
                 estado = c("dato", "dato", "dato", "ausente"), fuente = "aeat_mercado_trabajo", geo_ref = NA_character_,
                 version = "2026-11-09")
}

test_that("derivados 16 y 17: valores, estados y compuerta", {
  tipo <- tibble::tibble(anio = 2024L, tipo = 3.26)
  d <- armonizar_derivados_compraventa(larga_vt_prueba(), larga_sal_prueba(), tipo)
  a <- d[d$indicador == "anios_salario_compra", ]
  expect_equal(a$valor[a$geo_id == "28079"], 4000 * 80 / 32000)
  expect_equal(a$valor[a$geo_id == "00"], 2000 * 80 / 25000)
  expect_equal(a$estado[a$geo_id == "04902"], "ausente")
  e <- d[d$indicador == "esfuerzo_hipotecario", ]
  expect_equal(e$valor[e$geo_id == "28079"], 100 * 12 * cuota_hipoteca(0.8 * 4000 * 80, 3.26) / 32000)
  c0 <- comprobar_derivados_compraventa(d, larga_vt_prueba(), larga_sal_prueba(), tipo)
  expect_true(all(c0$calculado[c0$id %in% c("compraventa_estado", "compraventa_rango")] == 0))
  expect_true(all(c0$calculado[c0$id == "compraventa_terminos"] < 1e-9))
  sin_tipo <- armonizar_derivados_compraventa(larga_vt_prueba(), larga_sal_prueba(), tipo[0, ])
  expect_true(all(sin_tipo$estado[sin_tipo$indicador == "esfuerzo_hipotecario"] == "ausente"))
})

test_that("coherencia: superficie implícita de las escrituras sobre la tasación", {
  q <- tidyr::expand_grid(nivel = c("nacional", "provincia"), anio = 2024L, trimestre = 1:4) |>
    dplyr::mutate(geo_id = ifelse(nivel == "nacional", "00", "28"))
  tasado <- dplyr::mutate(q, valor = 2000)
  escrituras <- dplyr::mutate(q, valor = ifelse(nivel == "nacional", 190000, 400000))   # 95 y 200 m²
  c0 <- comprobar_coherencia_compraventa(tasado, escrituras, desde = 2024L)
  expect_equal(c0$calculado[c0$id == "compraventa_coherencia_espana"], 0)
  expect_equal(c0$calculado[c0$id == "compraventa_coherencia_provincias"], 100)
  expect_equal(sum(c0$id == "compraventa_coherencia_detalle"), 1)
})

test_that("código postal ↔ municipio: pesos, principal y compuerta", {
  tramos <- tibble::tibble(seccion = c("2807901001", "2800501001", "2807901002", "2807901003", "0100101001"),
                           cp = c("28001", "28001", "28001", "00040", "01240"), tramos = c(6L, 2L, 2L, 1L, 4L))
  tab <- geo_tabla_cp_municipio(tramos)
  expect_equal(tab$peso[tab$cp == "28001" & tab$municipio == "28079"], 80)
  expect_equal(sum(tab$principal[tab$cp == "28001"]), 1)
  expect_false("00040" %in% tab$cp)
  c0 <- comprobar_cp_municipio(tab, tramos, territorios_prueba)
  expect_equal(c0$calculado[c0$detalle == "tramos sin código postal"], 1)
  expect_equal(c0$calculado[c0$id == "cp_municipio_codigos"], 1)    # 01001 no está en la jerarquía de prueba
})
