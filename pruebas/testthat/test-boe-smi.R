# Salario mínimo de la tartera: cuantías del BOE y su compuerta (R/fuente_boe_smi.R). XML inventados
# con la forma de los del BOE.

xml_smi <- function(dir, anio, id, decreto, cuantia, desde = "enero") {
  ruta <- file.path(dir, paste0(anio, "_", id, ".xml"))
  writeLines(c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<documento><metadatos>",
    sprintf("<identificador>%s</identificador>", id),
    sprintf("<titulo>Real Decreto %s, por el que se fija el salario mínimo interprofesional para %d.</titulo>", decreto, anio),
    "</metadatos><analisis><notas><nota>Otro texto con 1 euros/mes que no cuenta</nota></notas></analisis><texto>",
    sprintf("<p>El salario mínimo queda fijado en 30 euros/día o %s euros/mes, según el salario.</p>", cuantia),
    sprintf("<p>Este real decreto surtirá efectos durante el período comprendido entre el 1 de %s y el 31 de diciembre de %d.</p>", desde, anio),
    "</texto></documento>"), ruta, useBytes = TRUE)
  ruta
}

test_that("leer_boe_smi: cuantía mensual con decimales y miles, año, norma y mes de efectos", {
  dir <- tempfile("smi"); dir.create(dir)
  r <- c(xml_smi(dir, 2018L, "BOE-A-2017-1", "1077/2017", "735,9"),
         xml_smi(dir, 2022L, "BOE-A-2022-1", "152/2022", "1.000"),
         xml_smi(dir, 2021L, "BOE-A-2021-1", "817/2021", "965", desde = "septiembre"))
  b <- leer_boe_smi(r)
  expect_equal(b$anio, c(2018L, 2022L, 2021L))
  expect_equal(b$mensual, c(735.9, 1000, 965))
  expect_equal(b$desde, c(1L, 1L, 9L))
  expect_equal(b$norma, c("RD 1077/2017", "RD 152/2022", "RD 817/2021"))
  expect_equal(b$id[3], "BOE-A-2021-1")
})

test_that("comprobar_smi_boe: 2021 con la media ponderada por meses de vigencia (pregunta 18)", {
  boe <- tibble::tibble(anio = c(2020L, 2021L), norma = c("RD 231/2020", "RD 817/2021"),
                        id = c("a", "b"), mensual = c(950, 965), desde = c(1L, 9L))
  c1 <- comprobar_smi_boe(boe)
  cuantia <- filter(c1, grepl("cuant", detalle))
  expect_equal(cuantia$referencia, c(950, 955))
  expect_equal(cuantia$calculado, c(950, 955))
  expect_true(all(c1$calculado[grepl("norma$", c1$detalle)] == 0))
  # Una cuantía o una norma mal en SMI_FICHAS: la compuerta lo ve
  mal <- mutate(SMI_FICHAS, mensual = ifelse(anio == 2021L, 965, mensual), norma = ifelse(anio == 2020L, "RD 1/2020", norma))
  c2 <- comprobar_smi_boe(boe, mal)
  expect_equal(filter(c2, anio == 2021L, grepl("cuant", detalle))$calculado - 955, 10)
  expect_equal(filter(c2, anio == 2020L, grepl("norma$", detalle))$calculado, 1)
})

test_that("SMI_FICHAS va de 2015 a 2026, con su norma y su cotización", {
  expect_equal(SMI_FICHAS$anio, 2015:2026)
  expect_true(all(SMI_FICHAS$pagas == 14L))
  expect_equal(SMI_FICHAS$cotizacion[SMI_FICHAS$anio <= 2022], rep(0.0635, 8))
  expect_equal(SMI_FICHAS$cotizacion[SMI_FICHAS$anio >= 2023], c(0.0645, 0.0647, 0.0648, 0.0650))
  expect_false(is.unsorted(SMI_FICHAS$mensual))
  expect_equal(SMI_FICHAS$mensual[SMI_FICHAS$anio == 2021L], (950 * 8 + 965 * 4) / 12)
  expect_true(all(ANIOS_BOE_SMI %in% SMI_FICHAS$anio[!is.na(SMI_FICHAS$boe)]))
})
