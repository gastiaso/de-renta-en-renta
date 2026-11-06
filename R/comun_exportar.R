# Exportación de resultados que se publican o se versionan.

# Tabla larga única (guía de trabajo, «Modelo de datos»).
COLUMNAS_TABLA_LARGA <- c("geo_id", "nivel", "anio", "indicador", "valor", "estado", "fuente", "geo_ref", "version")
NIVELES <- c(sc = 10L, distrito = 7L, municipio = 5L, cp = 5L, provincia = 2L, ccaa = 2L, nacional = 2L)   # nacional: «00»
ESTADOS <- c("dato", "secreto", "ausente", "estimado")

# Comprueba el esquema y la coherencia de la tabla larga; se detiene con el primer problema.
validar_tabla_larga <- function(tabla, indicadores = NULL, fuentes = NULL) {
  falta <- setdiff(COLUMNAS_TABLA_LARGA, names(tabla))
  if (length(falta) > 0) stop("Faltan columnas en la tabla larga: ", paste(falta, collapse = ", "), call. = FALSE)
  problema <- function(cond, texto) if (any(cond)) stop(texto, " (", sum(cond), " filas)", call. = FALSE)
  problema(!tabla$nivel %in% names(NIVELES), "Nivel desconocido")
  problema(nchar(tabla$geo_id) != NIVELES[tabla$nivel] | grepl("[^0-9]", tabla$geo_id),
           "Código territorial con longitud o caracteres incorrectos")
  problema(!tabla$estado %in% ESTADOS, "Estado desconocido")
  problema(is.na(tabla$valor) & tabla$estado %in% c("dato", "estimado"), "Valor vacío con estado dato o estimado")
  problema(!is.na(tabla$valor) & tabla$estado %in% c("secreto", "ausente"), "Valor con estado secreto o ausente")
  problema(duplicated(tabla[c("geo_id", "nivel", "anio", "indicador", "fuente")]), "Filas repetidas")
  if (!is.null(indicadores)) problema(!tabla$indicador %in% indicadores$codigo, "Indicador fuera del catálogo")
  if (!is.null(fuentes)) problema(!tabla$fuente %in% fuentes$id, "Fuente fuera del inventario")
  tabla
}

# Diccionarios de la web (web/i18n/es.json y en.json). Las secciones «indicadores», «fuentes»
# y «vocabulario» se generan desde inventario/ (no se editan a mano); las demás (sitio, nav,
# fichas, avisos…) se escriben a mano y se conservan.
exportar_i18n <- function(indicadores, fuentes, vocabulario, dir = file.path("web", "i18n")) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  rutas <- file.path(dir, c("es.json", "en.json"))
  for (i in 1:2) {
    idioma <- c("es", "en")[i]
    col <- function(base) indicadores[[paste0(base, "_", idioma)]]
    dic <- if (file.exists(rutas[i])) jsonlite::read_json(rutas[i]) else list()
    dic$indicadores <- stats::setNames(lapply(seq_len(nrow(indicadores)), function(k) list(
      nombre = col("nombre")[k], unidad = col("unidad")[k], definicion = col("definicion")[k],
      calculo = col("calculo")[k], lectura = col("lectura")[k]
    )), indicadores$codigo)
    dic$fuentes <- stats::setNames(as.list(if (idioma == "es") fuentes$nombre else fuentes$nombre_en), fuentes$id)
    dic$vocabulario <- lapply(split(vocabulario, vocabulario$grupo),
                              function(v) stats::setNames(as.list(v[[idioma]]), v$clave))
    jsonlite::write_json(dic, rutas[i], auto_unbox = TRUE, pretty = TRUE)
  }
  rutas
}

# Comprueba que los dos diccionarios tienen las mismas claves y ningún texto vacío.
comprobar_i18n <- function(rutas) {
  claves <- function(x, prefijo = "") {
    if (!is.list(x)) return(prefijo)
    unlist(lapply(names(x), function(n) claves(x[[n]], paste0(prefijo, "/", n))))
  }
  vacios <- function(x) if (is.list(x)) sum(vapply(x, vacios, numeric(1))) else as.numeric(is.null(x) || is.na(x) || !nzchar(x))
  es <- jsonlite::read_json(rutas[1]); en <- jsonlite::read_json(rutas[2])
  tibble::tibble(
    id = "i18n_completo", anio = NA_integer_,
    detalle = c("claves solo en es", "claves solo en en", "textos vacíos"),
    calculado = c(length(setdiff(claves(es), claves(en))), length(setdiff(claves(en), claves(es))), vacios(es) + vacios(en)),
    referencia = 0
  )
}

# Sobrecarga (F1b): cifras anuales de España por corte, cruces con varias olas y «escalera».
# Van aparte de la tabla larga, que no tiene dimensión de corte (tenencia, edad).
exportar_sobrecarga <- function(anual, agrupada, escalera, dir = file.path("datos", "intermedios", "sobrecarga")) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  rutas <- c(
    file.path(dir, "espana_anual.csv"),
    file.path(dir, "espana_agrupada.csv"),
    file.path(dir, sprintf("escalera_%d.csv", unique(escalera$anio)))
  )
  readr::write_csv(anual |> mutate(valor = round(valor, 2)), rutas[1])
  readr::write_csv(agrupada |> mutate(valor = round(valor, 2)), rutas[2])
  readr::write_csv(escalera, rutas[3])
  rutas
}

# Escribe la tabla larga en Parquet, ordenada, con los tipos fijos del esquema.
exportar_tabla_larga <- function(tabla, ruta) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  tabla |>
    transmute(geo_id = as.character(geo_id), nivel = as.character(nivel), anio = as.integer(anio),
              indicador = as.character(indicador), valor = as.numeric(valor), estado = as.character(estado),
              fuente = as.character(fuente), geo_ref = as.character(geo_ref), version = as.character(version)) |>
    arrange(fuente, indicador, nivel, geo_id, anio) |>
    arrow::write_parquet(ruta)
  ruta
}

# Tabla de paso a CSV (geo/tablas_paso/): una fila por par origen → destino.
exportar_tabla_paso <- function(tabla, ruta) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  tabla |>
    arrange(origen, destino) |>
    mutate(fraccion = round(fraccion, 6)) |>
    select(origen, destino, portales, metodo, fraccion) |>
    readr::write_csv(ruta, na = "")
  ruta
}
