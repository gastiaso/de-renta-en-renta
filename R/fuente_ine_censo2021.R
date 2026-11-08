# Fuente ine_censo2021: Censo de Población y Viviendas 2021 (INE), indicadores por sección censal.
# Un CSV de toda España (separador «,», punto decimal) en el seccionado del Censo 2021, el de
# referencia del atlas: no necesita tabla de paso. Diccionario en un xlsx aparte. Las variables
# de vivienda son recuentos: t18_1 viviendas, t19_1 principales, t19_2 no principales y, de las
# principales, t20_1 en propiedad, t20_2 en alquiler y t20_3 en otro régimen; t21_1, hogares.
# Indicador 18 (hogares en alquiler, %) = t20_2 / t19_1 (un hogar por vivienda principal).
# Compuerta: la tabla 59523 del Censo 2021 (viviendas familiares principales convencionales por
# régimen de tenencia, España, comunidades y provincias). Las cifras de España, de las comunidades
# y de las provincias de la tabla larga son las publicadas en esa tabla (territorios_ine_censo2021).
# La tabla 59521 (viviendas por comunidad y provincia) es el denominador de las viviendas turísticas
# de los territorios desde noviembre de 2024 (compuerta vut_territorios, R/fuente_ine_vut.R).

URL_CENSO2021_INDICADORES <- "https://www.ine.es/censos2021/C2021_Indicadores.csv"
URL_CENSO2021_DICCIONARIO <- "https://www.ine.es/censos2021/indicadores_seccen_c2021.xlsx"
TABLA_CENSO2021_TENENCIA <- "59523"
TABLA_CENSO2021_VIVIENDAS <- "59521"

# Tablas de los resultados del Censo (jaxi, ficheros px), en CSV separado por «;».
url_ine_tabla_px <- function(id) {
  sprintf("https://www.ine.es/jaxi/files/tpx/es/csv_bdsc/%s.csv?nocab=1", id)
}

# Devuelve las dos rutas: el CSV de indicadores y su diccionario.
descargar_ine_censo2021 <- function(dir = file.path("datos", "brutos", "ine_censo2021"), forzar = FALSE) {
  c(descargar_con_cache(URL_CENSO2021_INDICADORES, file.path(dir, "C2021_Indicadores.csv"), forzar),
    descargar_con_cache(URL_CENSO2021_DICCIONARIO, file.path(dir, "indicadores_seccen_c2021.xlsx"), forzar))
}

descargar_ine_censo2021_tabla <- function(id = TABLA_CENSO2021_TENENCIA,
                                          dir = file.path("datos", "brutos", "ine_censo2021"), forzar = FALSE) {
  descargar_con_cache(url_ine_tabla_px(id), file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Variables del CSV que usa el atlas y su nombre aquí.
VARIABLES_CENSO2021 <- c(t18_1 = "viviendas", t19_1 = "principales", t20_1 = "propiedad",
                         t20_2 = "alquiler", t20_3 = "otro_regimen", t21_1 = "hogares")

# Una fila por sección: código de 10 dígitos y los recuentos de VARIABLES_CENSO2021. Una celda
# que no es un número (vacía o con una marca) queda en NA: secreto o sin dato en la fuente.
# `ruta`: el CSV de indicadores (o el vector de descargar_ine_censo2021(), del que se toma el CSV).
leer_ine_censo2021 <- function(ruta, ambito = "") {
  ruta <- ruta[grepl("[.]csv$", ruta)][1]
  d <- readr::read_csv(ruta, col_types = readr::cols(.default = readr::col_character()),
                       locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  falta <- setdiff(c("cpro", "cmun", "dist", "secc", names(VARIABLES_CENSO2021)), names(d))
  if (length(falta) > 0) {
    stop("El CSV del Censo 2021 no trae las columnas: ", paste(falta, collapse = ", "), call. = FALSE)
  }
  d <- d |>
    mutate(seccion = codigo_seccion(cpro, cmun, dist, secc)) |>
    filter(startsWith(seccion, ambito)) |>
    select(seccion, all_of(names(VARIABLES_CENSO2021)))
  names(d) <- c("seccion", unname(VARIABLES_CENSO2021))
  d |> mutate(across(-seccion, ~ suppressWarnings(as.numeric(.x))))
}

# Indicador 18 en formato largo, una fila por sección del CSV:
#   dato: % de hogares (viviendas principales) en alquiler;
#   secreto: falta el recuento de principales o el de alquiler;
#   ausente: la sección no tiene viviendas principales (el cociente no existe).
# Sin redondeo: el valor se redondea al mostrarlo.
armonizar_ine_censo2021 <- function(censo, version) {
  censo |>
    transmute(
      geo_id = seccion, nivel = "sc", anio = 2021L, indicador = "hogares_alquiler",
      estado = case_when(is.na(principales) | is.na(alquiler) ~ "secreto",
                         principales == 0 ~ "ausente",
                         TRUE ~ "dato"),
      valor = if_else(estado == "dato", 100 * alquiler / principales, NA_real_)
    ) |>
    sin_desglose() |>
    mutate(fuente = "ine_censo2021", geo_ref = "2021", version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Indicador 18 de España, de las comunidades y de las provincias: la cifra publicada en la tabla
# 59523 (hogares en alquiler / viviendas principales), en formato largo, con los códigos del INE
# (los de geo/: comunidades 01-19, provincias 01-52, España «00»). Ceuta y Melilla vienen en los dos
# niveles con la misma cifra: comunidad 18 y provincia 51, comunidad 19 y provincia 52. El CSV de
# indicadores solo trae secciones, y sumarlas no da estas cifras: faltan las 1.363 en secreto. Sin
# seccionado de referencia (geo_ref NA, como las cifras de la ECV).
territorios_ine_censo2021 <- function(tenencia, version, niveles = c("nacional", "ccaa", "provincia")) {
  tenencia |>
    filter(nivel %in% niveles) |>
    transmute(geo_id = codigo, nivel, anio = 2021L, indicador = "hogares_alquiler",
              estado = if_else(is.na(principales) | is.na(alquiler) | principales == 0, "ausente", "dato"),
              valor = if_else(estado == "dato", 100 * alquiler / principales, NA_real_)) |>
    sin_desglose() |>
    mutate(fuente = "ine_censo2021", geo_ref = NA_character_, version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Solo la fila de España.
nacional_ine_censo2021 <- function(tenencia, version) {
  territorios_ine_censo2021(tenencia, version, niveles = "nacional")
}

# Etiquetas territoriales de las tablas del INE en orden de publicación («Total Nacional»,
# «01 Andalucía», «04 Almería»…): comunidades y provincias comparten códigos de dos dígitos.
# Cada comunidad lleva el siguiente número de la serie 01–19 y sus provincias van detrás; una
# etiqueta es comunidad si su código es el siguiente que se espera. `ccaa`: la comunidad de cada
# provincia (la última que ha salido) y el propio código en las comunidades.
nivel_territorios_ine <- function(etiquetas) {
  etiquetas <- unique(etiquetas)
  nivel <- character(length(etiquetas))
  ccaa <- rep(NA_character_, length(etiquetas))
  siguiente <- 1L
  actual <- NA_character_
  for (i in seq_along(etiquetas)) {
    codigo <- suppressWarnings(as.integer(substr(etiquetas[i], 1, 2)))
    if (is.na(codigo)) {
      nivel[i] <- "nacional"
      next
    }
    if (codigo == siguiente) {
      nivel[i] <- "ccaa"
      actual <- substr(etiquetas[i], 1, 2)
      siguiente <- siguiente + 1L
    } else {
      nivel[i] <- "provincia"
    }
    ccaa[i] <- actual
  }
  tibble::tibble(territorio = etiquetas, nivel = nivel,
                 codigo = if_else(nivel == "nacional", "00", substr(etiquetas, 1, 2)), ccaa = ccaa)
}

# Recuentos por provincia (`codigo`, más las columnas de `por`) sumados también por comunidad y
# para España: una fila por territorio con `nivel` y la suma de las demás columnas. Solo las
# comunidades con todas sus provincias en `d`, y España solo si están todas (con PROVINCIA, el
# pipeline lee una). `mapa`: cada provincia (`codigo`) con su comunidad (`ccaa`), de la tabla del
# INE con que se compara.
sumar_territorios_ine <- function(d, mapa, por = character()) {
  sumar <- function(x, nivel) {
    x |>
      group_by(across(all_of(c("codigo", por)))) |>
      summarise(across(everything(), sum), .groups = "drop") |>
      mutate(nivel = nivel, .before = 1)
  }
  completa <- tapply(mapa$codigo %in% d$codigo, mapa$ccaa, all)
  ccaa <- d |>
    inner_join(select(mapa, codigo, ccaa), by = "codigo") |>
    filter(ccaa %in% names(completa)[completa]) |>
    mutate(codigo = ccaa) |>
    select(-ccaa) |>
    sumar("ccaa")
  espana <- if (length(completa) > 0 && all(completa)) sumar(mutate(d, codigo = "00"), "nacional")
  bind_rows(mutate(d, nivel = "provincia", .before = 1), ccaa, espana)
}

# Tabla 59523: viviendas principales por régimen de tenencia, con el total de tamaños de
# municipio. Una fila por territorio (nacional, ccaa, provincia) con su comunidad y los recuentos.
leer_ine_censo2021_tenencia <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- c("territorio", "tenencia", "tamano", "valor")
  d <- d |>
    filter(startsWith(tamano, "Total")) |>
    mutate(valor = suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE))),
           tenencia = case_when(startsWith(tenencia, "Total") ~ "principales",
                                tenencia == "En alquiler" ~ "alquiler",
                                tenencia == "En propiedad" ~ "propiedad",
                                TRUE ~ "otro_regimen"))
  niveles <- nivel_territorios_ine(d$territorio)
  d |>
    tidyr::pivot_wider(names_from = tenencia, values_from = valor) |>
    inner_join(niveles, by = "territorio") |>
    select(nivel, codigo, ccaa, territorio, principales, propiedad, alquiler, otro_regimen)
}

# Tabla 59521: viviendas familiares convencionales, con el total de tipos (principales y no
# principales) y de años de construcción. Una fila por territorio (nacional, ccaa, provincia) con su
# comunidad y las viviendas. Cuenta las de las secciones en secreto, que el CSV de indicadores no
# trae, y solo las convencionales: en 11 provincias las secciones suman algo más que la tabla (hasta
# 791 viviendas, en Huelva). España: 26.623.708 viviendas.
leer_ine_censo2021_viviendas <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- c("tipo", "territorio", "construccion", "valor")
  d <- d |>
    filter(startsWith(tipo, "Total"), startsWith(construccion, "Total")) |>
    mutate(viviendas = suppressWarnings(as.numeric(gsub(".", "", valor, fixed = TRUE))))
  d |>
    inner_join(nivel_territorios_ine(d$territorio), by = "territorio") |>
    select(nivel, codigo, ccaa, territorio, viviendas)
}

# Compuerta (inventario/referencias_validacion.csv). Las secciones en secreto no traen recuentos,
# así que sus hogares faltan en la suma de las secciones (hasta un 6,6 % en Soria). Y la tabla
# 59523 cuenta solo viviendas convencionales: en Huelva, Almería y Melilla las secciones suman
# más hogares que la tabla.
#   censo2021_alquiler: % de hogares en alquiler de España, de cada comunidad y de cada provincia
#     (las cifras de la tabla larga) frente al cociente de las sumas de sus secciones. Los hogares
#     que faltan (publicados menos sumados, si es positivo) pueden estar entre el 0 y el 100 % en
#     alquiler: eso da un intervalo para el % del territorio. `calculado` es el punto del
#     intervalo más cercano al % de la tabla 59523; si la cifra publicada cae dentro, coinciden
#     (puntos).
#   censo2021_principales: hogares sumados frente a los publicados en España y en las comunidades
#     y provincias sin secciones en secreto (desviación en %).
#   censo2021_seccionado (con `secciones_2021`): secciones del CSV que no están en el seccionado
#     de 2021 y secciones del seccionado sin fila en el CSV (recuentos).
#   censo2021_nacional: % de España publicado (el que va a la tabla larga) frente a la media
#     ponderada de las provincias y de las comunidades de la misma tabla (hogares en alquiler
#     sumados / hogares sumados; puntos). No depende del ámbito: la tabla es de toda España.
comprobar_ine_censo2021 <- function(censo, tenencia, secciones_2021 = NULL) {
  seccionado <- if (is.null(secciones_2021)) NULL else tibble::tibble(
    id = "censo2021_seccionado", anio = 2021L,
    detalle = c("secciones del CSV fuera del seccionado de 2021", "secciones del seccionado de 2021 sin fila en el CSV"),
    calculado = c(sum(!censo$seccion %in% secciones_2021), sum(!unique(secciones_2021) %in% censo$seccion)),
    referencia = 0
  )
  sumas <- censo |>
    mutate(codigo = substr(seccion, 1, 2), completa = !is.na(principales) & !is.na(alquiler)) |>
    group_by(codigo) |>
    summarise(secretas = sum(!completa), principales = sum(principales[completa]),
              alquiler = sum(alquiler[completa]), .groups = "drop") |>
    sumar_territorios_ine(filter(tenencia, nivel == "provincia"))
  publicado <- tenencia |>
    select(nivel, codigo, territorio, principales_ref = principales, alquiler_ref = alquiler)
  t <- inner_join(sumas, publicado, by = c("nivel", "codigo")) |>
    mutate(faltan = pmax(principales_ref - principales, 0),
           minimo = 100 * alquiler / (principales + faltan),
           maximo = 100 * (alquiler + faltan) / (principales + faltan),
           publicado = 100 * alquiler_ref / principales_ref)
  espana <- filter(tenencia, nivel == "nacional")
  nacional <- tenencia |>
    filter(nivel %in% c("provincia", "ccaa")) |>
    group_by(nivel) |>
    summarise(calculado = 100 * sum(alquiler) / sum(principales), .groups = "drop") |>
    transmute(id = "censo2021_nacional", anio = 2021L,
              detalle = if_else(nivel == "ccaa", "media ponderada de las comunidades",
                                "media ponderada de las provincias"),
              calculado,
              referencia = if (nrow(espana) == 1) 100 * espana$alquiler / espana$principales else NA_real_)
  bind_rows(
    t |> transmute(id = "censo2021_alquiler", anio = 2021L, detalle = territorio,
                   calculado = pmin(pmax(publicado, minimo), maximo), referencia = publicado),
    t |> filter(secretas == 0 | nivel == "nacional") |>
      transmute(id = "censo2021_principales", anio = 2021L, detalle = territorio,
                calculado = 100 * (principales - principales_ref) / principales_ref, referencia = 0),
    seccionado,
    nacional
  )
}
