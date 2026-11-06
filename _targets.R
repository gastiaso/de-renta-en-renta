# Casilla de salida · pipeline (targets)
# F0: inventario y primer indicador (22, sobrecarga) con su compuerta.
# Ejecutar: targets::tar_make()      Ver el grafo: targets::tar_visnetwork()

library(targets)

tar_option_set(packages = c("dplyr", "readr"))

# Capa de precios de oferta de los portales (plan, §2.2). Apagada por defecto.
PORTALES <- identical(toupper(Sys.getenv("PORTALES", "FALSE")), "TRUE")

# Ola de la ECV (año de la encuesta; las rentas son del año anterior)
ANIO_ECV <- 2025L

# Funciones del proyecto (R/*.R)
tar_source("R")

inventario <- list(
  tar_target(fichero_fuentes, "inventario/fuentes.csv", format = "file"),
  tar_target(fichero_indicadores, "inventario/indicadores.csv", format = "file"),
  tar_target(fichero_referencias, "inventario/referencias_validacion.csv", format = "file"),
  tar_target(fuentes, readr::read_csv(fichero_fuentes, show_col_types = FALSE)),
  tar_target(indicadores, readr::read_csv(fichero_indicadores, show_col_types = FALSE)),
  tar_target(referencias, readr::read_csv(fichero_referencias, show_col_types = FALSE))
)

# Indicador 22: sobrecarga por gastos de vivienda (F1b)
sobrecarga <- list(
  tar_target(csv_ine_ecv, obtener_csv_ine_ecv(ANIO_ECV), format = "file"),
  tar_target(ine_ecv, leer_ine_ecv(csv_ine_ecv)),
  tar_target(sobrecarga_ecv, calcular_sobrecarga_ecv(ine_ecv)),
  tar_target(fichero_eurostat_sobrecarga, descargar_eurostat_ilc_lvho07(), format = "file"),
  tar_target(eurostat_sobrecarga, leer_eurostat_ilc_lvho07(fichero_eurostat_sobrecarga)),
  tar_target(comprobaciones_sobrecarga, comprobar_sobrecarga_ecv(sobrecarga_ecv, eurostat_sobrecarga)),
  tar_target(validacion_sobrecarga, validar_referencias(comprobaciones_sobrecarga, referencias))
)

# F1, prueba de la geografía constante en una provincia (backlog, tarea 6).
# Referencia: seccionado de 2021. El año t del ADRH está en el seccionado de t + 1.
#   2015 → 2021: aplicación antigua del callejero en los dos extremos (hacia delante: reparte)
#   2025 → 2021: aplicación nueva en los dos extremos (hacia atrás: agrega)
#   2022 → 2021: ídem, con un año de distancia; el diagnóstico frente al ADRH 2020 apenas
#                lleva crecimiento real y mide sobre todo el error de la tabla
PROVINCIA_PRUEBA <- "28"
ADRH_DEMOGRAFIA <- c("28" = "31105")   # tabla de indicadores demográficos de cada provincia

prueba_f1 <- list(
  tar_target(zip_callejero_2015, descargar_ine_callejero("012015"), format = "file"),
  tar_target(zip_callejero_2021, descargar_ine_callejero("012021"), format = "file"),
  tar_target(zip_callejero_2022, descargar_ine_callejero("012022"), format = "file"),
  tar_target(zip_callejero_2025, descargar_ine_callejero("012025"), format = "file"),
  tar_target(tramos_2015, leer_ine_callejero(zip_callejero_2015, FICHEROS_TRAMOS[["antigua_2015"]], PROVINCIA_PRUEBA)),
  tar_target(tramos_2021_antigua, leer_ine_callejero(zip_callejero_2021, FICHEROS_TRAMOS[["antigua_2021"]], PROVINCIA_PRUEBA)),
  tar_target(tramos_2021_nueva, leer_ine_callejero(zip_callejero_2021, FICHEROS_TRAMOS[["nueva_2021"]], PROVINCIA_PRUEBA)),
  tar_target(tramos_2022, leer_ine_callejero(zip_callejero_2022, FICHEROS_TRAMOS[["nueva_2022"]], PROVINCIA_PRUEBA)),
  tar_target(tramos_2025, leer_ine_callejero(zip_callejero_2025, FICHEROS_TRAMOS[["nueva_2025"]], PROVINCIA_PRUEBA)),
  tar_target(topes_portal, geo_topes_portal(tramos_2021_nueva)),
  tar_target(paso_2015_2021, geo_tabla_paso_callejero(tramos_2015, tramos_2021_antigua, topes_portal)),
  tar_target(paso_2022_2021, geo_tabla_paso_callejero(tramos_2022, tramos_2021_nueva, topes_portal)),
  tar_target(paso_2025_2021, geo_tabla_paso_callejero(tramos_2025, tramos_2021_nueva, topes_portal)),
  tar_target(fichero_paso_2022_2021,
             exportar_tabla_paso(paso_2022_2021, sprintf("geo/tablas_paso/callejero_2022_2021_%s.csv", PROVINCIA_PRUEBA)),
             format = "file"),
  tar_target(fichero_paso_2015_2021,
             exportar_tabla_paso(paso_2015_2021, sprintf("geo/tablas_paso/callejero_2015_2021_%s.csv", PROVINCIA_PRUEBA)),
             format = "file"),
  tar_target(fichero_paso_2025_2021,
             exportar_tabla_paso(paso_2025_2021, sprintf("geo/tablas_paso/callejero_2025_2021_%s.csv", PROVINCIA_PRUEBA)),
             format = "file"),

  tar_target(fichero_adrh_demografia, descargar_ine_adrh(ADRH_DEMOGRAFIA[[PROVINCIA_PRUEBA]]), format = "file"),
  tar_target(poblacion_adrh, leer_ine_adrh_demografia(fichero_adrh_demografia)),
  tar_target(comprobaciones_f1, bind_rows(
    comprobar_cierre_poblacional(poblacion_adrh, paso_2015_2021, 2015L),
    comprobar_cierre_poblacional(poblacion_adrh, paso_2022_2021, 2021L),
    comprobar_cierre_poblacional(poblacion_adrh, paso_2025_2021, 2024L)
  )),
  tar_target(validacion_f1, validar_referencias(comprobaciones_f1, referencias)),
  tar_target(diagnostico_f1, bind_rows(
    geo_diagnostico_paso(poblacion_adrh, paso_2015_2021, 2015L),
    geo_diagnostico_paso(poblacion_adrh, paso_2022_2021, 2021L),
    geo_diagnostico_paso(poblacion_adrh, paso_2025_2021, 2024L)
  )),

  tar_target(zip_seccionado_2015, descargar_ine_seccionado(2015), format = "file"),
  tar_target(zip_seccionado_2021, descargar_ine_seccionado(2021), format = "file"),
  tar_target(zip_seccionado_2025, descargar_ine_seccionado(2025), format = "file"),
  tar_target(cambios_limites, bind_rows(
    geo_cambios_limites(leer_ine_seccionado(zip_seccionado_2015, 2015, PROVINCIA_PRUEBA),
                        leer_ine_seccionado(zip_seccionado_2021, 2021, PROVINCIA_PRUEBA)) |> mutate(tramo = "2015-2021"),
    geo_cambios_limites(leer_ine_seccionado(zip_seccionado_2021, 2021, PROVINCIA_PRUEBA),
                        leer_ine_seccionado(zip_seccionado_2025, 2025, PROVINCIA_PRUEBA)) |> mutate(tramo = "2021-2025")
  ))
)

list(inventario, sobrecarga, prueba_f1)
