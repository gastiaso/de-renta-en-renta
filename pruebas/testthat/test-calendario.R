# Calendario de fuentes (R/calendario_fuentes.R; F6): fechas de publicación esperables, dato
# esperado, fuentes que tocan con fechas inventadas, señal del objetivo fuentes_pendientes,
# renovación (apartar y restaurar ficheros) y compuerta. Al final, el calendario real frente al
# inventario de fuentes y a los objetivos de descarga de _targets.R.

calendario_inventado <- function() {
  tibble::tibble(
    id = c("mensual_x", "anual_x", "trimestral_x", "fija_x"),
    cadencia = c("mensual", "anual", "trimestral", "unica"),
    meses_publicacion = c("1-7;9-12", "11", "3;6;9;12", NA),
    dia_publicacion = c(20L, 11L, 15L, NA),
    desfase_dias = c(-11L, 315L, 75L, NA),
    meses_dato = c("1-7;9-12", NA, NA, NA),
    ultimo_dato = c("2026-10", "2024", "2026-T2", "2025"),
    url_calendario = NA_character_, objetivos = c("obj_m", "obj_a", "obj_t", "obj_f"),
    ficheros = c("datos/brutos/m/", "datos/brutos/a/*.csv", "datos/brutos/t/*.xls", "datos/brutos/f/*.zip"),
    renovar = c("invalidar", "codigo", "mover", "fija"),
    cambio_codigo = c(NA, "ANIOS_X en _targets.R", NA, NA), notas = NA_character_
  )
}

test_that("cal_meses lee meses sueltos y tramos", {
  expect_equal(cal_meses("1-7;9-12"), c(1:7, 9:12))
  expect_equal(cal_meses("3;6;9;12"), c(3L, 6L, 9L, 12L))
  expect_equal(cal_meses("11"), 11L)
  expect_equal(cal_meses(NA), integer(0))
})

test_that("cal_proxima_edicion: primera fecha posterior, sin agosto y con el día recortado al mes", {
  expect_equal(cal_proxima_edicion(as.Date("2026-11-10"), c(1:7, 9:12), 20L), as.Date("2026-11-20"))
  expect_equal(cal_proxima_edicion(as.Date("2026-11-20"), c(1:7, 9:12), 20L), as.Date("2026-12-20"))
  expect_equal(cal_proxima_edicion(as.Date("2026-07-25"), c(1:7, 9:12), 20L), as.Date("2026-09-20"))
  expect_equal(cal_proxima_edicion(as.Date("2026-12-01"), 2L, 30L), as.Date("2027-02-28"))
  expect_true(is.na(cal_proxima_edicion(as.Date("2026-12-01"), integer(0), NA)))
})

test_that("cal_dato_esperado avanza mientras el periodo siguiente ya debería estar publicado", {
  expect_equal(cal_dato_esperado("2024", 315L, integer(0), as.Date("2026-11-10")), "2024")
  expect_equal(cal_dato_esperado("2024", 315L, integer(0), as.Date("2026-11-11")), "2025")
  expect_equal(cal_dato_esperado("2026-T2", 75L, integer(0), as.Date("2026-12-13")), "2026-T2")
  expect_equal(cal_dato_esperado("2026-T2", 75L, integer(0), as.Date("2026-12-14")), "2026-T3")
  # mensual sin agosto: de julio salta a septiembre (publicado 11 días antes de fin de mes)
  expect_equal(cal_dato_esperado("2026-07", -11L, c(1:7, 9:12), as.Date("2026-09-18")), "2026-07")
  expect_equal(cal_dato_esperado("2026-07", -11L, c(1:7, 9:12), as.Date("2026-09-19")), "2026-09")
  # semestral con meses de dato 5 y 11
  expect_equal(cal_dato_esperado("2026-05", 75L, c(5L, 11L), as.Date("2027-02-13")), "2026-11")
  expect_true(is.na(cal_dato_esperado(NA, 10L, integer(0), as.Date("2026-11-10"))))
})

test_that("cal_fuentes_pendientes: qué toca según la fecha de hoy y la última descarga", {
  cal <- calendario_inventado()
  ultimas <- c(mensual_x = "2026-11-10", anual_x = "2026-11-10", trimestral_x = "2026-11-09", fija_x = "2020-01-01")
  hoy <- cal_fuentes_pendientes(cal, hoy = as.Date("2026-11-10"), ultimas = ultimas)
  expect_equal(hoy$toca, c(FALSE, FALSE, FALSE, FALSE))
  expect_equal(hoy$proxima_edicion, as.Date(c("2026-11-20", "2026-11-11", "2026-12-15", NA)))
  # al día siguiente, la anual: edición nueva y dato de 2025
  manana <- cal_fuentes_pendientes(cal, hoy = as.Date("2026-11-11"), ultimas = ultimas)
  expect_equal(manana$toca, c(FALSE, TRUE, FALSE, FALSE))
  expect_true(manana$edicion_nueva[2] && manana$dato_nuevo[2])
  expect_equal(manana$dato_esperado[2], "2025")
  # el 21 de noviembre, también el barómetro mensual (edición del 20; el dato de noviembre, el 19)
  dia21 <- cal_fuentes_pendientes(cal, hoy = as.Date("2026-11-21"), ultimas = ultimas)
  expect_equal(dia21$toca, c(TRUE, TRUE, FALSE, FALSE))
  expect_equal(dia21$dato_esperado[1], "2026-11")
  # una «fija» no toca nunca
  expect_false(cal_fuentes_pendientes(cal, hoy = as.Date("2030-01-01"), ultimas = ultimas)$toca[4])
  # tras bajar la edición nueva, deja de tocar por la descarga (el dato sigue hasta que se suba ultimo_dato)
  despues <- cal_fuentes_pendientes(cal, hoy = as.Date("2026-11-21"),
                                    ultimas = replace(ultimas, c("mensual_x", "anual_x"), c("2026-11-21", "2026-11-21")))
  expect_equal(despues$edicion_nueva, c(FALSE, FALSE, FALSE, FALSE))
  expect_equal(despues$dato_nuevo, c(TRUE, TRUE, FALSE, FALSE))
})

test_that("cal_ultima_descarga: fecha del fichero más reciente, en carpetas y comodines, sin los .parcial", {
  raiz <- tempfile("cal"); dir.create(file.path(raiz, "datos", "brutos", "m", "sub"), recursive = TRUE)
  a <- file.path(raiz, "datos", "brutos", "m", "sub", "a.json"); writeLines("{}", a)
  b <- file.path(raiz, "datos", "brutos", "m", "b.json.parcial"); writeLines("{}", b)
  Sys.setFileTime(a, as.POSIXct("2026-10-20 12:00:00"))
  Sys.setFileTime(b, as.POSIXct("2026-11-09 12:00:00"))
  expect_equal(cal_ultima_descarga("datos/brutos/m/", raiz), as.Date("2026-10-20"))
  expect_equal(cal_ultima_descarga("datos/brutos/m/sub/*.json", raiz), as.Date("2026-10-20"))
  expect_true(is.na(cal_ultima_descarga("datos/brutos/nada/*.csv", raiz)))
  expect_equal(cal_ficheros("datos/brutos/m/", raiz), "datos/brutos/m/sub/a.json")
})

test_that("señal de fuentes_pendientes: cambia cuando cambia el conjunto de fuentes que tocan", {
  raiz <- tempfile("cal"); dir.create(raiz)
  ruta <- file.path(raiz, "calendario.csv")
  cal <- calendario_inventado()
  cal$ficheros <- c("datos/brutos/m/", "datos/brutos/a/*.csv", "datos/brutos/t/*.xls", "datos/brutos/f/*.zip")
  readr::write_csv(cal, ruta, na = "")
  estado <- file.path(raiz, "pendientes.csv")
  # sin ficheros (sin descargas) y sin estado guardado: hay que avisar
  expect_true(cal_hay_cambios(ruta, estado, hoy = as.Date("2026-11-10")))
  p <- suppressWarnings(cal_avisar_pendientes(cal_fuentes_pendientes(cal_leer_calendario(ruta), hoy = as.Date("2026-11-10")), estado))
  expect_true(file.exists(estado))
  expect_false(cal_hay_cambios(ruta, estado, hoy = as.Date("2026-11-10")))
  # al día siguiente, la anual pasa a tocar por el dato (sin descarga, la edición no cuenta)
  expect_true(cal_hay_cambios(ruta, estado, hoy = as.Date("2026-11-11")))
  expect_warning(cal_avisar_pendientes(cal_fuentes_pendientes(cal_leer_calendario(ruta), hoy = as.Date("2026-11-11")), estado),
                 "anual_x")
  expect_false(cal_hay_cambios(ruta, estado, hoy = as.Date("2026-11-11")))
  # un calendario que no se puede leer no rompe la lectura de _targets.R
  expect_true(cal_hay_cambios(file.path(raiz, "no_existe.csv"), estado))
  expect_false(cal_toca("anual_x", file.path(raiz, "no_existe.csv")))
})

test_that("cal_actualizar aparta los ficheros de las fuentes «mover» y cal_restaurar los devuelve", {
  raiz <- tempfile("cal"); dir.create(file.path(raiz, "datos", "brutos", "t"), recursive = TRUE)
  dir.create(file.path(raiz, "inventario"))
  cal <- calendario_inventado()
  ruta <- file.path(raiz, "inventario", "calendario.csv")
  readr::write_csv(cal, ruta, na = "")
  x <- file.path(raiz, "datos", "brutos", "t", "35101000.xls"); writeLines("viejo", x)
  plan <- suppressMessages(cal_actualizar("trimestral_x", hoy = as.Date("2026-12-20"), ruta = ruta, raiz = raiz))
  expect_match(plan$acciones, "apartar 1 ficheros")
  expect_true(file.exists(x))                      # sin ejecutar, no toca nada
  suppressMessages(cal_actualizar("trimestral_x", ejecutar = TRUE, hoy = as.Date("2026-12-20"), ruta = ruta, raiz = raiz))
  expect_false(file.exists(x))
  apartado <- file.path(raiz, "datos", "brutos", "_anteriores", "2026-12-20", "datos", "brutos", "t", "35101000.xls")
  expect_true(file.exists(apartado))
  devueltos <- cal_restaurar("2026-12-20", raiz = raiz)
  expect_equal(devueltos, "datos/brutos/t/35101000.xls")
  expect_equal(readLines(x), "viejo")
  # las de código solo se indican
  plan <- suppressMessages(cal_actualizar("anual_x", hoy = as.Date("2026-12-20"), ruta = ruta, raiz = raiz))
  expect_match(plan$acciones, "ANIOS_X")
  expect_error(suppressMessages(cal_actualizar("no_existe", ruta = ruta, raiz = raiz)), "desconocidas")
})

test_that("cal_comprobar_calendario: vocabulario, meses, días, periodos y fuentes del inventario", {
  cal <- calendario_inventado()
  fuentes <- tibble::tibble(id = cal$id)
  bien <- cal_comprobar_calendario(cal, fuentes, raiz = tempdir())
  expect_equal(sum(bien$calculado[bien$id == "calendario_fuentes"]), 0)
  mal <- cal
  mal$cadencia[1] <- "quincenal"; mal$meses_publicacion[2] <- "13"; mal$dia_publicacion[3] <- 40L
  mal$ultimo_dato[4] <- "2025-S1"; mal$renovar[2] <- "borrar"
  mal <- dplyr::bind_rows(mal, mal[1, ])
  r <- cal_comprobar_calendario(mal, tibble::tibble(id = cal$id[-4]), raiz = tempdir())
  r <- r[r$id == "calendario_fuentes", ]
  problemas <- stats::setNames(r$calculado, r$detalle)
  expect_equal(unname(problemas[["fuentes repetidas"]]), 1)
  expect_equal(unname(problemas[["fuentes fuera de inventario/fuentes.csv"]]), 1)
  expect_equal(unname(problemas[["cadencias fuera del vocabulario"]]), 2)
  expect_equal(unname(problemas[["meses imposibles"]]), 1)
  expect_equal(unname(problemas[["periodos sin formato"]]), 1)
  expect_equal(unname(problemas[["formas de renovar fuera del vocabulario"]]), 1)
  expect_equal(unname(problemas[["días imposibles"]]), 1)
})

test_that("el calendario real cubre las fuentes y los objetivos de descarga del pipeline", {
  cal <- cal_leer_calendario(file.path("..", "..", "inventario", "calendario_fuentes.csv"))
  fuentes <- readr::read_csv(file.path("..", "..", "inventario", "fuentes.csv"), col_types = readr::cols(.default = "c"))
  expect_equal(setdiff(cal$id, fuentes$id), character(0))
  r <- cal_comprobar_calendario(cal, fuentes, raiz = file.path("..", ".."))
  expect_equal(sum(r$calculado[r$id == "calendario_fuentes"]), 0, info = paste(r$detalle[r$calculado > 0], collapse = "; "))
  # cada objetivo que descarga algo en _targets.R está en una fila del calendario
  pipeline <- readLines(file.path("..", "..", "_targets.R"), encoding = "UTF-8", warn = FALSE)
  patron <- "tar_target\\(\\s*([a-z_0-9]+)\\s*,[^#]*(descargar_|obtener_csv_ine_ecv|ficheros_ign_au\\(|buscar_ficheros_portales\\(|cis_descargar_estudios\\()"
  descargas <- unique(sub(paste0("^.*", patron, ".*$"), "\\1", grep(patron, pipeline, value = TRUE, perl = TRUE), perl = TRUE))
  descargas <- setdiff(descargas, "ficheros_tipografias")   # tipografías de la web, no son datos
  listados <- unique(trimws(unlist(strsplit(stats::na.omit(cal$objetivos), ";"))))
  expect_true(length(descargas) > 30)
  expect_equal(setdiff(descargas, listados), character(0))
  # y cada objetivo listado existe en _targets.R
  texto <- paste(pipeline, collapse = "\n")
  existe <- vapply(listados, function(o) grepl(sprintf("tar_target\\(\\s*%s\\s*,", o), texto, perl = TRUE), logical(1))
  expect_equal(listados[!existe], character(0))
})
