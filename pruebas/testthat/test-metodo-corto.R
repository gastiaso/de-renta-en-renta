# Cifras del «Método en dos páginas» calculadas en el pipeline (R/cifras_metodo_corto.R; revisión del
# 18-nov-2026), con una tabla larga y una población inventadas.

larga_metodo_corto <- function() {
  f <- function(geo, anio, ind, valor, estado = "dato") {
    tibble::tibble(geo_id = geo, nivel = "sc", anio = anio, indicador = ind, corte = "tipologia", grupo = "VC",
                   valor = valor, estado = estado)
  }
  dplyr::bind_rows(
    f(c("2800101001", "2800101002", "2800101003"), 2015L, "alquiler_m2", c(10, 8, NA), c("dato", "estimado", "secreto")),
    f(c("2800101001", "2800101002", "2800101003"), 2024L, "alquiler_m2", c(14, 12, 9)),
    f(c("2800101001", "2800101002", "2800101003", "2800101004"), 2024L, "alquiler_mes",
      c(900, 700, NA, NA), c("dato", "dato", "secreto", "ausente"))
  )
}

test_that("subida y cobertura del SERPAVI para el método corto", {
  s <- cifra_subida_serpavi(larga_metodo_corto())
  expect_equal(s$secciones, 2L)                         # la 003 no tiene 2015
  expect_equal(s$subida_mediana, stats::median(c(40, 50)))
  pob <- tibble::tibble(anio = 2024L, nivel = "seccion", codigo = c("2800101001", "2800101002", "2800101003", "2800101004"),
                        valor = c(1000, 1000, 500, 500))
  c <- cifra_cobertura_serpavi(larga_metodo_corto(), pob, geo_tabla_identidad(pob$codigo))
  expect_equal(c$pct_secciones, 50)
  expect_equal(c$pct_poblacion, 100 * 2000 / 3000)
})

test_that("la compuerta lee las dos frases del texto y las compara con lo calculado", {
  md <- tempfile(fileext = ".md")
  writeLines(c("De 2015 a 2024, en las 2 secciones con dato los dos años, la mediana de la subida del alquiler por m² del SERPAVI es del 45 %.",
               "  - con menos de 10 contratos no hay cifra: en 2024 tiene dato el 50 % de las secciones, donde vive en torno al 67 % de la población."),
             md, useBytes = TRUE)
  s <- cifra_subida_serpavi(larga_metodo_corto())
  pob <- tibble::tibble(anio = 2024L, nivel = "seccion", codigo = c("2800101001", "2800101002", "2800101003", "2800101004"),
                        valor = c(1000, 1000, 500, 500))
  c <- cifra_cobertura_serpavi(larga_metodo_corto(), pob, geo_tabla_identidad(pob$codigo))
  r <- comprobar_cifras_metodo_corto(s, c, md)
  expect_equal(r$calculado, r$referencia)
  # Una cifra del texto que ya no es la calculada, o una frase reescrita: no pasa
  writeLines(sub("67 %", "83 %", readLines(md, encoding = "UTF-8")), md, useBytes = TRUE)
  r2 <- comprobar_cifras_metodo_corto(s, c, md)
  expect_false(isTRUE(all.equal(r2$calculado, r2$referencia)))
  # Los años de las frases también (19-nov-2026): con las cifras de 2015–2024, «De 2016 a 2024» o «en 2023» no pasan
  ok <- sub("83 %", "67 %", readLines(md, encoding = "UTF-8"))     # el texto bueno de antes
  writeLines(sub("De 2015 a", "De 2016 a", ok), md, useBytes = TRUE)
  r3 <- comprobar_cifras_metodo_corto(s, c, md)
  expect_equal(r3$detalle[r3$calculado != r3$referencia], "primer año de la subida")
  writeLines(sub("en 2024 tiene", "en 2023 tiene", ok), md, useBytes = TRUE)
  r4 <- comprobar_cifras_metodo_corto(s, c, md)
  expect_equal(r4$detalle[r4$calculado != r4$referencia], "año de la cobertura")
  writeLines("Otra cosa.", md)
  expect_true(all(is.na(comprobar_cifras_metodo_corto(s, c, md)$calculado)))
  # El método corto del repositorio tiene las dos frases
  t <- leer_cifras_metodo_corto(file.path("..", "..", "docs", "metodo_corto.md"))
  expect_false(anyNA(t))
})
