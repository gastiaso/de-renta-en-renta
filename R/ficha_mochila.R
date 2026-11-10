# Ficha «mochila» (joven de 26 a 35 años): mediana estimada del salario con la AEAT (plan §3.1,
# «Método de la mochila»), de 2015 a 2024, en cinco pasos:
#   1. Nivel provincial: salario medio anual de 26 a 35 años de la provincia (indicador 7,
#      R/fuente_aeat_salarios.R). Es lo cobrado en el año (paso 4).
#   2. De media a mediana: × relación mediana/media del salario medio estimado (SME, módulo de
#      «año completo») de 26 a 35 años de su comunidad, del mismo año (formas_sme). El módulo existe
#      desde la edición de 2019: de 2015 a 2018 se usa la relación de 2019 (anio_forma), con la
#      alerta mochila_forma, que mide cuánto se mueve de 2019 a 2024. Sin Ceuta ni Melilla, que no
#      están en el módulo.
#   3. De bruto a neto: × (1 − cotización del trabajador del año − retención de la AEAT de quien
#      solo cobra salarios, interpolada en el tramo de renta anual de su comunidad y año) ÷ 12.
#   4. Lo cobrado en el año (método B, adoptado el 7-nov-2026): incluye a quien trabajó pocos meses.
#   5. Control con la ECV de cada año (ingresos del mismo año que la AEAT): alertas mochila_ecv
#      (bruto) y mochila_neto_ecv (paso a neto).
# Sin País Vasco ni Navarra (la AEAT no los cubre). Opciones descartadas (pregunta abierta 7), que
# se siguen calculando como registro: A, mediana del SME de la comunidad llevada a la provincia con
# la posición de su salario medio real; C, mediana del SME de la comunidad.
#
# La AEAT no publica la mediana del SME por comunidad y edad: solo cuántos asalariados de cada
# comunidad y edad caen en cada decil nacional, y los límites de los centiles nacionales. La
# mediana se interpola suponiendo que, dentro de cada decil nacional, la comunidad se reparte
# como el país (uniforme en sus diez centiles). comprobar_interpolacion_deciles() lo contrasta
# con los recuentos por centil que la AEAT sí da por comunidad (todas las edades).

EDAD_MOCHILA <- "De 26 a 35 a\u00f1os"
ANIOS_MOCHILA <- 2015:2024
ANIOS_SME <- 2019:2024          # módulo de «año completo» de la AEAT

# Tablas de la AEAT que usa la ficha: título en el mapa de la estadística y filtros fijos. La
# provincial, en R/fuente_aeat_salarios.R.
TABLAS_AEAT_MOCHILA <- list(
  deciles   = list("Distribuci\u00f3n de asalariados por decilas, tramos de edad, CCAA y g\u00e9nero", list(`Género` = "Total")),
  sme_edad  = list("Distribuci\u00f3n de asalariados y Salario Medio Estimado Anual por tramos de edad, g\u00e9nero y CCAA", list()),
  recorrido = list("Recorrido del Salario Medio Estimado en cada decila de poblaci\u00f3n", list()),
  centiles  = list("Distribuci\u00f3n de asalariados y Salario Medio Estimado Anual por centilas, g\u00e9nero y CCAA", list()),
  retenciones = list("GRUPOS DE POBLACI\u00d3N POR LA NATURALEZA DE SUS RETRIBUCIONES", list())
)

descargar_aeat_mochila <- function(tabla, anio) {
  t <- TABLAS_AEAT_MOCHILA[[tabla]]
  descargar_aeat_mercado(anio, t[[1]], t[[2]])
}

clave_nombre <- function(x) gsub("_", "", nombre_columna(x))

# Código del INE de las comunidades de la AEAT (clave_comunidad(), estable entre ediciones);
# «Total», España («00»). Un nombre sin código detiene el proceso.
codigo_ccaa_aeat <- function(nombres, ccaa) {
  claves <- c(stats::setNames(ccaa$codigo, clave_comunidad(ccaa$nombre_ine)), total = "00")
  k <- unname(claves[clave_comunidad(nombres)])
  if (anyNA(k)) stop("Comunidades de la AEAT sin c\u00f3digo: ", paste(unique(nombres[is.na(k)]), collapse = ", "), call. = FALSE)
  k
}

# Columna de la comunidad en una tabla de la AEAT (cambia de nombre según la edición).
columna_geo_aeat <- function(d) {
  geo <- intersect(c("distribucion_geografica", "comunidad_autonoma", "ccaa"), names(d))[1]
  if (is.na(geo)) stop("Sin columna de comunidad en la tabla de la AEAT", call. = FALSE)
  geo
}

# Curva de los centiles nacionales del SME: posición (0–100) → euros.
curva_centiles_sme <- function(recorrido) {
  c <- recorrido |>
    filter(grepl("^[0-9]+$", fila), columna %in% c("SME inferior", "SME superior")) |>
    mutate(k = as.integer(fila)) |>
    select(k, columna, valor) |>
    tidyr::pivot_wider(names_from = columna, values_from = valor) |>
    arrange(k)
  if (!identical(c$k, 1:100)) stop("La tabla del recorrido del SME no trae los 100 centiles", call. = FALSE)
  list(x = c(0, c$k), y = c(c$`SME inferior`[1], c$`SME superior`))
}

# Cuantil p de una distribución dada por recuentos en tramos consecutivos de la curva nacional:
# deciles (`ancho` = 10 centiles) o centiles (`ancho` = 1), uniforme dentro de cada tramo.
cuantil_tramos <- function(n, curva, p = 0.5, ancho = 10) {
  acum <- cumsum(n)
  objetivo <- p * sum(n)
  t <- which(acum >= objetivo)[1]
  previo <- if (t == 1) 0 else acum[t - 1]
  stats::approx(curva$x, curva$y, xout = ancho * (t - 1 + (objetivo - previo) / n[t]))$y
}

# Recuentos por decil nacional («Decil 5 Mediana» incluido) de cada comunidad y edad.
deciles_aeat <- function(deciles) {
  geo <- columna_geo_aeat(deciles)
  deciles |>
    filter(grepl("^Decil [0-9]+", fila)) |>
    transmute(geo = .data[[geo]], edad = columna,
              decil = as.integer(sub("^Decil ([0-9]+).*$", "\\1", fila)), n = valor) |>
    arrange(geo, edad, decil)
}

# Comprobación del supuesto de la interpolación (todas las edades, cada comunidad): mediana
# desde los deciles frente a la mediana desde los recuentos por centil. Desviación en %.
comprobar_interpolacion_deciles <- function(deciles, centiles, recorrido, anio = NA_integer_) {
  curva <- curva_centiles_sme(recorrido)
  desde_deciles <- deciles_aeat(deciles) |>
    filter(edad == "Total") |>
    group_by(geo) |>
    summarise(con_deciles = cuantil_tramos(n, curva), .groups = "drop")
  geo <- columna_geo_aeat(centiles)
  desde_centiles <- centiles |>
    filter(grepl("^[0-9]+$", fila), columna == "Total \u00b7 N\u00famero") |>
    mutate(k = as.integer(fila)) |>
    arrange(k) |>
    group_by(geo = .data[[geo]]) |>
    summarise(con_centiles = cuantil_tramos(valor, curva, ancho = 1), .groups = "drop")
  inner_join(desde_deciles, desde_centiles, by = "geo") |>
    transmute(id = "aeat_mediana_deciles", anio = as.integer(anio), detalle = geo,
              calculado = 100 * (con_deciles / con_centiles - 1), referencia = 0)
}

# Módulo de «año completo» de un año, ya con códigos del INE (España, «00»): curva nacional de los
# centiles, recuentos por decil nacional de cada comunidad y edad, SME medio de cada comunidad y
# edad, y la comprobación de la interpolación. Una lista; combinar_modulos_sme() las une.
leer_modulo_sme <- function(rutas_deciles, rutas_sme_edad, rutas_recorrido, rutas_centiles, anio, ccaa) {
  anio <- as.integer(anio)
  deciles <- leer_aeat_mercado(rutas_deciles)
  sme_edad <- leer_aeat_mercado(rutas_sme_edad)
  recorrido <- leer_aeat_mercado(rutas_recorrido)
  centiles <- leer_aeat_mercado(rutas_centiles)
  curva <- curva_centiles_sme(recorrido)
  d <- deciles_aeat(deciles)
  geo_sme <- columna_geo_aeat(sme_edad)
  medias <- sme_edad |>
    filter(columna == "Total \u00b7 SME") |>
    transmute(geo = .data[[geo_sme]], edad = fila, media_sme = valor)
  list(
    curva = tibble::tibble(anio = anio, x = curva$x, y = curva$y),
    deciles = transmute(d, anio = anio, ccaa = codigo_ccaa_aeat(geo, ccaa), edad, decil, n),
    medias = transmute(medias, anio = anio, ccaa = codigo_ccaa_aeat(geo, ccaa), edad, media_sme),
    interpolacion = comprobar_interpolacion_deciles(deciles, centiles, recorrido, anio)
  )
}

combinar_modulos_sme <- function(modulos) {
  nombres <- c("curva", "deciles", "medias", "interpolacion")
  stats::setNames(lapply(nombres, function(n) bind_rows(lapply(modulos, `[[`, n))), nombres)
}

curva_del_anio <- function(modulos, a) {
  c <- modulos$curva[modulos$curva$anio == a, ]
  list(x = c$x, y = c$y)
}

# Paso 2: relación mediana/media del SME de una edad por comunidad y año. La mediana se interpola
# de los deciles nacionales con la curva del mismo año.
formas_sme <- function(modulos, edad = EDAD_MOCHILA) {
  medianas <- modulos$deciles |>
    filter(edad == !!edad) |>
    group_by(anio, ccaa) |>
    summarise(n_sme = sum(n), mediana_sme = cuantil_tramos(n, curva_del_anio(modulos, anio[1])), .groups = "drop")
  medianas |>
    inner_join(filter(modulos$medias, edad == !!edad) |> select(anio, ccaa, media_sme), by = c("anio", "ccaa")) |>
    mutate(forma = mediana_sme / media_sme) |>
    arrange(anio, ccaa)
}

# Pasos 1, 2 y 4: bruto anual de 26 a 35 años por provincia y año (método B), con las opciones A y
# C como registro. `salarios`: codificar_aeat_salarios() (tramo «Y26-35»); `formas`: formas_sme().
# Los años sin módulo de año completo toman la relación del primero que lo tiene (anio_forma).
calcular_mochila_serie <- function(salarios, formas, anios = ANIOS_MOCHILA) {
  joven <- salarios |> filter(edad == "Y26-35", anio %in% anios)
  real_ccaa <- joven |> filter(nivel == "ccaa") |> select(anio, ccaa = geo_id, real_ccaa = salario_medio)
  primero <- min(formas$anio)
  joven |>
    filter(nivel == "provincia") |>
    select(anio, provincia = geo_id, ccaa, asalariados, salario_medio) |>
    left_join(real_ccaa, by = c("anio", "ccaa")) |>
    mutate(anio_forma = if_else(anio %in% formas$anio, anio, primero)) |>
    inner_join(select(formas, anio_forma = anio, ccaa, mediana_sme, media_sme, forma), by = c("anio_forma", "ccaa")) |>
    mutate(bruto_anual = salario_medio * forma,
           A = mediana_sme * salario_medio / real_ccaa,
           C = mediana_sme) |>
    arrange(anio, provincia)
}

# Paso 3: de bruto anual a neto mensual repartido en 12 (regla 8) ---------------------------------

# Cotización del trabajador a la Seguridad Social del año de ingresos (régimen general, contrato
# indefinido): la de la tartera (SMI_FICHAS, R/derivados.R): 6,35 % hasta 2022 (contingencias
# comunes 4,70, desempleo 1,55 y formación profesional 0,10) y, con el MEI, 6,45 % en 2023 y
# 6,47 % en 2024. Con contrato temporal, el desempleo es del 1,60 % (0,05 puntos más).
cotizacion_trabajador <- function(anios) {
  x <- SMI_FICHAS$cotizacion[match(as.integer(anios), SMI_FICHAS$anio)]
  if (anyNA(x)) stop("Sin cotizaci\u00f3n del trabajador para: ", paste(unique(anios[is.na(x)]), collapse = ", "), call. = FALSE)
  x
}

# Retención del IRPF sobre el salario por comunidad (código del INE; España, «00») y tramo de renta
# anual (AEAT, «Grupos de población por la naturaleza de sus retribuciones», bloque de salarios),
# de un año. Se toman las personas que solo cobran salarios (columna «Asalariados»): su tramo de
# renta es el de su salario anual. Retribuciones y retenciones vienen en miles de euros. Una fila
# por comunidad y tramo, ordenada por salario medio del tramo (euros), con el tipo de retención.
retenciones_aeat <- function(grupos, anio, ccaa, columna = "Asalariados") {
  geo <- columna_geo_aeat(grupos)
  grupos |>
    filter(bloque == "SALARIOS", columna == !!columna, tramos_de_renta_anual != "Total",
           fila %in% c("Personas", "Retribuciones", "Retenciones")) |>
    transmute(geo = .data[[geo]], tramo = tramos_de_renta_anual, fila, valor) |>
    tidyr::pivot_wider(names_from = fila, values_from = valor) |>
    filter(Personas > 0, Retribuciones > 0) |>
    transmute(anio = as.integer(anio), ccaa = codigo_ccaa_aeat(geo, ccaa), tramo, personas = Personas,
              salario_medio = 1000 * Retribuciones / Personas, retencion = Retenciones / Retribuciones) |>
    arrange(anio, ccaa, salario_medio)
}

# Tipo de retención de un salario anual: interpolación lineal entre los salarios medios de los
# tramos de una curva (filas de retenciones_aeat() de un territorio); fuera de ellos, el tipo del
# tramo extremo.
tipo_retencion <- function(salario, curva) {
  stats::approx(curva$salario_medio, curva$retencion, xout = salario, rule = 2, ties = "ordered")$y
}

# Tipo de retención de cada salario con la curva de su comunidad y año.
tipos_retencion <- function(salario, anio, ccaa, retenciones) {
  curvas <- split(retenciones, paste(retenciones$anio, retenciones$ccaa))
  k <- paste(anio, ccaa)
  faltan <- setdiff(unique(k), names(curvas))
  if (length(faltan) > 0) stop("Sin retenciones de la AEAT para: ", paste(faltan, collapse = ", "), call. = FALSE)
  unname(mapply(function(x, kk) tipo_retencion(x, curvas[[kk]]), salario, k))
}

# Neto anual = bruto × (1 − cotización − retención), con la retención que corresponde al bruto
# en la curva de su comunidad y año (en `retencion_espana`, la de la curva de España, como
# registro). Es la retención practicada en nómina, no la cuota final del IRPF. Neto mensual =
# neto anual / 12.
calcular_mochila_neta <- function(mochila, retenciones, cotizacion = cotizacion_trabajador) {
  mochila |>
    mutate(cotizacion = cotizacion(anio),
           retencion = tipos_retencion(bruto_anual, anio, ccaa, retenciones),
           retencion_espana = tipos_retencion(bruto_anual, anio, rep("00", n()), retenciones),
           neto_anual = bruto_anual * (1 - cotizacion - retencion),
           neto_mensual = neto_anual / 12)
}

# Compuerta de la serie (inventario/referencias_validacion.csv):
#   mochila_cobertura (bloqueo): por año, provincias con nombre en la tabla de la AEAT
#     (inventario/provincias_aeat.csv: las 46 de régimen común con módulo de año completo) sin
#     neto, o repetidas;
#   mochila_forma (alerta): por comunidad, cuánto se aparta (en %) la relación mediana/media de
#     cada año de la de 2019, la que usan 2015–2018.
comprobar_mochila <- function(mochila_neta, formas, provincias_aeat, anios = ANIOS_MOCHILA) {
  esperadas <- provincias_aeat$provincia[!is.na(provincias_aeat$nombre_aeat)]
  cobertura <- vapply(anios, function(a) {
    m <- mochila_neta[mochila_neta$anio == a & !is.na(mochila_neta$neto_mensual), ]
    length(setdiff(esperadas, m$provincia)) + sum(duplicated(m$provincia))
  }, 0)
  primero <- min(formas$anio)
  base <- formas |> filter(anio == primero) |> select(ccaa, forma_base = forma)
  forma <- formas |>
    filter(anio != primero) |>
    inner_join(base, by = "ccaa") |>
    transmute(id = "mochila_forma", anio, detalle = paste("comunidad", ccaa, "frente a", primero),
              calculado = 100 * (forma / forma_base - 1), referencia = 0)
  bind_rows(
    tibble::tibble(id = "mochila_cobertura", anio = as.integer(anios), detalle = "provincias sin neto o repetidas",
                   calculado = cobertura, referencia = 0),
    forma
  ) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Mediana con pesos: primer valor en que el peso acumulado llega a la mitad.
mediana_ponderada <- function(x, w) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

# Control con la ECV (paso 5 del método): asalariados de 26 a 35 años con salario en el año de
# ingresos (PY010G > 0), con su comunidad (DB040), su factor (PB040), el salario neto de
# retenciones y cotizaciones (PY010N) y los meses trabajados por cuenta ajena (PL073 a tiempo
# completo, PL074 a tiempo parcial). La edad es la del final del año de ingresos (año de
# ingresos − año de nacimiento, PB140), como los tramos de la AEAT. Una ola sin PY010N da el neto
# vacío (el control del paso a neto se salta ese año).
leer_ecv_asalariados <- function(rutas, anio_ingresos, edades = c(26L, 35L)) {
  ruta <- function(letra) rutas[grepl(sprintf("esudb\\d{2}%s\\.csv$", letra), rutas, ignore.case = TRUE)]
  cab <- names(readr::read_csv(ruta("p"), n_max = 0, show_col_types = FALSE))
  columnas <- intersect(c("PB030", "PB040", "PB140", "PY010G", "PY010N", "PL073", "PL074"), cab)
  p <- readr::read_csv(ruta("p"), col_select = all_of(columnas),
                       col_types = readr::cols(.default = readr::col_double()), progress = FALSE)
  for (v in setdiff(c("PY010N", "PL073", "PL074"), names(p))) p[[v]] <- NA_real_
  d <- readr::read_csv(ruta("d"), col_select = c("DB030", "DB040"),
                       col_types = readr::cols(DB030 = readr::col_double(), DB040 = readr::col_character()),
                       progress = FALSE)
  p |>
    mutate(DB030 = PB030 %/% 100, edad = anio_ingresos - PB140) |>
    inner_join(d, by = "DB030") |>
    filter(edad >= edades[1], edad <= edades[2], !is.na(PY010G), PY010G > 0) |>
    transmute(nuts2 = DB040, peso = PB040, bruto = PY010G, neto = PY010N,
              meses = dplyr::coalesce(PL073, 0) + dplyr::coalesce(PL074, 0))
}

# Medianas del bruto y del neto por comunidad y para España, con el número de observaciones y la
# parte (con pesos) que trabajó los doce meses.
resumir_ecv_asalariados <- function(asalariados, anio = NA_integer_) {
  bind_rows(mutate(asalariados, nuts2 = "ES"), asalariados) |>
    group_by(nuts2) |>
    summarise(n = n(), mediana_bruto = mediana_ponderada(bruto, peso),
              pct_anio_completo = 100 * sum(peso[meses >= 12]) / sum(peso),
              mediana_neto = if (all(is.na(neto))) NA_real_ else mediana_ponderada(neto[!is.na(neto)], peso[!is.na(neto)]),
              .groups = "drop") |>
    mutate(anio = as.integer(anio), .before = 1)
}

# Mochila de España («00») por año: salario medio real de 26 a 35 años de España × su relación
# mediana/media (la del primer año del módulo antes de él), para el control con la ECV.
mochila_espana <- function(salarios, formas, anios = ANIOS_MOCHILA) {
  primero <- min(formas$anio)
  salarios |>
    filter(nivel == "nacional", edad == "Y26-35", anio %in% anios) |>
    transmute(anio, ccaa = "00", real_ccaa = salario_medio, anio_forma = if_else(anio %in% formas$anio, anio, primero)) |>
    inner_join(select(formas, anio_forma = anio, ccaa, forma), by = c("anio_forma", "ccaa")) |>
    select(anio, ccaa, real_ccaa, forma)
}

# Mochila de cada comunidad y año (salario medio real de 26 a 35 años de la comunidad × su
# relación mediana/media) y de España (`espana`: mochila_espana()) frente a la mediana de la ECV
# con ingresos del mismo año. Desviación en %; alerta mochila_ecv.
comprobar_mochila_ecv <- function(mochila, ecv, ccaa, espana = NULL) {
  comunidades <- mochila |>
    distinct(anio, ccaa, real_ccaa, forma) |>
    bind_rows(if (!is.null(espana)) select(espana, anio, ccaa, real_ccaa, forma)) |>
    mutate(mochila = real_ccaa * forma)
  territorios <- bind_rows(select(ccaa, ccaa = codigo, nuts2, nombre_ine),
                           tibble::tibble(ccaa = "00", nuts2 = "ES", nombre_ine = "Espa\u00f1a"))
  comunidades |>
    inner_join(territorios, by = "ccaa") |>
    inner_join(ecv, by = c("anio", "nuts2")) |>
    transmute(id = "mochila_ecv", anio = as.integer(anio), detalle = paste0(nombre_ine, " (n = ", n, ")"),
              calculado = 100 * (mochila / mediana_bruto - 1), referencia = 0)
}

# Control del paso 3 con la ECV: para cada comunidad (y España, con la curva del total) y año, el
# neto calculado sobre la mediana del bruto de la ECV frente a la mediana del neto de la ECV
# (PY010N: salario menos retenciones y cotizaciones del trabajador). Separa el paso a neto de la
# diferencia en el bruto, que ya mide mochila_ecv. Desviación en %; alerta mochila_neto_ecv. Los
# años sin PY010N en la ECV, fuera.
comprobar_neto_ecv <- function(retenciones, ecv, ccaa, cotizacion = cotizacion_trabajador) {
  territorios <- ccaa |>
    transmute(nuts2, ccaa = codigo, territorio = nombre_ine) |>
    bind_rows(tibble::tibble(nuts2 = "ES", ccaa = "00", territorio = "Total"))
  con_curva <- distinct(retenciones, anio, ccaa)
  ecv |>
    filter(!is.na(mediana_neto)) |>
    inner_join(territorios, by = "nuts2") |>
    semi_join(con_curva, by = c("anio", "ccaa")) |>
    mutate(neto = mediana_bruto * (1 - cotizacion(anio) - tipos_retencion(mediana_bruto, anio, ccaa, retenciones))) |>
    transmute(id = "mochila_neto_ecv", anio = as.integer(anio), detalle = paste0(territorio, " (n = ", n, ")"),
              calculado = 100 * (neto / mediana_neto - 1), referencia = 0)
}
