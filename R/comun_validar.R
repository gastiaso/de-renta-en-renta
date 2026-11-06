# Compuerta de publicación (plan, §6.5): cada comprobación se compara con su referencia
# y su tolerancia de inventario/referencias_validacion.csv. Las de tipo «bloqueo» paran
# el pipeline; las de tipo «alerta» avisan.

# «±0,1 puntos» → 0.1; «±0,5 %» → 0.5; «exacto» → 0. Otras (p. ej. «a fijar») no son
# comparables de forma automática.
leer_tolerancia <- function(texto) {
  texto <- trimws(texto)
  valor <- rep(NA_real_, length(texto))
  valor[texto == "exacto"] <- 0
  numerica <- grepl("^\u00b1\\s*[0-9]+([,.][0-9]+)?", texto)
  valor[numerica] <- as.numeric(sub(",", ".", sub("^\u00b1\\s*([0-9]+([,.][0-9]+)?).*$", "\\1",
                                                   texto[numerica])))
  valor
}

# `comprobaciones`: una fila por cifra, con `id` (el de referencias_validacion.csv),
# `detalle` (p. ej. la región), `calculado` y `referencia`.
validar_referencias <- function(comprobaciones, referencias) {
  tabla <- comprobaciones |>
    left_join(select(referencias, id, tolerancia, tipo), by = "id")
  sin_fila <- unique(tabla$id[is.na(tabla$tipo)])
  if (length(sin_fila) > 0) {
    stop("Comprobaciones sin fila en referencias_validacion.csv: ",
         paste(sin_fila, collapse = ", "), call. = FALSE)
  }
  tabla <- tabla |>
    mutate(
      tolerancia_num = leer_tolerancia(tolerancia),
      diferencia     = calculado - referencia,
      correcto       = !is.na(diferencia) & abs(diferencia) <= tolerancia_num + 1e-9
    )
  no_comparables <- unique(tabla$id[is.na(tabla$tolerancia_num)])
  if (length(no_comparables) > 0) {
    stop("Tolerancia no numérica en: ", paste(no_comparables, collapse = ", "), call. = FALSE)
  }

  fallos <- filter(tabla, !correcto)
  resumen <- function(f, maximo = 15) {
    anio <- if ("anio" %in% names(f)) paste0(" ", f$anio) else ""
    lineas <- paste0("  ", f$id, anio, " ", f$detalle, ": calculado ", format(f$calculado, digits = 4),
                     ", referencia ", f$referencia)
    if (length(lineas) > maximo) lineas <- c(utils::head(lineas, maximo), paste0("  … y ", length(lineas) - maximo, " más"))
    paste(lineas, collapse = "\n")
  }
  alertas <- filter(fallos, tipo == "alerta")
  if (nrow(alertas) > 0) warning("Alertas de validación:\n", resumen(alertas), call. = FALSE)
  bloqueos <- filter(fallos, tipo == "bloqueo")
  if (nrow(bloqueos) > 0) stop("La compuerta no pasa:\n", resumen(bloqueos), call. = FALSE)
  tabla
}
