# Dos familias de indicadores de alquiler (backlog, tarea 34; plan §11, preguntas 50 y 51):
# «quedarse» (parque alquilado, SERPAVI) y «entrar» (oferta e índice de contratos nuevos). Ningún
# texto del inventario, de la web ni de la nota llama «acceso» a una cifra del SERPAVI, y «barrera»
# queda para la familia «entrar».
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

raiz <- function(...) file.path("..", "..", ...)
leer_csv_inventario <- function(nombre) {
  readr::read_csv(raiz("inventario", nombre), show_col_types = FALSE, col_types = readr::cols(.default = "c"))
}
leer_texto <- function(...) paste(readLines(raiz(...), encoding = "UTF-8", warn = FALSE), collapse = "\n")

# Textos de un JSON anidado, con su ruta («a/b/c»).
textos_json <- function(x, prefijo = "") {
  if (is.list(x)) {
    return(unlist(lapply(names(x), function(n) textos_json(x[[n]], paste0(prefijo, "/", n)))))
  }
  if (is.character(x)) stats::setNames(x, rep(prefijo, length(x))) else character()
}

PALABRA_ACCESO <- "(?i)\\b(acceso|access)"
PALABRA_BARRERA <- "(?i)\\b(barreras?|barriers?)\\b"
FRASES_PROHIBIDAS <- "(?i)(barrera de acceso|acceso al alquiler|access barrier|rental access)"

test_that("cada indicador de alquiler lleva una familia del vocabulario", {
  ind <- leer_csv_inventario("indicadores.csv")
  voc <- leer_csv_inventario("vocabulario.csv")
  expect_true("familia_alquiler" %in% names(ind))
  claves <- voc$clave[voc$grupo == "familia_alquiler"]
  expect_setequal(claves, c("quedarse", "entrar"))
  fam <- ind$familia_alquiler[!is.na(ind$familia_alquiler)]
  expect_equal(setdiff(fam, claves), character(0))
  serpavi <- grepl("mivau_serpavi", ind$fuentes)
  expect_true(all(ind$familia_alquiler[serpavi] == "quedarse"))
  expect_equal(ind$familia_alquiler[ind$codigo == "precio_oferta"], "entrar")
  expect_equal(ind$familia_alquiler[ind$codigo == "peso_alquiler_ingreso"], "quedarse")
})

test_that("los textos de los indicadores de «quedarse» no hablan de acceso ni de barrera", {
  ind <- leer_csv_inventario("indicadores.csv")
  q <- ind[ind$familia_alquiler %in% "quedarse", ]
  campos <- c(outer(c("nombre", "unidad", "definicion", "calculo", "lectura"), c("_es", "_en"), paste0), "notas")
  for (cmp in campos) {
    texto <- stats::na.omit(q[[cmp]])
    expect_false(any(grepl(PALABRA_ACCESO, texto, perl = TRUE)), info = cmp)
    expect_false(any(grepl(PALABRA_BARRERA, texto, perl = TRUE)), info = cmp)
  }
  voc <- leer_csv_inventario("vocabulario.csv")
  fam_c <- voc[voc$grupo == "familia" & voc$clave == "C", c("es", "en")]
  expect_false(any(grepl(PALABRA_ACCESO, unlist(fam_c), perl = TRUE)))
})

test_that("la web no llama acceso ni barrera a una cifra del SERPAVI", {
  ind <- leer_csv_inventario("indicadores.csv")
  entrar <- ind$codigo[ind$familia_alquiler %in% "entrar"]
  for (idioma in c("es", "en")) {
    tx <- textos_json(jsonlite::read_json(raiz("web", "i18n", paste0(idioma, ".json"))))
    expect_false(any(grepl(FRASES_PROHIBIDAS, tx, perl = TRUE)), info = idioma)
    # «Barrera», solo en los textos de la familia «entrar»
    de_entrar <- grepl(paste0("^/indicadores/(", paste(c(entrar, "barrera_entrar"), collapse = "|"), ")/"), names(tx)) |
      grepl("entrar", names(tx))
    con_barrera <- names(tx)[grepl(PALABRA_BARRERA, tx, perl = TRUE) & !de_entrar]
    expect_equal(con_barrera, character(0), info = idioma)
    # Los indicadores de «quedarse», sin «acceso»
    quedarse <- ind$codigo[ind$familia_alquiler %in% "quedarse"]
    suyos <- grepl(paste0("^/indicadores/(", paste(quedarse, collapse = "|"), ")/"), names(tx))
    expect_equal(names(tx)[suyos & grepl(PALABRA_ACCESO, tx, perl = TRUE)], character(0), info = idioma)
  }
  # Las páginas «Método» y «Datos» las monta el flujo de Pages desde docs/ (fuera de git)
  generadas <- c("metodo.html", "method.html", "datos.html", "data.html")
  for (pagina in setdiff(list.files(raiz("web"), pattern = "[.]html$"), generadas)) {
    html <- leer_texto("web", pagina)
    expect_false(grepl(FRASES_PROHIBIDAS, html, perl = TRUE), info = pagina)
  }
})

test_that("la nota no llama acceso ni barrera a una cifra del SERPAVI", {
  ind <- leer_csv_inventario("indicadores.csv")
  quedarse <- ind$codigo[ind$familia_alquiler %in% "quedarse"]
  for (nota in c("metodologia.md", "methodology.md", "metodo_corto.md")) {
    if (!file.exists(raiz("docs", nota))) next
    lineas <- readLines(raiz("docs", nota), encoding = "UTF-8", warn = FALSE)
    expect_false(any(grepl(FRASES_PROHIBIDAS, lineas, perl = TRUE)), info = nota)
    expect_false(any(grepl(PALABRA_BARRERA, lineas, perl = TRUE) & !grepl("barrera_entrar|(?i)\\bentrar\\b|moving in", lineas, perl = TRUE)),
                 info = nota)
    # Líneas que hablan del SERPAVI o de un indicador de «quedarse», sin el código entre comillas
    # invertidas (la columna `acceso` de fuentes.csv es un nombre, no una lectura)
    sin_codigo <- gsub("`[^`]*`", "", lineas)
    del_parque <- grepl(paste(c("SERPAVI", quedarse), collapse = "|"), lineas)
    expect_equal(which(del_parque & grepl(PALABRA_ACCESO, sin_codigo, perl = TRUE)), integer(0), info = nota)
  }
})
