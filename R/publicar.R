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
#   - version.json: fecha, commit, versiones de las fuentes y tamaño y suma de cada fichero;
#   - SHA256SUMS: sumas SHA-256 de los cuatro anteriores, en el formato de sha256sum (el flujo las
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
#   - formato: el PMTiles empieza por «PMTiles» y el Parquet empieza y acaba por «PAR1»;
#   - tar_completo: el .tar.gz lleva todos los ficheros de datos/, y solo esos;
#   - versiones: cada fuente y versión del manifiesto está en la tabla larga (la exportación de la
#     web y la tabla larga son de la misma pasada del pipeline).

LIMITES_PUBLICACION <- c(
  release_fichero = 2 * 1024^3,    # «Each file included in a release must be under 2 GiB»
  sitio_total = 1e9,               # «Published GitHub Pages sites may be no larger than 1 GB»
  sitio_fichero = 100 * 1024^2     # git rechaza ficheros de más de 100 MiB
)
# Herramientas de desarrollo de web/ que no se publican (el flujo las borra al montar el sitio)
EXCLUIDOS_SITIO <- c("LEEME.md", "servir.mjs", "herramientas")
FICHEROS_RELEASE <- c(datos = "datos_web.tar.gz", tabla = "tabla_larga.parquet", version = "version.json",
                      sumas = "SHA256SUMS")
DESTINO_DESCARGAS <- "descargas"   # carpeta del sitio con la tabla larga y version.json

# Paquete del release en dir_salida. `commit`: lista con `id` y `cambios_sin_commit`
# (commit_publicacion()). `limites`: los de LIMITES_PUBLICACION (las pruebas los bajan).
empaquetar_publicacion <- function(dir_web = "web",
                                   pmtiles = "geo/referencia/mapa_base_2021.pmtiles",
                                   tabla_larga = "datos/intermedios/tabla_larga.parquet",
                                   dir_salida = "publicacion",
                                   fuentes = "inventario/fuentes.csv",
                                   commit = commit_publicacion(),
                                   fecha = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                                   limites = LIMITES_PUBLICACION) {
  manifiesto_ruta <- file.path(dir_web, "datos", "manifiesto.json")
  for (ruta in c(manifiesto_ruta, pmtiles, tabla_larga)) {
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
              version = file.path(dir_salida, FICHEROS_RELEASE[["version"]]),
              sumas = file.path(dir_salida, FICHEROS_RELEASE[["sumas"]]))
  correcto <- FALSE
  on.exit(if (!correcto) unlink(salida), add = TRUE)

  tar_datos_publicacion(dir_web, datos, salida[["datos"]])
  copiar <- function(de, a) if (!file.copy(de, a, overwrite = TRUE)) stop("No se ha podido copiar ", de, call. = FALSE)
  copiar(pmtiles, salida[["mapa"]])
  copiar(tabla_larga, salida[["tabla"]])

  release <- salida[c("datos", "mapa", "tabla")]
  sumas <- vapply(release, sha256_fichero, "")
  version <- version_publicacion(manifiesto, tabla_larga, fuentes, commit, fecha,
                                 ficheros = data.frame(nombre = basename(release), bytes = file.size(release),
                                                       sha256 = unname(sumas), destino = destino_publicacion(release, url_mapa)))
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

# Ficheros de web/datos/ que van al release, con la ruta desde web/: todo menos la muestra.
ficheros_datos_publicacion <- function(dir_web = "web") {
  rutas <- list.files(file.path(dir_web, "datos"), recursive = TRUE, all.files = FALSE)
  rutas <- sort(rutas[!startsWith(rutas, "ejemplo/")])
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
# versión, que es la fecha del fichero de origen, y su número de filas), mapa base y ficheros.
version_publicacion <- function(manifiesto, tabla_larga, fuentes, commit, fecha, ficheros) {
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
    ficheros = ficheros,
    licencia = list(datos = "CC BY-SA 4.0 (LICENCIA_DATOS.md)", codigo = "MIT (LICENSE)")
  )
}

# Ficheros del sitio montado, como lo hace el flujo: web/ como queda en git (sin web/datos/ salvo la
# muestra, sin *.pmtiles y sin las herramientas de desarrollo) más lo del release.
sitio_publicacion <- function(dir_web, datos, salida, url_mapa) {
  web <- list.files(dir_web, recursive = TRUE, all.files = FALSE)
  fuera_de_git <- (startsWith(web, "datos/") & !startsWith(web, "datos/ejemplo/")) | grepl("\\.pmtiles$", web)
  desarrollo <- web %in% EXCLUIDOS_SITIO | sub("/.*", "", web) %in% EXCLUIDOS_SITIO
  web <- web[!fuera_de_git & !desarrollo]
  descargas <- salida[c("tabla", "version")]
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
  release <- salida[c("datos", "mapa", "tabla", "version", "sumas")]
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
    fila("tar_completo", basename(salida[["datos"]]), length(en_tar), length(datos), setequal(en_tar, datos)),
    fila("versiones", "fuente y versión del manifiesto que no están en la tabla larga", sin_par, 0, sin_par == 0L)
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
