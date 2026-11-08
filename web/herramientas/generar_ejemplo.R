# Muestra de la web: geometría real, valores inventados.
#
# Genera en web/datos/ejemplo/ los ficheros con que el esqueleto de la web funciona mientras
# no exista la exportación del pipeline (web/datos/manifiesto.json y web/teselas/):
#   - secciones.geojson   secciones del distrito Centro de Madrid (seccionado de 2021, INE),
#                         con los nombres de capa y de propiedad del mapa base (`seccion`)
#   - provincias.geojson  contorno de la provincia de Madrid (fondo provisional)
#   - secciones.json      índice: códigos de sección en el orden de los valores
#   - territorios.json    nombres de municipio, provincia y comunidad
#   - sc/alquiler_m2/<año>.json   valores INVENTADOS de 2020 a 2024, uno por año
#   - fichas/28079.json   series de cada sección para la ficha (todas son de Madrid)
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
dir.create(file.path(salida, "fichas"), showWarnings = FALSE)

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

# Índice de secciones (el orden de los valores) y nombres de los territorios.
jsonlite::write_json(secciones$seccion, file.path(salida, "secciones.json"))
territorios <- list(
  municipio = stats::setNames(as.list(unique(centro$NMUN)), unique(centro$CUMUN)),
  provincia = stats::setNames(as.list(unique(centro$NPRO)), unique(centro$CPRO)),
  ccaa = stats::setNames(as.list(unique(centro$NCA)), unique(centro$CCA))
)
jsonlite::write_json(territorios, file.path(salida, "territorios.json"), auto_unbox = TRUE, pretty = TRUE)

# Valores INVENTADOS de alquiler por m² (€/m²/mes), 2020-2024: un punto de partida aleatorio
# entre 11 y 26 y una subida anual aleatoria del 0 al 6 %. Estados (0 dato, 1 estimado,
# 2 secreto, 3 ausente): cuatro secciones en secreto todos los años y algún hueco suelto.
set.seed(20261108)
n <- nrow(secciones)
anios <- 2020:2024
inicio <- runif(n, 11, 26)
subida <- runif(n, 0, 0.06)
valor <- sapply(seq_along(anios), function(k) as.numeric(sprintf("%.1f", inicio * (1 + subida)^(k - 1))))
estado <- matrix(sample(0:1, n * length(anios), replace = TRUE, prob = c(0.85, 0.15)), n)
estado[sample(n, 4), ] <- 2L
huecos <- cbind(sample(which(estado[, 1] != 2L), 6), sample(seq_along(anios), 6, replace = TRUE))
estado[huecos] <- 3L
valor[estado >= 2L] <- NA

# Formato de la web (plan, §6.6): {"v": [valor × 10 en enteros, null sin valor], "e": "0012…"},
# en el orden del índice; un carácter de estado por territorio. I() impide que jsonlite
# convierta en escalar un vector de longitud 1.
por_diez <- function(x) {
  y <- rep(NA_integer_, length(x))
  y[!is.na(x)] <- as.integer(sprintf("%.0f", x[!is.na(x)] * 10))
  y
}
codificar <- function(x, e) list(v = I(por_diez(x)), e = paste(e, collapse = ""))
escribir_json <- function(x, ruta) jsonlite::write_json(x, ruta, auto_unbox = TRUE, na = "null", digits = NA)

for (k in seq_along(anios)) {
  escribir_json(codificar(valor[, k], estado[, k]),
                file.path(salida, "sc", "alquiler_m2", sprintf("%d.json", anios[k])))
}

# Series de la ficha, un fichero por municipio: {"municipio", "anios": {indicador: [años]},
# "series": {sección: {indicador: {"v", "e"}}}}, con los años en el orden de "anios".
series <- stats::setNames(lapply(seq_len(n), function(i) list(alquiler_m2 = codificar(valor[i, ], estado[i, ]))),
                          secciones$seccion)
escribir_json(list(municipio = "28079", anios = list(alquiler_m2 = I(anios)), series = series),
              file.path(salida, "fichas", "28079.json"))

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
  fichas = "datos/ejemplo/fichas/{municipio}.json",
  codificacion = list(escala = 10L, estados = c("dato", "estimado", "secreto", "ausente")),
  supuestos = list(superficie_m2 = 50L, umbral = 0.30),
  indicadores = list(
    alquiler_m2 = list(nivel = "sc", anios = I(anios), ruta = "datos/ejemplo/sc/alquiler_m2/{anio}.json")
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
message(sprintf("Muestra en %s: %d secciones, %d años, %s KB.", salida, n, length(anios), sprintf("%.1f", sum(tam) / 1024)))
