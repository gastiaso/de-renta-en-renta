# Prueba de la web en Chrome sin ventana (R/web_navegador.R): la página, servida en local,
# recalcula una muestra y coincide con R (plan §6.5); la portada, la redirección de los enlaces
# viejos de la raíz a mapa.html, la ficha por niveles y la etiqueta del mapa (tareas 24–26). Se
# salta sin chromote, sin Chrome, sin node o sin la exportación del pipeline
# (web/datos/manifiesto.json) y su tabla larga. Tarda alrededor de un minuto y medio.

test_that("tramos de «¿te llega?» como en web/js/sueldo.js", {
  expect_equal(tramo_llega(c(0.1, 0.3, 0.31, 0.4, 0.41)), c(0L, 0L, 1L, 1L, 2L))
})

test_that("parámetros de la consulta de la página, como lista con nombre (tarea 49)", {
  p <- parametros_consulta_navegador("?mapa=alquiler_mes&territorio=municipio%3A28079&vista=11.30/40.42000/-3.70000")
  expect_equal(p, list(mapa = "alquiler_mes", territorio = "municipio:28079", vista = "11.30/40.42000/-3.70000"))
  expect_equal(parametros_consulta_navegador(""), stats::setNames(list(), character(0)))
})

test_that("las páginas que no salen de tar_make() quedan pendientes solo si no existen (tarea 58)", {
  raiz <- tempfile("web")
  dir.create(file.path(raiz, "web", "descargas"), recursive = TRUE)
  expect_equal(paginas_pendientes_navegador(raiz), c("metodo.html", "method.html", "descargas/version.json"))
  writeLines("{}", file.path(raiz, "web", "descargas", "version.json"))
  writeLines("<html></html>", file.path(raiz, "web", "metodo.html"))
  expect_equal(paginas_pendientes_navegador(raiz), "method.html")
  expect_equal(ruta_destino_navegador(c("metodo.html#71-alquiler", "mapa.html?mapa=x", "reglas.html")),
               c("metodo.html", "mapa.html", "reglas.html"))
  url <- "http://127.0.0.1:2345/"
  errores <- c("carga: Failed to load resource: the server responded with a status of 404 (Not Found) http://127.0.0.1:2345/metodo.html",
               "carga: Failed to load resource: the server responded with a status of 404 (Not Found) http://127.0.0.1:2345/descargas/version.json",
               "carga: Failed to load resource: the server responded with a status of 404 (Not Found) http://127.0.0.1:2345/datos/otro.json",
               "excepcion: TypeError 404 http://127.0.0.1:2345/metodo.html")
  expect_equal(error_pendiente_navegador(errores, c("metodo.html", "descargas/version.json"), url), c(TRUE, TRUE, FALSE, FALSE))
  # Con las páginas presentes (o en la web publicada), ningún error se da por pendiente
  expect_equal(error_pendiente_navegador(errores, character(0), url), rep(FALSE, 4))
  expect_equal(error_pendiente_navegador(character(0), "metodo.html", url), logical(0))
})

test_that("la web en un navegador recalcula una muestra y coincide con R (plan §6.5)", {
  raiz <- file.path("..", "..")
  almacen <- file.path(raiz, "_targets")
  skip_if_not_installed("chromote")
  skip_if(is.null(chromote::find_chrome()), "sin Chrome")
  skip_if(!nzchar(Sys.which("node")), "sin node")
  skip_if(!file.exists(file.path(raiz, "web", "datos", "manifiesto.json")), "sin la exportación de la web")
  skip_if(!dir.exists(almacen), "sin el pipeline")
  r <- comprobar_web_navegador(larga = targets::tar_read(tabla_larga, store = almacen),
                               perfiles = targets::tar_read(perfiles, store = almacen), raiz = raiz, muestra = 100L)
  expect_setequal(unique(r$id), c("navegador_arranque", "navegador_errores", "navegador_sueldo", "navegador_fiabilidad",
                                  "navegador_fichas", "navegador_redireccion", "navegador_portada", "navegador_casillas",
                                  "navegador_tu_sueldo", "navegador_movil", "navegador_territorio", "navegador_clic",
                                  "navegador_municipal",    # F5: mapas sin sección y de categorías
                                  "navegador_leyenda",      # tarea 51: juegos de cortes por escala
                                  "navegador_escala_municipio", "navegador_superficie_tipica",
                                  "navegador_una_escala",   # decisiones del autor, 11-nov-2026
                                  "navegador_historias",    # tarea 49: recorridos guiados (sin el fichero, una fila que se salta)
                                  "navegador_carga",        # tarea 62: carga inicial y primer clic
                                  "navegador_residual"))    # tarea 65: línea de ingreso residual
  expect_equal(sum(r$id == "navegador_fichas"), 6L)
  expect_equal(sum(r$id == "navegador_redireccion"), 2L)
  expect_equal(sum(r$id == "navegador_territorio"), 4L)
  expect_equal(sum(r$id == "navegador_clic"), 4L)
  expect_equal(sum(r$id == "navegador_municipal"), 6L)
  expect_equal(sum(r$id == "navegador_leyenda"), 3L)
  expect_equal(sum(r$id == "navegador_residual"), 13L)   # 5 de la parte A, 7 de los remates de la web y la vuelta de la llave (17-nov-2026)
  expect_true(sum(r$id == "navegador_historias") %in% c(1L, 3L))
  expect_true(sum(r$id == "navegador_carga") %in% c(1L, 2L))    # con una exportación anterior a la tarea 62, una fila que se salta
  expect_equal(r$detalle[r$calculado != r$referencia], character(0))
})
