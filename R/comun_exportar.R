# Exportación de resultados que se publican o se versionan.

# Tabla larga única (guía de trabajo, «Modelo de datos»).
COLUMNAS_TABLA_LARGA <- c("geo_id", "nivel", "anio", "indicador", "valor", "estado", "fuente", "geo_ref", "version")
NIVELES <- c(sc = 10L, distrito = 7L, municipio = 5L, cp = 5L, provincia = 2L, ccaa = 2L)
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
