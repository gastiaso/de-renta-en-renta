# Rederivación a mano de cinco cifras de «Entrar» (backlog, tarea 59), desde los ficheros de la
# fuente: la extracción de Idealista (datos/brutos/portales/idealista/, solo en local), la base del
# SERPAVI (datos/brutos/mivau_serpavi/) y el real decreto del salario mínimo (datos/brutos/boe_smi/).
# Código propio: no carga nada de R/. La cifra del atlas sale de targets::tar_read(indicadores_entrar)
# (cifras exactas que no salen del pipeline), solo para comparar.
#
# Privacidad (backlog, decisiones 17 a 19): ninguna cifra de Idealista ni derivada exacta suya va a un
# fichero versionado. Las cifras exactas se escriben en datos/intermedios/rederivar/entrar.csv (fuera
# de git); a pruebas/rederivar/resultado_entrar.csv solo van «coincide / no coincide» y, en la brecha,
# el tramo de inventario/entrar_tramos.csv. Por pantalla, lo mismo que al fichero versionado.
#
# Uso, desde la raíz del proyecto (necesita la extracción de Idealista y el almacén de targets con
# indicadores_entrar, que solo existe tras un tar_make() con PORTALES=TRUE):
#   Rscript pruebas/rederivar/rederivar_entrar.R

suppressPackageStartupMessages({
  library(readxl)
  library(xml2)
})

BRUTOS <- file.path("datos", "brutos")
IDEALISTA <- file.path(BRUTOS, "portales", "idealista")
historico <- list.files(IDEALISTA, pattern = "^alquiler_historico_.*\\.csv$", full.names = TRUE)
if (!length(historico)) stop("Falta la extracción de Idealista en ", IDEALISTA, call. = FALSE)
historico <- sort(historico, decreasing = TRUE)[1]

# Redondeo con los empates hacia arriba sobre la cifra decimal.
redondear <- function(x, d = 1) floor(x * 10^d + 0.5 + 1e-9) / 10^d

# ---- Oferta: media anual de los meses publicados (9 como mínimo), a dos decimales -------------------

h <- read.csv(historico, colClasses = "character", encoding = "UTF-8")
territorios <- read.csv(file.path("inventario", "portales_idealista_territorios.csv"), colClasses = "character",
                        encoding = "UTF-8")
mun <- territorios[territorios$nivel == "municipio" & nzchar(territorios$geo_id), c("path", "geo_id")]
h <- h[h$path %in% mun$path, ]
h$geo_id <- mun$geo_id[match(h$path, mun$path)]
h$anio <- substr(h$fecha, 1, 4)
h$valor <- suppressWarnings(as.numeric(h$precio_m2))
h <- h[!is.na(h$valor), ]
oferta_anual <- function(anio) {
  d <- h[h$anio == anio, ]
  meses <- tapply(substr(d$fecha, 1, 7), d$geo_id, function(x) length(unique(x)))
  media <- tapply(d$valor, d$geo_id, mean)
  v <- redondear(media, 2)
  v[meses < 9] <- NA
  v[!is.na(v)]
}

# ---- SERPAVI, vivienda colectiva: medianas municipales del alquiler mensual y por m², a un decimal ----

serpavi <- file.path(BRUTOS, "mivau_serpavi", "bd_serpavi_2011-2024.xlsx")
cab <- names(suppressMessages(read_excel(serpavi, sheet = "Municipios", n_max = 0)))
serpavi_municipios <- function(anio) {
  aa <- sprintf("%02d", anio %% 100)
  cols <- c(CUMUN = "CUMUN",
            testigos = paste0("BI_ALVHEPCO_TVC_", aa),
            mes = paste0("ALQTBID12_M_VC_", aa),
            m2 = grep(paste0("^ALQM2(mes)?_LV_M_VC_", aa, "$"), cab, value = TRUE))
  tipos <- ifelse(cab %in% cols, ifelse(cab == "CUMUN", "text", "numeric"), "skip")
  d <- suppressWarnings(suppressMessages(read_excel(serpavi, sheet = "Municipios", col_types = tipos)))
  d <- as.data.frame(d)[, cols]
  names(d) <- names(cols)
  d$CUMUN <- sprintf("%05d", as.integer(as.numeric(d$CUMUN)))
  d <- d[!is.na(d$testigos) & d$testigos >= 10 & !is.na(d$mes) & !is.na(d$m2), ]
  data.frame(geo_id = d$CUMUN, mes = redondear(d$mes, 1), m2 = redondear(d$m2, 1))
}

# ---- Salario mínimo de 2023 (tartera): real decreto del BOE, neto prorrateado en 12 -----------------

smi_2023 <- function() {
  x <- read_xml(file.path(BRUTOS, "boe_smi", "2023_BOE-A-2023-3982.xml"))
  t <- gsub("[[:space:]]+", " ", xml_text(x))
  m <- regmatches(t, regexpr("[0-9.]+(,[0-9]{2})? euros/mes", t))[1]   # «1080 euros/mes» o «1.080,00 euros/mes»
  mensual <- as.numeric(gsub(",", ".", gsub(".", "", sub(" euros/mes", "", m), fixed = TRUE), fixed = TRUE))
  # Cotización del trabajador en 2023: 4,70 + 1,55 + 0,10 + 0,10 (MEI) = 6,45 %; exento de IRPF.
  redondear(mensual * 14 * (1 - 0.0645) / 12, 1)
}

# ---- Cálculo a mano ---------------------------------------------------------------------------------

tramos <- read.csv(file.path("inventario", "entrar_tramos.csv"), colClasses = "character", encoding = "UTF-8")
fila <- tramos[tramos$indicador == "brecha_entrar_quedarse", ]
cortes <- as.numeric(strsplit(fila$cortes, ";", fixed = TRUE)[[1]])
bordes <- c(as.numeric(fila$limite_inferior), cortes, as.numeric(fila$limite_superior))
tramo_de <- function(x) {
  k <- findInterval(x * (1 + 1e-12), cortes)
  sprintf("tramo %d (de %s a %s)", k, format(bordes[k + 1], decimal.mark = ","), format(bordes[k + 2], decimal.mark = ","))
}

o24 <- oferta_anual("2024"); s24 <- serpavi_municipios(2024)
o23 <- oferta_anual("2023"); s23 <- serpavi_municipios(2023)
comun24 <- s24[s24$geo_id %in% names(o24), ]
comun24$oferta <- o24[comun24$geo_id]
comun24$brecha <- comun24$oferta / comun24$m2
comun24$superficie <- comun24$mes / comun24$m2
tartera <- smi_2023()

a_mano <- data.frame(
  id = c("E1", "E2", "E3", "E4", "E5"),
  cifra = c("Brecha entre la oferta y el parque, Madrid (municipio), 2024",
            "Brecha entre la oferta y el parque, Barcelona (municipio), 2024",
            "Brecha mediana de los municipios con oferta y SERPAVI, 2024",
            "Sueldo para entrar con 50 m² (umbral del 30 %), València (municipio), 2024",
            "Barrera para entrar de la tartera (50 m², salario mínimo de 2023), Madrid (municipio), 2023"),
  indicador = c("brecha_entrar_quedarse", "brecha_entrar_quedarse", "brecha_entrar_quedarse",
                "sueldo_entrar_50", "barrera_entrar"),
  geo_id = c("28079", "08019", NA, "46250", "28079"),
  anio = c(2024L, 2024L, 2024L, 2024L, 2023L),
  fuente = c(rep("Idealista (oferta) y MIVAU, SERPAVI (vivienda colectiva)", 3), "Idealista (oferta)",
             "Idealista (oferta) y BOE, RD 99/2023"),
  fichero = c(rep("portales/idealista/alquiler_historico_*.csv y mivau_serpavi/bd_serpavi_2011-2024.xlsx", 3),
              "portales/idealista/alquiler_historico_*.csv",
              "portales/idealista/alquiler_historico_*.csv y boe_smi/2023_BOE-A-2023-3982.xml"),
  valor = c(comun24$brecha[comun24$geo_id == "28079"], comun24$brecha[comun24$geo_id == "08019"],
            stats::median(comun24$brecha), o24[["46250"]] * 50 / 0.30, 100 * o23[["28079"]] * 50 / tartera),
  stringsAsFactors = FALSE
)

# Superficie típica mediana de esos mismos municipios (quinta comprobación auxiliar, sin cifra en el informe).
superficie_mediana <- stats::median(comun24$superficie)

# ---- Cifras del atlas (almacén de targets, solo lectura) ----------------------------------------------

e <- targets::tar_read(indicadores_entrar)
atlas_de <- function(ind, geo, anio, grupo = "total") {
  v <- e$valor[e$indicador == ind & e$nivel == "municipio" & e$geo_id == geo & e$anio == anio & e$grupo == grupo]
  if (length(v) == 1) v else NA_real_
}
brechas_atlas <- e[e$indicador == "brecha_entrar_quedarse" & e$nivel == "municipio" & e$anio == 2024 & !is.na(e$valor), ]
sup_atlas <- e[e$indicador == "superficie_tipica" & e$nivel == "municipio" & e$anio == 2024 & !is.na(e$valor) &
                 e$geo_id %in% brechas_atlas$geo_id, ]
a_mano$atlas <- c(atlas_de("brecha_entrar_quedarse", "28079", 2024), atlas_de("brecha_entrar_quedarse", "08019", 2024),
                  stats::median(brechas_atlas$valor), atlas_de("sueldo_entrar_50", "46250", 2024),
                  atlas_de("barrera_entrar", "28079", 2023, "tartera"))
a_mano$diferencia <- a_mano$valor - a_mano$atlas
a_mano$coincide <- ifelse(is.na(a_mano$atlas), "sin cifra del atlas",
                          ifelse(abs(a_mano$diferencia) <= 1e-6 * pmax(1, abs(a_mano$atlas)), "coincide", "no coincide"))
a_mano$tramo <- ifelse(a_mano$id %in% c("E1", "E2"), tramo_de(a_mano$valor), "")
a_mano$nota <- c("", "", if (nrow(comun24) == nrow(brechas_atlas)) "los mismos municipios a mano y en el atlas" else "distinto número de municipios a mano y en el atlas", "", "")
extra <- data.frame(
  id = "E6", cifra = "Superficie típica mediana de esos municipios, 2024 (m², SERPAVI)",
  indicador = "superficie_tipica", geo_id = NA, anio = 2024L, fuente = "MIVAU, SERPAVI",
  fichero = "mivau_serpavi/bd_serpavi_2011-2024.xlsx", valor = superficie_mediana,
  atlas = stats::median(sup_atlas$valor), stringsAsFactors = FALSE)
extra$diferencia <- extra$valor - extra$atlas
extra$coincide <- ifelse(abs(extra$diferencia) <= 1e-6 * extra$atlas, "coincide", "no coincide")
extra$tramo <- ""
extra$nota <- "Cifra del SERPAVI (pública), en los municipios con oferta"
todo <- rbind(a_mano, extra)

# Exacto: solo fuera de git.
dir.create(file.path("datos", "intermedios", "rederivar"), showWarnings = FALSE, recursive = TRUE)
write.csv(todo, file.path("datos", "intermedios", "rederivar", "entrar.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Versionado: sin cifras.
publico <- todo[, c("id", "cifra", "indicador", "anio", "fuente", "fichero", "coincide", "tramo", "nota")]
write.csv(publico, file.path("pruebas", "rederivar", "resultado_entrar.csv"), row.names = FALSE, fileEncoding = "UTF-8")
print(publico[, c("id", "coincide", "tramo", "nota")], row.names = FALSE)
