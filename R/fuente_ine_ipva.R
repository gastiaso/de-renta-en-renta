# INE, Índice de Precios de Vivienda en Alquiler (IPVA; indicador 10, F4). Estadística experimental,
# anual (mayo), con los alquileres declarados en el IRPF: índice (base 2015 = 100) desde 2011 y
# variación anual desde 2012. No cubre País Vasco ni Navarra (régimen foral). Cuatro tablas de
# INEbase, en CSV de jaxiT3 (TABLAS_IPVA): España y comunidades, provincias, municipios de más de
# 10.000 habitantes y distritos de las capitales de provincia, con el código del INE delante del
# nombre. El atlas toma la variación anual publicada (un índice no se agrega: regla 1), en total y
# en su nivel nativo, de 2015 a 2024. Los desgloses por tipo de edificación, tamaño y antigüedad
# del contrato (España, comunidades y provincias) no entran: la web no los distingue del total.
# Licencia: CC BY 4.0 (aviso legal del INE).

TABLAS_IPVA <- c(ccaa = "59056", provincia = "59058", municipio = "59060", distrito = "59061")
ANIOS_IPVA <- 2015:2024

descargar_ine_ipva <- function(id, dir = file.path("datos", "brutos", "ine_ipva"), forzar = FALSE) {
  descargar_con_cache(sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv?nocab=1", id),
                      file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Número del CSV de jaxiT3: coma decimal, punto de miles; «..» y vacío, NA.
numero_jaxi <- function(x) {
  x <- trimws(x)
  x[x %in% c("", "..", ".")] <- NA_character_
  suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE)))
}

# Una tabla del IPVA en formato ordenado: nivel, geo_id, territorio, tipologia (total, VC, VU),
# anio, medida (indice, variacion) y valor. El territorio es la columna con el código delante del
# nombre; sin código («Total Nacional»), España («00»). Se detiene si alguna serie no tiene todos
# los años: las descargas del INE pueden llegar cortadas sin dar error.
leer_ine_ipva <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- sub("^\ufeff", "", names(d))
  n <- ncol(d)
  i_dato <- grep("^Tipo de dato$", names(d))
  i_tipo <- grep("^Tipo de edificaci", names(d))
  if (length(i_dato) != 1) stop("Sin columna 'Tipo de dato' en ", ruta, call. = FALSE)
  # territorio: la columna anterior a las de medida con codigos delante del nombre
  candidatas <- setdiff(seq_len(i_dato - 1), i_tipo)
  terr <- d[[max(candidatas)]]
  if (length(candidatas) > 1) terr <- dplyr::coalesce(dplyr::na_if(terr, ""), d[[candidatas[1]]])
  terr <- trimws(dplyr::coalesce(terr, ""))
  # filas "Resto <provincia>" de la tabla de municipios: el resto de la provincia, sin codigo; no es
  # un territorio de la jerarquia y no entra
  resto <- grepl("^Resto ", terr)
  d <- d[!resto, ]
  terr <- terr[!resto]
  codigo <- ifelse(grepl("^[0-9]+ ", terr), sub(" .*$", "", terr), NA_character_)
  raros <- unique(terr[is.na(codigo) & !terr %in% c("", "Total Nacional")])
  if (length(raros)) stop("IPVA ", basename(ruta), ": territorios sin c\u00f3digo: ", paste(utils::head(raros, 5), collapse = ", "),
                          call. = FALSE)
  nivel <- dplyr::case_when(is.na(codigo) ~ "nacional", nchar(codigo) == 7 ~ "distrito",
                            nchar(codigo) == 5 ~ "municipio", TRUE ~ NA_character_)
  if (any(is.na(nivel))) {
    nivel[is.na(nivel)] <- if (grepl("Provincias", paste(names(d), collapse = " "))) "provincia" else "ccaa"
  }
  tipologia <- if (length(i_tipo)) {
    dplyr::case_when(grepl("colectiva", d[[i_tipo]]) ~ "VC", grepl("unifamiliar", d[[i_tipo]]) ~ "VU", TRUE ~ "total")
  } else "total"
  x <- tibble::tibble(
    nivel = nivel, geo_id = ifelse(is.na(codigo), "00", codigo),
    territorio = ifelse(is.na(codigo), "Total Nacional", sub("^[0-9]+ ", "", terr)),
    tipologia = tipologia,
    anio = as.integer(d[[n - 1]]),
    medida = ifelse(grepl("ndice", d[[i_dato]]), "indice", "variacion"),
    valor = numero_jaxi(d[[n]])
  )
  anios <- sort(unique(x$anio))
  por_serie <- dplyr::count(x, nivel, geo_id, tipologia, medida)
  if (any(por_serie$n != length(anios))) {
    stop("IPVA ", basename(ruta), ": ", sum(por_serie$n != length(anios)), " series sin todos los a\u00f1os (",
         min(anios), "-", max(anios), "). \u00bfDescarga cortada? B\u00f3rrala y vuelve a bajarla.", call. = FALSE)
  }
  x
}

# Las cuatro tablas juntas, con la tabla de origen. `rutas`: con nombres de TABLAS_IPVA.
leer_ine_ipva_tablas <- function(rutas) {
  dplyr::bind_rows(lapply(seq_along(rutas), function(k) {
    dplyr::mutate(leer_ine_ipva(rutas[[k]]), tabla = basename(tools::file_path_sans_ext(rutas[[k]])))
  }))
}

# Cifras de la nota de prensa del IPVA 2024 (INE, 11-5-2026), para la compuerta ipva_nota.
REFERENCIAS_IPVA <- tibble::tribble(
  ~nivel,      ~geo_id,  ~anio, ~referencia, ~detalle,
  "nacional",  "00",     2024L, 3.5,         "Espa\u00f1a",
  "municipio", "28079",  2024L, 3.6,         "Madrid",
  "municipio", "08019",  2024L, 3.3,         "Barcelona",
  "ccaa",      "10",     2024L, 5.0,         "Comunitat Valenciana"
)

# Compuerta del IPVA (inventario/referencias_validacion.csv):
#   ipva_variacion (bloqueo): por tabla, nivel y año, diferencia máxima entre la variación anual
#     publicada y la recalculada con los índices (tres decimales) del año y del anterior;
#   ipva_nota (bloqueo): España, Madrid, Barcelona y la Comunitat Valenciana en 2024, frente a la nota de prensa;
#   ipva_tablas (bloqueo): diferencias entre las cifras de España de las cuatro tablas;
#   ipva_territorios (bloqueo): municipios y distritos del IPVA que no están en la jerarquía del
#     seccionado de 2021, y comunidades o provincias que no son de las del INE.
comprobar_ine_ipva <- function(ipva, territorios) {
  idx <- ipva |> dplyr::filter(medida == "indice") |> dplyr::select(tabla, nivel, geo_id, tipologia, anio, indice = valor)
  ant <- dplyr::mutate(idx, anio = anio + 1L) |> dplyr::rename(indice_ant = indice)
  var <- ipva |> dplyr::filter(medida == "variacion", !is.na(valor)) |>
    dplyr::inner_join(idx, by = c("tabla", "nivel", "geo_id", "tipologia", "anio")) |>
    dplyr::inner_join(ant, by = c("tabla", "nivel", "geo_id", "tipologia", "anio")) |>
    dplyr::mutate(recalculada = 100 * (indice / indice_ant - 1)) |>
    dplyr::filter(!is.na(recalculada))
  variacion <- var |>
    dplyr::group_by(anio, detalle = paste(tabla, nivel)) |>
    dplyr::summarise(calculado = max(abs(valor - recalculada)), .groups = "drop") |>
    dplyr::transmute(id = "ipva_variacion", anio, detalle, calculado, referencia = 0)

  nota <- REFERENCIAS_IPVA |>
    dplyr::left_join(ipva |> dplyr::filter(medida == "variacion", tipologia == "total") |>
                       dplyr::distinct(nivel, geo_id, anio, valor), by = c("nivel", "geo_id", "anio")) |>
    dplyr::transmute(id = "ipva_nota", anio, detalle, calculado = valor, referencia)

  espana <- ipva |> dplyr::filter(nivel == "nacional", tipologia == "total")
  tablas <- espana |>
    dplyr::group_by(anio, medida) |>
    dplyr::summarise(calculado = dplyr::n_distinct(valor) - 1, n = dplyr::n_distinct(tabla), .groups = "drop") |>
    dplyr::group_by(anio) |>
    dplyr::summarise(calculado = sum(calculado) + sum(n != length(unique(espana$tabla))), .groups = "drop") |>
    dplyr::transmute(id = "ipva_tablas", anio, detalle = "Espa\u00f1a en las cuatro tablas", calculado, referencia = 0)

  codigos <- function(n) territorios$codigo[territorios$nivel == n]
  fuera <- ipva |> dplyr::distinct(nivel, geo_id) |> dplyr::filter(nivel != "nacional") |>
    dplyr::group_by(nivel) |>
    dplyr::summarise(calculado = sum(!geo_id %in% codigos(dplyr::cur_group()$nivel)), .groups = "drop") |>
    dplyr::transmute(id = "ipva_territorios", anio = NA_integer_, detalle = nivel, calculado, referencia = 0)

  dplyr::bind_rows(variacion, nota, tablas, fuera) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Indicador 10 (var_alquiler) en la tabla larga: la variación anual publicada, total, de 2015 a
# 2024, de España a los distritos, cada nivel desde su tabla (España, de la de comunidades). Sin
# variación publicada («..»), «ausente».
armonizar_ine_ipva <- function(ipva, version, anios = ANIOS_IPVA) {
  propia <- c(ccaa = TABLAS_IPVA[["ccaa"]], nacional = TABLAS_IPVA[["ccaa"]], provincia = TABLAS_IPVA[["provincia"]],
              municipio = TABLAS_IPVA[["municipio"]], distrito = TABLAS_IPVA[["distrito"]])
  ipva |>
    dplyr::filter(medida == "variacion", tipologia == "total", anio %in% anios, tabla == propia[nivel]) |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "var_alquiler", corte = "total", grupo = "total",
                     valor, estado = ifelse(is.na(valor), "ausente", "dato"),
                     fuente = "ine_ipva", geo_ref = "2021", version = version) |>
    dplyr::select(dplyr::all_of(COLUMNAS_TABLA_LARGA))
}
