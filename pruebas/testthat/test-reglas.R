# «Reglas del juego» (tarea 64; R/reglas.R): inventario, lectura del BOE consolidado, compuertas
# reglas_*, exportación a datos/reglas.json, versión publicable sin borradores y señal del calendario.
# Con normas, resúmenes, metadatos y bloques del BOE inventados (misma estructura que la API de
# legislación consolidada), sin red.

# --- Datos inventados ------------------------------------------------------------------------------

normas_inventadas <- function() tibble::tribble(
  ~id, ~nombre_es, ~nombre_en, ~abreviatura_es, ~abreviatura_en, ~rango, ~fecha_disposicion, ~consolidada, ~estado,
  ~efectos_desde, ~resolucion_congreso, ~texto_consultado, ~fecha_actualizacion, ~notas,
  "BOE-A-2099-1", "Ley 1/2099, de prueba", "Ley 1/2099 (Test Act)", "Ley 1/2099", "Test Act", "Ley", "2099-01-01", TRUE,
  "vigente", "2099-01-02", "", "2099-03-01", "2099-02-01T10:00:00Z", "",
  "BOE-A-2099-2", "Real Decreto-ley 2/2099, de prueba", "Real Decreto-ley 2/2099 (Test decree)", "RDL 2/2099", "RDL 2/2099",
  "Real Decreto-ley", "2099-02-02", TRUE, "vigente_pendiente_convalidacion", "2099-02-04", "", "2099-03-01",
  "2099-02-10T10:00:00Z", "",
  "BOE-A-2099-3", "Resolución de prueba", "Test resolution", "Resolución", "Resolution", "Resolución", "2099-01-05", FALSE,
  "vigente", "2099-01-06", "", "2099-03-01", "", ""
)

reglas_inventadas <- function() tibble::tibble(
  id = c("fianza_prueba", "duracion_prueba"), orden = c(1L, 2L),
  titulo_es = c("Fianza", "Duración"), titulo_en = c("Deposit", "Duration"),
  que_dice_es = c("Una mensualidad (art. 1).\nOtra cosa [en el mapa](mapa.html?mapa=alquiler_mes).", "Cinco años."),
  que_dice_en = c("One month (art. 1).\nSomething else [on the map](mapa.html?mapa=alquiler_mes).", "Five years."),
  a_quien_es = c("Contratos de vivienda.", "Contratos de vivienda."), a_quien_en = c("Housing leases.", "Housing leases."),
  cambios_es = c("Sin cambios.", "Real Decreto-ley 2/2099."), cambios_en = c("No changes.", "Royal Decree-law 2/2099."),
  en_el_atlas_es = c("Indicador 8.", "Indicador 9."), en_el_atlas_en = c("Indicator 8.", "Indicator 9."),
  normas = c("BOE-A-2099-1:a1;BOE-A-2099-3", "BOE-A-2099-1:a2;BOE-A-2099-2:a1"),
  indicadores = c("8", "9"), casillas = c("fianza", ""),
  estado = c("vigente", "vigente_pendiente_convalidacion"), vigente_desde = c("2099-01-02", "2099-02-04"),
  texto_consultado = c("2099-03-01", "2099-03-01"), revisado = c("2099-03-02", "borrador")
)

literales_inventados <- function() tibble::tribble(
  ~id, ~ambito, ~objeto, ~norma, ~bloque, ~fragmento, ~sostiene, ~notas,
  "fianza_mes", "regla", "fianza_prueba", "BOE-A-2099-1", "a1", "una mensualidad de renta", "un mes", "",
  "casilla_fianza", "casilla", "fianza", "BOE-A-2099-1", "a1", "fianza en metálico", "Fianza: un mes", ""
)

casillas_inventadas <- function() tibble::tibble(
  orden = 1:2, id = c("fianza", "ley"), texto_es = c("Fianza", "Ley"), texto_en = c("Deposit", "Act"),
  familia = c("alquiler", "especial"), destino = c("reglas.html#fianza-prueba", "reglas.html"), destino_en = c("", ""),
  activa = c(TRUE, TRUE)
)

# Bloque del BOE con dos versiones; la última trae una nota al pie y una redacción con efectos futuros
xml_bloque_inventado <- function(vigente, futura = NULL) {
  ruta <- tempfile(fileext = ".xml")
  futuro <- if (is.null(futura)) "" else paste0(
    "<p class=\"parrafo\">Téngase en cuenta que, con efectos de 1 de enero de 2100, se modifica, con la siguiente redacción:</p>",
    "<p class=\"parrafo\">«", futura, "»</p>")
  writeLines(enc2utf8(paste0(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?><response><status><code>200</code></status><data>",
    "<bloque id=\"a1\" tipo=\"precepto\" titulo=\"Artículo 1\">",
    "<version id_norma=\"BOE-A-2099-1\" fecha_publicacion=\"20990101\" fecha_vigencia=\"20990102\">",
    "<p class=\"articulo\">Artículo 1.</p><p class=\"parrafo\">Texto antiguo derogado.</p></version>",
    "<version id_norma=\"BOE-A-2099-2\" fecha_publicacion=\"20990203\" fecha_vigencia=\"20990204\">",
    "<p class=\"articulo\">Artículo 1. Fianza.</p><p class=\"parrafo\">", vigente, "</p>", futuro,
    "<p class=\"nota_pie\">Se modifica por el Real Decreto-ley 2/2099. Texto de nota.</p></version></bloque></data></response>")),
    ruta, useBytes = TRUE)
  ruta
}

xml_metadatos_inventado <- function(id, actualizacion, derogada = "N", dir) {
  ruta <- reglas_ruta_metadatos(id, dir)
  dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
  writeLines(paste0(
    "<?xml version=\"1.0\" encoding=\"utf-8\"?><response><status><code>200</code></status><data><metadatos>",
    "<fecha_actualizacion>", actualizacion, "</fecha_actualizacion><identificador>", id, "</identificador>",
    "<rango codigo=\"1\">Ley</rango><titulo>Prueba</titulo><fecha_vigencia>20990102</fecha_vigencia>",
    "<estatus_derogacion>", derogada, "</estatus_derogacion><estatus_anulacion>N</estatus_anulacion>",
    "<vigencia_agotada>", derogada, "</vigencia_agotada><url_html_consolidada>https://www.boe.es/buscar/act.php?id=", id,
    "</url_html_consolidada></metadatos></data></response>"), ruta)
  ruta
}

boe_inventado <- function(actualizacion_ley = "2099-02-01 10:00:00", derogada_rdl = FALSE,
                          texto = "Fianza en metálico: una mensualidad de renta en vivienda.") {
  list(
    metadatos = tibble::tibble(norma = c("BOE-A-2099-1", "BOE-A-2099-2"), titulo = "Prueba", rango = "Ley",
                               fecha_actualizacion = as.POSIXct(c(actualizacion_ley, "2099-02-10 10:00:00"), tz = "UTC"),
                               fecha_vigencia = "20990102", derogada = c(FALSE, derogada_rdl), anulada = FALSE,
                               agotada = c(FALSE, derogada_rdl), url = ""),
    indices = tibble::tibble(norma = c("BOE-A-2099-1", "BOE-A-2099-1", "BOE-A-2099-2"), bloque = c("a1", "a2", "a1"),
                             titulo = c("Artículo 1", "Artículo 2", "Artículo 1")),
    textos = tibble::tibble(norma = "BOE-A-2099-1", bloque = "a1", texto = texto)
  )
}

detalle <- function(x, id, patron) x$calculado[x$id == id & grepl(patron, x$detalle, fixed = TRUE)]

# --- Inventario y utilidades -----------------------------------------------------------------------

test_that("normas de una celda, anclas, párrafos y enlaces de los textos", {
  r <- reglas_refs("BOE-A-1994-26003:a36; BOE-A-2024-5213")
  expect_equal(r$norma, c("BOE-A-1994-26003", "BOE-A-2024-5213"))
  expect_equal(r$bloque, c("a36", ""))
  expect_equal(nrow(reglas_refs("")), 0L)
  expect_equal(reglas_ancla("zonas_tensionadas"), "zonas-tensionadas")
  expect_equal(reglas_parrafos("Uno.\r\n\nDos. "), c("Uno.", "Dos."))
  expect_equal(reglas_enlaces_texto("Ver [el BOE](https://www.boe.es/x) y [mapa](mapa.html?mapa=a)."),
               c("https://www.boe.es/x", "mapa.html?mapa=a"))
  expect_true(reglas_destino_valido("https://www.boe.es/buscar/act.php?id=BOE-A-1994-26003#a36", "x"))
  expect_true(reglas_destino_valido("reglas.html#fianza", "fianza"))
  expect_false(reglas_destino_valido("reglas.html#no-existe", "fianza"))
  expect_false(reglas_destino_valido("https://example.com/", "fianza"))
  expect_false(reglas_destino_valido("otra.html", "fianza"))
})

test_that("plazo de convalidación: 30 días hábiles (lunes a viernes) desde el día siguiente", {
  # Promulgado el martes 6-oct-2026: del miércoles 7-oct, 30 días de lunes a viernes acaban el 17-nov
  expect_equal(reglas_plazo_convalidacion("2026-10-06"), as.Date("2026-11-17"))
  expect_true(is.na(reglas_plazo_convalidacion(NA)))
})

test_that("el inventario real se lee y tiene las columnas de la especificación", {
  raiz <- file.path("..", "..")
  reglas <- reglas_leer(file.path(raiz, REGLAS_RUTA))
  normas <- reglas_leer_normas(file.path(raiz, REGLAS_NORMAS_RUTA))
  literales <- reglas_leer_literales(file.path(raiz, REGLAS_LITERALES_RUTA))
  expect_equal(nrow(reglas), 7L)   # los siete temas estatales de la primera tanda
  expect_setequal(reglas$id, c("ley_vivienda", "zonas_tensionadas", "indice_referencia", "duracion_prorroga",
                               "actualizacion_renta", "fianza_garantias", "gastos_contrato"))
  expect_true(all(reglas$estado %in% REGLAS_ESTADOS))
  expect_true(all(normas$estado %in% REGLAS_ESTADOS))
  expect_true(all(literales$ambito %in% c("regla", "casilla")))
  # Sin el BOE: las comprobaciones que no lo necesitan pasan (hoy: la última consulta del inventario, para
  # que la prueba no dependa del reloj ni se rompa al renovar la consulta)
  x <- reglas_comprobar_completo(reglas, normas, hoy = max(as.Date(reglas$texto_consultado)))
  expect_equal(sum(x$calculado[x$id == "reglas_completo"]), 0)
})

# --- BOE -----------------------------------------------------------------------------------------------

test_that("texto vigente de un bloque: última versión, sin notas ni la redacción con efectos futuros", {
  ruta <- xml_bloque_inventado("Fianza en metálico: una mensualidad de renta.", futura = "Fianza de dos mensualidades.")
  texto <- reglas_texto_vigente(ruta)
  expect_true(any(grepl("una mensualidad de renta", texto, fixed = TRUE)))
  expect_false(any(grepl("dos mensualidades", texto, fixed = TRUE)))   # efectos futuros: fuera
  expect_false(any(grepl("Texto de nota", texto, fixed = TRUE)))       # nota al pie: fuera
  expect_false(any(grepl("Texto antiguo", texto, fixed = TRUE)))       # versión anterior: fuera
})

test_that("metadatos del BOE: fecha de actualización y derogación", {
  dir <- tempfile()
  m <- reglas_leer_metadatos(xml_metadatos_inventado("BOE-A-2099-1", "20990201T100000Z", "S", dir))
  expect_equal(m$norma, "BOE-A-2099-1")
  expect_equal(format(m$fecha_actualizacion, "%Y-%m-%d %H:%M", tz = "UTC"), "2099-02-01 10:00")
  expect_true(m$derogada)
  expect_true(m$agotada)
})

# --- Compuertas -------------------------------------------------------------------------------------------

test_that("reglas_completo y reglas_borrador", {
  reglas <- reglas_inventadas()
  normas <- normas_inventadas()
  x <- reglas_comprobar_completo(reglas, normas, hoy = as.Date("2099-03-05"))
  expect_equal(sum(x$calculado[x$id == "reglas_completo"]), 0)
  expect_equal(x$calculado[x$id == "reglas_borrador"], 1)
  # Un texto sin inglés, un enlace fuera de lo permitido y una norma sin fila
  mal <- reglas
  mal$cambios_en[1] <- ""
  mal$que_dice_es[2] <- "Ver [esto](https://example.com/)."
  mal$normas[1] <- "BOE-A-2099-9:a1"
  y <- reglas_comprobar_completo(mal, normas, hoy = as.Date("2099-03-05"))
  expect_equal(detalle(y, "reglas_completo", "textos vac"), 1)
  expect_equal(detalle(y, "reglas_completo", "enlaces de los textos"), 1)
  expect_equal(detalle(y, "reglas_completo", "sin fila en reglas_normas"), 1)
})

test_that("reglas_al_dia: norma al día, actualizada en el BOE después de la consulta", {
  reglas <- reglas_inventadas()
  normas <- normas_inventadas()
  al_dia <- reglas_comprobar_vigencia(reglas, normas, boe_inventado(), hoy = as.Date("2099-03-05"))
  expect_equal(sum(al_dia$calculado), 0)
  actualizada <- reglas_comprobar_vigencia(reglas, normas, boe_inventado("2099-04-01 08:00:00"), hoy = as.Date("2099-03-05"))
  expect_equal(detalle(actualizada, "reglas_al_dia", "actualizadas en el BOE"), 1)
  expect_match(actualizada$detalle[actualizada$id == "reglas_al_dia"][1], "BOE-A-2099-1", fixed = TRUE)
  expect_equal(sum(actualizada$calculado[actualizada$id == "reglas_vigencia"]), 0)
})

test_that("reglas_vigencia: norma derogada, decreto-ley fuera de plazo, efectos futuros llegados, estado distinto", {
  reglas <- reglas_inventadas()
  normas <- normas_inventadas()
  # El BOE da por derogado el decreto-ley del que depende el segundo resumen
  derogada <- reglas_comprobar_vigencia(reglas, normas, boe_inventado(derogada_rdl = TRUE), hoy = as.Date("2099-03-05"))
  expect_equal(detalle(derogada, "reglas_vigencia", "se apoyan en una norma derogada"), 1)
  expect_equal(detalle(derogada, "reglas_vigencia", "estado del inventario distinto del BOE"), 1)
  # Pendiente de convalidación pasado el plazo (30 días hábiles y 10 de margen) sin resolución
  fuera <- reglas_comprobar_vigencia(reglas, normas, boe_inventado(), hoy = as.Date("2099-05-01"))
  expect_equal(detalle(fuera, "reglas_vigencia", "fuera de plazo"), 1)
  con_resolucion <- normas
  con_resolucion$resolucion_congreso[2] <- "BOE-A-2099-99"
  expect_equal(detalle(reglas_comprobar_vigencia(reglas, con_resolucion, boe_inventado(), hoy = as.Date("2099-05-01")),
                       "reglas_vigencia", "fuera de plazo"), 0)
  # Una norma con efectos futuros cuya fecha ya ha llegado
  futura <- normas
  futura$estado[2] <- "con_efectos_futuros"
  futura$efectos_desde[2] <- "2099-03-01"
  llegada <- reglas_comprobar_vigencia(reglas, futura, boe_inventado(), hoy = as.Date("2099-03-05"))
  expect_equal(detalle(llegada, "reglas_vigencia", "efectos futuros que ya han llegado"), 1)
  # El segundo resumen, como vigente sin más, depende de un decreto-ley pendiente
  estado <- reglas
  estado$estado[2] <- "vigente"
  expect_equal(detalle(reglas_comprobar_vigencia(estado, normas, boe_inventado(), hoy = as.Date("2099-03-05")),
                       "reglas_vigencia", "estado distinto del de sus normas"), 1)
})

test_that("reglas_literal: un fragmento que está y otro que no; casillas que llevan a la página sin literal", {
  reglas <- reglas_inventadas()
  casillas <- casillas_inventadas()
  boe <- boe_inventado()
  x <- reglas_comprobar_literales(literales_inventados(), reglas, casillas, boe)
  # «una mensualidad de renta» está; «fianza en metálico» no (el texto dice «Fianza en metálico»)
  expect_equal(detalle(x, "reglas_literal", "no están en el texto vigente"), 1)
  expect_match(x$detalle[1], "casilla_fianza", fixed = TRUE)
  # La casilla «ley» lleva a reglas.html sin literal
  expect_equal(detalle(x, "reglas_literal", "sin literal"), 1)
  bien <- literales_inventados()
  bien$fragmento[2] <- "Fianza en metálico"
  bien <- rbind(bien, tibble::tibble(id = "casilla_ley", ambito = "casilla", objeto = "ley", norma = "BOE-A-2099-1",
                                     bloque = "a1", fragmento = "mensualidad", sostiene = "Ley", notas = ""))
  expect_equal(sum(reglas_comprobar_literales(bien, reglas, casillas, boe)$calculado), 0)
  # Con espacios duros en el BOE, el fragmento se encuentra igual
  duro <- boe_inventado(texto = "Fianza en metálico: una mensualidad de renta.")
  duro$textos$texto <- reglas_normalizar(duro$textos$texto)
  expect_equal(sum(reglas_comprobar_literales(bien, reglas, casillas, duro)$calculado), 0)
})

test_that("reglas_enlaces: anclas de las casillas, casillas e indicadores citados", {
  reglas <- reglas_inventadas()
  reglas$id[1] <- "zonas_tensionadas"   # REGLAS_ANCLAS_WEB
  casillas <- casillas_inventadas()
  casillas$destino[1] <- "reglas.html#zonas-tensionadas"
  indicadores <- tibble::tibble(id = c(8, 9), codigo = c("a", "b"))
  expect_equal(sum(reglas_comprobar_enlaces(reglas, casillas, indicadores)$calculado), 0)
  casillas$destino[1] <- "reglas.html#no-existe"
  reglas$indicadores[2] <- "99"
  x <- reglas_comprobar_enlaces(reglas, casillas, indicadores)
  expect_equal(detalle(x, "reglas_enlaces", "ancla que no existe"), 2)   # castellano e inglés
  expect_equal(detalle(x, "reglas_enlaces", "indicadores citados"), 1)
})

# --- Web y publicación -----------------------------------------------------------------------------------

test_that("datos/reglas.json: ida y vuelta, borradores marcados y versión publicable sin su texto", {
  dir <- tempfile()
  zonas <- tibble::tibble(ccaa = c("09", "09"), declaracion = c("Orden A", "Orden A"), url_declaracion = c("https://a", "https://a"))
  ccaa <- tibble::tibble(codigo = "09", nombre_ine = "Cataluña", nuts2 = "ES51")
  ruta <- reglas_exportar_web(reglas_inventadas(), normas_inventadas(), boe_inventado(), zonas, ccaa, dir_web = dir,
                              generado = as.Date("2099-03-05"))
  expect_equal(sum(reglas_comprobar_web(reglas_inventadas(), normas_inventadas(), ruta)$calculado), 0)
  j <- jsonlite::read_json(ruta)
  expect_equal(j$borradores, 1L)
  expect_equal(j$reglas[[1]]$ancla, "fianza-prueba")
  expect_false(j$reglas[[1]]$borrador)
  expect_true(j$reglas[[2]]$borrador)
  expect_equal(j$reglas[[1]]$normas[[1]]$titulo, "Artículo 1")
  expect_equal(j$reglas[[1]]$normas[[1]]$url, "https://www.boe.es/buscar/act.php?id=BOE-A-2099-1#a1")
  expect_equal(j$reglas[[1]]$normas[[2]]$url, "https://www.boe.es/diario_boe/txt.php?id=BOE-A-2099-3")   # sin consolidar
  expect_length(j$declaraciones[[1]]$declaraciones, 1L)   # sin repetir
  # Un texto cambiado en el fichero: la compuerta lo ve
  j2 <- j
  j2$reglas[[1]]$que_dice$es[[1]] <- "Otra cosa."
  reglas_escribir_json(j2, ruta)
  expect_equal(detalle(reglas_comprobar_web(reglas_inventadas(), normas_inventadas(), ruta), "web_reglas", "textos distintos"), 1)
  # Versión publicable: el borrador, solo con su título y en revisión
  p <- reglas_para_publicar(j)
  expect_equal(reglas_borradores_con_texto(j), 1)
  expect_equal(reglas_borradores_con_texto(p), 0)
  expect_true(p$reglas[[2]]$en_revision)
  expect_null(p$reglas[[2]]$que_dice)
  expect_equal(p$reglas[[2]]$titulo$es, "Duración")
  expect_equal(p$reglas[[1]]$que_dice$es, j$reglas[[1]]$que_dice$es)
  # En revisión salen, como hechos, sus normas citadas y la fecha del texto consultado (23-nov-2026)
  expect_equal(p$reglas[[2]]$normas, j$reglas[[2]]$normas)
  expect_equal(p$reglas[[2]]$texto_consultado, j$reglas[[2]]$texto_consultado)
  expect_setequal(names(p$reglas[[2]]), c("id", "ancla", "orden", "titulo", "normas", "texto_consultado", "en_revision"))
})

test_that("empaquetar: el .tar.gz no lleva texto en borrador y el fichero local se restaura", {
  dir <- tempfile()
  ruta <- reglas_exportar_web(reglas_inventadas(), normas_inventadas(), boe_inventado(), dir_web = dir)
  original <- readLines(ruta, encoding = "UTF-8")
  tar <- tempfile(fileext = ".tar.gz")
  reglas_publicables(dir, function() tar_datos_publicacion(dir, file.path("datos", FICHERO_REGLAS_WEB), tar))
  expect_equal(reglas_borradores_en_tar(tar), 0)
  expect_identical(readLines(ruta, encoding = "UTF-8"), original)   # la web local sigue con los borradores
  expect_equal(reglas_borradores_con_texto(jsonlite::read_json(ruta)), 1)
})

# --- Calendario -------------------------------------------------------------------------------------------

test_that("señal del calendario: avisa cuando el BOE ha actualizado una norma citada", {
  raiz <- tempfile()
  dir.create(file.path(raiz, "inventario"), recursive = TRUE)
  readr::write_csv(normas_inventadas(), file.path(raiz, REGLAS_NORMAS_RUTA))
  cache <- file.path(raiz, REGLAS_DIR_BOE)
  xml_metadatos_inventado("BOE-A-2099-1", "20990201T100000Z", dir = cache)
  xml_metadatos_inventado("BOE-A-2099-2", "20990210T100000Z", dir = cache)
  expect_equal(reglas_senal_calendario(raiz), "")
  xml_metadatos_inventado("BOE-A-2099-1", "20990401T080000Z", dir = cache)
  expect_match(reglas_senal_calendario(raiz), "BOE-A-2099-1", fixed = TRUE)
  # En el calendario, la fila boe_legislacion toca por el aviso aunque no toque por fechas
  cal <- tibble::tibble(id = "boe_legislacion", cadencia = "continua", meses_publicacion = NA_character_,
                        dia_publicacion = NA_integer_, desfase_dias = NA_integer_, meses_dato = NA_character_,
                        ultimo_dato = NA_character_, url_calendario = NA_character_, objetivos = "metadatos_boe_reglas",
                        ficheros = "datos/brutos/boe_legislacion/", renovar = "mover", cambio_codigo = NA_character_, notas = "")
  p <- cal_fuentes_pendientes(cal, hoy = as.Date("2099-04-02"), raiz = raiz)
  expect_true(p$toca)
  expect_match(p$aviso, "BOE-A-2099-1", fixed = TRUE)
  expect_match(cal_firma(p), "^boe_legislacion:aviso ")
  # Sin la señal registrada (otra fuente), nada cambia
  expect_equal(cal_senal_externa("ine_ipc", raiz), "")
  # Caducidad de la caché de metadatos
  expect_false(reglas_boe_caducado(file.path(raiz, REGLAS_NORMAS_RUTA), cache, dias = 7, ahora = Sys.time()))
  expect_true(reglas_boe_caducado(file.path(raiz, REGLAS_NORMAS_RUTA), cache, dias = 7, ahora = Sys.time() + 8 * 86400))
})
