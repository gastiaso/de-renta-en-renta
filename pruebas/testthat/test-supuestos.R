# Módulo de supuestos (tarea 48; R/comun_supuestos.R): inventario/supuestos.csv como fuente única de
# R y de la web, superficie típica del SERPAVI, cuentas de la muestra y compuerta. Datos inventados,
# salvo la muestra de pruebas/datos/supuestos_muestra.json (términos reales de 2024), cuyos casos
# comprueba también pruebas/web/supuestos.test.mjs: R y la página coinciden.

raiz <- function(...) file.path("..", "..", ...)

# SERPAVI inventado (vivienda colectiva): dos secciones, un municipio y una comunidad en 2024; una
# sección en secreto. La fila de vivienda unifamiliar no se usa.
serpavi_supuestos <- function() {
  base <- tibble::tribble(
    ~geo_id,      ~nivel,      ~mes,   ~m2,   ~estado,
    "2800101001", "sc",        900.04, 15.04, "dato",
    "2800101002", "sc",        NA,     NA,    "secreto",
    "28001",      "municipio", 850,    14,    "estimado",
    "13",         "ccaa",      800,    12,    "dato"
  )
  dplyr::bind_rows(
    dplyr::transmute(base, geo_id, nivel, anio = 2024L, indicador = "alquiler_mes", corte = "tipologia", grupo = "VC", valor = mes, estado),
    dplyr::transmute(base, geo_id, nivel, anio = 2024L, indicador = "alquiler_m2", corte = "tipologia", grupo = "VC", valor = m2, estado),
    dplyr::transmute(base, geo_id, nivel, anio = 2024L, indicador = "alquiler_m2", corte = "tipologia", grupo = "VU", valor = 1, estado = "dato")
  ) |> dplyr::mutate(fuente = "mivau_serpavi", geo_ref = "2021", version = "2026-11-06")
}

perfiles_supuestos <- tibble::tribble(
  ~ficha,       ~nivel,      ~geo_id, ~anio, ~ingreso, ~estado,
  "tartera",    "nacional",  "00",    2024L, 1237.4,   "dato",
  "mochila",    "provincia", "28",    2024L, 1500,     "estimado",
  "transistor", "provincia", "28",    2024L, 1700,     "dato"
)

muestra_inventada <- tibble::tibble(geo_id = c("2800101001", "2800101002", "28001", "13"),
                                    nivel = c("sc", "sc", "municipio", "ccaa"))

test_that("inventario/supuestos.csv: completo, sin repetidos y con cada valor entre sus opciones", {
  s <- leer_supuestos(raiz("inventario", "supuestos.csv"))
  expect_false(anyDuplicated(s$id) > 0)
  for (id in s$id[nzchar(s$opciones)]) {
    expect_true(all(supuestos_numeros(s$valor[s$id == id]) %in% supuesto_opciones(id, s)), info = id)
  }
  expect_true(all(nzchar(s$unidad) & nzchar(s$uso) & nzchar(s$decision) & nzchar(s$descripcion)))
  expect_error(supuesto("no_existe", s), "falta el supuesto")
  expect_error(supuesto("superficie_tipica", s), "no es un n")   # es un método, no una cifra
})

test_that("las constantes de R salen del CSV, con el mismo valor y tipo que tenían", {
  expect_identical(SUPERFICIE_FICHA, 50)
  expect_identical(UMBRAL_SUELDO, 0.30)
  expect_identical(LIMITES_LLEGA, c(0.3, 0.4))
  expect_identical(ENTRAR_SUPERFICIE_DOS, 70)
  expect_identical(SUPERFICIE_COMPRA, 80)
  expect_identical(FINANCIACION_COMPRA, 0.80)
  expect_identical(PLAZO_HIPOTECA, 25)
  expect_identical(SUPUESTOS_WEB, list(superficie_m2 = 50, umbral = 0.3))
  expect_identical(eval(formals(entrar_tramo_llega)$limites), LIMITES_LLEGA)
})

test_that("web/js/supuestos.js es el que genera R desde el CSV", {
  expect_identical(readLines(raiz("web", "js", "supuestos.js"), encoding = "UTF-8"), enc2utf8(texto_supuestos_js()))
  tmp <- tempfile(fileext = ".js")
  generar_supuestos_js(ruta = tmp)
  expect_false(any(grepl("\r", readChar(tmp, file.size(tmp), useBytes = TRUE), fixed = TRUE)))   # LF
})

test_that("superficie típica: alquiler mensual / alquiler por m², con los términos redondeados y el peor estado", {
  st <- superficie_tipica_serpavi(serpavi_supuestos())
  expect_equal(st$valor[st$geo_id == "2800101001"], 900 / 15)   # 900,04 y 15,04 se publican como 900,0 y 15,0
  expect_equal(st$valor[st$geo_id == "28001"], 850 / 14)
  expect_equal(st$estado[st$geo_id == "28001"], "estimado")
  expect_true(is.na(st$valor[st$geo_id == "2800101002"]))
  expect_equal(nrow(st), 4)
})

test_that("muestra: cada combinación de «Tu ficha» y las tres fichas de una persona", {
  ter <- muestra_supuestos(serpavi_supuestos(), perfiles_supuestos, muestra_inventada, anio = 2024L)
  expect_equal(ter$ingreso_mochila, c(1500, 1500, 1500, NA))   # en la comunidad, sin ingreso provincial
  casos <- calcular_muestra_supuestos(ter)
  peon <- casos[casos$ficha == "peon", ]
  expect_equal(nrow(peon), 4 * 5 * 2 * 2 * 2)
  m <- peon[peon$geo_id == "28001", ]
  uno <- function(eleccion, umbral, pagas, segundo) m[m$eleccion == eleccion & m$umbral == umbral & m$pagas == pagas & m$segundo == segundo, ]
  # Por defecto: 50 m² con un sueldo y 70 con dos; 1.500 € en 12 pagas, o 2.500 € en 14 pagas.
  expect_equal(uno("defecto", 0.3, 12, FALSE)$superficie, 50)
  expect_equal(uno("defecto", 0.3, 12, TRUE)$superficie, 70)
  expect_equal(uno("90", 0.3, 14, TRUE)$ingreso, 2500 * 14 / 12)
  x <- uno("50", 0.4, 12, FALSE)
  expect_equal(c(x$alquiler, x$ratio, x$tramo, x$sueldo_minimo, x$sueldo_real, x$euros), c(700, 700 / 1500, 2, 1750, 2125, 800))
  # Con la superficie típica, el alquiler es el mensual real y el sueldo necesario mínimo, el principal.
  t <- uno("tipica", 0.3, 12, FALSE)
  expect_equal(t$superficie, 850 / 14)
  expect_equal(t$sueldo_minimo, t$sueldo_real)
  # Las secciones toman la superficie típica de su municipio, como la web (decisión del autor, 11-nov-2026)
  expect_equal(ter$superficie_tipica[ter$nivel == "sc"], rep(850 / 14, 2))
  s1 <- peon[peon$geo_id == "2800101001" & peon$eleccion == "tipica" & peon$umbral == 0.3 & peon$pagas == 12 & !peon$segundo, ]
  expect_equal(c(s1$superficie, s1$alquiler), c(850 / 14, 15 * 850 / 14))   # 15 €/m² de la sección × la típica de 28001
  fichas <- casos[casos$ficha != "peon" & casos$geo_id == "28001", ]
  expect_equal(fichas$ratio, 14 * 50 / c(1237.4, 1500, 1700))
  expect_equal(supuestos_tramo_llega(c(0.3, 0.30001, 0.4, 0.41)), c(0L, 1L, 1L, 2L))
  expect_equal(redondear_como_js(c(2.5, -2.5, 1.49)), c(3, -2, 1))
})

test_that("pruebas/datos/supuestos_muestra.json: R reproduce sus casos", {
  ruta <- raiz("pruebas", "datos", "supuestos_muestra.json")
  skip_if_not(file.exists(ruta))
  j <- jsonlite::fromJSON(ruta)
  ter <- tibble::as_tibble(j$terminos)
  expect_equal(nrow(ter), nrow(MUESTRA_SUPUESTOS))
  casos <- calcular_muestra_supuestos(ter)
  expect_equal(nrow(casos), nrow(j$casos))
  for (col in c("superficie", "ingreso", "alquiler", "ratio", "sueldo_minimo", "sueldo_real", "euros", "tramo")) {
    expect_equal(casos[[col]], j$casos[[col]], tolerance = 1e-12, info = col)
  }
})

test_that("compuerta: pasa con los supuestos del CSV y avisa si la web o una constante se apartan", {
  ls_ <- serpavi_supuestos()
  ter <- muestra_supuestos(ls_, perfiles_supuestos, muestra_inventada, anio = 2024L)
  ld <- dplyr::bind_rows(calcular_sueldo_necesario(ls_), calcular_peso_alquiler_ingreso(ls_, perfiles_supuestos))
  tmp <- tempfile(fileext = ".json")
  escribir_muestra_supuestos(ter, ruta = tmp)
  st <- superficie_tipica_serpavi(ls_)
  r <- comprobar_supuestos(leer_supuestos(raiz("inventario", "supuestos.csv")), ter, ld, st,
                           ruta_js = raiz("web", "js", "supuestos.js"), ruta_mapa = raiz("web", "mapa.html"),
                           ruta_muestra = tmp)
  v <- function(id) r$calculado[r$id == id]
  expect_equal(c(v("supuestos_inventario"), v("supuestos_r"), v("supuestos_web"), v("supuestos_muestra_fichero")), c(0, 0, 0, 0))
  expect_lt(v("supuestos_muestra_21"), 1e-9)
  expect_lt(v("supuestos_muestra_15"), 1e-9)
  expect_equal(v("supuestos_superficie_tipica_rango"), 0)
  # Un CSV con otro umbral por defecto: el JS y las constantes ya no cuadran.
  s <- leer_supuestos(raiz("inventario", "supuestos.csv"))
  s$valor[s$id == "umbral_sueldo"] <- "0.40"
  r2 <- comprobar_supuestos(s, ter, ld, st, ruta_js = raiz("web", "js", "supuestos.js"),
                            ruta_mapa = raiz("web", "mapa.html"), ruta_muestra = tmp)
  expect_gt(r2$calculado[r2$id == "supuestos_r"], 0)
  expect_gt(r2$calculado[r2$id == "supuestos_web"], 0)
})
