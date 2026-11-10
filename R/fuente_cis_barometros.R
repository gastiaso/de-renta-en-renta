# CIS, barómetros mensuales (F6, plan §7: «enlace con barómetros»): la vivienda entre los tres
# principales problemas de España y entre los tres que más afectan personalmente, en % de
# entrevistados. Es la columna TOTAL de dos preguntas multirrespuesta de respuesta espontánea:
#   «¿Cuál es, a su juicio, el principal problema que existe actualmente en España? ¿Y el segundo?
#   ¿Y el tercero?» y «¿Y cuál es el problema que a Ud., personalmente, le afecta más? ¿Y el
#   segundo? ¿Y el tercero?». TOTAL = primero + segundo + tercero (nadie cita dos veces lo mismo).
# Serie nacional y mensual (no hay barómetro en agosto). Cada mes, el estudio de su número.
#
# Acceso abierto y sin registro (comprobado el 10-nov-2026): la página de cada barómetro,
# https://www.cis.es/es/estudios/barometro-de-<mes>-<año>, declara sus documentos en JSON-LD
# (schema.org/Dataset, licencia CC BY 4.0). Se guarda ese bloque y se toma, por este orden:
#   1. las tabulaciones en XLSX («Resultados y cruces verticales», hoja «Resultados»; desde
#      febrero de 2025), con toda la precisión;
#   2. los resultados en HTML (marginales con un decimal; de enero de 2014 a enero de 2025; antes,
#      solo algún mes suelto de 2009, 2011 y 2013, por eso la serie empieza en 2014: CIS_DESDE).
# Los meses que solo publican el PDF de resultados quedan como hueco (sin lector de PDF en el
# proyecto) y salen en la alerta cis_vivienda_cobertura.
# No se usan: el catálogo de series del CIS (protegido frente a accesos automatizados), los datos
# de sus fichas de serie (se sirven por /ws/, que robots.txt excluye) ni los microdatos, que piden
# un formulario con correo y la aceptación de condiciones (con ellos saldría el dato por comunidad).
# Condiciones de reutilización: inventario/fuentes.csv (cis_barometros).
# No entra en la tabla larga por sección: tabla propia (cis_vivienda) y JSON para la web.

CIS_MESES <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
               "septiembre", "octubre", "noviembre", "diciembre")
CIS_DIR <- file.path("datos", "brutos", "cis_barometros")
CIS_WEB <- "https://www.cis.es"

# Cifras publicadas por el CIS en sus notas de prensa (compuerta cis_vivienda_publicada). Julio de
# 2026 sale de la nota de septiembre: «37,5 %, 5,5 puntos menos que el mes anterior» (no hay
# barómetro en agosto).
CIS_REFERENCIAS <- tibble::tribble(
  ~anio, ~mes, ~pregunta,  ~referencia, ~detalle,
  2026L, 1L,   "espana",   42.6,        "nota del CIS de 28-1-2026 (bar\u00f3metro de enero)",
  2026L, 1L,   "personal", 28.2,        "nota del CIS de 28-1-2026 (bar\u00f3metro de enero)",
  2026L, 9L,   "espana",   37.5,        "nota del CIS de 14-9-2026 (bar\u00f3metro de septiembre)",
  2026L, 9L,   "personal", 27.9,        "nota del CIS de 14-9-2026 (bar\u00f3metro de septiembre)",
  2026L, 7L,   "espana",   43.0,        "nota del CIS de 14-9-2026: 37,5 + 5,5 puntos (julio)"
)

cis_url_estudio <- function(anio, mes) {
  sprintf("%s/es/estudios/barometro-de-%s-%d", CIS_WEB, CIS_MESES[mes], as.integer(anio))
}

# Peticion HTTP sin error por estado (se decide fuera), con la identificacion del proyecto.
cis_peticion <- function(url, ruta = NULL) {
  httr2::request(url) |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3, retry_on_failure = TRUE) |>
    httr2::req_timeout(120) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform(path = ruta)
}

# La pagina con la que el CIS frena los accesos automatizados: no se sortea.
cis_comprobacion_acceso <- function(texto) {
  grepl("Comprobaci\u00f3n de acceso", texto, fixed = TRUE) ||
    grepl("protege este portal frente a accesos automatizados", texto, fixed = TRUE)
}

# Bloque JSON-LD con el Dataset del estudio (texto), o NULL.
cis_json_ld <- function(html) {
  bloques <- regmatches(html, gregexpr("(?s)<script type=\"application/ld\\+json\"[^>]*>.*?</script>", html, perl = TRUE))[[1]]
  bloques <- sub("^<script[^>]*>", "", sub("</script>$", "", bloques))
  bloques <- bloques[grepl("\"Dataset\"", bloques, fixed = TRUE) & grepl("\"distribution\"", bloques, fixed = TRUE)]
  if (length(bloques) == 0) return(NULL)
  bloques[1]
}

# Pagina de un barometro: guarda su JSON-LD en datos/brutos/cis_barometros/estudios/AAAA-MM.json y
# devuelve la ruta, o NA si ese mes no tiene barometro. Un mes sin barometro se recuerda
# (AAAA-MM.sin_estudio) solo cuando han pasado mas de 120 dias: los recientes se vuelven a mirar.
cis_descargar_estudio <- function(anio, mes, dir = CIS_DIR, hoy = Sys.Date(), pausa = 2) {
  base <- file.path(dir, "estudios", sprintf("%d-%02d", as.integer(anio), as.integer(mes)))
  json <- paste0(base, ".json")
  sin <- paste0(base, ".sin_estudio")
  if (file.exists(json)) return(json)
  if (file.exists(sin)) return(NA_character_)
  inicio <- as.Date(sprintf("%d-%02d-01", as.integer(anio), as.integer(mes)))
  if (inicio > hoy) return(NA_character_)
  dir.create(dirname(base), recursive = TRUE, showWarnings = FALSE)
  url <- cis_url_estudio(anio, mes)
  resp <- cis_peticion(url)
  Sys.sleep(pausa)
  estado <- httr2::resp_status(resp)
  if (estado == 404) {
    if (as.numeric(hoy - inicio) > 120) writeLines(format(hoy), sin)
    return(NA_character_)
  }
  if (estado != 200) {
    stop("CIS: la p\u00e1gina ", url, " responde ", estado, ". Vuelve a intentarlo m\u00e1s tarde.", call. = FALSE)
  }
  html <- httr2::resp_body_string(resp, encoding = "UTF-8")
  if (cis_comprobacion_acceso(html)) {
    stop("CIS: ", url, " devuelve la comprobaci\u00f3n frente a accesos automatizados; no se sortea. ",
         "Vuelve a intentarlo m\u00e1s tarde.", call. = FALSE)
  }
  ld <- cis_json_ld(html)
  if (is.null(ld)) {
    # pagina sin documentos: se trata como mes sin barometro
    if (as.numeric(hoy - inicio) > 120) writeLines(format(hoy), sin)
    return(NA_character_)
  }
  con <- file(json, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(ld)), con)
  json
}

# Todos los meses de `desde` (AAAA) a `hoy`: rutas de los JSON-LD guardados (para un objetivo
# de formato «file»). Solo pide a la web los meses que no están en la caché. Si la web del CIS no
# responde en un mes (le pasa de noche), se avisa y se sigue: ese mes falta en la serie y sale en la
# alerta cis_vivienda_meses hasta la siguiente pasada.
cis_descargar_estudios <- function(desde, hoy = Sys.Date(), dir = CIS_DIR, pausa = 2) {
  meses <- seq(as.Date(sprintf("%d-01-01", as.integer(desde))), hoy, by = "month")
  fallos <- character(0)
  rutas <- vapply(meses, function(m) {
    tryCatch(
      cis_descargar_estudio(as.integer(format(m, "%Y")), as.integer(format(m, "%m")), dir = dir, hoy = hoy, pausa = pausa),
      error = function(e) {
        fallos <<- c(fallos, paste0(format(m, "%Y-%m"), ": ", conditionMessage(e)))
        NA_character_
      })
  }, character(1))
  if (length(fallos) > 0) {
    warning("CIS: ", length(fallos), " meses sin respuesta (se reintentan en la siguiente pasada):\n  ",
            paste(utils::head(fallos, 10), collapse = "\n  "), call. = FALSE)
  }
  rutas[!is.na(rutas)]
}

# Documentos de un estudio desde su JSON-LD: una fila por documento.
cis_documentos <- function(ruta_json) {
  ld <- jsonlite::fromJSON(ruta_json, simplifyVector = FALSE)
  nodos <- if (!is.null(ld[["@graph"]])) ld[["@graph"]] else list(ld)
  ds <- Filter(function(x) identical(x[["@type"]], "Dataset"), nodos)
  if (length(ds) == 0) stop("CIS: ", ruta_json, " sin Dataset.", call. = FALSE)
  ds <- ds[[1]]
  dist <- ds[["distribution"]]
  mes <- sub("\\.json$", "", basename(ruta_json))
  tibble::tibble(
    anio = as.integer(substr(mes, 1, 4)), mes = as.integer(substr(mes, 6, 7)),
    estudio = as.character(ds[["identifier"]]),
    publicado = substr(as.character(ds[["datePublished"]] %||% NA_character_), 1, 10),
    licencia = as.character(ds[["license"]] %||% NA_character_),
    documento = vapply(dist, function(d) as.character(d[["name"]] %||% NA_character_), character(1)),
    url = vapply(dist, function(d) as.character(d[["contentUrl"]] %||% NA_character_), character(1))
  )
}

# Documento de resultados que se lee de un estudio: XLSX de tabulaciones o, si no, HTML. NULL si
# solo hay PDF (o nada).
cis_elegir_documento <- function(docs) {
  x <- docs[docs$documento %in% "Tabulaciones XLSX", ]
  if (nrow(x) > 0) return(list(formato = "xlsx", url = x$url[1]))
  x <- docs[docs$documento %in% "Resultados HTML", ]
  if (nrow(x) > 0) return(list(formato = "html", url = x$url[1]))
  NULL
}

# Enlace absoluto: «https://…» tal cual; «/documents/…», desde la raiz de la web; «3496-multi.xlsx»,
# en la carpeta de la pagina que lo enlaza (`base`).
cis_absoluta <- function(href, base = paste0(CIS_WEB, "/")) {
  href <- gsub("&amp;", "&", href, fixed = TRUE)
  carpeta <- sub("[^/]*$", "", base)
  ifelse(grepl("^https?://", href), sub("^(https?://[^/]+)//+", "\\1/", href),
         ifelse(grepl("^/", href), paste0(CIS_WEB, "/", sub("^/+", "", href)), paste0(carpeta, href)))
}

# Descarga con cache a `destino`; comprueba el estado, la pagina anti-robots y, en XLSX, que el
# fichero se abre como zip (las descargas pueden llegar cortadas sin error). `cierre`: etiqueta con
# la que debe acabar un HTML entero (las paginas de enlaces de las tabulaciones son un fragmento).
cis_descargar_documento <- function(url, destino, formato, pausa = 2, cierre = "</html>") {
  if (file.exists(destino)) return(destino)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  parcial <- paste0(destino, ".parcial")
  on.exit(unlink(parcial), add = TRUE)
  resp <- cis_peticion(url, ruta = parcial)
  Sys.sleep(pausa)
  if (httr2::resp_status(resp) != 200) {
    stop("CIS: ", url, " responde ", httr2::resp_status(resp), ".", call. = FALSE)
  }
  if (formato == "xlsx") {
    entero <- tryCatch(nrow(utils::unzip(parcial, list = TRUE)) > 0, error = function(e) FALSE, warning = function(w) FALSE)
    if (!entero) stop("CIS: ", url, " no es un XLSX completo (\u00bfdescarga cortada o p\u00e1gina de comprobaci\u00f3n?).", call. = FALSE)
  } else {
    texto <- readChar(parcial, file.size(parcial), useBytes = TRUE)
    if (cis_comprobacion_acceso(texto)) stop("CIS: ", url, " devuelve la comprobaci\u00f3n de acceso; no se sortea.", call. = FALSE)
    if (!grepl(cierre, texto, ignore.case = TRUE, fixed = FALSE, useBytes = TRUE)) {
      stop("CIS: ", url, " llega sin cierre ", cierre, " (\u00bfdescarga cortada?).", call. = FALSE)
    }
  }
  if (!file.rename(parcial, destino)) stop("CIS: no se puede mover la descarga a ", destino, call. = FALSE)
  destino
}

# Resultados de un estudio en datos/brutos/cis_barometros/resultados/: <estudio>.xlsx o
# <estudio>.html. Las tabulaciones se enlazan desde una página intermedia (se guarda también), igual
# que, en algún mes (diciembre de 2024), los resultados en HTML («visor?fichero=…», cuyo fichero
# está en /documents/d/guest/). Si las tabulaciones no se pueden bajar (en febrero, abril, mayo,
# junio y julio de 2025 el enlace del CIS da 404), se prueba con los resultados en HTML, si los hay.
cis_descargar_resultados <- function(docs, dir = CIS_DIR, pausa = 2) {
  doc <- cis_elegir_documento(docs)
  if (is.null(doc)) return(NA_character_)
  estudio <- docs$estudio[1]
  dir_res <- file.path(dir, "resultados")
  html <- docs[docs$documento %in% "Resultados HTML", ]
  bajar_html <- function(url) {
    destino <- file.path(dir_res, paste0(estudio, ".html"))
    if (!grepl("_enlace", url, fixed = TRUE)) return(cis_descargar_documento(url, destino, "html", pausa))
    if (file.exists(destino)) return(destino)
    enlace <- cis_descargar_documento(url, file.path(dir_res, paste0(estudio, "_html_enlace.html")), "html", pausa,
                                      cierre = "</table>")
    texto <- paste(readLines(enlace, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    fichero <- regmatches(texto, regexpr("visor\\?fichero=[^\"&]+", texto))
    if (length(fichero) == 0) stop("CIS: ", enlace, " sin enlace a los resultados.", call. = FALSE)
    # el primero es la muestra nacional (los siguientes, las muestras autonomicas)
    cis_descargar_documento(paste0(CIS_WEB, "/documents/d/guest/", sub("^visor\\?fichero=", "", fichero[1])),
                            destino, "html", pausa)
  }
  if (doc$formato == "html") return(bajar_html(doc$url))
  destino <- file.path(dir_res, paste0(estudio, ".xlsx"))
  if (file.exists(destino)) return(destino)
  tryCatch({
    enlace <- cis_descargar_documento(doc$url, file.path(dir_res, paste0(estudio, "_enlace.html")), "html", pausa,
                                      cierre = "</table>")
    texto <- paste(readLines(enlace, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    hrefs <- gsub("^href=\"|\"$", "", regmatches(texto, gregexpr("href=\"[^\"]+\"", texto))[[1]])
    # "Resultados y cruces verticales": <estudio>-multi.xlsx (o su URL corta, -multi-xlsx), sin
    # las variantes _fila (horizontales) ni _abs (valores absolutos)
    vertical <- hrefs[grepl("-multi(\\.xlsx|-xlsx)", hrefs) & !grepl("_fila|_abs", hrefs)]
    if (length(vertical) == 0) stop("CIS: ", enlace, " sin enlace a las tabulaciones verticales.", call. = FALSE)
    cis_descargar_documento(cis_absoluta(vertical[1], base = doc$url), destino, "xlsx", pausa)
  }, error = function(e) {
    if (nrow(html) == 0) stop(e)
    bajar_html(html$url[1])
  })
}

# «3,4» (HTML) o «3.4» (XLSX) a numero; «-» es cero; «(2.989)» es un recuento con punto de miles.
cis_numero <- function(x, formato) {
  x <- trimws(as.character(x))
  x[x %in% c("-", "\u2013")] <- "0"
  recuento <- grepl("^\\(.*\\)$", x)
  x <- gsub("[()]", "", x)
  if (formato == "html") {
    x <- gsub(".", "", x, fixed = TRUE)
    x <- sub(",", ".", x, fixed = TRUE)
  } else {
    x[recuento] <- gsub(".", "", x[recuento], fixed = TRUE)
  }
  suppressWarnings(as.numeric(x))
}

# Bloque de una pregunta -> primero, segundo, tercero, total (en %) y n de «La vivienda». Dos
# disposiciones: problemas en filas y cabecera «Primer problema»…«Total» (la habitual), o problemas
# en columnas y «Primer problema»…«Total» en la primera columna (septiembre de 2019, septiembre de
# 2025, octubre de 2026), que se traspone. Cabeceras con sufijo («Primer problema [recod.]», 2024).
cis_valores_bloque <- function(m, formato) {
  m <- as.matrix(m)
  m[is.na(m)] <- ""
  m[] <- trimws(gsub("[[:space:]\u00a0]+", " ", m))   # "Primer<salto>problema", "La<salto>vivienda" en el HTML
  primer <- matrix(grepl("^Primer problema", m, ignore.case = TRUE), nrow = nrow(m))
  if (!any(primer)) return(NULL)
  pos <- which(primer, arr.ind = TRUE)[1, ]
  if (pos[["col"]] == 1L) {
    filas <- seq_len(nrow(m))
    fin <- filas[filas > pos[["row"]] & grepl("^total", m[, 1], ignore.case = TRUE)]
    if (length(fin) == 0) return(NULL)
    m <- t(m[seq_len(fin[1]), , drop = FALSE])
    primer <- matrix(grepl("^Primer problema", m, ignore.case = TRUE), nrow = nrow(m))
    pos <- which(primer, arr.ind = TRUE)[1, ]
  }
  cab <- pos[["row"]]
  patrones <- c(primero = "^Primer problema", segundo = "^Segundo problema",
                tercero = "^Tercer problema", total = "^total")
  j <- vapply(patrones, function(p) {
    k <- which(grepl(p, m[cab, ], ignore.case = TRUE))
    if (length(k) == 0) NA_integer_ else k[1]
  }, integer(1))
  if (anyNA(j) || cab == nrow(m)) return(NULL)
  etiquetas <- m[, 1]
  filas <- seq(cab + 1, nrow(m))
  fin_n <- filas[etiquetas[filas] %in% c("(N)", "N")]
  fin <- if (length(fin_n) > 0) fin_n[1] else nrow(m)
  dentro <- seq(cab + 1, fin)
  i <- dentro[grepl("^(la )?vivienda$", etiquetas[dentro], ignore.case = TRUE)]
  valores <- if (length(i) == 0) rep(0, 4) else cis_numero(m[i[1], j], formato)
  n <- if (length(fin_n) > 0) cis_numero(m[fin, j[["total"]]], formato) else NA_real_
  tibble::tibble(primero = valores[1], segundo = valores[2], tercero = valores[3], total = valores[4],
                 n = n, categoria = length(i) > 0)
}

CIS_PREGUNTAS <- c(espana = "principal problema que existe actualmente en Espa",
                   personal = "personalmente, le afecta m")

# Tabulaciones XLSX (hoja «Resultados»): el texto de cada pregunta va en la primera columna, en
# la fila anterior a su bloque. Sin «(N)» en el bloque (disposición traspuesta), el de la muestra:
# el primero de la hoja.
cis_leer_xlsx <- function(ruta) {
  d <- suppressMessages(readxl::read_excel(ruta, sheet = "Resultados", col_names = FALSE, col_types = "text"))
  m <- as.matrix(d)
  m[is.na(m)] <- ""
  texto <- apply(m, 1, paste, collapse = " ")
  fila_n <- which(trimws(m[, 1]) == "(N)")
  n_muestra <- if (length(fila_n) > 0) cis_numero(m[fila_n[1], 2], "xlsx") else NA_real_
  filas <- lapply(names(CIS_PREGUNTAS), function(p) {
    k <- which(grepl(CIS_PREGUNTAS[[p]], texto, fixed = TRUE))
    if (length(k) == 0) return(NULL)
    fin <- min(nrow(m), k[1] + 150)
    v <- cis_valores_bloque(m[seq(k[1] + 1, fin), , drop = FALSE], "xlsx")
    if (is.null(v)) return(NULL)
    if (is.na(v$n)) v$n <- n_muestra
    dplyr::mutate(v, pregunta = p, .before = 1)
  })
  dplyr::bind_rows(filas)
}

# Resultados en HTML: cada pregunta es un parrafo («Pregunta N», enunciado) seguido de su tabla. El
# enunciado se busca en los tres parrafos anteriores a la tabla (en 2024 va en un parrafo anidado,
# que el lector cierra antes de tiempo).
cis_tabla_matriz <- function(tabla) {
  filas <- xml2::xml_find_all(tabla, ".//tr")
  celdas <- lapply(filas, function(f) xml2::xml_text(xml2::xml_find_all(f, "./td|./th")))
  ancho <- max(lengths(celdas), 1L)
  do.call(rbind, lapply(celdas, function(x) c(x, rep("", ancho - length(x)))))
}

cis_leer_html <- function(ruta) {
  doc <- xml2::read_html(ruta, encoding = "UTF-8")
  tablas <- xml2::xml_find_all(doc, "//table")
  previo <- vapply(tablas, function(t) {
    p <- xml2::xml_find_all(t, "preceding::p[position() <= 3]")
    gsub("\\s+", " ", paste(xml2::xml_text(p), collapse = " "))
  }, character(1))
  n_muestra <- NA_real_
  for (t in tablas) {
    mm <- cis_tabla_matriz(t)
    k <- which(trimws(mm[, 1]) == "(N)")
    if (length(k) > 0 && ncol(mm) >= 2) {
      n_muestra <- cis_numero(mm[k[1], 2], "html")
      break
    }
  }
  filas <- lapply(names(CIS_PREGUNTAS), function(p) {
    k <- which(grepl(CIS_PREGUNTAS[[p]], previo, fixed = TRUE))
    for (i in k) {
      v <- cis_valores_bloque(cis_tabla_matriz(tablas[[i]]), "html")
      if (!is.null(v)) {
        if (is.na(v$n)) v$n <- n_muestra
        return(dplyr::mutate(v, pregunta = p, .before = 1))
      }
    }
    NULL
  })
  dplyr::bind_rows(filas)
}

# Serie: una fila por barometro y pregunta, con su estudio, el formato leido y la fecha de
# publicacion. `rutas_json`: las del objetivo de los estudios.
cis_leer_barometros <- function(rutas_json, dir = CIS_DIR, pausa = 2) {
  filas <- lapply(rutas_json, function(r) {
    docs <- cis_documentos(r)
    base <- dplyr::distinct(docs, anio, mes, estudio, publicado, licencia)
    # si la descarga falla, el mes queda como hueco (alerta cis_vivienda_cobertura) y se reintenta
    ruta <- tryCatch(cis_descargar_resultados(docs, dir = dir, pausa = pausa), error = function(e) {
      warning("CIS, estudio ", base$estudio[1], ": ", conditionMessage(e), call. = FALSE)
      "fallo"
    })
    if (identical(ruta, "fallo")) return(dplyr::mutate(base, formato = "fallo", pregunta = NA_character_))
    if (is.na(ruta)) {
      return(dplyr::mutate(base, formato = "pdf", pregunta = NA_character_))
    }
    formato <- tools::file_ext(ruta)
    v <- if (formato == "xlsx") cis_leer_xlsx(ruta) else cis_leer_html(ruta)
    if (nrow(v) == 0) return(dplyr::mutate(base, formato = formato, pregunta = NA_character_))
    dplyr::bind_cols(base[rep(1, nrow(v)), ], tibble::tibble(formato = formato), v)
  })
  dplyr::bind_rows(filas) |>
    dplyr::arrange(anio, mes, pregunta)
}

# Tabla propia de la serie (una fila por mes y pregunta con dato): valores con la precisión de la
# fuente (XLSX) o un decimal (HTML). Los meses en que la tabla no trae la categoría «La vivienda»
# (abril y mayo de 2020, en España) no van: falta la categoría, no es un cero medido.
cis_serie_vivienda <- function(barometros) {
  barometros |>
    dplyr::filter(!is.na(pregunta), categoria %in% TRUE) |>
    dplyr::transmute(periodo = sprintf("%d-%02d", anio, mes), anio, mes, estudio, pregunta,
                     total, primero, segundo, tercero, n, formato, publicado)
}

# Redondeo a un decimal de la guia (sprintf), con NA donde no hay cifra.
cis_un_decimal <- function(x) {
  y <- rep(NA_real_, length(x))
  y[!is.na(x)] <- as.numeric(sprintf("%.1f", x[!is.na(x)]))
  y
}

# Compuerta (inventario/referencias_validacion.csv):
#   cis_vivienda_publicada (bloqueo): total de España y personal frente a las notas del CIS
#     (CIS_REFERENCIAS), redondeado a un decimal; una nota cuyo mes falta en la serie pasa a la
#     alerta de cobertura con su cifra (bloqueo solo si no se puede contrastar ninguna);
#   cis_vivienda_suma (bloqueo): total menos primero + segundo + tercero (tres redondeos en el HTML);
#   cis_vivienda_rango (bloqueo): cifras fuera de 0-100, N por debajo de 1.000 o meses con las dos
#     preguntas incompletas (una sin la otra), y estudios repetidos;
#   cis_vivienda_categoria (alerta): barometros leidos sin la fila «La vivienda» (el mes no entra en la serie);
#   cis_vivienda_cobertura (alerta): barometros sin resultados en XLSX ni HTML (solo PDF), hueco;
#   cis_vivienda_meses (alerta): meses sin barómetro entre el primero y el último (salvo agosto).
cis_comprobar_vivienda <- function(barometros) {
  serie <- dplyr::filter(barometros, !is.na(pregunta))
  publicada <- CIS_REFERENCIAS |>
    dplyr::left_join(dplyr::select(serie, anio, mes, pregunta, total), by = c("anio", "mes", "pregunta")) |>
    dplyr::transmute(id = "cis_vivienda_publicada", anio,
                     detalle = sprintf("%d-%02d %s, %s", anio, mes, pregunta, detalle),
                     calculado = cis_un_decimal(total), referencia)
  # Una nota cuyo mes falta en la serie (sin resultados abiertos o con la descarga fallida) no se puede
  # contrastar: pasa a la alerta de cobertura con su cifra. Si no se puede contrastar ninguna, bloqueo.
  sin_contraste <- is.na(publicada$calculado)
  if (any(!sin_contraste)) {
    falta <- publicada[sin_contraste, ] |>
      dplyr::mutate(id = "cis_vivienda_cobertura", detalle = paste0(detalle, ": ", referencia, " % sin contrastar"),
                    calculado = 1, referencia = 0)
    publicada <- dplyr::bind_rows(publicada[!sin_contraste, ], falta)
  }
  fechas <- as.Date(sprintf("%d-%02d-01", barometros$anio, barometros$mes))
  todos <- seq(min(fechas), max(fechas), by = "month")
  todos <- todos[format(todos, "%m") != "08" & !todos %in% fechas]
  meses <- tibble::tibble(id = "cis_vivienda_meses", anio = as.integer(format(todos, "%Y")),
                          detalle = paste(format(todos, "%Y-%m"), "sin bar\u00f3metro encontrado"),
                          calculado = rep(1, length(todos)), referencia = 0)
  suma <- serie |>
    dplyr::group_by(formato) |>
    dplyr::summarise(calculado = if (dplyr::n() > 0) max(abs(total - (primero + segundo + tercero))) else 0,
                     .groups = "drop") |>
    dplyr::transmute(id = "cis_vivienda_suma", anio = NA_integer_, detalle = paste("formato", formato),
                     calculado, referencia = 0)
  por_mes <- dplyr::count(serie, anio, mes)
  rango <- tibble::tibble(
    id = "cis_vivienda_rango", anio = NA_integer_,
    detalle = c("cifras fuera de 0-100", "N menor de 1.000", "meses con una sola pregunta", "estudios repetidos"),
    calculado = c(sum(serie$total < 0 | serie$total > 100 | serie$primero < 0, na.rm = TRUE) + sum(is.na(serie$total)),
                  sum(is.na(serie$n) | serie$n < 1000),
                  sum(por_mes$n != 2),
                  sum(duplicated(dplyr::distinct(barometros, anio, mes, estudio)$estudio))),
    referencia = 0)
  categoria <- serie |>
    dplyr::filter(!categoria) |>
    dplyr::transmute(id = "cis_vivienda_categoria", anio, detalle = sprintf("%d-%02d %s (estudio %s)", anio, mes, pregunta, estudio),
                     calculado = 1, referencia = 0)
  huecos <- barometros |>
    dplyr::filter(is.na(pregunta)) |>
    dplyr::transmute(id = "cis_vivienda_cobertura", anio, detalle = sprintf("%d-%02d (estudio %s, %s)", anio, mes, estudio, formato),
                     calculado = 1, referencia = 0)
  dplyr::bind_rows(publicada, suma, rango, categoria, huecos, meses) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# JSON para la web (pagina del historico): datos/cis_vivienda.json, con la serie por pregunta,
# un decimal, el estudio y la fuente. Los meses sin dato abierto no van (la web corta la linea
# donde falta un mes).
cis_exportar_vivienda <- function(serie, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "cis_vivienda.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  pregunta <- function(p) {
    s <- dplyr::filter(serie, pregunta == p) |> dplyr::arrange(periodo)
    list(periodo = s$periodo, valor = as.numeric(sprintf("%.1f", s$total)), estudio = s$estudio,
         n = as.integer(round(s$n)))
  }
  x <- list(
    fuente = "CIS, bar\u00f3metros mensuales (resultados y tabulaciones de cada estudio)",
    licencia = "CC BY 4.0; reutilizaci\u00f3n citando al CIS (Ley 37/2007)",
    unidad = "% de entrevistados que cita la vivienda entre los tres principales problemas",
    nota = "Respuesta espont\u00e1nea, hasta tres problemas. Sin bar\u00f3metro en agosto; los meses con solo PDF de resultados no van.",
    actualizado = format(max(as.Date(serie$publicado), na.rm = TRUE)),
    series = list(espana = pregunta("espana"), personal = pregunta("personal"))
  )
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  ruta
}

# Ida y vuelta del JSON (cis_vivienda_web, bloqueo): cifras distintas de la serie redondeada, y
# estudios o entrevistas distintos de los de la tabla (la pagina del historico los ensena al pasar
# el raton; F6, 10-nov-2026). Periodos de mas o de menos, o listas de otra longitud: Inf.
cis_comprobar_web <- function(serie, ruta) {
  x <- jsonlite::read_json(ruta, simplifyVector = TRUE)
  distintos <- function(a, b) sum(xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b))
  dif <- vapply(c("espana", "personal"), function(p) {
    s <- dplyr::filter(serie, pregunta == p) |> dplyr::arrange(periodo)
    w <- x$series[[p]]
    if (length(w$periodo) != nrow(s) || !identical(as.character(w$periodo), s$periodo)) return(Inf)
    if (length(w$estudio) != nrow(s) || length(w$n) != nrow(s)) return(Inf)
    sum(abs(w$valor - as.numeric(sprintf("%.1f", s$total))) > 1e-9) +
      distintos(as.character(w$estudio), as.character(s$estudio)) +
      distintos(as.integer(w$n), as.integer(round(s$n)))
  }, numeric(1))
  tibble::tibble(id = "cis_vivienda_web", anio = NA_integer_, detalle = names(dif),
                 calculado = as.numeric(dif), referencia = 0)
}
