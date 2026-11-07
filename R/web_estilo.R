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
#   contraste_declarado: diferencia entre lo declarado en tokens.json y lo recalculado (alerta);
#   rampa_contorno: tramos por debajo de 3:1 sin contorno en el CSS (bloqueo).
comprobar_contrastes <- function(tokens, ruta_css) {
  col <- tokens$colores
  texto <- c("tinta", "tenue", "rojo", "mesa")
  pares <- tibble::tibble(
    color = c(rep(texto, 2), paste0("ficha-", names(tokens$fichas)[names(tokens$fichas) != "regla"])),
    hex = c(vapply(texto, function(n) col[[n]]$hex, ""), vapply(texto, function(n) col[[n]]$hex, ""),
            vapply(tokens$fichas[names(tokens$fichas) != "regla"], `[[`, "", "texto")),
    fondo = c(rep("crema", 4), rep("placa", 4), rep("placa", length(tokens$fichas) - 1))
  ) |>
    mutate(contraste = contraste_wcag(hex, vapply(fondo, function(f) col[[f]]$hex, "")))
  declarado <- bind_rows(
    lapply(texto, function(n) tibble::tibble(detalle = paste(n, c("crema", "placa")),
                                             declarado = c(col[[n]]$contraste_crema, col[[n]]$contraste_placa),
                                             calculado = contraste_wcag(rep(col[[n]]$hex, 2), c(col$crema$hex, col$placa$hex))))
  )
  css <- readLines(ruta_css, encoding = "UTF-8")
  contorno <- tramos_con_contorno(tokens)
  sin_contorno <- sum(!vapply(contorno, function(i) any(grepl(sprintf("^\\.tramo-%d \\{.*outline", i), css)), logical(1)))
  bind_rows(
    tibble::tibble(id = "contraste_texto", detalle = paste(sum(pares$contraste < 4.5), "de", nrow(pares), "pares por debajo de 4,5:1"),
                   calculado = sum(pares$contraste < 4.5), referencia = 0),
    declarado |> transmute(id = "contraste_declarado", detalle, calculado = calculado - declarado, referencia = 0),
    tibble::tibble(id = "rampa_contorno", detalle = paste("tramos bajo 3:1:", paste(contorno, collapse = ", ")),
                   calculado = sin_contorno, referencia = 0)
  ) |> mutate(anio = NA_integer_, .after = id)
}
