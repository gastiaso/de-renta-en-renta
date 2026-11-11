# Zonas de mercado residencial tensionado declaradas (indicador 20; fuente zonas_tensionadas). F5.
#
# La Ley 12/2023, por el derecho a la vivienda (art. 18), deja la declaración a la administración
# competente en vivienda (las comunidades autónomas) y manda al Ministerio de Vivienda y Agenda
# Urbana publicar cada trimestre en el BOE una resolución con la relación de zonas declaradas, su
# periodo de vigencia y el enlace a la declaración de la comunidad (art. 18.2.d). Las resoluciones
# del BOE son la fuente del atlas: dan el ámbito, el periodo («tres años desde el día siguiente a
# la publicación de la presente resolución») y el enlace a la declaración autonómica.
#
# Decisiones en CSV (regla 7): inventario/zonas_tensionadas.csv, una fila por municipio y
# declaración, con el identificador de la resolución del BOE, el nombre literal del BOE, el código
# y el nombre del INE, el ámbito (municipio entero o parte), las fechas de efecto y de fin y los
# enlaces. Este fichero descarga el XML de cada resolución (datos/brutos/zonas_tensionadas/,
# fuera de git), lee sus tablas y comprueba el CSV contra ellas (compuerta `zonas_tensionadas_*`).
#
# Prórrogas (plan §11, pregunta 46 e revisada): la declaración dura tres años y puede prorrogarse
# (Ley 12/2023, art. 18.3); la prórroga llega al BOE como una resolución nueva. Va en el CSV como una
# fila más, con su resolución y, en la columna opcional prorroga_de, la resolución de la declaración
# que prorroga (del mismo municipio y ámbito). Su periodo empieza el día siguiente a la publicación
# si el texto lo dice así o, si no, el día siguiente al fin del periodo que prorroga, y dura los años
# que fije el texto (fin, el mismo día del año de vencimiento). La situación a 31 de diciembre junta
# todos los periodos de cada municipio, así que una prórroga alarga la declaración sin más.
#
# Tabla larga: nivel municipio (todos los del seccionado de 2021), un valor por año, la situación
# a 31 de diciembre: 2 declarada en todo el municipio, 1 declarada en parte (núcleos, barrios o
# distritos: el BOE no da su geometría y se pinta el municipio con la categoría «parte»), 0 sin
# declaración en vigor. Las categorías tienen su texto en inventario/vocabulario.csv (grupo
# zona_tensionada).
#
# Incorporado el 10-nov-2026: la normalización de nombres de municipio (artículos pospuestos,
# formas bilingües, apóstrofes) sigue la de un script propio anterior para casar el listado de
# zonas tensionadas con el nomenclátor; aquí solo sirve para proponer códigos al añadir
# resoluciones (proponer_zonas_tensionadas()), que se revisan a mano antes de entrar en el CSV.

DIR_ZONAS_TENSIONADAS <- file.path("datos", "brutos", "zonas_tensionadas")
URL_BOE_ZONAS_XML <- "https://www.boe.es/diario_boe/xml.php?id=%s"
URL_BOE_ZONAS_TEXTO <- "https://www.boe.es/diario_boe/txt.php?id=%s"
COLUMNAS_ZONAS_TENSIONADAS <- c("boe", "fecha_publicacion", "ccaa", "municipio", "nombre_ine", "nombre_boe", "ambito",
                                "ambito_texto", "fecha_inicio", "fecha_fin", "declaracion", "url", "url_declaracion")
AMBITOS_ZONAS_TENSIONADAS <- c(municipio = 2, parcial = 1)   # valor de la tabla larga; sin declaracion, 0
ANIO_INICIO_ZONAS_TENSIONADAS <- 2024L                       # primera resolucion del BOE: marzo de 2024

# Inventario de declaraciones (inventario/zonas_tensionadas.csv), con códigos como texto y fechas.
leer_zonas_tensionadas <- function(ruta) {
  x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = "")
  falta <- setdiff(COLUMNAS_ZONAS_TENSIONADAS, names(x))
  if (length(falta)) stop("Faltan columnas en ", ruta, ": ", paste(falta, collapse = ", "), call. = FALSE)
  for (col in c("fecha_publicacion", "fecha_inicio", "fecha_fin")) x[[col]] <- as.Date(x[[col]])
  x$ambito_texto[is.na(x$ambito_texto)] <- ""
  if (!"prorroga_de" %in% names(x)) x$prorroga_de <- NA_character_   # columna opcional (pregunta 46 e)
  x
}

# XML de cada resolución del BOE, con caché. Comprueba que el fichero está entero (se lee como XML y
# su identificador es el pedido); si no, lo borra y se detiene, para no guardar una descarga cortada.
descargar_zonas_tensionadas <- function(ids, dir = DIR_ZONAS_TENSIONADAS) {
  ids <- sort(unique(ids))
  rutas <- vapply(ids, function(id) {
    destino <- file.path(dir, paste0(id, ".xml"))
    descargar_con_cache(sprintf(URL_BOE_ZONAS_XML, id), destino)
    leido <- tryCatch(xml2::xml_text(xml2::xml_find_first(xml2::read_xml(destino), "/documento/metadatos/identificador")),
                      error = function(e) NA_character_)
    if (!identical(leido, id)) {
      unlink(destino)
      stop("El XML de ", id, " no esta entero o no es el pedido; se ha borrado ", destino,
           ". Vuelve a ejecutar tar_make() o bajalo de ", sprintf(URL_BOE_ZONAS_XML, id), call. = FALSE)
    }
    destino
  }, character(1))
  unname(rutas)
}

# Texto de una celda o párrafo: espacios seguidos (y los de no separación) en uno.
zt_texto_limpio <- function(x) trimws(gsub("\\s+", " ", gsub("\u00a0", " ", x, fixed = TRUE)))

# Filas de las tablas de cada resolución: identificador, fechas de publicación y de la disposición,
# título y, por fila de la tabla, la comunidad, el texto de los municipios (o ámbitos), el del
# periodo de vigencia y el de la declaración y su memoria (última columna). Sin el punto final.
leer_boe_zonas_tensionadas <- function(rutas) {
  sin_punto <- function(x) sub("\\.$", "", zt_texto_limpio(x))
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    x <- xml2::read_xml(ruta)
    campo <- function(xpath) xml2::xml_text(xml2::xml_find_first(x, xpath))
    filas <- xml2::xml_find_all(x, "/documento/texto//table/tbody/tr")
    # Texto de cada celda con sus parrafos separados (xml_text() los junta sin espacio)
    texto_celda <- function(td) paste(xml2::xml_text(xml2::xml_find_all(td, ".//text()")), collapse = " ")
    celdas <- lapply(filas, function(tr) vapply(xml2::xml_find_all(tr, "./td"), texto_celda, ""))
    celdas <- celdas[lengths(celdas) >= 3]
    tibble::tibble(
      boe = campo("/documento/metadatos/identificador"),
      fecha_publicacion = as.Date(campo("/documento/metadatos/fecha_publicacion"), "%Y%m%d"),
      fecha_disposicion = as.Date(campo("/documento/metadatos/fecha_disposicion"), "%Y%m%d"),
      titulo = zt_texto_limpio(campo("/documento/metadatos/titulo")),
      fila = seq_along(celdas),
      comunidad = vapply(celdas, function(c) sin_punto(c[1]), ""),
      municipios = vapply(celdas, function(c) sin_punto(c[2]), ""),
      vigencia = vapply(celdas, function(c) zt_texto_limpio(c[3]), ""),
      declaracion = vapply(celdas, function(c) zt_texto_limpio(c[length(c)]), "")
    )
  }))
}

# Texto en minúsculas, sin tildes ni signos (para comparar nombres y patrones sin caracteres no ASCII).
zt_texto_ascii <- function(x) {
  x <- stringi::stri_trans_general(tolower(x), "Latin-ASCII")
  zt_texto_limpio(gsub("[^a-z0-9/ ]", " ", x))
}

# Nombre de comunidad sin las palabras de su forma oficial («Principado de», «Comunidad Foral de»):
# «Principado de Asturias» y «Asturias, Principado de» dan lo mismo.
zt_clave_comunidad <- function(x) {
  palabras <- strsplit(zt_texto_ascii(x), " ", fixed = TRUE)
  vacias <- c("de", "del", "la", "el", "les", "illes", "principado", "comunidad", "comunitat", "foral", "region")
  vapply(palabras, function(p) paste(sort(setdiff(p, vacias)), collapse = " "), "")
}

# Periodo de vigencia que fija el texto de la resolución: hasta hoy, siempre «Tres años desde el día
# siguiente a la publicación de la presente resolución» (art. 18.2.d); una prórroga puede contar
# desde el fin del periodo anterior (pregunta 46 e). Devuelve los años o NA si el texto dice otra
# cosa (la compuerta lo para: habría que leerlo a mano).
zt_anios_vigencia <- function(vigencia) {
  v <- zt_texto_ascii(vigencia)
  numeros <- c(un = 1L, uno = 1L, dos = 2L, tres = 3L, cuatro = 4L, cinco = 5L)
  m <- regmatches(v, regexec("^(un|uno|dos|tres|cuatro|cinco) anos? desde el dia siguiente a", v))
  vapply(m, function(z) if (length(z) == 2) numeros[[z[2]]] else NA_integer_, integer(1))
}

# ¿Cuenta el periodo desde la publicación de la resolución? Si no (una prórroga que cuenta desde el
# fin del periodo anterior), FALSE.
zt_desde_publicacion <- function(vigencia) grepl("desde el dia siguiente a la publicacion", zt_texto_ascii(vigencia))

# Fecha de fin de un periodo de `anios` años que empieza el día siguiente a la publicación: el mismo
# día del año de vencimiento (art. 30.4 de la Ley 39/2015: los plazos en años acaban el mismo día en
# que se produjo la publicación). Del 29 de febrero, al 28.
zt_fin_vigencia <- function(publicacion, anios) {
  lt <- as.POSIXlt(publicacion)
  anios <- rep_len(as.integer(anios), length(publicacion))
  destino <- as.Date(sprintf("%04d-%02d-%02d", lt$year + 1900L + anios, lt$mon + 1L, lt$mday), format = "%Y-%m-%d")
  bisiesto <- is.na(destino) & !is.na(publicacion) & !is.na(anios)
  destino[bisiesto] <- as.Date(sprintf("%04d-%02d-28", lt$year[bisiesto] + 1900L + anios[bisiesto], lt$mon[bisiesto] + 1L),
                               format = "%Y-%m-%d")
  destino
}

# Compuerta del indicador 20 (inventario/referencias_validacion.csv, todas de bloqueo):
#   zonas_tensionadas_resolucion: filas del CSV cuya resolución no está descargada y leída, o cuya
#     fecha de publicación no es la del BOE;
#   zonas_tensionadas_codigos: códigos que no son municipios del seccionado de 2021, nombres del
#     INE que no son los de ese código, o municipios fuera de la comunidad de su fila del BOE;
#   zonas_tensionadas_nombre: filas cuyo nombre literal no está en la tabla de su resolución;
#   zonas_tensionadas_completa: filas de las tablas del BOE con algún nombre que el CSV no recoge;
#   zonas_tensionadas_fechas: efecto distinto del día siguiente a la publicación (o, en una prórroga
#     que cuenta desde el periodo anterior, al fin de ese periodo), fin distinto del que fija el texto
#     (o texto de vigencia no reconocido), fin anterior al efecto; prórrogas (prorroga_de) sin una
#     declaración anterior del mismo municipio y ámbito, o publicadas cuando ya había vencido;
#   zonas_tensionadas_ambito: ámbitos desconocidos, partes sin su texto, municipios enteros con texto,
#     filas repetidas y enlaces que no son los de la resolución.
comprobar_zonas_tensionadas <- function(zonas, boe, territorios) {
  fila <- function(id, detalle, calculado) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = 0)
  municipios <- territorios[territorios$nivel == "municipio", ]
  provincias <- territorios[territorios$nivel == "provincia", ]
  comunidades <- territorios[territorios$nivel == "ccaa", ]
  tablas <- boe |> dplyr::distinct(boe, fecha_publicacion)

  # Resolucion descargada y fecha de publicacion
  pub_boe <- tablas$fecha_publicacion[match(zonas$boe, tablas$boe)]
  sin_xml <- is.na(pub_boe)
  otra_fecha <- !sin_xml & (is.na(zonas$fecha_publicacion) | zonas$fecha_publicacion != pub_boe)

  # Codigos, nombres del INE y comunidad de la fila del BOE
  m <- match(zonas$municipio, municipios$codigo)
  ccaa_ine <- provincias$superior[match(substr(zonas$municipio, 1, 2), provincias$codigo)]
  nombre_ccaa <- comunidades$nombre[match(ccaa_ine, comunidades$codigo)]
  filas_boe <- dplyr::left_join(zonas[c("boe", "ccaa", "nombre_boe")], boe[c("boe", "comunidad", "municipios", "vigencia")],
                                by = "boe", relationship = "many-to-many")
  filas_boe <- filas_boe[!is.na(filas_boe$municipios) & zt_clave_comunidad(filas_boe$comunidad) ==
                           zt_clave_comunidad(comunidades$nombre[match(filas_boe$ccaa, comunidades$codigo)]), ]
  encontrado <- unique(paste(filas_boe$boe, filas_boe$nombre_boe)[mapply(grepl, filas_boe$nombre_boe, filas_boe$municipios, fixed = TRUE)])
  nombre_ok <- paste(zonas$boe, zonas$nombre_boe) %in% encontrado
  con_fila <- paste(zonas$boe, zonas$ccaa) %in% paste(filas_boe$boe, filas_boe$ccaa)

  # Completitud: en cada fila del BOE, quitados los nombres del CSV de esa resolucion y comunidad
  # (los mas largos primero), solo quedan comas, puntos, espacios y la 'y' o la 'i' de las listas
  completa <- vapply(seq_len(nrow(boe)), function(k) {
    b <- boe[k, ]
    propios <- zonas$nombre_boe[zonas$boe == b$boe & zt_clave_comunidad(comunidades$nombre[match(zonas$ccaa, comunidades$codigo)]) ==
                                  zt_clave_comunidad(b$comunidad)]
    resto <- b$municipios
    for (n in propios[order(-nchar(propios))]) resto <- gsub(n, " ", resto, fixed = TRUE)
    resto <- gsub("[,.;]", " ", resto)
    resto <- setdiff(strsplit(zt_texto_limpio(resto), " ", fixed = TRUE)[[1]], c("", "y", "i"))
    length(resto)
  }, numeric(1))
  restos <- boe[completa > 0, ]

  # Fechas: efecto, el dia siguiente a la publicacion; fin, el que fija el texto de su fila del BOE
  anios <- zt_anios_vigencia(filas_boe$vigencia)
  clave_fila <- paste(filas_boe$boe, filas_boe$nombre_boe)
  anios_fila <- anios[match(paste(zonas$boe, zonas$nombre_boe), clave_fila)]
  desde_pub <- zt_desde_publicacion(filas_boe$vigencia)[match(paste(zonas$boe, zonas$nombre_boe), clave_fila)]
  # Prorrogas: el periodo que prorrogan (mismo municipio y ambito, resolucion de prorroga_de)
  prorroga_de <- if ("prorroga_de" %in% names(zonas)) zonas$prorroga_de else rep(NA_character_, nrow(zonas))
  es_prorroga <- !is.na(prorroga_de) & nzchar(prorroga_de)
  previa <- match(paste(prorroga_de, zonas$municipio, zonas$ambito_texto), paste(zonas$boe, zonas$municipio, zonas$ambito_texto))
  fin_previo <- zonas$fecha_fin[previa]
  base <- zonas$fecha_publicacion
  desde_fin <- es_prorroga & !is.na(fin_previo) & !(desde_pub %in% TRUE)
  base[desde_fin] <- fin_previo[desde_fin]
  prorroga_mal <- es_prorroga & (is.na(previa) | is.na(fin_previo) | zonas$fecha_publicacion > fin_previo)
  efecto_mal <- is.na(zonas$fecha_inicio) | is.na(base) | zonas$fecha_inicio != base + 1
  fin_esperado <- zt_fin_vigencia(base, anios_fila)
  fin_mal <- is.na(anios_fila) | is.na(zonas$fecha_fin) | is.na(fin_esperado) | zonas$fecha_fin != fin_esperado
  orden_mal <- !is.na(zonas$fecha_fin) & !is.na(zonas$fecha_inicio) & zonas$fecha_fin <= zonas$fecha_inicio

  # Ambito, filas repetidas y enlaces
  ambito_mal <- !zonas$ambito %in% names(AMBITOS_ZONAS_TENSIONADAS) |
    (zonas$ambito == "parcial" & !nzchar(zonas$ambito_texto)) | (zonas$ambito == "municipio" & nzchar(zonas$ambito_texto))
  repetidas <- duplicated(zonas[c("boe", "municipio", "ambito_texto")])
  url_mal <- is.na(zonas$url) | zonas$url != sprintf(URL_BOE_ZONAS_TEXTO, zonas$boe)

  dplyr::bind_rows(
    fila("zonas_tensionadas_resolucion", c("filas sin resolucion descargada", "fecha de publicacion distinta de la del BOE"),
         c(sum(sin_xml), sum(otra_fecha))),
    fila("zonas_tensionadas_codigos", c("codigos fuera del seccionado de 2021", "nombre del INE distinto",
                                        "municipios fuera de la comunidad de su fila", "comunidades sin fila del BOE"),
         c(sum(is.na(m)), sum(!is.na(m) & municipios$nombre[m] != zonas$nombre_ine),
           sum(is.na(ccaa_ine) | ccaa_ine != zonas$ccaa), sum(!con_fila))),
    fila("zonas_tensionadas_nombre", "nombres literales que no estan en la tabla de su resolucion", sum(!nombre_ok)),
    fila("zonas_tensionadas_completa", if (nrow(restos)) paste(restos$boe, "fila", restos$fila) else "filas del BOE con nombres fuera del CSV",
         if (nrow(restos)) completa[completa > 0] else 0),
    fila("zonas_tensionadas_fechas", c("efecto distinto del dia siguiente a la publicacion (o al fin del periodo prorrogado)",
                                       "fin distinto del que fija el texto", "fin anterior al efecto",
                                       "prorrogas sin declaracion anterior del mismo ambito o publicadas ya vencida"),
         c(sum(efecto_mal), sum(fin_mal), sum(orden_mal), sum(prorroga_mal))),
    fila("zonas_tensionadas_ambito", c("ambitos desconocidos o sin su texto", "filas repetidas", "enlaces distintos del de la resolucion"),
         c(sum(ambito_mal), sum(repetidas), sum(url_mal)))
  )
}

# Situación de cada municipio a 31 de diciembre de cada año: 2 (todo el municipio), 1 (parte) o 0.
# Con varias declaraciones en vigor, la de más alcance.
situacion_zonas_tensionadas <- function(zonas, codigos, anios) {
  rejilla <- tidyr::expand_grid(geo_id = codigos, anio = as.integer(anios))
  corte <- as.Date(sprintf("%d-12-31", rejilla$anio))
  valor <- numeric(nrow(rejilla))
  for (k in seq_len(nrow(zonas))) {
    z <- zonas[k, ]
    i <- which(rejilla$geo_id == z$municipio & z$fecha_inicio <= corte & z$fecha_fin >= corte)
    valor[i] <- pmax(valor[i], AMBITOS_ZONAS_TENSIONADAS[[z$ambito]])
  }
  rejilla$valor <- valor
  rejilla
}

# Tabla larga: todos los municipios del seccionado de 2021, de 2024 al año de la última resolución,
# estado «dato» (también el 0: que no haya declaración en vigor es un hecho publicado).
armonizar_zonas_tensionadas <- function(zonas, territorios, version, anios = NULL) {
  codigos <- sort(territorios$codigo[territorios$nivel == "municipio"])
  if (is.null(anios)) anios <- seq(ANIO_INICIO_ZONAS_TENSIONADAS, as.integer(format(max(zonas$fecha_publicacion), "%Y")))
  situacion_zonas_tensionadas(zonas, codigos, anios) |>
    dplyr::transmute(geo_id, nivel = "municipio", anio, indicador = "zona_tensionada", corte = "total", grupo = "total",
                     valor, estado = "dato", fuente = "zonas_tensionadas", geo_ref = "2021", version = version)
}

# Resumen para la nota metodológica: municipios por categoría y año, y declaraciones por comunidad.
resumen_zonas_tensionadas <- function(larga, zonas) {
  list(
    por_anio = larga |> dplyr::count(anio, valor),
    por_ccaa = zonas |> dplyr::count(ccaa, ambito),
    resoluciones = zonas |> dplyr::count(boe, fecha_publicacion, fecha_inicio, fecha_fin)
  )
}

# --- Ayuda para añadir resoluciones --------------------------------------------------------------

# Nombre de municipio normalizado: minúsculas sin tildes, sin paréntesis, con el artículo pospuesto
# delante y luego quitado («Masnou, El» -> «masnou»), apóstrofes y guiones como espacios.
zt_normalizar_municipio <- function(x) {
  x <- gsub("\\s*\\([^)]*\\)", " ", x)
  x <- stringi::stri_trans_general(tolower(x), "Latin-ASCII")
  x <- gsub("['`\u2019-]", " ", x)
  x <- zt_texto_limpio(gsub("\\s*/\\s*", " / ", x))
  articulos <- "(el|la|els|les|lo|los|las|l|s|sa|es|ses|a|as|o|os)"
  x <- sub(paste0("^(.*),\\s*", articulos, "$"), "\\2 \\1", x)
  zt_texto_limpio(sub(paste0("^", articulos, "\\s+"), "", x))
}

# Partes de una lista separada por comas fuera de los paréntesis, sin la «y» o la «i» que encabeza
# la última («…, Vilassar de Dalt, i Vilassar de Mar») y con las salvedades («Vitoria-Gasteiz,
# excepto la zona rural…») unidas a su municipio.
zt_partir_lista <- function(x) {
  letras <- strsplit(x, "")[[1]]
  nivel <- cumsum((letras == "(") - c(0, utils::head(letras == ")", -1)))
  corte <- which(letras == "," & nivel == 0)
  partes <- zt_texto_limpio(substring(x, c(1, corte + 1), c(corte - 1, nchar(x))))
  partes <- sub("^(i|y)\\s+", "", partes)
  salvedad <- grepl("^excepto\\s", partes)
  for (k in rev(which(salvedad & seq_along(partes) > 1))) partes[k - 1] <- paste0(partes[k - 1], ", ", partes[k])
  partes[!salvedad]
}

# Borrador de filas del CSV desde las tablas leídas del BOE: cada nombre de la columna de municipios
# casado con un municipio de su comunidad por el nombre normalizado (o por una de las formas de los
# nombres bilingües). Lo que no casa sale con municipio NA: se resuelve a mano (por ejemplo, una
# coma que falta en el BOE o un nombre partido por la coma de su forma oficial). Los ámbitos entre
# paréntesis o con «excepto» salen como «parcial».
proponer_zonas_tensionadas <- function(boe, territorios) {
  municipios <- territorios[territorios$nivel == "municipio", ]
  provincias <- territorios[territorios$nivel == "provincia", ]
  comunidades <- territorios[territorios$nivel == "ccaa", ]
  municipios$ccaa <- provincias$superior[match(substr(municipios$codigo, 1, 2), provincias$codigo)]
  claves <- dplyr::bind_rows(lapply(seq_len(nrow(municipios)), function(k) {
    n <- zt_normalizar_municipio(municipios$nombre[k])
    formas <- unique(c(n, zt_texto_limpio(strsplit(n, "/", fixed = TRUE)[[1]])))
    tibble::tibble(codigo = municipios$codigo[k], ccaa = municipios$ccaa[k], clave = formas)
  }))
  dplyr::bind_rows(lapply(seq_len(nrow(boe)), function(k) {
    b <- boe[k, ]
    ccaa <- comunidades$codigo[zt_clave_comunidad(comunidades$nombre) == zt_clave_comunidad(b$comunidad)]
    if (length(ccaa) != 1) ccaa <- NA_character_
    nombres <- zt_partir_lista(b$municipios)
    dplyr::bind_rows(lapply(nombres, function(n) {
      base <- zt_texto_limpio(sub("\\s*\\(.*$", "", sub(",?\\s+excepto\\s.*$", "", n)))
      formas <- unique(c(zt_normalizar_municipio(base), zt_texto_limpio(strsplit(zt_normalizar_municipio(base), "/", fixed = TRUE)[[1]])))
      cand <- unique(claves$codigo[claves$ccaa %in% ccaa & claves$clave %in% formas])
      parcial <- grepl("(", n, fixed = TRUE) || grepl("\\sexcepto\\s", n)
      texto <- if (grepl("(", n, fixed = TRUE)) sub("^[^(]*\\((.*)\\)$", "\\1", n) else if (parcial) sub("^.*?,?\\s+(excepto\\s.*)$", "\\1", n) else ""
      tibble::tibble(
        boe = b$boe, fecha_publicacion = b$fecha_publicacion, ccaa = ccaa,
        municipio = if (length(cand) == 1) cand else NA_character_,
        nombre_ine = if (length(cand) == 1) municipios$nombre[municipios$codigo == cand] else NA_character_,
        nombre_boe = n, ambito = if (parcial) "parcial" else "municipio", ambito_texto = texto,
        fecha_inicio = b$fecha_publicacion + 1, fecha_fin = zt_fin_vigencia(b$fecha_publicacion, zt_anios_vigencia(b$vigencia)),
        declaracion = zt_declaracion_boe(b$declaracion), url = sprintf(URL_BOE_ZONAS_TEXTO, b$boe),
        url_declaracion = zt_enlace_declaracion(b$declaracion)
      )
    }))
  }))
}

# Declaración de la comunidad citada en la última columna de la tabla del BOE: el texto entre
# «Declaración:» y el primer enlace (o «Memoria»), sin el punto final.
zt_declaracion_boe <- function(texto) {
  x <- sub("^.*?Declaraci\\S*n:\\s*", "", texto, perl = TRUE)
  x <- sub("\\s*(https?://|\\S\\s*Memoria).*$", "", x, perl = TRUE)
  zt_texto_limpio(sub("[.,]$", "", x))
}

# Primer enlace de esa columna (la declaración; la memoria va después). Sin él, vacío.
zt_enlace_declaracion <- function(texto) {
  m <- regmatches(texto, regexpr("https?://[^ ]+", texto))
  if (length(m)) sub("[.,]$", "", m) else ""
}
