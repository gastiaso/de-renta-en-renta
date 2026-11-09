# Indicadores de distribución del ADRH, 4–6 (R/fuente_ine_adrh_distribucion.R), con datos inventados

csv_adrh <- function(lineas) {
  ruta <- tempfile(fileext = ".csv")
  writeLines(enc2utf8(c("\ufeffMunicipios;Distritos;Secciones;Indicador;Periodo;Total", lineas)), ruta, useBytes = TRUE)
  ruta
}
salario <- "Fuente de ingreso: salario"
umbral60 <- ADRH_UMBRALES_DEBAJO[3]

test_that("las marcas del CSV dan el estado: «.» secreto; «..» y vacío, ausente", {
  expect_equal(estado_marca_adrh(c("69,5", ".", "..", "", NA, "1.234,5")),
               c("dato", "secreto", "ausente", "ausente", "ausente", "dato"))
  expect_equal(numero_adrh(c("69,5", ".", "..", "1.234,5", "9")), c(69.5, NA, NA, 1234.5, 9))
})

test_that("la lectura por trozos se queda con los indicadores, el sexo y el ámbito pedidos", {
  ruta <- csv_adrh(c(
    paste0("28001 Uno;;;", salario, ";2024;61,2"),
    paste0("28001 Uno;2800101 Uno distrito 01;;", salario, ";2024;61,2"),
    paste0("28001 Uno;2800101 Uno distrito 01;2800101001 Uno sección 01001;", salario, ";2024;."),
    paste0("28001 Uno;2800101 Uno distrito 01;2800101001 Uno sección 01001;", salario, ";2015;\"\""),
    "28001 Uno;;;Fuente de ingreso: pensiones;2024;20,1",
    paste0("31001 Otro;;;", salario, ";2024;..")
  ))
  x <- leer_ine_adrh_distribucion(ruta, salario)
  expect_equal(nrow(x), 5L)
  expect_equal(x$nivel, c("municipio", "distrito", "seccion", "seccion", "municipio"))
  expect_equal(x$codigo, c("28001", "2800101", "2800101001", "2800101001", "31001"))
  expect_equal(x$estado, c("dato", "dato", "secreto", "ausente", "ausente"))
  expect_equal(x$valor, c(61.2, 61.2, NA, NA, NA))
  expect_equal(nrow(leer_ine_adrh_distribucion(ruta, salario, ambito = "28")), 4L)

  ruta7 <- tempfile(fileext = ".csv")
  writeLines(enc2utf8(c("\ufeffMunicipios;Distritos;Secciones;Sexo;Distribución;Periodo;Total",
                        paste0("28001 Uno;;;Total;", umbral60, ";2024;18,4"),
                        paste0("28001 Uno;;;Hombres;", umbral60, ";2024;17,0"),
                        paste0("28001 Uno;;;Total;", ADRH_UMBRALES_DEBAJO[1], ";2024;7,1"))), ruta7, useBytes = TRUE)
  y <- leer_ine_adrh_distribucion(ruta7, umbral60)
  expect_equal(y$valor, 18.4)
  expect_equal(y$sexo, "Total")
})

ccaa_prueba <- tibble::tibble(codigo = c("10", "13"), nombre_ine = c("Comunitat Valenciana", "Madrid, Comunidad de"))
territorios_prueba <- tibble::tibble(nivel = "provincia", codigo = c("03", "46", "28"),
                                     nombre = c("Alicante", "Valencia/Valéncia", "Madrid"),
                                     superior = c("10", "10", "13"))

test_that("los totales casan por nombre: comunidad por el del INE y provincia dentro de su comunidad", {
  t <- tibble::tibble(ccaa = c(NA, "Comunitat Valenciana", "Comunitat Valenciana", "Comunitat Valenciana", "Madrid, Comunidad de"),
                      provincia = c(NA, NA, "Alicante/Alacant", "Valencia/València", "Madrid"))
  c <- codigos_totales_adrh(t, ccaa_prueba, territorios_prueba)
  expect_equal(c$nivel, c("nacional", "ccaa", "provincia", "provincia", "provincia"))
  expect_equal(c$codigo, c("00", "10", "03", "46", "28"))
  expect_error(codigos_totales_adrh(tibble::tibble(ccaa = "Comunitat Valenciana", provincia = "Murcia"),
                                    ccaa_prueba, territorios_prueba), "Murcia")
  expect_error(codigos_totales_adrh(tibble::tibble(ccaa = "Atlantida", provincia = NA), ccaa_prueba, territorios_prueba),
               "Atlantida")
})

test_that("la tabla de totales deja fuera las islas y da el estado de cada año", {
  ruta <- tempfile(fileext = ".csv")
  writeLines(enc2utf8(c(
    "\ufeffTotal Nacional;Comunidades y Ciudades Autónomas;Provincias;Islas;Indicadores de renta media;Periodo;Total",
    paste0("Total Nacional;;;;", ADRH_GINI, ";2024;31,9"),
    paste0("Total Nacional;;;;", ADRH_GINI, ";2020;\"\""),
    paste0("Total Nacional;Madrid, Comunidad de;;;", ADRH_GINI, ";2024;33,8"),
    paste0("Total Nacional;Madrid, Comunidad de;Madrid;;", ADRH_GINI, ";2024;33,8"),
    paste0("Total Nacional;Comunitat Valenciana;Valencia/València;Isla inventada;", ADRH_GINI, ";2024;30,0"),
    "Total Nacional;;;;Distribución de la renta P80/P20;2024;2,6")), ruta, useBytes = TRUE)
  x <- leer_ine_adrh_totales(ruta, ADRH_GINI, ccaa_prueba, territorios_prueba)
  expect_equal(paste(x$nivel, x$codigo, x$anio), c("nacional 00 2024", "nacional 00 2020", "ccaa 13 2024", "provincia 28 2024"))
  expect_equal(x$estado, c("dato", "ausente", "dato", "dato"))
  expect_equal(x$valor, c(31.9, NA, 33.8, 33.8))
})

# Tabla de paso inventada: 01 cae entera en 01; 02 y 03 se juntan en 02 (enteras); 04 se reparte
# entre 04 (90 % de sus portales) y 05; 06 (secreto) va entero a 06; 07 (sin publicar) a 07.
paso_prueba <- tibble::tibble(
  origen   = c("2800101001", "2800101002", "2800101003", "2800101004", "2800101004", "2800101006", "2800101007"),
  destino  = c("2800101001", "2800101002", "2800101002", "2800101004", "2800101005", "2800101006", "2800101007"),
  portales = c(10L, 30L, 10L, 90L, 10L, 5L, 5L),
  fraccion = c(1, 1, 1, 0.9, 0.1, 1, 1)
)
secciones_prueba <- function(valores, estados = ifelse(is.na(valores), "secreto", "dato")) {
  tibble::tibble(codigo = sprintf("280010100%d", c(1:4, 6:7)), valor = valores, estado = estados)
}

test_that("las medias ponderadas juntan orígenes enteros como dato y se reparten como estimado", {
  s <- secciones_prueba(c(60, 50, 70, 40, NA, NA), c(rep("dato", 4), "secreto", "ausente"))
  pesos <- tibble::tibble(seccion = sprintf("280010100%d", c(1:4, 6:7)), renta_bruta = c(1, 3, 1, 2, 1, 1))
  r <- reproyectar_adrh_distribucion(s, paso_prueba, "renta_bruta", pesos)
  expect_equal(r$seccion, sprintf("280010100%d", c(1:2, 4:7)))                # 03 se junta con 02
  expect_equal(r$valor, c(60, (50 * 3 + 70) / 4, 40, 40, NA, NA))
  expect_equal(r$estado, c("dato", "dato", "estimado", "estimado", "secreto", "ausente"))
})

test_that("una sección de 2021 con un origen sin dato pasa a estimado; sin ninguno, secreto o ausente", {
  s <- secciones_prueba(c(60, 50, NA, 40, NA, NA), c("dato", "dato", "secreto", "dato", "secreto", "ausente"))
  pesos <- tibble::tibble(seccion = sprintf("280010100%d", c(1:4, 6:7)), poblacion = 100)
  r <- reproyectar_adrh_distribucion(s, paso_prueba, "poblacion", pesos)
  expect_equal(r$valor[r$seccion == "2800101002"], 50)
  expect_equal(r$estado[r$seccion == "2800101002"], "estimado")
})

test_that("el Gini sigue la regla de medianas: un origen entero, dato; el dominante, estimado; si no, ausente", {
  s <- secciones_prueba(c(28, 30, 35, 31, NA, NA), c(rep("dato", 4), "secreto", "ausente"))
  r <- reproyectar_adrh_distribucion(s, paso_prueba)
  expect_equal(r$valor, c(28, NA, 31, 31, NA, NA))
  # 02 recibe 30 portales de 02 y 10 de 03: ninguno llega al 95 %
  expect_equal(r$estado, c("dato", "ausente", "estimado", "estimado", "secreto", "ausente"))
})

test_that("la armonización da la tabla larga: secciones de 2021, municipios publicados y totales", {
  dist <- bind_rows(
    secciones_prueba(c(60, 50, 70, 40, NA, NA)) |> mutate(indicador = "peso_salarios"),
    secciones_prueba(c(18, 20, 22, 25, NA, NA)) |> mutate(indicador = "bajo_60_mediana"),
    secciones_prueba(c(28, 30, 35, 31, NA, NA)) |> mutate(indicador = "gini"),
    tibble::tibble(codigo = c("28001", "28999"), valor = c(55, NA), estado = c("dato", "ausente"), indicador = "gini")
  ) |> mutate(anio = 2024L, nivel = if_else(nchar(codigo) == 10, "seccion", "municipio"))
  totales <- tibble::tibble(anio = 2024L, nivel = c("nacional", "provincia"), codigo = c("00", "28"),
                            indicador = "gini", valor = c(31.9, 33.8), estado = "dato")
  pesos <- tibble::tibble(anio = 2024L, seccion = sprintf("280010100%d", c(1:4, 6:7)), poblacion = 100, renta_bruta = 1e6)
  x <- armonizar_ine_adrh_distribucion(dist, totales, pesos, list("2024" = paso_prueba), version = "2026-10-19")
  expect_true(all(c("geo_id", "nivel", "anio", "indicador", "corte", "grupo", "valor", "estado", "fuente", "geo_ref", "version")
                  %in% names(x)))
  expect_equal(sum(x$nivel == "sc"), 3L * 6L)
  expect_false("28999" %in% x$geo_id)                        # municipio de otro seccionado, sin ninguna cifra
  expect_equal(x$valor[x$nivel == "provincia"], 33.8)
  expect_true(all(x$corte == "total" & x$fuente == "ine_adrh"))
  expect_silent(validar_tabla_larga(x))
})

# Compuerta: dos municipios inventados de la provincia 28 (uno de una sola sección) y sus totales
fila_dist <- function(codigo, indicador, valor, estado = "dato", anio = 2024L) {
  tibble::tibble(anio = anio, nivel = dplyr::case_when(nchar(codigo) == 10 ~ "seccion", nchar(codigo) == 7 ~ "distrito",
                                                       TRUE ~ "municipio"),
                 codigo = codigo, sexo = "Total", indicador = indicador, valor = valor, estado = estado)
}
fuentes_prueba <- bind_rows(
  fila_dist("2800101001", ADRH_FUENTES_INGRESO, c(60, 20, 2, 5, 13)),
  fila_dist("2800101002", ADRH_FUENTES_INGRESO, c(40, 40, 2, 5, 13)),
  fila_dist("28001", ADRH_FUENTES_INGRESO, c(52, 28, 2, 5, 13)),          # (60 × 2 + 40 × 3) / 5 = 48: alerta
  fila_dist("2800201001", ADRH_FUENTES_INGRESO, c(70, 10, 2, 5, 13.1)),
  fila_dist("28002", ADRH_FUENTES_INGRESO, c(70, 10, 2, 5, 13.1))
)
umbrales_prueba <- bind_rows(
  fila_dist("2800101001", ADRH_UMBRALES_DEBAJO, c(5, 10, 20)),
  fila_dist("2800101002", ADRH_UMBRALES_DEBAJO, c(5, 10, 30)),
  fila_dist("28001", ADRH_UMBRALES_DEBAJO, c(5, 10, 25)),
  fila_dist("2800201001", ADRH_UMBRALES_DEBAJO, c(4, 8, 15)),
  fila_dist("28002", ADRH_UMBRALES_DEBAJO, c(4, 8, 15))
)
gini_prueba <- bind_rows(fila_dist(c("2800101001", "2800101002", "28001", "2800201001", "28002"), ADRH_GINI,
                                   c(28, 30, 31, 25, 25)))
totales_prueba <- bind_rows(
  fila_dist("28", ADRH_FUENTES_INGRESO, c(52, 28, 2, 5, 13)) |> mutate(nivel = "provincia"),
  fila_dist("28", ADRH_UMBRALES_DEBAJO, c(5, 9, 23)) |> mutate(nivel = "provincia"),
  fila_dist("28", ADRH_GINI, 30) |> mutate(nivel = "provincia")
)
pesos_prueba <- tibble::tibble(anio = 2024L, seccion = c("2800101001", "2800101002", "2800201001"),
                               poblacion = c(100, 100, 50), renta_bruta = c(2, 3, 1))

test_that("la compuerta de 4–6 mide cobertura, suma, orden, sección única y agregación", {
  c <- comprobar_ine_adrh_distribucion(fuentes_prueba, umbrales_prueba, gini_prueba, totales_prueba, pesos_prueba,
                                       ambito = "28")
  v <- function(id, detalle = NULL) {
    x <- c[c$id == id & (is.null(detalle) | c$detalle %in% detalle), ]
    x$calculado
  }
  expect_equal(v("adrh_dist_cobertura"), c(1, 1, 1))
  expect_equal(v("adrh_dist_rango"), c(0, 0, 0))
  expect_equal(v("adrh_dist_fuentes_suma"), 0.1, tolerance = 1e-9)
  expect_equal(v("adrh_dist_umbrales_orden"), 0)
  expect_equal(v("adrh_dist_seccion_unica"), c(0, 0, 0))                     # 28002, una sola sección
  expect_equal(v("adrh_dist_municipio_detalle", "28001 peso_salarios"), (60 * 2 + 40 * 3) / 5 - 52)
  expect_equal(v("adrh_dist_municipio_detalle", "28001 bajo_60_mediana"), 0)
  expect_equal(v("adrh_dist_provincia", "bajo_60_mediana"), abs((20 * 100 + 30 * 100 + 15 * 50) / 250 - 23))
})

test_that("la compuerta ve una descarga cortada, umbrales fuera de orden y una sección distinta de su municipio", {
  mal <- umbrales_prueba
  mal$valor[mal$codigo == "2800201001" & mal$indicador == ADRH_UMBRALES_DEBAJO[2]] <- 16
  c <- comprobar_ine_adrh_distribucion(fuentes_prueba, mal, gini_prueba, totales_prueba, pesos_prueba)
  # sin ámbito se esperan las 52 provincias: una tabla con una sola, como una descarga cortada, no pasa
  expect_equal(c$calculado[c$id == "adrh_dist_cobertura"], c(1, 1, 1))
  expect_true(all(c$referencia[c$id == "adrh_dist_cobertura"] == 52))
  expect_equal(c$calculado[c$id == "adrh_dist_umbrales_orden"], 1)
  otra <- fuentes_prueba
  otra$valor[otra$codigo == "28002" & otra$indicador == ADRH_FUENTES_INGRESO[1]] <- 69.9
  c2 <- comprobar_ine_adrh_distribucion(otra, umbrales_prueba, gini_prueba, totales_prueba, pesos_prueba, ambito = "28")
  expect_equal(c2$calculado[c2$id == "adrh_dist_seccion_unica" & c2$detalle == "peso_salarios"], 0.1, tolerance = 1e-9)
})

test_that("se eligen las filas del catálogo: salario, 60 % y Gini, con su código", {
  x <- seleccionar_adrh_distribucion(fuentes_prueba, umbrales_prueba, gini_prueba)
  expect_setequal(unique(x$indicador), c("peso_salarios", "bajo_60_mediana", "gini"))
  expect_false("sexo" %in% names(x))
  expect_equal(nrow(x), 15L)
})

test_that("en la web entran los indicadores con mapa y cifras de sección aunque no sean del núcleo de la v0.1", {
  ind <- tibble::tibble(id = c(1, 6, 22), codigo = c("renta_persona", "gini", "sobrecarga"),
                        unidad_es = c("\u20ac por persona y a\u00f1o", "\u00edndice (0\u2013100)", "% de las personas"),
                        nucleo_v01 = c(TRUE, FALSE, FALSE), cortes_web = c("10;20", "25;27;29;31;33", "4;6;8|RENT_MKT=15;20"))
  larga <- bind_rows(
    tibble::tibble(geo_id = "2800101001", nivel = "sc", indicador = c("renta_persona", "gini")),
    tibble::tibble(geo_id = "13", nivel = "ccaa", indicador = "sobrecarga")
  ) |> mutate(anio = 2024L, corte = "total", grupo = "total", valor = 30, estado = "dato", fuente = "prueba", version = "x")
  s <- series_web(larga, ind)
  expect_setequal(unique(s$clave), c("renta_persona", "gini"))     # la sobrecarga, sin secciones, no
  expect_equal(decimales_web(c("\u00edndice (0\u2013100)", "% de la poblaci\u00f3n", "\u20ac por mes")), c(1L, 1L, 0L))
})
