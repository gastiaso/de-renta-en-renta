# Utilidades comunes (R/comun_utilidades.R)

source(file.path("..", "..", "R", "comun_utilidades.R"), encoding = "UTF-8")

test_that("el código de sección tiene 10 dígitos con ceros", {
  expect_equal(codigo_seccion(28, 79, 1, 1), "2807901001")
  expect_equal(codigo_seccion("01", "059", "02", "005"), "0105902005")
})

test_that("redondear_empate_arriba sube los empates exactos que sprintf() baja", {
  expect_equal(redondear_empate_arriba(c(3.465, 7.575, 100.005, 2.2125, 5.815)), c(3.47, 7.58, 100.01, 2.21, 5.82))
  expect_equal(as.numeric(sprintf("%.2f", 3.465)), 3.46)   # el binario de 3,465 queda por debajo
  expect_equal(redondear_empate_arriba(c(-3.465, 0, NA)), c(-3.47, 0, NA))
  expect_equal(redondear_empate_arriba(12.25, 1L), 12.3)
})

test_that("con_ceros respeta los valores ausentes", {
  expect_equal(con_ceros(c(5, NA), 3), c("005", NA))
})

test_that("el SMI neto de 2026 repartido en 12 ronda los 1.332 euros", {
  # RD 126/2026: 1.221 € × 14 = 17.094 € brutos; exento de IRPF; cotizaciones ≈ 6,5 %
  expect_equal(round(neto_mensual(17094, 0.065)), 1332)
})
