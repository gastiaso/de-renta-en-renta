# Trazabilidad de la nota metodológica (docs/metodologia.md) y de su versión inglesa
# (docs/methodology.md): las funciones, los objetivos y los identificadores que citan existen en el
# pipeline y en el inventario, y las dos versiones citan lo mismo, con la misma estructura y las
# mismas cifras. Si se renombra algo, o si se cambia una versión sin la otra, la prueba avisa.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

NOTAS <- c(es = "metodologia.md", en = "methodology.md")

leer_nota <- function(idioma = "es") {
  readLines(file.path("..", "..", "docs", NOTAS[[idioma]]), encoding = "UTF-8", warn = FALSE)
}

entre_comillas <- function(lineas, patron) {
  unique(unlist(regmatches(lineas, gregexpr(patron, lineas, perl = TRUE))))
}

# Líneas fuera de los bloques de código delimitados con ```
sin_bloques <- function(lineas) {
  valla <- startsWith(lineas, "```")
  dentro <- (cumsum(valla) %% 2 == 1) | valla
  lineas[!dentro]
}

for (idioma in names(NOTAS)) {
  test_that(paste0("las funciones que cita la nota existen (", idioma, ")"), {
    citadas <- sub("\\(\\)`$", "", sub("^`", "", entre_comillas(leer_nota(idioma), "`[A-Za-z_][A-Za-z0-9_.]*\\(\\)`")))
    ajenas <- getNamespaceExports("targets")   # tar_make() y compañía
    faltan <- citadas[!vapply(citadas, exists, logical(1), mode = "function") & !citadas %in% ajenas]
    expect_equal(faltan, character(0))
  })

  test_that(paste0("los objetivos de la lista final de la nota están en _targets.R (", idioma, ")"), {
    nota <- leer_nota(idioma)
    desde <- grep(c(es = "Objetivos citados en esta nota", en = "Targets cited in this note")[[idioma]], nota, fixed = TRUE)
    expect_length(desde, 1)
    lista <- nota[seq(desde + 1, length(nota))]
    lista <- lista[startsWith(lista, "- **")]
    objetivos <- gsub("`", "", entre_comillas(lista, "`[a-z_0-9]+`"))
    pipeline <- paste(readLines(file.path("..", "..", "_targets.R"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
    definido <- vapply(objetivos, function(o) grepl(sprintf("tar_(target|combine)\\(\\s*%s\\s*,", o), pipeline, perl = TRUE), logical(1))
    expect_true(length(objetivos) > 0)
    expect_equal(objetivos[!definido], character(0))
  })

  test_that(paste0("las fuentes, comprobaciones y rupturas de las tablas de la nota están en el inventario (", idioma, ")"), {
    leer <- function(nombre) readr::read_csv(file.path("..", "..", "inventario", nombre), show_col_types = FALSE,
                                             col_types = readr::cols(.default = "c"))
    conocidos <- c(leer("fuentes.csv")$id, leer("referencias_validacion.csv")$id, leer("rupturas.csv")$id)
    nota <- leer_nota(idioma)
    cabecera <- c(startsWith(nota[-1], "|---"), FALSE)   # la fila de encima del separador es la cabecera
    filas <- nota[startsWith(nota, "| `") & !cabecera]
    primera_celda <- sub("^\\|([^|]*)\\|.*$", "\\1", filas)
    ids <- gsub("`", "", entre_comillas(primera_celda, "`[a-z_0-9]+`"))
    expect_true(length(ids) > 0)
    expect_equal(setdiff(ids, conocidos), character(0))
  })
}

test_that("las dos versiones tienen la misma estructura", {
  es <- sin_bloques(leer_nota("es"))
  en <- sin_bloques(leer_nota("en"))
  nivel <- function(l) nchar(sub("^(#+).*$", "\\1", l[grepl("^#+ ", l)]))
  expect_equal(nivel(en), nivel(es))
  expect_equal(sum(grepl("^\\s*\\|", en)), sum(grepl("^\\s*\\|", es)))   # filas de tabla
  expect_equal(sum(grepl("^\\s*- ", en)), sum(grepl("^\\s*- ", es)))     # viñetas
})

test_that("las dos versiones citan los mismos objetivos, funciones, columnas y códigos", {
  codigo <- function(idioma) {
    x <- gsub("`", "", entre_comillas(sin_bloques(leer_nota(idioma)), "`[^`]+`"))
    sort(x[!grepl("<|^docs/metodologia[.]md$|^docs/methodology[.]md$", x)])   # sin marcadores <...> ni los nombres de las notas
  }
  es <- codigo("es")
  en <- codigo("en")
  expect_equal(setdiff(en, es), character(0))
  expect_equal(setdiff(es, en), character(0))
})

# Cifras de cada versión: fuera quedan el código, las referencias a secciones (§3.1), los números
# de los títulos, las versiones (v0.21, R 4.6, CC BY 4.0, MapLibre GL JS 6.15.0, PMTiles 4.5.0) y
# el nombre inglés de la ficha «mochila» (Young adult). En inglés se intercambian el punto y la coma de
# las cifras (36,333.5 -> 36.333,5).
cifras_nota <- function(idioma) {
  t <- paste(sin_bloques(leer_nota(idioma)), collapse = "\n")
  quitar <- c("`[^`]*`", "(?m)^#+\\s*[0-9.]+\\s", "§[0-9]+(\\.[0-9]+)*", "\\bv[0-9]+(\\.[0-9]+)*",
              "\\bR [0-9]+\\.[0-9]+", "CC BY(-SA)? [0-9]+\\.[0-9]+", "GL JS [0-9.]+[0-9]", "PMTiles [0-9]+\\.[0-9]+\\.[0-9]+",
              "Young adult")
  for (p in quitar) t <- gsub(p, " ", t, perl = TRUE)
  cifras <- regmatches(t, gregexpr("[0-9]+(?:[.,][0-9]+)*", t, perl = TRUE))[[1]]
  if (idioma == "en") cifras <- chartr(".,", ",.", cifras)
  sort(cifras)
}

test_that("las dos versiones dan las mismas cifras", {
  es <- table(cifras_nota("es"))
  en <- table(cifras_nota("en"))
  todas <- union(names(es), names(en))
  n_es <- as.integer(es[todas]); n_es[is.na(n_es)] <- 0L
  n_en <- as.integer(en[todas]); n_en[is.na(n_en)] <- 0L
  distintas <- todas[n_es != n_en]
  expect_equal(paste(distintas, n_es[n_es != n_en], n_en[n_es != n_en]), character(0))
})
