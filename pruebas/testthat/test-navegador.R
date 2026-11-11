# Prueba de la web en Chrome sin ventana (R/web_navegador.R): la página, servida en local,
# recalcula una muestra y coincide con R (plan §6.5); la portada, la redirección de los enlaces
# viejos de la raíz a mapa.html, la ficha por niveles y la etiqueta del mapa (tareas 24–26). Se
# salta sin chromote, sin Chrome, sin node o sin la exportación del pipeline
# (web/datos/manifiesto.json) y su tabla larga. Tarda alrededor de un minuto y medio.

test_that("tramos de «¿te llega?» como en web/js/sueldo.js", {
  expect_equal(tramo_llega(c(0.1, 0.3, 0.31, 0.4, 0.41)), c(0L, 0L, 1L, 1L, 2L))
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
                                  "navegador_una_escala"))  # decisiones del autor, 11-nov-2026
  expect_equal(sum(r$id == "navegador_fichas"), 6L)
  expect_equal(sum(r$id == "navegador_redireccion"), 2L)
  expect_equal(sum(r$id == "navegador_territorio"), 4L)
  expect_equal(sum(r$id == "navegador_clic"), 4L)
  expect_equal(sum(r$id == "navegador_municipal"), 6L)
  expect_equal(sum(r$id == "navegador_leyenda"), 3L)
  expect_equal(r$detalle[r$calculado != r$referencia], character(0))
})
