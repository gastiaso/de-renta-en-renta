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
