# Muestra de la web: geometría real, valores inventados.
#
# Genera en web/datos/ejemplo/ los ficheros con que la web funciona mientras no exista la
# exportación del pipeline (web/datos/manifiesto.json y web/teselas/), con el mismo esquema
# (contrato de datos de la web: web/LEEME.md):
#   - secciones.geojson, provincias.geojson   mapa base: las secciones del distrito Centro de
#       Madrid (seccionado de 2021, INE) y el contorno de la provincia
#   - indices/<nivel>.json     códigos de cada nivel en el orden de los valores
#   - <nivel>/<serie>/<periodo>.json   valores INVENTADOS de los indicadores de la v0.1, con la
#       variante de vivienda unifamiliar de los alquileres (alquiler_m2_vu, alquiler_mes_vu) y
#       los auxiliares del alquiler (contratos y margen de la mediana, enlazados con `fiabilidad`)
#   - fichas/28079.json        series de cada sección para la ficha (sin las variantes)
#   - territorios.json, cajas.json, perfiles.json, manifiesto.json
#
# Los valores son de ejemplo (guía, regla 9): aleatorios, sin relación con la sección ni con
# las cifras reales; también los ingresos de las fichas. No es parte del pipeline. Se ejecuta a
# mano desde la raíz del proyecto:
#   Rscript web/herramientas/generar_ejemplo.R
# Necesita datos/brutos/ine_seccionado/seccionado_2021.zip (descarga del pipeline).

suppressPackageStartupMessages(library(sf))

zip_2021 <- file.path("datos", "brutos", "ine_seccionado", "seccionado_2021.zip")
if (!file.exists(zip_2021)) stop("Falta ", zip_2021, ": se descarga con el pipeline (ine_seccionado).")
capa <- "SECC_CE_20210101"
dsn <- paste0("/vsizip/", zip_2021, "/Seccionado_2021/", capa, ".shp")
salida <- file.path("web", "datos", "ejemplo")
ruta_web <- "datos/ejemplo"
unlink(salida, recursive = TRUE)
dir.create(salida, recursive = TRUE, showWarnings = FALSE)

leer <- function(where) {
  st_read(dsn, quiet = TRUE,
          query = sprintf("SELECT CUSEC, CUMUN, CPRO, CCA, NMUN, NPRO, NCA FROM %s WHERE %s", capa, where))
}
escribir_geojson <- function(x, ruta) {
  st_write(x, ruta, driver = "GeoJSON", quiet = TRUE,
           layer_options = c("COORDINATE_PRECISION=6", "RFC7946=YES", "WRITE_BBOX=NO"))
}
escribir_json <- function(x, ...) {
  ruta <- file.path(salida, ...)
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(x, ruta, auto_unbox = TRUE, na = "null", digits = NA)
}

# --- Mapa base --------------------------------------------------------------------------------

# Secciones de Centro (Madrid, distrito 01), simplificadas a 2 m y en grados.
centro <- leer("CUMUN = '28079' AND CDIS = '01'")
centro <- centro[order(centro$CUSEC), ]
secciones <- st_simplify(centro, preserveTopology = TRUE, dTolerance = 2) |> st_transform(4326)
secciones <- st_sf(seccion = secciones$CUSEC, municipio = secciones$CUMUN, geometry = st_geometry(secciones))
escribir_geojson(secciones, file.path(salida, "secciones.geojson"))

# Fondo provisional: la provincia de Madrid disuelta y muy simplificada.
provincia <- leer("CPRO = '28'")
contorno <- st_union(st_buffer(provincia, 1)) |> st_simplify(dTolerance = 150) |> st_transform(4326)
escribir_geojson(st_sf(provincia = "28", nombre = provincia$NPRO[1], geometry = contorno),
                 file.path(salida, "provincias.geojson"))

# --- Territorios ------------------------------------------------------------------------------

codigos <- list(sc = secciones$seccion, municipio = "28079", provincia = "28", ccaa = "13", nacional = "00")
for (nivel in names(codigos)) escribir_json(I(codigos[[nivel]]), "indices", paste0(nivel, ".json"))

escribir_json(list(
  ccaa = list(`13` = centro$NCA[1]),
  provincia = list(`28` = centro$NPRO[1]),
  municipio = list(`28079` = centro$NMUN[1]),
  ccaa_de_provincia = list(`28` = "13")
), "territorios.json")

madrid <- st_transform(provincia[provincia$CUMUN == "28079", ], 4326)
escribir_json(list(municipio = list(`28079` = I(round(as.numeric(st_bbox(madrid)), 5)))), "cajas.json")

# --- Valores INVENTADOS -----------------------------------------------------------------------

set.seed(20261108)
n <- length(codigos$sc)
anios <- 2020:2024
k <- length(anios)

# Serie de cada sección: un punto de partida aleatorio y una subida anual aleatoria.
crecer <- function(desde, hasta, subida_max) {
  inicio <- runif(n, desde, hasta)
  subida <- runif(n, 0, subida_max)
  sapply(seq_len(k), function(j) inicio * (1 + subida)^(j - 1))
}
# Estados: casi todo dato, algo estimado, y opcionalmente secretos y huecos.
estados_al_azar <- function(columnas, secretos = 0, huecos = 0) {
  e <- matrix(sample(0:1, n * columnas, replace = TRUE, prob = c(0.85, 0.15)), n)
  if (secretos > 0) e[sample(n, secretos), ] <- 2L
  if (huecos > 0) e[cbind(sample(which(e[, 1] != 2L), huecos), sample(seq_len(columnas), huecos, replace = TRUE))] <- 3L
  e
}
peor <- function(...) do.call(pmax, list(...))   # orden dato < estimado < secreto < ausente (pregunta 15)

alquiler_m2 <- crecer(11, 26, 0.06)
e_alquiler <- estados_al_azar(k, secretos = 4, huecos = 6)
superficie_mediana <- runif(n, 50, 85)
alquiler_mes <- alquiler_m2 * superficie_mediana
renta_hogar <- crecer(28000, 80000, 0.04)
e_renta <- estados_al_azar(k)
tamano_hogar <- runif(n, 1.8, 2.8)
renta_persona <- renta_hogar / tamano_hogar
renta_uc_mediana <- renta_persona * runif(n, 1.25, 1.5)
esfuerzo <- alquiler_mes * 12 / renta_hogar * 100
periodos_vut <- c("2024-08", "2025-02", "2025-08")
vut <- sapply(seq_along(periodos_vut), function(j) runif(n, 0, 20))

# serie: valores (n × periodos), estados, periodos, decimales y si los periodos son años.
series <- list(
  renta_persona = list(v = renta_persona, e = e_renta, periodos = anios, decimales = 0L),
  renta_hogar = list(v = renta_hogar, e = e_renta, periodos = anios, decimales = 0L),
  renta_uc_mediana = list(v = renta_uc_mediana, e = e_renta, periodos = anios, decimales = 0L),
  alquiler_mes = list(v = alquiler_mes, e = e_alquiler, periodos = anios, decimales = 0L),
  alquiler_m2 = list(v = alquiler_m2, e = e_alquiler, periodos = anios, decimales = 1L),
  esfuerzo_residentes = list(v = esfuerzo, e = peor(e_alquiler, e_renta), periodos = anios, decimales = 1L),
  hogares_alquiler = list(v = matrix(runif(n, 15, 55)), e = estados_al_azar(1), periodos = 2021L, decimales = 1L),
  viviendas_turisticas = list(v = vut, e = estados_al_azar(3, huecos = 2), periodos = periodos_vut, decimales = 1L)
)

# Variantes por tipología (como en la exportación del pipeline): la serie de la vivienda
# colectiva lleva «variantes» y la de la unifamiliar, «por_defecto». Las variantes no van en
# las series de la ficha.
variantes <- c(alquiler_m2 = "alquiler_m2_vu", alquiler_mes = "alquiler_mes_vu")
en_ficha <- setdiff(names(series), variantes)

# Formato de la web (plan, §6.6): {"v": [valor × 10 en enteros, null sin valor], "e": "0012…"}.
# Primero se redondea a una décima como manda la guía (sprintf("%.1f")) y después se multiplica:
# sprintf("%.0f", x * 10) no da lo mismo en algunos casos (0,15 → 0,1 con la guía, pero 2 décimas así).
# I() impide que jsonlite convierta en escalar un vector de longitud 1.
codificar <- function(x, e) {
  x[e >= 2L] <- NA
  v <- rep(NA_integer_, length(x))
  v[!is.na(x)] <- as.integer(round(as.numeric(sprintf("%.1f", x[!is.na(x)])) * 10))
  list(v = I(v), e = paste(e, collapse = ""))
}

niveles <- names(codigos)
escribir_series <- function(nombres) {
  for (s in nombres) {
    d <- series[[s]]
    for (j in seq_along(d$periodos)) {
      escribir_json(codificar(d$v[, j], d$e[, j]), "sc", s, paste0(d$periodos[j], ".json"))
      # Territorios superiores: una cifra inventada, alrededor de la media de las secciones.
      media <- mean(d$v[, j], na.rm = TRUE)
      otros <- c(municipio = media * runif(1, 0.9, 1.1), provincia = media * runif(1, 0.75, 0.95))
      otros <- c(otros, ccaa = otros[["provincia"]], nacional = otros[["provincia"]] * runif(1, 0.6, 0.85))
      for (nivel in names(otros)) escribir_json(codificar(otros[[nivel]], 0L), nivel, s, paste0(d$periodos[j], ".json"))
    }
  }
}
escribir_series(names(series))

# Vivienda unifamiliar (variante «VU» de los alquileres; decisión 12): pocas secciones con dato
# en el centro de una ciudad, como en los datos reales. Se sortea después del resto para no
# cambiar los valores anteriores de la muestra.
alquiler_m2_vu <- crecer(9, 22, 0.05)
e_vu <- estados_al_azar(k, secretos = 10, huecos = 6)
e_vu[sample(n, round(n * 0.6)), ] <- 3L
series$alquiler_m2_vu <- list(v = alquiler_m2_vu, e = e_vu, periodos = anios, decimales = 1L)
series$alquiler_mes_vu <- list(v = alquiler_m2_vu * runif(n, 70, 140), e = e_vu, periodos = anios, decimales = 0L)
escribir_series(variantes)

# Contratos y margen de la mediana (auxiliares del alquiler; plan §11, preguntas 12 y 15
# ampliadas), coherentes con el estado del alquiler: con mediana, de 10 a 300 contratos (algunas
# secciones con menos de 30, «pocos contratos»); en secreto, de 1 a 9; sin dato, 0 o sin recuento.
# El margen, con la fórmula del pipeline (margen_mediana(): 0,929 × recorrido intercuartílico
# relativo / √n) y una dispersión inventada; solo donde hay mediana. Se sortean después del resto
# para no cambiar los valores anteriores de la muestra.
contratos_de <- function(e) {
  x <- matrix(NA_real_, n, k)
  con <- e <= 1L
  x[con] <- round(exp(runif(sum(con), log(10), log(300))))
  x[e == 2L] <- sample(1:9, sum(e == 2L), replace = TRUE)
  aus <- which(e == 3L)
  x[aus] <- ifelse(runif(length(aus)) < 0.5, 0, NA)
  x
}
margen_de <- function(contratos, e) {
  m <- 100 * sqrt(pi / 2) / (2 * qnorm(0.75)) * runif(n * k, 0.25, 0.6) / sqrt(contratos)
  m[e > 1L] <- NA
  m
}
estado_recuento <- function(x) matrix(ifelse(is.na(x), 3L, 0L), n)
estado_margen <- function(x) matrix(ifelse(is.na(x), 3L, 0L), n)
c_vc <- contratos_de(e_alquiler)
c_vu <- contratos_de(e_vu)
auxiliares <- list(
  contratos_alquiler = list(v = c_vc, e = estado_recuento(c_vc), periodos = anios, decimales = 0L),
  contratos_alquiler_vu = list(v = c_vu, e = estado_recuento(c_vu), periodos = anios, decimales = 0L),
  margen_alquiler_m2 = list(v = matrix(margen_de(c_vc, e_alquiler), n), periodos = anios, decimales = 1L),
  margen_alquiler_m2_vu = list(v = matrix(margen_de(c_vu, e_vu), n), periodos = anios, decimales = 1L),
  margen_alquiler_mes = list(v = matrix(margen_de(c_vc, e_alquiler), n), periodos = anios, decimales = 1L),
  margen_alquiler_mes_vu = list(v = matrix(margen_de(c_vu, e_vu), n), periodos = anios, decimales = 1L)
)
for (s in grep("^margen_", names(auxiliares), value = TRUE)) auxiliares[[s]]$e <- estado_margen(auxiliares[[s]]$v)
series <- c(series, auxiliares)
escribir_series(names(auxiliares))
variantes <- c(variantes, contratos_alquiler = "contratos_alquiler_vu", margen_alquiler_m2 = "margen_alquiler_m2_vu",
               margen_alquiler_mes = "margen_alquiler_mes_vu")
# Los auxiliares no van en las fichas (la web los lee de los ficheros del periodo, como el pipeline)
en_ficha <- setdiff(names(series), c(variantes, names(auxiliares)))
# Series de fiabilidad de cada serie del alquiler (y de las que salen de él), de su misma tipología
fiabilidad <- list(
  alquiler_m2 = list(contratos = "contratos_alquiler", margen = "margen_alquiler_m2"),
  alquiler_m2_vu = list(contratos = "contratos_alquiler_vu", margen = "margen_alquiler_m2_vu"),
  alquiler_mes = list(contratos = "contratos_alquiler", margen = "margen_alquiler_mes"),
  alquiler_mes_vu = list(contratos = "contratos_alquiler_vu", margen = "margen_alquiler_mes_vu"),
  esfuerzo_residentes = list(contratos = "contratos_alquiler", margen = "margen_alquiler_mes")
)

# Series de la ficha, un fichero por municipio (todas las secciones de la muestra son de Madrid).
escribir_json(list(
  municipio = "28079",
  anios = lapply(series[en_ficha], function(d) I(d$periodos)),
  series = stats::setNames(lapply(seq_len(n), function(i) lapply(series[en_ficha], function(d) codificar(d$v[i, ], d$e[i, ]))),
                           codigos$sc)
), "fichas", "28079.json")

# Ingresos de las fichas (neto mensual en euros, INVENTADOS). Sin transistor: llega en F3.
escribir_json(list(
  llave = list(ingreso = list(serie = "renta_hogar", divisor = 12L), vivienda = list(serie = "alquiler_mes")),
  mochila = list(anio = 2024L, nivel = "provincia", neto_mensual = list(`28` = 1450), superficie_m2 = 50L),
  tartera = list(anio = 2026L, nivel = "nacional", neto_mensual = list(`00` = 1300), superficie_m2 = 50L)
), "perfiles.json")

# --- Manifiesto ---------------------------------------------------------------------------------

indicadores <- lapply(names(series), function(s) {
  d <- series[[s]]
  def <- list(niveles = I(niveles), decimales = d$decimales)
  if (s %in% names(variantes)) def$variantes <- list(VU = variantes[[s]])
  if (s %in% variantes) def$por_defecto <- names(variantes)[variantes == s]
  if (!is.null(fiabilidad[[s]])) def$fiabilidad <- fiabilidad[[s]]
  if (is.numeric(d$periodos)) {
    def$anios <- I(d$periodos)
    def$ruta <- sprintf("%s/{nivel}/%s/{anio}.json", ruta_web, s)
  } else {
    def$periodos <- I(d$periodos)
    def$ruta <- sprintf("%s/{nivel}/%s/{periodo}.json", ruta_web, s)
  }
  def
})
names(indicadores) <- names(series)

manifiesto <- list(
  version = "ejemplo",
  ejemplo = TRUE,
  generado = format(Sys.Date()),
  seccionado = 2021L,
  mapa_base = list(
    tipo = "geojson",
    atribucion = "INE",
    capas = list(
      provincias = list(url = file.path(ruta_web, "provincias.geojson"), id = "provincia"),
      secciones = list(url = file.path(ruta_web, "secciones.geojson"), id = "seccion")
    )
  ),
  indices = stats::setNames(lapply(niveles, function(nv) sprintf("%s/indices/%s.json", ruta_web, nv)), niveles),
  territorios = file.path(ruta_web, "territorios.json"),
  cajas = file.path(ruta_web, "cajas.json"),
  fichas = file.path(ruta_web, "fichas", "{municipio}.json"),
  perfiles = file.path(ruta_web, "perfiles.json"),
  codificacion = list(escala = 10L, estados = c("dato", "estimado", "secreto", "ausente")),
  supuestos = list(superficie_m2 = 50L, umbral = 0.30),
  umbral_pocos_contratos = 30L,
  indicadores = indicadores,
  mapas = list(
    # formula: nombre de una transformación conocida por la web (js/formulas.js), no código.
    # Tarea 40: la cifra principal con el alquiler mensual real y, al lado, el mínimo de 50 m².
    sueldo_necesario = list(base = "alquiler_mes", formula = "alquiler_mes_a_sueldo",
                            minimo = list(base = "alquiler_m2", formula = "alquiler_m2_a_sueldo"),
                            cortes = c(3000L, 3800L, 4500L, 5200L, 6000L), decimales = 0L),
    renta_hogar = list(base = "renta_hogar", formula = "directo",
                       cortes = c(35000L, 45000L, 55000L, 65000L), decimales = 0L),
    alquiler_m2 = list(base = "alquiler_m2", formula = "directo", cortes = c(14, 17, 20, 23), decimales = 1L),
    viviendas_turisticas = list(base = "viviendas_turisticas", formula = "directo",
                                cortes = c(4, 8, 12, 16), decimales = 1L)
  ),
  vista_inicial = list(limites = round(as.numeric(st_bbox(secciones)), 5))
)
jsonlite::write_json(manifiesto, file.path(salida, "manifiesto.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

tam <- file.size(list.files(salida, recursive = TRUE, full.names = TRUE))
message(sprintf("Muestra en %s: %d secciones, %d series, %d ficheros, %s KB.", salida, n, length(series),
                length(tam), sprintf("%.1f", sum(tam) / 1024)))
