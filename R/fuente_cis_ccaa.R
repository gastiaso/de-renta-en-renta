# CIS por comunidad autónoma (tarea 63; docs/especificacion_cis_comunidad.md, «Revisión del
# 13-nov-2026»): la vivienda entre los tres principales problemas de España y entre los tres que más
# afectan personalmente, por comunidad y año, desde 2021, con su intervalo al 95 %.
#
# Fuente: los microdatos armonizados de los barómetros mensuales del CIS que publica *Barómetro a
# barómetro* (https://gastiaso.github.io/barometros/, repositorio público gastiaso/barometros), en
# ediciones fechadas (release vAAAA-MM) con licencia CC BY 4.0 para la armonización; los datos de
# origen, con las condiciones del CIS. Una fila por entrevista: estudio, mes, peso (el PESO del CIS),
# ccaa (las 19 comunidades y ciudades autónomas) y las tres menciones de las dos preguntas de
# problemas (prob_esp_1 a 3 y prob_per_1 a 3, códigos armonizados: «La vivienda» es PROB_007; la
# ocupación de viviendas, PROB_081, va aparte y no se suma). Con el Parquet, metadatos_vAAAA-MM.json:
# entrevistas y efecto de diseño de cada estudio, categorías y rupturas de serie.
#
# Descarga automática y sin registro (descargar_con_cache()) de la edición de
# inventario/cis_ccaa_ficheros.csv, que guarda la URL, el tamaño y la suma SHA-256 de cada fichero:
# una suma distinta para el pipeline. Edición nueva: fila nueva en ese CSV (calendario, «codigo»).
# Los nombres de las comunidades del Parquet se casan con los códigos del INE por tabla fija
# (inventario/cis_ccaa_comunidades.csv), que dice también qué comunidades se agrupan de dos en dos años.
#
# Método (decisiones del autor, 13-nov-2026; el mismo que describe la herramienta):
#   - cifra: % de entrevistados que cita PROB_007 en alguna de sus hasta tres menciones, con `peso`
#     (no `peso_ccaa`: desde la ruptura R10 su suma no reproduce la cifra nacional publicada);
#   - base: quien tiene una primera mención distinta de «no procede» (NP); NS y NC cuentan;
#   - año: todas las entrevistas del año juntas (no la media de los meses); el año en curso, con los
#     meses publicados y rotulado «hasta {mes}»;
#   - Ceuta y Melilla, de dos en dos años: el año y el anterior, con `anio` = el último (como los
#     cruces de varias olas de la ECV);
#   - intervalo de Wilson al 95 % sobre el tamaño efectivo, n / efecto de diseño de Kish de la base
#     (n · Σw² / (Σw)²); margen = la mitad del intervalo;
#   - nada con menos de 50 entrevistas en la base (estado «ausente», sin cifra);
#   - rupturas de tipo C de las dos preguntas (R10, noviembre de 2023: ponderación con ajuste por
#     nivel educativo): el periodo que las cruza se marca (`ruptura`) y no se calculan variaciones a
#     través de ellas (la tabla no trae variaciones).
# No entra en la tabla larga (es opinión, no registro, y la tabla larga es por sección): tabla propia
# cis_vivienda_ccaa, CSV y JSON para la web (Máquina del tiempo y ficha de comunidad del mapa).

CIS_CCAA_DIR <- file.path("datos", "brutos", "cis_ccaa")
CIS_CCAA_VIVIENDA <- "PROB_007"
CIS_CCAA_NO_PROCEDE <- "NP"
CIS_CCAA_MINIMO <- 50L          # entrevistas en la base por debajo de las cuales no hay cifra
CIS_CCAA_Z <- stats::qnorm(0.975)
CIS_CCAA_ESPANA <- "00"
CIS_CCAA_COLUMNAS <- c(espana = "prob_esp_", personal = "prob_per_")

# Inventario de la edición: una fila por fichero (edicion, tipo «microdatos» o «metadatos», fichero,
# url, bytes, sha256). Se usa la edición más reciente.
cis_ccaa_leer_ficheros <- function(ruta) {
  x <- readr::read_csv(ruta, col_types = readr::cols(bytes = "d", .default = "c"), na = "")
  falta <- setdiff(c("edicion", "tipo", "fichero", "url", "bytes", "sha256"), names(x))
  if (length(falta)) stop("Faltan columnas en ", ruta, ": ", paste(falta, collapse = ", "), call. = FALSE)
  x
}

cis_ccaa_edicion <- function(ficheros) {
  ultima <- max(ficheros$edicion)
  x <- ficheros[ficheros$edicion == ultima, ]
  if (!setequal(x$tipo, c("microdatos", "metadatos")) || anyDuplicated(x$tipo)) {
    stop("inventario/cis_ccaa_ficheros.csv: la edici\u00f3n ", ultima, " debe tener un fichero de microdatos y uno de metadatos.",
         call. = FALSE)
  }
  x
}

cis_ccaa_sha256 <- function(ruta) digest::digest(ruta, algo = "sha256", file = TRUE)

# Ruta de un tipo entre las de un objetivo de formato «file» (por su nombre o, si targets lo pierde,
# por la extension): «microdatos» (.parquet), «metadatos» o «json» (.json), «csv» (.csv).
cis_ccaa_ruta <- function(rutas, tipo) {
  if (!is.null(names(rutas)) && tipo %in% names(rutas)) return(unname(rutas[[tipo]]))
  ext <- c(microdatos = "parquet", metadatos = "json", json = "json", csv = "csv")[[tipo]]
  r <- rutas[tolower(tools::file_ext(rutas)) == ext]
  if (length(r) != 1) stop("CIS por comunidad: no se encuentra el fichero ", tipo, " entre ", paste(rutas, collapse = ", "), call. = FALSE)
  r
}

# Descarga de la edición con caché en datos/brutos/cis_ccaa/<edición>/ y comprobación del tamaño y de
# la suma: si no coinciden, se para (el fichero se queda para poder mirarlo). Devuelve las dos rutas,
# con el nombre de su tipo (para un objetivo de formato «file»).
cis_ccaa_descargar <- function(ficheros, dir = CIS_CCAA_DIR) {
  ed <- cis_ccaa_edicion(ficheros)
  rutas <- vapply(seq_len(nrow(ed)), function(i) {
    destino <- file.path(dir, ed$edicion[i], ed$fichero[i])
    descargar_con_cache(ed$url[i], destino)
    suma <- cis_ccaa_sha256(destino)
    if (!identical(suma, ed$sha256[i]) || file.size(destino) != ed$bytes[i]) {
      stop("CIS por comunidad: ", destino, " no es el de la edici\u00f3n ", ed$edicion[i], " (", file.size(destino),
           " bytes, SHA-256 ", suma, "; se esperaban ", ed$bytes[i], " bytes y ", ed$sha256[i],
           "). B\u00f3rralo para volver a bajarlo o revisa inventario/cis_ccaa_ficheros.csv.", call. = FALSE)
    }
    destino
  }, character(1))
  stats::setNames(rutas, ed$tipo)
}

# Compuerta cis_ccaa_fichero (bloqueo): ficheros con tamaño o suma distintos de los del inventario.
cis_ccaa_comprobar_ficheros <- function(rutas, ficheros) {
  ed <- cis_ccaa_edicion(ficheros)
  ruta <- vapply(ed$tipo, function(k) cis_ccaa_ruta(rutas, k), character(1))
  mal <-!file.exists(ruta) | file.size(ruta) != ed$bytes |
    vapply(ruta, function(r) if (file.exists(r)) cis_ccaa_sha256(r) else "", character(1)) != ed$sha256
  tibble::tibble(id = "cis_ccaa_fichero", anio = NA_integer_, detalle = paste(ed$edicion, ed$fichero),
                 calculado = as.numeric(mal), referencia = 0)
}

# Tabla fija de las comunidades: codigo (INE), nombre_cis (el de la columna ccaa del Parquet) y
# agrupar_anios (1, o 2 para Ceuta y Melilla).
cis_ccaa_leer_comunidades <- function(ruta) {
  x <- readr::read_csv(ruta, col_types = readr::cols(agrupar_anios = "i", .default = "c"), na = "")
  falta <- setdiff(c("codigo", "nombre_cis", "agrupar_anios"), names(x))
  if (length(falta)) stop("Faltan columnas en ", ruta, ": ", paste(falta, collapse = ", "), call. = FALSE)
  x
}

# Lectura de la edición: microdatos (solo las columnas que hacen falta, como texto) y, de los
# metadatos, los estudios (estudio, mes, n, deff), las rupturas, la etiqueta de PROB_007 y las
# categorías de la comunidad.
cis_ccaa_leer <- function(rutas) {
  columnas <- c("estudio", "mes", "peso", "ccaa", paste0(rep(CIS_CCAA_COLUMNAS, each = 3), 1:3))
  d <- arrow::read_parquet(cis_ccaa_ruta(rutas, "microdatos"), col_select = tidyselect::all_of(columnas))
  d <- dplyr::mutate(tibble::as_tibble(d), dplyr::across(-peso, as.character), peso = as.numeric(peso))
  m <- jsonlite::read_json(cis_ccaa_ruta(rutas, "metadatos"))
  texto <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  estudios <- dplyr::bind_rows(lapply(m$estudios, function(e) tibble::tibble(
    estudio = texto(e$estudio), mes = texto(e$mes), n = as.numeric(e$n %||% NA), deff = as.numeric(e$deff %||% NA))))
  rupturas <- dplyr::bind_rows(lapply(m$rupturas, function(r) tibble::tibble(
    ruptura = texto(r$ruptura_id), mes = texto(r$mes), estudio = texto(r$estudio), tipo = texto(r$tipo),
    conceptos = texto(r$conceptos_afectados), estado = texto(r$estado), descripcion = texto(r$descripcion))))
  categorias <- function(concepto) {
    cats <- m$conceptos[[concepto]]$categorias
    tibble::tibble(id = vapply(cats, function(k) texto(k$id), ""), etiqueta = vapply(cats, function(k) texto(k$etiqueta), ""))
  }
  list(microdatos = d, estudios = estudios, rupturas = rupturas,
       problemas = list(espana = categorias("prob_esp_1"), personal = categorias("prob_per_1")),
       comunidades = categorias("ccaa")$id,
       fuente = texto(m$fuente), generado = texto(m$generado))
}

# Rupturas que cortan las dos preguntas: de tipo C, para todas las variables o para las de problemas
# (R10, noviembre de 2023). Meses «AAAA-MM».
cis_ccaa_rupturas <- function(rupturas) {
  r <- rupturas[rupturas$tipo %in% "C" & (rupturas$conceptos %in% "todas" | grepl("prob_", rupturas$conceptos, fixed = TRUE)), ]
  r[grepl("^\\d{4}-\\d{2}$", r$mes), ]
}

# Formato largo: una fila por entrevista y pregunta, con el código del INE de la comunidad, si está en
# la base (primera mención distinta de NP) y si cita la vivienda en alguna de las tres menciones.
cis_ccaa_menciones <- function(leido, comunidades) {
  d <- leido$microdatos
  codigo <- comunidades$codigo[match(d$ccaa, comunidades$nombre_cis)]
  filas <- lapply(names(CIS_CCAA_COLUMNAS), function(p) {
    col <- paste0(CIS_CCAA_COLUMNAS[[p]], 1:3)
    primera <- d[[col[1]]]
    cita <- Reduce(`|`, lapply(col, function(k) d[[k]] %in% CIS_CCAA_VIVIENDA))
    tibble::tibble(estudio = d$estudio, mes = d$mes, anio = as.integer(substr(d$mes, 1, 4)), codigo = codigo,
                   pregunta = p, peso = d$peso, en_base = !is.na(primera) & primera != CIS_CCAA_NO_PROCEDE,
                   menciona = cita)
  })
  dplyr::bind_rows(filas)
}

# Intervalo de Wilson para una proporcion p (0-1) con un tamano efectivo n_ef: list(inferior, superior).
cis_ccaa_wilson <- function(p, n_ef, z = CIS_CCAA_Z) {
  den <- 1 + z^2 / n_ef
  centro <- (p + z^2 / (2 * n_ef)) / den
  medio <- z * sqrt(p * (1 - p) / n_ef + z^2 / (4 * n_ef^2)) / den
  list(inferior = centro - medio, superior = centro + medio)
}

# Cifra de un grupo de entrevistas de la base: % ponderado, entrevistas, suma de pesos, efecto de
# diseno de Kish, tamano efectivo e intervalo de Wilson (en %).
cis_ccaa_estimar <- function(menciona, peso) {
  n <- length(peso)
  if (n == 0) {
    return(tibble::tibble(valor = NA_real_, entrevistas = 0L, suma_pesos = 0, deff = NA_real_, n_efectivo = NA_real_,
                          inferior = NA_real_, superior = NA_real_, margen = NA_real_))
  }
  sw <- sum(peso)
  p <- sum(peso * menciona) / sw
  deff <- n * sum(peso^2) / sw^2
  n_ef <- n / deff
  w <- cis_ccaa_wilson(p, n_ef)
  tibble::tibble(valor = 100 * p, entrevistas = as.integer(n), suma_pesos = sw, deff = deff, n_efectivo = n_ef,
                 inferior = 100 * w$inferior, superior = 100 * w$superior, margen = 100 * (w$superior - w$inferior) / 2)
}

# España por mes y pregunta (toda la base, con `peso`): para la compuerta frente a la serie nacional.
cis_ccaa_mensual <- function(menciones) {
  menciones |>
    dplyr::filter(en_base) |>
    dplyr::group_by(mes, estudio, pregunta) |>
    dplyr::reframe(cis_ccaa_estimar(menciona, peso)) |>
    dplyr::mutate(anio = as.integer(substr(mes, 1, 4)), mes_num = as.integer(substr(mes, 6, 7)), .after = mes)
}

# Cifras de un año natural por comunidad (las 19 y España, sin agrupar): para la compuerta de la suma.
cis_ccaa_por_anio <- function(menciones) {
  base <- dplyr::filter(menciones, en_base)
  ccaa <- base |>
    dplyr::group_by(codigo, anio, pregunta) |>
    dplyr::reframe(cis_ccaa_estimar(menciona, peso))
  espana <- base |>
    dplyr::group_by(anio, pregunta) |>
    dplyr::reframe(cis_ccaa_estimar(menciona, peso)) |>
    dplyr::mutate(codigo = CIS_CCAA_ESPANA, .before = 1)
  dplyr::bind_rows(ccaa, espana)
}

# Tabla cis_vivienda_ccaa: una fila por comunidad (y España), año y pregunta. Columnas: codigo,
# nombre, anio, desde y hasta (primer y último mes del periodo), anios (1 o 2), pregunta, valor,
# inferior, superior, margen (puntos), entrevistas, deff, meses (barómetros), en_curso (el periodo
# acaba en el año en curso), ruptura (el periodo cruza una ruptura de tipo C) y estado («dato» o
# «ausente», con menos de 50 entrevistas). `nombres`: geo/ccaa.csv (codigo, nombre_ine).
cis_ccaa_tabla <- function(menciones, comunidades, rupturas, nombres) {
  base <- dplyr::filter(menciones, en_base)
  ultimo <- max(base$mes)
  anio_ultimo <- as.integer(substr(ultimo, 1, 4))
  completo <- substr(ultimo, 6, 7) == "12"
  cortes <- cis_ccaa_rupturas(rupturas)$mes
  anios <- sort(unique(base$anio))
  grupos <- dplyr::bind_rows(comunidades[c("codigo", "agrupar_anios")],
                             tibble::tibble(codigo = CIS_CCAA_ESPANA, agrupar_anios = 1L))
  celdas <- tidyr::expand_grid(grupos, anio = anios, pregunta = names(CIS_CCAA_COLUMNAS))
  tabla <- dplyr::bind_rows(lapply(seq_len(nrow(celdas)), function(i) {
    g <- celdas[i, ]
    ventana <- seq(g$anio - g$agrupar_anios + 1L, g$anio)
    x <- base[base$anio %in% ventana & base$pregunta == g$pregunta &
                (g$codigo == CIS_CCAA_ESPANA | base$codigo %in% g$codigo), ]
    dplyr::bind_cols(
      tibble::tibble(codigo = g$codigo, anio = g$anio,
                     desde = if (nrow(x)) min(x$mes) else NA_character_, hasta = if (nrow(x)) max(x$mes) else NA_character_,
                     anios = length(intersect(ventana, anios)), pregunta = g$pregunta),
      cis_ccaa_estimar(x$menciona, x$peso), tibble::tibble(meses = length(unique(x$mes))))
  }))
  tabla |>
    dplyr::mutate(
      nombre = ifelse(codigo == CIS_CCAA_ESPANA, "Espa\u00f1a", nombres$nombre_ine[match(codigo, nombres$codigo)]),
      en_curso = anio == anio_ultimo & !completo,
      ruptura = vapply(seq_along(desde), function(k) any(!is.na(desde[k]) & cortes > desde[k] & cortes <= hasta[k]), logical(1)),
      estado = ifelse(entrevistas >= CIS_CCAA_MINIMO, "dato", "ausente"),
      dplyr::across(c(valor, inferior, superior, margen, deff, n_efectivo), ~ ifelse(estado == "dato", .x, NA_real_))
    ) |>
    dplyr::select(codigo, nombre, anio, desde, hasta, anios, pregunta, valor, inferior, superior, margen,
                  entrevistas, deff, n_efectivo, meses, en_curso, ruptura, estado) |>
    dplyr::arrange(pregunta, anio, codigo)
}

# Compuertas (inventario/referencias_validacion.csv):
#   cis_ccaa_espana (bloqueo): cada mes de España calculado desde el Parquet, a un decimal, frente a
#     la cifra publicada de la serie nacional (tabla cis_vivienda), ±0,1 puntos, las dos preguntas;
#   cis_ccaa_suma (bloqueo): por año natural y pregunta, la media de las comunidades ponderada por la
#     suma de sus pesos, frente a la cifra de España (diferencia máxima);
#   cis_ccaa_muestra (bloqueo): entrevistas de cada estudio en el Parquet frente a las de los
#     metadatos, y frente al (N) de las tabulaciones del CIS de ese mes (tabla cis_vivienda);
#   cis_ccaa_codigos (bloqueo): PROB_007 con la etiqueta «La vivienda» en las dos preguntas; las 19
#     comunidades de los metadatos y del Parquet, todas en la tabla fija; pesos positivos y sin
#     hueco; meses y estudios del Parquet en los metadatos;
#   cis_ccaa_margen (alerta): cifras publicadas con un margen de más de ±5 puntos;
#   cis_ccaa_meses (alerta): años con menos de nueve barómetros (fuera del año en curso) y meses
#     del Parquet sin cifra nacional publicada con la que contrastarlos.
cis_ccaa_comprobar <- function(leido, menciones, mensual, por_anio, tabla, comunidades, cis_vivienda) {
  pub <- dplyr::transmute(cis_vivienda, mes = periodo, pregunta, publicado = total, n_publicado = n)
  cruce <- dplyr::left_join(mensual, pub, by = c("mes", "pregunta"))
  con <- cruce[!is.na(cruce$publicado), ]
  espana <- tibble::tibble(id = "cis_ccaa_espana", anio = con$anio,
                           detalle = sprintf("%s %s (estudio %s)", con$mes, con$pregunta, con$estudio),
                           calculado = cis_un_decimal(con$valor), referencia = cis_un_decimal(con$publicado))
  if (!nrow(espana)) {
    espana <- tibble::tibble(id = "cis_ccaa_espana", anio = NA_integer_, detalle = "ning\u00fan mes con cifra publicada",
                             calculado = 1, referencia = 0)
  }
  sin_contraste <- cruce[is.na(cruce$publicado), ]
  # suma: comunidades ponderadas por su suma de pesos frente a Espana
  ccaa <- por_anio[por_anio$codigo != CIS_CCAA_ESPANA, ]
  agregada <- ccaa |>
    dplyr::group_by(anio, pregunta) |>
    dplyr::summarise(agregada = sum(valor * suma_pesos) / sum(suma_pesos), .groups = "drop") |>
    dplyr::inner_join(dplyr::select(por_anio[por_anio$codigo == CIS_CCAA_ESPANA, ], anio, pregunta, valor), by = c("anio", "pregunta"))
  suma <- tibble::tibble(id = "cis_ccaa_suma", anio = agregada$anio, detalle = paste("comunidades frente a Espa\u00f1a,", agregada$pregunta),
                         calculado = abs(agregada$agregada - agregada$valor), referencia = 0)
  # muestra
  d <- leido$microdatos
  por_estudio <- dplyr::count(d, estudio, mes, name = "n_parquet")
  meta <- dplyr::left_join(por_estudio, leido$estudios[c("estudio", "n")], by = "estudio")
  n_pub <- dplyr::distinct(dplyr::filter(pub, !is.na(n_publicado)), mes, n_publicado)
  n_pub <- n_pub[!duplicated(n_pub$mes), ]
  tab <- dplyr::inner_join(por_estudio, n_pub, by = "mes")
  muestra <- tibble::tibble(
    id = "cis_ccaa_muestra", anio = NA_integer_,
    detalle = c("estudios con otras entrevistas que en los metadatos", "meses con otras entrevistas que el (N) del CIS"),
    calculado = c(sum(is.na(meta$n) | meta$n != meta$n_parquet), sum(abs(tab$n_publicado - tab$n_parquet) > 0.5)),
    referencia = 0)
  # codigos
  etiqueta <- vapply(leido$problemas, function(cats) {
    e <- cats$etiqueta[cats$id == CIS_CCAA_VIVIENDA]
    length(e) == 1 && grepl("^(la )?vivienda$", trimws(e), ignore.case = TRUE)
  }, logical(1))
  meses_meta <- unique(leido$estudios$mes)
  codigos <- tibble::tibble(
    id = "cis_ccaa_codigos", anio = NA_integer_,
    detalle = c("preguntas sin PROB_007 = \u00abLa vivienda\u00bb", "comunidades de los metadatos que no son 19 o no est\u00e1n en la tabla fija",
                "comunidades del Parquet sin c\u00f3digo", "comunidades de la tabla fija que no son 19 o est\u00e1n repetidas",
                "pesos no positivos o vac\u00edos", "estudios o meses del Parquet fuera de los metadatos"),
    calculado = c(sum(!etiqueta),
                  abs(length(leido$comunidades) - 19) + sum(!leido$comunidades %in% comunidades$nombre_cis),
                  sum(is.na(menciones$codigo)),
                  abs(nrow(comunidades) - 19) + sum(duplicated(comunidades$codigo)) + sum(duplicated(comunidades$nombre_cis)),
                  sum(is.na(d$peso) | d$peso <= 0),
                  sum(!unique(d$mes) %in% meses_meta) + sum(!unique(d$estudio) %in% leido$estudios$estudio)),
    referencia = 0)
  # alertas
  anchos <- tabla[tabla$estado == "dato" & tabla$margen > 5, ]
  margen <- tibble::tibble(id = "cis_ccaa_margen", anio = anchos$anio,
                           detalle = sprintf("%s %s %s: \u00b1%.1f puntos", anchos$nombre, anchos$anio, anchos$pregunta, anchos$margen),
                           calculado = rep(1, nrow(anchos)), referencia = rep(0, nrow(anchos)))
  ultimo_anio <- max(as.integer(substr(d$mes, 1, 4)))
  pocos <- dplyr::count(dplyr::distinct(d, mes), anio = as.integer(substr(mes, 1, 4)), name = "barometros")
  pocos <- pocos[pocos$barometros < 9 & pocos$anio < ultimo_anio, ]
  meses <- dplyr::bind_rows(
    tibble::tibble(id = "cis_ccaa_meses", anio = pocos$anio, detalle = paste(pocos$anio, "con", pocos$barometros, "bar\u00f3metros"),
                   calculado = rep(1, nrow(pocos)), referencia = rep(0, nrow(pocos))),
    tibble::tibble(id = "cis_ccaa_meses", anio = sin_contraste$anio,
                   detalle = sprintf("%s %s sin cifra nacional publicada", sin_contraste$mes, sin_contraste$pregunta),
                   calculado = rep(1, nrow(sin_contraste)), referencia = rep(0, nrow(sin_contraste))))
  dplyr::bind_rows(espana, suma, muestra, codigos, margen, meses) |>
    dplyr::mutate(anio = as.integer(anio), calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Atribución (CC BY 4.0 de la armonización y condiciones del CIS) y edición, para el CSV y el JSON.
cis_ccaa_atribucion <- function(ficheros) {
  ed <- cis_ccaa_edicion(ficheros)
  list(
    fuente = paste0("Centro de Investigaciones Sociol\u00f3gicas (CIS), bar\u00f3metros mensuales; microdatos armonizados de ",
                    "Bar\u00f3metro a bar\u00f3metro (https://gastiaso.github.io/barometros/), edici\u00f3n ", ed$edicion[1]),
    licencia = paste("Armonizaci\u00f3n: CC BY 4.0 (Bar\u00f3metro a bar\u00f3metro); datos de origen: reutilizaci\u00f3n citando",
                     "\u00abFuente de los datos: Centro de Investigaciones Sociol\u00f3gicas\u00bb (Ley 37/2007)"),
    edicion = ed$edicion[1],
    url = ed$url[ed$tipo == "microdatos"]
  )
}

cis_ccaa_dos_decimales <- function(x) {
  y <- rep(NA_real_, length(x))
  y[!is.na(x)] <- as.numeric(sprintf("%.2f", x[!is.na(x)]))
  y
}

# CSV de la tabla (cifras a un decimal; deff, a dos) para las descargas de la web:
# datos/cis_vivienda_ccaa.csv. La fuente y la licencia van en el JSON y en la página.
cis_ccaa_csv <- function(tabla) {
  tabla |>
    dplyr::transmute(codigo, nombre, anio, desde, hasta, anios, pregunta,
                     valor = cis_un_decimal(valor), inferior = cis_un_decimal(inferior), superior = cis_un_decimal(superior),
                     margen = cis_un_decimal(margen), entrevistas, deff = cis_ccaa_dos_decimales(deff),
                     meses, en_curso, ruptura, estado)
}

# JSON y CSV para la web (Máquina del tiempo y ficha de comunidad del mapa): datos/cis_vivienda_ccaa.json,
# con listas paralelas por fila (como datos/cis_vivienda.json), la fuente, la licencia, la edición, el
# último mes y las rupturas; y datos/cis_vivienda_ccaa.csv. Devuelve las dos rutas.
cis_ccaa_exportar <- function(tabla, rupturas, ficheros, dir_web = "web") {
  dir <- file.path(dir_web, "datos")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  csv <- cis_ccaa_csv(tabla)
  ruta_csv <- file.path(dir, "cis_vivienda_ccaa.csv")
  readr::write_csv(csv, ruta_csv, na = "")
  at <- cis_ccaa_atribucion(ficheros)
  cortes <- cis_ccaa_rupturas(rupturas)
  x <- c(at, list(
    unidad = "% de entrevistados que cita la vivienda entre sus tres problemas",
    ultimo_mes = max(tabla$hasta, na.rm = TRUE),
    minimo = CIS_CCAA_MINIMO,
    rupturas = list(mes = cortes$mes, id = cortes$ruptura),
    nombres = as.list(stats::setNames(dplyr::distinct(tabla, codigo, nombre)$nombre, dplyr::distinct(tabla, codigo, nombre)$codigo)),
    filas = list(codigo = csv$codigo, anio = csv$anio, desde = csv$desde, hasta = csv$hasta, anios = csv$anios,
                 pregunta = csv$pregunta, valor = csv$valor, inferior = csv$inferior, superior = csv$superior,
                 margen = csv$margen, entrevistas = csv$entrevistas, meses = csv$meses, en_curso = csv$en_curso,
                 ruptura = csv$ruptura, estado = csv$estado)
  ))
  ruta_json <- file.path(dir, "cis_vivienda_ccaa.json")
  jsonlite::write_json(x, ruta_json, auto_unbox = TRUE, digits = NA, pretty = FALSE, na = "null")
  c(json = ruta_json, csv = ruta_csv)
}

# Ida y vuelta (web_cis_ccaa, bloqueo): filas, cifras e intervalos del JSON y del CSV frente a la tabla
# redondeada. Listas de otra longitud: Inf.
cis_ccaa_comprobar_web <- function(tabla, rutas) {
  esperado <- cis_ccaa_csv(tabla)
  x <- jsonlite::read_json(cis_ccaa_ruta(rutas, "json"), simplifyVector = TRUE)$filas
  c2 <- readr::read_csv(cis_ccaa_ruta(rutas, "csv"),col_types = readr::cols(codigo = "c", desde = "c", hasta = "c", .default = readr::col_guess()),
                        na = "")
  distintos <- function(a, b) {
    if (length(a) != length(b)) return(Inf)
    sum(xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b))
  }
  campos <- c("codigo", "anio", "pregunta", "valor", "inferior", "superior", "margen", "entrevistas", "meses", "en_curso",
              "ruptura", "estado")
  dif_json <- sum(vapply(campos, function(k) as.numeric(distintos(x[[k]], esperado[[k]])), numeric(1)))
  dif_csv <- sum(vapply(campos, function(k) as.numeric(distintos(c2[[k]], esperado[[k]])), numeric(1)))
  tibble::tibble(id = "web_cis_ccaa", anio = NA_integer_, detalle = c("datos/cis_vivienda_ccaa.json", "datos/cis_vivienda_ccaa.csv"),
                 calculado = c(dif_json, dif_csv), referencia = 0)
}
