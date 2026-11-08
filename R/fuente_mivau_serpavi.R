# Fuente mivau_serpavi: Sistema Estatal de Referencia del Precio del Alquiler de Vivienda (MIVAU).
# Indicadores 8 (alquiler_mes) y 9 (alquiler_m2).
#
# Base de datos completa en un Excel (2011–2024, 68 MB) con las hojas Metadatos, CCAA, Provincias,
# Municipios, Distritos y Secciones censales, todas en el seccionado del Censo 2021 para toda la
# serie (no hace falta tabla de paso: geo_ref = 2021). Un bloque de columnas por año (sufijo _AA) y,
# por tipología (VC: vivienda colectiva; VU: unifamiliar o rural), el recuento de testigos
# (BI_ALVHEPCO_TVC/TVU) y la mediana, el P25 y el P75 del alquiler mensual (ALQTBID12_M/25/75) y del
# alquiler por m² (ALQM2_LV_M/25/75; en la hoja Metadatos, ALQM2mes_LV). La superficie (SLVM2) no se usa.
# Con menos de 10 testigos solo se publica el recuento (secreto estadístico). La hoja CCAA lleva
# además una fila sin código con el total de España (solo el recuento, sin medianas).
#
# Coherencia de la edición 2011–2024 (comprobado el 8-nov-2026): las secciones suman exactamente
# los testigos de cada provincia y de España, y las provincias y comunidades cumplen la regla del
# secreto y el orden de los cuartiles. Las hojas Municipios y Distritos tienen errores en unas
# pocas filas (sobre todo Navarra en 2022 y 2023–2024: filas desplazadas, mediana y P25 cruzados,
# un recuento no entero, medianas con 0 testigos): esos territorios, años y tipologías van como
# «ausente» y salen en la alerta serpavi_escalas_detalle.

PAGINA_SERPAVI <- "https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi"

# Fichero manual: la web del MIVAU responde a las descargas automáticas con una página de bloqueo
# y el nombre del Excel cambia en cada edición. Se guarda con un nombre fijo por edición.
descargar_mivau_serpavi <- function(ultimo_anio = 2024L, dir = file.path("datos", "brutos", "mivau_serpavi")) {
  ruta <- file.path(dir, sprintf("bd_serpavi_2011-%d.xlsx", ultimo_anio))
  if (file.exists(ruta)) return(ruta)
  stop("Falta la base de datos del SERPAVI (fichero manual).\n",
       "  Hay que descargar el Excel de la base de datos 2011-", ultimo_anio, " desde ", PAGINA_SERPAVI,
       "\n  y guardarlo como ", ruta, call. = FALSE)
}

# Hojas del Excel por nivel de la tabla larga y columna con el código de cada una.
HOJAS_SERPAVI <- c(ccaa = "CCAA", provincia = "Provincias", municipio = "Municipios",
                   distrito = "Distritos", sc = "Secciones censales")
CODIGO_HOJA_SERPAVI <- c(ccaa = "CCAA", provincia = "CPRO", municipio = "CUMUN", distrito = "CUDIS", sc = "CUSEC")

# Medidas que usa el atlas, por año y tipología.
MEDIDAS_SERPAVI <- c("testigos", "alquiler_mes_p25", "alquiler_mes_p50", "alquiler_mes_p75",
                     "alquiler_m2_p25", "alquiler_m2_p50", "alquiler_m2_p75")

# Año de entrada de los territorios forales (inventario/rupturas.csv, serpavi_forales): antes, sin
# dato por sección. Navarra (31) en 2021, Gipuzkoa (20) en 2022, Araba/Álava (01) y Bizkaia (48) en 2024.
ENTRADA_SERPAVI_FORALES <- c("31" = 2021L, "20" = 2022L, "01" = 2024L, "48" = 2024L)

# Comunidad de cada provincia foral. El SERPAVI solo da la cifra de una comunidad cuando han
# entrado todas sus provincias: el País Vasco (16) no la tiene en 2022 y 2023, con Gipuzkoa ya
# dentro, y la fila de España de esos años es la suma de las comunidades, sin Gipuzkoa.
COMUNIDAD_FORAL_SERPAVI <- c("31" = "15", "20" = "16", "01" = "16", "48" = "16")

# Columnas del SERPAVI que usa el atlas: nombre de la columna, medida, tipología y año.
# Las demás (identificadores, superficie) quedan fuera.
columnas_serpavi <- function(nombres) {
  t <- regmatches(nombres, regexec("^BI_ALVHEPCO_T(V[CU])_([0-9]{2})$", nombres))
  q <- regmatches(nombres, regexec("^(ALQTBID12|ALQM2(mes)?_LV)_(M|25|75)_(V[CU])_([0-9]{2})$", nombres))
  es_t <- lengths(t) > 0
  es_q <- lengths(q) > 0
  estadistico <- c(M = "p50", `25` = "p25", `75` = "p75")
  medida_q <- vapply(q[es_q], function(m) {
    paste0(if (m[2] == "ALQTBID12") "alquiler_mes" else "alquiler_m2", "_", estadistico[[m[4]]])
  }, character(1))
  dplyr::bind_rows(
    tibble::tibble(columna = nombres[es_t], medida = "testigos",
                   tipologia = vapply(t[es_t], `[`, "", 2), aa = vapply(t[es_t], `[`, "", 3)),
    tibble::tibble(columna = nombres[es_q], medida = medida_q,
                   tipologia = vapply(q[es_q], `[`, "", 5), aa = vapply(q[es_q], `[`, "", 6))
  ) |>
    mutate(anio = 2000L + as.integer(aa)) |>
    select(columna, medida, tipologia, anio)
}

# Código como texto con ceros a la izquierda. Los de sección pasan de 2^31 (provincias 22 y
# siguientes): no caben en un entero de R, así que se formatean desde un número real.
codigo_serpavi <- function(x, ancho) {
  x <- trimws(as.character(x))
  vacio <- is.na(x) | !nzchar(x)
  out <- rep(NA_character_, length(x))
  out[!vacio] <- formatC(as.numeric(x[!vacio]), width = ancho, format = "f", digits = 0, flag = "0")
  out
}

# Una hoja del Excel (leída como tabla) en formato ordenado: una fila por territorio, año y
# tipología, con las MEDIDAS_SERPAVI en columnas. En la hoja CCAA, la fila sin código es España
# (nivel «nacional», código «00»). Se detiene si a algún año le falta alguna columna o si un
# código se repite.
ordenar_hoja_serpavi <- function(hoja, nivel, desde = 2015L) {
  cols <- columnas_serpavi(names(hoja))
  cols <- cols[cols$anio >= desde, ]
  if (nrow(cols) == 0) stop("La hoja ", HOJAS_SERPAVI[[nivel]], " no tiene columnas del SERPAVI desde ", desde, call. = FALSE)
  incompletas <- cols |> count(anio, tipologia) |> filter(n != length(MEDIDAS_SERPAVI))
  if (nrow(incompletas) > 0 || dplyr::n_distinct(cols$tipologia) != 2) {
    stop("Columnas del SERPAVI incompletas en la hoja ", HOJAS_SERPAVI[[nivel]], ": ",
         paste(incompletas$anio, incompletas$tipologia, collapse = ", "), call. = FALSE)
  }
  codigo <- codigo_serpavi(hoja[[CODIGO_HOJA_SERPAVI[[nivel]]]], NIVELES[[nivel]])
  niveles <- rep(nivel, length(codigo))
  if (nivel == "ccaa") {
    nacional <- is.na(codigo)
    if (sum(nacional) > 1) stop("La hoja CCAA tiene m\u00e1s de una fila sin c\u00f3digo", call. = FALSE)
    codigo[nacional] <- "00"
    niveles[nacional] <- "nacional"
  }
  if (anyDuplicated(codigo[!is.na(codigo)])) {
    stop("C\u00f3digos repetidos en la hoja ", HOJAS_SERPAVI[[nivel]], call. = FALSE)
  }
  valores <- as.data.frame(lapply(hoja[cols$columna], function(v) suppressWarnings(as.numeric(v))))
  names(valores) <- cols$columna
  dplyr::bind_cols(tibble::tibble(nivel = niveles, codigo = codigo), valores) |>
    filter(!is.na(codigo)) |>
    tidyr::pivot_longer(all_of(cols$columna), names_to = "columna", values_to = "valor") |>
    inner_join(cols, by = "columna") |>
    select(-columna) |>
    tidyr::pivot_wider(names_from = medida, values_from = valor) |>
    select(nivel, codigo, anio, tipologia, all_of(MEDIDAS_SERPAVI)) |>
    arrange(nivel, codigo, anio, tipologia)
}

# Lee las cinco hojas con datos desde el año `desde` (el alcance del atlas empieza en 2015).
# Solo se cargan las columnas que se usan; los datos, como números. Unas pocas celdas numéricas
# vienen guardadas como texto («600»): readxl las convierte bien y su aviso se calla.
leer_mivau_serpavi <- function(ruta, desde = 2015L) {
  callar_texto <- function(w) if (grepl("^Coercing text to numeric", conditionMessage(w))) invokeRestart("muffleWarning")
  dplyr::bind_rows(lapply(names(HOJAS_SERPAVI), function(nivel) {
    hoja <- HOJAS_SERPAVI[[nivel]]
    nombres <- names(readxl::read_excel(ruta, sheet = hoja, n_max = 0, .name_repair = "minimal"))
    cols <- columnas_serpavi(nombres)
    usar <- nombres %in% cols$columna[cols$anio >= desde]
    tipos <- ifelse(usar, "numeric", ifelse(nombres == CODIGO_HOJA_SERPAVI[[nivel]], "text", "skip"))
    datos <- withCallingHandlers(
      readxl::read_excel(ruta, sheet = hoja, col_types = tipos, .name_repair = "minimal"),
      warning = callar_texto)
    ordenar_hoja_serpavi(datos, nivel, desde)
  }))
}

# Coherencia de cada fila (territorio, año y tipología) consigo misma:
#   secreto_roto: mediana publicada con menos de 10 testigos, o 10 o más testigos sin mediana;
#   cuartiles_rotos: mediana sin cuartiles o sin su par (mensual / por m²), o P25 > P50 > P75 desordenados.
incoherencias_serpavi <- function(serpavi, holgura = 1e-9) {
  desordenados <- function(p25, p50, p75) coalesce(p25 > p50 + holgura | p50 > p75 + holgura, FALSE)
  serpavi |>
    mutate(
      con_mediana = !is.na(alquiler_mes_p50),
      secreto_roto = (con_mediana & coalesce(testigos, 0) < 10) | (!con_mediana & coalesce(testigos, 0) >= 10),
      cuartiles_rotos = (con_mediana & (is.na(alquiler_mes_p25) | is.na(alquiler_mes_p75) | is.na(alquiler_m2_p25) |
                                          is.na(alquiler_m2_p50) | is.na(alquiler_m2_p75))) |
        (!con_mediana & !is.na(alquiler_m2_p50)) |
        desordenados(alquiler_mes_p25, alquiler_mes_p50, alquiler_mes_p75) |
        desordenados(alquiler_m2_p25, alquiler_m2_p50, alquiler_m2_p75)
    ) |>
    select(-con_mediana)
}

# Municipios y distritos que existen en el seccionado de 2021 (tienen secciones en la hoja de secciones).
unidades_con_secciones <- function(serpavi) {
  sc <- unique(serpavi$codigo[serpavi$nivel == "sc"])
  dplyr::bind_rows(lapply(c("municipio", "distrito"), function(niv) {
    tibble::tibble(nivel = niv, codigo = unique(substr(sc, 1, NIVELES[[niv]])))
  }))
}

# Municipios y distritos que no cuadran con sus secciones, por año y tipología, con el motivo:
#   recuento: testigos distintos de la suma de los de sus secciones (vacío = 0);
#   secreto o cuartiles: ver incoherencias_serpavi();
#   seccion: con una sola sección, alguna cifra distinta de la de esa sección en más de una
#     milésima (algunas hojas vienen redondeadas a cuatro decimales: 485,9467 frente a 485,94666…).
descuadres_serpavi <- function(serpavi, holgura = 1e-3) {
  sc <- filter(serpavi, nivel == "sc")
  distintos <- function(a, b) xor(is.na(a), is.na(b)) | coalesce(abs(a - b) > holgura, FALSE)
  dplyr::bind_rows(lapply(c("municipio", "distrito"), function(niv) {
    sc_niv <- mutate(sc, superior = substr(codigo, 1, NIVELES[[niv]]))
    agregado <- sc_niv |>
      group_by(codigo = superior, anio, tipologia) |>
      summarise(secciones = n(), suma = sum(testigos, na.rm = TRUE), .groups = "drop")
    unica <- sc_niv |>
      semi_join(filter(agregado, secciones == 1), by = c(superior = "codigo", "anio", "tipologia")) |>
      select(codigo = superior, anio, tipologia, all_of(MEDIDAS_SERPAVI)) |>
      rename_with(~ paste0(.x, "_sc"), all_of(MEDIDAS_SERPAVI))
    x <- serpavi |>
      filter(nivel == niv) |>
      incoherencias_serpavi() |>
      inner_join(agregado, by = c("codigo", "anio", "tipologia")) |>
      left_join(unica, by = c("codigo", "anio", "tipologia"))
    distinta <- rep(FALSE, nrow(x))
    for (m in setdiff(MEDIDAS_SERPAVI, "testigos")) {
      distinta <- distinta | (x$secciones == 1 & distintos(x[[m]], x[[paste0(m, "_sc")]]))
    }
    x |>
      mutate(motivo = case_when(coalesce(testigos, 0) != suma ~ "recuento",
                                secreto_roto ~ "secreto",
                                cuartiles_rotos ~ "cuartiles",
                                distinta ~ "seccion",
                                TRUE ~ NA_character_)) |>
      filter(!is.na(motivo)) |>
      select(nivel, codigo, anio, tipologia, motivo, testigos, suma)
  }))
}

# Compuerta (inventario/referencias_validacion.csv):
#   serpavi_provincia (bloqueo): testigos de las secciones sumados a provincia = hoja Provincias;
#   serpavi_espana (bloqueo): testigos de las secciones (sin las provincias forales de una
#     comunidad todavía sin cifra) y de las comunidades sumados = fila de España;
#   serpavi_secreto y serpavi_cuartiles (bloqueo): filas incoherentes en secciones, provincias y comunidades;
#   serpavi_escalas (bloqueo, ±1 %): porcentaje de municipios y distritos que no cuadran con sus secciones;
#   serpavi_escalas_detalle (alerta): cada uno de ellos (van como «ausente» en la tabla larga);
#   serpavi_forales (alerta): primer año con testigos de cada provincia foral frente a la ruptura;
#   con `secciones` (las del seccionado de 2021), una fila por nivel (sección, distrito y municipio):
#     serpavi_seccionado (bloqueo), territorios de la base fuera del seccionado (las secciones,
#     todas; los distritos y municipios, los que tienen testigos o mediana algún año: las hojas
#     traen 68 distritos y 4 municipios de fuera, vacíos, que quedan fuera de la tabla larga), y
#     serpavi_sin_fila (alerta), territorios del seccionado que la base no trae (van como
#     «ausente»: completar_secciones_serpavi()). Con PROVINCIA, solo las provincias del seccionado leído.
comprobar_mivau_serpavi <- function(serpavi, entrada_forales = ENTRADA_SERPAVI_FORALES,
                                    comunidad_foral = COMUNIDAD_FORAL_SERPAVI, secciones = NULL) {
  sc <- filter(serpavi, nivel == "sc")
  publicado <- function(niv) serpavi |> filter(nivel == niv) |>
    transmute(codigo, anio, tipologia, referencia = coalesce(testigos, 0))

  provincia <- sc |>
    group_by(codigo = substr(codigo, 1, 2), anio, tipologia) |>
    summarise(calculado = sum(testigos, na.rm = TRUE), .groups = "drop") |>
    full_join(publicado("provincia"), by = c("codigo", "anio", "tipologia")) |>
    transmute(id = "serpavi_provincia", anio, detalle = paste(codigo, tipologia), calculado, referencia)

  ccaa_sin_cifra <- serpavi |> filter(nivel == "ccaa", is.na(testigos)) |>
    transmute(ccaa = codigo, anio, tipologia, fuera = TRUE)
  espana <- dplyr::bind_rows(
    sc |>
      mutate(ccaa = unname(comunidad_foral[substr(codigo, 1, 2)])) |>
      left_join(ccaa_sin_cifra, by = c("ccaa", "anio", "tipologia")) |>
      filter(is.na(fuera)) |>
      group_by(anio, tipologia) |> summarise(calculado = sum(testigos, na.rm = TRUE), .groups = "drop") |>
      mutate(origen = "secciones"),
    serpavi |> filter(nivel == "ccaa") |> group_by(anio, tipologia) |>
      summarise(calculado = sum(testigos, na.rm = TRUE), .groups = "drop") |> mutate(origen = "comunidades")
  ) |>
    left_join(select(publicado("nacional"), -codigo), by = c("anio", "tipologia")) |>
    transmute(id = "serpavi_espana", anio, detalle = paste(origen, tipologia), calculado, referencia)

  propias <- serpavi |>
    filter(nivel %in% c("sc", "provincia", "ccaa")) |>
    incoherencias_serpavi() |>
    group_by(anio, nivel, tipologia) |>
    summarise(secreto = sum(secreto_roto), cuartiles = sum(cuartiles_rotos), .groups = "drop")
  secreto <- transmute(propias, id = "serpavi_secreto", anio, detalle = paste(nivel, tipologia),
                       calculado = secreto, referencia = 0)
  cuartiles <- transmute(propias, id = "serpavi_cuartiles", anio, detalle = paste(nivel, tipologia),
                         calculado = cuartiles, referencia = 0)

  d <- descuadres_serpavi(serpavi)
  escalas <- serpavi |>
    semi_join(unidades_con_secciones(serpavi), by = c("nivel", "codigo")) |>
    count(anio, nivel, name = "filas") |>
    left_join(count(d, anio, nivel, name = "descuadres"), by = c("anio", "nivel")) |>
    transmute(id = "serpavi_escalas", anio, detalle = nivel,
              calculado = 100 * coalesce(descuadres, 0L) / filas, referencia = 0)
  escalas_detalle <- d |>
    transmute(id = "serpavi_escalas_detalle", anio,
              detalle = paste(nivel, codigo, tipologia, motivo), calculado = 1, referencia = 0)

  forales <- sc |>
    filter(substr(codigo, 1, 2) %in% names(entrada_forales), coalesce(testigos, 0) > 0) |>
    group_by(provincia = substr(codigo, 1, 2)) |>
    summarise(calculado = min(anio), .groups = "drop") |>
    right_join(tibble::tibble(provincia = names(entrada_forales), referencia = unname(entrada_forales)),
               by = "provincia") |>
    transmute(id = "serpavi_forales", anio = NA_integer_, detalle = provincia, calculado, referencia)

  seccionado <- if (!is.null(secciones)) {
    secciones <- unique(secciones)
    niveles <- c(sc = "secciones", distrito = "distritos", municipio = "municipios")
    ambito <- filter(serpavi, nivel %in% names(niveles), substr(codigo, 1, 2) %in% substr(secciones, 1, 2))
    fuera <- vapply(names(niveles), function(niv) {
      x <- filter(ambito, nivel == niv)
      if (niv != "sc") x <- filter(x, coalesce(testigos, 0) > 0 | !is.na(alquiler_mes_p50))
      sum(!unique(x$codigo) %in% substr(secciones, 1, NIVELES[[niv]]))
    }, numeric(1))
    con_fila <- filter(serpavi, nivel == "sc" | paste(nivel, codigo) %in% do.call(paste, unidades_con_secciones(serpavi)))
    faltan <- faltan_seccionado_serpavi(con_fila, secciones)
    sin_fila <- vapply(names(niveles), function(niv) sum(faltan$nivel == niv), numeric(1))
    tibble::tibble(id = rep(c("serpavi_seccionado", "serpavi_sin_fila"), each = length(niveles)), anio = NA_integer_,
                   detalle = c(paste(niveles, "de la base fuera del seccionado de 2021",
                                     c("", "(con testigos o mediana)", "(con testigos o mediana)")) |> trimws(),
                               paste(niveles, "del seccionado de 2021 sin fila en la base (van como ausente)")),
                   calculado = c(fuera, sin_fila), referencia = 0)
  }

  dplyr::bind_rows(provincia, espana, secreto, cuartiles, escalas, escalas_detalle, forales, seccionado) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Estado de cada territorio, año y tipología:
#   dato: mediana publicada;
#   secreto: de 1 a 9 testigos (el SERPAVI solo publica el recuento); nunca 0;
#   ausente: sin testigos o fuera de la cobertura (forales antes de su entrada, municipios y
#     distritos que no cuadran con sus secciones, y España, que no tiene medianas).
# Los municipios y distritos que no existen en el seccionado de 2021 (sin secciones) quedan fuera.
estado_serpavi <- function(serpavi, entrada_forales = ENTRADA_SERPAVI_FORALES) {
  descuadre <- descuadres_serpavi(serpavi) |> distinct(nivel, codigo, anio, tipologia) |> mutate(descuadre = TRUE)
  provincia <- ifelse(serpavi$nivel == "ccaa", NA_character_, substr(serpavi$codigo, 1, 2))
  entrada <- unname(entrada_forales[provincia])
  serpavi |>
    mutate(antes_de_entrar = !is.na(entrada) & anio < entrada) |>
    filter(!nivel %in% c("municipio", "distrito") |
             paste(nivel, codigo) %in% do.call(paste, unidades_con_secciones(serpavi))) |>
    filter(nivel != "nacional" | !is.na(alquiler_mes_p50)) |>
    left_join(descuadre, by = c("nivel", "codigo", "anio", "tipologia")) |>
    mutate(estado = case_when(antes_de_entrar | coalesce(descuadre, FALSE) ~ "ausente",
                              !is.na(alquiler_mes_p50) ~ "dato",
                              coalesce(testigos, 0) >= 1 ~ "secreto",
                              TRUE ~ "ausente")) |>
    select(-antes_de_entrar, -descuadre)
}

# Territorios del seccionado de 2021 (las secciones y los distritos y municipios que forman) sin
# fila en `filas` (columnas nivel y codigo).
faltan_seccionado_serpavi <- function(filas, secciones) {
  dplyr::bind_rows(lapply(c("sc", "distrito", "municipio"), function(niv) {
    tibble::tibble(nivel = niv, codigo = setdiff(unique(substr(secciones, 1, NIVELES[[niv]])),
                                                 filas$codigo[filas$nivel == niv]))
  }))
}

# Secciones del seccionado de 2021 que la base no trae (edición 2011–2024: 40), y distritos y
# municipios que les faltan (36 y 36). 36 secciones son municipios de una sola sección (34 de
# Navarra, uno de Álava y uno de Bizkaia), que tampoco están en las hojas de municipios y
# distritos; las otras 4 (Madrid, Las Palmas de Gran Canaria y Zaragoza) no tienen testigos: su
# distrito suma lo mismo que sus secciones publicadas. Van como «ausente» en todos los años y
# tipologías, igual que un territorio sin testigos, para que los indicadores 8 y 9, y sus
# derivados, tengan fila en todas las secciones, distritos y municipios del mapa. Sin `secciones`,
# no cambia nada.
completar_secciones_serpavi <- function(filas, secciones = NULL) {
  if (is.null(secciones)) return(filas)
  faltan <- faltan_seccionado_serpavi(filas, secciones)
  if (!nrow(faltan)) return(filas)
  sc <- filter(filas, nivel == "sc")
  nuevas <- tidyr::expand_grid(faltan, anio = sort(unique(sc$anio)), tipologia = sort(unique(sc$tipologia))) |>
    mutate(estado = "ausente")
  dplyr::bind_rows(filas, nuevas)
}

# Formato largo de la tabla única: indicadores alquiler_mes (8) y alquiler_m2 (9), con la
# tipología como corte. La mediana va en el corte «tipologia» (grupo VC o VU) con su estado; los
# cuartiles, en «tipologia_p25» y «tipologia_p75», solo donde hay dato. El SERPAVI no publica
# una mediana conjunta de las dos tipologías, así que no hay filas «total». Con `secciones`, las
# secciones, distritos y municipios del seccionado de 2021 que la base no trae van como «ausente»
# (completar_secciones_serpavi()).
armonizar_mivau_serpavi <- function(serpavi, version, entrada_forales = ENTRADA_SERPAVI_FORALES,
                                    secciones = NULL) {
  filas <- completar_secciones_serpavi(estado_serpavi(serpavi, entrada_forales), secciones)
  cortes <- c(p50 = "tipologia", p25 = "tipologia_p25", p75 = "tipologia_p75")
  partes <- list()
  for (ind in c("alquiler_mes", "alquiler_m2")) {
    for (est in names(cortes)) {
      columna <- paste0(ind, "_", est)
      partes[[columna]] <- filas |>
        filter(est == "p50" | estado == "dato") |>
        transmute(geo_id = codigo, nivel, anio, indicador = ind, corte = cortes[[est]], grupo = tipologia,
                  valor = if_else(estado == "dato", .data[[columna]], NA_real_), estado)
    }
  }
  dplyr::bind_rows(partes) |>
    mutate(fuente = "mivau_serpavi", geo_ref = "2021", version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA))
}

# Cifras para el informe: secciones con dato, secreto y ausente por año y tipología, y cobertura
# por provincia (secciones con mediana de vivienda colectiva sobre el total de la provincia).
resumen_serpavi <- function(larga) {
  sc <- filter(larga, nivel == "sc", indicador == "alquiler_mes", corte == "tipologia")
  list(
    estados = sc |> count(anio, grupo, estado) |> tidyr::pivot_wider(names_from = estado, values_from = n, values_fill = 0L),
    provincias = sc |> filter(grupo == "VC") |>
      group_by(provincia = substr(geo_id, 1, 2), anio) |>
      summarise(secciones = n(), dato = sum(estado == "dato"), secreto = sum(estado == "secreto"),
                cobertura = 100 * dato / secciones, .groups = "drop")
  )
}
