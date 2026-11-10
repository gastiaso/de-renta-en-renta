# MIVAU, Valor tasado de la vivienda libre (indicador 12, F4) y Transacciones inmobiliarias
# (compraventas ante notario que publica el MIVAU), del Boletín estadístico en línea del Ministerio
# (apps.fomento.gob.es/BoletinOnline2, ficheros .XLS de «sedal»; la web del MIVAU rechaza las
# descargas automáticas, el boletín no). Reutilización autorizada por el aviso legal del MIVAU
# (citando la fuente y la fecha de la última actualización).
#   35101000: valor tasado medio (€/m²) de España, comunidades y provincias, trimestral desde 1995,
#     una hoja por cuatrienio;
#   35103000: número de tasaciones de esos territorios, trimestral desde 2005 (mismas hojas);
#   35103500: valor tasado medio (€/m²) y número de tasaciones de los municipios de más de 25.000
#     habitantes, una hoja por trimestre desde 2005, con el municipio por su nombre;
#   34020150: valor medio (€) de las transacciones de vivienda libre ante notario, España,
#     comunidades y provincias, trimestral desde 2004 (compuerta de coherencia).
# El atlas usa años: el valor del año es la media de sus cuatro trimestres ponderada por el número
# de tasaciones (medias ponderadas: regla 1); sin los cuatro trimestres, «ausente».
# Los nombres del Ministerio se casan con los códigos del INE por su forma normalizada (sin tildes,
# con el artículo delante) y, cuando no basta, con inventario/nombres_mivau.csv.
# Lectura incorporada el 10-nov-2026 a partir de código propio anterior (lectura por la cabecera
# «Provincia»/«Municipio» y por las columnas «Total»).

FICHEROS_MIVAU <- c(valor_tasado = "35101000", tasaciones = "35103000", valor_tasado_municipios = "35103500",
                    transacciones_valor = "34020150")

descargar_mivau_boletin <- function(id, dir = file.path("datos", "brutos", "mivau_valor_tasado"), forzar = FALSE) {
  descargar_con_cache(sprintf("https://apps.fomento.gob.es/BoletinOnline2/sedal/%s.XLS", id),
                      file.path(dir, sprintf("%s.xls", id)), forzar)
}

# Número de una celda leída como texto: «1477.4000000000001» (el binario de 1.477,4) -> 1477.4 con
# el redondeo de la guía; «n.r» (no representativo), vacío y otros textos -> NA.
numero_mivau <- function(x, decimales = 1L) {
  v <- suppressWarnings(as.numeric(trimws(x)))
  ok <- !is.na(v)
  v[ok] <- as.numeric(sprintf(paste0("%.", decimales, "f"), v[ok]))
  v
}

hoja_texto <- function(ruta, hoja) {
  m <- readxl::read_excel(ruta, sheet = hoja, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  m <- as.matrix(m)
  m[is.na(m)] <- ""
  trimws(m)
}

# Tablas trimestrales por territorio (35101000, 35103000, 34020150): en cada hoja, una fila con
# «Año AAAA» encima de cada bloque de cuatro trimestres y los territorios en la columna de «TOTAL
# NACIONAL». Devuelve nombre (tal cual), orden (fila), anio, trimestre y valor.
leer_mivau_trimestral <- function(ruta, decimales = 1L) {
  hojas <- readxl::excel_sheets(ruta)
  filas <- list()
  for (h in seq_along(hojas)) {
    m <- hoja_texto(ruta, h)
    es_anio <- matrix(grepl("^A.o [0-9]{4}", m), nrow = nrow(m))
    fila_anio <- which(rowSums(es_anio) > 0)[1]
    if (is.na(fila_anio)) next
    col_anio <- which(es_anio[fila_anio, ])
    anios <- as.integer(sub("^.*([0-9]{4}).*$", "\\1", m[fila_anio, col_anio]))
    nac <- which(toupper(m) == "TOTAL NACIONAL", arr.ind = TRUE)
    if (!nrow(nac)) stop("Hoja ", hojas[h], " de ", basename(ruta), ": sin fila TOTAL NACIONAL", call. = FALSE)
    col_nombre <- nac[1, "col"]
    inicio <- nac[1, "row"]
    # fila de los trimestres ("1o" ... "4o") entre la de los anios y la primera cifra; solo cuentan
    # las columnas con trimestre (tras el ultimo, la hoja puede traer variaciones)
    fila_q <- fila_anio + which(apply(m[(fila_anio + 1):(inicio - 1), , drop = FALSE], 1,
                                      function(r) any(grepl("^[1-4]\\D?$", r))))[1]
    if (is.na(fila_q)) stop("Hoja ", hojas[h], " de ", basename(ruta), ": sin fila de trimestres", call. = FALSE)
    fin <- c(col_anio[-1], ncol(m) + 1L)
    for (k in seq_along(col_anio)) {
      cols <- col_anio[k]:min(col_anio[k] + 3L, fin[k] - 1L)
      cols <- cols[grepl("^[1-4]\\D?$", m[fila_q, cols])]
      for (cq in cols) {
        filas[[length(filas) + 1]] <- tibble::tibble(
          nombre = m[inicio:nrow(m), col_nombre], orden = inicio:nrow(m) - inicio + 1L,
          anio = anios[k], trimestre = as.integer(substr(m[fila_q, cq], 1, 1)),
          valor = numero_mivau(m[inicio:nrow(m), cq], decimales))
      }
    }
  }
  dplyr::bind_rows(filas) |>
    dplyr::filter(nzchar(nombre)) |>
    dplyr::group_by(nombre, orden) |>
    dplyr::filter(any(!is.na(valor))) |>      # notas al pie: sin ninguna cifra
    dplyr::ungroup() |>
    dplyr::distinct(nombre, anio, trimestre, .keep_all = TRUE)
}

# Municipios de más de 25.000 habitantes (35103500): una hoja por trimestre («T1A2005»). Cabecera
# con «Provincia» y «Municipio»; en las dos filas siguientes, la primera columna «Total» es el
# valor tasado y la última, el número de tasaciones. La provincia solo viene en el primer
# municipio de cada una: se arrastra.
leer_mivau_valor_tasado_municipios <- function(ruta) {
  hojas <- readxl::excel_sheets(ruta)
  filas <- vector("list", length(hojas))
  for (h in seq_along(hojas)) {
    mt <- regmatches(hojas[h], regexec("^\\s*T([1-4])A([0-9]{4})", hojas[h]))[[1]]
    if (!length(mt)) next
    m <- hoja_texto(ruta, h)
    cab <- which(apply(m, 1, function(r) "Provincia" %in% r && "Municipio" %in% r))[1]
    if (is.na(cab)) stop("Hoja ", hojas[h], ": sin cabecera Provincia/Municipio", call. = FALSE)
    cp <- which(m[cab, ] == "Provincia")[1]
    cm <- which(m[cab, ] == "Municipio")[1]
    total <- sort(unique(which(m[c(cab + 1, cab + 2), , drop = FALSE] == "Total", arr.ind = TRUE)[, "col"]))
    if (length(total) < 2) stop("Hoja ", hojas[h], ": sin las dos columnas Total", call. = FALSE)
    r <- (cab + 1):nrow(m)
    prov <- m[r, cp]
    prov[prov == ""] <- NA
    for (k in seq_along(prov)[-1]) if (is.na(prov[k])) prov[k] <- prov[k - 1]
    mun <- m[r, cm]
    valor <- numero_mivau(m[r, min(total)])
    tasaciones <- numero_mivau(m[r, max(total)], 0L)
    ok <- nzchar(mun) & !is.na(prov) & !grepl("^\\(", mun) & (!is.na(valor) | !is.na(tasaciones) | grepl("n[.]r", m[r, min(total)]))
    filas[[h]] <- tibble::tibble(anio = as.integer(mt[3]), trimestre = as.integer(mt[2]), provincia_mivau = prov[ok],
                                 municipio_mivau = mun[ok], valor = valor[ok], tasaciones = tasaciones[ok])
  }
  dplyr::bind_rows(filas)
}

# Forma normalizada de un nombre para casarlo: minúsculas, sin tildes ni signos, con el artículo
# delante («Ejido (El)» y «Ejido, El» -> «el ejido») y sin otros paréntesis («Asturias (Principado
# de )» -> «asturias»). Un nombre bilingüe del INE («Alicante/Alacant») da una forma por variante.
normalizar_nombre <- function(x) {
  x <- tolower(trimws(x))
  x <- chartr("\u00e1\u00e9\u00ed\u00f3\u00fa\u00e0\u00e8\u00ec\u00f2\u00f9\u00e4\u00eb\u00ef\u00f6\u00fc\u00e2\u00ea\u00ee\u00f4\u00fb\u00f1\u00e7",
              "aeiouaeiouaeiouaeiounc", x)
  articulo <- "^(.*)\\s*\\((el|la|los|las|l'|a|o|os|as|es|sa|ses|s')\\)$"
  x <- ifelse(grepl(articulo, x), sub(articulo, "\\2 \\1", x), x)
  coma <- "^(.*),\\s*(el|la|los|las|l'|a|o|os|as|es|sa|ses|s')$"
  x <- ifelse(grepl(coma, x), sub(coma, "\\2 \\1", x), x)
  x <- gsub("\\(.*?\\)", " ", x)
  x <- gsub("[^a-z0-9]+", "", x)
  x
}

MIN_SECCIONES_MIVAU <- 10L

variantes_nombre <- function(codigo, nombre) {
  partes <- strsplit(nombre, "/", fixed = TRUE)
  partes <- c(partes, lapply(partes, function(p) sub(",.*$", "", p)))   # "Balears, Illes" -> "Balears"
  tibble::tibble(codigo = rep(c(codigo, codigo), lengths(partes)), clave = normalizar_nombre(unlist(partes))) |>
    dplyr::bind_rows(tibble::tibble(codigo = codigo, clave = normalizar_nombre(nombre))) |>
    dplyr::distinct()
}

# Código del INE de cada nombre del Ministerio, en dos pasos: los territorios (España, comunidades
# y provincias, de las tablas territoriales y de la columna de provincia de la de municipios) y
# después los municipios dentro de su provincia. `territoriales`: nombres de territorio;
# `municipios`: provincia_mivau y municipio_mivau; `territorios`: la tabla de geo_territorios();
# `manual`: inventario/nombres_mivau.csv (nivel_ine, provincia, nombre_mivau, codigo, nota), que
# manda; nivel_ine «ninguno» marca un nombre que no es un territorio del atlas (Ceuta y Melilla
# juntas). España es «00». Un nombre de comunidad o de provincia se busca en los dos niveles; si
# casa con los dos (las comunidades de una provincia), cuenta como provincia.
# Devuelve nivel («territorio» o «municipio»), provincia (código; vacío en los territorios),
# nombre_mivau, codigo, nivel_ine y origen («auto» o «manual»).
casar_nombres_mivau <- function(territoriales, municipios, territorios, manual) {
  manual <- manual |>
    dplyr::mutate(provincia = dplyr::coalesce(provincia, ""),
                  nivel = dplyr::if_else(nivel_ine == "municipio", "municipio", "territorio")) |>
    dplyr::select(nivel, provincia, nombre_mivau, codigo_manual = codigo, nivel_manual = nivel_ine)
  # variantes de cada nivel por separado: los codigos de comunidad y de provincia se solapan
  claves <- function(niv) {
    dplyr::bind_rows(lapply(niv, function(n) {
      t <- territorios[territorios$nivel == n, ]
      dplyr::mutate(variantes_nombre(t$codigo, t$nombre), nivel_ine = n)
    }))
  }
  # variantes del lado del Ministerio: el nombre entero y cada parte de un nombre bilingue
  con_variantes <- function(x) {
    partes <- strsplit(x$nombre_mivau, "/", fixed = TRUE)
    x[rep(seq_len(nrow(x)), lengths(partes) + 1L), ] |>
      dplyr::mutate(clave = normalizar_nombre(unlist(mapply(function(n, p) c(n, p), x$nombre_mivau, partes,
                                                           SIMPLIFY = FALSE, USE.NAMES = FALSE)))) |>
      dplyr::distinct()
  }
  # un candidato por nombre: si alguno es provincia, solo esos; si queda mas de uno, ninguno
  elegir <- function(codigo, nivel_ine) {
    c0 <- unique(data.frame(codigo = codigo, nivel_ine = nivel_ine)[!is.na(codigo), , drop = FALSE])
    if (any(c0$nivel_ine == "provincia")) c0 <- c0[c0$nivel_ine == "provincia", , drop = FALSE]
    if (nrow(c0) == 1) c0 else data.frame(codigo = NA_character_, nivel_ine = NA_character_)
  }
  resolver <- function(x) {
    x |>
      dplyr::group_by(nivel, provincia, nombre_mivau) |>
      dplyr::summarise(elegido = list(elegir(codigo, nivel_ine)), .groups = "drop") |>
      tidyr::unnest(elegido) |>
      dplyr::left_join(manual, by = c("nivel", "provincia", "nombre_mivau")) |>
      dplyr::mutate(origen = dplyr::if_else(is.na(codigo_manual), "auto", "manual"),
                    codigo = dplyr::coalesce(codigo_manual, codigo),
                    nivel_ine = dplyr::coalesce(nivel_manual, nivel_ine),
                    codigo = dplyr::if_else(normalizar_nombre(nombre_mivau) == "totalnacional", "00", codigo),
                    nivel_ine = dplyr::if_else(codigo %in% "00", "nacional", nivel_ine)) |>
      dplyr::select(nivel, provincia, nombre_mivau, codigo, nivel_ine, origen)
  }
  terr <- tibble::tibble(nivel = "territorio", provincia = "",
                         nombre_mivau = unique(c(territoriales, municipios$provincia_mivau))) |>
    con_variantes() |>
    dplyr::left_join(claves(c("ccaa", "provincia")), by = "clave", relationship = "many-to-many") |>
    resolver()
  prov <- terr |> dplyr::filter(nivel_ine %in% "provincia") |> dplyr::select(provincia_mivau = nombre_mivau, provincia = codigo)
  mun <- municipios |>
    dplyr::distinct(provincia_mivau, nombre_mivau = municipio_mivau) |>
    dplyr::left_join(prov, by = "provincia_mivau") |>
    dplyr::mutate(nivel = "municipio", provincia = dplyr::coalesce(provincia, "")) |>
    con_variantes() |>
    dplyr::left_join(claves("municipio"), by = "clave", relationship = "many-to-many") |>
    dplyr::mutate(codigo = dplyr::if_else(substr(codigo, 1, 2) == provincia, codigo, NA_character_),
                  nivel_ine = dplyr::if_else(is.na(codigo), NA_character_, nivel_ine)) |>
    dplyr::select(-provincia_mivau) |>
    dplyr::distinct() |>
    resolver()
  # Respaldo: la tabla de municipios arrastra mal la provincia de algunos municipios anadidos en
  # 2009 y 2020 (Ames, en Caceres). Sin codigo en su provincia, se acepta el nombre si casa con un
  # solo municipio grande de toda Espana (al menos MIN_SECCIONES_MIVAU secciones).
  grandes <- territorios[territorios$nivel == "municipio" & as.integer(territorios$secciones) >= MIN_SECCIONES_MIVAU, ]
  nac <- mun |>
    dplyr::filter(is.na(codigo)) |>
    dplyr::select(nivel, provincia, nombre_mivau) |>
    con_variantes() |>
    dplyr::inner_join(variantes_nombre(grandes$codigo, grandes$nombre), by = "clave", relationship = "many-to-many") |>
    dplyr::group_by(nivel, provincia, nombre_mivau) |>
    dplyr::summarise(n = dplyr::n_distinct(codigo), codigo_nac = dplyr::first(codigo), .groups = "drop") |>
    dplyr::filter(n == 1) |>
    dplyr::select(-n)
  mun <- mun |>
    dplyr::left_join(nac, by = c("nivel", "provincia", "nombre_mivau")) |>
    dplyr::mutate(origen = dplyr::if_else(is.na(codigo) & !is.na(codigo_nac), "nacional", origen),
                  nivel_ine = dplyr::if_else(is.na(codigo) & !is.na(codigo_nac), "municipio", nivel_ine),
                  codigo = dplyr::coalesce(codigo, codigo_nac)) |>
    dplyr::select(-codigo_nac)
  dplyr::bind_rows(terr, mun)
}

# Nivel del atlas de un código del Ministerio casado: «00», nacional; dos cifras, comunidad o
# provincia según el nombre (una comunidad de una sola provincia cuenta en los dos niveles).
niveles_mivau <- function(casados, territorios) {
  pc <- territorios$codigo[territorios$nivel == "provincia"]
  cc <- territorios$codigo[territorios$nivel == "ccaa"]
  uniprov <- territorios |> dplyr::filter(nivel == "provincia") |> dplyr::count(superior) |> dplyr::filter(n == 1)
  uni <- territorios |> dplyr::filter(nivel == "provincia", superior %in% uniprov$superior) |>
    dplyr::select(provincia = codigo, ccaa = superior)
  x <- casados |> dplyr::filter(!is.na(codigo), !nivel_ine %in% "ninguno")
  dplyr::bind_rows(
    x |> dplyr::filter(codigo == "00") |> dplyr::mutate(nivel_atlas = "nacional"),
    x |> dplyr::filter(nivel_ine %in% "ccaa") |> dplyr::mutate(nivel_atlas = "ccaa"),
    x |> dplyr::filter(nivel_ine %in% "provincia") |> dplyr::mutate(nivel_atlas = "provincia"),
    # comunidad de una provincia: su fila del Ministerio tambi\u00e9n es la de la comunidad
    x |> dplyr::filter(nivel_ine %in% "provincia", codigo %in% uni$provincia) |>
      dplyr::mutate(codigo = uni$ccaa[match(codigo, uni$provincia)], nivel_atlas = "ccaa"),
    x |> dplyr::filter(nivel == "municipio") |> dplyr::mutate(nivel_atlas = "municipio")
  ) |>
    dplyr::filter(codigo == "00" | nivel_atlas == "municipio" | codigo %in% c(pc, cc))
}

# Valor tasado trimestral con su código del INE: nivel, geo_id, anio, trimestre, valor, tasaciones.
# `territoriales`: leer_mivau_trimestral() del 35101000; `tasaciones`: el mismo del 35103000;
# `municipios`: leer_mivau_valor_tasado_municipios(); `casados`: niveles_mivau().
valor_tasado_trimestral <- function(territoriales, tasaciones, municipios, casados) {
  terr <- casados |> dplyr::filter(nivel == "territorio") |> dplyr::select(nombre_mivau, nivel = nivel_atlas, geo_id = codigo)
  con_codigo <- function(x) dplyr::inner_join(x, terr, by = c("nombre" = "nombre_mivau"), relationship = "many-to-many")
  t <- con_codigo(territoriales) |>
    dplyr::left_join(con_codigo(tasaciones) |> dplyr::select(nivel, geo_id, anio, trimestre, tasaciones = valor),
                     by = c("nivel", "geo_id", "anio", "trimestre"))
  mun <- casados |> dplyr::filter(nivel == "municipio") |>
    dplyr::select(provincia, nombre_mivau, geo_id = codigo)
  provincia_de <- casados |> dplyr::filter(nivel == "territorio", nivel_atlas == "provincia") |>
    dplyr::distinct(nombre_mivau, provincia = codigo)
  m <- municipios |>
    dplyr::inner_join(provincia_de, by = c("provincia_mivau" = "nombre_mivau")) |>
    dplyr::inner_join(mun, by = c("provincia", "municipio_mivau" = "nombre_mivau")) |>
    dplyr::mutate(nivel = "municipio")
  dplyr::bind_rows(
    dplyr::select(t, nivel, geo_id, anio, trimestre, valor, tasaciones),
    dplyr::select(m, nivel, geo_id, anio, trimestre, valor, tasaciones)
  )
}

# Rango de un valor tasado creíble (€/m²): fuera, error de la fuente (en 2013 hay seis «15»).
RANGO_VALOR_TASADO <- c(200, 15000)

# Media anual: los cuatro trimestres con valor y tasaciones, ponderados por las tasaciones; sin
# los cuatro, NA. Devuelve nivel, geo_id, anio, valor, tasaciones y trimestres.
valor_tasado_anual <- function(trimestral, rango = RANGO_VALOR_TASADO) {
  trimestral |>
    dplyr::mutate(valor = dplyr::if_else(valor < rango[1] | valor > rango[2], NA_real_, valor)) |>
    dplyr::group_by(nivel, geo_id, anio) |>
    dplyr::summarise(
      trimestres = sum(!is.na(valor) & !is.na(tasaciones) & tasaciones > 0),
      valor = if (trimestres == 4) sum(valor * tasaciones, na.rm = TRUE) / sum(tasaciones, na.rm = TRUE) else NA_real_,
      tasaciones = sum(tasaciones, na.rm = TRUE), .groups = "drop")
}

# Compuerta del valor tasado (inventario/referencias_validacion.csv):
#   valor_tasado_nombres (bloqueo): nombres del Ministerio sin código del INE (territorios con
#     cifra y municipios);
#   valor_tasado_ccaa (bloqueo): por año (desde `desde`), trimestres en que el valor publicado de una
#     comunidad de varias provincias o de España cae fuera del intervalo de los de sus provincias
#     (una media ponderada, con los pesos que sean, no puede salirse);
#   valor_tasado_ccaa_media (alerta): diferencia máxima (%) entre ese valor y la media de sus
#     provincias ponderada por las tasaciones: el Ministerio no pondera por tasaciones (ni la
#     comunidad ni el año son esa media), así que la diferencia es de composición, no de lectura;
#   valor_tasado_tasaciones (bloqueo): por año, diferencia máxima entre las tasaciones publicadas
#     de cada comunidad y de España y la suma de las de sus provincias;
#   valor_tasado_rango (alerta): cada cifra trimestral fuera de RANGO_VALOR_TASADO (va como NA);
#   valor_tasado_nota (bloqueo): España en un trimestre, frente a la nota del Ministerio
#     (REFERENCIA_VALOR_TASADO).
REFERENCIA_VALOR_TASADO <- tibble::tibble(anio = 2026L, trimestre = 1L, referencia = 2315.7,
                                          detalle = "Espa\u00f1a, primer trimestre de 2026")
comprobar_mivau_valor_tasado <- function(trimestral, casados, territorios, desde = 2015L) {
  sin <- casados |> dplyr::filter(is.na(codigo), !nivel_ine %in% "ninguno") |>
    dplyr::group_by(nivel) |>
    dplyr::summarise(calculado = dplyr::n(), detalle = paste(utils::head(nombre_mivau, 6), collapse = "; "), .groups = "drop") |>
    dplyr::transmute(id = "valor_tasado_nombres", anio = NA_integer_, detalle = paste(nivel, detalle), calculado, referencia = 0)
  if (!nrow(sin)) sin <- tibble::tibble(id = "valor_tasado_nombres", anio = NA_integer_, detalle = "todos casados",
                                        calculado = 0, referencia = 0)
  prov <- territorios |> dplyr::filter(nivel == "provincia") |> dplyr::select(provincia = codigo, ccaa = superior)
  varias <- prov |> dplyr::count(ccaa) |> dplyr::filter(n > 1)
  p <- trimestral |> dplyr::filter(nivel == "provincia", anio >= desde) |>
    dplyr::inner_join(prov, by = c("geo_id" = "provincia"))
  agrega <- function(x, por) {
    x |> dplyr::group_by(dplyr::across(dplyr::all_of(c(por, "anio", "trimestre")))) |>
      dplyr::summarise(media = sum(valor * tasaciones) / sum(tasaciones), suma = sum(tasaciones),
                       minimo = min(valor), maximo = max(valor), .groups = "drop")
  }
  arriba <- dplyr::bind_rows(
    agrega(dplyr::filter(p, ccaa %in% varias$ccaa), "ccaa") |> dplyr::transmute(nivel = "ccaa", geo_id = ccaa, anio, trimestre, media, suma, minimo, maximo),
    agrega(p, character()) |> dplyr::transmute(nivel = "nacional", geo_id = "00", anio, trimestre, media, suma, minimo, maximo)
  ) |>
    dplyr::inner_join(dplyr::select(trimestral, nivel, geo_id, anio, trimestre, valor, tasaciones),
                      by = c("nivel", "geo_id", "anio", "trimestre")) |>
    dplyr::filter(!is.na(valor), !is.na(media))
  ccaa <- arriba |> dplyr::group_by(anio) |>
    dplyr::summarise(calculado = sum(valor < minimo - 0.05 | valor > maximo + 0.05), .groups = "drop") |>
    dplyr::transmute(id = "valor_tasado_ccaa", anio, detalle = "comunidades y Espa\u00f1a fuera de sus provincias",
                     calculado, referencia = 0)
  media <- arriba |> dplyr::group_by(anio) |>
    dplyr::summarise(calculado = max(100 * abs(valor - media) / valor), .groups = "drop") |>
    dplyr::transmute(id = "valor_tasado_ccaa_media", anio, detalle = "comunidades y Espa\u00f1a (%)", calculado, referencia = 0)
  suma <- arriba |> dplyr::group_by(anio) |>
    dplyr::summarise(calculado = max(abs(tasaciones - suma)), .groups = "drop") |>
    dplyr::transmute(id = "valor_tasado_tasaciones", anio, detalle = "comunidades y Espa\u00f1a", calculado, referencia = 0)
  rango <- trimestral |> dplyr::filter(!is.na(valor), valor < RANGO_VALOR_TASADO[1] | valor > RANGO_VALOR_TASADO[2]) |>
    dplyr::transmute(id = "valor_tasado_rango", anio, detalle = paste0(nivel, " ", geo_id, " T", trimestre, ": ", valor),
                     calculado = 1, referencia = 0)
  nota <- REFERENCIA_VALOR_TASADO |>
    dplyr::left_join(dplyr::filter(trimestral, nivel == "nacional"), by = c("anio", "trimestre")) |>
    dplyr::transmute(id = "valor_tasado_nota", anio, detalle, calculado = valor, referencia)
  repetidos <- tibble::tibble(id = "valor_tasado_nombres", anio = NA_integer_,
                              detalle = "territorios con dos nombres en un mismo trimestre",
                              calculado = sum(duplicated(trimestral[c("nivel", "geo_id", "anio", "trimestre")])), referencia = 0)
  dplyr::bind_rows(sin, repetidos, ccaa, media, suma, rango, nota) |>
    dplyr::mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Indicador 12 (valor_tasado_m2) en la tabla larga: media anual de `anios`, de España a los
# municipios de más de 25.000 habitantes; sin los cuatro trimestres, «ausente».
armonizar_mivau_valor_tasado <- function(anual, version, anios = 2015:2025) {
  anual |>
    dplyr::filter(anio %in% anios) |>
    dplyr::transmute(geo_id, nivel, anio, indicador = "valor_tasado_m2", corte = "total", grupo = "total",
                     valor, estado = dplyr::if_else(is.na(valor), "ausente", "dato"),
                     fuente = "mivau_valor_tasado", geo_ref = "2021", version = version) |>
    dplyr::select(dplyr::all_of(COLUMNAS_TABLA_LARGA))
}

# Una tabla territorial del Ministerio (leer_mivau_trimestral()) con su nivel y código del INE:
# nivel, geo_id, anio, trimestre y valor. Una comunidad de una provincia sale en los dos niveles.
codificar_mivau_trimestral <- function(trimestral, casados) {
  terr <- casados |> dplyr::filter(nivel == "territorio") |> dplyr::select(nombre_mivau, nivel = nivel_atlas, geo_id = codigo)
  trimestral |>
    dplyr::inner_join(terr, by = c("nombre" = "nombre_mivau"), relationship = "many-to-many") |>
    dplyr::select(nivel, geo_id, anio, trimestre, valor)
}
