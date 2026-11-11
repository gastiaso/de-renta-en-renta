# Tabla de paso desde el seccionado del Censo 2011 (tarea 47; R/paso2011.R). Datos inventados.

censo2011_zip <- function() {
  dir <- tempfile("censo2011_")
  dir.create(dir)
  writeLines(c(
    "ccaa,cpro,cmun,dist,secc,t1_1,t16_1,t17_1,t18_4,t21_1",
    "13,28,001,01,001,100,60,40,10,40",
    "13,28,001,01,002,200,90,80,,80"
  ), file.path(dir, "C2011_ccaa13_Indicadores.csv"))
  writeLines(c(
    "ccaa,cpro,cmun,dist,secc,t1_1,t16_1,t17_1,t18_4,t21_1",
    "01,04,013,01,001,50,30,20,5,20"
  ), file.path(dir, "C2011_ccaa01_Indicadores.csv"))
  zip <- tempfile(fileext = ".zip")
  zip::zipr(zip, list.files(dir, full.names = TRUE))
  zip
}

test_that("los indicadores del Censo 2011 se leen de todos los CSV del zip, con el secreto en NA", {
  c11 <- paso2011_leer_censo2011(censo2011_zip())
  expect_equal(c11$seccion, c("0401301001", "2800101001", "2800101002"))
  expect_equal(c11$alquiler, c(5, 10, NA))
  expect_equal(c11$viviendas, c(30, 60, 90))
  expect_equal(nrow(paso2011_leer_censo2011(censo2011_zip(), ambito = "28")), 2L)
})

ccaa_prueba <- tibble::tibble(codigo = c("01", "13", "18"), nombre_ine = c("Andalucía", "Madrid, Comunidad de", "Ceuta"))
territorios_prueba <- tibble::tibble(
  nivel = "provincia",
  codigo = c("04", "41", "03", "12", "28", "51"),
  nombre = c("Almería", "Sevilla", "Alicante", "Castellón/Castelló", "Madrid", "Ceuta"),
  superior = c("01", "01", "10", "10", "13", "18"))

test_that("las etiquetas del Censo 2011 casan con los códigos y las comunidades de una provincia dan también la provincia", {
  d <- tibble::tibble(comunidad = c(NA, "ANDALUCÍA", "ANDALUCÍA", "MADRID, COMUNIDAD DE", "Ceuta"),
                      provincia = c(NA, NA, "Almería", NA, NA), valor = 1:5)
  t <- paso2011_codigos_territorios(d, ccaa_prueba, territorios_prueba)
  expect_equal(paste(t$nivel, t$codigo), c("nacional 00", "ccaa 01", "ccaa 13", "ccaa 18", "provincia 04",
                                           "provincia 28", "provincia 51"))
  expect_equal(t$valor[t$codigo %in% c("13", "28")], c(4L, 4L))
  # Los bilingües casan por la primera parte
  expect_equal(paso2011_clave_nombre(c("Alicante/Alacant", "Valencia/Valéncia")), c("ALICANTE", "VALENCIA"))
  expect_error(paso2011_codigos_territorios(tibble::tibble(comunidad = "ATLANTIDA", provincia = NA),
                                            ccaa_prueba, territorios_prueba), "sin c")
})

test_that("los municipios descasados son los que no tienen los mismos códigos en el mapa y en el callejero", {
  expect_equal(paso2011_municipios_descasados(c("2800101001", "2800101002", "0401301001"),
                                              c("2800101001", "2800101003", "0401301001")), "28001")
})

# Dos secciones de 2011 (A, B) y tres de 2021 (X, Y, Z): A cae entera en X; B se reparte entre Y y Z.
paso_prueba <- tibble::tibble(origen = c("2800101001", "2800101002", "2800101002"),
                              destino = c("2800101001", "2800101002", "2800101003"),
                              portales = c(10, 30, 10), metodo = "callejero", fraccion = c(1, 0.75, 0.25))
secciones_2021_prueba <- c("2800101001", "2800101002", "2800101003", "2800101004")

test_that("la tabla combinada quita los orígenes que no están en el Censo y deja decidir al Catastro en los descasados", {
  a <- bind_rows(paso_prueba, tibble::tibble(origen = "2800101009", destino = "2800101004", portales = 5,
                                             metodo = "callejero", fraccion = 1))
  b <- tibble::tibble(origen = c("2800101002", "2800101002"), destino = c("2800101002", "2800101003"),
                      portales = c(50, 50), fraccion = c(0.5, 0.5), metodo = "catastro")
  datos <- c("2800101001", "2800101002")
  t <- paso2011_combinar(b, a, datos, secciones_2021_prueba)
  expect_false("2800101009" %in% t$origen)
  expect_equal(t$fraccion[t$origen == "2800101002"], c(0.5, 0.5))     # la sección repartida: Catastro
  # Un origen que cae entero sale del callejero salvo en un municipio descasado con Catastro
  a2 <- mutate(a, destino = if_else(origen == "2800101002", "2800101002", destino), fraccion = 1) |>
    distinct(origen, destino, .keep_all = TRUE)
  b2 <- tibble::tibble(origen = "2800101002", destino = "2800101002", portales = 100, fraccion = 1, metodo = "catastro")
  sin_forzar <- paso2011_combinar(b2, a2, datos, secciones_2021_prueba)
  expect_equal(unique(sin_forzar$metodo[sin_forzar$origen == "2800101002"]), "callejero")
  forzada <- paso2011_combinar(b2, a2, datos, secciones_2021_prueba, descasados = "28001")
  expect_equal(unique(forzada$metodo[forzada$origen == "2800101002"]), "catastro")
  expect_equal(paso2011_sin_paso(c(datos, "2800101077"), t), "2800101077")
})

test_that("la vía (b) desde 2011 filtra por año de construcción y no cruza municipios", {
  agregado <- tibble::tibble(
    origen = c("2800101002", "2800101002", "2800101002", "2800101002"),
    destino = c("2800101002", "2800101003", "2800101004", "2800201001"),
    anio_construccion = c(1990L, NA, 2015L, 1980L), edificios = 1L, viviendas = c(30, 10, 60, 5))
  t11 <- paso2011_tabla_catastro(agregado, 2011L)
  expect_equal(t11$destino, c("2800101002", "2800101003"))           # sin 2015 ni el otro municipio
  expect_equal(t11$fraccion, c(0.75, 0.25))
  t20 <- paso2011_tabla_catastro(agregado, 2020L)
  expect_equal(t20$portales, c(30, 10, 60))
  # 2800101004 no recibe nada en 2011 y sus edificios son de 2015: posterior
  expect_equal(paso2011_posteriores(t11, agregado, secciones_2021_prueba, 2011L), "2800101004")
  expect_equal(paso2011_posteriores(t20, agregado, secciones_2021_prueba, 2020L), character(0))
})

test_that("el indicador 18 de 2011 se rehace en 2021 con su estado", {
  censo <- tibble::tibble(seccion = c("2800101001", "2800101002"), poblacion = c(100, 200),
                          viviendas = c(60, 90), principales = c(40, 80), alquiler = c(10, 20))
  r <- paso2011_reproyectar_censo(censo, paso_prueba, secciones_2021_prueba)
  expect_equal(r$estado, c("dato", "estimado", "estimado", "ausente"))
  expect_equal(r$valor[1:3], c(25, 25, 25))
  expect_equal(r$principales[2:3], c(60, 20))
  # Un origen en secreto deja en secreto sus destinos
  censo$alquiler[2] <- NA
  r2 <- paso2011_reproyectar_censo(censo, paso_prueba, secciones_2021_prueba)
  expect_equal(r2$estado, c("dato", "secreto", "secreto", "ausente"))
  expect_true(all(is.na(r2$valor[2:4])))
})

test_that("las viviendas turísticas de 2020-2023 copian el porcentaje del INE en las 1:1 y lo rehacen en las demás", {
  censo <- tibble::tibble(seccion = c("2800101001", "2800101002"), poblacion = c(100, 200),
                          viviendas = c(60, 80), principales = c(40, 80), alquiler = c(10, 20))
  vut <- tibble::tibble(periodo = "AGO2020", anio = 2020L, mes = "M08", seccion = c("2800101001", "2800101002"),
                        viviendas = c(3, 8), porcentaje = c(5.01, 10))
  r <- paso2011_reproyectar_vut(vut, paso_prueba, censo, secciones_2021_prueba, periodos = "AGO2020")
  expect_equal(r$estado, c("dato", "estimado", "estimado", "ausente"))
  expect_equal(r$valor[1], 5.01)                                       # copiado del INE
  expect_equal(r$valor[2:3], c(100 * 6 / 60, 100 * 2 / 20))
  vut$porcentaje[2] <- NA
  r2 <- paso2011_reproyectar_vut(vut, paso_prueba, censo, secciones_2021_prueba, periodos = "AGO2020")
  expect_equal(r2$estado[2:3], c("secreto", "secreto"))
  larga <- paso2011_armonizar(paso2011_reproyectar_censo(censo, paso_prueba, secciones_2021_prueba), r,
                              tibble::tibble(nivel = "nacional", codigo = "00", ccaa = NA_character_,
                                             principales = 200, alquiler = 30),
                              tibble::tibble(nivel = character(), codigo = character(), anio = integer(),
                                             mes = character(), porcentaje = numeric()),
                              version_censo = "2015-05-05", version_vut = "2026-11-08", periodos = "AGO2020")
  expect_equal(sort(unique(larga$anio)), c(2011L, 2020L))
  expect_equal(larga$valor[larga$nivel == "nacional" & larga$indicador == "hogares_alquiler"], 15)
  expect_equal(unique(larga$fuente[larga$indicador == "hogares_alquiler"]), "ine_censo2011")
})
