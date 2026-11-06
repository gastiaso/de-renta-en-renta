# Fuente ine_seccionado: cartografía de secciones censales del INE, a 1 de enero de cada año.
# La referencia del atlas es el seccionado de 2021 (plan, §6.3).

url_ine_seccionado <- function(anio) {
  sprintf("https://www.ine.es/prodyser/cartografia/seccionado_%d.zip", anio)
}

descargar_ine_seccionado <- function(anio, dir = file.path("datos", "brutos", "ine_seccionado"),
                                     forzar = FALSE) {
  descargar_con_cache(url_ine_seccionado(anio), file.path(dir, sprintf("seccionado_%d.zip", anio)), forzar)
}

# Lee las secciones de una provincia (o de toda España si `provincia` es NULL).
# Devuelve un sf con el código de sección de 10 dígitos (`seccion`), el municipio y la geometría.
leer_ine_seccionado <- function(zip, anio, provincia = NULL) {
  # Se lee dentro del zip con GDAL (/vsizip/), sin descomprimir. Algunas rutas internas
  # llevan «ñ» en CP437 (seccionado de 2025): se pasan a UTF-8 para GDAL.
  contenido <- utils::unzip(zip, list = TRUE)$Name
  interno <- contenido[grepl("\\.shp$", contenido, ignore.case = TRUE, useBytes = TRUE)]
  if (length(interno) != 1) stop("Se esperaba un único .shp en ", zip, call. = FALSE)
  if (!validUTF8(interno)) interno <- iconv(interno, "CP437", "UTF-8")
  shp <- paste0("/vsizip/", normalizePath(zip, winslash = "/"), "/", interno)

  consulta <- NULL
  if (!is.null(provincia)) {
    capa_sf <- sf::st_layers(shp)$name[1]
    consulta <- sprintf("SELECT * FROM \"%s\" WHERE CPRO = '%s'", capa_sf, provincia)
  }
  secciones <- if (is.null(consulta)) sf::st_read(shp, quiet = TRUE) else sf::st_read(shp, query = consulta, quiet = TRUE)
  secciones |>
    transmute(
      anio      = as.integer(anio),
      seccion   = as.character(CUSEC),
      municipio = as.character(CUMUN)
    )
}
