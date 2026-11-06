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
    peso_persona = c(1, 1, 2, 1, 1, 1, 1, 1, 1)
  )
)

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
