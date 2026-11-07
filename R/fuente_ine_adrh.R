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

# Lee los indicadores pedidos de una tabla del ADRH (cualquier tabla provincial: renta,
# demografía…). Devuelve una fila por territorio, año e indicador: nivel (municipio, distrito
# o seccion), código y valor. Formato español: «.» de miles, «,» decimal; «.» solo es dato
# no disponible (secreto estadístico).
leer_ine_adrh <- function(ruta, indicadores) {
  datos <- readr::read_delim(
    ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"), progress = FALSE
  )
  names(datos) <- c("municipio", "distrito", "seccion", "indicador", "anio", "valor")
  datos |>
    filter(indicador %in% indicadores) |>
    mutate(
      nivel  = case_when(!is.na(seccion) ~ "seccion", !is.na(distrito) ~ "distrito", TRUE ~ "municipio"),
      codigo = case_when(nivel == "seccion" ~ substr(seccion, 1, 10),
                         nivel == "distrito" ~ substr(distrito, 1, 7),
                         TRUE ~ substr(municipio, 1, 5)),
      anio   = as.integer(anio),
      valor  = suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE)))
    ) |>
    select(anio, nivel, codigo, indicador, valor) |>
    filter(!is.na(valor))
}

# Un indicador de la tabla de indicadores demográficos (población por defecto).
leer_ine_adrh_demografia <- function(ruta, indicador = "Población") {
  leer_ine_adrh(ruta, indicador) |> select(-indicador)
}

# Indicadores de renta del catálogo (inventario/indicadores.csv) y su nombre en el ADRH
INDICADORES_ADRH_RENTA <- c(
  "Renta neta media por persona"              = "renta_persona",
  "Renta neta media por hogar"                = "renta_hogar",
  "Mediana de la renta por unidad de consumo" = "renta_uc_mediana"
)

leer_ine_adrh_renta <- function(ruta) {
  leer_ine_adrh(ruta, names(INDICADORES_ADRH_RENTA)) |>
    mutate(indicador = unname(INDICADORES_ADRH_RENTA[indicador]))
}

# Pesos para agregar las medias de renta: población (renta por persona) y hogares
# (renta por hogar), estos como población / tamaño medio del hogar (redondeado a un decimal
# en la fuente, así que los hogares son aproximados).
pesos_adrh <- function(ruta_demografia) {
  leer_ine_adrh(ruta_demografia, c("Población", "Tamaño medio del hogar")) |>
    filter(nivel == "seccion") |>
    tidyr::pivot_wider(names_from = indicador, values_from = valor) |>
    transmute(anio, seccion = codigo, poblacion = `Población`,
              hogares = `Población` / `Tamaño medio del hogar`)
}

# Medias de las secciones agregadas a municipio (renta por persona con la población; por
# hogar, con los hogares) frente a la cifra municipal publicada: desviación en %.
desviacion_adrh_municipio <- function(renta, pesos) {
  secciones <- renta |> filter(nivel == "seccion", indicador %in% c("renta_persona", "renta_hogar")) |>
    inner_join(pesos, by = c("anio", "codigo" = "seccion")) |>
    mutate(peso = if_else(indicador == "renta_hogar", hogares, poblacion),
           municipio = substr(codigo, 1, 5))
  agregado <- secciones |>
    group_by(anio, municipio, indicador) |>
    summarise(agregado = sum(valor * peso) / sum(peso), .groups = "drop")
  publicado <- renta |> filter(nivel == "municipio") |> select(anio, municipio = codigo, indicador, publicado = valor)
  inner_join(agregado, publicado, by = c("anio", "municipio", "indicador")) |>
    mutate(desviacion_pct = 100 * (agregado - publicado) / publicado)
}

# Compuerta en dos niveles (inventario/referencias_validacion.csv):
#   adrh_municipio (bloqueo): mediana, por año e indicador, de la desviación absoluta. Prueba
#     que las secciones se leen y se ponderan bien.
#   adrh_municipio_detalle (alerta): cada municipio. En Madrid, unos pocos municipios de renta
#     muy alta (Alcobendas, Pozuelo de Alarcón, Boadilla del Monte) quedan todos los años entre
#     un 5 y un 21 % por debajo de la cifra municipal con todas sus secciones con dato: es una
#     diferencia de la propia fuente entre escalas, no de la lectura.
comprobar_adrh_municipio <- function(renta, pesos) {
  d <- desviacion_adrh_municipio(renta, pesos)
  resumen <- d |> group_by(anio, indicador) |>
    summarise(calculado = stats::median(abs(desviacion_pct)), .groups = "drop") |>
    transmute(id = "adrh_municipio", anio, detalle = indicador, calculado, referencia = 0)
  detalle <- d |>
    transmute(id = "adrh_municipio_detalle", anio, detalle = paste(municipio, indicador),
              calculado = desviacion_pct, referencia = 0)
  bind_rows(resumen, detalle)
}

# Población por sección del ADRH sumada por municipio frente al total municipal que publica
# la misma tabla (alerta adrh_suma_secciones; desviación en %). En Madrid cuadran todos los
# años salvo 2016, 2017 y 2019, en unos pocos municipios (hasta −1,2 %, Tres Cantos en 2016).
comprobar_suma_secciones <- function(poblacion) {
  secciones <- poblacion |>
    filter(nivel == "seccion") |>
    group_by(anio, municipio = substr(codigo, 1, 5)) |>
    summarise(secciones = sum(valor), .groups = "drop")
  poblacion |>
    filter(nivel == "municipio") |>
    select(anio, municipio = codigo, publicado = valor) |>
    inner_join(secciones, by = c("anio", "municipio")) |>
    transmute(id = "adrh_suma_secciones", anio = as.integer(anio), detalle = municipio,
              calculado = 100 * (secciones - publicado) / publicado, referencia = 0)
}

# Lleva la renta del ADRH al seccionado de 2021 y la pone en formato largo, con su estado.
#   renta_persona: media ponderada por la población; renta_hogar, por los hogares;
#   renta_uc_mediana: mediana (único origen u origen dominante).
# `tablas`: lista con nombre = año del ADRH y valor = tabla de paso hacia 2021. Las secciones
# de 2021 que no reciben ningún origen con dato quedan «secreto»; si falta alguno de sus
# orígenes, el valor pasa a «estimado».
armonizar_ine_adrh <- function(renta, pesos, tablas, version) {
  peso_de <- c(renta_persona = "poblacion", renta_hogar = "hogares", renta_uc_mediana = NA)
  por_anio <- lapply(names(tablas), function(a_txt) {
    a <- as.integer(a_txt)
    t <- tablas[[a_txt]]
    destinos <- tibble::tibble(seccion = sort(unique(t$destino)))
    bind_rows(lapply(names(peso_de), function(ind) {
      valores <- renta |> filter(anio == a, nivel == "seccion", indicador == ind) |>
        select(seccion = codigo, valor)
      r <- if (is.na(peso_de[[ind]])) {
        geo_reproyectar_mediana(valores, t) |> select(seccion, valor, estado)
      } else {
        valores |>
          inner_join(pesos |> filter(anio == a) |> select(seccion, peso = all_of(peso_de[[ind]])), by = "seccion") |>
          geo_reproyectar_media(t)
      }
      destinos |>
        left_join(r, by = "seccion") |>
        left_join(geo_cobertura_origenes(valores, t), by = "seccion") |>
        mutate(
          estado = case_when(!is.na(estado) & estado == "ausente" ~ "ausente",
                             is.na(valor) ~ "secreto",
                             completos < origenes ~ "estimado",
                             TRUE ~ estado),
          anio = a, indicador = ind
        ) |>
        select(seccion, anio, indicador, valor, estado)
    }))
  })
  secciones <- bind_rows(por_anio) |>
    transmute(geo_id = seccion, nivel = "sc", anio, indicador, valor, estado)
  municipios <- renta |> filter(nivel == "municipio") |>
    transmute(geo_id = codigo, nivel = "municipio", anio, indicador, valor, estado = "dato")
  bind_rows(secciones, municipios) |>
    mutate(fuente = "ine_adrh", geo_ref = "2021", version = version)
}
