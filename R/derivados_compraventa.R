# Indicadores derivados de compraventa (F4; plan §5 C):
#   16 anios_salario_compra: valor tasado por m² × superficie tipo (80 m²) / salario medio anual
#      bruto por asalariado (indicador 7, AEAT), en años;
#   17 esfuerzo_hipotecario: cuota del primer año de una hipoteca francesa sobre el 80 % del valor
#      de la vivienda tipo, a 25 años y al tipo de los préstamos nuevos para vivienda del Banco de
#      España del año (D_IMVTIPLV, media de sus doce meses), dividida entre la renta neta media por
#      hogar del ADRH (indicador 2), en % (plan §11, pregunta 45 d y e revisadas, 10-nov-2026).
#      Sin `renta_hogar`, el salario del 16 y el tipo que se pase (antes, el del INE).
# El precio es el valor tasado del MIVAU (indicador 12): las webs del Notariado reservan sus
# derechos y piden autorización expresa (inventario/fuentes.csv, notariado), y el 11 sale de
# Registradores, por provincia. Niveles: municipio (de más de 25.000 habitantes,
# con el salario de su provincia), provincia, comunidad y España, con el salario publicado en ese
# nivel; sin salario (País Vasco y Navarra, domicilio fiscal foral), «ausente». Mismo año en los
# dos términos (regla 4). Términos redondeados como se publican (termino_publicado(); el tipo, con
# sus dos decimales). Estado, el peor de sus términos (peor_estado(), R/derivados.R).

SUPERFICIE_COMPRA <- 80        # superficie de la vivienda tipo, en m2 (plan, 5 C)
FINANCIACION_COMPRA <- 0.80    # parte del valor financiada
PLAZO_HIPOTECA <- 25           # en anios

# Cuota mensual de un préstamo francés: capital, tipo anual en % y plazo en años.
cuota_hipoteca <- function(capital, tipo_anual, anios = PLAZO_HIPOTECA) {
  r <- tipo_anual / 100 / 12
  n <- anios * 12
  ifelse(r == 0, capital / n, capital * r / (1 - (1 + r)^(-n)))
}

# Salario medio anual bruto (indicador 7, total) desde filas en formato de la tabla larga:
# nivel, geo_id, anio, salario y su estado.
salario_referencia <- function(larga_salarios) {
  larga_salarios |>
    dplyr::filter(indicador == "salario_medio", corte == "total") |>
    dplyr::transmute(nivel, geo_id, anio, salario = termino_publicado(valor), e_salario = estado)
}

# Tipo de interés del 17 (pregunta 45 e): el de los préstamos nuevos para adquisición de vivienda de
# los hogares del Banco de España (D_IMVTIPLV, serie tipo_prestamos de series_bde, R/fuente_bde.R),
# el mismo con que calcula su esfuerzo teórico. Año: media simple de sus doce meses, a dos decimales
# (como los publica); sin los doce meses, el año no entra.
compraventa_tipo_bde <- function(series_bde, serie = "tipo_prestamos") {
  d <- series_bde[series_bde$serie == serie & !is.na(series_bde$valor), ]
  d |>
    dplyr::group_by(anio) |>
    dplyr::summarise(n = dplyr::n(), tipo = mean(valor), .groups = "drop") |>
    dplyr::filter(n == 12L) |>
    dplyr::transmute(anio = as.integer(anio), tipo = as.numeric(sprintf("%.2f", tipo))) |>
    dplyr::arrange(anio)
}

# Renta neta media por hogar del ADRH (indicador 2), denominador del 17 (pregunta 45 d): en el
# municipio, la cifra publicada («dato»); en la provincia, la comunidad y España, la media de sus
# municipios ponderada por sus hogares (suma de los de sus secciones: población / tamaño medio del
# hogar), «estimado»: el pipeline no baja la tabla del ADRH con las cifras de esos niveles. Media
# ponderada: válida hacia arriba (regla 1). `renta_adrh`: leer_ine_adrh_renta(); `pesos`:
# pesos_adrh(); `territorios`: territorios_2021 (comunidad de cada provincia).
compraventa_renta_hogar <- function(renta_adrh, pesos, territorios) {
  mun <- renta_adrh |>
    dplyr::filter(nivel == "municipio", indicador == "renta_hogar", !is.na(valor)) |>
    dplyr::transmute(anio, municipio = codigo, renta = valor)
  hog <- pesos |>
    dplyr::filter(!is.na(hogares)) |>
    dplyr::mutate(municipio = substr(seccion, 1, 5)) |>
    dplyr::group_by(anio, municipio) |>
    dplyr::summarise(hogares = sum(hogares), .groups = "drop")
  prov <- territorios[territorios$nivel == "provincia", c("codigo", "superior")]
  m <- dplyr::inner_join(mun, hog, by = c("anio", "municipio")) |>
    dplyr::filter(hogares > 0) |>
    dplyr::mutate(provincia = substr(municipio, 1, 2), ccaa = prov$superior[match(provincia, prov$codigo)], nacional = "00")
  agregar <- function(clave, nivel) {
    m |>
      dplyr::filter(!is.na(.data[[clave]])) |>
      dplyr::group_by(anio, geo_id = .data[[clave]]) |>
      dplyr::summarise(renta = sum(renta * hogares) / sum(hogares), .groups = "drop") |>
      dplyr::mutate(nivel = nivel, e_renta = "estimado")
  }
  dplyr::bind_rows(
    dplyr::transmute(mun, nivel = "municipio", geo_id = municipio, anio, renta, e_renta = "dato"),
    agregar("provincia", "provincia"), agregar("ccaa", "ccaa"), agregar("nacional", "nacional")
  ) |>
    dplyr::transmute(nivel, geo_id, anio = as.integer(anio), renta, e_renta)
}

# Términos de los dos derivados: valor tasado de cada territorio y año, con el salario del mismo
# nivel (el municipio, el de su provincia), el tipo del año y, para el 17, la renta por hogar del
# mismo territorio (compraventa_renta_hogar(); sin ella, el salario).
terminos_compraventa <- function(larga_valor_tasado, larga_salarios, tipo, renta_hogar = NULL) {
  sal <- salario_referencia(larga_salarios)
  vt <- larga_valor_tasado |>
    dplyr::filter(indicador == "valor_tasado_m2", corte == "total") |>
    dplyr::transmute(geo_id, nivel, anio, valor_m2 = termino_publicado(valor), e_valor = estado,
                     nivel_sal = dplyr::if_else(nivel == "municipio", "provincia", nivel),
                     geo_sal = dplyr::if_else(nivel == "municipio", substr(geo_id, 1, 2), geo_id))
  vt |>
    dplyr::left_join(dplyr::rename(sal, nivel_sal = nivel, geo_sal = geo_id), by = c("nivel_sal", "geo_sal", "anio")) |>
    dplyr::left_join(dplyr::select(tipo, anio, tipo), by = "anio") |>
    (\(x) if (is.null(renta_hogar)) dplyr::mutate(x, renta = salario, e_renta = e_salario) else
      dplyr::left_join(x, dplyr::transmute(renta_hogar, nivel, geo_id, anio, renta = termino_publicado(renta), e_renta),
                       by = c("nivel", "geo_id", "anio")))() |>
    dplyr::mutate(e_renta = dplyr::coalesce(e_renta, "ausente")) |>
    dplyr::select(geo_id, nivel, anio, valor_m2, e_valor, salario, e_salario, tipo, renta, e_renta)
}

# Los dos derivados en el formato de la tabla larga, en los años con salario (los demás no entran).
armonizar_derivados_compraventa <- function(larga_valor_tasado, larga_salarios, tipo, renta_hogar = NULL,
                                            version_renta = NULL,
                                            superficie = SUPERFICIE_COMPRA, financiacion = FINANCIACION_COMPRA,
                                            plazo = PLAZO_HIPOTECA) {
  t <- terminos_compraventa(larga_valor_tasado, larga_salarios, tipo, renta_hogar) |>
    dplyr::filter(anio %in% unique(salario_referencia(larga_salarios)$anio))
  version <- max(c(unique(larga_valor_tasado$version), unique(larga_salarios$version), version_renta))
  t <- t |> dplyr::mutate(estado = peor_estado(e_valor, e_salario), con = con_valor(estado))
  anios <- t |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "anios_salario_compra",
                     valor = dplyr::if_else(con, valor_m2 * superficie / salario, NA_real_), estado)
  esfuerzo <- t |>
    dplyr::mutate(estado = dplyr::if_else(is.na(tipo), "ausente", peor_estado(e_valor, e_renta)), con = con_valor(estado)) |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "esfuerzo_hipotecario",
                     valor = dplyr::if_else(con, 100 * 12 * cuota_hipoteca(financiacion * valor_m2 * superficie, tipo, plazo) /
                                              renta, NA_real_), estado)
  dplyr::bind_rows(anios, esfuerzo) |>
    dplyr::mutate(corte = "total", grupo = "total", fuente = "calculo_propio", geo_ref = "2021", version = version) |>
    dplyr::select(dplyr::all_of(COLUMNAS_TABLA_LARGA))
}

# Rangos de la compuerta: fuera de [minimo, maximo], bloqueo; fuera de [aviso_min, aviso_max], alerta.
RANGOS_COMPRAVENTA <- tibble::tribble(
  ~indicador,             ~minimo, ~maximo, ~aviso_min, ~aviso_max,
  "anios_salario_compra",  0.5,     60,      2,          25,
  "esfuerzo_hipotecario",  1,       300,     5,          100
)

# Compuerta de los derivados de compraventa (inventario/referencias_validacion.csv):
#   compraventa_terminos (bloqueo): desviación máxima (%) por año e indicador entre cada cifra y la
#     recalculada con sus términos (la cuota, por la suma de los intereses y la amortización del primer mes);
#   compraventa_estado (bloqueo): cifras cuyo estado no es el peor de sus términos, o con valor y
#     estado sin valor (o al revés);
#   compraventa_rango (bloqueo) y compraventa_rango_detalle (alerta): RANGOS_COMPRAVENTA.
comprobar_derivados_compraventa <- function(derivados, larga_valor_tasado, larga_salarios, tipo, renta_hogar = NULL,
                                            superficie = SUPERFICIE_COMPRA, financiacion = FINANCIACION_COMPRA,
                                            plazo = PLAZO_HIPOTECA, rangos = RANGOS_COMPRAVENTA) {
  t <- terminos_compraventa(larga_valor_tasado, larga_salarios, tipo, renta_hogar)
  x <- derivados |>
    dplyr::left_join(t, by = c("geo_id", "nivel", "anio")) |>
    dplyr::mutate(
      capital = financiacion * valor_m2 * superficie,
      r = tipo / 100 / 12,
      # comprobacion independiente de la cuota: el capital es el valor actual de las cuotas
      recalculado = dplyr::if_else(indicador == "anios_salario_compra", valor_m2 * superficie / salario,
                                   100 * 12 * capital * r * (1 + r)^(plazo * 12) / ((1 + r)^(plazo * 12) - 1) / renta),
      esperado = dplyr::if_else(indicador == "esfuerzo_hipotecario",
                                dplyr::if_else(is.na(tipo), "ausente", peor_estado(e_valor, e_renta)),
                                peor_estado(e_valor, e_salario)),
      desviacion = 100 * abs(valor - recalculado) / abs(recalculado))
  terminos <- x |> dplyr::filter(!is.na(valor)) |>
    dplyr::group_by(anio, detalle = indicador) |>
    dplyr::summarise(calculado = max(desviacion), .groups = "drop") |>
    dplyr::transmute(id = "compraventa_terminos", anio, detalle, calculado, referencia = 0)
  estado <- x |>
    dplyr::group_by(anio, detalle = indicador) |>
    dplyr::summarise(calculado = sum(estado != esperado | is.na(valor) == con_valor(estado)), .groups = "drop") |>
    dplyr::transmute(id = "compraventa_estado", anio, detalle, calculado, referencia = 0)
  con_rango <- derivados |> dplyr::filter(!is.na(valor)) |> dplyr::inner_join(rangos, by = "indicador")
  fuera <- con_rango |>
    dplyr::group_by(anio, detalle = indicador) |>
    dplyr::summarise(calculado = sum(valor < minimo | valor > maximo), .groups = "drop") |>
    dplyr::transmute(id = "compraventa_rango", anio, detalle, calculado, referencia = 0)
  aviso <- con_rango |> dplyr::filter(valor < aviso_min | valor > aviso_max) |>
    dplyr::transmute(id = "compraventa_rango_detalle", anio, detalle = paste(indicador, nivel, geo_id, sprintf("%.1f", valor)),
                     calculado = 1, referencia = 0)
  dplyr::bind_rows(terminos, estado, fuera, aviso) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Compuerta de coherencia entre la tasación y las escrituras (el «hecho cuando» de F4). Las webs
# del Notariado reservan sus derechos y piden autorización expresa, pero el MIVAU publica, con sus propias
# condiciones de reutilización, el valor medio de las compraventas de vivienda libre escrituradas
# ante notario (34020150). Las dos cifras no tienen la misma unidad (€ por vivienda frente a € por
# m²): su cociente es la superficie que tendría la vivienda media vendida si se pagara al valor
# tasado, la «superficie implícita». Si las dos fuentes miden el mismo mercado, cae cerca de la
# superficie media de las viviendas que se venden (unos 90–100 m² construidos), algo por debajo,
# porque el precio escriturado suele quedar por debajo de la tasación. Un error de lectura o de
# casado (otra columna, otra provincia, otra unidad) la saca de golpe de ese entorno.
# Umbral razonado (SUPERFICIE_IMPLICITA): de 50 a 150 m² en cada provincia y trimestre (la
# vivienda unifamiliar rural y la costa turística separan las dos fuentes, pero no al doble) y de
# 70 a 110 m² en España, cada año.
#   compraventa_coherencia_espana (bloqueo): España fuera de su intervalo, por año (media de los
#     cuatro trimestres; 0 o 1);
#   compraventa_coherencia_provincias (bloqueo): % de provincias y trimestres fuera de su intervalo,
#     por año; tolerancia en referencias_validacion.csv;
#   compraventa_coherencia_detalle (alerta): cada provincia y año con la media de sus trimestres
#     fuera del intervalo.
SUPERFICIE_IMPLICITA <- list(espana = c(70, 110), provincia = c(50, 150))

superficie_implicita <- function(tasado_trimestral, transacciones_trimestral) {
  tasado_trimestral |>
    dplyr::filter(nivel %in% c("nacional", "provincia")) |>
    dplyr::select(nivel, geo_id, anio, trimestre, valor_m2 = valor) |>
    dplyr::inner_join(dplyr::select(transacciones_trimestral, nivel, geo_id, anio, trimestre, valor_medio = valor),
                      by = c("nivel", "geo_id", "anio", "trimestre")) |>
    dplyr::filter(!is.na(valor_m2), !is.na(valor_medio)) |>
    dplyr::mutate(superficie = valor_medio / valor_m2)
}

comprobar_coherencia_compraventa <- function(tasado_trimestral, transacciones_trimestral, desde = 2015L,
                                             intervalos = SUPERFICIE_IMPLICITA) {
  s <- superficie_implicita(tasado_trimestral, transacciones_trimestral) |> dplyr::filter(anio >= desde)
  completos <- s |> dplyr::count(nivel, geo_id, anio) |> dplyr::filter(n == 4)
  e <- intervalos$espana
  p <- intervalos$provincia
  espana <- s |> dplyr::filter(nivel == "nacional") |>
    dplyr::semi_join(completos, by = c("nivel", "geo_id", "anio")) |>
    dplyr::group_by(anio) |>
    dplyr::summarise(m2 = mean(superficie), .groups = "drop") |>
    dplyr::transmute(id = "compraventa_coherencia_espana", anio,
                     detalle = sprintf("Espa\u00f1a: %.1f m\u00b2", m2), calculado = as.numeric(m2 < e[1] | m2 > e[2]), referencia = 0)
  prov <- s |> dplyr::filter(nivel == "provincia")
  provincias <- prov |>
    dplyr::group_by(anio) |>
    dplyr::summarise(calculado = 100 * mean(superficie < p[1] | superficie > p[2]), n = dplyr::n(), .groups = "drop") |>
    dplyr::transmute(id = "compraventa_coherencia_provincias", anio,
                     detalle = sprintf("%d provincias y trimestres", n), calculado, referencia = 0)
  detalle <- prov |>
    dplyr::group_by(geo_id, anio) |>
    dplyr::summarise(m2 = mean(superficie), .groups = "drop") |>
    dplyr::filter(m2 < p[1] | m2 > p[2]) |>
    dplyr::transmute(id = "compraventa_coherencia_detalle", anio,
                     detalle = sprintf("provincia %s: %.1f m\u00b2", geo_id, m2), calculado = 1, referencia = 0)
  dplyr::bind_rows(espana, provincias, detalle)
}
