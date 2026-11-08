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
  expect_true(any(grepl("^\\.tramo-6 \\{", css)))
  comp <- comprobar_contrastes(tokens, ruta)
  expect_equal(comp$calculado[comp$id == "contraste_texto"], 0)
  expect_equal(comp$calculado[comp$id == "rampa_contorno"], 0)
  expect_true(all(abs(comp$calculado[comp$id == "contraste_declarado"]) <= 0.05))
  expect_true(any(grepl("^rampa 6 crema$", comp$detalle[comp$id == "contraste_declarado"])))
})

test_that("la rampa tiene seis pasos que se distinguen también con daltonismo", {
  expect_length(tokens$rampa_secuencial$pasos, MAX_CORTES_WEB + 1L)   # un paso por tramo del mapa más detallado
  hex <- vapply(tokens$rampa_secuencial$pasos, `[[`, "", "hex")
  d <- distancias_rampa(hex)
  expect_setequal(unique(d$vision), c("normal", "protanopia", "deuteranopia", "tritanopia"))
  expect_true(all(d$distancia >= DELTA_MINIMA_RAMPA))
  expect_true(all(d$baja_claridad))
  # OKLab: el blanco tiene claridad 1 y el negro, 0
  expect_equal(as.numeric(oklab(rgb_lineal("#ffffff"))[1, 1]), 1, tolerance = 1e-6)
  expect_equal(as.numeric(oklab(rgb_lineal("#000000"))[1, 1]), 0, tolerance = 1e-9)
  # Dos pasos casi iguales o una rampa que vuelve a aclarar: la compuerta lo ve
  mala <- tokens
  mala$rampa_secuencial$pasos[[3]]$hex <- mala$rampa_secuencial$pasos[[2]]$hex
  ruta <- generar_tokens_css(mala, tempfile(fileext = ".css"))
  comp <- comprobar_contrastes(mala, ruta)
  expect_true(all(comp$calculado[comp$id == "rampa_daltonismo"] > 0))
  expect_equal(nrow(filter(comp, id == "rampa_daltonismo")), 4L)
})
