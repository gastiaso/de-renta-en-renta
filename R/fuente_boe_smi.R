# BOE, real decreto del salario mínimo interprofesional de cada año (boe_smi). Fuente de la
# tartera (SMI_FICHAS, R/derivados.R). El XML de cada disposición se guarda en
# datos/brutos/boe_smi/<año>_<identificador>.xml; de él se leen la cuantía mensual (en 14 pagas)
# y el mes desde el que surte efectos. Solo se comprueban los años de ANIOS_BOE_SMI: los XML de
# 2024 a 2026 no se han bajado (decisión del autor, 9-nov-2026).

URL_BOE_XML <- "https://www.boe.es/diario_boe/xml.php?id=%s"
DIR_BOE_SMI <- file.path("datos", "brutos", "boe_smi")
ANIOS_BOE_SMI <- 2015:2023
MESES_ES <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
              "septiembre", "octubre", "noviembre", "diciembre")

# XML de los reales decretos de `anios`, con caché. El identificador de cada año sale de la
# columna `boe` de SMI_FICHAS (2021 lleva dos: el de 2020, prorrogado, y el suyo; cada XML se
# guarda con el año del decreto).
descargar_boe_smi <- function(anios = ANIOS_BOE_SMI, smi = SMI_FICHAS, dir = DIR_BOE_SMI) {
  f <- smi[smi$anio %in% anios & !is.na(smi$boe), ]
  ids <- unlist(strsplit(f$boe, ";", fixed = TRUE))
  ids <- ids[!duplicated(ids)]
  rutas <- vapply(ids, function(id) {
    anio <- f$anio[grepl(id, f$boe, fixed = TRUE)][1]
    destino <- file.path(dir, paste0(anio, "_", id, ".xml"))
    descargar_con_cache(sprintf(URL_BOE_XML, id), destino)
  }, "")
  unname(rutas)
}

# Año, norma, identificador, cuantía mensual (euros) y primer mes con efectos de cada XML.
leer_boe_smi <- function(rutas) {
  dplyr::bind_rows(lapply(rutas, function(ruta) {
    x <- xml2::read_xml(ruta)
    campo <- function(xpath) xml2::xml_text(xml2::xml_find_first(x, xpath))
    titulo <- campo("/documento/metadatos/titulo")
    texto <- gsub("\\s+", " ", gsub("\u00a0", " ", campo("/documento/texto"), fixed = TRUE))
    cuantia <- regmatches(texto, regexec("([0-9.]+(,[0-9]+)?) euros/mes", texto))[[1]][2]
    mes <- regmatches(texto, regexec("(desde el|entre el) 1 de ([a-z]+)", texto))[[1]][3]
    tibble::tibble(
      anio = as.integer(regmatches(titulo, regexec("para (\\d{4})", titulo))[[1]][2]),
      norma = paste("RD", regmatches(titulo, regexec("Real Decreto (\\d+/\\d{4})", titulo))[[1]][2]),
      id = campo("/documento/metadatos/identificador"),
      mensual = as.numeric(sub(",", ".", gsub(".", "", cuantia, fixed = TRUE), fixed = TRUE)),
      desde = match(mes, MESES_ES)
    )
  }))
}

# Compuerta smi_boe (bloqueo): cuantía de SMI_FICHAS frente a la del real decreto de su año; si
# el decreto surte efectos desde un mes posterior a enero, los meses anteriores llevan la cuantía
# del año anterior, prorrogada (2021: media ponderada por meses de vigencia, pregunta 18). Y la
# norma de SMI_FICHAS debe citar el decreto (1 si no lo cita).
comprobar_smi_boe <- function(boe, smi = SMI_FICHAS) {
  b <- boe[order(boe$anio), ]
  previo <- b$mensual[match(b$anio - 1L, b$anio)]
  ponderado <- ifelse(b$desde > 1, (previo * (b$desde - 1) + b$mensual * (13 - b$desde)) / 12, b$mensual)
  f <- smi[match(b$anio, smi$anio), ]
  dplyr::bind_rows(
    tibble::tibble(id = "smi_boe", anio = b$anio, detalle = paste(b$norma, "cuant\u00eda"),
                   calculado = f$mensual, referencia = ponderado),
    tibble::tibble(id = "smi_boe", anio = b$anio, detalle = paste(b$norma, "norma"),
                   calculado = as.numeric(is.na(f$norma) | !mapply(grepl, b$norma, f$norma, fixed = TRUE)),
                   referencia = 0)
  )
}
