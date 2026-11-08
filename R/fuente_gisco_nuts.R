# Fuente eurostat_nuts: geometrías NUTS de GISCO (paquete giscoR), una versión por fichero.
# Licencia: uso no comercial con el aviso «© EuroGeographics para los límites
# administrativos»; no entran en la licencia CC BY-SA 4.0 de los datos del atlas.

descargar_gisco_nuts <- function(version, dir = file.path("datos", "brutos", "gisco"), forzar = FALSE) {
  destino <- file.path(dir, sprintf("nuts_%s_20m_3035.gpkg", version))
  if (file.exists(destino) && !forzar) return(destino)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  nuts <- giscoR::gisco_get_nuts(year = version, epsg = 3035, resolution = 20, nuts_level = "all",
                                 cache_dir = dir, update_cache = forzar)
  if (is.null(nuts) || nrow(nuts) == 0) stop("GISCO no devuelve las NUTS ", version, call. = FALSE)
  sf::st_write(nuts, destino, delete_dsn = TRUE, quiet = TRUE)
  destino
}

# Versión NUTS de cada año de ilc_lvho07_r: NUTS 2021 hasta 2023 y NUTS 2024 desde 2024.
version_nuts <- function(anio) ifelse(anio >= 2024, "2024", "2021")

# Comprobación nuts_geometria: cada región con dato tiene geometría en la versión de su año.
# Devuelve una fila por año con el número de códigos sin geometría.
comprobar_geometrias_nuts <- function(europa, rutas_nuts) {
  codigos <- lapply(rutas_nuts, function(r) sf::st_drop_geometry(sf::st_read(r, quiet = TRUE))$NUTS_ID)
  reg <- filter(europa, conjunto == "ilc_lvho07_r") |> distinct(anio, geo)
  reg |>
    mutate(version = version_nuts(anio)) |>
    rowwise() |>
    mutate(sin_geometria = !geo %in% codigos[[version]]) |>
    ungroup() |>
    group_by(anio) |>
    summarise(calculado = sum(sin_geometria), faltan = paste(geo[sin_geometria], collapse = " "), .groups = "drop") |>
    transmute(id = "nuts_geometria", anio, detalle = if_else(faltan == "", "todas", faltan),
              calculado, referencia = 0)
}
