# Sobrecarga por gastos de vivienda, método de Eurostat (R/fuente_ine_ecv.R)

# Seis hogares inventados. Cociente = (gasto × 12 − ayuda) / (renta − ayuda).
ecv_prueba <- list(
  hogares = tibble::tibble(
    anio = 2025L,
    id_hogar           = c("1", "2", "3", "4", "5", "6"),
    region             = c("ES30", "ES30", "ES51", "ES51", "ES51", "ES30"),
    peso_hogar         = 1,
    tenencia           = c(3L, 1L, 3L, 2L, 4L, 2L),
    gasto_vivienda_mes = c(500, 100, 400, NA, 300, 400),
    renta_disponible   = c(12000, 30000, 2000, 20000, 10000, 12000),
    ayuda_vivienda     = c(0, 0, 2400, 0, 1000, NA)
  ),
  personas = tibble::tibble(
    id_persona   = c("101", "102", "201", "301", "401", "402", "403", "501", "601"),
    id_hogar     = c("1", "1", "2", "3", "4", "4", "4", "5", "6"),
    peso_persona = c(1, 1, 2, 1, 1, 1, 1, 1, 1),
    edad         = c(40L, 10L, 70L, 25L, 50L, 50L, 50L, 20L, 66L)
  )
)

test_that("la tasa por edad usa los grupos de Eurostat y el de 15–29 se solapa", {
  r <- calcular_sobrecarga_ecv(ecv_prueba)
  valor <- function(g) r$valor[r$corte == "edad" & r$grupo == g]
  # Menores de 18: solo el 102 (hogar 1, sobrecargado)
  expect_equal(valor("Y_LT18"), 100)
  # 65 y más: el 201 (hogar 2, peso 2, no) y el 601 (hogar 6, en el 40 %, no)
  expect_equal(valor("Y_GE65"), 0)
  # 15–29: el 301 (hogar 3, sobrecargado) y el 501 (hogar 5, no)
  expect_equal(valor("Y15-29"), 50)
})

test_that("las olas agrupadas reparten el peso y marcan la fiabilidad por tamaño de muestra", {
  otra <- ecv_prueba
  otra$hogares$anio <- 2024L
  a <- calcular_sobrecarga_agrupada(list(otra, ecv_prueba))
  mercado <- a[a$corte == "tenencia" & a$grupo == "RENT_MKT" & a$region == "ES30", ]
  expect_equal(mercado$valor, 100)                 # el mismo hogar en las dos olas
  expect_equal(mercado$n_personas, 4L)             # 2 personas × 2 olas
  expect_equal(mercado$fiabilidad, "no publicable")
  expect_equal(unique(a$olas), 2L)
  expect_equal(c(unique(a$anio_inicio), unique(a$anio_fin)), c(2024L, 2025L))
})

test_that("el cociente descuenta las ayudas y trata la renta neta no positiva como sobrecarga", {
  expect_equal(cociente_sobrecarga(500, 12000, 0), 0.5)
  expect_equal(cociente_sobrecarga(300, 10000, 1000), 2600 / 9000)
  expect_equal(cociente_sobrecarga(400, 2000, 2400), Inf)
  expect_true(is.na(cociente_sobrecarga(NA, 20000, 0)))
  expect_equal(cociente_sobrecarga(400, 12000, NA), 0.4)   # sin ayuda declarada = 0
})

test_that("la tasa pondera por persona, excluye hogares sin gasto y usa «más del 40 %»", {
  r <- calcular_sobrecarga_ecv(ecv_prueba)
  valor <- function(c, g) r$valor[r$corte == c & r$grupo == g]
  # Dentro: hogares 1 (2 personas), 2 (peso 2), 3, 5 y 6 → peso 7.
  # Sobrecargados: 1 (0,5) y 3 (renta neta ≤ 0) → peso 3. El 6 está justo en el 40 %: no cuenta.
  expect_equal(valor("total", "TOTAL"), 100 * 3 / 7)
  expect_equal(valor("tenencia", "RENT_MKT"), 100)
  expect_equal(valor("tenencia", "OWN_L"), 0)
  expect_equal(valor("tenencia", "RENT"), 100 * 3 / 4)
  expect_equal(r$n_personas[r$corte == "total"], 6L)
  expect_equal(r$n_hogares[r$corte == "region" & r$grupo == "ES51"], 2L)   # el 4 queda fuera
})

test_that("la comparación con Eurostat se detiene si falta la referencia nacional", {
  r <- calcular_sobrecarga_ecv(ecv_prueba)
  eurostat <- tibble::tibble(conjunto = "ilc_lvho07a", geo = "ES", tenencia = "TOTAL",
                             anio = 2025L, valor = 42.9)
  expect_error(suppressMessages(comprobar_sobrecarga_ecv(r, eurostat)), "no publica")
  eurostat <- bind_rows(eurostat, tibble::tibble(conjunto = "ilc_lvho07c", geo = "ES",
                                                 tenencia = "RENT_MKT", anio = 2025L, valor = 100))
  comp <- suppressMessages(comprobar_sobrecarga_ecv(r, eurostat))
  expect_equal(comp$id, c("sobrecarga_es_total", "sobrecarga_es_mercado"))
})

# Quintiles de renta (pregunta abierta 31): diez hogares de una persona, rentas de 1.000 a 10.000 €
# y una unidad de consumo cada uno; gasto de 100 € al mes (1.200 € al año).
ecv_quintil <- list(
  hogares = tibble::tibble(
    anio = 2025L, id_hogar = as.character(1:10), region = "ES30", peso_hogar = 1, tenencia = 3L,
    gasto_vivienda_mes = 100, renta_disponible = seq(1000, 10000, 1000), ayuda_vivienda = 0, unidades_consumo = 1
  ),
  personas = tibble::tibble(id_persona = paste0(1:10, "01"), id_hogar = as.character(1:10), peso_persona = 1, edad = 40L)
)

test_that("los quintiles de renta usan la renta equivalente y cortes ponderados por persona", {
  expect_equal(cuantil_ponderado(c(5, 1, 3), c(1, 1, 2), c(0.25, 0.5, 0.75)), c(1, 3, 3))
  q <- quintil_renta(ecv_quintil)
  expect_equal(q$quintil, rep(QUINTILES_RENTA, each = 2))   # una renta igual al corte va al quintil de abajo
  dos <- ecv_quintil
  dos$hogares$unidades_consumo[10] <- 10                    # 10.000 € entre 10 unidades: la renta más baja
  expect_equal(quintil_renta(dos)$quintil[10], "QU1")
})

test_that("la sobrecarga por quintil rehace la tasa total y reparte la población en quintos", {
  s <- calcular_sobrecarga_quintil(ecv_quintil)
  expect_equal(s$grupo, QUINTILES_RENTA)
  expect_equal(s$valor, c(100, 0, 0, 0, 0))                # 1.200 € sobre 1.000 y 2.000 € supera el 40 %; sobre 3.000, no
  expect_equal(s$poblacion, rep(20, 5))
  expect_equal(s$fiabilidad, rep("no publicable", 5))      # dos personas por quintil
  total <- calcular_sobrecarga_ecv(ecv_quintil)
  ch <- comprobar_sobrecarga_quintil(s, total)
  expect_equal(ch$calculado[ch$id == "sobrecarga_quintil_total"], ch$referencia[ch$id == "sobrecarga_quintil_total"])
  expect_equal(ch$calculado[ch$id == "sobrecarga_quintil_total"], 20)
  # Sin un quintil, la media no se calcula y la compuerta falla
  ch2 <- comprobar_sobrecarga_quintil(s[-1, ], total)
  expect_true(is.na(ch2$calculado[ch2$id == "sobrecarga_quintil_total"]))
})

test_that("la sobrecarga por quintil se compara con la de Eurostat de su año y para si falta", {
  s <- calcular_sobrecarga_quintil(ecv_quintil)
  total <- calcular_sobrecarga_ecv(ecv_quintil)
  eurostat <- tibble::tibble(conjunto = "ilc_lvho07b", geo = "ES", quintil = c("TOTAL", QUINTILES_RENTA),
                             anio = 2025L, valor = c(20, 99.9, 0, 0, 0.1, 0), bandera = NA_character_)
  ch <- comprobar_sobrecarga_quintil(s, total, eurostat)
  e <- ch[ch$id == "sobrecarga_quintil_eurostat", ]
  expect_equal(e$detalle, paste("ES,", QUINTILES_RENTA))
  expect_equal(e$referencia, c(99.9, 0, 0, 0.1, 0))
  expect_equal(e$calculado, s$valor)
  expect_equal(sum(ch$id == "sobrecarga_quintil_total"), 1L)
  # Otra ola sin cifra de Eurostat: para, en vez de dejar la comprobación sin referencia
  expect_error(comprobar_sobrecarga_quintil(s, total, dplyr::mutate(eurostat, anio = 2024L)), "ilc_lvho07b")
})

test_that("el JSON-stat de Eurostat se lee casilla a casilla, con sus marcas", {
  j <- list(
    id = list("freq", "quant_inc", "geo", "time"), size = list(1L, 2L, 1L, 3L),
    dimension = list(
      freq = list(category = list(index = list(A = 0L))),
      quant_inc = list(category = list(index = list(QU1 = 0L, TOTAL = 1L))),
      geo = list(category = list(index = list(ES = 0L))),
      time = list(category = list(index = list(`2008` = 0L, `2024` = 1L, `2025` = 2L)))
    ),
    value = list(`0` = 31.9, `2` = 27.7, `3` = 9.4, `5` = 7.2),
    status = list(`0` = "b", `3` = "b")
  )
  d <- tabla_jsonstat(j)
  expect_equal(nrow(d), 6L)
  expect_equal(d$quant_inc, rep(c("QU1", "TOTAL"), each = 3))
  expect_equal(d$time, rep(c("2008", "2024", "2025"), 2))
  expect_equal(d$valor, c(31.9, NA, 27.7, 9.4, NA, 7.2))
  expect_equal(d$bandera, c("b", NA, NA, "b", NA, NA))
  j$size <- list(1L, 2L, 1L, 2L)
  expect_error(tabla_jsonstat(j), "JSON-stat")
})
