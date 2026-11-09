# Ficha «transistor» (pensionista): pensión media de jubilación del INSS por provincia, neta de la
# retención del IRPF y repartida en 12 (plan §3.1; método decidido por el autor el 9-nov-2026):
#   1. Pensión media de jubilación de cada provincia y año (total del sistema, sin Clases
#      Pasivas): media de las doce cifras mensuales (pensiones en vigor a día 1 de cada mes),
#      ponderada por el número de pensiones (armonizar_inss_pensiones, anual_inss_pensiones).
#   2. Bruto anual = media × 14 pagas (la media del INSS es la de una paga ordinaria).
#   3. Retención: tipo medio de la AEAT de las personas que solo cobran pensiones (bloque
#      PENSIONES, columna «Pensionistas» de «Grupos de población por la naturaleza de sus
#      retribuciones»), por comunidad y tramo de renta anual, interpolado en el bruto anual, del
#      mismo año (retenciones_pensiones). La AEAT no separa la jubilación de las demás pensiones.
#      País Vasco y Navarra (IRPF foral, sin datos de la AEAT): curva de España y estado
#      «estimado». Las pensiones no cotizan.
#   4. Neto mensual = bruto anual × (1 − retención) / 12.
# La provincia es la de la dirección provincial que gestiona la pensión, no la de residencia, y
# se cuentan pensiones, no pensionistas (quien cobra dos pensiones aparece dos veces).

ANIOS_TRANSISTOR <- 2015:2024
PAGAS_PENSION <- 14L
CCAA_FORALES <- c("15", "16")   # Navarra y Pais Vasco

# Pensiones de jubilación de cada mes con el código de su territorio (inventario/provincias_inss.csv):
# nivel (nacional, ccaa o provincia), código y comunidad. Las comunidades de una provincia
# (Asturias, Baleares, Cantabria, Madrid, Murcia, Navarra, La Rioja) y Ceuta y Melilla salen
# como provincia. Se quitan las filas repetidas (algún Excel trae el total dos veces); una
# etiqueta sin código en la tabla detiene el proceso.
armonizar_inss_pensiones <- function(leidas, provincias_inss) {
  sin_codigo <- setdiff(unique(leidas$clave), provincias_inss$clave_inss)
  if (length(sin_codigo) > 0) {
    stop("Territorios del INSS sin c\u00f3digo en provincias_inss.csv: ", paste(sin_codigo, collapse = ", "), call. = FALSE)
  }
  leidas |>
    inner_join(provincias_inss, by = c("clave" = "clave_inss")) |>
    distinct(anio, mes, nivel, codigo, ccaa, pensiones, media) |>
    arrange(anio, mes, nivel, codigo)
}

# Media anual de cada territorio: pensiones medias del año y pensión media ponderada por el
# número de pensiones de cada mes (lo que cobra de media una pensión en el año, por paga).
anual_inss_pensiones <- function(mensual) {
  mensual |>
    group_by(anio, nivel, codigo, ccaa) |>
    summarise(meses = n(), media = sum(pensiones * media) / sum(pensiones), pensiones = mean(pensiones),
              .groups = "drop") |>   # la media antes: summarise() usa ya la `pensiones` resumida
    relocate(pensiones, .before = media)
}

# Compuerta del INSS (inventario/referencias_validacion.csv):
#   inss_cobertura (bloqueo): territorios que faltan o se repiten en cada año (52 provincias, 10
#     comunidades de varias provincias y España, en los 12 meses);
#   inss_suma (bloqueo): diferencia máxima entre el número de pensiones de las provincias y el
#     publicado para su comunidad y para España, cada mes;
#   inss_media (bloqueo): diferencia máxima (euros) entre la pensión media de las provincias,
#     ponderada por su número, y la publicada para su comunidad y para España, cada mes.
comprobar_inss_pensiones <- function(mensual, provincias_inss, anios = ANIOS_TRANSISTOR) {
  esperados <- provincias_inss |> distinct(nivel, codigo)
  cobertura <- lapply(anios, function(a) {
    m <- mensual[mensual$anio == a, ]
    n <- m |> count(nivel, codigo, name = "n")
    x <- esperados |> left_join(n, by = c("nivel", "codigo")) |> mutate(n = coalesce(n, 0L))
    tibble::tibble(id = "inss_cobertura", anio = a, detalle = "territorios sin los 12 meses o repetidos",
                   calculado = sum(x$n != 12L) + length(setdiff(unique(m$mes), 1:12)), referencia = 0)
  })
  prov <- mensual |> filter(nivel == "provincia")
  agregado <- bind_rows(
    prov |> group_by(anio, mes, nivel = "ccaa", codigo = ccaa) |>
      summarise(suma = sum(pensiones), ponderada = sum(pensiones * media) / sum(pensiones), .groups = "drop"),
    prov |> group_by(anio, mes, nivel = "nacional", codigo = "00") |>
      summarise(suma = sum(pensiones), ponderada = sum(pensiones * media) / sum(pensiones), .groups = "drop")
  ) |>
    inner_join(filter(mensual, nivel != "provincia") |> select(anio, mes, nivel, codigo, pensiones, media),
               by = c("anio", "mes", "nivel", "codigo"))
  dif <- agregado |>
    group_by(anio) |>
    summarise(suma = max(abs(suma - pensiones)), media = max(abs(ponderada - media)), comparadas = n(), .groups = "drop")
  bind_rows(
    cobertura,
    tibble::tibble(id = "inss_suma", anio = dif$anio, detalle = paste(dif$comparadas, "cifras de comunidad y Espa\u00f1a"),
                   calculado = dif$suma, referencia = 0),
    tibble::tibble(id = "inss_media", anio = dif$anio, detalle = paste(dif$comparadas, "cifras de comunidad y Espa\u00f1a"),
                   calculado = dif$media, referencia = 0)
  ) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Clave de una comunidad que no depende de cómo la escribe cada edición de la AEAT («Región de
# Murcia» y «Murcia, Región de»; «Comunidad Valenciana» y «Comunitat Valenciana»; «Ciudad de
# Ceuta» y «Ceuta»): palabras sin tildes, sin las genéricas, en orden alfabético.
clave_comunidad <- function(x) {
  genericas <- c("de", "la", "y", "ciudad", "comunidad", "comunitat", "illes", "principado", "region", "foral")
  vapply(strsplit(nombre_columna(x), "_", fixed = TRUE),
         function(p) paste(sort(setdiff(p, c(genericas, ""))), collapse = "_"), "")
}

# Curva de retención de los pensionistas de cada comunidad (código del INE; España, «00»): una
# fila por año, comunidad y tramo de renta anual, con la renta media del tramo (euros; columna
# salario_medio, para tipo_retencion()) y el tipo de retención. La columna de la comunidad se
# llama distinto según la edición (distribucion_geografica o comunidad_autonoma).
retenciones_pensiones <- function(grupos, anio, ccaa) {
  geo <- intersect(c("distribucion_geografica", "comunidad_autonoma"), names(grupos))[1]
  if (is.na(geo)) stop("Sin columna de comunidad en las retenciones de la AEAT de ", anio, call. = FALSE)
  claves <- c(stats::setNames(ccaa$codigo, clave_comunidad(ccaa$nombre_ine)), total = "00")
  r <- grupos |>
    filter(bloque == "PENSIONES", columna == "Pensionistas", tramos_de_renta_anual != "Total",
           fila %in% c("Personas", "Retribuciones", "Retenciones")) |>
    transmute(geo = .data[[geo]], tramo = tramos_de_renta_anual, fila, valor) |>
    tidyr::pivot_wider(names_from = fila, values_from = valor) |>
    filter(Personas > 0, Retribuciones > 0) |>
    transmute(anio = as.integer(anio), geo, ccaa = unname(claves[clave_comunidad(geo)]), tramo, personas = Personas,
              salario_medio = 1000 * Retribuciones / Personas, retencion = Retenciones / Retribuciones)
  if (anyNA(r$ccaa)) {
    stop("Comunidades de la AEAT sin c\u00f3digo (", anio, "): ", paste(unique(r$geo[is.na(r$ccaa)]), collapse = ", "), call. = FALSE)
  }
  arrange(select(r, -geo), anio, ccaa, salario_medio)
}

# Neto mensual del transistor por provincia y año (pasos 2 a 4). `anual`: anual_inss_pensiones();
# `retenciones`: retenciones_pensiones() de los años de la ficha. Estado: «dato»; con la curva
# de España (forales), «estimado».
calcular_transistor <- function(anual, retenciones, pagas = PAGAS_PENSION, forales = CCAA_FORALES) {
  p <- anual |> filter(nivel == "provincia")
  curva <- if_else(p$ccaa %in% forales, "00", p$ccaa)
  retencion <- mapply(function(bruto, a, k) {
    c <- retenciones[retenciones$anio == a & retenciones$ccaa == k, ]
    if (nrow(c) == 0) return(NA_real_)
    tipo_retencion(bruto, c)
  }, p$media * pagas, p$anio, curva)
  p |>
    transmute(provincia = codigo, ccaa, anio, pensiones, media_paga = media, bruto_anual = media * pagas,
              curva = curva, retencion = retencion, neto_anual = bruto_anual * (1 - retencion),
              neto_mensual = neto_anual / 12,
              estado = case_when(is.na(neto_mensual) ~ "ausente", ccaa %in% forales ~ "estimado", TRUE ~ "dato"))
}

# Compuerta del neto del transistor (bloqueo): por año, provincias sin neto (de las 52) y
# retenciones fuera de [0, 30 %] (la más alta de la AEAT para pensionistas, por encima de 30.000 €
# al año, ronda el 18 %).
PROVINCIAS_ESPANA <- 52L
comprobar_transistor <- function(transistor, anios = ANIOS_TRANSISTOR) {
  x <- tibble::tibble(anio = as.integer(anios)) |>
    left_join(transistor |> group_by(anio) |>
                summarise(con_neto = sum(!is.na(neto_mensual)),
                          fuera = sum(retencion < 0 | retencion > 0.3, na.rm = TRUE), .groups = "drop"),
              by = "anio") |>
    mutate(con_neto = coalesce(con_neto, 0L), fuera = coalesce(fuera, 0L))
  bind_rows(
    tibble::tibble(id = "transistor_cobertura", anio = x$anio, detalle = "provincias sin neto",
                   calculado = PROVINCIAS_ESPANA - x$con_neto, referencia = 0),
    tibble::tibble(id = "transistor_retencion", anio = x$anio, detalle = "retenciones fuera de [0, 30 %]",
                   calculado = x$fuera, referencia = 0)
  ) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}
