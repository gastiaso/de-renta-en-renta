# Fuente catastro_foral: edificios de los catastros forales (INSPIRE, servicios ATOM de las
# diputaciones forales de Álava, Bizkaia y Gipuzkoa y del Gobierno de Navarra). Completa la vía (b)
# de las tablas de paso (plan §6.3) donde no llega el Catastro estatal (fuente_catastro_inspire.R):
# cada edificio con su número de viviendas y su año de construcción, asignado a las secciones por
# su posición. Licencias distintas por territorio; se tratan como datos abiertos (decisión del
# autor, 8-nov-2026; inventario/fuentes.csv).
#   Álava y Gipuzkoa: un zip del territorio entero (el de Álava, con un GML por municipio).
#   Bizkaia y Navarra: un zip por municipio, con el código del INE en el nombre (Navarra, sin ceros
#   delante). Usansolo (48916, segregado de Galdakao en 2022) no tiene zip: va en el de Galdakao.

# Zips del territorio entero (Álava: el de ETRS89 / UTM 30N, el sistema de las secciones).
ZIPS_CATASTRO_FORAL <- c(
  "01" = "https://geo.araba.eus/deskargak/INSPIRE/BU/GML/25830/BU_25830_GML.zip",
  "20" = "https://b5m.gipuzkoa.eus/inspire/download/GML/ES.GFA.BU.zip"
)

# Feeds ATOM con un zip por municipio y el patrón que saca el código del municipio de cada enlace.
FEEDS_CATASTRO_FORAL <- tibble::tribble(
  ~provincia, ~feed,                                                                             ~patron,
  "48", "https://apli.bizkaia.eus/apps/Danok/INSPIRE/buildings.xml",                               "ES\\.BFA\\.BU\\.(\\d+)\\.zip$",
  "31", paste0("https://filescartografia.navarra.es/2_CARTOGRAFIA_TEMATICA/2_7_CATASTRO/",
               "2_7_3_INSPIRE_ATOM/2_7_3_2_BU/Buildings_ServiceATOM_Navarra.xml"),                 "BU_Navarra_(\\d+)\\.gml\\.zip$"
)

# Enlaces de un feed con su municipio del INE (provincia + código de 3 dígitos del enlace).
zips_feed_foral <- function(xml, provincia, patron) {
  urls <- unique(regmatches(xml, gregexpr("https://[^\"<]+\\.zip", xml))[[1]])
  urls <- urls[grepl(patron, urls)]
  tibble::tibble(provincia = provincia,
                 municipio = paste0(provincia, sprintf("%03d", as.integer(sub(paste0(".*", patron), "\\1", urls)))),
                 url = urls)
}

# Zips forales de las provincias pedidas: una fila por zip; `municipio` NA en los del territorio
# entero.
zips_catastro_forales <- function(provincias, pausa = 0.3) {
  provincias <- intersect(provincias, PROVINCIAS_FORALES)
  enteros <- tibble::tibble(provincia = names(ZIPS_CATASTRO_FORAL), municipio = NA_character_,
                            url = unname(ZIPS_CATASTRO_FORAL)) |>
    filter(provincia %in% provincias)
  f <- filter(FEEDS_CATASTRO_FORAL, provincia %in% provincias)
  por_municipio <- bind_rows(lapply(seq_len(nrow(f)), function(i) {
    Sys.sleep(pausa)
    xml <- httr2::request(f$feed[i]) |>
      httr2::req_user_agent("Mozilla/5.0 (compatible; de-renta-en-renta; R httr2)") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform() |> httr2::resp_body_string(encoding = "UTF-8")
    zips_feed_foral(xml, f$provincia[i], f$patron[i])
  }))
  bind_rows(enteros, por_municipio)
}

# Zips que hacen falta para unos municipios forales: el del territorio entero si alguno es de
# Álava o Gipuzkoa; el de cada municipio en Bizkaia y Navarra. Avisa de los que no tienen zip
# propio (Usansolo, dentro del de Galdakao).
seleccionar_zips_forales <- function(zips, municipios) {
  provincias <- unique(substr(municipios, 1, 2))
  sel <- filter(zips, provincia %in% provincias, is.na(municipio) | municipio %in% municipios)
  con_zip <- municipios[substr(municipios, 1, 2) %in% sel$provincia[is.na(sel$municipio)] |
                          municipios %in% sel$municipio]
  sin_zip <- setdiff(municipios, con_zip)
  if (length(sin_zip)) {
    message("Municipios forales sin zip propio (sus edificios, si están, van en el de un vecino): ",
            paste(sin_zip, collapse = ", "))
  }
  unique(sel$url)
}

descargar_catastro_foral <- function(url, dir = file.path("datos", "brutos", "catastro_foral"), forzar = FALSE) {
  descargar_con_cache(url, file.path(dir, basename(url)), forzar)
}

# Año de una columna de fechas: texto («2000-01-01T01:00:00Z», «1976»), fecha o fecha y hora (en
# su propia zona horaria, para que el 1 de enero no pase al año anterior).
anio_de_fecha <- function(x) {
  if (inherits(x, "POSIXt")) return(as.integer(as.POSIXlt(x)$year + 1900L))
  if (inherits(x, "Date")) return(as.integer(format(x, "%Y")))
  suppressWarnings(as.integer(substr(as.character(x), 1, 4)))
}

# Año de construcción: cada territorio lo pone en una parte de dateOfConstruction/DateOfEvent
# (Navarra, «beginning» y «end»; Bizkaia y Gipuzkoa, «end», con «beginning» vacío o ausente;
# Álava, «anyPoint»). Se toma la primera que tenga valor. La fecha de reforma de Álava
# («dateOfRenovation.DateOfEvent.anyPoint») tiene otro nombre y no entra.
anio_construccion_foral <- function(e, columnas = c("beginning", "end", "anyPoint", "dateOfConstruction")) {
  anio <- rep(NA_integer_, nrow(e))
  for (col in intersect(columnas, names(e))) {
    falta <- is.na(anio)
    anio[falta] <- anio_de_fecha(e[[col]])[falta]
  }
  anio
}

# Punto dentro de cada polígono calculado en un sistema proyectado (backlog, tarea 55). Con
# longitud y latitud, sf::st_point_on_surface() trabaja con los grados como si fueran metros y
# avisa («st_point_on_surface may not give correct results for longitude/latitude data»): lo hacen
# los GML de Bizkaia y Navarra, en ETRS89 geográficas (EPSG:4258). Aquí la geometría pasa a
# ETRS89 / UTM 30N (EPSG:25830, el sistema de las secciones), se toma el punto y vuelve a su
# sistema. Con un sistema proyectado, es sf::st_point_on_surface() sin más.
# PREPARADA, SIN USAR: leer_catastro_foral() la usaría en lugar de sf::st_point_on_surface(), pero
# cambiar esa función rehace edificios_foral y lo que cuelga de ella (docs/actualizacion.md,
# «Avisos de tar_make()»). Lo decide el autor.
punto_interior <- function(geometria, crs_plano = 25830) {
  if (!isTRUE(sf::st_is_longlat(geometria))) return(sf::st_point_on_surface(geometria))
  crs <- sf::st_crs(geometria)
  sf::st_transform(sf::st_point_on_surface(sf::st_transform(geometria, crs_plano)), crs)
}

# Edificios con viviendas de un zip foral, como leer_catastro_edificios() (que no se toca para no
# releer los zips del Catastro estatal): un punto dentro de cada edificio, viviendas y año de
# construcción. Lee todos los GML del zip (Álava: uno por municipio).
leer_catastro_foral <- function(zip) {
  contenido <- utils::unzip(zip, list = TRUE)$Name
  gml <- contenido[grepl("\\.gml$", contenido, ignore.case = TRUE)]
  if (length(gml) == 0) stop("No encuentro ningún GML en ", zip, call. = FALSE)
  partes <- lapply(gml, function(g) {
    e <- sf::st_read(paste0("/vsizip/", normalizePath(zip, winslash = "/"), "/", g), quiet = TRUE)
    viviendas <- suppressWarnings(as.numeric(e$numberOfDwellings))
    con_viviendas <- !is.na(viviendas) & viviendas > 0
    e <- e[con_viviendas, ]
    sf::st_sf(viviendas = viviendas[con_viviendas],
              anio_construccion = anio_construccion_foral(e),
              geometry = sf::st_point_on_surface(sf::st_make_valid(sf::st_geometry(e))))
  })
  do.call(rbind, partes)
}
