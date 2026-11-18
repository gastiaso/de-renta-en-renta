# Cifras del «Método en dos páginas» (docs/metodo_corto.md y docs/short_method.md) que salen del
# pipeline (revisión del 18-nov-2026: hasta entonces, el 42 % y el 83 % estaban escritos a mano, sin
# código que los calculara ni compuerta que los vigilara; regla «cada cifra sale del pipeline»):
#   subida: mediana de la subida del alquiler por m² del SERPAVI (vivienda colectiva) de `desde` a
#     `hasta` en las secciones con dato los dos años (estado «dato» o «estimado»), en %, y cuántas son;
#   cobertura: en `anio`, secciones con mediana del alquiler mensual de la vivienda colectiva y
#     población que vive en ellas (la del ADRH de ese año llevada al seccionado de 2021 con su
#     tabla de paso), en % del total.
# La compuerta (comprobar_cifras_metodo_corto(), bloqueo metodo_corto_cifras) lee las dos frases de
# docs/metodo_corto.md y compara: la cifra escrita, redondeada como en el texto, debe ser la calculada.

cifra_subida_serpavi <- function(larga_serpavi, desde = 2015L, hasta = 2024L, grupo = "VC") {
  x <- larga_serpavi |>
    dplyr::filter(nivel == "sc", indicador == "alquiler_m2", corte == "tipologia", grupo == !!grupo,
                  anio %in% c(desde, hasta), estado %in% c("dato", "estimado"), !is.na(valor), valor > 0) |>
    dplyr::select(geo_id, anio, valor) |>
    tidyr::pivot_wider(names_from = anio, values_from = valor, names_prefix = "a")
  a <- x[[paste0("a", desde)]]
  b <- x[[paste0("a", hasta)]]
  ok <- !is.na(a) & !is.na(b)
  tibble::tibble(desde = desde, hasta = hasta, secciones = sum(ok),
                 subida_mediana = if (any(ok)) stats::median(100 * (b[ok] / a[ok] - 1)) else NA_real_)
}

cifra_cobertura_serpavi <- function(larga_serpavi, poblacion_adrh, tabla_paso, anio = 2024L, grupo = "VC") {
  sc <- larga_serpavi |>
    dplyr::filter(nivel == "sc", indicador == "alquiler_mes", corte == "tipologia", grupo == !!grupo, anio == !!anio)
  con <- sc$geo_id[sc$estado %in% c("dato", "estimado")]
  pob <- poblacion_adrh |>
    dplyr::filter(anio == !!anio, nivel == "seccion") |>
    dplyr::select(seccion = codigo, valor) |>
    geo_reproyectar_recuento(tabla_paso)
  pob <- pob[pob$seccion %in% sc$geo_id, ]
  tibble::tibble(anio = anio, secciones = nrow(sc), con_dato = length(con),
                 pct_secciones = 100 * length(con) / nrow(sc),
                 pct_poblacion = 100 * sum(pob$valor[pob$seccion %in% con], na.rm = TRUE) / sum(pob$valor, na.rm = TRUE))
}

# Número escrito en castellano («21.609», «42», «83,5») a número.
numero_texto_es <- function(x) as.numeric(gsub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE))

# Lee las cifras de las dos frases del método corto (NA si la frase ya no está como se espera).
leer_cifras_metodo_corto <- function(ruta = file.path("docs", "metodo_corto.md")) {
  texto <- paste(readLines(ruta, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  pilla <- function(patron, k) {
    m <- regmatches(texto, regexec(patron, texto, perl = TRUE))[[1]]
    if (length(m) < k + 1L) NA_real_ else numero_texto_es(m[k + 1L])
  }
  subida <- "De (\\d{4}) a (\\d{4}), en las ([\\d.]+) secciones con dato los dos años, la mediana de la subida del alquiler por m² del SERPAVI es del (\\d+) %"
  cobertura <- "en (\\d{4}) tiene dato el (\\d+) % de las secciones, donde vive en torno al (\\d+) % de la población"
  c(desde = pilla(subida, 1), hasta = pilla(subida, 2), secciones = pilla(subida, 3), subida = pilla(subida, 4),
    anio = pilla(cobertura, 1), pct_secciones = pilla(cobertura, 2), pct_poblacion = pilla(cobertura, 3))
}

comprobar_cifras_metodo_corto <- function(subida, cobertura, ruta = file.path("docs", "metodo_corto.md")) {
  t <- leer_cifras_metodo_corto(ruta)
  tibble::tibble(
    id = "metodo_corto_cifras", anio = as.integer(c(subida$hasta, subida$hasta, cobertura$anio, cobertura$anio)),
    detalle = c("secciones con dato los dos años", "mediana de la subida del alquiler por m² (%)",
                "secciones con dato (%)", "población en secciones con dato (%)"),
    calculado = c(t[["secciones"]], t[["subida"]], t[["pct_secciones"]], t[["pct_poblacion"]]),
    referencia = c(subida$secciones, round(subida$subida_mediana), round(cobertura$pct_secciones),
                   round(cobertura$pct_poblacion))
  )
}
