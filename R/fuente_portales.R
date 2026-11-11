# Precios de oferta de los portales (indicador 13; fuente portales). Capa desmontable (plan §2.2;
# guía, regla 6): solo con la variable de entorno PORTALES=TRUE (por defecto, FALSE; _targets.R).
# Solo web (backlog, decisión 3): la capa no entra en la tabla larga, ni en las descargas, ni en el
# release, ni en git. Sale en su propia carpeta de la web, web/datos/portales/ (R/web_portales.R).
# Apagada, el pipeline no lee nada de aquí y la web la tiene apagada (un manifiesto vacío).
#
# Solo cifras de los informes agregados que los portales publican en sus salas de prensa (precio
# medio por m² de un territorio), nunca anuncios. El atlas no descarga nada de los portales: los
# ficheros los deja el autor en datos/brutos/portales/ (fuera de git), de dos maneras:
#   - Idealista (tarea 35): la extracción del autor, en datos/brutos/portales/idealista/, con los
#     nombres <operación>_historico_<AAAA-MM>.csv (path, fecha, precio_m2…: una cifra por territorio
#     y mes) y <operación>_zonas_<AAAA-MM>.csv (path, nivel, nombre, url…: los territorios). Cada
#     territorio se casa con su código del INE por su dirección (path) en
#     inventario/portales_idealista_territorios.csv (regla 7), casada por nombre y revisada a mano.
#     De cada operación se lee la extracción más reciente. Los barrios (<operación>_barrios_*.csv) no
#     se leen (decisión 16). idealista_convertir() lo pasa al formato de la capa;
#   - cualquier portal, a mano: uno o varios CSV en datos/brutos/portales/*.csv con el formato de la
#     capa (venta y Fotocasa quedan para la v1.1: el formato está preparado, sin datos).
#
# Formato de la capa (UTF-8, separador coma, punto decimal; una cifra por fila):
#
#   portal     idealista | fotocasa
#   operacion  alquiler (€ por m² y mes) | venta (€ por m²)
#   nivel      nacional | ccaa | provincia | municipio | zona | localidad
#   geo_id     código del INE como texto: España, «00»; comunidad y provincia, 2 cifras; municipio,
#              5. Las zonas del portal (que no son distritos del INE) y las localidades que el portal
#              lista como municipio sin serlo llevan el de su municipio; vacío en una localidad
#              repartida entre dos municipios
#   zona       en zonas y localidades, su identificador en el portal (el último tramo de su
#              dirección); vacío en el resto (columna opcional en los CSV manuales)
#   nombre     nombre del territorio en el informe (control; no se usa para casar)
#   periodo    AAAA-MM (informe mensual) o AAAA (informe anual)
#   valor      precio medio por m² del informe
#   informe    título o referencia del informe
#   url        dirección del informe en la sala de prensa (cada cifra lleva la suya)
#
# Ejemplo (cifras inventadas): idealista,alquiler,municipio,28079,,Madrid,2025-12,99.9,Informe de
# prueba,https://ejemplo.invalid/informe. Pruebas: pruebas/datos/portales_inventado.csv.
#
# Valor anual (anualizar_portales(); decidido el 10-nov-2026): la media de los meses publicados del
# año, con 9 meses como mínimo; con menos, el año queda `ausente`. Si el portal publica una cifra
# anual (periodo AAAA), manda esa. Hasta el 10-nov-2026 se tomaba el último mes del año: deja de
# usarse. La media se redondea a dos decimales, con los empates hacia arriba sobre la media exacta
# (7,575 da 7,58; sprintf daría 7,57 por la representación binaria). El último año puede no tener
# los doce meses: la web dice hasta qué mes llega (`ultimo_mes`).
#
# Tabla de la capa (armonizar_portales(); el formato de la tabla larga, pero fuera de ella):
# indicador precio_oferta, corte oferta_privada (etiqueta de dato privado de oferta, en
# inventario/vocabulario.csv), grupo «operacion_portal» (alquiler_idealista…), un valor por año, en
# los niveles nacional, ccaa, provincia y municipio: en cada uno, la cifra que publica el portal para
# ese nivel (regla 1; nada se agrega ni se reparte). Las zonas y las localidades, aparte, con su
# municipio y sin geometría (portales_zonas()). Nunca se mezcla con el SERPAVI, la tasación ni las
# escrituras (regla 5), ni un portal con otro.

DIR_PORTALES <- file.path("datos", "brutos", "portales")
COLUMNAS_PORTALES <- c("portal", "operacion", "nivel", "geo_id", "zona", "nombre", "periodo", "valor", "informe", "url")
PORTALES_VALIDOS <- c("idealista", "fotocasa")
OPERACIONES_PORTALES <- c("alquiler", "venta")
NIVELES_PORTALES <- c(nacional = 2L, ccaa = 2L, provincia = 2L, municipio = 5L, zona = 5L, localidad = 5L)
NIVELES_ZONA_PORTALES <- c("zona", "localidad")          # con su municipio y su identificador de zona
CORTE_PORTALES <- "oferta_privada"
PORTALES_ANIO_DESDE <- 2015L                             # primer año de la capa (el del atlas)
PORTALES_MESES_MINIMOS <- 9L                             # meses para la media anual

# Idealista: carpeta, dirección de la sala de prensa (para las filas sin url) y título de sus informes
DIR_IDEALISTA <- file.path(DIR_PORTALES, "idealista")
IDEALISTA_WEB <- "https://www.idealista.com"
IDEALISTA_INFORMES <- c(alquiler = "idealista, evoluci\u00f3n del precio de la vivienda en alquiler",
                        venta = "idealista, evoluci\u00f3n del precio de la vivienda en venta")
# Compuerta (inventario/referencias_validacion.csv; backlog, tarea 35): España, alquiler, media anual
# en 2015 y 2024, y municipios con serie desde 2015 o antes (de los que publica), en la extracción
# del 10-nov-2026
IDEALISTA_REFERENCIAS_ESPANA <- c("2015" = 7.58, "2024" = 13.06)
IDEALISTA_REFERENCIA_MUNICIPIOS <- c(con_serie = 286, desde_2015 = 278)

# ¿Está encendida la capa? (variable de entorno PORTALES; TRUE en mayúsculas o minúsculas).
portales_activos <- function(valor = Sys.getenv("PORTALES", "FALSE")) identical(toupper(trimws(valor)), "TRUE")

# Ficheros de la capa: los CSV manuales de dir (no recursivo) y la extracción de Idealista de
# dir/idealista/ (idealista_buscar_ficheros()). Sin ninguno, se detiene y dice qué dejar y dónde.
buscar_ficheros_portales <- function(dir = DIR_PORTALES) {
  manuales <- sort(list.files(dir, pattern = "[.]csv$", full.names = TRUE))
  rutas <- c(manuales, idealista_buscar_ficheros(file.path(dir, "idealista")))
  if (!length(rutas)) {
    stop("PORTALES=TRUE y no hay ficheros en ", dir, ". Deja en ", file.path(dir, "idealista"),
         " la extracci\u00f3n de Idealista (alquiler_historico_AAAA-MM.csv y alquiler_zonas_AAAA-MM.csv) o, ",
         "en ", dir, ", uno o varios CSV con las columnas ", paste(COLUMNAS_PORTALES, collapse = ", "),
         " (formato en R/fuente_portales.R), de los informes agregados de las salas de prensa; nunca anuncios. ",
         "Para apagar la capa, quita la variable PORTALES o ponla a FALSE.", call. = FALSE)
  }
  rutas
}

# Extracción de Idealista: por operación, el histórico y los territorios de la extracción más reciente
# que tenga los dos (AAAA-MM en el nombre). Un histórico sin su fichero de territorios detiene.
idealista_buscar_ficheros <- function(dir = DIR_IDEALISTA) {
  patron <- "^(alquiler|venta)_(historico|zonas)_([0-9]{4}-[0-9]{2})[.]csv$"
  f <- list.files(dir, pattern = patron)
  if (!length(f)) return(character())
  partes <- data.frame(fichero = f, operacion = sub(patron, "\\1", f), tipo = sub(patron, "\\2", f),
                       extraccion = sub(patron, "\\3", f))
  rutas <- character()
  for (op in intersect(OPERACIONES_PORTALES, partes$operacion)) {
    p <- partes[partes$operacion == op, ]
    ambos <- intersect(p$extraccion[p$tipo == "historico"], p$extraccion[p$tipo == "zonas"])
    if (!length(ambos)) {
      stop("Idealista, ", op, ": falta el hist\u00f3rico o el fichero de territorios de la misma extracci\u00f3n en ", dir,
           " (", op, "_historico_AAAA-MM.csv y ", op, "_zonas_AAAA-MM.csv).", call. = FALSE)
    }
    ultima <- max(ambos)
    rutas <- c(rutas, file.path(dir, paste0(op, c("_historico_", "_zonas_"), ultima, ".csv")))
  }
  rutas
}

# Correspondencia de los territorios de Idealista con los códigos del INE (regla 7).
idealista_leer_territorios <- function(ruta = file.path("inventario", "portales_idealista_territorios.csv")) {
  readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = "", locale = readr::locale(encoding = "UTF-8"))
}

# Lectura de la capa: los CSV manuales tal cual y la extracción de Idealista convertida al formato de
# la capa (necesita la correspondencia `territorios_idealista`). Códigos, zonas y periodos como texto,
# valor numérico, y el fichero de origen.
leer_portales <- function(rutas, territorios_idealista = NULL) {
  de_idealista <- basename(dirname(rutas)) == "idealista"
  manuales <- lapply(rutas[!de_idealista], function(ruta) {
    x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = c("", "NA"),
                         locale = readr::locale(encoding = "UTF-8"))
    if (!"zona" %in% names(x)) x$zona <- NA_character_
    falta <- setdiff(COLUMNAS_PORTALES, names(x))
    if (length(falta)) stop("Faltan columnas en ", ruta, ": ", paste(falta, collapse = ", "), call. = FALSE)
    x <- x[COLUMNAS_PORTALES]
    x$valor <- suppressWarnings(as.numeric(x$valor))
    x$fichero <- basename(ruta)
    x
  })
  idealista <- NULL
  if (any(de_idealista)) {
    if (is.null(territorios_idealista)) {
      stop("Para leer la extracci\u00f3n de Idealista hace falta inventario/portales_idealista_territorios.csv.", call. = FALSE)
    }
    idealista <- idealista_convertir_ficheros(rutas[de_idealista], territorios_idealista)
  }
  dplyr::bind_rows(c(manuales, list(idealista)))
}

# Conversor de la extracción de Idealista (pares histórico y territorios de idealista_buscar_ficheros())
# al formato de la capa.
idealista_convertir_ficheros <- function(rutas, territorios_idealista) {
  historicos <- rutas[grepl("_historico_", basename(rutas))]
  dplyr::bind_rows(lapply(historicos, function(ruta) {
    operacion <- sub("_.*$", "", basename(ruta))
    zonas <- sub("_historico_", "_zonas_", ruta, fixed = TRUE)
    leer <- function(r) readr::read_csv(r, col_types = readr::cols(.default = "c"), na = c("", "NA"),
                                        locale = readr::locale(encoding = "UTF-8"))
    x <- idealista_convertir(leer(ruta), leer(zonas), territorios_idealista, operacion)
    x$fichero <- basename(ruta)
    x
  }))
}

# Una fila de la capa por cifra mensual del histórico. El nivel, el código y el nombre salen de la
# correspondencia (una dirección sin fila queda sin nivel: la compuerta la cuenta); el enlace, del
# fichero de territorios (o, sin él, de la dirección).
idealista_convertir <- function(historico, zonas, territorios_idealista, operacion = "alquiler") {
  t <- territorios_idealista[match(historico$path, territorios_idealista$path), ]
  url <- zonas$url[match(historico$path, zonas$path)]
  sin_url <- is.na(url) | !nzchar(url)
  url[sin_url] <- paste0(IDEALISTA_WEB, historico$path[sin_url])
  nivel <- t$nivel
  tibble::tibble(
    portal = "idealista", operacion = operacion, nivel = nivel, geo_id = t$geo_id,
    zona = ifelse(nivel %in% NIVELES_ZONA_PORTALES, idealista_tramo(historico$path), NA_character_),
    nombre = t$nombre_idealista, periodo = substr(historico$fecha, 1, 7),
    valor = suppressWarnings(as.numeric(historico$precio_m2)),
    informe = unname(IDEALISTA_INFORMES[operacion]), url = url, path = historico$path
  )
}

# Último tramo de una dirección de la sala de prensa («…/madrid/centro/» → «centro»).
idealista_tramo <- function(path) sub("^.*/", "", sub("/+$", "", path))

# Compuerta de la capa (inventario/referencias_validacion.csv, de bloqueo):
#   portales_formato: portal, operación, nivel, código, zona, periodo (AAAA o AAAA-MM), valor, informe
#     o enlace que faltan o no son válidos (una dirección de Idealista sin correspondencia no tiene nivel);
#   portales_codigos: códigos que no son del seccionado de 2021 en su nivel (zonas y localidades: el
#     de su municipio);
#   portales_rango: precios fuera de lo posible (`rangos`: alquiler y venta, € por m²);
#   portales_repetidas: la misma cifra (portal, operación, territorio, zona y periodo) dos veces: en
#     Idealista, meses duplicados.
comprobar_portales <- function(portales, territorios, rangos = list(alquiler = c(1, 100), venta = c(100, 20000))) {
  fila <- function(id, detalle, calculado) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = 0)
  p <- portales
  if (!"zona" %in% names(p)) p$zona <- NA_character_
  periodo_ok <- grepl("^[0-9]{4}(-(0[1-9]|1[0-2]))?$", p$periodo)
  largo <- unname(NIVELES_PORTALES[p$nivel])
  sin_codigo <- p$nivel %in% "localidad" & is.na(p$geo_id)
  codigo_ok <- !is.na(largo) & (sin_codigo | (grepl("^[0-9]+$", p$geo_id) & nchar(p$geo_id) == largo))
  codigo_ok[p$nivel %in% "nacional"] <- p$geo_id[p$nivel %in% "nacional"] %in% "00"
  con_zona <- !is.na(p$zona) & nzchar(p$zona)
  zona_ok <- (p$nivel %in% NIVELES_ZONA_PORTALES) == con_zona
  formato <- c(
    "portal" = sum(!p$portal %in% PORTALES_VALIDOS),
    "operacion" = sum(!p$operacion %in% OPERACIONES_PORTALES),
    "nivel o codigo" = sum(!codigo_ok),
    "zona" = sum(!zona_ok),
    "periodo" = sum(!periodo_ok),
    "valor" = sum(is.na(p$valor)),
    "informe o enlace" = sum(is.na(p$informe) | !nzchar(trimws(p$informe)) | is.na(p$url) | !grepl("^https?://", p$url))
  )
  # Codigo del seccionado de 2021 en su nivel; zonas y localidades, el de su municipio
  nivel_ine <- ifelse(p$nivel %in% NIVELES_ZONA_PORTALES, "municipio", p$nivel)
  conocidos <- paste(territorios$nivel, territorios$codigo)
  revisar <- codigo_ok & !sin_codigo & !p$nivel %in% "nacional"
  rango <- vapply(seq_len(nrow(p)), function(k) {
    r <- rangos[[p$operacion[k]]]
    !is.null(r) && !is.na(p$valor[k]) && (p$valor[k] < r[1] || p$valor[k] > r[2])
  }, logical(1))
  dplyr::bind_rows(
    fila("portales_formato", names(formato), formato),
    fila("portales_codigos", "codigos fuera del seccionado de 2021", sum(revisar & !paste(nivel_ine, p$geo_id) %in% conocidos)),
    fila("portales_rango", "precios fuera del rango posible", sum(rango)),
    fila("portales_repetidas", "cifras repetidas", sum(duplicated(p[c("portal", "operacion", "nivel", "geo_id", "zona", "periodo")])))
  )
}

# Valor anual por portal, operación, territorio y año, desde PORTALES_ANIO_DESDE: la cifra anual
# publicada si la hay; si no, la media de los meses con 9 como mínimo (estado dato), o ausente con
# menos. Columnas: las de la capa sin periodo, más anio, meses (los publicados; NA en una cifra
# anual), valor y estado. Las filas sin nivel (sin correspondencia) no entran.
anualizar_portales <- function(portales, desde = PORTALES_ANIO_DESDE, meses_minimos = PORTALES_MESES_MINIMOS) {
  p <- portales[!is.na(portales$nivel) & !is.na(portales$valor), ]
  if (!"zona" %in% names(p)) p$zona <- NA_character_
  p$anio <- as.integer(substr(p$periodo, 1, 4))
  p <- p[p$anio >= desde, ]
  clave <- c("portal", "operacion", "nivel", "geo_id", "zona", "anio")
  anual <- p[nchar(p$periodo) == 4, ] |>
    dplyr::distinct(dplyr::across(dplyr::all_of(clave)), .keep_all = TRUE) |>
    dplyr::mutate(meses = NA_integer_, estado = "dato")
  mensual <- p[nchar(p$periodo) == 7, ] |>
    dplyr::anti_join(anual[clave], by = clave) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(clave))) |>
    dplyr::summarise(nombre = dplyr::first(nombre), informe = dplyr::first(informe), url = dplyr::first(url),
                     meses = dplyr::n_distinct(periodo), media = mean(valor), .groups = "drop") |>
    dplyr::mutate(estado = dplyr::if_else(meses >= meses_minimos, "dato", "ausente"),
                  valor = dplyr::if_else(estado == "dato", redondear_empate_arriba(media, 2L), NA_real_)) |>
    dplyr::select(-media)
  dplyr::bind_rows(anual[c(clave, "nombre", "informe", "url", "meses", "valor", "estado")], mensual) |>
    dplyr::arrange(portal, operacion, nivel, geo_id, zona, anio)
}

# Tabla de la capa en el formato de la tabla larga (no entra en ella: decisión 3): los niveles
# nacional, ccaa, provincia y municipio, con la etiqueta de dato privado de oferta en el corte.
armonizar_portales <- function(anual, version) {
  anual[anual$nivel %in% c("nacional", "ccaa", "provincia", "municipio"), ] |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "precio_oferta", corte = CORTE_PORTALES,
                     grupo = paste(operacion, portal, sep = "_"), valor, estado, fuente = "portales",
                     geo_ref = "2021", version = version) |>
    dplyr::arrange(grupo, nivel, geo_id, anio)
}

# Zonas y localidades del portal con su municipio (sin geometría; la ficha del municipio las
# listará: tarea 38): las del valor anual con código de municipio, con el grupo de su serie.
portales_zonas <- function(anual) {
  z <- anual[anual$nivel %in% NIVELES_ZONA_PORTALES & !is.na(anual$geo_id), ]
  z$grupo <- paste(z$operacion, z$portal, sep = "_")
  z[c("grupo", "geo_id", "nivel", "zona", "nombre", "url", "anio", "meses", "valor", "estado")]
}

# Último mes publicado por grupo (operación y portal), «AAAA-MM»: la web dice hasta dónde llega el
# último año.
portales_ultimo_mes <- function(portales) {
  p <- portales[!is.na(portales$nivel) & nchar(portales$periodo) == 7, ]
  if (!nrow(p)) return(list())
  u <- tapply(p$periodo, paste(p$operacion, p$portal, sep = "_"), max)
  as.list(u)
}

# Compuerta propia de Idealista (inventario/referencias_validacion.csv, de bloqueo):
#   portales_idealista_casados: direcciones de la extracción sin fila en la correspondencia, y filas
#     de la correspondencia sin ninguna cifra;
#   portales_idealista_espana: España, alquiler, media anual de 2015 y 2024 (IDEALISTA_REFERENCIAS_ESPANA);
#   portales_idealista_municipios: municipios con serie y, de ellos, con serie desde 2015 o antes (el
#     primer mes publicado), frente a IDEALISTA_REFERENCIA_MUNICIPIOS.
idealista_comprobar <- function(portales, anual, territorios_idealista) {
  fila <- function(id, detalle, calculado, referencia = 0) {
    tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = as.numeric(referencia))
  }
  # Solo las filas de la extraccion (con su direccion), no las de los CSV manuales
  p <- if ("path" %in% names(portales)) portales[!is.na(portales$path), ] else portales[0, ]
  p <- p[p$portal %in% "idealista" & p$operacion %in% "alquiler", ]
  if (!nrow(p)) return(tibble::tibble(id = character(), detalle = character(), calculado = numeric(), referencia = numeric()))
  rutas <- unique(p$path)
  sin_serie <- setdiff(territorios_idealista$path, rutas)
  esp <- anual[anual$portal %in% "idealista" & anual$operacion %in% "alquiler" & anual$nivel %in% "nacional", ]
  anios <- names(IDEALISTA_REFERENCIAS_ESPANA)
  espana <- esp$valor[match(as.integer(anios), esp$anio)]
  mun <- p[p$nivel %in% "municipio" & !is.na(p$valor), ]
  primero <- tapply(mun$periodo, mun$geo_id, min)
  dplyr::bind_rows(
    fila("portales_idealista_casados", "direcciones sin fila en la correspondencia", sum(!rutas %in% territorios_idealista$path)),
    fila("portales_idealista_casados", "territorios de la correspondencia sin cifras", length(sin_serie)),
    fila("portales_idealista_espana", paste("Espa\u00f1a, media anual de", anios), espana, IDEALISTA_REFERENCIAS_ESPANA),
    fila("portales_idealista_municipios", c("municipios con serie", "municipios con serie desde 2015 o antes"),
         c(length(primero), sum(primero <= "2015-12")), IDEALISTA_REFERENCIA_MUNICIPIOS)
  )
}

# Resumen de la capa por grupo, nivel y año: territorios con dato y con menos de 9 meses.
portales_resumen <- function(anual) {
  anual |>
    dplyr::mutate(grupo = paste(operacion, portal, sep = "_")) |>
    dplyr::group_by(grupo, nivel, anio) |>
    dplyr::summarise(con_dato = sum(estado == "dato"), ausentes = sum(estado == "ausente"), .groups = "drop") |>
    dplyr::arrange(grupo, match(nivel, names(NIVELES_PORTALES)), anio)
}
