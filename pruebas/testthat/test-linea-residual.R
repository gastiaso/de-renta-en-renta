# Línea de ingreso residual (tarea 65; R/linea_residual.R): cuantías del IMV y de la pensión no
# contributiva, umbral de la ECV, líneas por año y tipo de hogar, compuertas, fichero de la web y muestra.
# Datos inventados con la forma de los del BOE y del INE.

xml_norma <- function(dir, anio, id, frase) {
  ruta <- file.path(dir, paste0(anio, "_", id, ".xml"))
  writeLines(c('<?xml version="1.0" encoding="UTF-8"?>', "<documento><metadatos>",
               sprintf("<identificador>%s</identificador>", id), "</metadatos><texto>",
               "<p>La pensión mínima de viudedad queda fijada en 9.999,99 euros anuales.</p>",
               sprintf("<p>%s</p>", frase), "</texto></documento>"), ruta, useBytes = TRUE)
  ruta
}

cuantias_inventadas <- function() {
  tibble::tibble(
    anio = c(2019L, 2020L, 2022L, 2022L, 2024L, 2026L), desde = c(1L, 1L, 1L, 4L, 1L, 1L),
    tipo = c("pnc", "imv", "imv", "imv", "imv", "imv"), linea_anual = c(5488, 5538, 5899.6, 6784.54, 7250.6, 8803.2),
    norma_linea = "norma", pnc_anual = c(5488, 5538.4, 5899.6, NA, 7250.6, 8803.2), norma_pnc = "norma",
    boe_pnc = c("A", "B", "C", NA, "E", "D"), xml_pnc = c(FALSE, TRUE, TRUE, FALSE, FALSE, TRUE),
    imv_mes_publicado = c(NA, 461.5, NA, NA, 604.21, 733.6), imv_dos_mes_publicado = c(NA, NA, NA, NA, 785.48, 953.68),
    nota = NA_character_
  )
}

umbral_inventado <- function() {
  tibble::tibble(ola = c(2024L, 2025L, 2024L, 2025L, 2025L), valor = c(11584.4, 12220.4, 24327.2, 25662.8, 14093.3),
                 hogar = c("una_persona", "una_persona", "dos_adultos_dos_menores", "dos_adultos_dos_menores", "una_persona"),
                 imputado = c(FALSE, FALSE, FALSE, FALSE, TRUE), serie = "x")
}

test_that("cifra_pnc_texto: la cantidad tras «no contributiva» en sus tres redacciones", {
  expect_equal(cifra_pnc_texto("la cuantía de las pensiones de jubilación e invalidez, en su modalidad no contributiva, queda fijada en 5.136,60 euros íntegros anuales."), 5136.6)
  expect_equal(cifra_pnc_texto("3. Pensiones de la Seguridad Social en su modalidad no contributiva: 5.164,60 euros/año"), 5164.6)
  expect_equal(cifra_pnc_texto("las pensiones de invalidez y jubilación en su modalidad no contributiva, de incapacidad y jubilación tendrán un importe anual de 8.803,20 euros"), 8803.2)
  expect_equal(cifra_pnc_texto("no contributiva queda fijada en 5.899,60 euros anuales"), 5899.6)
  # Otra frase antes del punto no cuenta; sin cifra, NA
  expect_true(is.na(cifra_pnc_texto("modalidad no contributiva. La viudedad queda en 9.999,99 euros")))
  expect_true(is.na(cifra_pnc_texto("sin nada")))
})

test_that("leer_boe_pnc: año del nombre del fichero, identificador y cifra", {
  dir <- tempfile("imv"); dir.create(dir)
  r <- c(xml_norma(dir, 2017L, "BOE-A-2016-1", "Pensiones de la Seguridad Social en su modalidad no contributiva: 5.164,60 euros/año"),
         xml_norma(dir, 2026L, "BOE-A-2026-2", "en su modalidad no contributiva tendrán un importe anual de 8.803,20 euros"))
  b <- leer_boe_pnc(r)
  expect_equal(b$anio, c(2017L, 2026L))
  expect_equal(b$id, c("BOE-A-2016-1", "BOE-A-2026-2"))
  expect_equal(b$pnc_anual, c(5164.6, 8803.2))
})

test_that("inventario/cuantias_imv.csv: de 2015 a 2026, PNC antes de 2020, IMV de 2023 a 2026 publicado", {
  cu <- leer_cuantias_imv()
  expect_equal(sort(unique(cu$anio)), 2015:2026)
  expect_true(all(cu$tipo[cu$anio < 2020] == "pnc"))
  expect_true(all(cu$tipo[cu$anio >= 2020] == "imv"))
  expect_equal(cu$linea_anual[cu$anio == 2026], 8803.2)
  expect_equal(cu$imv_mes_publicado[cu$anio == 2026], 733.6)
  expect_equal(cu$imv_dos_mes_publicado[cu$anio == 2026], 953.68)
  # Tarea 65 (decisiones del 17-nov-2026): las de la Seguridad Social de 2023 a 2025, truncadas al céntimo
  expect_equal(cu$imv_mes_publicado[cu$anio %in% 2023:2025], c(565.37, 604.21, 658.81))
  expect_equal(cu$imv_dos_mes_publicado[cu$anio %in% 2023:2025], c(734.99, 785.48, 856.46))
  expect_equal(cu$desde[cu$anio == 2022], c(1L, 4L))
  # Cada fila con xml_pnc lleva su identificador del BOE
  expect_true(all(!is.na(cu$boe_pnc[cu$xml_pnc])))
})

test_that("calcular_lineas_residual: IMV mensual truncado al céntimo, 2022 ponderado, dos adultos × 1,3; ECV / 12 y × 1,5, año de ingresos", {
  l <- calcular_lineas_residual(cuantias_inventadas(), umbral_inventado())
  v <- function(linea, anio, hogar) l$valor[l$linea == linea & l$anio == anio & l$hogar == hogar]
  expect_equal(v("imv", 2026, "una_persona"), 733.60)
  expect_equal(v("imv", 2026, "dos_adultos"), 953.68)
  expect_equal(v("imv", 2020, "una_persona"), 461.50)
  expect_equal(v("imv", 2019, "una_persona"), 457.33)
  # Truncado, como la Seguridad Social: 7.250,60 / 12 = 604,2166… → 604,21 (redondeado, 604,22)
  expect_equal(v("imv", 2024, "una_persona"), 604.21)
  expect_equal(v("imv", 2024, "dos_adultos"), 785.48)
  expect_equal(l$tipo[l$linea == "imv" & l$anio == 2019][1], "pnc")
  # 2022: tres meses de 5.899,60 y nueve de 6.784,54
  expect_equal(v("imv", 2022, "una_persona"), truncar_centimo((3 * 5899.6 + 9 * 6784.54) / 12 / 12))
  # ECV: año de los ingresos (ola − 1); sin alquiler imputado
  expect_equal(v("ecv", 2024, "una_persona"), 1018.37)
  expect_equal(v("ecv", 2024, "dos_adultos"), 1527.55)
  expect_equal(l$ola[l$linea == "ecv" & l$anio == 2024][1], 2025L)
  expect_equal(nrow(l[l$linea == "ecv", ]), 4L)
})

test_that("truncar_centimo: baja al céntimo sin perder un céntimo por el binario", {
  expect_equal(truncar_centimo(c(604.2166, 565.3783, 658.8166, 785.4817)), c(604.21, 565.37, 658.81, 785.48))
  expect_equal(truncar_centimo(8803.2 * 1.3 / 12), 953.68)   # exacta en decimal, 953,679999… en binario
  expect_equal(truncar_centimo(5538 / 12), 461.5)
  expect_equal(truncar_centimo(5150.6 / 12), 429.21)          # PNC de 2016: redondeada, 429,22
})

test_that("ejemplo de la especificación: la tartera de 2026 con 700 € queda por debajo del IMV; sin ingreso, NA", {
  residual <- 1331.91 - 700
  expect_equal(residual, 631.91)
  expect_equal(tramo_residual(residual, 733.6), 2L)
  expect_equal(tramo_residual(c(600, 733.6, 917, 917.01, NA), 733.6), c(2L, 1L, 1L, 0L, NA))
  expect_true(is.na(tramo_residual(500, NA)))
})

test_that("armonizar_lineas_residual: nivel nacional, corte hogar y fuentes del inventario", {
  l <- calcular_lineas_residual(cuantias_inventadas(), umbral_inventado())
  x <- armonizar_lineas_residual(l, "2026-11-13", "2026-11-12")
  expect_true(all(x$geo_id == "00" & x$nivel == "nacional" & x$corte == "hogar" & x$estado == "dato"))
  expect_setequal(unique(x$indicador), c("linea_imv", "linea_pobreza_ecv"))
  expect_setequal(unique(x$fuente), c("boe_imv", "ine_ecv_umbral"))
  expect_setequal(unique(x$grupo), c("una_persona", "dos_adultos"))
  expect_equal(unique(x$version[x$fuente == "ine_ecv_umbral"]), "2026-11-12")
})

test_that("comprobar_lineas_residual: pasa con las cifras buenas y ve una cuantía, una escala o un año que faltan", {
  cu <- cuantias_inventadas()
  u <- umbral_inventado()
  l <- calcular_lineas_residual(cu, u)
  boe <- tibble::tibble(anio = c(2020L, 2022L, 2026L), id = c("B", "C", "D"), pnc_anual = c(5538.4, 5899.6, 8803.2))
  c1 <- comprobar_lineas_residual(l, cu, boe, u)
  expect_true(all(abs(c1$calculado[c1$id == "residual_pnc_boe"] - c1$referencia[c1$id == "residual_pnc_boe"]) < 1e-9))
  expect_true(all(abs(c1$calculado[c1$id == "residual_imv_publicada"] - c1$referencia[c1$id == "residual_imv_publicada"]) <= 0.005))
  expect_true(all(abs(c1$calculado[c1$id == "residual_umbral_ecv"] - c1$referencia[c1$id == "residual_umbral_ecv"]) <= 0.1))
  expect_true(all(c1$calculado[c1$id == "residual_escala"] <= 0.013))
  expect_equal(c1$calculado[c1$id == "residual_umbral_ecv_2025"], 12220.4)
  # Una PNC distinta en el BOE, una línea de dos adultos mal y un año que falta (las inventadas no tienen 2015)
  mal <- comprobar_lineas_residual(dplyr::mutate(l, valor = ifelse(linea == "imv" & anio == 2026 & hogar == "dos_adultos", 950, valor)),
                                   cu, dplyr::mutate(boe, pnc_anual = ifelse(anio == 2020L, 5538, pnc_anual)), u)
  expect_equal(abs(mal$calculado - mal$referencia)[mal$id == "residual_pnc_boe" & mal$anio %in% 2020L], 0.4, tolerance = 1e-9)
  expect_gt(max(mal$calculado[mal$id == "residual_escala"]), 1)
  expect_gt(sum(mal$calculado[mal$id == "residual_serie"]), 0)
})

test_that("datos/lineas_residual.json: ida y vuelta, y la compuerta ve una cifra cambiada", {
  l <- calcular_lineas_residual(cuantias_inventadas(), umbral_inventado())
  dir <- tempfile("web"); dir.create(dir)
  ruta <- exportar_web_lineas_residual(l, dir_web = dir, limites = c(1, 1.25))
  j <- jsonlite::fromJSON(ruta)
  expect_equal(j$imv$anios$`2026`$una_persona, 733.6)
  expect_equal(j$imv$anios$`2019`$tipo, "pnc")
  expect_equal(j$ecv$anios$`2024`$ola, 2025L)
  expect_equal(comprobar_web_lineas_residual(l, ruta)$calculado, 0)
  expect_gt(comprobar_web_lineas_residual(dplyr::mutate(l, valor = valor + (anio == 2026) * 0.01), ruta)$calculado, 0)
})

test_that("otros_gastos_territorio: la cifra de la comunidad de la provincia; sin ella, la de España", {
  og <- tibble::tibble(anio = 2024L, geo_id = c("00", "13", "09"), nivel = c("nacional", "ccaa", "ccaa"), valor = c(145.3, 170, 160))
  terr <- tibble::tibble(nivel = "provincia", codigo = c("28", "08", "41"), superior = c("13", "09", "01"))
  expect_equal(otros_gastos_territorio(c("2807901001", "08019", "41", "13", "00"), c("sc", "municipio", "provincia", "ccaa", "nacional"),
                                       2024L, og, terr), c(170, 160, 145.3, 170, 145.3))
})

test_that("pruebas/datos/residual_muestra.json: residuos y tramos que cuadran con las líneas del año", {
  ruta <- file.path("..", "datos", "residual_muestra.json")
  skip_if_not(file.exists(ruta))
  j <- jsonlite::fromJSON(ruta)
  c <- j$casos
  expect_gt(nrow(c), 500)
  expect_equal(c$residual, c$ingreso - c$alquiler)
  expect_equal(c$residual_gastos, c$ingreso - c$alquiler - c$otros)
  expect_equal(c$hogar == "dos_adultos", c$ficha == "peon" & c$segundo %in% TRUE)
  for (l in c("imv", "ecv")) {
    la <- j$lineas[[l]]$anios[[as.character(j$anio)]]
    expect_equal(c[[paste0("linea_", l)]], ifelse(c$hogar == "dos_adultos", la$dos_adultos, la$una_persona))
    expect_equal(c[[paste0("tramo_", l)]], tramo_residual(c$residual, c[[paste0("linea_", l)]], c(1, 1.25)))
    expect_equal(c[[paste0("tramo_", l, "_gastos")]], tramo_residual(c$residual_gastos, c[[paste0("linea_", l)]], c(1, 1.25)))
  }
})

test_that("remates: sueldo necesario con la línea (alquiler + otros gastos + línea de una persona) y cuenta de la portada", {
  ruta <- file.path("..", "datos", "residual_muestra.json")
  skip_if_not(file.exists(ruta))
  j <- jsonlite::fromJSON(ruta)
  c <- j$casos
  for (l in c("imv", "ecv")) {
    una <- j$lineas[[l]]$anios[[as.character(j$anio)]]$una_persona
    expect_equal(c[[paste0("sueldo_linea_", l)]], c$alquiler_mes + una)
    expect_equal(c[[paste0("sueldo_linea_", l, "_gastos")]], c$alquiler_mes + c$otros_sin_factor + una)
  }
  # No depende de la ficha: una sola cifra por territorio, también con los otros gastos, que van sin el
  # factor de la superficie (19-nov-2026: llevaban el de cada ficha)
  expect_equal(nrow(unique(c[c("geo_id", "nivel", "sueldo_linea_imv")])), nrow(unique(c[c("geo_id", "nivel")])))
  expect_equal(nrow(unique(c[c("geo_id", "nivel", "sueldo_linea_imv_gastos")])), nrow(unique(c[c("geo_id", "nivel")])))
  expect_equal(nrow(unique(c[c("geo_id", "nivel", "otros_sin_factor")])), nrow(unique(c[c("geo_id", "nivel")])))
  p <- j$portada
  expect_equal(nrow(p), 2L)
  expect_true(all(p$encima_ecv <= p$encima_imv & p$encima_imv <= p$con))
})

test_that("calcular_cuenta_portada_residual: secciones con los dos alquileres y lo que queda frente a la línea", {
  larga <- tibble::tibble(
    geo_id = rep(c("0100101001", "0100101002", "0100101003", "01001"), each = 2),
    nivel = rep(c("sc", "sc", "sc", "municipio"), each = 2), anio = 2024L,
    indicador = rep(c("alquiler_m2", "alquiler_mes"), 4), corte = "tipologia", grupo = "VC",
    valor = c(10, 500, 12, 900, NA, 300, 10, 500), estado = "dato")
  l <- tibble::tibble(linea = rep(c("imv", "ecv"), each = 2), anio = 2024L, hogar = rep(c("una_persona", "dos_adultos"), 2),
                      valor = c(600, 780, 1000, 1500))
  terminos <- tibble::tibble(ingreso_tartera = 1237.4)
  x <- calcular_cuenta_portada_residual(larga, terminos, l, anio = 2024L, netos = c(1500, 1100))
  # 1.500: quedan 1.000 y 600 (las dos llegan al IMV; una, a la ECV); 1.100: 600 y 200
  expect_equal(x$con, c(2L, 2L))
  expect_equal(x$encima_imv, c(2L, 1L))
  expect_equal(x$encima_ecv, c(1L, 0L))
})
