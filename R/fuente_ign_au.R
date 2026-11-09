# Fuente ign_au: unidades administrativas del IGN (Base de Datos de Divisiones Administrativas de
# España, BDDAE), del servicio WFS INSPIRE de unidades administrativas. Solo las de los códigos 53
# (condominios: montes y terrenos de varios municipios, como facerías, parzonerías, ledanías o
# comunidades) y 54 (territorios que no son de ninguna provincia), en GeoJSON, guardadas en
# datos/brutos/ign_au/ (descarga del 9-nov-2026, aprobada por el autor). Sirven para nombrar el
# suelo sin sección del mapa base (geo_nombrar_huecos(), R/geo_mapa_base.R). Licencia: CC BY 4.0
# (Orden FOM/2807/2015).

IGN_AU_WFS <- "https://www.ign.es/wfs-inspire/unidades-administrativas"

# Tipo de unidad según el código nacional del IGN (34 + comunidad + provincia + municipio): en las
# posiciones 7 y 8, donde los municipios llevan su provincia, 53 marca un condominio y 54 un
# territorio que no es de ninguna provincia (plazas de soberanía, Gibraltar, isla de los Faisanes).
IGN_AU_TIPOS <- c("53" = "condominio", "54" = "territorio")

# Rutas de los GeoJSON. Descarga manual: si falta alguno, el proceso se detiene y dice cómo
# obtenerlo y con qué nombre guardarlo.
ficheros_ign_au <- function(dir = file.path("datos", "brutos", "ign_au"), codigos = names(IGN_AU_TIPOS)) {
  rutas <- file.path(dir, sprintf("territorios_%s.geojson", codigos))
  faltan <- rutas[!file.exists(rutas)]
  if (length(faltan)) {
    stop("Faltan las unidades administrativas del IGN: ", paste(faltan, collapse = ", "), ".\n",
         "Se descargan del WFS INSPIRE del IGN (", IGN_AU_WFS, "): GetFeature de au:AdministrativeUnit ",
         "en GeoJSON, con las unidades cuyo codigo nacional (nationalCode) lleva ese codigo en las ",
         "posiciones 7 y 8, y se guardan con ese nombre.", call. = FALSE)
  }
  rutas
}

# Unidades de uno o varios GeoJSON del WFS: código nacional (11 cifras), nombre oficial (el literal
# del IGN, con los identificadores numéricos que lleva alguno) y tipo (IGN_AU_TIPOS). En ETRS89
# geográficas (el GeoJSON las declara como WGS 84). Se detiene si alguna no tiene nombre o tipo.
leer_ign_au <- function(rutas) {
  partes <- lapply(rutas, function(ruta) {
    x <- sf::st_read(ruta, quiet = TRUE, options = "FLATTEN_NESTED_ATTRIBUTES=YES")
    nombre <- x[["name_GeographicalName_spelling_SpellingOfName_text"]]
    if (is.null(nombre)) stop("Sin nombres (name/GeographicalName/spelling) en ", ruta, call. = FALSE)
    sf::st_sf(codigo = as.character(x$nationalCode), nombre = trimws(as.character(nombre)),
              geometry = sf::st_geometry(x))
  })
  u <- do.call(rbind, partes)
  u$tipo <- unname(IGN_AU_TIPOS[substr(u$codigo, 7, 8)])
  malas <- u$codigo[is.na(u$tipo) | is.na(u$nombre) | u$nombre == "" | nchar(u$codigo) != 11L]
  if (length(malas)) stop("Unidades del IGN sin nombre o de tipo desconocido: ", paste(malas, collapse = " "),
                          call. = FALSE)
  if (anyDuplicated(u$codigo)) stop("Unidades del IGN repetidas", call. = FALSE)
  geo_poligonos_validos(u[order(u$codigo), c("codigo", "nombre", "tipo")])
}
