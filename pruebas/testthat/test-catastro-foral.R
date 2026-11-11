# Catastros forales: enlaces de los feeds, zips que hacen falta y año de construcción.
# Datos inventados con la forma de los ficheros reales (8-nov-2026).

test_that("los enlaces de Bizkaia y Navarra dan el municipio del INE", {
  xml_bizkaia <- paste(
    '<entry><title>48001-ABADIÑO Buildings</title>',
    '<link href="https://apli.bizkaia.eus/apps/Danok/INSPIRE/ES.BFA.BU.001.zip"/>',
    '<link href="https://apli.bizkaia.eus/apps/Danok/INSPIRE/ES.BFA.BU.001.zip"/></entry>',
    '<entry><link href="https://apli.bizkaia.eus/apps/Danok/INSPIRE/ES.BFA.BU.902.zip"/></entry>',
    '<link href="https://apli.bizkaia.eus/apps/Danok/INSPIRE/otro.zip"/>')
  b <- zips_feed_foral(xml_bizkaia, "48", FEEDS_CATASTRO_FORAL$patron[FEEDS_CATASTRO_FORAL$provincia == "48"])
  expect_equal(b$municipio, c("48001", "48902"))
  expect_equal(b$provincia, c("48", "48"))

  xml_navarra <- paste(
    '<link href="https://filescartografia.navarra.es/x/files/BU_Navarra_16.gml.zip"/>',
    '<link href="https://filescartografia.navarra.es/x/files/BU_Navarra_201.gml.zip"/>',
    '<link href="https://filescartografia.navarra.es/x/files/BU_Navarra_1.gml.zip"/>')
  n <- zips_feed_foral(xml_navarra, "31", FEEDS_CATASTRO_FORAL$patron[FEEDS_CATASTRO_FORAL$provincia == "31"])
  expect_equal(n$municipio, c("31016", "31201", "31001"))
})

test_that("se piden el zip del territorio entero y los de cada municipio que hace falta", {
  zips <- tibble::tribble(
    ~provincia, ~municipio, ~url,
    "01", NA,      "alava.zip",
    "20", NA,      "gipuzkoa.zip",
    "48", "48020", "bilbao.zip",
    "48", "48036", "galdakao.zip",
    "48", "48044", "getxo.zip",
    "31", "31201", "pamplona.zip"
  )
  expect_message(u <- seleccionar_zips_forales(zips, c("01059", "48020", "48036", "48916")), "48916")
  expect_setequal(u, c("alava.zip", "bilbao.zip", "galdakao.zip"))
  expect_silent(u <- seleccionar_zips_forales(zips, c("20069", "31201")))
  expect_setequal(u, c("gipuzkoa.zip", "pamplona.zip"))
  expect_length(seleccionar_zips_forales(zips, character()), 0)
})

test_that("el año sale de texto, fecha o fecha y hora sin cambiar de año", {
  expect_equal(anio_de_fecha(c("2000-01-01T01:00:00Z", "1976", NA, "")), c(2000L, 1976L, NA, NA))
  expect_equal(anio_de_fecha(as.Date(c("1978-12-31", NA))), c(1978L, NA))
  hora <- as.POSIXct(c("1900-01-01 00:45:16", "1994-12-31 00:00:00"), tz = "Europe/Madrid")
  expect_equal(anio_de_fecha(hora), c(1900L, 1994L))
})

test_that("el año de construcción toma la primera parte con valor y no la fecha de reforma", {
  # Navarra: beginning y end; se queda con beginning
  navarra <- data.frame(beginning = c("1955-01-01", "1900-01-01"), end = c("2000-01-01", "1900-01-01"))
  expect_equal(anio_construccion_foral(navarra), c(1955L, 1900L))
  # Bizkaia: beginning vacío, end con valor
  bizkaia <- data.frame(beginning = c(NA, NA), end = c("1978-12-31", NA), anyPoint = NA)
  expect_equal(anio_construccion_foral(bizkaia), c(1978L, NA))
  # Gipuzkoa: solo end
  expect_equal(anio_construccion_foral(data.frame(end = "1934-12-31")), 1934L)
  # Álava: anyPoint; la reforma no cuenta
  alava <- data.frame(anyPoint = c("1976-12-31", NA), dateOfRenovation.DateOfEvent.anyPoint = c("2010-01-01", "2010-01-01"))
  expect_equal(anio_construccion_foral(alava), c(1976L, NA))
  # Sin ninguna columna de año
  expect_equal(anio_construccion_foral(data.frame(x = 1:2)), c(NA_integer_, NA_integer_))
})

test_that("punto_interior(): en grados, el punto se toma proyectado, sin aviso, dentro y en su sistema", {
  # Una «L» de unos 20 m en Bilbao, en ETRS89 geográficas como los GML de Bizkaia y Navarra
  ele <- matrix(c(-2.93500, 43.26300, -2.93475, 43.26300, -2.93475, 43.26305, -2.93490, 43.26305,
                  -2.93490, 43.26318, -2.93500, 43.26318, -2.93500, 43.26300), ncol = 2, byrow = TRUE)
  g <- sf::st_sfc(sf::st_polygon(list(ele)), crs = 4258)
  expect_no_warning(p <- punto_interior(g))
  expect_equal(sf::st_crs(p), sf::st_crs(g))
  expect_true(as.logical(sf::st_within(sf::st_transform(p, 25830), sf::st_transform(g, 25830), sparse = FALSE)))
  # Ya proyectado: lo mismo que sf::st_point_on_surface()
  plano <- sf::st_transform(g, 25830)
  expect_equal(sf::st_coordinates(punto_interior(plano)), sf::st_coordinates(sf::st_point_on_surface(plano)))
})
