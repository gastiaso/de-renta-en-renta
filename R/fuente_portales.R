# Precios de oferta de los portales (indicador 13; fuente portales). F5. Capa desmontable (plan §2.2;
# guía, regla 6): solo con la variable de entorno PORTALES=TRUE (por defecto, FALSE; _targets.R).
# Apagada, el pipeline no lee nada de aquí y la tabla larga y la web quedan como sin capa.
#
# Solo cifras de los informes agregados que los portales publican en sus salas de prensa (precio
# medio por m² de un municipio o distrito), nunca anuncios. El atlas no las descarga: el autor las
# copia a mano de cada informe en un CSV que deja en datos/brutos/portales/ (fuera de git). Formato
# (UTF-8, separador coma, punto decimal; uno o varios ficheros *.csv, con las mismas columnas):
#
#   portal     idealista | fotocasa
#   operacion  alquiler (€ por m² y mes) | venta (€ por m²)
#   nivel      municipio | distrito
#   geo_id     código del INE: municipio, 5 cifras; distrito, 7 (municipio + distrito), como texto
#   nombre     nombre del territorio en el informe (control; no se usa para casar)
#   periodo    AAAA-MM (informe mensual) o AAAA (informe anual)
#   valor      precio medio por m² del informe
#   informe    título o referencia del informe
#   url        dirección del informe en la sala de prensa
#
# Ejemplo (cifras inventadas): idealista,alquiler,municipio,28079,Madrid,2025-12,99.9,Informe de
# prueba,https://ejemplo.invalid/informe. Pruebas: pruebas/datos/portales_inventado.csv.
#
# Tabla larga: indicador precio_oferta, corte oferta_privada (etiqueta de dato privado de oferta, en
# inventario/vocabulario.csv), grupo «operacion_portal» (alquiler_idealista…), un valor por año: el
# del informe anual si lo hay y, si no, el del último mes publicado de ese año. Nunca se mezcla con
# el SERPAVI, la tasación ni las escrituras (regla 5), ni un portal con otro.

DIR_PORTALES <- file.path("datos", "brutos", "portales")
COLUMNAS_PORTALES <- c("portal", "operacion", "nivel", "geo_id", "nombre", "periodo", "valor", "informe", "url")
PORTALES_VALIDOS <- c("idealista", "fotocasa")
OPERACIONES_PORTALES <- c("alquiler", "venta")
NIVELES_PORTALES <- c(municipio = 5L, distrito = 7L)
CORTE_PORTALES <- "oferta_privada"

# ¿Está encendida la capa? (variable de entorno PORTALES; TRUE en mayúsculas o minúsculas).
portales_activos <- function(valor = Sys.getenv("PORTALES", "FALSE")) identical(toupper(trimws(valor)), "TRUE")

# Ficheros manuales de la capa. Sin ninguno, se detiene y dice qué dejar y dónde.
buscar_ficheros_portales <- function(dir = DIR_PORTALES) {
  rutas <- sort(list.files(dir, pattern = "[.]csv$", full.names = TRUE))
  if (!length(rutas)) {
    stop("PORTALES=TRUE y no hay ficheros en ", dir, ". Deja ahi uno o varios CSV con las columnas ",
         paste(COLUMNAS_PORTALES, collapse = ", "), " (formato en R/fuente_portales.R), copiados a mano de los ",
         "informes agregados de las salas de prensa de Idealista y Fotocasa; nunca anuncios. ",
         "Para apagar la capa, quita la variable PORTALES o ponla a FALSE.", call. = FALSE)
  }
  rutas
}

# Lectura de los CSV manuales: códigos y periodos como texto, valor numérico, y el fichero de origen.
leer_portales <- function(rutas) {
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         locale = readr::locale(encoding = "UTF-8"))
    falta <- setdiff(COLUMNAS_PORTALES, names(x))
    if (length(falta)) stop("Faltan columnas en ", ruta, ": ", paste(falta, collapse = ", "), call. = FALSE)
    x <- x[COLUMNAS_PORTALES]
    x$valor <- suppressWarnings(as.numeric(x$valor))
    x$fichero <- basename(ruta)
    x
  }))
}

# Compuerta de la capa (inventario/referencias_validacion.csv, de bloqueo):
#   portales_formato: portal, operación, nivel, periodo (AAAA o AAAA-MM), valor, informe o enlace
#     que faltan o no son válidos;
#   portales_codigos: códigos que no son del seccionado de 2021 en su nivel;
#   portales_rango: precios fuera de lo posible (`rangos`: alquiler y venta, € por m²);
#   portales_repetidas: la misma cifra (portal, operación, territorio y periodo) dos veces.
comprobar_portales <- function(portales, territorios, rangos = list(alquiler = c(1, 100), venta = c(100, 20000))) {
  fila <- function(id, detalle, calculado) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = 0)
  p <- portales
  periodo_ok <- grepl("^[0-9]{4}(-(0[1-9]|1[0-2]))?$", p$periodo)
  largo <- NIVELES_PORTALES[p$nivel]
  codigo_ok <- !is.na(largo) & grepl("^[0-9]+$", p$geo_id) & nchar(p$geo_id) == largo
  formato <- c(
    "portal" = sum(!p$portal %in% PORTALES_VALIDOS),
    "operacion" = sum(!p$operacion %in% OPERACIONES_PORTALES),
    "nivel o codigo" = sum(!codigo_ok),
    "periodo" = sum(!periodo_ok),
    "valor" = sum(is.na(p$valor)),
    "informe o enlace" = sum(is.na(p$informe) | !nzchar(trimws(p$informe)) | is.na(p$url) | !grepl("^https?://", p$url))
  )
  conocidos <- paste(territorios$nivel, territorios$codigo)
  rango <- vapply(seq_len(nrow(p)), function(k) {
    r <- rangos[[p$operacion[k]]]
    !is.null(r) && !is.na(p$valor[k]) && (p$valor[k] < r[1] || p$valor[k] > r[2])
  }, logical(1))
  dplyr::bind_rows(
    fila("portales_formato", names(formato), formato),
    fila("portales_codigos", "codigos fuera del seccionado de 2021", sum(codigo_ok & !paste(p$nivel, p$geo_id) %in% conocidos)),
    fila("portales_rango", "precios fuera del rango posible", sum(rango)),
    fila("portales_repetidas", "cifras repetidas", sum(duplicated(p[c("portal", "operacion", "nivel", "geo_id", "periodo")])))
  )
}

# Tabla larga: una cifra por portal, operación, territorio y año (la del informe anual o, sin él, la
# del último mes publicado del año), con la etiqueta de dato privado de oferta en el corte.
armonizar_portales <- function(portales, version) {
  p <- portales
  p$anio <- as.integer(substr(p$periodo, 1, 4))
  p$orden <- ifelse(nchar(p$periodo) == 4, 99L, as.integer(substr(p$periodo, 6, 7)))   # el anual, por delante
  p |>
    dplyr::group_by(portal, operacion, nivel, geo_id, anio) |>
    dplyr::slice_max(orden, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "precio_oferta", corte = CORTE_PORTALES,
                     grupo = paste(operacion, portal, sep = "_"), valor, estado = "dato", fuente = "portales",
                     geo_ref = "2021", version = version) |>
    dplyr::arrange(grupo, nivel, geo_id, anio)
}
