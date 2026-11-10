# Indicador 7 (F3): salario medio anual por asalariado, en total y de 26 a 35 años, por provincia,
# comunidad y España. AEAT, «Mercado de trabajo y pensiones en las fuentes tributarias», tabla
# «Asalariados, percepciones salariales y salarios por provincia, edad y sexo» (sexo total).
#   - Ediciones en tablas HTML: 2011–2024 (las anteriores no están en la web de la AEAT).
#   - Salario medio = salarios / asalariados: lo cobrado en el año, también por quien trabajó pocos
#     meses. Domicilio fiscal del perceptor.
#   - Sin País Vasco ni Navarra (domicilio fiscal foral): sus provincias y comunidades van como
#     «ausente»: de las haciendas forales, solo Gipuzkoa publica una cifra
#     comparable, en PDF. España es el territorio de régimen común.
#   - Nivel nativo, la provincia; la comunidad y España, con la cifra publicada (regla 1). Las
#     comunidades de una provincia (Asturias, Baleares, Cantabria, Madrid, Murcia, La Rioja) y Ceuta
#     y Melilla solo tienen fila de comunidad: es también la de su provincia.
# La compuerta (comprobar_aeat_salarios) comprueba la lectura (salarios / asalariados = salario
# medio publicado), la cobertura y que las provincias suman los asalariados y reproducen la media
# de su comunidad y de España.

TITULO_AEAT_SALARIOS <- "Asalariados, percepciones salariales y salarios por provincia, edad y sexo"
ANIOS_SALARIOS <- 2011:2024
# Tramos de edad de la AEAT que van a la tabla larga: total y 26–35 (el de la mochila).
GRUPOS_EDAD_SALARIOS <- c("Total" = "total", "De 26 a 35 a\u00f1os" = "Y26-35")
# Comunidades de una sola provincia (código de comunidad del INE → código de provincia).
PROVINCIA_UNICA <- c("03" = "33", "04" = "07", "06" = "39", "13" = "28", "14" = "30", "15" = "31",
                     "17" = "26", "18" = "51", "19" = "52")
CCAA_FORALES_SALARIOS <- c("15", "16")                 # Navarra y País Vasco
PROVINCIAS_FORALES <- c("01", "20", "31", "48")         # Álava, Gipuzkoa, Navarra y Bizkaia

descargar_aeat_salarios <- function(anio) {
  descargar_aeat_mercado(anio, TITULO_AEAT_SALARIOS, list(Sexo = "Total"))
}

# Una fila por territorio y tramo de edad: anio, nombre, nivel_fila (0 España, 1 comunidad,
# 2 provincia), grupo (comunidad a la que pertenece la fila, por orden de aparición), edad (texto
# de la AEAT), asalariados, salarios (euros) y salario_medio (euros, publicado). El tramo de edad
# se llama «Edad» hasta 2016, «Tramo de edad» en 2017 y 2018 y «Tramos de Edad» después.
leer_aeat_salarios <- function(rutas, anio) {
  d <- leer_aeat_mercado(rutas)
  col_edad <- intersect(c("tramos_de_edad", "tramo_de_edad", "edad"), names(d))[1]
  if (is.na(col_edad) || !"sexo" %in% names(d)) {
    stop("La tabla provincial de la AEAT de ", anio, " no trae sexo y edad como filtros", call. = FALSE)
  }
  d <- d |>
    filter(sexo == "Total") |>
    mutate(edad = .data[[col_edad]],
           medida = case_when(grepl("^Asalariados", columna) ~ "asalariados",
                              grepl("^Salarios", columna) ~ "salarios",
                              grepl("^Salario Medio", columna) ~ "salario_medio",
                              TRUE ~ NA_character_)) |>
    filter(!is.na(medida))
  orden <- d |>
    distinct(edad, fila, nivel_fila) |>
    group_by(edad) |>
    mutate(grupo = cumsum(nivel_fila == 1)) |>
    ungroup()
  d |>
    select(edad, fila, nivel_fila, medida, valor) |>
    tidyr::pivot_wider(names_from = medida, values_from = valor) |>
    inner_join(orden, by = c("edad", "fila", "nivel_fila")) |>
    transmute(anio = as.integer(anio), nombre = fila, nivel_fila, grupo, edad,
              asalariados, salarios, salario_medio)
}

# Clave de un nombre de provincia de la AEAT, estable entre ediciones (clave_comunidad(), más
# «Orense» → «Ourense», que cambia en 2014).
clave_provincia_aeat <- function(x) {
  k <- clave_comunidad(x)
  k[k == "orense"] <- "ourense"
  k
}

# Códigos del INE de cada fila: nacional «00»; comunidad por su nombre (clave_comunidad() frente a
# geo/ccaa.csv); provincia por su nombre en inventario/provincias_aeat.csv (nombre de la AEAT o del
# INE). Las comunidades de una provincia dan además su fila de provincia (PROVINCIA_UNICA). Solo
# los tramos de GRUPOS_EDAD_SALARIOS. Un nombre sin código detiene el proceso.
codificar_aeat_salarios <- function(leidas, provincias_aeat, ccaa, grupos = GRUPOS_EDAD_SALARIOS) {
  claves_ccaa <- stats::setNames(ccaa$codigo, clave_comunidad(ccaa$nombre_ine))
  claves_prov <- c(stats::setNames(provincias_aeat$provincia, clave_provincia_aeat(provincias_aeat$nombre_ine)),
                   stats::setNames(provincias_aeat$provincia[!is.na(provincias_aeat$nombre_aeat)],
                                   clave_provincia_aeat(stats::na.omit(provincias_aeat$nombre_aeat))))
  claves_prov <- claves_prov[!duplicated(names(claves_prov))]
  x <- leidas |>
    filter(edad %in% names(grupos)) |>
    mutate(grupo_edad = unname(grupos[edad]),
           nivel = c("nacional", "ccaa", "provincia")[nivel_fila + 1L],
           geo_id = case_when(nivel_fila == 0 ~ "00",
                              nivel_fila == 1 ~ unname(claves_ccaa[clave_comunidad(nombre)]),
                              nivel_fila == 2 ~ unname(claves_prov[clave_provincia_aeat(nombre)])))
  sin <- unique(x$nombre[is.na(x$geo_id)])
  if (length(sin) > 0) stop("Territorios de la AEAT sin c\u00f3digo: ", paste(sin, collapse = ", "), call. = FALSE)
  ccaa_fila <- x |> filter(nivel_fila == 1) |> distinct(anio, edad, grupo, ccaa = geo_id)
  x <- x |> left_join(ccaa_fila, by = c("anio", "edad", "grupo")) |>
    mutate(ccaa = if_else(nivel_fila == 0, NA_character_, ccaa))
  hijas <- x |> filter(nivel_fila == 2) |> distinct(anio, edad, grupo)
  unicas <- x |>
    filter(nivel_fila == 1) |>
    anti_join(hijas, by = c("anio", "edad", "grupo")) |>
    mutate(nivel = "provincia", geo_id = unname(PROVINCIA_UNICA[geo_id]))
  if (anyNA(unicas$geo_id)) {
    stop("Comunidades sin provincias en la AEAT que no son de una provincia: ",
         paste(unique(unicas$nombre[is.na(unicas$geo_id)]), collapse = ", "), call. = FALSE)
  }
  bind_rows(x, unicas) |>
    select(anio, nivel, geo_id, ccaa, nombre, edad = grupo_edad, asalariados, salarios, salario_medio) |>
    arrange(anio, edad, nivel, geo_id)
}

# Compuerta del indicador 7 (inventario/referencias_validacion.csv), por año:
#   aeat_provincia (bloqueo): cifras cuyo salario medio publicado no es salarios / asalariados
#     (redondeado al euro): comprueba la lectura y la unidad de los salarios;
#   aeat_salarios_cobertura (bloqueo): territorios de régimen común (48 provincias, 17 comunidades y
#     España) sin las dos cifras (total y 26–35), o repetidos;
#   aeat_salarios_suma (bloqueo): diferencia máxima entre los asalariados de las provincias y los de
#     su comunidad y España;
#   aeat_salarios_media (bloqueo): diferencia máxima (euros) entre la media de las provincias
#     (salarios / asalariados sumados) y la publicada para su comunidad y España.
comprobar_aeat_salarios <- function(salarios, anios = ANIOS_SALARIOS) {
  comunes_prov <- 48L
  comunes_ccaa <- 17L
  lectura <- salarios |>
    group_by(anio) |>
    summarise(calculado = sum(abs(salarios / asalariados - salario_medio) > 0.5 + 1e-6), .groups = "drop")
  esperado <- c(nacional = 1L, ccaa = comunes_ccaa, provincia = comunes_prov)
  cobertura <- lapply(anios, function(a) {
    s <- salarios[salarios$anio == a & !is.na(salarios$salario_medio), ]
    n <- dplyr::count(s, nivel, geo_id, name = "n")
    faltan <- sum(pmax(0L, esperado - as.integer(table(factor(unique(s[c("nivel", "geo_id")])$nivel, names(esperado))))))
    tibble::tibble(anio = a, calculado = faltan + sum(n$n != length(GRUPOS_EDAD_SALARIOS)))
  })
  prov <- salarios |> filter(nivel == "provincia")
  agregado <- bind_rows(
    prov |> group_by(anio, edad, nivel = "ccaa", geo_id = ccaa) |>
      summarise(suma = sum(asalariados), media = sum(salarios) / sum(asalariados), .groups = "drop"),
    prov |> group_by(anio, edad, nivel = "nacional", geo_id = "00") |>
      summarise(suma = sum(asalariados), media = sum(salarios) / sum(asalariados), .groups = "drop")
  ) |>
    inner_join(salarios |> filter(nivel != "provincia") |> select(anio, edad, nivel, geo_id, asalariados, salario_medio),
               by = c("anio", "edad", "nivel", "geo_id"))
  dif <- agregado |>
    group_by(anio) |>
    summarise(suma = max(abs(suma - asalariados)), media = max(abs(media - salario_medio)), comparadas = n(),
              .groups = "drop")
  bind_rows(
    tibble::tibble(id = "aeat_provincia", anio = lectura$anio, detalle = "salario medio distinto de salarios / asalariados",
                   calculado = lectura$calculado, referencia = 0),
    bind_rows(cobertura) |>
      transmute(id = "aeat_salarios_cobertura", anio, detalle = "territorios de r\u00e9gimen com\u00fan sin cifra o repetidos",
                calculado, referencia = 0),
    tibble::tibble(id = "aeat_salarios_suma", anio = dif$anio, detalle = paste(dif$comparadas, "cifras de comunidad y Espa\u00f1a"),
                   calculado = dif$suma, referencia = 0),
    tibble::tibble(id = "aeat_salarios_media", anio = dif$anio, detalle = paste(dif$comparadas, "cifras de comunidad y Espa\u00f1a"),
                   calculado = dif$media, referencia = 0)
  ) |>
    mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Filas de la tabla larga: salario_medio con la cifra publicada, «dato»; el total sin desglose y el
# tramo de 26 a 35 con corte «edad». Las provincias y comunidades forales, «ausente» en los dos.
armonizar_aeat_salarios <- function(salarios, version, anios = ANIOS_SALARIOS) {
  forales <- tidyr::expand_grid(
    anio = as.integer(anios),
    bind_rows(tibble::tibble(nivel = "provincia", geo_id = PROVINCIAS_FORALES),
              tibble::tibble(nivel = "ccaa", geo_id = CCAA_FORALES_SALARIOS)),
    edad = unname(GRUPOS_EDAD_SALARIOS)
  ) |>
    mutate(salario_medio = NA_real_)
  bind_rows(select(salarios, anio, nivel, geo_id, edad, salario_medio), forales) |>
    transmute(geo_id, nivel, anio = as.integer(anio), indicador = "salario_medio",
              corte = if_else(edad == "total", "total", "edad"), grupo = edad,
              valor = salario_medio, estado = if_else(is.na(salario_medio), "ausente", "dato"),
              fuente = "aeat_mercado_trabajo", geo_ref = NA_character_, version = version) |>
    select(all_of(COLUMNAS_TABLA_LARGA)) |>
    arrange(anio, nivel, geo_id, corte, grupo)
}
