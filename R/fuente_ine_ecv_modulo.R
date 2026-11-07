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
# Con las tablas por edad y por tenencia, también su total nacional frente al de comunidades.
comprobar_ine_ecv_modulo <- function(ccaa_tabla, edad_tabla = NULL, tenencia_tabla = NULL) {
  miles <- ccaa_tabla |> filter(medida == paste(MEDIDA_BUSQUEDA, "(miles)"))
  total <- miles$valor[miles[[1]] == "Total"]
  suma <- sum(miles$valor[miles[[1]] != "Total"])
  total_de <- function(d) {
    d <- filter(d, medida == paste(MEDIDA_BUSQUEDA, "(miles)"))
    dims <- as.matrix(d[seq_len(ncol(d) - 2)])
    d$valor[apply(dims == "Total" | dims == "Ambos sexos", 1, all)]
  }
  otras <- list(`total de la tabla por edad (miles)` = edad_tabla,
                `total de la tabla por tenencia (miles)` = tenencia_tabla)
  otras <- otras[!vapply(otras, is.null, logical(1))]
  tibble::tibble(id = "modulo_acceso_lectura", anio = 2025L,
                 detalle = c("suma de comunidades (miles)", names(otras)),
                 calculado = unname(100 * (c(suma, vapply(otras, total_de, numeric(1))) - total) / total),
                 referencia = 0)
}

# Indicador 23 (busqueda_sin_exito) por comunidad y nacional, en formato largo.
armonizar_ine_ecv_modulo <- function(ccaa_tabla, ccaa, version) {
  ccaa_tabla |>
    filter(medida == paste(MEDIDA_BUSQUEDA, "(%)")) |>
    rename(nombre = 1) |>
    left_join(ccaa |> select(codigo, nombre = nombre_ine), by = "nombre") |>
    mutate(nivel = if_else(nombre == "Total", "nacional", "ccaa"),
           geo_id = if_else(nombre == "Total", "00", codigo)) |>
    transmute(geo_id, nivel, anio = 2025L, indicador = "busqueda_sin_exito", corte = "total", grupo = "total",
              valor, estado = "dato", fuente = "ine_ecv_modulo", geo_ref = NA_character_, version = version)
}

# Categorías del INE en el módulo → grupos de la tabla larga (inventario/vocabulario.csv).
GRUPOS_MODULO <- list(
  edad = c("De 16 a 29 años" = "Y16-29", "De 30 a 44 años" = "Y30-44", "De 45 a 64 años" = "Y45-64",
           "65 y más años" = "Y_GE65"),
  sexo = c("Hombres" = "M", "Mujeres" = "F"),
  tenencia = c("Propiedad" = "OWN", "Propiedad sin hipoteca" = "OWN_NL", "Propiedad con hipoteca" = "OWN_L",
               "Alquiler a precio de mercado" = "RENT_MKT", "Alquiler inferior al precio de mercado" = "RENT_RED",
               "Cesión gratuita" = "FREE")
)

# Indicador 23 de España por edad, sexo y tenencia (tablas 79629 y 79635). Los cruces de sexo
# y edad no entran: la tabla larga tiene un solo corte por fila.
armonizar_ine_ecv_modulo_cortes <- function(edad_tabla, tenencia_tabla, version) {
  pct <- paste(MEDIDA_BUSQUEDA, "(%)")
  e <- filter(edad_tabla, medida == pct) |> rename(sexo = 1, edad = 2)
  t <- filter(tenencia_tabla, medida == pct) |> rename(tenencia = 1)
  filas <- bind_rows(
    e |> filter(sexo == "Ambos sexos", edad != "Total") |> transmute(corte = "edad", categoria = edad, valor),
    e |> filter(sexo != "Ambos sexos", edad == "Total") |> transmute(corte = "sexo", categoria = sexo, valor),
    t |> filter(tenencia != "Total") |> transmute(corte = "tenencia", categoria = tenencia, valor)
  )
  filas$grupo <- unname(mapply(function(c, k) unname(GRUPOS_MODULO[[c]][k]), filas$corte, filas$categoria))
  if (anyNA(filas$grupo)) {
    stop("Categorías del módulo sin grupo: ", paste(unique(filas$categoria[is.na(filas$grupo)]), collapse = ", "),
         call. = FALSE)
  }
  filas |>
    transmute(geo_id = "00", nivel = "nacional", anio = 2025L, indicador = "busqueda_sin_exito", corte, grupo,
              valor, estado = "dato", fuente = "ine_ecv_modulo", geo_ref = NA_character_, version = version)
}
