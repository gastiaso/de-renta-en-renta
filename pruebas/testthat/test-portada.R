# Portada (web/index.html; R/web_portada.R; docs/especificacion_portada.md): casillas desde su CSV,
# cifras de las cartas (portada.json) y sus compuertas, con datos inventados.
# Ejecutar desde la raíz del proyecto: testthat::test_dir("pruebas/testthat")

raiz_portada <- function(...) file.path("..", "..", ...)

# Tabla larga y perfiles inventados: 11 secciones con alquiler por m² (vivienda colectiva) en 2024,
# una sin dato; su sueldo necesario y su barrera con la tartera; sobrecarga de España de 2025.
larga_portada <- function() {
  m2 <- c(4.2, 5.04, 6, 7.3, 8, 9.1, 10, 11.55, 12.7, 14, 20, NA)
  sc <- sprintf("28079%05d", seq_along(m2))
  estado <- ifelse(is.na(m2), "secreto", "dato")
  base <- tibble::tibble(geo_id = sc, nivel = "sc", anio = 2024L, estado = estado)
  mes <- m2 * 70   # tarea 40: el alquiler mensual, de pisos de 70 m²
  alquiler <- bind_rows(base |> mutate(indicador = "alquiler_m2", corte = "tipologia", grupo = "VC", valor = m2),
                        base |> mutate(indicador = "alquiler_mes", corte = "tipologia", grupo = "VC", valor = mes))
  sueldo <- bind_rows(base |> mutate(indicador = "sueldo_necesario", corte = "total", grupo = "total",
                                     valor = termino_publicado(mes) / 0.3),
                      base |> mutate(indicador = "sueldo_necesario", corte = "superficie", grupo = "50",
                                     valor = termino_publicado(m2) * 50 / 0.3))
  barrera <- base |> mutate(indicador = "peso_alquiler_ingreso", corte = "ficha", grupo = "tartera",
                            valor = 100 * termino_publicado(m2) * 50 / 1000)
  sobrecarga <- tibble::tibble(geo_id = "00", nivel = "nacional", anio = c(2024L, 2025L, 2025L),
                               indicador = "sobrecarga", corte = c("total", "total", "tenencia"),
                               grupo = c("total", "total", "RENT_MKT"), valor = c(7.77, 7.17202, 26.796451), estado = "dato")
  bind_rows(alquiler, sueldo, barrera, sobrecarga)
}

perfiles_portada <- function() {
  tibble::tibble(ficha = "tartera", geo_id = "00", nivel = "nacional", anio = c(2023L, 2024L),
                 ingreso = c(950, 1000), estado = "dato", superficie_m2 = 50)
}

test_that("las casillas del CSV cumplen las reglas de la especificación", {
  cs <- leer_casillas_portada(raiz_portada("inventario", "casillas_portada.csv"))
  r <- comprobar_casillas_portada(cs, claves_estado = claves_estado_web(raiz_portada("web", "js", "estado.js")))
  expect_equal(r$calculado, r$referencia, label = paste(r$detalle, collapse = "; "))
  expect_equal(sum(cs$orden %in% ESQUINAS_PORTADA), 4L)
  # Las esquinas, casillas especiales fuera de las cuatro familias; la de inicio no es «Salida», sino
  # el salario de The Landlord's Game, y otra, su parque público (decisión del autor, 12-nov-2026)
  expect_equal(cs$familia[cs$orden %in% ESQUINAS_PORTADA], rep(FAMILIA_ESPECIAL, 4))
  expect_true(all(cs$familia[!cs$orden %in% ESQUINAS_PORTADA] %in% FAMILIAS_PORTADA))
  expect_true(cs$texto_es[cs$orden == ESQUINA_INICIO] == "Cobra la nómina")
  expect_true("Parque público" %in% cs$texto_es[cs$orden %in% ESQUINAS_PORTADA])
  # Etiquetas que la portada no puede llevar (especificación, §2): ni «dos meses» de fianza, ni la
  # agencia a cargo de quien alquila, ni nombres propios de Monopoly
  prohibidas <- "dos meses|agencia|salida|la banca|suerte|caja de comunidad|sube el ipc"
  expect_false(any(grepl(prohibidas, cs$texto_es, ignore.case = TRUE)))
  expect_true("Fianza: un mes" %in% cs$texto_es)
})

test_that("la compuerta de las casillas detecta destinos mal puestos", {
  cs <- leer_casillas_portada(raiz_portada("inventario", "casillas_portada.csv"))
  mal <- cs
  mal$destino[mal$id == "notaria"] <- "mapa.html"                  # inactiva con destino
  mal$destino[mal$id == "paga_alquiler"] <- "mapa.html?mapa=no_existe"
  mal$destino[mal$id == "mudanza"] <- "mapa.html?clave_rara=1"
  mal$destino[mal$id == "fianza"] <- "metodo.html#no-existe"
  mal$id[2] <- mal$id[1]
  mal$familia[mal$orden == 7] <- "barrio"                          # esquina sin la familia especial
  mapas <- c("sueldo_necesario", "alquiler_mes", "viviendas_turisticas", "hogares_alquiler", "zona_tensionada",
             "var_alquiler", "anios_salario_compra", "esfuerzo_hipotecario")
  anclas <- list(metodo.html = "71-alquiler-indicadores-8-y-9", method.html = "71-rent-indicators-8-and-9")
  claves <- claves_estado_web(raiz_portada("web", "js", "estado.js"))
  expect_true(all(comprobar_casillas_portada(cs, mapas = mapas, anclas = anclas, claves_estado = claves)$calculado ==
                    c(24, rep(0, 12))))
  r <- comprobar_casillas_portada(mal, mapas = mapas, anclas = anclas, claves_estado = claves)
  fallos <- r$detalle[r$calculado != r$referencia]
  expect_setequal(fallos, c("ids repetidos", "inactivas con destino", "mapas que no están en el manifiesto",
                            "claves del mapa que no son de estado.js", "anclas que no están en su página",
                            "esquinas sin la familia especial o especiales fuera de las esquinas"))
})

test_that("el destino en inglés lleva el idioma o la página inglesa", {
  expect_equal(destino_ingles("mapa.html?mapa=alquiler_mes"), "mapa.html?mapa=alquiler_mes&idioma=en")
  expect_equal(destino_ingles("mapa.html#tu-sueldo"), "mapa.html?idioma=en#tu-sueldo")
  expect_equal(destino_ingles("mapa.html?superficie=70#tu-sueldo"), "mapa.html?superficie=70&idioma=en#tu-sueldo")
  expect_equal(destino_ingles("sobrecarga.html"), "sobrecarga.html?idioma=en")
  expect_equal(destino_ingles("datos.html"), "data.html")
  expect_equal(destino_ingles("metodo.html#a", "method.html#b"), "method.html#b")
  expect_equal(destino_ingles(""), "")
})

test_that("las casillas se escriben en el HTML entre sus marcas, sin enlace las inactivas", {
  cs <- leer_casillas_portada(raiz_portada("inventario", "casillas_portada.csv"))
  li <- html_casillas_portada(cs)
  expect_length(li, 24L)
  inactivas <- li[!cs$activa[order(cs$orden)]]
  expect_false(any(grepl("<a ", inactivas)))
  expect_true(all(grepl("portada.proximamente", inactivas, fixed = TRUE)))
  expect_true(all(grepl("data-href-en=", li[cs$activa[order(cs$orden)]], fixed = TRUE)))
  expect_true(any(grepl("&amp;idioma=en", li, fixed = TRUE)))
  # Una sola casilla de inicio (la primera); las cuatro esquinas, especiales
  expect_equal(which(grepl("casilla-inicio", li, fixed = TRUE)), ESQUINA_INICIO)
  expect_equal(which(grepl("casilla-especial", li, fixed = TRUE)), ESQUINAS_PORTADA)

  tmp <- tempfile(fileext = ".html")
  writeLines(c("<ol>", paste0("  ", MARCAS_CASILLAS[["inicio"]]), "  <li>viejo</li>", paste0("  ", MARCAS_CASILLAS[["fin"]]), "</ol>"), tmp)
  escribir_casillas_portada(cs, tmp)
  html <- readLines(tmp, encoding = "UTF-8")
  expect_length(html, 24L + 4L)
  expect_false(any(grepl("viejo", html)))
  antes <- tools::md5sum(tmp)
  escribir_casillas_portada(cs, tmp)          # idempotente
  expect_equal(unname(tools::md5sum(tmp)), unname(antes))
  writeLines("<ol></ol>", tmp)
  expect_error(escribir_casillas_portada(cs, tmp), "Marcas")
})

test_that("web/index.html lleva las casillas del CSV (escribir_casillas_portada() al día)", {
  cs <- leer_casillas_portada(raiz_portada("inventario", "casillas_portada.csv"))
  html <- readLines(raiz_portada("web", "index.html"), encoding = "UTF-8", warn = FALSE)
  i <- grep(MARCAS_CASILLAS[["inicio"]], html, fixed = TRUE)
  f <- grep(MARCAS_CASILLAS[["fin"]], html, fixed = TRUE)
  expect_length(i, 1L)
  expect_equal(trimws(html[(i + 1):(f - 1)]), trimws(html_casillas_portada(cs)))
})

test_that("portada.json lleva las cifras de las cartas y la compuerta las reproduce", {
  larga <- larga_portada()
  dir <- tempfile("web_")
  ruta <- exportar_portada(larga, perfiles_portada(), dir_web = dir)
  p <- jsonlite::read_json(ruta)$cartas
  s <- larga$valor[larga$indicador == "sueldo_necesario" & larga$corte == "total" & !is.na(larga$valor)]
  minimo <- larga$valor[larga$indicador == "sueldo_necesario" & larga$corte == "superficie" & !is.na(larga$valor)]
  expect_equal(p$sueldo$secciones, 11L)
  expect_equal(p$sueldo$mediana, redondeo_guia(stats::median(s)))
  expect_equal(p$sueldo$p10, redondeo_guia(stats::quantile(s, 0.1, names = FALSE)))
  expect_equal(p$sueldo$minimo, redondeo_guia(stats::median(minimo)))   # tarea 40: el mínimo de 50 m², al lado
  expect_gt(p$sueldo$mediana, p$sueldo$minimo)
  expect_equal(p$sueldo$anio, 2024L)
  expect_equal(p$smi$neto_mensual, 1000)
  # Ratio > 30 % con 1.000 €: m² > 6 (de 7,3 a 20: 8 de 11; 6 da el 30 % justo y no pasa);
  # > 40 %: m² > 8 (de 9,1 a 20: 6 de 11; 8 da el 40 % justo)
  expect_equal(p$smi$pct_30, redondeo_guia(100 * 8 / 11))
  expect_equal(p$smi$pct_40, redondeo_guia(100 * 6 / 11))
  # Con el alquiler mensual real (m² × 70): > 300 € en 10 de 11 y > 400 € en 9 de 11
  expect_equal(p$smi$pct_30_real, redondeo_guia(100 * 10 / 11))
  expect_equal(p$smi$pct_40_real, redondeo_guia(100 * 9 / 11))
  expect_equal(p$sobrecarga, list(anio = 2025L, total = 7.2, alquiler_mercado = 26.8, fuentes = list("ine_ecv")))

  r <- comprobar_portada(larga, perfiles_portada(), dir_web = dir)
  expect_equal(r$calculado, r$referencia, label = paste(r$detalle, collapse = "; "))
  expect_true(all(r$id == "portada_valores"))

  # Una cifra cambiada o una carta que falta no pasan
  j <- jsonlite::read_json(ruta)
  j$cartas$smi$pct_40 <- 50
  j$cartas$sueldo$minimo <- 1
  j$cartas$sobrecarga <- NULL
  writeLines(jsonlite::toJSON(j, auto_unbox = TRUE, digits = NA), ruta)
  r2 <- comprobar_portada(larga, perfiles_portada(), dir_web = dir)
  mal <- r2$detalle[is.na(r2$calculado) | r2$calculado != r2$referencia]
  expect_true(all(c("salario mínimo: más del 40 %", "sobrecarga: total", "sueldo: mínimo de 50 m2 (mediana)") %in% mal))
})

test_that("sin el ingreso de la tartera de ese año, la carta del salario mínimo no se exporta", {
  perf <- perfiles_portada() |> filter(anio == 2023L)
  ruta <- exportar_portada(larga_portada(), perf, dir_web = tempfile("web_"))
  expect_null(jsonlite::read_json(ruta)$cartas$smi)
})

test_that("los iconos de las fichas de la web son los de diseno/fichas", {
  for (f in c("llave", "mochila", "tartera", "transistor", "peon")) {
    expect_equal(unname(tools::md5sum(raiz_portada("web", "estilo", "fichas", paste0(f, ".svg")))),
                 unname(tools::md5sum(raiz_portada("diseno", "fichas", paste0(f, ".svg")))), label = f)
    expect_false(any(grepl("<metadata", readLines(raiz_portada("web", "estilo", "fichas", paste0(f, ".svg")), warn = FALSE))))
  }
})

test_that("las bandas de las familias contrastan al menos 3:1 con la crema", {
  css <- paste(readLines(raiz_portada("web", "estilo", "portada.css"), encoding = "UTF-8"), collapse = "\n")
  tokens <- paste(readLines(raiz_portada("web", "estilo", "tokens.css"), encoding = "UTF-8"), collapse = "\n")
  hex <- function(var) regmatches(tokens, regexec(paste0("--", var, ":\\s*(#[0-9a-fA-F]{6})"), tokens))[[1]][2]
  crema <- hex("color-crema")
  for (familia in FAMILIAS_PORTADA) {
    var <- regmatches(css, regexec(paste0("\\.casilla-", familia, " \\{ --banda: var\\(--([a-z-]+)\\); \\}"), css))[[1]][2]
    expect_false(is.na(var), label = familia)
    expect_gte(contraste_wcag(hex(var), crema), 3)
  }
})

test_that("solo la esquina de inicio va en rojo; las otras tres, en beige con texto en tinta", {
  css <- paste(readLines(raiz_portada("web", "estilo", "portada.css"), encoding = "UTF-8"), collapse = "\n")
  tokens <- paste(readLines(raiz_portada("web", "estilo", "tokens.css"), encoding = "UTF-8"), collapse = "\n")
  hex <- function(var) regmatches(tokens, regexec(paste0("--", var, ":\\s*(#[0-9a-fA-F]{6})"), tokens))[[1]][2]
  fondo <- function(selector) {
    regmatches(css, regexec(paste0("(^|\\n)", gsub(".", "\\.", selector, fixed = TRUE),
                                   " \\{[^}]*background: var\\(--([a-z-]+)\\)"), css))[[1]][3]
  }
  expect_equal(fondo(".casilla-especial"), "color-beige")
  expect_equal(fondo(".casilla-inicio"), "color-rojo")
  # Ninguna otra regla pinta de rojo las esquinas
  expect_false(grepl("\\.casilla-esquina[^{]*\\{[^}]*color-rojo", css))
  expect_gte(contraste_wcag(hex("color-tinta"), hex("color-beige")), 4.5)
  expect_gte(contraste_wcag(hex("color-tenue"), hex("color-beige")), 4.5)   # la inactiva, «próximamente»
  expect_gte(contraste_wcag("#ffffff", hex("color-rojo")), 4.5)
})

test_that("las claves del estado de la vista se leen de estado.js", {
  claves <- claves_estado_web(raiz_portada("web", "js", "estado.js"))
  expect_true(all(c("idioma", "mapa", "seccion", "comparar", "vista", "territorio", "superficie") %in% claves))
})
