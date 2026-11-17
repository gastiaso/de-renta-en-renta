# Riesgo de pobreza tras los gastos de vivienda, indicador 24 (R/fuente_ine_ecv_pobreza.R y
# R/fuente_eurostat_ilc_li48.R), con datos inventados.

# Cinco hogares inventados. El 2 tiene dos personas y 1,5 unidades de consumo; el 4 no declara gasto.
# Renta equivalente: 10.000 (peso 1), 20.000 (peso 2), 30.000, 40.000 y 50.000 (peso 1): la mediana
# ponderada es 20.000 (peso acumulado 3 de 6) y el umbral, 12.000 € al año.
ecv_pobreza <- list(
  hogares = tibble::tibble(
    anio = 2025L,
    id_hogar           = c("1", "2", "3", "4", "5"),
    region             = c("ES30", "ES30", "ES51", "ES51", "ES51"),
    peso_hogar         = 1,
    grado_urbanizacion = c("1", "1", "2", "3", "3"),
    tenencia           = c(3L, 1L, 3L, 2L, 4L),
    gasto_vivienda_mes = c(100, 700, 1500, NA, 200),
    renta_disponible   = c(10000, 30000, 30000, 40000, 50000),
    ayuda_vivienda     = c(0, 4000, 0, 0, 3000),
    unidades_consumo   = c(1, 1.5, 1, 1, 1)
  ),
  personas = tibble::tibble(
    id_persona   = c("101", "201", "202", "301", "401", "501"),
    id_hogar     = c("1", "2", "2", "3", "4", "5"),
    peso_persona = 1,
    edad         = c(30L, 40L, 10L, 50L, 60L, 70L)
  )
)

test_that("el umbral es el 60 % de la mediana antes de restar la vivienda, con todas las personas con renta", {
  p <- personas_pobreza_vivienda(ecv_pobreza)
  expect_equal(unique(p$mediana), 20000)
  expect_equal(unique(p$umbral), 12000)
  expect_false("4" %in% p$id_hogar)                                   # sin gasto declarado: fuera del cálculo
  # Renta tras la vivienda: (HY020 − 12 × HH070) ÷ HX240; las ayudas no se tocan
  expect_equal(p$renta_tras_vivienda[p$id_hogar == "2"][1], (30000 - 12 * 700) / 1.5)
  expect_equal(p$renta_tras_vivienda[p$id_hogar == "3"], 12000)
  # «Por debajo» del umbral: el 3, justo en el umbral, no cuenta
  expect_equal(p$pobre[p$id_hogar == "1"], TRUE)
  expect_equal(p$pobre[p$id_hogar == "3"], FALSE)
})

test_that("la tasa pondera por persona y se desglosa por tenencia y comunidad", {
  r <- calcular_pobreza_vivienda_ecv(ecv_pobreza)
  valor <- function(c, g) r$valor[r$corte == c & r$grupo == g]
  # Dentro: hogares 1, 2 (dos personas), 3 y 5 → peso 5; por debajo: solo el 1
  expect_equal(valor("total", "TOTAL"), 100 * 1 / 5)
  expect_equal(valor("tenencia", "RENT_MKT"), 50)                     # hogares 1 y 3
  expect_equal(valor("tenencia", "OWN_NL"), 0)
  expect_equal(valor("tenencia", "OWN"), 0)
  expect_equal(valor("tenencia", "RENT"), 100 / 3)
  expect_equal(valor("region", "ES30"), 100 / 3)                      # hogar 1 frente a 1 + 2
  expect_equal(r$n_hogares[r$corte == "region" & r$grupo == "ES51"], 2L)
  expect_equal(r$n_personas[r$corte == "total"], 5L)
  expect_equal(unique(r$umbral), 12000)
  expect_equal(unique(r$indicador), "pobreza_tras_vivienda")
  # Edad (grupos de ilc_li45, con 18 y más) y grado de urbanización (DB100 → DEG1–DEG3)
  expect_equal(valor("edad", "Y_LT18"), 0)                            # el 202, de 10 años
  expect_equal(valor("edad", "Y18-64"), 100 / 3)
  expect_equal(valor("edad", "Y_GE18"), 25)                           # 101, 201, 301 y 501
  expect_equal(r$n_personas[r$corte == "edad" & r$grupo == "Y_GE18"], 4L)
  expect_equal(valor("urbanizacion", "DEG1"), 100 / 3)                # hogares 1 y 2
  expect_equal(sort(r$grupo[r$corte == "urbanizacion"]), c("DEG1", "DEG2", "DEG3"))
  # Un hogar sin tenencia cuenta en el total y en los demás cortes, no en ninguna tenencia
  sin_tenencia <- ecv_pobreza
  sin_tenencia$hogares$tenencia[1] <- NA_integer_
  st <- calcular_pobreza_vivienda_ecv(sin_tenencia)
  expect_false(anyNA(st$grupo))
  expect_equal(st$n_personas[st$corte == "total"], 5L)
  expect_equal(sum(st$n_personas[st$corte == "tenencia" & st$grupo %in% c("OWN", "RENT")]), 4L)
  # Con las ayudas restadas solo de la renta, el hogar 2 caería por debajo: aquí no cambia nada
  sin_ayudas <- ecv_pobreza
  sin_ayudas$hogares$ayuda_vivienda <- 0
  expect_equal(calcular_pobreza_vivienda_ecv(sin_ayudas)$valor, r$valor)
})

test_that("las olas agrupadas reparten el peso, cada una con su umbral, y marcan la fiabilidad", {
  otra <- ecv_pobreza
  otra$hogares$anio <- 2024L
  otra$hogares$renta_disponible <- otra$hogares$renta_disponible * 2   # umbral de 24.000
  otra$hogares$gasto_vivienda_mes[3] <- 3100                          # el hogar 3: 60.000 − 37.200 = 22.800, por debajo
  a <- calcular_pobreza_vivienda_agrupada(list(otra, ecv_pobreza))
  mercado <- a[a$corte == "tenencia" & a$grupo == "RENT_MKT" & a$region == "ES51", ]
  expect_equal(mercado$valor, 50)                                     # el 3, pobre en 2024 y no en 2025
  expect_equal(mercado$n_personas, 2L)
  expect_equal(mercado$fiabilidad, "no publicable")
  expect_equal(c(unique(a$anio_inicio), unique(a$anio_fin), unique(a$olas)), c(2024L, 2025L, 2L))
})

test_that("los trienios móviles agrupan cada ola con las dos anteriores, y la web pinta el último", {
  ola <- function(anio) {
    o <- ecv_pobreza
    o$hogares$anio <- anio
    o
  }
  olas <- lapply(c(2019L, 2020L, 2021L, 2022L, 2023L), ola)
  t3 <- agrupar_trienios(olas, calcular_pobreza_vivienda_agrupada)
  expect_equal(sort(unique(t3$anio_fin)), c(2021L, 2022L, 2023L))
  expect_equal(unique(t3$anio_inicio[t3$anio_fin == 2023L]), 2021L)
  expect_equal(unique(t3$olas), 3L)
  ultimo <- ultima_agrupacion(t3)
  expect_equal(unique(ultimo$anio_fin), 2023L)
  expect_equal(nrow(ultimo), nrow(t3) / 3)
  # Con la misma ola repetida, cada trienio da la cifra de una ola
  expect_equal(ultimo$valor, calcular_pobreza_vivienda_agrupada(list(ola(2023L)))$valor)
  # Olas no seguidas: solo los trienios completos; sin ninguno, para
  expect_equal(unique(agrupar_trienios(olas[-2], calcular_pobreza_vivienda_agrupada)$anio_fin), 2023L)
  expect_error(agrupar_trienios(olas[c(1, 3, 5)], calcular_pobreza_vivienda_agrupada), "seguidas")
  # La sobrecarga se agrupa igual
  s3 <- agrupar_trienios(olas, calcular_sobrecarga_agrupada)
  expect_equal(sort(unique(s3$anio_fin)), c(2021L, 2022L, 2023L))
})

test_that("ilc_li45 en JSON-stat: edades, sexos y marcas", {
  j <- list(
    id = list("freq", "unit", "age", "sex", "geo", "time"), size = list(1, 1, 2, 2, 1, 1),
    dimension = list(
      freq = list(category = list(index = list(A = 0))),
      unit = list(category = list(index = list(PC = 0))),
      age = list(category = list(index = list(TOTAL = 0, Y_LT18 = 1))),
      sex = list(category = list(index = list(F = 0, T = 1))),
      geo = list(category = list(index = list(ES = 0))),
      time = list(category = list(index = list(`2025` = 0)))
    ),
    value = list(`0` = 29, `1` = 28.7, `2` = 39.5, `3` = 39),
    status = list(`3` = "p")
  )
  d <- normalizar_eurostat_ilc_li45(tabla_jsonstat(j))
  expect_equal(nrow(d), 4L)
  expect_equal(d$valor[d$edad == "Y_LT18" & d$sexo == "T"], 39)
  expect_equal(d$bandera[d$edad == "Y_LT18" & d$sexo == "T"], "p")
  expect_equal(unique(d$conjunto), "ilc_li45")
  expect_named(d, c("conjunto", "geo", "edad", "sexo", "anio", "valor", "bandera"))
  expect_error(normalizar_eurostat_ilc_li45(tabla_jsonstat(j)[0, ]), "no devuelve")
})

test_that("la compuerta compara España con ilc_li48, el umbral con el del INE y rehace el total", {
  r <- calcular_pobreza_vivienda_ecv(ecv_pobreza)
  eurostat <- tibble::tibble(conjunto = "ilc_li48", geo = c("ES", "ES", "FR"), grado = c("TOTAL", "DEG1", "TOTAL"),
                             anio = 2025L, valor = c(20.04, 15, 30), bandera = NA_character_)
  umbral <- tibble::tibble(ola = 2025L, valor = c(12000.04, 18000), hogar = c("una_persona", "una_persona"),
                           imputado = c(FALSE, TRUE), serie = "x")
  eurostat <- dplyr::bind_rows(eurostat, tibble::tibble(conjunto = "ilc_li48", geo = "ES", grado = c("DEG2", "DEG3"),
                                                        anio = 2025L, valor = c(0, 0), bandera = NA_character_))
  comp <- comprobar_pobreza_vivienda(r, eurostat, umbral)
  expect_equal(comp$id, c("ahc_es_eurostat", "ahc_umbral_ine", "ahc_tenencia_total", rep("ahc_es_urbanizacion", 3)))
  expect_equal(comp$referencia, c(20.04, 12000.04, 20, 15, 0, 0))
  expect_equal(comp$calculado[3], 20)                                 # las tenencias rehacen el total
  expect_equal(comp$detalle[4:6], c("ES, DEG1", "ES, DEG2", "ES, DEG3"))
  expect_error(comprobar_pobreza_vivienda(r, eurostat[eurostat$geo == "FR", ]), "no publica")
  expect_error(comprobar_pobreza_vivienda(r, eurostat[eurostat$grado != "DEG3", ]), "ilc_li48.*2025 DEG3")
  # Por edad, frente a ilc_li45 de ambos sexos; sin un grupo, para
  edad <- tibble::tibble(conjunto = "ilc_li45", geo = "ES", edad = c("Y_LT18", "Y18-64", "Y_GE65", "Y_GE18", "Y_GE18"),
                         sexo = c("T", "T", "T", "T", "F"), anio = 2025L, valor = c(0, 33.3, 0, 25, 99), bandera = NA_character_)
  ce <- comprobar_pobreza_vivienda(r, eurostat, edad = edad)
  e <- ce[ce$id == "ahc_es_edad", ]
  expect_equal(e$detalle, paste("ES,", c("Y18-64", "Y_GE65", "Y_LT18", "Y_GE18")))
  expect_equal(e$referencia, c(33.3, 0, 0, 25))
  expect_equal(e$calculado, c(100 / 3, 0, 0, 25))                    # 18 y más: el 1 de los cuatro adultos
  expect_error(comprobar_pobreza_vivienda(r, eurostat, edad = edad[edad$edad != "Y_LT18", ]), "ilc_li45")
  refs <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  expect_true(all(c("ahc_es_eurostat", "ahc_umbral_ine", "ahc_tenencia_total", "ahc_es_urbanizacion", "ahc_es_edad") %in% refs$id))
  expect_equal(refs$tipo[match(c("ahc_es_eurostat", "ahc_es_urbanizacion", "ahc_es_edad"), refs$id)], rep("bloqueo", 3))
  expect_equal(refs$tolerancia[match(c("ahc_es_eurostat", "ahc_es_urbanizacion", "ahc_es_edad"), refs$id)], rep("±0,1 puntos", 3))
})

test_that("en la tabla larga va como el 22: España, comunidades y cruces agrupados, con secreto por muestra", {
  r <- calcular_pobreza_vivienda_ecv(ecv_pobreza)
  a <- calcular_pobreza_vivienda_agrupada(list(ecv_pobreza))
  ccaa <- tibble::tibble(codigo = c("13", "09"), nuts2 = c("ES30", "ES51"))
  l <- armonizar_pobreza_vivienda_ecv(r, a, ccaa, version = "2026-11-17")
  expect_setequal(unique(l$nivel), c("nacional", "ccaa"))
  expect_equal(sort(unique(l$geo_id)), c("00", "09", "13"))
  expect_true(all(l$indicador == "pobreza_tras_vivienda" & l$fuente == "ine_ecv"))
  expect_equal(nrow(l[l$geo_id == "00" & l$corte == "total" & l$grupo == "total", ]), 1L)
  expect_setequal(unique(l$corte[l$geo_id == "00"]), c("total", "tenencia", "edad", "urbanizacion"))
  expect_equal(sort(l$grupo[l$geo_id == "00" & l$corte == "urbanizacion"]), c("DEG1", "DEG2", "DEG3"))
  voc <- readr::read_csv(file.path("..", "..", "inventario", "vocabulario.csv"), show_col_types = FALSE)
  expect_true(all(paste(l$corte[l$corte != "total"], l$grupo[l$corte != "total"]) %in% paste(voc$grupo, voc$clave)))
  expect_true(all(l$estado == "secreto" & is.na(l$valor)))           # muestras de menos de 20
  expect_named(l, c("geo_id", "nivel", "anio", "corte", "grupo", "valor", "estado", "indicador", "fuente", "geo_ref", "version"),
               ignore.order = TRUE)
  expect_error(armonizar_pobreza_vivienda_ecv(r, a, ccaa[1, ], version = "x"), "sin comunidad")
})

test_that("ilc_li48 en JSON-stat: porcentajes, grados de urbanización y marcas", {
  j <- list(
    id = list("freq", "deg_urb", "unit", "geo", "time"), size = list(1, 2, 1, 2, 2),
    dimension = list(
      freq = list(category = list(index = list(A = 0))),
      deg_urb = list(category = list(index = list(DEG1 = 1, TOTAL = 0))),
      unit = list(category = list(index = list(PC = 0))),
      geo = list(category = list(index = list(ES = 0, FR = 1))),
      time = list(category = list(index = list(`2024` = 0, `2025` = 1)))
    ),
    value = list(`0` = 29.1, `1` = 28.7, `2` = 30, `4` = 26.6, `5` = 26.4, `6` = 27),
    status = list(`1` = "p")
  )
  d <- normalizar_eurostat_ilc_li48(tabla_jsonstat(j))
  expect_equal(nrow(d), 6L)                                           # la casilla 3 (FR, TOTAL, 2025) no trae valor
  es <- d[d$geo == "ES" & d$grado == "TOTAL", ]
  expect_equal(es$valor, c(29.1, 28.7))
  expect_equal(es$bandera, c(NA, "p"))
  expect_equal(unique(d$conjunto), "ilc_li48")
  sin_es <- tabla_jsonstat(j)
  sin_es <- sin_es[sin_es$geo != "ES", ]
  expect_error(normalizar_eurostat_ilc_li48(sin_es), "no trae Espa")
})
