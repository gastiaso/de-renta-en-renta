# Indicador 11 (F4; plan §11, pregunta 45 a revisada): precio de compraventa de vivienda por metro
# cuadrado, de la Estadística Registral Inmobiliaria del Colegio de Registradores, en su portal de
# datos abiertos (licencia ODbL 1.0: LICENCIA_DATOS.md). Conjunto «Compraventas de inmuebles, uso
# residencial, por provincia» (fuente `registradores` de inventario/fuentes.csv).
#
# Nivel: provincia, el más fino que publica la fuente abierta (decisión del autor, 10-nov-2026, que
# sustituye al municipio de la pregunta 45); el mismo fichero da la comunidad y España, que entran
# con su cifra publicada (regla 1). Nunca se mezcla con el Notariado, que mide otra superficie
# (pregunta 45 a; regla 5).
#
# Fichero manual (guía, «Descargas»): el servidor rechaza los clientes que no son un navegador, y no
# se fuerza. registradores_descargar() se detiene y dice qué bajar y dónde dejarlo, como el SERPAVI.
#   Página: REGISTRADORES_PAGINA; fichero: RP_ComprvResid_2007-<t>t<AAAA>.csv (el último trimestre
#   publicado en el nombre), en datos/brutos/registradores/ (fuera de git).
#
# Formato (comprobado el 10-nov-2026): CSV separado por «;», UTF-8, coma decimal y un «;» de cierre
# en cada fila. Columnas: ano; trim; geo (Nacional, Comunidad o Provincia); cod-ca; ca; cod-prv;
# prv; y, por tipo de inmueble, número de compraventas, importe medio por operación (€) y precio
# medio por m² (€): viv-* (vivienda), gar-* (garajes) y tras-* (trasteros). Los códigos de comunidad
# y provincia son los del INE; España lleva 99. Cada trimestre acumula los cuatro últimos (el número
# de compraventas de España del primer trimestre de 2007 es el de todo el año que acaba en él), así
# que el cuarto trimestre es el año natural: el valor anual del atlas es el del cuarto trimestre,
# la media anual del €/m² de vivienda (no la media de los cuatro trimestres, que se solaparían).
#
# Objetivos, en bloque_compraventa de _targets.R (conectados el 11-nov-2026, con el fichero de
# 2007-2t2026; sin él, registradores_descargar() para el pipeline y dice qué bajar):
#   tar_target(fichero_registradores, registradores_descargar(), format = "file"),
#   tar_target(registradores, registradores_leer(fichero_registradores)),
#   tar_target(validacion_registradores, validar_referencias(bind_rows(
#     registradores_comprobar(registradores, territorios_2021),
#     registradores_coherencia_tasado(registradores, larga_valor_tasado)), referencias)),
#   tar_target(larga_registradores, {
#     validacion_registradores
#     registradores_armonizar(registradores, version = version_de(fichero_registradores)) |>
#       validar_tabla_larga(indicadores, fuentes, vocabulario)
#   }),
# y larga_registradores en larga_compraventa y de ahí en tabla_larga. Incorporado el 10-nov-2026.

REGISTRADORES_DIR <- file.path("datos", "brutos", "registradores")
REGISTRADORES_PAGINA <- "https://opendata.registradores.org/dataset/dataset/compraventas-de-inmuebles-uso-residencial-por-provincia"
REGISTRADORES_CSV <- "https://opendata.registradores.org/data-integration/compraventas-residencial-trimestres-provincias-es/RP_ComprvResid_2007-2t2026.csv"
REGISTRADORES_PATRON <- "^RP_ComprvResid_2007-([1-4])t([0-9]{4})\\.csv$"
REGISTRADORES_COLUMNAS <- c("ano", "trim", "geo", "cod-ca", "cod-prv", "viv-num", "viv-imp", "viv-pm2")
REGISTRADORES_NIVELES <- c(Nacional = "nacional", Comunidad = "ccaa", Provincia = "provincia")
REGISTRADORES_ANIOS <- 2015:2025

# Cifras publicadas para la compuerta (registradores_espana, ±0,5 €/m²): España, año 2025, del plan
# (§11, pregunta 45 revisada), contrastada con el fichero de datos abiertos.
REGISTRADORES_REFERENCIAS <- tibble::tribble(
  ~anio, ~geo_id, ~referencia, ~detalle,
  2025L, "00",    2284,        "Espa\u00f1a, 2025 (plan, \u00a711, pregunta 45)"
)

# Intervalos de la compuerta de coherencia con el valor tasado (precio por m² de Registradores /
# valor tasado por m² del MIVAU, mismo territorio y año; pregunta 45 b). Con el fichero de
# 2007-2t2026, de 2015 a 2025: España, de 0,99 a 1,12; provincias, de 0,74 (Badajoz, 2015) a 1,41
# (Santa Cruz de Tenerife, 2022). Fuera de `bloqueo`, error de lectura o de casado (otra columna,
# otra provincia, otra unidad); fuera de `aviso`, provincia que revisar.
REGISTRADORES_RATIO_TASADO <- list(espana = c(0.85, 1.25), bloqueo = c(0.6, 1.6), aviso = c(0.7, 1.4))
REGISTRADORES_RANGO_M2 <- c(300, 10000)

# Fichero manual: la versión más reciente que haya en `dir` (por el trimestre de su nombre). Si no
# hay ninguna, se detiene y explica qué bajar y dónde dejarlo.
registradores_descargar <- function(dir = REGISTRADORES_DIR) {
  ficheros <- list.files(dir, pattern = REGISTRADORES_PATRON)
  if (!length(ficheros)) {
    stop("Falta el fichero de Registradores (descarga manual: su servidor rechaza los clientes que no son un navegador).\n",
         "  Hay que bajar con el navegador el CSV de la p\u00e1gina ", REGISTRADORES_PAGINA, "\n",
         "  (hoy, ", REGISTRADORES_CSV, ", unos 577 KB)\n",
         "  y guardarlo con su nombre en ", file.path(dir, basename(REGISTRADORES_CSV)), call. = FALSE)
  }
  partes <- regmatches(ficheros, regexec(REGISTRADORES_PATRON, ficheros))
  orden <- vapply(partes, function(p) as.integer(p[3]) * 10L + as.integer(p[2]), integer(1))
  file.path(dir, ficheros[which.max(orden)])
}

# Número con coma decimal («1961,66», «2392»); vacío, NA.
registradores_numero <- function(x) {
  x <- trimws(x)
  x[x == ""] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE)))
}

# Lectura: una fila por territorio y trimestre (anio, trimestre, nivel, geo_id con dos cifras y
# «00» para España, compraventas, importe_medio y precio_m2 de vivienda). Se detiene si faltan
# columnas, si hay niveles desconocidos o cifras que no se leen.
registradores_leer <- function(ruta) {
  bruto <- readBin(ruta, "raw", file.info(ruta)$size)
  texto <- rawToChar(bruto)
  Encoding(texto) <- "UTF-8"
  if (!validUTF8(texto)) texto <- iconv(rawToChar(bruto), "CP1252", "UTF-8")
  lineas <- strsplit(sub("^\ufeff", "", texto), "\r?\n")[[1]]
  lineas <- sub(";+$", "", lineas[nzchar(trimws(lineas))])
  partes <- strsplit(lineas, ";", fixed = TRUE)
  cabecera <- trimws(partes[[1]])
  falta <- setdiff(REGISTRADORES_COLUMNAS, cabecera)
  if (length(falta)) stop("Registradores: faltan columnas en ", basename(ruta), ": ", paste(falta, collapse = ", "), call. = FALSE)
  filas <- partes[-1]
  corta <- lengths(filas) < length(cabecera)
  if (any(corta)) stop("Registradores: ", sum(corta), " filas con menos columnas que la cabecera en ", basename(ruta), call. = FALSE)
  col <- function(nombre) vapply(filas, function(f) f[match(nombre, cabecera)], character(1))
  geo <- trimws(col("geo"))
  raros <- setdiff(unique(geo), names(REGISTRADORES_NIVELES))
  if (length(raros)) stop("Registradores: niveles desconocidos en la columna geo: ", paste(raros, collapse = ", "), call. = FALSE)
  nivel <- unname(REGISTRADORES_NIVELES[geo])
  codigo <- ifelse(nivel == "nacional", "00",
                   ifelse(nivel == "ccaa", sprintf("%02d", as.integer(col("cod-ca"))), sprintf("%02d", as.integer(col("cod-prv")))))
  x <- tibble::tibble(anio = as.integer(col("ano")), trimestre = as.integer(col("trim")), nivel = nivel, geo_id = codigo,
                      compraventas = registradores_numero(col("viv-num")), importe_medio = registradores_numero(col("viv-imp")),
                      precio_m2 = registradores_numero(col("viv-pm2")))
  malas <- is.na(x$anio) | is.na(x$trimestre) | !x$trimestre %in% 1:4 | is.na(x$geo_id) | grepl("NA", x$geo_id, fixed = TRUE)
  if (any(malas)) stop("Registradores: ", sum(malas), " filas sin a\u00f1o, trimestre o c\u00f3digo legibles", call. = FALSE)
  x[order(x$anio, x$trimestre, match(x$nivel, REGISTRADORES_NIVELES), x$geo_id), ]
}

# Valor anual: el cuarto trimestre, que acumula el año natural. Una fila por territorio y año.
registradores_anual <- function(trimestral, anios = NULL) {
  x <- trimestral[trimestral$trimestre == 4L, ]
  if (!is.null(anios)) x <- x[x$anio %in% anios, ]
  x$trimestre <- NULL
  x
}

# Tabla larga: precio por m² de vivienda (indicador 11, precio_compra_m2) de España, comunidades y
# provincias, con la precisión de la fuente; estado «dato»; sin cifra, «ausente».
registradores_armonizar <- function(trimestral, version, anios = REGISTRADORES_ANIOS) {
  a <- registradores_anual(trimestral, anios)
  tibble::tibble(geo_id = a$geo_id, nivel = a$nivel, anio = a$anio, indicador = "precio_compra_m2", corte = "total",
                 grupo = "total", valor = a$precio_m2, estado = ifelse(is.na(a$precio_m2), "ausente", "dato"),
                 fuente = "registradores", geo_ref = "2021", version = version)[COLUMNAS_TABLA_LARGA]
}

# Compuerta de la lectura (inventario/referencias_validacion.csv):
#   registradores_lectura (bloqueo): por año (desde `desde`), trimestres sin las 52 provincias, las 19
#     comunidades o España, filas repetidas y cifras de vivienda vacías o no positivas;
#   registradores_espana (bloqueo, ±0,5): las cifras de REGISTRADORES_REFERENCIAS;
#   registradores_suma (bloqueo): por año, sumas que no cuadran: en cada trimestre, las compraventas
#     de las provincias frente a las de España y frente a las de cada comunidad;
#   registradores_agregado (alerta, ±3 %): por año (cuarto trimestre), desviación del precio por m²
#     de cada comunidad de varias provincias y de España frente a la media de sus provincias
#     ponderada por compraventas (la fuente no da los m², así que no es una identidad exacta);
#   registradores_rango (bloqueo): precios por m² fuera de REGISTRADORES_RANGO_M2.
# `territorios`: territorios_2021 (códigos del INE de provincias y comunidades); sin él, 01–52 y 01–19.
registradores_comprobar <- function(trimestral, territorios = NULL, referencias = REGISTRADORES_REFERENCIAS,
                                    desde = min(REGISTRADORES_ANIOS)) {
  provincias <- if (is.null(territorios)) sprintf("%02d", 1:52) else territorios$codigo[territorios$nivel == "provincia"]
  comunidades <- if (is.null(territorios)) sprintf("%02d", 1:19) else territorios$codigo[territorios$nivel == "ccaa"]
  tp <- if (is.null(territorios)) NULL else territorios[territorios$nivel == "provincia", ]
  superior <- if (is.null(tp)) NULL else stats::setNames(tp$superior, tp$codigo)
  x <- trimestral[trimestral$anio >= desde, ]
  fila <- function(id, anio, detalle, calculado, referencia = 0) {
    tibble::tibble(id = id, anio = as.integer(anio), detalle = detalle, calculado = as.numeric(calculado),
                   referencia = as.numeric(referencia))
  }
  anios <- sort(unique(x$anio))
  lectura <- dplyr::bind_rows(lapply(anios, function(a) {
    d <- x[x$anio == a, ]
    faltan <- sum(vapply(sort(unique(d$trimestre)), function(t) {
      q <- d[d$trimestre == t, ]
      length(setdiff(provincias, q$geo_id[q$nivel == "provincia"])) +
        length(setdiff(comunidades, q$geo_id[q$nivel == "ccaa"])) + as.integer(!"00" %in% q$geo_id[q$nivel == "nacional"])
    }, numeric(1)))
    repetidas <- sum(duplicated(d[c("trimestre", "nivel", "geo_id")]))
    malas <- sum(is.na(d$compraventas) | is.na(d$precio_m2) | is.na(d$importe_medio) | d$compraventas < 0 |
                   d$precio_m2 <= 0 | d$importe_medio <= 0, na.rm = TRUE)
    fila("registradores_lectura", a, "territorios que faltan, filas repetidas y cifras vac\u00edas o no positivas",
         faltan + repetidas + malas)
  }))
  anual <- registradores_anual(x)
  espana <- dplyr::bind_rows(lapply(seq_len(nrow(referencias)), function(k) {
    r <- referencias[k, ]
    v <- anual$precio_m2[anual$anio == r$anio & anual$geo_id == r$geo_id & anual$nivel == if (r$geo_id == "00") "nacional" else "provincia"]
    fila("registradores_espana", r$anio, r$detalle, if (length(v) == 1L) v else NA_real_, r$referencia)
  }))
  p <- x[x$nivel == "provincia", ]
  p$ccaa <- if (is.null(superior)) NA_character_ else unname(superior[p$geo_id])
  sumas <- dplyr::bind_rows(lapply(anios, function(a) {
    mal <- vapply(sort(unique(x$trimestre[x$anio == a])), function(t) {
      q <- x[x$anio == a & x$trimestre == t, ]
      pq <- p[p$anio == a & p$trimestre == t, ]
      n_esp <- q$compraventas[q$nivel == "nacional"]
      m <- as.integer(length(n_esp) != 1L || abs(sum(pq$compraventas) - n_esp) > 0.5)
      if (!is.null(superior)) {
        por_ccaa <- tapply(pq$compraventas, pq$ccaa, sum)
        cc <- q[q$nivel == "ccaa", ]
        m <- m + sum(is.na(match(cc$geo_id, names(por_ccaa))) | abs(cc$compraventas - por_ccaa[cc$geo_id]) > 0.5, na.rm = TRUE)
      }
      m
    }, numeric(1))
    fila("registradores_suma", a, "sumas de provincias que no cuadran con su comunidad o con Espa\u00f1a (por trimestre)", sum(mal))
  }))
  # Precio por m2 agregado (cuarto trimestre): Espana y comunidades de varias provincias
  pa <- p[p$trimestre == 4L, ]
  media <- function(d) sum(d$compraventas * d$precio_m2) / sum(d$compraventas)
  agregado <- dplyr::bind_rows(lapply(anios, function(a) {
    filas <- list()
    e <- anual[anual$anio == a & anual$nivel == "nacional", ]
    if (nrow(e) == 1L && any(pa$anio == a)) {
      filas[[1]] <- fila("registradores_agregado", a, "Espa\u00f1a frente a sus provincias (%)",
                         100 * (e$precio_m2 / media(pa[pa$anio == a, ]) - 1))
    }
    if (!is.null(superior)) {
      varias <- names(which(table(superior) > 1))
      for (cc in varias) {
        c1 <- anual[anual$anio == a & anual$nivel == "ccaa" & anual$geo_id == cc, ]
        d <- pa[pa$anio == a & pa$ccaa %in% cc, ]
        if (nrow(c1) == 1L && nrow(d)) {
          filas[[length(filas) + 1L]] <- fila("registradores_agregado", a, paste0("comunidad ", cc, " frente a sus provincias (%)"),
                                              100 * (c1$precio_m2 / media(d) - 1))
        }
      }
    }
    dplyr::bind_rows(filas)
  }))
  rango <- dplyr::bind_rows(lapply(anios, function(a) {
    d <- x[x$anio == a & !is.na(x$precio_m2), ]
    fila("registradores_rango", a, sprintf("precios por m\u00b2 fuera de %d\u2013%d \u20ac", REGISTRADORES_RANGO_M2[1], REGISTRADORES_RANGO_M2[2]),
         sum(d$precio_m2 < REGISTRADORES_RANGO_M2[1] | d$precio_m2 > REGISTRADORES_RANGO_M2[2]))
  }))
  dplyr::bind_rows(lectura, espana, sumas, agregado, rango)
}

# Coherencia del valor tasado con el precio por m² de Registradores (pregunta 45 b): mismo
# territorio y año, provincia frente a provincia, €/m² frente a €/m². `larga_valor_tasado`: el
# indicador 12 en la tabla larga (año: media de sus trimestres ponderada por tasaciones).
#   registradores_tasado_espana (bloqueo): años en que el cociente de España cae fuera de
#     REGISTRADORES_RATIO_TASADO$espana (0 o 1 por año);
#   registradores_tasado_provincias (bloqueo, ±5 %): por año, % de provincias fuera de $bloqueo;
#   registradores_tasado_detalle (alerta): cada provincia y año fuera de $aviso.
registradores_coherencia_tasado <- function(trimestral, larga_valor_tasado, intervalos = REGISTRADORES_RATIO_TASADO,
                                            anios = REGISTRADORES_ANIOS) {
  r <- registradores_anual(trimestral, anios)
  t <- larga_valor_tasado[larga_valor_tasado$indicador == "valor_tasado_m2" & larga_valor_tasado$corte == "total" &
                            larga_valor_tasado$nivel %in% c("nacional", "provincia") & !is.na(larga_valor_tasado$valor),
                          c("geo_id", "nivel", "anio", "valor")]
  j <- dplyr::inner_join(r[c("geo_id", "nivel", "anio", "precio_m2")], t, by = c("geo_id", "nivel", "anio"))
  j <- j[!is.na(j$precio_m2), ]
  j$cociente <- j$precio_m2 / j$valor
  e <- j[j$nivel == "nacional", ]
  p <- j[j$nivel == "provincia", ]
  espana <- tibble::tibble(id = "registradores_tasado_espana", anio = as.integer(e$anio),
                           detalle = sprintf("Espa\u00f1a: %.3f", e$cociente),
                           calculado = as.numeric(e$cociente < intervalos$espana[1] | e$cociente > intervalos$espana[2]),
                           referencia = 0)
  provincias <- p |>
    dplyr::group_by(anio) |>
    dplyr::summarise(calculado = 100 * mean(cociente < intervalos$bloqueo[1] | cociente > intervalos$bloqueo[2]),
                     n = dplyr::n(), .groups = "drop") |>
    dplyr::transmute(id = "registradores_tasado_provincias", anio = as.integer(anio), detalle = sprintf("%d provincias", n),
                     calculado = as.numeric(calculado), referencia = 0)
  detalle <- p[p$cociente < intervalos$aviso[1] | p$cociente > intervalos$aviso[2], ]
  detalle <- tibble::tibble(id = "registradores_tasado_detalle", anio = as.integer(detalle$anio),
                            detalle = sprintf("provincia %s: %.3f", detalle$geo_id, detalle$cociente), calculado = 1, referencia = 0)
  dplyr::bind_rows(espana, provincias, detalle)
}
