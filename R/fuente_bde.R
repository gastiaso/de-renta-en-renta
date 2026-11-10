# F6, histórico («máquina del tiempo»; plan §7): series nacionales del Banco de España desde 1987.
#   si_1_5 (Síntesis de indicadores, 1.5 «Indicadores del mercado inmobiliario»), trimestrales:
#     D_TKB57110_IPV  precio de la vivienda / renta bruta del hogar mediano (años de renta);
#     D_TKB57210_IPV  esfuerzo teórico anual sin deducciones (% de la renta disponible del hogar
#                     mediano que se va en las cuotas del primer año, préstamo del 80 %);
#     DHIVTNOAPLPMMUVT_RLI.T  valor tasado medio de la vivienda libre del MIVAU (€/m²), que el
#                     Banco de España reproduce: solo para la compuerta del valor tasado.
#   be1901 (Boletín Estadístico, 19.1 «Tipos de interés de referencia oficiales del mercado
#   hipotecario»), mensuales:
#     D_1T9H0000      tipo medio de los préstamos hipotecarios a más de tres años para adquisición
#                     de vivienda libre, conjunto de entidades de crédito en España (desde 1990);
#     D_1E723706.EUR  MIBOR a un año (desde 1977; desde 1999 sigue al euríbor a un año).
# CSV de dirección estable en latin1: seis filas de cabecera (código, número secuencial, alias,
# descripción, unidades, frecuencia), una fila por mes («ENE 1987»; las series trimestrales solo
# llenan marzo, junio, septiembre y diciembre), «_» sin dato y dos filas de cierre, FUENTE y NOTAS:
# si faltan, la descarga llegó cortada. La serie «con deducciones» que cita la nota metodológica
# (vigente hasta 2012) no está en el CSV ni en la API (comprobado el 10-nov-2026).
# Reutilización: términos de uso de las estadísticas del Banco de España (citar «Elaboración propia
# con datos extraídos del sitio web del Banco de España (www.bde.es)» y la fecha de actualización).
# Incorporado el 10-nov-2026.

HIST_DESDE <- 1987L                      # primer a\u00f1o del m\u00f3dulo hist\u00f3rico
HIST_TABLAS_BDE <- c(si_1_5 = "si_1_5", be1901 = "be1901")
HIST_SERIES_BDE <- tibble::tribble(
  ~serie,             ~tabla,   ~codigo,                  ~frecuencia,  ~unidad,      ~fuente,
  "anios_renta",      "si_1_5", "D_TKB57110_IPV",         "trimestral", "anios",      "bde_accesibilidad",
  "esfuerzo_teorico", "si_1_5", "D_TKB57210_IPV",         "trimestral", "porcentaje", "bde_accesibilidad",
  "valor_tasado_bde", "si_1_5", "DHIVTNOAPLPMMUVT_RLI.T", "trimestral", "euros_m2",   "bde_accesibilidad",
  "tipo_hipotecas",   "be1901", "D_1T9H0000",             "mensual",    "porcentaje", "bde_tipos_referencia",
  "mibor_euribor",    "be1901", "D_1E723706.EUR",         "mensual",    "porcentaje", "bde_tipos_referencia"
)
# Series del módulo que no se publican: solo sirven a una compuerta
HIST_SOLO_COMPUERTA <- "valor_tasado_bde"
HIST_MESES_BDE <- c(ENE = 1L, FEB = 2L, MAR = 3L, ABR = 4L, MAY = 5L, JUN = 6L, JUL = 7L, AGO = 8L, SEP = 9L,
                    OCT = 10L, NOV = 11L, DIC = 12L)

hist_descargar_bde <- function(tabla, dir = file.path("datos", "brutos", "bde"), forzar = FALSE) {
  hist_descargar_entera(sprintf("https://www.bde.es/webbe/es/estadisticas/compartido/datos/csv/%s.csv", tabla),
                        file.path(dir, paste0(tabla, ".csv")), hist_csv_bde_entero, forzar = forzar)
}

# Las descargas pueden llegar cortadas sin dar error (guía; backlog, «Siguiente», punto 6). Si la
# prueba `entera` falla, se repite la descarga; tras `intentos`, se borra el fichero y se para.
hist_descargar_entera <- function(url, destino, entera, intentos = 3L, forzar = FALSE) {
  for (k in seq_len(intentos)) {
    ruta <- descargar_con_cache(url, destino, forzar = forzar || k > 1L)
    if (isTRUE(entera(ruta))) return(ruta)
    warning("Descarga cortada (", basename(ruta), "): se repite", call. = FALSE)
  }
  unlink(destino)
  stop("La descarga de ", url, " llega cortada ", intentos, " veces; se ha borrado ", destino, call. = FALSE)
}

# Una tabla del Banco de España está entera si termina con las filas FUENTE y NOTAS.
hist_csv_bde_entero <- function(ruta) {
  final <- utils::tail(readLines(ruta, warn = FALSE, encoding = "latin1"), 3)
  any(startsWith(final, "\"FUENTE\"")) && any(startsWith(final, "\"NOTAS\""))
}

# Una tabla del Banco de España: codigo, anio, mes y valor (NA sin dato) de los `codigos` pedidos
# (un código repetido en la tabla, como D_1T9H0000 en be1901, se toma de su primera columna).
hist_leer_bde <- function(ruta, codigos) {
  x <- readr::read_csv(ruta, col_names = FALSE, col_types = readr::cols(.default = "c"),
                       locale = readr::locale(encoding = "latin1"), na = character(), progress = FALSE)
  etiquetas <- toupper(trimws(x[[1]]))
  if (!all(c("FUENTE", "NOTAS") %in% etiquetas)) {
    stop("Tabla del Banco de Espa\u00f1a sin las filas FUENTE y NOTAS (descarga cortada): ", ruta, call. = FALSE)
  }
  cabecera <- unlist(x[1, ], use.names = FALSE)
  faltan <- setdiff(codigos, cabecera)
  if (length(faltan)) stop("Series que no est\u00e1n en ", basename(ruta), ": ", paste(faltan, collapse = ", "), call. = FALSE)
  filas <- grep("^[A-Z]{3} [0-9]{4}$", etiquetas)
  mes <- unname(HIST_MESES_BDE[substr(etiquetas[filas], 1, 3)])
  if (anyNA(mes)) stop("Meses que no se reconocen en ", basename(ruta), call. = FALSE)
  anio <- as.integer(substr(etiquetas[filas], 5, 8))
  dplyr::bind_rows(lapply(codigos, function(k) {
    texto <- trimws(x[[match(k, cabecera)]][filas])
    valor <- suppressWarnings(as.numeric(texto))
    raros <- !is.na(texto) & nzchar(texto) & texto != "_" & is.na(valor)
    if (any(raros)) stop("Cifras que no se leen en ", k, ": ", paste(utils::head(texto[raros], 3), collapse = ", "), call. = FALSE)
    tibble::tibble(codigo = k, anio = anio, mes = mes, valor = valor)
  }))
}

# Las series de HIST_SERIES_BDE en el formato del módulo histórico (hist_columnas()): una fila por
# periodo (trimestre o mes) desde HIST_DESDE o desde el primer dato hasta el último; los huecos
# intermedios quedan como NA (la compuerta los cuenta). `rutas`: las tablas, con su nombre.
hist_leer_bde_tablas <- function(rutas, series = HIST_SERIES_BDE, desde = HIST_DESDE) {
  dplyr::bind_rows(lapply(seq_len(nrow(series)), function(i) {
    s <- series[i, ]
    d <- hist_leer_bde(rutas[[s$tabla]], s$codigo)
    if (s$frecuencia == "trimestral") {
      fuera <- sum(!is.na(d$valor) & d$mes %% 3L != 0L)
      if (fuera) stop("La serie trimestral ", s$codigo, " trae ", fuera, " cifras fuera de fin de trimestre", call. = FALSE)
      d <- d[d$mes %% 3L == 0L, ]
      d$subperiodo <- d$mes %/% 3L
    } else {
      d$subperiodo <- d$mes
    }
    d <- d[d$anio >= desde, ]
    con <- which(!is.na(d$valor))
    if (!length(con)) stop("La serie ", s$codigo, " no trae cifras desde ", desde, call. = FALSE)
    d <- d[min(con):max(con), ]
    hist_columnas(tibble::tibble(serie = s$serie, geo_id = "00", nivel = "nacional", frecuencia = s$frecuencia,
                                 anio = d$anio, subperiodo = d$subperiodo, valor = d$valor, unidad = s$unidad,
                                 fuente = s$fuente, codigo = s$codigo))
  }))
}

# Columnas de la tabla del módulo histórico (una tabla propia, no la tabla larga: series
# trimestrales y mensuales, nacionales y de comunidad; plan §7, F6).
HIST_COLUMNAS <- c("serie", "geo_id", "nivel", "frecuencia", "anio", "subperiodo", "valor", "unidad", "fuente", "codigo")
hist_columnas <- function(x) {
  x$anio <- as.integer(x$anio)
  x$subperiodo <- as.integer(x$subperiodo)
  x$valor <- as.numeric(x$valor)
  x[HIST_COLUMNAS]
}
