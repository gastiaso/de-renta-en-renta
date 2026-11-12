# Qué falta en datos/brutos/ antes de tar_make() (backlog, tarea 58; R/brutos_comprobar.R), con una
# carpeta inventada en un directorio temporal: un inventario de descargas manuales y un calendario de
# dos fuentes, y ficheros vacíos o de unos bytes (ninguno es de la fuente). Al final, la coherencia de
# inventario/descargas_manuales.csv con el código que lee esos ficheros.

MANUALES_INVENTADOS <- data.frame(
  id = c("hoja", "par_a", "cuatro", "solo_toda", "oferta"),
  fuente = c("fuente_manual", "fuente_par", "fuente_auto", "fuente_toda", "portales"),
  tipo = c("manual", "manual", "copiado", "manual", "portales"),
  carpeta = c("fuente_manual", "fuente_par", "fuente_auto/2025", "fuente_toda", "portales/oferta"),
  patron = c("^hoja_2024[.]xlsx$", "^par_a[.]geojson$", "^tabla_[a-d][.]csv$", "^serie_[0-9]{4}[.]csv$",
             "^oferta_.*[.]csv$"),
  minimo = c("1", "1", "4", "1", "1"),
  con_provincia = c("TRUE", "TRUE", "TRUE", "FALSE", "FALSE"),
  pagina = "https://ejemplo.invalid/pagina",
  guardar_como = c("hoja_2024.xlsx", "par_a.geojson", "tabla_a.csv;tabla_b.csv;tabla_c.csv;tabla_d.csv",
                   "serie_AAAA.csv", "oferta_AAAA-MM.csv"),
  bytes = "", notas = "", stringsAsFactors = FALSE
)
CALENDARIO_INVENTADO <- data.frame(
  id = c("fuente_auto", "fuente_carpeta", "fuente_manual"),
  objetivos = c("fichero_auto", "paginas_carpeta", "fichero_manual"),
  ficheros = c("datos/brutos/fuente_auto/*.zip", "datos/brutos/fuente_carpeta/", "datos/brutos/fuente_manual/*.xlsx"),
  stringsAsFactors = FALSE
)

brutos_inventados <- function() {
  raiz <- tempfile("brutos_")
  dir.create(file.path(raiz, "datos", "brutos"), recursive = TRUE)
  raiz
}
poner <- function(raiz, ...) {
  ruta <- file.path(raiz, "datos", "brutos", ...)
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  writeLines("inventado", ruta)
}
comprobar <- function(raiz, ...) {
  brutos_comprobar(raiz, manuales = MANUALES_INVENTADOS, calendario = CALENDARIO_INVENTADO, ...)
}

test_that("con la carpeta vacía faltan todas, y las manuales dicen dónde bajarlas", {
  raiz <- brutos_inventados()
  on.exit(unlink(raiz, recursive = TRUE))
  x <- comprobar(raiz, portales = FALSE, provincia = "")
  expect_equal(x$grupo, c("manual", "manual", "manual", "manual", "copiado", "automatica", "automatica"))
  expect_false(any(x$presente))
  expect_setequal(x$id[x$grupo == "automatica"], c("fuente_auto", "fuente_carpeta"))   # fuente_manual, arriba
  expect_false(x$necesaria[x$id == "oferta"])                                          # sin PORTALES
  expect_match(x$si_falta[x$id == "hoja"], "se detiene.*https://ejemplo.invalid/pagina.*hoja_2024.xlsx")
  expect_match(x$si_falta[x$id == "cuatro"], "^se descarga")
  r <- NULL
  salida <- capture.output(r <- brutos_informe(x))
  expect_false(r$lista)
  expect_false(r$completa)
  expect_setequal(r$faltan$id, c("hoja", "par_a", "solo_toda", "cuatro", "fuente_auto", "fuente_carpeta"))
  expect_true(any(grepl("No está lista", salida)))
  expect_true(any(grepl("No hacen falta en esta pasada: oferta", salida, fixed = TRUE)))
})

test_that("un fichero con otro nombre no cuenta, y las copiadas piden todos sus ficheros", {
  raiz <- brutos_inventados()
  on.exit(unlink(raiz, recursive = TRUE))
  poner(raiz, "fuente_manual", "hoja_2023.xlsx")              # otra edición: no es la que lee el pipeline
  for (l in c("a", "b", "c")) poner(raiz, "fuente_auto", "2025", paste0("tabla_", l, ".csv"))
  x <- comprobar(raiz, portales = FALSE, provincia = "")
  expect_false(x$presente[x$id == "hoja"])
  expect_equal(x$ficheros[x$id == "cuatro"], 3L)
  expect_false(x$presente[x$id == "cuatro"])
  poner(raiz, "fuente_auto", "2025", "tabla_d.csv")
  y <- comprobar(raiz, portales = FALSE, provincia = "")
  expect_true(y$presente[y$id == "cuatro"])
})

test_that("con las manuales ya está lista, y con todo, completa", {
  raiz <- brutos_inventados()
  on.exit(unlink(raiz, recursive = TRUE))
  poner(raiz, "fuente_manual", "hoja_2024.xlsx")
  poner(raiz, "fuente_par", "par_a.geojson")
  poner(raiz, "fuente_toda", "serie_2026.csv")
  r <- NULL
  capture.output(r <- brutos_informe(comprobar(raiz, portales = FALSE, provincia = "")))
  expect_true(r$lista)
  expect_false(r$completa)
  expect_setequal(r$faltan$grupo, c("copiado", "automatica"))

  for (l in c("a", "b", "c", "d")) poner(raiz, "fuente_auto", "2025", paste0("tabla_", l, ".csv"))
  poner(raiz, "fuente_auto", "datos.zip")
  poner(raiz, "fuente_carpeta", "2024", "pagina.html")        # carpeta: vale cualquier fichero dentro
  x <- comprobar(raiz, portales = FALSE, provincia = "")
  expect_true(all(x$presente[x$necesaria]))
  expect_equal(x$bytes[x$id == "fuente_auto"], file.size(file.path(raiz, "datos", "brutos", "fuente_auto", "datos.zip")))
  salida <- capture.output(r <- brutos_informe(x))
  expect_true(r$completa)
  expect_true(any(grepl("^Completa", salida)))
})

test_that("con PROVINCIA no cuentan las de toda España, y con PORTALES cuentan las de portales", {
  raiz <- brutos_inventados()
  on.exit(unlink(raiz, recursive = TRUE))
  x <- comprobar(raiz, portales = FALSE, provincia = "28")
  expect_false(x$necesaria[x$id == "solo_toda"])
  expect_true(x$necesaria[x$id == "hoja"])
  expect_false(x$necesaria[x$id == "oferta"])
  # Portales encendido pero con PROVINCIA: el bloque de portales no entra
  expect_false(comprobar(raiz, portales = TRUE, provincia = "28")$necesaria[x$id == "oferta"])
  y <- comprobar(raiz, portales = TRUE, provincia = "")
  expect_true(y$necesaria[y$id == "oferta"])
  expect_equal(y$grupo[y$id == "oferta"], "manual")
})

test_that("un tipo de descarga desconocido para", {
  m <- MANUALES_INVENTADOS
  m$tipo[1] <- "a_veces"
  expect_error(brutos_comprobar(tempdir(), manuales = m, calendario = CALENDARIO_INVENTADO), "desconocido")
})

# --- inventario/descargas_manuales.csv frente al código ------------------------------------------

test_that("las descargas manuales del inventario casan con los nombres que pide el código", {
  m <- brutos_leer_csv(file.path("..", "..", "inventario", "descargas_manuales.csv"))
  fuentes <- brutos_leer_csv(file.path("..", "..", "inventario", "fuentes.csv"))
  expect_false(anyDuplicated(m$id) > 0)
  expect_equal(setdiff(m$fuente, fuentes$id), character(0))
  expect_true(all(m$tipo %in% names(BRUTOS_GRUPOS)))
  expect_true(all(m$con_provincia %in% c("TRUE", "FALSE")))
  # cada nombre de guardar_como (salvo los de plantilla, con AAAA) casa con su patrón
  for (i in seq_len(nrow(m))) {
    nombres <- strsplit(m$guardar_como[i], ";", fixed = TRUE)[[1]]
    nombres <- nombres[!grepl("AAAA", nombres)]
    expect_true(all(grepl(m$patron[i], nombres)), info = m$id[i])
  }
  # SERPAVI: el año de ULTIMO_ANIO_SERPAVI de _targets.R
  targets_r <- readLines(file.path("..", "..", "_targets.R"), encoding = "UTF-8")
  ultimo <- sub(".*<- *([0-9]{4})L.*", "\\1", grep("^ULTIMO_ANIO_SERPAVI <-", targets_r, value = TRUE))
  expect_length(ultimo, 1)
  serpavi <- m[m$id == "serpavi", ]
  expect_equal(serpavi$guardar_como, sprintf("bd_serpavi_2011-%s.xlsx", ultimo))
  expect_match(serpavi$guardar_como, serpavi$patron)
  # Registradores: lo que acepta el inventario lo acepta registradores_descargar()
  reg <- m[m$id == "registradores", ]
  expect_match(reg$guardar_como, REGISTRADORES_PATRON)
  expect_equal(reg$guardar_como, basename(REGISTRADORES_CSV))
  # IGN: los dos GeoJSON que pide ficheros_ign_au()
  ign <- m[m$fuente == "ign_au", ]
  expect_setequal(ign$guardar_como, sprintf("territorios_%s.geojson", names(IGN_AU_TIPOS)))
  # Copiados: las direcciones de la fuente son las del código
  expect_equal(m$pagina[m$id == "ecv_2025"], url_ine_ecv(2025))
  expect_equal(m$pagina[m$id == "seccionado_2025"], url_ine_seccionado(2025))
})
