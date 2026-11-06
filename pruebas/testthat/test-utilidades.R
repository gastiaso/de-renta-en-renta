# Utilidades comunes (R/comun_utilidades.R)

source(file.path("..", "..", "R", "comun_utilidades.R"), encoding = "UTF-8")

test_that("el código de sección tiene 10 dígitos con ceros", {
  expect_equal(codigo_seccion(28, 79, 1, 1), "2807901001")
  expect_equal(codigo_seccion("01", "059", "02", "005"), "0105902005")
})

test_that("con_ceros respeta los valores ausentes", {
  expect_equal(con_ceros(c(5, NA), 3), c("005", NA))
})

test_that("el SMI neto de 2026 repartido en 12 ronda los 1.332 euros", {
  # RD 126/2026: 1.221 € × 14 = 17.094 € brutos; exento de IRPF; cotizaciones ≈ 6,5 %
  expect_equal(round(neto_mensual(17094, 0.065)), 1332)
})
