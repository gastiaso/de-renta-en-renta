# Trazabilidad de la nota metodológica (docs/metodologia.md): las funciones, los objetivos y los
# identificadores que cita existen en el pipeline y en el inventario. Si se renombra algo, la
# prueba avisa de que la nota hay que actualizarla.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

leer_nota <- function() readLines(file.path("..", "..", "docs", "metodologia.md"), encoding = "UTF-8", warn = FALSE)

entre_comillas <- function(lineas, patron) {
  unique(unlist(regmatches(lineas, gregexpr(patron, lineas, perl = TRUE))))
}

test_that("las funciones que cita la nota existen", {
  citadas <- sub("\\(\\)`$", "", sub("^`", "", entre_comillas(leer_nota(), "`[A-Za-z_][A-Za-z0-9_.]*\\(\\)`")))
  ajenas <- getNamespaceExports("targets")   # tar_make() y compañía
  faltan <- citadas[!vapply(citadas, exists, logical(1), mode = "function") & !citadas %in% ajenas]
  expect_equal(faltan, character(0))
})

test_that("los objetivos de la lista final de la nota están en _targets.R", {
  nota <- leer_nota()
  desde <- grep("Objetivos citados en esta nota", nota, fixed = TRUE)
  expect_length(desde, 1)
  lista <- nota[seq(desde + 1, length(nota))]
  lista <- lista[startsWith(lista, "- **")]
  objetivos <- gsub("`", "", entre_comillas(lista, "`[a-z_0-9]+`"))
  pipeline <- paste(readLines(file.path("..", "..", "_targets.R"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  definido <- vapply(objetivos, function(o) grepl(sprintf("tar_(target|combine)\\(\\s*%s\\s*,", o), pipeline, perl = TRUE), logical(1))
  expect_true(length(objetivos) > 0)
  expect_equal(objetivos[!definido], character(0))
})

test_that("las fuentes y las comprobaciones de las tablas de la nota están en el inventario", {
  leer <- function(nombre) readr::read_csv(file.path("..", "..", "inventario", nombre), show_col_types = FALSE,
                                           col_types = readr::cols(.default = "c"))
  conocidos <- c(leer("fuentes.csv")$id, leer("referencias_validacion.csv")$id)
  nota <- leer_nota()
  cabecera <- c(startsWith(nota[-1], "|---"), FALSE)   # la fila de encima del separador es la cabecera
  filas <- nota[startsWith(nota, "| `") & !cabecera]
  primera_celda <- sub("^\\|([^|]*)\\|.*$", "\\1", filas)
  ids <- gsub("`", "", entre_comillas(primera_celda, "`[a-z_0-9]+`"))
  expect_true(length(ids) > 0)
  expect_equal(setdiff(ids, conocidos), character(0))
})
