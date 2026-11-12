# Otros gastos de vivienda de los inquilinos (decisión del autor, 12-nov-2026; R/fuente_ine_ecv_gastos.R):
# lectura de los ficheros Td y Th de la ECV, mediana ponderada de HH070 - HH060 de España por el factor
# de cada comunidad (con las olas juntas; sin muestra, la cifra de España), compuerta,
# datos/otros_gastos.json y las cuentas de la web
# con los casos de pruebas/datos/otros_gastos_inventado.json, que comprueba también
# pruebas/web/otros_gastos.test.mjs (R y la página dan lo mismo). Todo con datos inventados.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

CCAA_PRUEBA <- tibble::tibble(codigo = c("02", "13", "18"), nombre_ine = c("Aragón", "Madrid", "Ceuta"),
                              nuts2 = c("ES24", "ES30", "ES63"))

# Ficheros Td y Th inventados: `hogares` con region, peso, tenencia, alquiler y gasto total.
csv_ecv_inventado <- function(hogares, anio = 2024L) {
  dir <- tempfile("ecv_")
  dir.create(dir)
  id <- sprintf("%d%05d", anio, seq_len(nrow(hogares)))
  na_vacio <- function(x) ifelse(is.na(x), "", format(x, trim = TRUE, scientific = FALSE))
  d <- data.frame(DB010 = anio, DB020 = "ES", DB030 = id, DB040 = hogares$region, DB090 = hogares$peso, DB100 = "1")
  h <- data.frame(HB010 = anio, HB030 = id, HH021 = hogares$tenencia, HH060 = na_vacio(hogares$alquiler),
                  HH070 = na_vacio(hogares$gasto))
  rutas <- file.path(dir, sprintf(c("esudb%02dd.csv", "esudb%02dh.csv"), anio %% 100))
  utils::write.csv(d, rutas[1], row.names = FALSE, quote = FALSE)
  utils::write.csv(h, rutas[2], row.names = FALSE, quote = FALSE)
  rutas
}

# Aragón con 60 inquilinos de mercado (otros gastos de 101 a 160 €), Madrid con 70 (de 201 a 270 €) y
# Ceuta con 10 (300 €): menos que el mínimo, toma la cifra de España. Más propietarios y un inquilino
# por debajo del precio de mercado y otro sin alquiler, que no cuentan.
hogares_inventados <- function() {
  ar <- tibble::tibble(region = "ES24", peso = 1, tenencia = 3L, alquiler = 500, gasto = 500 + 101:160)
  ma <- tibble::tibble(region = "ES30", peso = 2, tenencia = 3L, alquiler = 800, gasto = 800 + 201:270)
  ce <- tibble::tibble(region = "ES63", peso = 1, tenencia = 3L, alquiler = 400, gasto = 700)
  ce <- ce[rep(1, 10), ]
  otros <- tibble::tibble(region = c("ES30", "ES30", "ES24"), peso = 1, tenencia = c(1L, 4L, 3L),
                          alquiler = c(NA, 300, NA), gasto = c(100, 900, 400))
  dplyr::bind_rows(ar, ma, ce, otros)
}

test_that("lee el Td y el Th y se queda con los inquilinos de mercado con los dos importes", {
  x <- leer_ine_ecv_gastos(csv_ecv_inventado(hogares_inventados()))
  expect_equal(nrow(x), 143)
  expect_equal(unique(x$anio), 2024L)
  h <- otros_gastos_hogares(x)
  expect_equal(nrow(h), 140)
  expect_true(all(h$tenencia == 3L))
  expect_equal(h$otros_gastos[1:3], 101:103)
})

test_that("la cifra de una comunidad es la de España de la ola por su factor, y la de España sin muestra", {
  x <- leer_ine_ecv_gastos(csv_ecv_inventado(hogares_inventados()))
  g <- calcular_otros_gastos_ecv(x, CCAA_PRUEBA, minimo = 50)
  es <- g[g$geo_id == "00", ]
  # España: 60 hogares de peso 1 (101 a 160), 70 de peso 2 (201 a 270) y 10 de peso 1 (300); peso
  # total 210, la mitad 105: el valor 105.º de la lista ordenada con sus pesos (60 + 2 × 23 = 106) es 223
  expect_equal(es$n_hogares, 140L)
  expect_equal(es$mediana, 223)
  expect_equal(es$valor, 223)
  expect_equal(es$factor, 1)
  # Con una sola ola, el factor es la mediana propia entre la de España: 130 / 223 y 235 / 223
  aragon <- g[g$geo_id == "02", ]
  expect_equal(aragon$mediana, 130)             # la mitad de 60: el 30.º, 130
  expect_equal(aragon$factor, 0.583)
  expect_equal(aragon$n_factor, 60L)
  expect_equal(aragon$valor, 130)               # 223 × 0,583 = 130,009
  madrid <- g[g$geo_id == "13", ]
  expect_equal(madrid$mediana, 235)             # pesos iguales: el 35.º de 70, 235
  expect_equal(madrid$factor, 1.054)
  expect_equal(madrid$valor, 235)               # 223 × 1,054 = 235,042
  ceuta <- g[g$geo_id == "18", ]
  expect_true(ceuta$espana)
  expect_equal(ceuta$mediana, 300)
  expect_equal(ceuta$factor, 1)
  expect_equal(ceuta$valor, 223)
  expect_false(any(g$espana[g$geo_id != "18"]))
  # Una comunidad sin hogares también tiene cifra (la de España)
  g2 <- calcular_otros_gastos_ecv(x, dplyr::bind_rows(CCAA_PRUEBA, tibble::tibble(codigo = "17", nombre_ine = "Rioja", nuts2 = "ES23")), minimo = 50)
  expect_equal(g2$valor[g2$geo_id == "17"], 223)
  expect_equal(g2$n_hogares[g2$geo_id == "17"], 0L)
  expect_equal(g2$n_factor[g2$geo_id == "17"], 0L)
  # Con un mínimo de 5, Ceuta tiene su factor: 300 / 223 = 1,345 y 223 × 1,345 = 299,935
  expect_equal(calcular_otros_gastos_ecv(x, CCAA_PRUEBA, minimo = 5)$valor[3 + 1], 299.9)
})

test_that("el factor sale de las olas juntas: el nivel lo da España y la diferencia, la comunidad", {
  # Segunda ola con todos los gastos al doble, y Ceuta con 45 hogares más: entre las dos olas llega al mínimo
  h1 <- hogares_inventados()
  h2 <- dplyr::bind_rows(h1, h1[rep(which(h1$region == "ES63")[1], 35), ])
  h2$gasto <- h2$alquiler + 2 * (h2$gasto - h2$alquiler)
  x <- dplyr::bind_rows(leer_ine_ecv_gastos(csv_ecv_inventado(h1, 2024L)), leer_ine_ecv_gastos(csv_ecv_inventado(h2, 2025L)))
  g <- calcular_otros_gastos_ecv(x, CCAA_PRUEBA, minimo = 50)
  es <- g[g$geo_id == "00", ]
  expect_equal(es$anio, c(2024L, 2025L))
  expect_equal(es$n_factor, rep(140L + 175L, 2))
  ceuta <- g[g$geo_id == "18", ]
  expect_equal(ceuta$n_hogares, c(10L, 45L))
  expect_equal(ceuta$n_factor, c(55L, 55L))     # 10 + 45 observaciones: ya tiene factor
  expect_false(any(ceuta$espana))
  # Un factor por comunidad, el mismo en las dos olas, y la cifra es la de España de la ola por él
  for (c in c("02", "13", "18")) {
    f <- g[g$geo_id == c, ]
    expect_equal(length(unique(f$factor)), 1L)
    expect_equal(f$valor, redondear_1(es$valor * f$factor))
  }
  # Los factores, por definición: mediana ponderada de lo que paga cada hogar entre la mediana de
  # España de su ola, con cada ola pesando lo mismo
  h <- otros_gastos_con_ccaa(x, CCAA_PRUEBA)
  f <- otros_gastos_factores(h, CCAA_PRUEBA, minimo = 50)
  r <- otros_gastos_relativos(h)
  expect_equal(as.numeric(tapply(r$peso_ola, r$anio, sum)), c(1, 1))
  for (c in c("02", "13", "18")) {
    rc <- r[r$codigo == c, ]
    expect_equal(f$factor_propio[f$geo_id == c], cuantil_ponderado(rc$relativo, rc$peso_ola, 0.5))
  }
  expect_equal(f$factor, redondear_3(f$factor_propio))
  # La compuerta pasa con dos olas (con el rango abierto: los gastos de la segunda van al doble)
  comprobado <- comprobar_otros_gastos(g, x, CCAA_PRUEBA, minimo = 50, rango = c(50, 1000))
  expect_true(all(comprobado$calculado == comprobado$referencia))
})

test_that("la compuerta pasa con datos sanos y avisa de lo que se aparta", {
  x <- leer_ine_ecv_gastos(csv_ecv_inventado(hogares_inventados()))
  g <- calcular_otros_gastos_ecv(x, CCAA_PRUEBA, minimo = 50)
  c <- comprobar_otros_gastos(g, x, CCAA_PRUEBA, minimo = 50)
  expect_setequal(c$id, c("otros_gastos_cobertura", "otros_gastos_negativos", "otros_gastos_rango", "otros_gastos_hogares",
                          "otros_gastos_mediana", "otros_gastos_minimo", "otros_gastos_factor"))
  expect_true(all(c$calculado == c$referencia))
  # Un hogar con el gasto total por debajo del alquiler, una cifra fuera de rango y una marca mal puesta
  x2 <- x
  x2$gasto_vivienda_mes[1] <- 100
  expect_equal(comprobar_otros_gastos(g, x2, CCAA_PRUEBA, minimo = 50)$calculado[2], 1)
  g2 <- g
  g2$valor[g2$geo_id == "18"] <- 400
  g2$espana[g2$geo_id == "02"] <- TRUE
  c2 <- comprobar_otros_gastos(g2, x, CCAA_PRUEBA, minimo = 50)
  expect_equal(c2$calculado[c2$id == "otros_gastos_rango"], 1)
  expect_equal(c2$calculado[c2$id == "otros_gastos_minimo"], 1)
  expect_equal(c2$calculado[c2$id == "otros_gastos_factor"], 1)   # la cifra de Ceuta ya no es la de España por su factor
  # Un factor cambiado en la tabla: no cuadra con el recalculado ni da la cifra
  g3 <- g
  g3$factor[g3$geo_id == "02"] <- 0.9
  expect_equal(comprobar_otros_gastos(g3, x, CCAA_PRUEBA, minimo = 50)$calculado[7], 2)
  # Las comprobaciones tienen su fila en el inventario
  ref <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  expect_true(all(c(c$id, "web_otros_gastos") %in% ref$id))
})

test_that("datos/otros_gastos.json: ida y vuelta", {
  x <- leer_ine_ecv_gastos(csv_ecv_inventado(hogares_inventados()))
  g <- calcular_otros_gastos_ecv(x, CCAA_PRUEBA, minimo = 50)
  dir <- tempfile("web_")
  ruta <- exportar_web_otros_gastos(g, dir_web = dir, minimo = 50)
  j <- jsonlite::fromJSON(ruta, simplifyVector = FALSE)
  expect_equal(j$minimo_hogares, 50)
  expect_equal(unlist(j$anios), 2024L)
  expect_equal(j$cifras[["2024"]][["00"]], list(v = 223, n = 140L))
  expect_equal(j$cifras[["2024"]][["18"]], list(v = 223, espana = TRUE))
  expect_equal(j$cifras[["2024"]][["02"]], list(v = 130))
  expect_equal(j$factores[["02"]], list(f = 0.583, n = 60L))
  expect_equal(j$factores[["18"]], list(f = 1, n = 10L, espana = TRUE))
  expect_equal(comprobar_web_otros_gastos(g, ruta)$calculado, 0)
  g$valor[1] <- g$valor[1] + 0.1
  expect_equal(comprobar_web_otros_gastos(g, ruta)$calculado, 1)
  g$factor[g$geo_id == "13"] <- 1.1
  expect_equal(comprobar_web_otros_gastos(g, ruta)$calculado, 2)
})

test_that("R y la página dan la misma cuenta (pruebas/datos/otros_gastos_inventado.json)", {
  casos <- jsonlite::fromJSON(file.path("..", "..", "pruebas", "datos", "otros_gastos_inventado.json"))
  s <- casos$sueldo
  expect_equal(sueldo_con_otros_gastos(s$alquiler_mes, s$otros, s$umbral), s$esperado, tolerance = 1e-12)
  m <- casos$minimo
  expect_equal(sueldo_con_otros_gastos(m$alquiler_m2 * m$superficie, m$otros, m$umbral), m$esperado, tolerance = 1e-12)
  l <- casos$llega
  expect_equal(ratio_con_otros_gastos(l$alquiler, l$otros, l$ingreso), l$ratio, tolerance = 1e-12)
  # Euros que quedan, cada término redondeado como Math.round() de la página
  expect_equal(redondear_como_js(l$ingreso) - redondear_como_js(l$alquiler) - redondear_como_js(l$otros), l$euros)
  expect_equal(anio_ecv_para(casos$anios$alquiler, casos$anios$olas), casos$anios$esperado)
})

test_that("el supuesto del mínimo de hogares está en el inventario", {
  expect_equal(otros_gastos_minimo(), 50)
  expect_true("otros_gastos_vivienda" %in% SUPUESTOS_INVENTARIO$id)
})
