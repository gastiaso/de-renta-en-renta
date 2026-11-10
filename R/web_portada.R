# Portada de la web (web/index.html; docs/especificacion_portada.md; backlog, tarea 24).
#
#   leer_casillas_portada()                  -> inventario/casillas_portada.csv (regla 7)
#   escribir_casillas_portada(casillas)      -> la lista de casillas de web/index.html, entre sus
#                                               marcas: el tablero se ve sin JavaScript
#   exportar_portada(larga, perfiles)        -> web/datos/portada.json, las cifras de las cartas
#   comprobar_portada(larga, perfiles, ...)  -> compuertas portada_valores (cada cifra de
#                                               portada.json, recalculada por otro camino) y
#                                               portada_casillas (validez del CSV)
#
# Las cartas solo llevan cifras reales del pipeline:
#   - sueldo: sueldo necesario (21) de las secciones con dato del último año: percentiles 10, 50 y
#     90 (quantile() de R, tipo 7), con la superficie y el umbral del mapa por defecto;
#   - smi: peso del alquiler en el ingreso (15) de la tartera en las secciones con dato del último año que la
#     tiene: porcentaje de secciones donde el alquiler de 50 m2 pasa del 30 y del 40 % del SMI neto;
#   - sobrecarga: tasa de sobrecarga (22) de España del último año de la ECV, total y de quienes
#     viven de alquiler a precio de mercado.
# La compuerta recalcula la primera y la segunda desde el alquiler por m2 (9) y el ingreso de la
# tartera que recibe la web (perfiles_web()), como lo haría el navegador; la tercera, desde las
# filas de la sobrecarga. Redondeo de la guía (redondeo_guia()) a un decimal.
# Los textos llevan escapes \u: los caracteres no ASCII en el cuerpo de las funciones rompen targets.

RUTA_CASILLAS_PORTADA <- file.path("inventario", "casillas_portada.csv")
FAMILIAS_PORTADA <- c("ingresos", "alquiler", "compra", "barrio")
ESQUINAS_PORTADA <- c(1L, 7L, 13L, 19L)   # tablero de 7 x 7: cuatro esquinas y cinco casillas por lado
MARCAS_CASILLAS <- c(inicio = "<!-- casillas:inicio (escribir_casillas_portada(), desde inventario/casillas_portada.csv; no editar a mano) -->",
                     fin = "<!-- casillas:fin -->")
FICHERO_PORTADA_WEB <- "portada.json"   # bajo <dir_web>/datos/

leer_casillas_portada <- function(ruta = RUTA_CASILLAS_PORTADA) {
  readr::read_csv(ruta, col_types = readr::cols(orden = "i", activa = "l", .default = "c"), na = character()) |>
    mutate(across(c(destino, destino_en), function(x) dplyr::coalesce(x, "")))
}

# --- Destinos ----------------------------------------------------------------------------------

# Destino en ingles de una casilla: el de la columna destino_en o, si va vacia, el mismo con el
# idioma (mapa.html y sobrecarga.html, con idioma=en en la consulta; metodo.html y datos.html, sus
# paginas inglesas, sin ancla: las anclas cambian con el idioma y piden destino_en).
destino_ingles <- function(destino, destino_en = "") {
  vapply(seq_along(destino), function(i) {
    d <- destino[i]
    if (nzchar(destino_en[i])) return(destino_en[i])
    if (!nzchar(d)) return("")
    partes <- regmatches(d, regexec("^([^?#]*)(\\?[^#]*)?(#.*)?$", d))[[1]]
    pagina <- partes[2]; consulta <- partes[3]; ancla <- partes[4]
    if (pagina %in% c("mapa.html", "sobrecarga.html", "historico.html", "", "./", "index.html")) {   # F6, historico
      consulta <- if (nzchar(consulta)) paste0(consulta, "&idioma=en") else "?idioma=en"
      return(paste0(pagina, consulta, ancla))
    }
    paginas <- c(metodo.html = "method.html", datos.html = "data.html")
    if (pagina %in% names(paginas)) return(paste0(paginas[[pagina]], consulta, ancla))
    d
  }, "", USE.NAMES = FALSE)
}

# Partes de un destino: pagina, parametros de la consulta (lista con nombre) y ancla.
partes_destino <- function(destino) {
  partes <- regmatches(destino, regexec("^([^?#]*)(\\?[^#]*)?(#.*)?$", destino))[[1]]
  consulta <- sub("^\\?", "", partes[3])
  pares <- if (nzchar(consulta)) strsplit(strsplit(consulta, "&", fixed = TRUE)[[1]], "=", fixed = TRUE) else list()
  list(pagina = partes[2],
       parametros = stats::setNames(lapply(pares, function(p) if (length(p) > 1) p[2] else ""), vapply(pares, `[`, "", 1)),
       ancla = sub("^#", "", partes[4]))
}

# --- HTML de las casillas ----------------------------------------------------------------------

escapar_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

# Lineas de la lista ordenada de las casillas (dentro de web/index.html). Cada casilla lleva su
# familia (la banda de color, web/estilo/portada.css), sus textos en los dos idiomas (i18n.js los
# cambia con data-texto-es y data-texto-en) y, si esta activa, el enlace a su destino en cada
# idioma (data-href-es y data-href-en); si no, el aviso «proximamente», sin enlace.
html_casillas_portada <- function(casillas, sangria = "          ") {
  casillas <- casillas[order(casillas$orden), ]
  li <- vapply(seq_len(nrow(casillas)), function(k) {
    cs <- casillas[k, ]
    clases <- c("casilla", paste0("casilla-", cs$familia), if (cs$orden %in% ESQUINAS_PORTADA) "casilla-esquina",
                if (!cs$activa) "casilla-inactiva")
    texto <- sprintf("<span class=\"casilla-texto\" data-texto-es=\"%s\" data-texto-en=\"%s\">%s</span>",
                     escapar_html(cs$texto_es), escapar_html(cs$texto_en), escapar_html(cs$texto_es))
    cuerpo <- if (cs$activa) {
      es <- escapar_html(cs$destino)
      sprintf("<a href=\"%s\" data-href-es=\"%s\" data-href-en=\"%s\">%s</a>", es, es,
              escapar_html(destino_ingles(cs$destino, cs$destino_en)), texto)
    } else {
      paste0(texto, " <span class=\"casilla-pronto\" data-i18n=\"portada.proximamente\">pr\u00f3ximamente</span>")
    }
    titulo <- if (cs$activa) "" else " title=\"pr\u00f3ximamente\" data-i18n-title=\"portada.proximamente\""
    sprintf("%s<li class=\"%s\" data-casilla=\"%s\"%s>%s</li>", sangria, paste(clases, collapse = " "),
            escapar_html(cs$id), titulo, cuerpo)
  }, "")
  li
}

# Sustituye las casillas de web/index.html (entre MARCAS_CASILLAS) por las del CSV. Devuelve la ruta.
escribir_casillas_portada <- function(casillas, ruta = file.path("web", "index.html")) {
  html <- readLines(ruta, encoding = "UTF-8", warn = FALSE)
  i <- grep(MARCAS_CASILLAS[["inicio"]], html, fixed = TRUE)
  f <- grep(MARCAS_CASILLAS[["fin"]], html, fixed = TRUE)
  if (length(i) != 1 || length(f) != 1 || f <= i) stop("Marcas de las casillas no encontradas en ", ruta, call. = FALSE)
  sangria <- sub("^(\\s*).*$", "\\1", html[i])
  nuevo <- c(html[seq_len(i)], html_casillas_portada(casillas, sangria = sangria), html[f:length(html)])
  if (!identical(nuevo, html)) {
    con <- file(ruta, open = "wb")
    writeLines(enc2utf8(nuevo), con, useBytes = TRUE)
    close(con)
  }
  ruta
}

# --- Cifras de las cartas ----------------------------------------------------------------------

# Porcentaje con el redondeo de la guia.
porcentaje_guia <- function(x) redondeo_guia(100 * mean(x))

cifras_portada <- function(larga, superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  sueldo <- larga |> filter(indicador == "sueldo_necesario", nivel == "sc", corte == "total", !is.na(valor))
  anio_s <- max(sueldo$anio)
  s <- sueldo$valor[sueldo$anio == anio_s]
  q <- stats::quantile(s, c(0.1, 0.5, 0.9), names = FALSE, type = 7)

  peso <- larga |> filter(indicador == "peso_alquiler_ingreso", nivel == "sc", corte == "ficha", grupo == "tartera", !is.na(valor))
  anio_b <- max(peso$anio)
  b <- peso$valor[peso$anio == anio_b]

  sc <- larga |> filter(indicador == "sobrecarga", nivel == "nacional", geo_id == "00", !is.na(valor))
  anio_c <- max(sc$anio)
  de <- function(cc, g) sc$valor[sc$anio == anio_c & sc$corte == cc & sc$grupo == g]
  total <- de("total", "total")
  mercado <- de("tenencia", "RENT_MKT")

  list(
    sueldo = list(anio = anio_s, secciones = length(s), p10 = redondeo_guia(q[1]), mediana = redondeo_guia(q[2]),
                  p90 = redondeo_guia(q[3]), superficie_m2 = superficie, umbral = 100 * umbral,
                  mapa = "sueldo_necesario", fuentes = I(c("mivau_serpavi", "calculo_propio"))),
    smi = list(anio = anio_b, secciones = length(b), pct_30 = porcentaje_guia(b > 30), pct_40 = porcentaje_guia(b > 40),
               superficie_m2 = superficie, ficha = "tartera", fuentes = I(c("mivau_serpavi", "boe_smi", "calculo_propio"))),
    sobrecarga = if (length(total) == 1 && length(mercado) == 1) {
      list(anio = anio_c, total = redondeo_guia(total), alquiler_mercado = redondeo_guia(mercado), fuentes = I("ine_ecv"))
    }
  )
}

# Escribe <dir_web>/datos/portada.json. El ingreso neto de la tartera del año de la carta va con
# ella (el que usa la web, perfiles_web()). Devuelve la ruta.
exportar_portada <- function(larga, perfiles, dir_web = "web") {
  cifras <- cifras_portada(larga)
  tartera <- perfiles_web(perfiles)$tartera
  neto <- (tartera$anios[[as.character(cifras$smi$anio)]] %||% list())[["00"]]
  if (is.null(neto)) cifras$smi <- NULL else cifras$smi$neto_mensual <- neto
  cartas <- cifras[!vapply(cifras, is.null, TRUE)]
  dir <- file.path(dir_web, "datos")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ruta <- file.path(dir, FICHERO_PORTADA_WEB)
  con <- file(ruta, open = "wb")
  writeLines(jsonlite::toJSON(list(generado = format(Sys.Date()), cartas = cartas), auto_unbox = TRUE, digits = NA,
                              pretty = TRUE), con, useBytes = TRUE)
  close(con)
  ruta
}

# --- Compuertas --------------------------------------------------------------------------------

# portada_casillas: validez de inventario/casillas_portada.csv. `mapas`: ids de los mapas del
# manifiesto (o NULL); `anclas`: lista con las anclas de cada pagina generada (metodo.html,
# method.html...; o NULL). Una fila por comprobacion, con su recuento de casillas mal.
comprobar_casillas_portada <- function(casillas, mapas = NULL, anclas = NULL, claves_estado = NULL) {
  activa <- casillas$activa %in% TRUE
  con_destino <- nzchar(casillas$destino)
  destinos <- c(casillas$destino[activa], destino_ingles(casillas$destino[activa], casillas$destino_en[activa]))
  partes <- lapply(destinos, partes_destino)
  paginas_conocidas <- c("mapa.html", "sobrecarga.html", "metodo.html", "method.html", "datos.html", "data.html",
                         "historico.html")   # F6, historico
  mapa_mal <- if (is.null(mapas)) 0 else sum(vapply(partes, function(p) {
    !is.null(p$parametros$mapa) && !p$parametros$mapa %in% mapas
  }, TRUE))
  clave_mal <- if (is.null(claves_estado)) 0 else sum(vapply(partes, function(p) {
    p$pagina == "mapa.html" && any(!names(p$parametros) %in% claves_estado)
  }, TRUE))
  ancla_mal <- if (is.null(anclas)) 0 else sum(vapply(partes, function(p) {
    nzchar(p$ancla) && !is.null(anclas[[p$pagina]]) && !p$ancla %in% anclas[[p$pagina]]
  }, TRUE))
  ancla_sin_ingles <- sum(activa & grepl("^(metodo|datos)\\.html#", casillas$destino) & !nzchar(casillas$destino_en))
  tibble::tibble(
    id = "portada_casillas",
    detalle = c("casillas (24: 4 esquinas y 5 por lado)", "orden de 1 a 24 sin huecos", "ids repetidos",
                "familias fuera de las cuatro", "textos vac\u00edos", "activas sin destino", "inactivas con destino",
                "destinos fuera de las p\u00e1ginas del sitio", "mapas que no est\u00e1n en el manifiesto",
                "claves del mapa que no son de estado.js", "anclas que no est\u00e1n en su p\u00e1gina",
                "anclas de M\u00e9todo o Datos sin destino en ingl\u00e9s"),
    calculado = c(nrow(casillas), sum(sort(casillas$orden) != seq_len(nrow(casillas))), sum(duplicated(casillas$id)),
                  sum(!casillas$familia %in% FAMILIAS_PORTADA),
                  sum(!nzchar(trimws(casillas$texto_es)) | !nzchar(trimws(casillas$texto_en)) | !nzchar(casillas$id)),
                  sum(activa & !con_destino), sum(!activa & (con_destino | nzchar(casillas$destino_en))),
                  sum(!vapply(partes, function(p) p$pagina %in% paginas_conocidas, TRUE)), mapa_mal, clave_mal,
                  ancla_mal, ancla_sin_ingles),
    referencia = c(24, rep(0, 11))
  )
}

# portada_valores: cada cifra de portada.json frente a la recalculada. Sueldo y salario minimo,
# desde el alquiler por m2 de la vivienda colectiva (termino_publicado(), como lo recibe la web) y
# el ingreso de la tartera de perfiles_web(); sobrecarga, desde sus filas. Una carta que falta en
# el fichero cuenta como diferencia.
comprobar_portada <- function(larga, perfiles, dir_web = "web", superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  ruta <- file.path(dir_web, "datos", FICHERO_PORTADA_WEB)
  json <- if (file.exists(ruta)) jsonlite::read_json(ruta) else list()
  cartas <- json$cartas %||% list()
  m2 <- larga |> filter(indicador == "alquiler_m2", nivel == "sc", corte == "tipologia", grupo == "VC") |>
    mutate(valor = termino_publicado(valor)) |> filter(!is.na(valor))
  fila <- function(detalle, calculado, referencia) {
    tibble::tibble(id = "portada_valores", detalle = detalle, calculado = as.numeric(calculado %||% NA_real_),
                   referencia = as.numeric(referencia))
  }
  filas <- list()

  anio_s <- max(m2$anio)
  sueldo <- m2$valor[m2$anio == anio_s] * superficie / umbral
  q <- redondeo_guia(stats::quantile(sueldo, c(0.1, 0.5, 0.9), names = FALSE, type = 7))
  s <- cartas$sueldo
  filas <- c(filas, list(fila("sueldo: a\u00f1o", s$anio, anio_s), fila("sueldo: secciones con dato", s$secciones, length(sueldo)),
                         fila("sueldo: percentil 10", s$p10, q[1]), fila("sueldo: mediana", s$mediana, q[2]),
                         fila("sueldo: percentil 90", s$p90, q[3])))

  tartera <- perfiles_web(perfiles)$tartera
  c2 <- cartas$smi
  anio_b <- c2$anio %||% NA_integer_
  ingreso <- (tartera$anios[[as.character(anio_b)]] %||% list())[["00"]]
  if (is.null(c2) || is.null(ingreso)) {
    filas <- c(filas, list(fila("salario m\u00ednimo: carta e ingreso de la tartera", NA_real_, 1)))
  } else {
    ratio <- m2$valor[m2$anio == anio_b] * superficie / ingreso
    filas <- c(filas, list(fila("salario m\u00ednimo: secciones con dato", c2$secciones, length(ratio)),
                           fila("salario m\u00ednimo: ingreso neto", c2$neto_mensual, ingreso),
                           fila("salario m\u00ednimo: m\u00e1s del 30 %", c2$pct_30, porcentaje_guia(ratio > 0.3)),
                           fila("salario m\u00ednimo: m\u00e1s del 40 %", c2$pct_40, porcentaje_guia(ratio > 0.4))))
  }

  sc <- larga |> filter(indicador == "sobrecarga", nivel == "nacional", geo_id == "00", !is.na(valor))
  anio_c <- max(sc$anio)
  de <- function(cc, g) redondeo_guia(sc$valor[sc$anio == anio_c & sc$corte == cc & sc$grupo == g])
  c3 <- cartas$sobrecarga
  filas <- c(filas, list(fila("sobrecarga: a\u00f1o", c3$anio, anio_c), fila("sobrecarga: total", c3$total, de("total", "total")),
                         fila("sobrecarga: alquiler a precio de mercado", c3$alquiler_mercado, de("tenencia", "RENT_MKT"))))
  bind_rows(filas)
}

# Anclas (atributos id) de las paginas de texto generadas que existan en <dir_web>.
anclas_paginas_web <- function(dir_web = "web", paginas = c("metodo.html", "method.html", "datos.html", "data.html")) {
  rutas <- file.path(dir_web, paginas)
  existe <- file.exists(rutas)
  stats::setNames(lapply(rutas[existe], function(r) {
    html <- paste(readLines(r, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    unique(regmatches(html, gregexpr("(?<=\\bid=\")[^\"]+", html, perl = TRUE))[[1]])
  }), paginas[existe])
}

# Claves del estado de la vista (web/js/estado.js, VALIDAS), leidas del propio fichero.
claves_estado_web <- function(ruta = file.path("web", "js", "estado.js")) {
  js <- readLines(ruta, encoding = "UTF-8", warn = FALSE)
  i <- grep("^const VALIDAS = \\{", js)
  f <- i + which(js[(i + 1):length(js)] == "};")[1]
  sub("^\\s+([a-z_]+):.*$", "\\1", grep("^\\s+[a-z_]+: ", js[(i + 1):(f - 1)], value = TRUE))
}
