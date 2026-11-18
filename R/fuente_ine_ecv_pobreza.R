# Indicador 24 (tarea 65, parte B): tasa de riesgo de pobreza tras los gastos de vivienda, con los
# microdatos de la ECV que ya lee el pipeline (leer_ine_ecv(), R/fuente_ine_ecv.R) y la definición de
# Eurostat (ilc_li48; R/fuente_eurostat_ilc_li48.R):
#   - renta disponible equivalente de cada persona: HY020 entre las unidades de consumo de su hogar
#     (HX240, escala de la OCDE modificada), como en los quintiles del indicador 22;
#   - umbral de la ola: 60 % de la mediana de esa renta, con el factor de cada persona (RB050), sobre
#     toda la población con renta; el umbral no se recalcula tras restar la vivienda;
#   - renta tras la vivienda: (HY020 − 12 × HH070) entre las mismas unidades de consumo. Las ayudas a
#     la vivienda (HY070G) no se tocan: restarlas de la renta y del gasto a la vez, como en la tasa
#     de sobrecarga, da la misma resta;
#   - en riesgo de pobreza tras la vivienda: renta tras la vivienda por debajo del umbral (estricto).
# Personas en hogares sin gasto declarado (HH070 vacío): fuera del cálculo, como en el 22.
# Ponderación por persona (RB050). Con esta definición, España reproduce ilc_li48 a un decimal en las
# olas 2016–2025 (compuerta ahc_es_eurostat), también por grado de urbanización (ilc_li48, DB100;
# ahc_es_urbanizacion) y por edad (ilc_li45, RB081 o, hasta 2020, RB010 − RB080 − 1; ahc_es_edad).

PROPORCION_UMBRAL_POBREZA <- 0.6
# Grupos de edad de ilc_li45 (además del total): menores de 18, de 18 a 64, 65 y más y 18 y más
# (este último reúne los dos anteriores).
EDADES_POBREZA <- c("Y_LT18", "Y18-64", "Y_GE65", "Y_GE18")
# Grado de urbanización (DB100 de la ECV) → deg_urb de Eurostat: GRADOS_URBANIZACION_ECV
# (R/fuente_ine_ecv.R), el mismo que el del 22.
# Total agrupado de cada comunidad (trienio de olas, toda la población) en la tabla larga: corte y
# grupo propios (inventario/vocabulario.csv), porque corte y grupo `total` son la cifra anual.
CORTE_TOTAL_AGRUPADO <- c(corte = "olas", grupo = "trienio")

# Personas con su renta equivalente, el umbral de su ola y la marca `pobre` (una fila por persona).
personas_pobreza_vivienda <- function(ecv, proporcion = PROPORCION_UMBRAL_POBREZA) {
  p <- ecv$personas |>
    inner_join(ecv$hogares, by = "id_hogar") |>
    filter(!is.na(peso_persona)) |>
    mutate(renta_equivalente = renta_disponible / unidades_consumo) |>
    filter(!is.na(renta_equivalente), is.finite(renta_equivalente))
  if (!nrow(p)) stop("Ninguna persona con renta disponible equivalente", call. = FALSE)
  mediana <- cuantil_ponderado(p$renta_equivalente, p$peso_persona, 0.5)
  umbral <- proporcion * mediana
  p |>
    filter(!is.na(gasto_vivienda_mes)) |>
    mutate(
      renta_tras_vivienda = (renta_disponible - 12 * gasto_vivienda_mes) / unidades_consumo,
      pobre             = renta_tras_vivienda < umbral,
      mediana           = mediana,
      umbral            = umbral,
      tenencia_eurostat = unname(TENENCIA_EUROSTAT[as.character(tenencia)]),
      propietario       = tenencia_eurostat %in% c("OWN_NL", "OWN_L"),
      grupo_edad        = grupo_edad_eurostat(edad),
      grado             = unname(GRADOS_URBANIZACION_ECV[as.character(grado_urbanizacion)])
    )
}

# Tasa ponderada por grupos (% de personas en riesgo de pobreza tras la vivienda), con la muestra y
# la suma de los factores (`peso`, para rehacer el total en la compuerta).
tasa_pobreza_vivienda <- function(datos, corte, grupo, ambito = "ES") {
  datos |>
    mutate(corte = .env$corte, grupo = .env$grupo, ambito = .env$ambito) |>
    group_by(ambito, corte, grupo) |>
    summarise(
      valor      = 100 * sum(peso_persona[pobre]) / sum(peso_persona),
      peso       = sum(peso_persona),
      n_personas = n(),
      n_hogares  = n_distinct(id_hogar),
      .groups = "drop"
    )
}

# Una ola: España en total, por tenencia (las cuatro de Eurostat y propietarios e inquilinos
# agregados), por edad (EDADES_POBREZA, las de ilc_li45) y por grado de urbanización (GRADOS_URBANIZACION_ECV,
# los de ilc_li48), y cada comunidad (región NUTS 2) en total, con el umbral de la ola (`umbral`, euros
# al año, para la compuerta ahc_umbral_ine). Sin tenencia, edad o grado, la persona cuenta en el total
# y no en ese corte.
calcular_pobreza_vivienda_ecv <- function(ecv, proporcion = PROPORCION_UMBRAL_POBREZA) {
  p <- personas_pobreza_vivienda(ecv, proporcion)
  pt <- con_tenencia(p)
  pe <- filter(p, !is.na(grupo_edad))
  adultos <- filter(p, !is.na(edad), edad >= 18)
  pg <- filter(p, !is.na(grado))
  bind_rows(
    tasa_pobreza_vivienda(p, "total", "TOTAL"),
    tasa_pobreza_vivienda(pt, "tenencia", pt$tenencia_eurostat),
    tasa_pobreza_vivienda(pt, "tenencia", ifelse(pt$propietario, "OWN", "RENT")),
    tasa_pobreza_vivienda(pe, "edad", pe$grupo_edad),
    tasa_pobreza_vivienda(adultos, "edad", "Y_GE18"),
    tasa_pobreza_vivienda(pg, "urbanizacion", pg$grado),
    tasa_pobreza_vivienda(p, "region", p$region)
  ) |>
    select(-ambito) |>
    mutate(anio = unique(ecv$hogares$anio), indicador = "pobreza_tras_vivienda", umbral = unique(p$umbral), .before = 1)
}

# Comunidad × tenencia y comunidad × edad con varias olas agrupadas, como el 22
# (calcular_sobrecarga_agrupada()): cada persona con el umbral de su ola y cada ola con el mismo peso
# (su factor entre el número de olas). Edades: las de ilc_li45 (EDADES_POBREZA; 18 y más reúne 18–64 y
# 65 y más; decisión del autor del 17-nov-2026). Lleva también el total de cada comunidad con las
# mismas olas (corte «total»): sirve a la compuerta ahc_ccaa_edad_total y, desde el 18-nov-2026
# (decisión del autor), se publica en la tabla larga (CORTE_TOTAL_AGRUPADO) y en la web. Sin tenencia
# o edad, la persona cuenta en el total y no en ese corte. En el pipeline, un trienio por ola con
# agrupar_trienios() (R/fuente_ine_ecv.R). Observaciones: personas distintas estimadas, como en el 22
# (contar_distintas(), n_distintas_rotacion(); decisión del autor del 18-nov-2026); `n_personas_olas`
# guarda la suma por olas.
calcular_pobreza_vivienda_agrupada <- function(olas, proporcion = PROPORCION_UMBRAL_POBREZA) {
  p <- bind_rows(lapply(olas, personas_pobreza_vivienda, proporcion = proporcion)) |>
    mutate(peso_persona = peso_persona / length(olas), id_hogar = paste(anio, id_hogar))
  anios <- range(p$anio)
  pt <- con_tenencia(p)
  pe <- filter(p, !is.na(grupo_edad))
  adultos <- filter(p, !is.na(edad), edad >= 18)
  celda <- function(d, corte, grupo) {
    tasa_pobreza_vivienda(d, corte, grupo, ambito = d$region) |>
      left_join(contar_distintas(d, corte, grupo, d$region), by = c("ambito", "corte", "grupo"))
  }
  bind_rows(
    celda(p, "total", "TOTAL"),
    celda(pt, "tenencia", pt$tenencia_eurostat),
    celda(pt, "tenencia", ifelse(pt$propietario, "OWN", "RENT")),
    celda(pe, "edad", pe$grupo_edad),
    celda(adultos, "edad", "Y_GE18")
  ) |>
    rename(region = ambito, n_personas_olas = n_personas) |>
    mutate(n_personas = as.integer(n_distintas), .after = n_personas_olas) |>
    select(-n_distintas) |>
    mutate(fiabilidad = fiabilidad_eusilc(n_personas), anio_inicio = anios[1], anio_fin = anios[2],
           olas = length(olas), indicador = "pobreza_tras_vivienda", .before = 1)
}

# Compuerta (inventario/referencias_validacion.csv):
#   ahc_es_eurostat (bloqueo): España, cada ola, frente a ilc_li48 (grado de urbanización TOTAL) del
#     mismo año. Sin cifra de Eurostat para una ola, para;
#   ahc_umbral_ine (bloqueo): el umbral anual de la ola frente al del INE para un hogar unipersonal
#     sin alquiler imputado (tabla 9964; umbral_ecv, R/linea_residual.R), si se da `umbral_ine`;
#   ahc_tenencia_total (bloqueo): la media de las cuatro tenencias de Eurostat, ponderada por la suma
#     de sus factores, reproduce el total (ninguna persona se pierde ni se cuenta dos veces; en 2016, un
#     hogar sin tenencia queda solo en el total);
#   ahc_es_urbanizacion (bloqueo): España por grado de urbanización, cada ola, frente a ilc_li48
#     (DEG1, DEG2, DEG3) del mismo año;
#   ahc_es_edad (bloqueo): España por edad, cada ola, frente a ilc_li45 (ambos sexos) del mismo año,
#     si se da `edad` (leer_eurostat_ilc_li45());
#   ahc_ccaa_edad_total (bloqueo), si se da `agrupada` (calcular_pobreza_vivienda_agrupada(), un
#     trienio por ola): en cada trienio y comunidad, la media de los tres grupos de edad que no se
#     solapan (menores de 18, 18–64, 65 y más), ponderada por la suma de sus factores, reproduce el
#     total de la comunidad con las mismas olas, y la de 18–64 y 65 y más, la de 18 y más. Eurostat no
#     publica la tasa por comunidad: es una compuerta de coherencia, como ahc_tenencia_total.
# Sin cifra de Eurostat para un grupo de una ola, para.
comprobar_pobreza_vivienda <- function(anual, eurostat, umbral_ine = NULL, edad = NULL, agrupada = NULL) {
  total <- filter(anual, corte == "total")
  # Lo calculado de un corte frente a su referencia (anio, grupo, referencia); sin referencia, para
  frente_a <- function(id, corte, ref, tabla) {
    d <- anual |> filter(.data$corte == .env$corte) |> select(anio, grupo, calculado = valor) |>
      left_join(ref, by = c("anio", "grupo"))
    sin_ref <- unique(paste(d$anio[is.na(d$referencia)], d$grupo[is.na(d$referencia)]))
    if (any(is.na(d$referencia))) {
      stop("Eurostat no publica todavía la tasa de riesgo de pobreza tras los gastos de vivienda de España (", tabla,
           ") de ", paste(sin_ref, collapse = ", "), ": no hay referencia para la compuerta", call. = FALSE)
    }
    transmute(d, id = id, anio, detalle = paste("ES,", grupo), calculado, referencia)
  }
  ref <- filter(eurostat, geo == "ES", grado == "TOTAL") |> transmute(anio, grupo = "TOTAL", referencia = valor)
  filas <- list(frente_a("ahc_es_eurostat", "total", ref, "ilc_li48"))
  if (!is.null(umbral_ine)) {
    u <- filter(umbral_ine, hogar == "una_persona", !imputado) |> select(anio = ola, referencia = valor)
    filas[[2]] <- total |> distinct(anio, calculado = umbral) |> left_join(u, by = "anio") |>
      transmute(id = "ahc_umbral_ine", anio, detalle = "umbral anual, hogar unipersonal", calculado, referencia)
  }
  ten <- anual |> filter(corte == "tenencia", grupo %in% unname(unique(TENENCIA_EUROSTAT)))
  filas[[length(filas) + 1L]] <- ten |>
    group_by(anio) |>
    summarise(calculado = sum(valor * peso) / sum(peso), n = n(), .groups = "drop") |>
    left_join(select(total, anio, valor), by = "anio") |>
    transmute(id = "ahc_tenencia_total", anio, detalle = paste("media ponderada de", n, "tenencias"),
              calculado, referencia = valor)
  grados <- filter(eurostat, geo == "ES", grado %in% GRADOS_URBANIZACION_ECV) |> select(anio, grupo = grado, referencia = valor)
  filas[[length(filas) + 1L]] <- frente_a("ahc_es_urbanizacion", "urbanizacion", grados, "ilc_li48")
  if (!is.null(edad)) {
    edades <- filter(edad, geo == "ES", sexo == "T", .data$edad %in% EDADES_POBREZA) |>
      select(anio, grupo = edad, referencia = valor)
    filas[[length(filas) + 1L]] <- frente_a("ahc_es_edad", "edad", edades, "ilc_li45")
  }
  if (!is.null(agrupada)) filas[[length(filas) + 1L]] <- comprobar_pobreza_edad_ccaa(agrupada)
  bind_rows(filas)
}

# ahc_ccaa_edad_total: coherencia de comunidad × edad con el total de la comunidad (ver arriba). Un
# grupo sin personas no está y no pesa. `anio` es la última ola del trienio; sin el total o sin
# ningún grupo, sin cifra (falla).
comprobar_pobreza_edad_ccaa <- function(agrupada) {
  media <- function(d, grupos, ref, detalle) {
    d |>
      group_by(anio = anio_fin, region) |>
      summarise(calculado = {
        g <- corte == "edad" & grupo %in% grupos
        if (any(g)) sum(valor[g] * peso[g]) / sum(peso[g]) else NA_real_
      },
      referencia = { r <- valor[corte == ref[1] & grupo == ref[2]]; if (length(r) == 1) r else NA_real_ },
      .groups = "drop") |>
      transmute(id = "ahc_ccaa_edad_total", anio, detalle = paste0(region, ", ", detalle), calculado, referencia)
  }
  bind_rows(
    media(agrupada, c("Y_LT18", "Y18-64", "Y_GE65"), c("total", "TOTAL"), "media ponderada de 3 grupos de edad frente al total"),
    media(agrupada, c("Y18-64", "Y_GE65"), c("edad", "Y_GE18"), "media ponderada de 18-64 y 65 y más frente a 18 y más")
  ) |>
    arrange(anio, detalle)
}

# Indicador 24 en la tabla larga, como el 22 (armonizar_sobrecarga_ecv()): España («00»), cada ola,
# en total y por tenencia, edad y grado de urbanización; comunidades, cada ola, en total; comunidad ×
# tenencia y comunidad × edad con las olas agrupadas (`anio`, la última). El total agrupado de cada
# comunidad también entra (decisión del autor del 18-nov-2026), con `anio` la última ola como los
# cruces y el corte `olas`, grupo `trienio` (inventario/vocabulario.csv), para no chocar con el total
# anual de la comunidad (corte y grupo `total`) del mismo año. Con menos de 20 observaciones, «secreto».
armonizar_pobreza_vivienda_ecv <- function(anual, agrupada, ccaa, version) {
  nuts <- select(ccaa, codigo, nuts2)
  espana <- anual |>
    filter(corte != "region") |>
    transmute(geo_id = "00", nivel = "nacional", anio, corte, grupo = if_else(corte == "total", "total", grupo),
              valor, n_personas)
  comunidades <- anual |>
    filter(corte == "region") |>
    left_join(nuts, by = c("grupo" = "nuts2")) |>
    transmute(geo_id = codigo, nivel = "ccaa", anio, corte = "total", grupo = "total", valor, n_personas)
  cruces <- agrupada |>
    left_join(nuts, by = c("region" = "nuts2")) |>
    transmute(geo_id = codigo, nivel = "ccaa", anio = anio_fin,
              grupo = if_else(corte == "total", CORTE_TOTAL_AGRUPADO[["grupo"]], grupo),   # antes que `corte`
              corte = if_else(corte == "total", CORTE_TOTAL_AGRUPADO[["corte"]], corte), valor, n_personas)
  x <- bind_rows(espana, comunidades, cruces)
  if (anyNA(x$geo_id)) stop("Regiones de la ECV sin comunidad en la tabla ccaa", call. = FALSE)
  x |>
    mutate(estado = if_else(fiabilidad_eusilc(n_personas) == "no publicable", "secreto", "dato"),
           valor = if_else(estado == "secreto", NA_real_, valor),
           indicador = "pobreza_tras_vivienda", fuente = "ine_ecv", geo_ref = NA_character_, version = version) |>
    select(-n_personas)
}
