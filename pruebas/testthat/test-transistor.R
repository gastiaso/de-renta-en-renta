# Ficha «transistor» (R/fuente_inss_pensiones.R, R/ficha_transistor.R). Datos inventados.

# Tabla de códigos mínima: una comunidad de dos provincias (Aragón), una de una provincia
# (Madrid), una foral (Navarra) y España.
provincias_inss_prueba <- tibble::tribble(
  ~clave_inss,      ~nivel,      ~codigo, ~ccaa,
  "total",          "nacional",  "00",    NA,
  "aragon",         "ccaa",      "02",    "02",
  "huesca",         "provincia", "22",    "02",
  "zaragoza",       "provincia", "50",    "02",
  "madrid_com_de",  "provincia", "28",    "13",
  "navarra",        "provincia", "31",    "15"
)

# Doce meses de un año: Huesca, Zaragoza, Madrid y Navarra, con Aragón y España coherentes.
inss_leidas <- function(anio = 2024L, cambio = 0) {
  bind_rows(lapply(1:12, function(m) {
    p <- tibble::tibble(clave = c("huesca", "zaragoza", "madrid_com_de", "navarra"),
                        pensiones = c(100, 300, 1000, 200) + m, media = c(1000, 1200, 1500, 1400) + m * cambio)
    aragon <- p[1:2, ]
    bind_rows(p,
              tibble::tibble(clave = "aragon", pensiones = sum(aragon$pensiones),
                             media = sum(aragon$pensiones * aragon$media) / sum(aragon$pensiones)),
              tibble::tibble(clave = "total", pensiones = sum(p$pensiones), media = sum(p$pensiones * p$media) / sum(p$pensiones))) |>
      mutate(anio = anio, mes = m, etiqueta = clave, fichero = sprintf("CA%d%02d.xlsx", anio, m))
  }))
}

test_that("el año y el mes salen del nombre del Excel en sus tres formas", {
  expect_equal(inss_mes_de_fichero("/wps/wcm/connect/wss/x/CA2%28072015%29.xlsx?MOD=AJPERES"), c(anio = 2015L, mes = 7L))
  expect_equal(inss_mes_de_fichero("CA2201801.xlsx"), c(anio = 2018L, mes = 1L))
  expect_equal(inss_mes_de_fichero("CA202412.xlsx?x=1"), c(anio = 2024L, mes = 12L))
  expect_true(all(is.na(inss_mes_de_fichero("CA2024.pdf"))))
})

test_that("armonizar: códigos de la tabla fija, sin filas repetidas, y error con una etiqueta desconocida", {
  l <- inss_leidas()
  m <- armonizar_inss_pensiones(bind_rows(l, filter(l, clave == "total")), provincias_inss_prueba)
  expect_equal(nrow(m), 12L * 6L)
  expect_equal(sort(unique(m$codigo[m$nivel == "provincia"])), c("22", "28", "31", "50"))
  expect_error(armonizar_inss_pensiones(mutate(l, clave = sub("huesca", "uesca", clave)), provincias_inss_prueba), "uesca")
})

test_that("media anual ponderada por el número de pensiones de cada mes", {
  m <- armonizar_inss_pensiones(inss_leidas(cambio = 10), provincias_inss_prueba)
  a <- anual_inss_pensiones(m)
  h <- filter(a, codigo == "22")
  n <- 100 + 1:12
  expect_equal(h$media, sum(n * (1000 + 1:12 * 10)) / sum(n))
  expect_equal(h$pensiones, mean(n))
  expect_equal(h$meses, 12L)
})

test_that("la compuerta del INSS cuadra con las cifras publicadas y ve un mes roto", {
  m <- armonizar_inss_pensiones(inss_leidas(), provincias_inss_prueba)
  c1 <- comprobar_inss_pensiones(m, provincias_inss_prueba, anios = 2024L)
  expect_equal(c1$calculado, c(0, 0, 0), tolerance = 1e-9)
  roto <- mutate(m, media = ifelse(codigo == "02" & mes == 5L, media + 3, media),
                 pensiones = ifelse(nivel == "nacional" & mes == 2L, pensiones + 1, pensiones))
  c2 <- comprobar_inss_pensiones(roto, provincias_inss_prueba, anios = 2024L)
  expect_equal(filter(c2, id == "inss_media")$calculado, 3, tolerance = 1e-6)
  expect_equal(filter(c2, id == "inss_suma")$calculado, 1)
  c3 <- comprobar_inss_pensiones(filter(m, !(codigo == "28" & mes == 3L)), provincias_inss_prueba, anios = c(2023L, 2024L))
  expect_equal(filter(c3, id == "inss_cobertura")$calculado, c(6, 1))   # 2023, sin nada; 2024, Madrid sin marzo
})

test_that("clave_comunidad: la misma comunidad escrita de varias formas", {
  expect_equal(clave_comunidad(c("Región de Murcia", "Murcia, Región de")), c("murcia", "murcia"))
  expect_equal(clave_comunidad(c("Comunidad Valenciana", "Comunitat Valenciana")), c("valenciana", "valenciana"))
  expect_equal(clave_comunidad(c("Ciudad de Ceuta", "Ceuta", "Illes Balears", "Balears, Illes")), c("ceuta", "ceuta", "balears", "balears"))
  expect_false(clave_comunidad("Castilla y León") == clave_comunidad("Castilla - La Mancha"))
  expect_equal(clave_comunidad("Total"), "total")
})

# Retenciones inventadas con la forma de leer_aeat_mercado(): España y Aragón, dos tramos, y
# filas de otros bloques y columnas que no cuentan.
grupos_prueba <- function(geo = "comunidad_autonoma") {
  fila <- function(g, tramo, personas, retrib, reten, bloque = "PENSIONES", columna = "Pensionistas") {
    tibble::tibble(bloque, columna, fila = c("Personas", "Retribuciones", "Retenciones"), valor = c(personas, retrib, reten),
                   tramos_de_renta_anual = tramo, g = g)
  }
  x <- bind_rows(
    fila("Total", "De 12001 a 18000", 1000, 15000, 300),          # 15.000 € de media, 2 %
    fila("Total", "De 18001 a 24000", 1000, 21000, 1680),         # 21.000 €, 8 %
    fila("Total", "Total", 2000, 36000, 1980),
    fila("Aragón", "De 12001 a 18000", 100, 1500, 45),        # 3 %
    fila("Aragón", "De 18001 a 24000", 100, 2100, 189),       # 9 %
    fila("Aragón", "De 18001 a 24000", 100, 2100, 999, bloque = "SALARIOS"),
    fila("Aragón", "De 18001 a 24000", 100, 2100, 999, columna = "Asalariados")
  )
  names(x)[names(x) == "g"] <- geo
  x
}
ccaa_prueba <- tibble::tibble(codigo = c("02", "13", "15"), nombre_ine = c("Aragón", "Madrid, Comunidad de", "Navarra, Comunidad Foral de"))

test_that("retenciones de los pensionistas por comunidad (código del INE) y tramo, en las dos ediciones", {
  r <- retenciones_pensiones(grupos_prueba(), 2015L, ccaa_prueba)
  expect_equal(nrow(r), 4L)
  expect_equal(sort(unique(r$ccaa)), c("00", "02"))
  expect_equal(r$retencion[r$ccaa == "02"], c(0.03, 0.09))
  expect_equal(r$salario_medio[r$ccaa == "00"], c(15000, 21000))
  r2 <- retenciones_pensiones(grupos_prueba("distribucion_geografica"), 2024L, ccaa_prueba)
  expect_equal(unique(r2$anio), 2024L)
  desconocida <- mutate(grupos_prueba(), comunidad_autonoma = ifelse(comunidad_autonoma == "Total", "Total", "Atlántida"))
  expect_error(retenciones_pensiones(desconocida, 2015L, ccaa_prueba), "Atl")
})

test_that("neto del transistor: × 14, retención interpolada de su comunidad y año; forales con la de España", {
  ret <- bind_rows(retenciones_pensiones(grupos_prueba(), 2024L, ccaa_prueba))
  anual <- tibble::tibble(anio = 2024L, nivel = c("provincia", "provincia", "provincia", "nacional"),
                          codigo = c("22", "31", "28", "00"), ccaa = c("02", "15", "13", NA),
                          meses = 12L, pensiones = 100, media = c(18000, 18000, 18000, 18000) / 14)
  t <- calcular_transistor(anual, ret)
  expect_equal(nrow(t), 3L)   # solo provincias
  h <- filter(t, provincia == "22")
  expect_equal(h$bruto_anual, 18000)
  expect_equal(h$retencion, 0.03 + (18000 - 15000) / 6000 * 0.06)          # interpolada en Aragón: 6 %
  expect_equal(h$neto_mensual, 18000 * (1 - 0.06) / 12)
  expect_equal(h$estado, "dato")
  n <- filter(t, provincia == "31")
  expect_equal(n$curva, "00")
  expect_equal(n$retencion, 0.02 + 0.5 * 0.06)                             # curva de España: 5 %
  expect_equal(n$estado, "estimado")
  expect_equal(filter(t, provincia == "28")$estado, "ausente")             # sin curva de su comunidad
  comp <- comprobar_transistor(t, anios = 2024L)
  expect_equal(filter(comp, id == "transistor_cobertura")$calculado, PROVINCIAS_ESPANA - 2)
  expect_equal(filter(comp, id == "transistor_retencion")$calculado, 0)
})

test_that("los Excel del INSS de los dos formatos se leen igual (si están en datos/brutos)", {
  r <- file.path("..", "..", DIR_INSS, c("2015/CA201507.xlsx", "2024/CA202407.xlsx"))
  skip_if_not(all(file.exists(r)), "sin los Excel del INSS")
  x <- leer_inss_pensiones(r)
  expect_equal(unique(x$anio), c(2015L, 2024L))
  expect_equal(unique(x$mes), 7L)
  expect_true(all(c("total", "total_sistema", "huesca", "madrid", "madrid_com_de") %in% x$clave))
  expect_true(all(x$media > 300 & x$media < 3000))
})
