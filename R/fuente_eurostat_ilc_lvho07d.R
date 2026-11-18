# Fuente eurostat_ilc_lvho07d (18-nov-2026): tasa de sobrecarga por gastos de vivienda por grado de
# urbanización (dimensión deg_urb: TOTAL, DEG1 ciudades, DEG2 pueblos y zonas suburbanas, DEG3 zonas
# rurales), de todos los países y agregados. Referencia de la compuerta del indicador 22 por grado de
# urbanización (sobrecarga_es_urbanizacion) y de los desgloses de España de la sección «Sobrecarga».
# Se pide a la API de Eurostat en JSON-stat (como ilc_li48, R/fuente_eurostat_ilc_li48.R), para
# conservar las marcas, y se guarda en datos/brutos/eurostat/: la referencia queda fija hasta que se
# decida actualizarla. Misma definición que ilc_lvho07a (R/fuente_eurostat_ilc_lvho07.R).

descargar_eurostat_ilc_lvho07d <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_lvho07d_europa.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  j <- httr2::request(paste0(URL_EUROSTAT_JSON, "ilc_lvho07d")) |>
    httr2::req_url_query(format = "JSON", lang = "EN") |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    jsonlite::fromJSON(simplifyVector = FALSE)
  datos <- normalizar_eurostat_ilc_lvho07d(tabla_jsonstat(j))
  readr::write_csv(datos, destino)
  destino
}

# Tabla de JSON-stat → conjunto, geo, grado, anio, valor y bandera (vacía si no hay marca); solo
# porcentajes, los grados de GRADOS_URBANIZACION y, de cualquier otra dimensión (como el grupo de
# renta, incgrp), el total.
normalizar_eurostat_ilc_lvho07d <- function(d) {
  if (!all(c("deg_urb", "geo", "time") %in% names(d))) {
    stop("ilc_lvho07d: dimensiones inesperadas (", paste(names(d), collapse = ", "), ")", call. = FALSE)
  }
  if ("unit" %in% names(d)) d <- d[d$unit == "PC", , drop = FALSE]
  if ("freq" %in% names(d)) d <- d[d$freq == "A", , drop = FALSE]
  otras <- setdiff(names(d), c("deg_urb", "geo", "time", "unit", "freq", "valor", "bandera"))
  for (k in otras) d <- d[d[[k]] %in% c("TOTAL", "T"), , drop = FALSE]
  bandera <- trimws(as.character(d$bandera))
  datos <- tibble::tibble(conjunto = "ilc_lvho07d", geo = as.character(d$geo), grado = as.character(d$deg_urb),
                          anio = as.integer(d$time), valor = as.numeric(d$valor),
                          bandera = ifelse(is.na(bandera) | bandera == "", NA_character_, bandera)) |>
    filter(!is.na(valor), grado %in% GRADOS_URBANIZACION)
  if (!nrow(datos)) stop("Eurostat no devuelve datos de ilc_lvho07d", call. = FALSE)
  if (anyDuplicated(datos[c("geo", "grado", "anio")])) stop("ilc_lvho07d: filas repetidas por país, grado y año", call. = FALSE)
  if (!any(datos$geo == "ES" & datos$grado == "DEG1")) stop("ilc_lvho07d no trae España por grado de urbanización", call. = FALSE)
  arrange(datos, geo, grado, anio)
}

leer_eurostat_ilc_lvho07d <- function(ruta) {
  readr::read_csv(ruta, col_types = "cccidc", progress = FALSE)
}
