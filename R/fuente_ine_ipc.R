# INE, Índice de Precios de Consumo (IPC), base 2025: medias anuales del índice general nacional y su
# variación, en la tabla 76144 de INEbase («Índices nacionales: general y de grupos ECOICOP ver.2»,
# medias anuales; CSV de jaxiT3), desde 2002. Sirve al aviso de la evolución de la ficha (backlog,
# tarea 45): las series del atlas están en euros corrientes de cada año, y la web dice cuánto subió
# el IPC entre el primer y el último año de la serie que enseña (datos/ipc.json). No deflacta ninguna
# cifra del atlas ni entra en la tabla larga. Licencia: CC BY 4.0 (aviso legal del INE).

TABLA_IPC <- "76144"

ipc_descargar <- function(id = TABLA_IPC, dir = file.path("datos", "brutos", "ine_ipc"), forzar = FALSE) {
  descargar_con_cache(sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv?nocab=1", id),
                      file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Índice general: una fila por año, con la media anual del índice (tres decimales, como lo publica
# el INE) y la variación de las medias anuales (un decimal; NA el primer año). Se detiene si falta
# algún año entre el primero y el último, si un año sale dos veces o si falta el índice de algún
# año: las descargas del INE pueden llegar cortadas sin dar error.
ipc_leer <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- sub("^\ufeff", "", names(d))
  if (!all(c("Tipo de dato", "Periodo", "Total") %in% names(d))) {
    stop("IPC ", basename(ruta), ": faltan las columnas Tipo de dato, Periodo o Total", call. = FALSE)
  }
  general <- trimws(d[[1]]) == "\u00cdndice general"
  if (!any(general)) stop("IPC ", basename(ruta), ": sin filas del \u00edndice general", call. = FALSE)
  d <- d[general, ]
  medida <- dplyr::case_when(trimws(d[["Tipo de dato"]]) == "Media anual" ~ "indice",
                             grepl("^Variaci", trimws(d[["Tipo de dato"]])) ~ "variacion",
                             TRUE ~ NA_character_)
  x <- tibble::tibble(anio = as.integer(trimws(d$Periodo)), medida = medida, valor = numero_jaxi(d$Total)) |>
    dplyr::filter(!is.na(.data$medida))
  if (anyDuplicated(x[c("anio", "medida")])) stop("IPC ", basename(ruta), ": a\u00f1os repetidos", call. = FALSE)
  ipc <- tidyr::pivot_wider(x, names_from = "medida", values_from = "valor") |> dplyr::arrange(.data$anio)
  if (!"variacion" %in% names(ipc)) ipc$variacion <- NA_real_
  huecos <- setdiff(seq(min(ipc$anio), max(ipc$anio)), ipc$anio)
  if (length(huecos) || anyNA(ipc$indice)) {
    stop("IPC ", basename(ruta), ": serie cortada (a\u00f1os sin \u00edndice: ",
         paste(c(huecos, ipc$anio[is.na(ipc$indice)]), collapse = ", "), ")", call. = FALSE)
  }
  dplyr::select(ipc, "anio", "indice", "variacion")
}

# Compuerta del IPC (inventario/referencias_validacion.csv):
#   ipc_variacion (bloqueo): diferencia maxima entre la variacion publicada y la recalculada con los
#     indices del ano y del anterior, que el INE redondea a tres decimales;
#   ipc_serie (bloqueo): anos que faltan desde 2015 hasta el ultimo ano del alquiler (2024);
#   ipc_referencia (bloqueo): variacion de las medias anuales de 2022 publicada por el INE, 8,4 %.
ipc_comprobar <- function(ipc, desde = 2015L, hasta = 2024L) {
  recalculada <- 100 * (ipc$indice / dplyr::lag(ipc$indice) - 1)
  dif <- abs(ipc$variacion - recalculada)
  tibble::tibble(
    id = c("ipc_variacion", "ipc_serie", "ipc_referencia"),
    anio = c(NA_integer_, NA_integer_, 2022L),
    detalle = c("diferencia maxima (puntos)", sprintf("anos sin indice de %d a %d", desde, hasta),
                "variacion de las medias anuales (%)"),
    calculado = c(if (all(is.na(dif))) Inf else max(dif, na.rm = TRUE),
                  length(setdiff(desde:hasta, ipc$anio[!is.na(ipc$indice)])),
                  dplyr::coalesce(ipc$variacion[ipc$anio == 2022L][1], NA_real_)),
    referencia = c(0, 0, 8.4)
  )
}

# datos/ipc.json para la web: la fuente, la licencia, el año base (el de índice 100, o null) y los
# índices de cada año, con los tres decimales del INE.
ipc_exportar_web <- function(ipc, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "ipc.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  base <- ipc$anio[which(abs(ipc$indice - 100) < 1e-9)]
  x <- list(
    fuente = "INE, \u00cdndice de Precios de Consumo: medias anuales del \u00edndice general nacional (tabla 76144)",
    licencia = "CC BY 4.0 (aviso legal del INE)",
    base = if (length(base)) base[1] else NULL,
    anios = ipc$anio,
    indice = ipc$indice
  )
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, pretty = FALSE, null = "null")
  ruta
}

# Ida y vuelta de datos/ipc.json (web_ipc, bloqueo): años de más o de menos e índices distintos de
# los de la tabla.
ipc_comprobar_web <- function(ipc, ruta) {
  x <- jsonlite::read_json(ruta, simplifyVector = TRUE)
  mismos_anios <- identical(as.integer(x$anios), ipc$anio)
  distintos <- if (mismos_anios) sum(abs(as.numeric(x$indice) - ipc$indice) > 1e-9) else Inf
  tibble::tibble(id = "web_ipc", anio = NA_integer_,
                 detalle = c("anos distintos de la tabla", "indices distintos"),
                 calculado = c(if (mismos_anios) 0 else 1, distintos), referencia = 0)
}
