# Rederivación a mano de cifras de F4 a F6 (backlog, tarea 59).
#
# Cada cifra se vuelve a calcular desde el fichero de la fuente en datos/brutos/, con código propio:
# este guion no carga nada de R/ ni usa objetivos de targets para la cifra a mano. Solo después se
# compara con lo que publica el atlas (tabla larga, histórico o datos de la web; el indicador 11,
# mientras no esté en la tabla larga, con el objetivo larga_registradores). Si una diferencia pasa de la
# tolerancia, la fila sale como «no coincide» y hay que explicarla en docs/rederivacion.md.
#
# Uso, desde la raíz del proyecto:
#   Rscript pruebas/rederivar/rederivar.R
# Escribe pruebas/rederivar/resultado.csv (cifras públicas: nada de portales) y lo imprime.
# Las cinco cifras de «Entrar» van aparte, en pruebas/rederivar/rederivar_entrar.R.

suppressPackageStartupMessages({
  library(arrow)
  library(readxl)
  library(jsonlite)
  library(xml2)
})

BRUTOS <- file.path("datos", "brutos")
if (!dir.exists(BRUTOS)) stop("Ejecutar desde la raíz del proyecto (falta datos/brutos/)", call. = FALSE)

# ---- Utilidades propias -------------------------------------------------------------------------

# Número español («1.234,5»), «..» o vacío -> NA.
num_es <- function(x) {
  x <- trimws(x)
  x[x %in% c("", "..", ".", "-", "_")] <- NA
  as.numeric(gsub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE))
}

# Una tabla de INEbase en CSV («;», con BOM), como data.frame de texto.
leer_jaxi <- function(ruta) {
  l <- readLines(ruta, encoding = "UTF-8", warn = FALSE)
  l[1] <- sub("^﻿", "", l[1])
  partes <- strsplit(l, ";", fixed = TRUE)
  cab <- partes[[1]]
  m <- do.call(rbind, lapply(partes[-1], function(p) c(p, rep("", length(cab) - length(p)))[seq_along(cab)]))
  d <- as.data.frame(m, stringsAsFactors = FALSE)
  names(d) <- make.unique(cab)
  d
}

# Redondeo a d decimales con los empates hacia arriba sobre la cifra decimal (no al par).
redondear <- function(x, d = 1) {
  f <- 10^d
  sign(x) * floor(abs(x) * f + 0.5 + 1e-9) / f
}

# Celda de Excel leída como texto («1972.0999999999999») -> número con un decimal.
celda <- function(x) {
  v <- suppressWarnings(as.numeric(x))
  redondear(v, 1)
}

LARGA <- arrow::read_parquet(file.path("datos", "intermedios", "tabla_larga.parquet"))
HIST <- arrow::read_parquet(file.path("datos", "intermedios", "historico.parquet"))

atlas <- function(ind, nivel, geo, anio, corte = "total", grupo = "total") {
  v <- LARGA$valor[LARGA$indicador == ind & LARGA$nivel == nivel & LARGA$geo_id == geo &
                     LARGA$anio == anio & LARGA$corte == corte & LARGA$grupo == grupo]
  if (length(v) == 1) v else NA_real_
}

resultado <- list()
anotar <- function(id, cifra, fuente, fichero, a_mano, atlas, tolerancia, donde_atlas, nota = "") {
  dif <- a_mano - atlas
  resultado[[length(resultado) + 1]] <<- data.frame(
    id = id, cifra = cifra, fuente = fuente, fichero = fichero,
    a_mano = signif(a_mano, 10), atlas = signif(atlas, 10), diferencia = signif(dif, 4),
    tolerancia = tolerancia,
    coincide = if (is.na(atlas)) "sin cifra del atlas" else if (abs(dif) <= tolerancia) "coincide" else "no coincide",
    donde_atlas = donde_atlas, nota = nota, stringsAsFactors = FALSE)
}

# ---- 10 · Variación anual del alquiler (IPVA): índice del año / índice del anterior ---------------

ipva_var <- function(tabla, filtro, anio) {
  d <- leer_jaxi(file.path(BRUTOS, "ine_ipva", paste0(tabla, ".csv")))
  d <- d[filtro(d) & d[["Tipo de dato"]] == "Índice", ]
  i1 <- num_es(d$Total[d$Periodo == anio])
  i0 <- num_es(d$Total[d$Periodo == anio - 1])
  stopifnot(length(i1) == 1, length(i0) == 1)
  100 * (i1 / i0 - 1)
}

v <- ipva_var("59056", function(d) d[[1]] == "Total Nacional" & d[[2]] == "" & d[[3]] == "Total", 2024)
anotar("10a", "Variación anual del alquiler, España, 2024 (%)", "INE, IPVA", "ine_ipva/59056.csv",
       redondear(v, 1), atlas("var_alquiler", "nacional", "00", 2024), 0.05, "tabla larga",
       "Índice 2024 / índice 2023, a un decimal; el atlas guarda la variación publicada")

v <- ipva_var("59060", function(d) d[[1]] == "28079 Madrid", 2024)
anotar("10b", "Variación anual del alquiler, Madrid (municipio), 2024 (%)", "INE, IPVA", "ine_ipva/59060.csv",
       redondear(v, 1), atlas("var_alquiler", "municipio", "28079", 2024), 0.05, "tabla larga",
       "Índice 2024 / índice 2023, a un decimal")

v <- ipva_var("59005", function(d) d[[2]] == "46 Valencia/València" & d[[3]] == "Nuevo contrato", 2024)
anotar("10c", "Variación anual del alquiler, contratos nuevos, Valencia/València (provincia), 2024 (%)",
       "INE, IPVA por antigüedad del contrato", "ine_ipva/59005.csv",
       redondear(v, 1), atlas("var_alquiler", "provincia", "46", 2024, "contrato", "nuevo"), 0.05, "tabla larga",
       "Índice 2024 / índice 2023 del contrato nuevo, a un decimal")

# ---- 11 · Precio de compraventa por m² (Registradores): cuarto trimestre = año natural ------------

reg <- read.csv2(file.path(BRUTOS, "registradores", "RP_ComprvResid_2007-2t2026.csv"), colClasses = "character",
                 encoding = "UTF-8", check.names = FALSE)
pm2 <- function(geo, cod_prv, anio) {
  f <- reg[reg$ano == anio & reg$trim == "4" & reg$geo == geo & reg[["cod-prv"]] == cod_prv, ]
  stopifnot(nrow(f) == 1)
  num_es(f[["viv-pm2"]])
}
# Recién conectado (tarea 46): si la tabla larga aún no lo trae, la cifra del atlas es la del objetivo
# larga_registradores del almacén (solo lectura), que es lo que entrará en ella.
atlas_11 <- function(nivel, geo, anio) {
  v <- atlas("precio_compra_m2", nivel, geo, anio)
  if (!is.na(v)) return(list(valor = v, donde = "tabla larga"))
  if (requireNamespace("targets", quietly = TRUE) && isTRUE(targets::tar_exist_objects("larga_registradores"))) {
    x <- targets::tar_read(larga_registradores)
    v <- x$valor[x$nivel == nivel & x$geo_id == geo & x$anio == anio & x$corte == "total"]
    if (length(v) == 1) return(list(valor = v, donde = "objetivo larga_registradores (aún no en la tabla larga)"))
  }
  list(valor = NA_real_, donde = "tabla larga")
}
a <- atlas_11("nacional", "00", 2025)
anotar("11a", "Precio de compraventa de vivienda por m², España, 2025 (€/m²)", "Colegio de Registradores",
       "registradores/RP_ComprvResid_2007-2t2026.csv", pm2("Nacional", "99", 2025), a$valor, 0.005, a$donde,
       "Fila del cuarto trimestre (acumula los cuatro últimos)")
a <- atlas_11("provincia", "28", 2024)
anotar("11b", "Precio de compraventa de vivienda por m², Madrid (provincia), 2024 (€/m²)", "Colegio de Registradores",
       "registradores/RP_ComprvResid_2007-2t2026.csv", pm2("Provincia", "28", 2024), a$valor, 0.005, a$donde,
       "Fila del cuarto trimestre")

# ---- 12 · Valor tasado por m² (MIVAU): media de los cuatro trimestres ponderada por tasaciones ---

# Tablas territoriales (35101000 valor, 35103000 tasaciones): hoja del cuatrienio, fila del territorio,
# las cuatro columnas del bloque «Año AAAA».
trimestres_territorio <- function(fichero, territorio, anio) {
  ruta <- file.path(BRUTOS, "mivau_valor_tasado", fichero)
  hoja <- grep(as.character(anio), excel_sheets(ruta), value = TRUE)[1]
  d <- suppressMessages(read_excel(ruta, sheet = hoja, col_names = FALSE, col_types = "text"))
  fila_anio <- which(apply(d, 1, function(r) any(r %in% paste("Año", anio))))[1]
  col <- which(unlist(d[fila_anio, ]) %in% paste("Año", anio))
  fila <- which(trimws(d[[1]]) == territorio)[1]
  celda(unlist(d[fila, col:(col + 3)]))
}
vt <- trimestres_territorio("35101000.xls", "TOTAL NACIONAL", 2024)
nt <- trimestres_territorio("35103000.xls", "TOTAL NACIONAL", 2024)
vt_espana <- sum(vt * nt) / sum(nt)
anotar("12a", "Valor tasado de la vivienda libre, España, 2024 (€/m²)", "MIVAU", "mivau_valor_tasado/35101000.xls y 35103000.xls",
       vt_espana, atlas("valor_tasado_m2", "nacional", "00", 2024), 0.05, "tabla larga",
       "Media de los cuatro trimestres ponderada por el número de tasaciones")

# Municipios (35103500): una hoja por trimestre; columna «Total» primera (valor) y última (tasaciones).
trimestre_municipio <- function(provincia, municipio, hoja) {
  d <- suppressMessages(read_excel(file.path(BRUTOS, "mivau_valor_tasado", "35103500.xls"), sheet = hoja,
                                   col_names = FALSE, col_types = "text"))
  cab <- which(apply(d, 1, function(r) any(r %in% "Municipio")))[1]
  totales <- which(apply(d[cab:(cab + 2), ], 2, function(r) any(r %in% "Total")))
  prov <- d[[2]]
  for (i in seq_along(prov)) if (is.na(prov[i]) && i > 1) prov[i] <- prov[i - 1]
  f <- which(prov == provincia & d[[3]] == municipio)
  stopifnot(length(f) == 1)
  c(valor = celda(d[[min(totales)]][f]), tasaciones = suppressWarnings(as.numeric(d[[max(totales)]][f])))
}
mad <- sapply(paste0("T", 1:4, "A2024"), function(h) trimestre_municipio("Madrid", "Madrid", h))
vt_madrid <- sum(mad["valor", ] * mad["tasaciones", ]) / sum(mad["tasaciones", ])
anotar("12b", "Valor tasado de la vivienda libre, Madrid (municipio), 2024 (€/m²)", "MIVAU", "mivau_valor_tasado/35103500.xls",
       vt_madrid, atlas("valor_tasado_m2", "municipio", "28079", 2024), 0.05, "tabla larga",
       "Hojas T1A2024 a T4A2024, ponderadas por tasaciones")

# ---- 16 · Años de salario para comprar: valor tasado × 80 / salario medio de la provincia ---------

# AEAT: página de la tabla provincial con «Tramos de Edad: Total»; salario medio = salarios / asalariados.
aeat_salario <- function(anio, territorio) {
  dir <- file.path(BRUTOS, "aeat_mercado", anio)
  paginas <- list.files(dir, pattern = "^jrubik.*\\.html$", full.names = TRUE)
  texto <- lapply(paginas, function(p) {
    t <- paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = " ")
    t <- gsub("<!--.*?-->", " ", t, perl = TRUE)
    gsub("[[:space:]]+", " ", gsub("<[^>]*>", "|", t))
  })
  es <- vapply(texto, function(t) grepl("salarios por provincia, edad y sexo", t, fixed = TRUE) &&
                 grepl("Tramos de Edad: Total", t, fixed = TRUE), logical(1))
  t <- texto[es][[which.max(file.mtime(paginas[es]))]]
  celdas <- trimws(strsplit(t, "|", fixed = TRUE)[[1]])
  celdas <- celdas[celdas != ""]
  i <- which(celdas == territorio)
  i <- i[grepl("^[0-9.]+$", celdas[i + 1])][1]
  c(asalariados = num_es(celdas[i + 1]), salarios = num_es(celdas[i + 3]), publicado = num_es(celdas[i + 4]))
}
sal <- aeat_salario(2024, "Madrid, Comunidad de")   # comunidad de una provincia: su fila es la de la provincia
salario_madrid <- round(sal[["salarios"]] / sal[["asalariados"]])   # la AEAT lo publica al euro
stopifnot(salario_madrid == sal[["publicado"]])
anotar("16", "Años de salario para comprar 80 m², Madrid (municipio), 2024 (años)",
       "MIVAU y AEAT", "mivau_valor_tasado/35103500.xls y aeat_mercado/2024",
       redondear(vt_madrid, 1) * 80 / salario_madrid, atlas("anios_salario_compra", "municipio", "28079", 2024),
       0.005, "tabla larga",
       "Valor tasado a un decimal × 80 / salario medio de la provincia (salarios / asalariados, al euro)")

# ---- 17 · Cuota hipotecaria sobre la renta del hogar: cuota del primer año / renta neta media por hogar

bde <- function(tabla) {
  l <- readLines(file.path(BRUTOS, "bde", tabla), encoding = "latin1", warn = FALSE)
  cab <- strsplit(gsub('"', "", l[1]), ",", fixed = TRUE)[[1]]
  filas <- grep('^"[A-Z]{3} [0-9]{4}"', l, value = TRUE)
  m <- do.call(rbind, lapply(strsplit(gsub('"', "", filas), ",", fixed = TRUE), function(p) p[seq_along(cab)]))
  colnames(m) <- cab
  m
}
si15 <- bde("si_1_5.csv")
tipos_2024 <- suppressWarnings(as.numeric(si15[grepl(" 2024$", si15[, 1]), "D_IMVTIPLV"]))
stopifnot(length(tipos_2024) == 12, !anyNA(tipos_2024))
tipo_2024 <- redondear(mean(tipos_2024), 2)

# Renta neta media por hogar del municipio (ADRH, tabla 30824; 400 MB: se leen solo las líneas de Madrid).
renta_hogar <- function(codigo_nombre, anio) {
  con <- file(file.path(BRUTOS, "ine_adrh", "30824.csv"), open = "r", encoding = "UTF-8")
  on.exit(close(con))
  patron <- paste0(codigo_nombre, ";;;Renta neta media por hogar;", anio, ";")
  repeat {
    l <- readLines(con, n = 200000, warn = FALSE)
    if (!length(l)) break
    h <- l[startsWith(l, patron)]
    if (length(h)) return(num_es(sub(".*;", "", h[1])))
  }
  NA_real_
}
renta_madrid <- renta_hogar("28079 Madrid", 2024)
esfuerzo <- function(tipo) {
  capital <- 0.8 * redondear(vt_madrid, 1) * 80
  r <- tipo / 100 / 12
  100 * 12 * capital * r / (1 - (1 + r)^(-25 * 12)) / renta_madrid
}
# La media de 2024 es 3,465 exacta en decimal: a dos decimales, 3,47 con el empate hacia arriba, como
# el pipeline desde el 11-nov-2026 (decisión del autor); sprintf("%.2f") da 3,46 (el binario de 3,465
# queda por debajo). Se anota también la cifra con 3,46, la que daba el atlas antes.
tipo_sprintf <- as.numeric(sprintf("%.2f", mean(tipos_2024)))
anotar("17", "Cuota hipotecaria sobre la renta del hogar, Madrid (municipio), 2024 (% de la renta del hogar)",
       "MIVAU, Banco de España e INE (ADRH)", "35103500.xls, bde/si_1_5.csv y ine_adrh/30824.csv",
       esfuerzo(tipo_2024), atlas("esfuerzo_hipotecario", "municipio", "28079", 2024), 0.005, "tabla larga",
       sprintf(paste("Préstamo del 80 %% de 80 m², 25 años, tipo D_IMVTIPLV medio de 2024 (media exacta %.3f, a dos",
                     "decimales con el empate hacia arriba %.2f %%), renta por hogar %s €; con el tipo a %.2f",
                     "(sprintf, el redondeo del atlas hasta el 11-nov-2026) salía %.5f"),
               mean(tipos_2024), tipo_2024, format(renta_madrid, big.mark = ".", decimal.mark = ","),
               tipo_sprintf, esfuerzo(tipo_sprintf)))

# ---- 20 · Zonas tensionadas: municipios con declaración en vigor el 31-12-2025 --------------------

# Cada resolución del BOE trae una tabla: comunidad, municipios (separados por comas, «y» antes del
# último) y el periodo («tres años desde el día siguiente a la publicación»). Se cuentan los nombres
# de las resoluciones publicadas antes del 31-12-2025, que siguen en vigor esa fecha (tres años).
zt <- do.call(rbind, lapply(list.files(file.path(BRUTOS, "zonas_tensionadas"), pattern = "\\.xml$", full.names = TRUE), function(f) {
  x <- read_xml(f)
  pub <- as.Date(xml_text(xml_find_first(x, ".//fecha_publicacion")), "%Y%m%d")
  filas <- xml_find_all(x, ".//table//tr")
  do.call(rbind, lapply(filas, function(tr) {
    td <- vapply(xml_find_all(tr, "./td|./th"), function(n) trimws(gsub("[[:space:]]+", " ", xml_text(n))), "")
    if (length(td) < 3 || grepl("^Comunidad", td[1])) return(NULL)
    data.frame(boe = basename(f), publicacion = pub, comunidad = sub("\\.$", "", td[1]),
               municipios = sub("\\.$", "", td[2]), periodo = td[3], stringsAsFactors = FALSE)
  }))
}))
nombres_zt <- function(texto) {
  texto <- gsub("\\([^)]*\\)", "", texto)                          # ámbitos parciales: el municipio cuenta
  partes <- trimws(unlist(strsplit(texto, ",")))
  partes <- partes[!grepl("^excepto ", partes)]                    # «Vitoria-Gasteiz, excepto la zona rural…»
  ultimo <- length(partes)
  if (ultimo && grepl(" y ", partes[ultimo])) partes <- c(partes[-ultimo], trimws(strsplit(partes[ultimo], " y ")[[1]]))
  partes[nzchar(partes)]
}
vigentes <- zt[zt$publicacion <= as.Date("2025-12-31") & grepl("^Tres años desde el día siguiente", zt$periodo), ]
municipios_2025 <- unique(unlist(lapply(vigentes$municipios, nombres_zt)))
zona <- LARGA[LARGA$indicador == "zona_tensionada" & LARGA$anio == 2025, ]
anotar("20a", "Municipios con zona tensionada declarada (todo o parte), 31-12-2025", "MIVAU, resoluciones en el BOE",
       "zonas_tensionadas/BOE-A-*.xml", length(municipios_2025), sum(zona$valor >= 1, na.rm = TRUE), 0, "tabla larga",
       "Nombres distintos en las tablas de las resoluciones publicadas hasta el 31-12-2025 (vigencia de tres años)")
anotar("20b", "Barcelona, categoría de zona tensionada a 31-12-2025 (2 = todo el municipio)", "MIVAU, resoluciones en el BOE",
       "zonas_tensionadas/BOE-A-2024-5214.xml", if ("Barcelona" %in% municipios_2025) 2 else 0,
       atlas("zona_tensionada", "municipio", "08019", 2025), 0, "tabla larga", "Nombre en la tabla de la resolución, sin ámbito parcial")

# ---- Histórico (F6): Contabilidad Nacional y Banco de España --------------------------------------

cne_s <- leer_jaxi(file.path(BRUTOS, "ine_cne", "71129.csv"))
cne_p <- leer_jaxi(file.path(BRUTOS, "ine_cne", "71133.csv"))
sueldos <- num_es(cne_s$Total[cne_s[[1]] == "Sueldos y salarios" & cne_s[[2]] == "Total CNAE" & cne_s[[3]] == "" &
                                cne_s[[4]] == "" & cne_s[[5]] == "" & cne_s$Periodo == "2024"])
personas <- num_es(cne_p$Total[cne_p[[1]] == "Personas" & cne_p[[2]] == "Asalariados" & cne_p[[3]] == "Total CNAE" &
                                 cne_p[[4]] == "" & cne_p[[5]] == "" & cne_p[[6]] == "" & cne_p$Periodo == "2024"])
hist <- function(serie, anio, sub = 0L) {
  v <- HIST$valor[HIST$serie == serie & HIST$anio == anio & HIST$subperiodo == sub]
  if (length(v) == 1) v else NA_real_
}
anotar("H1", "Sueldo bruto medio por asalariado, España, 2024 (€ al año)", "INE, Contabilidad Nacional",
       "ine_cne/71129.csv y 71133.csv", sueldos * 1e6 / (personas * 1e3), hist("sueldo_asalariado", 2024), 0.005,
       "histórico", "Sueldos y salarios (millones) / personas asalariadas (miles), total de la economía")

anios_renta <- suppressWarnings(as.numeric(si15[si15[, 1] == "DIC 2024", "D_TKB57110_IPV"]))
anotar("H2", "Años de renta para comprar (precio / renta del hogar mediano), España, 4.º trimestre de 2024",
       "Banco de España", "bde/si_1_5.csv", anios_renta, hist("anios_renta", 2024, 4L), 0.005, "histórico",
       "Columna D_TKB57110_IPV, fila DIC 2024")

be19 <- bde("be1901.csv")
col_hip <- which(colnames(be19) == "D_1T9H0000")[1]
tipo_hip <- suppressWarnings(as.numeric(be19[be19[, 1] == "DIC 2024", col_hip]))
anotar("H3", "Tipo medio de los préstamos hipotecarios a más de tres años, diciembre de 2024 (%)",
       "Banco de España", "bde/be1901.csv", tipo_hip, hist("tipo_hipotecas", 2024, 12L), 0.005, "histórico",
       "Columna D_1T9H0000 (la primera, si se repite), fila DIC 2024")

# ---- CIS: la vivienda entre los tres principales problemas de España -------------------------------

cis <- function(estudio, pregunta) {
  t <- paste(readLines(file.path(BRUTOS, "cis_barometros", "resultados", paste0(estudio, ".html")),
                       encoding = "UTF-8", warn = FALSE), collapse = " ")
  celdas <- trimws(strsplit(gsub("<[^>]*>", "|", t), "|", fixed = TRUE)[[1]])
  celdas <- celdas[celdas != ""]
  i <- which(celdas == "La vivienda")[pregunta]          # 1: problemas de España; 2: los que más le afectan
  primero_a_tercero <- num_es(celdas[i + 1:3])
  c(suma = sum(primero_a_tercero), total = num_es(celdas[i + 4]))
}
web_cis <- jsonlite::fromJSON(file.path("web", "datos", "cis_vivienda.json"))
valor_web_cis <- function(serie, periodo) {
  s <- web_cis$series[[serie]]
  v <- s$valor[s$periodo == periodo]
  if (length(v) == 1) v else NA_real_
}
c1 <- cis("3478", 1)
anotar("C1", "La vivienda entre los tres principales problemas de España, octubre de 2024 (%)", "CIS, barómetro 3478",
       "cis_barometros/resultados/3478.html", c1[["suma"]], valor_web_cis("espana", "2024-10"), 0.15, "web (cis_vivienda.json)",
       sprintf("Primer + segundo + tercer problema; la columna TOTAL del CIS dice %s", format(c1[["total"]], decimal.mark = ",")))
c2 <- cis("3478", 2)
anotar("C2", "La vivienda entre los tres problemas que más afectan personalmente, octubre de 2024 (%)", "CIS, barómetro 3478",
       "cis_barometros/resultados/3478.html", c2[["suma"]], valor_web_cis("personal", "2024-10"), 0.15, "web (cis_vivienda.json)",
       sprintf("Primer + segundo + tercer problema; la columna TOTAL del CIS dice %s", format(c2[["total"]], decimal.mark = ",")))

# ---- Salida ---------------------------------------------------------------------------------------

res <- do.call(rbind, resultado)
write.csv(res, file.path("pruebas", "rederivar", "resultado.csv"), row.names = FALSE, fileEncoding = "UTF-8")
print(res[, c("id", "a_mano", "atlas", "diferencia", "coincide")], row.names = FALSE)
cat(sprintf("\n%d cifras: %d coinciden, %d no coinciden, %d sin cifra del atlas\n", nrow(res),
            sum(res$coincide == "coincide"), sum(res$coincide == "no coincide"), sum(res$coincide == "sin cifra del atlas")))
