# Fuente catastro_inspire: edificios del Catastro (INSPIRE, servicio ATOM), uno por municipio.
# Vía (b) de las tablas de paso (plan §6.3): cada edificio con su número de viviendas.
# Sin País Vasco ni Navarra (catastros forales). Licencia por aclarar antes de publicar
# derivados (inventario/fuentes.csv). El código de municipio del Catastro no siempre es el
# del INE (Madrid: 28900), así que los municipios se casan por nombre y los edificios se
# asignan a las secciones por su posición.

url_catastro_provincia <- function(provincia) {
  sprintf("https://www.catastro.hacienda.gob.es/INSPIRE/buildings/%s/ES.SDGC.bu.atom_%s.xml", provincia, provincia)
}

# Enlaces de los zips municipales de una provincia, con el nombre que da el Catastro.
municipios_catastro <- function(provincia) {
  # El feed viene en ISO-8859-1
  xml <- httr2::request(url_catastro_provincia(provincia)) |>
    httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
    httr2::req_perform() |> httr2::resp_body_raw() |> rawToChar() |> iconv(from = "latin1", to = "UTF-8")
  urls <- unique(regmatches(xml, gregexpr("https://[^\"<]+\\.zip", xml))[[1]])
  tibble::tibble(
    url = urls,
    codigo_catastro = sub(".*/(\\d{5})-[^/]+/[^/]+$", "\\1", urls),
    nombre_catastro = sub(".*/\\d{5}-([^/]+)/[^/]+$", "\\1", urls)
  )
}

# Casa nombres del INE («Rozas de Madrid, Las») con los del Catastro («LAS ROZAS DE MADRID»).
normalizar_nombre_municipio <- function(x) {
  x <- toupper(iconv(x, to = "ASCII//TRANSLIT"))
  x <- sub("^(.*), (LA|EL|LOS|LAS|L')$", "\\2 \\1", x)
  gsub("[^A-Z0-9]", "", x)
}

descargar_catastro_edificios <- function(url, dir = file.path("datos", "brutos", "catastro"), forzar = FALSE) {
  destino <- file.path(dir, basename(url))
  descargar_con_cache(utils::URLencode(enc2utf8(url)), destino, forzar)
}

# Edificios con viviendas: un punto dentro de cada edificio, su número de viviendas y su año de
# construcción (campo «beginning»; vacío en unos pocos).
leer_catastro_edificios <- function(zip) {
  contenido <- utils::unzip(zip, list = TRUE)$Name
  gml <- contenido[grepl("\\.building\\.gml$", contenido, ignore.case = TRUE)]
  if (length(gml) != 1) stop("No encuentro el GML de edificios en ", zip, call. = FALSE)
  e <- sf::st_read(paste0("/vsizip/", normalizePath(zip, winslash = "/"), "/", gml), quiet = TRUE)
  viviendas <- suppressWarnings(as.numeric(e$numberOfDwellings))
  con_viviendas <- !is.na(viviendas) & viviendas > 0
  e <- e[con_viviendas, ]
  sf::st_sf(viviendas = viviendas[con_viviendas],
            anio_construccion = suppressWarnings(as.integer(substr(as.character(e$beginning), 1, 4))),
            geometry = sf::st_point_on_surface(sf::st_make_valid(sf::st_geometry(e))))
}

# Tabla de paso por viviendas: cada edificio cae en una sección de origen y en una de destino;
# el peso es el número de viviendas compartidas. Misma estructura que la del callejero.
# `anio_max`: solo cuentan los edificios construidos hasta ese año (los de año desconocido, sí).
geo_tabla_paso_catastro <- function(edificios, origen, destino, anio_max = NULL) {
  if (!is.null(anio_max) && "anio_construccion" %in% names(edificios)) {
    edificios <- edificios[is.na(edificios$anio_construccion) | edificios$anio_construccion <= anio_max, ]
  }
  edificios <- sf::st_transform(edificios, sf::st_crs(origen))
  destino <- sf::st_transform(destino, sf::st_crs(origen))
  o <- sf::st_join(edificios, origen[, "seccion"], join = sf::st_within)
  d <- sf::st_join(edificios, destino[, "seccion"], join = sf::st_within)
  # Solo pares del mismo municipio: un edificio junto a un límite municipal puede caer en
  # municipios distintos en dos seccionados porque los límites se digitalizan de forma distinta;
  # el callejero tampoco cruza municipios (sin esto, la prueba de cierre falla en 2015).
  tibble::tibble(origen = o$seccion, destino = d$seccion, viviendas = edificios$viviendas) |>
    filter(!is.na(origen), !is.na(destino), substr(origen, 1, 5) == substr(destino, 1, 5)) |>
    group_by(origen, destino) |>
    summarise(portales = sum(viviendas), .groups = "drop") |>    # «portales» = viviendas, para reutilizar las funciones
    group_by(origen) |>
    mutate(fraccion = portales / sum(portales), metodo = "catastro") |>
    ungroup()
}

# Municipios con secciones «estimado» en alguna de las tablas del callejero y su zip del Catastro.
seleccionar_municipios_catastro <- function(tablas, ruta_demografia, provincia) {
  estimados <- bind_rows(lapply(tablas, geo_estado_paso)) |>
    filter(estado_recuento == "estimado") |>
    distinct(municipio = substr(seccion, 1, 5))
  d <- readr::read_delim(ruta_demografia, delim = ";", col_types = readr::cols(.default = "c"), progress = FALSE)
  nombres <- tibble::tibble(municipio = substr(unique(d[[1]]), 1, 5), nombre = substring(unique(d[[1]]), 7))
  m <- municipios_catastro(provincia) |> mutate(clave = normalizar_nombre_municipio(nombre_catastro))
  estimados |>
    left_join(nombres, by = "municipio") |>
    mutate(clave = normalizar_nombre_municipio(nombre)) |>
    left_join(m, by = "clave")
}

# Secciones «fantasma»: códigos del mapa que no están en los datos (callejero y ADRH). El
# seccionado del INE va a veces por detrás de ellos (dibuja una sección ya fusionada) o por
# delante (una sección que los datos aún no tienen); en Madrid, dos en el mapa de 2022. Sus
# edificios pasan al origen de los datos que, según el callejero, cubre el mismo destino de
# 2021. Si lo cubren varios, no se sabe a cuál van: esos orígenes siguen por el callejero
# (`excluidos`).
reasignar_fantasmas <- function(tabla_b, tabla_a) {
  fantasmas <- setdiff(tabla_b$origen, tabla_a$origen)
  if (length(fantasmas) == 0) return(list(tabla = tabla_b, excluidos = character(0)))
  f <- filter(tabla_b, origen %in% fantasmas)
  cubre <- tabla_a |>
    filter(destino %in% f$destino) |>
    distinct(destino, origen_datos = origen) |>
    group_by(destino) |> mutate(n = n()) |> ungroup()
  f <- left_join(f, filter(cubre, n == 1) |> select(destino, origen_datos), by = "destino")
  excluidos <- unique(cubre$origen_datos[cubre$destino %in% f$destino[is.na(f$origen_datos)]])
  tabla <- bind_rows(filter(tabla_b, !origen %in% fantasmas),
                     filter(f, !is.na(origen_datos)) |> mutate(origen = origen_datos) |> select(-origen_datos)) |>
    group_by(origen, destino) |>
    summarise(portales = sum(portales), .groups = "drop") |>
    group_by(origen) |>
    mutate(fraccion = portales / sum(portales), metodo = "catastro") |>
    ungroup()
  list(tabla = tabla, excluidos = excluidos)
}

# Regla adoptada (7-nov-2026, plan §6.3): callejero (vía a) para las secciones de origen que
# caen enteras en una de 2021; Catastro (vía b) para las que hay que repartir, si tienen
# edificios con viviendas. En las que siguen por el callejero, el peso pasa a ser el número de
# viviendas cuando el Catastro lo da, para que el origen dominante de las medianas compare
# viviendas con viviendas.
combinar_vias <- function(tabla_b, tabla_a, umbral = 0.99) {
  r <- reasignar_fantasmas(tabla_b, tabla_a)
  tabla_b <- r$tabla
  repartidos <- unique(tabla_a$origen[tabla_a$fraccion < umbral])
  por_catastro <- setdiff(intersect(repartidos, tabla_b$origen), r$excluidos)
  viviendas <- tabla_b |> group_by(origen) |> summarise(total = sum(portales), .groups = "drop")
  por_callejero <- tabla_a |>
    filter(!origen %in% por_catastro) |>
    left_join(viviendas, by = "origen") |>
    mutate(portales = if_else(!is.na(total) & fraccion >= umbral, as.numeric(total), as.numeric(portales))) |>
    select(-total)
  bind_rows(por_callejero, filter(tabla_b, origen %in% por_catastro) |> mutate(portales = as.numeric(portales)))
}

# Compara las dos vías en las secciones de destino de los municipios cubiertos: población de un
# año llevada a 2021 frente a la publicada en 2021 (ADRH 2020). Con un año de distancia (2022 →
# 2021) mide el error de la tabla; con más, lo mezcla con el crecimiento.
comparar_vias_paso <- function(poblacion, tabla_a, tabla_b, anio, municipios, anio_nativo = 2020L) {
  dest <- unique(tabla_a$destino[substr(tabla_a$destino, 1, 5) %in% municipios])
  estimadas <- geo_estado_paso(tabla_a) |> filter(estado_recuento == "estimado") |> pull(seccion)
  diag <- function(t, via) geo_diagnostico_paso(poblacion, t, anio, anio_nativo) |>
    filter(seccion %in% dest) |> transmute(seccion, via, razon, estimada_a = seccion %in% estimadas)
  bind_rows(diag(tabla_a, "a: callejero"), diag(combinar_vias(tabla_b, tabla_a), "b: catastro")) |>
    group_by(via, estimada_a) |>
    summarise(secciones = n(), p05 = stats::quantile(razon, 0.05), p50 = stats::median(razon),
              p95 = stats::quantile(razon, 0.95), dentro_5 = mean(abs(razon - 1) <= 0.05),
              fuera_20 = sum(razon < 0.8 | razon > 1.25), .groups = "drop") |>
    mutate(anio_origen = anio, .before = 1)
}
