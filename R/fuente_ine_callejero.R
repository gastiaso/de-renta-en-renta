# Fuente ine_callejero: callejero del censo electoral del INE (enero y julio de cada año).
# Vía (a) de las tablas de paso: tramos de vía asignados a cada sección (plan, §6.3).
# `fecha` en formato MMAAAA, p. ej. "012021" para el 1 de enero de 2021.

url_ine_callejero <- function(fecha) {
  sprintf("https://www.ine.es/prodyser/callejero/caj_esp/caj_esp_%s.zip", fecha)
}

descargar_ine_callejero <- function(fecha, dir = file.path("datos", "brutos", "ine_callejero"),
                                    forzar = FALSE) {
  descargar_con_cache(url_ine_callejero(fecha), file.path(dir, sprintf("caj_esp_%s.zip", fecha)), forzar)
}

# Ficheros de tramos según la publicación. El INE cambió de aplicación en 2021: la
# publicación de enero de 2021 trae los tramos con las dos (antigua y nueva); desde
# entonces, solo con la nueva, que da números de portal reales en lugar de 0001–9999.
FICHEROS_TRAMOS <- c(
  antigua_2015 = "^TRAMOS-NAL\\.F\\d{6}$",
  antigua_2021 = "^TRAM-NAL\\.F\\d{6}$",
  nueva_2021   = "^GJCALLE\\.TRAM-NAL\\.F\\d{6}$",
  nueva_2022   = "^Tramero$",
  nueva_2025   = "^TRAM\\.P01-52\\.D\\d{6}\\.G\\d{6}$"
)

# Lee los tramos de una provincia. `fichero` es la expresión regular del fichero de tramos
# (FICHEROS_TRAMOS); puede venir suelto en el zip o dentro de un zip interno.
# Registro de ancho fijo: sección en 1–10, vía en 21–25, pseudovía en 26–30, código postal
# en 43–47, tipo de numeración en 48 (0 = sin número), primer número en 49–52, último en 54–57.
leer_ine_callejero <- function(zip, fichero, provincia) {
  temporal <- tempfile("callejero_")
  dir.create(temporal)
  on.exit(unlink(temporal, recursive = TRUE), add = TRUE)

  extraer <- function(zip, patron) {
    nombres <- utils::unzip(zip, list = TRUE)$Name
    elegido <- nombres[grepl(patron, basename(nombres))]
    if (length(elegido) != 1) return(NULL)
    utils::unzip(zip, files = elegido, exdir = temporal, junkpaths = TRUE)
    file.path(temporal, basename(elegido))
  }
  texto <- extraer(zip, fichero)
  if (is.null(texto)) {
    interno <- extraer(zip, sub("\\$$", "\\\\.zip$", fichero))
    if (!is.null(interno)) texto <- extraer(interno, fichero)
  }
  if (is.null(texto)) stop("No encuentro el fichero de tramos ", fichero, " en ", zip, call. = FALSE)

  lineas <- readr::read_lines_chunked(
    texto,
    readr::AccumulateCallback$new(function(x, pos, acc) c(acc, x[startsWith(x, provincia)]),
                                  acc = character()),
    chunk_size = 200000L,
    locale = readr::locale(encoding = "latin1"),
    progress = FALSE
  )
  if (length(lineas) == 0) stop("No hay tramos de la provincia ", provincia, " en ", zip, call. = FALSE)
  tibble::tibble(
    seccion   = substr(lineas, 1, 10),
    municipio = substr(lineas, 1, 5),
    via       = substr(lineas, 21, 25),
    pseudovia = substr(lineas, 26, 30),
    tinum     = suppressWarnings(as.integer(substr(lineas, 48, 48))),
    ein       = suppressWarnings(as.integer(substr(lineas, 49, 52))),
    esn       = suppressWarnings(as.integer(substr(lineas, 54, 57)))
  )
}
