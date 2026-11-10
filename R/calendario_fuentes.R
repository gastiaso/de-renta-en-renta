# Calendario de fuentes y actualizaciones (F6, plan §7 y §8): inventario/calendario_fuentes.csv,
# una fila por fuente del pipeline, con su cadencia, los meses y el día habituales de publicación,
# el desfase entre el final del periodo y su publicación, el último dato que tiene el atlas, los
# objetivos que la descargan, sus ficheros en datos/brutos/ y cómo se renueva:
#   mover     la edición nueva reescribe los mismos ficheros: cal_actualizar() los aparta a
#             datos/brutos/_anteriores/<fecha>/ y el siguiente tar_make() los vuelve a bajar;
#   invalidar el objetivo de descarga se vuelve a ejecutar (CIS: busca los barómetros nuevos);
#   codigo    hay que tocar una constante de _targets.R (un año o un periodo nuevos);
#   manual    descarga a mano (la fuente no deja hacerla de forma automática);
#   fija      no se renueva con el calendario (geometrías y tablas de paso).
#
# Una fuente «toca» si desde su última descarga (el fichero más reciente) ha pasado una fecha de
# publicación esperable, o si a la fecha de hoy ya debería estar publicado un periodo posterior al
# último que tiene el atlas (desfase). Lo dice cal_fuentes_pendientes(); el objetivo
# fuentes_pendientes avisa (y deja la lista en datos/intermedios/calendario/pendientes.csv) cada vez
# que cambia el conjunto de fuentes que tocan: su señal (tar_cue_force) se evalúa al leer _targets.R.
# Procedimiento: docs/actualizacion.md.

CAL_RUTA <- file.path("inventario", "calendario_fuentes.csv")
CAL_ESTADO <- file.path("datos", "intermedios", "calendario", "pendientes.csv")
CAL_CADENCIAS <- c("mensual", "trimestral", "semestral", "anual", "decenal", "unica", "continua")
CAL_RENOVAR <- c("mover", "invalidar", "codigo", "manual", "fija")

cal_leer_calendario <- function(ruta = CAL_RUTA) {
  readr::read_csv(ruta, col_types = readr::cols(.default = readr::col_character(),
                                                dia_publicacion = readr::col_integer(),
                                                desfase_dias = readr::col_integer()),
                  locale = readr::locale(encoding = "UTF-8"), progress = FALSE)
}

# «1-7;9-12» -> 1:7, 9:12. Vacio -> integer(0).
cal_meses <- function(texto) {
  if (is.na(texto) || !nzchar(trimws(texto))) return(integer(0))
  partes <- strsplit(trimws(texto), ";", fixed = TRUE)[[1]]
  sort(unique(unlist(lapply(partes, function(p) {
    lim <- as.integer(strsplit(trimws(p), "-", fixed = TRUE)[[1]])
    if (length(lim) == 1) lim else seq(lim[1], lim[2])
  }))))
}

# Fecha de un dia del mes, recortado al ultimo dia si el mes es mas corto.
cal_fecha <- function(anio, mes, dia) {
  primero <- as.Date(sprintf("%d-%02d-01", anio, mes))
  ultimo <- seq(primero, by = "month", length.out = 2)[2] - 1
  min(primero + (dia - 1L), ultimo)
}

# Primera fecha de publicacion esperable posterior a `desde` (NA si la fuente no tiene calendario).
cal_proxima_edicion <- function(desde, meses, dia) {
  if (length(meses) == 0 || is.na(dia) || is.na(desde)) return(as.Date(NA))
  anio <- as.integer(format(desde, "%Y"))
  for (a in anio + 0:2) for (m in meses) {
    f <- cal_fecha(a, m, dia)
    if (f > desde) return(f)
  }
  as.Date(NA)
}

# Ficheros de una fila, relativos a `raiz`: patrones separados por «;». Un patrón que acaba en «/»
# es una carpeta (se recorre entera); si no, un comodín de Sys.glob(). Sin las descargas a medias.
cal_ficheros <- function(ficheros, raiz = ".") {
  if (is.na(ficheros) || !nzchar(trimws(ficheros))) return(character(0))
  patrones <- trimws(strsplit(ficheros, ";", fixed = TRUE)[[1]])
  rutas <- unlist(lapply(patrones, function(p) {
    if (grepl("/$", p)) {
      file.path(sub("/+$", "", p), list.files(file.path(raiz, p), recursive = TRUE))
    } else {
      encontrados <- Sys.glob(file.path(raiz, p))
      substring(encontrados, nchar(raiz) + 2L)
    }
  }))
  rutas[!grepl("\\.parcial$", rutas)]
}

# Ultima descarga: fecha del fichero mas reciente de la fila.
cal_ultima_descarga <- function(ficheros, raiz = ".") {
  rutas <- cal_ficheros(ficheros, raiz)
  if (length(rutas) == 0) return(as.Date(NA))
  as.Date(max(file.mtime(file.path(raiz, rutas)), na.rm = TRUE))
}

# Periodos: «AAAA» (anual), «AAAA-Tn» (trimestral), «AAAA-MM» (mensual o semestral).
cal_periodo_inicio <- function(periodo) {
  if (grepl("^[0-9]{4}$", periodo)) return(as.Date(paste0(periodo, "-01-01")))
  if (grepl("^[0-9]{4}-T[1-4]$", periodo)) {
    return(as.Date(sprintf("%s-%02d-01", substr(periodo, 1, 4), 3L * as.integer(substr(periodo, 7, 7)) - 2L)))
  }
  if (grepl("^[0-9]{4}-[0-9]{2}$", periodo)) return(as.Date(paste0(periodo, "-01")))
  stop("Calendario: periodo no reconocido: ", periodo, call. = FALSE)
}

cal_periodo_meses <- function(periodo) {
  if (grepl("^[0-9]{4}$", periodo)) 12L else if (grepl("-T", periodo, fixed = TRUE)) 3L else 1L
}

cal_periodo_fin <- function(periodo) {
  seq(cal_periodo_inicio(periodo), by = paste(cal_periodo_meses(periodo), "months"), length.out = 2)[2] - 1
}

cal_periodo_texto <- function(inicio, formato) {
  anio <- format(inicio, "%Y")
  mes <- as.integer(format(inicio, "%m"))
  if (grepl("^[0-9]{4}$", formato)) anio
  else if (grepl("-T", formato, fixed = TRUE)) sprintf("%s-T%d", anio, (mes - 1L) %/% 3L + 1L)
  else sprintf("%s-%02d", anio, mes)
}

# Periodo siguiente con dato (en los mensuales y semestrales, solo los meses de `meses_dato`).
cal_periodo_siguiente <- function(periodo, meses_dato = integer(0)) {
  inicio <- cal_periodo_inicio(periodo)
  paso <- cal_periodo_meses(periodo)
  for (k in 1:24) {
    siguiente <- seq(inicio, by = paste(paso * k, "months"), length.out = 2)[2]
    if (paso != 1L || length(meses_dato) == 0 || as.integer(format(siguiente, "%m")) %in% meses_dato) {
      return(cal_periodo_texto(siguiente, periodo))
    }
  }
  NA_character_
}

# Ultimo periodo que deberia estar publicado a `hoy`: se avanza desde `ultimo` mientras el final del
# periodo siguiente mas el desfase no pase de hoy. NA sin dato o sin desfase.
cal_dato_esperado <- function(ultimo, desfase, meses_dato, hoy) {
  if (is.na(ultimo) || !nzchar(ultimo) || is.na(desfase)) return(NA_character_)
  periodo <- ultimo
  for (k in 1:60) {
    siguiente <- cal_periodo_siguiente(periodo, meses_dato)
    if (is.na(siguiente) || cal_periodo_fin(siguiente) + desfase > hoy) break
    periodo <- siguiente
  }
  periodo
}

# Que fuentes tocan a `hoy`. `ultimas`: fechas de la ultima descarga por fuente (con nombres); si
# falta, se miran los ficheros de cada fila (desde `raiz`). Las «fija» no tocan nunca.
cal_fuentes_pendientes <- function(calendario, hoy = Sys.Date(), ultimas = NULL, raiz = ".") {
  hoy <- as.Date(hoy)
  filas <- lapply(seq_len(nrow(calendario)), function(i) {
    f <- calendario[i, ]
    renovar <- strsplit(f$renovar, ";", fixed = TRUE)[[1]]
    ultima <- if (!is.null(ultimas) && f$id %in% names(ultimas)) as.Date(ultimas[[f$id]]) else cal_ultima_descarga(f$ficheros, raiz)
    proxima <- cal_proxima_edicion(ultima, cal_meses(f$meses_publicacion), f$dia_publicacion)
    esperado <- cal_dato_esperado(f$ultimo_dato, f$desfase_dias, cal_meses(f$meses_dato), hoy)
    fija <- "fija" %in% renovar
    edicion <- !fija && !is.na(proxima) && proxima <= hoy
    atrasada <- !fija && !is.na(esperado) && !identical(esperado, f$ultimo_dato)
    tibble::tibble(id = f$id, ultima_descarga = ultima, proxima_edicion = proxima,
                   ultimo_dato = f$ultimo_dato, dato_esperado = esperado,
                   edicion_nueva = edicion, dato_nuevo = atrasada, toca = edicion | atrasada,
                   renovar = f$renovar, objetivos = f$objetivos, cambio_codigo = f$cambio_codigo)
  })
  dplyr::bind_rows(filas)
}

# ¿Toca una fuente? (para la señal de su objetivo de descarga). Nunca da error: si el calendario
# no se puede leer, FALSE (la compuerta del calendario lo dira).
cal_toca <- function(id, ruta = CAL_RUTA, hoy = Sys.Date()) {
  tryCatch({
    cal <- cal_leer_calendario(ruta)
    p <- cal_fuentes_pendientes(cal[cal$id == id, ], hoy = hoy)
    nrow(p) == 1 && isTRUE(p$toca)
  }, error = function(e) FALSE)
}

# Conjunto de fuentes que tocan, en texto («id:edicion|dato»), para compararlo con el guardado.
cal_firma <- function(pendientes) {
  p <- pendientes[pendientes$toca, ]
  if (nrow(p) == 0) return(character(0))
  sort(paste0(p$id, ":", ifelse(p$edicion_nueva, "edicion", ""), ifelse(p$dato_nuevo, paste0("dato ", p$dato_esperado), "")))
}

# Señal del objetivo fuentes_pendientes: TRUE si el conjunto de fuentes que tocan hoy no es el que
# dejo la ultima pasada (o si no hay pasada). Se evalua al leer _targets.R: nunca da error.
cal_hay_cambios <- function(ruta = CAL_RUTA, estado = CAL_ESTADO, hoy = Sys.Date()) {
  tryCatch({
    if (!file.exists(estado)) return(TRUE)
    actual <- cal_firma(cal_fuentes_pendientes(cal_leer_calendario(ruta), hoy = hoy))
    guardado <- readr::read_csv(estado, col_types = readr::cols(.default = "c"), progress = FALSE)
    !identical(actual, sort(guardado$firma))
  }, error = function(e) TRUE)
}

# Objetivo fuentes_pendientes: guarda la lista y avisa de lo que toca y de como renovarlo.
cal_avisar_pendientes <- function(pendientes, estado = CAL_ESTADO) {
  dir.create(dirname(estado), recursive = TRUE, showWarnings = FALSE)
  p <- pendientes[pendientes$toca, ]
  firma <- cal_firma(pendientes)
  readr::write_csv(tibble::tibble(firma = firma, id = sub(":.*$", "", firma)), estado)
  if (nrow(p) > 0) {
    lineas <- paste0("  ", p$id, ": ",
                     ifelse(p$edicion_nueva, paste0("edici\u00f3n esperable desde el ", format(p$proxima_edicion)), ""),
                     ifelse(p$edicion_nueva & p$dato_nuevo, "; ", ""),
                     ifelse(p$dato_nuevo, paste0("deber\u00eda haber dato de ", p$dato_esperado, " (el atlas llega a ", p$ultimo_dato, ")"), ""),
                     " [", p$renovar, "]",
                     ifelse(is.na(p$cambio_codigo), "", paste0("; c\u00f3digo: ", p$cambio_codigo)))
    warning("Calendario de fuentes: tocan ", nrow(p), " fuentes (docs/actualizacion.md):\n",
            paste(lineas, collapse = "\n"),
            "\n  Para renovar las de tipo mover o invalidar: cal_actualizar(c(\"",
            paste(p$id[grepl("mover|invalidar", p$renovar)], collapse = "\", \""), "\"), ejecutar = TRUE)",
            call. = FALSE)
  }
  pendientes
}

# Renovar fuentes (fuera de tar_make()). Sin `ejecutar`, solo dice lo que haria. Con «mover», los
# ficheros de la fuente pasan a datos/brutos/_anteriores/<hoy>/ (se recuperan con
# cal_restaurar()); con «invalidar», tar_invalidate() de sus objetivos; «codigo» y «manual» solo se
# indican. Despues: targets::tar_make().
cal_actualizar <- function(ids = NULL, ejecutar = FALSE, hoy = Sys.Date(), ruta = CAL_RUTA, raiz = ".") {
  cal <- cal_leer_calendario(ruta)
  pend <- cal_fuentes_pendientes(cal, hoy = hoy, raiz = raiz)
  if (is.null(ids)) ids <- pend$id[pend$toca]
  desconocidas <- setdiff(ids, cal$id)
  if (length(desconocidas) > 0) stop("Calendario: fuentes desconocidas: ", paste(desconocidas, collapse = ", "), call. = FALSE)
  archivo <- file.path(raiz, "datos", "brutos", "_anteriores", format(as.Date(hoy)))
  plan <- lapply(ids, function(id) {
    f <- cal[cal$id == id, ]
    renovar <- strsplit(f$renovar, ";", fixed = TRUE)[[1]]
    acciones <- character(0)
    if ("mover" %in% renovar) {
      rutas <- cal_ficheros(f$ficheros, raiz)
      acciones <- c(acciones, sprintf("apartar %d ficheros a %s", length(rutas), archivo))
      if (ejecutar && length(rutas) > 0) {
        destino <- file.path(archivo, rutas)
        for (k in seq_along(rutas)) {
          dir.create(dirname(destino[k]), recursive = TRUE, showWarnings = FALSE)
          if (!file.rename(file.path(raiz, rutas[k]), destino[k])) {
            stop("Calendario: no se puede apartar ", rutas[k], call. = FALSE)
          }
        }
      }
    }
    if ("invalidar" %in% renovar) {
      objetivos <- trimws(strsplit(f$objetivos, ";", fixed = TRUE)[[1]])
      acciones <- c(acciones, paste("invalidar", paste(objetivos, collapse = ", ")))
      if (ejecutar) targets::tar_invalidate(tidyselect::any_of(objetivos))
    }
    if ("codigo" %in% renovar) acciones <- c(acciones, paste("c\u00f3digo:", f$cambio_codigo))
    if ("manual" %in% renovar) acciones <- c(acciones, "descarga manual (inventario/fuentes.csv, columna acceso)")
    tibble::tibble(id = id, acciones = paste(acciones, collapse = "; "))
  })
  plan <- dplyr::bind_rows(plan)
  message(paste0(if (ejecutar) "Hecho" else "Plan (sin ejecutar)", ":\n",
                 paste0("  ", plan$id, ": ", plan$acciones, collapse = "\n"),
                 "\nDespu\u00e9s: targets::tar_make()"))
  invisible(plan)
}

# Devuelve a datos/brutos/ los ficheros apartados en una fecha que no se hayan vuelto a bajar.
cal_restaurar <- function(fecha, raiz = ".") {
  archivo <- file.path(raiz, "datos", "brutos", "_anteriores", fecha)
  rutas <- list.files(archivo, recursive = TRUE)
  destino <- file.path(raiz, rutas)
  faltan <- !file.exists(destino)
  for (k in which(faltan)) {
    dir.create(dirname(destino[k]), recursive = TRUE, showWarnings = FALSE)
    file.rename(file.path(archivo, rutas[k]), destino[k])
  }
  invisible(rutas[faltan])
}

# Compuerta del calendario (inventario/referencias_validacion.csv):
#   calendario_fuentes (bloqueo): fuentes que no están en inventario/fuentes.csv, filas repetidas,
#     cadencias o formas de renovar fuera del vocabulario, meses o días imposibles, periodos que no
#     se entienden y filas «mover» sin ficheros;
#   calendario_descargas (alerta): fuentes renovables sin ningún fichero descargado.
cal_comprobar_calendario <- function(calendario, fuentes, raiz = ".") {
  renovar <- strsplit(calendario$renovar, ";", fixed = TRUE)
  meses_ok <- vapply(seq_len(nrow(calendario)), function(i) {
    m <- tryCatch(c(cal_meses(calendario$meses_publicacion[i]), cal_meses(calendario$meses_dato[i])), error = function(e) 0L)
    all(m %in% 1:12)
  }, logical(1))
  periodo_ok <- vapply(calendario$ultimo_dato, function(p) {
    is.na(p) || !nzchar(p) || !inherits(tryCatch(cal_periodo_inicio(p), error = function(e) e), "error")
  }, logical(1))
  problemas <- c(
    "fuentes fuera de inventario/fuentes.csv" = sum(!calendario$id %in% fuentes$id),
    "fuentes repetidas" = sum(duplicated(calendario$id)),
    "cadencias fuera del vocabulario" = sum(!calendario$cadencia %in% CAL_CADENCIAS),
    "formas de renovar fuera del vocabulario" = sum(!vapply(renovar, function(r) all(r %in% CAL_RENOVAR), logical(1))),
    "meses imposibles" = sum(!meses_ok),
    "d\u00edas imposibles" = sum(!is.na(calendario$dia_publicacion) & !calendario$dia_publicacion %in% 1:31),
    "periodos sin formato" = sum(!periodo_ok),
    "filas mover sin ficheros" = sum(vapply(renovar, function(r) "mover" %in% r, logical(1)) & is.na(calendario$ficheros)),
    "filas con calendario a medias" = sum(xor(is.na(calendario$meses_publicacion), is.na(calendario$dia_publicacion)))
  )
  bloqueo <- tibble::tibble(id = "calendario_fuentes", anio = NA_integer_, detalle = names(problemas),
                            calculado = as.numeric(problemas), referencia = 0)
  renovables <- calendario[!vapply(renovar, function(r) all(r %in% c("fija", "manual")), logical(1)), ]
  sin <- renovables$id[is.na(vapply(renovables$ficheros, cal_ultima_descarga, as.Date(NA), raiz = raiz))]
  alerta <- tibble::tibble(id = "calendario_descargas", anio = NA_integer_,
                           detalle = if (length(sin)) paste("sin ficheros:", sin) else "todas con ficheros",
                           calculado = if (length(sin)) 1 else 0, referencia = 0)
  dplyr::bind_rows(bloqueo, alerta)
}
