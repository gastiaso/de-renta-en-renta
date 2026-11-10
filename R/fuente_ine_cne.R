# F6, histórico: sueldo bruto medio por asalariado desde 1995, de la Contabilidad Nacional Anual de
# España del INE (base 2020; «Agregados por ramas de actividad»), en CSV de jaxiT3:
#   71129  agregados macroeconómicos a precios corrientes (millones de euros): remuneración de los
#          asalariados, sueldos y salarios y cotizaciones sociales a cargo de los empleadores;
#   71133  empleo (miles): personas, puestos de trabajo, equivalentes a tiempo completo y horas,
#          totales y asalariados.
# Sueldo bruto medio por asalariado (€ al año) = sueldos y salarios / personas asalariadas, del
# total de la economía: una media (regla 1), con los dos términos del mismo año (regla 4). Es la
# serie oficial más larga que mide lo mismo todos los años (SEC 2010 en base 2020, 1995–último
# año, sin rupturas); los últimos años son estimaciones provisionales y avances, que el INE revisa
# cada septiembre. Es otra cosa que el salario medio de la AEAT (indicador 7, desde 2011): no
# descuenta a quien cobra parte del año y no sale de las retenciones. El INE renumera la tabla
# cuando cambia de base (HIST_TABLAS_CNE). CC BY 4.0. Incorporado el 10-nov-2026.

HIST_TABLAS_CNE <- c(agregados = "71129", empleo = "71133")
HIST_MEDIDAS_CNE <- c(sueldos = "Sueldos y salarios", remuneracion = "Remuneraci\u00f3n de los asalariados",
                      cotizaciones = "Cotizaciones sociales a cargo de los empleadores", personas = "Personas")

hist_descargar_ine_cne <- function(id, dir = file.path("datos", "brutos", "ine_cne"), forzar = FALSE) {
  hist_descargar_entera(sprintf("https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/%s.csv?nocab=1", id),
                        file.path(dir, paste0(id, ".csv")), hist_csv_ine_entero, forzar = forzar)
}

# Un CSV de jaxiT3 está entero si acaba en salto de línea y su última fila tiene tantos campos como
# la cabecera (el 10-nov-2026, la tabla 71129 llegó cortada a mitad de una fila, sin error).
hist_csv_ine_entero <- function(ruta) {
  tam <- file.size(ruta)
  if (is.na(tam) || tam < 100) return(FALSE)
  con <- file(ruta, open = "rb")
  on.exit(close(con))
  cabecera <- readLines(con, n = 1L, warn = FALSE)
  seek(con, max(0, tam - 4096))
  cola <- rawToChar(readBin(con, "raw", 4096L))
  if (!endsWith(cola, "\n")) return(FALSE)
  lineas <- strsplit(cola, "\r?\n")[[1]]
  ultima <- utils::tail(lineas[nzchar(lineas)], 1)
  cuenta <- function(x) lengths(regmatches(x, gregexpr(";", x, fixed = TRUE)))
  length(ultima) == 1L && cuenta(ultima) == cuenta(cabecera)
}

# Número en formato español («3.127.790», «22.123,8»); vacío o «..», NA.
hist_numero_es <- function(x) {
  x <- trimws(x)
  x[x %in% c("", "..", ".", "-")] <- NA_character_
  suppressWarnings(as.numeric(gsub(",", ".", gsub(".", "", x, fixed = TRUE), fixed = TRUE)))
}

# Una tabla de la CNE: medida, situacion (asalariados o total; NA en los agregados), rama («total»
# o el código de la agrupación A10, como «GHI»), anio y valor. Las ramas más finas (A21, A64) se
# dejan fuera.
hist_leer_ine_cne <- function(ruta) {
  x <- readr::read_delim(ruta, delim = ";", col_types = readr::cols(.default = "c"), na = character(),
                         locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
  n <- ncol(x)
  if (!n %in% c(7L, 8L)) stop("Tabla de la CNE con ", n, " columnas: ", ruta, call. = FALSE)
  a10 <- x[[n - 4L]]; a21 <- x[[n - 3L]]; a64 <- x[[n - 2L]]
  total <- !nzchar(a10) & !nzchar(a21) & !nzchar(a64)
  rama10 <- nzchar(a10) & !nzchar(a21) & !nzchar(a64)
  quedan <- total | rama10
  anio <- suppressWarnings(as.integer(substr(trimws(x[[n - 1L]]), 1, 4)))
  if (anyNA(anio[quedan])) stop("Periodos que no se leen en ", basename(ruta), call. = FALSE)
  tibble::tibble(
    medida = x[[1]], situacion = if (n == 8L) x[[2]] else NA_character_,
    rama = ifelse(total, "total", sub(" .*$", "", a10)), anio = anio, valor = hist_numero_es(x[[n]])
  )[quedan, ]
}

# Sueldo bruto medio por asalariado (€ al año), España, desde el primer año con los dos términos.
hist_sueldo_asalariado <- function(agregados, empleo) {
  s <- agregados[agregados$medida == HIST_MEDIDAS_CNE[["sueldos"]] & agregados$rama == "total", c("anio", "valor")]
  p <- empleo[empleo$medida == HIST_MEDIDAS_CNE[["personas"]] & empleo$situacion %in% "Asalariados" &
                empleo$rama == "total", c("anio", "valor")]
  if (!nrow(s) || !nrow(p)) stop("La CNE no trae sueldos y salarios o personas asalariadas del total", call. = FALSE)
  d <- dplyr::inner_join(s, p, by = "anio", suffix = c("_sueldos", "_personas")) |> dplyr::arrange(anio)
  hist_columnas(tibble::tibble(serie = "sueldo_asalariado", geo_id = "00", nivel = "nacional", frecuencia = "anual",
                               anio = d$anio, subperiodo = 0L, valor = d$valor_sueldos * 1000 / d$valor_personas,
                               unidad = "euros_anio", fuente = "ine_cne", codigo = paste(HIST_TABLAS_CNE, collapse = "/")))
}

# Compuerta de la lectura de la CNE (hist_salarios_suma, bloqueo, ±1 en millones de euros o en miles
# de personas): por año, la remuneración de los asalariados frente a sueldos y salarios más
# cotizaciones, y el total de la economía frente a la suma de las diez ramas A10 (sueldos y personas
# asalariadas). Una columna mal leída o una rama perdida descuadran.
hist_comprobar_ine_cne <- function(agregados, empleo) {
  tot <- function(d, medida, situacion = NULL) {
    d <- d[d$medida == medida & d$rama == "total" & (is.null(situacion) | d$situacion %in% situacion), ]
    stats::setNames(d$valor, d$anio)
  }
  ramas <- function(d, medida, situacion = NULL) {
    d <- d[d$medida == medida & d$rama != "total" & (is.null(situacion) | d$situacion %in% situacion), ]
    tapply(d$valor, d$anio, sum)
  }
  maximo <- function(a, b) {
    k <- union(names(a), names(b))
    if (!length(k)) return(NA_real_)
    max(abs(a[k] - b[k]))
  }
  rem <- tot(agregados, HIST_MEDIDAS_CNE[["remuneracion"]])
  sue <- tot(agregados, HIST_MEDIDAS_CNE[["sueldos"]])
  cot <- tot(agregados, HIST_MEDIDAS_CNE[["cotizaciones"]])
  per <- tot(empleo, HIST_MEDIDAS_CNE[["personas"]], "Asalariados")
  tibble::tibble(
    id = "hist_salarios_suma", anio = NA_integer_,
    detalle = c("remuneraci\u00f3n frente a sueldos m\u00e1s cotizaciones (millones de euros)",
                "sueldos: total frente a la suma de las ramas A10 (millones de euros)",
                "personas asalariadas: total frente a la suma de las ramas A10 (miles)"),
    calculado = c(maximo(rem, sue[names(rem)] + cot[names(rem)]), maximo(sue, ramas(agregados, HIST_MEDIDAS_CNE[["sueldos"]])),
                  maximo(per, ramas(empleo, HIST_MEDIDAS_CNE[["personas"]], "Asalariados"))),
    referencia = 0
  )
}
