# Indicadores derivados de F2 y perfiles de las fichas (plan §3.1, §5 C y §6.6):
#   14 esfuerzo_residentes: alquiler mensual mediano × 12 / renta neta media por hogar (ADRH), en %;
#   21 sueldo_necesario: alquiler mediano por m² × 50 m² / 0,30, en € netos al mes (mapa por defecto);
#   15 barrera_acceso: alquiler mediano por m² × 50 m² / ingreso neto mensual de la ficha, en %. Se
#      calcula en el navegador con la ficha elegida; en R, solo la mochila y la tartera, como control.
# El alquiler es siempre el de la vivienda colectiva (pregunta abierta 12). Estado: el peor de sus
# términos, en el orden dato < estimado < secreto < ausente; sin algún término, ausente (pregunta
# abierta 15). En el 15, el del alquiler: el ingreso de la ficha solo aporta «ausente» cuando
# falta (pregunta 15 ampliada, 9-nov-2026; estado_barrera()). Numerador y denominador, del mismo
# año (regla 4).
# Términos tal como se publican: el alquiler, la renta y el ingreso de la ficha entran redondeados a
# un decimal con el redondeo de la guía, como los recibe la web, para que la página y R den la misma
# cifra (pregunta abierta 19). La tabla larga del SERPAVI y del ADRH conserva la precisión de la fuente.
# El 14 y el 21 no tienen desglose (corte y grupo «total»); el 15 lleva la ficha como corte.

ORDEN_ESTADOS <- c("dato", "estimado", "secreto", "ausente")

# Supuestos por defecto (plan §3.1 y §6.6): 50 m² para las fichas de una persona y el mapa por
# defecto; umbral del 30 % para el sueldo necesario. La web los cambia (70 y 90 m², 40 %).
SUPERFICIE_FICHA <- 50
UMBRAL_SUELDO <- 0.30

# Niveles del esfuerzo de residentes: donde el SERPAVI y el ADRH publican los dos términos.
NIVELES_ESFUERZO <- c("sc", "municipio")

# Salario mínimo (tartera): cuantía mensual en 14 pagas del real decreto de cada año y cotización
# del trabajador (contingencias comunes 4,70 %, desempleo 1,55 %, formación profesional 0,10 % y MEI:
# 0,12 % en 2024 y 0,15 % en 2026). Exento de IRPF. Neto prorrateado = mensual × 14 × (1 − cotización) / 12.
#   2024: RD 145/2024, 1.134 € (la cifra de 2024 que cita el plan, §3.1: ≈ 1.237 € netos);
#   2026: RD 126/2026, 1.221 € (fuente boe_smi: ≈ 1.332 € netos).
# El de 2024 sirve para el control del 15 con el alquiler del mismo año; el de 2026 es el que usa la web.
SMI_FICHAS <- tibble::tribble(
  ~anio, ~mensual, ~pagas, ~cotizacion, ~norma,
  2024L, 1134,     14L,    0.0647,      "RD 145/2024",
  2026L, 1221,     14L,    0.0650,      "RD 126/2026"
)
REFERENCIA_TARTERA_2026 <- 1332   # referencias_validacion.csv, smi_neto

# Rangos de la compuerta: fuera de [minimo, maximo], bloqueo (derivados_rango); fuera de
# [aviso_min, aviso_max], alerta por cifra (derivados_rango_detalle).
RANGOS_DERIVADOS <- tibble::tribble(
  ~indicador,            ~minimo, ~maximo, ~aviso_min, ~aviso_max,
  "esfuerzo_residentes",  0.1,     100,     3,          60,
  "sueldo_necesario",     100,     10000,   200,        4000,
  "barrera_acceso",       0.1,     300,     3,          150
)

# Peor estado de varios términos, fila a fila; un término que falta (NA) cuenta como «ausente».
peor_estado <- function(...) {
  posiciones <- lapply(list(...), function(e) {
    p <- match(e, ORDEN_ESTADOS)
    raros <- unique(e[!is.na(e) & is.na(p)])
    if (length(raros) > 0) stop("Estado desconocido: ", paste(raros, collapse = ", "), call. = FALSE)
    ifelse(is.na(p), length(ORDEN_ESTADOS), p)
  })
  ORDEN_ESTADOS[do.call(pmax, posiciones)]
}

con_valor <- function(estado) estado %in% c("dato", "estimado")

# Estado de la barrera (15): el del alquiler; si el ingreso de la ficha no tiene valor (la mochila
# en los territorios forales, Ceuta y Melilla), «ausente». La calidad del ingreso (la mochila es
# una estimación) se explica una vez, en el método de la ficha, y no rebaja cada cifra.
estado_barrera <- function(e_alquiler, e_ingreso) {
  ifelse(con_valor(e_ingreso), ifelse(is.na(e_alquiler), "ausente", e_alquiler), "ausente")
}

# Término tal como se publica: redondeo de la guía a un decimal (sprintf, no round()), sin aviso
# con los NA (pregunta abierta 19).
termino_publicado <- function(x) {
  r <- rep(NA_real_, length(x))
  ok <- !is.na(x)
  r[ok] <- as.numeric(sprintf("%.1f", x[ok]))
  r
}

# Mediana de la vivienda colectiva de un indicador del SERPAVI (alquiler_mes o alquiler_m2), redondeada.
alquiler_vc <- function(larga_serpavi, ind) {
  larga_serpavi |>
    filter(indicador == ind, corte == "tipologia", grupo == "VC") |>
    transmute(geo_id, nivel, anio, valor = termino_publicado(valor), estado)
}

# Renta neta media por hogar del ADRH (indicador 2), por sección (seccionado de 2021) y municipio, redondeada.
renta_hogar_adrh <- function(larga_adrh, niveles = NIVELES_ESFUERZO) {
  larga_adrh |>
    filter(indicador == "renta_hogar", nivel %in% niveles, corte == "total") |>
    transmute(geo_id, nivel, anio, valor = termino_publicado(valor), estado)
}

# 14: alquiler mensual mediano (VC) × 12 / renta media por hogar × 100, en los años con los dos términos.
calcular_esfuerzo_residentes <- function(larga_serpavi, larga_adrh, niveles = NIVELES_ESFUERZO) {
  alquiler <- alquiler_vc(larga_serpavi, "alquiler_mes") |> filter(nivel %in% niveles) |>
    rename(alquiler = valor, e_alquiler = estado)
  renta <- renta_hogar_adrh(larga_adrh, niveles) |> rename(renta = valor, e_renta = estado)
  anios <- intersect(alquiler$anio, renta$anio)
  full_join(filter(alquiler, anio %in% anios), filter(renta, anio %in% anios), by = c("geo_id", "nivel", "anio")) |>
    mutate(estado = peor_estado(e_alquiler, e_renta),
           valor = if_else(con_valor(estado), 100 * alquiler * 12 / renta, NA_real_),
           indicador = "esfuerzo_residentes", corte = "total", grupo = "total") |>
    select(geo_id, nivel, anio, indicador, corte, grupo, valor, estado)
}

# 21: alquiler mediano por m² (VC) × superficie / umbral, en todos los niveles del SERPAVI. Es el
# alquiler en otra unidad: lleva el estado del alquiler.
calcular_sueldo_necesario <- function(larga_serpavi, superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  alquiler_vc(larga_serpavi, "alquiler_m2") |>
    transmute(geo_id, nivel, anio, indicador = "sueldo_necesario", corte = "total", grupo = "total",
              valor = if_else(con_valor(estado), valor * superficie / umbral, NA_real_), estado)
}

# Ingreso neto mensual (12 pagas) de cada ficha:
#   tartera: salario mínimo de cada año de SMI_FICHAS (nacional);
#   mochila: mochila_neta (método B, neto) de cada provincia, año de la AEAT, como «estimado» (el
#     método B es una estimación; pregunta 15 ampliada); sin dato en los territorios forales, Ceuta
#     y Melilla (ausente). La provincia sale de inventario/provincias_aeat.csv;
#   llave: renta neta media por hogar / 12 de cada sección y municipio, con el estado del ADRH.
# El transistor (pensionista) queda para F3.
perfiles_fichas <- function(mochila_neta, provincias_aeat, larga_adrh, anio_mochila,
                            smi = SMI_FICHAS, superficie = SUPERFICIE_FICHA) {
  tartera <- smi |>
    transmute(ficha = "tartera", nivel = "nacional", geo_id = "00", anio,
              ingreso = mensual * pagas * (1 - cotizacion) / 12, estado = "dato",
              superficie_m2 = superficie, fuente = "boe_smi")
  mochila <- provincias_aeat |>
    left_join(select(mochila_neta, nombre_aeat = provincia, neto_mensual), by = "nombre_aeat") |>
    transmute(ficha = "mochila", nivel = "provincia", geo_id = provincia, anio = as.integer(anio_mochila),
              ingreso = neto_mensual, estado = if_else(is.na(neto_mensual), "ausente", "estimado"),
              superficie_m2 = superficie, fuente = "aeat_mercado_trabajo")
  llave <- renta_hogar_adrh(larga_adrh) |>
    transmute(ficha = "llave", nivel, geo_id, anio, ingreso = valor / 12, estado,
              superficie_m2 = NA_real_, fuente = "ine_adrh")
  bind_rows(tartera, mochila, llave)
}

# Llave resumida por año (para la regla de la leyenda): percentiles 10, 50 y 90 del ingreso de las
# secciones con dato o estimado.
resumen_llave <- function(perfiles) {
  perfiles |>
    filter(ficha == "llave", nivel == "sc", con_valor(estado)) |>
    group_by(anio) |>
    summarise(secciones = n(), p10 = stats::quantile(ingreso, 0.10), p50 = stats::median(ingreso),
              p90 = stats::quantile(ingreso, 0.90), .groups = "drop")
}

# Ingreso de la tartera y la mochila tal como lo recibe la web (perfiles.json, redondeado).
ingresos_fichas <- function(perfiles) {
  perfiles |>
    filter(ficha %in% c("tartera", "mochila")) |>
    transmute(ficha, geo_id, anio, ingreso = termino_publicado(ingreso), estado)
}

# 15, control en R: alquiler mediano por m² (VC) × superficie / ingreso de la ficha × 100, con el
# ingreso del mismo año que el alquiler (regla 4): la tartera en los años de SMI_FICHAS con alquiler
# (2024), la mochila en su año, en las provincias y sus secciones, distritos y municipios. Estado:
# estado_barrera().
calcular_barrera_acceso <- function(larga_serpavi, perfiles, superficie = SUPERFICIE_FICHA) {
  m2 <- alquiler_vc(larga_serpavi, "alquiler_m2") |> rename(alquiler_m2 = valor, e_alquiler = estado)
  ingresos <- ingresos_fichas(perfiles)
  tartera <- ingresos |> filter(ficha == "tartera") |> select(anio, ingreso, e_ingreso = estado)
  mochila <- ingresos |> filter(ficha == "mochila") |> select(provincia = geo_id, anio, ingreso, e_ingreso = estado)
  bind_rows(
    m2 |> inner_join(tartera, by = "anio") |> mutate(grupo = "tartera"),
    m2 |>
      filter(nivel != "ccaa", anio %in% mochila$anio) |>
      mutate(provincia = substr(geo_id, 1, 2)) |>
      left_join(mochila, by = c("provincia", "anio")) |>
      select(-provincia) |>
      mutate(grupo = "mochila")
  ) |>
    mutate(estado = estado_barrera(e_alquiler, e_ingreso),
           valor = if_else(con_valor(estado), 100 * alquiler_m2 * superficie / ingreso, NA_real_),
           indicador = "barrera_acceso", corte = "ficha") |>
    select(geo_id, nivel, anio, indicador, corte, grupo, valor, estado)
}

# Los tres derivados en el formato de la tabla larga. Fuente: calculo_propio (inventario/fuentes.csv);
# versión: la más reciente de sus términos.
armonizar_derivados <- function(larga_serpavi, larga_adrh, perfiles,
                                superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  version <- max(c(unique(larga_serpavi$version), unique(larga_adrh$version)))
  bind_rows(
    calcular_esfuerzo_residentes(larga_serpavi, larga_adrh),
    calcular_sueldo_necesario(larga_serpavi, superficie, umbral),
    calcular_barrera_acceso(larga_serpavi, perfiles, superficie)
  ) |>
    mutate(fuente = "calculo_propio", geo_ref = "2021", version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Términos de cada cifra derivada, para la compuerta: numerador y denominador con sus estados,
# redondeados como en el cálculo.
terminos_derivados <- function(derivados, larga_serpavi, larga_adrh, perfiles,
                               superficie = SUPERFICIE_FICHA, umbral = UMBRAL_SUELDO) {
  clave <- c("geo_id", "nivel", "anio")
  mes <- alquiler_vc(larga_serpavi, "alquiler_mes") |> rename(num = valor, e_num = estado)
  m2 <- alquiler_vc(larga_serpavi, "alquiler_m2") |> rename(num = valor, e_num = estado)
  renta <- renta_hogar_adrh(larga_adrh) |> rename(den = valor, e_den = estado)
  esfuerzo <- derivados |> filter(indicador == "esfuerzo_residentes") |>
    left_join(mes, by = clave) |> left_join(renta, by = clave) |>
    mutate(num = num * 12, recalculado = 100 * num / den)
  sueldo <- derivados |> filter(indicador == "sueldo_necesario") |>
    left_join(m2, by = clave) |>
    mutate(den = umbral, e_den = "dato", num = num * superficie, recalculado = num / den)
  ingresos <- ingresos_fichas(perfiles) |>
    transmute(grupo = ficha, provincia = if_else(ficha == "tartera", NA_character_, geo_id), anio, den = ingreso, e_den = estado)
  barrera <- derivados |> filter(indicador == "barrera_acceso") |>
    left_join(m2, by = clave) |>
    mutate(provincia = if_else(grupo == "tartera", NA_character_, substr(geo_id, 1, 2))) |>
    left_join(ingresos, by = c("grupo", "provincia", "anio")) |>
    select(-provincia) |>
    mutate(num = num * superficie, recalculado = 100 * num / den)
  bind_rows(esfuerzo, sueldo, barrera)
}

# Compuerta de los derivados (inventario/referencias_validacion.csv):
#   derivados_terminos (bloqueo): desviación máxima (%) entre cada cifra y la recalculada con sus términos;
#   derivados_estado (bloqueo): cifras cuyo estado no es el peor de sus términos (en el 15, el
#     del alquiler, o «ausente» sin ingreso: estado_barrera()), o con valor y estado secreto o
#     ausente (o al revés);
#   derivados_rango (bloqueo): cifras fuera del rango posible (RANGOS_DERIVADOS);
#   derivados_rango_detalle (alerta): cada cifra fuera del rango habitual;
#   smi_neto (bloqueo): ingreso neto de la tartera de 2026 frente a la cifra del plan;
#   perfiles_mochila (bloqueo): provincias de la mochila sin código del INE, o códigos repetidos.
comprobar_derivados <- function(derivados, larga_serpavi, larga_adrh, perfiles, provincias_aeat, mochila_neta,
                                rangos = RANGOS_DERIVADOS) {
  t <- terminos_derivados(derivados, larga_serpavi, larga_adrh, perfiles)
  rango <- c(dato = 1L, estimado = 2L, secreto = 3L, ausente = 4L)
  t <- t |>
    mutate(esperado = if_else(indicador == "barrera_acceso", estado_barrera(e_num, e_den),
                              names(rango)[pmax(coalesce(rango[e_num], 4L), coalesce(rango[e_den], 4L))]),
           desviacion = 100 * abs(valor - recalculado) / abs(recalculado))
  etiqueta_derivado <- function(x) if_else(x$indicador == "barrera_acceso", paste(x$indicador, x$grupo), x$indicador)

  terminos <- t |> filter(!is.na(valor)) |> mutate(detalle = etiqueta_derivado(pick(everything()))) |>
    group_by(anio, detalle) |>
    summarise(calculado = max(desviacion), .groups = "drop") |>
    transmute(id = "derivados_terminos", anio, detalle, calculado, referencia = 0)

  estado <- t |> mutate(detalle = etiqueta_derivado(pick(everything()))) |>
    group_by(anio, detalle) |>
    summarise(calculado = sum(estado != esperado | is.na(valor) == con_valor(estado)), .groups = "drop") |>
    transmute(id = "derivados_estado", anio, detalle, calculado, referencia = 0)

  con_rango <- derivados |> filter(!is.na(valor)) |> inner_join(rangos, by = "indicador")
  fuera <- con_rango |> mutate(detalle = etiqueta_derivado(pick(everything()))) |>
    group_by(anio, detalle) |>
    summarise(calculado = sum(valor < minimo | valor > maximo), .groups = "drop") |>
    transmute(id = "derivados_rango", anio, detalle, calculado, referencia = 0)
  aviso <- con_rango |> filter(valor < aviso_min | valor > aviso_max) |>
    transmute(id = "derivados_rango_detalle", anio,
              detalle = paste(etiqueta_derivado(pick(everything())), nivel, geo_id, sprintf("%.1f", valor)),
              calculado = 1, referencia = 0)

  tartera <- perfiles |> filter(ficha == "tartera", anio == 2026L) |>
    transmute(id = "smi_neto", anio, detalle = "tartera", calculado = ingreso, referencia = REFERENCIA_TARTERA_2026)

  sin_codigo <- setdiff(mochila_neta$provincia, provincias_aeat$nombre_aeat)
  codigos <- provincias_aeat$provincia[!is.na(provincias_aeat$nombre_aeat)]
  mochila <- tibble::tibble(
    id = "perfiles_mochila", anio = NA_integer_,
    detalle = c("provincias de la AEAT sin c\u00f3digo", "c\u00f3digos repetidos", "nombres de la tabla sin mochila"),
    calculado = c(length(sin_codigo), sum(duplicated(codigos)),
                  length(setdiff(stats::na.omit(provincias_aeat$nombre_aeat), mochila_neta$provincia))),
    referencia = 0)

  bind_rows(terminos, estado, fuera, aviso, tartera, mochila) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Cifras para el informe: estados por indicador, nivel y año, y percentiles de las cifras con valor.
resumen_derivados <- function(larga) {
  etiqueta <- if_else(larga$corte == "ficha", paste(larga$indicador, larga$grupo), larga$indicador)
  x <- mutate(larga, indicador = etiqueta)
  list(
    estados = x |> count(indicador, nivel, anio, estado) |>
      tidyr::pivot_wider(names_from = estado, values_from = n, values_fill = 0L),
    rangos = x |> filter(!is.na(valor)) |> group_by(indicador, nivel, anio) |>
      summarise(n = n(), min = min(valor), p10 = stats::quantile(valor, 0.1), p50 = stats::median(valor),
                p90 = stats::quantile(valor, 0.9), max = max(valor), .groups = "drop")
  )
}
