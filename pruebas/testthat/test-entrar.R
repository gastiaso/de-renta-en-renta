# Indicadores de «entrar» (backlog, tarea 37; R/derivados_entrar.R), con datos inventados (ninguna
# cifra de un portal):
#   - los tramos de inventario/entrar_tramos.csv cumplen su ancho mínimo y los derivados no tienen
#     cortes propios (decisión 18: con varios juegos de tramos se reconstruye la oferta);
#   - R y la página coinciden: los casos de pruebas/datos/entrar_inventado.json, que también comprueba
#     pruebas/web/entrar.test.mjs (tramo, límites, intervalos, «¿te llega?» y fichero de tramos);
#   - cálculo exacto, estados (sin informe o sin SERPAVI, ausente; ingreso del mismo año), compuerta
#     (rango, aviso de 2 o más, coherencia, referencias y aviso del IPVA) y exportación a la carpeta de
#     la capa de portales con su ida y vuelta, sin ninguna cifra exacta.

CASOS_ENTRAR <- jsonlite::fromJSON(file.path("..", "datos", "entrar_inventado.json"), simplifyVector = FALSE)
TRAMOS_INVENTARIO <- file.path("..", "..", "inventario", "entrar_tramos.csv")
REFERENCIAS_CSV <- readr::read_csv(file.path("..", "..", "inventario", "referencias_validacion.csv"), show_col_types = FALSE)

# Tramos del inventario con los cortes de los casos (los del CSV pueden cambiar; los casos, no)
tramos_casos <- function() {
  t <- entrar_leer_tramos(TRAMOS_INVENTARIO)
  b <- CASOS_ENTRAR$tramos
  i <- t$indicador == ENTRAR_BASE
  t$cortes[i] <- paste(unlist(b$cortes), collapse = ";")
  t$limite_inferior[i] <- as.character(b$limites[[1]])
  t$limite_superior[i] <- as.character(b$limites[[2]])
  t$aviso[i] <- as.character(b$aviso)
  t
}
cerca <- function(a, b) expect_equal(a, b, tolerance = 1e-9)

test_that("los tramos del inventario: la brecha con su ancho mínimo y los derivados sin cortes propios", {
  t <- entrar_leer_tramos(TRAMOS_INVENTARIO)
  expect_setequal(t$indicador, c(ENTRAR_BASE, ENTRAR_DERIVADOS))
  expect_true(all(t$estado == "por revisar"))
  x <- entrar_comprobar_tramos(t)
  expect_true(all(x == 0), info = paste(names(x)[x != 0], collapse = "; "))
  b <- entrar_cortes(t)
  bordes <- c(b$limites[1], b$cortes, b$limites[2])
  expect_true(all(bordes[-1] / bordes[-length(bordes)] >= 1 + b$ancho_minimo - 1e-9))
  expect_equal(entrar_cortes(t, "barrera_entrar")$cortes, c(30, 40))   # los de «¿te llega?» (LIMITES_LLEGA de la web)
  # Un tramo más estrecho que el ancho mínimo, o un derivado con cortes propios, no pasa
  t2 <- t
  t2$cortes[t2$indicador == ENTRAR_BASE] <- "1;1.1;1.35;1.6;2"
  expect_gt(entrar_comprobar_tramos(t2)[["tramos de la brecha mas estrechos que el ancho minimo"]], 0)
  t3 <- t
  t3$cortes[t3$indicador == "sueldo_entrar_50"] <- "1000;1500;2000"
  expect_equal(entrar_comprobar_tramos(t3)[["derivados con cortes propios"]], 1)
})

test_that("R y la página coinciden: tramo, límites, intervalos y «¿te llega?» de los casos comunes", {
  b <- entrar_cortes(tramos_casos())
  brechas <- vapply(CASOS_ENTRAR$brechas, function(x) x[[1]], numeric(1))
  esperado <- vapply(CASOS_ENTRAR$brechas, function(x) as.integer(x[[2]]), integer(1))
  expect_equal(entrar_tramo(brechas, b$cortes), esperado)
  expect_equal(entrar_tramo(c(NA, 11.5 / 10), b$cortes), c(NA, 2L))       # el corte, al tramo de arriba
  for (caso in CASOS_ENTRAR$casos) {
    l <- entrar_limites_tramo(caso$tramo, b)
    expect_equal(c(l$desde, l$hasta), unlist(caso$limites))
    f <- entrar_factores(caso$alquiler_m2, caso$alquiler_mes, caso$ingreso, caso$superficie, caso$umbral)
    for (cifra in ENTRAR_DERIVADOS) {
      i <- entrar_intervalo(caso$tramo, b, f[[cifra]])
      cerca(c(i$desde, i$hasta), unlist(caso[[cifra]]))
    }
    ll <- entrar_llega(entrar_intervalo(caso$tramo, b, f$barrera_entrar))
    expect_equal(c(ll$desde, ll$hasta), as.integer(unlist(caso$llega)))
    expect_equal(ll$en_limite, caso$llega[[1]] != caso$llega[[2]])
  }
})

test_that("R escribe el fichero de tramos que la página lee en los casos comunes", {
  fx <- CASOS_ENTRAR$fichero
  indice <- unlist(fx$indice)
  web <- tibble::tibble(geo_id = indice, nivel = "municipio", anio = 2024L, indicador = ENTRAR_BASE,
                        tramo = vapply(fx$tramos, function(x) if (is.null(x)) NA_integer_ else as.integer(x), integer(1)),
                        estado = unlist(fx$estados))
  web <- web[web$estado != "ausente", ]                                    # sin fila: null y ausente
  dir <- withr::local_tempdir()
  e <- entrar_escribir_web(web, tramos_casos(), list(municipio = indice), dir)
  expect_equal(readLines(e$rutas), fx$json)
  expect_equal(e$manifiesto$series[[ENTRAR_BASE]]$ruta, "datos/portales/entrar/{nivel}/brecha_entrar_quedarse/{anio}.json")
  expect_equal(as.numeric(e$manifiesto$tramos$cortes), as.numeric(unlist(CASOS_ENTRAR$tramos$cortes)))
  expect_equal(as.numeric(e$manifiesto$derivados$barrera_entrar$cortes), c(0.3, 0.4))
  expect_named(e$manifiesto$series, ENTRAR_BASE)                           # un solo dato derivado de la oferta
})

# --- Datos inventados del pipeline -------------------------------------------------------------
# Capa de portales: cifras mensuales constantes (la media anual es la cifra), por territorio y año;
# 28003 tiene solo seis meses en 2024 (ausente); 28005, SERPAVI en secreto.
OFERTA_E <- tibble::tribble(
  ~nivel,      ~geo_id, ~anio, ~valor, ~meses,
  "nacional",  "00",    2015,  8,      12,
  "nacional",  "00",    2024,  11,     12,
  "ccaa",      "13",    2024,  13,     12,
  "provincia", "28",    2015,  9,      12,
  "provincia", "28",    2021,  10,     12,
  "provincia", "28",    2024,  12,     12,
  "municipio", "28001", 2015,  10,     12,
  "municipio", "28001", 2021,  11,     12,
  "municipio", "28001", 2024,  14,     12,
  "municipio", "28001", 2025,  15,     10,
  "municipio", "28002", 2024,  9,      12,
  "municipio", "28003", 2024,  12,     6,
  "municipio", "28004", 2024,  21,     12,
  "municipio", "28005", 2024,  12,     12
)
csv_oferta_e <- function(dir) {
  filas <- lapply(seq_len(nrow(OFERTA_E)), function(k) {
    o <- OFERTA_E[k, ]
    tibble::tibble(portal = "idealista", operacion = "alquiler", nivel = o$nivel, geo_id = o$geo_id, zona = NA_character_,
                   nombre = paste("Territorio", o$geo_id), periodo = sprintf("%d-%02d", o$anio, seq_len(o$meses)),
                   valor = o$valor, informe = "Informe inventado para pruebas", url = "https://ejemplo.invalid/informe")
  })
  ruta <- file.path(dir, "oferta_inventada.csv")
  readr::write_csv(dplyr::bind_rows(filas), ruta, na = "")
  ruta
}
serpavi_e <- function() {
  x <- tibble::tribble(
    ~nivel,      ~geo_id, ~anio, ~m2,  ~mes, ~estado,
    "ccaa",      "13",    2024,  9.5,  760,  "dato",
    "provincia", "28",    2015,  7.5,  600,  "dato",
    "provincia", "28",    2024,  10,   750,  "dato",
    "municipio", "28001", 2015,  8,    640,  "dato",
    "municipio", "28001", 2021,  9,    700,  "dato",
    "municipio", "28001", 2024,  10,   700,  "dato",
    "municipio", "28003", 2024,  7,    500,  "dato",
    "municipio", "28004", 2024,  10,   800,  "dato",
    "municipio", "28005", 2024,  NA,   NA,   "secreto"
  )
  fila <- function(ind, v) tibble::tibble(geo_id = x$geo_id, nivel = x$nivel, anio = as.integer(x$anio), indicador = ind,
                                          corte = "tipologia", grupo = "VC", valor = v, estado = x$estado,
                                          fuente = "mivau_serpavi", geo_ref = "2021", version = "2026-03-18")
  dplyr::bind_rows(fila("alquiler_m2", x$m2), fila("alquiler_mes", x$mes))
}
perfiles_e <- tibble::tribble(
  ~ficha,       ~nivel,      ~geo_id, ~anio, ~ingreso, ~estado,
  "tartera",    "nacional",  "00",    2015,  700,      "dato",
  "tartera",    "nacional",  "00",    2021,  1100,     "dato",
  "tartera",    "nacional",  "00",    2024,  1200,     "dato",
  "tartera",    "nacional",  "00",    2025,  1250,     "dato",
  "mochila",    "provincia", "28",    2015,  NA,       "ausente",
  "mochila",    "provincia", "28",    2024,  1500,     "estimado",
  "transistor", "provincia", "28",    2024,  1300,     "dato"
) |> dplyr::mutate(anio = as.integer(anio), superficie_m2 = 50, fuente = "prueba")
ipva_e <- tibble::tibble(geo_id = "28", nivel = "provincia", anio = 2021:2024, indicador = "var_alquiler", corte = "contrato",
                         grupo = "nuevo", valor = c(1, 2, 3, 4), estado = "dato", fuente = "ine_ipva", geo_ref = "2021",
                         version = "2026-05-11")
REFERENCIAS_E <- list(municipios = c("2015" = 1, "2024" = 2), mediana = c("2015" = 1.25, "2024" = 1.75),
                      mediana_rango = c("2024" = 1.75), superficie = c("2024" = 75))

capa_e <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  p <- leer_portales(csv_oferta_e(dir))
  a <- anualizar_portales(p)
  list(portales = p, anual = a, larga = armonizar_portales(a, version = "2026-11-10"))
}

test_that("cálculo exacto: brecha, superficie típica, sueldos y barrera, con sus estados", {
  capa <- capa_e()
  t <- entrar_terminos(capa$larga, serpavi_e(), perfiles_e)
  x <- entrar_calcular(t)
  v <- function(ind, geo, anio, grupo = "total") x[x$indicador == ind & x$geo_id == geo & x$anio == anio & x$grupo == grupo, ]
  cerca(v(ENTRAR_BASE, "28001", 2024)$valor, 1.4)
  cerca(v("superficie_tipica", "28001", 2024)$valor, 70)
  cerca(v("sueldo_entrar", "28001", 2024)$valor, 14 * 70 / 0.3)
  cerca(v("sueldo_entrar_50", "28001", 2024)$valor, 14 * 50 / 0.3)
  cerca(v("barrera_entrar", "28001", 2024, "tartera")$valor, 100 * 14 * 50 / 1200)
  cerca(v("barrera_entrar", "28001", 2024, "mochila")$valor, 100 * 14 * 50 / 1500)
  expect_equal(v("barrera_entrar", "28001", 2024, "mochila")$estado, "dato")   # el de la oferta (como el 15)
  expect_equal(v("barrera_entrar", "28001", 2015, "mochila")$estado, "ausente") # sin ingreso ese año
  cerca(v("barrera_entrar", "28001", 2015, "tartera")$valor, 100 * 10 * 50 / 700)   # el SMI del mismo año
  expect_equal(v(ENTRAR_BASE, "28002", 2024)$estado, "ausente")             # sin SERPAVI
  expect_equal(v(ENTRAR_BASE, "28003", 2024)$estado, "ausente")             # menos de 9 meses
  expect_equal(v("sueldo_entrar_50", "28003", 2024)$estado, "ausente")
  expect_equal(v(ENTRAR_BASE, "28005", 2024)$estado, "secreto")
  expect_equal(v(ENTRAR_BASE, "28001", 2025)$estado, "ausente")             # sin SERPAVI de 2025
  expect_equal(v("sueldo_entrar_50", "28001", 2025)$estado, "dato")
  expect_equal(v(ENTRAR_BASE, "00", 2024)$estado, "ausente")                # el SERPAVI no da España
  expect_true(is.na(v("barrera_entrar", "13", 2024, "mochila")$valor))      # comunidad: sin ingreso provincial
  expect_false(any(is.na(x$valor) == con_valor(x$estado)))
  w <- entrar_tramos_web(x, tramos_casos())
  tramo <- function(geo, anio) w$tramo[w$geo_id == geo & w$anio == anio]
  expect_equal(c(tramo("28001", 2015), tramo("28001", 2024), tramo("28004", 2024), tramo("28", 2024), tramo("13", 2024)),
               c(2L, 3L, 5L, 2L, 3L))
  expect_true(is.na(tramo("28002", 2024)))
})

test_that("la compuerta: referencias, rango, aviso de 2 o más, coherencia y aviso del IPVA", {
  capa <- capa_e()
  t <- entrar_terminos(capa$larga, serpavi_e(), perfiles_e)
  x <- entrar_calcular(t)
  tr <- tramos_casos()
  ter <- tibble::tibble(nivel = c("provincia", "municipio"), codigo = c("28", "28004"), nombre = c("Madrid", "Cuatro"))
  c1 <- entrar_comprobar(x, t, tr, capa$larga, ipva_e, ter, referencias = REFERENCIAS_E)
  expect_setequal(setdiff(unique(REFERENCIAS_CSV$id[startsWith(REFERENCIAS_CSV$id, "entrar_")]), unique(c1$id)), character(0))
  bloqueo <- c1[!c1$id %in% c("entrar_rango_detalle", "entrar_ipva"), ]
  r <- validar_referencias(bloqueo, REFERENCIAS_CSV)                       # pasa: no se detiene
  expect_true(all(r$correcto))
  # Aviso: 28004, brecha 2,1; IPVA: la oferta de la provincia crece un 20 % y los contratos nuevos, un 9,3 %
  expect_equal(c1$detalle[c1$id == "entrar_rango_detalle"], "municipio 28004 Cuatro 2.10")
  ipva <- c1[c1$id == "entrar_ipva", ]
  expect_equal(nrow(ipva), 1L)
  expect_equal(ipva$calculado, 1)
  expect_match(ipva$detalle, "provincia 28 Madrid")
  expect_warning(validar_referencias(c1, REFERENCIAS_CSV), "entrar_ipva")
  # Una brecha fuera de 0,8-2,5 para el pipeline
  t2 <- t
  t2$oferta[t2$geo_id == "28004" & t2$anio == 2024] <- 30
  c2 <- entrar_comprobar(entrar_calcular(t2), t2, tr, capa$larga, ipva_e, ter, referencias = REFERENCIAS_E)
  expect_equal(c2$calculado[c2$id == "entrar_rango"], 1)
  expect_error(validar_referencias(c2[c2$id == "entrar_rango", ], REFERENCIAS_CSV), "entrar_rango")
  # Una cifra exacta que no cae en el intervalo de su tramo
  x3 <- x
  x3$valor[x3$indicador == "sueldo_entrar_50" & x3$geo_id == "28001" & x3$anio == 2024] <- 1
  c3 <- entrar_comprobar(x3, t, tr, capa$larga, ipva_e, ter, referencias = REFERENCIAS_E)
  expect_equal(sum(c3$calculado[c3$id == "entrar_coherencia"]), 1)
})

test_that("la exportación: solo el tramo de la brecha, en la carpeta de la capa, con su ida y vuelta", {
  capa <- capa_e()
  t <- entrar_terminos(capa$larga, serpavi_e(), perfiles_e)
  x <- entrar_calcular(t)
  tr <- tramos_casos()
  web <- entrar_tramos_web(x, tr)
  jer <- tibble::tibble(seccion = paste0("2800", 1:5, "01001"), distrito = paste0("2800", 1:5, "01"),
                        municipio = paste0("2800", 1:5), provincia = "28", ccaa = "13")
  ter <- geo_territorios(jer, tibble::tibble(municipio = paste0("2800", 1:5), nombre = c("Uno", "Dos", "Tres", "Cuatro", "Cinco")),
                         tibble::tibble(provincia = "28", nombre = "Madrid", ccaa = "13"),
                         tibble::tibble(codigo = "13", nombre_ine = "Madrid, Comunidad de", nuts2 = "ES30"))
  ind <- tibble::tibble(id = 13, codigo = "precio_oferta", unidad_es = "€ por m² (alquiler: por m² y mes)", nucleo_v01 = FALSE,
                        cortes_web = "8;10;12;15;20", escala_web = 100)
  voc <- readr::read_csv(file.path("..", "..", "inventario", "vocabulario.csv"), show_col_types = FALSE)
  dir <- withr::local_tempdir()
  rutas <- portales_exportar_web(capa$larga, capa$anual, capa$portales, ind, jer, ter, vocabulario = voc, dir_web = dir,
                                 fecha = "2026-11-10", entrar = web, tramos_entrar = tr)
  carpeta <- file.path(dir, "datos", "portales", "entrar")
  expect_true(all(file.path(carpeta, list.files(carpeta, recursive = TRUE)) %in% rutas))
  expect_setequal(list.files(carpeta, recursive = TRUE),
                  as.vector(outer(c("municipio", "provincia", "ccaa"), c(2015, 2021, 2024),
                                  function(n, a) file.path(n, ENTRAR_BASE, paste0(a, ".json")))))
  expect_equal(readLines(file.path(carpeta, "municipio", ENTRAR_BASE, "2024.json")), '{"v":[3,null,null,5,null],"e":"03302"}')
  m <- jsonlite::fromJSON(file.path(dir, "datos", "portales", "manifiesto.json"), simplifyVector = FALSE)
  expect_equal(m$entrar$base, ENTRAR_BASE)
  expect_equal(unlist(m$entrar$series[[ENTRAR_BASE]]$niveles), c("municipio", "provincia", "ccaa"))
  expect_equal(unlist(m$entrar$series[[ENTRAR_BASE]]$anios), c(2015L, 2021L, 2024L))
  expect_null(m$indicadores[[ENTRAR_BASE]])                                 # la web de hoy no lo pinta (tareas 38 y 39)
  # Ninguna cifra exacta: en los ficheros de «entrar», solo enteros de 0 a 5
  valores <- unlist(lapply(file.path(carpeta, list.files(carpeta, recursive = TRUE)), function(f) jsonlite::fromJSON(f)$v))
  expect_true(all(is.na(valores) | valores %in% 0:5))
  ida <- entrar_comprobar_web(web, tr, jer, ter, dir_web = dir)
  expect_true(all(ida$calculado == 0), info = paste(ida$detalle[ida$calculado != 0], collapse = "; "))
  validar_referencias(ida, REFERENCIAS_CSV)
  # Con la cifra exacta en un fichero, la compuerta para
  writeLines('{"v":[1.4,null,null,5,null],"e":"03302"}', file.path(carpeta, "municipio", ENTRAR_BASE, "2024.json"))
  mal <- entrar_comprobar_web(web, tr, jer, ter, dir_web = dir)
  expect_equal(mal$calculado[mal$detalle == "valores que no son un tramo (decision 18)"], 1)
  expect_error(validar_referencias(mal, REFERENCIAS_CSV), "web_entrar")
  # Sin tramos, el manifiesto de la capa no lleva la entrada
  portales_exportar_web(capa$larga, capa$anual, capa$portales, ind, jer, ter, vocabulario = voc, dir_web = dir, fecha = "2026-11-10")
  expect_null(jsonlite::fromJSON(file.path(dir, "datos", "portales", "manifiesto.json"))$entrar)
  expect_false(dir.exists(carpeta))
  expect_equal(entrar_comprobar_web(web, tr, jer, ter, dir_web = dir)$calculado, 1)
})
