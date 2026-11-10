# Empaquetado del release para GitHub Pages (R/publicar.R) y su flujo (.github/workflows/pages.yml),
# con un proyecto inventado en un directorio temporal: web/ con su muestra y sus herramientas, un
# PMTiles y una tabla larga falsos y un inventario de fuentes mínimo.

COMMIT_FALSO <- list(id = strrep("a1", 20), cambios_sin_commit = FALSE)

proyecto_falso <- function(raiz = withr::local_tempdir(.local_envir = parent.frame()), ejemplo = FALSE,
                           version_serpavi = "2026-11-06") {
  escribir <- function(ruta, texto) {
    dir.create(dirname(file.path(raiz, ruta)), recursive = TRUE, showWarnings = FALSE)
    writeLines(texto, file.path(raiz, ruta), useBytes = TRUE)
  }
  escribir("web/index.html", "<!doctype html><title>Prueba</title>")
  escribir("web/js/principal.js", "console.log('hola');")
  escribir("web/LEEME.md", "# Web")
  escribir("web/servir.mjs", "// servidor local")
  escribir("web/herramientas/generar_ejemplo.R", "# muestra")
  escribir("web/datos/ejemplo/manifiesto.json", '{"ejemplo": true}')
  manifiesto <- list(version = "2026-11-08", ejemplo = ejemplo, generado = "2026-11-08", seccionado = 2021L,
                     mapa_base = list(tipo = "pmtiles", url = "teselas/seccionado_2021.pmtiles", atribucion = "INE"),
                     indicadores = list(alquiler_m2 = list(fuente = "mivau_serpavi", version = version_serpavi),
                                        renta_hogar = list(fuente = "ine_adrh", version = "2026-11-07")))
  escribir("web/datos/manifiesto.json", jsonlite::toJSON(manifiesto, auto_unbox = TRUE))
  escribir("web/datos/indices/sc.json", '["2807901001","2807901002"]')
  escribir("web/datos/sc/alquiler_m2/2024.json", '{"v": [247, null], "e": "03"}')
  escribir("web/datos/fichas/28079.json", '{"municipio": "28079"}')
  # Copia local del mapa base que deja exportar_web(): fuera de git, no debe contar dos veces
  dir.create(file.path(raiz, "web/teselas"), recursive = TRUE)
  pmtiles <- c(charToRaw("PMTiles"), as.raw(3), as.raw(sample.int(255, 2000, replace = TRUE)))
  writeBin(pmtiles, file.path(raiz, "web/teselas/seccionado_2021.pmtiles"))
  dir.create(file.path(raiz, "geo/referencia"), recursive = TRUE)
  writeBin(pmtiles, file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"))

  dir.create(file.path(raiz, "datos/intermedios"), recursive = TRUE)
  larga <- tibble::tibble(geo_id = c("2807901001", "2807901002", "28079"), nivel = c("sc", "sc", "municipio"),
                          anio = 2024L, indicador = c("alquiler_m2", "alquiler_m2", "renta_hogar"),
                          corte = c("tipologia", "tipologia", "total"), grupo = c("VC", "VC", "total"),
                          valor = c(24.7, NA, 40000), estado = c("dato", "ausente", "dato"),
                          fuente = c("mivau_serpavi", "mivau_serpavi", "ine_adrh"), geo_ref = "2021",
                          version = c("2026-11-06", "2026-11-06", "2026-11-07"))
  arrow::write_parquet(larga, file.path(raiz, "datos/intermedios/tabla_larga.parquet"))
  escribir("inventario/fuentes.csv", c("id,nombre", "mivau_serpavi,SERPAVI", "ine_adrh,ADRH"))
  escribir("inventario/indicadores.csv", c("id,codigo", "2,renta_hogar", "9,alquiler_m2"))
  # Copia local de las descargas para ver la página «Datos» (fuera de git): no cuenta en el sitio
  escribir("web/descargas/version.json", "{}")
  raiz
}

empaquetar_falso <- function(raiz, ...) {
  empaquetar_publicacion(dir_web = file.path(raiz, "web"),
                         pmtiles = file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"),
                         tabla_larga = file.path(raiz, "datos/intermedios/tabla_larga.parquet"),
                         dir_salida = file.path(raiz, "publicacion"),
                         fuentes = file.path(raiz, "inventario/fuentes.csv"),
                         indicadores = file.path(raiz, "inventario/indicadores.csv"),
                         commit = COMMIT_FALSO, fecha = "2026-11-08T12:00:00+0100", ...)
}

test_that("empaqueta los cinco ficheros del release con sus sumas SHA-256", {
  raiz <- proyecto_falso()
  res <- suppressMessages(empaquetar_falso(raiz))
  salida <- file.path(raiz, "publicacion")
  expect_setequal(list.files(salida), c("datos_web.tar.gz", "seccionado_2021.pmtiles", "tabla_larga.parquet",
                                        "version.json", "SHA256SUMS"))
  expect_true(all(res$comprobaciones$correcto))

  bruto <- readBin(file.path(salida, "SHA256SUMS"), "raw", 10000)
  expect_false(as.raw(13) %in% bruto)                                  # LF, también en Windows
  lineas <- readLines(file.path(salida, "SHA256SUMS"))
  expect_length(lineas, 4)
  expect_true(all(grepl("^[0-9a-f]{64}  [A-Za-z0-9_.]+$", lineas)))
  nombres <- sub("^.{64}  ", "", lineas)
  expect_setequal(nombres, c("datos_web.tar.gz", "seccionado_2021.pmtiles", "tabla_larga.parquet", "version.json"))
  esperadas <- vapply(file.path(salida, nombres), function(r) digest::digest(r, algo = "sha256", file = TRUE), "")
  expect_equal(substr(lineas, 1, 64), unname(esperadas))
  # El mapa base y la tabla larga salen tal cual
  expect_equal(unname(tools::md5sum(file.path(salida, "seccionado_2021.pmtiles"))),
               unname(tools::md5sum(file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"))))
})

test_that("el .tar.gz lleva web/datos/ sin la muestra, con las rutas desde web/", {
  raiz <- proyecto_falso()
  suppressMessages(empaquetar_falso(raiz))
  tar <- file.path(raiz, "publicacion", "datos_web.tar.gz")
  dentro <- utils::untar(tar, list = TRUE, tar = "internal")
  dentro <- dentro[!endsWith(dentro, "/")]
  expect_setequal(dentro, c("datos/manifiesto.json", "datos/indices/sc.json", "datos/sc/alquiler_m2/2024.json",
                            "datos/fichas/28079.json"))
  destino <- withr::local_tempdir()
  utils::untar(tar, exdir = destino, tar = "internal")
  expect_equal(unname(tools::md5sum(file.path(destino, "datos/sc/alquiler_m2/2024.json"))),
               unname(tools::md5sum(file.path(raiz, "web/datos/sc/alquiler_m2/2024.json"))))
})

test_that("tarea 35: el paquete no lleva la capa de portales, que es solo web (decisión 3)", {
  raiz <- proyecto_falso()
  escribir <- function(ruta, texto) {
    dir.create(dirname(file.path(raiz, ruta)), recursive = TRUE, showWarnings = FALSE)
    writeLines(texto, file.path(raiz, ruta), useBytes = TRUE)
  }
  # La exportación de la capa encendida (R/web_portales.R), con cifras inventadas
  escribir("web/datos/portales/manifiesto.json",
           '{"capa":"portales","activa":true,"indicadores":{"precio_oferta_alquiler_idealista":{"corte":"oferta_privada","fuente":"portales"}}}')
  escribir("web/datos/portales/nacional/precio_oferta_alquiler_idealista/2024.json", '{"v":[999],"e":"0"}')
  escribir("web/datos/portales/enlaces/precio_oferta_alquiler_idealista.json", '{"nacional":{"00":"https://ejemplo.invalid/idealista/"}}')
  res <- suppressMessages(empaquetar_falso(raiz))
  expect_true(all(res$comprobaciones$correcto))
  expect_equal(res$comprobaciones$valor[res$comprobaciones$id == "sin_portales"], c(0, 0, 0))
  tar <- file.path(raiz, "publicacion", "datos_web.tar.gz")
  dentro <- utils::untar(tar, list = TRUE, tar = "internal")
  expect_false(any(startsWith(dentro, "datos/portales")))
  # Ningún fichero del paquete nombra el corte, la fuente ni el portal
  destino <- withr::local_tempdir()
  utils::untar(tar, exdir = destino, tar = "internal")
  textos <- c(unlist(lapply(list.files(destino, recursive = TRUE, full.names = TRUE), readLines, warn = FALSE)),
              readLines(file.path(raiz, "publicacion", "version.json"), warn = FALSE))
  expect_false(any(grepl("oferta_privada|idealista|portales", textos, ignore.case = TRUE)))
  # El sitio montado tampoco la toma de web/ (está fuera de git)
  expect_false(any(startsWith(res$sitio$ruta, "datos/portales")))

  # Si la tabla larga o el manifiesto general la llevaran, no empaqueta
  # (en otro fichero: Windows no deja reescribir un Parquet que arrow tiene abierto)
  larga <- arrow::read_parquet(file.path(raiz, "datos/intermedios/tabla_larga.parquet"))
  capa <- tibble::tibble(geo_id = "00", nivel = "nacional", anio = 2024L, indicador = "precio_oferta", corte = "oferta_privada",
                         grupo = "alquiler_idealista", valor = 9.99, estado = "dato", fuente = "portales", geo_ref = "2021",
                         version = "2026-11-06")
  con_capa <- file.path(raiz, "datos/intermedios/tabla_larga_con_portales.parquet")
  arrow::write_parquet(dplyr::bind_rows(larga, capa), con_capa)
  expect_error(suppressMessages(capture.output(
    empaquetar_publicacion(dir_web = file.path(raiz, "web"), pmtiles = file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"),
                           tabla_larga = con_capa, dir_salida = file.path(raiz, "publicacion"),
                           fuentes = file.path(raiz, "inventario/fuentes.csv"), indicadores = file.path(raiz, "inventario/indicadores.csv"),
                           commit = COMMIT_FALSO, fecha = "2026-11-08T12:00:00+0100"))), "sin_portales")
})

test_that("version.json: fecha, commit, web, fuentes con su versión y ficheros con su suma", {
  raiz <- proyecto_falso()
  suppressMessages(empaquetar_falso(raiz))
  v <- jsonlite::fromJSON(file.path(raiz, "publicacion", "version.json"))
  expect_equal(v$fecha, "2026-11-08T12:00:00+0100")
  expect_equal(v$commit$id, COMMIT_FALSO$id)
  expect_false(v$commit$cambios_sin_commit)
  expect_equal(v$web$version, "2026-11-08")
  expect_equal(v$fuentes$fuente, c("ine_adrh", "mivau_serpavi"))
  expect_equal(v$fuentes$version, c("2026-11-07", "2026-11-06"))
  expect_equal(v$fuentes$filas, c(1, 2))
  expect_equal(v$fuentes$nombre, c("ADRH", "SERPAVI"))
  expect_setequal(v$ficheros$nombre, c("datos_web.tar.gz", "seccionado_2021.pmtiles", "tabla_larga.parquet"))
  expect_equal(v$ficheros$destino[v$ficheros$nombre == "seccionado_2021.pmtiles"], "teselas/seccionado_2021.pmtiles")
  expect_equal(v$ficheros$destino[v$ficheros$nombre == "tabla_larga.parquet"], "descargas/tabla_larga.parquet")
  sumas <- readLines(file.path(raiz, "publicacion", "SHA256SUMS"))
  expect_true(all(paste0(v$ficheros$sha256, "  ", v$ficheros$nombre) %in% sumas))
})

test_that("version.json: cobertura por indicador en el orden del inventario, con niveles y cortes", {
  raiz <- proyecto_falso()
  suppressMessages(empaquetar_falso(raiz))
  v <- jsonlite::fromJSON(file.path(raiz, "publicacion", "version.json"), simplifyVector = FALSE)
  cobertura <- v$indicadores
  expect_equal(vapply(cobertura, `[[`, "", "indicador"), c("renta_hogar", "alquiler_m2"))
  alquiler <- cobertura[[2]]
  expect_equal(alquiler$filas, 2)
  expect_equal(c(alquiler$anio_desde, alquiler$anio_hasta), c(2024L, 2024L))
  expect_equal(alquiler$niveles, list("sc"))                         # lista también con un solo nivel
  expect_equal(alquiler$cortes, list("tipologia"))
  expect_equal(cobertura[[1]]$niveles, list("municipio"))

  # Sin inventario: por orden alfabético; niveles en el orden de NIVELES y «total» delante
  dir <- withr::local_tempdir()
  larga <- tibble::tibble(indicador = c("z", "z", "z", "a"), nivel = c("provincia", "sc", "municipio", "sc"),
                          anio = c(2015L, 2024L, 2020L, 2021L), corte = c("edad", "total", "edad", "total"))
  arrow::write_parquet(larga, file.path(dir, "t.parquet"))
  c2 <- cobertura_publicacion(file.path(dir, "t.parquet"))
  expect_equal(vapply(c2, `[[`, "", "indicador"), c("a", "z"))
  expect_equal(as.character(c2[[2]]$niveles), c("sc", "municipio", "provincia"))
  expect_equal(as.character(c2[[2]]$cortes), c("total", "edad"))
  expect_equal(c(c2[[2]]$anio_desde, c2[[2]]$anio_hasta, c2[[2]]$filas), c(2015, 2024, 3))
})

test_that("el sitio montado: web/ sin herramientas ni copias locales, más lo del release", {
  raiz <- proyecto_falso()
  res <- suppressMessages(empaquetar_falso(raiz))
  rutas <- res$sitio$ruta
  expect_true(all(c("index.html", "js/principal.js", "datos/ejemplo/manifiesto.json", "datos/manifiesto.json",
                    "teselas/seccionado_2021.pmtiles", "descargas/tabla_larga.parquet", "descargas/version.json")
                  %in% rutas))
  expect_false(any(c("LEEME.md", "servir.mjs", "herramientas/generar_ejemplo.R") %in% rutas))
  expect_equal(sum(rutas == "teselas/seccionado_2021.pmtiles"), 1L)
  expect_equal(sum(rutas == "descargas/version.json"), 1L)           # la del release, no la copia local
  expect_false(anyDuplicated(rutas) > 0)
})

test_that("se detiene si se pasa un límite, y no deja nada a medias", {
  raiz <- proyecto_falso()
  salida <- file.path(raiz, "publicacion")
  pocos <- function(...) modifyList(as.list(LIMITES_PUBLICACION), list(...)) |> unlist()
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz, limites = pocos(sitio_fichero = 100)))),
               "sitio_fichero")
  expect_length(list.files(salida), 0)
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz, limites = pocos(sitio_total = 1000)))),
               "sitio_total")
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz, limites = pocos(release_fichero = 1000)))),
               "release_fichero")
  expect_length(list.files(salida), 0)
})

test_that("no empaqueta la muestra ni una exportación de otra pasada", {
  raiz <- proyecto_falso(ejemplo = TRUE)
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz))), "manifiesto")
  raiz <- proyecto_falso(version_serpavi = "2026-10-01")
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz))), "versiones")
})

test_that("comprueba que existen y son lo que dicen el PMTiles y el Parquet", {
  raiz <- proyecto_falso()
  file.remove(file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"))
  expect_error(empaquetar_falso(raiz), "mapa_base_2021.pmtiles")

  raiz <- proyecto_falso()
  writeLines("no es un PMTiles", file.path(raiz, "geo/referencia/mapa_base_2021.pmtiles"))
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz))), "formato")

  raiz <- proyecto_falso()
  writeLines("no es un Parquet", file.path(raiz, "datos/intermedios/tabla_larga.parquet"))
  expect_error(suppressMessages(capture.output(empaquetar_falso(raiz))))
})

test_that("rehace el paquete encima del anterior, pero no borra ficheros ajenos", {
  raiz <- proyecto_falso()
  suppressMessages(empaquetar_falso(raiz))
  suppressMessages(empaquetar_falso(raiz))
  expect_length(list.files(file.path(raiz, "publicacion")), 5)
  writeLines("nota", file.path(raiz, "publicacion", "notas.txt"))
  expect_error(suppressMessages(empaquetar_falso(raiz)), "notas.txt")
  expect_true(file.exists(file.path(raiz, "publicacion", "notas.txt")))
})

test_that("formato_bytes escribe las cifras con coma decimal", {
  expect_equal(formato_bytes(c(512, 35160405, 1e9)), c("512 B", "35,2 MB", "1,0 GB"))
})

# El flujo de Pages: YAML válido, con los mismos nombres que el empaquetado, acciones oficiales
# fijadas por commit, permisos mínimos, sin secretos y sin nombre de repositorio.
test_that("el flujo de Pages cuadra con el empaquetado", {
  ruta <- file.path("..", "..", ".github", "workflows", "pages.yml")
  skip_if_not(file.exists(ruta))
  texto <- readLines(ruta, encoding = "UTF-8", warn = FALSE)
  flujo <- yaml::read_yaml(ruta)
  disparadores <- flujo[["on"]] %||% flujo[["TRUE"]]               # yaml lee «on» como lógico
  # Sitio congelado hasta la v1.0 (plan, pregunta 42): solo a mano, sobre una referencia fija que
  # existe en el repositorio, y el checkout monta esa referencia.
  expect_equal(names(disparadores), "workflow_dispatch")
  ref <- disparadores$workflow_dispatch$inputs$ref
  expect_true(isTRUE(ref$required))
  expect_match(ref$default, "^[0-9a-f]{40}$")
  if (nzchar(Sys.which("git"))) {
    existe <- suppressWarnings(system2("git", c("cat-file", "-e", paste0(ref$default, "^{commit}")),
                                       stdout = FALSE, stderr = FALSE))
    expect_equal(existe, 0L)
  }
  expect_equal(flujo$jobs$montar$steps[[1]]$with$ref, "${{ inputs.ref }}")
  expect_length(flujo$permissions, 0)
  expect_setequal(names(flujo$jobs), c("montar", "desplegar"))
  expect_equal(flujo$jobs$montar$permissions, list(contents = "read"))
  expect_equal(flujo$jobs$desplegar$permissions, list(pages = "write", `id-token` = "write"))
  expect_equal(flujo$jobs$desplegar$needs, "montar")
  expect_equal(flujo$jobs$desplegar$environment$name, "github-pages")

  pasos <- c(flujo$jobs$montar$steps, flujo$jobs$desplegar$steps)
  acciones <- unlist(lapply(pasos, `[[`, "uses"))
  expect_setequal(sub("@.*", "", acciones), c("actions/checkout", "actions/upload-pages-artifact", "actions/deploy-pages"))
  expect_true(all(grepl("^actions/[a-z-]+@[0-9a-f]{40}$", acciones)))
  usos <- grep("uses: actions/", texto, value = TRUE)
  expect_true(all(grepl("# v[0-9]+\\.[0-9]+\\.[0-9]+$", usos)))      # versión en el comentario

  guion <- paste(unlist(lapply(pasos, `[[`, "run")), collapse = "\n")
  for (f in FICHEROS_RELEASE) expect_match(guion, f, fixed = TRUE)
  expect_match(guion, paste0(DESTINO_DESCARGAS, "/"), fixed = TRUE)
  borrado <- grep("rm -rf", strsplit(guion, "\n")[[1]], value = TRUE)
  for (f in EXCLUIDOS_SITIO) expect_match(borrado, paste0("$sitio/", f), fixed = TRUE)
  expect_match(guion, "1000000000", fixed = TRUE)                  # LIMITES_PUBLICACION[["sitio_total"]]
  expect_match(guion, format(LIMITES_PUBLICACION[["sitio_fichero"]], scientific = FALSE), fixed = TRUE)

  # Páginas «Método» y «Datos»: plantilla, metadatos por idioma, herramienta y textos que cita el flujo
  citados <- unique(unlist(regmatches(guion, gregexpr("(web|docs)/[A-Za-z_/]+\\.(html|yaml|md|mjs)", guion))))
  idiomas <- c("es", "en")
  pares <- regmatches(guion, gregexpr('"(es|en)( [a-z_]+\\.(md|html))+"', guion))[[1]]
  expect_length(pares, 2)
  ficheros_par <- unlist(lapply(strsplit(gsub('"', "", pares), " "), `[`, -1))
  expect_true(all(c("datos.html", "data.html", "metodo.html", "method.html") %in% ficheros_par))
  citados <- unique(c(gsub("\\$1", "es", citados), gsub("\\$1", "en", citados),
                      file.path("web/herramientas", paste0("documento_", idiomas, ".yaml")),
                      file.path("web/herramientas", paste0("datos_", idiomas, ".yaml")),
                      file.path("docs", grep("\\.md$", ficheros_par, value = TRUE)), "CITATION.cff"))
  expect_true("web/herramientas/pagina_datos.mjs" %in% citados)
  expect_true(all(file.exists(file.path("..", "..", citados))), info = paste(citados, collapse = ", "))
  for (idioma in idiomas) {
    dic <- jsonlite::fromJSON(file.path("..", "..", "web", "i18n", paste0(idioma, ".json")), simplifyVector = FALSE)
    claves <- regmatches(guion, gregexpr("jq -r \\.[a-z_.]+ \"\\$dic\"", guion))[[1]]
    for (clave in sub("^jq -r \\.", "", sub(" \"\\$dic\"$", "", claves))) {
      valor <- Reduce(function(x, k) x[[k]], strsplit(clave, ".", fixed = TRUE)[[1]], dic)
      expect_true(is.character(valor) && nzchar(valor), info = paste(idioma, clave))
    }
  }

  expect_false(any(grepl("secrets\\.", texto)))
  expect_false(any(grepl("gastiaso|de-renta-en-renta", texto)))
})
