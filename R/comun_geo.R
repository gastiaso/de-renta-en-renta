# Geografía constante (plan, §6.3): tablas de paso entre seccionados y reproyección.
# Referencia: el seccionado de 2021. Vía (a): tramos del callejero del censo electoral.

# Cuántos números de portal de paridad `par` (1 impar, 0 par) hay entre lo y hi.
contar_portales <- function(lo, hi, par) {
  primero <- lo + ((par - lo) %% 2L)
  ifelse(hi >= primero, (hi - primero) %/% 2L + 1L, 0L)
}

# Paridad del tramo (1 impar, 0 par; NA si no tiene numeración) y rango ordenado.
preparar_tramos <- function(tramos) {
  tramos |>
    mutate(
      clave_via  = paste0(via, "-", pseudovia),   # los tramos sin vía (00000) se identifican por su pseudovía
      con_numero = !is.na(tinum) & tinum != 0L & !is.na(ein) & ein > 0L,
      paridad    = if_else(con_numero, ein %% 2L, NA_integer_),
      ein        = if_else(con_numero, ein, 0L),
      esn        = if_else(con_numero, pmax(dplyr::coalesce(esn, ein), ein), 0L)
    )
}

# Último número de portal real de cada vía y lado, tomado de tramos de la aplicación nueva
# del INE (que da números reales). Sirve para recortar los rangos genéricos 0001–9999 de la
# aplicación antigua, que si no pesarían como miles de portales.
geo_topes_portal <- function(tramos_nuevos) {
  preparar_tramos(tramos_nuevos) |>
    filter(con_numero, esn < 9998L) |>
    group_by(municipio, clave_via, paridad) |>
    summarise(tope = max(esn), .groups = "drop")
}

recortar_tramos <- function(tramos, topes) {
  propios <- tramos |>
    filter(con_numero, esn < 9998L) |>
    group_by(municipio, clave_via, paridad) |>
    summarise(tope_propio = max(esn), .groups = "drop")
  tramos |>
    left_join(topes, by = c("municipio", "clave_via", "paridad")) |>
    left_join(propios, by = c("municipio", "clave_via", "paridad")) |>
    mutate(
      tope = dplyr::coalesce(tope, tope_propio, ein),
      esn  = if_else(con_numero, pmax(pmin(esn, tope), ein), esn)
    ) |>
    select(-tope, -tope_propio)
}

# Tabla de paso sección de origen → sección de destino con los tramos de las dos fechas.
# Peso: números de portal compartidos (misma vía o pseudovía y mismo lado, rangos que se
# solapan); los tramos sin numeración cuentan 1 si coincide la vía. `fraccion` reparte cada
# sección de origen entre sus destinos (suma 1). Las secciones de origen sin ningún tramo
# casado pasan a la sección con el mismo código si existe en el destino (`metodo = "codigo"`).
geo_tabla_paso_callejero <- function(origen, destino, topes = NULL) {
  if (is.null(topes)) topes <- tibble::tibble(municipio = character(), clave_via = character(),
                                              paridad = integer(), tope = integer())
  o <- recortar_tramos(preparar_tramos(origen), topes)
  d <- recortar_tramos(preparar_tramos(destino), topes)

  numerados <- inner_join(
    filter(o, con_numero) |> select(seccion, municipio, clave_via, paridad, ein, esn),
    filter(d, con_numero) |> select(seccion, municipio, clave_via, paridad, ein, esn),
    by = c("municipio", "clave_via", "paridad"), suffix = c("_o", "_d"), relationship = "many-to-many"
  ) |>
    mutate(portales = contar_portales(pmax(ein_o, ein_d), pmin(esn_o, esn_d), paridad)) |>
    filter(portales > 0) |>
    select(origen = seccion_o, destino = seccion_d, portales)

  sin_numero <- inner_join(
    filter(o, !con_numero) |> distinct(seccion, municipio, clave_via),
    filter(d, !con_numero) |> distinct(seccion, municipio, clave_via),
    by = c("municipio", "clave_via"), suffix = c("_o", "_d"), relationship = "many-to-many"
  ) |>
    transmute(origen = seccion_o, destino = seccion_d, portales = 1L)

  tabla <- bind_rows(numerados, sin_numero) |>
    group_by(origen, destino) |>
    summarise(portales = sum(portales), .groups = "drop") |>
    mutate(metodo = "callejero")

  sin_casar <- setdiff(unique(o$seccion), tabla$origen)
  por_codigo <- intersect(sin_casar, unique(d$seccion))
  tabla <- bind_rows(tabla, tibble::tibble(origen = por_codigo, destino = por_codigo,
                                           portales = NA_integer_, metodo = "codigo")) |>
    group_by(origen) |>
    mutate(fraccion = if (all(is.na(portales))) 1 else portales / sum(portales)) |>
    ungroup()
  attr(tabla, "sin_paso") <- setdiff(sin_casar, por_codigo)
  tabla
}

# Estado de las cifras reproyectadas en cada sección de destino (plan, §6.3; adoptado el
# 6-nov-2026). Una sección de origen «cae entera» si su fracción hacia ese destino es ≥ umbral.
#   recuentos y medias ponderadas: «dato» si todos sus orígenes caen enteros (sumar o
#     promediar con pesos es exacto); «estimado» si alguno se reparte;
#   medianas: no se combinan; se copia la de un solo origen. «dato» con un único origen que
#     cae entero (la misma sección, aunque cambie de código); «estimado» con un único origen
#     repartido o con un origen dominante (≥ umbral_dominante de los portales que recibe la
#     sección); «ausente» si ningún origen domina. `origen_mediana` dice de dónde se copia.
geo_estado_paso <- function(tabla, umbral = 0.99, umbral_dominante = 0.95) {
  tabla |>
    mutate(peso_entrada = dplyr::coalesce(as.numeric(portales), 1)) |>
    group_by(seccion = destino) |>
    summarise(
      n_origenes       = n_distinct(origen),
      enteros          = all(fraccion >= umbral),
      origen_dominante = origen[which.max(peso_entrada)],
      cuota_dominante  = max(peso_entrada) / sum(peso_entrada),
      .groups = "drop"
    ) |>
    mutate(
      estado_recuento = if_else(enteros, "dato", "estimado"),
      estado_media    = estado_recuento,
      estado_mediana  = case_when(n_origenes == 1 & enteros ~ "dato",
                                  n_origenes == 1 | cuota_dominante >= umbral_dominante ~ "estimado",
                                  TRUE ~ "ausente"),
      origen_mediana  = if_else(estado_mediana == "ausente", NA_character_, origen_dominante)
    )
}

avisar_sin_paso <- function(valores, tabla) {
  sin_paso <- setdiff(valores$seccion, tabla$origen)
  if (length(sin_paso) > 0) {
    warning(length(sin_paso), " secciones de origen sin tabla de paso: su valor se pierde (",
            paste(utils::head(sin_paso, 5), collapse = ", "), "…)", call. = FALSE)
  }
}

# Lleva recuentos (población, viviendas…) de las secciones de origen a las de destino,
# repartiéndolos con las fracciones de la tabla.
geo_reproyectar_recuento <- function(valores, tabla, umbral = 0.99) {
  avisar_sin_paso(valores, tabla)
  valores |>
    inner_join(tabla, by = c("seccion" = "origen"), relationship = "one-to-many") |>
    group_by(seccion = destino) |>
    summarise(valor = sum(valor * fraccion), .groups = "drop") |>
    left_join(geo_estado_paso(tabla, umbral) |> select(seccion, estado = estado_recuento), by = "seccion")
}

# Medias ponderadas (renta media por hogar…): media de los orígenes ponderada por su
# denominador (`peso`: hogares, personas) y por la fracción de la tabla.
geo_reproyectar_media <- function(valores, tabla, umbral = 0.99) {
  avisar_sin_paso(valores, tabla)
  valores |>
    inner_join(tabla, by = c("seccion" = "origen"), relationship = "one-to-many") |>
    group_by(seccion = destino) |>
    summarise(valor = sum(valor * peso * fraccion) / sum(peso * fraccion), .groups = "drop") |>
    left_join(geo_estado_paso(tabla, umbral) |> select(seccion, estado = estado_media), by = "seccion")
}

# Medianas (e índices): se copia la del único origen o la del origen dominante; si ninguno
# domina, sin dato.
geo_reproyectar_mediana <- function(valores, tabla, umbral = 0.99, umbral_dominante = 0.95) {
  avisar_sin_paso(valores, tabla)
  geo_estado_paso(tabla, umbral, umbral_dominante) |>
    left_join(select(valores, origen_mediana = seccion, valor), by = "origen_mediana") |>
    transmute(seccion, valor, estado = estado_mediana, origen = origen_mediana) |>
    arrange(seccion)
}

# Prueba de cierre (plan, §6.3): la población reproyectada, sumada por municipio, frente al
# total municipal publicado. Devuelve la desviación en % para la compuerta.
geo_cierre_poblacional <- function(reproyectado, totales_municipio) {
  reproyectado |>
    mutate(municipio = substr(seccion, 1, 5)) |>
    group_by(municipio) |>
    summarise(reproyectado = sum(valor), .groups = "drop") |>
    full_join(totales_municipio |> select(municipio = codigo, publicado = valor), by = "municipio") |>
    mutate(desviacion_pct = 100 * (dplyr::coalesce(reproyectado, 0) - publicado) / publicado)
}

# Comprobaciones de la compuerta (referencia cierre_poblacional) para un año del ADRH: su
# población por sección, llevada al seccionado de 2021 con `tabla`, frente al total
# municipal publicado ese año. Las tablas no cruzan municipios: la prueba detecta sobre
# todo secciones sin tabla de paso y municipios que cambian.
comprobar_cierre_poblacional <- function(poblacion, tabla, anio) {
  secciones <- poblacion |> filter(anio == !!anio, nivel == "seccion") |> select(seccion = codigo, valor)
  municipios <- poblacion |> filter(anio == !!anio, nivel == "municipio") |> select(codigo, valor)
  geo_cierre_poblacional(geo_reproyectar_recuento(secciones, tabla), municipios) |>
    transmute(id = "cierre_poblacional", anio = as.integer(!!anio), detalle = municipio,
              calculado = desviacion_pct, referencia = 0)
}

# Diagnóstico sección a sección (no es compuerta): población de un año llevada a 2021
# frente a la publicada en el seccionado de 2021 (ADRH 2020). La razón mezcla el error de
# la tabla con el crecimiento real entre los dos años; `afectada` marca las secciones de
# destino que reciben de otra sección o de una sección que se reparte.
geo_diagnostico_paso <- function(poblacion, tabla, anio, anio_nativo = 2020L) {
  secciones <- function(a) poblacion |> filter(anio == a, nivel == "seccion") |> select(seccion = codigo, valor)
  repartidas <- unique(tabla$origen[duplicated(tabla$origen)])
  afectadas <- unique(tabla$destino[tabla$origen != tabla$destino | tabla$origen %in% repartidas])
  geo_reproyectar_recuento(secciones(anio), tabla) |>
    inner_join(secciones(anio_nativo), by = "seccion", suffix = c("_reproyectado", "_nativo")) |>
    transmute(seccion, anio_origen = as.integer(anio), reproyectado = valor_reproyectado,
              nativo = valor_nativo, razon = nativo / reproyectado, afectada = seccion %in% afectadas,
              estado)
}

# Secciones que conservan el código entre dos seccionados y cuánto cambian de superficie:
# parte del área de la sección de `a` que no está en la misma sección de `b`, y al revés.
geo_cambios_limites <- function(a, b) {
  comunes <- intersect(a$seccion, b$seccion)
  a <- a[match(comunes, a$seccion), ]
  b <- b[match(comunes, b$seccion), ]
  area_a <- as.numeric(sf::st_area(a))
  area_b <- as.numeric(sf::st_area(b))
  interseccion <- vapply(seq_along(comunes), function(i) {
    x <- suppressWarnings(sf::st_intersection(sf::st_geometry(a)[i], sf::st_geometry(b)[i]))
    if (length(x) == 0) 0 else as.numeric(sum(sf::st_area(x)))
  }, numeric(1))
  tibble::tibble(
    seccion = comunes,
    area_a = area_a,
    area_b = area_b,
    cambio_pct = 100 * pmax(1 - interseccion / area_a, 1 - interseccion / area_b)
  )
}
