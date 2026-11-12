# Historias (tarea 49; R/web_historias.R): consultas de las cifras (también las de panel constante,
# el IPC y las derivadas), formato en los dos idiomas, relleno de las marcas del texto y de la nota,
# exportación y compuerta. Datos inventados, salvo la última prueba,
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

test_that("prefijo de territorio, panel constante, IPC y cifras derivadas", {
  l <- dplyr::bind_rows(larga_historias(), tibble::tibble(
    geo_id = c("07054", "28079", "29067"), nivel = "municipio", anio = 2015L, indicador = "anios_salario_compra",
    corte = "total", grupo = "total", valor = c(10.69, 9.96, 5), estado = "dato", fuente = "x"))
  m <- function(consulta, geo_id = "", anio = "2024", parametro = "", id = consulta, decimales = 0L) {
    cifra(consulta, indicador = "anios_salario_compra", nivel = "municipio", geo_id = geo_id, anio = anio, grupo = "",
          parametro = parametro, decimales = decimales, id = id)
  }
  derivada <- function(consulta, parametro, id = consulta) {
    cifra(consulta, indicador = "", nivel = "", geo_id = "", anio = "", grupo = "", parametro = parametro, id = id)
  }
  cf <- dplyr::bind_rows(
    m("maximo_geo", geo_id = "13"),                                    # solo los municipios de la provincia 13
    m("cuenta_desde", geo_id = "07", parametro = "10", id = "desde_07"),
    m("panel_n", parametro = ";2015"),                                 # 07054 y 28079: 13071 no tiene 2015 ni 29067, 2024
    m("panel_cuenta_desde", anio = "2015", parametro = "10;2024", id = "panel_sin_redondear"),   # 10,69 (9,96 no llega)
    m("panel_cuenta_desde", anio = "2015", parametro = "10;2024;1", id = "panel_un_decimal"),    # 10,7 y 10,0
    m("panel_cuantil", parametro = "0.5;2015;1"),                      # entre 17,9 y 8,1
    m("panel_cuenta_desde", geo_id = "28", parametro = "8;2015", id = "panel_prefijo"),
    m("panel_n", id = "panel_sin_anio"),
    cifra("ipc_variacion", indicador = "ipc", nivel = "", geo_id = "", anio = "2024", grupo = "", parametro = "2015"),
    m("valor", geo_id = "07054", id = "a", decimales = 1L),            # 17,88: redondeado, 17,9
    m("valor", geo_id = "28079", id = "b"),                            # 8,1: redondeado, 8
    derivada("derivada_variacion", "a;b"), derivada("derivada_diferencia", "a;b"),
    derivada("derivada_diferencia", "a;no_existe", id = "derivada_coja"),
    derivada("derivada_diferencia", "derivada_variacion;b", id = "derivada_de_derivada"))
  ipc <- tibble::tibble(anio = c(2015L, 2024L), indice = c(80, 100))
  r <- historias_calcular(cf, l, historico_historias(), NULL, ipc = ipc)
  v <- stats::setNames(r$calculado, r$id)
  expect_equal(v[["maximo_geo"]], 13071)
  expect_equal(v[["desde_07"]], 1)
  expect_equal(v[["panel_n"]], 2)
  expect_equal(v[["panel_sin_redondear"]], 1)
  expect_equal(v[["panel_un_decimal"]], 2)
  expect_equal(v[["panel_cuantil"]], 13)
  expect_equal(v[["panel_prefijo"]], 1)
  expect_true(is.na(v[["panel_sin_anio"]]))
  expect_equal(v[["ipc_variacion"]], 25)
  expect_equal(v[["derivada_variacion"]], 100 * (17.9 / 8 - 1))   # desde los términos ya redondeados
  expect_equal(v[["derivada_diferencia"]], 17.9 - 8)
  expect_true(is.na(v[["derivada_coja"]]))
  expect_true(is.na(v[["derivada_de_derivada"]]))
  # Sin la tabla del IPC, la cifra queda sin calcular (y la compuerta la para)
  sin_ipc <- historias_calcular(cf[cf$consulta == "ipc_variacion", ], l, historico_historias(), NULL)
  expect_true(is.na(sin_ipc$calculado))
})

test_that("salario minimo: secciones por encima de un umbral (también de una provincia), ingreso de la ficha, carta de la portada y derivada por un número", {
  sc <- c(sprintf("0200301%03d", 1:4), sprintf("2807901%03d", 1:4))
  peso <- function(anio, v) tibble::tibble(geo_id = sc, nivel = "sc", anio = anio, indicador = "peso_alquiler_ingreso",
                                           corte = "ficha", grupo = "tartera", valor = v)
  alquiler <- function(anio, v) tibble::tibble(geo_id = sc, nivel = "sc", anio = anio, indicador = "alquiler_mes",
                                               corte = "tipologia", grupo = "VC", valor = v)
  sueldo <- function(anio) tibble::tibble(geo_id = sc, nivel = "sc", anio = anio, indicador = "sueldo_necesario",
                                          corte = "total", grupo = "total", valor = 2000)
  l <- dplyr::bind_rows(peso(2015L, c(20, 30, 31, 40, 50, 60, 70, 80)), peso(2024L, c(10, 12, 14, 16, 31, 40, 50, 60)),
                        alquiler(2015L, c(200, 210, 220, 230, 400, 500, 600, 700)),
                        alquiler(2024L, c(300, 400, 500, 600, 700, 800, 900, 1000)), sueldo(2015L), sueldo(2024L)) |>
    dplyr::mutate(estado = "dato", fuente = "x")
  perfiles <- tibble::tibble(ficha = "tartera", geo_id = "00", nivel = "nacional", anio = c(2015L, 2024L),
                             ingreso = c(700, 1000), estado = "dato", superficie_m2 = 50)
  s <- function(consulta, geo_id, anio, parametro = "30", id = consulta, ...) {
    cifra(consulta, indicador = "peso_alquiler_ingreso", geo_id = geo_id, anio = anio, grupo = "ficha:tartera",
          parametro = parametro, id = id, ...)
  }
  cf <- dplyr::bind_rows(
    s("secciones_cuota_mayor", "02", "2015", id = "mayor_02"),                # 31 y 40 de 20, 30, 31, 40: el 30 no cuenta
    s("secciones_cuota_desde", "02", "2015", id = "desde_02"),                # con el 30
    s("secciones_cuota_mayor", "28079", "2024", id = "mayor_mad"),
    cifra("perfil_ingreso", indicador = "tartera", nivel = "nacional", geo_id = "00", anio = "2024", grupo = "", id = "neto", decimales = 1L),
    cifra("perfil_ingreso", indicador = "tartera", nivel = "nacional", geo_id = "00", anio = "2030", grupo = "", id = "neto_sin"),
    s("portada_smi", "00", "2015", parametro = "pct_30", id = "carta_2015"),
    s("portada_smi", "00", "2024", parametro = "pct_30", id = "carta_2024"),
    s("portada_smi", "00", "2024", parametro = "pct_30_real", id = "carta_real"),
    s("portada_smi", "00", "2020", parametro = "pct_30", id = "carta_sin_anio"),
    cifra("derivada_por", indicador = "", nivel = "", geo_id = "", anio = "", grupo = "", parametro = "neto;2.4", id = "por"),
    cifra("derivada_por", indicador = "", nivel = "", geo_id = "", anio = "", grupo = "", parametro = "neto;x", id = "por_mal"))
  v <- stats::setNames(historias_calcular(cf, l, historico_historias(), NULL, perfiles = perfiles)$calculado, cf$id)
  expect_equal(v[["mayor_02"]], 50)
  expect_equal(v[["desde_02"]], 75)
  expect_equal(v[["mayor_mad"]], 100)
  expect_equal(v[["neto"]], 1000)
  expect_true(is.na(v[["neto_sin"]]))
  # La carta de la portada, para cada año: la misma definición (más del 30 %), calculada por cifras_portada()
  expect_equal(v[["carta_2015"]], 75)
  expect_equal(v[["carta_2024"]], 50)
  expect_equal(v[["carta_2024"]], suppressWarnings(cifras_portada(l, perfiles = perfiles))$smi$pct_30)   # sin sobrecarga: avisa
  expect_equal(v[["carta_real"]], 100 * mean(c(300, 400, 500, 600, 700, 800, 900, 1000) / 1000 > 0.3))
  expect_true(is.na(v[["carta_sin_anio"]]))   # 2020 no tiene dato: la carta sería la de 2015, y no vale
  expect_equal(v[["por"]], 2400)
  expect_true(is.na(v[["por_mal"]]))
  # Sin perfiles, sin esas cifras (y la compuerta las para)
  sin <- historias_calcular(cf[cf$id %in% c("neto", "carta_2024"), ], l, historico_historias(), NULL)
  expect_true(all(is.na(sin$calculado)))
})

test_that("un paso puede fijar una ficha de perfil, nunca el peón; se exporta en su estado y el enlace a otra historia vale", {
  historias <- tibble::tibble(
    historia = "h", paso = 1:3, historia_titulo_es = c("T", "", ""), historia_titulo_en = c("T", "", ""),
    entradilla_es = c("E", "", ""), entradilla_en = c("E", "", ""), titulo_es = "t", titulo_en = "t",
    texto_es = "x", texto_en = "x", fuente_es = "f", fuente_en = "f",
    mapa = "m1", anio = "2024", vista = "5/40/-3", territorio = "", escala = "",
    enlace = c("mapa.html?historia=centro", "", ""), enlace_es = c("ver", "", ""), enlace_en = c("see", "", ""),
    nota_es = "", nota_en = "", ficha = c("tartera", "", "peon"))
  cf <- tibble::tibble(id = character(), historia = character(), consulta = character(), indicador = character(),
                       calculado = numeric(), decimales = integer(), redactado = numeric())
  manifiesto <- list(mapas = list(m1 = list(base = "s1")),
                     indicadores = list(s1 = list(anios = list(2024L), niveles = list("municipio"), fuente = "mivau_serpavi")))
  comprobar <- function(h, claves = c("mapa", "anio", "vista", "territorio", "escala", "historia", "paso", "ficha")) {
    comprobar_historias(h, cf, manifiesto, claves_estado = claves, anclas = list(), larga = tibble::tibble(indicador = character(), fuente = character()),
                        indicadores = tibble::tibble(codigo = character(), fuentes = character()))
  }
  mal <- function(r, texto) r$calculado[r$id == "historias_estado" & grepl(texto, r$detalle, fixed = TRUE)]
  r <- comprobar(historias)
  expect_equal(mal(r, "fichas que no son de perfil"), 1)   # el peon
  expect_equal(mal(r, "enlaces"), 0)                       # mapa.html con consulta
  expect_equal(mal(r, "claves del recorrido"), 0)
  expect_equal(mal(comprobar(historias, claves = c("mapa", "anio", "vista", "territorio", "escala", "historia", "paso")), "claves del recorrido"), 1)
  bien <- historias[1:2, ]
  expect_equal(sum(comprobar(bien)$calculado[comprobar(bien)$id == "historias_estado"]), 0)
  pasos <- historias_web(bien, cf)[[1]]$pasos
  expect_equal(pasos[[1]]$estado$ficha, "tartera")
  expect_null(pasos[[2]]$estado$ficha)
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

test_that("la nota del paso se rellena y se exporta, y la compuerta también la mira", {
  historias <- tibble::tibble(
    historia = "h", paso = c(1L, 2L), historia_titulo_es = c("T {a}", ""), historia_titulo_en = c("T", ""),
    entradilla_es = c("E", ""), entradilla_en = c("E", ""), titulo_es = "t", titulo_en = "t",
    texto_es = "{a}", texto_en = "{a}", fuente_es = "f", fuente_en = "f",
    mapa = "m1", anio = "2024", vista = "5/40/-3", territorio = "", escala = "",
    enlace = "", enlace_es = "", enlace_en = "",
    nota_es = c("{a} y {b}", "solo en castellano"), nota_en = c("{a}", ""))
  cf <- tibble::tibble(id = "a", historia = "h", consulta = "valor", indicador = "alquiler_mes", calculado = 1234,
                       decimales = 0L, redactado = 1234)
  manifiesto <- list(mapas = list(m1 = list(base = "s1")),
                     indicadores = list(s1 = list(anios = list(2024L), niveles = list("municipio"), fuente = "mivau_serpavi")))
  comprobar <- function(h) {
    comprobar_historias(h, cf, manifiesto, claves_estado = c("mapa", "anio", "vista", "territorio", "escala", "historia", "paso"),
                        anclas = list(), larga = tibble::tibble(indicador = "alquiler_mes", fuente = "mivau_serpavi"),
                        indicadores = tibble::tibble(codigo = "alquiler_mes", fuentes = "mivau_serpavi"))
  }
  r <- comprobar(historias)
  mal <- function(r, texto) r$calculado[r$id == "historias_textos" & grepl(texto, r$detalle, fixed = TRUE)]
  expect_equal(mal(r, "sin cifra"), 1)                 # {b}, solo en la nota
  expect_equal(mal(r, "marcas distintas"), 1)          # paso 1: {b} en castellano y no en inglés
  expect_equal(mal(r, "notas en un solo idioma"), 1)   # paso 2
  expect_equal(mal(r, "no se rellena"), 1)             # {a} en el título de la historia
  expect_equal(sum(r$calculado[r$id %in% c("historias_estado", "historias_privado")]), 0)
  pasos <- historias_web(historias, cf)[[1]]$pasos
  expect_equal(pasos[[1]]$nota, list(es = "1.234 y {b}", en = "1,234"))
  expect_null(pasos[[2]]$nota)                         # sin las dos lenguas, sin nota
  # Sin las columnas de la nota (inventario antiguo), la compuerta no falla por ellas
  sin <- historias[setdiff(names(historias), c("nota_es", "nota_en"))]
  expect_equal(mal(comprobar(sin), "notas en un solo idioma"), 0)
  expect_equal(mal(comprobar(sin), "sin cifra"), 0)
})

test_that("los CSV de inventario/ tienen la forma que esperan la exportación y la compuerta", {
  h <- leer_historias(raiz("inventario", "historias.csv"))
  cf <- leer_historias_cifras(raiz("inventario", "historias_cifras.csv"))
  expect_setequal(unique(h$historia), c("centro", "anios", "minimo", "padres"))
  expect_true(all(h$ficha %in% c("", HISTORIAS_FICHAS)))   # solo fichas de perfil, nunca el peon
  expect_false(any(grepl("entrar", c(h$mapa, cf$indicador))))   # la brecha queda aplazada
  expect_true(all(cf$consulta %in% HISTORIAS_CONSULTAS))
  expect_false(anyDuplicated(cf$id) > 0)
  marcas <- unique(unlist(lapply(c(h$texto_es, h$texto_en, h$nota_es, h$nota_en), historias_marcas)))
  expect_true(all(marcas %in% cf$id))
  expect_true(all(nzchar(h$nota_es) == nzchar(h$nota_en)))   # la nota, en los dos idiomas o en ninguno
  sin_relleno <- c(h$historia_titulo_es, h$historia_titulo_en, h$entradilla_es, h$entradilla_en, h$titulo_es, h$titulo_en)
  expect_false(any(grepl("{", sin_relleno, fixed = TRUE)))   # títulos y entradilla no llevan marcas
  # Las derivadas salen de dos cifras de su misma historia que no son derivadas
  # (derivada_por: una cifra y un numero)
  d <- cf[startsWith(cf$consulta, "derivada_"), ]
  for (i in seq_len(nrow(d))) {
    terminos <- strsplit(d$parametro[i], ";", fixed = TRUE)[[1]]
    expect_length(terminos, 2)
    if (d$consulta[i] == "derivada_por") {
      terminos <- terminos[1]
      expect_false(is.na(suppressWarnings(as.numeric(strsplit(d$parametro[i], ";", fixed = TRUE)[[1]][2]))))
    }
    expect_true(all(terminos %in% cf$id[cf$historia == d$historia[i] & !startsWith(cf$consulta, "derivada_")]))
  }
  # Exportación con las cifras redactadas: misma forma que lee web/js/historias.js
  cf$calculado <- cf$redactado
  d <- withr::local_tempdir()
  j <- jsonlite::read_json(exportar_historias(h, cf, d))
  expect_equal(vapply(j$historias, `[[`, "", "id"), c("centro", "anios", "minimo", "padres"))
  # Un paso con ficha la lleva en su estado; uno sin ella, no
  minimo <- j$historias[[3]]$pasos
  expect_equal(minimo[[1]]$estado$ficha, "tartera")
  expect_null(minimo[[4]]$estado$ficha)
  paso <- j$historias[[1]]$pasos[[3]]
  expect_setequal(names(paso$estado), c("mapa", "anio", "vista", "territorio", "escala"))
  expect_false(grepl("{", paso$texto$es, fixed = TRUE))
  expect_match(j$historias[[1]]$pasos[[2]]$texto$es, "de 600 a 850 € al mes", fixed = TRUE)
  expect_match(j$historias[[1]]$pasos[[2]]$nota$es, "2.421 secciones", fixed = TRUE)
  expect_match(j$historias[[1]]$pasos[[2]]$nota$en, "2,421 tracts", fixed = TRUE)
  expect_false(any(grepl("{", unlist(j$historias), fixed = TRUE)))   # ninguna marca sin rellenar, tampoco en las notas
  expect_null(j$historias[[1]]$pasos[[1]]$enlace)
  expect_equal(j$historias[[2]]$pasos[[1]]$enlace$href, "historico.html#hist-renta")
})
