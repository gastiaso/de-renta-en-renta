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
