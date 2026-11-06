# Exportación de resultados que se publican o se versionan.

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
