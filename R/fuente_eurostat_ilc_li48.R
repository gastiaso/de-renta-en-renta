# Fuente eurostat_ilc_li48 (tarea 65, parte B): tasa de riesgo de pobreza tras deducir los gastos
# de vivienda, por grado de urbanización (dimensión deg_urb: TOTAL, DEG1 ciudades, DEG2 pueblos y
# zonas suburbanas, DEG3 zonas rurales), de todos los países y agregados. Referencia de la compuerta
# del indicador 24 (ahc_es_eurostat) y cifras de los países en «La escalera» de la sección
# «Sobrecarga». Se pide a la API de Eurostat en JSON-stat (como ilc_lvho07b), para conservar las
# marcas, y se guarda en datos/brutos/eurostat/: la referencia queda fija hasta que se decida
# actualizarla.
#
# Definición de Eurostat (metodología de EU-SILC, pobreza monetaria): porcentaje de personas de toda
# la población cuya renta disponible equivalente sin el gasto total en vivienda (HH070) queda por
# debajo del umbral de riesgo de pobreza calculado de la forma habitual (60 % de la mediana de la renta
# disponible equivalente, antes de restar la vivienda).

GRADOS_URBANIZACION <- c("TOTAL", "DEG1", "DEG2", "DEG3")

descargar_eurostat_ilc_li48 <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_li48_europa.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  j <- httr2::request(paste0(URL_EUROSTAT_JSON, "ilc_li48")) |>
    httr2::req_url_query(format = "JSON", lang = "EN") |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    jsonlite::fromJSON(simplifyVector = FALSE)
  datos <- normalizar_eurostat_ilc_li48(tabla_jsonstat(j))
  readr::write_csv(datos, destino)
  destino
}

# Tabla de JSON-stat → conjunto, geo, grado, anio, valor y bandera (vacía si no hay marca); solo
# porcentajes y los grados de GRADOS_URBANIZACION.
normalizar_eurostat_ilc_li48 <- function(d) {
  if (!all(c("deg_urb", "geo", "time") %in% names(d))) {
    stop("ilc_li48: dimensiones inesperadas (", paste(names(d), collapse = ", "), ")", call. = FALSE)
  }
  if ("unit" %in% names(d)) d <- d[d$unit == "PC", , drop = FALSE]
  if ("freq" %in% names(d)) d <- d[d$freq == "A", , drop = FALSE]
  bandera <- trimws(as.character(d$bandera))
  datos <- tibble::tibble(conjunto = "ilc_li48", geo = as.character(d$geo), grado = as.character(d$deg_urb),
                          anio = as.integer(d$time), valor = as.numeric(d$valor),
                          bandera = ifelse(is.na(bandera) | bandera == "", NA_character_, bandera)) |>
    filter(!is.na(valor), grado %in% GRADOS_URBANIZACION)
  if (!nrow(datos)) stop("Eurostat no devuelve datos de ilc_li48", call. = FALSE)
  if (anyDuplicated(datos[c("geo", "grado", "anio")])) stop("ilc_li48: filas repetidas por país, grado y año", call. = FALSE)
  if (!any(datos$geo == "ES" & datos$grado == "TOTAL")) stop("ilc_li48 no trae España", call. = FALSE)
  arrange(datos, geo, grado, anio)
}

leer_eurostat_ilc_li48 <- function(ruta) {
  readr::read_csv(ruta, col_types = "cccidc", progress = FALSE)
}
