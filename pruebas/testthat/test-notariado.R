# Notariado (R/fuente_notariado.R y R/web_notariado.R; docs/especificacion_notariado.md): Portal
# Estadístico (penotariado, indicadores 25 a 27) y CIEN (28 y 29), con licencia propia no comercial y
# solo web. Todo con cifras inventadas y servicios simulados (nunca se consulta la red ni datos/brutos/).

# Territorios inventados: dos comunidades (Andalucía, 01, con dos provincias; Madrid, 13, con una) y
# las de Ceuta (18) y Melilla (19) con sus provincias, como en el seccionado de 2021
jer_n <- tibble::tibble(
  seccion = c("0400101001", "0400201001", "1100101001", "2807901001", "2807901002", "5100101001", "5200101001"),
  distrito = c("0400101", "0400201", "1100101", "2807901", "2807901", "5100101", "5200101"),
  municipio = c("04001", "04002", "11001", "28079", "28079", "51001", "52001"),
  provincia = c("04", "04", "11", "28", "28", "51", "52"), ccaa = c("01", "01", "01", "13", "13", "18", "19"))
ter_n <- geo_territorios(jer_n,
                         tibble::tibble(municipio = c("04001", "04002", "11001", "28079", "51001", "52001"),
                                        nombre = c("Uno", "Dos", "Tres", "Madrid", "Ceuta", "Melilla")),
                         tibble::tibble(provincia = c("04", "11", "28", "51", "52"), nombre = c("Almería", "Cádiz", "Madrid", "Ceuta", "Melilla"),
                                        ccaa = c("01", "01", "13", "18", "19")),
                         tibble::tibble(codigo = c("01", "13", "18", "19"), nombre_ine = c("Andalucía", "Madrid", "Ceuta", "Melilla"),
                                        nuts2 = c("ES61", "ES30", "ES63", "ES64")))
ind_n <- tibble::tibble(
  id = c(25, 26, 27, 28, 29),
  codigo = c("precio_escriturado_m2", "precio_escriturado_vivienda", "compraventas_notariado", "hipotecas_compra_vivienda",
             "cuantia_hipoteca_vivienda"),
  unidad_es = c("€ por m²", "€ por vivienda", "compraventas", "hipotecas al año", "€ por hipoteca"),
  nucleo_v01 = FALSE,
  cortes_web = c("600;900;1200", "70000;100000", "5;20;50", "1000;2500", "100000;150000"),
  escala_web = NA
)
voc_n <- readr::read_csv(file.path("..", "..", "inventario", "vocabulario.csv"), show_col_types = FALSE)

# ---- Penotariado: servicio ArcGIS simulado ----

# Atributos de una fila de la capa
atributos_n <- function(codigo_campo = NULL, codigo = NULL, nombre_campo = NULL, nombre = NULL, precio_m2, superficie, total,
                        informados, estimado = 0L) {
  a <- list(es_estimado = estimado, precio_m2 = precio_m2, precio_medio = precio_m2 * superficie, superficie_media = superficie,
            total_informados = informados, total = total, tipo_construccion_id = 99L, clase_finca_urbana_id = 99L)
  if (!is.null(codigo_campo)) a[[codigo_campo]] <- codigo
  if (!is.null(nombre_campo)) a[[nombre_campo]] <- nombre
  a
}
# Una foto inventada: España, dos comunidades, tres provincias, cuatro municipios y dos códigos postales
capas_n <- function() {
  list(
    "0" = list(atributos_n(precio_m2 = 2000, superficie = 100, total = 1000, informados = 900)),
    "1" = list(atributos_n("cod_ccaa", "01", "name_ccaa", "Andalucía", 1500, 110, 400, 350),
               atributos_n("cod_ccaa", "13", "name_ccaa", "Comunidad de Madrid", 3000, 90, 600, 550)),
    "2" = list(atributos_n("cod_prov", "04", "name_prov", "Almería", 1200, 105, 150, 130),
               atributos_n("cod_prov", "11", "name_prov", "Cádiz", 1700, 112, 250, 220),
               atributos_n("cod_prov", "28", "name_prov", "Madrid", 3000, 90, 600, 550)),
    "3" = list(atributos_n("cod_muni", "04001", "name_muni", "Uno", 1250, 100, 100, 90),
               atributos_n("cod_muni", "4002", "name_muni", "Dos", 900, 120, 15, 12),        # sin ceros; menos de 20 informadas
               atributos_n("cod_muni", "11001", "name_muni", "Tres", 1800, 110, 240, 210, estimado = 1L),
               atributos_n("cod_muni", "28079", "name_muni", "Madrid", 3200, 85, 500, 470)),
    "4" = list(atributos_n("cp", "28013", precio_m2 = 5000, superficie = 80, total = 40, informados = 35),
               atributos_n("cp", "4001", precio_m2 = 1000, superficie = 100, total = 10, informados = 9))
  )
}
# Servicio simulado: definiciones con la fecha (21-10-2026) y consultas por páginas de `pagina` filas
servicio_n <- function(capas = capas_n(), pagina = 2L, fecha_ms = 1792585954664, contador = new.env()) {
  contador$consultas <- 0L
  function(url, consulta = list()) {
    capa <- sub("^.*/([0-9])(/query)?$", "\\1", url)
    if (!grepl("/query$", url)) {
      return(list(name = paste("Capa", capa), editingInfo = list(lastEditDate = fecha_ms, dataLastEditDate = fecha_ms - 1e6),
                  fields = list(list(name = "OBJECTID"), list(name = "precio_m2"))))
    }
    contador$consultas <- contador$consultas + 1L
    filas <- capas[[capa]]
    desde <- as.integer(consulta$resultOffset)
    trozo <- filas[seq_along(filas) > desde & seq_along(filas) <= desde + pagina]
    list(features = lapply(trozo, function(a) list(attributes = a)), exceededTransferLimit = desde + pagina < length(filas))
  }
}

test_that("penotariado: la foto se guarda en su carpeta con la fecha, por páginas, y no se vuelve a pedir", {
  dir <- withr::local_tempdir()
  cuenta <- new.env()
  pedir <- servicio_n(contador = cuenta)
  f <- descargar_penotariado(dir = dir, pedir = pedir, url = "https://ejemplo.invalid/FeatureServer")
  expect_equal(basename(dirname(f[1])), "2026-10-21")
  expect_equal(basename(f), c(paste0("capa_", c("nacional", "ccaa", "provincia", "municipio", "cp"), ".csv"), "definiciones.csv"))
  expect_equal(cuenta$consultas, 1 + 1 + 2 + 2 + 1)                   # el servidor da dos filas por página y avisa con exceededTransferLimit
  municipios <- readr::read_csv(f[4], col_types = readr::cols(.default = "c"))
  expect_equal(nrow(municipios), 4)
  # Segunda vez, la misma fecha: solo las definiciones
  antes <- cuenta$consultas
  descargar_penotariado(dir = dir, pedir = pedir, url = "https://ejemplo.invalid/FeatureServer")
  expect_equal(cuenta$consultas, antes)
  # Sin red: la última foto, con un aviso
  sin_red <- function(url, consulta = list()) stop("sin conexión")
  expect_warning(g <- descargar_penotariado(dir = dir, pedir = sin_red), "se usa la foto de 2026-10-21")
  expect_equal(g, f)
  expect_error(descargar_penotariado(dir = withr::local_tempdir(), pedir = sin_red), "No se ha podido consultar")
})

foto_n <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  leer_penotariado(descargar_penotariado(dir = dir, pedir = servicio_n(), url = "https://ejemplo.invalid/FeatureServer"))
}

test_that("penotariado: lectura con códigos con ceros, y se detiene si falta un campo", {
  pen <- foto_n()
  expect_equal(pen$fecha, as.Date("2026-10-21"))
  f <- pen$filas
  expect_equal(f$geo_id[f$nivel == "nacional"], "00")
  expect_true("04002" %in% f$geo_id[f$nivel == "municipio"])
  expect_true("04001" %in% f$geo_id[f$nivel == "cp"])
  expect_equal(f$precio_medio[f$geo_id == "28079"], 3200 * 85)

  capas <- capas_n()
  capas[["3"]] <- lapply(capas[["3"]], function(a) { a$precio_m2 <- NULL; a$precio_euros_m2 <- 1; a })
  dir <- withr::local_tempdir()
  rutas <- descargar_penotariado(dir = dir, pedir = servicio_n(capas), url = "https://ejemplo.invalid/FeatureServer")
  expect_error(leer_penotariado(rutas), "capa municipio: faltan los campos precio_m2")
})

test_that("penotariado: la compuerta pasa con la foto coherente y salta con sumas, identidades y rangos rotos", {
  pen <- foto_n()
  esperados <- c(nacional = 1, ccaa = 2, provincia = 3)
  ok <- comprobar_penotariado(pen, ter_n, hoy = as.Date("2026-11-19"), esperados = esperados)
  expect_true(all(ok$calculado[ok$id != "notariado_foto_antiguedad"] == 0), info = paste(ok$detalle[ok$calculado != 0], collapse = "; "))
  expect_equal(ok$calculado[ok$id == "notariado_foto_antiguedad"], 29)

  mal <- pen
  f <- mal$filas
  f$total[f$nivel == "ccaa" & f$geo_id == "13"] <- 700                            # comunidades: 1.100 frente a 1.000
  f$total[f$nivel == "municipio" & f$geo_id == "04001"] <- 400                    # municipios de Almería por encima
  f$precio_medio[f$nivel == "provincia" & f$geo_id == "28"] <- 1                  # identidad rota
  f$precio_m2[f$nivel == "municipio" & f$geo_id == "11001"] <- 30                 # fuera de rango (y de identidad)
  f <- dplyr::bind_rows(f, f[f$nivel == "provincia" & f$geo_id == "04", ])        # repetida
  f$geo_id[f$nivel == "municipio" & f$geo_id == "28079"] <- "28999"               # fuera del seccionado
  mal$filas <- f
  r <- comprobar_penotariado(mal, ter_n, hoy = as.Date("2026-11-19"), esperados = esperados)
  valor <- function(id, i = 1) r$calculado[r$id == id][i]
  expect_equal(valor("notariado_suma"), 10)
  expect_gt(valor("notariado_suma_municipios"), 0.1)
  expect_equal(valor("notariado_identidad"), 2)
  expect_equal(valor("notariado_rango"), 1)
  expect_equal(valor("notariado_codigos"), 1)
  expect_equal(valor("notariado_niveles", 3), 1)                                  # cuatro provincias (con la repetida) frente a tres
  expect_equal(valor("notariado_municipios"), 1)
})

test_that("penotariado frente al MIVAU: los cuatro últimos trimestres cerrados antes de la foto, España y provincias", {
  pen <- foto_n()                                                              # foto del 21-10-2026
  # Valor medio del MIVAU: España 190.000 € de media en los cuatro trimestres; el de 2026-T4 acaba después de la foto
  trim <- function(nivel, geo_id, valores, anio = c(2025L, 2026L, 2026L, 2026L, 2026L), trimestre = c(4L, 1L, 2L, 3L, 4L)) {
    tibble::tibble(nivel = nivel, geo_id = geo_id, anio = anio, trimestre = trimestre, valor = valores)
  }
  tt <- dplyr::bind_rows(trim("nacional", "00", c(180000, 185000, 195000, 200000, 900000)),
                         trim("provincia", "04", c(120000, 120000, 120000, 120000, 1)),
                         trim("provincia", "11", c(190400, 190400, 190400, 190400, 1)),
                         trim("provincia", "28", c(200000, 200000, 200000, 200000, 1)),
                         trim("ccaa", "13", c(1, 1, 1, 1, 1)))
  r <- comprobar_notariado_mivau(pen, tt)
  expect_equal(r$id, c("notariado_mivau_espana", "notariado_mivau_provincias"))
  expect_equal(r$anio, c(2026L, 2026L))
  expect_equal(r$calculado[1], 100 * (200000 / 190000 - 1))                    # España: 2.000 € × 100 m² frente a 190.000
  expect_match(r$detalle[1], "2025-T4 a 2026-T3")
  expect_equal(r$calculado[2], 1)                                              # Madrid: 270.000 frente a 200.000 (+35 %)
  expect_match(r$detalle[2], ": 28$")
  expect_equal(comprobar_notariado_mivau(pen, tt, margen_provincia = 40)$calculado[2], 0)

  # Una provincia sin sus cuatro trimestres cuenta como fuera; sin trimestres de España, NA (la alerta salta)
  corto <- tt[!(tt$geo_id == "04" & tt$anio == 2025L), ]
  expect_match(comprobar_notariado_mivau(pen, corto)$detalle[2], ": 04, 28$")
  vacio <- comprobar_notariado_mivau(pen, tt[tt$nivel != "nacional", ])
  expect_true(is.na(vacio$calculado[1]))
  expect_match(vacio$detalle[1], "sin trimestres")
  # Los trimestres sin cifra no cuentan: se toman los cuatro anteriores con valor
  hueco <- tt
  hueco$valor[hueco$nivel == "nacional" & hueco$anio == 2026L & hueco$trimestre == 3L] <- NA
  hueco <- dplyr::bind_rows(trim("nacional", "00", 175000, 2025L, 3L), hueco)
  expect_match(comprobar_notariado_mivau(pen, hueco)$detalle[1], "2025-T3 a 2026-T2")

  # Número de compraventas (22-nov-2026): los 12 meses de la foto frente a la suma de los cuatro trimestres
  nn <- dplyr::bind_rows(trim("nacional", "00", c(250, 260, 270, 280, 9999)),      # 1.060 frente a 1.000 de la foto
                         trim("provincia", "04", c(40, 40, 40, 40, 1)),            # 160 frente a 150
                         trim("provincia", "11", c(60, 60, 65, 65, 1)),            # 250 frente a 250
                         trim("provincia", "28", c(100, 100, 100, 100, 1)))        # 400 frente a 600 (+50 %)
  rn <- comprobar_notariado_mivau(pen, tt, nn)
  expect_equal(rn$id, c("notariado_mivau_espana", "notariado_mivau_provincias", "notariado_mivau_compraventas",
                        "notariado_mivau_compraventas_provincias"))
  expect_equal(rn[1:2, ], r)                                                   # el precio, como sin el recuento
  expect_equal(rn$calculado[3], 100 * (1000 / 1060 - 1))
  expect_match(rn$detalle[3], "compraventas de España frente a las del MIVAU de 2025-T4 a 2026-T3")
  expect_equal(rn$calculado[4], 1)
  expect_match(rn$detalle[4], "de las compraventas del MIVAU de 2025-T4 a 2026-T3: 28$")
  expect_equal(comprobar_notariado_mivau(pen, tt, nn[nn$geo_id != "11", ])$calculado[4], 2)   # sin trimestres, fuera

  referencias <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)
  expect_warning(validar_referencias(rn, referencias), "notariado_mivau_compraventas_provincias")   # alerta: avisa y no detiene
  expect_silent(validar_referencias(comprobar_notariado_mivau(pen, tt, nn, margen_provincia = 60), referencias))
})

test_that("penotariado: tabla con el umbral de 20 informadas (secreto), los estimados y sin códigos postales", {
  pen <- foto_n()
  larga <- armonizar_penotariado(pen, ter_n)
  expect_silent(validar_tabla_larga(larga, ind_n, tibble::tibble(id = c("notariado", "notariado_cien")), voc_n))
  expect_setequal(unique(larga$nivel), c("nacional", "ccaa", "provincia", "municipio"))
  expect_equal(unique(larga$anio), 2026L)
  expect_equal(unique(larga$fuente), "notariado")
  expect_equal(unique(larga$version), "2026-10-21")
  x <- function(ind, geo) larga[larga$indicador == ind & larga$geo_id == geo, ]
  expect_equal(x("precio_escriturado_m2", "04002")$estado, "secreto")             # 12 informadas
  expect_true(is.na(x("precio_escriturado_m2", "04002")$valor))
  expect_equal(x("precio_escriturado_vivienda", "04002")$estado, "secreto")
  expect_equal(x("compraventas_notariado", "04002")$valor, 15)                    # el número, siempre
  expect_equal(x("precio_escriturado_m2", "11001")$estado, "estimado")
  expect_equal(x("precio_escriturado_vivienda", "28079")$valor, 3200 * 85)
  expect_equal(x("precio_escriturado_m2", "00")$valor, 2000)
})

# ---- CIEN: servicio simulado ----

# Respuesta del buscador en Latin-1, como la del CIEN: filas con sus variables y el campo CALCD
fila_cien <- function(anio, n, cuantia, n_cuantia = n, comunidad = NULL, provincia = NULL, mes = NULL) {
  f <- list(ANO = as.character(anio), ACTOID = "1203", CALCD1203V7 = n_cuantia,
            VARIABLES = list(list(ID = "12", VALOR = n), list(ID = "7", VALOR = cuantia)))
  if (!is.null(comunidad)) f$COMUNIDADDESC <- comunidad
  if (!is.null(provincia)) f$PROVINCIADESC <- provincia
  if (!is.null(mes)) f$MES <- sprintf("%02d", mes)
  f
}
respuesta_cien <- function(filas) {
  texto <- jsonlite::toJSON(list(total = length(filas), datos = filas), auto_unbox = TRUE, digits = NA)
  iconv(texto, "UTF-8", "latin1", toRaw = TRUE)[[1]]
}
# Dos años: 2024 completo y 2025 con cinco meses. Andalucía del CIEN = Almería + Cádiz + Ceuta y Melilla
consultas_cien_n <- function(nd = FALSE) {
  anual <- function(y, k = 1) list(
    nacional = list(fila_cien(y, 1000 * k, 150000)),
    ccaa = list(fila_cien(y, 400 * k, 120000, comunidad = "Andalucía"),
                fila_cien(y, 600 * k, 170000, comunidad = "Madrid (Comunidad de)")),
    provincia = list(fila_cien(y, if (nd) "ND" else 100 * k, 100000, 100 * k, "Andalucía", "Almería"),
                     fila_cien(y, 250 * k, 128000, 250 * k, "Andalucía", "Cádiz"),
                     fila_cien(y, 50 * k, 120000, 50 * k, "Andalucía", "Ceuta y Melilla"),
                     fila_cien(y, 600 * k, 170000, 600 * k, "Madrid (Comunidad de)", "Madrid")))
  a24 <- anual(2024); a25 <- anual(2025, 0.5)
  list(
    nacional_anual = c(a24$nacional, a25$nacional), ccaa_anual = c(a24$ccaa, a25$ccaa),
    provincia_anual = c(a24$provincia, a25$provincia),
    nacional_mensual = c(lapply(1:12, function(m) fila_cien(2024, if (m <= 4) 100 else 75, 150000, mes = m)),
                         lapply(1:5, function(m) fila_cien(2025, 100, 150000, mes = m)))
  )
}
territorios_cien_n <- readr::read_csv(file.path("..", "..", "inventario", "notariado_cien_territorios.csv"),
                                      col_types = readr::cols(.default = "c"), na = "")
servicio_cien_n <- function(consultas = consultas_cien_n(), registro = new.env()) {
  registro$campos <- list()
  geografia <- charToRaw(enc2utf8(jsonlite::toJSON(list(list(id = "055", ccaa_id = 20, children = list(
    list(id = "152", ccaa_id = 20, prov_id = 52), list(id = "15", ccaa_id = 20, prov_id = 5)))), auto_unbox = TRUE)))
  function(url, campos = list()) {
    if (grepl("getGeografia", url)) return(geografia)
    registro$campos[[length(registro$campos) + 1L]] <- campos
    nivel <- names(CIEN_GEOGRAFIA)[CIEN_GEOGRAFIA == campos$geografia]
    periodicidad <- names(CIEN_TEMPORAL)[CIEN_TEMPORAL == campos$temporal]
    respuesta_cien(consultas[[paste(nivel, periodicidad, sep = "_")]])
  }
}

test_that("CIEN: consultas con los ids de getGeografia, caché renovada a los 30 días y la anterior si falla", {
  dir <- withr::local_tempdir()
  registro <- new.env()
  f <- descargar_notariado_cien(dir = dir, pedir = servicio_cien_n(registro = registro), hasta = as.Date("2026-11-19"))
  expect_equal(basename(f), c("hipotecas_vivienda_nacional_anual.json", "hipotecas_vivienda_ccaa_anual.json",
                              "hipotecas_vivienda_provincia_anual.json", "hipotecas_vivienda_nacional_mensual.json", "geografia.json"))
  campos <- registro$campos
  expect_length(campos, 4)
  expect_equal(campos[[2]]$ccaaid, "20")
  expect_equal(campos[[3]]$provid, "5,52")
  expect_equal(campos[[1]]$fechaFin, "01/11/2026")
  expect_equal(campos[[4]]$temporal, "02")
  expect_equal(c(campos[[1]]$actos, campos[[1]]$fpid, campos[[1]]$ocpid), c("1203,1203,1203", "1,1", "3"))
  # Al día: no se pide nada
  descargar_notariado_cien(dir = dir, pedir = function(...) stop("no debería pedir"))
  # Caducada y sin red: se conserva la anterior, con aviso
  Sys.setFileTime(f, Sys.time() - 40 * 86400)
  avisos <- testthat::capture_warnings(g <- descargar_notariado_cien(dir = dir, pedir = function(...) stop("sin conexión")))
  expect_length(avisos, 5)
  expect_true(all(grepl("se conserva la anterior", avisos)))
  expect_equal(g, f)
})

cien_n <- function(nd = FALSE, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  leer_notariado_cien(descargar_notariado_cien(dir = dir, pedir = servicio_cien_n(consultas_cien_n(nd))), territorios_cien_n)
}

test_that("CIEN: lectura en Latin-1, territorios casados, último mes y años completos", {
  cien <- cien_n()
  expect_true(all(cien$casado))
  expect_true("Andalucía" %in% cien$comunidad_cien)                               # tildes bien leídas
  expect_true(is.na(cien$geo_id[cien$nombre_cien == "Andalucía"][1]))              # con Ceuta y Melilla: sin código
  expect_equal(cien$geo_id[cien$nombre_cien == "Cádiz"][1], "11")
  expect_true(is.na(cien$geo_id[cien$nombre_cien == "Ceuta y Melilla"][1]))
  expect_equal(cien_ultimo_mes(cien), "2025-05")
  expect_equal(cien_anios_completos(cien), 2024L)
  # Un total que no cuadra con las filas: descarga cortada
  dir <- withr::local_tempdir()
  writeBin(charToRaw('{"total": 3, "datos": []}'), file.path(dir, "hipotecas_vivienda_nacional_anual.json"))
  expect_error(leer_notariado_cien(file.path(dir, "hipotecas_vivienda_nacional_anual.json"), territorios_cien_n), "Descarga cortada")
})

test_that("CIEN: compuerta de sumas, meses, referencia y cuantía ponderada", {
  cien <- cien_n()
  r <- comprobar_notariado_cien(cien, referencia = c("2024" = 1000))
  expect_true(all(abs(r$calculado - r$referencia) < 1e-9 | r$id == "notariado_cien_cuantia"),
              info = paste(r$id[abs(r$calculado - r$referencia) >= 1e-9], collapse = "; "))
  # Andalucía del CIEN: (100 × 100.000 + 250 × 128.000 + 50 × 120.000) / 400 = 120.000, igual que la publicada
  expect_true(all(r$calculado[r$id == "notariado_cien_cuantia"] < 1e-9))
  expect_equal(r$calculado[r$id == "notariado_cien_meses"], 0)                      # 4 × 100 + 8 × 75 = 1.000

  mal <- cien
  mal$n[mal$nivel == "ccaa" & mal$anio == 2024 & mal$nombre_cien == "Andalucía"] <- 401
  mal$nombre_cien[mal$nivel == "provincia" & mal$nombre_cien == "Cádiz" & mal$anio == 2025] <- "Cadiz"
  mal$casado <- mal$nivel == "nacional" | mal$nombre_cien %in% territorios_cien_n$nombre_cien
  r <- comprobar_notariado_cien(mal, referencia = c("2024" = 999))
  valor <- function(id) r$calculado[r$id == id]
  expect_equal(valor("notariado_cien_suma_ccaa"), c(1, 0))
  expect_equal(valor("notariado_cien_suma_provincias")[1], 1)
  expect_equal(valor("notariado_cien_territorios")[1], 1)
  expect_equal(valor("notariado_cien_espana"), 1000)
})

test_that("CIEN: tabla con años completos, Andalucía sin Ceuta y Melilla y Ceuta y Melilla sin dato", {
  cien <- cien_n()
  larga <- armonizar_notariado_cien(cien, ter_n, version = "2026-11-19")
  expect_silent(validar_tabla_larga(larga, ind_n, tibble::tibble(id = c("notariado", "notariado_cien")), voc_n))
  expect_equal(unique(larga$anio), 2024L)                                          # 2025 no está completo
  expect_equal(unique(larga$fuente), "notariado_cien")
  x <- function(ind, nivel, geo) larga[larga$indicador == ind & larga$nivel == nivel & larga$geo_id == geo, ]
  expect_equal(x("hipotecas_compra_vivienda", "ccaa", "01")$valor, 350)           # Almería + Cádiz, sin las 50 de Ceuta y Melilla
  expect_equal(x("hipotecas_compra_vivienda", "ccaa", "01")$estado, "dato")
  expect_equal(x("cuantia_hipoteca_vivienda", "ccaa", "01")$valor, (100 * 100000 + 250 * 128000) / 350)
  expect_equal(x("hipotecas_compra_vivienda", "ccaa", "13")$valor, 600)
  expect_equal(x("hipotecas_compra_vivienda", "nacional", "00")$valor, 1000)
  expect_false(any(larga$geo_id %in% c("18", "19", "51", "52")))

  # «ND» en una provincia: secreto, y Andalucía sin número
  larga_nd <- armonizar_notariado_cien(cien_n(nd = TRUE), ter_n)
  expect_equal(larga_nd$estado[larga_nd$indicador == "hipotecas_compra_vivienda" & larga_nd$nivel == "provincia" &
                                 larga_nd$geo_id == "04"], "secreto")
  expect_equal(larga_nd$estado[larga_nd$indicador == "hipotecas_compra_vivienda" & larga_nd$nivel == "ccaa" &
                                 larga_nd$geo_id == "01"], "secreto")
})

# ---- Web ----

# Firma de todos los ficheros de una exportación (ruta relativa y contenido)
firma_n <- function(dir) {
  f <- sort(list.files(dir, recursive = TRUE))
  stats::setNames(vapply(file.path(dir, f), function(r) paste(readLines(r, warn = FALSE), collapse = "
"), ""), f)
}

test_that("la capa sale en web/datos/notariado/, con su licencia y su compuerta, y no toca la exportación general", {
  dir <- withr::local_tempdir()
  base <- tibble::tibble(geo_id = c("0400101001", "2807901001"), nivel = "sc", anio = 2024L, indicador = "renta_persona",
                         corte = "total", grupo = "total", valor = c(11, 12), estado = "dato", fuente = "ine_adrh", geo_ref = "2021",
                         version = "2026-11-10")
  ind_g <- dplyr::bind_rows(tibble::tibble(id = 1, codigo = "renta_persona", unidad_es = "€ por persona y año", nucleo_v01 = TRUE,
                                           cortes_web = "10;20", escala_web = NA), ind_n)
  exportar_web(base, ind_g, jer_n, ter_n, dir_web = dir, fecha = "2026-11-19", vocabulario = voc_n)
  general <- firma_n(file.path(dir, "datos"))

  notariado_apagar_web(dir)
  expect_equal(jsonlite::fromJSON(file.path(dir, "datos", "notariado", "manifiesto.json")), list(capa = "notariado", activa = FALSE))

  pen <- foto_n()
  cien <- cien_n()
  larga <- dplyr::bind_rows(armonizar_penotariado(pen, ter_n), armonizar_notariado_cien(cien, ter_n, version = "2026-11-19"))
  rutas <- notariado_exportar_web(larga, ind_g, jer_n, ter_n, vocabulario = voc_n, foto = pen$fecha,
                                  ultimo_mes = cien_ultimo_mes(cien), dir_web = dir, fecha = "2026-11-19")
  expect_true(all(startsWith(rutas, file.path(dir, "datos", "notariado"))))
  ahora <- firma_n(file.path(dir, "datos"))
  expect_identical(ahora[names(general)], general)
  expect_true(all(startsWith(setdiff(names(ahora), names(general)), "notariado/")))

  m <- jsonlite::fromJSON(file.path(dir, "datos", "notariado", "manifiesto.json"), simplifyVector = FALSE)
  expect_true(m$activa)
  expect_equal(m$licencia, "© Consejo General del Notariado, solo uso no comercial")
  expect_equal(m$foto, "2026-10-21")
  expect_equal(m$cien_ultimo_mes, "2025-05")
  expect_setequal(names(m$indicadores), ind_n$codigo)
  s <- m$indicadores$precio_escriturado_m2
  expect_equal(s$fuente, "notariado")                                          # la web pone la etiqueta por la fuente
  expect_equal(s$foto, "2026-10-21")
  expect_equal(s$minimo_informadas, 20L)
  expect_equal(s$ruta, "datos/notariado/{nivel}/precio_escriturado_m2/{anio}.json")
  expect_equal(unlist(s$niveles), c("municipio", "provincia", "ccaa", "nacional"))
  h <- m$indicadores$hipotecas_compra_vivienda
  expect_equal(h$fuente, "notariado_cien")
  expect_null(h$foto)
  expect_equal(unlist(h$niveles), c("provincia", "ccaa", "nacional"))
  expect_equal(m$mapas$precio_escriturado_m2$nivel_minimo, "municipio")
  expect_equal(m$mapas$hipotecas_compra_vivienda$nivel_minimo, "provincia")
  # Municipios: 04001, 04002 (secreto), 11001 (estimado), 28079, y Ceuta y Melilla sin dato
  expect_equal(readLines(file.path(dir, "datos", "notariado", "municipio", "precio_escriturado_m2", "2026.json")),
               '{"v":[12500,null,18000,32000,null,null],"e":"021033"}')

  x <- notariado_comprobar_web(larga, ind_g, jer_n, ter_n, dir_web = dir)
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))
  writeLines('{"v":[1],"e":"0"}', file.path(dir, "datos", "notariado", "nacional", "precio_escriturado_m2", "2026.json"))
  writeLines("{}", file.path(dir, "datos", "notariado", "sobrante.json"))
  x <- notariado_comprobar_web(larga, ind_g, jer_n, ter_n, dir_web = dir)
  expect_equal(sum(x$calculado), 2)

  notariado_apagar_web(dir)
  expect_equal(list.files(file.path(dir, "datos", "notariado"), recursive = TRUE), "manifiesto.json")
})

test_that("el inventario trae las dos fuentes, sus indicadores, su etiqueta y su correspondencia", {
  raiz <- file.path("..", "..")
  fuentes <- readr::read_csv(file.path(raiz, "inventario", "fuentes.csv"), col_types = readr::cols(.default = "c"))
  expect_true(all(c("notariado", "notariado_cien") %in% fuentes$id))
  expect_match(fuentes$licencia[fuentes$id == "notariado"], "solo uso no comercial")
  expect_match(fuentes$licencia[fuentes$id == "notariado_cien"], "solo uso no comercial")
  ind <- readr::read_csv(file.path(raiz, "inventario", "indicadores.csv"), col_types = readr::cols(.default = "c"))
  notariales <- ind[grepl("notariado", ind$fuentes), ]
  expect_setequal(notariales$id, as.character(25:29))
  expect_false(any(grepl("registradores", notariales$fuentes)))                  # nunca mezclado con el 11
  expect_true(all(grepl("no comercial", notariales$lectura_es)))
  voc <- readr::read_csv(file.path(raiz, "inventario", "vocabulario.csv"), col_types = readr::cols(.default = "c"))
  etiquetas <- voc$es[voc$grupo == "etiqueta" & voc$clave %in% c("notariado", "notariado_cien")]
  expect_equal(unique(etiquetas), "© Consejo General del Notariado, solo uso no comercial")
  t <- readr::read_csv(file.path(raiz, "inventario", "notariado_cien_territorios.csv"), col_types = readr::cols(.default = "c"), na = "")
  expect_equal(sum(t$nivel == "ccaa"), 17)
  expect_equal(sum(t$nivel == "provincia"), 51)
  expect_equal(sort(t$geo_id[t$nivel == "provincia" & !is.na(t$geo_id)]), sprintf("%02d", 1:50))
  expect_false(anyDuplicated(t$nombre_cien[t$nivel == "provincia"]) > 0)
})
