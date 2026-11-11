# CIS, la vivienda como problema (R/fuente_cis_barometros.R; F6): JSON-LD de la página de un
# barómetro, elección del documento, lectura de los resultados en HTML y del bloque de las
# tabulaciones, compuerta y JSON de la web. Ficheros inventados con la forma de los del CIS.

ld_inventado <- function(estudio = "3999", documentos = c("Cuestionario", "Resultados HTML", "Resultados PDF")) {
  dist <- paste(sprintf('{"contentUrl":"https://www.cis.es/documents/20117/1/%s_%d.x","@type":"DataDownload","name":"%s"}',
                        estudio, seq_along(documentos), documentos), collapse = ",")
  sprintf('{"@graph":[{"identifier":"%s","@type":"Report","license":"https://creativecommons.org/licenses/by/4.0/"},{"identifier":"%s","@type":"Dataset","datePublished":"2026-03-20T06:00:00Z","license":"https://creativecommons.org/licenses/by/4.0/","distribution":[%s]}],"@context":"https://schema.org"}',
          estudio, estudio, dist)
}

marginales_inventadas <- function(ruta, vivienda = c("5,1", "4,0", "2,9", "12,0"), personal = c("3,0", "-", "1,0", "4,0")) {
  fila <- function(etiqueta, v) paste0("<tr><td>", etiqueta, "</td>", paste0("<td>", v, "</td>", collapse = ""), "</tr>")
  tabla <- function(v) paste0(
    "<table><tbody><tr><td>&nbsp;</td><td>Primer problema</td><td>Segundo problema</td><td>Tercer problema</td><td>TOTAL</td></tr>",
    fila("El paro", c("20,0", "10,0", "5,0", "35,0")),
    fila("La vivienda", v),
    fila("La ocupación de viviendas", c("0,2", "0,1", "-", "0,3")),
    fila("(N)", rep("(2.471)", 4)), "</tbody></table>")
  writeLines(enc2utf8(c(
    "<html><head><meta charset=\"utf-8\"></head><body>",
    "<p><b>Pregunta 6</b><br>¿Cree Ud. que dentro de un año la situación será mejor?</p>",
    "<table><tr><td>Mejor</td><td>12,4</td></tr><tr><td>(N)</td><td>(2.471)</td></tr></table>",
    "<p><b>Pregunta 7</b><br>¿Cuál es, a su juicio, el principal problema que existe actualmente en\nEspaña? ¿Y el segundo? ¿Y el tercero?</p>",
    tabla(vivienda),
    "<p><b>Pregunta 8</b><br>¿Y cuál es el problema que a Ud., personalmente, le afecta más?</p>",
    tabla(personal),
    "</body></html>")), ruta, useBytes = TRUE)
  ruta
}

test_that("cis_json_ld y cis_documentos: documentos, estudio, fecha y licencia del barómetro", {
  html <- paste0("<html><script type=\"application/ld+json\">{\"@type\":\"WebPage\"}</script>\n",
                 "<script type=\"application/ld+json\">\n", ld_inventado(), "\n</script></html>")
  ld <- cis_json_ld(html)
  expect_match(ld, "Dataset")
  ruta <- file.path(tempfile("cis"), "2026-03.json"); dir.create(dirname(ruta))
  writeLines(ld, ruta)
  docs <- cis_documentos(ruta)
  expect_equal(nrow(docs), 3L)
  expect_equal(unique(docs$estudio), "3999")
  expect_equal(unique(docs$anio), 2026L); expect_equal(unique(docs$mes), 3L)
  expect_equal(unique(docs$publicado), "2026-03-20")
  expect_match(unique(docs$licencia), "by/4.0")
  expect_null(cis_json_ld("<html>sin datos</html>"))
})

test_that("cis_elegir_documento: tabulaciones XLSX antes que HTML; solo PDF, nada", {
  d <- function(nombres) tibble::tibble(documento = nombres, url = paste0("u_", seq_along(nombres)))
  expect_equal(cis_elegir_documento(d(c("Resultados PDF", "Tabulaciones XLSX", "Resultados HTML")))$formato, "xlsx")
  expect_equal(cis_elegir_documento(d(c("Resultados PDF", "Resultados HTML")))$formato, "html")
  expect_null(cis_elegir_documento(d(c("Resultados PDF", "Cuestionario"))))
})

test_that("cis_numero: coma decimal y miles con punto en el HTML, punto decimal en el XLSX, guion es cero", {
  expect_equal(cis_numero(c("3,4", "-", "(2.989)", "12,0"), "html"), c(3.4, 0, 2989, 12))
  expect_equal(cis_numero(c("18.972956", "4017.0", "-"), "xlsx"), c(18.972956, 4017, 0))
  expect_equal(cis_numero("(4.017)", "xlsx"), 4017)
})

test_that("cis_leer_html: «La vivienda» de las dos preguntas, sin confundirla con la ocupación de viviendas", {
  ruta <- marginales_inventadas(tempfile(fileext = ".html"))
  v <- cis_leer_html(ruta)
  expect_equal(v$pregunta, c("espana", "personal"))
  expect_equal(v$total, c(12.0, 4.0))
  expect_equal(v$primero, c(5.1, 3.0))
  expect_equal(v$segundo, c(4.0, 0))          # «-» es cero
  expect_equal(v$n, c(2471, 2471))
  expect_true(all(v$categoria))
})

test_that("cis_valores_bloque con la forma de las tabulaciones XLSX (cabecera sin etiqueta, «Total»)", {
  m <- rbind(c("", "Primer problema", "Segundo problema", "Tercer problema", "Total"),
             c("La crisis económica", "10.5", "8.25", "3", "21.75"),
             c("La vivienda", "18.972956152125345", "12.968873306170247", "7.919351725660009", "39.861181183955686"),
             c("(N)", "4017.0", "4017.0", "4017.0", "4017.0"),
             c("Otra pregunta", "", "", "", ""))
  v <- cis_valores_bloque(m, "xlsx")
  expect_equal(v$total, 39.861181183955686)
  expect_equal(v$n, 4017)
  # sin la fila de la vivienda (nadie la cita): cero y marcada
  v0 <- cis_valores_bloque(m[-3, ], "xlsx")
  expect_equal(v0$total, 0); expect_false(v0$categoria)
  # sin cabecera reconocible: nada
  expect_null(cis_valores_bloque(m[-1, ], "xlsx"))
})

test_that("cis_valores_bloque: disposición traspuesta y cabeceras con sufijo", {
  # problemas en columnas (septiembre de 2019 en HTML; septiembre de 2025 en XLSX), sin (N)
  tras <- rbind(c(" ", "El paro", "La vivienda"),
                c("Primer problema", "20,0", "0,5"), c("Segundo problema", "10,0", "0,9"),
                c("Tercer problema", "5,0", "1,0"), c("TOTAL", "35,0", "2,4"),
                c("Otra fila", "x", "y"))
  v <- cis_valores_bloque(tras, "html")
  expect_equal(c(v$primero, v$segundo, v$tercero, v$total), c(0.5, 0.9, 1.0, 2.4))
  expect_true(is.na(v$n))
  # cabeceras «[recod.]» (2024) y celdas con saltos de línea
  rec <- rbind(c("", "Primer problema [recod.]", "Segundo problema [recod.]", "Tercer problema [recod.]", "TOTAL"),
               c("La\nvivienda", "10,1", "8,0", "5,0", "23,1"), c("(N)", "(4.032)", "(4.032)", "(4.032)", "(4.032)"))
  v2 <- cis_valores_bloque(rec, "html")
  expect_equal(v2$total, 23.1); expect_equal(v2$n, 4032)
})

barometros_inventados <- function() {
  base <- tibble::tibble(anio = 2026L, estudio = c("3540", "3540", "3567", "3567", "3577", "3577", "3560"),
                         mes = c(1L, 1L, 7L, 7L, 9L, 9L, 5L), publicado = "2026-09-14", licencia = "cc",
                         formato = c(rep("xlsx", 6), "pdf"),
                         pregunta = c("espana", "personal", "espana", "personal", "espana", "personal", NA),
                         total = c(42.6249, 28.21, 43.0, 30, 37.4501, 27.9, NA),
                         n = c(4000, 4000, 4000, 4000, 4000, 4000, NA), categoria = c(rep(TRUE, 6), NA))
  dplyr::mutate(base, primero = total / 2, segundo = total / 3, tercero = total - total / 2 - total / 3)
}

test_that("cis_comprobar_vivienda: notas de prensa, suma de menciones, rango y huecos", {
  r <- cis_comprobar_vivienda(barometros_inventados())
  pub <- r[r$id == "cis_vivienda_publicada", ]
  expect_equal(nrow(pub), nrow(CIS_REFERENCIAS))
  expect_equal(pub$calculado, pub$referencia)          # redondeo a un decimal: 42,6; 28,2; 37,5; 27,9; 43,0
  expect_equal(max(r$calculado[r$id == "cis_vivienda_suma"]), 0, tolerance = 1e-9)
  expect_equal(sum(r$calculado[r$id == "cis_vivienda_rango"]), 0)
  expect_equal(sum(r$id == "cis_vivienda_cobertura"), 1L)     # mayo, solo PDF
  expect_equal(sort(r$detalle[r$id == "cis_vivienda_meses"]),  # sin estudio: febrero, marzo, abril y junio (agosto no cuenta)
               paste(c("2026-02", "2026-03", "2026-04", "2026-06"), "sin barómetro encontrado"))
  # una nota cuyo mes falta (julio) pasa a la alerta de cobertura con su cifra; sin ninguna, bloqueo
  sin_julio <- dplyr::filter(barometros_inventados(), mes != 7L)
  r3 <- cis_comprobar_vivienda(sin_julio)
  expect_false(anyNA(r3$calculado[r3$id == "cis_vivienda_publicada"]))
  expect_true(any(grepl("43 % sin contrastar", r3$detalle[r3$id == "cis_vivienda_cobertura"])))
  r4 <- cis_comprobar_vivienda(dplyr::filter(barometros_inventados(), mes == 5L))
  expect_true(all(is.na(r4$calculado[r4$id == "cis_vivienda_publicada"])))
  # un mes con una sola pregunta y una cifra imposible
  mal <- barometros_inventados()[-2, ]
  mal$total[1] <- 142.6
  r2 <- cis_comprobar_vivienda(mal)
  expect_gt(sum(r2$calculado[r2$id == "cis_vivienda_rango"]), 1)
})

test_that("cis_exportar_vivienda y cis_comprobar_web: ida y vuelta con un decimal", {
  serie <- cis_serie_vivienda(barometros_inventados())
  expect_equal(nrow(serie), 6L)
  dir_web <- tempfile("web")
  ruta <- cis_exportar_vivienda(serie, dir_web)
  expect_equal(basename(ruta), "cis_vivienda.json")
  x <- jsonlite::read_json(ruta, simplifyVector = TRUE)
  expect_equal(x$series$espana$periodo, c("2026-01", "2026-07", "2026-09"))
  expect_equal(x$series$espana$valor, c(42.6, 43.0, 37.5))
  expect_equal(sum(cis_comprobar_web(serie, ruta)$calculado), 0)
  expect_equal(x$series$espana$estudio[1], serie$estudio[serie$pregunta == "espana"][1])
  expect_type(x$series$espana$n, "integer")
  serie$total[1] <- 50
  expect_equal(sum(cis_comprobar_web(serie, ruta)$calculado), 1)
  # el estudio y las entrevistas que ensena el globo de la pagina, tambien de ida y vuelta
  serie <- cis_serie_vivienda(barometros_inventados())
  serie$estudio[1] <- "9999"
  serie$n[2] <- serie$n[2] + 1
  expect_equal(sum(cis_comprobar_web(serie, ruta)$calculado), 2)
  # un JSON sin las entrevistas no pasa
  sin_n <- jsonlite::read_json(ruta)
  sin_n$series$espana$n <- NULL
  jsonlite::write_json(sin_n, ruta, auto_unbox = TRUE, digits = NA)
  expect_equal(cis_comprobar_web(cis_serie_vivienda(barometros_inventados()), ruta)$calculado[1], Inf)
})

test_that("cis_comprobacion_acceso reconoce la página con la que el CIS frena a los robots", {
  expect_true(cis_comprobacion_acceso("<title>Comprobación de acceso | Centro de Investigaciones Sociológicas</title>"))
  expect_false(cis_comprobacion_acceso("<title>Estudio | CIS</title>"))
})

test_that("meses solo en PDF: la transcripción llena el hueco y su compuerta (pregunta 48 a)", {
  tr <- tibble::tibble(anio = 2026L, mes = 5L, estudio = "3560", pregunta = c("espana", "personal"),
                       pregunta_cis = c("Pregunta 10R", "Pregunta 11R"), pagina = c(5L, 7L),
                       total = c(30, 20.1), primero = c(14, 9), segundo = c(10, 7), tercero = c(6, 4), n = 4000,
                       url_pdf = "https://www.cis.es/documents/20117/1/es3560mar.pdf", bytes_pdf = 1, sha256_pdf = "x",
                       comprobacion = "inventada")
  b <- barometros_inventados()
  completos <- cis_aplicar_transcripcion(b, tr)
  mayo <- completos[completos$mes == 5L, ]
  expect_equal(sort(mayo$pregunta), c("espana", "personal"))
  expect_equal(unique(mayo$formato), "pdf_transcrito")
  expect_equal(mayo$total[mayo$pregunta == "espana"], 30)
  r <- cis_comprobar_vivienda(completos)
  expect_equal(sum(r$id == "cis_vivienda_cobertura"), 0L)          # el hueco de mayo ya no está
  expect_equal(sum(cis_comprobar_transcripcion(b, tr)$calculado), 0)
  expect_equal(nrow(cis_serie_vivienda(completos)), 8L)
  # Una transcripción que pisa un mes abierto, de otro estudio, que no suma o con un enlace ajeno
  mal <- dplyr::bind_rows(tr, dplyr::mutate(tr, mes = 1L, estudio = "3540"))
  mal$total[2] <- 25
  mal$url_pdf[1] <- "https://ejemplo.invalid/es3560mar.pdf"
  c2 <- cis_comprobar_transcripcion(b, mal)
  expect_equal(c2$calculado, c(2, 0, 0, 1, 3))   # enero: el enlace tampoco nombra su estudio
  # Sin transcripción, nada cambia
  expect_identical(cis_aplicar_transcripcion(b, tr[0, ]), b)
})

test_that("la transcripción del inventario: seis meses, dos preguntas, sumas y enlaces del CIS", {
  tr <- cis_leer_transcripcion(file.path("..", "..", "inventario", "cis_transcripcion_pdf.csv"))
  expect_equal(nrow(tr), 12L)
  expect_setequal(unique(paste(tr$anio, tr$mes)), c("2014 7", "2025 2", "2025 4", "2025 5", "2025 6", "2025 7"))
  expect_true(all(abs(tr$total - (tr$primero + tr$segundo + tr$tercero)) <= 0.2 + 1e-9))
  expect_true(all(startsWith(tr$url_pdf, "https://www.cis.es/documents/")))
  expect_true(all(mapply(grepl, tr$estudio, basename(tr$url_pdf), fixed = TRUE)))
  expect_true(all(nchar(tr$sha256_pdf) == 64L))
})
