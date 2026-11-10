# Web de la capa de portales (indicador 13; R/fuente_portales.R). Solo web (backlog, decisión 3):
# carpeta propia, web/datos/portales/, aparte de la exportación general (web/datos/manifiesto.json,
# R/web_exportar.R), de la tabla larga, del paquete del release (empaquetar_publicacion() la deja
# fuera) y de git. La web suma sus series y mapas a los del manifiesto general al cargarlo
# (web/js/datos.js, unirCapas()), así que encender o apagar la capa no toca la exportación general.
#
#   datos/portales/manifiesto.json: {capa: "portales", activa, version, generado, indicadores,
#     mapas}. Las entradas de `indicadores` y `mapas` tienen el formato del manifiesto general
#     (web/LEEME.md) y, en cada serie, además: `ultimo_mes` («AAAA-MM»: hasta dónde llega el último
#     año), `meses_minimos` (9), `enlaces` y `zonas` (rutas). Apagada (PORTALES distinto de TRUE),
#     solo {"capa": "portales", "activa": false} (portales_apagar_web()): la web no pide nada más;
#   datos/portales/<nivel>/<serie>/<año>.json: valores con el índice general del nivel ({v, e}, como
#     los de la exportación general), en los niveles nacional, ccaa, provincia y municipio;
#   datos/portales/enlaces/<serie>.json: {nivel: {código: url}}, el informe de cada cifra;
#   datos/portales/zonas/<serie>.json: {anios, escala, municipios: {municipio: [{zona, nombre, tipo,
#     url, v, e}]}}: las zonas del portal y las localidades con su municipio, sin geometría (la
#     ficha del municipio las listará: tarea 38).
DIR_WEB_PORTALES <- file.path("datos", "portales")

# Exportación de la capa encendida. `larga`: armonizar_portales(); `anual`: anualizar_portales();
# `portales`: la capa mensual (para el último mes). Borra antes lo exportado la vez anterior.
portales_exportar_web <- function(larga, anual, portales, indicadores, jerarquia, territorios, vocabulario = NULL,
                                  dir_web = "web", fecha = format(Sys.Date())) {
  dir <- file.path(dir_web, DIR_WEB_PORTALES)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  catalogo <- catalogo_web(series)
  catalogo$ruta <- ruta_web(catalogo$clave, catalogo$corte, prefijo = DIR_WEB_PORTALES)
  valores <- escribir_valores_web(series, catalogo, indices, dir_web)

  escribir <- function(x, ruta, pretty = FALSE) {
    dir.create(dirname(file.path(dir_web, ruta)), recursive = TRUE, showWarnings = FALSE)
    jsonlite::write_json(x, file.path(dir_web, ruta), auto_unbox = TRUE, digits = NA, na = "null", pretty = pretty)
    file.path(dir_web, ruta)
  }
  entradas <- indicadores_manifiesto_web(catalogo, indicadores)
  ultimo <- portales_ultimo_mes(portales)
  zonas <- portales_zonas(anual)
  extra <- character()
  for (k in seq_len(nrow(catalogo))) {
    cl <- catalogo$clave[k]
    grupo <- catalogo$grupo_web[k]
    ruta_enlaces <- file.path(DIR_WEB_PORTALES, "enlaces", paste0(cl, ".json"))
    ruta_zonas <- file.path(DIR_WEB_PORTALES, "zonas", paste0(cl, ".json"))
    extra <- c(extra, escribir(portales_enlaces_web(anual, grupo, catalogo$niveles[[k]]), ruta_enlaces),
               escribir(portales_zonas_web(zonas[zonas$grupo == grupo, ], as.integer(catalogo$periodos[[k]]), catalogo$escala[k]),
                        ruta_zonas))
    entradas[[cl]] <- c(entradas[[cl]], list(ultimo_mes = ultimo[[grupo]] %||% NA_character_, meses_minimos = PORTALES_MESES_MINIMOS,
                                             enlaces = ruta_enlaces, zonas = ruta_zonas))
  }
  manifiesto <- list(capa = "portales", activa = TRUE,
                     version = if (nrow(catalogo)) max(catalogo$version) else fecha, generado = fecha,
                     indicadores = if (length(entradas)) entradas else structure(list(), names = character()),
                     mapas = mapas_web(catalogo, indicadores, vocabulario))
  if (!length(manifiesto$mapas)) manifiesto$mapas <- structure(list(), names = character())
  c(escribir(manifiesto, file.path(DIR_WEB_PORTALES, "manifiesto.json"), pretty = TRUE), valores, extra)
}

# Capa apagada: borra la exportación anterior y deja solo el manifiesto vacío, para que la web sepa
# que no hay capa sin pedir nada más (y sin un 404 en la consola).
portales_apagar_web <- function(dir_web = "web") {
  dir <- file.path(dir_web, DIR_WEB_PORTALES)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ruta <- file.path(dir, "manifiesto.json")
  writeLines('{"capa":"portales","activa":false}', ruta, useBytes = TRUE)
  ruta
}

# Enlaces de una serie: {nivel: {código: url}}, el informe de cada territorio con alguna cifra.
portales_enlaces_web <- function(anual, grupo, niveles) {
  a <- anual[paste(anual$operacion, anual$portal, sep = "_") == grupo & anual$nivel %in% niveles &
               !is.na(anual$url), ]
  a <- a[!duplicated(a[c("nivel", "geo_id")]), ]
  out <- lapply(niveles, function(n) {
    x <- a[a$nivel == n, ]
    stats::setNames(as.list(x$url), x$geo_id)
  })
  stats::setNames(out, niveles)
}

# Zonas de una serie por municipio, con los años de la serie: valores × escala (enteros o null) y una
# cifra de estado por año, como los ficheros de valores. Solo las zonas con algún dato en esos años.
portales_zonas_web <- function(zonas, anios, escala = ESCALA_WEB) {
  z <- zonas[zonas$anio %in% anios, ]
  claves <- unique(z[c("geo_id", "nivel", "zona")])
  con_dato <- z |> dplyr::group_by(geo_id, nivel, zona) |> dplyr::summarise(n = sum(estado == "dato"), .groups = "drop")
  claves <- dplyr::semi_join(claves, con_dato[con_dato$n > 0, ], by = c("geo_id", "nivel", "zona"))
  claves <- claves[order(claves$geo_id, claves$nivel, claves$zona), ]
  municipios <- list()
  for (k in seq_len(nrow(claves))) {
    d <- z[z$geo_id == claves$geo_id[k] & z$nivel == claves$nivel[k] & z$zona == claves$zona[k], ]
    m <- match(anios, d$anio)
    entrada <- list(zona = claves$zona[k], nombre = d$nombre[1], tipo = claves$nivel[k], url = d$url[1],
                    v = I(valor_web(d$valor[m], escala)),
                    e = paste(estado_web(ifelse(is.na(m), "ausente", d$estado[m])), collapse = ""))
    municipios[[claves$geo_id[k]]] <- c(municipios[[claves$geo_id[k]]], list(entrada))
  }
  list(anios = I(anios), escala = escala,
       municipios = if (length(municipios)) municipios else structure(list(), names = character()))
}

# Compuerta web_portales (bloqueo): lo escrito en web/datos/portales/ reproduce la capa (ida y vuelta).
#   valores: por fichero, territorios cuyo valor (÷ escala) o estado no es el de la capa, con el
#     redondeo de la guía a los decimales de la escala (longitud distinta del índice: todos);
#     además, series de la capa sin fichero y filas sin hueco en el índice de su nivel;
#   enlaces: territorios con dato sin el enlace a su informe, o con un enlace que no es https;
#   zonas: cifras o estados de las zonas que no son los de la capa, y zonas de más o de menos;
#   manifiesto general: series de los portales en web/datos/manifiesto.json (deben ir aparte).
portales_comprobar_web <- function(larga, anual, indicadores, jerarquia, territorios, dir_web = "web") {
  fila <- function(detalle, calculado) tibble::tibble(id = "web_portales", detalle = detalle, calculado = as.numeric(calculado))
  dir <- file.path(dir_web, DIR_WEB_PORTALES)
  m <- jsonlite::fromJSON(file.path(dir, "manifiesto.json"), simplifyVector = FALSE)
  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  series$redondeado <- redondeo_guia(series$valor, decimales_escala(series$escala))
  filas <- list(fila("capa encendida en el manifiesto", !isTRUE(m$activa)))
  zonas <- portales_zonas(anual)
  for (clave in names(m$indicadores)) {
    def <- m$indicadores[[clave]]
    escala <- as.numeric(def$escala %||% ESCALA_WEB)
    d_c <- series[series$clave == clave, ]
    for (nivel in unlist(def$niveles)) {
      d_n <- d_c[d_c$nivel == nivel, ]
      n_ind <- length(indices[[nivel]])
      for (p in as.character(unlist(def$anios))) {
        ruta <- ruta_valores(def$ruta, nivel, p)
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
    # Enlaces: cada territorio con dato, con el suyo
    enlaces <- jsonlite::fromJSON(file.path(dir_web, def$enlaces), simplifyVector = FALSE)
    con_dato <- unique(d_c[d_c$estado == "dato", c("nivel", "geo_id")])
    url <- vapply(seq_len(nrow(con_dato)), function(k) as.character(enlaces[[con_dato$nivel[k]]][[con_dato$geo_id[k]]] %||% NA), "")
    filas[[length(filas) + 1L]] <- fila(paste(def$enlaces, "(territorios con dato sin enlace https)"),
                                        sum(is.na(url) | !grepl("^https://", url)))
    # Zonas: ida y vuelta con la capa
    leido <- jsonlite::fromJSON(file.path(dir_web, def$zonas), simplifyVector = FALSE)
    esperado <- portales_zonas_web(zonas[zonas$grupo == def$grupo, ], as.integer(unlist(def$anios)), escala)
    plano <- function(x) unlist(lapply(names(x$municipios), function(mun) vapply(x$municipios[[mun]], function(z) {
      v <- vapply(z$v, function(y) if (is.null(y)) "null" else format(y, scientific = FALSE), "")
      paste(mun, z$tipo, z$zona, z$url, paste(v, collapse = ","), z$e)
    }, "")))
    a <- plano(leido)
    b <- plano(jsonlite::fromJSON(jsonlite::toJSON(esperado, auto_unbox = TRUE, na = "null", digits = NA), simplifyVector = FALSE))
    filas[[length(filas) + 1L]] <- fila(paste(def$zonas, "(zonas distintas de la capa)"), length(union(setdiff(a, b), setdiff(b, a))))
  }
  en_manifiesto <- unlist(lapply(names(m$indicadores), function(cl) {
    def <- m$indicadores[[cl]]
    as.vector(outer(paste(cl, unlist(def$niveles)), as.character(unlist(def$anios)), paste))
  }))
  filas[[length(filas) + 1L]] <- fila("series de la capa sin fichero",
                                      length(setdiff(unique(paste(series$clave, series$nivel, series$periodo)), en_manifiesto)))
  fuera <- vapply(names(indices), function(n) sum(!series$geo_id[series$nivel == n] %in% indices[[n]]), numeric(1))
  filas[[length(filas) + 1L]] <- fila("filas sin hueco en el indice de su nivel", sum(fuera))
  general <- file.path(dir_web, "datos", "manifiesto.json")
  en_general <- if (file.exists(general)) {
    g <- jsonlite::fromJSON(general, simplifyVector = FALSE)
    sum(vapply(g$indicadores, function(d) identical(d$fuente, "portales") || identical(d$corte, CORTE_PORTALES), TRUE))
  } else 0
  filas[[length(filas) + 1L]] <- fila("series de los portales en el manifiesto general", en_general)
  dplyr::bind_rows(filas) |> dplyr::mutate(referencia = 0)
}
