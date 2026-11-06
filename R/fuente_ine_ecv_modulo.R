# Fuente ine_ecv_modulo: tablas publicadas del módulo de la ECV 2025 sobre dificultades de
# acceso a la vivienda (INEbase, padre 13548). Indicador 23: personas de 16 o más años que han
# buscado vivienda activamente en los últimos 12 meses sin llegar a cambiarse.
# Las variables del módulo no vienen en los microdatos: se usan las tablas.
#   79637: por comunidad autónoma · 79629: por edad y sexo · 79635: por régimen de tenencia

url_ine_tpx <- function(id) sprintf("https://www.ine.es/jaxi/files/tpx/es/csv_bdsc/%s.csv", id)

descargar_ine_ecv_modulo <- function(id, dir = file.path("datos", "brutos", "ine_ecv_modulo"), forzar = FALSE) {
  descargar_con_cache(url_ine_tpx(id), file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Tabla larga de lo publicado: las primeras columnas son las dimensiones de la tabla, la
# penúltima la medida y la última el valor (formato español).
leer_ine_ecv_modulo <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  n <- ncol(d)
  names(d)[n - 1] <- "medida"
  names(d)[n] <- "valor"
  d |> mutate(valor = suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE))))
}

MEDIDA_BUSQUEDA <- "Ha buscado vivienda activamente pero no se ha cambiado"

# Comprobación de lectura (modulo_acceso_lectura): la suma de las comunidades, en miles,
# frente al total nacional publicado. Desviación en %.
comprobar_ine_ecv_modulo <- function(ccaa_tabla) {
  miles <- ccaa_tabla |> filter(medida == paste(MEDIDA_BUSQUEDA, "(miles)"))
  total <- miles$valor[miles[[1]] == "Total"]
  suma <- sum(miles$valor[miles[[1]] != "Total"])
  tibble::tibble(id = "modulo_acceso_lectura", anio = 2025L, detalle = "suma de comunidades (miles)",
                 calculado = 100 * (suma - total) / total, referencia = 0)
}

# Indicador 23 (busqueda_sin_exito) por comunidad y nacional, en formato largo.
armonizar_ine_ecv_modulo <- function(ccaa_tabla, ccaa, version) {
  ccaa_tabla |>
    filter(medida == paste(MEDIDA_BUSQUEDA, "(%)")) |>
    rename(nombre = 1) |>
    left_join(ccaa |> select(codigo, nombre = nombre_ine), by = "nombre") |>
    mutate(nivel = if_else(nombre == "Total", "nacional", "ccaa"),
           geo_id = if_else(nombre == "Total", "00", codigo)) |>
    transmute(geo_id, nivel, anio = 2025L, indicador = "busqueda_sin_exito", valor,
              estado = "dato", fuente = "ine_ecv_modulo", geo_ref = NA_character_, version = version)
}
