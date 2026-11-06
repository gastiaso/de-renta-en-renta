# Compuerta de publicación (R/comun_validar.R)

referencias_prueba <- tibble::tibble(
  id = c("a", "b"),
  tolerancia = c("±0,1 puntos", "exacto"),
  tipo = c("bloqueo", "alerta")
)

test_that("las tolerancias del inventario se leen como números", {
  expect_equal(leer_tolerancia(c("±0,1 puntos", "exacto", "±0,5 %", "a fijar")),
               c(0.1, 0, 0.5, NA))
})

test_that("dentro de tolerancia pasa; fuera, el bloqueo para y la alerta avisa", {
  ok <- validar_referencias(tibble::tibble(id = "a", detalle = "ES", calculado = 7.17, referencia = 7.2),
                            referencias_prueba)
  expect_true(ok$correcto)
  expect_error(validar_referencias(tibble::tibble(id = "a", detalle = "ES", calculado = 7.4, referencia = 7.2),
                                   referencias_prueba), "no pasa")
  expect_warning(validar_referencias(tibble::tibble(id = "b", detalle = "ES", calculado = 3, referencia = 2),
                                     referencias_prueba), "Alertas")
})

test_that("una comprobación sin fila en el inventario es un error", {
  expect_error(validar_referencias(tibble::tibble(id = "z", detalle = "", calculado = 1, referencia = 1),
                                   referencias_prueba), "sin fila")
})
