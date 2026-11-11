# Módulo de supuestos (backlog, tarea 48; plan F3): superficie, umbral, pagas y segundo sueldo, y
# los de la compraventa, en un solo sitio, inventario/supuestos.csv (regla 7). Lo leen:
#   - R, al cargar las funciones: SUPERFICIE_FICHA, UMBRAL_SUELDO y LIMITES_LLEGA (R/derivados.R),
#     ENTRAR_SUPERFICIE_DOS (R/derivados_entrar.R), SUPERFICIE_COMPRA, FINANCIACION_COMPRA y
#     PLAZO_HIPOTECA (R/derivados_compraventa.R) y SUPUESTOS_WEB (R/web_exportar.R, el «supuestos»
#     del manifiesto) salen de aquí. Este fichero se carga antes que los demás (orden alfabético de
#     tar_source(): comun_supuestos.R va antes que derivados*.R y web_*.R) y solo usa R base;
#   - la web, por web/js/supuestos.js, que genera generar_supuestos_js() desde el mismo CSV (como
#     web/estilo/tokens.css desde diseno/tokens.json): web/js/sueldo.js y web/js/estado.js toman de
#     él las superficies, los umbrales, los tramos de «¿te llega?» y las pagas.
# Superficie típica de los pisos alquilados (backlog, decisión 5): alquiler mensual mediano /
# alquiler por m² mediano del SERPAVI, vivienda colectiva, con los dos términos como se publican
# (superficie_tipica_serpavi()), de la sección a la comunidad y de 2015 a 2024. En la web (decisión
# del autor, 11-nov-2026; plan §11, pregunta 59): opción «típica» de «Tu ficha», junto a 50, 70 y 90 m²
# (sin cambiar los 50 m² por defecto), con la del territorio que manda (una sección toma la de su
# municipio; un municipio, una provincia o una comunidad, la suya), y una línea en la ficha de
# municipio. La calcula la página con los dos términos que ya exporta (alquiler_mes y alquiler_m2).
#
# Compuerta (comprobar_supuestos(); inventario/referencias_validacion.csv): supuestos_inventario,
# supuestos_r, supuestos_web, supuestos_muestra_21, supuestos_muestra_15, supuestos_muestra_fichero,
# supuestos_superficie_tipica, supuestos_superficie_tipica_mediana y
# supuestos_superficie_tipica_rango. La muestra: MUESTRA_SUPUESTOS (catorce territorios, de la
# sección a la comunidad) × todas las combinaciones de «Tu ficha» (superficie por defecto, 50, 70,
# 90 o típica, la del municipio en las secciones; umbral del 30 o del 40 %; 12 o 14 pagas; con o sin
# segundo sueldo) y las tres fichas
# de una persona. Sus casos, en pruebas/datos/supuestos_muestra.json (escribir_muestra_supuestos()),
# los comprueban también test-supuestos.R y pruebas/web/supuestos.test.mjs: R y la página coinciden.

# Ruta del CSV desde la raíz del proyecto o desde pruebas/testthat (las pruebas se ejecutan allí).
ruta_supuestos <- function() {
  candidatas <- c(file.path("inventario", "supuestos.csv"), file.path("..", "..", "inventario", "supuestos.csv"))
  r <- candidatas[file.exists(candidatas)]
  if (length(r) == 0L) stop("Falta inventario/supuestos.csv", call. = FALSE)
  r[1]
}

leer_supuestos <- function(ruta = ruta_supuestos()) {
  x <- utils::read.csv(ruta, colClasses = "character", fileEncoding = "UTF-8", na.strings = character(),
                       check.names = FALSE)
  faltan <- setdiff(c("id", "valor", "opciones", "unidad", "uso", "decision", "descripcion"), names(x))
  if (length(faltan) > 0L) stop("inventario/supuestos.csv: faltan las columnas ", paste(faltan, collapse = ", "), call. = FALSE)
  x
}

# Lista «a;b» a números (vacía: numeric(0)).
supuestos_numeros <- function(texto) {
  if (is.na(texto) || !nzchar(texto)) return(numeric(0))
  as.numeric(strsplit(texto, ";", fixed = TRUE)[[1]])
}

SUPUESTOS_INVENTARIO <- leer_supuestos()

# Valor de un supuesto (numérico, sin nombres) y sus opciones.
supuesto <- function(id, supuestos = SUPUESTOS_INVENTARIO) {
  f <- supuestos[supuestos$id == id, ]
  if (nrow(f) != 1L) stop("inventario/supuestos.csv: falta el supuesto ", id, call. = FALSE)
  v <- suppressWarnings(supuestos_numeros(f$valor))
  if (length(v) == 0L || anyNA(v)) stop("inventario/supuestos.csv: ", id, " no es un n\u00famero", call. = FALSE)
  v
}
supuesto_opciones <- function(id, supuestos = SUPUESTOS_INVENTARIO) {
  f <- supuestos[supuestos$id == id, ]
  if (nrow(f) != 1L) stop("inventario/supuestos.csv: falta el supuesto ", id, call. = FALSE)
  supuestos_numeros(f$opciones)
}

# Territorios de la muestra (2024): ocho municipios grandes de distinta superficie típica, cuatro
# secciones de Madrid, Barcelona y Sevilla, una provincia (Madrid) y una comunidad (Madrid).
MUESTRA_SUPUESTOS <- tibble::tribble(
  ~geo_id, ~nivel,
  "28079", "municipio", "08019", "municipio", "46250", "municipio", "41091", "municipio",
  "50297", "municipio", "29067", "municipio", "15030", "municipio", "33044", "municipio",
  "2807901001", "sc", "2807905001", "sc", "0801901001", "sc", "4109101001", "sc",
  "28", "provincia", "13", "ccaa"
)
MUESTRA_SUPUESTOS_ANIO <- 2024L
# Sueldo inventado de «Tu ficha» en la muestra: neto de una paga y segundo sueldo.
MUESTRA_SUPUESTOS_PEON <- list(neto = 1500, segundo = 1000)
# Referencias de la superficie típica (backlog, tarea 37, 2024: Madrid, Barcelona y València) y
# mediana de todos los municipios con los dos términos en 2024 (cálculo del 11-nov-2026).
SUPERFICIE_TIPICA_REFERENCIAS <- list(
  municipios = c("28079" = 62, "08019" = 66, "46250" = 83),
  anio = 2024L
)
# Rango habitual de la superficie típica de un municipio (m²): fuera, avisa.
SUPERFICIE_TIPICA_RANGO <- c(40, 160)
SUPERFICIE_TIPICA_MEDIANA <- 82.1

# Superficie típica: alquiler mensual mediano / alquiler por m² mediano (vivienda colectiva), con
# los términos redondeados como los recibe la web (alquiler_vc()). Estado: el peor de los dos.
superficie_tipica_serpavi <- function(larga_serpavi) {
  clave <- c("geo_id", "nivel", "anio")
  m2 <- alquiler_vc(larga_serpavi, "alquiler_m2") |> dplyr::rename(m2 = valor, e_m2 = estado)
  mes <- alquiler_vc(larga_serpavi, "alquiler_mes") |> dplyr::rename(mes = valor, e_mes = estado)
  dplyr::inner_join(mes, m2, by = clave) |>
    dplyr::mutate(estado = peor_estado(e_mes, e_m2),
                  valor = dplyr::if_else(con_valor(estado) & m2 > 0, mes / m2, NA_real_)) |>
    dplyr::select(geo_id, nivel, anio, alquiler_mes = mes, alquiler_m2 = m2, valor, estado)
}

# Combinaciones de «Tu ficha»: superficie elegida (NA, la de por defecto: la de una persona o, con
# segundo sueldo, la de dos; las opciones; «tipica»), umbral, pagas y segundo sueldo.
supuestos_combinaciones <- function(supuestos = SUPUESTOS_INVENTARIO) {
  expand.grid(superficie = c("defecto", format(supuesto_opciones("superficie_una_persona", supuestos), trim = TRUE), "tipica"),
              umbral = supuesto_opciones("umbral_sueldo", supuestos),
              pagas = supuesto_opciones("pagas", supuestos),
              segundo = c(FALSE, TRUE), stringsAsFactors = FALSE)
}

# Tramo de «¿te llega?» (tramoLlega() de web/js/sueldo.js).
supuestos_tramo_llega <- function(ratio, limites = supuesto("limites_llega")) {
  ifelse(ratio <= limites[1], 0L, ifelse(ratio <= limites[2], 1L, 2L))
}

# Redondeo al entero como Math.round() de la página (empates hacia arriba).
redondear_como_js <- function(x) floor(x + 0.5)

# Términos de la muestra: alquiler mensual y por m² (vivienda colectiva, como los recibe la web),
# superficie típica e ingreso de las tres fichas de una persona del mismo año (la tartera,
# nacional; la mochila y el transistor, el de la provincia; en la comunidad, sin ellos). La
# superficie típica de «Tu ficha» (superficie_tipica) es la del municipio en las secciones y la
# propia en los demás niveles, como en la web (web/js/principal.js, territorioTipica()).
muestra_supuestos <- function(larga_serpavi, perfiles, muestra = MUESTRA_SUPUESTOS, anio = MUESTRA_SUPUESTOS_ANIO) {
  st <- superficie_tipica_serpavi(larga_serpavi)
  st <- st[st$anio == anio, ]
  x <- dplyr::left_join(muestra, st, by = c("geo_id", "nivel"))
  x$anio <- anio
  clave <- ifelse(x$nivel == "sc", paste(substr(x$geo_id, 1, 5), "municipio"), paste(x$geo_id, x$nivel))
  x$superficie_tipica <- st$valor[match(clave, paste(st$geo_id, st$nivel))]
  ing <- ingresos_fichas(perfiles)
  ing <- ing[ing$anio == anio, ]
  for (f in c("tartera", FICHAS_PROVINCIALES)) {
    i <- ing[ing$ficha == f, ]
    clave <- if (f == "tartera") rep("00", nrow(x)) else ifelse(x$nivel == "ccaa", NA_character_, substr(x$geo_id, 1, 2))
    m <- match(clave, i$geo_id)
    x[[paste0("ingreso_", f)]] <- ifelse(con_valor(i$estado[m]), i$ingreso[m], NA_real_)
  }
  x
}

# Cuentas de la página (web/js/sueldo.js y formulas.js) en el mismo orden: ingreso de «Tu ficha»
# ((neto + segundo) × pagas / 12), superficie, alquiler (€/m² × superficie), proporción, tramo,
# sueldo necesario (mínimo con la superficie y principal con el alquiler real) y euros que quedan.
calcular_muestra_supuestos <- function(terminos, supuestos = SUPUESTOS_INVENTARIO, peon = MUESTRA_SUPUESTOS_PEON) {
  comb <- supuestos_combinaciones(supuestos)
  una <- supuesto("superficie_una_persona", supuestos)
  dos <- supuesto("superficie_dos_sueldos", supuestos)
  limites <- supuesto("limites_llega", supuestos)
  peones <- do.call(rbind, lapply(seq_len(nrow(terminos)), function(i) {
    t <- terminos[i, ]
    tipica <- t$superficie_tipica
    sup <- ifelse(comb$superficie == "defecto", ifelse(comb$segundo, dos, una),
                  ifelse(comb$superficie == "tipica", tipica, suppressWarnings(as.numeric(comb$superficie))))
    ingreso <- ((peon$neto + ifelse(comb$segundo, peon$segundo, 0)) * comb$pagas) / 12
    alquiler <- t$alquiler_m2 * sup
    ratio <- alquiler / ingreso
    data.frame(geo_id = t$geo_id, nivel = t$nivel, ficha = "peon", eleccion = comb$superficie, umbral = comb$umbral,
               pagas = comb$pagas, segundo = comb$segundo, superficie = sup, ingreso = ingreso, alquiler = alquiler,
               ratio = ratio, tramo = supuestos_tramo_llega(ratio, limites),
               sueldo_minimo = (t$alquiler_m2 * sup) / comb$umbral, sueldo_real = t$alquiler_mes / comb$umbral,
               euros = redondear_como_js(ingreso) - redondear_como_js(alquiler), stringsAsFactors = FALSE)
  }))
  fichas <- do.call(rbind, lapply(c("tartera", FICHAS_PROVINCIALES), function(f) {
    ingreso <- terminos[[paste0("ingreso_", f)]]
    alquiler <- terminos$alquiler_m2 * una
    ratio <- alquiler / ingreso
    data.frame(geo_id = terminos$geo_id, nivel = terminos$nivel, ficha = f, eleccion = "defecto",
               umbral = supuesto("umbral_sueldo", supuestos), pagas = NA_real_, segundo = NA,
               superficie = una, ingreso = ingreso, alquiler = alquiler, ratio = ratio,
               tramo = supuestos_tramo_llega(ratio, limites),
               sueldo_minimo = alquiler / supuesto("umbral_sueldo", supuestos),
               sueldo_real = terminos$alquiler_mes / supuesto("umbral_sueldo", supuestos),
               euros = redondear_como_js(ingreso) - redondear_como_js(alquiler), stringsAsFactors = FALSE)
  }))
  tibble::as_tibble(rbind(peones, fichas))
}

# web/js/supuestos.js: los supuestos de la página, generados desde el CSV (no se editan a mano).
texto_supuestos_js <- function(supuestos = SUPUESTOS_INVENTARIO) {
  lista <- function(x) paste0("[", paste(format(x, trim = TRUE, scientific = FALSE), collapse = ", "), "]")
  num <- function(x) format(x, trim = TRUE, scientific = FALSE)
  c("// Generado por generar_supuestos_js() (R/comun_supuestos.R) desde inventario/supuestos.csv: no se",
    "// edita a mano. Supuestos de \u00abTu sueldo\u00bb (backlog, tarea 48): superficies en m\u00b2, umbrales en %,",
    "// tramos de \u00ab\u00bfte llega?\u00bb como proporci\u00f3n del ingreso, pagas al a\u00f1o y sueldo m\u00e1ximo en euros.",
    "export const SUPUESTOS = Object.freeze({",
    sprintf("  superficies: Object.freeze(%s),", lista(supuesto_opciones("superficie_una_persona", supuestos))),
    sprintf("  superficie_una_persona: %s,", num(supuesto("superficie_una_persona", supuestos))),
    sprintf("  superficie_dos_sueldos: %s,", num(supuesto("superficie_dos_sueldos", supuestos))),
    sprintf("  umbrales: Object.freeze(%s),", lista(round(100 * supuesto_opciones("umbral_sueldo", supuestos)))),
    sprintf("  umbral_sueldo: %s,", num(round(100 * supuesto("umbral_sueldo", supuestos)))),
    sprintf("  limites_llega: Object.freeze(%s),", lista(supuesto("limites_llega", supuestos))),
    sprintf("  pagas: Object.freeze(%s),", lista(supuesto_opciones("pagas", supuestos))),
    sprintf("  pagas_defecto: %s,", num(supuesto("pagas", supuestos))),
    sprintf("  divisor_llave: %s,", num(supuesto("divisor_llave", supuestos))),
    sprintf("  sueldo_maximo: %s,", num(supuesto("sueldo_maximo", supuestos))),
    "});")
}

generar_supuestos_js <- function(supuestos = SUPUESTOS_INVENTARIO, ruta = file.path("web", "js", "supuestos.js")) {
  texto <- enc2utf8(texto_supuestos_js(supuestos))
  previo <- if (file.exists(ruta)) readLines(ruta, encoding = "UTF-8", warn = FALSE) else character(0)
  if (!identical(previo, texto)) {
    con <- file(ruta, open = "wb")   # saltos de linea LF, tambien en Windows
    on.exit(close(con))
    writeLines(texto, con, useBytes = TRUE)
  }
  ruta
}

# Casos de la muestra en un JSON que leen las pruebas de R y de la página (se escribe a mano tras
# cambiar los supuestos o la muestra: escribir_muestra_supuestos(tar_read(terminos_supuestos))).
escribir_muestra_supuestos <- function(terminos, supuestos = SUPUESTOS_INVENTARIO,
                                       ruta = file.path("pruebas", "datos", "supuestos_muestra.json")) {
  casos <- calcular_muestra_supuestos(terminos, supuestos)
  x <- list(
    nota = paste("Muestra del m\u00f3dulo de supuestos (tarea 48): t\u00e9rminos del SERPAVI y de las fichas de",
                 MUESTRA_SUPUESTOS_ANIO, "como los recibe la web; el sueldo de \u00abTu ficha\u00bb es inventado."),
    peon = MUESTRA_SUPUESTOS_PEON,
    terminos = terminos[, c("geo_id", "nivel", "anio", "alquiler_mes", "alquiler_m2", "superficie_tipica",
                            "ingreso_tartera", "ingreso_mochila", "ingreso_transistor")],
    casos = casos
  )
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, na = "null", pretty = TRUE)
  ruta
}

# Compuerta del módulo de supuestos.
comprobar_supuestos <- function(supuestos, terminos, larga_derivados, superficie_tipica,
                                ruta_js = file.path("web", "js", "supuestos.js"),
                                ruta_mapa = file.path("web", "mapa.html"),
                                ruta_muestra = file.path("pruebas", "datos", "supuestos_muestra.json")) {
  fila <- function(id, detalle, calculado, referencia) {
    tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(calculado), referencia = as.numeric(referencia))
  }
  # 1. Inventario: cada valor entre sus opciones, los obligatorios presentes, unidades y decision.
  obligatorios <- c("superficie_una_persona", "superficie_dos_sueldos", "umbral_sueldo", "limites_llega", "pagas",
                    "segundo_sueldo", "sueldo_maximo", "divisor_llave", "superficie_tipica", "superficie_compra",
                    "financiacion_compra", "plazo_hipoteca")
  con_opciones <- supuestos[nzchar(supuestos$opciones), ]
  fuera <- sum(!vapply(seq_len(nrow(con_opciones)), function(i) {
    all(supuestos_numeros(con_opciones$valor[i]) %in% supuestos_numeros(con_opciones$opciones[i]))
  }, logical(1)))
  incompletos <- sum(!nzchar(supuestos$unidad) | !nzchar(supuestos$uso) | !nzchar(supuestos$decision))
  inventario <- fila("supuestos_inventario", "fuera de sus opciones, sin unidad, uso o decisi\u00f3n, obligatorios que faltan o duplicados",
                     fuera + incompletos + length(setdiff(obligatorios, supuestos$id)) + sum(duplicated(supuestos$id)), 0)
  # 2. R: las constantes del pipeline son las del CSV.
  r <- list(
    SUPERFICIE_FICHA = c(SUPERFICIE_FICHA, supuesto("superficie_una_persona", supuestos)),
    ENTRAR_SUPERFICIE_DOS = c(ENTRAR_SUPERFICIE_DOS, supuesto("superficie_dos_sueldos", supuestos)),
    UMBRAL_SUELDO = c(UMBRAL_SUELDO, supuesto("umbral_sueldo", supuestos)),
    LIMITES_LLEGA = list(LIMITES_LLEGA, supuesto("limites_llega", supuestos)),
    entrar_tramo_llega = list(eval(formals(entrar_tramo_llega)$limites), supuesto("limites_llega", supuestos)),
    SUPUESTOS_WEB = list(unlist(SUPUESTOS_WEB), c(superficie_m2 = supuesto("superficie_una_persona", supuestos),
                                                  umbral = supuesto("umbral_sueldo", supuestos))),
    SUPERFICIE_COMPRA = c(SUPERFICIE_COMPRA, supuesto("superficie_compra", supuestos)),
    FINANCIACION_COMPRA = c(FINANCIACION_COMPRA, supuesto("financiacion_compra", supuestos)),
    PLAZO_HIPOTECA = c(PLAZO_HIPOTECA, supuesto("plazo_hipoteca", supuestos))
  )
  distintas <- names(r)[!vapply(r, function(p) isTRUE(all.equal(unname(unlist(p[1])), unname(unlist(p[2])))), logical(1))]
  constantes <- fila("supuestos_r", paste(c("constantes distintas del CSV:", distintas), collapse = " "), length(distintas), 0)
  # 3. Web: supuestos.js generado desde el CSV y botones de mapa.html (el manifiesto lleva
  # SUPUESTOS_WEB, ya comprobado en el punto 2).
  js <- if (file.exists(ruta_js)) readLines(ruta_js, encoding = "UTF-8", warn = FALSE) else character(0)
  mapa <- paste(readLines(ruta_mapa, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  botones <- function(atributo) {
    m <- regmatches(mapa, gregexpr(sprintf("data-%s=\"([0-9]+)\"", atributo), mapa))[[1]]
    as.numeric(gsub("[^0-9]", "", m))
  }
  web_fallos <- c(
    js = !identical(js, enc2utf8(texto_supuestos_js(supuestos))),
    superficie = !setequal(botones("superficie"), supuesto_opciones("superficie_una_persona", supuestos)),
    tipica = !grepl("data-superficie=\"tipica\"", mapa, fixed = TRUE),   # opcion "tipica" de Tu ficha
    umbral = !setequal(botones("umbral"), round(100 * supuesto_opciones("umbral_sueldo", supuestos))),
    pagas = !setequal(botones("pagas"), supuesto_opciones("pagas", supuestos))
  )
  web <- fila("supuestos_web", paste(c("distintos del CSV:", names(web_fallos)[web_fallos]), collapse = " "), sum(web_fallos), 0)
  # 4 y 5. Muestra: con los supuestos por defecto, las cuentas de la pagina reproducen el
  # indicador 21 (sus dos cifras) y el 15 de la tabla larga, por territorio.
  casos <- calcular_muestra_supuestos(terminos, supuestos)
  d <- larga_derivados[larga_derivados$anio == MUESTRA_SUPUESTOS_ANIO &
                         paste(larga_derivados$geo_id, larga_derivados$nivel) %in% paste(terminos$geo_id, terminos$nivel), ]
  desv <- function(a, b) ifelse(is.na(a) & is.na(b), 0, 100 * abs(a / b - 1))
  defecto <- casos[casos$ficha == "peon" & casos$eleccion == format(supuesto("superficie_una_persona", supuestos), trim = TRUE) &
                     casos$umbral == supuesto("umbral_sueldo", supuestos) & casos$pagas == supuesto("pagas", supuestos) & !casos$segundo, ]
  clave <- paste(defecto$geo_id, defecto$nivel)
  minimo <- d[d$indicador == "sueldo_necesario" & d$corte == CORTE_MINIMO_SUELDO, ]
  principal <- d[d$indicador == "sueldo_necesario" & d$corte == "total", ]
  dif21 <- c(desv(defecto$sueldo_minimo, minimo$valor[match(clave, paste(minimo$geo_id, minimo$nivel))]),
             desv(defecto$sueldo_real, principal$valor[match(clave, paste(principal$geo_id, principal$nivel))]))
  muestra21 <- fila("supuestos_muestra_21", sprintf("desviaci\u00f3n m\u00e1xima (%%) en %d territorios", nrow(defecto)),
                    if (anyNA(dif21)) NA_real_ else max(dif21), 0)
  fichas <- casos[casos$ficha != "peon" & !is.na(casos$ingreso), ]
  p15 <- d[d$indicador == "peso_alquiler_ingreso", ]
  ref15 <- p15$valor[match(paste(fichas$geo_id, fichas$nivel, fichas$ficha), paste(p15$geo_id, p15$nivel, p15$grupo))]
  dif15 <- desv(100 * fichas$ratio, ref15)
  muestra15 <- fila("supuestos_muestra_15", sprintf("desviaci\u00f3n m\u00e1xima (%%) en %d cifras de fichas", nrow(fichas)),
                    if (anyNA(dif15) || nrow(fichas) == 0L) NA_real_ else max(dif15), 0)
  # 6. El JSON de la muestra que leen las pruebas sigue al dia (terminos y casos).
  al_dia <- file.exists(ruta_muestra) && {
    j <- jsonlite::fromJSON(ruta_muestra)
    nums <- c("alquiler_mes", "alquiler_m2", "superficie_tipica", "ingreso_tartera", "ingreso_mochila", "ingreso_transistor")
    isTRUE(all.equal(as.data.frame(j$terminos[, nums]), as.data.frame(terminos[, nums]), check.attributes = FALSE)) &&
      nrow(j$casos) == nrow(casos) &&
      isTRUE(all.equal(j$casos$sueldo_minimo, casos$sueldo_minimo)) && isTRUE(all.equal(j$casos$ratio, casos$ratio))
  }
  fichero <- fila("supuestos_muestra_fichero", "pruebas/datos/supuestos_muestra.json distinto de la muestra (0 = al d\u00eda)",
                  if (al_dia) 0 else 1, 0)
  # 7 a 9. Superficie tipica: referencias de la tarea 37, mediana municipal y rango.
  ref <- SUPERFICIE_TIPICA_REFERENCIAS
  st <- superficie_tipica[superficie_tipica$anio == ref$anio & superficie_tipica$nivel == "municipio", ]
  tipica <- fila("supuestos_superficie_tipica", paste("municipio", names(ref$municipios), ref$anio),
                 st$valor[match(names(ref$municipios), st$geo_id)], ref$municipios)
  mediana <- fila("supuestos_superficie_tipica_mediana",
                  sprintf("mediana de %d municipios, %d", sum(!is.na(st$valor)), ref$anio),
                  stats::median(st$valor, na.rm = TRUE), SUPERFICIE_TIPICA_MEDIANA)
  todos <- superficie_tipica[superficie_tipica$nivel == "municipio" & !is.na(superficie_tipica$valor), ]
  rango <- fila("supuestos_superficie_tipica_rango",
                sprintf("cifras municipales fuera de %s a %s m\u00b2, 2015-2024", SUPERFICIE_TIPICA_RANGO[1], SUPERFICIE_TIPICA_RANGO[2]),
                sum(todos$valor < SUPERFICIE_TIPICA_RANGO[1] | todos$valor > SUPERFICIE_TIPICA_RANGO[2]), 0)
  dplyr::bind_rows(inventario, constantes, web, muestra21, muestra15, fichero, tipica, mediana, rango)
}
