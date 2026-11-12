# INE, Índice de Precios de Consumo (IPC), base 2025: medias anuales del índice general nacional y su
# variación, en la tabla 76144 de INEbase («Índices nacionales: general y de grupos ECOICOP ver.2»,
# medias anuales; CSV de jaxiT3), desde 2002. Sirve al aviso de la evolución de la ficha (backlog,
# tarea 45) y a los euros constantes de la web (decisión del autor, 12-nov-2026): las series del atlas
# están en euros corrientes de cada año; la Máquina del tiempo (valor tasado y sueldo medio) y la
# evolución de la ficha ofrecen además «Euros de {año base}», con el año base en el último año con
# media anual publicada (ipc_anio_base()). La web deflacta con datos/ipc.json; aquí, la misma cuenta
# (ipc_deflactar()) para el fichero de control de la página (ipc_exportar_control()). Nada deflactado
# entra en la tabla larga. Antes de 2002 no hay índice en base 2025: la serie del INE «desde enero de
# 1961» (tabla 24077) va vacía hasta diciembre de 2001 (comprobado el 12-nov-2026), y no se empalma
# con bases anteriores. Licencia: CC BY 4.0 (aviso legal del INE).

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

# datos/ipc.json para la web: la fuente, la licencia, el año base del índice (el de índice 100, o
# null), el de los euros constantes (anio_base, el último con media anual) y los índices de cada
# año, con los tres decimales del INE.
ipc_exportar_web <- function(ipc, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "ipc.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  base <- ipc$anio[which(abs(ipc$indice - 100) < 1e-9)]
  x <- list(
    fuente = "INE, \u00cdndice de Precios de Consumo: medias anuales del \u00edndice general nacional (tabla 76144)",
    licencia = "CC BY 4.0 (aviso legal del INE)",
    base = if (length(base)) base[1] else NULL,
    anio_base = ipc_anio_base(ipc),   # el de los euros constantes de la web (ipc_anio_base())
    anios = ipc$anio,
    indice = ipc$indice
  )
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, pretty = FALSE, null = "null")
  ruta
}

# --- Euros constantes (decisión del autor, 12-nov-2026) -------------------------------------------

# Series de la Máquina del tiempo que se ofrecen también en euros del año base.
IPC_SERIES_DEFLACTADAS <- c("valor_tasado", "sueldo_asalariado")

# Año base: el último año con media anual publicada (el año en curso no la tiene hasta enero).
ipc_anio_base <- function(ipc) max(ipc$anio[!is.na(ipc$indice)])

# Valor en euros del año base: valor × índice del año base / índice de su año (media anual). NA en
# los años sin media anual: antes del primero del índice (2002) y después del año base (el año en
# curso). Los trimestres van con la media anual de su año.
ipc_deflactar <- function(valor, anio, ipc, base = ipc_anio_base(ipc)) {
  i_anio <- ipc$indice[match(as.integer(anio), ipc$anio)]
  i_base <- ipc$indice[match(as.integer(base), ipc$anio)]
  valor * i_base / i_anio
}

# Compuerta de los euros constantes (inventario/referencias_validacion.csv):
#   ipc_deflactor_anios (bloqueo): años sin media anual entre el primero del índice y el año base;
#   ipc_deflactor_base (bloqueo): el año base es el último con media anual y su índice es el de la
#     tabla (diferencia con el último año de la tabla, en años);
#   ipc_referencia_2008, ipc_referencia_2009 (bloqueo): variación de las medias anuales que el INE
#     publicó para esos años (4,1 % y −0,3 %), recalculada con los índices en base 2025 a un decimal.
ipc_comprobar_deflactor <- function(ipc) {
  base <- ipc_anio_base(ipc)
  con <- ipc$anio[!is.na(ipc$indice)]
  recalculada <- function(a) {
    x <- 100 * (ipc$indice[ipc$anio == a] / ipc$indice[ipc$anio == a - 1L] - 1)
    if (length(x) == 1L) redondeo_guia(x, 1L) else NA_real_
  }
  tibble::tibble(
    id = c("ipc_deflactor_anios", "ipc_deflactor_base", "ipc_referencia_2008", "ipc_referencia_2009"),
    anio = c(NA_integer_, as.integer(base), 2008L, 2009L),
    detalle = c(sprintf("anos sin media anual de %d a %d", min(con), base), "anos entre el ano base y el ultimo de la tabla",
                "variacion de las medias anuales recalculada (%)", "variacion de las medias anuales recalculada (%)"),
    calculado = c(length(setdiff(seq(min(con), base), con)), max(ipc$anio) - base, recalculada(2008L), recalculada(2009L)),
    referencia = c(0, 0, 4.1, -0.3)
  )
}

# Cifras de control de la página (web/datos/ipc_control.json): las series de España en euros del
# año base, deflactadas desde la cifra que recibe la web (valor_web(), ya redondeada) y redondeadas
# con la guía a los decimales de su escala, como vectores de historico.json (inicio, v × escala; null
# sin índice). pruebas/web/historico.test.mjs comprueba que la página da las mismas.
ipc_control_deflactado <- function(historico, ipc, series = IPC_SERIES_DEFLACTADAS, escalas = HIST_ESCALAS_WEB) {
  base <- ipc_anio_base(ipc)
  lapply(stats::setNames(series, series), function(s) {
    d <- historico[historico$serie == s & historico$geo_id == "00", ]
    d <- d[order(d$anio, d$subperiodo), ]
    escala <- escalas[[s]]
    publicado <- valor_web(d$valor, escala) / escala
    d$valor <- ipc_deflactar(publicado, d$anio, ipc, base)
    hist_serie_json(d, escala)
  })
}

ipc_exportar_control <- function(historico, ipc, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "ipc_control.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  x <- list(anio_base = ipc_anio_base(ipc), series = ipc_control_deflactado(historico, ipc))
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, na = "null", null = "null")
  ruta
}

# Ida y vuelta del control (web_ipc_control, bloqueo): año base y cifras frente a la cuenta de R.
ipc_comprobar_control <- function(historico, ipc, ruta) {
  x <- jsonlite::fromJSON(ruta, simplifyVector = FALSE)
  esperado <- ipc_control_deflactado(historico, ipc)
  plano <- function(l) vapply(unlist(lapply(l, function(s) s$v), recursive = FALSE),
                              function(z) if (is.null(z)) NA_real_ else as.numeric(z), 0)
  a <- plano(x$series)
  b <- plano(lapply(esperado, function(s) list(v = as.list(s$v))))
  distintos <- if (length(a) == length(b)) sum(xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b)) else Inf
  tibble::tibble(id = "web_ipc_control", anio = NA_integer_,
                 detalle = c("ano base distinto", "cifras distintas"),
                 calculado = c(as.numeric(!identical(as.integer(x$anio_base), as.integer(ipc_anio_base(ipc)))), distintos),
                 referencia = 0)
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
