# «Reglas del juego» (backlog, tarea 64; docs/especificacion_reglas_del_juego.md): resúmenes de las
# normas estatales que fijan las condiciones del alquiler y la compra de vivienda habitual, con su
# norma y artículo enlazados al BOE consolidado, la fecha del texto consultado y su relación con los
# indicadores del atlas. Página web/reglas.html (web/js/reglas.js), desde datos/reglas.json.
#
#   inventario/reglas.csv            una fila por tema: textos en los dos idiomas (qué dice, a quién y
#                                    desde cuándo, cambios, en el atlas), normas en que se apoya el
#                                    resumen («BOE-A-1994-26003:a36», separadas por «;»), indicadores
#                                    y casillas de la portada relacionados, estado, fecha en que se leyó
#                                    el texto del BOE y revisión (`borrador` hasta que el autor hace la
#                                    revisión jurídica y pone la fecha)
#   inventario/reglas_normas.csv     una fila por norma citada: nombre en castellano y glosa en inglés,
#                                    rango, si el BOE la consolida, estado (REGLAS_ESTADOS), fecha de
#                                    efectos, resolución del Congreso (decretos-leyes), fecha de la
#                                    consulta y `fecha_actualizacion` del BOE en ese momento
#   inventario/reglas_literales.csv  una fila por cifra legal o literal de un resumen o de una casilla
#                                    de la portada: la norma, el bloque del artículo y el fragmento
#                                    literal del BOE que la sostiene
#
# Textos: cada línea de un campo es un párrafo o una viñeta; «[texto](destino)» es un enlace, al BOE
# (https://www.boe.es/) o a una página del atlas (REGLAS_PAGINAS).
#
# BOE, API de legislación consolidada (https://www.boe.es/datosabiertos/documentos/APIconsolidada.pdf;
# reutilización libre citando la fuente, aviso legal del BOE): por norma consolidada, sus metadatos
# (`fecha_actualizacion`, derogación, anulación, vigencia agotada) y su índice de bloques; por
# literal, el bloque del artículo. Caché en datos/brutos/boe_legislacion/<id>/. Los metadatos se
# vuelven a pedir si tienen más de REGLAS_DIAS_METADATOS días (señal del objetivo en _targets.R:
# reglas_boe_caducado()); el índice y los bloques, cuando el BOE ha actualizado la norma después de
# bajarlos. Si una descarga falla, se conserva la versión anterior y se avisa.
#
# Texto vigente de un bloque: la última versión que trae la API, sin las notas al pie
# (clase «nota_pie*») y sin la redacción futura que el BOE intercala como «Téngase en cuenta que, con
# efectos de …» (así iba el Real Decreto-ley 28/2026 en el artículo 10 de la LAU hasta que el BOE lo dio
# por derogado, 13-nov-2026): nunca se resume ni se comprueba como vigente una versión con efectos futuros.
#
# Compuertas (inventario/referencias_validacion.csv):
#   reglas_completo (bloqueo)  campos en los dos idiomas, identificadores y anclas válidos y únicos,
#                              normas con identificador del BOE válido y fila en reglas_normas.csv,
#                              estados del vocabulario, fechas, enlaces de los textos a destinos
#                              permitidos
#   reglas_borrador (alerta)   resúmenes con `revisado` = borrador. No paran el pipeline (la página
#                              se ve en local, marcados como borrador), pero empaquetar_publicacion()
#                              no publica su texto (R/publicar.R, comprobación reglas_sin_borrador)
#   reglas_al_dia (alerta)     normas con `fecha_actualizacion` del BOE posterior a la consultada, y
#                              normas que ningún resumen tiene por base cuyo estado en el inventario
#                              ya no es el del BOE. El calendario lo avisa también en
#                              fuentes_pendientes (fuente boe_legislacion; reglas_senal_calendario())
#   reglas_vigencia (bloqueo)  resúmenes que se apoyan en una norma derogada, anulada o con la
#                              vigencia agotada (en el BOE o en el inventario); estado del resumen
#                              distinto del de sus normas; decretos-leyes pendientes de convalidación
#                              fuera de plazo sin resolución del Congreso en el inventario; normas con
#                              efectos futuros que ya han llegado (y el BOE no da por derogadas)
#   reglas_literal (bloqueo)   cada fragmento de reglas_literales.csv está en el texto vigente de su
#                              bloque; filas de resúmenes o casillas que no existen; casillas que
#                              llevan a la página sin literal
#   reglas_enlaces (bloqueo)   las casillas de la portada que llevan a reglas.html, los enlaces de los
#                              textos y la ficha del 20 (web/js/ficha.js) van a anclas que existen;
#                              los indicadores citados existen en inventario/indicadores.csv
#   web_reglas (bloqueo)       ida y vuelta de datos/reglas.json
#
# Plazo de convalidación de un decreto-ley (Constitución, art. 86.2: «en el plazo de los treinta días
# siguientes a su promulgación»): se cuentan 30 días hábiles, de lunes a viernes, desde el día siguiente
# a la promulgación, y se da un margen de REGLAS_MARGEN_PUBLICACION días naturales a la publicación de
# la resolución en el BOE. El cómputo, por revisar (especificación, «Compuertas»).
#
# Salida: web/datos/reglas.json (fuera de git), con todos los resúmenes; los borradores llevan
# `borrador: true` y la página los marca. Los textos llevan escapes \u en el cuerpo de las funciones.

FICHERO_REGLAS_WEB <- "reglas.json"
REGLAS_RUTA <- file.path("inventario", "reglas.csv")
REGLAS_NORMAS_RUTA <- file.path("inventario", "reglas_normas.csv")
REGLAS_LITERALES_RUTA <- file.path("inventario", "reglas_literales.csv")
REGLAS_DIR_BOE <- file.path("datos", "brutos", "boe_legislacion")
REGLAS_API_BOE <- "https://boe.es/datosabiertos/api/legislacion-consolidada/id/"
REGLAS_DIAS_METADATOS <- 7
REGLAS_MARGEN_PUBLICACION <- 10
REGLAS_ESTADOS <- c("vigente", "vigente_pendiente_convalidacion", "con_efectos_futuros", "derogada", "anulada_tc")
REGLAS_BORRADOR <- "borrador"
REGLAS_COLUMNAS <- c("id", "orden", "titulo_es", "titulo_en", "que_dice_es", "que_dice_en", "a_quien_es", "a_quien_en",
                     "cambios_es", "cambios_en", "en_el_atlas_es", "en_el_atlas_en", "normas", "indicadores", "casillas",
                     "estado", "vigente_desde", "texto_consultado", "revisado")
REGLAS_TEXTOS <- c("titulo", "que_dice", "a_quien", "cambios", "en_el_atlas")
REGLAS_NORMAS_COLUMNAS <- c("id", "nombre_es", "nombre_en", "abreviatura_es", "abreviatura_en", "rango", "fecha_disposicion",
                            "consolidada", "estado", "efectos_desde", "resolucion_congreso", "texto_consultado",
                            "fecha_actualizacion", "notas")
REGLAS_LITERALES_COLUMNAS <- c("id", "ambito", "objeto", "norma", "bloque", "fragmento", "sostiene", "notas")
# Páginas del atlas a las que puede enlazar un texto (además del BOE)
REGLAS_PAGINAS <- c("./", "index.html", "mapa.html", "sobrecarga.html", "historico.html", "reglas.html",
                    "metodo.html", "method.html", "metodo_corto.html", "short_method.html", "datos.html", "data.html")
# Anclas de reglas.html que enlaza el código de la web (web/js/ficha.js: la ficha del indicador 20 y
# la de la variación del alquiler)
REGLAS_ANCLAS_WEB <- c("zonas-tensionadas")
REGLAS_RE_BOE <- "^BOE-A-[0-9]{4}-[0-9]+$"
REGLAS_RE_REF <- "^BOE-A-[0-9]{4}-[0-9]+(:[a-z0-9-]+)?$"

# --- Lectura del inventario -------------------------------------------------------------------------

reglas_leer_csv <- function(ruta, columnas) {
  x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = character(),
                       locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  faltan <- setdiff(columnas, names(x))
  if (length(faltan)) stop("Faltan columnas en ", ruta, ": ", paste(faltan, collapse = ", "), call. = FALSE)
  x
}

reglas_leer <- function(ruta = REGLAS_RUTA) {
  x <- reglas_leer_csv(ruta, REGLAS_COLUMNAS)
  x$orden <- suppressWarnings(as.integer(x$orden))
  x[order(x$orden), ]
}

reglas_leer_normas <- function(ruta = REGLAS_NORMAS_RUTA) {
  x <- reglas_leer_csv(ruta, REGLAS_NORMAS_COLUMNAS)
  x$consolidada <- toupper(x$consolidada) %in% "TRUE"
  x
}

reglas_leer_literales <- function(ruta = REGLAS_LITERALES_RUTA) reglas_leer_csv(ruta, REGLAS_LITERALES_COLUMNAS)

# Ancla de un resumen en la página: el id con guiones (zonas_tensionadas -> zonas-tensionadas).
reglas_ancla <- function(id) gsub("_", "-", id, fixed = TRUE)

# Normas de una celda («BOE-A-1994-26003:a36;BOE-A-2024-5213»): tabla norma, bloque ("" sin bloque).
reglas_refs <- function(celda) {
  partes <- trimws(unlist(strsplit(celda %||% "", ";", fixed = TRUE)))
  partes <- partes[nzchar(partes)]
  if (!length(partes)) return(tibble::tibble(ref = character(), norma = character(), bloque = character()))
  tibble::tibble(ref = partes, norma = sub(":.*$", "", partes),
                 bloque = ifelse(grepl(":", partes, fixed = TRUE), sub("^[^:]*:", "", partes), ""))
}

# Lista de una celda separada por «;» (indicadores, casillas).
reglas_lista <- function(celda) {
  x <- trimws(unlist(strsplit(celda %||% "", ";", fixed = TRUE)))
  x[nzchar(x)]
}

# Parrafos de un campo de texto: una linea, un parrafo; sin lineas vacias.
reglas_parrafos <- function(texto) {
  x <- trimws(unlist(strsplit(gsub("\r", "", texto %||% "", fixed = TRUE), "\n", fixed = TRUE)))
  x[nzchar(x)]
}

# Enlaces «[texto](destino)» de un texto: sus destinos.
reglas_enlaces_texto <- function(texto) {
  m <- regmatches(texto, gregexpr("\\[[^]]+\\]\\(([^)\\s]+)\\)", texto, perl = TRUE))[[1]]
  sub("^\\[[^]]+\\]\\(([^)]+)\\)$", "\\1", m)
}

# --- BOE: descarga con cache --------------------------------------------------------------------------

reglas_dir_norma <- function(id, dir = REGLAS_DIR_BOE) file.path(dir, id)
reglas_ruta_metadatos <- function(id, dir = REGLAS_DIR_BOE) file.path(reglas_dir_norma(id, dir), "metadatos.xml")
reglas_ruta_indice <- function(id, dir = REGLAS_DIR_BOE) file.path(reglas_dir_norma(id, dir), "indice.xml")
reglas_ruta_bloque <- function(id, bloque, dir = REGLAS_DIR_BOE) file.path(reglas_dir_norma(id, dir), paste0("bloque_", bloque, ".xml"))

# Pide una ruta de la API (XML) y la guarda en `destino`. La API contesta con su propio estado en el
# XML (<status><code>200</code>): otro codigo es un error. Si falla y hay copia, se conserva y se avisa.
reglas_pedir_boe <- function(url, destino) {
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  parcial <- paste0(destino, ".parcial")
  on.exit(unlink(parcial), add = TRUE)
  error <- tryCatch({
    httr2::request(url) |>
      httr2::req_headers(Accept = "application/xml") |>
      httr2::req_user_agent("de-renta-en-renta (R httr2)") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_timeout(120) |>
      httr2::req_perform(path = parcial)
    codigo <- xml2::xml_text(xml2::xml_find_first(xml2::read_xml(parcial), "/response/status/code"))
    if (!identical(codigo, "200")) stop("la API del BOE responde ", codigo, call. = FALSE)
    NULL
  }, error = function(e) e)
  if (is.null(error)) {
    if (file.exists(destino)) unlink(destino)
    if (!file.rename(parcial, destino)) stop("No se ha podido mover la descarga a ", destino, call. = FALSE)
    return(destino)
  }
  if (file.exists(destino)) {
    warning("Falla la descarga de ", url, ": se conserva la versi\u00f3n anterior de ", destino, "\n  ",
            conditionMessage(error), call. = FALSE)
    return(destino)
  }
  stop("No se ha podido descargar ", url, "\n  ", conditionMessage(error), call. = FALSE)
}

# Fecha de actualizacion del BOE de unos metadatos guardados (POSIXct, UTC), o NA.
reglas_fecha_actualizacion <- function(ruta) {
  if (!file.exists(ruta)) return(as.POSIXct(NA, tz = "UTC"))
  texto <- xml2::xml_text(xml2::xml_find_first(xml2::read_xml(ruta), "//metadatos/fecha_actualizacion"))
  as.POSIXct(texto, format = "%Y%m%dT%H%M%SZ", tz = "UTC")
}

# Descarga (o reutiliza) los metadatos e indices de las normas consolidadas de `normas` y los bloques
# de `literales`. Devuelve las rutas de los ficheros, para un objetivo de tipo fichero.
reglas_descargar_boe <- function(normas, literales, dir = REGLAS_DIR_BOE, dias = REGLAS_DIAS_METADATOS, ahora = Sys.time()) {
  ids <- normas$id[normas$consolidada]
  rutas <- character()
  for (id in ids) {
    base <- paste0(REGLAS_API_BOE, id)
    meta <- reglas_ruta_metadatos(id, dir)
    viejo <- !file.exists(meta) || difftime(ahora, file.mtime(meta), units = "days") > dias
    if (viejo) reglas_pedir_boe(paste0(base, "/metadatos"), meta)
    actualizada <- reglas_fecha_actualizacion(meta)
    # Indice y bloques: si faltan o si el BOE ha actualizado la norma despues de bajarlos
    pasado <- function(ruta) !file.exists(ruta) || (!is.na(actualizada) && file.mtime(ruta) < actualizada)
    indice <- reglas_ruta_indice(id, dir)
    if (pasado(indice)) reglas_pedir_boe(paste0(base, "/texto/indice"), indice)
    bloques <- unique(literales$bloque[literales$norma == id])
    for (b in bloques) {
      ruta <- reglas_ruta_bloque(id, b, dir)
      if (pasado(ruta)) reglas_pedir_boe(paste0(base, "/texto/bloque/", b), ruta)
      rutas <- c(rutas, ruta)
    }
    rutas <- c(rutas, meta, indice)
  }
  sort(unique(rutas))
}

# Senal del objetivo de descarga (se evalua al leer _targets.R; nunca da error): TRUE si a alguna norma
# consolidada le faltan los metadatos o tienen mas de `dias` dias.
reglas_boe_caducado <- function(ruta_normas = REGLAS_NORMAS_RUTA, dir = REGLAS_DIR_BOE, dias = REGLAS_DIAS_METADATOS,
                                ahora = Sys.time()) {
  tryCatch({
    normas <- reglas_leer_normas(ruta_normas)
    metas <- reglas_ruta_metadatos(normas$id[normas$consolidada], dir)
    any(!file.exists(metas)) || any(difftime(ahora, file.mtime(metas), units = "days") > dias)
  }, error = function(e) TRUE)
}

# --- BOE: lectura -----------------------------------------------------------------------------------

reglas_leer_metadatos <- function(ruta) {
  x <- xml2::read_xml(ruta)
  campo <- function(n) xml2::xml_text(xml2::xml_find_first(x, paste0("//metadatos/", n)))
  tibble::tibble(norma = campo("identificador"), titulo = campo("titulo"), rango = campo("rango"),
                 fecha_actualizacion = as.POSIXct(campo("fecha_actualizacion"), format = "%Y%m%dT%H%M%SZ", tz = "UTC"),
                 fecha_vigencia = campo("fecha_vigencia"), derogada = campo("estatus_derogacion") %in% "S",
                 anulada = campo("estatus_anulacion") %in% "S", agotada = campo("vigencia_agotada") %in% "S",
                 url = campo("url_html_consolidada"))
}

reglas_leer_indice <- function(ruta, norma) {
  bloques <- xml2::xml_find_all(xml2::read_xml(ruta), "//bloque")
  tibble::tibble(norma = norma, bloque = xml2::xml_text(xml2::xml_find_first(bloques, "id")),
                 titulo = trimws(gsub("\u00a0", " ", xml2::xml_text(xml2::xml_find_first(bloques, "titulo")), fixed = TRUE)))
}

# Normaliza un texto para comparar literales: espacios duros y seguidos, uno solo.
reglas_normalizar <- function(x) trimws(gsub("[[:space:]\u00a0]+", " ", x, perl = TRUE))

# Parrafos vigentes de un bloque: los de su ultima version, sin las notas al pie y sin la redaccion
# futura que el BOE intercala («Tengase en cuenta que, con efectos de ...») ni lo que la sigue.
reglas_texto_vigente <- function(ruta) {
  versiones <- xml2::xml_find_all(xml2::read_xml(ruta), "//version")
  if (!length(versiones)) return(character())
  p <- xml2::xml_find_all(versiones[[length(versiones)]], ".//p")
  clase <- xml2::xml_attr(p, "class")
  texto <- reglas_normalizar(xml2::xml_text(p))
  texto <- texto[is.na(clase) | !startsWith(clase, "nota")]
  futura <- grep("^T\u00e9ngase en cuenta que,? ?con efectos de", texto)
  if (length(futura)) texto <- texto[seq_len(futura[1] - 1L)]
  texto[nzchar(texto)]
}

# Todo lo leido del BOE: metadatos e indices de cada norma consolidada y texto vigente de cada bloque
# descargado. `ficheros`: los de reglas_descargar_boe().
reglas_leer_boe <- function(ficheros) {
  metas <- ficheros[basename(ficheros) == "metadatos.xml"]
  indices <- ficheros[basename(ficheros) == "indice.xml"]
  bloques <- ficheros[startsWith(basename(ficheros), "bloque_")]
  list(
    metadatos = dplyr::bind_rows(lapply(metas, reglas_leer_metadatos)),
    indices = dplyr::bind_rows(lapply(indices, function(r) reglas_leer_indice(r, basename(dirname(r))))),
    textos = dplyr::bind_rows(lapply(bloques, function(r) tibble::tibble(
      norma = basename(dirname(r)), bloque = sub("^bloque_(.*)\\.xml$", "\\1", basename(r)),
      texto = paste(reglas_texto_vigente(r), collapse = "\n"))))
  )
}

# --- Plazos -----------------------------------------------------------------------------------------

# Fin del plazo de convalidacion de un decreto-ley promulgado en `fecha` (Date): 30 dias habiles, de
# lunes a viernes, contados desde el dia siguiente.
reglas_plazo_convalidacion <- function(fecha, dias = 30L) {
  fecha <- as.Date(fecha)
  if (is.na(fecha)) return(as.Date(NA))
  d <- seq(fecha + 1, by = "day", length.out = dias * 2L)
  habiles <- d[!format(d, "%u") %in% c("6", "7")]
  habiles[dias]
}

# --- Compuertas -------------------------------------------------------------------------------------

reglas_fila <- function(id, detalle, calculado, referencia = 0) {
  tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

reglas_es_fecha <- function(x) !is.na(suppressWarnings(as.Date(x, format = "%Y-%m-%d"))) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)

# Destinos permitidos de un enlace de los textos: el BOE o una pagina del atlas (con su ancla, si es
# reglas.html, entre las de `anclas`).
reglas_destino_valido <- function(destino, anclas) {
  if (startsWith(destino, "https://www.boe.es/")) return(TRUE)
  partes <- regmatches(destino, regexec("^([^?#]*)(\\?[^#]*)?(#.*)?$", destino))[[1]]
  if (!length(partes)) return(FALSE)
  pagina <- if (nzchar(partes[2])) partes[2] else "reglas.html"
  if (!pagina %in% REGLAS_PAGINAS) return(FALSE)
  ancla <- sub("^#", "", partes[4])
  pagina != "reglas.html" || !nzchar(ancla) || ancla %in% anclas
}

# reglas_completo y reglas_borrador.
reglas_comprobar_completo <- function(reglas, normas, hoy = Sys.Date()) {
  campos <- unlist(lapply(REGLAS_TEXTOS, function(b) paste0(b, c("_es", "_en"))))
  vacios <- sum(vapply(campos, function(cc) sum(!nzchar(trimws(reglas[[cc]]))), numeric(1)))
  # Mismo numero de parrafos en los dos idiomas (un parrafo por linea)
  parrafos <- sum(vapply(REGLAS_TEXTOS[-1], function(b) {
    sum(vapply(seq_len(nrow(reglas)), function(k) length(reglas_parrafos(reglas[[paste0(b, "_es")]][k])) !=
                 length(reglas_parrafos(reglas[[paste0(b, "_en")]][k])), TRUE))
  }, numeric(1)))
  refs <- dplyr::bind_rows(lapply(reglas$normas, reglas_refs))
  sin_normas <- sum(vapply(reglas$normas, function(n) nrow(reglas_refs(n)) == 0, TRUE))
  anclas <- reglas_ancla(reglas$id)
  enlaces <- unlist(lapply(unlist(reglas[campos]), reglas_enlaces_texto))
  revisado_mal <- sum(!(reglas$revisado == REGLAS_BORRADOR | reglas_es_fecha(reglas$revisado)))
  fechas_mal <- sum(!reglas_es_fecha(reglas$texto_consultado) | (reglas_es_fecha(reglas$texto_consultado) &
                                                                     suppressWarnings(as.Date(reglas$texto_consultado)) > hoy)) +
    sum(!reglas_es_fecha(reglas$vigente_desde))
  normas_mal <- sum(!grepl(REGLAS_RE_BOE, normas$id)) + sum(duplicated(normas$id)) +
    sum(!normas$estado %in% REGLAS_ESTADOS) + sum(!reglas_es_fecha(normas$fecha_disposicion)) +
    sum(!nzchar(trimws(normas$nombre_es)) | !nzchar(trimws(normas$nombre_en)) |
          !nzchar(trimws(normas$abreviatura_es)) | !nzchar(trimws(normas$abreviatura_en))) +
    sum(normas$consolidada & !(reglas_es_fecha(normas$texto_consultado) & nzchar(normas$fecha_actualizacion)))
  dplyr::bind_rows(
    reglas_fila("reglas_completo", c(
      "res\u00famenes sin fila", "ids repetidos o con caracteres no v\u00e1lidos", "orden repetido o vac\u00edo",
      "textos vac\u00edos (castellano o ingl\u00e9s)", "textos con distinto n\u00famero de p\u00e1rrafos en cada idioma",
      "res\u00famenes sin normas", "normas citadas con identificador no v\u00e1lido",
      "normas citadas sin fila en reglas_normas.csv", "estados fuera del vocabulario",
      "fechas de consulta o de vigencia no v\u00e1lidas", "revisado: ni fecha ni borrador",
      "enlaces de los textos a destinos no permitidos", "filas de reglas_normas.csv no v\u00e1lidas"),
      c(as.numeric(nrow(reglas) == 0), sum(duplicated(reglas$id)) + sum(!grepl("^[a-z][a-z0-9_]{1,40}$", reglas$id)),
        sum(duplicated(reglas$orden)) + sum(is.na(reglas$orden)), vacios, parrafos, sin_normas,
        sum(!grepl(REGLAS_RE_REF, refs$ref)), sum(!refs$norma %in% normas$id), sum(!reglas$estado %in% REGLAS_ESTADOS),
        fechas_mal, revisado_mal, sum(!vapply(enlaces, reglas_destino_valido, TRUE, anclas = anclas)), normas_mal)),
    reglas_fila("reglas_borrador", "res\u00famenes en borrador (sin revisi\u00f3n jur\u00eddica: no se publican)",
                sum(reglas$revisado == REGLAS_BORRADOR))
  )
}

# reglas_al_dia y reglas_vigencia. `boe`: reglas_leer_boe(); `hoy`: Date.
reglas_comprobar_vigencia <- function(reglas, normas, boe, hoy = Sys.Date()) {
  meta <- boe$metadatos
  consultada <- as.POSIXct(normas$fecha_actualizacion, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  actual <- meta$fecha_actualizacion[match(normas$id, meta$norma)]
  cambiadas <- normas$id[normas$consolidada & !is.na(actual) & !is.na(consultada) & actual > consultada]
  sin_meta <- normas$id[normas$consolidada & is.na(actual)]
  refs <- dplyr::bind_rows(lapply(seq_len(nrow(reglas)), function(k) dplyr::mutate(reglas_refs(reglas$normas[k]), regla = reglas$id[k])))
  base <- unique(refs$norma)
  fuera_boe <- meta$norma[meta$derogada | meta$anulada | meta$agotada]
  fuera_inv <- normas$id[normas$estado %in% c("derogada", "anulada_tc")]
  # Estado del inventario frente al BOE: vigente o pendiente en el inventario y derogada en el BOE, o
  # al reves
  vigente_inv <- normas$estado %in% c("vigente", "vigente_pendiente_convalidacion", "con_efectos_futuros")
  descasadas <- normas$id[normas$consolidada & normas$id %in% meta$norma &
                            vigente_inv == (normas$id %in% fuera_boe)]
  # Resumenes que se apoyan en una norma fuera de vigor
  apoyo_mal <- unique(refs$regla[refs$norma %in% c(fuera_boe, fuera_inv)])
  # Estado de cada resumen frente al de sus normas
  pendiente <- normas$id[normas$estado == "vigente_pendiente_convalidacion"]
  esperado <- vapply(reglas$id, function(r) {
    ns <- refs$norma[refs$regla == r]
    if (any(ns %in% pendiente)) "vigente_pendiente_convalidacion" else "vigente"
  }, "")
  estado_mal <- reglas$id[reglas$estado != esperado]
  # Decretos-leyes pendientes fuera de plazo sin resolucion del Congreso
  limite <- vapply(normas$fecha_disposicion, function(f) as.character(reglas_plazo_convalidacion(f) + REGLAS_MARGEN_PUBLICACION), "")
  fuera_plazo <- normas$id[normas$estado %in% c("vigente_pendiente_convalidacion", "con_efectos_futuros") &
                             grepl("Real Decreto-ley", normas$rango, fixed = TRUE) & !nzchar(normas$resolucion_congreso) &
                             !is.na(limite) & as.Date(limite) < hoy]
  # Normas con efectos futuros que ya han llegado, sin derogar en el BOE
  efectos <- suppressWarnings(as.Date(normas$efectos_desde))
  llegadas <- normas$id[normas$estado == "con_efectos_futuros" & !is.na(efectos) & efectos <= hoy & !normas$id %in% fuera_boe]
  lista <- function(x) if (length(x)) paste0(": ", paste(x, collapse = ", ")) else ""
  dplyr::bind_rows(
    reglas_fila("reglas_al_dia", c(paste0("normas actualizadas en el BOE despu\u00e9s de la consulta", lista(cambiadas)),
                                   paste0("normas consolidadas sin metadatos del BOE", lista(sin_meta)),
                                   paste0("normas sin resumen que se apoye en ellas con el estado del inventario distinto del BOE",
                                          lista(setdiff(descasadas, base)))),
                c(length(cambiadas), length(sin_meta), length(setdiff(descasadas, base)))),
    reglas_fila("reglas_vigencia", c(paste0("res\u00famenes que se apoyan en una norma derogada, anulada o agotada", lista(apoyo_mal)),
                                     paste0("normas de los res\u00famenes con el estado del inventario distinto del BOE",
                                            lista(intersect(descasadas, base))),
                                     paste0("res\u00famenes con un estado distinto del de sus normas", lista(estado_mal)),
                                     paste0("decretos-leyes pendientes de convalidaci\u00f3n fuera de plazo sin resoluci\u00f3n del Congreso",
                                            lista(fuera_plazo)),
                                     paste0("normas con efectos futuros que ya han llegado", lista(llegadas))),
                c(length(apoyo_mal), length(intersect(descasadas, base)), length(estado_mal), length(fuera_plazo), length(llegadas)))
  )
}

# reglas_literal. `casillas`: leer_casillas_portada().
reglas_comprobar_literales <- function(literales, reglas, casillas, boe) {
  textos <- boe$textos
  vigente <- vapply(seq_len(nrow(literales)), function(k) {
    t <- textos$texto[textos$norma == literales$norma[k] & textos$bloque == literales$bloque[k]]
    length(t) == 1 && grepl(reglas_normalizar(literales$fragmento[k]), t, fixed = TRUE)
  }, TRUE)
  faltan <- literales$id[!vigente]
  objeto_mal <- sum(!(literales$ambito == "regla" & literales$objeto %in% reglas$id |
                        literales$ambito == "casilla" & literales$objeto %in% casillas$id))
  a_reglas <- casillas$id[casillas$activa %in% TRUE & startsWith(casillas$destino, "reglas.html")]
  sin_literal <- setdiff(a_reglas, literales$objeto[literales$ambito == "casilla"])
  lista <- function(x) if (length(x)) paste0(": ", paste(x, collapse = ", ")) else ""
  reglas_fila("reglas_literal", c(paste0("fragmentos que no est\u00e1n en el texto vigente de su bloque", lista(faltan)),
                                  "filas de res\u00famenes o casillas que no existen",
                                  "ids de literales repetidos o vac\u00edos",
                                  paste0("casillas que llevan a la p\u00e1gina sin literal", lista(sin_literal))),
              c(length(faltan), objeto_mal, sum(duplicated(literales$id)) + sum(!nzchar(literales$id)), length(sin_literal)))
}

# reglas_enlaces. `indicadores`: inventario/indicadores.csv.
reglas_comprobar_enlaces <- function(reglas, casillas, indicadores) {
  anclas <- reglas_ancla(reglas$id)
  destinos <- c(casillas$destino[casillas$activa %in% TRUE], destino_ingles(casillas$destino[casillas$activa %in% TRUE],
                                                                            casillas$destino_en[casillas$activa %in% TRUE]))
  a_reglas <- destinos[startsWith(destinos, "reglas.html")]
  ancla_casilla <- sub("^[^#]*#?", "", a_reglas)
  casilla_mal <- sum(nzchar(ancla_casilla) & !ancla_casilla %in% anclas)
  citadas <- unlist(lapply(reglas$casillas, reglas_lista))
  indic <- unlist(lapply(reglas$indicadores, reglas_lista))
  reglas_fila("reglas_enlaces", c("casillas de la portada que llevan a un ancla que no existe",
                                  "anclas que enlaza la web (ficha del indicador 20) y no existen",
                                  "casillas citadas que no est\u00e1n en la portada",
                                  "indicadores citados que no est\u00e1n en inventario/indicadores.csv"),
              c(casilla_mal, sum(!REGLAS_ANCLAS_WEB %in% anclas), sum(!citadas %in% casillas$id),
                sum(!indic %in% as.character(indicadores$id))))
}

# Todas las compuertas de las reglas salvo la de la web.
reglas_comprobar <- function(reglas, normas, literales, boe, casillas, indicadores, hoy = Sys.Date()) {
  dplyr::bind_rows(reglas_comprobar_completo(reglas, normas, hoy),
                   reglas_comprobar_vigencia(reglas, normas, boe, hoy),
                   reglas_comprobar_literales(literales, reglas, casillas, boe),
                   reglas_comprobar_enlaces(reglas, casillas, indicadores))
}

# --- Calendario ---------------------------------------------------------------------------------------

# Senal para fuentes_pendientes (R/calendario_fuentes.R, fuente boe_legislacion): normas citadas que el
# BOE ha actualizado despues de la consulta, segun los metadatos de la cache. Sin red. Nunca da error:
# texto vacio si no hay nada o no se puede leer.
reglas_senal_calendario <- function(raiz = ".") {
  tryCatch({
    normas <- reglas_leer_normas(file.path(raiz, REGLAS_NORMAS_RUTA))
    normas <- normas[normas$consolidada, ]
    actual <- vapply(normas$id, function(id) {
      as.numeric(reglas_fecha_actualizacion(reglas_ruta_metadatos(id, file.path(raiz, REGLAS_DIR_BOE))))
    }, numeric(1))
    consultada <- as.numeric(as.POSIXct(normas$fecha_actualizacion, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
    cambiadas <- normas$id[!is.na(actual) & !is.na(consultada) & actual > consultada]
    if (length(cambiadas)) paste0("normas citadas actualizadas en el BOE: ", paste(cambiadas, collapse = ", ")) else ""
  }, error = function(e) "")
}

# --- Exportacion a la web -------------------------------------------------------------------------------

# Declaraciones de zona tensionada de las comunidades (inventario/zonas_tensionadas.csv): por comunidad,
# cada declaracion con su enlace, sin repetir. `ccaa`: geo/ccaa.csv.
reglas_declaraciones <- function(zonas, ccaa) {
  if (is.null(zonas) || !nrow(zonas)) return(list())
  d <- unique(zonas[nzchar(zonas$declaracion %||% "") & !is.na(zonas$declaracion), c("ccaa", "declaracion", "url_declaracion")])
  d$url_declaracion[is.na(d$url_declaracion)] <- ""
  nombres <- stats::setNames(ccaa[[2]], ccaa[[1]])
  lapply(sort(unique(d$ccaa)), function(c) {
    x <- d[d$ccaa == c, ]
    list(ccaa = c, nombre = unname(nombres[c] %||% c),
         declaraciones = lapply(seq_len(nrow(x)), function(k) list(texto = x$declaracion[k], url = x$url_declaracion[k])))
  })
}

# Lista que se escribe en datos/reglas.json.
reglas_web <- function(reglas, normas, boe, zonas = NULL, ccaa = NULL, generado = Sys.Date()) {
  titulos <- boe$indices
  url_norma <- function(id, consolidada) {
    if (consolidada) paste0("https://www.boe.es/buscar/act.php?id=", id) else paste0("https://www.boe.es/diario_boe/txt.php?id=", id)
  }
  lista_normas <- stats::setNames(lapply(seq_len(nrow(normas)), function(k) {
    n <- normas[k, ]
    list(nombre = list(es = n$nombre_es, en = n$nombre_en), abreviatura = list(es = n$abreviatura_es, en = n$abreviatura_en),
         rango = n$rango, fecha_disposicion = n$fecha_disposicion, consolidada = n$consolidada, estado = n$estado,
         efectos_desde = n$efectos_desde, resolucion_congreso = n$resolucion_congreso,
         texto_consultado = n$texto_consultado, fecha_actualizacion = n$fecha_actualizacion,
         url = url_norma(n$id, n$consolidada))
  }), normas$id)
  # Siempre listas, tambien con un solo parrafo (I(): jsonlite no las desempaqueta)
  textos <- function(fila, base) list(es = I(reglas_parrafos(fila[[paste0(base, "_es")]])), en = I(reglas_parrafos(fila[[paste0(base, "_en")]])))
  lista_reglas <- lapply(seq_len(nrow(reglas)), function(k) {
    r <- reglas[k, ]
    refs <- reglas_refs(r$normas)
    consolidada <- normas$consolidada[match(refs$norma, normas$id)] %in% TRUE
    list(
      id = r$id, ancla = reglas_ancla(r$id), orden = r$orden,
      titulo = list(es = r$titulo_es, en = r$titulo_en),
      que_dice = textos(r, "que_dice"), a_quien = textos(r, "a_quien"), cambios = textos(r, "cambios"),
      en_el_atlas = textos(r, "en_el_atlas"),
      normas = lapply(seq_len(nrow(refs)), function(j) {
        t <- titulos$titulo[titulos$norma == refs$norma[j] & titulos$bloque == refs$bloque[j]]
        list(norma = refs$norma[j], bloque = refs$bloque[j], titulo = if (length(t) == 1) t else "",
             url = paste0(url_norma(refs$norma[j], consolidada[j]), if (nzchar(refs$bloque[j])) paste0("#", refs$bloque[j]) else ""))
      }),
      indicadores = I(reglas_lista(r$indicadores)), casillas = I(reglas_lista(r$casillas)),
      estado = r$estado, vigente_desde = r$vigente_desde, texto_consultado = r$texto_consultado,
      revisado = r$revisado, borrador = identical(r$revisado, REGLAS_BORRADOR)
    )
  })
  list(generado = format(as.Date(generado)), consultado = max(reglas$texto_consultado),
       borradores = sum(reglas$revisado == REGLAS_BORRADOR), normas = lista_normas, reglas = lista_reglas,
       declaraciones = reglas_declaraciones(zonas, ccaa))
}

reglas_escribir_json <- function(x, ruta) {
  # El texto, antes de abrir el fichero: `x` puede venir de leer ese mismo fichero (evaluacion perezosa)
  texto <- enc2utf8(jsonlite::toJSON(x, auto_unbox = TRUE, pretty = TRUE, null = "null"))
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  con <- file(ruta, open = "wb")
  on.exit(close(con), add = TRUE)
  writeLines(texto, con, useBytes = TRUE)
  ruta
}

# Escribe <dir_web>/datos/reglas.json. Devuelve la ruta.
reglas_exportar_web <- function(reglas, normas, boe, zonas = NULL, ccaa = NULL, dir_web = "web", generado = Sys.Date()) {
  reglas_escribir_json(reglas_web(reglas, normas, boe, zonas, ccaa, generado), file.path(dir_web, "datos", FICHERO_REGLAS_WEB))
}

# web_reglas: ida y vuelta de datos/reglas.json frente al inventario.
reglas_comprobar_web <- function(reglas, normas, ruta) {
  json <- if (file.exists(ruta)) jsonlite::read_json(ruta) else list()
  r <- json$reglas %||% list()
  ids <- vapply(r, function(x) x$id %||% "", "")
  k <- match(reglas$id, ids)
  distinto <- function(f) sum(vapply(seq_len(nrow(reglas)), function(i) {
    if (is.na(k[i])) return(TRUE)
    !isTRUE(f(reglas[i, ], r[[k[i]]]))
  }, TRUE))
  textos <- function(fila, x) all(vapply(REGLAS_TEXTOS[-1], function(b) {
    identical(unlist(x[[b]]$es) %||% character(), reglas_parrafos(fila[[paste0(b, "_es")]])) &&
      identical(unlist(x[[b]]$en) %||% character(), reglas_parrafos(fila[[paste0(b, "_en")]]))
  }, TRUE))
  reglas_fila("web_reglas", c("res\u00famenes del inventario que no est\u00e1n en el fichero", "res\u00famenes de m\u00e1s en el fichero",
                              "t\u00edtulos u orden distintos", "textos distintos", "normas citadas distintas",
                              "estado o revisi\u00f3n distintos", "normas sin ficha en el fichero"),
              c(sum(is.na(k)), sum(!ids %in% reglas$id),
                distinto(function(f, x) identical(x$titulo$es, f$titulo_es) && identical(x$titulo$en, f$titulo_en) &&
                           identical(as.integer(x$orden), f$orden) && identical(x$ancla, reglas_ancla(f$id))),
                distinto(textos),
                distinto(function(f, x) identical(vapply(x$normas, function(n) paste0(n$norma, if (nzchar(n$bloque)) paste0(":", n$bloque) else ""), ""),
                                                  reglas_refs(f$normas)$ref)),
                distinto(function(f, x) identical(x$estado, f$estado) && identical(x$revisado, f$revisado) &&
                           identical(isTRUE(x$borrador), f$revisado == REGLAS_BORRADOR)),
                sum(!normas$id %in% names(json$normas %||% list()))))
}

# --- Publicacion ---------------------------------------------------------------------------------------

# reglas.json para el release (R/publicar.R): los resumenes en borrador quedan sin texto, solo con su
# id, ancla, orden y titulo, y `en_revision` (la pagina lo dice; las anclas de la portada siguen
# existiendo). Nada en borrador sale en el release ni en el sitio.
reglas_para_publicar <- function(json) {
  json$reglas <- lapply(json$reglas %||% list(), function(r) {
    if (!isTRUE(r$borrador) && !identical(r$revisado, REGLAS_BORRADOR)) return(r)
    list(id = r$id, ancla = r$ancla, orden = r$orden, titulo = r$titulo, en_revision = TRUE)
  })
  json$borradores <- 0L
  json$en_revision <- sum(vapply(json$reglas, function(r) isTRUE(r$en_revision), TRUE))
  json
}

# Resumenes con texto en borrador en un reglas.json (lista ya leida): los que llevan borrador o
# revisado = borrador y algun texto.
reglas_borradores_con_texto <- function(json) {
  sum(vapply(json$reglas %||% list(), function(r) {
    (isTRUE(r$borrador) || identical(r$revisado, REGLAS_BORRADOR)) &&
      any(c("que_dice", "a_quien", "cambios", "en_el_atlas", "normas") %in% names(r))
  }, TRUE))
}
