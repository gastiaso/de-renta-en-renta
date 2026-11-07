# AEAT, «Mercado de trabajo y pensiones en las fuentes tributarias» (aeat_mercado_trabajo).
# Solo hay tablas HTML: una página por combinación de filtros (jrubik<hash>.html), con hashes
# que cambian en cada edición. Se parte del mapa de la estadística, se busca la tabla por su
# título y se recorren sus menús de filtros. Cada página se guarda en
# datos/brutos/aeat_mercado/<año>/ con su nombre original.

URL_AEAT_MERCADO <- paste0("https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/",
                           "Estadisticas/Publicaciones/sites/mercado/%d/%s")
DIR_AEAT_MERCADO <- file.path("datos", "brutos", "aeat_mercado")

aeat_pagina <- function(anio, pagina, dir = DIR_AEAT_MERCADO) {
  destino <- file.path(dir, anio, pagina)
  nueva <- !file.exists(destino)
  ruta <- descargar_con_cache(sprintf(URL_AEAT_MERCADO, anio, pagina), destino)
  if (nueva) Sys.sleep(0.3)   # sin prisa con la sede
  ruta
}

# Nombre de columna sin tildes ni espacios: «Distribución geográfica» → «distribucion_geografica».
# (targets no admite símbolos con caracteres no ASCII en el cuerpo de las funciones.)
nombre_columna <- function(x) {
  x <- chartr("áéíóúüñÁÉÍÓÚÜÑ", "aeiouunAEIOUUN", x)
  gsub("^_|_$", "", gsub("[^a-z0-9]+", "_", tolower(x)))
}

espacios <- function(x) trimws(gsub("[\\s\\x{00A0}]+", " ", x, perl = TRUE))   # también espacios duros

# Título de la página: «Mercado de trabajo y pensiones: <año>:», la tabla y, después, una
# línea «Filtro: valor» por cada filtro (separadas por comas sueltas).
aeat_titulo <- function(html) {
  lineas <- trimws(strsplit(xml2::xml_text(xml2::xml_find_first(html, "//title")), "\n")[[1]])
  lineas <- lineas[nzchar(lineas) & lineas != ","]
  filtros <- lineas[-(1:2)]
  list(tabla = espacios(lineas[2]),
       filtros = stats::setNames(espacios(sub("^[^:]*:", "", filtros)), espacios(sub(":.*$", "", filtros))))
}

# Enlaces de los menús de filtros: dimensión, valor y página.
aeat_menus <- function(html) {
  menus <- xml2::xml_find_all(html, "//nav[@aria-label='Filtros']//ul[@role='menu']")
  vacio <- tibble::tibble(dimension = character(0), valor = character(0), pagina = character(0))
  dplyr::bind_rows(vacio, lapply(menus, function(m) {
    a <- xml2::xml_find_all(m, ".//a[@role='menuitem']")
    tibble::tibble(dimension = espacios(xml2::xml_attr(m, "aria-label")), valor = espacios(xml2::xml_text(a)),
                   pagina = xml2::xml_attr(a, "href"))
  }))
}

# Página de inicio de la tabla cuyo título en el mapa es exactamente `titulo`.
aeat_buscar_tabla <- function(anio, titulo, dir = DIR_AEAT_MERCADO) {
  mapa <- xml2::read_html(aeat_pagina(anio, "mapa.html", dir))
  enlaces <- xml2::xml_find_all(mapa, "//a[starts-with(@href, 'jrubik')]")
  i <- which(espacios(xml2::xml_text(enlaces)) == titulo)
  if (length(i) != 1) stop("No se encuentra una única tabla «", titulo, "» en el mapa de ", anio, call. = FALSE)
  xml2::xml_attr(enlaces[i], "href")
}

# Descarga las páginas de una tabla con los filtros de `fijos` (lista dimensión = valor); las
# dimensiones que no se fijan se recorren enteras. Devuelve las rutas (para format = "file").
descargar_aeat_mercado <- function(anio, titulo, fijos = list(), dir = DIR_AEAT_MERCADO, max_paginas = 300) {
  inicio <- aeat_buscar_tabla(anio, titulo, dir)
  cola <- inicio
  vistas <- character(0)
  guardadas <- character(0)
  combinaciones <- character(0)   # la misma combinación de filtros puede tener dos páginas
  tabla <- NULL
  while (length(cola) > 0) {
    p <- cola[1]
    cola <- cola[-1]
    if (p %in% vistas) next
    vistas <- c(vistas, p)
    if (length(vistas) > max_paginas) stop("Más de ", max_paginas, " páginas en «", titulo, "»", call. = FALSE)
    ruta <- aeat_pagina(anio, p, dir)
    html <- xml2::read_html(ruta)
    meta <- aeat_titulo(html)
    if (is.null(tabla)) tabla <- meta$tabla
    if (meta$tabla != tabla) next
    cumple <- all(vapply(names(fijos), function(d) identical(unname(meta$filtros[d]), fijos[[d]]), logical(1)))
    clave <- paste(names(meta$filtros), meta$filtros, sep = "=", collapse = "|")
    if (cumple && !clave %in% combinaciones) {
      guardadas <- c(guardadas, ruta)
      combinaciones <- c(combinaciones, clave)
    }
    m <- aeat_menus(html)
    fuera <- m$dimension %in% names(fijos)
    fuera[fuera] <- m$valor[fuera] != unlist(fijos)[m$dimension[fuera]]
    cola <- c(cola, setdiff(m$pagina[!fuera], vistas))
  }
  if (length(guardadas) == 0) stop("Ninguna página de «", titulo, "» cumple los filtros", call. = FALSE)
  sort(guardadas)
}

# Lee páginas de una tabla en formato largo: una fila por celda, con los filtros de la página
# (una columna por filtro, con nombre_columna()),
# la etiqueta de la fila (y su nivel de sangría: 0 = comunidad, 1 = provincia) y la columna
# (cabeceras de varios niveles unidas con « · »). Cada celda lleva en `headers` los
# identificadores de sus cabeceras.
leer_aeat_mercado <- function(rutas) {
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    html <- xml2::read_html(ruta)
    meta <- aeat_titulo(html)
    tabla <- xml2::xml_find_first(html, "//table")
    cab <- xml2::xml_find_all(tabla, ".//th[@id]")
    textos <- stats::setNames(espacios(xml2::xml_text(cab)), xml2::xml_attr(cab, "id"))
    sangria <- stats::setNames(
      as.integer(sub("^.*depth_div_(\\d+).*$", "\\1",
                     vapply(cab, function(x) {
                       d <- xml2::xml_find_first(x, ".//div[contains(@class, 'depth_div_')]")
                       if (inherits(d, "xml_missing")) "depth_div_0" else xml2::xml_attr(d, "class")
                     }, ""))),
      names(textos))
    celdas <- xml2::xml_find_all(tabla, ".//td[@headers]")
    ids <- strsplit(trimws(xml2::xml_attr(celdas, "headers")), "\\s+")
    fila_id <- vapply(ids, function(x) x[grepl("_f\\d+$", x)][1], "")
    col_ids <- lapply(ids, function(x) x[grepl("_c\\d+$", x)])
    d <- tibble::tibble(
      tabla = meta$tabla,
      fila = unname(textos[fila_id]),
      nivel_fila = unname(sangria[fila_id]),
      columna = vapply(col_ids, function(x) paste(textos[x], collapse = " · "), ""),
      valor = numero_es(xml2::xml_text(celdas))
    )
    for (f in names(meta$filtros)) d[[nombre_columna(f)]] <- meta$filtros[[f]]
    d
  }))
}

# «20.637.992» → 20637992; «1,39» → 1.39; «3,80%» → 3.8; «-» → NA.
numero_es <- function(x) {
  x <- gsub("[%\\s]", "", trimws(x), perl = TRUE)
  suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE)))
}
