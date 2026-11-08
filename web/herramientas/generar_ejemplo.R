# Muestra de la web: geometría real, valores inventados.
#
# Genera en web/datos/ejemplo/ los ficheros con que el esqueleto de la web funciona mientras
# no exista la exportación del pipeline (web/datos/manifiesto.json y web/teselas/):
#   - secciones.geojson   secciones del distrito Centro de Madrid (seccionado de 2021, INE),
#                         con los nombres de capa y de propiedad del mapa base (`seccion`)
#   - provincias.geojson  contorno de la provincia de Madrid (fondo provisional)
#   - secciones.json      índice: códigos de sección en el orden de los binarios
#   - territorios.json    nombres de municipio, provincia y comunidad
#   - sc/alquiler_m2/2024.bin   valores INVENTADOS, con el formato propuesto para la web
#   - manifiesto.json     qué hay y dónde (mismo esquema que el manifiesto real)
#
# Los valores son de ejemplo (guía, regla 9): aleatorios, sin relación con la sección.
# No es parte del pipeline. Se ejecuta a mano desde la raíz del proyecto:
#   Rscript web/herramientas/generar_ejemplo.R
# Necesita datos/brutos/ine_seccionado/seccionado_2021.zip (descarga del pipeline).

suppressPackageStartupMessages(library(sf))

zip_2021 <- file.path("datos", "brutos", "ine_seccionado", "seccionado_2021.zip")
if (!file.exists(zip_2021)) stop("Falta ", zip_2021, ": se descarga con el pipeline (ine_seccionado).")
capa <- "SECC_CE_20210101"
dsn <- paste0("/vsizip/", zip_2021, "/Seccionado_2021/", capa, ".shp")
salida <- file.path("web", "datos", "ejemplo")
unlink(salida, recursive = TRUE)
dir.create(file.path(salida, "sc", "alquiler_m2"), recursive = TRUE, showWarnings = FALSE)

leer <- function(where) {
  st_read(dsn, quiet = TRUE,
          query = sprintf("SELECT CUSEC, CUMUN, CPRO, CCA, NMUN, NPRO, NCA FROM %s WHERE %s", capa, where))
}

# Secciones de Centro (Madrid, distrito 01), simplificadas a 2 m y en grados.
centro <- leer("CUMUN = '28079' AND CDIS = '01'")
centro <- centro[order(centro$CUSEC), ]
secciones <- st_simplify(centro, preserveTopology = TRUE, dTolerance = 2) |> st_transform(4326)
secciones <- st_sf(seccion = secciones$CUSEC, municipio = secciones$CUMUN, geometry = st_geometry(secciones))

# Fondo provisional: la provincia de Madrid disuelta y muy simplificada.
provincia <- leer("CPRO = '28'")
contorno <- st_union(st_buffer(provincia, 1)) |> st_simplify(dTolerance = 150) |> st_transform(4326)
provincias <- st_sf(provincia = "28", nombre = provincia$NPRO[1], geometry = contorno)

escribir_geojson <- function(x, ruta) {
  st_write(x, ruta, driver = "GeoJSON", quiet = TRUE,
           layer_options = c("COORDINATE_PRECISION=6", "RFC7946=YES", "WRITE_BBOX=NO"))
}
escribir_geojson(secciones, file.path(salida, "secciones.geojson"))
escribir_geojson(provincias, file.path(salida, "provincias.geojson"))

# Índice de secciones (el orden de los binarios) y nombres de los territorios.
jsonlite::write_json(secciones$seccion, file.path(salida, "secciones.json"))
territorios <- list(
  municipio = stats::setNames(as.list(unique(centro$NMUN)), unique(centro$CUMUN)),
  provincia = stats::setNames(as.list(unique(centro$NPRO)), unique(centro$CPRO)),
  ccaa = stats::setNames(as.list(unique(centro$NCA)), unique(centro$CCA))
)
jsonlite::write_json(territorios, file.path(salida, "territorios.json"), auto_unbox = TRUE, pretty = TRUE)

# Valores INVENTADOS de alquiler por m² (€/m²/mes): aleatorios entre 12 y 30.
# Binario: n enteros de 32 bits con signo, little-endian, valor × 10 (un decimal exacto;
# NA_integer_ = -2147483648 es el nulo), seguidos de n bytes de estado
# (0 dato, 1 estimado, 2 secreto, 3 ausente).
set.seed(20261108)
n <- nrow(secciones)
valor <- as.numeric(sprintf("%.1f", runif(n, 12, 30)))
estado <- sample(0:1, n, replace = TRUE, prob = c(0.85, 0.15))
estado[sample(n, 4)] <- 2L
estado[sample(which(estado != 2L), 2)] <- 3L
valor[estado >= 2L] <- NA
por_diez <- rep(NA_integer_, n)
por_diez[!is.na(valor)] <- as.integer(sprintf("%.0f", valor[!is.na(valor)] * 10))
con <- file(file.path(salida, "sc", "alquiler_m2", "2024.bin"), "wb")
writeBin(por_diez, con, size = 4, endian = "little")
writeBin(as.integer(estado), con, size = 1)
close(con)

caja <- as.numeric(st_bbox(secciones))
manifiesto <- list(
  version = "ejemplo",
  ejemplo = TRUE,
  generado = format(Sys.Date()),
  seccionado = 2021L,
  mapa_base = list(
    tipo = "geojson",
    atribucion = "INE",
    capas = list(
      provincias = list(url = "datos/ejemplo/provincias.geojson", id = "provincia"),
      secciones = list(url = "datos/ejemplo/secciones.geojson", id = "seccion")
    )
  ),
  secciones = "datos/ejemplo/secciones.json",
  territorios = "datos/ejemplo/territorios.json",
  binario = list(valor = "int32le_x10", estado = "uint8", nulo = -2147483648,
                 estados = c("dato", "estimado", "secreto", "ausente")),
  supuestos = list(superficie_m2 = 50L, umbral = 0.30),
  indicadores = list(
    alquiler_m2 = list(nivel = "sc", anios = list(2024L), ruta = "datos/ejemplo/sc/alquiler_m2/{anio}.bin")
  ),
  mapas = list(
    # formula: nombre de una transformación conocida por la web (js/formulas.js), no código.
    sueldo_necesario = list(base = "alquiler_m2", formula = "alquiler_m2_a_sueldo",
                            cortes = c(2600L, 3200L, 3800L, 4400L), decimales = 0L)
  ),
  vista_inicial = list(limites = round(caja, 5))
)
jsonlite::write_json(manifiesto, file.path(salida, "manifiesto.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

tam <- file.size(list.files(salida, recursive = TRUE, full.names = TRUE))
message(sprintf("Muestra en %s: %d secciones, %s KB.", salida, n, sprintf("%.1f", sum(tam) / 1024)))
