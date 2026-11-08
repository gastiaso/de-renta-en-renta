# Kit de diseño en la web (backlog, tarea 9): web/estilo/tokens.css desde diseno/tokens.json,
# contrastes WCAG recalculados y tipografías autoalojadas.

# Contraste WCAG 2 entre dos colores hexadecimales.
luminancia_relativa <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  lin <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  as.numeric(c(0.2126, 0.7152, 0.0722) %*% lin)
}

contraste_wcag <- function(a, b) {
  vapply(seq_along(a), function(i) {
    l <- sort(c(luminancia_relativa(a[i]), luminancia_relativa(b[i])), decreasing = TRUE)
    (l[1] + 0.05) / (l[2] + 0.05)
  }, numeric(1))
}

# Tramos de la rampa con menos de 3:1 sobre la crema: llevan siempre contorno.
tramos_con_contorno <- function(tokens) {
  pasos <- vapply(tokens$rampa_secuencial$pasos, `[[`, "", "hex")
  which(contraste_wcag(pasos, rep(tokens$colores$crema$hex, length(pasos))) < 3)
}

# Daltonismo (pregunta abierta 20). Colores en OKLab (Ottosson, 2020), con la visión normal y con
# protanopía, deuteranopía y tritanopía simuladas con las matrices de Machado, Oliveira y
# Fernandes (2009, severidad 1), que se aplican al RGB lineal.
SIMULACION_DALTONISMO <- list(
  normal = diag(3),
  protanopia = matrix(c(0.152286, 1.052583, -0.204868, 0.114503, 0.786281, 0.099216,
                        -0.003882, -0.048116, 1.051998), 3, byrow = TRUE),
  deuteranopia = matrix(c(0.367322, 0.860646, -0.227968, 0.280085, 0.672501, 0.047413,
                          -0.011820, 0.042940, 0.968881), 3, byrow = TRUE),
  tritanopia = matrix(c(1.255528, -0.076749, -0.178779, -0.078411, 0.930809, 0.147602,
                        0.004733, 0.691367, 0.303900), 3, byrow = TRUE)
)
# Distancia OKLab mínima entre pasos contiguos de la rampa, en cada visión (la de cinco pasos daba 0,089).
DELTA_MINIMA_RAMPA <- 0.08

rgb_lineal <- function(hex) {
  x <- grDevices::col2rgb(hex) / 255
  ifelse(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055)^2.4)
}

oklab <- function(lineal) {
  a_lms <- matrix(c(0.4122214708, 0.5363325363, 0.0514459929, 0.2119034982, 0.6806995451, 0.1073969566,
                    0.0883024619, 0.2817188376, 0.6299787005), 3, byrow = TRUE)
  a_lab <- matrix(c(0.2104542553, 0.7936177850, -0.0040720468, 1.9779984951, -2.4285922050, 0.4505937099,
                    0.0259040371, 0.7827717662, -0.8086757660), 3, byrow = TRUE)
  lms <- a_lms %*% lineal
  a_lab %*% (sign(lms) * abs(lms)^(1 / 3))
}

# Por visión: distancia OKLab entre cada par de pasos contiguos y claridad de cada paso.
distancias_rampa <- function(hex, simulaciones = SIMULACION_DALTONISMO) {
  bind_rows(lapply(names(simulaciones), function(v) {
    lab <- oklab(pmin(pmax(simulaciones[[v]] %*% rgb_lineal(hex), 0), 1))
    tibble::tibble(vision = v, par = seq_len(length(hex) - 1),
                   distancia = sqrt(colSums((lab[, -1, drop = FALSE] - lab[, -ncol(lab), drop = FALSE])^2)),
                   baja_claridad = lab[1, -1] < lab[1, -ncol(lab)])
  }))
}

# Tipografías: la API de Google Fonts solo se usa para bajar los woff2 (subconjunto latino)
# y las licencias; en la web se sirven desde web/estilo/fuentes/. Jost y Archivo Narrow son
# variables (un fichero para todos los pesos). Yellowtail tiene licencia Apache 2.0, no OFL.
TIPOGRAFIAS <- tibble::tribble(
  ~familia,         ~api,                            ~licencia,
  "Jost",           "Jost:wght@400;500;700;800",     "ofl/jost/OFL.txt",
  "Marcellus SC",   "Marcellus+SC",                  "ofl/marcellussc/OFL.txt",
  "Archivo Narrow", "Archivo+Narrow:wght@400;700",   "ofl/archivonarrow/OFL.txt",
  "Yellowtail",     "Yellowtail",                    "apache/yellowtail/LICENSE.txt"
)

descargar_tipografias <- function(dir = file.path("web", "estilo", "fuentes"), forzar = FALSE) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  rutas <- character()
  for (k in seq_len(nrow(TIPOGRAFIAS))) {
    t <- TIPOGRAFIAS[k, ]
    base <- gsub(" ", "-", tolower(t$familia))
    woff2 <- file.path(dir, paste0(base, "-latin.woff2"))
    licencia <- file.path(dir, paste0(base, "-", basename(t$licencia)))
    if (!file.exists(woff2) || forzar) {
      css <- httr2::request(paste0("https://fonts.googleapis.com/css2?family=", t$api, "&display=swap")) |>
        httr2::req_user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36") |>
        httr2::req_perform() |> httr2::resp_body_string()
      bloque <- regmatches(css, regexpr("/\\* latin \\*/\\s*@font-face\\s*\\{[^}]*\\}", css))
      url <- sub(".*url\\(([^)]+)\\).*", "\\1", bloque)
      if (length(url) != 1) stop("No encuentro el subconjunto latino de ", t$familia, call. = FALSE)
      descargar_con_cache(url, woff2, forzar = TRUE)
    }
    descargar_con_cache(paste0("https://raw.githubusercontent.com/google/fonts/main/", t$licencia), licencia, forzar)
    rutas <- c(rutas, woff2, licencia)
  }
  rutas
}

# Escribe web/estilo/tokens.css. Lo que sale de tokens.json no se edita a mano en el CSS.
generar_tokens_css <- function(tokens, ruta = file.path("web", "estilo", "tokens.css")) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  var <- function(nombre, valor) sprintf("  --%s: %s;", nombre, valor)
  colores <- mapply(function(n, c) var(paste0("color-", n), c$hex), names(tokens$colores), tokens$colores)
  pasos <- vapply(tokens$rampa_secuencial$pasos, `[[`, "", "hex")
  rampa <- var(paste0("rampa-", seq_along(pasos)), pasos)
  fichas <- tokens$fichas[names(tokens$fichas) != "regla"]
  fichas_css <- unlist(mapply(function(n, f) c(var(paste0("ficha-", n), f$objeto), var(paste0("ficha-", n, "-texto"), f$texto)),
                              names(fichas), fichas, SIMPLIFY = FALSE))
  f <- tokens$formas
  formas <- c(
    var("borde", sub("tinta", "solid var(--color-tinta)", f$borde)),
    var("marco-pagina", sub("tinta", "solid var(--color-tinta)", f$marco_pagina)),
    var("radio-tarjeta", paste0(f$radio_tarjeta_px, "px")),
    var("radio-control", paste0(f$radio_control_px, "px")),
    var("radio-mapa", paste0(f$radio_mapa_px, "px")),
    var("sombra-ficha", sub("tinta", "var(--color-tinta)", f$sombra_ficha)),
    var("objetivo-tactil", paste0(f$objetivo_tactil_min_px, "px"))
  )
  tipos <- c(
    var("fuente-tablero", '"Jost", "Futura", "Century Gothic", sans-serif'),
    var("fuente-escritura", '"Marcellus SC", "Copperplate", serif'),
    var("fuente-carta", '"Archivo Narrow", "Arial Narrow", sans-serif'),
    var("fuente-cabecera-carta", '"Yellowtail", cursive')
  )
  caras <- c(
    '@font-face { font-family: "Jost"; src: url("fuentes/jost-latin.woff2") format("woff2"); font-weight: 400 800; font-display: swap; }',
    '@font-face { font-family: "Marcellus SC"; src: url("fuentes/marcellus-sc-latin.woff2") format("woff2"); font-weight: 400; font-display: swap; }',
    '@font-face { font-family: "Archivo Narrow"; src: url("fuentes/archivo-narrow-latin.woff2") format("woff2"); font-weight: 400 700; font-display: swap; }',
    '@font-face { font-family: "Yellowtail"; src: url("fuentes/yellowtail-latin.woff2") format("woff2"); font-weight: 400; font-display: swap; }'
  )
  contorno <- tramos_con_contorno(tokens)
  tramos <- vapply(seq_along(pasos), function(i) {
    regla <- sprintf(".tramo-%d { background: var(--rampa-%d);", i, i)
    if (i %in% contorno) regla <- paste(regla, "outline: 1px solid var(--color-tinta); outline-offset: -1px;")
    paste(regla, "}")
  }, "")
  css <- c(
    "/* De renta en renta · tokens del tablero.",
    "   Generado desde diseno/tokens.json con generar_tokens_css(): no editar a mano. */",
    "", caras, "", ":root {", colores, "", rampa, "", fichas_css, "", tipos, "", formas, "}", "",
    sprintf("/* Rampa secuencial. Los tramos %s no llegan a 3:1 sobre la crema: llevan siempre contorno",
            paste(contorno, collapse = " y ")),
    "   (en los mapas de MapLibre, una capa de línea del mismo color que el texto). Nunca como texto. */",
    tramos, "",
    "/* Huecos: secreto estadístico y muestra pequeña */",
    ".secreto { background: repeating-linear-gradient(45deg, var(--color-tenue) 0 2px, transparent 2px 6px); border: 1px solid var(--color-tenue); }",
    ".muestra-pequena { background-image: repeating-linear-gradient(45deg, var(--color-placa) 0 2px, transparent 2px 6px); }",
    "",
    "/* Yellowtail solo en titulares de 22 px o más */",
    ".cabecera-carta { font-family: var(--fuente-cabecera-carta); font-size: max(22px, 1.5rem); font-weight: 400; }",
    ""
  )
  writeLines(css, ruta, useBytes = TRUE)
  ruta
}

# Compuertas del diseño (inventario/referencias_validacion.csv):
#   contraste_texto: colores de texto por debajo de 4,5:1 sobre crema o placa (bloqueo);
#   contraste_declarado: diferencia entre lo declarado en tokens.json y lo recalculado, también en
#     la rampa (alerta);
#   rampa_contorno: tramos por debajo de 3:1 sin contorno en el CSS (bloqueo);
#   rampa_daltonismo: pares de pasos contiguos más cerca que DELTA_MINIMA_RAMPA en alguna visión, o
#     que no bajan de claridad (bloqueo).
comprobar_contrastes <- function(tokens, ruta_css, delta_minima = DELTA_MINIMA_RAMPA) {
  col <- tokens$colores
  texto <- c("tinta", "tenue", "rojo", "mesa")
  pares <- tibble::tibble(
    color = c(rep(texto, 2), paste0("ficha-", names(tokens$fichas)[names(tokens$fichas) != "regla"])),
    hex = c(vapply(texto, function(n) col[[n]]$hex, ""), vapply(texto, function(n) col[[n]]$hex, ""),
            vapply(tokens$fichas[names(tokens$fichas) != "regla"], `[[`, "", "texto")),
    fondo = c(rep("crema", 4), rep("placa", 4), rep("placa", length(tokens$fichas) - 1))
  ) |>
    mutate(contraste = contraste_wcag(hex, vapply(fondo, function(f) col[[f]]$hex, "")))
  pasos <- tokens$rampa_secuencial$pasos
  hex_pasos <- vapply(pasos, `[[`, "", "hex")
  declarado <- bind_rows(
    lapply(texto, function(n) tibble::tibble(detalle = paste(n, c("crema", "placa")),
                                             declarado = c(col[[n]]$contraste_crema, col[[n]]$contraste_placa),
                                             calculado = contraste_wcag(rep(col[[n]]$hex, 2), c(col$crema$hex, col$placa$hex)))),
    tibble::tibble(detalle = paste("rampa", seq_along(pasos), "crema"),
                   declarado = vapply(pasos, function(p) as.numeric(p$contraste_crema), 0),
                   calculado = contraste_wcag(hex_pasos, rep(col$crema$hex, length(pasos))))
  )
  css <- readLines(ruta_css, encoding = "UTF-8")
  contorno <- tramos_con_contorno(tokens)
  sin_contorno <- sum(!vapply(contorno, function(i) any(grepl(sprintf("^\\.tramo-%d \\{.*outline", i), css)), logical(1)))
  d <- distancias_rampa(hex_pasos)
  daltonismo <- d |>
    group_by(vision) |>
    summarise(calculado = sum(distancia < delta_minima | !baja_claridad), minima = min(distancia), .groups = "drop") |>
    transmute(id = "rampa_daltonismo", detalle = sprintf("%s: distancia OKLab mínima %.3f", vision, minima),
              calculado, referencia = 0)
  bind_rows(
    tibble::tibble(id = "contraste_texto", detalle = paste(sum(pares$contraste < 4.5), "de", nrow(pares), "pares por debajo de 4,5:1"),
                   calculado = sum(pares$contraste < 4.5), referencia = 0),
    declarado |> transmute(id = "contraste_declarado", detalle, calculado = calculado - declarado, referencia = 0),
    tibble::tibble(id = "rampa_contorno", detalle = paste("tramos bajo 3:1:", paste(contorno, collapse = ", ")),
                   calculado = sin_contorno, referencia = 0),
    daltonismo
  ) |> mutate(anio = NA_integer_, .after = id)
}
