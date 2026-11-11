# Tabla de paso desde el seccionado del Censo 2011 (backlog, tarea 47; plan §11, pregunta 14).
# Las viviendas turísticas de agosto de 2020 a febrero de 2023 (indicador 19) y el Censo 2011
# (indicador 18 de 2011) vienen en las 35.960 secciones del Censo 2011, a 1 de noviembre de 2011.
# Se llevan al seccionado de referencia (2021) como en F1 (plan §6.3): callejero donde las secciones
# caen enteras y viviendas del Catastro donde hay que repartir, con los mismos estados y compuertas.
#
# Insumos (todos del INE salvo el Catastro, que es el de F1 y no se vuelve a leer):
#   - cartografía de las secciones del Censo 2011 (shapefile a 1-nov-2011): coincide código a código
#     con las secciones de las viviendas turísticas. El seccionado de 1 de enero de 2011 no: le
#     sobran 4 códigos y le faltan 3 (por revisar);
#   - callejero de enero de 2012 (tramos a 31-12-2011), con la aplicación antigua, como las tablas
#     de 2016–2020: es el más cercano a la fecha del Censo. Por qué no el de enero de 2011: su fecha
#     está a diez meses de la del Censo, y el de 2012, a dos;
#   - edificios del Catastro de F1 (`edificios_paso`), construidos hasta 2011. Solo están los
#     1.501 municipios que F1 lee; en los demás decide el callejero;
#   - indicadores por sección del Censo 2011 (población, viviendas, principales y en alquiler) y
#     las tablas 02003 (viviendas principales por régimen de tenencia) y 01010a (viviendas por tipo)
#     de sus resultados por comunidad y provincia.
# El callejero de enero de 2012 no está en fase con el Censo: 63 códigos suyos no están en el Censo
# y 45 del Censo no están en él (secciones creadas o suprimidas en noviembre y diciembre de 2011).
# En los municipios donde no casan los códigos, decide el Catastro si tiene edificios
# (paso2011_combinar()); los códigos que solo están en el callejero salen de la tabla.

PASO2011_CALLEJERO <- "012012"
PASO2011_ANIO_CATASTRO <- 2011L
# Las viviendas turísticas de 2020–2023 van con su propia tabla, la de los edificios construidos hasta
# 2020 (año del primer periodo, como la tabla 2024 -> 2021 para las de 2024–2026): con los de 2011, las
# secciones de 2021 de los barrios construidos después no recibirían nada.
PASO2011_ANIO_CATASTRO_VUT <- 2020L
# Periodos de las viviendas turísticas en las secciones del Censo 2011, con sus viviendas como
# denominador. Agosto de 2023 mezcla seccionados y queda fuera (por revisar).
PERIODOS_VUT_2011 <- c("AGO2020", "FEB2021", "AGO2021", "FEB2022", "AGO2022", "FEB2023")
URL_CENSO2011_CARTOGRAFIA <- "https://www.ine.es/censos2011_datos/cartografia_censo2011_nacional.zip"
URL_CENSO2011_INDICADORES <- "https://www.ine.es/censos2011_datos/indicadores_seccion_censal_csv.zip"
TABLAS_CENSO2011 <- c(tenencia = "02003", viviendas = "01010a")

paso2011_descargar_cartografia <- function(dir = file.path("datos", "brutos", "ine_censo2011"), forzar = FALSE) {
  descargar_con_cache(URL_CENSO2011_CARTOGRAFIA, file.path(dir, "cartografia_censo2011_nacional.zip"), forzar)
}

paso2011_descargar_indicadores <- function(dir = file.path("datos", "brutos", "ine_censo2011"), forzar = FALSE) {
  descargar_con_cache(URL_CENSO2011_INDICADORES, file.path(dir, "indicadores_seccion_censal_csv.zip"), forzar)
}

# Tablas de resultados del Censo 2011 (jaxi antiguo, CSV separado por punto y coma).
paso2011_descargar_tabla <- function(id, dir = file.path("datos", "brutos", "ine_censo2011"), forzar = FALSE) {
  url <- sprintf("https://www.ine.es/jaxi/files/_px/es/csv_bdsc/t20/e244/viviendas/p01/l0/%s.csv_bdsc?nocab=1", id)
  descargar_con_cache(url, file.path(dir, sprintf("%s.csv", id)), forzar)
}

# Indicadores por sección del Censo 2011: un CSV por comunidad dentro del zip. Una fila por sección
# con población (t1_1), viviendas (t16_1), principales (t17_1) y en alquiler (t18_4). Son
# estimaciones de la muestra, redondeadas a 5; una celda vacía es secreto (menos de 5 unidades
# muestrales) y queda en NA. 43 secciones del Censo no tienen fila.
paso2011_leer_censo2011 <- function(zip, ambito = "") {
  nombres <- utils::unzip(zip, list = TRUE)$Name
  nombres <- nombres[grepl("Indicadores[.]csv$", nombres)]
  d <- bind_rows(lapply(nombres, function(n) {
    readr::read_csv(unz(zip, n), col_types = readr::cols(.default = readr::col_character()), progress = FALSE)
  }))
  num <- function(x) suppressWarnings(as.numeric(x))
  d |>
    mutate(seccion = codigo_seccion(cpro, cmun, dist, secc)) |>
    filter(startsWith(seccion, ambito)) |>
    transmute(seccion, poblacion = num(t1_1), viviendas = num(t16_1), principales = num(t17_1),
              alquiler = num(t18_4)) |>
    arrange(seccion)
}

# Clave de nombre para casar territorios: sin tildes ni signos, en mayúsculas y, en los bilingües,
# la primera parte («Alicante/Alacant»).
paso2011_clave_nombre <- function(x) {
  x <- sub("/.*$", "", x)
  gsub("[^A-Z0-9]", "", toupper(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")))
}

# Etiquetas de comunidad y provincia de las tablas del Censo 2011 -> códigos del INE. Las comunidades
# vienen en mayúsculas («ANDALUCÍA») salvo Ceuta y Melilla; las provincias, con su nombre. Las
# comunidades de una provincia no traen fila de provincia: se le da la de la comunidad (como Ceuta y
# Melilla en el Censo 2021). `ccaa`: geo/ccaa.csv; `territorios`: territorios_2021.
paso2011_codigos_territorios <- function(d, ccaa, territorios) {
  prov <- filter(territorios, nivel == "provincia") |> transmute(provincia = codigo, ccaa_p = superior, nombre)
  d <- d |>
    mutate(ccaa = ccaa$codigo[match(paso2011_clave_nombre(comunidad), paso2011_clave_nombre(ccaa$nombre_ine))])
  if (any(!is.na(d$comunidad) & d$comunidad != "" & is.na(d$ccaa))) {
    stop("Comunidades del Censo 2011 sin c\u00f3digo: ",
         paste(unique(d$comunidad[!is.na(d$comunidad) & d$comunidad != "" & is.na(d$ccaa)]), collapse = ", "), call. = FALSE)
  }
  d$provincia_cod <- NA_character_
  con_prov <- !is.na(d$provincia) & d$provincia != ""
  clave_d <- paste(d$ccaa, paso2011_clave_nombre(d$provincia))
  clave_t <- paste(prov$ccaa_p, paso2011_clave_nombre(prov$nombre))
  d$provincia_cod[con_prov] <- prov$provincia[match(clave_d[con_prov], clave_t)]
  if (any(con_prov & is.na(d$provincia_cod))) {
    stop("Provincias del Censo 2011 sin c\u00f3digo: ", paste(unique(d$provincia[con_prov & is.na(d$provincia_cod)]),
                                                          collapse = ", "), call. = FALSE)
  }
  uniprovinciales <- prov |> group_by(ccaa_p) |> filter(n() == 1) |> ungroup() |>
    select(ccaa_p, provincia_uni = provincia)
  nac <- d |> filter(is.na(ccaa)) |> mutate(nivel = "nacional", codigo = "00", ccaa = NA_character_)
  com <- d |> filter(!is.na(ccaa), !con_prov) |> mutate(nivel = "ccaa", codigo = ccaa)
  pro <- d |> filter(con_prov) |> mutate(nivel = "provincia", codigo = provincia_cod)
  uni <- com |>
    inner_join(uniprovinciales, by = c("ccaa" = "ccaa_p")) |>
    mutate(nivel = "provincia", codigo = provincia_uni) |>
    select(-provincia_uni)
  bind_rows(nac, com, pro, uni) |> select(-provincia_cod)
}

# Lee una tabla de jaxi del Censo 2011 y la deja con las columnas comunidad y provincia.
paso2011_leer_jaxi <- function(ruta) {
  d <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = readr::col_character()),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  d$valor_num <- suppressWarnings(as.numeric(gsub(".", "", d[[ncol(d)]], fixed = TRUE)))
  d
}

# Tabla 02003: viviendas principales (hogares) y en alquiler («Alquilada») de España, cada comunidad y
# cada provincia, con todos los tamaños de municipio.
paso2011_leer_tenencia <- function(ruta, ccaa, territorios) {
  d <- paso2011_leer_jaxi(ruta)
  names(d)[1:5] <- c("nacional", "comunidad", "provincia", "tenencia", "tamano")
  d |>
    filter(startsWith(tamano, "Total"), startsWith(tenencia, "Total") | tenencia == "Alquilada") |>
    mutate(medida = if_else(tenencia == "Alquilada", "alquiler", "principales")) |>
    select(comunidad, provincia, medida, valor_num) |>
    tidyr::pivot_wider(names_from = medida, values_from = valor_num) |>
    paso2011_codigos_territorios(ccaa, territorios) |>
    select(nivel, codigo, ccaa, principales, alquiler)
}

# Tabla 01010a: total de viviendas (familiares y colectivas) de España, cada comunidad y cada provincia.
paso2011_leer_viviendas <- function(ruta, ccaa, territorios) {
  d <- paso2011_leer_jaxi(ruta)
  names(d)[1:5] <- c("tipo", "nacional", "comunidad", "provincia", "tamano")
  d |>
    filter(startsWith(tipo, "1 "), tamano == "Total") |>
    transmute(comunidad, provincia, viviendas = valor_num) |>
    paso2011_codigos_territorios(ccaa, territorios) |>
    select(nivel, codigo, ccaa, viviendas)
}

# Edificios de F1 (`edificios_paso`: coordenadas en `crs`, el sistema del seccionado de 2021, y la
# sección de 2021 ya puesta) con su sección del Censo 2011, agregados por par de secciones y año de
# construcción. Sirve para las dos tablas de la vía (b) (Censo 2011 y viviendas turísticas) sin
# situar dos veces los 5,8 millones de puntos.
paso2011_origen_edificios <- function(edificios, secciones, crs) {
  puntos <- sf::st_as_sf(edificios, coords = c("x", "y"), crs = crs)
  tibble::tibble(origen = seccion_de_puntos(puntos, secciones), destino = edificios$destino,
                 anio_construccion = edificios$anio_construccion, viviendas = edificios$viviendas) |>
    filter(!is.na(origen), !is.na(destino)) |>
    group_by(origen, destino, anio_construccion) |>
    summarise(edificios = n(), viviendas = sum(viviendas), .groups = "drop")
}

# Tabla de la vía (b) desde las secciones del Censo 2011, como geo_tabla_paso_catastro(): solo los
# edificios construidos hasta `anio_max` (los de año desconocido, también) y sin cruzar municipios
# salvo dentro de un grupo de fusión o segregación. `agregado`: paso2011_origen_edificios().
paso2011_tabla_catastro <- function(agregado, anio_max, grupos = NULL) {
  agregado |>
    filter(is.na(anio_construccion) | anio_construccion <= anio_max,
           agrupar_municipio(substr(origen, 1, 5), grupos) == agrupar_municipio(substr(destino, 1, 5), grupos)) |>
    group_by(origen, destino) |>
    summarise(portales = sum(viviendas), .groups = "drop") |>
    group_by(origen) |>
    mutate(fraccion = portales / sum(portales), metodo = "catastro") |>
    ungroup()
}

# Secciones de 2021 sin nada de una tabla cuyos edificios del Catastro son todos posteriores a
# `anio_max`: barrios construidos después, que en esa fecha no tenían viviendas.
paso2011_posteriores <- function(tabla, agregado, secciones_2021, anio_max) {
  vacias <- setdiff(unique(secciones_2021), tabla$destino)
  agregado |>
    filter(destino %in% vacias) |>
    group_by(destino) |>
    summarise(posterior = all(!is.na(anio_construccion) & anio_construccion > anio_max), .groups = "drop") |>
    filter(posterior) |>
    pull(destino)
}

# Municipios donde el mapa del Censo 2011 y el callejero no tienen los mismos códigos de sección.
paso2011_municipios_descasados <- function(secciones_mapa, secciones_callejero) {
  a <- unique(secciones_mapa)
  b <- unique(secciones_callejero)
  sort(unique(substr(c(setdiff(a, b), setdiff(b, a)), 1, 5)))
}

# Tabla combinada 2011 -> 2021. Como combinar_vias() (sin cambiarla), con dos ajustes por la fase del
# callejero:
#   - los orígenes del callejero que no están en el mapa del Censo (`datos`) salen de la tabla;
#   - en los municipios descasados (`descasados`), las secciones del Censo con edificios del Catastro
#     se quitan de la vía (a) para que decida la (b): el callejero solo ve una parte de ellas.
# Después, las secciones con datos sin ninguna vía pasan a la de su código si existe en 2021.
paso2011_combinar <- function(tabla_b, tabla_a, datos, referencia, descasados = character()) {
  tabla_a <- filter(tabla_a, origen %in% datos)
  forzadas <- intersect(unique(tabla_a$origen[substr(tabla_a$origen, 1, 5) %in% descasados]), tabla_b$origen)
  tabla_a <- filter(tabla_a, !origen %in% forzadas)
  combinar_vias(tabla_b, tabla_a, datos = datos) |>
    completar_por_codigo(datos, referencia)
}

# Secciones del Censo 2011 con datos que la tabla no lleva a 2021 (quedan fuera: alerta).
paso2011_sin_paso <- function(datos, tabla) setdiff(datos, tabla$origen)

# Indicador 18 de 2011 en el seccionado de 2021. Viviendas principales y en alquiler pasan como
# recuentos y el porcentaje se rehace en cada sección de 2021. Estado: el de los recuentos (dato si
# todos sus orígenes caen enteros); secreto si alguno de sus orígenes no trae los dos recuentos;
# ausente si no recibe nada o no tiene viviendas principales.
paso2011_reproyectar_censo <- function(censo, paso, secciones_2021) {
  censo <- filter(censo, seccion %in% paso$origen)
  completo <- censo$seccion[!is.na(censo$principales) & !is.na(censo$alquiler)]
  falta <- setdiff(unique(paso$origen), completo)
  marca <- paso |>
    group_by(seccion = destino) |>
    summarise(con_secreto = any(origen %in% falta), .groups = "drop")
  r <- function(v) geo_reproyectar_recuento(select(filter(censo, seccion %in% completo), seccion, valor = all_of(v)), paso)
  tibble::tibble(seccion = sort(unique(secciones_2021))) |>
    left_join(rename(r("principales"), principales = valor, estado_paso = estado), by = "seccion") |>
    left_join(select(r("alquiler"), seccion, alquiler = valor), by = "seccion") |>
    left_join(marca, by = "seccion") |>
    mutate(
      estado = case_when(is.na(con_secreto) ~ "ausente",
                         con_secreto ~ "secreto",
                         is.na(principales) | principales == 0 ~ "ausente",
                         TRUE ~ estado_paso),
      valor = if_else(estado %in% c("dato", "estimado"), 100 * alquiler / principales, NA_real_)
    ) |>
    select(seccion, principales, alquiler, valor, estado)
}

# Indicador 19 de agosto de 2020 a febrero de 2023 en el seccionado de 2021 (como reproyectar_ine_vut,
# con las viviendas del Censo 2011, el denominador del INE en esos periodos):
#   - si la sección de 2021 recibe una sola sección del Censo 2011, entera, se copia el porcentaje del INE;
#   - en las demás, 100 * viviendas turísticas reproyectadas / viviendas del Censo 2011 reproyectadas;
#   - estado: el de los recuentos; secreto si el INE protege el porcentaje de alguno de sus orígenes o
#     el Censo 2011 no da sus viviendas; ausente si no recibe nada.
paso2011_reproyectar_vut <- function(vut, paso, censo, secciones_2021, periodos = PERIODOS_VUT_2011) {
  unoauno <- secciones_1a1_vut(paso)
  viv11 <- select(filter(censo, seccion %in% paso$origen, !is.na(viviendas)), seccion, valor = viviendas)
  denominador <- geo_reproyectar_recuento(viv11, paso) |> select(seccion, viviendas_censo = valor)
  bind_rows(lapply(periodos, function(p) {
    v <- filter(vut, periodo == p, seccion %in% paso$origen)
    falta <- union(v$seccion[is.na(v$porcentaje)], setdiff(v$seccion, viv11$seccion))
    marca <- paso |>
      filter(origen %in% v$seccion) |>
      group_by(seccion = destino) |>
      summarise(con_secreto = any(origen %in% falta), .groups = "drop")
    r <- geo_reproyectar_recuento(select(v, seccion, valor = viviendas), paso)
    copia <- unoauno |>
      left_join(select(v, origen = seccion, porcentaje_ine = porcentaje), by = "origen") |>
      select(seccion, porcentaje_ine)
    tibble::tibble(seccion = sort(unique(secciones_2021))) |>
      left_join(denominador, by = "seccion") |>
      left_join(rename(r, viviendas = valor, estado_paso = estado), by = "seccion") |>
      left_join(copia, by = "seccion") |>
      left_join(marca, by = "seccion") |>
      mutate(
        unoauno = seccion %in% unoauno$seccion,
        valor = if_else(unoauno, porcentaje_ine, 100 * viviendas / viviendas_censo),
        estado = case_when(is.na(viviendas) ~ "ausente",
                           con_secreto | is.na(valor) ~ "secreto",
                           TRUE ~ estado_paso),
        valor = if_else(estado %in% c("dato", "estimado"), valor, NA_real_),
        periodo = p
      ) |>
      bind_cols(periodo_vut(p)) |>
      select(periodo, anio, mes, seccion, viviendas, viviendas_censo, unoauno, valor, estado)
  }))
}

# Filas de la tabla larga: secciones de 2021 (geo_ref 2021) y las cifras publicadas de España, las
# comunidades y las provincias (geo_ref vacío): del 18 en 2011 (tabla 02003) y del 19 en los periodos
# de PERIODOS_VUT_2011 (tabla 39365, con territorios_ine_vut()).
paso2011_armonizar <- function(censo_2021, vut_2021, tenencia, vut_provincias, version_censo, version_vut,
                               periodos = PERIODOS_VUT_2011) {
  bind_rows(
    censo_2021 |>
      transmute(geo_id = seccion, nivel = "sc", anio = 2011L, indicador = "hogares_alquiler", estado, valor) |>
      sin_desglose() |>
      mutate(fuente = "ine_censo2011", geo_ref = "2021", version = version_censo),
    tenencia |>
      transmute(geo_id = codigo, nivel, anio = 2011L, indicador = "hogares_alquiler",
                estado = if_else(is.na(principales) | is.na(alquiler) | principales == 0, "ausente", "dato"),
                valor = if_else(estado == "dato", 100 * alquiler / principales, NA_real_)) |>
      sin_desglose() |>
      mutate(fuente = "ine_censo2011", geo_ref = NA_character_, version = version_censo),
    armonizar_ine_vut(vut_2021, version = version_vut),
    territorios_ine_vut(vut_provincias, version = version_vut, periodos = periodos)
  ) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Compuerta de las dos tablas de paso 2011 y de las series que las usan (inventario/referencias_validacion.csv).
# En `anio`, 2011 para la tabla del Censo (`paso`) y 2020 para la de las viviendas turísticas (`paso_vut`):
#   cierre_poblacional y cobertura_destino: las mismas de F1, con la población del Censo 2011 (los
#     municipios sin población no entran en el cierre);
#   cobertura_destino_excepcion: las excepciones de inventario/excepciones_cobertura.csv de ese año;
#   paso2011_cobertura_posterior (alerta): secciones de 2021 sin nada de la tabla cuyos edificios del
#     Catastro son todos posteriores a su año (paso2011_posteriores()); no cuentan en cobertura_destino;
#   paso2011_seccionado: secciones de las viviendas turísticas (seis periodos) y del Censo 2011 fuera del
#     mapa del Censo, y secciones del mapa sin fila en las viviendas turísticas;
#   paso2011_sin_paso (alerta): secciones del Censo 2011 con datos que ninguna vía lleva a 2021;
#   paso2011_censo_alquiler: % de hogares en alquiler de España, cada comunidad y cada provincia (tabla
#     02003) frente a las secciones del Censo 2011 sumadas, con las secciones en secreto como intervalo
#     (como censo2021_alquiler);
#   paso2011_censo_principales: hogares de las secciones sumados frente a los publicados (desviación en %);
#   paso2011_censo_paso: hogares y hogares en alquiler llevados a 2021, sumados por provincia, frente a
#     los de sus secciones del Censo 2011 (desviación en %);
#   paso2011_vut_paso: viviendas turísticas llevadas a 2021, sumadas por provincia y España, frente a la
#     tabla 39364 (desviación en %);
#   paso2011_vut_denominador: secciones del Censo que caen enteras y solas en la sección de 2021 del mismo
#     código: mediana de |porcentaje del INE - 100 * viviendas turísticas / viviendas del Censo 2011|;
#   paso2011_vut_territorios: porcentaje publicado de España, cada comunidad y cada provincia (tabla
#     39365) frente a 100 * viviendas turísticas de sus secciones / viviendas del Censo 2011 de sus
#     secciones.
paso2011_comprobar <- function(paso, paso_vut, agregado, censo, censo_2021, tenencia, vut, vut_2021, vut_provincias,
                               secciones_mapa, secciones_2021, grupos, excepciones, periodos = PERIODOS_VUT_2011,
                               anios = c(PASO2011_ANIO_CATASTRO, PASO2011_ANIO_CATASTRO_VUT)) {
  mapa <- unique(secciones_mapa)
  con_poblacion <- censo |> group_by(municipio = substr(seccion, 1, 5)) |>
    summarise(total = sum(poblacion, na.rm = TRUE), .groups = "drop") |> filter(total > 0) |> pull(municipio)
  geografia <- bind_rows(lapply(1:2, function(k) {
    tabla <- list(paso, paso_vut)[[k]]
    poblacion <- censo |>
      filter(!is.na(poblacion), seccion %in% tabla$origen, substr(seccion, 1, 5) %in% con_poblacion) |>
      transmute(anio = anios[k], nivel = "seccion", codigo = seccion, valor = poblacion)
    posteriores <- paso2011_posteriores(tabla, agregado, secciones_2021, anios[k])
    bind_rows(
      comprobar_cierre_poblacional(poblacion, tabla, anios[k], grupos),
      comprobar_cobertura_destino(tabla, setdiff(secciones_2021, posteriores), anios[k], excepciones),
      tibble::tibble(id = "paso2011_cobertura_posterior", anio = as.integer(anios[k]), detalle = posteriores,
                     calculado = 1, referencia = 0)
    )
  }))
  v <- filter(vut, periodo %in% periodos)
  seccionado <- tibble::tibble(
    id = "paso2011_seccionado", anio = 2011L,
    detalle = c("secciones de las viviendas turisticas fuera del mapa del Censo 2011",
                "secciones del mapa del Censo 2011 sin fila en las viviendas turisticas",
                "secciones del Censo 2011 (indicadores) fuera de su mapa"),
    calculado = c(length(setdiff(v$seccion, mapa)),
                  sum(vapply(split(v$seccion, v$periodo), function(s) length(setdiff(mapa, s)), 1L)),
                  length(setdiff(censo$seccion, mapa))),
    referencia = 0)
  sin_paso <- bind_rows(
    tibble::tibble(anio = anios[1], detalle = paso2011_sin_paso(intersect(censo$seccion, mapa), paso)),
    tibble::tibble(anio = anios[2], detalle = paso2011_sin_paso(intersect(v$seccion, mapa), paso_vut)))
  provincias_tabla <- filter(tenencia, nivel == "provincia") |> distinct(codigo, ccaa)
  sumas <- censo |>
    mutate(codigo = substr(seccion, 1, 2), completa = !is.na(principales) & !is.na(alquiler)) |>
    group_by(codigo) |>
    summarise(principales_todas = sum(principales, na.rm = TRUE), principales = sum(principales[completa]),
              alquiler = sum(alquiler[completa]), .groups = "drop") |>
    sumar_territorios_ine(provincias_tabla)
  t <- inner_join(sumas, select(tenencia, nivel, codigo, principales_ref = principales, alquiler_ref = alquiler),
                  by = c("nivel", "codigo")) |>
    mutate(faltan = pmax(principales_ref - principales, 0),
           minimo = 100 * alquiler / (principales + faltan),
           maximo = 100 * (alquiler + faltan) / (principales + faltan),
           publicado = 100 * alquiler_ref / principales_ref)
  origen_prov <- censo |>
    filter(seccion %in% paso$origen, !is.na(principales), !is.na(alquiler)) |>
    group_by(codigo = substr(seccion, 1, 2)) |>
    summarise(principales = sum(principales), alquiler = sum(alquiler), .groups = "drop")
  llevado <- censo_2021 |>
    filter(!is.na(principales)) |>
    group_by(codigo = substr(seccion, 1, 2)) |>
    summarise(principales_2021 = sum(principales), alquiler_2021 = sum(alquiler, na.rm = TRUE), .groups = "drop")
  paso_censo <- inner_join(origen_prov, llevado, by = "codigo")
  vut_prov <- filter(vut_provincias, paste(anio, mes) %in% paste(v$anio, v$mes))
  sumar_vut <- function(d) {
    s <- d |> group_by(anio, mes, codigo = substr(seccion, 1, 2)) |>
      summarise(suma = sum(viviendas, na.rm = TRUE), viviendas_censo = sum(viviendas_censo, na.rm = TRUE), .groups = "drop")
    todas <- unique(vut_prov$codigo[vut_prov$nivel == "provincia"])
    espana <- s |> group_by(anio, mes) |> filter(all(todas %in% codigo)) |>
      summarise(codigo = "00", suma = sum(suma), viviendas_censo = sum(viviendas_censo), .groups = "drop") |>
      mutate(nivel = "nacional")
    bind_rows(mutate(s, nivel = "provincia"), espana)
  }
  mismo_codigo <- secciones_1a1_vut(paso_vut) |> filter(seccion == origen)
  denominador <- v |>
    filter(seccion %in% mismo_codigo$seccion, !is.na(porcentaje)) |>
    inner_join(select(censo, seccion, viviendas_censo = viviendas), by = "seccion") |>
    filter(!is.na(viviendas_censo), viviendas_censo > 0) |>
    mutate(diferencia = abs(porcentaje - 100 * viviendas / viviendas_censo))
  territorios <- v |>
    left_join(select(censo, seccion, viviendas_censo = viviendas), by = "seccion") |>
    group_by(anio, mes, codigo = substr(seccion, 1, 2)) |>
    summarise(viviendas = sum(viviendas, na.rm = TRUE), viviendas_censo = sum(viviendas_censo, na.rm = TRUE),
              .groups = "drop") |>
    sumar_territorios_ine(distinct(filter(vut_provincias, nivel == "provincia"), codigo, ccaa), por = c("anio", "mes")) |>
    inner_join(select(vut_prov, nivel, codigo, territorio, anio, mes, porcentaje), by = c("nivel", "codigo", "anio", "mes"))
  bind_rows(
    geografia,
    seccionado,
    transmute(sin_paso, id = "paso2011_sin_paso", anio = as.integer(anio), detalle, calculado = 1, referencia = 0),
    t |> transmute(id = "paso2011_censo_alquiler", anio = 2011L, detalle = paste(nivel, codigo),
                   calculado = pmin(pmax(publicado, minimo), maximo), referencia = publicado),
    t |> transmute(id = "paso2011_censo_principales", anio = 2011L, detalle = paste(nivel, codigo),
                   calculado = 100 * (principales_todas - principales_ref) / principales_ref, referencia = 0),
    paso_censo |> transmute(id = "paso2011_censo_paso", anio = 2011L, detalle = paste("hogares", codigo),
                            calculado = 100 * (principales_2021 - principales) / principales, referencia = 0),
    paso_censo |> transmute(id = "paso2011_censo_paso", anio = 2011L, detalle = paste("alquiler", codigo),
                            calculado = 100 * (alquiler_2021 - alquiler) / alquiler, referencia = 0),
    sumar_vut(vut_2021) |>
      inner_join(select(vut_prov, nivel, codigo, anio, mes, territorio, publicado = viviendas),
                 by = c("nivel", "codigo", "anio", "mes")) |>
      transmute(id = "paso2011_vut_paso", anio, detalle = paste(mes, territorio),
                calculado = 100 * (suma - publicado) / publicado, referencia = 0),
    denominador |> group_by(anio, mes) |> summarise(calculado = stats::median(diferencia), .groups = "drop") |>
      transmute(id = "paso2011_vut_denominador", anio, detalle = mes, calculado, referencia = 0),
    territorios |> transmute(id = "paso2011_vut_territorios", anio, detalle = paste(mes, territorio),
                             calculado = 100 * viviendas / viviendas_censo, referencia = porcentaje)
  )
}

# Resumen para la nota (§3.11): secciones de 2021 por estado de los recuentos y de las medianas, con
# solo el callejero y con la tabla combinada, y pares por vía.
paso2011_resumen <- function(paso_callejero, paso_final, datos) {
  e <- function(t) geo_estado_paso(t)
  a <- e(filter(paso_callejero, origen %in% datos))
  b <- e(paso_final)
  tibble::tibble(
    tabla = c("callejero", "combinada"),
    secciones_2021 = c(nrow(a), nrow(b)),
    estimado = c(sum(a$estado_recuento == "estimado"), sum(b$estado_recuento == "estimado")),
    medianas_ausente = c(sum(a$estado_mediana == "ausente"), sum(b$estado_mediana == "ausente")),
    pares_callejero = c(sum(paso_callejero$metodo == "callejero"), sum(paso_final$metodo == "callejero")),
    pares_catastro = c(0L, sum(paso_final$metodo == "catastro")),
    pares_codigo = c(sum(paso_callejero$metodo == "codigo"), sum(paso_final$metodo == "codigo"))
  )
}
