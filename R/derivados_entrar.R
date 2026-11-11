# Indicadores de «entrar» (backlog, tarea 37; decisiones 1, 5, 9 y 18): comparan la oferta de los
# portales (indicador 13, capa desmontable; R/fuente_portales.R) con el parque alquilado del SERPAVI
# (indicadores 8 y 9, vivienda colectiva) y con el ingreso de las fichas. Solo con PORTALES=TRUE:
# nada de aquí entra en la tabla larga, en las descargas ni en el release (decisión 3).
#
#   superficie_tipica: alquiler mensual mediano / alquiler por m² mediano del SERPAVI (m²). Es el
#     cociente de dos medianas, no la mediana de las superficies; y son m² catastrales del contrato,
#     no los del anuncio. Solo del SERPAVI;
#   brecha_entrar_quedarse: oferta (€/m²) / alquiler por m² mediano del SERPAVI, por territorio y año.
#     Compara dos fuentes, rotulada como tal: no las mezcla en una cifra (regla 5);
#   sueldo_entrar: oferta × superficie típica / umbral (€ netos al mes);
#   sueldo_entrar_50: oferta × 50 m² / umbral, el mínimo de una persona;
#   barrera_entrar: oferta × 50 m² / ingreso neto mensual de la ficha × 100 (%), por ficha (tartera,
#     mochila y transistor), con el ingreso del mismo año (regla 4).
# Términos como los recibe la web (termino_publicado(): el SERPAVI y el ingreso de las fichas, a un
# decimal; la oferta, la media anual a dos decimales de anualizar_portales()). Estado: el peor de sus
# términos (peor_estado()); en la barrera, el de la oferta, o «ausente» sin ingreso
# (estado_peso_alquiler()). Sin informe del portal o sin SERPAVI ese año, «ausente».
#
# En la web, solo por tramos (decisión 18). Con la cifra exacta se reconstruye la oferta: la brecha,
# por el alquiler del SERPAVI, que es público; el sueldo de 50 m², por 0,30 / 50. Y con varios
# juegos de tramos, uno por indicador, también: cada juego corta la oferta por otro sitio, porque
# cada indicador es la oferta por un número público distinto en cada territorio (el alquiler del
# SERPAVI, la superficie típica, el ingreso de cada ficha), y la intersección de los tramos la
# estrecha mucho más que cualquiera de ellos. Por eso a la web solo llega UN dato derivado de la
# oferta por territorio y año, el tramo de la brecha (inventario/entrar_tramos.csv, con un ancho
# mínimo comprobado por la compuerta), y los demás son intervalos que la página calcula con ese
# tramo y cifras públicas, porque todos son la brecha por una cifra de «quedarse»:
#   sueldo_entrar    = brecha × alquiler mensual mediano / umbral;
#   sueldo_entrar_50 = brecha × alquiler por m² mediano × 50 / umbral (= brecha × indicador 21);
#   barrera_entrar   = brecha × alquiler por m² mediano × 50 / ingreso × 100 (= brecha × indicador 15).
# El intervalo [límite inferior del tramo, límite superior) × esa cifra no dice nada que no diga el
# tramo. Vale también para «Tu ficha» (el sueldo que escribe el usuario): la barrera se lee con los
# tramos de «¿te llega?» y, si el intervalo cruza un corte, «en el límite». web/js/entrar.js hace las
# mismas cuentas, en el mismo orden (entrar_intervalo(), entrar_llega()); la prueba compartida
# pruebas/datos/entrar_inventado.json comprueba que R y la página coinciden.
#
# Compuerta (inventario/referencias_validacion.csv; entrar_comprobar() y entrar_comprobar_web()):
# entrar_tramos, entrar_rango, entrar_rango_detalle, entrar_estado, entrar_coherencia,
# entrar_municipios, entrar_mediana, entrar_mediana_rango, entrar_superficie, entrar_ipva y
# web_entrar.

ENTRAR_BASE <- "brecha_entrar_quedarse"                 # el único indicador de «entrar» con fichero en la web
ENTRAR_GRUPO_OFERTA <- "alquiler_idealista"             # serie de la capa de portales (operación y portal)
ENTRAR_NIVELES <- c("nacional", "ccaa", "provincia", "municipio")
ENTRAR_FICHAS <- c("tartera", "mochila", "transistor")
ENTRAR_DERIVADOS <- c("sueldo_entrar", "sueldo_entrar_50", "barrera_entrar")
DIR_WEB_ENTRAR <- file.path("datos", "portales", "entrar")   # dentro de la capa (DIR_WEB_PORTALES)
# Holgura del tramo en los cortes: una brecha que vale el corte en decimal (11,5 / 10 = 1,15) va al
# tramo de arriba aunque la división binaria quede una millonésima de millonésima por debajo.
ENTRAR_HOLGURA <- 1e-12
# Cifras de referencia de la tarea 37 (backlog; cálculo fuera del pipeline del 10-nov-2026):
# municipios con oferta y SERPAVI el mismo año, brecha mediana municipal y superficie típica
# mediana de esos municipios; la mediana de 2024, además, entre 1,30 y 1,40 (entrar_mediana_rango).
ENTRAR_REFERENCIAS <- list(
  municipios = c("2015" = 256, "2024" = 259),
  mediana = c("2015" = 1.16, "2024" = 1.35),
  mediana_rango = c("2024" = 1.35),
  superficie = c("2024" = 77)
)
# Aviso de la tarea 36: provincias donde la oferta crece más del doble que los contratos nuevos del
# IPVA (var_alquiler, corte contrato, grupo nuevo) en el mismo periodo.
ENTRAR_IPVA <- list(desde = 2021L, hasta = 2024L, veces = 2)

# Tramos de inventario/entrar_tramos.csv (regla 7): una fila por indicador de «entrar» de la web.
entrar_leer_tramos <- function(ruta = file.path("inventario", "entrar_tramos.csv")) {
  readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = "", locale = readr::locale(encoding = "UTF-8"))
}

# Cortes de un indicador: numéricos, con los límites, el ancho mínimo y el aviso si los tiene.
entrar_cortes <- function(tramos, indicador = ENTRAR_BASE) {
  f <- tramos[tramos$indicador == indicador, ]
  if (nrow(f) != 1L) stop("inventario/entrar_tramos.csv: falta la fila de ", indicador, call. = FALSE)
  numero <- function(x) if (is.na(x) || !nzchar(x)) NA_real_ else as.numeric(x)
  cortes <- if (is.na(f$cortes) || !nzchar(f$cortes)) numeric() else as.numeric(strsplit(f$cortes, ";", fixed = TRUE)[[1]])
  list(cortes = cortes, limites = c(numero(f$limite_inferior), numero(f$limite_superior)),
       ancho_minimo = numero(f$ancho_minimo), aviso = numero(f$aviso), tramos_de = f$tramos_de)
}

# Tramo de cada cifra: 0 por debajo del primer corte; k si cortes[k] <= x < cortes[k + 1]; NA sin cifra.
entrar_tramo <- function(x, cortes) {
  r <- rep(NA_integer_, length(x))
  ok <- !is.na(x)
  r[ok] <- findInterval(x[ok] * (1 + ENTRAR_HOLGURA), cortes)
  r
}

# Límites [desde, hasta) del tramo k: los cortes, con los de la compuerta en los extremos.
entrar_limites_tramo <- function(tramo, b) {
  bordes <- c(b$limites[1], b$cortes, b$limites[2])
  list(desde = bordes[tramo + 1L], hasta = bordes[tramo + 2L])
}

# Piso de dos sueldos iguales: 70 m² por defecto, cambiable a 50 o 90 en la web (plan §11, pregunta 43 h).
ENTRAR_SUPERFICIE_DOS <- supuesto("superficie_dos_sueldos")   # inventario/supuestos.csv

# Factores públicos por los que se multiplica el tramo de la brecha (mismo orden de operaciones que
# FACTORES_ENTRAR de web/js/entrar.js): sueldo para entrar, sueldo de 50 m², barrera (proporción) y,
# entre dos sueldos iguales con el piso de dos, cada uno (sueldo_entrar_dos; solo web, como intervalo).
entrar_factores <- function(alquiler_m2, alquiler_mes, ingreso = NA_real_, superficie = SUPERFICIE_FICHA,
                            umbral = UMBRAL_SUELDO, superficie_dos = ENTRAR_SUPERFICIE_DOS) {
  list(sueldo_entrar = alquiler_mes / umbral,
       sueldo_entrar_50 = (alquiler_m2 * superficie) / umbral,
       barrera_entrar = (alquiler_m2 * superficie) / ingreso,
       sueldo_entrar_dos = (alquiler_m2 * superficie_dos) / umbral / 2)
}

# Intervalo de una cifra derivada: límites del tramo de la brecha × factor.
entrar_intervalo <- function(tramo, b, factor) {
  l <- entrar_limites_tramo(tramo, b)
  list(desde = l$desde * factor, hasta = l$hasta * factor)
}

# Tramo de «¿te llega?» de una proporción (tramoLlega() de web/js/sueldo.js): 0 hasta el 30 %, 1 del
# 30 al 40 %, 2 más del 40 %. De un intervalo, el de cada extremo: si difieren, «en el límite».
entrar_tramo_llega <- function(ratio, limites = c(0.3, 0.4)) {
  ifelse(ratio <= limites[1], 0L, ifelse(ratio <= limites[2], 1L, 2L))
}
entrar_llega <- function(intervalo, limites = c(0.3, 0.4)) {
  d <- entrar_tramo_llega(intervalo$desde, limites)
  h <- entrar_tramo_llega(intervalo$hasta, limites)
  list(desde = d, hasta = h, en_limite = d != h)
}

# Términos de cada territorio y año con oferta: la oferta (larga_portales, el grupo de
# ENTRAR_GRUPO_OFERTA), el alquiler mensual y por m² medianos de la vivienda colectiva (alquiler_vc(),
# redondeados) y el ingreso de cada ficha del mismo año (ingresos_fichas(), redondeado): la tartera
# en todos los niveles; la mochila y el transistor, el de la provincia, en provincias y municipios.
entrar_terminos <- function(larga_portales, larga_serpavi, perfiles, grupo_oferta = ENTRAR_GRUPO_OFERTA) {
  clave <- c("geo_id", "nivel", "anio")
  o <- larga_portales[larga_portales$indicador == "precio_oferta" & larga_portales$corte == CORTE_PORTALES &
                        larga_portales$grupo == grupo_oferta & larga_portales$nivel %in% ENTRAR_NIVELES, ]
  x <- tibble::tibble(geo_id = o$geo_id, nivel = o$nivel, anio = as.integer(o$anio), oferta = o$valor, e_oferta = o$estado)
  m2 <- alquiler_vc(larga_serpavi, "alquiler_m2") |> dplyr::rename(m2 = valor, e_m2 = estado)
  mes <- alquiler_vc(larga_serpavi, "alquiler_mes") |> dplyr::rename(mes = valor, e_mes = estado)
  x <- x |> dplyr::left_join(m2, by = clave) |> dplyr::left_join(mes, by = clave)
  ing <- ingresos_fichas(perfiles)
  for (f in ENTRAR_FICHAS) {
    i <- ing[ing$ficha == f, ]
    m <- if (f == "tartera") match(x$anio, i$anio) else
      match(paste(ifelse(x$nivel %in% c("provincia", "municipio"), substr(x$geo_id, 1, 2), NA), x$anio), paste(i$geo_id, i$anio))
    x[[paste0("ingreso_", f)]] <- i$ingreso[m]
    x[[paste0("e_", f)]] <- i$estado[m]
  }
  x$version <- max(c(unique(larga_portales$version), unique(larga_serpavi$version)))
  x
}

# Cifras exactas en el formato de la tabla larga (no entran en ella): para la compuerta y para el
# tramo de la brecha. Fuente calculo_propio.
entrar_calcular <- function(terminos, superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  x <- terminos
  fila <- function(indicador, valor, estado, corte = "total", grupo = "total") {
    tibble::tibble(geo_id = x$geo_id, nivel = x$nivel, anio = x$anio, indicador = indicador, corte = corte, grupo = grupo,
                   valor = ifelse(con_valor(estado), valor, NA_real_), estado = estado)
  }
  e_sup <- peor_estado(x$e_m2, x$e_mes)
  sup <- x$mes / x$m2
  e_oferta <- peor_estado(x$e_oferta)
  barreras <- lapply(ENTRAR_FICHAS, function(f) {
    fila("barrera_entrar", 100 * x$oferta * superficie / x[[paste0("ingreso_", f)]],
         estado_peso_alquiler(e_oferta, x[[paste0("e_", f)]]), corte = "ficha", grupo = f)
  })
  dplyr::bind_rows(
    fila("superficie_tipica", sup, e_sup),
    fila(ENTRAR_BASE, x$oferta / x$m2, peor_estado(x$e_oferta, x$e_m2)),
    fila("sueldo_entrar", x$oferta * sup / umbral, peor_estado(x$e_oferta, x$e_m2, x$e_mes)),
    fila("sueldo_entrar_50", x$oferta * superficie / umbral, e_oferta),
    barreras
  ) |>
    dplyr::mutate(fuente = "calculo_propio", geo_ref = "2021", version = rep_len(x$version, dplyr::n()))
}

# Lo que va a la web: el tramo de la brecha y su estado, por territorio y año (decisión 18).
entrar_tramos_web <- function(entrar, tramos) {
  b <- entrar_cortes(tramos)
  x <- entrar[entrar$indicador == ENTRAR_BASE, ]
  tibble::tibble(geo_id = x$geo_id, nivel = x$nivel, anio = x$anio, indicador = x$indicador,
                 tramo = ifelse(con_valor(x$estado), entrar_tramo(x$valor, b$cortes), NA_integer_), estado = x$estado)
}

# Cortes de inventario/entrar_tramos.csv que no valen (entrar_tramos): la brecha, con cortes
# crecientes dentro de sus límites y cada tramo, de los límites incluidos, al menos ancho_minimo más
# ancho (el siguiente borde entre el anterior); los derivados, sin cortes propios salvo los de
# «¿te llega?» de la barrera, y con sus tramos de la brecha.
entrar_comprobar_tramos <- function(tramos) {
  b <- entrar_cortes(tramos)
  bordes <- c(b$limites[1], b$cortes, b$limites[2])
  derivados <- tramos[tramos$indicador %in% ENTRAR_DERIVADOS, ]
  barrera <- if ("barrera_entrar" %in% tramos$indicador) entrar_cortes(tramos, "barrera_entrar")$cortes else numeric()
  c(
    "cortes de la brecha" = as.numeric(!length(b$cortes) || anyNA(bordes) || is.unsorted(bordes, strictly = TRUE)),
    "tramos de la brecha mas estrechos que el ancho minimo" = if (anyNA(bordes) || is.na(b$ancho_minimo)) 1 else
      sum(bordes[-1] / bordes[-length(bordes)] < 1 + b$ancho_minimo - 1e-9),
    "indicadores derivados que faltan" = length(setdiff(ENTRAR_DERIVADOS, derivados$indicador)),
    "derivados sin el tramo de la brecha" = sum(!derivados$tramos_de %in% ENTRAR_BASE),
    "derivados con cortes propios" = sum(!is.na(derivados$cortes[derivados$indicador != "barrera_entrar"])),
    "cortes de la barrera" = as.numeric(!length(barrera) || anyNA(barrera) || is.unsorted(barrera, strictly = TRUE) ||
                                          any(barrera <= 0 | barrera >= 100))
  )
}

# Compuerta de los indicadores de «entrar» (antes de la exportación):
#   entrar_tramos (bloqueo): entrar_comprobar_tramos();
#   entrar_rango (bloqueo): brechas fuera de los límites de la fila de la brecha (0,8–2,5);
#   entrar_rango_detalle (alerta): cada brecha igual o mayor que el aviso (2);
#   entrar_estado (bloqueo): cifras con valor y estado sin valor (o al revés), y brechas cuyo
#     estado no es el peor de la oferta y el SERPAVI;
#   entrar_coherencia (bloqueo): cifras exactas de sueldo_entrar, sueldo_entrar_50 y
#     barrera_entrar fuera del intervalo que la página calcula con el tramo de su brecha;
#   entrar_municipios, entrar_mediana, entrar_mediana_rango y entrar_superficie (bloqueo):
#     municipios con oferta y SERPAVI, brecha mediana y superficie típica mediana frente a
#     ENTRAR_REFERENCIAS;
#   entrar_ipva (alerta): entrar_comprobar_ipva().
entrar_comprobar <- function(entrar, terminos, tramos, larga_portales, larga_ipva, territorios = NULL,
                             referencias = ENTRAR_REFERENCIAS, ipva = ENTRAR_IPVA,
                             superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  fila <- function(id, detalle, calculado, referencia = 0, anio = NA_integer_) {
    tibble::tibble(id = id, anio = as.integer(anio), detalle = detalle, calculado = as.numeric(calculado),
                   referencia = as.numeric(referencia))
  }
  clave <- c("geo_id", "nivel", "anio")
  b <- entrar_cortes(tramos)
  tr <- entrar_comprobar_tramos(tramos)
  brecha <- entrar[entrar$indicador == ENTRAR_BASE, ]
  con <- brecha[!is.na(brecha$valor), ]
  mun <- con[con$nivel == "municipio", ]
  nombre <- function(nivel, codigo) {
    if (is.null(territorios)) return(rep("", length(codigo)))
    n <- territorios$nombre[match(paste(nivel, codigo), paste(territorios$nivel, territorios$codigo))]
    ifelse(is.na(n), "", n)
  }
  altas <- con[con$valor >= b$aviso, ]
  aviso <- if (nrow(altas)) fila("entrar_rango_detalle", paste(altas$nivel, altas$geo_id, nombre(altas$nivel, altas$geo_id),
                                                              sprintf("%.2f", altas$valor)), 1, anio = altas$anio) else NULL
  # Estado
  t_b <- dplyr::left_join(brecha[c(clave, "estado")], terminos[c(clave, "e_oferta", "e_m2")], by = clave)
  estado <- c("cifras con valor y estado sin valor, o al reves" = sum(is.na(entrar$valor) == con_valor(entrar$estado)),
              "brechas con un estado que no es el peor de sus terminos" = sum(t_b$estado != peor_estado(t_b$e_oferta, t_b$e_m2)))
  # Coherencia: la cifra exacta, dentro del intervalo de su tramo
  w <- entrar_tramos_web(entrar, tramos)
  w <- dplyr::left_join(w[!is.na(w$tramo), c(clave, "tramo")], terminos, by = clave)
  dentro <- function(valor, i) !is.na(valor) & valor >= i$desde * (1 - 1e-9) & valor <= i$hasta * (1 + 1e-9)
  exacto <- function(ind, grupo = "total") {
    e <- entrar[entrar$indicador == ind & entrar$grupo == grupo, c(clave, "valor")]
    e$valor[match(paste(w$geo_id, w$nivel, w$anio), paste(e$geo_id, e$nivel, e$anio))]
  }
  coherencia <- c(
    sueldo_entrar = {
      v <- exacto("sueldo_entrar"); f <- entrar_factores(w$m2, w$mes, superficie = superficie, umbral = umbral)
      sum(!is.na(v) & !dentro(v, entrar_intervalo(w$tramo, b, f$sueldo_entrar)))
    },
    sueldo_entrar_50 = {
      v <- exacto("sueldo_entrar_50"); f <- entrar_factores(w$m2, w$mes, superficie = superficie, umbral = umbral)
      sum(!is.na(v) & !dentro(v, entrar_intervalo(w$tramo, b, f$sueldo_entrar_50)))
    },
    stats::setNames(vapply(ENTRAR_FICHAS, function(fi) {
      v <- exacto("barrera_entrar", fi); f <- entrar_factores(w$m2, w$mes, w[[paste0("ingreso_", fi)]], superficie, umbral)
      sum(!is.na(v) & !dentro(v, entrar_intervalo(w$tramo, b, 100 * f$barrera_entrar)))
    }, numeric(1)), paste("barrera_entrar", ENTRAR_FICHAS))
  )
  # Referencias de la tarea 37 (municipios)
  anios <- function(x) as.integer(names(x))
  med <- function(a) if (any(mun$anio == a)) stats::median(mun$valor[mun$anio == a]) else NA_real_
  sup <- entrar[entrar$indicador == "superficie_tipica" & entrar$nivel == "municipio", ]
  sup_med <- function(a) {
    s <- sup$valor[sup$anio == a & paste(sup$geo_id, sup$anio) %in% paste(mun$geo_id, mun$anio)]
    if (length(s)) stats::median(s) else NA_real_
  }
  dplyr::bind_rows(
    fila("entrar_tramos", names(tr), tr),
    fila("entrar_rango", "brechas fuera de los limites", sum(con$valor < b$limites[1] | con$valor > b$limites[2])),
    aviso,
    fila("entrar_estado", names(estado), estado),
    fila("entrar_coherencia", paste(names(coherencia), "fuera del intervalo de su tramo"), coherencia),
    fila("entrar_municipios", "municipios con oferta y SERPAVI el mismo anio", vapply(anios(referencias$municipios),
         function(a) sum(mun$anio == a), numeric(1)), referencias$municipios, anios(referencias$municipios)),
    fila("entrar_mediana", "brecha mediana de los municipios", vapply(anios(referencias$mediana), med, numeric(1)),
         referencias$mediana, anios(referencias$mediana)),
    fila("entrar_mediana_rango", "brecha mediana de los municipios", vapply(anios(referencias$mediana_rango), med, numeric(1)),
         referencias$mediana_rango, anios(referencias$mediana_rango)),
    fila("entrar_superficie", "superficie tipica mediana de los municipios con brecha", vapply(anios(referencias$superficie),
         sup_med, numeric(1)), referencias$superficie, anios(referencias$superficie)),
    entrar_comprobar_ipva(larga_portales, larga_ipva, territorios, ipva)
  )
}

# Aviso de la tarea 36 (entrar_ipva, alerta): por provincia, crecimiento de la oferta (media anual del
# portal) de `desde` a `hasta` frente al de los contratos nuevos del IPVA, encadenando sus variaciones
# anuales publicadas (la tabla larga no guarda el índice); una fila por provincia comparable, 1 si la
# oferta crece y más de `veces` lo que los contratos nuevos.
entrar_comprobar_ipva <- function(larga_portales, larga_ipva, territorios = NULL, ipva = ENTRAR_IPVA,
                                  grupo_oferta = ENTRAR_GRUPO_OFERTA) {
  vacio <- tibble::tibble(id = character(), anio = integer(), detalle = character(), calculado = numeric(), referencia = numeric())
  if (is.null(larga_ipva) || !nrow(larga_ipva)) return(vacio)
  n <- larga_ipva[larga_ipva$indicador == "var_alquiler" & larga_ipva$corte == "contrato" & larga_ipva$grupo == "nuevo" &
                    larga_ipva$nivel == "provincia" & larga_ipva$anio > ipva$desde & larga_ipva$anio <= ipva$hasta &
                    !is.na(larga_ipva$valor), ]
  nuevos <- n |> dplyr::group_by(geo_id) |>
    dplyr::summarise(anios = dplyr::n_distinct(anio), nuevos = prod(1 + valor / 100) - 1, .groups = "drop")
  nuevos <- nuevos[nuevos$anios == ipva$hasta - ipva$desde, ]
  o <- larga_portales[larga_portales$indicador == "precio_oferta" & larga_portales$grupo == grupo_oferta &
                        larga_portales$nivel == "provincia" & !is.na(larga_portales$valor), ]
  desde <- o$valor[match(paste(nuevos$geo_id, ipva$desde), paste(o$geo_id, o$anio))]
  hasta <- o$valor[match(paste(nuevos$geo_id, ipva$hasta), paste(o$geo_id, o$anio))]
  nuevos$oferta <- hasta / desde - 1
  x <- nuevos[!is.na(nuevos$oferta), ]
  if (!nrow(x)) return(vacio)
  nombre <- if (is.null(territorios)) "" else territorios$nombre[match(paste("provincia", x$geo_id), paste(territorios$nivel, territorios$codigo))]
  avisa <- x$oferta > 0 & x$oferta > ipva$veces * x$nuevos
  tibble::tibble(id = "entrar_ipva", anio = ipva$hasta,
                 detalle = paste0("provincia ", x$geo_id, " ", ifelse(is.na(nombre), "", nombre), ": la oferta crece ",
                                  sprintf("%.1f", x$oferta / x$nuevos), " veces lo que los contratos nuevos (", ipva$desde, "-", ipva$hasta, ")"),
                 calculado = as.numeric(avisa), referencia = 0)
}

# Resumen para el informe (no va a la web): por indicador, grupo, nivel y año, cifras con valor y
# percentiles 10, 50 y 90.
entrar_resumen <- function(entrar) {
  entrar[!is.na(entrar$valor), ] |>
    dplyr::group_by(indicador, grupo, nivel, anio) |>
    dplyr::summarise(n = dplyr::n(), p10 = stats::quantile(valor, 0.1), p50 = stats::median(valor),
                     p90 = stats::quantile(valor, 0.9), .groups = "drop")
}

# Exportación (desde portales_exportar_web(), en la carpeta de la capa): un fichero por nivel y año con
# el tramo de la brecha de cada territorio del índice general del nivel ({"v": [tramo o null], "e":
# estados}; sin informe o sin SERPAVI, null y «ausente») y la entrada `entrar` del manifiesto de la
# capa: los tramos (cortes, límites y aviso), la serie y cómo se derivan las demás cifras.
entrar_escribir_web <- function(web, tramos, indices, dir_web = "web") {
  b <- entrar_cortes(tramos)
  con <- web[!is.na(web$tramo), ]
  niveles <- NIVELES_WEB[NIVELES_WEB %in% con$nivel]
  anios <- sort(unique(con$anio))
  ruta <- file.path(DIR_WEB_ENTRAR, "{nivel}", ENTRAR_BASE, "{anio}.json")
  rutas <- character()
  for (nivel in niveles) {
    for (anio in anios) {
      d <- web[web$nivel == nivel & web$anio == anio, ]
      m <- match(indices[[nivel]], d$geo_id)
      f <- file.path(dir_web, ruta_valores(ruta, nivel, anio))
      dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
      writeLines(json_valores(as.integer(d$tramo[m]), estado_web(ifelse(is.na(m), "ausente", d$estado[m]))), f, useBytes = TRUE)
      rutas <- c(rutas, f)
    }
  }
  llega <- entrar_cortes(tramos, "barrera_entrar")$cortes / 100
  serie <- list(niveles = I(niveles), anios = I(as.integer(anios)), ruta = ruta, valor = "tramo", familia = "entrar",
                fuente = "calculo_propio")
  entrada <- list(
    base = ENTRAR_BASE, grupo_oferta = ENTRAR_GRUPO_OFERTA,
    tramos = list(cortes = I(b$cortes), limites = I(b$limites), aviso = b$aviso),
    series = stats::setNames(list(serie), ENTRAR_BASE),
    derivados = list(sueldo_entrar = list(serie = "alquiler_mes"),
                     sueldo_entrar_50 = list(serie = "alquiler_m2", superficie_m2 = SUPERFICIE_FICHA),
                     barrera_entrar = list(serie = "alquiler_m2", superficie_m2 = SUPERFICIE_FICHA, cortes = I(llega))),
    supuestos = list(superficie_m2 = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO)
  )
  list(manifiesto = entrada, rutas = rutas)
}

# Compuerta web_entrar (bloqueo): lo escrito en datos/portales/entrar/ reproduce los tramos de R (ida
# y vuelta) y no lleva ninguna cifra exacta.
#   - la entrada `entrar` del manifiesto de la capa existe y sus cortes y límites son los del inventario;
#   - por fichero, territorios cuyo tramo o estado no es el de R (longitud distinta del índice: todos);
#   - valores que no son un tramo (un entero de 0 al número de cortes): la privacidad de la decisión 18;
#   - tramos de R sin fichero, filas sin hueco en el índice de su nivel y ficheros de más en la carpeta;
#   - series de «entrar» en el manifiesto general (no deben estar).
entrar_comprobar_web <- function(web, tramos, jerarquia, territorios, dir_web = "web") {
  fila <- function(detalle, calculado) tibble::tibble(id = "web_entrar", detalle = detalle, calculado = as.numeric(calculado), referencia = 0)
  m <- jsonlite::fromJSON(file.path(dir_web, "datos", "portales", "manifiesto.json"), simplifyVector = FALSE)
  e <- m$entrar
  if (is.null(e)) return(fila("manifiesto de la capa sin la entrada entrar", 1))
  b <- entrar_cortes(tramos)
  distinto <- function(a, b) !isTRUE(all.equal(as.numeric(unlist(a)), b))
  filas <- list(fila("cortes o limites del manifiesto distintos del inventario",
                     distinto(e$tramos$cortes, b$cortes) + distinto(e$tramos$limites, b$limites)))
  indices <- indices_web(jerarquia, territorios)
  def <- e$series[[ENTRAR_BASE]]
  n_tramos <- length(b$cortes) + 1L
  no_tramo <- 0
  escritos <- character()
  for (nivel in unlist(def$niveles)) {
    for (anio in as.character(unlist(def$anios))) {
      ruta <- ruta_valores(def$ruta, nivel, anio)
      escritos <- c(escritos, ruta)
      x <- jsonlite::fromJSON(file.path(dir_web, ruta), simplifyVector = TRUE)
      v <- suppressWarnings(as.numeric(unlist(lapply(x$v, function(y) if (is.null(y)) NA else y))))
      leido_e <- ESTADOS_WEB[match(strsplit(x$e, "")[[1]], as.character(0:3))]
      d <- web[web$nivel == nivel & web$anio == as.integer(anio), ]
      i <- match(indices[[nivel]], d$geo_id)
      esp_t <- d$tramo[i]
      esp_e <- ifelse(is.na(i), "ausente", d$estado[i])
      n <- length(indices[[nivel]])
      mal <- if (length(v) != n || length(leido_e) != n) n else
        sum(is.na(leido_e) | leido_e != esp_e | xor(is.na(v), is.na(esp_t)) | (!is.na(v) & !is.na(esp_t) & v != esp_t))
      no_tramo <- no_tramo + sum(!is.na(v) & (v != round(v) | v < 0 | v > n_tramos - 1))
      filas[[length(filas) + 1L]] <- fila(ruta, mal)
    }
  }
  con <- web[!is.na(web$tramo), ]
  en_manifiesto <- as.vector(outer(unlist(def$niveles), as.character(unlist(def$anios)), paste))
  fuera <- vapply(names(indices), function(n) sum(!con$geo_id[con$nivel == n] %in% indices[[n]]), numeric(1))
  carpeta <- file.path(dir_web, "datos", "portales", "entrar")
  sobran <- setdiff(file.path("datos", "portales", "entrar", list.files(carpeta, recursive = TRUE)), escritos)
  general <- file.path(dir_web, "datos", "manifiesto.json")
  en_general <- if (file.exists(general)) {
    g <- jsonlite::fromJSON(general, simplifyVector = FALSE)
    codigos <- c(ENTRAR_BASE, ENTRAR_DERIVADOS)
    sum(names(g$indicadores) %in% codigos) + sum(names(g$mapas) %in% codigos) + !is.null(g$entrar)
  } else 0
  dplyr::bind_rows(filas, fila(c("valores que no son un tramo (decision 18)", "tramos de R sin fichero",
                                 "filas sin hueco en el indice de su nivel", "ficheros de mas en datos/portales/entrar",
                                 "series de entrar en el manifiesto general"),
                               c(no_tramo, length(setdiff(unique(paste(con$nivel, con$anio)), en_manifiesto)), sum(fuera),
                                 length(sobran), en_general)))
}
