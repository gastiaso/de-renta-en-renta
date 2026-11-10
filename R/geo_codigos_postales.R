# Tabla de paso código postal ↔ municipio (F4; plan §7 y pregunta abierta 16), desde el callejero
# del censo electoral del INE de enero de 2021 (el del seccionado de referencia), aplicación nueva:
# cada tramo de vía lleva su sección y su código postal (columnas 43–47 del registro). No hay
# polígonos oficiales de los códigos postales que se puedan reutilizar: la correspondencia se
# mide en tramos de vía. Un código postal puede repartirse entre varios municipios; `peso` es la
# parte de sus tramos en cada uno y `principal` marca el municipio con más tramos.
# Sirve para llevar a municipio una fuente publicada por código postal (como el Notariado, si
# llega a poder reutilizarse) y para buscar por código postal en la web.

# Tramos por sección y código postal de toda España: seccion, cp, tramos. Lee el fichero por
# trozos y agrega cada uno, para no tener las 1,5 millones de líneas en memoria.
leer_ine_callejero_cp <- function(zip, fichero = FICHEROS_TRAMOS[["nueva_2021"]]) {
  temporal <- tempfile("callejero_cp_")
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
    interno <- extraer(zip, patron_zip_interno(fichero))
    if (!is.null(interno)) texto <- extraer(interno, fichero)
  }
  if (is.null(texto)) stop("No encuentro el fichero de tramos ", fichero, " en ", zip, call. = FALSE)
  trozos <- readr::read_lines_chunked(
    texto,
    readr::ListCallback$new(function(x, pos) {
      dplyr::count(tibble::tibble(seccion = substr(x, 1, 10), cp = substr(x, 43, 47)), seccion, cp, name = "tramos")
    }),
    chunk_size = 200000L, locale = readr::locale(encoding = "latin1"), progress = FALSE)
  dplyr::bind_rows(trozos) |>
    dplyr::group_by(seccion, cp) |>
    dplyr::summarise(tramos = sum(tramos), .groups = "drop")
}

# Un código postal válido: cinco cifras que empiezan por una provincia (01 a 52).
cp_valido <- function(cp) grepl("^[0-9]{5}$", cp) & substr(cp, 1, 2) >= "01" & substr(cp, 1, 2) <= "52"

# Código postal ↔ municipio: cp, municipio, tramos, peso (% de los tramos del código postal) y
# principal. Fuera, los tramos sin código postal válido (vacío, «00000» o con un prefijo que no
# es una provincia, como «00040»).
geo_tabla_cp_municipio <- function(tramos_cp) {
  tramos_cp |>
    dplyr::filter(cp_valido(cp)) |>
    dplyr::mutate(municipio = substr(seccion, 1, 5)) |>
    dplyr::group_by(cp, municipio) |>
    dplyr::summarise(tramos = sum(tramos), .groups = "drop") |>
    dplyr::group_by(cp) |>
    dplyr::mutate(peso = 100 * tramos / sum(tramos),
                  principal = dplyr::row_number(dplyr::desc(tramos)) == 1L) |>
    dplyr::ungroup() |>
    dplyr::arrange(cp, dplyr::desc(tramos), municipio)
}

# Compuerta de la tabla de paso (inventario/referencias_validacion.csv):
#   cp_municipio_codigos (bloqueo): municipios de la tabla que no están en la jerarquía del
#     seccionado de 2021;
#   cp_municipio_reparto (bloqueo): diferencia máxima entre 100 y la suma de los pesos de un código
#     postal, y códigos postales sin un municipio principal (o con más de uno);
#   cp_municipio_provincia (alerta): pares cuyo código postal no empieza por la provincia del municipio;
#   cp_municipio_cobertura (alerta): municipios de la jerarquía sin ningún código postal, y
#     tramos sin código postal.
comprobar_cp_municipio <- function(tabla, tramos_cp, territorios) {
  municipios <- territorios$codigo[territorios$nivel == "municipio"]
  por_cp <- tabla |> dplyr::group_by(cp) |>
    dplyr::summarise(suma = sum(peso), principales = sum(principal), .groups = "drop")
  sin_cp <- sum(tramos_cp$tramos[!cp_valido(tramos_cp$cp)])
  tibble::tibble(
    id = c("cp_municipio_codigos", "cp_municipio_reparto", "cp_municipio_reparto", "cp_municipio_provincia",
           "cp_municipio_cobertura", "cp_municipio_cobertura"),
    anio = NA_integer_,
    detalle = c("municipios fuera de la jerarqu\u00eda", "suma de pesos (diferencia m\u00e1xima con 100)",
                "c\u00f3digos postales sin un \u00fanico principal", "pares de otra provincia",
                "municipios sin c\u00f3digo postal", "tramos sin c\u00f3digo postal"),
    calculado = c(sum(!unique(tabla$municipio) %in% municipios), max(abs(por_cp$suma - 100)),
                  sum(por_cp$principales != 1), sum(substr(tabla$cp, 1, 2) != substr(tabla$municipio, 1, 2)),
                  sum(!municipios %in% tabla$municipio), sin_cp),
    referencia = 0
  )
}

# Resumen para el informe: códigos postales, pares, códigos de un solo municipio y peso del principal.
resumen_cp_municipio <- function(tabla) {
  por_cp <- tabla |> dplyr::group_by(cp) |> dplyr::summarise(n = dplyr::n(), principal = max(peso), .groups = "drop")
  tibble::tibble(codigos_postales = nrow(por_cp), pares = nrow(tabla), municipios = dplyr::n_distinct(tabla$municipio),
                 un_municipio = sum(por_cp$n == 1), peso_principal_mediana = stats::median(por_cp$principal))
}

exportar_cp_municipio <- function(tabla, ruta = file.path("geo", "codigos_postales_2021.csv")) {
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(dplyr::mutate(tabla, peso = as.numeric(sprintf("%.3f", peso))), ruta, na = "")
  ruta
}
