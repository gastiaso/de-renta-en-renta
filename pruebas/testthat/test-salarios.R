# Indicador 7 (R/fuente_aeat_salarios.R) y percentil salarial (R/percentil_salarial.R), con cifras
# inventadas con la estructura de las tablas de la AEAT.

# Tabla provincial leída (leer_aeat_salarios()) de un año: España, Aragón con Huesca y Zaragoza,
# «Comunidad de Madrid» sin provincias y «Ciudad de Ceuta», en dos tramos de edad.
leidas_inventadas <- function(anio = 2015L) {
  base <- tibble::tibble(
    nombre = c("Total", "Aragón", "Huesca", "Zaragoza", "Comunidad de Madrid", "Ciudad de Ceuta"),
    nivel_fila = c(0L, 1L, 2L, 2L, 1L, 1L), grupo = c(0L, 1L, 1L, 1L, 2L, 3L),
    asalariados = c(410, 100, 30, 70, 300, 10), salarios = c(569000, 124000, 33000, 91000, 435000, 10000))
  bind_rows(mutate(base, edad = "Total"),
            mutate(base, edad = "De 26 a 35 años", salarios = salarios / 2),
            mutate(base, edad = "De 18 a 25 años")) |>
    mutate(anio = as.integer(anio), salario_medio = as.numeric(sprintf("%.0f", salarios / asalariados)))
}
provincias_inv <- tibble::tibble(provincia = c("22", "50", "28", "51"), nombre_ine = c("Huesca", "Zaragoza", "Madrid", "Ceuta"),
                                 nombre_aeat = c("Huesca", "Zaragoza", "Madrid, Comunidad de", NA))
ccaa_inv <- tibble::tibble(codigo = c("02", "13", "18"), nombre_ine = c("Aragón", "Madrid, Comunidad de", "Ceuta"),
                           nuts2 = c("ES24", "ES30", "ES63"))

test_that("indicador 7: códigos del INE, comunidades de una provincia y solo los tramos de la tabla larga", {
  s <- codificar_aeat_salarios(leidas_inventadas(), provincias_inv, ccaa_inv)
  expect_setequal(unique(s$edad), c("total", "Y26-35"))
  t <- filter(s, edad == "total")
  expect_equal(paste(t$nivel, t$geo_id), c("ccaa 02", "ccaa 13", "ccaa 18", "nacional 00", "provincia 22",
                                            "provincia 28", "provincia 50", "provincia 51"))
  expect_equal(t$ccaa[t$geo_id %in% c("22", "50", "28", "51")], c("02", "13", "02", "18"))
  expect_equal(t$salario_medio[t$nivel == "provincia" & t$geo_id == "28"], 1450)   # la de su comunidad
  expect_error(codificar_aeat_salarios(mutate(leidas_inventadas(), nombre = sub("Huesca", "Uesca", nombre)),
                                       provincias_inv, ccaa_inv), "sin c")
})

test_that("compuerta del indicador 7: lectura, cobertura, suma y media de las provincias", {
  s <- codificar_aeat_salarios(leidas_inventadas(), provincias_inv, ccaa_inv)
  c <- comprobar_aeat_salarios(s, anios = 2015L)
  expect_equal(c$calculado[c$id == "aeat_provincia"], 0)
  expect_equal(c$calculado[c$id == "aeat_salarios_cobertura"], (48 - 4) + (17 - 3))   # faltan las demás
  expect_equal(c$calculado[c$id == "aeat_salarios_suma"], 0)
  expect_lt(c$calculado[c$id == "aeat_salarios_media"], 0.5)
  mal <- mutate(s, salario_medio = if_else(geo_id == "22", salario_medio + 3, salario_medio))
  c2 <- comprobar_aeat_salarios(mal, anios = 2015L)
  expect_equal(c2$calculado[c2$id == "aeat_provincia"], 2)   # Huesca, en los dos tramos
})

test_that("indicador 7 en la tabla larga: total sin desglose, 26–35 con corte de edad y forales ausentes", {
  s <- codificar_aeat_salarios(leidas_inventadas(), provincias_inv, ccaa_inv)
  l <- armonizar_aeat_salarios(s, version = "2026-11-10", anios = 2015L)
  expect_equal(nrow(l), nrow(s) + 2 * 6)   # 4 provincias y 2 comunidades forales, en los dos tramos
  expect_true(all(l$estado[l$geo_id %in% c("01", "20", "31", "48")] == "ausente"))
  expect_true(all(is.na(l$valor[l$estado == "ausente"])))
  expect_equal(l$valor[l$geo_id == "22" & l$corte == "total"], 1100)
  expect_equal(l$grupo[l$geo_id == "22" & l$corte == "edad"], "Y26-35")
  vocabulario <- tibble::tibble(grupo = c("corte", "corte", "edad"), clave = c("total", "edad", "Y26-35"), es = "x", en = "x")
  expect_silent(validar_tabla_larga(l, vocabulario = vocabulario))
})

# Tramos inventados de un año con SMI anual de 10.000 € (1.000 × 10 pagas): España y Aragón, con
# 100 asalariados en cada uno de cuatro tramos; las medias, en el centro (uniforme), salvo la del
# último, abierto, y la del primero de Aragón, desplazada.
smi_inventado <- tibble::tibble(anio = 2019L, mensual = 1000, pagas = 10L)
tramos_inventados <- function() {
  base <- tibble::tibble(tramo = c("De 0 a 0,5 SMI", "De 0,5 a 1 SMI", "De 1 a 1,5 SMI", "Más de 10 SMI", "Total"),
                         desde = c(0, 0.5, 1, 10, NA), hasta = c(0.5, 1, 1.5, NA, NA), asalariados = c(100, 100, 100, 100, 400),
                         salarios = 100 * c(2500, 7500, 12500, 150000, NA))
  base$salarios[5] <- sum(base$salarios[1:4])
  bind_rows(mutate(base, ccaa = "00"),
            mutate(base, ccaa = "02", salarios = replace(salarios, 1, 100 * 2000)) |>
              mutate(salarios = replace(salarios, 5, sum(salarios[1:4])))) |>
    mutate(anio = 2019L, .before = 1)
}
ret_inventadas <- tibble::tibble(anio = 2019L, ccaa = rep(c("00", "02"), each = 2), tramo = "x", personas = 1,
                                 salario_medio = c(0, 1e6, 0, 1e6), retencion = 0.1)

test_that("tramos de salario de la AEAT: límites en euros y densidad lineal con la media de cada tramo", {
  t <- tramos_en_euros(tramos_inventados(), smi_inventado)
  es <- filter(t, ccaa == "00")
  expect_equal(es$a, c(0, 5000, 10000, 100000))
  expect_equal(es$b, c(5000, 10000, 15000, 200000))   # el último, cerrado con su media
  expect_equal(es$s, rep(0, 4))                        # media en el centro: uniforme
  ar <- filter(t, ccaa == "02")
  expect_lt(ar$s[1], 0)                                # media baja: más peso abajo
  # Cuantiles: uniforme en España; en Aragón, la densidad lineal reproduce la media del tramo
  expect_equal(cuantil_tramos_salario(es, c(0.125, 0.5, 0.625)), c(2500, 10000, 12500))
  x <- seq(0, 5000, length.out = 20001)
  dens <- 1 / 5000 + ar$s[1] * (x - 2500)
  expect_equal(sum(x * dens) / sum(dens), 2000, tolerance = 1e-3)
  expect_equal(cuantil_tramos_salario(ar, 0.25), 5000)   # límite del primer tramo
})

test_that("curvas salariales: cuantiles por tramos, a neto con su retención, y percentil interpolado", {
  c <- curvas_salariales(tramos_inventados(), ret_inventadas, smi = smi_inventado,
                         cotizacion = function(a) rep(0.05, length(a)))
  expect_equal(nrow(c), 2 * 99)
  expect_equal(c$bruto_anual[c$ccaa == "00" & c$percentil == 50], 10000)
  expect_equal(c$neto_mensual[c$ccaa == "00" & c$percentil == 50], 10000 * 0.85 / 12)
  es <- c$neto_mensual[c$ccaa == "00"]
  expect_equal(percentil_salarial(es[50], es), 50)
  expect_equal(percentil_salarial((es[50] + es[51]) / 2, es), 50.5)
  expect_equal(percentil_salarial(c(0, 1e6, NA), es), c(0, 100, NA))
  comp <- comprobar_curvas_salariales(c, tramos_inventados(), smi = smi_inventado, anios = 2019L, obligatorias = c("00", "02"))
  expect_true(all(abs(comp$calculado) < 1e-9))
  # Un tramo cuya media no cabe en sus límites (otro SMI): percentil_limites
  mal <- mutate(tramos_inventados(), salarios = if_else(ccaa == "00" & desde %in% 0.5, 100 * 12000, salarios))
  c2 <- comprobar_curvas_salariales(c, mal, smi = smi_inventado, anios = 2019L, obligatorias = c("00", "02"))
  expect_equal(c2$calculado[c2$id == "percentil_limites"], 1)
})

test_that("salarios.json: ida y vuelta con las curvas redondeadas al euro", {
  c <- curvas_salariales(tramos_inventados(), ret_inventadas, smi = smi_inventado,
                         cotizacion = function(a) rep(0.05, length(a)))
  dir <- tempfile()
  dir.create(file.path(dir, "datos"), recursive = TRUE)
  jsonlite::write_json(salarios_web(c), file.path(dir, "datos", "salarios.json"), auto_unbox = TRUE, digits = NA)
  w <- jsonlite::read_json(file.path(dir, "datos", "salarios.json"), simplifyVector = TRUE)
  expect_equal(w$percentiles, 1:99)
  expect_equal(w$anios[["2019"]][["00"]][50], round(10000 * 0.85 / 12))
  expect_true(all(comprobar_salarios_web(c, dir)$calculado == 0))
  w$anios[["2019"]][["02"]][3] <- 0
  jsonlite::write_json(w, file.path(dir, "datos", "salarios.json"), auto_unbox = TRUE, digits = NA)
  expect_equal(comprobar_salarios_web(c, dir)$calculado, c(1, 0))
})
