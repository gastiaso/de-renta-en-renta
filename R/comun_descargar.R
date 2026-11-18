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

# Feeds ATOM (listas de enlaces de descarga; tarea 58), con caché como descargar_con_cache(): si el
# fichero ya está, no se pide; si la petición falla, se conserva el anterior y se avisa. Son pequeños:
# la respuesta se lee en memoria y se escribe tal cual (las pruebas la simulan con
# httr2::with_mocked_responses()). Una pausa antes de cada petición. Se renuevan cuando tienen más
# de `max_dias` días (DIAS_RENOVAR_FEEDS, decisión del autor del 18-nov-2026: así entran municipios y
# zips nuevos sin borrar la carpeta); en el pipeline, `tar_cue_age()` vuelve a lanzar sus objetivos a
# los mismos días. Si el feed renovado es idéntico, no se rehace nada del Catastro.
DIAS_RENOVAR_FEEDS <- 90

feed_caducado <- function(destino, max_dias = DIAS_RENOVAR_FEEDS) {
  edad <- difftime(Sys.time(), file.mtime(destino), units = "days")
  !is.na(edad) && as.numeric(edad) > max_dias
}

descargar_feed <- function(url, destino, forzar = FALSE, pausa = 0.3, max_dias = DIAS_RENOVAR_FEEDS) {
  if (file.exists(destino) && !forzar && !feed_caducado(destino, max_dias)) return(destino)
  Sys.sleep(pausa)
  cuerpo <- tryCatch(
    httr2::request(url) |>
      httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_timeout(300) |>
      httr2::req_perform() |>
      httr2::resp_body_raw(),
    error = function(e) e)
  if (inherits(cuerpo, "error")) {
    if (file.exists(destino)) {
      warning("Falla la descarga de ", url, ": se conserva la versión anterior de ", destino,
              "\n  ", conditionMessage(cuerpo), call. = FALSE)
      return(destino)
    }
    stop("No se ha podido descargar ", url, "\n  ", conditionMessage(cuerpo),
         "\n  Descárgalo a mano y guárdalo como ", destino, call. = FALSE)
  }
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  parcial <- paste0(destino, ".parcial")
  on.exit(unlink(parcial), add = TRUE)
  writeBin(cuerpo, parcial)
  if (file.exists(destino)) unlink(destino)
  if (!file.rename(parcial, destino)) stop("No se ha podido mover la descarga a ", destino, call. = FALSE)
  destino
}
