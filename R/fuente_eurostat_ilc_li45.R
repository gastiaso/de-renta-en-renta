# Fuente eurostat_ilc_li45 (17-nov-2026): tasa de riesgo de pobreza tras deducir los gastos de
# vivienda por edad y sexo (dimensiones age y sex), de todos los países y agregados. Referencia de la
# compuerta del indicador 24 por edad (ahc_es_edad) y de los desgloses de España por edad de la
# sección «Sobrecarga». Se pide a la API de Eurostat en JSON-stat (como ilc_li48), para conservar las
# marcas, y se guarda en datos/brutos/eurostat/: la referencia queda fija hasta que se decida
# actualizarla. Misma definición que ilc_li48 (R/fuente_eurostat_ilc_li48.R).

descargar_eurostat_ilc_li45 <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_li45_europa.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  j <- httr2::request(paste0(URL_EUROSTAT_JSON, "ilc_li45")) |>
    httr2::req_url_query(format = "JSON", lang = "EN") |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    jsonlite::fromJSON(simplifyVector = FALSE)
  datos <- normalizar_eurostat_ilc_li45(tabla_jsonstat(j))
  readr::write_csv(datos, destino)
  destino
}

# Tabla de JSON-stat → conjunto, geo, edad, sexo, anio, valor y bandera (vacía si no hay marca); solo
# porcentajes.
normalizar_eurostat_ilc_li45 <- function(d) {
  if (!all(c("age", "sex", "geo", "time") %in% names(d))) {
    stop("ilc_li45: dimensiones inesperadas (", paste(names(d), collapse = ", "), ")", call. = FALSE)
  }
  if ("unit" %in% names(d)) d <- d[d$unit == "PC", , drop = FALSE]
  if ("freq" %in% names(d)) d <- d[d$freq == "A", , drop = FALSE]
  bandera <- trimws(as.character(d$bandera))
  datos <- tibble::tibble(conjunto = "ilc_li45", geo = as.character(d$geo), edad = as.character(d$age),
                          sexo = as.character(d$sex), anio = as.integer(d$time), valor = as.numeric(d$valor),
                          bandera = ifelse(is.na(bandera) | bandera == "", NA_character_, bandera)) |>
    filter(!is.na(valor))
  if (!nrow(datos)) stop("Eurostat no devuelve datos de ilc_li45", call. = FALSE)
  if (anyDuplicated(datos[c("geo", "edad", "sexo", "anio")])) stop("ilc_li45: filas repetidas por país, edad, sexo y año", call. = FALSE)
  if (!any(datos$geo == "ES" & datos$edad == "TOTAL" & datos$sexo == "T")) stop("ilc_li45 no trae España", call. = FALSE)
  arrange(datos, geo, edad, sexo, anio)
}

leer_eurostat_ilc_li45 <- function(ruta) {
  readr::read_csv(ruta, col_types = "ccccidc", progress = FALSE)
}
