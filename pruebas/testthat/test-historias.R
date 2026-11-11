# Primeras historias (tarea 49; R/web_historias.R): consultas de las cifras, formato en los dos
# idiomas, relleno de las marcas, exportación y compuerta. Datos inventados, salvo la última prueba,
# que lee los dos CSV de inventario/ y comprueba su forma sin el almacén de targets.

raiz <- function(...) file.path("..", "..", ...)

larga_historias <- function() {
  secciones <- tibble::tibble(
    geo_id = c(sprintf("2807901%03d", 1:10), sprintf("0801901%03d", 1:4)),
    nivel = "sc", anio = 2024L, indicador = "alquiler_mes", corte = "tipologia", grupo = "VC",
    valor = c(500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 650, 700, 750, 2000))
  # Las mismas secciones en el percentil 75: no deben entrar en las cuentas de tipologia:VC
  p75 <- dplyr::mutate(secciones, corte = "tipologia_p75", valor = valor * 2)
  municipios <- tibble::tibble(
    geo_id = c("07054", "13071", "28079", "00"), nivel = c("municipio", "municipio", "municipio", "nacional"),
    anio = 2024L, indicador = "anios_salario_compra", corte = "total", grupo = "total", valor = c(17.88, 2.2, 8.1, 6.13))
  dplyr::bind_rows(secciones, p75, municipios) |> dplyr::mutate(estado = "dato", fuente = "x")
}

historico_historias <- function() {
  tibble::tibble(serie = "anios_renta", geo_id = "00", nivel = "nacional", frecuencia = "trimestral",
                 anio = c(2007L, 2007L, 2011L, 2015L, 2026L, 2026L), subperiodo = c(2L, 3L, 1L, 1L, 1L, 2L),
                 valor = c(9.3, 9.46, 8.44, 6.59, 8.05, 8.36))
}

cifra <- function(consulta, indicador = "alquiler_mes", nivel = "sc", geo_id = "28079", anio = "2024",
                  grupo = "tipologia:VC", parametro = "", decimales = 0L, id = consulta) {
  tibble::tibble(id = id, historia = "h", consulta = consulta, indicador = indicador, nivel = nivel, geo_id = geo_id,
                 anio = anio, grupo = grupo, parametro = parametro, decimales = decimales, redactado = 0, nota = "")
}

test_that("las consultas de la tabla larga cuentan solo el corte y el grupo pedidos", {
  cortes <- tibble::tibble(indicador = "alquiler_mes", juego = "seccion", cortes = "325;400;450;500;600;700")
  cf <- dplyr::bind_rows(
    cifra("secciones_n"), cifra("secciones_mediana"), cifra("secciones_cuantil", parametro = "0.9"),
    cifra("secciones_cuota_desde", parametro = "700"), cifra("secciones_n", geo_id = "00", id = "n_es"),
    cifra("corte_mayor", nivel = "seccion", grupo = ""),
    cifra("valor", indicador = "anios_salario_compra", nivel = "nacional", geo_id = "00", grupo = ""),
    cifra("maximo_geo", indicador = "anios_salario_compra", nivel = "municipio", geo_id = "", grupo = ""),
    cifra("minimo_geo", indicador = "anios_salario_compra", nivel = "municipio", geo_id = "", grupo = ""),
    cifra("cuenta_desde", indicador = "anios_salario_compra", nivel = "municipio", geo_id = "", grupo = "", parametro = "8"),
    cifra("cociente_p90_p10", indicador = "anios_salario_compra", nivel = "municipio", geo_id = "", grupo = ""),
    cifra("consulta_que_no_existe"))
  r <- historias_calcular(cf, larga_historias(), historico_historias(), cortes)
  v <- stats::setNames(r$calculado, r$id)
  expect_equal(v[["secciones_n"]], 10)
  expect_equal(v[["secciones_mediana"]], 950)
  expect_equal(v[["secciones_cuantil"]], stats::quantile(seq(500, 1400, 100), 0.9, names = FALSE))
  expect_equal(v[["secciones_cuota_desde"]], 80)
  expect_equal(v[["n_es"]], 14)
  expect_equal(v[["corte_mayor"]], 700)
  expect_equal(v[["valor"]], 6.13)
  expect_equal(v[["maximo_geo"]], 7054)
  expect_equal(v[["minimo_geo"]], 13071)
  expect_equal(v[["cuenta_desde"]], 2)
  expect_equal(v[["cociente_p90_p10"]], stats::quantile(c(17.88, 2.2, 8.1), 0.9, names = FALSE) /
                 stats::quantile(c(17.88, 2.2, 8.1), 0.1, names = FALSE))
  expect_true(is.na(v[["consulta_que_no_existe"]]))
})

test_that("las consultas del histórico: valor, máximo, mínimo desde un año, último y el más alto desde", {
  h <- function(consulta, anio = "", parametro = "") {
    cifra(consulta, indicador = "anios_renta", nivel = "nacional", geo_id = "00", anio = anio, grupo = "", parametro = parametro)
  }
  cf <- dplyr::bind_rows(h("hist_valor", "2007", "2"), h("hist_maximo"), h("hist_maximo_anio"), h("hist_maximo_subperiodo"),
                         h("hist_minimo_desde", "2008"), h("hist_minimo_desde_anio", "2008"), h("hist_ultimo"),
                         h("hist_ultimo_subperiodo"), h("hist_mayor_desde_anio"), h("hist_mayor_desde_subperiodo"))
  v <- stats::setNames(historias_calcular(cf, larga_historias(), historico_historias(), NULL)$calculado, cf$consulta)
  expect_equal(unname(v), c(9.3, 9.46, 2007, 3, 6.59, 2015, 8.36, 2, 2011, 1))
})

test_that("cifras con los separadores de cada idioma y empates hacia arriba", {
  expect_equal(historias_formatear(2421, 0, "es"), "2.421")
  expect_equal(historias_formatear(2421, 0, "en"), "2,421")
  expect_equal(historias_formatear(2.95701, 1, "es"), "3,0")
  expect_equal(historias_formatear(9.45, 1, "en"), "9.5")
  cf <- tibble::tibble(id = c("a", "b"), calculado = c(1234.5, NA), decimales = c(1L, 0L))
  expect_equal(historias_rellenar("{a} y {b} y {c}", cf, "es"), "1.234,5 y {b} y {c}")
})

test_that("la compuerta encuentra marcas sin cifra, vistas imposibles y la oferta privada", {
  historias <- tibble::tibble(
    historia = "h", paso = c(1L, 2L), historia_titulo_es = c("T", ""), historia_titulo_en = c("T", ""),
    entradilla_es = c("E", ""), entradilla_en = c("E", ""), titulo_es = "t", titulo_en = "t",
    texto_es = c("{a}", "{a} {z}"), texto_en = c("{a}", "{a}"), fuente_es = "f", fuente_en = "f",
    mapa = c("m1", "precio_oferta"), anio = c("2024", "2030"), vista = c("5/40/-3", "mal"),
    territorio = c("municipio:28079", ""), escala = c("municipio", ""),
    enlace = c("historico.html#hist-renta", "historico.html#no-existe"), enlace_es = "ver", enlace_en = "see")
  cf <- tibble::tibble(id = "a", historia = "h", consulta = "valor", indicador = "alquiler_mes", calculado = 1.04,
                       decimales = 1L, redactado = 1.1)
  manifiesto <- list(
    mapas = list(m1 = list(base = "s1", juegos = list(municipio = list())), precio_oferta = list(base = "s2")),
    indicadores = list(s1 = list(anios = list(2024L), niveles = list("municipio"), fuente = "mivau_serpavi"),
                       s2 = list(anios = list(2024L), niveles = list("municipio"), fuente = "portales")))
  r <- comprobar_historias(historias, cf, manifiesto, claves_estado = c("mapa", "anio", "vista", "territorio", "escala"),
                           anclas = list(historico.html = "hist-renta"),
                           larga = tibble::tibble(indicador = "alquiler_mes", fuente = "mivau_serpavi"),
                           indicadores = tibble::tibble(codigo = c("alquiler_mes", "precio_oferta"), fuentes = c("mivau_serpavi", "portales")))
  mal <- function(id, texto) r$calculado[r$id == id & grepl(texto, r$detalle, fixed = TRUE)]
  expect_equal(r$calculado[r$id == "historias_cifras"], 1)   # 1,04 redondeado a 1,0 frente a 1,1 redactado
  expect_equal(mal("historias_textos", "sin cifra"), 1)
  expect_equal(mal("historias_textos", "marcas distintas"), 1)
  expect_equal(mal("historias_estado", "fuera de la serie"), 1)
  expect_equal(mal("historias_estado", "formato"), 1)
  expect_equal(mal("historias_estado", "sin juego de cortes"), 1)
  expect_equal(mal("historias_estado", "claves del recorrido"), 2)   # historia y paso
  expect_equal(mal("historias_estado", "enlaces"), 1)
  expect_equal(mal("historias_privado", "mapa de la oferta"), 1)
})

test_that("los CSV de inventario/ tienen la forma que esperan la exportación y la compuerta", {
  h <- leer_historias(raiz("inventario", "historias.csv"))
  cf <- leer_historias_cifras(raiz("inventario", "historias_cifras.csv"))
  expect_setequal(unique(h$historia), c("centro", "anios"))
  expect_false(any(grepl("entrar", c(h$mapa, cf$indicador))))   # la brecha queda aplazada
  expect_true(all(cf$consulta %in% HISTORIAS_CONSULTAS))
  expect_false(anyDuplicated(cf$id) > 0)
  marcas <- unique(unlist(lapply(c(h$texto_es, h$texto_en), historias_marcas)))
  expect_true(all(marcas %in% cf$id))
  # Exportación con las cifras redactadas: misma forma que lee web/js/historias.js
  cf$calculado <- cf$redactado
  d <- withr::local_tempdir()
  j <- jsonlite::read_json(exportar_historias(h, cf, d))
  expect_equal(vapply(j$historias, `[[`, "", "id"), c("centro", "anios"))
  paso <- j$historias[[1]]$pasos[[3]]
  expect_setequal(names(paso$estado), c("mapa", "anio", "vista", "territorio", "escala"))
  expect_false(grepl("{", paso$texto$es, fixed = TRUE))
  expect_match(j$historias[[1]]$pasos[[2]]$texto$es, "2.421 secciones", fixed = TRUE)
  expect_match(j$historias[[1]]$pasos[[2]]$texto$en, "2,421 tracts", fixed = TRUE)
  expect_null(j$historias[[1]]$pasos[[1]]$enlace)
  expect_equal(j$historias[[2]]$pasos[[1]]$enlace$href, "historico.html#hist-renta")
})
