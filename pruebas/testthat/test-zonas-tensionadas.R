# Indicador 20 (F5): zonas de mercado residencial tensionado (R/fuente_zonas_tensionadas.R), con una
# resolución del BOE inventada (misma estructura que las del MIVAU: tabla con comunidad,
# municipios, periodo de vigencia y declaración) y un nomenclátor inventado.

xml_boe_inventado <- function(id = "BOE-A-2099-1", publicacion = "20990315", filas) {
  tr <- vapply(filas, function(f) paste0(
    "<tr><td class=\"cuerpo_tabla_izq\">", f[1], "</td><td class=\"cuerpo_tabla_izq\">", f[2], "</td>",
    "<td class=\"cuerpo_tabla_izq\">", f[3], "</td><td>Gran tenedor</td><td>Sí</td>",
    "<td><p>– Declaración: Orden de prueba (Boletín núm. 1) https://diario.example/orden.html</p>",
    "<p>– Memoria: https://diario.example/memoria.pdf</p></td></tr>"), "")
  ruta <- tempfile(fileext = ".xml")
  writeLines(enc2utf8(paste0(
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><documento><metadatos><identificador>", id, "</identificador>",
    "<fecha_disposicion>20990310</fecha_disposicion><fecha_publicacion>", publicacion, "</fecha_publicacion>",
    "<titulo>Resolución de prueba</titulo></metadatos><texto><p>Preámbulo</p><table><thead><tr><th>Comunidad</th>",
    "<th>Municipios</th><th>Vigencia</th></tr></thead><tbody>", paste(tr, collapse = ""), "</tbody></table></texto></documento>")),
    ruta, useBytes = TRUE)
  ruta
}

VIGENCIA <- "Tres años desde el día siguiente a la publicación de la presente resolución, de acuerdo con el artículo 18.2.d)."

territorios_inventados <- function() tibble::tribble(
  ~nivel, ~codigo, ~nombre, ~superior, ~secciones,
  "ccaa", "09", "Cataluña", NA, "4",
  "ccaa", "16", "País Vasco", NA, "2",
  "provincia", "08", "Barcelona", "09", "3",
  "provincia", "17", "Girona", "09", "1",
  "provincia", "01", "Araba/Álava", "16", "1",
  "provincia", "20", "Gipuzkoa", "16", "1",
  "municipio", "08118", "Masnou, El", "08", "1",
  "municipio", "08101", "Hospitalet de Llobregat, L'", "08", "1",
  "municipio", "08219", "Vilassar de Mar", "08", "1",
  "municipio", "17048", "Castell d'Aro, Platja d'Aro i s'Agaró", "17", "1",
  "municipio", "01059", "Vitoria-Gasteiz", "01", "1",
  "municipio", "20069", "Donostia/San Sebastián", "20", "1"
)

boe_inventado <- function() {
  ruta <- xml_boe_inventado(filas = list(
    c("Cataluña.", "el Masnou, l'Hospitalet de Llobregat, i Vilassar de Mar.", VIGENCIA),
    c("País Vasco.", "Vitoria-Gasteiz, excepto la zona rural de prueba.", VIGENCIA),
    c("País Vasco.", "Donostia/San Sebastián.", VIGENCIA)
  ))
  leer_boe_zonas_tensionadas(ruta)
}

test_that("las filas de la tabla del BOE se leen con su comunidad, municipios, vigencia y declaración", {
  b <- boe_inventado()
  expect_equal(nrow(b), 3L)
  expect_equal(b$boe[1], "BOE-A-2099-1")
  expect_equal(b$fecha_publicacion[1], as.Date("2099-03-15"))
  expect_equal(b$comunidad, c("Cataluña", "País Vasco", "País Vasco"))
  expect_equal(b$municipios[1], "el Masnou, l'Hospitalet de Llobregat, i Vilassar de Mar")
  expect_equal(zt_anios_vigencia(b$vigencia), c(3L, 3L, 3L))
  expect_equal(zt_declaracion_boe(b$declaracion[1]), "Orden de prueba (Boletín núm. 1)")
  expect_equal(zt_enlace_declaracion(b$declaracion[1]), "https://diario.example/orden.html")
})

test_that("el periodo de vigencia acaba el mismo día del año de vencimiento", {
  expect_equal(zt_fin_vigencia(as.Date("2024-03-15"), 3L), as.Date("2027-03-15"))
  expect_equal(zt_fin_vigencia(as.Date("2024-02-29"), 3L), as.Date("2027-02-28"))
  expect_true(is.na(zt_anios_vigencia("Hasta que la comunidad lo revoque")))
})

test_that("la propuesta casa nombres con artículo pospuesto, formas bilingües y salvedades", {
  p <- proponer_zonas_tensionadas(boe_inventado(), territorios_inventados())
  expect_equal(p$municipio, c("08118", "08101", "08219", "01059", "20069"))
  expect_equal(p$nombre_boe[3], "Vilassar de Mar")
  expect_equal(p$ambito, c("municipio", "municipio", "municipio", "parcial", "municipio"))
  expect_equal(p$ambito_texto[4], "excepto la zona rural de prueba")
  expect_equal(p$fecha_inicio[1], as.Date("2099-03-16"))
  expect_equal(p$fecha_fin[1], as.Date("2102-03-15"))
  expect_equal(zt_normalizar_municipio("Hospitalet de Llobregat, L'"), "hospitalet de llobregat")
  expect_equal(zt_partir_lista("Llanes (núcleos de Nueva, Poo), Cabrales"), c("Llanes (núcleos de Nueva, Poo)", "Cabrales"))
})

zonas_inventadas <- function() {
  p <- proponer_zonas_tensionadas(boe_inventado(), territorios_inventados())
  p[COLUMNAS_ZONAS_TENSIONADAS]
}

test_that("la compuerta pasa con el inventario que reproduce el BOE", {
  x <- comprobar_zonas_tensionadas(zonas_inventadas(), boe_inventado(), territorios_inventados())
  expect_true(all(x$calculado == 0), info = paste(x$detalle[x$calculado != 0], collapse = "; "))
  expect_setequal(unique(x$id), c("zonas_tensionadas_resolucion", "zonas_tensionadas_codigos", "zonas_tensionadas_nombre",
                                  "zonas_tensionadas_completa", "zonas_tensionadas_fechas", "zonas_tensionadas_ambito"))
})

test_that("la compuerta para con códigos, nombres, fechas, ámbitos y municipios que faltan", {
  b <- boe_inventado()
  ter <- territorios_inventados()
  suma <- function(z, id) sum(comprobar_zonas_tensionadas(z, b, ter)$calculado[comprobar_zonas_tensionadas(z, b, ter)$id == id])
  z <- zonas_inventadas()
  z1 <- z; z1$municipio[1] <- "08999"
  expect_gt(suma(z1, "zonas_tensionadas_codigos"), 0)
  z2 <- z; z2$nombre_boe[2] <- "Badalona"
  expect_gt(suma(z2, "zonas_tensionadas_nombre"), 0)
  expect_gt(suma(z2, "zonas_tensionadas_completa"), 0)          # l'Hospitalet queda sin fila
  z3 <- z; z3$fecha_fin[1] <- z3$fecha_fin[1] + 1
  expect_gt(suma(z3, "zonas_tensionadas_fechas"), 0)
  z4 <- z; z4$ambito_texto[4] <- ""
  expect_gt(suma(z4, "zonas_tensionadas_ambito"), 0)
  z5 <- z[-5, ]
  expect_gt(suma(z5, "zonas_tensionadas_completa"), 0)          # Donostia, en el BOE y no en el CSV
  z6 <- z; z6$boe[1] <- "BOE-A-2099-2"
  expect_gt(suma(z6, "zonas_tensionadas_resolucion"), 0)
})

test_that("la tabla larga da la situación a 31 de diciembre de todos los municipios", {
  z <- zonas_inventadas()
  z$fecha_publicacion <- as.Date("2024-03-15"); z$fecha_inicio <- as.Date("2024-03-16"); z$fecha_fin <- as.Date("2027-03-15")
  z$fecha_inicio[5] <- as.Date("2025-01-31"); z$fecha_fin[5] <- as.Date("2028-01-30")    # Donostia, desde 2025
  larga <- armonizar_zonas_tensionadas(z, territorios_inventados(), version = "2099-01-01", anios = 2024:2027)
  expect_equal(nrow(larga), 6L * 4L)
  validar_tabla_larga(larga)
  v <- function(cod, anio) larga$valor[larga$geo_id == cod & larga$anio == anio]
  expect_equal(v("08118", 2024), 2)
  expect_equal(v("01059", 2024), 1)       # parte del municipio
  expect_equal(v("20069", 2024), 0)       # aún sin declaración
  expect_equal(v("20069", 2025), 2)
  expect_equal(v("17048", 2025), 0)       # nunca declarado
  expect_equal(v("08118", 2027), 0)       # vencida el 15 de marzo de 2027
  expect_true(all(larga$estado == "dato" & larga$nivel == "municipio" & larga$fuente == "zonas_tensionadas"))
})

test_that("el inventario real cumple su forma: códigos de cinco cifras, ámbitos y fechas", {
  z <- leer_zonas_tensionadas(file.path("..", "..", "inventario", "zonas_tensionadas.csv"))
  expect_true(all(grepl("^[0-9]{5}$", z$municipio)))
  expect_true(all(grepl("^BOE-A-[0-9]{4}-[0-9]+$", z$boe)))
  expect_true(all(z$ambito %in% names(AMBITOS_ZONAS_TENSIONADAS)))
  expect_true(all(z$fecha_inicio == z$fecha_publicacion + 1))
  expect_true(all(z$fecha_fin > z$fecha_inicio))
  expect_equal(z$url, sprintf(URL_BOE_ZONAS_TEXTO, z$boe))
})
