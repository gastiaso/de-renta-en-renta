# Qué falta en datos/brutos/ antes de lanzar tar_make() (backlog, tarea 58: reproducir en limpio;
# docs/reproducir.md). Solo mira el disco: no descarga nada ni lee objetivos de targets.
#
# Tres grupos:
#   manual      descarga manual (inventario/descargas_manuales.csv, tipo «manual»): si falta,
#               tar_make() se detiene en su objetivo y dice qué bajar;
#   copiado     fichero que se trajo de fuera del pipeline y que el pipeline sabe bajar de la fuente
#               (tipo «copiado»): si falta, se descarga;
#   automatica  el resto de fuentes del calendario (inventario/calendario_fuentes.csv, columna
#               `ficheros`): si faltan, tar_make() las descarga.
# Las de tipo «portales» solo cuentan con PORTALES=TRUE, y las de `con_provincia` FALSE no cuentan
# con PROVINCIA (el bloque que las lee no entra).
#
# Uso, desde la raíz del proyecto (no hace falta cargar targets):
#   source("R/brutos_comprobar.R"); brutos_informe(brutos_comprobar())

BRUTOS_DIR <- file.path("datos", "brutos")
BRUTOS_GRUPOS <- c(manual = "manual", copiado = "copiado", portales = "manual")

brutos_leer_csv <- function(ruta) {
  utils::read.csv(ruta, colClasses = "character", fileEncoding = "UTF-8", na.strings = "",
                  check.names = FALSE)
}

# Ficheros de `carpeta` (relativa a datos/brutos/) cuyo nombre casa con `patron`.
brutos_ficheros_patron <- function(raiz, carpeta, patron) {
  dir <- file.path(raiz, BRUTOS_DIR, carpeta)
  if (!dir.exists(dir)) return(character(0))
  list.files(dir, pattern = patron, full.names = TRUE)
}

# Ficheros de una entrada de la columna `ficheros` del calendario: un comodín
# («datos/brutos/ine_adrh/*.csv»), un fichero o una carpeta acabada en «/» (todo lo que tenga dentro).
brutos_ficheros_calendario <- function(raiz, entrada) {
  entrada <- trimws(entrada)
  if (grepl("/$", entrada)) {
    dir <- file.path(raiz, sub("/$", "", entrada))
    if (!dir.exists(dir)) return(character(0))
    return(list.files(dir, recursive = TRUE, full.names = TRUE))
  }
  f <- Sys.glob(file.path(raiz, entrada))
  f[!dir.exists(f)]
}

# Una fila por descarga manual o copiada y por fuente automática del calendario: si hace falta en
# esta pasada (`necesaria`), cuántos ficheros hay, cuánto ocupan, si está (`presente`) y qué pasa
# si falta (`si_falta`).
brutos_comprobar <- function(raiz = ".",
                             portales = identical(toupper(Sys.getenv("PORTALES", "FALSE")), "TRUE"),
                             provincia = Sys.getenv("PROVINCIA", ""),
                             manuales = brutos_leer_csv(file.path(raiz, "inventario", "descargas_manuales.csv")),
                             calendario = brutos_leer_csv(file.path(raiz, "inventario", "calendario_fuentes.csv"))) {
  desconocidos <- setdiff(manuales$tipo, names(BRUTOS_GRUPOS))
  if (length(desconocidos)) stop("Tipo de descarga desconocido: ", paste(desconocidos, collapse = ", "), call. = FALSE)

  filas_manuales <- lapply(seq_len(nrow(manuales)), function(i) {
    m <- manuales[i, ]
    f <- brutos_ficheros_patron(raiz, m$carpeta, m$patron)
    necesaria <- (m$tipo != "portales" || portales) && (provincia == "" || isTRUE(as.logical(m$con_provincia)))
    data.frame(
      grupo = unname(BRUTOS_GRUPOS[m$tipo]), id = m$id, fuente = m$fuente,
      ruta = file.path(BRUTOS_DIR, m$carpeta, gsub(";", " ; ", m$guardar_como, fixed = TRUE)),
      necesaria = necesaria, ficheros = length(f), bytes = sum(file.size(f)),
      presente = length(f) >= as.integer(m$minimo),
      si_falta = if (m$tipo == "copiado") paste("se descarga de", m$pagina)
                 else paste("tar_make() se detiene: bajarlo de", m$pagina, "y guardarlo como", m$guardar_como),
      stringsAsFactors = FALSE
    )
  })

  # Las fuentes con descarga manual o de portales salen arriba, fichero a fichero.
  cubiertas <- unique(manuales$fuente[manuales$tipo != "copiado"])
  cal <- calendario[!calendario$id %in% cubiertas & !is.na(calendario$ficheros), ]
  filas_calendario <- lapply(seq_len(nrow(cal)), function(i) {
    f <- unique(unlist(lapply(strsplit(cal$ficheros[i], ";", fixed = TRUE)[[1]],
                              function(e) brutos_ficheros_calendario(raiz, e))))
    data.frame(
      grupo = "automatica", id = cal$id[i], fuente = cal$id[i], ruta = gsub(";", " ; ", cal$ficheros[i], fixed = TRUE),
      necesaria = TRUE, ficheros = length(f), bytes = sum(file.size(f)), presente = length(f) > 0,
      si_falta = paste("se descarga (objetivos:", gsub(";", ", ", cal$objetivos[i], fixed = TRUE), ")"),
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, c(filas_manuales, filas_calendario))
  out$grupo <- factor(out$grupo, levels = c("manual", "copiado", "automatica"))
  out <- out[order(out$grupo, out$id), ]
  out$grupo <- as.character(out$grupo)
  rownames(out) <- NULL
  out
}

# Resumen en la consola. Devuelve, invisible, una lista con `lista` (no falta ninguna descarga
# manual: tar_make() puede arrancar), `completa` (no falta nada: no descargará nada) y las filas
# que faltan.
brutos_informe <- function(comprobacion = brutos_comprobar()) {
  faltan <- comprobacion[comprobacion$necesaria & !comprobacion$presente, ]
  manuales <- faltan[faltan$grupo == "manual", ]
  mb <- function(b) format(round(b / 1e6, 1), big.mark = ".", decimal.mark = ",", nsmall = 1)
  presentes <- comprobacion[comprobacion$presente, ]
  cat("datos/brutos/: ", nrow(presentes), " de ", nrow(comprobacion), " entradas presentes (",
      mb(sum(presentes$bytes)), " MB)\n", sep = "")
  for (g in c("manual", "copiado", "automatica")) {
    x <- faltan[faltan$grupo == g, ]
    if (!nrow(x)) next
    titulo <- c(manual = "Faltan descargas manuales (tar_make() se detendría):",
                copiado = "Faltan ficheros que se trajeron de fuera (el pipeline los bajará de la fuente):",
                automatica = "Faltan fuentes automáticas (el pipeline las bajará):")[[g]]
    cat("\n", titulo, "\n", sep = "")
    for (i in seq_len(nrow(x))) cat("  - ", x$id[i], ": ", x$ruta[i], "\n      ", x$si_falta[i], "\n", sep = "")
  }
  no_hacen_falta <- comprobacion$id[!comprobacion$necesaria]
  if (length(no_hacen_falta)) cat("\nNo hacen falta en esta pasada: ", paste(no_hacen_falta, collapse = ", "), "\n", sep = "")
  lista <- nrow(manuales) == 0
  completa <- nrow(faltan) == 0
  cat("\n", if (completa) "Completa: tar_make() no tiene nada que descargar."
            else if (lista) "Lista para tar_make(): no falta ninguna descarga manual; el resto se descargará."
            else "No está lista: faltan descargas manuales.", "\n", sep = "")
  invisible(list(lista = lista, completa = completa, faltan = faltan))
}
