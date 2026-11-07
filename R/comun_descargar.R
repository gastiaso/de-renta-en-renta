# Descargas con caché en datos/brutos/ (guía de trabajo, «Convenciones técnicas»).
# Si el fichero ya está, no se vuelve a descargar salvo que se pida (`forzar`).
# Si la descarga falla y hay una versión anterior, se conserva y se avisa.

descargar_con_cache <- function(url, destino, forzar = FALSE) {
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  parcial <- paste0(destino, ".parcial")
  on.exit(unlink(parcial), add = TRUE)

  error <- tryCatch({
    httr2::request(url) |>
      httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_timeout(900) |>
      httr2::req_perform(path = parcial)
    NULL
  }, error = function(e) e)

  if (is.null(error)) {
    if (file.exists(destino)) unlink(destino)
    if (!file.rename(parcial, destino)) stop("No se ha podido mover la descarga a ", destino, call. = FALSE)
    return(destino)
  }
  if (file.exists(destino)) {
    warning("Falla la descarga de ", url, ": se conserva la versión anterior de ", destino,
            "\n  ", conditionMessage(error), call. = FALSE)
    return(destino)
  }
  stop("No se ha podido descargar ", url, "\n  ", conditionMessage(error),
       "\n  Descárgalo a mano y guárdalo como ", destino, call. = FALSE)
}
