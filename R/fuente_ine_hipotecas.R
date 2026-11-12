# INE, Estadística de Hipotecas (H): tipo de interés medio al inicio de las hipotecas constituidas
# sobre viviendas, total (fijo y variable), España. Es el «tipo medio» de la cuota hipotecaria
# sobre la renta del hogar (indicador 17, F4; plan §5 C). Dos tablas de INEbase en CSV de jaxiT3: la anual (24460,
# desde 2003) y la mensual (24457, desde 2009), que sirve de compuerta. Licencia: CC BY 4.0.
# Se toma la cifra anual publicada del mismo año que el valor tasado (regla 4).

TABLAS_HIPOTECAS <- c(anual = "24460", mensual = "24457")

descargar_ine_hipotecas <- function(id, dir = file.path("datos", "brutos", "ine_hipotecas"), forzar = FALSE) {
  descargar_con_cache(sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv?nocab=1", id),
                      file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Una tabla en formato ordenado: tipo (Total, Fijo, Variable), finca (Total fincas, Viviendas),
# anio, mes (NA en la anual) y valor (%). Se detiene si a alguna serie le faltan periodos
# (descarga cortada sin error).
leer_ine_hipotecas <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- c("tipo", "finca", "periodo", "valor")
  x <- tibble::tibble(tipo = d$tipo, finca = d$finca,
                      anio = as.integer(substr(d$periodo, 1, 4)),
                      mes = ifelse(grepl("M", d$periodo), as.integer(sub("^.*M", "", d$periodo)), NA_integer_),
                      valor = numero_jaxi(d$valor))
  n <- dplyr::count(x, tipo, finca)
  if (length(unique(n$n)) != 1) {
    stop("Hipotecas ", basename(ruta), ": series con distinto n\u00famero de periodos. \u00bfDescarga cortada?", call. = FALSE)
  }
  x
}

# Tipo medio anual de las hipotecas sobre viviendas (total), en %: una fila por año.
tipo_hipotecario <- function(anual) {
  anual |>
    dplyr::filter(tipo == "Total", finca == "Viviendas", !is.na(valor)) |>
    dplyr::transmute(anio, tipo = valor) |>
    dplyr::arrange(anio)
}

# Compuerta del tipo hipotecario (inventario/referencias_validacion.csv):
#   hipotecas_tipo_anual (bloqueo): por año de `anios` con los doce meses publicados, diferencia
#     entre la cifra anual de la tabla 24460 y la media simple de los meses de la 24457 (puntos);
#   hipotecas_serie (bloqueo): años de `anios` sin tipo anual.
comprobar_ine_hipotecas <- function(anual, mensual, anios) {
  tipo <- tipo_hipotecario(anual)
  meses <- mensual |>
    dplyr::filter(tipo == "Total", finca == "Viviendas", !is.na(valor)) |>
    dplyr::group_by(anio) |>
    dplyr::summarise(n = dplyr::n(), media = mean(valor), .groups = "drop") |>
    dplyr::filter(n == 12)
  coherencia <- tipo |>
    dplyr::inner_join(meses, by = "anio") |>
    dplyr::filter(anio %in% anios) |>
    dplyr::transmute(id = "hipotecas_tipo_anual", anio, detalle = "viviendas, total",
                     calculado = tipo - media, referencia = 0)
  serie <- tibble::tibble(id = "hipotecas_serie", anio = NA_integer_, detalle = "a\u00f1os sin tipo anual",
                          calculado = sum(!anios %in% tipo$anio), referencia = 0)
  dplyr::bind_rows(coherencia, serie) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}
