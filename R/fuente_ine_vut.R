# Fuente ine_vut: Medición del número de viviendas turísticas en España y su capacidad (INE,
# estadística experimental). Tabla 5, distritos y secciones: un xlsx por periodo, solo para
# descarga. Hoja de secciones: código de 10 dígitos, viviendas turísticas, plazas, plazas por
# vivienda y porcentaje de viviendas turísticas sobre el total de viviendas. El INE publica las
# viviendas turísticas de todas las secciones y protege el porcentaje de algunas («Dato protegido
# por secreto estadístico»): las que tienen en secreto sus viviendas en el Censo 2021.
# Periodos semestrales con mes de referencia: febrero y agosto hasta agosto de 2024; mayo y
# noviembre desde noviembre de 2024 (inventario/rupturas.csv, vut_calendario_2024).
#
# Seccionado y denominador de cada periodo (comprobado el 8-nov-2026 con los códigos de cada
# fichero frente a los seccionados de 2016–2025; inventario/rupturas.csv, vut_seccionado_2024):
#   - agosto de 2020 a febrero de 2023: las 35.960 secciones del Censo 2011 y, como denominador,
#     sus viviendas (nota 4 de los ficheros). No hay tabla de paso de 2011 a 2021: fuera.
#   - agosto de 2023: 37.063 códigos, mezcla de las secciones de 2011 y de seccionados
#     posteriores (6.097 viviendas turísticas en códigos que no son de 2024): fuera.
#   - febrero de 2024 en adelante: el seccionado de 2024 (febrero de 2024 trae además 258 códigos
#     antiguos, todos sin viviendas turísticas) y, como denominador, las viviendas del Censo 2021
#     (t18_1): en las secciones que no cambian, el porcentaje del INE es exactamente
#     100 * viviendas turísticas / t18_1.
# El indicador 19 en el seccionado de 2021 (reproyectar_ine_vut): las viviendas turísticas pasan
# por la tabla de paso combinada 2024 -> 2021 y se dividen por las viviendas del Censo 2021 de la
# sección de destino, el mismo denominador que usa el INE; donde la sección de 2021 recibe una
# sola sección de 2024 entera, se copia el porcentaje publicado.
# Compuerta: tabla 39364 de jaxiT3 (viviendas turísticas por provincia). La cifra de España de la
# tabla larga es el porcentaje publicado en la tabla 39365 (nacional_ine_vut).

PERIODOS_VUT <- c("AGO2020", "FEB2021", "AGO2021", "FEB2022", "AGO2022", "FEB2023", "AGO2023",
                  "FEB2024", "AGO2024", "NOV2024", "MAY2025", "NOV2025", "MAY2026")
# Periodos en el seccionado de 2024, los que entran en el indicador
PERIODOS_VUT_2024 <- c("FEB2024", "AGO2024", "NOV2024", "MAY2025", "NOV2025", "MAY2026")
MESES_VUT <- c(FEB = "M02", MAY = "M05", AGO = "M08", NOV = "M11")
TABLAS_VUT_PROVINCIAS <- c(viviendas = "39364", porcentaje = "39365")

url_ine_vut_tabla5 <- function(periodo) {
  sprintf("https://www.ine.es/experimental/viv_turistica/exp_viv_turistica_tabla5_%s.xlsx", periodo)
}

descargar_ine_vut <- function(periodo, dir = file.path("datos", "brutos", "ine_vut"), forzar = FALSE) {
  descargar_con_cache(url_ine_vut_tabla5(periodo),
                      file.path(dir, sprintf("exp_viv_turistica_tabla5_%s.xlsx", periodo)), forzar)
}

# Tablas provinciales de jaxiT3 (CSV separado por «;», coma decimal).
descargar_ine_vut_provincias <- function(id, dir = file.path("datos", "brutos", "ine_vut"), forzar = FALSE) {
  descargar_con_cache(sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv?nocab=1", id),
                      file.path(dir, sprintf("%s.csv", id)), forzar)
}

# «AGO2020» -> año 2020 y mes «M08»; «2024M11» (jaxiT3) -> 2024 y «M11».
periodo_vut <- function(periodo) {
  jaxi <- grepl("^[0-9]{4}M[0-9]{2}$", periodo)
  tibble::tibble(
    anio = as.integer(ifelse(jaxi, substr(periodo, 1, 4), substr(periodo, 4, 7))),
    mes  = ifelse(jaxi, substr(periodo, 5, 7), unname(MESES_VUT[substr(periodo, 1, 3)]))
  )
}

# Número en texto, con punto decimal y sin separador de miles (lo que da readxl en texto).
numero_vut <- function(x) suppressWarnings(as.numeric(sub(",", ".", trimws(x), fixed = TRUE)))

# Hoja de secciones de la tabla 5 de un periodo. Devuelve una fila por sección: periodo, año,
# mes, viviendas turísticas y porcentaje sobre el total de viviendas (NA si la celda no es un
# número: secreto estadístico).
leer_ine_vut <- function(ruta, periodo, ambito = "") {
  hojas <- readxl::excel_sheets(ruta)
  hoja <- hojas[grepl("secci", hojas, ignore.case = TRUE)][1]
  if (is.na(hoja)) stop("La tabla 5 de ", periodo, " no tiene hoja de secciones: ", paste(hojas, collapse = ", "),
                        call. = FALSE)
  bruto <- readxl::read_excel(ruta, sheet = hoja, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  secciones_vut(bruto, periodo, ambito)
}

# La hoja de secciones ya leída como texto, sin nombres de columna (separada para probarla sin
# xlsx). Busca la fila de cabecera (código «CODIGO» o «cusec» y alguna columna de plazas) y las
# columnas por su nombre.
secciones_vut <- function(bruto, periodo, ambito = "") {
  es_cabecera <- apply(bruto, 1, function(f) any(grepl("^(codigo|cusec)$", trimws(f), ignore.case = TRUE)) &&
                         any(grepl("plaza", f, ignore.case = TRUE)))
  fila <- which(es_cabecera)[1]
  if (is.na(fila)) stop("No se encuentra la cabecera en la hoja de secciones de ", periodo, call. = FALSE)
  cabecera <- tolower(trimws(as.character(unlist(bruto[fila, ]))))
  cabecera[is.na(cabecera)] <- ""
  columna <- function(patron, excluir = "^$") {
    i <- which(grepl(patron, cabecera) & !grepl(excluir, cabecera))
    if (length(i) != 1) stop("Columna ambigua o ausente (", patron, ") en ", periodo, ": ",
                             paste(cabecera, collapse = " | "), call. = FALSE)
    i
  }
  i_codigo <- columna("^(codigo|cusec)$")
  i_viviendas <- columna("^vivienda", "plaza|porcentaje")
  i_porcentaje <- columna("^porcentaje")
  datos <- bruto[-seq_len(fila), c(i_codigo, i_viviendas, i_porcentaje)]
  names(datos) <- c("seccion", "viviendas", "porcentaje")
  p <- periodo_vut(periodo)
  datos |>
    mutate(seccion = trimws(seccion)) |>
    filter(grepl("^[0-9]{10}$", seccion), startsWith(seccion, ambito)) |>
    transmute(periodo = periodo, anio = p$anio, mes = p$mes, seccion,
              viviendas = numero_vut(viviendas), porcentaje = numero_vut(porcentaje))
}

# Tablas 39364 y 39365: una fila por territorio (nacional o provincia) y periodo, con las
# viviendas turísticas y el porcentaje publicados.
leer_ine_vut_provincias <- function(ruta_viviendas, ruta_porcentaje) {
  leer <- function(ruta) {
    d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                           locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
    n <- ncol(d)
    names(d)[c(1:3, n - 1, n)] <- c("nacional", "ccaa", "provincia", "periodo_ine", "valor")
    if (n == 6) names(d)[4] <- "medida" else d$medida <- "porcentaje"
    d |>
      filter(is.na(ccaa) == is.na(provincia)) |>
      mutate(nivel = if_else(is.na(provincia), "nacional", "provincia"),
             codigo = if_else(is.na(provincia), "00", substr(provincia, 1, 2)),
             territorio = if_else(is.na(provincia), nacional, provincia),
             valor = suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE)))) |>
      select(nivel, codigo, territorio, periodo_ine, medida, valor)
  }
  viviendas <- leer(ruta_viviendas) |>
    filter(grepl("^viviendas tur", medida, ignore.case = TRUE)) |>
    select(nivel, codigo, territorio, periodo_ine, viviendas = valor)
  porcentaje <- leer(ruta_porcentaje) |> select(codigo, periodo_ine, porcentaje = valor)
  t <- full_join(viviendas, porcentaje, by = c("codigo", "periodo_ine"))
  bind_cols(t, periodo_vut(t$periodo_ine))
}

# Secciones de 2024 que caen enteras y solas en una sección de 2021 (la sección de destino no
# recibe nada más): ahí el porcentaje del INE vale tal cual en el seccionado de 2021.
secciones_1a1_vut <- function(paso, umbral = 0.99) {
  geo_estado_paso(paso, umbral) |>
    filter(n_origenes == 1, enteros) |>
    transmute(seccion, origen = origen_dominante)
}

# Indicador 19 en el seccionado de 2021, una fila por sección del Censo y periodo de `periodos`:
#   viviendas: viviendas turísticas reproyectadas (geo_reproyectar_recuento);
#   valor: el porcentaje del INE si la sección recibe una sola sección de 2024 entera; si no,
#     100 * viviendas / viviendas del Censo 2021 (t18_1) de la sección;
#   estado: dato (sección 1:1 o suma de secciones enteras), estimado (alguna sección repartida),
#     secreto (porcentaje protegido por el INE o viviendas del Censo en secreto) o ausente (la
#     sección no recibe nada de la tabla de paso).
# `paso`: tabla de paso combinada del seccionado de 2024 al de 2021; `censo`: leer_ine_censo2021().
reproyectar_ine_vut <- function(vut, paso, censo, periodos = PERIODOS_VUT_2024) {
  unoauno <- secciones_1a1_vut(paso)
  por_periodo <- lapply(periodos, function(p) {
    v <- filter(vut, periodo == p, seccion %in% paso$origen)
    r <- geo_reproyectar_recuento(select(v, seccion, valor = viviendas), paso)
    copia <- unoauno |>
      left_join(select(v, origen = seccion, porcentaje_ine = porcentaje), by = "origen") |>
      select(seccion, porcentaje_ine)
    censo |>
      select(seccion, viviendas_censo = viviendas) |>
      left_join(rename(r, viviendas = valor, estado_paso = estado), by = "seccion") |>
      left_join(copia, by = "seccion") |>
      mutate(
        unoauno = seccion %in% unoauno$seccion,
        valor = if_else(unoauno, porcentaje_ine, 100 * viviendas / viviendas_censo),
        estado = case_when(is.na(viviendas) ~ "ausente",
                           is.na(valor) ~ "secreto",
                           TRUE ~ estado_paso),
        valor = if_else(estado %in% c("dato", "estimado"), valor, NA_real_),
        periodo = p
      ) |>
      bind_cols(periodo_vut(p)) |>
      select(periodo, anio, mes, seccion, viviendas, viviendas_censo, unoauno, valor, estado)
  })
  bind_rows(por_periodo)
}

# Indicador 19 en formato largo. `anio`: año del mes de referencia; `corte` «mes» y `grupo` el
# mes («M02», «M05», «M08», «M11»; inventario/vocabulario.csv).
armonizar_ine_vut <- function(vut_2021, version) {
  vut_2021 |>
    transmute(geo_id = seccion, nivel = "sc", anio, indicador = "viviendas_turisticas",
              corte = "mes", grupo = mes, valor, estado,
              fuente = "ine_vut", geo_ref = "2021", version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Indicador 19 de España: el porcentaje publicado en la tabla 39365 (total nacional), en los
# mismos periodos que las secciones (`periodos`), con el mes en `corte` y `grupo`. Los periodos
# anteriores a febrero de 2024 no entran, como en las secciones; hasta febrero de 2023, además, el
# denominador del INE eran las viviendas del Censo 2011 (rupturas.csv, vut_seccionado_2024). Sin
# seccionado de referencia (geo_ref NA).
# `provincias`: leer_ine_vut_provincias().
nacional_ine_vut <- function(provincias, version, periodos = PERIODOS_VUT_2024) {
  periodo_vut(periodos) |>
    left_join(filter(provincias, nivel == "nacional"), by = c("anio", "mes")) |>
    transmute(geo_id = "00", nivel = "nacional", anio, indicador = "viviendas_turisticas",
              corte = "mes", grupo = mes, valor = porcentaje,
              estado = if_else(is.na(porcentaje), "ausente", "dato"),
              fuente = "ine_vut", geo_ref = NA_character_, version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Compuerta (inventario/referencias_validacion.csv):
#   vut_viviendas_provincia: viviendas turísticas de las secciones sumadas por provincia y
#     España frente a la tabla 39364, todos los periodos (desviación en %).
#   vut_seccionado: en cada periodo de PERIODOS_VUT_2024, secciones del seccionado de 2024 que
#     faltan en el fichero más secciones con viviendas turísticas fuera de ese seccionado.
#   vut_paso_2021: viviendas turísticas reproyectadas al seccionado de 2021, sumadas por
#     provincia y España, frente a la tabla 39364 (desviación en %).
#   vut_denominador: en las secciones 1:1 con el mismo código en 2024 y 2021 y viviendas del Censo
#     publicadas, mediana de |porcentaje del INE - 100 * viviendas turísticas / t18_1| (puntos).
#   vut_denominador_detalle (alerta): las mismas secciones, una a una (solo salen las que se
#     apartan más de 0,001 puntos).
#   vut_nacional_viviendas: viviendas turísticas de las provincias de la tabla 39364 sumadas
#     frente a las de España de la misma tabla, todos los periodos (desviación en %).
#   vut_nacional_porcentaje: en cada periodo de `periodos`, media ponderada de los porcentajes
#     provinciales de la tabla 39365 con las viviendas del Censo 2021 de cada provincia (t18_1
#     sumado de sus secciones con dato) frente al porcentaje de España de esa tabla, el que va a
#     la tabla larga (puntos). Solo con todas las provincias en `censo`. Las secciones en secreto
#     del Censo no entran en el peso y los porcentajes van con dos decimales: no es exacto.
comprobar_ine_vut <- function(vut, vut_2021, provincias, censo, secciones_2024, paso, periodos = PERIODOS_VUT_2024) {
  sumar <- function(d) {
    s <- d |> group_by(anio, mes, codigo = substr(seccion, 1, 2)) |>
      summarise(suma = sum(viviendas, na.rm = TRUE), .groups = "drop")
    # España solo si están todas las provincias de la tabla (con PROVINCIA, el pipeline lee una)
    todas <- unique(provincias$codigo[provincias$nivel == "provincia"])
    espana <- s |> group_by(anio, mes) |> filter(all(todas %in% codigo)) |>
      summarise(codigo = "00", suma = sum(suma), .groups = "drop")
    bind_rows(s, espana) |>
      inner_join(provincias, by = c("anio", "mes", "codigo"))
  }
  frente_39364 <- function(d, id) {
    sumar(d) |> transmute(id = id, anio, detalle = paste(mes, territorio),
                          calculado = 100 * (suma - viviendas) / viviendas, referencia = 0)
  }
  usados <- filter(vut, periodo %in% periodos)
  seccionado <- usados |>
    group_by(anio, mes) |>
    summarise(calculado = sum(!secciones_2024 %in% seccion) +
                sum(viviendas > 0 & !seccion %in% secciones_2024, na.rm = TRUE), .groups = "drop") |>
    transmute(id = "vut_seccionado", anio, detalle = mes, calculado, referencia = 0)
  mismo_codigo <- secciones_1a1_vut(paso) |> filter(seccion == origen)
  denominador <- usados |>
    filter(seccion %in% mismo_codigo$seccion, !is.na(porcentaje)) |>
    inner_join(select(censo, seccion, viviendas_censo = viviendas), by = "seccion") |>
    filter(!is.na(viviendas_censo)) |>
    mutate(diferencia = abs(porcentaje - 100 * viviendas / viviendas_censo))
  bind_rows(
    frente_39364(vut, "vut_viviendas_provincia"),
    seccionado,
    frente_39364(vut_2021, "vut_paso_2021"),
    denominador |> group_by(anio, mes) |>
      summarise(calculado = stats::median(diferencia), .groups = "drop") |>
      transmute(id = "vut_denominador", anio, detalle = mes, calculado, referencia = 0),
    denominador |> filter(diferencia > 0.001) |>
      transmute(id = "vut_denominador_detalle", anio, detalle = paste(mes, seccion), calculado = diferencia,
                referencia = 0),
    nacional_vut(provincias, censo, periodos)
  )
}

# Las dos comprobaciones de España de comprobar_ine_vut() (vut_nacional_viviendas y
# vut_nacional_porcentaje). Un periodo sin cifra de España sale con NA y no pasa.
nacional_vut <- function(provincias, censo, periodos = PERIODOS_VUT_2024) {
  espana <- filter(provincias, nivel == "nacional")
  prov <- filter(provincias, nivel == "provincia")
  viviendas <- prov |>
    group_by(anio, mes) |>
    summarise(suma = sum(viviendas), .groups = "drop") |>
    left_join(select(espana, anio, mes, publicado = viviendas), by = c("anio", "mes")) |>
    transmute(id = "vut_nacional_viviendas", anio, detalle = mes,
              calculado = 100 * (suma - publicado) / publicado, referencia = 0)
  pesos <- censo |>
    group_by(codigo = substr(seccion, 1, 2)) |>
    summarise(viviendas_censo = sum(viviendas, na.rm = TRUE), .groups = "drop")
  if (!all(unique(prov$codigo) %in% pesos$codigo)) return(viviendas)
  media <- prov |>
    inner_join(pesos, by = "codigo") |>
    group_by(anio, mes) |>
    summarise(calculado = sum(porcentaje * viviendas_censo) / sum(viviendas_censo), .groups = "drop")
  porcentaje <- periodo_vut(periodos) |>
    left_join(media, by = c("anio", "mes")) |>
    left_join(select(espana, anio, mes, referencia = porcentaje), by = c("anio", "mes")) |>
    transmute(id = "vut_nacional_porcentaje", anio, detalle = mes, calculado, referencia)
  bind_rows(viviendas, porcentaje)
}
