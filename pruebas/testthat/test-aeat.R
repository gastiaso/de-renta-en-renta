# AEAT, «Mercado de trabajo y pensiones» (R/fuente_aeat_mercado.R) y serie de la mochila
# (R/ficha_mochila.R). Páginas y cifras inventadas con la estructura de las de la AEAT.

pagina_aeat <- function(filtros, filas, menus = list()) {
  titulo <- paste(c("Mercado de trabajo y pensiones: 2024:", "Tabla de prueba",
                    paste(paste0(names(filtros), ": ", unlist(filtros)), collapse = "\n,\n")), collapse = "\n")
  menu <- paste0('<nav aria-label="Filtros" class="nav"><ul role="menubar">',
                 paste(vapply(names(menus), function(d) paste0(
                   '<li><a role="menuitem" href="#">', d, '</a><ul aria-label="', d, '" role="menu">',
                   paste0('<li><a href="', menus[[d]], '" role="menuitem">', names(menus[[d]]), "</a></li>", collapse = ""),
                   "</ul></li>"), ""), collapse = ""), "</ul></nav>")
  cuerpo <- paste0(vapply(seq_along(filas), function(i) paste0(
    '<tr><th id="t_f', i, '"><div class="depth_div_', filas[[i]]$nivel, '">', filas[[i]]$fila, "</div></th>",
    '<td headers="t_c1 t_c3 t_f', i, '">', filas[[i]]$a, "</td>",
    '<td headers="t_c1 t_c4 t_f', i, '">', filas[[i]]$b, "</td></tr>"), ""), collapse = "")
  paste0("<html><head><title>", titulo, "</title></head><body>", menu,
         '<table><thead><tr><th id="t_cornerR0C0" rowspan="2">Esquina</th><th id="t_c1" colspan="2">Total</th></tr>',
         '<tr><th id="t_c3">Número</th><th id="t_c4">SME</th></tr></thead>', cuerpo, "</table></body></html>")
}

test_that("las páginas de la AEAT se leen con sus filtros, sangrías y cabeceras de dos niveles", {
  ruta <- tempfile(fileext = ".html")
  writeLines(pagina_aeat(list(`Distribución geográfica` = "Aragón", `Género` = "Total"),
                         list(list(fila = "Total", nivel = 0, a = "14.187.169", b = "32.078"),
                              list(fila = "Huesca ", nivel = 2, a = "1,39", b = "-")),
                         menus = list(`Género` = c(Total = "jrubik1.html", Varón = "jrubik2.html"))),
             ruta, useBytes = TRUE)
  h <- xml2::read_html(ruta)
  expect_equal(aeat_titulo(h)$tabla, "Tabla de prueba")
  expect_equal(aeat_titulo(h)$filtros, c(`Distribución geográfica` = "Aragón", `Género` = "Total"))
  expect_equal(aeat_menus(h)$valor, c("Total", "Varón"))
  d <- leer_aeat_mercado(ruta)
  expect_equal(d$valor, c(14187169, 32078, 1.39, NA))
  expect_equal(unique(d$columna), c("Total · Número", "Total · SME"))
  expect_equal(d$fila[3], "Huesca")
  expect_equal(d$nivel_fila, c(0L, 0L, 2L, 2L))
  expect_equal(unique(d$distribucion_geografica), "Aragón")
  expect_equal(unique(d$genero), "Total")
  expect_false("bloque" %in% names(d))   # sin filas agrupadas, sin columna de bloque
})

test_that("las filas agrupadas en bloques (grupos de población) se leen con su bloque", {
  ruta <- tempfile(fileext = ".html")
  writeLines(paste0(
    "<html><head><title>Mercado de trabajo y pensiones: 2024:\nTabla de grupos\n",
    "Distribución geográfica: Balears, Illes\n,\nTramos de renta anual: Hasta 3000</title></head><body><table>",
    '<thead><tr><th id="t_c1">Asalariados</th><th id="t_c2">Total</th></tr></thead>',
    '<tr><th id="t_f1" rowspan="2">SALARIOS</th><th id="t_f2">Personas</th>',
    '<td headers="t_c1 t_f1 t_f2 ">10</td><td headers="t_c2 t_f1 t_f2 ">12</td></tr>',
    '<tr><th id="t_f3">Retenciones</th><td headers="t_c1 t_f1 t_f3 ">1,5</td><td headers="t_c2 t_f1 t_f3 ">2</td></tr>',
    '<tr><th id="t_f4" rowspan="1">PENSIONES</th><th id="t_f5">Personas</th>',
    '<td headers="t_c1 t_f4 t_f5 ">0</td><td headers="t_c2 t_f4 t_f5 ">7</td></tr>',
    "</table></body></html>"), ruta, useBytes = TRUE)
  d <- leer_aeat_mercado(ruta)
  expect_equal(d$bloque, rep(c("SALARIOS", "PENSIONES"), c(4, 2)))
  expect_equal(d$fila, c("Personas", "Personas", "Retenciones", "Retenciones", "Personas", "Personas"))
  expect_equal(d$columna, rep(c("Asalariados", "Total"), 3))
  expect_equal(d$valor, c(10, 12, 1.5, 2, 0, 7))
  expect_equal(unique(d$distribucion_geografica), "Balears, Illes")
  expect_equal(unique(d$tramos_de_renta_anual), "Hasta 3000")
})

test_that("números en formato español", {
  expect_equal(numero_es(c("20.637.992", "1,39", "3,80%", "-", " 12 ")), c(20637992, 1.39, 3.8, NA, 12))
})

test_that("la mediana se interpola dentro de los tramos de la curva nacional", {
  curva <- list(x = 0:100, y = 1000 + 10 * (0:100))   # centil k → 1000 + 10 k
  # Reparto como el país: la mediana es el centil 50
  expect_equal(cuantil_tramos(rep(5, 10), curva), 1500)
  # Todo en el decil 3: la mediana cae en su centro (centil 25)
  expect_equal(cuantil_tramos(c(0, 0, 8, rep(0, 7)), curva), 1250)
  # Con centiles (ancho 1): 100 recuentos iguales
  expect_equal(cuantil_tramos(rep(1, 100), curva, p = 0.25, ancho = 1), 1250)
})

test_that("las ediciones de 2011 a 2014 se leen: cabeceras sin prefijo y sangría por margen", {
  ruta <- tempfile(fileext = ".html")
  writeLines(paste0(
    "<html><head><title>Mercado de trabajo y pensiones: 2011\nTabla vieja\nSexo: Total\n,\nEdad: Total</title></head><body><table>",
    '<tr><th class="corner-heading"></th><th id="c1">Asalariados</th><th id="c2">Salario <br/> Medio Anual</th></tr>',
    '<tr><th id="f1"><div style="margin-left: 0em">Total</div></th><td headers="c1 f1 ">17.788.121</td><td headers="c2 f1 ">19.102</td></tr>',
    '<tr><th id="f2"><div style="margin-left: 1em">Andaluc&iacute;a</div></th><td headers="c1 f2 ">3.226.262</td><td headers="c2 f2 ">15.375</td></tr>',
    '<tr><th id="f3"><div style="margin-left: 2em">Almer&iacute;a</div></th><td headers="c1 f3 ">269.927</td><td headers="c2 f3 ">14.033</td></tr>',
    "</table></body></html>"), ruta, useBytes = TRUE)
  d <- leer_aeat_mercado(ruta)
  expect_equal(d$nivel_fila, rep(0:2, each = 2))
  expect_equal(d$fila[5], "Almería")
  # Margen en píxeles (cabeceras de grupo del recorrido y los centiles del SME): sin nivel y sin aviso
  th <- function(estilo) xml2::xml_find_first(xml2::read_html(paste0('<table><tr><th id="f1"><div style="', estilo,
                                                                    '">Decil 1</div></th></tr></table>')), "//th")
  expect_no_warning(n <- aeat_sangria(th("margin-left: 10px")))
  expect_identical(n, NA_integer_)
  expect_identical(aeat_sangria(th("margin-left: 1.5em")), 1L)
  expect_equal(d$valor, c(17788121, 19102, 3226262, 15375, 269927, 14033))
  expect_equal(unique(d$columna), c("Asalariados", "Salario Medio Anual"))
})

# Módulo de año completo inventado: curva nacional lineal (centil k → 1000 + 10 k euros) y una
# comunidad, Aragón (02), con sus recuentos por decil nacional en dos edades.
modulo_inventado <- function(anio = 2019L, n_joven = rep(10, 10), media_joven = 2000) {
  list(curva = tibble::tibble(anio = anio, x = 0:100, y = 1000 + 10 * (0:100)),
       deciles = tibble::tibble(anio = anio, ccaa = rep(c("02", "00"), each = 20),
                                edad = rep(rep(c("De 26 a 35 años", "Total"), each = 10), 2),
                                decil = rep(1:10, 4), n = c(n_joven, rep(10, 10), rep(10, 20))),
       medias = tibble::tibble(anio = anio, ccaa = c("02", "00"), edad = "De 26 a 35 años", media_sme = media_joven))
}

test_that("relación mediana/media del SME por comunidad y año (paso 2)", {
  m <- combinar_modulos_sme(list(modulo_inventado(2019L), modulo_inventado(2020L, n_joven = c(0, 0, 8, rep(0, 7)))))
  f <- formas_sme(m)
  expect_equal(f$mediana_sme[f$anio == 2019 & f$ccaa == "02"], 1500)   # reparto como el país: centil 50
  expect_equal(f$mediana_sme[f$anio == 2020 & f$ccaa == "02"], 1250)   # todo en el decil 3: su centro
  expect_equal(f$forma[f$anio == 2019 & f$ccaa == "02"], 1500 / 2000)
})

# Salarios de la AEAT ya con códigos (codificar_aeat_salarios()): Aragón, Huesca y Zaragoza; Madrid,
# de una provincia (fila de comunidad y de provincia).
salarios_inventados <- function(anios = 2018:2019) {
  base <- tibble::tibble(
    nivel = c("nacional", "ccaa", "provincia", "provincia", "ccaa", "provincia"),
    geo_id = c("00", "02", "22", "50", "13", "28"), ccaa = c(NA, "02", "02", "02", "13", "13"),
    asalariados = c(1000, 100, 30, 70, 300, 300), salario_medio = c(1400, 1200, 1100, 1300, 1600, 1600))
  tidyr::expand_grid(anio = as.integer(anios), edad = c("total", "Y26-35"), base) |>
    mutate(salarios = asalariados * salario_medio, nombre = geo_id)
}

test_that("serie de la mochila (pasos 1, 2 y 4): B, y A y C como registro; antes del módulo, su primer año", {
  f <- formas_sme(combinar_modulos_sme(list(modulo_inventado(2019L))))
  s <- calcular_mochila_serie(salarios_inventados(), f, anios = 2018:2019)
  expect_equal(s$provincia, c("22", "50", "22", "50"))    # Madrid, sin deciles en la prueba
  expect_equal(s$anio_forma, rep(2019L, 4))               # 2018 toma la relación de 2019
  expect_equal(s$bruto_anual[s$anio == 2019], c(1100, 1300) * 1500 / 2000)
  expect_equal(s$A[s$anio == 2019], 1500 * c(1100, 1300) / 1200)
  expect_equal(s$C, rep(1500, 4))
})

# Grupos de población inventados: tres tramos con salario medio de 5.000, 15.000 y 25.000 € y la
# retención (en tanto por uno) que se pida; retribuciones y retenciones en miles de euros.
grupos_aeat <- function(geo, tipos, columna = "Asalariados", bloque = "SALARIOS") {
  tramo <- c("Hasta 10000", "De 10001 a 20000", "Más de 20000")
  retribuciones <- 100 * c(5, 15, 25)   # 100 personas por tramo
  tibble::tibble(bloque = bloque, fila = rep(c("Personas", "Retribuciones", "Retenciones"), each = 3),
                 columna = columna, valor = c(rep(100, 3), retribuciones, retribuciones * tipos),
                 distribucion_geografica = geo, tramos_de_renta_anual = rep(tramo, 3))
}
ccaa_inventadas <- tibble::tibble(codigo = c("04", "13", "17"), nombre_ine = c("Balears, Illes", "Madrid, Comunidad de", "Rioja, La"),
                                  nuts2 = c("ES53", "ES30", "ES23"))

test_that("retenciones por tramo: salario medio y tipo de quien solo cobra salarios, interpolados", {
  g <- bind_rows(
    grupos_aeat("Total", c(0.01, 0.03, 0.10)),
    grupos_aeat("Total", c(0.5, 0.5, 0.5), columna = "Total"),        # otra columna: fuera
    grupos_aeat("Total", c(0.5, 0.5, 0.5), bloque = "PENSIONES"),     # otro bloque: fuera
    mutate(grupos_aeat("Total", c(0.5, 0.5, 0.5)), tramos_de_renta_anual = "Total")   # tramo total: fuera
  )
  r <- retenciones_aeat(g, 2024L, ccaa_inventadas)
  expect_equal(r$ccaa, rep("00", 3))
  expect_equal(r$salario_medio, c(5000, 15000, 25000))
  expect_equal(r$retencion, c(0.01, 0.03, 0.10))
  # Lineal entre los salarios medios; constante fuera de ellos
  expect_equal(tipo_retencion(c(1000, 10000, 20000, 30000), r), c(0.01, 0.02, 0.065, 0.10))
  # Ediciones con otra columna de comunidad y otro nombre de la misma comunidad
  g2 <- rename(grupos_aeat("Illes Balears", c(0.02, 0.04, 0.12)), comunidad_autonoma = distribucion_geografica)
  expect_equal(unique(retenciones_aeat(g2, 2016L, ccaa_inventadas)$ccaa), "04")
})

test_that("cotización del trabajador de cada año, la de la tartera", {
  expect_equal(cotizacion_trabajador(c(2015, 2023, 2024)), c(0.0635, 0.0645, 0.0647))
  expect_error(cotizacion_trabajador(2030), "Sin cotizaci")
})

test_that("de bruto anual a neto mensual: cotización del año y retención de la curva de su comunidad y año", {
  ret <- bind_rows(retenciones_aeat(bind_rows(grupos_aeat("Total", c(0.01, 0.03, 0.10)),
                                              grupos_aeat("Balears, Illes", c(0.02, 0.04, 0.12))), 2024L, ccaa_inventadas),
                   retenciones_aeat(grupos_aeat("Balears, Illes", c(0.05, 0.05, 0.05)), 2023L, ccaa_inventadas),
                   retenciones_aeat(grupos_aeat("Total", c(0.05, 0.05, 0.05)), 2023L, ccaa_inventadas))
  mochila <- tibble::tibble(anio = c(2024L, 2023L), provincia = "07", ccaa = "04", bruto_anual = 10000)
  m <- calcular_mochila_neta(mochila, ret, cotizacion = function(a) rep(0.065, length(a)))
  expect_equal(m$retencion, c(0.03, 0.05))          # 2024: entre 0,02 (5.000 €) y 0,04 (15.000 €)
  expect_equal(m$retencion_espana, c(0.02, 0.05))
  expect_equal(m$neto_anual[1], 10000 * (1 - 0.065 - 0.03))
  expect_equal(m$neto_mensual[1], 9050 / 12)
  expect_equal(calcular_mochila_neta(mochila[1, ], ret)$cotizacion, 0.0647)   # por defecto, la del año
  expect_error(calcular_mochila_neta(mutate(mochila, ccaa = "17"), ret), "Sin retenciones")
})

test_that("compuerta de la serie: cobertura por año y relación mediana/media frente a la del primer año", {
  provincias <- tibble::tibble(provincia = c("01", "22", "50"), nombre_ine = c("Araba/Álava", "Huesca", "Zaragoza"),
                               nombre_aeat = c(NA, "Huesca", "Zaragoza"))
  neta <- tibble::tibble(anio = c(2018L, 2018L, 2019L), provincia = c("22", "50", "22"), neto_mensual = 1000)
  formas <- tibble::tibble(anio = c(2019L, 2020L), ccaa = "02", forma = c(0.80, 0.82))
  c <- comprobar_mochila(neta, formas, provincias, anios = 2018:2019)
  expect_equal(c$calculado[c$id == "mochila_cobertura"], c(0, 1))   # en 2019 falta Zaragoza
  expect_equal(c$calculado[c$id == "mochila_forma"], 100 * (0.82 / 0.80 - 1))
})

test_that("la mediana con pesos y el control de la mochila con la ECV de cada año", {
  expect_equal(mediana_ponderada(c(10, 20, 30), c(1, 1, 1)), 20)
  expect_equal(mediana_ponderada(c(30, 10, 20), c(5, 1, 1)), 30)
  mochila <- tibble::tibble(anio = c(2023L, 2024L, 2024L), ccaa = "17", real_ccaa = 20000, forma = 0.9)
  # Pregunta 44 g: la tolerancia es el intervalo de la mediana de la ECV, que sale de su muestra
  ecv <- tibble::tibble(anio = c(2024L, 2024L, 2023L), nuts2 = c("ES", "ES23", "ES23"), n = c(500L, 100L, 90L),
                        n_eff = c(400, 80, 70), mediana_bruto = c(17000, 18000, 20000),
                        mediana_lo = c(16500, 16000, 19000), mediana_hi = c(17500, 19000, 21000))
  c <- comprobar_mochila_ecv(mochila, ecv, ccaa_inventadas)
  expect_equal(nrow(c), 2)
  salarios <- tibble::tibble(nivel = "nacional", edad = "Y26-35", anio = 2023:2024, salario_medio = 20000)
  formas <- tibble::tibble(anio = 2024L, ccaa = "00", forma = 0.85)
  es <- mochila_espana(salarios, formas, anios = 2023:2024)
  expect_equal(es$forma, c(0.85, 0.85))     # 2023, sin módulo: la del primer año que lo tiene
  c2 <- comprobar_mochila_ecv(mochila, ecv, ccaa_inventadas, espana = es)
  expect_equal(c2$calculado[startsWith(c2$detalle, "España")], 0)     # 17.000, dentro de 16.500–17.500
  expect_equal(c$calculado[c$anio == 2024], 0)                         # 18.000, dentro de 16.000–19.000
  expect_equal(c$calculado[c$anio == 2023], 100 * (18000 / 19000 - 1))  # 18.000, por debajo de 19.000
  expect_match(c$detalle[c$anio == 2024], "^Rioja, La \\(n = 100, n efectiva = 80; mochila \\+0,0|^Rioja, La \\(n = 100, n efectiva = 80; mochila \\+0.0")
})

test_that("resumen de la ECV: muestra efectiva, intervalo de la mediana y relación de quien trabajó el año entero", {
  set.seed(1)
  a <- tibble::tibble(nuts2 = "ES30", peso = rep(c(1, 3), 200), bruto = round(stats::rlnorm(400, 10, 0.4)), neto = NA_real_,
                      meses = rep(c(12, 6), each = 200))
  e <- resumir_ecv_asalariados(a, 2019L)
  es <- e[e$nuts2 == "ES", ]
  expect_equal(es$n_eff, 400^2 * 4 / (200 * (1 + 9)))
  expect_true(es$mediana_lo < es$mediana_bruto && es$mediana_bruto < es$mediana_hi)
  expect_equal(es$n_12, 200)
  doce <- a[a$meses >= 12, ]
  expect_equal(es$media_12, stats::weighted.mean(doce$bruto, doce$peso))
  expect_equal(es$relacion_12, mediana_ponderada(doce$bruto, doce$peso) / es$media_12)
})

test_that("pregunta 44 f: relación de 2015–2018 frente a 2019 con la ECV; se corrige solo si avisa y se valida", {
  formas <- tidyr::expand_grid(anio = 2019:2024, ccaa = c("00", "13")) |>
    dplyr::mutate(forma = ifelse(ccaa == "00", 0.85, 0.87))
  ecv <- function(r) tibble::tibble(anio = 2015:2024, nuts2 = "ES", n_12 = 900L, relacion_12 = r)
  # Sin aviso (todo a menos de 2 puntos de 2019): no se corrige
  x <- ecv_mochila_correccion(ecv(c(0.90, 0.905, 0.895, 0.90, rep(0.90, 6))), formas)
  expect_equal(x$comprobaciones$calculado[x$comprobaciones$id == "mochila_relacion_ecv"], 100 * (c(0.90, 0.905, 0.895, 0.90) - 0.90))
  expect_equal(x$comprobaciones$calculado[x$comprobaciones$id == "mochila_relacion_correccion"], 0)
  expect_equal(nrow(x$factores), 0)
  # Avisa y la ECV se mueve en 2020–2024 mientras la AEAT no: el método no se valida y no se corrige
  y <- ecv_mochila_correccion(ecv(c(0.93, 0.90, 0.87, 0.90, 0.90, 0.86, 0.88, 0.86, 0.86, 0.85)), formas)
  expect_equal(y$comprobaciones$calculado[y$comprobaciones$id == "mochila_relacion_correccion"], 1)
  expect_false(y$resumen$valida)
  expect_equal(nrow(y$factores), 0)
  expect_match(y$comprobaciones$detalle[y$comprobaciones$id == "mochila_relacion_correccion"], "no se corrige")
  # Avisa y la AEAT se mueve como la ECV: se valida y se corrige con la relación del año / la de 2019
  formas2 <- formas |> dplyr::mutate(forma = forma * c(1, 0.96, 0.98, 0.96, 0.96, 0.95)[anio - 2018L])
  z <- ecv_mochila_correccion(ecv(c(0.93, 0.90, 0.87, 0.90, 0.90, 0.864, 0.882, 0.864, 0.864, 0.855)), formas2)
  expect_true(z$resumen$corrige)
  expect_equal(z$factores$anio, 2015:2018)
  expect_equal(z$factores$factor, c(0.93, 0.90, 0.87, 0.90) / 0.90)
  # La serie aplica el factor a los años sin módulo y anota el método
  f <- formas_sme(combinar_modulos_sme(list(modulo_inventado(2019L))))
  s <- calcular_mochila_serie(salarios_inventados(), f, anios = 2018:2019,
                              correccion = tibble::tibble(anio = 2018L, factor = 1.1))
  expect_equal(s$metodo_forma, c("primer_anio_ecv", "primer_anio_ecv", "anio", "anio"))
  expect_equal(s$bruto_anual[s$anio == 2018], c(1100, 1300) * 1500 / 2000 * 1.1)
  expect_equal(calcular_mochila_serie(salarios_inventados(), f, anios = 2018:2019)$metodo_forma[1], "primer_anio")
})

test_that("control del paso a neto con la ECV: neto calculado sobre la mediana del bruto; sin PY010N, fuera", {
  a <- tibble::tibble(nuts2 = c("ES53", "ES53", "ES30"), peso = 1, bruto = c(10, 20, 30), neto = c(9, 18, 27), meses = 12)
  e <- resumir_ecv_asalariados(a, 2024L)
  expect_equal(e$mediana_neto[e$nuts2 == "ES"], 18)
  expect_equal(unique(e$anio), 2024L)
  expect_true(all(is.na(resumir_ecv_asalariados(mutate(a, neto = NA_real_))$mediana_neto)))
  ret <- retenciones_aeat(bind_rows(grupos_aeat("Total", c(0.01, 0.03, 0.10)),
                                    grupos_aeat("Balears, Illes", c(0.02, 0.04, 0.12))), 2024L, ccaa_inventadas)
  ecv <- tibble::tibble(anio = 2024L, nuts2 = c("ES", "ES53", "ES30", "ES23"), n = c(500L, 100L, 80L, 50L),
                        mediana_bruto = c(15000, 10000, 12000, 9000),
                        mediana_neto = c(15000 * (1 - 0.065 - 0.03), 10000 * (1 - 0.065 - 0.03) / 1.1, 1, NA))
  c <- comprobar_neto_ecv(ret, ecv, ccaa_inventadas, cotizacion = function(a) rep(0.065, length(a)))
  expect_equal(c$detalle, c("Total (n = 500)", "Balears, Illes (n = 100)"))   # Madrid, sin curva; La Rioja, sin neto
  expect_equal(c$calculado, c(0, 10))
  expect_equal(unique(c$id), "mochila_neto_ecv")
})
