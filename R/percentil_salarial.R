# Percentil salarial (F3, plan §7): el sueldo neto necesario (21) expresado también como percentil
# de la distribución salarial, para comparar en el tiempo sin depender de los precios de cada año.
#
# Distribución: salario cobrado en el año por los asalariados de cada comunidad (y de España), la
# misma medida que el indicador 7 y la mochila (método B). AEAT, «Asalariados, percepciones
# salariales y salarios por Comunidad Autónoma, tramos de salario y sexo», sexo total, de 2015 a
# 2025: asalariados y salarios en 13 tramos de salario anual, en múltiplos del SMI anual del año
# (14 pagas; SMI_FICHAS): 0–0,5, 0,5–1, …, 4,5–5, 5–7,5, 7,5–10 y más de 10.
#   1. Dentro de cada tramo, densidad lineal con la media del tramo (salarios / asalariados): la
#      pendiente que da esa media, acotada para que la densidad no sea negativa. El último tramo,
#      abierto, se cierra con la media: uniforme entre 10 SMI y 2 × media − 10 SMI.
#   2. Cuantiles de los percentiles 1 a 99 de esa distribución por tramos (bruto anual).
#   3. A neto mensual en 12 (regla 8): × (1 − cotización del trabajador − retención de la AEAT de
#      quien solo cobra salarios de su comunidad y año) ÷ 12, como la mochila. Es una función
#      creciente del bruto, así que el orden (y el percentil) no cambia.
#   4. La web toma la curva de la comunidad de la sección (la de España en País Vasco y Navarra,
#      que la AEAT no cubre, y en Ceuta y Melilla en 2020 y 2021, años en que la tabla no las trae)
#      y el año del alquiler, e interpola el percentil del sueldo necesario
#      que pinta, con los supuestos elegidos (superficie y umbral).
# Incluye a quien trabajó pocos meses, como el indicador 7: el percentil dice qué parte de los
# asalariados cobró en el año menos que ese sueldo (neto, repartido en 12).
# Alternativa descartada (10-nov-2026): el salario medio estimado (SME) del módulo de año completo,
# anualizado por días cotizados y sin los que no llegan al SMI (solo 2019–2024; el percentil 1
# queda en el SMI, y la sección mediana, por debajo del percentil 3).
# Fichero de la web: datos/salarios.json (salarios_web()).

TITULO_AEAT_TRAMOS <- "Asalariados, percepciones salariales y salarios por Comunidad Aut\u00f3noma, tramos de salario y sexo"
# En 2020 y 2021, con una dimensión más (situación ERTE): se toma su total.
TITULO_AEAT_TRAMOS_ERTE <- "Asalariados, percepciones salariales y salarios por Comunidad Aut\u00f3noma, tramos de salario, sexo y situaci\u00f3n ERTE"
ANIOS_PERCENTIL <- 2015:2025       # los años de la mochila: los del alquiler y el último de la AEAT
PERCENTILES_SALARIALES <- 1:99

descargar_aeat_tramos <- function(anio) {
  titulo <- tryCatch({ aeat_buscar_tabla(anio, TITULO_AEAT_TRAMOS); TITULO_AEAT_TRAMOS },
                     error = function(e) TITULO_AEAT_TRAMOS_ERTE)
  descargar_aeat_mercado(anio, titulo, list(Sexo = "Total"))
}

# Tramos de una edición: una fila por comunidad (código del INE; España, «00») y tramo, con sus
# límites en múltiplos del SMI (`hasta` NA en el último), asalariados y salarios (euros). La fila
# del total de cada comunidad lleva `desde` NA (para la compuerta).
leer_aeat_tramos <- function(rutas, anio, ccaa) {
  d <- leer_aeat_mercado(rutas)
  col <- grep("^tramos?_de_salario", names(d), value = TRUE)[1]
  if (is.na(col) || !"sexo" %in% names(d)) {
    stop("La tabla de tramos de salario de la AEAT de ", anio, " no trae sexo y tramo como filtros", call. = FALSE)
  }
  erte <- grep("erte", names(d), value = TRUE)[1]
  if (!is.na(erte)) d <- d[d[[erte]] == "Total", ]
  x <- d |>
    filter(sexo == "Total", columna %in% c("Asalariados", "Salarios")) |>
    transmute(geo = fila, tramo = .data[[col]], columna, valor) |>
    tidyr::pivot_wider(names_from = columna, values_from = valor)
  limites <- regmatches(x$tramo, gregexpr("[0-9]+(,[0-9]+)?", x$tramo))
  numero <- function(v, k) vapply(v, function(z) if (length(z) >= k) as.numeric(sub(",", ".", z[k])) else NA_real_, 0)
  x |>
    transmute(anio = as.integer(anio), ccaa = codigo_ccaa_aeat(geo, ccaa), tramo,
              desde = numero(limites, 1L), hasta = numero(limites, 2L),
              asalariados = Asalariados, salarios = Salarios) |>
    mutate(desde = if_else(tramo == "Total", NA_real_, desde),
           desde = if_else(grepl("^De 0 a", tramo), 0, desde)) |>
    arrange(anio, ccaa, desde)
}

# Límites en euros y densidad lineal de cada tramo: a, b, ancho w, media m y pendiente s de la
# densidad f(t) = 1/w + s (t − w/2), t = x − a, acotada a |s| ≤ 2/w² (densidad no negativa).
tramos_en_euros <- function(tramos, smi = SMI_FICHAS) {
  anual <- smi |> transmute(anio, smi_anual = mensual * pagas)
  tramos |>
    filter(!is.na(desde), asalariados > 0) |>
    inner_join(anual, by = "anio") |>
    mutate(m = salarios / asalariados,
           a = desde * smi_anual,
           b = if_else(is.na(hasta), pmax(2 * m - a, a + 1), hasta * smi_anual),
           w = b - a,
           s_libre = 12 * (m - (a + b) / 2) / w^3,
           s = pmax(pmin(s_libre, 2 / w^2), -2 / w^2)) |>
    arrange(anio, ccaa, desde)
}

# Cuantil p (0–1) de una distribución por tramos (filas de tramos_en_euros() de un territorio).
cuantil_tramos_salario <- function(t, p) {
  n <- t$asalariados
  acum <- cumsum(n) / sum(n)
  vapply(p, function(pp) {
    k <- which(acum >= pp - 1e-12)[1]
    previo <- if (k == 1) 0 else acum[k - 1]
    q <- min(max((pp - previo) / (acum[k] - previo), 0), 1)
    w <- t$w[k]
    s <- t$s[k]
    B <- 1 / w - s * w / 2
    t$a[k] + 2 * q / (B + sqrt(max(B^2 + 2 * s * q, 0)))
  }, 0)
}

# Curva de cada comunidad (y España, «00») y año: percentil, bruto anual y neto mensual en 12.
curvas_salariales <- function(tramos, retenciones, smi = SMI_FICHAS, cotizacion = cotizacion_trabajador,
                              percentiles = PERCENTILES_SALARIALES) {
  t <- tramos_en_euros(tramos, smi)
  claves <- distinct(t, anio, ccaa)
  bind_rows(lapply(seq_len(nrow(claves)), function(k) {
    x <- t[t$anio == claves$anio[k] & t$ccaa == claves$ccaa[k], ]
    tibble::tibble(anio = claves$anio[k], ccaa = claves$ccaa[k], percentil = as.integer(percentiles),
                   bruto_anual = cuantil_tramos_salario(x, percentiles / 100))
  })) |>
    mutate(cotizacion = cotizacion(anio),
           retencion = tipos_retencion(bruto_anual, anio, ccaa, retenciones),
           neto_mensual = bruto_anual * (1 - cotizacion - retencion) / 12) |>
    arrange(anio, ccaa, percentil)
}

# Percentil de un neto mensual en una curva (neto_mensual creciente, percentiles 1 a 99), por
# interpolación lineal; por debajo del primero, 0; por encima del último, 100 (la web escribe
# «por debajo del percentil 1» y «por encima del 99»).
percentil_salarial <- function(neto, curva_neto, percentiles = PERCENTILES_SALARIALES) {
  p <- stats::approx(curva_neto, percentiles, xout = neto, ties = "ordered")$y
  p[!is.na(neto) & neto < min(curva_neto)] <- 0
  p[!is.na(neto) & neto > max(curva_neto)] <- 100
  p
}

# Compuerta (inventario/referencias_validacion.csv), por año:
#   percentil_cobertura (bloqueo): comunidades de régimen común (las 15, sin Ceuta ni Melilla, que
#     faltan en las ediciones de 2020 y 2021) y España sin curva completa (percentiles 1 a 99);
#   percentil_monotono (bloqueo): curvas cuyo neto mensual no crece estrictamente con el percentil;
#   percentil_suma (bloqueo): diferencia máxima entre los asalariados de los 13 tramos y el total
#     de su comunidad o España;
#   percentil_limites (bloqueo): tramos cuyo salario medio cae fuera de sus límites con el SMI
#     anual del año (comprueba qué SMI usa la AEAT para los tramos);
#   percentil_media (alerta): desviación máxima (%) entre la media de la distribución modelada y
#     el salario medio publicado de cada territorio (solo se aparta si se acota alguna pendiente).
CURVAS_OBLIGATORIAS <- c("00", sprintf("%02d", c(1:14, 17)))
comprobar_curvas_salariales <- function(curvas, tramos, smi = SMI_FICHAS, anios = ANIOS_PERCENTIL,
                                        obligatorias = CURVAS_OBLIGATORIAS) {
  n <- length(PERCENTILES_SALARIALES)
  t <- tramos_en_euros(tramos, smi)
  totales <- tramos |> filter(is.na(desde)) |> select(anio, ccaa, total = asalariados, salarios_total = salarios)
  por_anio <- lapply(anios, function(a) {
    c <- curvas[curvas$anio == a, ]
    cuenta <- dplyr::count(c, ccaa)
    monotono <- c |> group_by(ccaa) |> summarise(mal = any(diff(neto_mensual) <= 0), .groups = "drop")
    ta <- t[t$anio == a, ]
    suma <- ta |> group_by(ccaa) |> summarise(n = sum(asalariados), .groups = "drop") |>
      inner_join(totales[totales$anio == a, ], by = "ccaa")
    limites <- sum(ta$m < ta$a - 1e-6 | (!is.na(ta$hasta) & ta$m > ta$b + 1e-6))
    # Media de la densidad lineal de cada tramo: (a + b) / 2 + s w^3 / 12
    media <- ta |> mutate(m_modelo = (a + b) / 2 + s * w^3 / 12) |> group_by(ccaa) |>
      summarise(media = sum(m_modelo * asalariados) / sum(asalariados), .groups = "drop") |>
      inner_join(totales[totales$anio == a, ], by = "ccaa") |>
      mutate(dev = 100 * (media / (salarios_total / total) - 1))
    tibble::tibble(
      id = c("percentil_cobertura", "percentil_monotono", "percentil_suma", "percentil_limites", "percentil_media"),
      anio = as.integer(a),
      detalle = c("territorios sin curva completa", "curvas no crecientes", "asalariados de los tramos frente al total",
                  "tramos con la media fuera de sus l\u00edmites", "media modelada frente a la publicada"),
      calculado = c(length(setdiff(obligatorias, cuenta$ccaa)) + sum(cuenta$n != n), sum(monotono$mal),
                    if (nrow(suma)) max(abs(suma$n - suma$total)) else NA_real_, limites,
                    if (nrow(media)) media$dev[which.max(abs(media$dev))] else NA_real_),
      referencia = 0)
  })
  bind_rows(por_anio) |> mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Lo que lee la web (datos/salarios.json): los percentiles y, por año y comunidad (España, «00»),
# el neto mensual de cada percentil redondeado al euro. La comunidad de cada provincia, de
# territorios.json (ccaa_de_provincia); sin curva propia, la de España.
salarios_web <- function(curvas) {
  anios <- split(curvas, curvas$anio)
  list(fuente = "aeat_mercado_trabajo",
       percentiles = I(PERCENTILES_SALARIALES),
       anios = lapply(anios, function(x) lapply(split(x, x$ccaa), function(y) I(redondeo_guia(y$neto_mensual, 0L)))))
}

# Compuerta de ida y vuelta de datos/salarios.json (web_salarios, bloqueo): cifras distintas de
# las de la tabla de curvas redondeadas, y años o comunidades que faltan o sobran.
comprobar_salarios_web <- function(curvas, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "salarios.json")
  if (!file.exists(ruta)) {
    return(tibble::tibble(id = "web_salarios", anio = NA_integer_, detalle = "falta datos/salarios.json",
                          calculado = 1, referencia = 0))
  }
  web <- jsonlite::read_json(ruta, simplifyVector = TRUE)
  esperado <- salarios_web(curvas)
  claves <- function(x) unlist(lapply(names(x$anios), function(a) paste(a, names(x$anios[[a]]))))
  distintas <- sum(vapply(names(esperado$anios), function(a) {
    sum(vapply(names(esperado$anios[[a]]), function(g) {
      w <- web$anios[[a]][[g]]
      e <- as.numeric(esperado$anios[[a]][[g]])
      if (is.null(w) || length(w) != length(e)) length(e) else sum(abs(as.numeric(w) - e) > 1e-9)
    }, 0))
  }, 0))
  sobran <- length(setdiff(claves(web), claves(esperado))) + length(setdiff(claves(esperado), claves(web)))
  tibble::tibble(id = "web_salarios", anio = NA_integer_, detalle = c("cifras distintas", "curvas que faltan o sobran"),
                 calculado = c(distintas, sobran), referencia = 0)
}
