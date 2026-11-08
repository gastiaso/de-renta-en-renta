# SERPAVI, indicadores 8 y 9 (R/fuente_mivau_serpavi.R). Datos inventados.

# Una provincia común (28: dos municipios, uno con dos secciones) y una foral (31: entra en 2021),
# con sus comunidades y España, en 2020 y 2021. Las medianas de los cuartiles y del m² se derivan
# de la mensual para que todo sea coherente.
serpavi_inventado <- function() {
  madrid <- tibble::tribble(
    ~nivel,      ~codigo,      ~tipologia, ~testigos, ~mediana,
    "sc",        "2800101001", "VC",       25,        800,
    "sc",        "2800101001", "VU",        3,         NA,
    "sc",        "2800101002", "VC",        4,         NA,
    "sc",        "2800101002", "VU",        0,         NA,
    "sc",        "2800201001", "VC",       12,        500,
    "sc",        "2800201001", "VU",       NA,         NA,
    "distrito",  "2800101",    "VC",       29,        780,
    "distrito",  "2800101",    "VU",        3,         NA,
    "distrito",  "2800201",    "VC",       12,        500,
    "distrito",  "2800201",    "VU",       NA,         NA,
    "municipio", "28001",      "VC",       29,        780,
    "municipio", "28001",      "VU",        3,         NA,
    "municipio", "28002",      "VC",       12,        500,
    "municipio", "28002",      "VU",        0,         NA,
    "provincia", "28",         "VC",       41,        700,
    "provincia", "28",         "VU",        3,         NA,
    "ccaa",      "13",         "VC",       41,        700,
    "ccaa",      "13",         "VU",        3,         NA
  )
  navarra <- tibble::tribble(
    ~nivel,      ~codigo,      ~tipologia, ~testigos, ~mediana,
    "sc",        "3100101001", "VC",       15,        600,
    "sc",        "3100101001", "VU",        2,         NA,
    "distrito",  "3100101",    "VC",       15,        600,
    "distrito",  "3100101",    "VU",        2,         NA,
    "municipio", "31001",      "VC",       15,        600,
    "municipio", "31001",      "VU",        2,         NA,
    "provincia", "31",         "VC",       15,        600,
    "provincia", "31",         "VU",        2,         NA,
    "ccaa",      "15",         "VC",       15,        600,
    "ccaa",      "15",         "VU",        2,         NA
  )
  espana <- function(vc, vu) tibble::tibble(nivel = "nacional", codigo = "00", tipologia = c("VC", "VU"),
                                            testigos = c(vc, vu), mediana = NA_real_)
  bind_rows(
    bind_rows(madrid, mutate(navarra, testigos = NA_real_, mediana = NA_real_), espana(41, 3)) |> mutate(anio = 2020L),
    bind_rows(madrid, navarra, espana(56, 5)) |> mutate(anio = 2021L)
  ) |>
    transmute(nivel, codigo, anio, tipologia, testigos,
              alquiler_mes_p25 = mediana * 0.8, alquiler_mes_p50 = mediana, alquiler_mes_p75 = mediana * 1.25,
              alquiler_m2_p25 = mediana / 100, alquiler_m2_p50 = mediana / 80, alquiler_m2_p75 = mediana / 60)
}

# Inversa de ordenar_hoja_serpavi(): las filas ordenadas, como una hoja del Excel.
a_hoja <- function(x, columna_codigo) {
  prefijo <- c(testigos = "BI_ALVHEPCO_T", alquiler_mes_p25 = "ALQTBID12_25_", alquiler_mes_p50 = "ALQTBID12_M_",
               alquiler_mes_p75 = "ALQTBID12_75_", alquiler_m2_p25 = "ALQM2_LV_25_", alquiler_m2_p50 = "ALQM2_LV_M_",
               alquiler_m2_p75 = "ALQM2_LV_75_")
  h <- x |>
    tidyr::pivot_longer(all_of(MEDIDAS_SERPAVI), names_to = "medida") |>
    mutate(columna = paste0(prefijo[medida], tipologia, "_", sprintf("%02d", anio - 2000L))) |>
    select(codigo, columna, value) |>
    tidyr::pivot_wider(names_from = columna, values_from = value)
  names(h)[1] <- columna_codigo
  h
}

voc <- readr::read_csv(file.path("..", "..", "inventario", "vocabulario.csv"), show_col_types = FALSE)

test_that("se reconocen las columnas del SERPAVI (también ALQM2mes) y se ignoran las demás", {
  cols <- columnas_serpavi(c("CPRO", "LITPRO", "BI_ALVHEPCO_TVC_15", "ALQTBID12_M_VU_24",
                             "ALQM2mes_LV_25_VC_16", "ALQM2_LV_75_VU_15", "SLVM2_M_VC_15"))
  expect_equal(cols$medida, c("testigos", "alquiler_mes_p50", "alquiler_m2_p25", "alquiler_m2_p75"))
  expect_equal(cols$tipologia, c("VC", "VU", "VC", "VU"))
  expect_equal(cols$anio, c(2015L, 2024L, 2016L, 2015L))
})

test_that("una hoja vuelve a su forma ordenada, con códigos de diez dígitos y España en la hoja CCAA", {
  s <- serpavi_inventado()
  sc <- filter(s, nivel == "sc")
  expect_equal(ordenar_hoja_serpavi(a_hoja(sc, "CUSEC"), "sc", desde = 2020L), arrange(sc, nivel, codigo, anio, tipologia))
  # Códigos leídos como números: ceros a la izquierda, también por encima de 2^31
  h <- a_hoja(sc, "CUSEC") |> mutate(CUSEC = c(5000101001, 100101001, 2800201001, 3100101001))
  expect_equal(sort(ordenar_hoja_serpavi(h, "sc", desde = 2020L)$codigo |> unique()),
               c("0100101001", "2800201001", "3100101001", "5000101001"))
  # Solo los años desde `desde`
  expect_equal(unique(ordenar_hoja_serpavi(a_hoja(sc, "CUSEC"), "sc", desde = 2021L)$anio), 2021L)
  # Hoja CCAA: la fila sin código es España
  cc <- filter(s, nivel %in% c("ccaa", "nacional")) |> mutate(codigo = ifelse(nivel == "nacional", NA, codigo))
  o <- ordenar_hoja_serpavi(a_hoja(cc, "CCAA"), "ccaa", desde = 2020L)
  expect_equal(sort(unique(o$nivel)), c("ccaa", "nacional"))
  expect_equal(o$testigos[o$nivel == "nacional" & o$anio == 2021L & o$tipologia == "VC"], 56)
  # A un año le falta una columna: se detiene
  expect_error(ordenar_hoja_serpavi(select(a_hoja(sc, "CUSEC"), -ALQM2_LV_75_VU_21), "sc", desde = 2020L), "incompletas")
  expect_error(ordenar_hoja_serpavi(a_hoja(sc, "CUSEC")[c(1, 1), ], "sc", desde = 2020L), "repetidos")
})

test_that("con datos coherentes, la compuerta cuadra y la entrada foral coincide con la ruptura", {
  s <- serpavi_inventado()
  comp <- comprobar_mivau_serpavi(s, entrada_forales = c("31" = 2021L))
  bloqueos <- filter(comp, id %in% c("serpavi_provincia", "serpavi_espana", "serpavi_secreto", "serpavi_cuartiles", "serpavi_escalas"))
  expect_equal(bloqueos$calculado, bloqueos$referencia)
  expect_equal(nrow(filter(comp, id == "serpavi_escalas_detalle")), 0L)
  expect_equal(comp$calculado[comp$id == "serpavi_forales"], 2021)
  # España en 2021: secciones y comunidades
  expect_equal(comp$calculado[comp$id == "serpavi_espana" & comp$anio == 2021L], c(56, 5, 56, 5))
})

test_that("una comunidad foral sin cifra deja fuera sus secciones al cuadrar España", {
  # Como el País Vasco en 2022 y 2023: la provincia ya tiene testigos, la comunidad no
  s <- serpavi_inventado() |>
    mutate(testigos = ifelse(nivel == "ccaa" & codigo == "15" & anio == 2021L, NA, testigos),
           testigos = ifelse(nivel == "nacional" & anio == 2021L, testigos - ifelse(tipologia == "VC", 15, 2), testigos))
  comp <- filter(comprobar_mivau_serpavi(s, entrada_forales = c("31" = 2021L)), id == "serpavi_espana", anio == 2021L)
  expect_equal(comp$calculado, comp$referencia)
})

test_that("los descuadres de la fuente se detectan y van como ausente", {
  s <- serpavi_inventado()
  # Provincia que no suma sus secciones: bloqueo
  roto <- mutate(s, testigos = ifelse(nivel == "provincia" & codigo == "28" & tipologia == "VC", 40, testigos))
  p <- filter(comprobar_mivau_serpavi(roto), id == "serpavi_provincia", calculado != referencia)
  expect_equal(nrow(p), 2L)
  # Municipio con la mediana y el P25 cruzados (como Navarra en 2022) y distrito con otro recuento
  cruzado <- s |>
    mutate(p25 = alquiler_mes_p25,
           alquiler_mes_p25 = ifelse(nivel == "municipio" & codigo == "28001" & tipologia == "VC", alquiler_mes_p50, alquiler_mes_p25),
           alquiler_mes_p50 = ifelse(nivel == "municipio" & codigo == "28001" & tipologia == "VC", p25, alquiler_mes_p50),
           testigos = ifelse(nivel == "distrito" & codigo == "2800201" & tipologia == "VC" & anio == 2021L, 13, testigos)) |>
    select(-p25)
  d <- descuadres_serpavi(cruzado)
  expect_setequal(paste(d$nivel, d$codigo, d$anio, d$motivo),
                  c("municipio 28001 2020 cuartiles", "municipio 28001 2021 cuartiles", "distrito 2800201 2021 recuento"))
  comp <- comprobar_mivau_serpavi(cruzado, entrada_forales = c("31" = 2021L))
  expect_equal(nrow(filter(comp, id == "serpavi_escalas_detalle")), 3L)
  expect_equal(sum(comp$calculado[comp$id == "serpavi_escalas"] > 0), 3L)   # 2020 y 2021 municipio, 2021 distrito
  l <- armonizar_mivau_serpavi(cruzado, version = "2026-11-08", entrada_forales = c("31" = 2021L))
  m <- filter(l, geo_id == "28001", corte == "tipologia", grupo == "VC")
  expect_true(all(m$estado == "ausente" & is.na(m$valor)))
  expect_equal(nrow(filter(l, geo_id == "28001", corte == "tipologia_p25", grupo == "VC")), 0L)
  # Municipio de una sección con una cifra distinta de la de su sección
  distinta <- mutate(s, alquiler_m2_p50 = ifelse(nivel == "municipio" & codigo == "28002" & tipologia == "VC", 7, alquiler_m2_p50))
  expect_equal(unique(descuadres_serpavi(distinta)$motivo), "seccion")
  # Una diferencia de redondeo (cuatro decimales en una hoja, todos en la otra) no es un descuadre
  redondeo <- mutate(s, alquiler_mes_p50 = ifelse(nivel == "municipio" & codigo == "28002" & tipologia == "VC",
                                                  500.00003, alquiler_mes_p50))
  expect_equal(nrow(descuadres_serpavi(redondeo)), 0L)
})

test_that("estados: dato, secreto (nunca 0) y ausente; cuartiles solo con dato; forales desde su entrada", {
  s <- serpavi_inventado()
  l <- armonizar_mivau_serpavi(s, version = "2026-11-08", entrada_forales = c("31" = 2021L))
  expect_silent(validar_tabla_larga(l, vocabulario = voc))
  fila <- function(geo, a, ind, corte, grupo) filter(l, geo_id == geo, anio == a, indicador == ind, corte == !!corte, grupo == !!grupo)
  expect_equal(fila("2800101001", 2020L, "alquiler_mes", "tipologia", "VC")$valor, 800)
  expect_equal(fila("2800101001", 2020L, "alquiler_mes", "tipologia_p25", "VC")$valor, 640)
  expect_equal(fila("2800101001", 2020L, "alquiler_m2", "tipologia_p75", "VC")$valor, 800 / 60)
  secreto <- fila("2800101001", 2020L, "alquiler_mes", "tipologia", "VU")
  expect_equal(secreto$estado, "secreto")
  expect_true(is.na(secreto$valor))
  expect_equal(nrow(fila("2800101001", 2020L, "alquiler_mes", "tipologia_p25", "VU")), 0L)
  expect_equal(fila("2800101002", 2020L, "alquiler_mes", "tipologia", "VU")$estado, "ausente")   # 0 testigos
  expect_equal(fila("2800201001", 2020L, "alquiler_mes", "tipologia", "VU")$estado, "ausente")   # sin recuento
  expect_false(any(l$valor == 0, na.rm = TRUE))
  # Foral: ausente antes de entrar, con dato y secreto después
  expect_equal(fila("3100101001", 2020L, "alquiler_mes", "tipologia", "VC")$estado, "ausente")
  expect_equal(fila("3100101001", 2021L, "alquiler_mes", "tipologia", "VC")$estado, "dato")
  expect_equal(fila("3100101001", 2021L, "alquiler_mes", "tipologia", "VU")$estado, "secreto")
  expect_equal(fila("15", 2020L, "alquiler_mes", "tipologia", "VC")$estado, "ausente")
  # España no tiene medianas: fuera. Sin filas «total» (el SERPAVI no da una mediana conjunta)
  expect_false(any(l$nivel == "nacional"))
  expect_false(any(l$corte == "total"))
  expect_equal(unique(l$geo_ref), "2021")
  # Si la fuente publicara una foral antes del año de la ruptura, se queda fuera y la alerta lo dice
  tarde <- armonizar_mivau_serpavi(s, version = "2026-11-08", entrada_forales = c("31" = 2022L))
  expect_true(all(tarde$estado[startsWith(tarde$geo_id, "31") & tarde$anio == 2021L] == "ausente"))
  expect_equal(comprobar_mivau_serpavi(s, entrada_forales = c("31" = 2022L)) |> filter(id == "serpavi_forales") |>
                 pull(calculado), 2021)
})

test_that("los municipios y distritos sin secciones en el seccionado de 2021 quedan fuera", {
  s <- bind_rows(serpavi_inventado(),
                 serpavi_inventado() |> filter(nivel == "municipio", codigo == "28002") |>
                   mutate(codigo = "28003", testigos = NA_real_, across(starts_with("alquiler"), ~ NA_real_)))
  l <- armonizar_mivau_serpavi(s, version = "2026-11-08", entrada_forales = c("31" = 2021L))
  expect_false("28003" %in% l$geo_id)
})

test_that("el resumen cuenta secciones por estado y la cobertura por provincia", {
  l <- armonizar_mivau_serpavi(serpavi_inventado(), version = "2026-11-08", entrada_forales = c("31" = 2021L))
  r <- resumen_serpavi(l)
  expect_equal(filter(r$estados, anio == 2020L, grupo == "VC")$dato, 2L)
  expect_equal(filter(r$provincias, provincia == "28", anio == 2021L)$cobertura, 100 * 2 / 3)
})
