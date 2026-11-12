# Fuente ine_ecv: otros gastos de vivienda de los inquilinos (decisión del autor, 12-nov-2026).
# «Tu sueldo» de la web tiene un selector, «Añadir otros gastos de vivienda», apagado por defecto:
# encendido, al alquiler de cada sección se le suma lo que pagan de más al mes los hogares que
# alquilan (suministros, comunidad, seguros y demás gastos de la vivienda que no son el alquiler),
# como en la definición de gastos de vivienda de Eurostat, en «¿te llega?» y en el sueldo necesario.
#
# Definición (inventario/supuestos.csv, otros_gastos_vivienda y otros_gastos_minimo_hogares):
#   - variables del fichero de hogares (Th) de la ECV, en euros al mes: HH070, gastos de la vivienda
#     (alquiler, intereses de la hipoteca y otros gastos asociados: comunidad, agua, electricidad, gas…),
#     y HH060, alquiler actual por la vivienda ocupada (diseño de registro del INE). Otros gastos =
#     HH070 − HH060;
#   - hogares: los que alquilan a precio de mercado (HH021 = 3) con los dos importes (HH060 > 0);
#   - estadístico: mediana ponderada con el factor del hogar (DB090), la de cuantil_ponderado()
#     (R/fuente_ine_ecv.R): el menor valor cuyo peso acumulado llega a la mitad;
#   - escala: la comunidad autónoma (DB040, NUTS 2), lo más fino que publica la ECV, pero no con la
#     mediana de cada comunidad y ola: con 50 a 150 hogares por comunidad, salta hasta 47 € de una ola
#     a la siguiente, casi tanto como la distancia entre comunidades. La cifra de una comunidad es la
#     mediana de España de la ola por el factor de la comunidad (decisión del autor, 12-nov-2026):
#     la mediana ponderada, con las olas juntas, de lo que paga cada hogar respecto a la mediana de
#     España de su ola (otros_gastos_factores()). Cada ola pesa lo mismo. El nivel de cada año lo da
#     España (unos 3.700 hogares en 2024) y la diferencia entre comunidades, todas las olas;
#   - mínimo: con menos observaciones (hogar y ola) que el mínimo (50, la convención de EU-SILC: de 20
#     a 49 observaciones, poco fiable), factor 1, la cifra de España, y se dice. Un hogar entrevistado
#     en varias olas cuenta una vez por ola. El cruce con el grado de urbanización (DB100) no aguanta
#     por comunidad (de 2016 a 2025, entre 29 y 50 de las 53 celdas comunidad × grado tienen menos de
#     50 hogares en una ola) y la web no tiene el grado de cada sección: no se usa;
#   - año: el de la encuesta, porque HH060 y HH070 son los gastos del momento de la entrevista (las
#     rentas de la ECV son del año anterior, los gastos no). La web toma la ola del año del alquiler
#     que se ve o, si no la hay, la más cercana, y lo dice (anio_ecv_para()).
# Eurostat no imputa una cifra típica: en su tasa de sobrecarga cada hogar entra con su propio gasto
# total (HH070) y su renta. Aquí no hay hogares por sección, y por eso se suma una cifra de la
# comunidad. Mediana, hogares, mínimo, factor y año: decisiones del autor del 12-nov-2026
# (docs/metodologia.md, §8).
#
# Compuerta (inventario/referencias_validacion.csv): el INE y Eurostat no publican esta cifra, así que
# son comprobaciones internas, de tipo alerta (otros_gastos_*), y la ida y vuelta del fichero de la web,
# de tipo bloqueo (web_otros_gastos).

# Lee del Td y el Th lo necesario: año, hogar, región, factor, grado de urbanización, tenencia,
# alquiler (HH060) y gasto total de la vivienda (HH070), los dos en euros al mes.
leer_ine_ecv_gastos <- function(rutas) {
  ruta <- function(letra) {
    r <- rutas[grepl(sprintf("esudb\\d{2}%s\\.csv$", letra), rutas, ignore.case = TRUE)]
    if (length(r) != 1) stop("Falta el CSV del fichero T", toupper(letra), call. = FALSE)
    r
  }
  leer <- function(ruta, columnas) {
    readr::read_csv(ruta, col_select = dplyr::all_of(columnas),
                    col_types = readr::cols(.default = readr::col_character()), progress = FALSE)
  }
  d <- leer(ruta("d"), c("DB010", "DB030", "DB040", "DB090", "DB100"))
  h <- leer(ruta("h"), c("HB030", "HH021", "HH060", "HH070"))
  x <- dplyr::inner_join(d, h, by = c("DB030" = "HB030")) |>
    dplyr::transmute(
      anio               = as.integer(DB010),
      id_hogar           = DB030,
      region             = DB040,
      peso_hogar         = as.numeric(DB090),
      grado_urbanizacion = DB100,
      tenencia           = as.integer(HH021),
      alquiler_mes       = as.numeric(HH060),
      gasto_vivienda_mes = as.numeric(HH070)
    )
  if (nrow(x) != nrow(d)) stop("Td y Th no casan hogar a hogar", call. = FALSE)
  x
}

# Hogares de la cuenta: inquilinos a precio de mercado con los dos importes y factor. `otros_gastos`,
# HH070 − HH060 (negativo si el gasto total declarado no llega al alquiler: lo cuenta la compuerta).
otros_gastos_hogares <- function(ecv_gastos) {
  ecv_gastos |>
    dplyr::filter(tenencia == 3L, !is.na(alquiler_mes), alquiler_mes > 0, !is.na(gasto_vivienda_mes),
                  !is.na(peso_hogar), peso_hogar > 0) |>
    dplyr::mutate(otros_gastos = gasto_vivienda_mes - alquiler_mes)
}

# Los mismos hogares con el código de su comunidad (geo/ccaa.csv, por la región NUTS 2).
otros_gastos_con_ccaa <- function(ecv_gastos, ccaa) {
  h <- otros_gastos_hogares(ecv_gastos) |>
    dplyr::left_join(dplyr::select(ccaa, codigo, nuts2), by = c("region" = "nuts2"))
  sin_ccaa <- unique(h$region[is.na(h$codigo)])
  if (length(sin_ccaa) > 0) stop("Regiones de la ECV sin comunidad en geo/ccaa.csv: ", paste(sin_ccaa, collapse = ", "), call. = FALSE)
  h
}

# Mínimo de observaciones de una comunidad (inventario/supuestos.csv).
otros_gastos_minimo <- function() supuesto("otros_gastos_minimo_hogares")

# Tres decimales, como redondear_1() (sprintf(), no round()).
redondear_3 <- function(x) as.numeric(sprintf("%.3f", x))

# Lo que paga cada hogar respecto a la mediana de España de su ola (relativo) y su peso con todas las
# olas pesando lo mismo (peso_ola: el factor del hogar, DB090, entre la suma de su ola).
otros_gastos_relativos <- function(h) {
  h |>
    dplyr::group_by(anio) |>
    dplyr::mutate(relativo = otros_gastos / cuantil_ponderado(otros_gastos, peso_hogar, 0.5),
                  peso_ola = peso_hogar / sum(peso_hogar)) |>
    dplyr::ungroup()
}

# Factor de cada comunidad con las olas juntas: mediana ponderada (peso_ola) de `relativo`. `h`: los
# hogares de otros_gastos_con_ccaa(). Una fila por comunidad: n_factor (observaciones, hogar y ola),
# factor_propio (sin redondear), espana (menos observaciones que el mínimo) y factor (tres
# decimales; 1 si espana).
otros_gastos_factores <- function(h, ccaa, minimo = otros_gastos_minimo()) {
  propios <- otros_gastos_relativos(h) |>
    dplyr::group_by(geo_id = codigo) |>
    dplyr::summarise(n_factor = dplyr::n(), factor_propio = cuantil_ponderado(relativo, peso_ola, 0.5),
                     .groups = "drop")
  tibble::tibble(geo_id = ccaa$codigo) |>
    dplyr::left_join(propios, by = "geo_id") |>
    dplyr::mutate(n_factor = dplyr::coalesce(n_factor, 0L), espana = n_factor < minimo,
                  factor = dplyr::if_else(espana, 1, redondear_3(factor_propio)))
}

# Cifra de cada comunidad y de España por año de la ECV: una fila por año y territorio con
# n_hogares, mediana y media de la ola (las propias, para contraste), factor y n_factor (los de la
# comunidad con las olas juntas; España, 1 y todas las observaciones) y valor, la que usa la web: la
# mediana de España de la ola (un decimal) por el factor (tres), a un decimal (redondear_1()).
# espana = TRUE si la comunidad no llega al mínimo de observaciones: factor 1, la cifra de España.
calcular_otros_gastos_ecv <- function(ecv_gastos, ccaa, minimo = otros_gastos_minimo()) {
  h <- otros_gastos_con_ccaa(ecv_gastos, ccaa)
  resumir <- function(x) {
    x |>
      dplyr::summarise(n_hogares = dplyr::n(),
                       mediana = cuantil_ponderado(otros_gastos, peso_hogar, 0.5),
                       media = stats::weighted.mean(otros_gastos, peso_hogar), .groups = "drop")
  }
  espana <- h |> dplyr::group_by(anio) |> resumir() |>
    dplyr::mutate(geo_id = "00", nivel = "nacional", factor = 1, n_factor = nrow(h), espana = FALSE)
  comunidades <- h |> dplyr::group_by(anio, geo_id = codigo) |> resumir()
  # Todas las comunidades y olas, también las que no tienen hogares en la muestra de un año
  todas <- tidyr::expand_grid(anio = sort(unique(h$anio)), geo_id = ccaa$codigo)
  factores <- otros_gastos_factores(h, ccaa, minimo)
  comunidades <- dplyr::left_join(todas, comunidades, by = c("anio", "geo_id")) |>
    dplyr::mutate(nivel = "ccaa", n_hogares = dplyr::coalesce(n_hogares, 0L)) |>
    dplyr::left_join(dplyr::select(factores, geo_id, factor, n_factor, espana), by = "geo_id")
  dplyr::bind_rows(espana, comunidades) |>
    dplyr::left_join(dplyr::select(espana, anio, mediana_es = mediana), by = "anio") |>
    dplyr::mutate(valor = redondear_1(redondear_1(mediana_es) * factor),
                  mediana = redondear_1(mediana), media = redondear_1(media)) |>
    dplyr::select(anio, geo_id, nivel, n_hogares, mediana, media, factor, n_factor, valor, espana) |>
    dplyr::arrange(anio, nivel != "nacional", geo_id)
}

# Año de la ECV para un año del alquiler: el mismo o, si no hay ola, la más cercana (en un empate,
# la más reciente). Lo mismo que anioEcv() de web/js/sueldo.js.
anio_ecv_para <- function(anio, anios_ecv) {
  vapply(as.integer(anio), function(a) {
    d <- abs(anios_ecv - a)
    max(anios_ecv[d == min(d)])
  }, integer(1))
}

# Cuentas con otros gastos de la web (web/js/formulas.js y sueldo.js): sueldo necesario
# (alquiler + otros) / umbral y proporción (alquiler + otros) / ingreso.
sueldo_con_otros_gastos <- function(alquiler, otros, umbral) (alquiler + otros) / umbral
ratio_con_otros_gastos <- function(alquiler, otros, ingreso) (alquiler + otros) / ingreso

# Compuerta: comprobaciones internas (no hay cifra publicada que reproducir).
comprobar_otros_gastos <- function(otros_gastos, ecv_gastos, ccaa, minimo = otros_gastos_minimo(), rango = OTROS_GASTOS_RANGO,
                                   rango_factor = OTROS_GASTOS_RANGO_FACTOR) {
  h <- otros_gastos_con_ccaa(ecv_gastos, ccaa)
  com <- otros_gastos[otros_gastos$nivel == "ccaa", ]
  es <- otros_gastos[otros_gastos$nivel == "nacional", ]
  # 1. Cada comunidad y año con cifra (la de España de la ola por su factor)
  cobertura <- tibble::tibble(id = "otros_gastos_cobertura", detalle = "comunidades y años sin cifra",
                              calculado = sum(is.na(com$valor)) + sum(is.na(es$valor)), referencia = 0)
  # 2. Ningún hogar con el gasto total por debajo del alquiler
  negativos <- tibble::tibble(id = "otros_gastos_negativos", detalle = sprintf("hogares con HH070 < HH060 de %d", nrow(h)),
                              calculado = sum(h$otros_gastos < 0), referencia = 0)
  # 3. Rango habitual
  fuera <- tibble::tibble(id = "otros_gastos_rango", detalle = sprintf("cifras fuera de %s a %s € al mes", rango[1], rango[2]),
                          calculado = sum(otros_gastos$valor < rango[1] | otros_gastos$valor > rango[2], na.rm = TRUE), referencia = 0)
  # 4. Ningún hogar se pierde: la suma de las comunidades es la muestra de España
  suma <- com |> dplyr::group_by(anio) |> dplyr::summarise(n = sum(n_hogares), .groups = "drop") |>
    dplyr::left_join(dplyr::select(es, anio, n_es = n_hogares), by = "anio")
  hogares <- tibble::tibble(id = "otros_gastos_hogares", anio = suma$anio, detalle = "hogares de las comunidades menos los de España",
                            calculado = suma$n - suma$n_es, referencia = 0)
  # 5. La mediana por definición, por otro camino: con su valor, el peso de los hogares por debajo es
  # menor que la mitad y el de los que no pasan de él llega a la mitad (sin redondear)
  grupos <- dplyr::bind_rows(dplyr::mutate(h, geo_id = "00"), dplyr::mutate(h, geo_id = codigo)) |>
    dplyr::group_by(anio, geo_id)
  def <- grupos |> dplyr::summarise(
    m = cuantil_ponderado(otros_gastos, peso_hogar, 0.5),
    falla = sum(peso_hogar[otros_gastos < m]) / sum(peso_hogar) >= 0.5 | sum(peso_hogar[otros_gastos <= m]) / sum(peso_hogar) < 0.5 - 1e-12,
    .groups = "drop")
  m <- dplyr::inner_join(def, otros_gastos, by = c("anio", "geo_id"))
  definicion <- tibble::tibble(id = "otros_gastos_mediana", detalle = sprintf("medianas que no cumplen la definición o no cuadran, de %d", nrow(m)),
                               calculado = sum(m$falla) + sum(abs(redondear_1(m$m) - m$mediana) > 1e-9), referencia = 0)
  # 6. Las comunidades con menos observaciones que el mínimo llevan la cifra de España (factor 1), y
  # solo ellas
  marca <- tibble::tibble(id = "otros_gastos_minimo",
                          detalle = sprintf("comunidades con la cifra de España mal marcada (mínimo de %d observaciones con las olas juntas)", minimo),
                          calculado = sum(com$espana != (com$n_factor < minimo) | (com$espana & com$factor != 1)), referencia = 0)
  # 7. El factor de cada comunidad: cumple la definición de la mediana por otro camino (sobre lo que
  # paga cada hogar respecto a la mediana de España de su ola, con las olas juntas), cuadra con la
  # tabla, está en su rango habitual y da la cifra (la de España de la ola por el factor)
  f <- otros_gastos_factores(h, ccaa, minimo)
  def_factor <- otros_gastos_relativos(h) |>
    dplyr::inner_join(dplyr::select(f, geo_id, factor_propio), by = c("codigo" = "geo_id")) |>
    dplyr::group_by(geo_id = codigo) |>
    dplyr::summarise(falla = sum(peso_ola[relativo < factor_propio[1]]) / sum(peso_ola) >= 0.5 |
                       sum(peso_ola[relativo <= factor_propio[1]]) / sum(peso_ola) < 0.5 - 1e-12, .groups = "drop")
  cruce <- dplyr::full_join(dplyr::distinct(com, geo_id, factor, n_factor), f, by = "geo_id", suffix = c("", "_f"))
  aplicado <- dplyr::left_join(otros_gastos, dplyr::select(es, anio, valor_es = valor), by = "anio")
  factor <- tibble::tibble(
    id = "otros_gastos_factor",
    detalle = sprintf("factores de %d comunidades que no cumplen la definición, no cuadran, salen de %s a %s o no dan la cifra",
                      nrow(f), rango_factor[1], rango_factor[2]),
    calculado = sum(def_factor$falla) +
      sum(is.na(cruce$factor) | is.na(cruce$factor_f) | abs(cruce$factor - cruce$factor_f) > 1e-9 | cruce$n_factor != cruce$n_factor_f) +
      sum(f$factor < rango_factor[1] | f$factor > rango_factor[2]) +
      sum(is.na(aplicado$valor) | abs(aplicado$valor - redondear_1(aplicado$valor_es * aplicado$factor)) > 1e-9),
    referencia = 0)
  dplyr::bind_rows(cobertura, negativos, fuera, hogares, definicion, marca, factor)
}

# Rango habitual de la cifra (€ al mes) y del factor de las comunidades: fuera, avisa.
OTROS_GASTOS_RANGO <- c(50, 300)
OTROS_GASTOS_RANGO_FACTOR <- c(0.5, 1.5)

# web/datos/otros_gastos.json (no va en el manifiesto; lo lee js/datos.js, cargarOtrosGastos()):
#   minimo_hogares, anios (las olas), factores (por comunidad, código del INE: f, el factor; n, las
#   observaciones con las olas juntas, y espana si no llegan al mínimo y lleva la cifra de España) y,
#   por ola, la cifra de España («00»: v, € al mes con un decimal, y n, sus hogares) y la de cada
#   comunidad (v y, si es la de España, espana).
exportar_web_otros_gastos <- function(otros_gastos, dir_web = "web", minimo = otros_gastos_minimo()) {
  ruta <- file.path(dir_web, "datos", "otros_gastos.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  anios <- sort(unique(otros_gastos$anio))
  f <- dplyr::distinct(otros_gastos[otros_gastos$nivel == "ccaa", ], geo_id, factor, n_factor, espana)
  f <- f[order(f$geo_id), ]
  factores <- stats::setNames(lapply(seq_len(nrow(f)), function(i) {
    fila <- list(f = f$factor[i], n = f$n_factor[i])
    if (isTRUE(f$espana[i])) fila$espana <- TRUE
    fila
  }), f$geo_id)
  cifras <- lapply(anios, function(a) {
    x <- otros_gastos[otros_gastos$anio == a, ]
    stats::setNames(lapply(seq_len(nrow(x)), function(i) {
      fila <- list(v = x$valor[i])
      if (x$nivel[i] == "nacional") fila$n <- x$n_hogares[i]
      if (isTRUE(x$espana[i])) fila$espana <- TRUE
      fila
    }), x$geo_id)
  })
  names(cifras) <- anios
  j <- list(
    fuente = "ine_ecv",
    definicion = paste("HH070 - HH060 de los hogares que alquilan a precio de mercado (HH021 = 3):",
                       "mediana ponderada (DB090) de España de cada ola por el factor de la comunidad,",
                       "la mediana ponderada, con las olas juntas, de lo que paga cada hogar respecto a la mediana de España de su ola"),
    minimo_hogares = minimo,
    anios = anios,
    factores = factores,
    cifras = cifras
  )
  jsonlite::write_json(j, ruta, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  ruta
}

# Ida y vuelta: el fichero de la web da las mismas cifras, factores, observaciones y marcas que la tabla.
comprobar_web_otros_gastos <- function(otros_gastos, ruta) {
  j <- jsonlite::fromJSON(ruta, simplifyVector = FALSE)
  leidas <- dplyr::bind_rows(lapply(names(j$cifras), function(a) {
    x <- j$cifras[[a]]
    tibble::tibble(anio = as.integer(a), geo_id = names(x),
                   v = vapply(x, function(f) as.numeric(f$v), numeric(1)),
                   n = vapply(x, function(f) if (is.null(f$n)) NA_real_ else as.numeric(f$n), numeric(1)),
                   e = vapply(x, function(f) isTRUE(f$espana), logical(1)))
  }))
  c <- dplyr::full_join(otros_gastos, leidas, by = c("anio", "geo_id"))
  distintas <- sum(is.na(c$v) | is.na(c$valor) | abs(c$v - c$valor) > 1e-9 | c$e != c$espana |
                     (c$nivel == "nacional" & (is.na(c$n) | c$n != c$n_hogares)), na.rm = FALSE)
  com <- dplyr::distinct(otros_gastos[otros_gastos$nivel == "ccaa", ], geo_id, factor, n_factor, espana)
  fj <- tibble::tibble(geo_id = names(j$factores),
                       f = vapply(j$factores, function(x) as.numeric(x$f), numeric(1)),
                       n = vapply(j$factores, function(x) as.numeric(x$n), numeric(1)),
                       e = vapply(j$factores, function(x) isTRUE(x$espana), logical(1)))
  cf <- dplyr::full_join(com, fj, by = "geo_id")
  distintos <- sum(is.na(cf$f) | is.na(cf$factor) | abs(cf$f - cf$factor) > 1e-9 | cf$n != cf$n_factor | cf$e != cf$espana)
  tibble::tibble(id = "web_otros_gastos", detalle = sprintf("cifras y factores distintos de la tabla, de %d y %d", nrow(c), nrow(cf)),
                 calculado = distintas + distintos, referencia = 0)
}
