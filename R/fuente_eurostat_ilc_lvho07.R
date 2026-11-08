# Fuentes eurostat_ilc_lvho07 y eurostat_ilc_lvho07_r: tasa de sobrecarga por gastos de
# vivienda publicada por Eurostat. Referencia de la compuerta del indicador 22.
#   ilc_lvho07a: total (por edad, sexo y grupo de renta)
#   ilc_lvho07c: por tenencia
#   ilc_lvho07_r: regiones NUTS 2 (solo población total)
#   ilc_lvho07b: por quintil de renta (solo España; compuerta del cálculo por quintil)
# La consulta se guarda en datos/brutos/eurostat/ y no se repite salvo que se pida:
# la referencia queda fija hasta que se decida actualizarla.

REGIONES_ES <- c("ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41",
                 "ES42", "ES43", "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70")

# Deja solo el total de cada dimensión que no sea geo, tiempo o tenencia.
quedarse_con_totales <- function(datos) {
  totales <- c(age = "TOTAL", sex = "T", rskpovth = "TOTAL", incgrp = "TOTAL",
               hhtyp = "TOTAL", deg_urb = "TOTAL", unit = "PC", freq = "A")
  for (columna in intersect(names(datos), names(totales))) {
    datos <- datos[datos[[columna]] == totales[[columna]], , drop = FALSE]
  }
  datos
}

consultar_eurostat <- function(id, geo) {
  datos <- eurostat::get_eurostat(id, filters = list(geo = geo), time_format = "num",
                                  cache = FALSE)
  if (is.null(datos) || nrow(datos) == 0) stop("Eurostat no devuelve datos de ", id, call. = FALSE)
  datos <- quedarse_con_totales(as.data.frame(datos))
  claves <- intersect(c("geo", "tenure", "TIME_PERIOD", "time"), names(datos))
  if (anyDuplicated(datos[claves])) {
    stop(id, ": quedan filas repetidas tras filtrar los totales; revisar sus dimensiones (",
         paste(names(datos), collapse = ", "), ")", call. = FALSE)
  }
  columna_tiempo <- intersect(c("TIME_PERIOD", "time"), names(datos))[1]
  tibble::tibble(
    conjunto = id,
    geo      = as.character(datos$geo),
    tenencia = if ("tenure" %in% names(datos)) as.character(datos$tenure) else "TOTAL",
    anio     = as.integer(datos[[columna_tiempo]]),
    valor    = as.numeric(datos$values)
  ) |>
    filter(!is.na(valor))
}

descargar_eurostat_ilc_lvho07 <- function(dir = file.path("datos", "brutos", "eurostat"),
                                          forzar = FALSE) {
  destino <- file.path(dir, "ilc_lvho07_es.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  datos <- bind_rows(
    consultar_eurostat("ilc_lvho07a", "ES"),
    consultar_eurostat("ilc_lvho07c", "ES"),
    consultar_eurostat("ilc_lvho07_r", REGIONES_ES)
  )
  readr::write_csv(datos, destino)
  destino
}

leer_eurostat_ilc_lvho07 <- function(ruta) {
  readr::read_csv(ruta, col_types = "cccid", progress = FALSE)
}

# Europa (mapa y «escalera»): todos los países y agregados, con tenencia (ilc_lvho07c),
# edad (ilc_lvho07a: total y los grupos del atlas) y regiones (ilc_lvho07_r), con las marcas de
# Eurostat de cada cifra en `bandera` (b: ruptura de serie; u: poco fiable; p: provisional;
# e: estimado; d: definición distinta; varias juntas, como «bu»). Sin marca, vacía.
EDADES_ATLAS <- c("TOTAL", "Y_LT18", "Y18-64", "Y_GE65", "Y15-29")

descargar_eurostat_europa <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_lvho07_europa.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  normalizar <- function(id) {
    d <- as.data.frame(eurostat::get_eurostat(id, time_format = "num", cache = FALSE, keepFlags = TRUE))
    if (!"flags" %in% names(d)) stop(id, ": Eurostat no devuelve las marcas (flags)", call. = FALSE)
    tiempo <- intersect(c("TIME_PERIOD", "time"), names(d))[1]
    if ("age" %in% names(d)) d <- d[d$age %in% EDADES_ATLAS, , drop = FALSE] else d$age <- "TOTAL"
    if ("sex" %in% names(d)) d <- d[d$sex == "T", , drop = FALSE]
    if ("rskpovth" %in% names(d)) d <- d[d$rskpovth == "TOTAL", , drop = FALSE]
    if ("unit" %in% names(d)) d <- d[d$unit == "PC", , drop = FALSE]
    bandera <- trimws(as.character(d$flags))
    tibble::tibble(
      conjunto = id, geo = as.character(d$geo),
      tenencia = if ("tenure" %in% names(d)) as.character(d$tenure) else "TOTAL",
      edad = as.character(d$age), anio = as.integer(d[[tiempo]]), valor = as.numeric(d$values),
      bandera = ifelse(is.na(bandera) | bandera == "", NA_character_, bandera)
    ) |>
      filter(!is.na(valor))
  }
  datos <- bind_rows(normalizar("ilc_lvho07a"), normalizar("ilc_lvho07c"), normalizar("ilc_lvho07_r"))
  if (anyDuplicated(datos[c("conjunto", "geo", "tenencia", "edad", "anio")])) {
    stop("Filas repetidas en la descarga europea de Eurostat", call. = FALSE)
  }
  readr::write_csv(datos, destino)
  destino
}

leer_eurostat_europa <- function(ruta) {
  readr::read_csv(ruta, col_types = "ccccidc", progress = FALSE)
}

# Quintil de renta disponible equivalente (ilc_lvho07b, dimensión quant_inc: TOTAL y QU1–QU5),
# solo España, con las marcas, para contrastar el cálculo por quintil con la ECV (pregunta
# abierta 31). El paquete eurostat no da las marcas cuando se filtra por país, así que se pide
# a la API de Eurostat en JSON-stat (unos 5 KB).
URL_EUROSTAT_JSON <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

# JSON-stat 2.0 de Eurostat → una fila por casilla, con el código de cada dimensión, `valor` y
# `bandera`. Las casillas van en orden de filas: la última dimensión es la que cambia más rápido.
tabla_jsonstat <- function(j) {
  dims <- unlist(j$id)
  codigos <- stats::setNames(lapply(dims, function(d) {
    posicion <- unlist(j$dimension[[d]]$category$index)
    names(posicion)[order(posicion)]
  }), dims)
  if (prod(lengths(codigos)) != prod(unlist(j$size))) stop("JSON-stat: tama\u00f1os que no cuadran", call. = FALSE)
  rejilla <- expand.grid(rev(codigos), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)[dims]
  claves <- as.character(seq_len(nrow(rejilla)) - 1L)
  valor <- unlist(j$value)
  if (is.null(names(valor))) names(valor) <- claves[seq_along(valor)]
  bandera <- unlist(j$status)
  tibble::as_tibble(rejilla) |>
    mutate(valor = unname(as.numeric(valor[claves])),
           bandera = if (is.null(bandera)) NA_character_ else unname(bandera[claves]))
}

descargar_eurostat_quintil <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_lvho07b_es.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  j <- httr2::request(paste0(URL_EUROSTAT_JSON, "ilc_lvho07b")) |>
    httr2::req_url_query(geo = "ES", format = "JSON", lang = "EN") |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_perform() |>
    httr2::resp_body_string(encoding = "UTF-8") |>
    jsonlite::fromJSON(simplifyVector = FALSE)
  d <- tabla_jsonstat(j)
  if (!all(c("quant_inc", "geo", "time") %in% names(d))) {
    stop("ilc_lvho07b: dimensiones inesperadas (", paste(names(d), collapse = ", "), ")", call. = FALSE)
  }
  datos <- quedarse_con_totales(d) |>
    mutate(bandera = trimws(bandera)) |>
    transmute(conjunto = "ilc_lvho07b", geo, quintil = quant_inc, anio = as.integer(time), valor,
              bandera = if_else(is.na(bandera) | bandera == "", NA_character_, bandera)) |>
    filter(!is.na(valor))
  if (nrow(datos) == 0) stop("Eurostat no devuelve datos de ilc_lvho07b para Espa\u00f1a", call. = FALSE)
  if (anyDuplicated(datos[c("geo", "quintil", "anio")])) {
    stop("ilc_lvho07b: filas repetidas por quintil y a\u00f1o", call. = FALSE)
  }
  readr::write_csv(datos, destino)
  destino
}

leer_eurostat_quintil <- function(ruta) {
  readr::read_csv(ruta, col_types = "cccidc", progress = FALSE)
}

# «La escalera» (plan §6.6): una sola lista ordenada del último año con regiones NUTS 2,
# países sin regiones (o con solo NUTS 1, el nivel más fino que haya), la UE-27 y España.
# Las comunidades llevan su puesto en la lista completa.
armar_escalera <- function(europa, anio = NULL) {
  reg <- filter(europa, conjunto == "ilc_lvho07_r")
  if (is.null(anio)) anio <- max(reg$anio)
  reg <- filter(reg, anio == !!anio)
  nivel <- function(g) nchar(g) - 2L
  # Para cada país, su nivel más fino publicado (los códigos agrupados, como FI19_20, quedan fuera)
  fino <- reg |> mutate(pais = substr(geo, 1, 2), nivel = nivel(geo)) |>
    filter(nivel <= 2) |>
    group_by(pais) |> filter(nivel == max(nivel)) |> ungroup()
  referencias <- filter(europa, conjunto == "ilc_lvho07a", edad == "TOTAL", anio == !!anio,
                        geo %in% c("EU27_2020", "ES"))
  bind_rows(
    fino |> transmute(geo, nivel, valor, bloque = if_else(pais == "ES", "comunidad", "europa")),
    referencias |> transmute(geo, nivel = NA_integer_, valor, bloque = "referencia")
  ) |>
    arrange(desc(valor)) |>
    mutate(puesto = row_number(), anio = anio, .before = 1)
}
