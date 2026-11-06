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
extraer_ine_ecv <- function(zip, anio, ficheros = c("d", "r", "h"),
                            dir = file.path("datos", "intermedios", "ine_ecv")) {
  destino <- file.path(dir, anio)
  dir.create(destino, recursive = TRUE, showWarnings = FALSE)
  temporal <- tempfile("ine_ecv_")
  on.exit(unlink(temporal, recursive = TRUE), add = TRUE)
  contenido <- utils::unzip(zip, list = TRUE)$Name

  rutas <- vapply(ficheros, function(f) {
    patron_csv <- sprintf("(^|/)CSV/esudb%02d%s\\.csv$", anio %% 100, f)
    directo <- grep(patron_csv, contenido, value = TRUE, ignore.case = TRUE)
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
      csv <- grep(patron_csv, utils::unzip(zip_interno, list = TRUE)$Name,
                  value = TRUE, ignore.case = TRUE)
      if (length(csv) != 1) stop("No encuentro el CSV dentro de ", interno, call. = FALSE)
      utils::unzip(zip_interno, files = csv, exdir = temporal, junkpaths = TRUE)
    }
    origen <- list.files(temporal, pattern = sprintf("^esudb%02d%s\\.csv$", anio %% 100, f),
                         full.names = TRUE, ignore.case = TRUE)
    final <- file.path(destino, basename(origen))
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
#   HY020 renta disponible del año anterior, HY070G ayudas a la vivienda.
# Persona (Tr): RB030 identificador (hogar + dos dígitos de orden), RB050 factor de la persona.
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
  d <- leer(ruta("d"), c("DB010", "DB030", "DB040", "DB090"))
  h <- leer(ruta("h"), c("HB030", "HH021", "HH070", "HY020", "HY070G"))
  r <- leer(ruta("r"), c("RB030", "RB050"))

  hogares <- d |>
    inner_join(h, by = c("DB030" = "HB030")) |>
    transmute(
      anio               = as.integer(DB010),
      id_hogar           = DB030,
      region             = DB040,
      peso_hogar         = as.numeric(DB090),
      tenencia           = as.integer(HH021),
      gasto_vivienda_mes = as.numeric(HH070),
      renta_disponible   = as.numeric(HY020),
      ayuda_vivienda     = as.numeric(HY070G)
    )
  if (nrow(hogares) != nrow(d)) stop("Td y Th no casan hogar a hogar", call. = FALSE)

  personas <- r |>
    transmute(
      id_persona   = RB030,
      id_hogar     = substr(RB030, 1, nchar(RB030) - 2),
      peso_persona = as.numeric(RB050)
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

# Tasa de sobrecarga (%): personas que viven en hogares cuyo cociente supera el umbral,
# ponderadas por RB050. Cortes: total, tenencia (y propietarios e inquilinos agregados)
# y región NUTS 2.
calcular_sobrecarga_ecv <- function(ecv, umbral = 0.40) {
  hogares <- ecv$hogares |>
    mutate(
      cociente  = cociente_sobrecarga(gasto_vivienda_mes, renta_disponible, ayuda_vivienda),
      sobrecarga = cociente > umbral,
      tenencia_eurostat = unname(TENENCIA_EUROSTAT[as.character(tenencia)])
    )
  personas <- ecv$personas |>
    inner_join(hogares, by = "id_hogar") |>
    filter(!is.na(cociente), !is.na(peso_persona))

  tasa <- function(datos, corte, grupo) {
    datos |>
      mutate(corte = corte, grupo = grupo) |>
      group_by(anio, corte, grupo) |>
      summarise(
        valor      = 100 * sum(peso_persona[sobrecarga]) / sum(peso_persona),
        n_personas = n(),
        n_hogares  = n_distinct(id_hogar),
        .groups = "drop"
      )
  }
  propietario <- personas$tenencia_eurostat %in% c("OWN_NL", "OWN_L")
  bind_rows(
    tasa(personas, "total", "TOTAL"),
    tasa(personas, "tenencia", personas$tenencia_eurostat),
    tasa(personas, "tenencia", ifelse(propietario, "OWN", "RENT")),
    tasa(personas, "region", personas$region)
  ) |>
    mutate(indicador = "sobrecarga", umbral = umbral, .before = 1)
}

# Empareja lo calculado con las cifras de Eurostat para la compuerta
# (referencias sobrecarga_es_total, sobrecarga_es_mercado y sobrecarga_ccaa).
comprobar_sobrecarga_ecv <- function(sobrecarga, eurostat) {
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
    stop("Eurostat no publica todavía la sobrecarga de España de ", anio_ecv,
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
    message("Eurostat no publica todavía ilc_lvho07_r de ", anio_ecv,
            ": la comprobación por comunidades queda pendiente")
    regional <- regional[0, ]
  }
  sin_ref <- regional$detalle[is.na(regional$referencia)]
  if (length(sin_ref) > 0) {
    message("Sin referencia de Eurostat en ", anio_ecv, ": ", paste(sin_ref, collapse = ", "))
    regional <- filter(regional, !is.na(referencia))
  }
  bind_rows(nacional, regional) |> mutate(anio = anio_ecv, .after = id)
}
