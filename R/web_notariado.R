# Web de la capa del Notariado (R/fuente_notariado.R; docs/especificacion_notariado.md). Solo web y
# con licencia propia no comercial (decisiones del autor del 19-nov-2026): carpeta propia,
# web/datos/notariado/, aparte de la exportación general (web/datos/manifiesto.json), de la tabla
# larga y del paquete del release (empaquetar_publicacion() la deja fuera y lo comprueba:
# sin_notariado). Tampoco va en git (decisión del autor del 21-nov-2026): empaquetar_notariado()
# (R/publicar.R) la empaqueta, después de pasar sus compuertas, para el release en borrador
# «notariado», y el flujo de Pages la baja de ahí al montar el sitio (docs/publicacion.md, «Capa del
# Notariado»).
# La web suma sus series y mapas a los del manifiesto general al cargarlo (web/js/datos.js,
# unirCapas()), y cada cifra lleva la etiqueta de su fuente (vocabulario.etiqueta.notariado y
# .notariado_cien): «© Consejo General del Notariado · solo uso no comercial», sin descarga en CSV.
#
#   datos/notariado/manifiesto.json: {capa: "notariado", activa, version, generado, licencia, foto,
#     cien_ultimo_mes, indicadores, mapas}. Las entradas de `indicadores` y `mapas` tienen el formato
#     del manifiesto general (web/LEEME.md); las series de penotariado llevan además `foto` (fecha de
#     la foto de 12 meses: la ficha la cita) y `minimo_informadas` (20). Apagada (NOTARIADO=FALSE),
#     solo {"capa": "notariado", "activa": false} (notariado_apagar_web());
#   datos/notariado/<nivel>/<serie>/<año>.json: valores con el índice general del nivel ({v, e}).
DIR_WEB_NOTARIADO <- file.path("datos", "notariado")
LICENCIA_NOTARIADO <- "© Consejo General del Notariado, solo uso no comercial"
FUENTES_NOTARIADO <- c("notariado", "notariado_cien")

# Exportación de la capa encendida. `larga`: armonizar_penotariado() y armonizar_notariado_cien()
# juntas; `foto`: la fecha de la foto de penotariado; `ultimo_mes`: el del CIEN. Borra antes lo
# exportado la vez anterior.
notariado_exportar_web <- function(larga, indicadores, jerarquia, territorios, vocabulario = NULL, foto = NA,
                                   ultimo_mes = NA_character_, dir_web = "web", fecha = format(Sys.Date())) {
  dir <- file.path(dir_web, DIR_WEB_NOTARIADO)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  catalogo <- catalogo_web(series)
  catalogo$ruta <- ruta_web(catalogo$clave, catalogo$corte, prefijo = DIR_WEB_NOTARIADO)
  valores <- escribir_valores_web(series, catalogo, indices, dir_web)
  entradas <- indicadores_manifiesto_web(catalogo, indicadores)
  for (cl in names(entradas)) {
    if (identical(entradas[[cl]]$fuente, "notariado")) {
      entradas[[cl]] <- c(entradas[[cl]], list(foto = format(as.Date(foto)), minimo_informadas = NOTARIADO_MIN_INFORMADAS))
    }
  }
  manifiesto <- list(capa = "notariado", activa = TRUE, version = if (nrow(catalogo)) max(catalogo$version) else fecha,
                     generado = fecha, licencia = LICENCIA_NOTARIADO, foto = format(as.Date(foto)),
                     cien_ultimo_mes = ultimo_mes,
                     indicadores = if (length(entradas)) entradas else structure(list(), names = character()),
                     mapas = mapas_web(catalogo, indicadores, vocabulario))
  if (!length(manifiesto$mapas)) manifiesto$mapas <- structure(list(), names = character())
  ruta <- file.path(dir, "manifiesto.json")
  jsonlite::write_json(manifiesto, ruta, auto_unbox = TRUE, digits = NA, na = "null", pretty = TRUE)
  c(ruta, valores)
}

# Capa apagada: borra la exportación anterior y deja solo el manifiesto vacío.
notariado_apagar_web <- function(dir_web = "web") {
  dir <- file.path(dir_web, DIR_WEB_NOTARIADO)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ruta <- file.path(dir, "manifiesto.json")
  writeLines('{"capa":"notariado","activa":false}', ruta, useBytes = TRUE)
  ruta
}

# Compuerta web_notariado (bloqueo): lo escrito en web/datos/notariado/ reproduce la capa.
#   valores: por fichero, territorios cuyo valor (÷ escala, con el redondeo de la guía) o estado no
#     es el de la capa (longitud distinta del índice: todos);
#   series de la capa sin fichero, y filas sin hueco en el índice de su nivel;
#   manifiesto: capa encendida, con la licencia; cada serie, de una fuente del Notariado;
#   ficheros de la carpeta que el manifiesto no cita (restos de otra exportación);
#   manifiesto general: series del Notariado en web/datos/manifiesto.json (deben ir aparte).
notariado_comprobar_web <- function(larga, indicadores, jerarquia, territorios, dir_web = "web") {
  fila <- function(detalle, calculado) tibble::tibble(id = "web_notariado", detalle = detalle, calculado = as.numeric(calculado))
  dir <- file.path(dir_web, DIR_WEB_NOTARIADO)
  m <- jsonlite::fromJSON(file.path(dir, "manifiesto.json"), simplifyVector = FALSE)
  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  series$redondeado <- redondeo_guia(series$valor, decimales_escala(series$escala))
  filas <- list(fila("capa encendida en el manifiesto", !isTRUE(m$activa)),
                fila("licencia en el manifiesto", !identical(m$licencia, LICENCIA_NOTARIADO)),
                fila("series de una fuente que no es del Notariado",
                     sum(!vapply(m$indicadores, function(d) isTRUE(d$fuente %in% FUENTES_NOTARIADO), TRUE))))
  citados <- "manifiesto.json"
  for (clave in names(m$indicadores)) {
    def <- m$indicadores[[clave]]
    escala <- as.numeric(def$escala %||% ESCALA_WEB)
    d_c <- series[series$clave == clave, ]
    for (nivel in unlist(def$niveles)) {
      d_n <- d_c[d_c$nivel == nivel, ]
      n_ind <- length(indices[[nivel]])
      for (p in as.character(unlist(def$anios))) {
        ruta <- ruta_valores(def$ruta, nivel, p)
        citados <- c(citados, sub(paste0("^", DIR_WEB_NOTARIADO, "/"), "", ruta))
        leido <- leer_valores_web(file.path(dir_web, ruta), escala)
        d <- d_n[d_n$periodo == p, ]
        i <- match(indices[[nivel]], d$geo_id)
        esp_v <- d$redondeado[i]
        esp_e <- ifelse(is.na(i), "ausente", d$estado[i])
        mal <- if (length(leido$valores) != n_ind || length(leido$estados) != n_ind) n_ind else
          sum(is.na(leido$estados) | leido$estados != esp_e | xor(is.na(leido$valores), is.na(esp_v)) |
                (!is.na(esp_v) & !is.na(leido$valores) & abs(esp_v - leido$valores) > 1e-9))
        filas[[length(filas) + 1L]] <- fila(ruta, mal)
      }
    }
  }
  en_manifiesto <- unlist(lapply(names(m$indicadores), function(cl) {
    def <- m$indicadores[[cl]]
    as.vector(outer(paste(cl, unlist(def$niveles)), as.character(unlist(def$anios)), paste))
  }))
  filas[[length(filas) + 1L]] <- fila("series de la capa sin fichero",
                                      length(setdiff(unique(paste(series$clave, series$nivel, series$periodo)), en_manifiesto)))
  fuera <- vapply(names(indices), function(n) sum(!series$geo_id[series$nivel == n] %in% indices[[n]]), numeric(1))
  filas[[length(filas) + 1L]] <- fila("filas sin hueco en el indice de su nivel", sum(fuera))
  presentes <- list.files(dir, recursive = TRUE)
  filas[[length(filas) + 1L]] <- fila("ficheros de la carpeta que el manifiesto no cita", length(setdiff(presentes, citados)))
  general <- file.path(dir_web, "datos", "manifiesto.json")
  en_general <- if (file.exists(general)) {
    g <- jsonlite::fromJSON(general, simplifyVector = FALSE)
    sum(vapply(g$indicadores, function(d) isTRUE(d$fuente %in% FUENTES_NOTARIADO), TRUE))
  } else 0
  filas[[length(filas) + 1L]] <- fila("series del Notariado en el manifiesto general", en_general)
  dplyr::bind_rows(filas) |> dplyr::mutate(referencia = 0)
}
