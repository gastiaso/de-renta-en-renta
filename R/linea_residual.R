# Línea de ingreso residual (backlog, tarea 65; docs/especificacion_ingreso_residual.md, parte A;
# decisión del autor, 13-nov-2026). Dos líneas mensuales por año y tipo de hogar (una persona y dos
# adultos, sin menores), con que la web compara lo que queda tras pagar la vivienda:
#   - linea_imv (boe_imv): renta garantizada del ingreso mínimo vital, el 100 % de la pensión no
#     contributiva (PNC) anual / 12 (RDL 20/2020, art. 10.2.a; Ley 19/2021, art. 13.2.a), +30 % por el
#     segundo adulto (art. 13.2.b). De 2015 a 2019, antes del IMV, la PNC anual / 12, rotulada como tal
#     (tipo «pnc»). Las cuantías, en inventario/cuantias_imv.csv, transcritas del BOE: 2020, 5.538 € (sin
#     los 40 céntimos de la PNC; art. 10.5); 2022, media de sus dos cuantías ponderada por meses (de
#     abril a diciembre, +15 %: RDL 6/2022, art. 45, en la redacción del RDL 11/2022), como el SMI de
#     2021 (R/fuente_boe_smi.R). La PNC de cada año se comprueba en el XML del BOE de su norma, en
#     datos/brutos/boe_imv/, solo en los años con xml_pnc = TRUE (los XML de menos de 200 KB: el resto,
#     de 0,4 a 2,9 MB, no se bajan; el límite de descarga de la tarea es de 1 MB);
#   - linea_pobreza_ecv (ine_ecv_umbral): umbral de riesgo de pobreza de la ECV del INE, sin alquiler
#     imputado (tabla 9964, «Umbral de riesgo de pobreza (valores ilustrativos)», por la API JSON del
#     INE), hogar unipersonal / 12; dos adultos, × 1,5 (escala de la OCDE modificada: el INE publica el
#     hogar de dos adultos y dos menores de 14, × 2,1). Año = el de los ingresos (ola − 1): el alquiler
#     de 2024 va con la ECV 2025, como la mochila (regla 4).
# Las dos se guardan al céntimo; la de dos adultos, de la cifra anual × la escala. La del IMV (y la PNC),
# truncada, como la publica la Seguridad Social (604,21 € en 2024, no 604,22; tarea 65, decisiones del
# 17-nov-2026: truncar_centimo()); la de la ECV, redondeada (empate hacia arriba).
# Van a la tabla larga (nivel nacional, corte hogar) y a la web (datos/lineas_residual.json). La web
# calcula el ingreso residual por sección con los términos que ya exporta (residual.js); R y la página
# coinciden en la muestra de los supuestos (calcular_muestra_residual(), pruebas/datos/residual_muestra.json).

DIR_BOE_IMV <- file.path("datos", "brutos", "boe_imv")
DIR_INE_ECV_UMBRAL <- file.path("datos", "brutos", "ine_ecv_umbral")
TABLA_ECV_UMBRAL <- "9964"
URL_INE_TABLA_JSON <- "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/%s"
ESCALA_LINEA <- c(imv = 1.3, ecv = 1.5)
HOGARES_LINEA <- c("una_persona", "dos_adultos")
INDICADOR_LINEA <- c(imv = "linea_imv", ecv = "linea_pobreza_ecv")
FUENTE_LINEA <- c(imv = "boe_imv", ecv = "ine_ecv_umbral")
# Umbral de una persona de la ECV 2025 (ingresos de 2024) en la nota de prensa del INE de 5-feb-2026,
# 12.220,4 € al año: referencia de la compuerta residual_umbral_ecv_2025.
UMBRAL_ECV_REFERENCIA <- c(ola = 2025, valor = 12220.4)
# Años que deben tener línea: el IMV, de 2015 a 2026 (el SMI de la tartera llega a 2026); la ECV, los
# ingresos de 2015 a 2024 (los años del alquiler del SERPAVI).
ANIOS_LINEA <- list(imv = 2015:2026, ecv = 2015:2024)

# Ruta del CSV desde la raíz del proyecto o desde pruebas/testthat.
ruta_cuantias_imv <- function() {
  candidatas <- c(file.path("inventario", "cuantias_imv.csv"), file.path("..", "..", "inventario", "cuantias_imv.csv"))
  r <- candidatas[file.exists(candidatas)]
  if (length(r) == 0L) stop("Falta inventario/cuantias_imv.csv", call. = FALSE)
  r[1]
}

leer_cuantias_imv <- function(ruta = ruta_cuantias_imv()) {
  x <- readr::read_csv(ruta, col_types = readr::cols(
    anio = "i", desde = "i", tipo = "c", linea_anual = "d", norma_linea = "c", pnc_anual = "d", norma_pnc = "c",
    boe_pnc = "c", xml_pnc = "l", imv_mes_publicado = "d", imv_dos_mes_publicado = "d", nota = "c"
  ), progress = FALSE)
  if (anyNA(x$anio) || anyNA(x$desde) || any(x$desde < 1L | x$desde > 12L)) stop("cuantias_imv.csv: a\u00f1o o mes vac\u00edo o fuera de 1 a 12", call. = FALSE)
  if (anyDuplicated(x[c("anio", "desde")])) stop("cuantias_imv.csv: a\u00f1o y mes repetidos", call. = FALSE)
  if (!all(x$tipo %in% c("imv", "pnc"))) stop("cuantias_imv.csv: tipo distinto de imv o pnc", call. = FALSE)
  x[order(x$anio, x$desde), ]
}

# XML de las normas de la PNC de los años con xml_pnc, con caché (como descargar_boe_smi()).
descargar_boe_imv <- function(cuantias, dir = DIR_BOE_IMV) {
  f <- cuantias[cuantias$xml_pnc %in% TRUE & !is.na(cuantias$boe_pnc), ]
  unname(vapply(seq_len(nrow(f)), function(i) {
    descargar_con_cache(sprintf(URL_BOE_XML, f$boe_pnc[i]), file.path(dir, paste0(f$anio[i], "_", f$boe_pnc[i], ".xml")))
  }, ""))
}

# Cifra anual de la PNC de jubilacion e invalidez en el texto de una norma: la primera cantidad en
# euros tras «no contributiva» en la misma frase («queda fijada en 5.136,60 euros integros anuales»,
# «modalidad no contributiva: 5.164,60 euros/ano», «tendran un importe anual de 8.803,20 euros»).
cifra_pnc_texto <- function(texto) {
  texto <- gsub("\\s+", " ", gsub("\u00a0", " ", texto, fixed = TRUE))
  m <- regmatches(texto, regexec("no contributiva[^.;]{0,300}?([0-9]{1,2}\\.[0-9]{3},[0-9]{2}) euros", texto, perl = TRUE))[[1]]
  if (length(m) < 2L) return(NA_real_)
  as.numeric(sub(",", ".", gsub(".", "", m[2], fixed = TRUE), fixed = TRUE))
}

# Año (del nombre del fichero), identificador y PNC anual de cada XML.
leer_boe_pnc <- function(rutas) {
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    x <- xml2::read_xml(ruta)
    campo <- function(xpath) xml2::xml_text(xml2::xml_find_first(x, xpath))
    tibble::tibble(anio = as.integer(sub("_.*$", "", basename(ruta))), id = campo("/documento/metadatos/identificador"),
                   pnc_anual = cifra_pnc_texto(campo("/documento/texto")))
  }))
}

descargar_ine_ecv_umbral <- function(id = TABLA_ECV_UMBRAL, dir = DIR_INE_ECV_UMBRAL, forzar = FALSE) {
  descargar_con_cache(sprintf(URL_INE_TABLA_JSON, id), file.path(dir, paste0(id, ".json")), forzar)
}

# Series de la tabla del INE: ola, hogar (una_persona o dos_adultos_dos_menores), con o sin alquiler
# imputado y valor anual. Se detiene si falta la serie del hogar unipersonal sin alquiler imputado.
leer_ine_ecv_umbral <- function(ruta) {
  j <- jsonlite::fromJSON(ruta, simplifyVector = FALSE)
  x <- dplyr::bind_rows(lapply(j, function(s) {
    nombre <- s$Nombre
    hogar <- if (grepl("unipersonal", nombre)) "una_persona" else if (grepl("2 adultos", nombre)) "dos_adultos_dos_menores" else NA_character_
    tibble::tibble(ola = vapply(s$Data, function(d) as.integer(d$Anyo), integer(1)),
                   valor = vapply(s$Data, function(d) if (is.null(d$Valor)) NA_real_ else as.numeric(d$Valor), numeric(1)),
                   hogar = hogar, imputado = grepl("alquiler imputado", nombre), serie = s$COD)
  }))
  x <- x[!is.na(x$hogar), ]
  if (!any(x$hogar == "una_persona" & !x$imputado)) stop("Tabla ", basename(ruta), ": falta el umbral del hogar unipersonal", call. = FALSE)
  if (anyDuplicated(x[c("ola", "hogar", "imputado")])) stop("Tabla ", basename(ruta), ": olas repetidas", call. = FALSE)
  x[order(x$hogar, x$imputado, x$ola), ]
}

# Cifra anual de la linea de un ano: media de sus cuantias ponderada por los meses de vigencia.
anual_ponderado <- function(desde, cuantia) {
  hasta <- c(desde[-1] - 1L, 12L)
  sum(cuantia * (hasta - desde + 1L)) / 12
}

# Truncado al centimo (tarea 65, decisiones del 17-nov-2026): la Seguridad Social publica el IMV mensual
# truncado (565,37 en 2023, 604,21 en 2024, 658,81 en 2025). La tolerancia evita que el binario baje un
# centimo una cifra exacta (953,68 se guarda como 953,679999...).
truncar_centimo <- function(x) floor(x * 100 + 1e-6) / 100

# Lineas mensuales: linea, anio, hogar, valor (euros al mes, al centimo: el IMV y la PNC, truncados; la
# ECV, redondeada), tipo (imv, pnc o ecv), ola (la de la ECV) y anual (la cifra anual de una persona de
# que salen).
calcular_lineas_residual <- function(cuantias, umbral) {
  imv <- dplyr::bind_rows(lapply(split(cuantias, cuantias$anio), function(f) {
    anual <- anual_ponderado(f$desde, f$linea_anual)
    tibble::tibble(linea = "imv", anio = f$anio[1], hogar = HOGARES_LINEA,
                   valor = truncar_centimo(anual * c(1, ESCALA_LINEA[["imv"]]) / 12),
                   tipo = f$tipo[1], ola = NA_integer_, anual = anual)
  }))
  u <- umbral[umbral$hogar == "una_persona" & !umbral$imputado & !is.na(umbral$valor), ]
  ecv <- dplyr::bind_rows(lapply(seq_len(nrow(u)), function(i) {
    tibble::tibble(linea = "ecv", anio = u$ola[i] - 1L, hogar = HOGARES_LINEA,
                   valor = redondear_empate_arriba(u$valor[i] * c(1, ESCALA_LINEA[["ecv"]]) / 12, 2L),
                   tipo = "ecv", ola = u$ola[i], anual = u$valor[i])
  }))
  dplyr::bind_rows(imv, ecv)
}

# Filas de la tabla larga: nivel nacional, corte hogar, euros al mes.
armonizar_lineas_residual <- function(lineas, version_imv, version_ecv) {
  tibble::tibble(geo_id = "00", nivel = "nacional", anio = as.integer(lineas$anio),
                 indicador = unname(INDICADOR_LINEA[lineas$linea]), corte = "hogar", grupo = lineas$hogar,
                 valor = lineas$valor, estado = "dato", fuente = unname(FUENTE_LINEA[lineas$linea]),
                 geo_ref = NA_character_, version = ifelse(lineas$linea == "imv", version_imv, version_ecv))
}

# Compuerta de las lineas (inventario/referencias_validacion.csv):
#   residual_pnc_boe (bloqueo): PNC anual del CSV frente a la de su XML del BOE (anos con xml_pnc);
#   residual_imv_publicada (bloqueo): IMV mensual de una persona y de dos adultos frente a las cifras
#     del CSV: las publicadas por la Seguridad Social (2023 a 2025, truncadas, y 2026: 733,60 y 953,68
#     euros) y, en 2020, la del RDL 20/2020 (anexo I, 5.538 euros al ano / 12 = 461,50; IMV desde el
#     1 de junio de 2020);
#   residual_umbral_ecv (bloqueo): linea de una persona x 12 frente al umbral anual del INE, cada ola;
#   residual_umbral_ecv_2025 (bloqueo): umbral de la ECV 2025 frente a la nota de prensa del INE;
#   residual_escala (bloqueo): dos adultos = una persona x 1,3 (IMV) o x 1,5 (ECV), al centimo;
#   residual_escala_ine (alerta): el hogar de dos adultos y dos menores del INE = una persona x 2,1;
#   residual_serie (bloqueo): anos sin linea de los que debe tener (ANIOS_LINEA).
comprobar_lineas_residual <- function(lineas, cuantias, pnc_boe, umbral) {
  fila <- function(id, anio, detalle, calculado, referencia) {
    tibble::tibble(id = id, anio = as.integer(anio), detalle = detalle, calculado = as.numeric(calculado),
                   referencia = as.numeric(referencia))
  }
  b <- pnc_boe[order(pnc_boe$anio), ]
  ref_pnc <- cuantias[cuantias$xml_pnc %in% TRUE, ]
  pnc <- fila("residual_pnc_boe", b$anio, paste(b$id, "PNC anual"), ref_pnc$pnc_anual[match(b$anio, ref_pnc$anio)], b$pnc_anual)
  faltan_xml <- fila("residual_pnc_boe", NA, "a\u00f1os con xml_pnc sin XML le\u00eddo", length(setdiff(ref_pnc$anio, b$anio)), 0)
  imv <- lineas[lineas$linea == "imv", ]
  pub <- cuantias[!is.na(cuantias$imv_mes_publicado) | !is.na(cuantias$imv_dos_mes_publicado), ]
  publicada <- dplyr::bind_rows(lapply(seq_len(nrow(pub)), function(i) {
    a <- pub$anio[i]
    x <- imv[imv$anio == a, ]
    fila("residual_imv_publicada", a, paste("IMV mensual,", c("una persona", "dos adultos")),
         x$valor[match(HOGARES_LINEA, x$hogar)], c(pub$imv_mes_publicado[i], pub$imv_dos_mes_publicado[i]))
  }))
  publicada <- publicada[!is.na(publicada$referencia), ]
  u <- umbral[umbral$hogar == "una_persona" & !umbral$imputado & !is.na(umbral$valor), ]
  ecv1 <- lineas[lineas$linea == "ecv" & lineas$hogar == "una_persona", ]
  ecv <- fila("residual_umbral_ecv", u$ola, "umbral anual de una persona (l\u00ednea mensual x 12)",
              12 * ecv1$valor[match(u$ola, ecv1$ola)], u$valor)
  ref <- fila("residual_umbral_ecv_2025", UMBRAL_ECV_REFERENCIA[["ola"]], "umbral de una persona, nota de prensa del INE",
              u$valor[u$ola == UMBRAL_ECV_REFERENCIA[["ola"]]][1], UMBRAL_ECV_REFERENCIA[["valor"]])
  ancho <- tidyr::pivot_wider(lineas[c("linea", "anio", "hogar", "valor")], names_from = "hogar", values_from = "valor")
  escala <- fila("residual_escala", ancho$anio, paste(ancho$linea, "dos adultos / una persona"),
                 abs(ancho$dos_adultos - ancho$una_persona * ESCALA_LINEA[ancho$linea]), 0)
  d <- umbral[!umbral$imputado & !is.na(umbral$valor), ]
  d4 <- d[d$hogar == "dos_adultos_dos_menores", ]
  escala_ine <- fila("residual_escala_ine", d4$ola, "dos adultos y dos menores / una persona (x 2,1)",
                     d4$valor, 2.1 * d$valor[d$hogar == "una_persona"][match(d4$ola, d$ola[d$hogar == "una_persona"])])
  faltan <- vapply(names(ANIOS_LINEA), function(l) {
    con <- lineas$anio[lineas$linea == l & !is.na(lineas$valor)]
    length(setdiff(ANIOS_LINEA[[l]], con))
  }, numeric(1))
  serie <- fila("residual_serie", NA, paste("a\u00f1os sin l\u00ednea:", names(ANIOS_LINEA)), faltan, 0)
  dplyr::bind_rows(pnc, faltan_xml, publicada, ecv, ref, escala, escala_ine, serie)
}

# datos/lineas_residual.json para la web: por linea, { anios: { "2024": { una_persona, dos_adultos,
# tipo, ola } } }, los limites de los tramos (inventario/supuestos.csv) y las fuentes.
exportar_web_lineas_residual <- function(lineas, dir_web = "web", limites = supuesto("limites_residual")) {
  ruta <- file.path(dir_web, "datos", "lineas_residual.json")
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  porLinea <- function(l) {
    x <- lineas[lineas$linea == l, ]
    anios <- sort(unique(x$anio))
    stats::setNames(lapply(anios, function(a) {
      f <- x[x$anio == a, ]
      fila <- list(una_persona = f$valor[f$hogar == "una_persona"], dos_adultos = f$valor[f$hogar == "dos_adultos"], tipo = f$tipo[1])
      if (!is.na(f$ola[1])) fila$ola <- f$ola[1]
      fila
    }), anios)
  }
  j <- list(
    fuentes = list(imv = "boe_imv", ecv = "ine_ecv_umbral"),
    unidad = "euros al mes",
    limites = limites,
    imv = list(escala = ESCALA_LINEA[["imv"]], anios = porLinea("imv")),
    ecv = list(escala = ESCALA_LINEA[["ecv"]], tabla = TABLA_ECV_UMBRAL, anios = porLinea("ecv"))
  )
  texto <- jsonlite::toJSON(j, auto_unbox = TRUE, digits = NA, pretty = TRUE)
  con <- file(ruta, open = "wb")   # LF tambien en Windows
  on.exit(close(con))
  writeLines(texto, con, useBytes = TRUE)
  ruta
}

# web_residual (bloqueo): ida y vuelta del fichero de la web frente a las lineas.
comprobar_web_lineas_residual <- function(lineas, ruta) {
  j <- jsonlite::fromJSON(ruta, simplifyVector = FALSE)
  leidas <- dplyr::bind_rows(lapply(c("imv", "ecv"), function(l) {
    a <- j[[l]]$anios
    dplyr::bind_rows(lapply(names(a), function(clave) {
      f <- a[[clave]]
      tibble::tibble(linea = l, anio = as.integer(clave), hogar = HOGARES_LINEA,
                     v = c(as.numeric(f$una_persona), as.numeric(f$dos_adultos)),
                     t = f$tipo, o = if (is.null(f$ola)) NA_integer_ else as.integer(f$ola))
    }))
  }))
  c <- dplyr::full_join(lineas, leidas, by = c("linea", "anio", "hogar"))
  distintas <- sum(is.na(c$v) | is.na(c$valor) | abs(c$v - c$valor) > 1e-9 | c$t != c$tipo |
                     !((is.na(c$o) & is.na(c$ola)) | (!is.na(c$o) & !is.na(c$ola) & c$o == c$ola)))
  limites <- !isTRUE(all.equal(as.numeric(unlist(j$limites)), supuesto("limites_residual")))
  tibble::tibble(id = "web_residual", detalle = sprintf("cifras distintas de las l\u00edneas (%d) y l\u00edmites", nrow(c)),
                 calculado = distintas + limites, referencia = 0)
}

# --- Muestra: R y la pagina coinciden (residual_muestra) -------------------------------------------
# Tramo de la regla residual (tramoResidual() de web/js/residual.js): 0 por encima de 1,25 x la linea,
# 1 de la linea a 1,25 x la linea, 2 por debajo.
tramo_residual <- function(residual, linea, limites = supuesto("limites_residual")) {
  ifelse(is.na(residual) | is.na(linea), NA_integer_,
         ifelse(residual < linea * limites[1], 2L, ifelse(residual <= linea * limites[2], 1L, 0L)))
}

# Otros gastos de vivienda de un territorio en la ola del ano (otrosGastosEn() de web/js/sueldo.js): la
# cifra de su comunidad (las secciones, los municipios y las provincias, la de la comunidad de su
# provincia) o, si no la hay, la de Espana.
otros_gastos_territorio <- function(geo_id, nivel, anio, otros_gastos, territorios) {
  ola <- anio_ecv_para(anio, sort(unique(otros_gastos$anio)))
  g <- otros_gastos[otros_gastos$anio == ola, ]
  prov <- territorios[territorios$nivel == "provincia", ]
  ccaa <- ifelse(nivel == "ccaa", geo_id, ifelse(nivel == "nacional", NA_character_,
                                                 prov$superior[match(substr(geo_id, 1, 2), prov$codigo)]))
  v <- g$valor[g$nivel == "ccaa"][match(ccaa, g$geo_id[g$nivel == "ccaa"])]
  ifelse(is.na(v), g$valor[g$nivel == "nacional"][1], v)
}

# Casos de la muestra de los supuestos (calcular_muestra_supuestos(): los catorce territorios de 2024 x
# las combinaciones de «Tu ficha» y las tres fichas de una persona), con el tipo de hogar, los otros
# gastos de vivienda de su comunidad, el ingreso residual sin y con ellos y, con cada linea del ano, su
# cifra y el tramo de la regla residual.
calcular_muestra_residual <- function(terminos, lineas, otros_gastos, territorios, supuestos = SUPUESTOS_INVENTARIO,
                                      anio = MUESTRA_SUPUESTOS_ANIO) {
  casos <- calcular_muestra_supuestos(terminos, supuestos)
  hogar <- ifelse(casos$ficha == "peon" & casos$segundo %in% TRUE, "dos_adultos", "una_persona")
  # Con la superficie del caso, solo crece la parte ligada a los metros (factor_otros_gastos(); 18-nov-2026)
  otros <- otros_gastos_territorio(casos$geo_id, casos$nivel, anio, otros_gastos, territorios) *
    factor_otros_gastos(casos$superficie, supuestos)
  x <- tibble::tibble(geo_id = casos$geo_id, nivel = casos$nivel, ficha = casos$ficha, eleccion = casos$eleccion,
                      umbral = casos$umbral, pagas = casos$pagas, segundo = casos$segundo, hogar = hogar,
                      ingreso = casos$ingreso, alquiler = casos$alquiler, otros = otros, euros = casos$euros)
  valido <- !is.na(x$ingreso) & x$ingreso > 0 & !is.na(x$alquiler)
  x$residual <- ifelse(valido, x$ingreso - x$alquiler, NA_real_)
  x$residual_gastos <- ifelse(valido, x$ingreso - x$alquiler - x$otros, NA_real_)
  for (l in c("imv", "ecv")) {
    la <- lineas[lineas$linea == l & lineas$anio == anio, ]
    x[[paste0("linea_", l)]] <- la$valor[match(x$hogar, la$hogar)]
    x[[paste0("tramo_", l)]] <- tramo_residual(x$residual, x[[paste0("linea_", l)]], supuesto("limites_residual", supuestos))
    x[[paste0("tramo_", l, "_gastos")]] <- tramo_residual(x$residual_gastos, x[[paste0("linea_", l)]], supuesto("limites_residual", supuestos))
  }
  # Remates de la web: sueldo necesario con la linea (indicador 21, segunda cifra de la ficha;
  # sueldoConLinea() de residual.js): alquiler mensual mediano del territorio + la linea de una persona
  # del ano y, con los otros gastos de vivienda, + los de su comunidad. No depende de la ficha.
  x$alquiler_mes <- terminos$alquiler_mes[match(paste(x$geo_id, x$nivel), paste(terminos$geo_id, terminos$nivel))]
  for (l in c("imv", "ecv")) {
    una <- lineas$valor[lineas$linea == l & lineas$anio == anio & lineas$hogar == "una_persona"]
    x[[paste0("sueldo_linea_", l)]] <- x$alquiler_mes + una
    x[[paste0("sueldo_linea_", l, "_gastos")]] <- x$alquiler_mes + x$otros + una
  }
  x
}

# Remates de la web: la cuenta de la portada con la linea (cuentaLinea() de web/js/portada.js): con unos
# ingresos netos en 12 pagas, en cuantas secciones con el alquiler por m2 y el alquiler mensual mediano
# de la vivienda colectiva del ano (como los recibe la web) lo que queda tras pagar el alquiler mensual
# no baja de la linea de una persona (encima_imv, encima_ecv). Ingresos: el sueldo inventado de la
# muestra y el de la tartera del ano (el salario minimo neto).
calcular_cuenta_portada_residual <- function(larga_serpavi, terminos, lineas, anio = MUESTRA_SUPUESTOS_ANIO,
                                             netos = c(MUESTRA_SUPUESTOS_PEON$neto, terminos$ingreso_tartera[1])) {
  sc <- function(ind) {
    x <- alquiler_vc(larga_serpavi, ind)
    x[x$nivel == "sc" & x$anio == anio & !is.na(x$valor), c("geo_id", "valor")]
  }
  ambos <- dplyr::inner_join(sc("alquiler_m2"), sc("alquiler_mes"), by = "geo_id", suffix = c("_m2", "_mes"))
  una <- function(l) lineas$valor[lineas$linea == l & lineas$anio == anio & lineas$hogar == "una_persona"]
  dplyr::bind_rows(lapply(netos, function(neto) {
    resto <- neto - ambos$valor_mes
    tibble::tibble(neto = neto, con = length(resto), encima_imv = sum(resto >= una("imv")), encima_ecv = sum(resto >= una("ecv")))
  }))
}

# pruebas/datos/residual_muestra.json, que comprueban test-linea-residual.R y pruebas/web/residual.test.mjs
# (se escribe a mano tras cambiar la muestra, las lineas o los supuestos:
# escribir_muestra_residual(tar_read(muestra_residual), tar_read(lineas_residual))).
escribir_muestra_residual <- function(muestra, lineas, portada = NULL, anio = MUESTRA_SUPUESTOS_ANIO,
                                      ruta = file.path("pruebas", "datos", "residual_muestra.json")) {
  lin <- lapply(c(imv = "imv", ecv = "ecv"), function(l) {
    f <- lineas[lineas$linea == l & lineas$anio == anio, ]
    fila <- list(una_persona = f$valor[f$hogar == "una_persona"], dos_adultos = f$valor[f$hogar == "dos_adultos"], tipo = f$tipo[1])
    if (!is.na(f$ola[1])) fila$ola <- f$ola[1]
    list(anios = stats::setNames(list(fila), anio))
  })
  j <- list(
    nota = paste("Muestra de la l\u00ednea de ingreso residual (tarea 65): la de los supuestos de", anio,
                 "con el tipo de hogar, los otros gastos de vivienda de la comunidad y las dos l\u00edneas del a\u00f1o."),
    anio = anio, peon = MUESTRA_SUPUESTOS_PEON, lineas = lin, casos = muestra
  )
  if (!is.null(portada)) j$portada <- portada   # calcular_cuenta_portada_residual()
  texto <- jsonlite::toJSON(j, auto_unbox = TRUE, digits = NA, na = "null", pretty = TRUE)
  con <- file(ruta, open = "wb")
  on.exit(close(con))
  writeLines(texto, con, useBytes = TRUE)
  ruta
}

# residual_muestra (bloqueo): el fichero de la muestra sigue al dia (los mismos casos, residuos, lineas,
# tramos y sueldos necesarios con la linea que la muestra del pipeline, y la misma cuenta de la portada
# con la linea), y R da tramo a todos los casos con ingreso y alquiler;
# residual_coherencia (alerta): el ingreso residual con otros gastos cuadra con los euros que quedan
# menos los otros gastos (redondeados al euro como los escribe la pagina), a 1,5 euros como mucho.
comprobar_muestra_residual <- function(muestra, ruta, portada = NULL) {
  j <- if (file.exists(ruta)) jsonlite::fromJSON(ruta) else NULL
  cols <- c("residual", "residual_gastos", "linea_imv", "linea_ecv", "tramo_imv", "tramo_ecv", "tramo_imv_gastos", "tramo_ecv_gastos",
            "sueldo_linea_imv", "sueldo_linea_ecv", "sueldo_linea_imv_gastos", "sueldo_linea_ecv_gastos")
  al_dia <- !is.null(j) && nrow(j$casos) == nrow(muestra) &&
    all(vapply(cols, function(k) isTRUE(all.equal(as.numeric(j$casos[[k]]), as.numeric(muestra[[k]]))), logical(1))) &&
    identical(as.character(j$casos$hogar), as.character(muestra$hogar)) &&
    (is.null(portada) || (!is.null(j$portada) && isTRUE(all.equal(as.data.frame(j$portada), as.data.frame(portada), check.attributes = FALSE))))
  sin_tramo <- sum(!is.na(muestra$residual) & (is.na(muestra$tramo_imv) | is.na(muestra$tramo_ecv)))
  dif <- abs(muestra$residual_gastos - (muestra$euros - redondear_como_js(muestra$otros)))
  dplyr::bind_rows(
    tibble::tibble(id = "residual_muestra", detalle = c("pruebas/datos/residual_muestra.json distinto de la muestra (0 = al d\u00eda)",
                                                       sprintf("casos sin tramo de %d", nrow(muestra))),
                   calculado = c(if (al_dia) 0 else 1, sin_tramo), referencia = 0),
    tibble::tibble(id = "residual_coherencia", detalle = sprintf("casos a m\u00e1s de 1,5 \u20ac de %d", sum(!is.na(dif))),
                   calculado = sum(dif > 1.5, na.rm = TRUE), referencia = 0)
  )
}

# --- Navegador (comprobar_web_navegador(), R/web_navegador.R) --------------------------------------
# navegador_residual: con «Lo que queda» (?regla=residual), la ficha de una seccion da la frase con la
# linea del ano y del hogar (la del IMV por defecto; la de la ECV con ?linea=ecv, en ingles) y el tramo
# que sale de sus terminos (alquiler e ingreso, como los escribe la ficha); la leyenda, los tres tramos
# residuales; con la regla apagada, los del porcentaje y la frase de la linea igual; con la llave, «no
# se aplica», y con «Lo que queda» elegido, los tramos de la proporcion con una nota, y al volver a otra
# ficha, otra vez «Lo que queda» (decisiones del 17-nov-2026); y a 375 px, con los selectores a la
# vista, el mapa no desborda.
comprobar_residual_navegador <- function(b, evaluar, url, espera = 60, seccion = "2807901001", anio = 2024L) {
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_residual", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  leer <- "JSON.stringify({ frase: document.querySelector('#ficha .ficha-residual')?.textContent ?? null,
    tramo: document.querySelector('#ficha .ficha-tramo')?.textContent ?? null,
    terminos: [...document.querySelectorAll('#ficha .ficha-estado')].map((x) => x.textContent)[0] ?? null,
    leyenda: [...document.querySelectorAll('#leyenda .leyenda-llega li')].map((x) => x.textContent.trim()),
    regla: [...document.querySelectorAll('#sueldo-regla button')].map((x) => x.getAttribute('aria-pressed')),
    visible: !document.getElementById('sueldo-regla').hidden,
    ancho: [document.documentElement.scrollWidth, document.documentElement.clientWidth] })"
  numero <- function(x, idioma) {
    x <- gsub("[^0-9.,]", "", x)
    as.numeric(if (idioma == "es") sub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE) else gsub(",", "", x, fixed = TRUE))
  }
  abrir <- function(consulta, leer_con = leer) {
    b$Page$navigate(sprintf("%smapa.html%s", url, consulta))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-tramo') && document.getElementById('mapa-cargando')?.hidden !== false", espera)
    if (!ok) return(NULL)
    Sys.sleep(1)
    jsonlite::fromJSON(evaluar(leer_con), simplifyVector = TRUE)
  }
  lineas <- tryCatch(jsonlite::fromJSON(evaluar("fetch('datos/lineas_residual.json').then((r) => r.text())")), error = function(e) NULL)
  dic <- lapply(c(es = "es", en = "en"), function(i) jsonlite::fromJSON(evaluar(sprintf("fetch('i18n/%s.json').then((r) => r.text())", i))))
  if (is.null(lineas)) return(list(fila("datos/lineas_residual.json no llega", TRUE)))
  filas <- list()
  for (caso in list(list(idioma = "es", linea = "imv", ficha = "tartera"), list(idioma = "en", linea = "ecv", ficha = "mochila"))) {
    i <- caso$idioma
    consulta <- sprintf("?idioma=%s&ficha=%s&anio=%d&regla=residual%s&seccion=%s", i, caso$ficha, anio,
                        if (caso$linea == "ecv") "&linea=ecv" else "", seccion)
    p <- abrir(consulta)
    tramos <- unlist(dic[[i]]$interfaz$residual[c("tramo_1", "tramo_2", "tramo_3")])
    if (is.null(p) || is.null(p$frase) || is.null(p$terminos)) {
      filas[[length(filas) + 1L]] <- fila(paste(consulta, ": sin ficha o sin frase"), TRUE)
      next
    }
    n <- lineas[[caso$linea]]$anios[[as.character(anio)]]$una_persona
    cifra <- if (i == "es") formatC(n, format = "f", digits = 2, big.mark = ".", decimal.mark = ",") else formatC(n, format = "f", digits = 2, big.mark = ",")
    t <- regmatches(p$terminos, gregexpr("[0-9][0-9.,]*", p$terminos))[[1]]
    residual <- numero(t[2], i) - numero(t[1], i)
    esperado <- tramo_residual(residual, n)
    lejos <- abs(residual - n) > 2 && abs(residual - 1.25 * n) > 2
    mal <- !grepl(cifra, p$frase, fixed = TRUE) || !identical(p$leyenda, unname(tramos)) || !isTRUE(p$visible) ||
      !identical(p$regla, c("false", "true")) || (lejos && !identical(p$tramo, unname(tramos[esperado + 1L])))
    filas[[length(filas) + 1L]] <- fila(sprintf("%s: %s (%s)", consulta, p$tramo, p$frase), mal)
  }
  # Regla apagada: tramos del porcentaje y la frase de la linea, igual
  p <- abrir(sprintf("?ficha=tartera&anio=%d&seccion=%s", anio, seccion))
  llega <- unlist(dic$es$interfaz$leyenda[c("llega_1", "llega_2", "llega_3")])
  filas[[length(filas) + 1L]] <- fila("regla apagada: tramos del porcentaje y la frase de la l\u00ednea",
                                      is.null(p) || !identical(p$leyenda, unname(llega)) || is.null(p$frase) || !identical(p$regla, c("true", "false")))
  # La llave (tarea 65, decisiones del 17-nov-2026): \u00abno se aplica\u00bb en la ficha; con \u00abLo que queda\u00bb elegido,
  # el mapa y la leyenda van con la proporcion y una nota de la leyenda lo dice, y la eleccion se queda
  # (boton pulsado y regla=residual en la direccion); al volver a la tartera, \u00abLo que queda\u00bb otra vez
  leer_llave <- sub("JSON.stringify({", "JSON.stringify({ aviso: document.querySelector('#leyenda .leyenda-aviso-regla')?.textContent ?? null,
    busqueda: location.search,", leer, fixed = TRUE)
  p <- abrir(sprintf("?ficha=llave&anio=%d&regla=residual&seccion=%s", anio, seccion), leer_llave)
  trozos <- strsplit(dic$es$interfaz$residual$llave_proporcion, "{umbral}", fixed = TRUE)[[1]]
  aviso_bien <- !is.null(p$aviso) && all(vapply(trozos, function(x) grepl(x, p$aviso, fixed = TRUE), TRUE))
  mal <- is.null(p) || !identical(p$frase, dic$es$interfaz$residual$no_aplica) || !identical(p$leyenda, unname(llega)) ||
    !aviso_bien || !identical(p$regla, c("false", "true")) || !grepl("regla=residual", p$busqueda, fixed = TRUE)
  filas[[length(filas) + 1L]] <- fila(sprintf("la llave con \u00abLo que queda\u00bb: \u00abno se aplica\u00bb, tramos de la proporci\u00f3n y la nota (%s)",
                                              if (is.null(p$aviso)) "sin nota" else p$aviso), mal)
  vuelta <- NULL
  if (!is.null(p)) {
    evaluar("(() => { document.querySelector('button.ficha-boton-tartera')?.click(); return true; })()")
    residuales <- jsonlite::toJSON(paste(unname(unlist(dic$es$interfaz$residual[c("tramo_1", "tramo_2", "tramo_3")])), collapse = "|"), auto_unbox = TRUE)
    ok <- esperar_navegador(evaluar, sprintf("location.search.includes('ficha=tartera') && [...document.querySelectorAll('#leyenda .leyenda-llega li')].map((x) => x.textContent.trim()).join('|') === %s", residuales), espera)
    if (ok) { Sys.sleep(1); vuelta <- jsonlite::fromJSON(evaluar(leer_llave), simplifyVector = TRUE) }
  }
  filas[[length(filas) + 1L]] <- fila("de la llave a la tartera: vuelve \u00abLo que queda\u00bb (tramos residuales, sin la nota)",
                                      is.null(vuelta) || !is.null(vuelta$aviso) || !grepl("regla=residual", vuelta$busqueda, fixed = TRUE) ||
                                        !identical(vuelta$regla, c("false", "true")) || identical(vuelta$frase, dic$es$interfaz$residual$no_aplica))
  # 375 px con la regla encendida
  b$Emulation$setDeviceMetricsOverride(width = 375, height = 812, deviceScaleFactor = 1, mobile = TRUE)
  p <- abrir(sprintf("?ficha=tartera&anio=%d&regla=residual&seccion=%s", anio, seccion))
  b$Emulation$setDeviceMetricsOverride(width = 1280, height = 900, deviceScaleFactor = 1, mobile = FALSE)
  filas[[length(filas) + 1L]] <- fila("375 px con la regla residual: sin desbordar", is.null(p) || p$ancho[1] > p$ancho[2])
  c(filas, comprobar_remates_residual_navegador(b, evaluar, url, lineas, espera, seccion, anio))
}

# Remates de la web (tarea 65), en el navegador, frente a las cifras de R (pruebas/datos/residual_muestra.json):
#   - sueldo necesario: la segunda cifra con la linea (IMV en castellano; ECV y otros gastos en ingles) es
#     la de R para la seccion, y el selector Linea se ve (sin la Regla);
#   - evolucion de la ficha: la linea de cada ano al lado de lo que queda (IMV del ano y PNC antes de 2020);
#   - CSV de te llega: las columnas de la linea, con su cifra, y lo que queda menos la linea con la tartera
#     (con Tu ficha, sin esa columna);
#   - portada: la cuenta con la linea da las secciones de R con 1.500 euros;
#   - 375 px con el sueldo necesario y la segunda cifra: sin desbordar.
comprobar_remates_residual_navegador <- function(b, evaluar, url, lineas, espera = 60, seccion = "2807901001", anio = 2024L,
                                                 ruta_muestra = file.path("pruebas", "datos", "residual_muestra.json")) {
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_residual", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  # Desde la raiz del proyecto o desde pruebas/testthat (test-navegador.R)
  if (!file.exists(ruta_muestra) && file.exists(file.path("..", "datos", basename(ruta_muestra)))) {
    ruta_muestra <- file.path("..", "datos", basename(ruta_muestra))
  }
  if (!file.exists(ruta_muestra)) return(list(fila(paste(ruta_muestra, "no existe"), TRUE)))
  mu <- jsonlite::fromJSON(ruta_muestra)
  caso <- mu$casos[mu$casos$geo_id == seccion & mu$casos$nivel == "sc", ][1, ]
  euros <- function(x, idioma) formatC(floor(x + 0.5), format = "d", big.mark = if (idioma == "es") "." else ",",
                                       decimal.mark = if (idioma == "es") "," else ".")
  abrir <- function(consulta, condicion, leer) {
    b$Page$navigate(sprintf("%s%s", url, consulta))
    ok <- esperar_navegador(evaluar, condicion, espera)
    if (!ok) return(NULL)
    Sys.sleep(1)
    jsonlite::fromJSON(evaluar(leer), simplifyVector = TRUE)
  }
  filas <- list()
  # Sueldo necesario con la linea
  leer_sueldo <- "JSON.stringify({ texto: document.querySelector('#ficha .ficha-sueldo-linea')?.textContent ?? null,
    linea: !document.getElementById('sueldo-linea').hidden, regla: !document.getElementById('sueldo-regla').hidden,
    ancho: [document.documentElement.scrollWidth, document.documentElement.clientWidth] })"
  listo_sueldo <- "document.querySelector('#ficha .ficha-sueldo-linea') && document.getElementById('mapa-cargando')?.hidden !== false"
  for (k in list(list(idioma = "es", extra = "", col = "sueldo_linea_imv"),
                 list(idioma = "en", extra = "&linea=ecv&gastos=1", col = "sueldo_linea_ecv_gastos"))) {
    consulta <- sprintf("mapa.html?idioma=%s&anio=%d%s&seccion=%s", k$idioma, anio, k$extra, seccion)
    p <- abrir(consulta, listo_sueldo, leer_sueldo)
    esperado <- euros(caso[[k$col]], k$idioma)
    mal <- is.null(p) || is.null(p$texto) || !grepl(esperado, p$texto, fixed = TRUE) || !isTRUE(p$linea) || isTRUE(p$regla)
    filas[[length(filas) + 1L]] <- fila(sprintf("sueldo necesario con la línea, %s (R: %s): %s", consulta, esperado,
                                                if (is.null(p$texto)) "sin cifra" else p$texto), mal)
  }
  # Evolucion de la ficha: la linea de cada ano
  leer_evol <- "JSON.stringify([...document.querySelectorAll('#ficha .ficha-tabla tbody tr')].map((tr) => [tr.querySelector('th')?.textContent ?? '', tr.querySelector('.ficha-tabla-linea')?.textContent ?? '']))"
  p <- abrir(sprintf("mapa.html?ficha=tartera&anio=%d&seccion=%s", anio, seccion), "document.querySelector('#ficha .ficha-tabla-linea')", leer_evol)
  imv <- lineas$imv$anios
  celda <- function(a) {
    x <- imv[[as.character(a)]]
    sprintf("%s %s €", if (identical(x$tipo, "pnc")) "PNC" else "IMV", euros(x$una_persona, "es"))
  }
  bien <- !is.null(p) && length(p) > 0 && all(vapply(seq_len(nrow(p)), function(i) {
    a <- suppressWarnings(as.integer(p[i, 1]))
    is.na(a) || is.null(imv[[as.character(a)]]) || identical(gsub(" ", " ", p[i, 2]), celda(a))
  }, TRUE)) && any(grepl("^PNC", p[, 2])) && any(grepl("^IMV", p[, 2]))
  filas[[length(filas) + 1L]] <- fila(sprintf("evolución: línea de cada año (%s)",
                                              if (is.null(p) || !length(p)) "sin tabla" else paste(p[, 1], p[, 2], collapse = " | ")), !bien)
  # CSV de te llega con la linea
  csv_js <- "(async () => { let blob = null; const o = URL.createObjectURL; URL.createObjectURL = (x) => { blob = x; return o.call(URL, x); };
    document.getElementById('exportar-csv').click();
    for (let i = 0; i < 100 && !blob; i++) await new Promise((r) => setTimeout(r, 200));
    URL.createObjectURL = o; return blob ? await blob.text() : null; })()"
  for (k in list(list(idioma = "es", ficha = "tartera", col = "queda_menos_linea", euros = "linea_residual_euros_mes"),
                 list(idioma = "en", ficha = "peon", col = NA, euros = "residual_line_eur_month"))) {
    extra <- if (k$ficha == "peon") "#sueldo=1500" else ""
    b$Page$navigate(sprintf("%smapa.html?idioma=%s&ficha=%s&anio=%d&seccion=%s%s", url, k$idioma, k$ficha, anio, seccion, extra))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-tramo') && document.getElementById('mapa-cargando')?.hidden !== false", espera)
    texto <- if (ok) { Sys.sleep(1); evaluar(csv_js) } else NULL
    if (is.null(texto)) {
      filas[[length(filas) + 1L]] <- fila(sprintf("CSV (%s, %s): no sale", k$idioma, k$ficha), TRUE)
      next
    }
    d <- utils::read.csv(text = sub("^﻿", "", texto), check.names = FALSE, encoding = "UTF-8")
    valor <- lineas$imv$anios[[as.character(anio)]]$una_persona
    mal <- !k$euros %in% names(d) || any(abs(d[[k$euros]] - valor) > 1e-9, na.rm = TRUE) ||
      (if (is.na(k$col)) any(c("queda_menos_linea", "left_minus_line") %in% names(d)) else !k$col %in% names(d) || all(is.na(d[[k$col]])))
    filas[[length(filas) + 1L]] <- fila(sprintf("CSV (%s, %s): %d filas, columnas %s", k$idioma, k$ficha, nrow(d),
                                                paste(utils::tail(names(d), 3), collapse = ", ")), mal)
  }
  # Portada: la cuenta con la linea, con 1.500 euros
  pc <- mu$portada
  if (!is.null(pc) && any(pc$neto == 1500)) {
    r <- pc[pc$neto == 1500, ][1, ]
    b$Page$navigate(url)
    esperar_navegador(evaluar, "document.getElementById('portada-dado-nota')?.textContent", espera)
    evaluar("(() => { const e = document.getElementById('portada-neto'); e.value = '1500'; e.dispatchEvent(new Event('input', { bubbles: true })); return true; })()")
    ok <- esperar_navegador(evaluar, "document.querySelector('#portada-cuenta .portada-cuenta-linea')", espera)
    texto <- if (ok) evaluar("document.querySelector('#portada-cuenta .portada-cuenta-linea').textContent") else NULL
    esperado <- c(euros(r$encima_imv, "es"), euros(r$con, "es"))
    mal <- is.null(texto) || !all(vapply(esperado, function(e) grepl(e, texto, fixed = TRUE), TRUE))
    filas[[length(filas) + 1L]] <- fila(sprintf("portada: cuenta con la línea, 1.500 € (R: %s de %s): %s", esperado[1], esperado[2],
                                                if (is.null(texto)) "sin frase" else texto), mal)
  } else {
    filas[[length(filas) + 1L]] <- fila("portada: la muestra no trae la cuenta con 1.500 €", TRUE)
  }
  # 375 px con el sueldo necesario y la segunda cifra
  b$Emulation$setDeviceMetricsOverride(width = 375, height = 812, deviceScaleFactor = 1, mobile = TRUE)
  p <- abrir(sprintf("mapa.html?anio=%d&seccion=%s", anio, seccion), listo_sueldo, leer_sueldo)
  b$Emulation$setDeviceMetricsOverride(width = 1280, height = 900, deviceScaleFactor = 1, mobile = FALSE)
  filas[[length(filas) + 1L]] <- fila("375 px con el sueldo necesario y la línea: sin desbordar", is.null(p) || p$ancho[1] > p$ancho[2])
  filas
}
