# Fuente ine_adrh: Atlas de Distribución de Renta de los Hogares (INE).
# Tablas por provincia en INEbase; se descargan en CSV (separador «;», coma decimal).
# 31105: Madrid, indicadores demográficos (población por sección censal, entre otros).

url_ine_tabla <- function(id) {
  sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv", id)
}

descargar_ine_adrh <- function(id, dir = file.path("datos", "brutos", "ine_adrh"), forzar = FALSE) {
  descargar_con_cache(url_ine_tabla(id), file.path(dir, sprintf("%s.csv", id)), forzar)
}

# El año t del ADRH (renta del año t) se publica en el seccionado de 1 de enero de t + 1:
# en Madrid, el ADRH 2020 coincide código a código con el seccionado de 2021 y el ADRH
# 2024, con el de 2025 (comprobado el 6-nov-2026).
seccionado_adrh <- function(anio_adrh) anio_adrh + 1L

# Lee un indicador de la tabla de indicadores demográficos de una provincia.
# Devuelve una fila por territorio y año: nivel (municipio, distrito o seccion), código y valor.
# «.» es dato no disponible.
leer_ine_adrh_demografia <- function(ruta, indicador = "Población") {
  datos <- readr::read_delim(
    ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"), progress = FALSE
  )
  names(datos) <- c("municipio", "distrito", "seccion", "indicador", "anio", "valor")
  datos |>
    filter(indicador == !!indicador) |>
    mutate(
      nivel  = case_when(!is.na(seccion) ~ "seccion", !is.na(distrito) ~ "distrito", TRUE ~ "municipio"),
      codigo = case_when(nivel == "seccion" ~ substr(seccion, 1, 10),
                         nivel == "distrito" ~ substr(distrito, 1, 7),
                         TRUE ~ substr(municipio, 1, 5)),
      anio   = as.integer(anio),
      valor  = suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE)))
    ) |>
    select(anio, nivel, codigo, valor) |>
    filter(!is.na(valor))
}
