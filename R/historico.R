# F6, módulo histórico («máquina del tiempo»; plan §7): series nacionales y de comunidad desde 1987
# en una tabla propia (no en la tabla larga: hay series trimestrales y mensuales, y el año de la
# tabla larga es anual; regla 4). Una fila por serie, territorio y periodo:
#   serie | geo_id | nivel | frecuencia | anio | subperiodo | valor | unidad | fuente | codigo | version
# `subperiodo`: trimestre (1–4), mes (1–12) o 0 en las anuales. Series:
#   anios_renta, esfuerzo_teorico      Banco de España, trimestrales, España (R/fuente_bde.R);
#   tipo_hipotecas, mibor_euribor      Banco de España, tipos oficiales de referencia, mensuales;
#   valor_tasado                       MIVAU, €/m², trimestral desde 1995, España y comunidades
#                                      (lectura de F4: objetivo valor_tasado_trim);
#   sueldo_asalariado                  INE, Contabilidad Nacional, € al año, España (R/fuente_ine_cne.R).
# Cada serie conserva su fuente y su unidad: no se combinan en un indicador (reglas 4 y 5).
# Fechas clave (inventario/historico_fechas.csv) y cifras publicadas para la compuerta
# (inventario/historico_referencias.csv), en CSV (regla 7). Incorporado el 10-nov-2026.

HIST_SERIES <- c("anios_renta", "esfuerzo_teorico", "tipo_hipotecas", "mibor_euribor", "valor_tasado", "sueldo_asalariado")
HIST_COLUMNAS_TABLA <- c(HIST_COLUMNAS, "version")
# Rango creíble de cada serie: fuera, error de lectura o de la fuente (compuerta hist_series)
HIST_RANGOS <- list(anios_renta = c(1, 20), esfuerzo_teorico = c(5, 100), tipo_hipotecas = c(-1, 25),
                    mibor_euribor = c(-2, 25), valor_tasado = c(200, 15000), sueldo_asalariado = c(5000, 100000))
HIST_SUBPERIODOS <- c(trimestral = 4L, mensual = 12L, anual = 1L)

# Rejilla completa de periodos de cada serie y territorio, del primer dato al último: los periodos
# que faltan entran con valor NA (la compuerta los cuenta y la web los deja en blanco).
hist_completar <- function(x) {
  if (!nrow(x)) return(x)
  partes <- split(x, paste(x$serie, x$geo_id, sep = "|"), drop = TRUE)
  dplyr::bind_rows(lapply(partes, function(d) {
    n <- HIST_SUBPERIODOS[[d$frecuencia[1]]]
    indice <- function(a, s) a * n + pmax(s, 1L) - 1L
    i <- indice(d$anio, d$subperiodo)
    con <- !is.na(d$valor)
    if (!any(con)) return(d[0, ])
    todos <- seq(min(i[con]), max(i[con]))
    rejilla <- tibble::tibble(anio = as.integer(todos %/% n),
                              subperiodo = if (n == 1L) 0L else as.integer(todos %% n + 1L))
    fijo <- d[1, setdiff(names(d), c("anio", "subperiodo", "valor"))]
    r <- dplyr::left_join(rejilla, d[c("anio", "subperiodo", "valor")], by = c("anio", "subperiodo"),
                          relationship = "many-to-many")
    dplyr::bind_cols(fijo[rep(1L, nrow(r)), ], r)[names(d)]
  }))
}

# Valor tasado trimestral del MIVAU (objetivo valor_tasado_trim de F4: nivel, geo_id, anio,
# trimestre, valor, tasaciones) en el formato del módulo: España y comunidades, desde su primer
# dato; las cifras fuera de RANGO_VALOR_TASADO (R/fuente_mivau_valor_tasado.R), como NA.
hist_valor_tasado <- function(trimestral, desde = HIST_DESDE, rango = HIST_RANGOS$valor_tasado) {
  d <- trimestral[trimestral$nivel %in% c("nacional", "ccaa") & trimestral$anio >= desde, ]
  d$valor[!is.na(d$valor) & (d$valor < rango[1] | d$valor > rango[2])] <- NA_real_
  hist_columnas(tibble::tibble(serie = "valor_tasado", geo_id = d$geo_id, nivel = d$nivel, frecuencia = "trimestral",
                               anio = d$anio, subperiodo = d$trimestre, valor = d$valor, unidad = "euros_m2",
                               fuente = "mivau_valor_tasado", codigo = "35101000"))
}

# Tabla del módulo: las series del Banco de España que se publican, el valor tasado y el sueldo,
# completas (hist_completar()) y con la versión de su fuente (`versiones`: vector con nombre por
# fuente, la fecha de su fichero).
hist_armar <- function(series_bde, valor_tasado, sueldo, versiones) {
  x <- dplyr::bind_rows(series_bde[!series_bde$serie %in% HIST_SOLO_COMPUERTA, ], valor_tasado, sueldo)
  x <- hist_completar(x)
  sin <- setdiff(unique(x$fuente), names(versiones))
  if (length(sin)) stop("Fuentes sin versi\u00f3n: ", paste(sin, collapse = ", "), call. = FALSE)
  x$version <- unname(versiones[x$fuente])
  x <- x[order(match(x$serie, HIST_SERIES), x$geo_id, x$anio, x$subperiodo), HIST_COLUMNAS_TABLA]
  tibble::as_tibble(x)
}

hist_exportar_parquet <- function(historico, ruta = file.path("datos", "intermedios", "historico.parquet")) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  arrow::write_parquet(historico, ruta)
  ruta
}

# --- Periodos ------------------------------------------------------------------------------------

# Un periodo escrito («1987-T1», «2026-08», «2023») como lista: anio, subperiodo (NA en un año) y
# frecuencia («trimestral», «mensual» o «anual»). NULL si no se reconoce.
hist_periodo <- function(texto) {
  texto <- trimws(texto)
  if (grepl("^[0-9]{4}-T[1-4]$", texto)) return(list(anio = as.integer(substr(texto, 1, 4)), subperiodo = as.integer(substr(texto, 7, 7)), frecuencia = "trimestral"))
  if (grepl("^[0-9]{4}-(0[1-9]|1[0-2])$", texto)) return(list(anio = as.integer(substr(texto, 1, 4)), subperiodo = as.integer(substr(texto, 6, 7)), frecuencia = "mensual"))
  if (grepl("^[0-9]{4}$", texto)) return(list(anio = as.integer(texto), subperiodo = NA_integer_, frecuencia = "anual"))
  NULL
}

hist_periodo_texto <- function(anio, subperiodo, frecuencia) {
  ifelse(frecuencia == "trimestral", sprintf("%d-T%d", anio, subperiodo),
         ifelse(frecuencia == "mensual", sprintf("%d-%02d", anio, subperiodo), sprintf("%d", anio)))
}

# Valor de una serie en un periodo. Un año en una serie trimestral o mensual es la media simple de
# sus periodos, solo si están todos (así publica el Banco de España sus datos anuales); si no, NA.
hist_valor_en <- function(historico, serie, geo_id, periodo) {
  p <- hist_periodo(periodo)
  d <- historico[historico$serie == serie & historico$geo_id == geo_id, ]
  if (is.null(p) || !nrow(d)) return(NA_real_)
  if (is.na(p$subperiodo)) {
    a <- d$valor[d$anio == p$anio]
    n <- HIST_SUBPERIODOS[[d$frecuencia[1]]]
    if (length(a) != n || anyNA(a)) return(NA_real_)
    return(mean(a))
  }
  if (p$frecuencia != d$frecuencia[1]) return(NA_real_)
  v <- d$valor[d$anio == p$anio & d$subperiodo == p$subperiodo]
  if (length(v) == 1L) v else NA_real_
}

# Periodo del máximo o del mínimo de una serie (el primero si se repite), como texto.
hist_extremo <- function(historico, serie, geo_id, cual = c("maximo", "minimo")) {
  cual <- match.arg(cual)
  d <- historico[historico$serie == serie & historico$geo_id == geo_id & !is.na(historico$valor), ]
  if (!nrow(d)) return(NA_character_)
  i <- if (cual == "maximo") which.max(d$valor) else which.min(d$valor)
  hist_periodo_texto(d$anio[i], d$subperiodo[i], d$frecuencia[i])
}

# --- Inventario ----------------------------------------------------------------------------------

HIST_TIPOS_FECHA <- c("maximo", "minimo", "evento", "ruptura")

# Rupturas del módulo: las de inventario/rupturas.csv con indicador «historico» y estado «aplicado».
hist_rupturas <- function(rupturas) {
  del <- vapply(strsplit(as.character(rupturas$indicador), ";", fixed = TRUE), function(i) "historico" %in% trimws(i), TRUE)
  rupturas[del & rupturas$estado %in% "aplicado", ]
}
hist_leer_fechas <- function(ruta) {
  f <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = character())
  necesarias <- c("id", "serie", "geo_id", "periodo", "tipo", "texto_es", "texto_en", "fuente")
  if (!all(necesarias %in% names(f))) stop("historico_fechas.csv sin las columnas ", paste(setdiff(necesarias, names(f)), collapse = ", "), call. = FALSE)
  f
}

HIST_COMPARACIONES <- c("igual", "menor", "maximo", "minimo")
hist_leer_referencias <- function(ruta) {
  r <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = character())
  necesarias <- c("id", "serie", "geo_id", "periodo", "valor", "comparacion", "compuerta", "fuente", "fecha")
  if (!all(necesarias %in% names(r))) stop("historico_referencias.csv sin las columnas ", paste(setdiff(necesarias, names(r)), collapse = ", "), call. = FALSE)
  r$valor <- as.numeric(r$valor)
  r
}

# --- Compuerta -----------------------------------------------------------------------------------

# Comprobaciones del módulo (inventario/referencias_validacion.csv; todas por debajo de su tolerancia):
#   hist_series (bloqueo): por serie de España, periodos sin cifra entre el primero y el último,
#     periodos repetidos y cifras fuera de HIST_RANGOS; series que faltan;
#   hist_publicadas (bloqueo, ±0,05) y hist_publicadas_enteras (bloqueo, ±0,5): cada cifra publicada
#     de inventario/historico_referencias.csv (tablas del Banco de España con un decimal, el BOE) frente
#     a la serie, con la media simple de los periodos de un año;
#   hist_prensa (bloqueo, ±0,5): las cifras de prensa del plan que la serie confirma («igual»,
#     «menor que», «máximo en»); las que no confirma van con la compuerta «ninguna» y no se comprueban;
#   hist_fechas (bloqueo): fechas clave de inventario/historico_fechas.csv cuyo máximo o mínimo no
#     está en su periodo, o cuyo periodo cae fuera de la serie; rupturas del módulo de
#     inventario/rupturas.csv sin su fecha de tipo «ruptura», o al revés;
#   hist_valor_tasado_bde (bloqueo, ±0,1 €/m²): el valor tasado de España del MIVAU frente al que
#     publica el Banco de España (si_1_5), en todos los trimestres comunes;
#   hist_valor_tasado_ccaa (alerta): por año, trimestres en que una comunidad de varias provincias
#     queda fuera del intervalo de sus provincias, y trimestres sin cifra de las comunidades.
hist_comprobar <- function(historico, series_bde, valor_tasado_trim, territorios, fechas, referencias_hist,
                           rupturas = NULL) {
  filas <- list()
  anota <- function(id, detalle, calculado, referencia = 0, anio = NA_integer_) {
    filas[[length(filas) + 1L]] <<- tibble::tibble(id = id, anio = as.integer(anio), detalle = detalle,
                                                   calculado = as.numeric(calculado), referencia = as.numeric(referencia))
  }
  nac <- historico[historico$geo_id == "00", ]
  for (s in HIST_SERIES) {
    d <- nac[nac$serie == s, ]
    if (!nrow(d)) {
      anota("hist_series", paste(s, "sin cifras"), 1)
      next
    }
    r <- HIST_RANGOS[[s]]
    anota("hist_series", paste0(s, ": huecos, repetidos y fuera de rango (", hist_periodo_texto(d$anio[1], d$subperiodo[1], d$frecuencia[1]),
                                "\u2013", hist_periodo_texto(d$anio[nrow(d)], d$subperiodo[nrow(d)], d$frecuencia[1]), ")"),
          sum(is.na(d$valor)) + sum(duplicated(d[c("anio", "subperiodo")])) +
            sum(!is.na(d$valor) & (d$valor < r[1] | d$valor > r[2])))
  }

  # Cifras publicadas y de prensa
  for (k in seq_len(nrow(referencias_hist))) {
    ref <- referencias_hist[k, ]
    if (ref$compuerta == "ninguna") next
    if (ref$comparacion %in% c("maximo", "minimo")) {
      en <- hist_extremo(historico, ref$serie, ref$geo_id, ref$comparacion)
      v <- if (identical(en, ref$periodo)) hist_valor_en(historico, ref$serie, ref$geo_id, ref$periodo) else NA_real_
      anota(ref$compuerta, paste0(ref$serie, " ", ref$comparacion, " en ", ref$periodo, " (", ref$fuente, "; est\u00e1 en ", en, ")"),
            v, ref$valor)
    } else if (ref$comparacion == "menor") {
      v <- hist_valor_en(historico, ref$serie, ref$geo_id, ref$periodo)
      anota(ref$compuerta, paste0(ref$serie, " ", ref$periodo, " por debajo de ", ref$valor, " (", ref$fuente, "; ", format(v), ")"),
            as.numeric(!is.na(v) & v < ref$valor), 1)
    } else {
      v <- if (ref$serie %in% historico$serie) hist_valor_en(historico, ref$serie, ref$geo_id, ref$periodo) else
        hist_valor_en(series_bde, ref$serie, ref$geo_id, ref$periodo)
      anota(ref$compuerta, paste0(ref$serie, " ", ref$periodo, " (", ref$fuente, ")"), v, ref$valor)
    }
  }

  # Fechas clave
  mal <- vapply(seq_len(nrow(fechas)), function(k) {
    f <- fechas[k, ]
    if (!f$tipo %in% HIST_TIPOS_FECHA || is.null(hist_periodo(f$periodo))) return(TRUE)
    if (f$tipo %in% c("maximo", "minimo")) return(!identical(hist_extremo(historico, f$serie, f$geo_id, f$tipo), f$periodo))
    p <- hist_periodo(f$periodo)
    d <- historico[historico$serie == f$serie & historico$geo_id == f$geo_id, ]
    if (!nrow(d) || p$frecuencia != d$frecuencia[1]) return(TRUE)
    clave <- p$anio * 100L + p$subperiodo
    clave < min(d$anio * 100L + d$subperiodo) || clave > max(d$anio * 100L + d$subperiodo)
  }, TRUE)
  anota("hist_fechas", paste0("fechas clave mal situadas", if (any(mal)) paste0(": ", paste(fechas$id[mal], collapse = ", ")) else ""),
        sum(mal) + sum(duplicated(fechas$id)) + sum(!fechas$serie %in% HIST_SERIES) +
          sum(!nzchar(trimws(fechas$texto_es)) | !nzchar(trimws(fechas$texto_en))))
  # Rupturas: las del m\u00f3dulo en inventario/rupturas.csv (indicador \u00abhistorico\u00bb, aplicadas) y las
  # fechas de tipo \u00abruptura\u00bb, las mismas
  if (!is.null(rupturas)) {
    del_modulo <- hist_rupturas(rupturas)$id
    marcadas <- fechas$id[fechas$tipo == "ruptura"]
    anota("hist_fechas", "rupturas del m\u00f3dulo sin fecha o fechas de ruptura sin fila en rupturas.csv",
          length(setdiff(del_modulo, marcadas)) + length(setdiff(marcadas, del_modulo)))
  }

  # Valor tasado de Espa\u00f1a: MIVAU frente al Banco de Espa\u00f1a
  m <- historico[historico$serie == "valor_tasado" & historico$geo_id == "00" & !is.na(historico$valor), ]
  b <- series_bde[series_bde$serie == "valor_tasado_bde" & !is.na(series_bde$valor), ]
  comun <- dplyr::inner_join(m[c("anio", "subperiodo", "valor")], b[c("anio", "subperiodo", "valor")], by = c("anio", "subperiodo"))
  anota("hist_valor_tasado_bde", sprintf("diferencia m\u00e1xima en %d trimestres comunes (\u20ac/m\u00b2)", nrow(comun)),
        if (nrow(comun) >= 40L) max(abs(comun$valor.x - comun$valor.y)) else NA_real_)

  # Comunidades de varias provincias dentro del intervalo de sus provincias; huecos de las comunidades
  prov <- territorios[territorios$nivel == "provincia", c("codigo", "superior")]
  varias <- names(which(table(prov$superior) > 1))
  p <- valor_tasado_trim[valor_tasado_trim$nivel == "provincia" & !is.na(valor_tasado_trim$valor) &
                           valor_tasado_trim$anio >= HIST_DESDE, ]
  p$ccaa <- prov$superior[match(p$geo_id, prov$codigo)]
  # Solo los trimestres con cifra en todas las provincias de la comunidad
  n_prov <- table(prov$superior)
  intervalos <- p |> dplyr::filter(ccaa %in% varias) |> dplyr::group_by(ccaa, anio, trimestre) |>
    dplyr::summarise(minimo = min(valor), maximo = max(valor), n = dplyr::n(), .groups = "drop") |>
    dplyr::filter(n == as.integer(n_prov[ccaa]))
  cc <- historico[historico$serie == "valor_tasado" & historico$nivel == "ccaa", ]
  fuera <- dplyr::inner_join(cc, intervalos, by = c("geo_id" = "ccaa", "anio", "subperiodo" = "trimestre")) |>
    dplyr::filter(!is.na(valor), valor < minimo - 0.05 | valor > maximo + 0.05)
  for (a in sort(unique(cc$anio))) {
    anota("hist_valor_tasado_ccaa", "comunidades fuera de sus provincias y trimestres sin cifra",
          sum(fuera$anio == a) + sum(cc$anio == a & is.na(cc$valor)), anio = a)
  }
  dplyr::bind_rows(filas)
}
