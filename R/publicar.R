# Publicación en GitHub Pages (docs/publicacion.md; plan §6.6 y §11, preguntas abiertas 16 y 21).
#
# empaquetar_publicacion() prepara en publicacion/ (fuera de git) los ficheros del release que el
# flujo de Pages (.github/workflows/pages.yml) copia junto a web/:
#   - datos_web.tar.gz: web/datos/ sin la muestra (datos/ejemplo/ va en git), con las rutas desde
#     web/ (datos/manifiesto.json…), para descomprimir en la raíz del sitio. En .tar.gz porque R
#     lo escribe sin programas externos (utils::tar interno) y el flujo lo abre con tar;
#   - el mapa base en PMTiles, con el nombre que pide el manifiesto (mapa_base.url, hoy
#     teselas/seccionado_2021.pmtiles);
#   - tabla_larga.parquet: la tabla larga validada, para la descarga de la página «Datos» (el flujo
#     la deja en descargas/);
#   - historico.parquet: la tabla del módulo histórico (series de España y comunidades desde 1987),
#     también en descargas/ (plan §11, pregunta 47 a: entra en el paquete de la v1.0);
#   - version.json: fecha, commit, versiones de las fuentes, cobertura de la tabla larga por
#     indicador (filas, años, niveles y cortes; la muestra la página «Datos») y tamaño y suma de
#     cada fichero;
#   - SHA256SUMS: sumas SHA-256 de los cinco anteriores, en el formato de sha256sum (el flujo las
#     comprueba con sha256sum --check antes de montar el sitio).
#
# No entra en el tar_make() por defecto: se ejecuta a mano, con la exportación de la web y la tabla
# larga ya al día, cuando se quiere publicar:
#   empaquetar_publicacion()
#
# Comprobaciones (si falla alguna, borra lo escrito y se detiene):
#   - release_fichero: cada fichero del release, por debajo de 2 GiB (límite de GitHub por recurso);
#   - sitio_total: el sitio montado (web/ como queda en git, más lo del release), por debajo de 1 GB
#     (límite de Pages);
#   - sitio_fichero: ningún fichero del sitio por encima de 100 MiB (límite de git, que se mantiene
#     también en el sitio);
#   - manifiesto: exportación real (ejemplo = false) con mapa base PMTiles en teselas/;
#   - formato: el PMTiles empieza por «PMTiles» y los Parquet empiezan y acaban por «PAR1»;
#   - tar_completo: el .tar.gz lleva todos los ficheros de datos/ (salvo la capa de portales), y solo esos;
#   - versiones: cada fuente y versión del manifiesto está en la tabla larga (la exportación de la
#     web y la tabla larga son de la misma pasada del pipeline);
#   - sin_portales (tarea 35; backlog, decisión 3): el paquete no lleva la capa de portales: ni
#     datos/portales/ en el .tar.gz, ni series de los portales en el manifiesto, ni el corte
#     oferta_privada o la fuente portales en la tabla larga. La capa sale de web/datos/portales/
#     y se monta en el sitio por su cuenta (docs/publicacion.md, «Capa de portales»).

LIMITES_PUBLICACION <- c(
  release_fichero = 2 * 1024^3,    # «Each file included in a release must be under 2 GiB»
  sitio_total = 1e9,               # «Published GitHub Pages sites may be no larger than 1 GB»
  sitio_fichero = 100 * 1024^2     # git rechaza ficheros de más de 100 MiB
)
# Herramientas de desarrollo de web/ que no se publican (el flujo las borra al montar el sitio)
EXCLUIDOS_SITIO <- c("LEEME.md", "servir.mjs", "herramientas")
FICHEROS_RELEASE <- c(datos = "datos_web.tar.gz", tabla = "tabla_larga.parquet", historico = "historico.parquet",
                      version = "version.json", sumas = "SHA256SUMS")
# Licencias del paquete (version.json): la general de los datos y las excepciones por fuente. Las
# filas de Registradores (indicador 11) siguen su licencia, la ODbL 1.0 (LICENCIA_DATOS.md).
LICENCIAS_PUBLICACION <- list(
  datos = "CC BY-SA 4.0 (LICENCIA_DATOS.md)",
  excepciones = list(registradores = paste("ODbL 1.0 (Open Database License): las filas de la fuente registradores",
                                           "(indicador 11) y lo que derive de ellas; LICENCIA_DATOS.md")),
  codigo = "MIT (LICENSE)"
)
DESTINO_DESCARGAS <- "descargas"   # carpeta del sitio con la tabla larga y version.json

# Paquete del release en dir_salida. `commit`: lista con `id` y `cambios_sin_commit`
# (commit_publicacion()). `limites`: los de LIMITES_PUBLICACION (las pruebas los bajan).
empaquetar_publicacion <- function(dir_web = "web",
                                   pmtiles = "geo/referencia/mapa_base_2021.pmtiles",
                                   tabla_larga = "datos/intermedios/tabla_larga.parquet",
                                   historico = "datos/intermedios/historico.parquet",
                                   dir_salida = "publicacion",
                                   fuentes = "inventario/fuentes.csv",
                                   indicadores = "inventario/indicadores.csv",
                                   commit = commit_publicacion(),
                                   fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                                   limites = LIMITES_PUBLICACION) {
  manifiesto_ruta <- file.path(dir_web, "datos", "manifiesto.json")
  for (ruta in c(manifiesto_ruta, pmtiles, tabla_larga, historico)) {
    if (!file.exists(ruta)) {
      stop("Falta ", ruta, ". Antes de empaquetar: targets::tar_make() (o, solo la web, ",
           "targets::tar_make(names = c(ficheros_web, validacion_web))).", call. = FALSE)
    }
  }
  manifiesto <- jsonlite::fromJSON(manifiesto_ruta, simplifyVector = FALSE)
  url_mapa <- manifiesto$mapa_base$url %||% ""
  nombre_mapa <- basename(url_mapa)

  # Salida: solo ficheros de este paquete, para que «gh release create … publicacion/*» no suba nada más
  dir.create(dir_salida, recursive = TRUE, showWarnings = FALSE)
  previos <- list.files(dir_salida, all.files = TRUE, no.. = TRUE)
  ajenos <- setdiff(previos, c(FICHEROS_RELEASE, list.files(dir_salida, pattern = "\\.pmtiles$")))
  if (length(ajenos)) {
    stop(dir_salida, "/ tiene ficheros que no son del paquete: ", paste(ajenos, collapse = ", "),
         ". Bórralos antes de empaquetar.", call. = FALSE)
  }
  unlink(file.path(dir_salida, previos), recursive = TRUE)

  datos <- ficheros_datos_publicacion(dir_web)
  salida <- c(datos = file.path(dir_salida, FICHEROS_RELEASE[["datos"]]),
              mapa = file.path(dir_salida, if (nzchar(nombre_mapa)) nombre_mapa else "mapa_base.pmtiles"),
              tabla = file.path(dir_salida, FICHEROS_RELEASE[["tabla"]]),
              historico = file.path(dir_salida, FICHEROS_RELEASE[["historico"]]),
              version = file.path(dir_salida, FICHEROS_RELEASE[["version"]]),
              sumas = file.path(dir_salida, FICHEROS_RELEASE[["sumas"]]))
  correcto <- FALSE
  on.exit(if (!correcto) unlink(salida), add = TRUE)

  tar_datos_publicacion(dir_web, datos, salida[["datos"]])
  copiar <- function(de, a) if (!file.copy(de, a, overwrite = TRUE)) stop("No se ha podido copiar ", de, call. = FALSE)
  copiar(pmtiles, salida[["mapa"]])
  copiar(tabla_larga, salida[["tabla"]])
  copiar(historico, salida[["historico"]])

  release <- salida[c("datos", "mapa", "tabla", "historico")]
  sumas <- vapply(release, sha256_fichero, "")
  version <- version_publicacion(manifiesto, tabla_larga, fuentes, commit, fecha,
                                 ficheros = data.frame(nombre = basename(release), bytes = file.size(release),
                                                       sha256 = unname(sumas), destino = destino_publicacion(release, url_mapa)),
                                 indicadores = indicadores)
  escribir_texto_lf(jsonlite::toJSON(version, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null"),
                    salida[["version"]])
  sumas <- c(sumas, version = sha256_fichero(salida[["version"]]))
  escribir_texto_lf(paste0(sumas, "  ", basename(salida[names(sumas)])), salida[["sumas"]])

  sitio <- sitio_publicacion(dir_web, datos, salida, url_mapa)
  comprobaciones <- comprobar_publicacion(manifiesto, salida, datos, sitio, tabla_larga, limites)
  mal <- comprobaciones[!comprobaciones$correcto, ]
  if (nrow(mal)) {
    print(as.data.frame(mal), row.names = FALSE)
    stop("El paquete no pasa las comprobaciones: ", paste(unique(mal$id), collapse = ", "),
         ". No se ha dejado nada en ", dir_salida, "/.", call. = FALSE)
  }
  correcto <- TRUE

  message("Paquete del release en ", dir_salida, "/:")
  for (r in salida) message(sprintf("  %-26s %10s", basename(r), formato_bytes(file.size(r))))
  message(sprintf("Sitio montado: %s ficheros, %s (límite de Pages: %s)", format(nrow(sitio), big.mark = ".", decimal.mark = ","),
                  formato_bytes(sum(sitio$bytes)), formato_bytes(limites[["sitio_total"]])))
  if (isTRUE(commit$cambios_sin_commit)) {
    message("Aviso: hay cambios sin commit; version.json lo anota (commit$cambios_sin_commit).")
  }
  invisible(list(ficheros = unname(salida), comprobaciones = comprobaciones, version = version, sitio = sitio))
}

# Ficheros de web/datos/ que van al release, con la ruta desde web/: todo menos la muestra y la capa
# de portales (datos/portales/: solo web, decisión 3; R/web_portales.R).
CARPETAS_FUERA_RELEASE <- c("ejemplo/", "portales/")
ficheros_datos_publicacion <- function(dir_web = "web") {
  rutas <- list.files(file.path(dir_web, "datos"), recursive = TRUE, all.files = FALSE)
  fuera <- Reduce(`|`, lapply(CARPETAS_FUERA_RELEASE, function(c) startsWith(rutas, c)), FALSE)
  rutas <- sort(rutas[!fuera])
  file.path("datos", rutas)
}

# .tar.gz con el tar interno de R (sin programas externos), con las rutas desde dir_web.
tar_datos_publicacion <- function(dir_web, rutas, destino) {
  destino <- file.path(normalizePath(dirname(destino), winslash = "/", mustWork = TRUE), basename(destino))
  anterior <- setwd(dir_web)
  on.exit(setwd(anterior), add = TRUE)
  estado <- utils::tar(destino, files = rutas, compression = "gzip", tar = "internal")
  if (!identical(as.integer(estado), 0L)) stop("No se ha podido escribir ", destino, call. = FALSE)
  destino
}

sha256_fichero <- function(ruta) digest::digest(ruta, algo = "sha256", file = TRUE)

# Texto en UTF-8 con finales de línea LF también en Windows (sha256sum no admite CRLF en --strict).
escribir_texto_lf <- function(lineas, ruta) {
  writeBin(charToRaw(enc2utf8(paste0(paste(lineas, collapse = "\n"), "\n"))), ruta)
  ruta
}

# Dónde deja el flujo cada fichero del release en el sitio.
destino_publicacion <- function(rutas, url_mapa) {
  nombres <- basename(rutas)
  ifelse(nombres == FICHEROS_RELEASE[["datos"]], "datos/ (descomprimido)",
         ifelse(grepl("\\.pmtiles$", nombres), url_mapa, file.path(DESTINO_DESCARGAS, nombres)))
}

# Commit del repositorio y si hay cambios sin commit (también ficheros nuevos sin añadir). Sin git o
# fuera de un repositorio, NA.
commit_publicacion <- function(dir = ".") {
  git <- Sys.which("git")
  if (!nzchar(git)) return(list(id = NA_character_, cambios_sin_commit = NA))
  anterior <- setwd(dir)
  on.exit(setwd(anterior), add = TRUE)
  id <- suppressWarnings(tryCatch(system2(git, c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
                                  error = function(e) character()))
  if (length(id) != 1L || !grepl("^[0-9a-f]{40}$", id)) return(list(id = NA_character_, cambios_sin_commit = NA))
  cambios <- suppressWarnings(system2(git, c("status", "--porcelain"), stdout = TRUE, stderr = FALSE))
  list(id = id, cambios_sin_commit = length(cambios) > 0L)
}

# Contenido de version.json: fecha, commit, exportación de la web, fuentes de la tabla larga (con su
# versión, que es la fecha del fichero de origen, y su número de filas), cobertura por indicador
# (cobertura_publicacion(), en el orden del inventario `indicadores`), mapa base y ficheros.
version_publicacion <- function(manifiesto, tabla_larga, fuentes, commit, fecha, ficheros, indicadores = NULL) {
  por_fuente <- arrow::open_dataset(tabla_larga) |>
    dplyr::count(fuente, version, name = "filas") |>
    dplyr::collect() |>
    dplyr::arrange(fuente, version)
  if (!is.null(fuentes) && file.exists(fuentes)) {
    inventario <- readr::read_csv(fuentes, col_types = readr::cols(.default = "c"), progress = FALSE)
    por_fuente$nombre <- inventario$nombre[match(por_fuente$fuente, inventario$id)]
  }
  list(
    proyecto = "De renta en renta",
    fecha = fecha,
    commit = list(id = commit$id %||% NA_character_, cambios_sin_commit = commit$cambios_sin_commit %||% NA),
    web = list(version = manifiesto$version %||% NA_character_, generado = manifiesto$generado %||% NA_character_,
               seccionado = manifiesto$seccionado %||% NA_integer_),
    mapa_base = list(url = manifiesto$mapa_base$url %||% NA_character_,
                     atribucion = manifiesto$mapa_base$atribucion %||% NA_character_),
    fuentes = por_fuente,
    indicadores = cobertura_publicacion(tabla_larga, indicadores),
    ficheros = ficheros,
    licencia = LICENCIAS_PUBLICACION
  )
}

# Cobertura de la tabla larga por indicador: filas, primer y último año, niveles (en el orden de
# NIVELES) y cortes (total delante). En el orden de inventario/indicadores.csv si se da su ruta
# (`indicadores`); los que no estén en él, al final y por orden alfabético.
cobertura_publicacion <- function(tabla_larga, indicadores = NULL) {
  larga <- arrow::open_dataset(tabla_larga)
  resumen <- larga |>
    dplyr::group_by(indicador) |>
    dplyr::summarise(filas = dplyr::n(), anio_desde = min(anio), anio_hasta = max(anio)) |>
    dplyr::collect()
  niveles <- larga |> dplyr::distinct(indicador, nivel) |> dplyr::collect()
  cortes <- larga |> dplyr::distinct(indicador, corte) |> dplyr::collect()
  orden <- if (!is.null(indicadores) && file.exists(indicadores)) {
    readr::read_csv(indicadores, col_types = readr::cols(.default = "c"), progress = FALSE)$codigo
  } else character()
  resumen <- resumen[order(match(resumen$indicador, orden), resumen$indicador), ]
  lapply(seq_len(nrow(resumen)), function(k) {
    i <- resumen$indicador[k]
    n <- niveles$nivel[niveles$indicador == i]
    cc <- cortes$corte[cortes$indicador == i]
    list(indicador = i, filas = as.numeric(resumen$filas[k]),
         anio_desde = as.integer(resumen$anio_desde[k]), anio_hasta = as.integer(resumen$anio_hasta[k]),
         niveles = I(n[order(match(n, names(NIVELES)), n)]), cortes = I(cc[order(cc != "total", cc)]))
  })
}

# Ficheros del sitio montado, como lo hace el flujo: web/ como queda en git (sin web/datos/ salvo la
# muestra, sin *.pmtiles, sin la copia local de descargas/ y sin las herramientas de desarrollo)
# más lo del release.
sitio_publicacion <- function(dir_web, datos, salida, url_mapa) {
  web <- list.files(dir_web, recursive = TRUE, all.files = FALSE)
  fuera_de_git <- (startsWith(web, "datos/") & !startsWith(web, "datos/ejemplo/")) | grepl("\\.pmtiles$", web) |
    startsWith(web, paste0(DESTINO_DESCARGAS, "/"))
  desarrollo <- web %in% EXCLUIDOS_SITIO | sub("/.*", "", web) %in% EXCLUIDOS_SITIO
  web <- web[!fuera_de_git & !desarrollo]
  descargas <- salida[c("tabla", "historico", "version")]
  data.frame(
    ruta = c(web, datos, url_mapa, file.path(DESTINO_DESCARGAS, basename(descargas))),
    bytes = c(file.size(file.path(dir_web, c(web, datos))), file.size(salida[["mapa"]]), file.size(descargas)),
    origen = c(rep("web", length(web)), rep("release", length(datos) + 1L + length(descargas)))
  )
}

# Tabla de comprobaciones: id, detalle, valor, límite y si se cumple.
comprobar_publicacion <- function(manifiesto, salida, datos, sitio, tabla_larga, limites) {
  fila <- function(id, detalle, valor, limite, correcto) {
    data.frame(id = id, detalle = detalle, valor = as.numeric(valor), limite = as.numeric(limite), correcto = correcto)
  }
  release <- salida[c("datos", "mapa", "tabla", "historico", "version", "sumas")]
  tam <- file.size(release)
  mayor <- which.max(sitio$bytes)
  url_mapa <- manifiesto$mapa_base$url %||% ""

  en_tar <- utils::untar(salida[["datos"]], list = TRUE, tar = "internal")
  en_tar <- en_tar[!endsWith(en_tar, "/")]

  versiones_web <- unique(do.call(rbind, lapply(manifiesto$indicadores, function(x) {
    data.frame(fuente = x$fuente %||% NA_character_, version = x$version %||% NA_character_)
  })))
  versiones_larga <- arrow::open_dataset(tabla_larga) |> dplyr::distinct(fuente, version) |> dplyr::collect()
  sin_par <- if (is.null(versiones_web)) 0L else
    sum(!paste(versiones_web$fuente, versiones_web$version) %in% paste(versiones_larga$fuente, versiones_larga$version))

  # Tarea 35: la capa de portales no va en el paquete (solo web; decision 3)
  portales_tar <- sum(startsWith(en_tar, "datos/portales/"))
  portales_manifiesto <- sum(vapply(manifiesto$indicadores, function(x)
    identical(x$fuente, "portales") || identical(x$corte, "oferta_privada"), TRUE))
  portales_larga <- arrow::open_dataset(tabla_larga) |>
    dplyr::filter(fuente == "portales" | corte == "oferta_privada") |>
    dplyr::count() |>
    dplyr::collect()
  portales_larga <- if (nrow(portales_larga)) as.numeric(portales_larga$n[1]) else 0

  rbind(
    fila("release_fichero", basename(release), tam, limites[["release_fichero"]], tam < limites[["release_fichero"]]),
    fila("sitio_total", sprintf("%d ficheros", nrow(sitio)), sum(sitio$bytes), limites[["sitio_total"]],
         sum(sitio$bytes) < limites[["sitio_total"]]),
    fila("sitio_fichero", sitio$ruta[mayor], sitio$bytes[mayor], limites[["sitio_fichero"]],
         sitio$bytes[mayor] <= limites[["sitio_fichero"]]),
    fila("manifiesto", "ejemplo = false", 0, 0, isFALSE(manifiesto$ejemplo)),
    fila("manifiesto", paste("mapa base:", url_mapa), 0, 0,
         identical(manifiesto$mapa_base$tipo, "pmtiles") && grepl("^teselas/[^/]+\\.pmtiles$", url_mapa)),
    fila("formato", basename(salida[["mapa"]]), 0, 0, identical(leer_bytes(salida[["mapa"]], 7L), charToRaw("PMTiles"))),
    fila("formato", basename(salida[["tabla"]]), 0, 0,
         identical(leer_bytes(salida[["tabla"]], 4L), charToRaw("PAR1")) &&
           identical(leer_bytes(salida[["tabla"]], 4L, desde_el_final = TRUE), charToRaw("PAR1"))),
    fila("formato", basename(salida[["historico"]]), 0, 0,
         identical(leer_bytes(salida[["historico"]], 4L), charToRaw("PAR1")) &&
           identical(leer_bytes(salida[["historico"]], 4L, desde_el_final = TRUE), charToRaw("PAR1"))),
    fila("tar_completo", basename(salida[["datos"]]), length(en_tar), length(datos), setequal(en_tar, datos)),
    fila("versiones", "fuente y versión del manifiesto que no están en la tabla larga", sin_par, 0, sin_par == 0L),
    fila("sin_portales", "ficheros de datos/portales/ en el .tar.gz", portales_tar, 0, portales_tar == 0),
    fila("sin_portales", "series de los portales en el manifiesto", portales_manifiesto, 0, portales_manifiesto == 0),
    fila("sin_portales", "filas de los portales en la tabla larga", portales_larga, 0, portales_larga == 0)
  )
}

leer_bytes <- function(ruta, n, desde_el_final = FALSE) {
  con <- file(ruta, "rb")
  on.exit(close(con), add = TRUE)
  if (desde_el_final) seek(con, where = max(0, file.size(ruta) - n), origin = "start")
  readBin(con, "raw", n)
}

formato_bytes <- function(x) {
  unidades <- c("B", "KB", "MB", "GB")
  k <- pmin(pmax(floor(log(pmax(x, 1), 1000)), 0), 3)
  ifelse(k == 0, sprintf("%.0f B", x), sub("\\.", ",", sprintf("%.1f %s", x / 1000^k, unidades[k + 1])))
}
