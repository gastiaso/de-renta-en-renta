# INSS, «Pensiones contributivas del Sistema de la Seguridad Social» en vigor (inss_pensiones).
# Excel mensual «Pensiones por CCAA y provincias» (total del sistema): número de pensiones y
# pensión media por clase, de cada provincia, comunidad y España, a día 1 del mes. La pensión
# media es la de una paga ordinaria (14 pagas al año). La provincia es la de la dirección
# provincial que gestiona la pensión, no la de residencia. Cuenta pensiones, no pensionistas.
# No incluye Clases Pasivas.
#
# Los ficheros cuelgan del histórico de la estadística (una página por año, otra por tipo de
# estadística y otra con los doce meses); las rutas llevan un identificador distinto por año y
# por fichero, así que se recorren las páginas. Cada Excel se guarda en
# datos/brutos/inss_pensiones/<año>/CA<año><mes>.xlsx. El nombre original cambia con los años
# (CA2(072015).xlsx, CA2201801.xlsx, CA202101.xlsx): el año y el mes salen de él.

URL_INSS <- "https://www.seg-social.es"
RUTA_INSS_HISTORICO <- "/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/2575"
DIR_INSS <- file.path("datos", "brutos", "inss_pensiones")

# Enlaces de una página del sitio de la Seguridad Social: destino (absoluto) y texto.
inss_enlaces <- function(ruta) {
  url <- if (grepl("^https?://", ruta)) ruta else paste0(URL_INSS, ruta)
  resp <- httr2::request(url) |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  html <- xml2::read_html(httr2::resp_body_string(resp, encoding = "UTF-8"))
  a <- xml2::xml_find_all(html, "//a[@href]")
  href <- xml2::xml_attr(a, "href")
  tibble::tibble(href = ifelse(grepl("^https?://", href), href, paste0(URL_INSS, href)),
                 texto = trimws(gsub("\\s+", " ", xml2::xml_text(a))))
}

# Único enlace cuyo texto cumple `patron` (sin distinguir mayúsculas).
inss_enlace <- function(enlaces, patron, que) {
  i <- which(grepl(patron, enlaces$texto, ignore.case = TRUE, perl = TRUE))
  i <- i[!duplicated(enlaces$href[i])]
  if (length(i) != 1) stop("No se encuentra un \u00fanico enlace a ", que, " (", length(i), ")", call. = FALSE)
  enlaces$href[i]
}

# Año y mes de un Excel por su nombre original: CA2(MMAAAA).xlsx o ...AAAAMM.xlsx.
inss_mes_de_fichero <- function(nombre) {
  nombre <- utils::URLdecode(basename(sub("\\?.*$", "", nombre)))   # %28 y %29 son los parentesis
  entre <-regmatches(nombre, regexec("\\((\\d{2})(\\d{4})\\)\\.xlsx?$", nombre))[[1]]
  final <- regmatches(nombre, regexec("(\\d{4})(\\d{2})\\.xlsx?$", nombre))[[1]]
  if (length(entre) == 3) return(c(anio = as.integer(entre[3]), mes = as.integer(entre[2])))
  if (length(final) == 3) return(c(anio = as.integer(final[2]), mes = as.integer(final[3])))
  c(anio = NA_integer_, mes = NA_integer_)
}

# Excel de los doce meses de un año, con caché: si ya están todos, no se consulta la web.
descargar_inss_pensiones <- function(anio, dir = DIR_INSS) {
  destino <- file.path(dir, anio, sprintf("CA%d%02d.xlsx", anio, 1:12))
  if (all(file.exists(destino))) return(destino)
  e <- inss_enlaces(RUTA_INSS_HISTORICO)
  e <- inss_enlaces(inss_enlace(e, paste0("^A\u00f1o ", anio, "$"), paste("el a\u00f1o", anio)))
  e <- inss_enlaces(inss_enlace(e, "^Pensiones contributivas en vigor$", "las pensiones en vigor"))
  e <- inss_enlaces(inss_enlace(e, "^Pensiones por CCAA y provincias", "las pensiones por provincia"))
  xlsx <- e[grepl("\\.xlsx?(\\?|$)", e$href), ]
  meses <- t(vapply(xlsx$href, inss_mes_de_fichero, c(anio = 0L, mes = 0L)))
  xlsx <- xlsx[!is.na(meses[, "anio"]) & meses[, "anio"] == anio, ]
  meses <- meses[!is.na(meses[, "anio"]) & meses[, "anio"] == anio, , drop = FALSE]
  falta <- setdiff(1:12, meses[, "mes"])
  if (length(falta) > 0) stop("Sin Excel del INSS de ", anio, " para los meses ", paste(falta, collapse = ", "), call. = FALSE)
  for (m in 1:12) {
    if (file.exists(destino[m])) next
    descargar_con_cache(xlsx$href[match(m, meses[, "mes"])], destino[m])
    Sys.sleep(0.5)   # sin prisa con la sede
  }
  destino
}

# Hoja del total del sistema: la primera, sin contar el índice, que dice TOTAL SISTEMA en sus
# primeras filas (desde 2020, el libro trae una hoja por régimen detrás de la del total).
inss_hoja_total <- function(ruta) {
  hojas <- readxl::excel_sheets(ruta)
  for (h in hojas[!grepl("^Indice", hojas, ignore.case = TRUE)]) {
    d <- suppressMessages(readxl::read_excel(ruta, sheet = h, col_names = FALSE, col_types = "text", n_max = 6))
    if (any(grepl("TOTAL SISTEMA", toupper(unlist(d)), fixed = TRUE))) return(h)
  }
  stop("Sin hoja del total del sistema en ", ruta, call. = FALSE)
}

# Pensiones de jubilación de cada fila (comunidad, provincia o total) de un Excel mensual: año y
# mes del título («PENSIONES EN VIGOR A 1 DE <MES> DE <AÑO>»), etiqueta, su clave
# (nombre_columna()), número de pensiones y pensión media (euros por paga). La columna se busca
# por su cabecera («JUBILACIÓN»), porque su posición cambia con los años.
leer_inss_pensiones <- function(rutas) {
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    d <- suppressMessages(readxl::read_excel(ruta, sheet = inss_hoja_total(ruta), col_names = FALSE, col_types = "text"))
    m <- as.matrix(d)
    arriba <- toupper(gsub("\\s+", " ", paste(stats::na.omit(m[1:4, 1]), collapse = " ")))
    fecha <- regmatches(arriba, regexec("A 1 DE ([A-Z]+) DE (\\d{4})", arriba))[[1]]
    if (length(fecha) != 3) stop("Sin fecha en el t\u00edtulo de ", ruta, call. = FALSE)
    cab <- which(matrix(grepl("^JUBILACI", toupper(trimws(m))), nrow = nrow(m)), arr.ind = TRUE)
    if (nrow(cab) != 1) stop("Sin una \u00fanica columna de jubilaci\u00f3n en ", ruta, call. = FALSE)
    fila <- cab[1, "row"]
    col <- cab[1, "col"]
    # Bajo la clase: numero y pension media (desde 2024, con el importe entre las dos)
    sub_cab <- tolower(m[fila + 1, pmin(col + 0:2, ncol(m))])
    col_media <- col + which(grepl("media", sub_cab[2:3]))[1]
    if (!grepl("^n", sub_cab[1]) || is.na(col_media)) {
      stop("Cabecera inesperada bajo la jubilaci\u00f3n en ", ruta, ": ", paste(sub_cab, collapse = " | "), call. = FALSE)
    }
    datos <- seq(fila + 2, nrow(m))
    etiqueta <- trimws(gsub("\\s+", " ", m[datos, 1]))
    numero <- suppressWarnings(as.numeric(m[datos, col]))
    media <- suppressWarnings(as.numeric(m[datos, col_media]))
    ok <- !is.na(etiqueta) & !is.na(numero) & !is.na(media)
    tibble::tibble(anio = as.integer(fecha[3]), mes = match(tolower(fecha[2]), MESES_ES),
                   etiqueta = etiqueta[ok], clave = nombre_columna(etiqueta[ok]),
                   pensiones = numero[ok], media = media[ok], fichero = basename(ruta))
  }))
}
