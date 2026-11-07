# Casilla de salida · pipeline (targets)
# F0: inventario, sobrecarga (22) y acceso (23) de la v0.0, prueba de F1 en Madrid y renta (1–3) de punta a punta.
# Ejecutar: targets::tar_make()      Ver el grafo: targets::tar_visnetwork()

library(targets)

tar_option_set(packages = c("dplyr", "readr", "sf"))   # sf: para filtrar objetos espaciales guardados

# Capa de precios de oferta de los portales (plan, §2.2). Apagada por defecto.
PORTALES <- identical(toupper(Sys.getenv("PORTALES", "FALSE")), "TRUE")

# Olas de la ECV (año de la encuesta; las rentas son del año anterior). Cada ola da sus cifras
# anuales; las tres juntas, los cruces que una sola ola no sostiene (comunidad × tenencia).
ANIOS_ECV <- c(2023L, 2024L, 2025L)

# Funciones del proyecto (R/*.R)
tar_source("R")

inventario <- list(
  tar_target(fichero_fuentes, "inventario/fuentes.csv", format = "file"),
  tar_target(fichero_indicadores, "inventario/indicadores.csv", format = "file"),
  tar_target(fichero_referencias, "inventario/referencias_validacion.csv", format = "file"),
  tar_target(fuentes, readr::read_csv(fichero_fuentes, show_col_types = FALSE)),
  tar_target(indicadores, readr::read_csv(fichero_indicadores, show_col_types = FALSE)),
  tar_target(referencias, readr::read_csv(fichero_referencias, show_col_types = FALSE)),
  tar_target(fichero_ccaa, "geo/ccaa.csv", format = "file"),
  tar_target(ccaa, readr::read_csv(fichero_ccaa, col_types = "ccc")),
  tar_target(fichero_vocabulario, "inventario/vocabulario.csv", format = "file"),
  tar_target(vocabulario, readr::read_csv(fichero_vocabulario, show_col_types = FALSE)),
  # Diccionarios ES/EN de la web: las secciones de indicadores, fuentes y vocabulario salen del inventario
  tar_target(ficheros_i18n, exportar_i18n(indicadores, fuentes, vocabulario), format = "file"),
  tar_target(validacion_i18n, validar_referencias(comprobar_i18n(ficheros_i18n), referencias)),
  # Kit de diseño (tarea 9): tokens.css, tipografías autoalojadas y contrastes
  tar_target(fichero_tokens, "diseno/tokens.json", format = "file"),
  tar_target(tokens, jsonlite::read_json(fichero_tokens)),
  tar_target(ficheros_tipografias, descargar_tipografias(), format = "file"),
  tar_target(fichero_tokens_css, {
    ficheros_tipografias
    generar_tokens_css(tokens)
  }, format = "file"),
  tar_target(validacion_diseno, validar_referencias(comprobar_contrastes(tokens, fichero_tokens_css), referencias))
)

version_de <- function(ruta) format(file.mtime(ruta[1]), "%Y-%m-%d")

# Indicador 22: sobrecarga por gastos de vivienda (F1b, v0.0)
olas_ecv <- tarchetypes::tar_map(
  values = list(anio = ANIOS_ECV), names = "anio",
  tar_target(csv_ine_ecv, obtener_csv_ine_ecv(anio), format = "file"),
  tar_target(ine_ecv, leer_ine_ecv(csv_ine_ecv)),
  tar_target(sobrecarga_ecv, calcular_sobrecarga_ecv(ine_ecv))
)

sobrecarga <- list(
  olas_ecv,
  tarchetypes::tar_combine(sobrecarga_ecv, olas_ecv$sobrecarga_ecv, command = dplyr::bind_rows(!!!.x)),
  tarchetypes::tar_combine(olas_ine_ecv, olas_ecv$ine_ecv, command = list(!!!.x)),
  tar_target(sobrecarga_agrupada, calcular_sobrecarga_agrupada(olas_ine_ecv)),
  tar_target(fichero_eurostat_sobrecarga, descargar_eurostat_ilc_lvho07(), format = "file"),
  tar_target(eurostat_sobrecarga, leer_eurostat_ilc_lvho07(fichero_eurostat_sobrecarga)),
  tar_target(fichero_eurostat_europa, descargar_eurostat_europa(), format = "file"),
  tar_target(eurostat_europa, leer_eurostat_europa(fichero_eurostat_europa)),
  tar_target(comprobaciones_sobrecarga,
             comprobar_sobrecarga_ecv(sobrecarga_ecv, eurostat_sobrecarga, eurostat_europa)),
  tar_target(validacion_sobrecarga, validar_referencias(comprobaciones_sobrecarga, referencias)),
  tar_target(fichero_nuts_2021, descargar_gisco_nuts("2021"), format = "file"),
  tar_target(fichero_nuts_2024, descargar_gisco_nuts("2024"), format = "file"),
  tar_target(comprobaciones_nuts, comprobar_geometrias_nuts(
    eurostat_europa, c("2021" = fichero_nuts_2021, "2024" = fichero_nuts_2024))),
  tar_target(validacion_nuts, validar_referencias(comprobaciones_nuts, referencias)),
  tar_target(escalera, armar_escalera(eurostat_europa)),
  tar_target(ficheros_sobrecarga, {
    validacion_sobrecarga   # la compuerta va antes
    exportar_sobrecarga(sobrecarga_ecv, sobrecarga_agrupada, escalera)
  }, format = "file")
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
  # Cierre sobre las tablas que se usan (combinadas con el Catastro en 2015 y 2025 → 2021)
  tar_target(comprobaciones_f1, bind_rows(
    comprobar_cierre_poblacional(poblacion_adrh, paso_final_2015_2021, 2015L),
    comprobar_cierre_poblacional(poblacion_adrh, paso_2022_2021, 2021L),
    comprobar_cierre_poblacional(poblacion_adrh, paso_final_2025_2021, 2024L)
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

# Vía (b) de las tablas de paso: viviendas de los edificios del Catastro, en los municipios de la
# provincia de prueba con secciones «estimado» por el callejero. Regla adoptada (plan §6.3):
# callejero donde las secciones caen enteras y Catastro donde hay que repartir (combinar_vias).
# Para 2022 → 2021 falta el seccionado de 2022: esa tabla sigue solo con el callejero.
via_catastro <- list(
  tar_target(municipios_catastro_prueba, seleccionar_municipios_catastro(
    list(paso_2015_2021, paso_2022_2021, paso_2025_2021), fichero_adrh_demografia, PROVINCIA_PRUEBA)),
  tar_target(zips_catastro, vapply(stats::na.omit(municipios_catastro_prueba$url), descargar_catastro_edificios, ""),
             format = "file"),
  tar_target(edificios_catastro, leer_catastro_varios(zips_catastro)),
  tar_target(secciones_2015_prueba, leer_ine_seccionado(zip_seccionado_2015, 2015, PROVINCIA_PRUEBA)),
  tar_target(secciones_2021_prueba, leer_ine_seccionado(zip_seccionado_2021, 2021, PROVINCIA_PRUEBA)),
  tar_target(secciones_2025_prueba, leer_ine_seccionado(zip_seccionado_2025, 2025, PROVINCIA_PRUEBA)),
  tar_target(paso_catastro_2015_2021,
             geo_tabla_paso_catastro(edificios_catastro, secciones_2015_prueba, secciones_2021_prueba, anio_max = 2015L)),
  tar_target(paso_catastro_2025_2021,
             geo_tabla_paso_catastro(edificios_catastro, secciones_2025_prueba, secciones_2021_prueba, anio_max = 2025L)),
  tar_target(paso_final_2015_2021, combinar_vias(paso_catastro_2015_2021, paso_2015_2021)),
  tar_target(paso_final_2025_2021, combinar_vias(paso_catastro_2025_2021, paso_2025_2021)),
  tar_target(comparacion_vias, {
    cubiertos <- municipios_catastro_prueba$municipio[!is.na(municipios_catastro_prueba$url)]
    bind_rows(
      comparar_vias_paso(poblacion_adrh, paso_2015_2021, paso_catastro_2015_2021, 2015L, cubiertos),
      comparar_vias_paso(poblacion_adrh, paso_2025_2021, paso_catastro_2025_2021, 2024L, cubiertos)
    )
  })
)

# Tarea 7: indicadores 1–3 (renta del ADRH) de punta a punta en la provincia de prueba:
# descarga → lectura → compuerta → seccionado de 2021 con estado → tabla larga en Parquet.
# Años con tabla de paso: 2020 (nativo), 2015, 2021 y 2024. Para 2016–2019 y 2022–2023 hacen
# falta los callejeros de enero de 2017–2020, 2023 y 2024.
ADRH_RENTA <- c("28" = "31097")

bloque_renta_adrh <- list(
  tar_target(fichero_adrh_renta, descargar_ine_adrh(ADRH_RENTA[[PROVINCIA_PRUEBA]]), format = "file"),
  tar_target(renta_adrh, leer_ine_adrh_renta(fichero_adrh_renta)),
  tar_target(pesos_adrh_prueba, pesos_adrh(fichero_adrh_demografia)),
  tar_target(comprobaciones_adrh, comprobar_adrh_municipio(renta_adrh, pesos_adrh_prueba)),
  tar_target(validacion_adrh, validar_referencias(comprobaciones_adrh, referencias)),
  tar_target(tablas_paso_adrh, list(
    "2015" = paso_final_2015_2021,
    "2020" = geo_tabla_identidad(pesos_adrh_prueba$seccion[pesos_adrh_prueba$anio == 2020]),
    "2021" = paso_2022_2021,
    "2024" = paso_final_2025_2021
  )),
  tar_target(larga_adrh, {
    validacion_adrh   # la compuerta va antes que la armonización
    armonizar_ine_adrh(renta_adrh, pesos_adrh_prueba, tablas_paso_adrh, version = version_de(fichero_adrh_renta))
  })
)

# Indicador 23: módulo de la ECV 2025 sobre dificultades de acceso a la vivienda (tablas)
modulo_acceso <- list(
  tar_target(fichero_modulo_ccaa, descargar_ine_ecv_modulo("79637"), format = "file"),
  tar_target(fichero_modulo_edad, descargar_ine_ecv_modulo("79629"), format = "file"),
  tar_target(fichero_modulo_tenencia, descargar_ine_ecv_modulo("79635"), format = "file"),
  tar_target(modulo_ccaa, leer_ine_ecv_modulo(fichero_modulo_ccaa)),
  tar_target(comprobaciones_modulo, comprobar_ine_ecv_modulo(modulo_ccaa)),
  tar_target(validacion_modulo, validar_referencias(comprobaciones_modulo, referencias))
)

# Tabla larga única: cada bloque entra después de pasar su compuerta
bloque_tabla_larga <- list(
  tar_target(tabla_larga, {
    validacion_sobrecarga; validacion_modulo
    bind_rows(
      larga_adrh,
      armonizar_sobrecarga_ecv(sobrecarga_ecv, ccaa, version = version_de(csv_ine_ecv_2025)),
      armonizar_ine_ecv_modulo(modulo_ccaa, ccaa, version = version_de(fichero_modulo_ccaa))
    ) |>
      validar_tabla_larga(indicadores, fuentes)
  }),
  tar_target(fichero_tabla_larga, exportar_tabla_larga(tabla_larga, "datos/intermedios/tabla_larga.parquet"),
             format = "file")
)

list(inventario, sobrecarga, prueba_f1, via_catastro, bloque_renta_adrh, modulo_acceso, bloque_tabla_larga)
