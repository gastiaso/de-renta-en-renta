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
# ocupa unos píxeles; las capas de arriba sirven de contexto y de bordes.
ZOOMS_MAPA_BASE <- list(
  comunidades = c(0L, 12L),
  provincias  = c(3L, 12L),
  municipios  = c(5L, 12L),
  secciones   = c(7L, 12L)
)

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
geo_capas_mapa_base <- function(secciones, jerarquia, territorios) {
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
  comunidades <- disolver(provincias, "ccaa")
  list(
    comunidades = select(comunidades, ccaa = codigo, nombre),
    provincias  = select(provincias, provincia = codigo, nombre),
    municipios  = select(municipios, municipio = codigo, nombre),
    secciones   = select(s, seccion)
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

# Compuerta del mapa base (mapa_base_secciones): toda sección del seccionado está en las teselas
# del zoom máximo, las que MapLibre amplía después. Se leen con GDAL (unos segundos).
comprobar_mapa_base <- function(ruta, secciones_referencia) {
  cab <- pmtiles_cabecera(ruta)
  teselas <- suppressWarnings(sf::st_read(ruta, query = "SELECT seccion FROM secciones",
                                          options = paste0("ZOOM_LEVEL=", cab$zoom_max), quiet = TRUE))
  faltan <- setdiff(secciones_referencia, teselas$seccion)
  tibble::tibble(id = "mapa_base_secciones", detalle = paste(utils::head(faltan, 5), collapse = " "),
                 calculado = length(faltan), referencia = 0)
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
