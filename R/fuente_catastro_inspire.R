# Fuente catastro_inspire: edificios del Catastro (INSPIRE, servicio ATOM), uno por municipio.
# Vía (b) de las tablas de paso (plan §6.3): cada edificio con su número de viviendas.
# País Vasco y Navarra van por sus catastros forales (fuente_catastro_foral.R). Licencia por
# aclarar antes de publicar derivados (inventario/fuentes.csv). El código de municipio del
# Catastro no siempre es el del INE (Madrid: 28900), así que los municipios se casan por nombre
# y los edificios se asignan a las secciones por su posición.

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

# Provincias sin Catastro estatal (catastros forales de País Vasco y Navarra).
PROVINCIAS_FORALES <- c("01", "20", "31", "48")

# Gerencias del Catastro con feed propio fuera de la numeración provincial y la provincia del INE
# a la que pertenecen sus municipios. Ojo: el feed 51 del Catastro es Cartagena, no Ceuta.
GERENCIAS_CATASTRO <- c("51" = "30", "52" = "33", "53" = "11", "54" = "36", "55" = "51", "56" = "52")

# Feeds del Catastro de unas provincias del INE: el de la provincia y los de sus gerencias.
feeds_catastro <- function(provincias) {
  provincias <- setdiff(provincias, PROVINCIAS_FORALES)
  propios <- tibble::tibble(feed = setdiff(provincias, c("51", "52")), provincia = feed)
  gerencias <- tibble::tibble(feed = names(GERENCIAS_CATASTRO), provincia = unname(GERENCIAS_CATASTRO)) |>
    filter(provincia %in% provincias)
  bind_rows(propios, gerencias)
}

# Municipios del Catastro de las provincias pedidas, con la provincia del INE a la que pertenecen.
municipios_catastro_provincias <- function(provincias, pausa = 0.3) {
  f <- feeds_catastro(provincias)
  bind_rows(lapply(seq_len(nrow(f)), function(i) {
    Sys.sleep(pausa)
    municipios_catastro(f$feed[i]) |> mutate(provincia = f$provincia[i])
  }))
}

# Casa nombres del INE («Rozas de Madrid, Las») con los del Catastro («LAS ROZAS DE MADRID»).
normalizar_nombre_municipio <- function(x) {
  x <- toupper(iconv(x, to = "ASCII//TRANSLIT"))
  x <- sub("^(.*), (LA|EL|LOS|LAS|L')$", "\\2 \\1", x)
  gsub("[^A-Z0-9]", "", x)
}

# Artículos castellanos, catalanes y gallegos que el INE pospone («Coruña, A») y el Catastro
# antepone («A CORUÑA») o pospone sin coma («PUEBLA DE ALFINDEN LA»).
ARTICULOS_MUNICIPIO <- "EL|LA|LOS|LAS|L'|ELS|LES|ES|SA|SES|A|O|OS|AS"

# Clave sin artículos ni signos. La «ç» se quita en lugar de transliterarse porque el Catastro
# la pierde («LLI A D AMUNT» por Lliçà d'Amunt).
nombre_sin_articulo <- function(x) {
  x <- toupper(iconv(gsub("[çÇ]", "", x), to = "ASCII//TRANSLIT"))
  x <- trimws(gsub("\\s+", " ", x))
  x <- sub(sprintf(", (%s)$", ARTICULOS_MUNICIPIO), "", x)
  x <- sub(sprintf("^(%s) ", ARTICULOS_MUNICIPIO), "", x)
  x <- sub(sprintf(" (%s)$", ARTICULOS_MUNICIPIO), "", x)
  trimws(gsub("\\s+", " ", gsub("[^A-Z0-9]", " ", x)))
}
clave_sin_articulo <- function(x) gsub(" ", "", nombre_sin_articulo(x), fixed = TRUE)

# Fusiones y cambios de nombre que no se casan por el nombre: municipio del INE y nombre (o
# nombres) del Catastro en la provincia del municipio.
CATASTRO_MANUAL <- tibble::tribble(
  ~municipio, ~nombre_catastro,
  "15902",    "CESURAS",          # Oza-Cesuras, fusión de 2013: el Catastro sigue con los dos
  "15902",    "OZA DOS RIOS",
  "36902",    "CERDEDO",          # Cerdedo-Cotobade, fusión de 2016
  "36902",    "COTOBADE",
  "43136",    "LA RAPITA",        # Sant Carles de la Ràpita, hoy La Ràpita
  "17092",    "LLAN A",           # Llançà: sin la «ç», la «A» final parece un artículo
  "17048",    "CASTELL PLATJA D ARO I S AGARO"   # el ADRH la llama Castell d'Aro, Platja d'Aro i s'Agaró
)

# Casa los municipios del INE (`municipio`, `nombre`) con los zips del Catastro de su provincia
# (`provincia`, `nombre_catastro`, `url`). Por orden, y siempre con un único candidato libre que
# ningún otro municipio pida en la misma vuelta:
#   1. nombre normalizado igual;
#   2. alguna variante igual (cada parte de los bilingües «Pinós, el/Pinoso», sin artículos);
#   3. bilingües que el Catastro junta («ORPESA OROPESA DEL MAR»): todas las partes dentro;
#   4. nombres que el Catastro corta a 30 caracteres o alarga: uno empieza por el otro;
#   5. nombres cortos que el Catastro completa («CANGAS DE MORRAZO», «MONTCADA MONCADA»): el del
#      INE es la primera o la última palabra del Catastro;
#   6. tabla manual (CATASTRO_MANUAL).
# Devuelve una fila por municipio y zip (las fusiones tienen varios); url NA si no casa.
casar_municipios_catastro <- function(ine, catastro) {
  ine <- distinct(ine, municipio, nombre) |> mutate(provincia = substr(municipio, 1, 2))
  cat_ <- catastro |> mutate(clave = normalizar_nombre_municipio(nombre_catastro),
                             sin_art = clave_sin_articulo(nombre_catastro))
  variantes <- function(nombre) unique(clave_sin_articulo(strsplit(nombre, "/", fixed = TRUE)[[1]]))
  contiene_todas <- function(v, s) length(v) > 1 && all(vapply(v, function(x) grepl(x, s, fixed = TRUE), TRUE))
  empieza <- function(v, s) any(nchar(v) >= 10 & nchar(s) >= 10 & (startsWith(v, s) | startsWith(s, v)))
  palabras <- function(nombre) unique(nombre_sin_articulo(strsplit(nombre, "/", fixed = TRUE)[[1]]))
  extremo <- function(v, s) any(startsWith(s, paste0(v, " ")) | endsWith(s, paste0(" ", v)))
  reglas <- list(
    function(m, c) c$sin_art %in% variantes(m$nombre),
    function(m, c) vapply(c$sin_art, function(s) contiene_todas(variantes(m$nombre), s), TRUE),
    function(m, c) vapply(c$sin_art, function(s) empieza(variantes(m$nombre), s), TRUE),
    function(m, c) vapply(nombre_sin_articulo(c$nombre_catastro), function(s) extremo(palabras(m$nombre), s), TRUE)
  )
  # Un candidato vale si es único para el municipio y nadie más lo pide en la misma vuelta
  unicos <- function(x) x |> group_by(municipio) |> filter(n() == 1) |> group_by(url) |> filter(n() == 1) |> ungroup()

  # Regla 1, de una vez
  casados <- ine |>
    mutate(clave = normalizar_nombre_municipio(nombre)) |>
    inner_join(cat_ |> select(provincia, clave, url), by = c("provincia", "clave"), relationship = "many-to-many") |>
    unicos() |>
    transmute(municipio, url, regla = 1L)
  for (k in seq_along(reglas)) {
    pendientes <- filter(ine, !municipio %in% casados$municipio)
    libres <- filter(cat_, !url %in% casados$url)
    nuevos <- bind_rows(lapply(seq_len(nrow(pendientes)), function(i) {
      m <- pendientes[i, ]
      c <- filter(libres, provincia == m$provincia)
      if (nrow(c) == 0) return(NULL)
      ok <- reglas[[k]](m, c)
      tibble::tibble(municipio = rep(m$municipio, sum(ok)), url = c$url[ok])
    }))
    if (nrow(nuevos)) casados <- bind_rows(casados, unicos(nuevos) |> mutate(regla = k + 1L))
  }
  manual <- CATASTRO_MANUAL |>
    filter(!municipio %in% casados$municipio, municipio %in% ine$municipio) |>
    mutate(provincia = substr(municipio, 1, 2)) |>
    inner_join(cat_ |> select(provincia, nombre_catastro, url), by = c("provincia", "nombre_catastro")) |>
    transmute(municipio, url, regla = 6L)
  ine |>
    select(municipio, nombre) |>
    left_join(bind_rows(casados, manual), by = "municipio", relationship = "one-to-many")
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

# Sección en la que cae cada punto (la primera si dos polígonos se solapan; NA si ninguna).
seccion_de_puntos <- function(puntos, secciones) {
  secciones <- sf::st_transform(secciones, sf::st_crs(puntos))
  dentro <- sf::st_within(puntos, secciones)
  secciones$seccion[vapply(dentro, function(i) if (length(i)) i[1] else NA_integer_, 1L)]
}

# Los edificios de todos los municipios en una tabla: coordenadas en el sistema de las secciones
# (los zips vienen en el huso UTM de cada provincia), viviendas, año de construcción y sección
# de destino (la del seccionado de referencia, que es la misma para todos los años).
combinar_edificios <- function(lista, destino) {
  crs <- sf::st_crs(destino)
  e <- bind_rows(lapply(lista, function(m) {
    xy <- sf::st_coordinates(sf::st_transform(m, crs))
    tibble::tibble(x = xy[, 1], y = xy[, 2], viviendas = m$viviendas, anio_construccion = m$anio_construccion)
  }))
  e$destino <- seccion_de_puntos(sf::st_as_sf(e, coords = c("x", "y"), crs = crs), destino)
  e
}

# Tabla de paso por viviendas: cada edificio cae en una sección de origen y en una de destino;
# el peso es el número de viviendas compartidas. Misma estructura que la del callejero.
# `edificios`: sf de puntos o tabla de combinar_edificios() (con x, y en el sistema de `origen`
# y la sección de destino ya puesta; entonces `destino` puede ser NULL).
# `anio_max`: solo cuentan los edificios construidos hasta ese año (los de año desconocido, sí).
geo_tabla_paso_catastro <- function(edificios, origen, destino = NULL, anio_max = NULL, grupos = NULL) {
  if (!is.null(anio_max) && "anio_construccion" %in% names(edificios)) {
    edificios <- edificios[is.na(edificios$anio_construccion) | edificios$anio_construccion <= anio_max, ]
  }
  if (!inherits(edificios, "sf")) {
    edificios <- sf::st_as_sf(edificios, coords = c("x", "y"), crs = sf::st_crs(origen))
  }
  edificios <- sf::st_transform(edificios, sf::st_crs(origen))
  o <- seccion_de_puntos(edificios, origen)
  d <- if (is.null(destino)) edificios$destino else seccion_de_puntos(edificios, destino)
  # Solo pares del mismo municipio: un edificio junto a un límite municipal puede caer en
  # municipios distintos en dos seccionados porque los límites se digitalizan de forma distinta;
  # el callejero tampoco cruza municipios (sin esto, la prueba de cierre falla en 2015). Dentro de
  # un grupo de fusión o segregación (`grupos`), sí.
  tibble::tibble(origen = o, destino = d, viviendas = edificios$viviendas) |>
    filter(!is.na(origen), !is.na(destino),
           agrupar_municipio(substr(origen, 1, 5), grupos) == agrupar_municipio(substr(destino, 1, 5), grupos)) |>
    group_by(origen, destino) |>
    summarise(portales = sum(viviendas), .groups = "drop") |>    # «portales» = viviendas, para reutilizar las funciones
    group_by(origen) |>
    mutate(fraccion = portales / sum(portales), metodo = "catastro") |>
    ungroup()
}

# Municipios con secciones «estimado» en alguna de las tablas del callejero y sus zips del
# Catastro (`catastro`: municipios_catastro_provincias()). Una fila por municipio y zip; url NA
# en los forales y en los que no casan. `extra`: municipios que se añaden siempre (los de los
# grupos de fusión o segregación).
seleccionar_municipios_catastro <- function(tablas, nombres, catastro, extra = character()) {
  estimados <- bind_rows(lapply(tablas, geo_estado_paso)) |>
    filter(estado_recuento == "estimado") |>
    distinct(municipio = substr(seccion, 1, 5)) |>
    bind_rows(tibble::tibble(municipio = extra)) |>
    distinct(municipio) |>
    left_join(nombres, by = "municipio")
  forales <- substr(estimados$municipio, 1, 2) %in% PROVINCIAS_FORALES
  casados <- casar_municipios_catastro(filter(estimados[!forales, ], !is.na(nombre)), catastro)
  estimados |>
    left_join(select(casados, municipio, url, regla), by = "municipio", relationship = "one-to-many") |>
    mutate(foral = substr(municipio, 1, 2) %in% PROVINCIAS_FORALES)
}

# Secciones «fantasma»: códigos del mapa que no están en los datos (callejero y ADRH). El
# seccionado del INE va a veces por detrás de ellos (dibuja una sección ya fusionada) o por
# delante (una sección que los datos aún no tienen); en Madrid, dos en el mapa de 2022. Sus
# edificios pasan al origen de los datos que, según el callejero, cubre el mismo destino de
# 2021. Si lo cubren varios, no se sabe a cuál van: esos orígenes siguen por el callejero
# (`excluidos`). `datos`: códigos con datos del año (ADRH); sin ellos, solo cuenta el callejero.
reasignar_fantasmas <- function(tabla_b, tabla_a, datos = NULL) {
  fantasmas <- setdiff(tabla_b$origen, union(tabla_a$origen, datos))
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
#
# El Catastro decide también donde el callejero no llega (toda España, 7-nov-2026):
#   - orígenes que el Catastro lleva a otro municipio (solo dentro de un grupo de fusión o
#     segregación): el callejero no siempre los cruza;
#   - orígenes con datos (`datos`, del ADRH) que están en el mapa pero no en el callejero;
#   - orígenes que el Catastro lleva, en parte, a una sección de 2021 que en la tabla combinada
#     se queda sin nada (el callejero los da por enteros en otra). Se repite hasta que no queden
#     secciones así.
combinar_vias <- function(tabla_b, tabla_a, umbral = 0.99, datos = NULL) {
  r <- reasignar_fantasmas(tabla_b, tabla_a, datos)
  tabla_b <- r$tabla
  cruzan <- tabla_b$origen[substr(tabla_b$origen, 1, 5) != substr(tabla_b$destino, 1, 5)]
  sin_callejero <- setdiff(tabla_b$origen, tabla_a$origen)
  repartidos <- unique(c(tabla_a$origen[tabla_a$fraccion < umbral], cruzan, sin_callejero))
  por_catastro <- setdiff(intersect(repartidos, tabla_b$origen), r$excluidos)
  viviendas <- tabla_b |> group_by(origen) |> summarise(total = sum(portales), .groups = "drop")
  combinar <- function(por_catastro) {
    por_callejero <- tabla_a |>
      filter(!origen %in% por_catastro) |>
      left_join(viviendas, by = "origen") |>
      mutate(portales = if_else(!is.na(total) & fraccion >= umbral, as.numeric(total), as.numeric(portales))) |>
      select(-total)
    bind_rows(por_callejero, filter(tabla_b, origen %in% por_catastro) |> mutate(portales = as.numeric(portales)))
  }
  tabla <- combinar(por_catastro)
  repeat {
    huecos <- setdiff(tabla_b$destino, tabla$destino)
    nuevos <- setdiff(unique(tabla_b$origen[tabla_b$destino %in% huecos]), por_catastro)
    if (length(nuevos) == 0) break
    por_catastro <- c(por_catastro, nuevos)
    tabla <- combinar(por_catastro)
  }
  tabla
}

# Secciones con datos que ninguna vía lleva a 2021 (ni en el callejero ni con edificios) pero cuyo
# código existe en el seccionado de referencia: pasan a esa sección (`metodo = "codigo"`). En
# España, secciones que el mapa y el ADRH tienen y el callejero del mismo año no (2023: seis).
completar_por_codigo <- function(tabla, datos, referencia) {
  faltan <- setdiff(intersect(datos, referencia), tabla$origen)
  if (length(faltan) == 0) return(tabla)
  bind_rows(tabla, tibble::tibble(origen = faltan, destino = faltan, portales = NA_real_,
                                  metodo = "codigo", fraccion = 1))
}

# Códigos de sección con datos de un año (ADRH).
secciones_con_datos <- function(poblacion, anio) {
  unique(poblacion$codigo[poblacion$nivel == "seccion" & poblacion$anio == anio])
}

# Compara las dos vías en las secciones de destino de los municipios cubiertos: población de un
# año llevada a 2021 frente a la publicada en 2021 (ADRH 2020). Con un año de distancia (2022 →
# 2021) mide el error de la tabla; con más, lo mezcla con el crecimiento.
comparar_vias_paso <- function(poblacion, tabla_a, tabla_b, anio, municipios, anio_nativo = 2020L) {
  dest <- unique(tabla_a$destino[substr(tabla_a$destino, 1, 5) %in% municipios])
  estimadas <- geo_estado_paso(tabla_a) |> filter(estado_recuento == "estimado") |> pull(seccion)
  diag <- function(t, via) geo_diagnostico_paso(poblacion, t, anio, anio_nativo) |>
    filter(seccion %in% dest) |> transmute(seccion, via, razon, estimada_a = seccion %in% estimadas)
  bind_rows(diag(tabla_a, "a: callejero"),
            diag(combinar_vias(tabla_b, tabla_a, datos = secciones_con_datos(poblacion, anio)), "b: catastro")) |>
    group_by(via, estimada_a) |>
    summarise(secciones = n(), p05 = stats::quantile(razon, 0.05), p50 = stats::median(razon),
              p95 = stats::quantile(razon, 0.95), dentro_5 = mean(abs(razon - 1) <= 0.05),
              fuera_20 = sum(razon < 0.8 | razon > 1.25), .groups = "drop") |>
    mutate(anio_origen = anio, .before = 1)
}
