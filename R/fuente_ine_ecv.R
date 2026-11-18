# Fuente ine_ecv: INE, Encuesta de Condiciones de Vida, microdatos transversales (base 2013).
# Indicador 22: tasa de sobrecarga por gastos de vivienda con el método de Eurostat.
# Criterios del cálculo (renta neta de ayudas ≤ 0, hogares sin gasto declarado,
# ponderación por persona) reaprovechados de un proyecto propio anterior: 6-nov-2026.

url_ine_ecv <- function(anio) {
  sprintf("https://www.ine.es/ftp/microdatos/ecv/ecv_b2013/datos_%d.zip", anio)
}

descargar_ine_ecv <- function(anio, dir = file.path("datos", "brutos", "ine_ecv"), forzar = FALSE) {
  descargar_con_cache(url_ine_ecv(anio), file.path(dir, sprintf("datos_%d.zip", anio)), forzar)
}

# El zip anual del INE contiene un zip por fichero (ECV_Td_2025.zip, ECV_Tr_…, ECV_Th_…,
# ECV_Tp_…) y cada uno, el CSV separado por comas en CSV/esudb<aa><letra>.csv.
# Extrae los CSV de los ficheros pedidos y devuelve sus rutas, con nombre (d, r, h, p).
# De 2016 a 2020, el Tr no trae CSV/esudb<aa>r.csv sino CSV/esudb<aa>r_AROPE.csv (las mismas
# personas y variables, más las del indicador AROPE) y CSV/ECV_Tr_<año>.csv (separado por
# tabuladores): se toma el primero y se guarda como esudb<aa>r.csv.
extraer_ine_ecv <- function(zip, anio, ficheros = c("d", "r", "h"),
                            dir = file.path("datos", "intermedios", "ine_ecv")) {
  destino <- file.path(dir, anio)
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  temporal <- tempfile("ine_ecv_")
  on.exit(unlink(temporal, recursive = TRUE), add = TRUE)
  contenido <- utils::unzip(zip, list = TRUE)$Name

  rutas <- vapply(ficheros, function(f) {
    patron_csv <- sprintf("(^|/)CSV/esudb%02d%s(_AROPE)?\\.csv$", anio %% 100, f)
    sin_arope <- function(x) if (length(x) > 1) x[!grepl("_AROPE", x, ignore.case = TRUE)] else x
    directo <- sin_arope(grep(patron_csv, contenido, value = TRUE, ignore.case = TRUE))
    if (length(directo) == 1) {
      utils::unzip(zip, files = directo, exdir = temporal, junkpaths = TRUE)
    } else {
      interno <- grep(sprintf("(^|/)ECV_T%s_%d\\.zip$", f, anio), contenido,
                      value = TRUE, ignore.case = TRUE)
      if (length(interno) != 1) {
        stop("No encuentro el fichero T", toupper(f), " de ", anio, " dentro de ", zip,
             ". Contenido: ", paste(contenido, collapse = ", "), call. = FALSE)
      }
      utils::unzip(zip, files = interno, exdir = temporal, junkpaths = TRUE)
      zip_interno <- file.path(temporal, basename(interno))
      csv <- sin_arope(grep(patron_csv, utils::unzip(zip_interno, list = TRUE)$Name,
                            value = TRUE, ignore.case = TRUE))
      if (length(csv) != 1) stop("No encuentro el CSV dentro de ", interno, call. = FALSE)
      utils::unzip(zip_interno, files = csv, exdir = temporal, junkpaths = TRUE)
    }
    origen <- list.files(temporal, pattern = sprintf("^esudb%02d%s(_AROPE)?\\.csv$", anio %% 100, f),
                         full.names = TRUE, ignore.case = TRUE)
    if (length(origen) != 1) stop("No encuentro el CSV del fichero T", toupper(f), " de ", anio, call. = FALSE)
    final <- file.path(destino, sprintf("esudb%02d%s.csv", anio %% 100, f))
    file.copy(origen, final, overwrite = TRUE)
    final
  }, character(1))
  rutas
}

# Rutas de los CSV de una ola. Si ya están en datos/brutos/ine_ecv/<año>/ (copiados a
# mano), se usan tal cual; si no, se descarga el zip del INE y se extraen.
obtener_csv_ine_ecv <- function(anio, ficheros = c("d", "r", "h"),
                                dir = file.path("datos", "brutos", "ine_ecv")) {
  manuales <- file.path(dir, anio, sprintf("esudb%02d%s.csv", anio %% 100, ficheros))
  if (all(file.exists(manuales))) return(manuales)
  extraer_ine_ecv(descargar_ine_ecv(anio, dir), anio, ficheros)
}

# Lee las variables necesarias para la sobrecarga.
# Hogar (Td + Th): DB040 región NUTS 2, DB090 factor del hogar, HH021 tenencia,
#   HH070 gasto total mensual en vivienda (de la hipoteca, solo intereses),
#   HY020 renta disponible del año anterior, HY070G ayudas a la vivienda, HX240 unidades de
#   consumo (escala de la OCDE modificada; solo para los quintiles de renta), DB100 grado de
#   urbanización (1 ciudades, 2 pueblos y zonas suburbanas, 3 rural; el deg_urb de Eurostat).
# Persona (Tr): RB030 identificador (hogar + dos dígitos de orden), RB050 factor de la persona,
#   RB081 edad al final del año de ingresos. Las olas de 2016 a 2020 no traen RB081 (llega con el
#   reglamento de EU-SILC de 2021): la edad es la misma, RB010 − RB080 − 1 (año de la encuesta menos
#   año de nacimiento, menos uno), la que trae RB081 desde 2021.
leer_ine_ecv <- function(rutas) {
  ruta <- function(letra) {
    r <- rutas[grepl(sprintf("esudb\\d{2}%s\\.csv$", letra), rutas, ignore.case = TRUE)]
    if (length(r) != 1) stop("Falta el CSV del fichero T", toupper(letra), call. = FALSE)
    r
  }
  leer <- function(ruta, columnas) {
    readr::read_csv(ruta, col_select = dplyr::all_of(columnas),
                    col_types = readr::cols(.default = readr::col_character()),
                    progress = FALSE)
  }
  d <- leer(ruta("d"), c("DB010", "DB030", "DB040", "DB090", "DB100"))
  h <- leer(ruta("h"), c("HB030", "HH021", "HH070", "HY020", "HY070G", "HX240"))
  cabecera_r <- names(readr::read_csv(ruta("r"), n_max = 0, col_types = readr::cols(.default = "c"), progress = FALSE))
  r <- leer(ruta("r"), intersect(c("RB010", "RB030", "RB050", "RB080", "RB081"), cabecera_r))
  if (!"RB081" %in% names(r)) {
    if (!all(c("RB010", "RB080") %in% names(r))) stop("El Tr no trae RB081 ni RB010 y RB080", call. = FALSE)
    r$RB081 <- as.character(as.integer(r$RB010) - as.integer(r$RB080) - 1L)
  }

  hogares <- d |>
    inner_join(h, by = c("DB030" = "HB030")) |>
    transmute(
      anio               = as.integer(DB010),
      id_hogar           = DB030,
      region             = DB040,
      peso_hogar         = as.numeric(DB090),
      grado_urbanizacion = DB100,
      tenencia           = as.integer(HH021),
      gasto_vivienda_mes = as.numeric(HH070),
      renta_disponible   = as.numeric(HY020),
      ayuda_vivienda     = as.numeric(HY070G),
      unidades_consumo   = as.numeric(HX240)   # escala de la OCDE modificada (quintiles de renta)
    )
  if (nrow(hogares) != nrow(d)) stop("Td y Th no casan hogar a hogar", call. = FALSE)

  personas <- r |>
    transmute(
      id_persona   = RB030,
      id_hogar     = substr(RB030, 1, nchar(RB030) - 2),
      peso_persona = as.numeric(RB050),
      edad         = as.integer(RB081)    # edad al final del año de ingresos (la de Eurostat; con la de la entrevista, RB082, el corte por edad de 2025 se desvía 0,12 puntos)
    )
  huerfanas <- sum(!personas$id_hogar %in% hogares$id_hogar)
  if (huerfanas > 0) stop(huerfanas, " personas sin hogar en Td/Th", call. = FALSE)

  list(hogares = hogares, personas = personas)
}

# Cociente de sobrecarga de Eurostat: gasto anual en vivienda neto de ayudas entre
# renta disponible neta de ayudas. Renta neta ≤ 0 → Inf (cuenta como sobrecargado).
# Sin gasto o sin renta declarados → NA (fuera del cálculo).
cociente_sobrecarga <- function(gasto_mes, renta, ayuda) {
  ayuda <- dplyr::coalesce(ayuda, 0)
  renta_neta <- renta - ayuda
  dplyr::case_when(
    is.na(gasto_mes) | is.na(renta) ~ NA_real_,
    renta_neta > 0                  ~ (gasto_mes * 12 - ayuda) / renta_neta,
    TRUE                            ~ Inf
  )
}

# HH021 → categorías de tenencia de Eurostat (ilc_lvho07c)
TENENCIA_EUROSTAT <- c("1" = "OWN_NL", "2" = "OWN_L", "3" = "RENT_MKT", "4" = "RENT_FR", "5" = "RENT_FR")

# DB100 → grado de urbanización de Eurostat (deg_urb): ciudades, pueblos y zonas suburbanas, zonas
# rurales (ilc_lvho07d para el 22; ilc_li48 para el 24).
GRADOS_URBANIZACION_ECV <- c("1" = "DEG1", "2" = "DEG2", "3" = "DEG3")

# Grupos de edad de Eurostat (ilc_lvho07a) que usa el atlas. Y15-29 se solapa con los otros.
grupo_edad_eurostat <- function(edad) {
  dplyr::case_when(is.na(edad) ~ NA_character_, edad < 18 ~ "Y_LT18", edad < 65 ~ "Y18-64", TRUE ~ "Y_GE65")
}

# Personas con su cociente, su tenencia, su grupo de edad y su grado de urbanización (una fila por
# persona).
personas_sobrecarga <- function(ecv, umbral = 0.40) {
  hogares <- ecv$hogares |>
    mutate(
      cociente  = cociente_sobrecarga(gasto_vivienda_mes, renta_disponible, ayuda_vivienda),
      sobrecarga = cociente > umbral,
      tenencia_eurostat = unname(TENENCIA_EUROSTAT[as.character(tenencia)])
    )
  ecv$personas |>
    inner_join(hogares, by = "id_hogar") |>
    filter(!is.na(cociente), !is.na(peso_persona)) |>
    mutate(propietario = tenencia_eurostat %in% c("OWN_NL", "OWN_L"),
           grupo_edad = grupo_edad_eurostat(edad),
           grado = unname(GRADOS_URBANIZACION_ECV[as.character(grado_urbanizacion)]))
}

# Personas con tenencia: las de los cortes por tenencia. Un hogar sin HH021 (uno en 2016) cuenta en
# el total y en los demás cortes, pero en ninguna tenencia (ni en propiedad ni en alquiler).
con_tenencia <- function(p) filter(p, !is.na(tenencia_eurostat))

# Tasa ponderada por grupos, con el tamaño de la muestra detrás.
tasa_sobrecarga <- function(datos, corte, grupo, ambito = "ES") {
  datos |>
    mutate(corte = .env$corte, grupo = .env$grupo, ambito = .env$ambito) |>
    group_by(ambito, corte, grupo) |>
    summarise(
      valor      = 100 * sum(peso_persona[sobrecarga]) / sum(peso_persona),
      n_personas = n(),
      n_hogares  = n_distinct(id_hogar),
      .groups = "drop"
    )
}

# Tasa de sobrecarga (%): personas que viven en hogares cuyo cociente supera el umbral,
# ponderadas por RB050. Cortes: total, tenencia (y propietarios e inquilinos agregados),
# edad, grado de urbanización (DB100, los de ilc_lvho07d; 18-nov-2026) y región NUTS 2. Sin grado,
# la persona cuenta en el total y no en ese corte.
calcular_sobrecarga_ecv <- function(ecv, umbral = 0.40) {
  p <- personas_sobrecarga(ecv, umbral)
  jovenes <- filter(p, !is.na(edad), edad >= 15, edad <= 29)
  pt <- con_tenencia(p)
  pg <- filter(p, !is.na(grado))
  bind_rows(
    tasa_sobrecarga(p, "total", "TOTAL"),
    tasa_sobrecarga(pt, "tenencia", pt$tenencia_eurostat),
    tasa_sobrecarga(pt, "tenencia", ifelse(pt$propietario, "OWN", "RENT")),
    tasa_sobrecarga(filter(p, !is.na(grupo_edad)), "edad", filter(p, !is.na(grupo_edad))$grupo_edad),
    tasa_sobrecarga(jovenes, "edad", "Y15-29"),
    tasa_sobrecarga(pg, "urbanizacion", pg$grado),
    tasa_sobrecarga(p, "region", p$region)
  ) |>
    select(-ambito) |>
    mutate(anio = unique(ecv$hogares$anio), indicador = "sobrecarga", umbral = umbral, .before = 1)
}

# Quintiles de renta (pregunta abierta 31). Renta disponible equivalente de cada persona: HY020
# entre las unidades de consumo de su hogar (HX240). Los ficheros del INE no traen HX090 ni el factor
# HY025 (sin él, 1), así que es la definición de Eurostat. Puntos de corte del 20, 40, 60 y 80 %
# con el factor de cada persona (RB050), sobre toda la población con renta, no solo la que tiene
# cociente de sobrecarga. Una renta igual a un corte va al quintil de abajo. Códigos de Eurostat.
QUINTILES_RENTA <- c("QU1", "QU2", "QU3", "QU4", "QU5")

# Cuantiles ponderados: el menor valor cuyo peso acumulado llega a cada proporción de `p`.
cuantil_ponderado <- function(x, peso, p) {
  o <- order(x)
  x <- x[o]
  acumulado <- cumsum(peso[o]) / sum(peso)
  vapply(p, function(q) x[which(acumulado >= q - 1e-12)[1]], numeric(1))
}

# Quintil de cada persona (id_persona, quintil, peso_persona). Una renta igual a un corte va al
# quintil de arriba (pregunta abierta 36): con esa regla, las 15 cifras de 2023 a 2025 coinciden a un
# decimal con las de Eurostat (ilc_lvho07b).
quintil_renta <- function(ecv) {
  p <- ecv$personas |>
    inner_join(select(ecv$hogares, id_hogar, renta_disponible, unidades_consumo), by = "id_hogar") |>
    mutate(renta_equivalente = renta_disponible / unidades_consumo) |>
    filter(!is.na(renta_equivalente), is.finite(renta_equivalente), !is.na(peso_persona))
  cortes <- cuantil_ponderado(p$renta_equivalente, p$peso_persona, c(0.2, 0.4, 0.6, 0.8))
  p |>
    transmute(id_persona, peso_persona,
              quintil = QUINTILES_RENTA[findInterval(renta_equivalente, cortes) + 1L])
}

# Tasa de sobrecarga de España por quintil de renta, una ola: con la muestra y la marca de
# EU-SILC, `poblacion` (% de toda la población con renta en el quintil: en torno al 20 %) y `peso`
# (suma de factores de las personas con cociente, para rehacer la tasa total en la compuerta).
calcular_sobrecarga_quintil <- function(ecv, umbral = 0.40) {
  q <- quintil_renta(ecv)
  reparto <- q |>
    group_by(grupo = quintil) |>
    summarise(poblacion = 100 * sum(peso_persona) / sum(q$peso_persona), .groups = "drop")
  p <- personas_sobrecarga(ecv, umbral) |> inner_join(select(q, id_persona, quintil), by = "id_persona")
  pesos <- p |> group_by(grupo = quintil) |> summarise(peso = sum(peso_persona), .groups = "drop")
  tasa_sobrecarga(p, "quintil", p$quintil) |>
    select(-ambito) |>
    left_join(pesos, by = "grupo") |>
    left_join(reparto, by = "grupo") |>
    mutate(fiabilidad = fiabilidad_eusilc(n_personas), anio = unique(ecv$hogares$anio), indicador = "sobrecarga",
           umbral = umbral, .before = 1) |>
    arrange(anio, grupo)
}

# Compuerta del quintil (referencias sobrecarga_quintil_total y sobrecarga_quintil_reparto):
#   la media de las tasas de los cinco quintiles, ponderada por sus personas con cociente,
#   reproduce la tasa total de la ola (ninguna persona se pierde ni se cuenta dos veces); con
#   menos de cinco quintiles, sin cifra (falla);
#   cada quintil reúne en torno al 20 % de la población con renta;
#   con `eurostat` (leer_eurostat_quintil()), la tasa de cada quintil y ola frente a la de
#   Eurostat del mismo año (sobrecarga_quintil_eurostat). Sin cifra de Eurostat para una ola, para.
comprobar_sobrecarga_quintil <- function(quintil, sobrecarga, eurostat = NULL) {
  total <- sobrecarga |> filter(corte == "total") |> select(anio, referencia = valor)
  media <- quintil |>
    group_by(anio) |>
    summarise(calculado = if (n() == 5L) sum(valor * peso) / sum(peso) else NA_real_, n = n(), .groups = "drop") |>
    left_join(total, by = "anio")
  publicado <- NULL
  if (!is.null(eurostat)) {
    ref <- eurostat |> filter(geo == "ES") |> select(anio, grupo = quintil, referencia = valor)
    publicado <- quintil |> select(anio, grupo, calculado = valor) |> left_join(ref, by = c("anio", "grupo"))
    sin_ref <- unique(publicado$anio[is.na(publicado$referencia)])
    if (length(sin_ref) > 0) {
      stop("Eurostat no publica todav\u00eda la sobrecarga de Espa\u00f1a por quintil de renta (ilc_lvho07b) de ",
           paste(sin_ref, collapse = ", "), ": no hay referencia para la compuerta", call. = FALSE)
    }
    publicado <- transmute(publicado, id = "sobrecarga_quintil_eurostat", anio, detalle = paste("ES,", grupo),
                           calculado, referencia)
  }
  bind_rows(
    media |> transmute(id = "sobrecarga_quintil_total", anio, detalle = paste("media ponderada de", n, "quintiles"),
                       calculado, referencia),
    quintil |> transmute(id = "sobrecarga_quintil_reparto", anio, detalle = grupo, calculado = poblacion, referencia = 20),
    publicado
  )
}

# Varias olas agrupadas para los cruces que una sola ola no sostiene (comunidad × tenencia,
# comunidad × edad; plan §7, F1b). Cada ola pesa lo mismo: su factor se divide por el número
# de olas. Fiabilidad según la convención de EU-SILC: con menos de 20 observaciones no se
# publica; de 20 a 49, se marca como poco fiable.
calcular_sobrecarga_agrupada <- function(olas, umbral = 0.40) {
  p <- bind_rows(lapply(olas, personas_sobrecarga, umbral = umbral)) |>
    mutate(peso_persona = peso_persona / length(olas), id_hogar = paste(anio, id_hogar))
  anios <- range(p$anio)
  pt <- con_tenencia(p)
  bind_rows(
    tasa_sobrecarga(pt, "tenencia", pt$tenencia_eurostat, ambito = pt$region),
    tasa_sobrecarga(pt, "tenencia", ifelse(pt$propietario, "OWN", "RENT"), ambito = pt$region),
    tasa_sobrecarga(filter(p, !is.na(grupo_edad)), "edad", filter(p, !is.na(grupo_edad))$grupo_edad,
                    ambito = filter(p, !is.na(grupo_edad))$region)
  ) |>
    rename(region = ambito) |>
    mutate(
      fiabilidad = fiabilidad_eusilc(n_personas),
      anio_inicio = anios[1], anio_fin = anios[2], olas = length(olas),
      indicador = "sobrecarga", umbral = umbral, .before = 1
    )
}

# Trienios de olas (decisión del 17-nov-2026, con las olas 2016–2025): los cruces agrupados se
# calculan para cada ola que tiene las dos anteriores, con ella y esas dos (trienios móviles: 2016–2018,
# 2017–2019… 2023–2025), y en la tabla larga llevan en `anio` la última. La web pinta el último
# (ultima_agrupacion()). Una ola nueva añade un trienio y no cambia los anteriores. La regla está
# anotada en la columna `notas` del 22 y el 24 (inventario/indicadores.csv). `calcular`:
# calcular_sobrecarga_agrupada() o calcular_pobreza_vivienda_agrupada(); `olas`: lista de leer_ine_ecv().
OLAS_POR_AGRUPACION <- 3L

agrupar_trienios <- function(olas, calcular, n = OLAS_POR_AGRUPACION) {
  anios <- vapply(olas, function(o) unique(o$hogares$anio), 0L)
  finales <- anios[vapply(anios, function(a) all(seq(a - n + 1L, a) %in% anios), TRUE)]
  if (!length(finales)) stop("No hay ", n, " olas seguidas de la ECV para agrupar", call. = FALSE)
  bind_rows(lapply(sort(finales), function(a) calcular(olas[anios %in% seq(a - n + 1L, a)])))
}

# El trienio más reciente de unos cruces agrupados (el que pinta la web).
ultima_agrupacion <- function(agrupada) agrupada[agrupada$anio_fin == max(agrupada$anio_fin), ]

# Empareja lo calculado con las cifras de Eurostat para la compuerta, año a año
# (referencias sobrecarga_es_total, sobrecarga_es_mercado, sobrecarga_ccaa y, si se dan,
# sobrecarga_es_edad con `europa` y sobrecarga_es_urbanizacion con `urbanizacion`, la tabla de
# leer_eurostat_ilc_lvho07d(): España por grado de urbanización; sin cifra de Eurostat de un grado
# de una ola, para).
comprobar_sobrecarga_ecv <- function(sobrecarga, eurostat, europa = NULL, urbanizacion = NULL) {
  bind_rows(lapply(sort(unique(sobrecarga$anio)), function(a) {
    comprobar_sobrecarga_anio(filter(sobrecarga, anio == a), eurostat, europa, urbanizacion)
  }))
}

comprobar_sobrecarga_anio <- function(sobrecarga, eurostat, europa = NULL, urbanizacion = NULL) {
  anio_ecv <- unique(sobrecarga$anio)
  ref <- filter(eurostat, anio == anio_ecv)
  calc <- function(c, g) sobrecarga$valor[sobrecarga$corte == c & sobrecarga$grupo == g]
  referencia <- function(conjunto, geo, tenencia = "TOTAL") {
    v <- ref$valor[ref$conjunto == conjunto & ref$geo == geo & ref$tenencia == tenencia]
    if (length(v) != 1) NA_real_ else v
  }
  nacional <- tibble::tibble(
    id         = c("sobrecarga_es_total", "sobrecarga_es_mercado"),
    detalle    = c("ES", "ES, RENT_MKT"),
    calculado  = c(calc("total", "TOTAL"), calc("tenencia", "RENT_MKT")),
    referencia = c(referencia("ilc_lvho07a", "ES"), referencia("ilc_lvho07c", "ES", "RENT_MKT"))
  )
  if (anyNA(nacional$referencia)) {
    stop("Eurostat no publica todav\u00eda la sobrecarga de Espa\u00f1a de ", anio_ecv,
         ": no hay referencia para la compuerta", call. = FALSE)
  }
  regiones <- filter(sobrecarga, corte == "region")
  regional <- tibble::tibble(
    id         = "sobrecarga_ccaa",
    detalle    = regiones$grupo,
    calculado  = regiones$valor,
    referencia = vapply(regiones$grupo, function(g) referencia("ilc_lvho07_r", g), numeric(1))
  )
  if (all(is.na(regional$referencia))) {
    message("Eurostat no publica todav\u00eda ilc_lvho07_r de ", anio_ecv,
            ": la comprobaci\u00f3n por comunidades queda pendiente")
    regional <- regional[0, ]
  }
  sin_ref <- regional$detalle[is.na(regional$referencia)]
  if (length(sin_ref) > 0) {
    message("Sin referencia de Eurostat en ", anio_ecv, ": ", paste(sin_ref, collapse = ", "))
    regional <- filter(regional, !is.na(referencia))
  }
  edades <- NULL
  if (!is.null(europa)) {
    calc_edad <- filter(sobrecarga, corte == "edad")
    ref_edad <- filter(europa, conjunto == "ilc_lvho07a", geo == "ES", anio == anio_ecv)
    edades <- inner_join(calc_edad, ref_edad, by = c("grupo" = "edad"), suffix = c("", "_ref")) |>
      transmute(id = "sobrecarga_es_edad", detalle = paste("ES,", grupo), calculado = valor, referencia = valor_ref)
  }
  grados <- NULL
  if (!is.null(urbanizacion)) {
    ref_grado <- filter(urbanizacion, geo == "ES", anio == anio_ecv, grado %in% GRADOS_URBANIZACION_ECV)
    grados <- filter(sobrecarga, corte == "urbanizacion") |>
      left_join(select(ref_grado, grupo = grado, referencia = valor), by = "grupo") |>
      transmute(id = "sobrecarga_es_urbanizacion", detalle = paste("ES,", grupo), calculado = valor, referencia)
    if (anyNA(grados$referencia)) {
      stop("Eurostat no publica todavía la sobrecarga de España por grado de urbanización (ilc_lvho07d) de ",
           anio_ecv, ": no hay referencia para la compuerta", call. = FALSE)
    }
  }
  bind_rows(nacional, regional, edades, grados) |> mutate(anio = anio_ecv, .after = id)
}

# Convención de EU-SILC: con menos de 20 observaciones no se publica; de 20 a 49, poco fiable.
fiabilidad_eusilc <- function(n) {
  dplyr::case_when(n < 20 ~ "no publicable", n < 50 ~ "baja", TRUE ~ "normal")
}

# Indicador 22 en la tabla larga (comunidades con el código del INE, desde la región NUTS 2):
# - España («00»), cada año, en total y por tenencia, edad y grado de urbanización;
# - comunidades, cada año, en total;
# - comunidad × tenencia y comunidad × edad con varias olas agrupadas (`agrupada`, un trienio por
#   ola desde 2018 con agrupar_trienios()): `anio` es la última ola (2023–2025 → 2025), y la ficha lo dice.
# Lo que EU-SILC no deja publicar queda como «secreto». El número de observaciones y la marca
# de fiabilidad van en los ficheros de la sobrecarga (exportar_sobrecarga; pregunta abierta 9).
armonizar_sobrecarga_ecv <- function(sobrecarga, agrupada, ccaa, version) {
  nuts <- select(ccaa, codigo, nuts2)
  espana <- sobrecarga |>
    filter(corte != "region") |>
    transmute(geo_id = "00", nivel = "nacional", anio, corte,
              grupo = if_else(corte == "total", "total", grupo), valor, n_personas)
  comunidades <- sobrecarga |>
    filter(corte == "region") |>
    left_join(nuts, by = c("grupo" = "nuts2")) |>
    transmute(geo_id = codigo, nivel = "ccaa", anio, corte = "total", grupo = "total", valor, n_personas)
  cruces <- agrupada |>
    left_join(nuts, by = c("region" = "nuts2")) |>
    transmute(geo_id = codigo, nivel = "ccaa", anio = anio_fin, corte, grupo, valor, n_personas)
  bind_rows(espana, comunidades, cruces) |>
    mutate(estado = if_else(fiabilidad_eusilc(n_personas) == "no publicable", "secreto", "dato"),
           valor = if_else(estado == "secreto", NA_real_, valor),
           indicador = "sobrecarga", fuente = "ine_ecv", geo_ref = NA_character_, version = version) |>
    select(-n_personas)
}
