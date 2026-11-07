# AEAT, «Mercado de trabajo y pensiones» (R/fuente_aeat_mercado.R) y opciones de la mochila
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

test_that("opciones A, B y C: A y B difieren en la relación media SME / media real de la comunidad", {
  recorrido <- tibble::tibble(fila = rep(as.character(1:100), each = 2),
                              columna = rep(c("SME inferior", "SME superior"), 100),
                              valor = as.vector(rbind(1000 + 10 * (0:99), 1000 + 10 * (1:100))))
  deciles <- tibble::tibble(fila = c("Total", paste("Decil", 1:4), "Decil 5 Mediana", paste("Decil", 6:10)),
                            columna = "De 26 a 35 años", valor = c(100, rep(10, 10)),
                            distribucion_geografica = "Aragón", genero = "Total")
  sme <- tibble::tibble(fila = "De 26 a 35 años", columna = "Total · SME", valor = 2000,
                        distribucion_geografica = "Aragón")
  provincia <- tibble::tibble(
    fila = rep(c("Total", "Aragón", "Huesca", "Zaragoza", "Madrid, Comunidad de"), each = 2),
    nivel_fila = rep(c(0L, 1L, 2L, 2L, 1L), each = 2),
    columna = rep(c("Asalariados", "Salario Medio Anual"), 5),
    valor = c(1000, 1400, 100, 1200, 30, 1100, 70, 1300, 300, 1600),
    sexo = "Total", tramos_de_edad = "De 26 a 35 años")
  o <- calcular_mochila_opciones(provincia, deciles, sme, recorrido)
  expect_equal(o$provincia, c("Huesca", "Zaragoza"))   # Madrid no tiene deciles en la prueba
  expect_equal(o$C, c(1500, 1500))
  expect_equal(o$A, 1500 * c(1100, 1300) / 1200)
  expect_equal(o$B, c(1100, 1300) * 1500 / 2000)
  expect_equal(o$A_sobre_B, rep(2000 / 1200, 2))
})

test_that("la mediana con pesos y el control de la mochila con la ECV", {
  expect_equal(mediana_ponderada(c(10, 20, 30), c(1, 1, 1)), 20)
  expect_equal(mediana_ponderada(c(30, 10, 20), c(5, 1, 1)), 30)
  op <- tibble::tibble(comunidad = c("Rioja, La", "Rioja, La"), real_ccaa = 20000, forma = 0.9)
  ecv <- tibble::tibble(nuts2 = c("ES", "ES23"), n = c(500L, 100L), mediana_bruto = c(17000, 18000))
  ccaa <- tibble::tibble(codigo = "17", nombre_ine = "Rioja, La", nuts2 = "ES23")
  c <- comprobar_mochila_ecv(op, ecv, ccaa)
  expect_equal(nrow(c), 1)
  expect_equal(c$calculado, 0)
  expect_equal(c$detalle, "Rioja, La (n = 100)")
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

test_that("retenciones por tramo: salario medio y tipo de quien solo cobra salarios, interpolados", {
  g <- bind_rows(
    grupos_aeat("Total", c(0.01, 0.03, 0.10)),
    grupos_aeat("Total", c(0.5, 0.5, 0.5), columna = "Total"),        # otra columna: fuera
    grupos_aeat("Total", c(0.5, 0.5, 0.5), bloque = "PENSIONES"),     # otro bloque: fuera
    mutate(grupos_aeat("Total", c(0.5, 0.5, 0.5)), tramos_de_renta_anual = "Total")   # tramo total: fuera
  )
  r <- retenciones_aeat(g)
  expect_equal(r$salario_medio, c(5000, 15000, 25000))
  expect_equal(r$retencion, c(0.01, 0.03, 0.10))
  # Lineal entre los salarios medios; constante fuera de ellos
  expect_equal(tipo_retencion(c(1000, 10000, 20000, 30000), r), c(0.01, 0.02, 0.065, 0.10))
})

test_that("de bruto anual a neto mensual: cotización y retención de la curva de su comunidad", {
  ret <- retenciones_aeat(bind_rows(grupos_aeat("Total", c(0.01, 0.03, 0.10)),
                                    grupos_aeat("Balears, Illes", c(0.02, 0.04, 0.12))))
  mochila <- tibble::tibble(provincia = "Balears,Illes", comunidad = "Balears,Illes", bruto_anual = 10000)
  m <- calcular_mochila_neta(mochila, ret, cotizacion = 0.065)
  expect_equal(m$retencion, 0.03)          # entre 0,02 (5.000 €) y 0,04 (15.000 €)
  expect_equal(m$retencion_espana, 0.02)
  expect_equal(m$neto_anual, 10000 * (1 - 0.065 - 0.03))
  expect_equal(m$neto_mensual, 9050 / 12)
  expect_error(calcular_mochila_neta(mutate(mochila, comunidad = "Rioja, La"), ret, 0.065), "Sin retenciones")
})

test_that("control del paso a neto con la ECV: neto calculado sobre la mediana del bruto", {
  a <- tibble::tibble(nuts2 = c("ES53", "ES53", "ES30"), peso = 1, bruto = c(10, 20, 30), neto = c(9, 18, 27), meses = 12)
  e <- resumir_ecv_asalariados(a)
  expect_equal(e$mediana_neto[e$nuts2 == "ES"], 18)
  ret <- retenciones_aeat(bind_rows(grupos_aeat("Total", c(0.01, 0.03, 0.10)),
                                    grupos_aeat("Balears, Illes", c(0.02, 0.04, 0.12))))
  ecv <- tibble::tibble(nuts2 = c("ES", "ES53", "ES30"), n = c(500L, 100L, 80L), mediana_bruto = c(15000, 10000, 12000),
                        mediana_neto = c(15000 * (1 - 0.065 - 0.03), 10000 * (1 - 0.065 - 0.03) / 1.1, 1))
  ccaa <- tibble::tibble(codigo = c("04", "13"), nombre_ine = c("Balears, Illes", "Madrid, Comunidad de"),
                         nuts2 = c("ES53", "ES30"))
  c <- comprobar_neto_ecv(ret, ecv, ccaa, cotizacion = 0.065)
  expect_equal(c$detalle, c("Total (n = 500)", "Balears, Illes (n = 100)"))   # Madrid, sin curva: fuera
  expect_equal(c$calculado, c(0, 10))
  expect_equal(unique(c$id), "mochila_neto_ecv")
})
