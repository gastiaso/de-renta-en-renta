# Fuente ine_adrh: indicadores de distribución del ADRH (F3, indicadores 4–6).
#   4 peso_salarios: porcentaje de la renta bruta que procede de salarios (tabla 30825,
#     «Distribución por fuente de ingresos»; en porcentaje desde la edición ADRH 2023, para toda
#     la serie).
#   5 bajo_60_mediana: población con ingresos por unidad de consumo por debajo del 60 % de la
#     mediana (tabla 30829, umbrales relativos por sexo; sexo «Total»). La mediana es la del
#     territorio fiscal común hasta la edición ADRH 2022 y la nacional desde la 2023 (ruptura
#     adrh_umbral_mediana_2023 de inventario/rupturas.csv).
#   6 gini: índice de Gini de la renta por unidad de consumo (tabla 37677).
# Las tres tablas son de toda España, por sección, distrito y municipio, en el mismo CSV que la de
# renta (R/fuente_ine_adrh.R). España, comunidades, provincias e islas van en tablas aparte, desde
# la edición de octubre de 2026 (53687, 53694 y 53688), con los nombres de los territorios y sin
# sus códigos.
#
# Marcas del CSV (comprobadas el 9-nov-2026 en las tres tablas):
#   «.»  secreto estadístico (menos de 100 residentes; en los umbrales, protección por sexo);
#   «..» dato no disponible (p. ej., las prestaciones y pensiones de las secciones de Álava);
#   «""» sin publicar ese año: territorios forales antes de entrar en el ADRH (Navarra hasta
#        2020, Álava hasta 2019, Gipuzkoa en 2015) y unidades de otros seccionados.
# Estado: «.» → secreto; «..» y «""» → ausente. Los huecos forales no se completan con Eustat ni
# Nastat (decisión del autor, 9-nov-2026): miden otra cosa (mayores de 18 sin unidad de consumo;
# umbral navarro).
#
# Hacia arriba solo la cifra publicada (regla 1). Al llevar los años a las secciones de 2021, el 4
# y el 5 son cocientes de sumas y se reproyectan como medias ponderadas (decisión del autor,
# 9-nov-2026): el 4 con la renta bruta de la sección (renta bruta media por persona × población) y
# el 5 con la población, porque el umbral es el mismo en toda España cada año. El 6 sigue la regla
# de medianas e índices (plan §6.3). La compuerta adrh_dist_municipio mide si las secciones así
# agregadas reproducen la cifra municipal.

# Nombre del indicador en el ADRH → código del catálogo (inventario/indicadores.csv)
INDICADORES_ADRH_DISTRIBUCION <- c(
  "Fuente de ingreso: salario" = "peso_salarios",
  "Poblaci\u00f3n con ingresos por unidad de consumo por debajo 60% de la mediana" = "bajo_60_mediana",
  "\u00cdndice de Gini" = "gini"
)
# Lo que lee el pipeline de cada tabla de secciones (lo demás, solo para las compuertas)
ADRH_FUENTES_INGRESO <- paste("Fuente de ingreso:", c("salario", "pensiones", "prestaciones por desempleo",
                                                       "otras prestaciones", "otros ingresos"))
ADRH_UMBRALES_DEBAJO <- sprintf("Poblaci\u00f3n con ingresos por unidad de consumo por debajo %d%% de la mediana",
                                c(40L, 50L, 60L))
ADRH_GINI <- "\u00cdndice de Gini"
# Cómo se reproyecta cada indicador al seccionado de 2021: peso de la media ponderada o mediana
PESO_REPROYECCION_ADRH_DISTRIBUCION <- c(peso_salarios = "renta_bruta", bajo_60_mediana = "poblacion", gini = NA)

# Estado de una cifra del CSV del ADRH por su texto («69,5», «.», «..» o vacío).
estado_marca_adrh <- function(texto) {
  t <- trimws(dplyr::coalesce(texto, ""))
  dplyr::case_when(t == "." ~ "secreto",
                   t %in% c("", "..") ~ "ausente",
                   TRUE ~ "dato")
}

# Número de una cifra del CSV del ADRH: «.» de miles, «,» decimal; las marcas, NA.
numero_adrh <- function(texto) {
  suppressWarnings(as.numeric(sub(",", ".", gsub(".", "", texto, fixed = TRUE), fixed = TRUE)))
}

# Lee una tabla de secciones del ADRH (cualquiera de las de toda España) por trozos, quedándose
# con los indicadores pedidos (y, en las tablas por sexo, con los sexos pedidos). Devuelve una
# fila por territorio, año e indicador: nivel (municipio, distrito o seccion), codigo, valor y
# estado (dato, secreto o ausente, de la marca del CSV). `ambito`: prefijo de los códigos.
leer_ine_adrh_distribucion <- function(ruta, indicadores, ambito = "", sexo = "Total") {
  cabecera <- strsplit(readr::read_lines(ruta, n_max = 1), ";", fixed = TRUE)[[1]]
  con_sexo <- length(cabecera) == 7L
  if (!length(cabecera) %in% c(6L, 7L)) stop("Tabla del ADRH con ", length(cabecera), " columnas: ", ruta, call. = FALSE)
  nombres <- c("municipio", "distrito", "seccion", if (con_sexo) "sexo", "indicador", "anio", "valor")
  quedarse <- function(x, pos) {
    x <- x[x$indicador %in% indicadores & startsWith(x$municipio, ambito), , drop = FALSE]
    if (con_sexo) x <- x[x$sexo %in% sexo, , drop = FALSE]
    x
  }
  datos <- readr::read_delim_chunked(
    ruta, readr::DataFrameCallback$new(quedarse), chunk_size = 1000000L, delim = ";", skip = 1,
    col_names = nombres, col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"), progress = FALSE
  )
  if (!con_sexo) datos$sexo <- "Total"
  datos |>
    mutate(
      nivel  = case_when(!is.na(seccion) ~ "seccion", !is.na(distrito) ~ "distrito", TRUE ~ "municipio"),
      codigo = case_when(nivel == "seccion" ~ substr(seccion, 1, 10),
                         nivel == "distrito" ~ substr(distrito, 1, 7),
                         TRUE ~ substr(municipio, 1, 5)),
      anio   = as.integer(anio),
      estado = estado_marca_adrh(valor),
      valor  = if_else(estado == "dato", numero_adrh(valor), NA_real_)
    ) |>
    select(anio, nivel, codigo, sexo, indicador, valor, estado)
}

# Códigos de los territorios de las tablas de totales del ADRH, que solo traen nombres: España
# «00»; comunidades por su nombre del INE (geo/ccaa.csv); provincias por su nombre dentro de su
# comunidad (territorios del seccionado de 2021), y si no casa, por la parte anterior a «/»
# (el ADRH escribe «Alicante/Alacant» y «Valencia/València»). Se detiene si algún territorio no
# casa o casa dos veces; con `parar = FALSE` (pruebas de una provincia), las provincias que no
# casan quedan sin código. `t`: columnas ccaa y provincia (vacías en España).
codigos_totales_adrh <- function(t, ccaa, territorios, parar = TRUE) {
  clave <- function(x) tolower(trimws(sub("/.*$", "", x)))
  provincias <- territorios[territorios$nivel == "provincia", c("codigo", "nombre", "superior")]
  cod_ccaa <- ccaa$codigo[match(t$ccaa, ccaa$nombre_ine)]
  if (any(!is.na(t$ccaa) & is.na(cod_ccaa))) {
    stop("Comunidades del ADRH sin c\u00f3digo: ", paste(unique(t$ccaa[!is.na(t$ccaa) & is.na(cod_ccaa)]), collapse = ", "),
         call. = FALSE)
  }
  exacto <- match(paste(cod_ccaa, t$provincia), paste(provincias$superior, provincias$nombre))
  por_clave <- match(paste(cod_ccaa, clave(t$provincia)), paste(provincias$superior, clave(provincias$nombre)))
  fila <- dplyr::coalesce(exacto, por_clave)
  sin_casar <- !is.na(t$provincia) & is.na(fila)
  if (any(sin_casar) && parar) {
    stop("Provincias del ADRH sin c\u00f3digo: ", paste(unique(t$provincia[sin_casar]), collapse = ", "), call. = FALSE)
  }
  nivel <- case_when(!is.na(t$provincia) ~ "provincia", !is.na(t$ccaa) ~ "ccaa", TRUE ~ "nacional")
  codigo <- case_when(nivel == "provincia" ~ provincias$codigo[fila], nivel == "ccaa" ~ cod_ccaa, TRUE ~ "00")
  unicos <- unique(data.frame(nivel, codigo, ccaa = dplyr::coalesce(t$ccaa, ""), provincia = dplyr::coalesce(t$provincia, "")))
  unicos <- unicos[!is.na(unicos$codigo), ]
  repetidos <- unicos[duplicated(unicos[c("nivel", "codigo")]), ]
  if (nrow(repetidos)) {
    stop("Territorios del ADRH que casan dos veces: ", paste(repetidos$provincia, repetidos$ccaa, collapse = ", "), call. = FALSE)
  }
  tibble::tibble(nivel = nivel, codigo = codigo)
}

# Lee una tabla de totales del ADRH (España, comunidades, provincias e islas): una fila por
# territorio, año e indicador, con nivel (nacional, ccaa o provincia), codigo, valor y estado.
# Las islas no se leen (la tabla larga no tiene ese nivel). Con `ambito` (una provincia), solo
# España, la comunidad de la provincia y la provincia.
leer_ine_adrh_totales <- function(ruta, indicadores, ccaa, territorios, sexo = "Total", ambito = "") {
  cabecera <- strsplit(readr::read_lines(ruta, n_max = 1), ";", fixed = TRUE)[[1]]
  con_sexo <- length(cabecera) == 8L
  if (!length(cabecera) %in% c(7L, 8L)) stop("Tabla de totales del ADRH con ", length(cabecera), " columnas: ", ruta, call. = FALSE)
  nombres <- c("nacional", "ccaa", "provincia", "isla", if (con_sexo) "sexo", "indicador", "anio", "valor")
  datos <- readr::read_delim(ruta, delim = ";", skip = 1, col_names = nombres,
                             col_types = readr::cols(.default = readr::col_character()),
                             locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  if (!con_sexo) datos$sexo <- "Total"
  datos <- datos[is.na(datos$isla) & datos$indicador %in% indicadores & datos$sexo %in% sexo, , drop = FALSE]
  x <- datos |>
    bind_cols(codigos_totales_adrh(datos, ccaa, territorios, parar = !nzchar(ambito))) |>
    filter(!is.na(codigo)) |>
    transmute(anio = as.integer(anio), nivel, codigo, sexo, indicador,
              estado = estado_marca_adrh(valor), valor = if_else(estado == "dato", numero_adrh(valor), NA_real_))
  if (nzchar(ambito)) {
    comunidad <- territorios$superior[territorios$nivel == "provincia" & territorios$codigo == ambito]
    x <- x[x$nivel == "nacional" | (x$nivel == "ccaa" & x$codigo %in% comunidad) |
             (x$nivel == "provincia" & x$codigo == ambito), , drop = FALSE]
  }
  x
}

# Filas que entran en la tabla larga, con el código del catálogo: el salario de la tabla de
# fuentes de ingreso, el 60 % de la de umbrales y el Gini. Vale para las tablas de secciones y
# para las de totales.
seleccionar_adrh_distribucion <- function(...) {
  bind_rows(...) |>
    filter(indicador %in% names(INDICADORES_ADRH_DISTRIBUCION), sexo == "Total") |>
    mutate(indicador = unname(INDICADORES_ADRH_DISTRIBUCION[indicador])) |>
    select(-sexo)
}

# Compuerta de los indicadores 4–6 (inventario/referencias_validacion.csv). `fuentes`,
# `umbrales`, `gini`: tablas de secciones leídas con leer_ine_adrh_distribucion() (las cinco
# fuentes de ingreso, los umbrales del 40, el 50 y el 60 % y el Gini); `totales`: las tres de
# totales juntas (leer_ine_adrh_totales()); `pesos`: pesos_adrh_distribucion().
#   adrh_dist_cobertura (bloqueo): cada tabla de secciones trae municipios de todas las provincias
#     del ámbito (una descarga cortada, como la primera de la 30829 el 9-nov-2026, se queda en
#     una provincia intermedia sin dar error).
#   adrh_dist_rango (bloqueo): porcentajes e índices entre 0 y 100.
#   adrh_dist_fuentes_suma (bloqueo): las cinco fuentes de ingreso suman 100 en cada territorio y
#     año con las cinco publicadas (cinco cifras redondeadas a una décima: ±0,25 puntos).
#   adrh_dist_umbrales_orden (bloqueo): por debajo del 40 % ≤ del 50 % ≤ del 60 %.
#   adrh_dist_seccion_unica (bloqueo): en los municipios de una sola sección, la cifra de la
#     sección es la del municipio (comprueba que se leen la escala y la columna buenas).
#   adrh_dist_municipio (bloqueo) y adrh_dist_municipio_detalle (alerta): el 4 y el 5 de las
#     secciones, agregados como media ponderada (renta bruta; población), frente a la cifra
#     municipal, en los municipios con todas sus secciones publicadas. Valida la reproyección como
#     media ponderada.
#   adrh_dist_provincia (bloqueo): ídem por provincia frente a la tabla de totales (mediana de la
#     desviación por año), con las secciones publicadas: comprueba el casado de nombres.
comprobar_ine_adrh_distribucion <- function(fuentes, umbrales, gini, totales, pesos, ambito = "") {
  provincias_esperadas <- if (nzchar(ambito)) 1L else 52L
  cobertura <- bind_rows(fuentes = fuentes, umbrales = umbrales, gini = gini, .id = "tabla") |>
    filter(nivel == "municipio") |>
    group_by(tabla) |>
    summarise(calculado = n_distinct(substr(codigo, 1, 2)), .groups = "drop") |>
    transmute(id = "adrh_dist_cobertura", anio = NA_integer_, detalle = tabla, calculado,
              referencia = provincias_esperadas)

  todo <- seleccionar_adrh_distribucion(fuentes, umbrales, gini, totales)
  rango <- todo |>
    group_by(anio, indicador) |>
    summarise(calculado = sum(!is.na(valor) & (valor < 0 | valor > 100)), .groups = "drop") |>
    transmute(id = "adrh_dist_rango", anio, detalle = indicador, calculado, referencia = 0)

  suma <- bind_rows(fuentes, totales |> filter(indicador %in% ADRH_FUENTES_INGRESO)) |>
    group_by(anio, nivel, codigo) |>
    summarise(n = sum(estado == "dato"), suma = sum(valor), .groups = "drop") |>
    filter(n == length(ADRH_FUENTES_INGRESO)) |>
    group_by(anio) |>
    summarise(calculado = max(abs(suma - 100)), .groups = "drop") |>
    transmute(id = "adrh_dist_fuentes_suma", anio, detalle = "maxima desviacion de la suma de las cinco fuentes",
              calculado, referencia = 0)

  orden <- bind_rows(umbrales, totales |> filter(indicador %in% ADRH_UMBRALES_DEBAJO)) |>
    filter(estado == "dato", sexo == "Total") |>
    mutate(k = match(indicador, ADRH_UMBRALES_DEBAJO)) |>
    select(anio, nivel, codigo, k, valor) |>
    tidyr::pivot_wider(names_from = k, values_from = valor, names_prefix = "u") |>
    group_by(anio) |>
    summarise(calculado = sum(u1 > u2 | u2 > u3, na.rm = TRUE), .groups = "drop") |>
    transmute(id = "adrh_dist_umbrales_orden", anio, detalle = "territorios con los umbrales fuera de orden",
              calculado, referencia = 0)

  catalogo <- seleccionar_adrh_distribucion(fuentes, umbrales, gini)
  secciones <- catalogo |> filter(nivel == "seccion") |> mutate(municipio = substr(codigo, 1, 5))
  municipios <- catalogo |> filter(nivel == "municipio", estado == "dato") |>
    select(anio, indicador, municipio = codigo, publicado = valor)
  unica <- secciones |>
    group_by(anio, indicador, municipio) |>
    filter(n() == 1, estado == "dato") |>
    ungroup() |>
    inner_join(municipios, by = c("anio", "indicador", "municipio")) |>
    group_by(anio, indicador) |>
    summarise(calculado = max(abs(valor - publicado)), .groups = "drop") |>
    transmute(id = "adrh_dist_seccion_unica", anio, detalle = indicador, calculado, referencia = 0)

  ponderadas <- secciones |>
    filter(indicador %in% names(PESO_REPROYECCION_ADRH_DISTRIBUCION)[!is.na(PESO_REPROYECCION_ADRH_DISTRIBUCION)]) |>
    left_join(pesos, by = c("anio", "codigo" = "seccion")) |>
    mutate(peso = if_else(indicador == "peso_salarios", renta_bruta, poblacion))
  por_municipio <- ponderadas |>
    filter(estado != "ausente") |>
    group_by(anio, indicador, municipio) |>
    filter(all(estado == "dato") & all(!is.na(peso))) |>
    summarise(agregado = sum(valor * peso) / sum(peso), .groups = "drop") |>
    inner_join(municipios, by = c("anio", "indicador", "municipio")) |>
    mutate(desviacion = agregado - publicado)
  municipio <- por_municipio |>
    group_by(anio, indicador) |>
    summarise(calculado = stats::median(abs(desviacion)), .groups = "drop") |>
    transmute(id = "adrh_dist_municipio", anio, detalle = indicador, calculado, referencia = 0)
  municipio_detalle <- por_municipio |>
    transmute(id = "adrh_dist_municipio_detalle", anio, detalle = paste(municipio, indicador),
              calculado = desviacion, referencia = 0)

  publicados_provincia <- seleccionar_adrh_distribucion(totales) |>
    filter(nivel == "provincia", estado == "dato") |>
    select(anio, indicador, provincia = codigo, publicado = valor)
  provincia <- ponderadas |>
    filter(estado == "dato", !is.na(peso)) |>
    group_by(anio, indicador, provincia = substr(codigo, 1, 2)) |>
    summarise(agregado = sum(valor * peso) / sum(peso), .groups = "drop") |>
    inner_join(publicados_provincia, by = c("anio", "indicador", "provincia")) |>
    group_by(anio, indicador) |>
    summarise(calculado = stats::median(abs(agregado - publicado)), .groups = "drop") |>
    transmute(id = "adrh_dist_provincia", anio, detalle = indicador, calculado, referencia = 0)

  bind_rows(cobertura, rango, suma, orden, unica, municipio, municipio_detalle, provincia)
}

# Pesos de las medias ponderadas del 4 y el 5 por sección y año: población y renta bruta total
# (renta bruta media por persona × población). `pesos`: pesos_adrh(); `renta_bruta`: la renta bruta
# media por persona de la tabla de renta (leer_ine_adrh()).
pesos_adrh_distribucion <- function(pesos, renta_bruta) {
  bruta <- renta_bruta |> filter(nivel == "seccion") |> select(anio, seccion = codigo, renta_bruta_persona = valor)
  pesos |>
    select(anio, seccion, poblacion) |>
    left_join(bruta, by = c("anio", "seccion")) |>
    mutate(renta_bruta = renta_bruta_persona * poblacion) |>
    select(anio, seccion, poblacion, renta_bruta)
}

# Estado de una sección de 2021 sin valor: «secreto» si alguno de sus orígenes es secreto
# estadístico; si no, «ausente» (año sin publicar o dato no disponible en todos ellos).
estado_sin_valor_adrh <- function(tabla, estados_origen) {
  tabla |>
    distinct(origen, destino) |>
    left_join(estados_origen, by = c("origen" = "seccion")) |>
    mutate(es_secreto = dplyr::coalesce(estado_origen == "secreto", FALSE)) |>
    group_by(seccion = destino) |>
    summarise(secreto = sum(es_secreto) > 0, .groups = "drop")
}

# Cuántos orígenes recibe cada sección de 2021 y cuántos tienen valor: lo mismo que
# geo_cobertura_origenes(), sin evaluar %in% en cada grupo (con toda España, 30 llamadas pasan de
# unos 10 minutos a segundos).
cobertura_origenes_adrh <- function(valores, tabla) {
  con_valor <- unique(valores$seccion[!is.na(valores$valor)])
  tabla |>
    distinct(origen, destino) |>
    mutate(con = origen %in% con_valor) |>
    group_by(seccion = destino) |>
    summarise(origenes = n(), completos = sum(con), .groups = "drop")
}

# Lleva un indicador de distribución de un año del ADRH al seccionado de 2021 con su tabla de
# paso: media ponderada (`peso`: columna de `pesos_anio`) o, sin peso, regla de medianas. Devuelve
# una fila por sección de destino con valor y estado.
reproyectar_adrh_distribucion <- function(secciones, tabla, peso = NA, pesos_anio = NULL) {
  destinos <- tibble::tibble(seccion = sort(unique(tabla$destino)))
  valores <- secciones |> filter(!is.na(valor)) |> select(seccion = codigo, valor)
  if (is.na(peso)) {
    r <- geo_reproyectar_mediana(valores, tabla) |> select(seccion, valor, estado, origen)
  } else {
    valores <- valores |>
      inner_join(pesos_anio |> select(seccion, peso = all_of(peso)), by = "seccion") |>
      filter(!is.na(peso), peso > 0)
    r <- geo_reproyectar_media(valores, tabla) |> mutate(origen = NA_character_)
  }
  estados_origen <- secciones |> select(seccion = codigo, estado_origen = estado)
  secreto_destino <- estado_sin_valor_adrh(tabla, estados_origen)
  estado_mediana_origen <- estados_origen |> select(origen = seccion, estado_dominante = estado_origen)
  destinos |>
    left_join(r, by = "seccion") |>
    left_join(cobertura_origenes_adrh(valores, tabla), by = "seccion") |>
    left_join(secreto_destino, by = "seccion") |>
    left_join(estado_mediana_origen, by = "origen") |>
    mutate(estado = case_when(
      !is.na(estado) & estado == "ausente" ~ "ausente",
      is.na(valor) & !is.na(origen) ~ if_else(estado_dominante %in% "secreto", "secreto", "ausente"),
      is.na(valor) & secreto ~ "secreto",
      is.na(valor) ~ "ausente",
      completos < origenes ~ "estimado",
      TRUE ~ estado
    )) |>
    select(seccion, valor, estado)
}

# Indicadores 4–6 en formato largo: secciones de 2021 (cada año con su tabla de paso; 2020,
# nativo), municipios (cifra publicada) y España, comunidades y provincias (tablas de totales).
# `distribucion`: filas de leer_ine_adrh_distribucion() con el código del catálogo en `indicador`;
# `totales`: ídem de leer_ine_adrh_totales(); `pesos`: pesos_adrh_distribucion(); `tablas`: lista
# con nombre = año del ADRH y valor = tabla de paso hacia 2021. De los municipios entran las cifras
# publicadas y las secretas; los años sin publicar no llevan fila (en la web, «sin dato»), como en
# la renta (1–3).
armonizar_ine_adrh_distribucion <- function(distribucion, totales, pesos, tablas, version) {
  por_anio <- lapply(names(tablas), function(a_txt) {
    a <- as.integer(a_txt)
    bind_rows(lapply(names(PESO_REPROYECCION_ADRH_DISTRIBUCION), function(ind) {
      secciones <- distribucion |> filter(anio == a, nivel == "seccion", indicador == ind)
      reproyectar_adrh_distribucion(secciones, tablas[[a_txt]], PESO_REPROYECCION_ADRH_DISTRIBUCION[[ind]],
                                    pesos |> filter(anio == a)) |>
        mutate(anio = a, indicador = ind)
    }))
  })
  secciones <- bind_rows(por_anio) |>
    transmute(geo_id = seccion, nivel = "sc", anio, indicador, valor, estado)
  municipios <- distribucion |>
    filter(nivel == "municipio", estado != "ausente") |>
    transmute(geo_id = codigo, nivel = "municipio", anio, indicador, valor, estado)
  arriba <- totales |> transmute(geo_id = codigo, nivel, anio, indicador, valor, estado)
  bind_rows(secciones, municipios, arriba) |>
    sin_desglose() |>
    mutate(fuente = "ine_adrh", geo_ref = "2021", version = version)
}
