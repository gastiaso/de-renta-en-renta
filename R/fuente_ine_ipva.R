# INE, Índice de Precios de Vivienda en Alquiler (IPVA; indicador 10, F4). Estadística experimental,
# anual (mayo), con los alquileres declarados en el IRPF: índice (base 2015 = 100) desde 2011 y
# variación anual desde 2012. No cubre País Vasco ni Navarra (régimen foral). Cuatro tablas generales
# de INEbase, en CSV de jaxiT3 (TABLAS_IPVA): España y comunidades, provincias, municipios de más de
# 10.000 habitantes y distritos de las capitales de provincia, con el código del INE delante del
# nombre. El atlas toma la variación anual publicada (un índice no se agrega: regla 1), en total y
# en su nivel nativo, de 2015 a 2024. Los desgloses por tipo de edificación y tamaño no entran.
# Tarea 36 (10-nov-2026): desde la edición de 2021, el desglose por antigüedad del contrato
# (contratos nuevos, con año de contrato igual al de referencia, y existentes) en dos tablas más:
# 59004 (España y comunidades) y 59005 (provincias), de 2021 a 2024. Entra en la tabla larga como
# corte `contrato` (grupos `nuevo` y `existente`) del indicador 10; el total sigue saliendo de las
# cuatro tablas generales. Los índices por contrato están en base 2015 = 100 encadenados desde el
# índice general de 2020 (proyecto técnico del INE, junio de 2023, §5.3; comprobación
# ipva_contrato_enlace). Licencia: CC BY 4.0 (aviso legal del INE).

TABLAS_IPVA <- c(ccaa = "59056", provincia = "59058", municipio = "59060", distrito = "59061",
                 ccaa_contrato = "59004", provincia_contrato = "59005")
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

# Grupo del corte `contrato` desde la columna «Antigüedad del contrato de arrendamiento» de las
# tablas 59004 y 59005: «Total», «Nuevo contrato» y «Contrato existente». Otro texto, error.
ipva_grupo_contrato <- function(texto) {
  texto <- trimws(texto)
  grupo <- dplyr::case_when(texto == "Total" ~ "total", texto == "Nuevo contrato" ~ "nuevo",
                            texto == "Contrato existente" ~ "existente", TRUE ~ NA_character_)
  if (anyNA(grupo)) {
    stop("IPVA: antig\u00fcedad del contrato desconocida: ", paste(unique(texto[is.na(grupo)]), collapse = ", "),
         call. = FALSE)
  }
  grupo
}

# Una tabla del IPVA en formato ordenado: nivel, geo_id, territorio, tipologia (total, VC, VU),
# contrato (total, nuevo, existente), anio, medida (indice, variacion) y valor. El territorio es la
# columna con el código delante del nombre; sin código («Total Nacional»), España («00»). Se
# detiene si alguna serie no tiene todos los años: las descargas del INE pueden llegar cortadas
# sin dar error.
leer_ine_ipva <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  names(d) <- sub("^\ufeff", "", names(d))
  n <- ncol(d)
  i_dato <- grep("^Tipo de dato$", names(d))
  i_tipo <- grep("^Tipo de edificaci", names(d))
  i_contrato <- grep("^Antig\u00fcedad del contrato", names(d))
  if (length(i_dato) != 1) stop("Sin columna 'Tipo de dato' en ", ruta, call. = FALSE)
  # territorio: la columna anterior a las de medida con codigos delante del nombre (ni la de tipo
  # de edificacion ni la de antiguedad del contrato)
  candidatas <- setdiff(seq_len(i_dato - 1), c(i_tipo, i_contrato))
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
  contrato <- if (length(i_contrato)) ipva_grupo_contrato(d[[i_contrato]]) else "total"
  x <- tibble::tibble(
    nivel = nivel, geo_id = ifelse(is.na(codigo), "00", codigo),
    territorio = ifelse(is.na(codigo), "Total Nacional", sub("^[0-9]+ ", "", terr)),
    tipologia = tipologia,
    contrato = contrato,
    anio = as.integer(d[[n - 1]]),
    medida = ifelse(grepl("ndice", d[[i_dato]]), "indice", "variacion"),
    valor = numero_jaxi(d[[n]])
  )
  anios <- sort(unique(x$anio))
  por_serie <- dplyr::count(x, nivel, geo_id, tipologia, contrato, medida)
  if (any(por_serie$n != length(anios))) {
    stop("IPVA ", basename(ruta), ": ", sum(por_serie$n != length(anios)), " series sin todos los a\u00f1os (",
         min(anios), "-", max(anios), "). \u00bfDescarga cortada? B\u00f3rrala y vuelve a bajarla.", call. = FALSE)
  }
  x
}

# Las seis tablas juntas, con la tabla de origen. `rutas`: con nombres de TABLAS_IPVA.
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

# Cifras de España por antigüedad del contrato (tabla 59004; backlog, tarea 36), para la compuerta
# ipva_contrato: el índice de 2021 y 2024 de los contratos nuevos, los existentes y el total, y la
# variación anual de los nuevos y los existentes en 2021, 2022 y 2024.
REFERENCIAS_IPVA_CONTRATO <- tibble::tribble(
  ~contrato,   ~medida,     ~anio, ~referencia,
  "nuevo",     "indice",    2021L, 114.871,
  "nuevo",     "indice",    2024L, 137.041,
  "existente", "indice",    2021L, 112.229,
  "existente", "indice",    2024L, 120.637,
  "total",     "indice",    2021L, 112.694,
  "total",     "indice",    2024L, 122.920,
  "nuevo",     "variacion", 2021L, 3.5,
  "existente", "variacion", 2021L, 1.2,
  "nuevo",     "variacion", 2022L, 5.3,
  "existente", "variacion", 2022L, 2.1,
  "nuevo",     "variacion", 2024L, 8.8,
  "existente", "variacion", 2024L, 2.8
)

# Compuerta del IPVA (inventario/referencias_validacion.csv):
#   ipva_variacion (bloqueo): por tabla, nivel y año, diferencia máxima entre la variación anual
#     publicada y la recalculada con los índices (tres decimales) del año y del anterior;
#   ipva_contrato_enlace (bloqueo): primer año del desglose por contrato (2021), sin índice del año
#     anterior en su tabla: variación publicada frente a la recalculada con el índice general del
#     año anterior del mismo territorio (el INE encadena desde él la base 2015 = 100);
#   ipva_nota (bloqueo): España, Madrid, Barcelona y la Comunitat Valenciana en 2024, frente a la nota de prensa;
#   ipva_contrato (bloqueo): cifras de España por antigüedad del contrato (REFERENCIAS_IPVA_CONTRATO);
#   ipva_tablas (bloqueo): diferencias entre las tablas en las cifras que comparten (España, con su
#     total en todas las tablas que publican el año y sus contratos en la 59004 y la 59005;
#     comunidades y provincias, en la tabla general y en la de contratos);
#   ipva_territorios (bloqueo): municipios y distritos del IPVA que no están en la jerarquía del
#     seccionado de 2021, y comunidades o provincias que no son de las del INE.
comprobar_ine_ipva <- function(ipva, territorios) {
  claves <- c("tabla", "nivel", "geo_id", "tipologia", "contrato", "anio")
  idx <- ipva |> dplyr::filter(medida == "indice") |>
    dplyr::select(tabla, nivel, geo_id, tipologia, contrato, anio, indice = valor)
  ant <- dplyr::mutate(idx, anio = anio + 1L) |> dplyr::rename(indice_ant = indice)
  var <- ipva |> dplyr::filter(medida == "variacion", !is.na(valor)) |>
    dplyr::inner_join(idx, by = claves) |>
    dplyr::inner_join(ant, by = claves) |>
    dplyr::mutate(recalculada = 100 * (indice / indice_ant - 1)) |>
    dplyr::filter(!is.na(recalculada))
  variacion <- var |>
    dplyr::group_by(anio, detalle = paste(tabla, nivel)) |>
    dplyr::summarise(calculado = max(abs(valor - recalculada)), .groups = "drop") |>
    dplyr::transmute(id = "ipva_variacion", anio, detalle, calculado, referencia = 0)

  # enlace del desglose por contrato: su primer anio, frente al indice general del anio anterior (sin
  # ese indice, NA y la compuerta no pasa)
  por_contrato <- dplyr::filter(ipva, contrato != "total")
  enlace <- NULL
  if (nrow(por_contrato)) {
    primero <- min(por_contrato$anio)
    general <- idx |> dplyr::filter(contrato == "total", tipologia == "total", anio == primero - 1L) |>
      dplyr::distinct(nivel, geo_id, indice_ant = indice)
    enlace <- por_contrato |>
      dplyr::filter(medida == "variacion", anio == primero, !is.na(valor)) |>
      dplyr::inner_join(idx, by = claves) |>
      dplyr::left_join(general, by = c("nivel", "geo_id")) |>
      dplyr::mutate(recalculada = 100 * (indice / indice_ant - 1)) |>
      dplyr::group_by(anio, detalle = paste(tabla, nivel)) |>
      dplyr::summarise(calculado = max(abs(valor - recalculada)), .groups = "drop") |>
      dplyr::transmute(id = "ipva_contrato_enlace", anio, detalle, calculado, referencia = 0)
  }

  nota <- REFERENCIAS_IPVA |>
    dplyr::left_join(ipva |> dplyr::filter(medida == "variacion", tipologia == "total", contrato == "total") |>
                       dplyr::distinct(nivel, geo_id, anio, valor), by = c("nivel", "geo_id", "anio")) |>
    dplyr::transmute(id = "ipva_nota", anio, detalle, calculado = valor, referencia)

  nombre_contrato <- c(nuevo = "contratos nuevos", existente = "contratos existentes", total = "total")
  nombre_medida <- c(indice = "\u00edndice", variacion = "variaci\u00f3n anual")
  contrato <- REFERENCIAS_IPVA_CONTRATO |>
    dplyr::left_join(ipva |> dplyr::filter(tabla == TABLAS_IPVA[["ccaa_contrato"]], nivel == "nacional", tipologia == "total") |>
                       dplyr::select(contrato, medida, anio, valor), by = c("contrato", "medida", "anio")) |>
    dplyr::transmute(id = "ipva_contrato", anio,
                     detalle = paste0("Espa\u00f1a, ", nombre_contrato[contrato], ", ", nombre_medida[medida]),
                     calculado = valor, referencia)

  con_anio <- dplyr::count(dplyr::distinct(ipva, tabla, anio), anio, name = "tablas_anio")
  nombre_nivel <- c(nacional = "Espa\u00f1a en las tablas que publican el a\u00f1o",
                    ccaa = "Comunidades en la tabla general y en la de contratos",
                    provincia = "Provincias en la tabla general y en la de contratos")
  tablas <- ipva |>
    dplyr::filter(tipologia == "total", nivel %in% names(nombre_nivel), contrato == "total" | nivel == "nacional") |>
    dplyr::group_by(anio, nivel, geo_id, contrato, medida) |>
    dplyr::summarise(distintas = dplyr::n_distinct(valor) - 1, n = dplyr::n_distinct(tabla), .groups = "drop") |>
    dplyr::left_join(con_anio, by = "anio") |>
    dplyr::mutate(falta = nivel == "nacional" & contrato == "total" & n != tablas_anio) |>
    dplyr::group_by(anio, nivel) |>
    dplyr::summarise(calculado = sum(distintas) + sum(falta), .groups = "drop") |>
    dplyr::transmute(id = "ipva_tablas", anio, detalle = unname(nombre_nivel[nivel]), calculado, referencia = 0)

  codigos <- function(n) territorios$codigo[territorios$nivel == n]
  fuera <- ipva |> dplyr::distinct(nivel, geo_id) |> dplyr::filter(nivel != "nacional") |>
    dplyr::group_by(nivel) |>
    dplyr::summarise(calculado = sum(!geo_id %in% codigos(dplyr::cur_group()$nivel)), .groups = "drop") |>
    dplyr::transmute(id = "ipva_territorios", anio = NA_integer_, detalle = nivel, calculado, referencia = 0)

  dplyr::bind_rows(variacion, enlace, nota, contrato, tablas, fuera) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Indicador 10 (var_alquiler) en la tabla larga: la variación anual publicada, de 2015 a 2024, cada
# nivel desde su tabla. El total, de España a los distritos (España, de la tabla de comunidades);
# el corte `contrato` (grupos `nuevo` y `existente`; tarea 36), de España, las comunidades y las
# provincias, desde las tablas por antigüedad del contrato (2021-2024). Sin variación publicada
# («..»), «ausente».
armonizar_ine_ipva <- function(ipva, version, anios = ANIOS_IPVA) {
  propia <- c(ccaa = TABLAS_IPVA[["ccaa"]], nacional = TABLAS_IPVA[["ccaa"]], provincia = TABLAS_IPVA[["provincia"]],
              municipio = TABLAS_IPVA[["municipio"]], distrito = TABLAS_IPVA[["distrito"]])
  propia_contrato <- c(ccaa = TABLAS_IPVA[["ccaa_contrato"]], nacional = TABLAS_IPVA[["ccaa_contrato"]],
                       provincia = TABLAS_IPVA[["provincia_contrato"]])
  ipva |>
    dplyr::filter(medida == "variacion", tipologia == "total", anio %in% anios) |>
    dplyr::filter(dplyr::if_else(contrato == "total", dplyr::coalesce(tabla == propia[nivel], FALSE),
                                 dplyr::coalesce(tabla == propia_contrato[nivel], FALSE))) |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "var_alquiler",
                     corte = ifelse(contrato == "total", "total", "contrato"), grupo = contrato,
                     valor, estado = ifelse(is.na(valor), "ausente", "dato"),
                     fuente = "ine_ipva", geo_ref = "2021", version = version) |>
    dplyr::select(dplyr::all_of(COLUMNAS_TABLA_LARGA))
}
