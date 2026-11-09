# Jerarquía territorial y mapa base del seccionado de referencia (2021). F1, plan §7.
#
# Jerarquía: sección → distrito → municipio → provincia → comunidad. Los cuatro primeros niveles
# están en el propio código de la sección (provincia 2, municipio 3, distrito 2, sección 3); la
# comunidad sale de la tabla de atributos del seccionado (columna CCA). Nombres: municipios del
# ADRH (nombre vigente), provincias del seccionado y comunidades de geo/ccaa.csv.
#
# Mapa base: PMTiles (teselas vectoriales MVT) con cuatro capas, secciones y, por disolución de
# las secciones, municipios, provincias y comunidades. Se genera con GDAL desde R (controlador
# PMTiles, GDAL >= 3.8, el que trae sf): no hace falta tippecanoe. GDAL cuantifica cada tesela a
# su rejilla (EXTENT) y simplifica en unidades de esa rejilla, así que la simplificación va por
# nivel de zoom y los vértices que comparten dos secciones se mueven igual en las dos.

# Ruta GDAL del .shp dentro del zip del seccionado (como en leer_ine_seccionado()).
ruta_shp_seccionado <- function(zip) {
  contenido <- utils::unzip(zip, list = TRUE)$Name
  interno <- contenido[grepl("\\.shp$", contenido, ignore.case = TRUE, useBytes = TRUE)]
  if (length(interno) != 1) stop("Se esperaba un unico .shp en ", zip, call. = FALSE)
  if (!validUTF8(interno)) interno <- iconv(interno, "CP437", "UTF-8")
  paste0("/vsizip/", normalizePath(zip, winslash = "/"), "/", interno)
}

# Provincias del seccionado: código, nombre y comunidad (CPRO, NPRO y CCA). Sin geometría.
leer_ine_seccionado_provincias <- function(zip) {
  shp <- ruta_shp_seccionado(zip)
  capa <- sf::st_layers(shp)$name[1]
  atributos <- suppressWarnings(sf::st_read(shp, query = sprintf("SELECT CPRO, NPRO, CCA FROM \"%s\"", capa),
                                            quiet = TRUE))
  tibble::as_tibble(as.data.frame(atributos)) |>
    transmute(provincia = as.character(CPRO), nombre = as.character(NPRO), ccaa = as.character(CCA)) |>
    distinct() |>
    arrange(provincia)
}

# Una fila por sección con el código de cada nivel superior. `secciones`: el seccionado de
# referencia (sf o tabla) con `seccion` y, si la trae, `municipio` (el de la tabla de atributos;
# si no, el del código). `provincias`: leer_ine_seccionado_provincias().
geo_jerarquia <- function(secciones, provincias) {
  if (inherits(secciones, "sf")) secciones <- sf::st_drop_geometry(secciones)
  s <- as.character(secciones$seccion)
  municipio <- if ("municipio" %in% names(secciones)) as.character(secciones$municipio) else substr(s, 1, 5)
  tibble::tibble(seccion = s, distrito = substr(s, 1, 7), municipio = municipio, provincia = substr(s, 1, 2)) |>
    left_join(select(provincias, provincia, ccaa), by = "provincia", relationship = "many-to-many") |>
    relocate(ccaa, .after = provincia) |>
    arrange(seccion)
}

# Territorios de cada nivel: código, nombre, territorio superior y número de secciones.
# `nombres_municipios`: municipio y nombre (nombres_municipios_adrh()); `ccaa`: geo/ccaa.csv.
geo_territorios <- function(jerarquia, nombres_municipios, provincias, ccaa) {
  nombres <- bind_rows(
    transmute(ccaa, nivel = "ccaa", codigo = codigo, nombre = nombre_ine),
    transmute(provincias, nivel = "provincia", codigo = provincia, nombre = nombre),
    transmute(nombres_municipios, nivel = "municipio", codigo = municipio, nombre = nombre)
  ) |> distinct(nivel, codigo, .keep_all = TRUE)
  contar <- function(nivel, codigo, superior) {
    jerarquia |>
      count(codigo = .data[[codigo]], superior = if (is.null(superior)) NA_character_ else .data[[superior]],
            name = "secciones") |>
      mutate(nivel = nivel)
  }
  bind_rows(
    contar("ccaa", "ccaa", NULL),
    contar("provincia", "provincia", "ccaa"),
    contar("municipio", "municipio", "provincia"),
    contar("distrito", "distrito", "municipio")
  ) |>
    left_join(nombres, by = c("nivel", "codigo")) |>
    mutate(nivel = factor(nivel, c("ccaa", "provincia", "municipio", "distrito"))) |>
    arrange(nivel, codigo) |>
    mutate(nivel = as.character(nivel), secciones = as.integer(secciones)) |>
    select(nivel, codigo, nombre, superior, secciones)
}

# Compuerta de la jerarquía (inventario/referencias_validacion.csv):
#   jerarquia_unica: cada sección aparece una vez y cada territorio cuelga de un solo superior;
#     los códigos encajan (el de la sección empieza por el de su distrito, y así hacia arriba).
#   jerarquia_sumas: las secciones de cada territorio son la suma de las de sus partes; el total,
#     las del seccionado, y no falta ni sobra ninguna sección.
#   jerarquia_nombres: comunidades, provincias y municipios sin nombre.
comprobar_jerarquia <- function(jerarquia, territorios, secciones_referencia) {
  superiores <- function(hijo, padre) {
    jerarquia |> distinct(.data[[hijo]], .data[[padre]]) |> count(.data[[hijo]]) |> filter(n > 1) |> nrow()
  }
  codigos <- with(jerarquia, sum(is.na(ccaa) | !startsWith(seccion, distrito) | !startsWith(distrito, municipio) |
                                   !startsWith(municipio, provincia) | nchar(seccion) != 10L | nchar(ccaa) != 2L))
  unica <- tibble::tibble(
    detalle = c("seccion repetida", "distrito en mas de un municipio", "municipio en mas de una provincia",
                "provincia en mas de una comunidad", "codigos que no encajan"),
    calculado = c(sum(duplicated(jerarquia$seccion)), superiores("distrito", "municipio"),
                  superiores("municipio", "provincia"), superiores("provincia", "ccaa"), codigos)
  )
  partes <- territorios |>
    filter(nivel != "ccaa") |>
    group_by(nivel_superior = c(provincia = "ccaa", municipio = "provincia", distrito = "municipio")[nivel],
             codigo = superior) |>
    summarise(suma = sum(secciones), .groups = "drop")
  descuadres <- territorios |>
    filter(nivel != "distrito") |>
    left_join(partes, by = c(nivel = "nivel_superior", "codigo")) |>
    group_by(nivel) |>
    summarise(calculado = sum(is.na(suma) | suma != secciones), .groups = "drop")
  sumas <- bind_rows(
    tibble::tibble(detalle = paste("territorios que no suman sus partes:", descuadres$nivel),
                   calculado = descuadres$calculado),
    tibble::tibble(detalle = "secciones del total menos las del seccionado",
                   calculado = sum(territorios$secciones[territorios$nivel == "ccaa"]) - length(secciones_referencia)),
    tibble::tibble(detalle = "secciones del seccionado sin jerarquia",
                   calculado = length(setdiff(secciones_referencia, jerarquia$seccion))),
    tibble::tibble(detalle = "secciones de la jerarquia fuera del seccionado",
                   calculado = length(setdiff(jerarquia$seccion, secciones_referencia)))
  )
  sin_nombre <- territorios |>
    filter(nivel != "distrito") |>
    group_by(nivel) |>
    summarise(calculado = sum(is.na(nombre) | nombre == ""), .groups = "drop")
  bind_rows(
    mutate(unica, id = "jerarquia_unica"),
    mutate(sumas, id = "jerarquia_sumas"),
    transmute(sin_nombre, id = "jerarquia_nombres", detalle = nivel, calculado)
  ) |>
    transmute(id, detalle, calculado = as.numeric(calculado), referencia = 0)
}

# Jerarquía y territorios a CSV (geo/): pequeños, van en git. `sufijo`: el del ámbito de prueba
# (PROVINCIA), para no pisar los de toda España.
exportar_jerarquia <- function(jerarquia, territorios, dir = "geo", anio = 2021L, sufijo = "") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  rutas <- file.path(dir, paste0(sprintf(c("jerarquia_%d", "territorios_%d"), anio), sufijo, ".csv"))
  readr::write_csv(arrange(jerarquia, seccion), rutas[1], na = "")
  readr::write_csv(territorios, rutas[2], na = "")
  rutas
}

# --- Mapa base -------------------------------------------------------------------------------

# Niveles de zoom de cada capa (mínimo y máximo con datos; MapLibre amplía las teselas del
# máximo en los zooms siguientes). Las secciones empiezan donde una sección urbana mediana ya
# ocupa unos píxeles; las capas de arriba sirven de contexto y de bordes. El suelo sin sección
# va en todos los zooms, para que no se vea el fondo en ninguno.
ZOOMS_MAPA_BASE <- list(
  comunidades = c(0L, 12L),
  provincias  = c(3L, 12L),
  municipios  = c(5L, 12L),
  secciones   = c(7L, 12L),
  sin_seccion = c(0L, 12L)
)

# Suelo sin sección. El seccionado de 2021 no cubre el suelo que no es de ningún término
# municipal: montes y terrenos comunales compartidos, como las Bardenas Reales o las sierras de
# Urbasa y Andía. Quedan como anillos interiores de la unión de las secciones: 95 de al menos
# 0,01 km², 1.495 km² sin las secciones que caen dentro (8-nov-2026). Por debajo del umbral solo
# hay rendijas entre secciones vecinas, del orden de un metro de ancho, que no se ven ni se pulsan.
UMBRAL_SIN_SECCION_KM2 <- 0.01

# Huecos de una capa de polígonos (sf o sfc): anillos interiores de su unión de al menos
# `umbral_km2`, sin las islas que caen dentro (enclaves). Devuelve un sf con `km2` (dos decimales).
geo_huecos <- function(poligonos, umbral_km2 = UMBRAL_SIN_SECCION_KM2) {
  geom <- sf::st_geometry(poligonos)
  crs <- sf::st_crs(geom)
  vacio <- sf::st_sf(km2 = numeric(), geometry = sf::st_sfc(sf::st_multipolygon(), crs = crs)[0])
  partes <- sf::st_cast(sf::st_union(geom), "POLYGON")
  anillos <- list()
  for (p in partes) {
    if (length(p) > 1) for (k in 2:length(p)) anillos[[length(anillos) + 1]] <- sf::st_polygon(list(p[[k]]))
  }
  if (!length(anillos)) return(vacio)
  h <- sf::st_sfc(anillos, crs = crs)
  h <- h[as.numeric(sf::st_area(h)) / 1e6 >= umbral_km2]     # las islas solo restan
  if (!length(h)) return(vacio)
  dentro <- sf::st_within(partes, h)
  for (i in seq_along(h)) {
    islas <- which(vapply(dentro, function(x) i %in% x, TRUE))
    if (length(islas)) h[i] <- sf::st_difference(h[i], sf::st_union(partes[islas]))
  }
  km2 <- as.numeric(sf::st_area(h)) / 1e6
  h <- geo_poligonos_validos(sf::st_sf(km2 = as.numeric(sprintf("%.2f", km2)), geometry = h))
  h[km2 >= umbral_km2, ]
}

# Suma a cada territorio de `capa` (columna `codigo`) los huecos cuyo `destino` es su código.
geo_absorber_huecos <- function(capa, huecos, destino) {
  geom <- sf::st_geometry(capa)
  for (codigo in unique(stats::na.omit(destino))) {
    i <- match(codigo, capa$codigo)
    geom[i] <- sf::st_cast(sf::st_union(c(geom[i], sf::st_geometry(huecos)[destino %in% codigo])), "MULTIPOLYGON")
  }
  geo_poligonos_validos(sf::st_set_geometry(capa, geom))
}

# Nombres del suelo sin sección (decisión del autor, 9-nov-2026): los trozos de cada hueco que
# caen en una unidad del IGN (leer_ign_au(); condominios, sobre todo), con el nombre literal y el
# tipo de la suya, donde el IGN la dibuja. Cuenta el solape de al menos `umbral_km2`, el mismo
# umbral que los huecos: con toda España, los solapes menores son de 0,001 km² o menos (roces de
# bordes) y el siguiente, de 0,012. Lo que no cubre ninguna unidad no es un trozo: se queda en el
# hueco (geo_capas_mapa_base). Las líneas del IGN no coinciden del todo con las del INE, así que
# esos restos son sobre todo franjas finas en los bordes, que la cuantización de las teselas rompe.
# Devuelve un sf con `hueco` (fila de `huecos`), `km2` (del trozo, dos decimales), las columnas de
# `huecos` salvo la geometría y `km2`, y `nombre` y `tipo`.
geo_nombrar_huecos <- function(huecos, unidades, umbral_km2 = UMBRAL_SIN_SECCION_KM2) {
  crs <- sf::st_crs(huecos)
  geom_h <- sf::st_geometry(huecos)
  if (!length(geom_h)) {
    vacio <- huecos[0, setdiff(names(huecos), c("hueco", "nombre", "tipo"))]
    vacio$hueco <- integer()
    vacio$nombre <- character()
    vacio$tipo <- character()
    return(vacio)
  }
  geom_u <- sf::st_geometry(sf::st_transform(unidades, crs))
  cruce <- sf::st_intersects(geom_h, geom_u)
  poligonos <- function(g) {
    g <- g[!sf::st_is_empty(g)]
    tipo <- as.character(sf::st_geometry_type(g))
    if (any(tipo == "GEOMETRYCOLLECTION")) {
      g <- sf::st_collection_extract(g, "POLYGON", warn = FALSE)
      tipo <- as.character(sf::st_geometry_type(g))
    }
    g <- g[tipo %in% c("POLYGON", "MULTIPOLYGON")]
    if (!length(g)) return(NULL)
    g <- sf::st_union(g)
    if (!length(g) || all(sf::st_is_empty(g))) NULL else g
  }
  km2 <- function(g) sum(as.numeric(sf::st_area(g))) / 1e6
  trozos <- list()
  anadir <- function(i, g, nombre, tipo) {
    trozos[[length(trozos) + 1]] <<- list(hueco = i, nombre = nombre, tipo = tipo, km2 = km2(g),
                                          geometry = sf::st_cast(g, "MULTIPOLYGON")[[1]])
  }
  for (i in seq_along(geom_h)) {
    for (j in cruce[[i]]) {
      p <- poligonos(sf::st_intersection(geom_h[i], geom_u[j]))
      if (!is.null(p) && km2(p) >= umbral_km2) anadir(i, p, unidades$nombre[j], unidades$tipo[j])
    }
  }
  atributos <- sf::st_drop_geometry(huecos)
  atributos <- atributos[, setdiff(names(atributos), c("km2", "hueco", "nombre", "tipo")), drop = FALSE]
  t <- tibble::tibble(hueco = vapply(trozos, `[[`, 1L, "hueco"),
                      km2 = as.numeric(sprintf("%.2f", vapply(trozos, `[[`, 1, "km2"))))
  t <- dplyr::bind_cols(t, atributos[t$hueco, , drop = FALSE],
                        tibble::tibble(nombre = vapply(trozos, `[[`, "", "nombre"),
                                       tipo = vapply(trozos, `[[`, "", "tipo")))
  geo_poligonos_validos(sf::st_sf(t, geometry = sf::st_sfc(lapply(trozos, `[[`, "geometry"), crs = crs)))
}

# Polígonos válidos y en MULTIPOLYGON (st_make_valid puede devolver colecciones con líneas).
geo_poligonos_validos <- function(x) {
  geom <- sf::st_geometry(x)
  malos <- !sf::st_is_valid(geom)
  if (any(malos)) {
    arreglados <- sf::st_collection_extract(sf::st_make_valid(geom[malos]), "POLYGON", warn = FALSE)
    geom[malos] <- sf::st_cast(arreglados, "MULTIPOLYGON")
  }
  sf::st_set_geometry(x, sf::st_cast(geom, "MULTIPOLYGON"))
}

# Capas del mapa base en el CRS del seccionado (ETRS89 / UTM 30N): GDAL las pasa a Web Mercator
# al teselar. Atributos mínimos: el código y, salvo en las secciones, el nombre.
# sin_seccion: los huecos del seccionado (geo_huecos), con su superficie (`km2`) y los códigos de
# las provincias que tocan (`provincias`, separados por espacios). Los que tocan una sola
# provincia se suman a ella, y los que tocan una sola comunidad, a ella, para que sus bordes no
# los rodeen; los demás se quedan fuera de esas capas: sin la línea límite oficial, no se
# reparte suelo entre provincias por suposición. Con `unidades` (leer_ign_au()), van además, encima
# de los huecos enteros (sin nombre), sus trozos con el nombre y el tipo de la unidad del IGN
# (geo_nombrar_huecos); cada trozo, con su superficie y las provincias que toca él (las del hueco,
# si no toca ninguna). La web da el del trozo pulsado; fuera de los trozos, el del hueco.
geo_capas_mapa_base <- function(secciones, jerarquia, territorios, unidades = NULL,
                                umbral_km2 = UMBRAL_SIN_SECCION_KM2) {
  s <- secciones |>
    select(seccion) |>
    geo_poligonos_validos() |>
    left_join(select(jerarquia, seccion, municipio, provincia, ccaa), by = "seccion")
  disolver <- function(x, nivel) {
    x |>
      group_by(codigo = .data[[nivel]]) |>
      summarise(.groups = "drop") |>
      geo_poligonos_validos() |>
      left_join(territorios |> filter(nivel == !!nivel) |> select(codigo, nombre), by = "codigo")
  }
  municipios <- disolver(s, "municipio")
  municipios$provincia <- substr(municipios$codigo, 1, 2)
  municipios$ccaa <- jerarquia$ccaa[match(municipios$codigo, jerarquia$municipio)]
  provincias <- disolver(municipios, "provincia")
  provincias$ccaa <- jerarquia$ccaa[match(provincias$codigo, jerarquia$provincia)]

  huecos <- geo_huecos(provincias, umbral_km2)
  toca <- sf::st_is_within_distance(huecos, provincias, dist = 1)    # metros
  huecos$provincias <- vapply(toca, function(i) paste(sort(provincias$codigo[i]), collapse = " "), "")
  una <- function(x) if (length(x) == 1) x else NA_character_
  provincias <- geo_absorber_huecos(provincias, huecos, vapply(toca, function(i) una(provincias$codigo[i]), ""))
  comunidades <- disolver(provincias, "ccaa")
  a_comunidad <- vapply(toca, function(i) if (length(i) > 1) una(unique(provincias$ccaa[i])) else NA_character_, "")
  comunidades <- geo_absorber_huecos(comunidades, huecos, a_comunidad)
  sin_seccion <- select(huecos, km2, provincias)
  if (!is.null(unidades) && nrow(huecos)) {
    trozos <- geo_nombrar_huecos(sin_seccion, unidades, umbral_km2)
    cerca <- sf::st_is_within_distance(trozos, provincias, dist = 1)
    propias <- vapply(cerca, function(i) paste(sort(provincias$codigo[i]), collapse = " "), "")
    trozos$provincias <- ifelse(propias == "", trozos$provincias, propias)
    sin_seccion$nombre <- NA_character_
    sin_seccion$tipo <- NA_character_
    sin_seccion <- rbind(sin_seccion, select(trozos, km2, provincias, nombre, tipo))
  }
  list(
    comunidades = select(comunidades, ccaa = codigo, nombre),
    provincias  = select(provincias, provincia = codigo, nombre),
    municipios  = select(municipios, municipio = codigo, nombre),
    secciones   = select(s, seccion),
    sin_seccion = sin_seccion
  )
}

# PMTiles con GDAL (ogr2ogr): las capas pasan por un GeoPackage temporal para ir todas a un
# solo fichero, cada una con sus zooms (opción CONF). `simplificacion`: tolerancia de
# Douglas-Peucker en unidades de la rejilla de la tesela (EXTENT = 4096 por tesela de 512 px:
# 1 unidad = 1/8 de píxel). `simplificacion_zoom_max`: la del zoom máximo (en GDAL,
# SIMPLIFICATION_MAX_ZOOM es una tolerancia, no un zoom). Por defecto 0: las teselas del zoom
# máximo solo se cuantifican, porque MapLibre las amplía en los zooms siguientes y cualquier
# simplificación se vería allí como cuñas entre secciones vecinas. Con toda España (8-nov-2026):
# 44,4 MB con 1; 39,3 MB con 2; 35,2 MB con 4 (medio píxel, sin costuras visibles entre vecinas
# ni ampliando hasta casi el zoom siguiente) y teselas de los zooms 5 a 7 un 35 % más ligeras.
generar_pmtiles <- function(capas, ruta, zooms = ZOOMS_MAPA_BASE, simplificacion = 4, simplificacion_zoom_max = 0,
                            nombre = "seccionado_2021", descripcion = "") {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  gpkg <- tempfile(fileext = ".gpkg")
  conf <- tempfile(fileext = ".json")
  on.exit(unlink(c(gpkg, conf)), add = TRUE)
  for (capa in names(capas)) sf::st_write(capas[[capa]], gpkg, layer = capa, quiet = TRUE)
  zooms <- zooms[names(capas)]
  jsonlite::write_json(lapply(zooms, function(z) list(minzoom = z[1], maxzoom = z[2])), conf, auto_unbox = TRUE)
  zmin <- min(vapply(zooms, `[`, 1L, 1L))
  zmax <- max(vapply(zooms, `[`, 1L, 2L))
  if (file.exists(ruta)) unlink(ruta)
  sf::gdal_utils("vectortranslate", gpkg, ruta, options = c(
    "-f", "PMTiles",
    "-dsco", paste0("NAME=", nombre),
    "-dsco", paste0("DESCRIPTION=", descripcion),
    "-dsco", paste0("MINZOOM=", zmin),
    "-dsco", paste0("MAXZOOM=", zmax),
    "-dsco", paste0("CONF=", conf),
    "-dsco", paste0("SIMPLIFICATION=", simplificacion),
    "-dsco", paste0("SIMPLIFICATION_MAX_ZOOM=", simplificacion_zoom_max)
  ))
  if (!file.exists(ruta)) stop("GDAL no ha escrito ", ruta, call. = FALSE)
  ruta
}

# Compuertas del mapa base, con las teselas del zoom máximo (las que MapLibre amplía después),
# leídas con GDAL:
#   mapa_base_secciones (bloqueo): secciones del seccionado que no están en las teselas.
#   mapa_base_huecos (alerta): número y superficie de los huecos del seccionado (geo_huecos),
#     calculados aquí desde las secciones, por provincia y luego juntas.
#   mapa_base_sin_seccion (bloqueo): huecos que siguen abiertos con las secciones y la capa
#     sin_seccion juntas. La capa llega cuantificada a la rejilla de la tesela (4.096 unidades):
#     se ensancha una unidad para que esa cuantización no abra rendijas.
# Con `unidades` (leer_ign_au()), los nombres del IGN, recalculados aquí (geo_nombrar_huecos):
#   mapa_base_huecos (alerta), dos filas más: huecos con nombre y superficie con nombre (km2).
#   mapa_base_nombres (bloqueo): trozos con nombre que no lo llevan, con su tipo, en la capa
#     sin_seccion (en su punto interior, a una unidad de la rejilla).
#   mapa_base_nombres_dobles (bloqueo): superficie de los huecos con dos unidades del IGN a la vez.
# `secciones`: el seccionado (sf, con `seccion`), o solo sus códigos para la primera.
comprobar_mapa_base <- function(ruta, secciones, unidades = NULL, umbral_km2 = UMBRAL_SIN_SECCION_KM2) {
  cab <- pmtiles_cabecera(ruta)
  zoom <- paste0("ZOOM_LEVEL=", cab$zoom_max)
  codigos <- if (inherits(secciones, "sf")) secciones$seccion else secciones
  teselas <- suppressWarnings(sf::st_read(ruta, query = "SELECT seccion FROM secciones", options = zoom, quiet = TRUE))
  faltan <- setdiff(codigos, teselas$seccion)
  filas <- tibble::tibble(id = "mapa_base_secciones", detalle = paste(utils::head(faltan, 5), collapse = " "),
                          calculado = length(faltan), referencia = 0)
  if (!inherits(secciones, "sf")) return(filas)

  provincias <- secciones |>
    select(seccion) |>
    geo_poligonos_validos() |>
    group_by(provincia = substr(seccion, 1, 2)) |>
    summarise(.groups = "drop")
  huecos <- geo_huecos(provincias, umbral_km2)
  mayor <- if (nrow(huecos)) sprintf("%.1f", max(huecos$km2)) else "0"
  capa <- tryCatch(suppressWarnings(sf::st_read(ruta, layer = "sin_seccion", options = zoom, quiet = TRUE)),
                   error = function(e) NULL)
  unidad <- 2 * pi * 6378137 / 2^cab$zoom_max / 4096
  geom_capa <- if (is.null(capa) || !nrow(capa)) NULL else
    sf::st_geometry(geo_poligonos_validos(sf::st_transform(capa, sf::st_crs(provincias))))
  cubierta <- if (is.null(capa) || !nrow(capa)) sf::st_sfc(crs = sf::st_crs(provincias)) else {
    sf::st_buffer(sf::st_union(geom_capa), unidad)
  }
  abiertos <- geo_huecos(c(sf::st_geometry(provincias), cubierta), umbral_km2)
  centro <- function(h) {
    if (!nrow(h)) return("")
    p <- sf::st_coordinates(sf::st_transform(sf::st_point_on_surface(sf::st_geometry(h)), 4326))
    paste(utils::head(sprintf("%.3f,%.3f", p[, 1], p[, 2]), 5), collapse = " ")
  }
  filas <- bind_rows(filas, tibble::tibble(
    id = c("mapa_base_huecos", "mapa_base_huecos", "mapa_base_sin_seccion"),
    detalle = c(paste0("n\u00famero (el mayor, ", mayor, " km2)"), "superficie (km2)",
                paste("huecos sin cubrir (lon,lat):", centro(abiertos))),
    calculado = c(nrow(huecos), as.numeric(sprintf("%.1f", sum(huecos$km2))), nrow(abiertos)),
    referencia = 0
  ))
  if (is.null(unidades)) return(filas)

  trozos <- geo_nombrar_huecos(huecos, unidades, umbral_km2)
  con <- trozos[!is.na(trozos$nombre), ]
  union_con <- sum(as.numeric(sf::st_area(sf::st_union(sf::st_geometry(con))))) / 1e6
  dobles <- if (nrow(con)) sum(as.numeric(sf::st_area(con))) / 1e6 - union_con else 0
  clave <- function(n, t) paste(n, t, sep = " | ")
  en_capa <- if (is.null(capa) || !nrow(capa) || is.null(capa$nombre)) rep(NA_character_, NROW(capa)) else
    clave(capa$nombre, capa$tipo)
  puntos <- sf::st_point_on_surface(sf::st_geometry(con))
  cerca <- if (is.null(geom_capa)) rep(list(integer()), nrow(con)) else
    sf::st_is_within_distance(puntos, geom_capa, unidad)
  claves <- clave(con$nombre, con$tipo)
  falta <- !vapply(seq_along(claves), function(k) claves[k] %in% en_capa[cerca[[k]]], TRUE)
  bind_rows(filas, tibble::tibble(
    id = c("mapa_base_huecos", "mapa_base_huecos", "mapa_base_nombres", "mapa_base_nombres_dobles"),
    detalle = c("con nombre del IGN", "superficie con nombre del IGN (km2)",
                paste0("trozos con nombre del IGN que no lo llevan en la capa (de ", nrow(con), "): ",
                       paste(utils::head(con$nombre[falta], 3), collapse = "; ")),
                "superficie con dos unidades del IGN a la vez (km2)"),
    calculado = c(length(unique(con$hueco)), as.numeric(sprintf("%.1f", sum(con$km2))), sum(falta),
                  as.numeric(sprintf("%.2f", dobles))),
    referencia = 0
  ))
}

# --- Lectura del PMTiles (formato v3) para medirlo ---------------------------------------------

# Enteros sin signo de 64 bits (little endian) desde bytes; exactos hasta 2^53.
pmtiles_u64 <- function(b) sum(as.numeric(b) * 256^(seq_along(b) - 1))

pmtiles_cabecera <- function(ruta) {
  con <- file(ruta, "rb")
  on.exit(close(con))
  b <- readBin(con, "raw", 127L)
  if (length(b) < 127L || rawToChar(b[1:7]) != "PMTiles") stop(ruta, " no es un PMTiles", call. = FALSE)
  u <- function(desde) pmtiles_u64(b[desde + 1:8])            # `desde`: posicion en base 0
  i32 <- function(desde) readBin(b[desde + 1:4], "integer", size = 4L, endian = "little")
  list(
    version = as.integer(b[8]),
    raiz = c(u(8), u(16)), metadatos = c(u(24), u(32)), hojas = c(u(40), u(48)), datos = c(u(56), u(64)),
    teselas = u(72), entradas = u(80), contenidos = u(88),
    compresion_interna = as.integer(b[98]), compresion_teselas = as.integer(b[99]), tipo = as.integer(b[100]),
    zoom_min = as.integer(b[101]), zoom_max = as.integer(b[102]),
    limites = c(i32(102), i32(106), i32(110), i32(114)) / 1e7
  )
}

# Todos los varint (LEB128 sin signo) seguidos de un vector de bytes.
pmtiles_varints <- function(r) {
  x <- as.integer(r)
  fin <- which(x < 128L)
  if (!length(fin)) return(numeric())
  inicio <- c(1L, utils::head(fin, -1L) + 1L)
  grupo <- rep(seq_along(fin), fin - inicio + 1L)
  x <- x[seq_len(max(fin))]
  posicion <- seq_along(x) - inicio[grupo]
  as.numeric(rowsum((x %% 128L) * 128^posicion, grupo))
}

pmtiles_descomprimir <- function(r, compresion) {
  if (compresion == 1L) return(r)                              # sin comprimir
  if (compresion != 2L) stop("Compresion del PMTiles no admitida: ", compresion, call. = FALSE)
  con <- gzcon(rawConnection(r))
  on.exit(close(con))
  partes <- list()
  repeat {
    trozo <- readBin(con, "raw", 1e6)
    if (!length(trozo)) break
    partes[[length(partes) + 1L]] <- trozo
  }
  unlist(partes)
}

# Directorio (ya descomprimido) → tabla de entradas: id de tesela, repeticiones, posición y
# longitud. Las entradas con 0 repeticiones apuntan a un directorio hoja.
pmtiles_directorio <- function(r) {
  v <- pmtiles_varints(r)
  n <- v[1]
  if (n == 0) return(tibble::tibble(id = numeric(), repeticiones = numeric(), posicion = numeric(), longitud = numeric()))
  id <- cumsum(v[1 + seq_len(n)])
  repeticiones <- v[1 + n + seq_len(n)]
  longitud <- v[1 + 2 * n + seq_len(n)]
  bruto <- v[1 + 3 * n + seq_len(n)]
  posicion <- numeric(n)
  for (i in seq_len(n)) {
    posicion[i] <- if (i > 1 && bruto[i] == 0) posicion[i - 1] + longitud[i - 1] else bruto[i] - 1
  }
  tibble::tibble(id = id, repeticiones = repeticiones, posicion = posicion, longitud = longitud)
}

# Nivel de zoom de un id de tesela: los ids del zoom z empiezan en (4^z - 1) / 3.
pmtiles_zoom <- function(id) findInterval(id, (4^(0:31) - 1) / 3) - 1L

# Todas las entradas de teselas (con los directorios hoja resueltos).
pmtiles_entradas <- function(ruta) {
  cab <- pmtiles_cabecera(ruta)
  con <- file(ruta, "rb")
  on.exit(close(con))
  leer <- function(desde, n) {
    seek(con, desde)
    pmtiles_descomprimir(readBin(con, "raw", n), cab$compresion_interna)
  }
  pendientes <- list(pmtiles_directorio(leer(cab$raiz[1], cab$raiz[2])))
  teselas <- list()
  while (length(pendientes)) {
    d <- pendientes[[1]]
    pendientes <- pendientes[-1]
    teselas[[length(teselas) + 1L]] <- d[d$repeticiones > 0, ]
    for (i in which(d$repeticiones == 0)) {
      pendientes[[length(pendientes) + 1L]] <- pmtiles_directorio(leer(cab$hojas[1] + d$posicion[i], d$longitud[i]))
    }
  }
  bind_rows(teselas)
}

# Teselas y bytes (comprimidos, lo que viaja por la red) por nivel de zoom.
pmtiles_resumen <- function(ruta) {
  pmtiles_entradas(ruta) |>
    mutate(zoom = pmtiles_zoom(id)) |>
    group_by(zoom) |>
    summarise(teselas = sum(repeticiones), bytes = sum(longitud), bytes_max = max(longitud),
              bytes_medio = sum(longitud) / sum(repeticiones), .groups = "drop")
}
