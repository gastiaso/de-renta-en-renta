# Página «Datos» (datos.html y data.html): diccionario generado desde el inventario
# (R/web_pagina_datos.R), su versión en docs/ y los textos a mano de docs/datos.md y docs/data.md.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

raiz_proyecto <- function(...) file.path("..", "..", ...)

inventario_falso <- function() {
  indicadores <- tibble::tibble(
    id = c(1, 2, NA), codigo = c("renta_a", "alquiler_b", "contratos_b"),
    nombre_es = c("Renta *media*", "Alquiler | mediana", "Contratos"),
    nombre_en = c("Mean *income*", "Rent | median", "Contracts"),
    unidad_es = c("€ por año", "€ por m²", "contratos"), unidad_en = c("€ per year", "€ per m²", "contracts"),
    definicion_es = c("Def A.", "Def B.", "Def C."), definicion_en = c("Def A en.", "Def B en.", "Def C en."),
    calculo_es = c("Calc A.", "Calc B.", "Calc C."), calculo_en = c("Calc A en.", "Calc B en.", "Calc C en."),
    lectura_es = c("Lect A.", NA, "Lect C."), lectura_en = c("Read A.", NA, "Read C."),
    familia = c("A capacidad de pago", "B coste de la vivienda", "B coste de la vivienda"),
    fuentes = c("ine_adrh", "mivau_serpavi;ine_adrh", "mivau_serpavi"),
    fase = c("F2", "F3", "F2"), auxiliar_de = c(NA, NA, "alquiler_b")
  )
  vocabulario <- tibble::tribble(
    ~grupo, ~clave, ~es, ~en,
    "familia", "A", "Capacidad de pago", "Ability to pay",
    "familia", "B", "Coste de la vivienda", "Housing cost",
    "nivel", "sc", "Sección censal", "Census tract",
    "nivel", "nacional", "España", "Spain",
    "estado", "dato", "Dato", "Value",
    "estado", "ausente", "Sin dato", "No data",
    "corte", "total", "Total", "Total",
    "corte", "tipologia", "Tipología", "Dwelling type",
    "tipologia", "VC", "Colectiva", "Flat",
    "fiabilidad", "baja", "Muestra pequeña", "Small sample"
  )
  fuentes <- tibble::tibble(id = c("ine_adrh", "mivau_serpavi", "portales", "calculo_propio"),
                            nombre = c("ADRH", "SERPAVI", "Portales", "Cálculo propio"),
                            nombre_en = c("ADRH en", "SERPAVI en", "Portals", "Own calculation"),
                            url = c("https://ine.es", "https://mivau.gob.es", "", "—"))
  list(indicadores = indicadores, vocabulario = vocabulario, fuentes = fuentes)
}

test_that("el diccionario lleva las columnas con vocabulario y una ficha por indicador", {
  inv <- inventario_falso()
  es <- diccionario_datos_md(inv$indicadores, inv$vocabulario, inv$fuentes, "es")
  titulos <- es[grepl("^#+ ", es)]
  expect_equal(titulos, c("## Valores de las columnas", "### `estado`", "### `nivel`", "### `corte`", "### `grupo`",
                          "### `fuente`", "## Diccionario de indicadores", "### `renta_a`", "### `alquiler_b`",
                          "### `contratos_b`"))
  expect_true("| `sc` | Sección censal | 10 |" %in% es)
  expect_true("| `nacional` | España | 2 (`00`) |" %in% es)
  expect_true("| `total` | `total` | Sin desglose |" %in% es)
  expect_true("| `tipologia` | `VC` | Colectiva |" %in% es)
  expect_false(any(grepl("Muestra peque", es)))                     # fiabilidad no es una columna
  # Fuentes: las que cita el inventario y calculo_propio, sin las demás
  expect_true(all(c("| `ine_adrh` | ADRH |", "| `mivau_serpavi` | SERPAVI |", "| `calculo_propio` | Cálculo propio |") %in% es))
  expect_false(any(grepl("`portales`", es)))
  # Resumen y fichas: número, versión de la fase, familia, fuentes, auxiliar y textos escapados
  expect_true("| 1 | [`renta_a`](#renta_a) | Renta \\*media\\* | € por año | v0.1 |" %in% es)
  expect_true("| 2 | [`alquiler_b`](#alquiler_b) | Alquiler \\| mediana | € por m² | v0.2 |" %in% es)
  expect_true("| Auxiliar | [`contratos_b`](#contratos_b) | Contratos | contratos | v0.1 |" %in% es)
  expect_true("**2 · Alquiler \\| mediana**" %in% es)
  expect_true("- **Fuentes:** `mivau_serpavi`, `ine_adrh`" %in% es)
  expect_true("- **Familia:** Coste de la vivienda" %in% es)
  expect_true("- **Auxiliar de:** [`alquiler_b`](#alquiler_b)" %in% es)
  expect_equal(sum(startsWith(es, "- **Lectura:**")), 2L)           # sin lectura, sin viñeta
  expect_match(es[grepl("^Los ", es)], "Los 2 indicadores del plan y 1 auxiliares", fixed = TRUE)

  en <- diccionario_datos_md(inv$indicadores, inv$vocabulario, inv$fuentes, "en")
  expect_equal(sum(grepl("^#+ ", en)), length(titulos))
  expect_true("| 1 | [`renta_a`](#renta_a) | Mean \\*income\\* | € per year | v0.1 |" %in% en)
  expect_true("- **Auxiliary of:** [`alquiler_b`](#alquiler_b)" %in% en)
  expect_true("| `ine_adrh` | ADRH en |" %in% en)
})

test_that("una fase sin versión del atlas detiene el diccionario", {
  inv <- inventario_falso()
  inv$indicadores$fase[1] <- "F9"
  expect_error(diccionario_datos_md(inv$indicadores, inv$vocabulario, inv$fuentes, "es"), "F9")
})

test_that("exportar_diccionario_datos() escribe los dos idiomas en UTF-8 con LF", {
  inv <- inventario_falso()
  dir <- withr::local_tempdir()
  rutas <- exportar_diccionario_datos(inv$indicadores, inv$vocabulario, inv$fuentes, dir = dir)
  expect_equal(basename(rutas), c("datos_diccionario.md", "data_dictionary.md"))
  bruto <- readBin(rutas[1], "raw", 1e5)
  expect_false(as.raw(13) %in% bruto)
  expect_equal(readLines(rutas[1], encoding = "UTF-8"),
               diccionario_datos_md(inv$indicadores, inv$vocabulario, inv$fuentes, "es"))
})

# El diccionario versionado en docs/ es el que sale del inventario de hoy (si no, tar_make()).
test_that("docs/datos_diccionario.md y docs/data_dictionary.md están al día con el inventario", {
  leer <- function(nombre) readr::read_csv(raiz_proyecto("inventario", nombre), show_col_types = FALSE)
  indicadores <- leer("indicadores.csv")
  dir <- withr::local_tempdir()
  rutas <- exportar_diccionario_datos(indicadores, leer("vocabulario.csv"), leer("fuentes.csv"), dir = dir)
  for (k in seq_along(rutas)) {
    versionado <- raiz_proyecto("docs", basename(rutas[k]))
    expect_true(file.exists(versionado), info = versionado)
    expect_identical(readLines(versionado, encoding = "UTF-8", warn = FALSE),
                     readLines(rutas[k], encoding = "UTF-8", warn = FALSE),
                     info = paste(basename(rutas[k]), "no coincide con el inventario: targets::tar_make()"))
    texto <- readLines(versionado, encoding = "UTF-8", warn = FALSE)
    expect_setequal(sub("^### `(.*)`$", "\\1", texto[grepl("^### `[a-z0-9_]+`$", texto)]),
                    c("estado", "nivel", "corte", "grupo", "fuente", indicadores$codigo))
  }
})

# Textos a mano: docs/datos.md y su traducción, docs/data.md
NOTAS_DATOS <- c(es = "datos.md", en = "data.md")
leer_nota_datos <- function(idioma) readLines(raiz_proyecto("docs", NOTAS_DATOS[[idioma]]), encoding = "UTF-8", warn = FALSE)

# Bloques de código delimitados con ``` de un lenguaje, como texto
bloques_de <- function(lineas, lenguaje = NULL) {
  valla <- which(startsWith(lineas, "```"))
  inicios <- valla[seq(1, length(valla), by = 2)]
  finales <- valla[seq(2, length(valla), by = 2)]
  bloques <- mapply(function(i, f) paste(lineas[seq_len(f - i - 1) + i], collapse = "\n"), inicios, finales)
  lenguajes <- sub("^```", "", lineas[inicios])
  if (is.null(lenguaje)) unname(bloques) else unname(bloques[lenguajes == lenguaje])
}

fuera_de_bloques <- function(lineas) {
  valla <- startsWith(lineas, "```")
  lineas[!((cumsum(valla) %% 2 == 1) | valla)]
}

test_that("datos.md y data.md: misma estructura, mismo código y mismas marcas", {
  es <- leer_nota_datos("es")
  en <- leer_nota_datos("en")
  expect_equal(bloques_de(en), bloques_de(es))
  es_t <- fuera_de_bloques(es)
  en_t <- fuera_de_bloques(en)
  nivel <- function(l) nchar(sub("^(#+).*$", "\\1", l[grepl("^#+ ", l)]))
  expect_equal(nivel(en_t), nivel(es_t))
  expect_equal(sum(grepl("^\\|", en_t)), sum(grepl("^\\|", es_t)))
  expect_equal(sum(grepl("^- ", en_t)), sum(grepl("^- ", es_t)))
  for (marca in c("<!-- descarga -->", "<!-- cita -->", "<!-- cobertura -->")) {
    expect_equal(sum(es_t == marca), 1L, info = marca)
    expect_equal(sum(en_t == marca), 1L, info = marca)
  }
  codigos <- function(l) {
    x <- unique(gsub("`", "", unlist(regmatches(l, gregexpr("`[^`]+`", l)))))
    sort(x[!grepl("^docs/", x)])                                    # sin los nombres de los ficheros de docs/
  }
  expect_equal(codigos(en_t), codigos(es_t))
})

test_that("el modelo de datos nombra las columnas, la clave y los tipos de la tabla larga", {
  dir <- withr::local_tempdir()
  ruta <- exportar_tabla_larga(tibble::tibble(geo_id = "00", nivel = "nacional", anio = 2024L, indicador = "x",
                                              corte = "total", grupo = "total", valor = 1, estado = "dato",
                                              fuente = "f", geo_ref = NA_character_, version = "2026-11-09"),
                               file.path(dir, "t.parquet"))
  esquema <- arrow::open_dataset(ruta)$schema
  tipos <- vapply(esquema$fields, function(f) f$type$ToString(), "")
  names(tipos) <- esquema$names
  for (idioma in names(NOTAS_DATOS)) {
    nota <- leer_nota_datos(idioma)
    filas <- nota[grepl("^\\| `[a-z_]+` \\| ", nota)]
    columnas <- sub("^\\| `([a-z_]+)` \\|.*$", "\\1", filas)
    expect_equal(columnas, COLUMNAS_TABLA_LARGA, info = idioma)
    tipo_nota <- sub("^\\| `[a-z_]+` \\| [^|(]*\\(`([a-z0-9]+)`\\) \\|.*$", "\\1", filas)
    expect_equal(tipo_nota, unname(tipos[columnas]), info = idioma)
    clave <- sub("^.*(La clave es|The key is) ", "", nota[grepl("(La clave es|The key is) ", nota)])
    expect_length(clave, 1)
    expect_equal(gsub("`", "", unlist(regmatches(clave, gregexpr("`[a-z_]+`", clave)))), CLAVE_TABLA_LARGA, info = idioma)
  }
})

test_that("la atribución y la dirección de la descarga son las de LICENCIA_DATOS.md y CITATION.cff", {
  es <- leer_nota_datos("es")
  atribucion <- regmatches(es, regexpr("«De renta en renta \\([^»]+»", es))
  expect_length(atribucion, 1)
  licencia <- paste(readLines(raiz_proyecto("LICENCIA_DATOS.md"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_true(grepl(atribucion, licencia, fixed = TRUE))
  sitio <- yaml::read_yaml(raiz_proyecto("CITATION.cff"))$url
  esperada <- paste0(sub("/?$", "/", sitio), "descargas/tabla_larga.parquet")
  for (idioma in names(NOTAS_DATOS)) {
    direcciones <- unlist(regmatches(leer_nota_datos(idioma), gregexpr("https://[^\"]+\\.parquet", leer_nota_datos(idioma))))
    expect_equal(unique(direcciones), esperada, info = idioma)
  }
})

# Tabla larga inventada para los ejemplos: Madrid (28079) con colectiva y unifamiliar en 2024,
# más filas que el filtro debe dejar fuera (otro año, otro nivel y otro indicador)
larga_ejemplo <- function(dir) {
  exportar_tabla_larga(tibble::tibble(
    geo_id = c("28079", "28079", "28079", "28079", "2807901001", "08019"),
    nivel = c("municipio", "municipio", "municipio", "municipio", "sc", "municipio"),
    anio = c(2024L, 2024L, 2023L, 2024L, 2024L, 2024L),
    indicador = c("alquiler_m2", "alquiler_m2", "alquiler_m2", "alquiler_mes", "alquiler_m2", "alquiler_m2"),
    corte = "tipologia", grupo = c("VC", "VU", "VC", "VC", "VC", "VC"),
    valor = c(14, 9.5, 13.2, 900, 20.1, 17.3), estado = "dato", fuente = "mivau_serpavi", geo_ref = "2021",
    version = "2026-11-06"), file.path(dir, "tabla_larga.parquet"))
}

test_that("el ejemplo de R de la página lee la tabla larga y saca la fila de Madrid", {
  bloques <- bloques_de(leer_nota_datos("es"), "r")
  expect_length(bloques, 2)                                         # la descarga y la lectura
  expect_match(bloques[1], "download.file(", fixed = TRUE)
  dir <- withr::local_tempdir()
  larga_ejemplo(dir)
  # En otro proceso, para no adjuntar arrow en esta sesión de pruebas
  res <- callr::r(function(codigo, dir) {
    setwd(dir)
    as.data.frame(eval(parse(text = codigo), envir = new.env()))
  }, args = list(codigo = bloques[2], dir = dir))
  expect_equal(res, data.frame(geo_id = "28079", valor = 14, estado = "dato"))
})

# Con un Python que tenga pandas y pyarrow (variable PYTHON_PARQUET, o «python» del PATH); si no, se salta.
test_that("el ejemplo de Python de la página lee la tabla larga y saca la fila de Madrid", {
  python <- Sys.getenv("PYTHON_PARQUET", "python")
  disponible <- suppressWarnings(tryCatch(
    system2(python, c("-c", shQuote("import pandas, pyarrow")), stdout = FALSE, stderr = FALSE) == 0,
    error = function(e) FALSE))
  skip_if_not(isTRUE(disponible), "sin Python con pandas y pyarrow (PYTHON_PARQUET)")
  bloques <- bloques_de(leer_nota_datos("es"), "python")
  expect_length(bloques, 2)
  expect_match(bloques[1], "urlretrieve(", fixed = TRUE)
  dir <- withr::local_tempdir()
  larga_ejemplo(dir)
  guion <- file.path(dir, "ejemplo.py")
  writeLines(bloques[2], guion, useBytes = TRUE)
  salida <- withr::with_dir(dir, system2(python, shQuote(guion), stdout = TRUE, stderr = TRUE))
  expect_null(attr(salida, "status"))
  expect_length(grep("28079", salida), 1)
  expect_match(paste(salida, collapse = "\n"), "28079\\s+14\\.0\\s+dato")
})
