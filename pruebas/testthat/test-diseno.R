# Kit de diseño (R/web_estilo.R)

tokens <- jsonlite::read_json(file.path("..", "..", "diseno", "tokens.json"))

test_that("el contraste WCAG reproduce los valores de referencia", {
  expect_equal(contraste_wcag("#000000", "#ffffff"), 21)
  expect_equal(contraste_wcag("#777777", "#777777"), 1)
  expect_equal(round(contraste_wcag(tokens$colores$tinta$hex, tokens$colores$crema$hex), 2),
               tokens$colores$tinta$contraste_crema)
})

test_that("los tramos claros de la rampa llevan contorno en el CSS y los oscuros no", {
  expect_equal(tramos_con_contorno(tokens), c(1L, 2L))
  ruta <- generar_tokens_css(tokens, tempfile(fileext = ".css"))
  css <- readLines(ruta, encoding = "UTF-8")
  expect_true(any(grepl("^\\.tramo-1 \\{.*outline", css)))
  expect_true(any(grepl("^\\.tramo-2 \\{.*outline", css)))
  expect_false(any(grepl("^\\.tramo-3 \\{.*outline", css)))
  expect_true(any(grepl("--color-crema: #f6efe0;", css, fixed = TRUE)))
  comp <- comprobar_contrastes(tokens, ruta)
  expect_equal(comp$calculado[comp$id == "contraste_texto"], 0)
  expect_equal(comp$calculado[comp$id == "rampa_contorno"], 0)
  expect_true(all(abs(comp$calculado[comp$id == "contraste_declarado"]) <= 0.05))
})
