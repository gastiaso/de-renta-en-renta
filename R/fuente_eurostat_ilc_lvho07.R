# Fuentes eurostat_ilc_lvho07 y eurostat_ilc_lvho07_r: tasa de sobrecarga por gastos de
# vivienda publicada por Eurostat. Referencia de la compuerta del indicador 22.
#   ilc_lvho07a: total (por edad, sexo y grupo de renta)
#   ilc_lvho07c: por tenencia
#   ilc_lvho07_r: regiones NUTS 2 (solo población total)
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
# edad (ilc_lvho07a: total y los grupos del atlas) y regiones (ilc_lvho07_r).
EDADES_ATLAS <- c("TOTAL", "Y_LT18", "Y18-64", "Y_GE65", "Y15-29")

descargar_eurostat_europa <- function(dir = file.path("datos", "brutos", "eurostat"), forzar = FALSE) {
  destino <- file.path(dir, "ilc_lvho07_europa.csv")
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  normalizar <- function(id) {
    d <- as.data.frame(eurostat::get_eurostat(id, time_format = "num", cache = FALSE))
    tiempo <- intersect(c("TIME_PERIOD", "time"), names(d))[1]
    if ("age" %in% names(d)) d <- d[d$age %in% EDADES_ATLAS, , drop = FALSE] else d$age <- "TOTAL"
    if ("sex" %in% names(d)) d <- d[d$sex == "T", , drop = FALSE]
    if ("rskpovth" %in% names(d)) d <- d[d$rskpovth == "TOTAL", , drop = FALSE]
    if ("unit" %in% names(d)) d <- d[d$unit == "PC", , drop = FALSE]
    tibble::tibble(
      conjunto = id, geo = as.character(d$geo),
      tenencia = if ("tenure" %in% names(d)) as.character(d$tenure) else "TOTAL",
      edad = as.character(d$age), anio = as.integer(d[[tiempo]]), valor = as.numeric(d$values),
      bandera = if ("flags" %in% names(d)) as.character(d$flags) else NA_character_
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
