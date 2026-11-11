# F6, página «Máquina del tiempo» (web/historico.html): datos en web/datos/historico/historico.json,
# fuera de git como el resto de web/datos/, desde la tabla del módulo histórico ya validada
# (R/historico.R), las fechas clave (inventario/historico_fechas.csv) y las rupturas del módulo
# (inventario/rupturas.csv). Sin mapa.
#
# Cifras: valor × escala de su serie en enteros, con el redondeo de la guía (valor_web(),
# R/web_exportar.R); cada serie y territorio, un vector desde su primer periodo, sin huecos de
# periodos (null sin cifra). Los textos fijos van en web/i18n (sección «historico»); los de las
# fechas clave, en su CSV (castellano e inglés). Incorporado el 10-nov-2026.

HIST_DIR_WEB <- "historico"                          # bajo <dir_web>/datos/
HIST_ESCALAS_WEB <- c(anios_renta = 100, esfuerzo_teorico = 100, tipo_prestamos = 100, tipo_hipotecas = 1000, mibor_euribor = 1000,
                      valor_tasado = 10, sueldo_asalariado = 1)

hist_serie_json <- function(d, escala) {
  d <- d[order(d$anio, d$subperiodo), ]
  list(inicio = I(c(d$anio[1], d$subperiodo[1])), v = I(valor_web(d$valor, escala)))
}

hist_periodo_lista <- function(texto) {
  p <- hist_periodo(texto)
  c(p$anio, if (is.na(p$subperiodo)) 0L else p$subperiodo)
}

# Exportación completa: borra lo exportado la vez anterior. `ccaa`: geo/ccaa.csv (código y nombre
# del INE de cada comunidad); `rupturas`: inventario/rupturas.csv. Devuelve la ruta del JSON.
hist_exportar_web <- function(historico, fechas, rupturas, ccaa, dir_web = "web", fecha = format(Sys.Date())) {
  dir <- file.path(dir_web, "datos", HIST_DIR_WEB)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  series <- lapply(stats::setNames(HIST_SERIES, HIST_SERIES), function(s) {
    d <- historico[historico$serie == s, ]
    geos <- sort(unique(d$geo_id))
    list(fuente = d$fuente[1], frecuencia = d$frecuencia[1], unidad = d$unidad[1], codigo = d$codigo[1],
         version = d$version[1], escala = unname(HIST_ESCALAS_WEB[[s]]),
         territorios = stats::setNames(lapply(geos, function(g) hist_serie_json(d[d$geo_id == g, ], HIST_ESCALAS_WEB[[s]])), geos))
  })
  rup <- hist_rupturas(rupturas)
  marcas <- fechas[fechas$tipo %in% HIST_TIPOS_FECHA, ]
  datos <- list(
    version = fecha,
    desde = HIST_DESDE,
    series = series,
    territorios = stats::setNames(as.list(ccaa$nombre_ine), ccaa$codigo),
    fechas = lapply(seq_len(nrow(marcas)), function(k) {
      f <- marcas[k, ]
      list(id = f$id, serie = f$serie, geo = f$geo_id, periodo = I(hist_periodo_lista(f$periodo)), tipo = f$tipo,
           texto_es = f$texto_es, texto_en = f$texto_en, fuente = f$fuente)
    }),
    rupturas = I(rup$id)
  )
  ruta <- file.path(dir, "historico.json")
  jsonlite::write_json(datos, ruta, auto_unbox = TRUE, digits = NA, na = "null", null = "null")
  ruta
}

# Compuerta de ida y vuelta (web_historico, bloqueo): lee lo exportado y lo compara con la tabla del
# módulo, cifra a cifra (÷ escala, con el redondeo de la guía a los decimales de la escala), con el
# periodo de cada posición; series o territorios de más o de menos; fechas clave y rupturas.
hist_comprobar_web <- function(historico, fechas, rupturas, dir_web = "web") {
  x <- jsonlite::fromJSON(file.path(dir_web, "datos", HIST_DIR_WEB, "historico.json"), simplifyVector = FALSE)
  filas <- list()
  anota <- function(detalle, mal) {
    filas[[length(filas) + 1L]] <<- tibble::tibble(id = "web_historico", anio = NA_integer_, detalle = detalle,
                                                   calculado = as.numeric(sum(mal | is.na(mal))), referencia = 0)
  }
  anota("series de m\u00e1s o de menos", c(!setequal(names(x$series), HIST_SERIES)))
  for (s in intersect(HIST_SERIES, names(x$series))) {
    js <- x$series[[s]]
    d <- historico[historico$serie == s, ]
    escala <- HIST_ESCALAS_WEB[[s]]
    mal <- c(!setequal(names(js$territorios), unique(d$geo_id)), !identical(as.numeric(js$escala), as.numeric(escala)),
             !identical(js$frecuencia, d$frecuencia[1]), !identical(js$fuente, d$fuente[1]))
    n <- HIST_SUBPERIODOS[[d$frecuencia[1]]]
    for (g in intersect(names(js$territorios), unique(d$geo_id))) {
      t_g <- js$territorios[[g]]
      dg <- d[d$geo_id == g, ]
      dg <- dg[order(dg$anio, dg$subperiodo), ]
      v <- vapply(t_g$v, function(z) if (is.null(z)) NA_real_ else as.numeric(z) / escala, 0)
      inicio <- as.integer(unlist(t_g$inicio))
      k <- seq_along(v) - 1L
      indice <- inicio[1] * n + pmax(inicio[2], 1L) - 1L + k
      anio <- indice %/% n
      sub <- if (n == 1L) rep(0L, length(k)) else indice %% n + 1L
      esperado <- redondeo_guia(dg$valor, decimales_escala(escala))
      mal <- c(mal, length(v) != nrow(dg))
      if (length(v) == nrow(dg)) {
        mal <- c(mal, anio != dg$anio | sub != dg$subperiodo,
                 xor(is.na(v), is.na(esperado)) | (!is.na(v) & !is.na(esperado) & abs(v - esperado) > 1e-9))
      }
    }
    anota(s, mal)
  }
  # Fechas clave y rupturas
  ids <- vapply(x$fechas, function(f) f$id, "")
  periodos <- vapply(x$fechas, function(f) paste(unlist(f$periodo), collapse = "-"), "")
  esperados <- vapply(fechas$periodo, function(p) paste(hist_periodo_lista(p), collapse = "-"), "", USE.NAMES = FALSE)
  anota("fechas clave", c(!setequal(ids, fechas$id), periodos[match(fechas$id, ids)] != esperados))
  anota("rupturas", !setequal(as.character(unlist(x$rupturas)), hist_rupturas(rupturas)$id))
  dplyr::bind_rows(filas)
}
