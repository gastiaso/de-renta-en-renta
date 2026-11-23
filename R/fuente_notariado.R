# Notariado (Consejo General del Notariado): dos fuentes con licencia propia no comercial y solo web
# (decisiones del autor del 19-nov-2026; plan v0.57; docs/especificacion_notariado.md):
#   - notariado: Portal Estadístico (penotariado.com), la capa ArcGIS que alimenta su mapa de
#     precios: compraventas de vivienda de los últimos 12 meses (precio por m², precio medio,
#     superficie media y número), en España, comunidad, provincia, municipio y código postal. Es una
#     foto móvil, sin serie: cada descarga se guarda con su fecha;
#   - notariado_cien: CIEN, «Estadísticas al completo» (notariado.org): series de actos notariales
#     desde 2007. Entran las hipotecas para la compra de vivienda (número y cuantía media), por año,
#     en España, comunidad y provincia.
#
# Licencia: «© Consejo General del Notariado, solo uso no comercial» (LICENCIA_DATOS.md). Como la
# capa de portales (R/fuente_portales.R), las cifras no entran en la tabla larga, ni en las descargas
# CSV, ni en el paquete del release: larga_notariado tiene el formato de la tabla larga, pero solo va
# a web/datos/notariado/ (R/web_notariado.R), y empaquetar_publicacion() comprueba que no se cuela
# (sin_notariado). Nunca se mezclan con Registradores (indicador 11), que mide otra superficie
# (regla 5), ni entre sí: el CIEN no tiene compraventas y penotariado no tiene hipotecas.
#
# Capa desmontable: NOTARIADO=FALSE (variable de entorno) la apaga y la web la lleva apagada
# (notariado_apagar_web()). Por defecto, encendida.
#
# Acceso (comprobado el 19-nov-2026; sin registro ni formularios):
#   - penotariado: GET a PENOTARIADO_URL/<capa>/query con f=json, sin geometría, 2.000 filas por
#     página (maxRecordCount) y paginación con resultOffset; capas 0 España, 1 comunidad, 2 provincia,
#     3 municipio y 4 código postal. Se piden solo las filas de todas las viviendas
#     (PENOTARIADO_FILTRO: todas las construcciones y todas las clases de finca). La fecha de la foto
#     es editingInfo.lastEditDate de la definición de la capa 0 (milisegundos desde 1970, UTC). Su
#     servidor responde con Access-Control-Allow-Origin: * (CORS abierto);
#   - CIEN: POST de formulario a CIEN_DATOS_URL; responde JSON declarado en ISO-8859-1 (se lee en
#     Latin-1 si no es UTF-8 válido). Los territorios llegan por nombre, sin código: se casan con el
#     INE en inventario/notariado_cien_territorios.csv (regla 7). Los ids internos de comunidades y
#     provincias salen de getGeografia del portlet (CIEN_PORTLET_URL). Ceuta y Melilla van juntas
#     como una provincia y dentro de Andalucía. Su servidor no manda cabeceras CORS.
#
# Caché en datos/brutos/ (fuera de git):
#   - datos/brutos/notariado/penotariado/<AAAA-MM-DD>/: una carpeta por foto, con la fecha de la
#     capa 0; capa_<nivel>.csv (atributos tal cual) y definiciones.csv (fechas de cada capa). Si la
#     foto ya está, no se vuelve a pedir; solo se pide la definición de la capa 0 (10 KB) para saber
#     si hay una nueva. Sin red, la foto más reciente, con un aviso;
#   - datos/brutos/notariado_cien/: geografia.json y una consulta por nivel y periodicidad
#     (hipotecas_vivienda_<nivel>_<periodicidad>.json), renovadas a los CIEN_DIAS_RENOVAR días (el
#     CIEN revisa los últimos meses). Si falla, se conserva la anterior y se avisa.

DIR_NOTARIADO <- file.path("datos", "brutos", "notariado", "penotariado")
DIR_NOTARIADO_CIEN <- file.path("datos", "brutos", "notariado_cien")
PENOTARIADO_URL <- "https://services-eu1.arcgis.com/UpPGybwp9RK4YtZj/arcgis/rest/services/PRO_Inmuebles_Datos/FeatureServer"
PENOTARIADO_CAPAS <- c(nacional = 0L, ccaa = 1L, provincia = 2L, municipio = 3L, cp = 4L)
PENOTARIADO_FILTRO <- "tipo_construccion_id=99 AND clase_finca_urbana_id=99"
PENOTARIADO_PAGINA <- 2000L
# Campo del código del territorio en cada capa (España no lleva) y largo del código del INE
PENOTARIADO_CODIGO <- c(nacional = NA, ccaa = "cod_ccaa", provincia = "cod_prov", municipio = "cod_muni", cp = "cp")
PENOTARIADO_NOMBRE <- c(nacional = NA, ccaa = "name_ccaa", provincia = "name_prov", municipio = "name_muni", cp = NA)
PENOTARIADO_LARGO <- c(nacional = 2L, ccaa = 2L, provincia = 2L, municipio = 5L, cp = 5L)
# Campos de las cifras (los nombres han cambiado alguna vez: si falta alguno, se detiene y lo dice)
PENOTARIADO_CIFRAS <- c("precio_m2", "precio_medio", "superficie_media", "total", "total_informados", "es_estimado")
# Umbral de fiabilidad: sin precio (estado secreto) con menos de 20 compraventas con precio y
# superficie informados en los 12 meses. El número de compraventas se publica siempre.
NOTARIADO_MIN_INFORMADAS <- 20L

CIEN_DATOS_URL <- "https://www.notariado.org/cienServices/service/buscador/json"
CIEN_PORTLET_URL <- paste0("https://www.notariado.org/liferay/web/cien/estadisticas-al-completo?",
                           "p_p_id=CIEN002_WAR_cienEstadisticaPlugin_INSTANCE_O1Sc&p_p_lifecycle=2&p_p_state=normal",
                           "&p_p_mode=view&p_p_cacheability=cacheLevelPage&p_p_col_id=column-1&p_p_col_count=1")
# Serie: 1203, hipoteca inmobiliaria, subcategoría «Adquisición de vivienda» (finalidad 1, otras
# categorías 3); variables 12 (número de actos) y 7 (cuantía promedio). Como la pide la web del CIEN.
CIEN_HIPOTECAS <- list(actos = "1203,1203,1203", tabla = "SOLREC_ACTOS_PRESTAMOS", variables = "12,7",
                       fpid = "1,1", ocpid = "3")
CIEN_GEOGRAFIA <- c(nacional = "04", ccaa = "01", provincia = "05")
CIEN_TEMPORAL <- c(anual = "01", mensual = "02")
# Consultas: el año por nivel y, en España, también el mes (para el último mes publicado y la
# compuerta de los meses frente al año)
CIEN_CONSULTAS <- data.frame(nivel = c("nacional", "ccaa", "provincia", "nacional"),
                             periodicidad = c("anual", "anual", "anual", "mensual"))
CIEN_DESDE <- "01/01/2007"
CIEN_DIAS_RENOVAR <- 30
# Compuerta notariado_cien_espana: hipotecas para compra de vivienda de España en 2025, consulta
# del CIEN del 19-nov-2026
CIEN_REFERENCIA_ESPANA <- c("2025" = 385194)

# ---- Descarga ------------------------------------------------------------------------------------

notariado_agente <- function(req) httr2::req_user_agent(req, "Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)")

# GET a la capa ArcGIS: la lista que devuelve (JSON). Las pruebas pasan su propia función `pedir`.
penotariado_pedir <- function(url, consulta = list()) {
  j <- httr2::request(url) |>
    notariado_agente() |>
    httr2::req_url_query(!!!consulta) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(120) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  if (!is.null(j$error)) stop("ArcGIS (", url, "): ", j$error$message %||% "error", call. = FALSE)
  j
}

# Fecha de la foto: editingInfo.lastEditDate de una definición de capa, como Date (UTC).
penotariado_fecha <- function(definicion) {
  ms <- definicion$editingInfo$lastEditDate %||% NA_real_
  as.Date(as.POSIXct(as.numeric(ms) / 1000, origin = "1970-01-01", tz = "UTC"))
}

# Todas las filas de una capa con el filtro, por páginas: un data.frame con los atributos.
penotariado_capa <- function(capa, pedir = penotariado_pedir, url = PENOTARIADO_URL, where = PENOTARIADO_FILTRO,
                             pagina = PENOTARIADO_PAGINA) {
  filas <- list()
  desde <- 0L
  repeat {
    j <- pedir(paste0(url, "/", capa, "/query"),
               list(f = "json", where = where, returnGeometry = "false", outFields = "*",
                    orderByFields = "OBJECTID", resultRecordCount = pagina, resultOffset = desde))
    atributos <- lapply(j$features, `[[`, "attributes")
    filas <- c(filas, atributos)
    desde <- desde + length(atributos)
    if (length(atributos) < pagina && !isTRUE(j$exceededTransferLimit)) break
    if (!length(atributos)) break
  }
  if (!length(filas)) return(data.frame())
  nombres <- unique(unlist(lapply(filas, names)))
  as.data.frame(stats::setNames(lapply(nombres, function(n) {
    v <- lapply(filas, function(a) a[[n]] %||% NA)
    if (all(vapply(v, function(x) is.numeric(x) || is.na(x), TRUE))) as.numeric(unlist(v)) else as.character(unlist(v))
  }), nombres), stringsAsFactors = FALSE)
}

# Ficheros de una foto en su carpeta, en el orden de PENOTARIADO_CAPAS, con definiciones.csv al final.
penotariado_ficheros <- function(carpeta) {
  file.path(carpeta, c(paste0("capa_", names(PENOTARIADO_CAPAS), ".csv"), "definiciones.csv"))
}

# Descarga de la foto vigente (si no está ya en la caché). Devuelve sus ficheros.
descargar_penotariado <- function(dir = DIR_NOTARIADO, forzar = FALSE, pedir = penotariado_pedir, url = PENOTARIADO_URL) {
  definiciones <- tryCatch(lapply(PENOTARIADO_CAPAS, function(capa) pedir(paste0(url, "/", capa), list(f = "json"))),
                           error = function(e) e)
  previas <- sort(list.dirs(dir, recursive = FALSE, full.names = TRUE))
  previas <- previas[grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", basename(previas)) &
                       vapply(previas, function(p) all(file.exists(penotariado_ficheros(p))), TRUE)]
  if (inherits(definiciones, "error")) {
    if (length(previas)) {
      warning("Falla la consulta del Portal Estadístico del Notariado: se usa la foto de ", basename(utils::tail(previas, 1)),
              "\n  ", conditionMessage(definiciones), call. = FALSE)
      return(penotariado_ficheros(utils::tail(previas, 1)))
    }
    stop("No se ha podido consultar ", url, "\n  ", conditionMessage(definiciones), call. = FALSE)
  }
  fecha <- penotariado_fecha(definiciones[["nacional"]])
  if (is.na(fecha)) stop("La capa 0 del Notariado no trae editingInfo.lastEditDate: ¿ha cambiado el servicio?", call. = FALSE)
  carpeta <- file.path(dir, format(fecha))
  ficheros <- penotariado_ficheros(carpeta)
  # Fecha de la última consulta, aunque la foto no sea nueva: el calendario de fuentes
  # (cal_ultima_descarga()) toma la fecha más reciente de esta carpeta y, sin ella, daría la fuente por
  # pendiente cada día hasta la foto siguiente. No va en lo que devuelve: no rehace nada.
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(format(Sys.Date()), file.path(dir, "ultima_consulta.txt"))
  if (all(file.exists(ficheros)) && !forzar) return(ficheros)

  dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
  parciales <- paste0(ficheros, ".parcial")
  on.exit(unlink(parciales), add = TRUE)
  for (k in seq_along(PENOTARIADO_CAPAS)) {
    x <- penotariado_capa(PENOTARIADO_CAPAS[[k]], pedir = pedir, url = url)
    readr::write_csv(x, parciales[k], na = "")
  }
  fechas <- function(d, campo) {
    ms <- d$editingInfo[[campo]] %||% NA_real_
    format(as.POSIXct(as.numeric(ms) / 1000, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
  }
  readr::write_csv(data.frame(
    nivel = names(PENOTARIADO_CAPAS), capa = unname(PENOTARIADO_CAPAS),
    nombre = vapply(definiciones, function(d) as.character(d$name %||% NA), ""),
    ultima_edicion = vapply(definiciones, fechas, "", campo = "lastEditDate"),
    ultima_edicion_datos = vapply(definiciones, fechas, "", campo = "dataLastEditDate"),
    campos = vapply(definiciones, function(d) paste(vapply(d$fields, `[[`, "", "name"), collapse = ";"), "")
  ), parciales[length(parciales)], na = "")
  for (k in seq_along(ficheros)) {
    if (file.exists(ficheros[k])) unlink(ficheros[k])
    if (!file.rename(parciales[k], ficheros[k])) stop("No se ha podido mover la descarga a ", ficheros[k], call. = FALSE)
  }
  ficheros
}

# POST de formulario al CIEN: el cuerpo en bruto (para guardarlo tal cual).
cien_pedir <- function(url, campos = list()) {
  req <- httr2::request(url) |> notariado_agente() |> httr2::req_retry(max_tries = 3) |> httr2::req_timeout(300)
  req <- if (length(campos)) httr2::req_body_form(req, !!!campos) else httr2::req_method(req, "POST")
  httr2::req_perform(req) |> httr2::resp_body_raw()
}

# Texto de una respuesta del CIEN: UTF-8 si lo es; si no, Latin-1 (buscador/json va en ISO-8859-1).
cien_texto <- function(bruto) {
  txt <- rawToChar(bruto)
  Encoding(txt) <- "UTF-8"
  if (!validUTF8(txt)) txt <- iconv(rawToChar(bruto), "latin1", "UTF-8")
  txt
}
cien_json <- function(ruta) jsonlite::fromJSON(cien_texto(readBin(ruta, "raw", file.size(ruta))), simplifyVector = FALSE)

# Ids internos de comunidades y provincias del árbol de getGeografia (no son los del INE).
cien_ids_geografia <- function(geografia) {
  cc <- integer(); pp <- integer()
  recorrer <- function(nodos) for (x in nodos) {
    cc <<- c(cc, as.integer(x$ccaa_id %||% 0L)); pp <<- c(pp, as.integer(x$prov_id %||% 0L))
    if (!is.null(x$children)) recorrer(x$children)
  }
  recorrer(geografia)
  list(ccaa = sort(unique(cc[cc > 0])), provincia = sort(unique(pp[pp > 0])))
}

cien_fichero <- function(dir, nivel, periodicidad) file.path(dir, sprintf("hipotecas_vivienda_%s_%s.json", nivel, periodicidad))

# Campos de una consulta de hipotecas para compra de vivienda, de enero de 2007 al mes `hasta`.
cien_campos <- function(nivel, periodicidad, ids, hasta = Sys.Date()) {
  c(CIEN_HIPOTECAS, list(
    geografia = CIEN_GEOGRAFIA[[nivel]],
    ccaaid = if (nivel == "ccaa") paste(ids$ccaa, collapse = ",") else "",
    provid = if (nivel == "provincia") paste(ids$provincia, collapse = ",") else "",
    munid = "", distid = "", temporal = CIEN_TEMPORAL[[periodicidad]],
    fechaInicio = CIEN_DESDE, fechaFin = format(as.Date(hasta), "01/%m/%Y")))
}

# Descarga del CIEN con caché (renovada a los `max_dias`). Devuelve los ficheros de las consultas,
# en el orden de CIEN_CONSULTAS, y geografia.json al final.
descargar_notariado_cien <- function(dir = DIR_NOTARIADO_CIEN, forzar = FALSE, pedir = cien_pedir,
                                     max_dias = CIEN_DIAS_RENOVAR, hasta = Sys.Date()) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  geo <- file.path(dir, "geografia.json")
  consultas <- cien_fichero(dir, CIEN_CONSULTAS$nivel, CIEN_CONSULTAS$periodicidad)
  todos <- c(consultas, geo)
  caducado <- function(f) !file.exists(f) || forzar || feed_caducado(f, max_dias)
  if (!any(vapply(todos, caducado, TRUE))) return(todos)
  guardar <- function(destino, url, campos) {
    cuerpo <- tryCatch(pedir(url, campos), error = function(e) e)
    # Una página web con estado 200 (mantenimiento, otra dirección) no se guarda encima de la anterior
    # (revisión del 23-nov-2026): lo que no es JSON cuenta como un fallo
    if (!inherits(cuerpo, "error") && length(cuerpo) &&
        !tryCatch(isTRUE(jsonlite::validate(cien_texto(cuerpo))), error = function(e) FALSE)) {
      cuerpo <- simpleError("la respuesta no es JSON (¿una página web?)")
    }
    if (inherits(cuerpo, "error") || !length(cuerpo)) {
      motivo <- if (inherits(cuerpo, "error")) conditionMessage(cuerpo) else "respuesta vacía"
      if (file.exists(destino)) {
        warning("Falla la consulta del CIEN (", basename(destino), "): se conserva la anterior\n  ", motivo, call. = FALSE)
        return(destino)
      }
      stop("No se ha podido consultar el CIEN (", basename(destino), ")\n  ", motivo, call. = FALSE)
    }
    parcial <- paste0(destino, ".parcial")
    on.exit(unlink(parcial), add = TRUE)
    writeBin(cuerpo, parcial)
    if (file.exists(destino)) unlink(destino)
    if (!file.rename(parcial, destino)) stop("No se ha podido mover la descarga a ", destino, call. = FALSE)
    destino
  }
  if (caducado(geo)) guardar(geo, paste0(CIEN_PORTLET_URL, "&method=getGeografia"), list())
  ids <- cien_ids_geografia(cien_json(geo))
  for (k in seq_len(nrow(CIEN_CONSULTAS))) {
    if (!caducado(consultas[k])) next
    guardar(consultas[k], CIEN_DATOS_URL, cien_campos(CIEN_CONSULTAS$nivel[k], CIEN_CONSULTAS$periodicidad[k], ids, hasta))
  }
  todos
}

# ---- Lectura -------------------------------------------------------------------------------------

# Una foto de penotariado: list(filas, definiciones, fecha). `filas`: nivel (nacional, ccaa,
# provincia, municipio, cp), geo_id (código del INE con ceros; España, «00»; código postal, 5
# cifras), nombre, las cifras de PENOTARIADO_CIFRAS y fecha (la de la foto). Se detiene si a una
# capa le falta un campo.
leer_penotariado <- function(rutas) {
  carpeta <- unique(dirname(rutas))
  if (length(carpeta) != 1) stop("Las rutas del Notariado deben ser de una sola foto", call. = FALSE)
  fecha <- as.Date(basename(carpeta))
  definiciones <- readr::read_csv(file.path(carpeta, "definiciones.csv"), col_types = readr::cols(.default = "c"),
                                  progress = FALSE)
  filas <- lapply(names(PENOTARIADO_CAPAS), function(nivel) {
    x <- readr::read_csv(file.path(carpeta, paste0("capa_", nivel, ".csv")), col_types = readr::cols(.default = "c"),
                         na = "", progress = FALSE)
    codigo <- PENOTARIADO_CODIGO[[nivel]]
    nombre <- PENOTARIADO_NOMBRE[[nivel]]
    falta <- setdiff(c(PENOTARIADO_CIFRAS, stats::na.omit(c(codigo, nombre))), names(x))
    if (length(falta)) {
      stop("Notariado, capa ", nivel, ": faltan los campos ", paste(falta, collapse = ", "), " (hay ",
           paste(names(x), collapse = ", "), "). ¿Han cambiado los nombres en el servicio?", call. = FALSE)
    }
    geo <- if (is.na(codigo)) rep("00", nrow(x)) else con_ceros(trimws(x[[codigo]]), PENOTARIADO_LARGO[[nivel]])
    tibble::tibble(nivel = nivel, geo_id = geo,
                   nombre = if (is.na(nombre)) NA_character_ else x[[nombre]],
                   precio_m2 = as.numeric(x$precio_m2), precio_medio = as.numeric(x$precio_medio),
                   superficie_media = as.numeric(x$superficie_media), total = as.numeric(x$total),
                   total_informados = as.numeric(x$total_informados), es_estimado = as.integer(x$es_estimado),
                   fecha = fecha)
  })
  list(filas = dplyr::bind_rows(filas), definiciones = definiciones, fecha = fecha)
}

# Correspondencia de los territorios del CIEN con el INE (regla 7).
leer_notariado_cien_territorios <- function(ruta = file.path("inventario", "notariado_cien_territorios.csv")) {
  readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = "", locale = readr::locale(encoding = "UTF-8"),
                  progress = FALSE)
}

# Valor de una variable de una fila del CIEN: número, o NA si es «ND» (no disponible) o no viene.
cien_valor <- function(fila, id) {
  v <- Filter(function(x) identical(as.character(x$ID), id), fila$VARIABLES)
  if (!length(v)) return(NA_real_)
  v <- v[[1]]$VALOR
  if (is.null(v) || identical(v, "ND")) NA_real_ else suppressWarnings(as.numeric(v))
}

# Consultas del CIEN en una tabla: nivel, periodicidad, comunidad y nombre en el CIEN, geo_id (de la
# correspondencia; NA si no tiene código), anio, mes (NA en las anuales), n (número de hipotecas),
# n_nd (TRUE si el CIEN lo da como «ND»), cuantia (€) y n_cuantia (hipotecas con cuantía informada,
# el campo CALCD…: pesa la cuantía al agregar). Se detiene si el «total» de una consulta no es su
# número de filas (descarga cortada).
leer_notariado_cien <- function(rutas, territorios_cien) {
  consultas <- rutas[grepl("^hipotecas_vivienda_", basename(rutas))]
  dplyr::bind_rows(lapply(consultas, function(ruta) {
    b <- basename(ruta)
    patron <- "^hipotecas_vivienda_([a-z]+)_(anual|mensual)[.]json$"
    if (!grepl(patron, b)) stop("CIEN: fichero con un nombre inesperado, ", b, call. = FALSE)
    nivel <- sub(patron, "\\1", b)
    periodicidad <- sub(patron, "\\2", b)
    j <- cien_json(ruta)
    datos <- j$datos %||% list()
    if (!identical(as.integer(j$total %||% -1L), length(datos))) {
      stop("CIEN, ", basename(ruta), ": el total (", j$total %||% "?", ") no es el número de filas (", length(datos),
           "). ¿Descarga cortada?", call. = FALSE)
    }
    if (!length(datos)) stop("CIEN, ", basename(ruta), ": sin filas. ¿Fechas o filtros fuera de rango?", call. = FALSE)
    texto <- function(f, campo) as.character(f[[campo]] %||% NA_character_)
    calcd <- function(f) {
      campo <- grep("^CALCD", names(f), value = TRUE)
      if (length(campo)) as.numeric(f[[campo[1]]]) else NA_real_
    }
    # (fuera de tibble(): dentro, `nivel` y `periodicidad` serían ya las columnas recicladas)
    nombre_cien <- if (nivel == "nacional") rep("España", length(datos)) else
      vapply(datos, texto, "", campo = if (nivel == "ccaa") "COMUNIDADDESC" else "PROVINCIADESC")
    mes <- if (periodicidad == "mensual") as.integer(vapply(datos, texto, "", campo = "MES")) else NA_integer_
    x <- tibble::tibble(
      nivel = nivel, periodicidad = periodicidad,
      comunidad_cien = vapply(datos, texto, "", campo = "COMUNIDADDESC"),
      nombre_cien = nombre_cien,
      anio = as.integer(vapply(datos, texto, "", campo = "ANO")),
      mes = mes,
      n = vapply(datos, cien_valor, 0, id = "12"),
      n_nd = vapply(datos, function(f) identical(Filter(function(v) identical(as.character(v$ID), "12"), f$VARIABLES)[[1]]$VALOR, "ND"), TRUE),
      cuantia = vapply(datos, cien_valor, 0, id = "7"),
      n_cuantia = vapply(datos, calcd, 0)
    )
    t <- territorios_cien[territorios_cien$nivel == nivel, ]
    x$geo_id <- if (nivel == "nacional") "00" else t$geo_id[match(x$nombre_cien, t$nombre_cien)]
    x$casado <- nivel == "nacional" | x$nombre_cien %in% t$nombre_cien
    x
  }))
}

# Último mes publicado por el CIEN (España, mensual), «AAAA-MM».
cien_ultimo_mes <- function(cien) {
  m <- cien[cien$nivel == "nacional" & cien$periodicidad == "mensual" & !is.na(cien$n), ]
  if (!nrow(m)) return(NA_character_)
  u <- m[order(m$anio, m$mes), ][nrow(m), ]
  sprintf("%d-%02d", u$anio, u$mes)
}

# Años completos del CIEN: los que tienen los doce meses de España publicados.
cien_anios_completos <- function(cien) {
  m <- cien[cien$nivel == "nacional" & cien$periodicidad == "mensual" & !is.na(cien$n), ]
  meses <- tapply(m$mes, m$anio, function(x) length(unique(x)))
  sort(as.integer(names(meses)[meses == 12]))
}

# ---- Compuertas ----------------------------------------------------------------------------------

# Compuerta de penotariado (inventario/referencias_validacion.csv):
#   notariado_niveles: territorios por nivel distintos de los esperados (1 España, 19 comunidades,
#     52 provincias) y municipios y códigos postales sin filas;
#   notariado_codigos: códigos repetidos en un nivel, y códigos de comunidad o provincia fuera del
#     seccionado de 2021 (bloqueo); notariado_municipios: municipios fuera del seccionado de 2021
#     (alerta: no se pueden pintar);
#   notariado_suma: desviación (%) de la suma de las compraventas de las comunidades frente a España,
#     y la mayor de las provincias frente a su comunidad; notariado_suma_municipios: la mayor de los
#     municipios por encima de su provincia (un municipio sin compraventas no sale, así que la suma
#     puede quedar por debajo, nunca por encima);
#   notariado_identidad: filas publicables (20 o más informadas) en que el precio por m² × la
#     superficie media no da el precio medio (±1 %);
#   notariado_rango: precios por m² publicables fuera de 50–20.000 €, informadas por encima del total
#     o cifras negativas;
#   notariado_foto: días entre la fecha más antigua y la más reciente de las cinco capas (una foto
#     a medias mezclaría dos meses), y antigüedad de la foto (alerta).
comprobar_penotariado <- function(pen, territorios, hoy = Sys.Date(), esperados = c(nacional = 1, ccaa = 19, provincia = 52)) {
  fila <- function(id, detalle, calculado, referencia = 0) {
    tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = as.numeric(referencia))
  }
  f <- pen$filas
  n <- table(factor(f$nivel, levels = names(PENOTARIADO_CAPAS)))
  esperado <- esperados
  conocidos <- paste(territorios$nivel, territorios$codigo)
  ine <- f[f$nivel %in% c("ccaa", "provincia"), ]
  mun <- f[f$nivel == "municipio", ]
  total <- function(nivel, codigo = NULL) {
    x <- f[f$nivel == nivel, ]
    if (!is.null(codigo)) x <- x[x$geo_id == codigo, ]
    sum(x$total, na.rm = TRUE)
  }
  espana <- total("nacional")
  dev <- function(a, b) if (is.na(b) || b == 0) NA_real_ else 100 * (a - b) / b
  ccaa_de <- territorios$superior[territorios$nivel == "provincia"]
  names(ccaa_de) <- territorios$codigo[territorios$nivel == "provincia"]
  prov <- f[f$nivel == "provincia", ]
  por_ccaa <- tapply(prov$total, ccaa_de[prov$geo_id], sum)
  dev_prov <- vapply(names(por_ccaa), function(cc) abs(dev(por_ccaa[[cc]], total("ccaa", cc))), 0)
  mun$provincia <- substr(mun$geo_id, 1, 2)
  por_prov <- tapply(mun$total, mun$provincia, sum)
  dev_mun <- vapply(names(por_prov), function(p) dev(por_prov[[p]], total("provincia", p)), 0)
  publicable <- f$nivel != "cp" & !is.na(f$total_informados) & f$total_informados >= NOTARIADO_MIN_INFORMADAS
  identidad <- abs(f$precio_m2 * f$superficie_media / f$precio_medio - 1)
  fechas <- as.Date(substr(pen$definiciones$ultima_edicion_datos, 1, 10))
  dplyr::bind_rows(
    fila("notariado_niveles", paste("territorios:", names(esperado)), abs(as.numeric(n[names(esperado)]) - esperado)),
    fila("notariado_niveles", "niveles de municipio o código postal sin filas", sum(n[c("municipio", "cp")] == 0)),
    fila("notariado_codigos", "códigos repetidos en un nivel", sum(duplicated(f[c("nivel", "geo_id")]))),
    fila("notariado_codigos", "comunidades y provincias fuera del seccionado de 2021",
         sum(!paste(ine$nivel, ine$geo_id) %in% conocidos)),
    fila("notariado_municipios", "municipios fuera del seccionado de 2021", sum(!paste("municipio", mun$geo_id) %in% conocidos)),
    fila("notariado_suma", "compraventas: comunidades frente a España (%)", abs(dev(total("ccaa"), espana))),
    fila("notariado_suma", "compraventas: provincias frente a su comunidad, la mayor desviación (%)",
         if (length(dev_prov)) max(dev_prov, na.rm = TRUE) else NA_real_),
    fila("notariado_suma_municipios", "compraventas: municipios por encima de su provincia, la mayor (%)",
         max(c(0, dev_mun), na.rm = TRUE)),
    fila("notariado_identidad", "precio por m² × superficie frente al precio medio, fuera de ±1 %",
         sum(publicable & (is.na(identidad) | identidad > 0.01))),
    fila("notariado_rango", "precios por m² publicables fuera de 50–20.000 €",
         sum(publicable & (is.na(f$precio_m2) | f$precio_m2 < 50 | f$precio_m2 > 20000))),
    fila("notariado_rango", "informadas por encima del total o cifras negativas",
         sum(f$total_informados > f$total | f$total < 0 | f$precio_m2 < 0 | f$precio_medio < 0, na.rm = TRUE)),
    fila("notariado_foto", "días entre las fechas de las cinco capas", as.numeric(diff(range(fechas)))),
    fila("notariado_foto_antiguedad", "días desde la foto", as.numeric(hoy - pen$fecha))
  )
}

# Compuerta del CIEN (inventario/referencias_validacion.csv):
#   notariado_cien_territorios: nombres sin fila en la correspondencia y filas repetidas;
#   notariado_cien_suma_ccaa: por año, hipotecas de las 17 comunidades del CIEN menos las de España;
#   notariado_cien_suma_provincias: por año, comunidades cuya suma de provincias no es la suya (con
#     Ceuta y Melilla dentro de Andalucía, como las da el CIEN);
#   notariado_cien_meses: por año completo, la suma de los meses de España menos el año;
#   notariado_cien_espana: España en 2025 frente a CIEN_REFERENCIA_ESPANA;
#   notariado_cien_cuantia: por año, la mayor desviación (%) de la cuantía media de una comunidad
#     frente a la media de sus provincias ponderada por las hipotecas con cuantía (bloqueo: sostiene
#     la cuantía de Andalucía sin Ceuta y Melilla, que el atlas calcula así);
#   notariado_cien_rango: cuantías fuera de 20.000–1.000.000 € y números negativos.
comprobar_notariado_cien <- function(cien, referencia = CIEN_REFERENCIA_ESPANA) {
  fila <- function(id, detalle, calculado, referencia = 0, anio = NA_integer_) {
    tibble::tibble(id = id, anio = as.integer(anio), detalle = detalle, calculado = as.numeric(calculado),
                   referencia = as.numeric(referencia))
  }
  a <- cien[cien$periodicidad == "anual", ]
  esp <- a[a$nivel == "nacional", ]
  cc <- a[a$nivel == "ccaa", ]
  pr <- a[a$nivel == "provincia", ]
  anios <- sort(unique(esp$anio))
  suma_ccaa <- vapply(anios, function(y) sum(cc$n[cc$anio == y], na.rm = TRUE) - sum(esp$n[esp$anio == y], na.rm = TRUE), 0)
  suma_prov <- vapply(anios, function(y) {
    p <- pr[pr$anio == y & !pr$n_nd, ]
    s <- tapply(p$n, p$comunidad_cien, sum)
    c_y <- cc[cc$anio == y, ]
    sum(abs(s[c_y$comunidad_cien] - c_y$n) > 0, na.rm = TRUE)
  }, 0)
  completos <- cien_anios_completos(cien)
  mes <- cien[cien$nivel == "nacional" & cien$periodicidad == "mensual", ]
  meses <- vapply(completos, function(y) sum(mes$n[mes$anio == y]) - sum(esp$n[esp$anio == y]), 0)
  cuantia <- vapply(anios, function(y) {
    p <- pr[pr$anio == y & !is.na(pr$cuantia) & !is.na(pr$n_cuantia), ]
    pond <- tapply(p$cuantia * p$n_cuantia, p$comunidad_cien, sum) / tapply(p$n_cuantia, p$comunidad_cien, sum)
    c_y <- cc[cc$anio == y & !is.na(cc$cuantia), ]
    d <- 100 * abs(pond[c_y$comunidad_cien] / c_y$cuantia - 1)
    if (all(is.na(d))) NA_real_ else max(d, na.rm = TRUE)
  }, 0)
  ref <- esp$n[match(as.integer(names(referencia)), esp$anio)]
  dplyr::bind_rows(
    fila("notariado_cien_territorios", "nombres sin fila en inventario/notariado_cien_territorios.csv", sum(!cien$casado)),
    fila("notariado_cien_territorios", "filas repetidas",
         sum(duplicated(cien[c("nivel", "periodicidad", "nombre_cien", "anio", "mes")]))),
    fila("notariado_cien_suma_ccaa", "hipotecas: comunidades menos España", suma_ccaa, anio = anios),
    fila("notariado_cien_suma_provincias", "comunidades cuya suma de provincias no cuadra", suma_prov, anio = anios),
    if (length(completos)) fila("notariado_cien_meses", "hipotecas: meses de España menos el año", meses, anio = completos),
    fila("notariado_cien_espana", "hipotecas para compra de vivienda, España", ref, referencia, anio = as.integer(names(referencia))),
    fila("notariado_cien_cuantia", "cuantía media de una comunidad frente a sus provincias ponderadas (%)", cuantia, anio = anios),
    fila("notariado_cien_rango", "cuantías fuera de 20.000–1.000.000 € o números negativos",
         sum(cien$cuantia < 20000 | cien$cuantia > 1e6 | cien$n < 0, na.rm = TRUE))
  )
}

# Coherencia con otra fuente (alertas; inventario/referencias_validacion.csv): la foto de
# penotariado frente a las transacciones inmobiliarias del MIVAU (mivau_transacciones), que salen
# de las mismas escrituras. Del MIVAU se toman los `n_trimestres` últimos trimestres con cifra
# cerrados antes de la foto:
#   notariado_mivau_espana: desviación (%) del precio medio por compraventa de España frente a la
#     media del valor medio de las compraventas de vivienda libre (tabla 34020150);
#   notariado_mivau_provincias: provincias con precio publicable cuya desviación pasa de
#     `margen_provincia` (%) o que no tienen los trimestres del MIVAU;
#   notariado_mivau_compraventas y notariado_mivau_compraventas_provincias (con `numero_trimestral`,
#     tabla 34010110): lo mismo con el número de compraventas de los 12 meses frente a la suma de
#     los trimestres.
# Las cifras no miden lo mismo: la foto son 12 meses móviles de todas las viviendas y el MIVAU va
# unos meses por detrás (y su valor medio es el de la vivienda libre). Son avisos de nivel (unidades,
# una foto de otra clase de fincas o recortada por un filtro), no indicadores: no mezclan fuentes
# (regla 5). Sin trimestres del MIVAU, NA (la alerta salta).
comprobar_notariado_mivau <- function(pen, transacciones_trimestral, numero_trimestral = NULL, n_trimestres = 4L,
                                      margen_provincia = 25) {
  # Agregado de los últimos trimestres por territorio (NA si no están todos) y el periodo de España
  ultimos <- function(trim, agregar) {
    fin <- as.Date(sprintf("%d-%02d-01", trim$anio, 3L * trim$trimestre)) + 31
    fin <- as.Date(format(fin, "%Y-%m-01")) - 1                     # último día del trimestre
    t <- trim[fin <= pen$fecha & !is.na(trim$valor) & trim$nivel %in% c("nacional", "provincia"), ]
    t <- t[order(t$nivel, t$geo_id, t$anio, t$trimestre), ]
    clave <- paste(t$nivel, t$geo_id)
    orden <- stats::ave(seq_along(clave), clave, FUN = function(i) rev(seq_along(i)))   # 1 = el más reciente
    t <- t[orden <= n_trimestres, ]
    esp <- t[t$nivel == "nacional", ]
    list(valor = tapply(t$valor, paste(t$nivel, t$geo_id), function(v) if (length(v) == n_trimestres) agregar(v) else NA_real_),
         periodo = if (nrow(esp)) sprintf("%d-T%d a %d-T%d", esp$anio[1], esp$trimestre[1], esp$anio[nrow(esp)],
                                          esp$trimestre[nrow(esp)]) else "sin trimestres")
  }
  anio <- as.integer(format(pen$fecha, "%Y"))
  contraste <- function(ids, f, cifra, mivau, espana, provincias) {
    dev <- 100 * (cifra / unname(mivau$valor[paste(f$nivel, f$geo_id)]) - 1)
    nac <- f$nivel == "nacional"
    fuera <- !nac & (is.na(dev) | abs(dev) > margen_provincia)
    tibble::tibble(
      id = ids, anio = anio,
      detalle = c(sprintf("%s de %s (%%)", espana, mivau$periodo),
                  sprintf("provincias fuera de ±%s %% %s de %s%s", format(margen_provincia), provincias, mivau$periodo,
                          if (any(fuera)) paste0(": ", paste(sort(f$geo_id[fuera]), collapse = ", ")) else "")),
      calculado = c(if (any(nac)) dev[nac][1] else NA_real_, sum(fuera)),
      referencia = 0)
  }
  f <- pen$filas[pen$filas$nivel %in% c("nacional", "provincia"), ]
  publicable <- f[!is.na(f$total_informados) & f$total_informados >= NOTARIADO_MIN_INFORMADAS, ]
  dplyr::bind_rows(
    contraste(c("notariado_mivau_espana", "notariado_mivau_provincias"), publicable, publicable$precio_medio,
              ultimos(transacciones_trimestral, mean),
              "precio medio por compraventa de España frente al valor medio del MIVAU", "del valor medio del MIVAU"),
    if (!is.null(numero_trimestral)) {
      contraste(c("notariado_mivau_compraventas", "notariado_mivau_compraventas_provincias"), f, f$total,
                ultimos(numero_trimestral, sum),
                "compraventas de España frente a las del MIVAU", "de las compraventas del MIVAU")
    }
  )
}

# ---- Armonización (formato de la tabla larga, fuera de ella) -------------------------------------

# Penotariado en el formato de la tabla larga: España, comunidad, provincia y municipio (el código
# postal no: no es un nivel del atlas), en el año de la foto. Indicadores 25 (precio por m²), 26
# (precio medio por compraventa) y 27 (compraventas en los 12 meses). Precios con menos de
# NOTARIADO_MIN_INFORMADAS compraventas informadas: secreto; con es_estimado, estimado. Municipios
# fuera del seccionado de 2021: fuera (la compuerta los cuenta).
armonizar_penotariado <- function(pen, territorios, version = format(pen$fecha)) {
  f <- pen$filas[pen$filas$nivel %in% c("nacional", "ccaa", "provincia", "municipio"), ]
  f <- f[f$nivel == "nacional" | paste(f$nivel, f$geo_id) %in% paste(territorios$nivel, territorios$codigo), ]
  anio <- as.integer(format(pen$fecha, "%Y"))
  fiable <- !is.na(f$total_informados) & f$total_informados >= NOTARIADO_MIN_INFORMADAS
  estado_precio <- ifelse(!fiable, "secreto", ifelse(f$es_estimado %in% 1L, "estimado", "dato"))
  base <- function(indicador, valor, estado) {
    tibble::tibble(geo_id = f$geo_id, nivel = f$nivel, anio = anio, indicador = indicador, corte = "total",
                   grupo = "total", valor = ifelse(estado %in% c("dato", "estimado"), valor, NA_real_), estado = estado,
                   fuente = "notariado", geo_ref = "2021", version = version)
  }
  dplyr::bind_rows(
    base("precio_escriturado_m2", f$precio_m2, estado_precio),
    base("precio_escriturado_vivienda", f$precio_medio, estado_precio),
    base("compraventas_notariado", f$total, ifelse(is.na(f$total), "ausente", "dato"))
  ) |>
    dplyr::arrange(indicador, nivel, geo_id)
}

# CIEN en el formato de la tabla larga: años completos (cien_anios_completos()), España, comunidad y
# provincia. Indicadores 28 (hipotecas para compra de vivienda) y 29 (su cuantía media). «ND»:
# secreto. Ceuta y Melilla (una sola provincia en el CIEN) quedan sin código y fuera: las provincias
# 51 y 52 y las comunidades 18 y 19, sin dato. Andalucía (01): el CIEN la da con Ceuta y Melilla, así
# que sale de sus ocho provincias: el número, la suma; la cuantía, la media ponderada por las
# hipotecas con cuantía, que reproduce la media publicada de cada comunidad (compuerta de bloqueo
# notariado_cien_cuantia, ±0,01 %): las dos, dato (regla 1: suma y media ponderada). Lo mismo con
# cualquier comunidad que la correspondencia deje sin código.
armonizar_notariado_cien <- function(cien, territorios, version = format(Sys.Date()), anios = cien_anios_completos(cien)) {
  a <- cien[cien$periodicidad == "anual" & cien$anio %in% anios & !is.na(cien$geo_id), ]
  directo <- a |>
    dplyr::transmute(geo_id, nivel, anio, n, n_nd, cuantia, estado_n = ifelse(n_nd | is.na(n), "secreto", "dato"),
                     estado_c = ifelse(is.na(cuantia), "secreto", "dato"))
  # Comunidades sin cifra propia: la suma de sus provincias, si están todas
  prov_ine <- territorios[territorios$nivel == "provincia", ]
  sin_cifra <- setdiff(territorios$codigo[territorios$nivel == "ccaa"], directo$geo_id[directo$nivel == "ccaa"])
  p <- a[a$nivel == "provincia", ]
  p$ccaa <- prov_ine$superior[match(p$geo_id, prov_ine$codigo)]
  sumadas <- dplyr::bind_rows(lapply(sin_cifra, function(cc) {
    hijas <- prov_ine$codigo[prov_ine$superior == cc]
    x <- p[p$ccaa %in% cc, ]
    dplyr::bind_rows(lapply(anios, function(y) {
      x_y <- x[x$anio == y, ]
      if (!length(hijas) || !setequal(x_y$geo_id, hijas)) return(NULL)
      completo <- !any(x_y$n_nd | is.na(x_y$n))
      con_c <- !is.na(x_y$cuantia) & !is.na(x_y$n_cuantia)
      tibble::tibble(geo_id = cc, nivel = "ccaa", anio = y, n = if (completo) sum(x_y$n) else NA_real_, n_nd = !completo,
                     cuantia = if (all(con_c)) sum(x_y$cuantia * x_y$n_cuantia) / sum(x_y$n_cuantia) else NA_real_,
                     estado_n = if (completo) "dato" else "secreto",
                     estado_c = if (all(con_c)) "dato" else "secreto")
    }))
  }))
  todo <- dplyr::bind_rows(directo, sumadas)
  base <- function(indicador, valor, estado) {
    tibble::tibble(geo_id = todo$geo_id, nivel = todo$nivel, anio = as.integer(todo$anio), indicador = indicador,
                   corte = "total", grupo = "total", valor = ifelse(estado %in% c("dato", "estimado"), valor, NA_real_),
                   estado = estado, fuente = "notariado_cien", geo_ref = "2021", version = version)
  }
  dplyr::bind_rows(
    base("hipotecas_compra_vivienda", todo$n, todo$estado_n),
    base("cuantia_hipoteca_vivienda", todo$cuantia, todo$estado_c)
  ) |>
    dplyr::arrange(indicador, nivel, geo_id, anio)
}

# Resumen de la capa: por indicador y nivel, territorios con dato, estimados y secretos, y periodos.
notariado_resumen <- function(larga) {
  larga |>
    dplyr::group_by(fuente, indicador, nivel) |>
    dplyr::summarise(anios = paste(range(anio), collapse = "–"), dato = sum(estado == "dato"),
                     estimado = sum(estado == "estimado"), secreto = sum(estado == "secreto"), .groups = "drop") |>
    dplyr::arrange(fuente, indicador, match(nivel, c("nacional", "ccaa", "provincia", "municipio")))
}
