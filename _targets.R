# De renta en renta · pipeline (targets)
# F0: inventario, sobrecarga (22) y acceso (23) de la v0.0, prueba de F1 en Madrid y renta (1–3) de punta a punta.
# Ejecutar: targets::tar_make()      Ver el grafo: targets::tar_visnetwork()

library(targets)

# sf: para filtrar objetos espaciales guardados. Memoria «transient»: cada objetivo carga lo que
# necesita y lo suelta al acabar (con toda España, los objetos geográficos no caben a la vez).
tar_option_set(packages = c("dplyr", "readr", "sf"), memory = "transient", garbage_collection = TRUE)

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
  tar_target(fichero_rupturas, "inventario/rupturas.csv", format = "file"),
  tar_target(fuentes, readr::read_csv(fichero_fuentes, show_col_types = FALSE)),
  tar_target(indicadores, readr::read_csv(fichero_indicadores, show_col_types = FALSE)),
  tar_target(referencias, readr::read_csv(fichero_referencias, show_col_types = FALSE)),
  tar_target(rupturas, readr::read_csv(fichero_rupturas, col_types = readr::cols(.default = "c"))),
  tar_target(fichero_ccaa, "geo/ccaa.csv", format = "file"),
  tar_target(ccaa, readr::read_csv(fichero_ccaa, col_types = "ccc")),
  tar_target(fichero_excepciones_cobertura, "inventario/excepciones_cobertura.csv", format = "file"),
  tar_target(excepciones_cobertura, readr::read_csv(fichero_excepciones_cobertura, col_types = "ccc")),
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
  tar_target(sobrecarga_ecv, calcular_sobrecarga_ecv(ine_ecv)),
  # España por quintil de renta disponible equivalente (pregunta abierta 31): solo para la web
  tar_target(sobrecarga_quintil, calcular_sobrecarga_quintil(ine_ecv))
)

sobrecarga <- list(
  olas_ecv,
  tarchetypes::tar_combine(sobrecarga_ecv, olas_ecv$sobrecarga_ecv, command = dplyr::bind_rows(!!!.x)),
  tarchetypes::tar_combine(sobrecarga_quintil, olas_ecv$sobrecarga_quintil, command = dplyr::bind_rows(!!!.x)),
  tar_target(fichero_eurostat_quintil, descargar_eurostat_quintil(), format = "file"),
  tar_target(eurostat_quintil, leer_eurostat_quintil(fichero_eurostat_quintil)),
  tar_target(comprobaciones_quintil,
             comprobar_sobrecarga_quintil(sobrecarga_quintil, sobrecarga_ecv, eurostat_quintil)),
  tar_target(validacion_quintil, validar_referencias(comprobaciones_quintil, referencias)),
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

# F1, geografía constante (backlog, tarea 6; probada en Madrid y extendida a toda España el
# 7-nov-2026). Referencia: seccionado de 2021. El año t del ADRH está en el seccionado de 1 de enero de t + 1
# (el ADRH 2020 es nativo; el 2015, primer año, también: va con el de 2016, plan §6.3). Una tabla de paso
# por seccionado, sección de ese año → sección de 2021:
#   hasta 2020, aplicación antigua del callejero en los dos extremos (hacia delante: reparte);
#   desde 2022, aplicación nueva en los dos extremos (hacia atrás: casi siempre agrega).
# Vía (b): viviendas de los edificios del Catastro en los municipios con secciones «estimado» por
# el callejero. Regla adoptada (plan §6.3): callejero donde las secciones caen enteras y Catastro
# donde hay que repartir (combinar_vias). La tabla 2022 → 2021 hace de prueba de un año: frente
# al ADRH 2020 apenas hay crecimiento real, así que la razón mide sobre todo el error de la tabla.
#
# Ámbito: toda España. Con la variable de entorno PROVINCIA (p. ej. PROVINCIA=28 antes de
# tar_make()), una sola provincia, para pruebas rápidas; sus tablas de paso llevan el código
# de la provincia en el nombre y no se versionan.
AMBITO <- Sys.getenv("PROVINCIA", "")
PROVINCIAS <- if (AMBITO == "") sprintf("%02d", 1:52) else AMBITO
SECCIONES_AMBITO <- if (AMBITO == "") NULL else AMBITO       # filtro de leer_ine_seccionado()
SUFIJO_AMBITO <- if (AMBITO == "") "" else paste0("_", AMBITO)
ADRH_DEMOGRAFIA <- "30832"   # tablas del ADRH de toda España: indicadores demográficos…
ADRH_RENTA <- "30824"        # …y de renta

PASOS_2021 <- tibble::tibble(
  seccionado  = c(2016L, 2017L, 2018L, 2019L, 2020L, 2022L, 2023L, 2024L, 2025L),
  anio        = c(2015L, 2016L, 2017L, 2018L, 2019L, 2021L, 2022L, 2023L, 2024L),   # año del ADRH
  callejero   = sprintf("01%d", seccionado),
  formato     = c(rep("antigua_2015", 5), "nueva_2022", rep("nueva_2025", 3)),
  tramos_2021 = rlang::syms(c(rep("tramos_2021_antigua", 5), rep("tramos_2021_nueva", 4)))
)

pasos_2021 <- tarchetypes::tar_map(
  values = PASOS_2021, names = "seccionado",
  tar_target(zip_callejero, descargar_ine_callejero(callejero), format = "file"),
  tar_target(zip_seccionado, descargar_ine_seccionado(seccionado), format = "file"),
  tar_target(tramos, leer_ine_callejero(zip_callejero, FICHEROS_TRAMOS[[formato]], AMBITO)),
  tar_target(secciones, leer_ine_seccionado(zip_seccionado, seccionado, SECCIONES_AMBITO)),
  tar_target(fase, geo_fase_codigos(poblacion_adrh, anio, secciones$seccion, tramos$seccion)),
  # Fusiones y segregaciones de municipios frente a 2021: las tablas cruzan municipios solo ahí
  tar_target(grupos, geo_grupos_municipio(secciones, secciones_2021)),
  tar_target(paso_callejero, geo_tabla_paso_callejero_por_provincia(tramos, tramos_2021, topes_portal, grupos)),
  tar_target(fichero_paso, exportar_tabla_paso(
    paso_callejero, sprintf("geo/tablas_paso/callejero_%d_2021%s.csv", seccionado, SUFIJO_AMBITO)), format = "file"),
  # Edificios con la sección de 2021 ya puesta (combinar_edificios): aquí solo falta la de origen
  tar_target(paso_catastro, geo_tabla_paso_catastro(edificios_paso, secciones, NULL, anio_max = seccionado,
                                                    grupos = grupos)),
  tar_target(codigos_mapa, unique(secciones$seccion)),
  tar_target(paso_final, {
    datos <- secciones_con_datos(poblacion_adrh, anio)
    combinar_vias(paso_catastro, paso_callejero, datos = datos) |>
      completar_por_codigo(datos, secciones_2021$seccion)
  }),
  # La tabla que se usa, en git desde el 8-nov-2026 (datos abiertos, CC BY-SA 4.0)
  tar_target(fichero_paso_final, exportar_tabla_paso(
    paso_final, sprintf("geo/tablas_paso/combinada_%d_2021%s.csv", seccionado, SUFIJO_AMBITO)), format = "file"),
  # Cierre y cobertura sobre las tablas que se usan (combinadas)
  tar_target(comprobacion_paso, bind_rows(
    comprobar_cierre_poblacional(poblacion_adrh, paso_final, anio, grupos, excluir = huerfanas_adrh$codigo),
    comprobar_cobertura_destino(paso_final, secciones_2021$seccion, anio, excepciones_cobertura))),
  tar_target(diagnostico_paso, geo_diagnostico_paso(poblacion_adrh, paso_callejero, anio)),
  tar_target(comparacion_paso, comparar_vias_paso(poblacion_adrh, paso_callejero, paso_catastro, anio, municipios_cubiertos)),
  tar_target(tabla_adrh, stats::setNames(list(paso_final), anio))
)

prueba_f1 <- list(
  tar_target(zip_callejero_2021, descargar_ine_callejero("012021"), format = "file"),
  tar_target(tramos_2021_antigua, leer_ine_callejero(zip_callejero_2021, FICHEROS_TRAMOS[["antigua_2021"]], AMBITO)),
  tar_target(tramos_2021_nueva, leer_ine_callejero(zip_callejero_2021, FICHEROS_TRAMOS[["nueva_2021"]], AMBITO)),
  tar_target(topes_portal, geo_topes_portal(tramos_2021_nueva)),
  tar_target(zip_seccionado_2021, descargar_ine_seccionado(2021), format = "file"),
  tar_target(secciones_2021, leer_ine_seccionado(zip_seccionado_2021, 2021, SECCIONES_AMBITO)),
  tar_target(fichero_adrh_demografia, descargar_ine_adrh(ADRH_DEMOGRAFIA), format = "file"),
  tar_target(demografia_adrh, leer_ine_adrh(fichero_adrh_demografia, INDICADORES_ADRH_DEMOGRAFIA, AMBITO)),
  tar_target(poblacion_adrh, demografia_adrh |> filter(indicador == INDICADORES_ADRH_DEMOGRAFIA[1]) |> select(-indicador)),
  tar_target(nombres_municipios, nombres_municipios_adrh(fichero_adrh_demografia, AMBITO)),

  pasos_2021,
  tarchetypes::tar_combine(tablas_paso_callejero, pasos_2021$paso_callejero, command = list(!!!.x)),
  tarchetypes::tar_combine(tablas_paso_finales, pasos_2021$tabla_adrh, command = {
    l <- list(!!!.x)   # cada elemento: lista de una tabla con el año del ADRH como nombre
    stats::setNames(lapply(l, `[[`, 1), vapply(l, names, ""))
  }),
  tarchetypes::tar_combine(fase_codigos, pasos_2021$fase, command = dplyr::bind_rows(!!!.x)),
  tarchetypes::tar_combine(grupos_municipio, pasos_2021$grupos, command = dplyr::distinct(dplyr::bind_rows(!!!.x))),
  tarchetypes::tar_combine(codigos_seccionados, pasos_2021$codigos_mapa, command = unique(c(!!!.x))),
  tar_target(huerfanas_adrh, seccion_huerfanas(poblacion_adrh, c(codigos_seccionados, secciones_2021$seccion))),
  tarchetypes::tar_combine(comprobaciones_pasos, pasos_2021$comprobacion_paso, command = dplyr::bind_rows(!!!.x)),
  tar_target(comprobaciones_f1, bind_rows(comprobaciones_pasos, comprobar_suma_secciones(poblacion_adrh),
                                          comprobar_huerfanas(huerfanas_adrh))),
  tar_target(validacion_f1, validar_referencias(comprobaciones_f1, referencias)),
  tarchetypes::tar_combine(diagnostico_f1, pasos_2021$diagnostico_paso, command = dplyr::bind_rows(!!!.x)),
  tarchetypes::tar_combine(comparacion_vias, pasos_2021$comparacion_paso, command = dplyr::bind_rows(!!!.x)),
  tar_target(cambios_limites, bind_rows(
    geo_cambios_limites(secciones_2016, secciones_2021) |> mutate(tramo = "2016-2021"),
    geo_cambios_limites(secciones_2021, secciones_2025) |> mutate(tramo = "2021-2025")
  )),

  # Vía (b): edificios del Catastro de los municipios con secciones «estimado» en alguna tabla.
  # Se leen municipio a municipio (ramas dinámicas): un municipio nuevo no obliga a releer el resto.
  tar_target(municipios_catastro_feeds, municipios_catastro_provincias(PROVINCIAS)),
  tar_target(municipios_catastro_sel, seleccionar_municipios_catastro(
    tablas_paso_callejero, nombres_municipios, municipios_catastro_feeds, extra = grupos_municipio$municipio)),
  tar_target(municipios_forales, municipios_catastro_sel$municipio[municipios_catastro_sel$foral]),
  tar_target(municipios_cubiertos, unique(c(municipios_catastro_sel$municipio[!is.na(municipios_catastro_sel$url)],
                                            municipios_forales))),
  tar_target(urls_catastro, unique(municipios_catastro_sel$url[!is.na(municipios_catastro_sel$url)])),
  tar_target(zips_catastro, descargar_catastro_edificios(urls_catastro), pattern = map(urls_catastro),
             format = "file"),
  tar_target(edificios_municipio, leer_catastro_edificios(zips_catastro), pattern = map(zips_catastro),
             iteration = "list"),
  tar_target(edificios_catastro, combinar_edificios(edificios_municipio, secciones_2021)),
  # País Vasco y Navarra: catastros forales (8-nov-2026), para los mismos municipios. Álava y
  # Gipuzkoa dan un zip del territorio entero: de ellos solo cuentan los edificios de los municipios
  # seleccionados (por la sección de 2021 en la que caen). Fuera del ámbito (PROVINCIA sin
  # forales), el bloque no entra: targets no admite ramas sobre una lista vacía.
  if (length(intersect(PROVINCIAS, PROVINCIAS_FORALES))) list(
    tar_target(zips_forales_feeds, zips_catastro_forales(PROVINCIAS)),
    tar_target(urls_forales, seleccionar_zips_forales(zips_forales_feeds, municipios_forales)),
    tar_target(zips_forales, descargar_catastro_foral(urls_forales), pattern = map(urls_forales), format = "file"),
    tar_target(edificios_foral, leer_catastro_foral(zips_forales), pattern = map(zips_forales), iteration = "list"),
    tar_target(edificios_forales, combinar_edificios(edificios_foral, secciones_2021) |>
                 filter(substr(destino, 1, 5) %in% municipios_forales))
  ) else tar_target(edificios_forales, NULL),
  tar_target(edificios_paso, bind_rows(edificios_catastro, edificios_forales))
)

# Tarea 7: indicadores 1–3 (renta del ADRH) de punta a punta:
# descarga → lectura → compuerta → seccionado de 2021 con estado → tabla larga en Parquet.
# Todos los años del ADRH: 2020 nativo, el resto con su tabla de paso.
bloque_renta_adrh <- list(
  tar_target(fichero_adrh_renta, descargar_ine_adrh(ADRH_RENTA), format = "file"),
  tar_target(renta_adrh, leer_ine_adrh_renta(fichero_adrh_renta, AMBITO)),
  tar_target(pesos_adrh_prueba, pesos_adrh(demografia_adrh)),
  tar_target(comprobaciones_adrh, comprobar_adrh_municipio(renta_adrh, pesos_adrh_prueba)),
  tar_target(validacion_adrh, validar_referencias(comprobaciones_adrh, referencias)),
  tar_target(tablas_paso_adrh, {
    tablas <- c(tablas_paso_finales,
                list("2020" = geo_tabla_identidad(pesos_adrh_prueba$seccion[pesos_adrh_prueba$anio == 2020])))
    tablas[order(as.integer(names(tablas)))]
  }),
  tar_target(larga_adrh, {
    validacion_adrh; validacion_f1   # las compuertas (renta y tablas de paso) van antes que la armonización
    armonizar_ine_adrh(renta_adrh, pesos_adrh_prueba, tablas_paso_adrh, version = version_de(fichero_adrh_renta))
  })
)

# Indicadores 8 y 9 (SERPAVI, MIVAU): alquiler mensual y por m², mediana y cuartiles por tipología,
# de la sección a la comunidad. Toda la serie viene en el seccionado de 2021: sin tabla de paso.
# Fichero manual (descargar_mivau_serpavi() indica dónde bajarlo). Serie desde 2015; País Vasco y
# Navarra desde su entrada (ruptura serpavi_forales). Las 40 secciones, 36 distritos y 36 municipios
# del seccionado de 2021 que la base no trae van como «ausente» (compuertas serpavi_seccionado y
# serpavi_sin_fila). Como auxiliares, los contratos de cada mediana (también España) y su margen
# aproximado (compuertas contratos_mediana, contratos_suma y margen_rango, antes de la tabla larga).
ULTIMO_ANIO_SERPAVI <- 2024L
bloque_serpavi <- list(
  tar_target(fichero_serpavi, descargar_mivau_serpavi(ULTIMO_ANIO_SERPAVI), format = "file"),
  tar_target(serpavi, leer_mivau_serpavi(fichero_serpavi, desde = 2015L)),
  tar_target(comprobaciones_serpavi, comprobar_mivau_serpavi(serpavi, secciones = secciones_2021$seccion)),
  tar_target(validacion_serpavi, validar_referencias(comprobaciones_serpavi, referencias)),
  tar_target(larga_serpavi, {
    validacion_serpavi   # la compuerta va antes que la armonización
    bind_rows(
      armonizar_mivau_serpavi(serpavi, version = version_de(fichero_serpavi),
                              secciones = secciones_2021$seccion),   # lo que la base no trae, «ausente»
      # contratos y margen de la mediana (auxiliares; plan §11, preguntas 12 y 15 ampliadas)
      armonizar_fiabilidad_serpavi(serpavi, version = version_de(fichero_serpavi), secciones = secciones_2021$seccion)
    ) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(comprobaciones_fiabilidad, comprobar_fiabilidad_serpavi(larga_serpavi)),
  tar_target(validacion_fiabilidad, validar_referencias(comprobaciones_fiabilidad, referencias)),
  tar_target(resumen_larga_serpavi, resumen_serpavi(larga_serpavi)),
  tar_target(resumen_fiabilidad, resumen_fiabilidad_serpavi(larga_serpavi))
)

# Indicador 18: hogares en alquiler (%) del Censo 2021, en el seccionado de referencia (sin tabla
# de paso). España, comunidades y provincias: la cifra publicada en la tabla 59523 (compuertas
# censo2021_nacional y censo2021_alquiler). Las viviendas por comunidad y provincia (tabla 59521)
# son el denominador de la compuerta vut_territorios.
bloque_censo2021 <- list(
  tar_target(ficheros_censo2021, descargar_ine_censo2021(), format = "file"),
  tar_target(fichero_censo2021_tenencia, descargar_ine_censo2021_tabla(TABLA_CENSO2021_TENENCIA), format = "file"),
  tar_target(fichero_censo2021_viviendas, descargar_ine_censo2021_tabla(TABLA_CENSO2021_VIVIENDAS), format = "file"),
  tar_target(censo2021_viviendas, leer_ine_censo2021_viviendas(fichero_censo2021_viviendas)),
  tar_target(censo2021, leer_ine_censo2021(ficheros_censo2021, AMBITO)),
  tar_target(censo2021_tenencia, leer_ine_censo2021_tenencia(fichero_censo2021_tenencia)),
  tar_target(comprobaciones_censo2021, comprobar_ine_censo2021(censo2021, censo2021_tenencia, secciones_2021$seccion)),
  tar_target(validacion_censo2021, validar_referencias(comprobaciones_censo2021, referencias)),
  tar_target(larga_censo2021, {
    validacion_censo2021   # la compuerta va antes que la armonización
    bind_rows(armonizar_ine_censo2021(censo2021, version = version_de(ficheros_censo2021)),
              territorios_ine_censo2021(censo2021_tenencia, version = version_de(fichero_censo2021_tenencia))) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  })
)

# Indicador 19: viviendas turísticas sobre el total de viviendas (INE, estadística experimental).
# Se leen los 13 periodos de la tabla 5; entran los del seccionado de 2024 (PERIODOS_VUT_2024,
# desde febrero de 2024), llevados al de 2021 con la tabla de paso combinada 2024 -> 2021 y las
# viviendas del Censo 2021 como denominador (ruptura vut_seccionado_2024). En `corte` «mes» y en
# `grupo`, el mes de referencia. España, comunidades y provincias: el porcentaje publicado en la
# tabla 39365, en los mismos periodos (compuertas vut_nacional_viviendas, vut_nacional_porcentaje
# y vut_territorios, esta con el denominador del INE en cada periodo: ruptura vut_denominador_2024).
periodos_vut <- tarchetypes::tar_map(
  values = list(periodo = PERIODOS_VUT), names = "periodo",
  tar_target(fichero_vut, descargar_ine_vut(periodo), format = "file"),
  tar_target(vut_periodo, leer_ine_vut(fichero_vut, periodo, AMBITO))
)
bloque_vut <- list(
  periodos_vut,
  tarchetypes::tar_combine(ficheros_vut, periodos_vut$fichero_vut, command = c(!!!.x), format = "file"),
  tarchetypes::tar_combine(vut, periodos_vut$vut_periodo, command = dplyr::bind_rows(!!!.x)),
  tar_target(ficheros_vut_provincias, vapply(TABLAS_VUT_PROVINCIAS, descargar_ine_vut_provincias, ""),
             format = "file"),
  tar_target(vut_provincias, leer_ine_vut_provincias(ficheros_vut_provincias[1], ficheros_vut_provincias[2])),
  tar_target(vut_2021, reproyectar_ine_vut(vut, paso_final_2024, censo2021)),
  tar_target(comprobaciones_vut, comprobar_ine_vut(vut, vut_2021, vut_provincias, censo2021,
                                                   unique(secciones_2024$seccion), paso_final_2024,
                                                   censo2021_viviendas)),
  tar_target(validacion_vut, validar_referencias(comprobaciones_vut, referencias)),
  tar_target(larga_vut, {
    validacion_vut   # la compuerta va antes que la armonización
    bind_rows(armonizar_ine_vut(vut_2021, version = version_de(utils::tail(ficheros_vut, 1))),
              territorios_ine_vut(vut_provincias, version = version_de(ficheros_vut_provincias))) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  })
)

# Indicador 23: módulo de la ECV 2025 sobre dificultades de acceso a la vivienda (tablas)
modulo_acceso <- list(
  tar_target(fichero_modulo_ccaa, descargar_ine_ecv_modulo("79637"), format = "file"),
  tar_target(fichero_modulo_edad, descargar_ine_ecv_modulo("79629"), format = "file"),
  tar_target(fichero_modulo_tenencia, descargar_ine_ecv_modulo("79635"), format = "file"),
  tar_target(modulo_ccaa, leer_ine_ecv_modulo(fichero_modulo_ccaa)),
  tar_target(modulo_edad, leer_ine_ecv_modulo(fichero_modulo_edad)),
  tar_target(modulo_tenencia, leer_ine_ecv_modulo(fichero_modulo_tenencia)),
  tar_target(comprobaciones_modulo, comprobar_ine_ecv_modulo(modulo_ccaa, modulo_edad, modulo_tenencia)),
  tar_target(validacion_modulo, validar_referencias(comprobaciones_modulo, referencias))
)

# Ficha «mochila»: opciones A, B y C con la AEAT; adoptada la B (7-nov-2026, plan §3.1), con el
# control de la ECV del año siguiente (ingresos del mismo año que la AEAT).
# Cada tabla de la AEAT es un conjunto de páginas HTML (una por combinación de filtros); sus
# títulos y filtros están en TABLAS_AEAT_MOCHILA (R/ficha_mochila.R).
ANIO_AEAT <- 2024L
bloque_mochila <- list(
  tarchetypes::tar_map(
    values = list(tabla = c("provincia", "deciles", "sme_edad", "recorrido", "centiles", "retenciones")), names = "tabla",
    tar_target(paginas_aeat, descargar_aeat_mochila(tabla, ANIO_AEAT), format = "file"),
    tar_target(aeat, leer_aeat_mercado(paginas_aeat))
  ),
  list(
    tar_target(comprobaciones_mochila, comprobar_interpolacion_deciles(aeat_deciles, aeat_centiles, aeat_recorrido)),
    tar_target(validacion_mochila, validar_referencias(comprobaciones_mochila, referencias)),
    tar_target(mochila_opciones, {
      validacion_mochila
      calcular_mochila_opciones(aeat_provincia, aeat_deciles, aeat_sme_edad, aeat_recorrido)
    }),
    tar_target(fichero_mochila_opciones, {
      ruta <- sprintf("datos/intermedios/mochila/opciones_%d.csv", ANIO_AEAT)
      dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(mutate(mochila_opciones, across(where(is.double), ~ round(.x, 3))), ruta)
      ruta
    }, format = "file"),
    # Control con la ECV: ficheros de hogares (d) y personas (p) de la ola con ingresos de ANIO_AEAT
    tar_target(csv_ecv_mochila, obtener_csv_ine_ecv(ANIO_AEAT + 1L, c("d", "p")), format = "file"),
    tar_target(ecv_mochila, resumir_ecv_asalariados(leer_ecv_asalariados(csv_ecv_mochila, ANIO_AEAT))),
    tar_target(validacion_mochila_ecv, validar_referencias(comprobar_mochila_ecv(mochila_opciones, ecv_mochila, ccaa),
                                                           referencias)),
    tar_target(mochila, {
      validacion_mochila_ecv
      calcular_mochila(mochila_opciones)
    }),
    tar_target(fichero_mochila, {
      ruta <- sprintf("datos/intermedios/mochila/mochila_%d.csv", ANIO_AEAT)
      dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(mutate(mochila, across(where(is.double), ~ round(.x, 3))), ruta)
      ruta
    }, format = "file"),
    # Paso 3: de bruto anual a neto mensual en 12 (regla 8), con la cotización del trabajador y la
    # retención de la AEAT por tramo de renta anual de su comunidad; control con el neto de la ECV
    tar_target(cotizacion_mochila, COTIZACION_TRABAJADOR[[as.character(ANIO_AEAT)]]),
    tar_target(retenciones_mochila, retenciones_aeat(aeat_retenciones)),
    tar_target(validacion_mochila_neto_ecv,
               validar_referencias(comprobar_neto_ecv(retenciones_mochila, ecv_mochila, ccaa, cotizacion_mochila),
                                   referencias)),
    tar_target(mochila_neta, {
      validacion_mochila_neto_ecv
      calcular_mochila_neta(mochila, retenciones_mochila, cotizacion_mochila)
    }),
    tar_target(fichero_mochila_neta, {
      ruta <- sprintf("datos/intermedios/mochila/mochila_neta_%d.csv", ANIO_AEAT)
      dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
      readr::write_csv(mutate(mochila_neta, across(where(is.double), ~ round(.x, 3))), ruta)
      ruta
    }, format = "file")
  )
)

# F1: jerarquía territorial (sección → distrito → municipio → provincia → comunidad) y mapa base
# del seccionado de referencia (2021) en PMTiles, con GDAL (R/geo_mapa_base.R). La jerarquía va a
# geo/ (CSV, en git); el PMTiles, a geo/referencia/ (fuera de git). Solo el mapa base:
#   targets::tar_make(names = c(ficheros_jerarquia, fichero_mapa_base, validacion_mapa_base))
mapa_base <- list(
  tar_target(provincias_2021, leer_ine_seccionado_provincias(zip_seccionado_2021)),
  tar_target(jerarquia_2021, geo_jerarquia(secciones_2021, provincias_2021)),
  tar_target(territorios_2021, geo_territorios(jerarquia_2021, nombres_municipios, provincias_2021, ccaa)),
  tar_target(validacion_jerarquia, validar_referencias(
    comprobar_jerarquia(jerarquia_2021, territorios_2021, secciones_2021$seccion), referencias)),
  tar_target(ficheros_jerarquia, {
    validacion_jerarquia
    exportar_jerarquia(jerarquia_2021, territorios_2021, sufijo = SUFIJO_AMBITO)
  }, format = "file"),
  # Disolución de las capas y suelo sin sección (≈ 4,5 min) y teselas en un solo paso (≈ 7 min en
  # total, 8-nov-2026): las capas no se guardan
  tar_target(fichero_mapa_base, {
    validacion_jerarquia
    generar_pmtiles(geo_capas_mapa_base(secciones_2021, jerarquia_2021, territorios_2021),
                    sprintf("geo/referencia/mapa_base_2021%s.pmtiles", SUFIJO_AMBITO))
  }, format = "file"),
  tar_target(resumen_mapa_base, pmtiles_resumen(fichero_mapa_base)),
  tar_target(validacion_mapa_base, validar_referencias(comprobar_mapa_base(fichero_mapa_base, secciones_2021),
                                                       referencias))
)

# Indicadores derivados (R/derivados.R): 14 (esfuerzo de residentes), 21 (sueldo neto necesario,
# mapa por defecto: 50 m² y umbral del 30 %) y 15 (barrera de acceso: se calcula en la web; aquí,
# la mochila y la tartera de 2024 como control). Alquiler de vivienda colectiva; estado, el peor de
# sus términos (plan, preguntas abiertas 12 y 15); numerador y denominador del mismo año (regla 4).
# `perfiles`: ingreso neto mensual de cada ficha (tartera, mochila y llave), para la web.
bloque_derivados <- list(
  tar_target(fichero_provincias_aeat, "inventario/provincias_aeat.csv", format = "file"),
  tar_target(provincias_aeat, readr::read_csv(fichero_provincias_aeat, col_types = "ccc")),
  tar_target(perfiles, perfiles_fichas(mochila_neta, provincias_aeat, larga_adrh, anio_mochila = ANIO_AEAT)),
  tar_target(resumen_perfiles_llave, resumen_llave(perfiles)),
  tar_target(derivados, armonizar_derivados(larga_serpavi, larga_adrh, perfiles)),
  tar_target(comprobaciones_derivados,
             comprobar_derivados(derivados, larga_serpavi, larga_adrh, perfiles, provincias_aeat, mochila_neta)),
  tar_target(validacion_derivados, validar_referencias(comprobaciones_derivados, referencias)),
  tar_target(larga_derivados, {
    validacion_derivados   # la compuerta va antes que la tabla larga
    validar_tabla_larga(derivados, indicadores, fuentes, vocabulario)
  }),
  tar_target(resumen_larga_derivados, resumen_derivados(larga_derivados))
)

# Tabla larga única: cada bloque entra después de pasar su compuerta
bloque_tabla_larga <- list(
  tar_target(tabla_larga, {
    validacion_sobrecarga; validacion_modulo; validacion_fiabilidad
    bind_rows(
      larga_adrh,
      larga_serpavi,      # 8 y 9, contratos y margen: la tipología como corte; sin filas «total»
      larga_censo2021,    # 18
      larga_vut,          # 19: el mes de referencia en corte y grupo
      larga_derivados,    # 14 y 21 sin desglose; 15 con la ficha (tartera y mochila, 2024) como corte
      armonizar_sobrecarga_ecv(sobrecarga_ecv, sobrecarga_agrupada, ccaa, version = version_de(csv_ine_ecv_2025)),
      armonizar_ine_ecv_modulo(modulo_ccaa, ccaa, version = version_de(fichero_modulo_ccaa)),
      armonizar_ine_ecv_modulo_cortes(modulo_edad, modulo_tenencia, version = version_de(fichero_modulo_edad))
    ) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(fichero_tabla_larga, exportar_tabla_larga(tabla_larga, "datos/intermedios/tabla_larga.parquet"),
             format = "file")
)

# Datos de la web (plan §6.6; preguntas abiertas 12, 14 y 17): web/datos/ y el mapa base en
# web/teselas/ (fuera de git), desde la tabla larga ya validada y la jerarquía (R/web_exportar.R).
# Con PROVINCIA, a datos/intermedios/web_<provincia>/, para no pisar la exportación de toda España.
#   targets::tar_make(names = c(ficheros_web, validacion_web))
DIR_WEB <- if (AMBITO == "") "web" else file.path("datos", "intermedios", paste0("web", SUFIJO_AMBITO))
bloque_web <- list(
  tar_target(cajas_municipios, cajas_web(secciones_2021, jerarquia_2021)),   # buscador de municipios
  tar_target(ficheros_web, {
    validacion_jerarquia; validacion_mapa_base; validacion_derivados    # lo que va, con sus compuertas pasadas
    exportar_web(tabla_larga, indicadores, jerarquia_2021, territorios_2021, pmtiles = fichero_mapa_base,
                 perfiles = perfiles, cajas = cajas_municipios, dir_web = DIR_WEB)
  }, format = "file"),
  tar_target(validacion_web, {
    ficheros_web
    validar_referencias(comprobar_web(tabla_larga, indicadores, jerarquia_2021, territorios_2021, DIR_WEB,
                                      perfiles = perfiles), referencias)
  }),
  # Sección «Sobrecarga» (v0.0; R/web_sobrecarga.R): web/datos/sobrecarga/, desde los objetivos de la
  # sobrecarga, del quintil y del módulo de acceso, las geometrías NUTS de GISCO y los cortes del
  # indicador 22 (inventario/indicadores.csv). No depende de la tabla larga. La serie de España se
  # corta también en las rupturas del atlas (inventario/rupturas.csv; pregunta abierta 34).
  #   targets::tar_make(names = c(ficheros_web_sobrecarga, validacion_web_sobrecarga))
  tar_target(rupturas_sobrecarga, rupturas_serie_sobrecarga(rupturas)),
  tar_target(ficheros_web_sobrecarga, {
    validacion_sobrecarga; validacion_modulo; validacion_nuts; validacion_quintil    # las compuertas van antes
    exportar_web_sobrecarga(sobrecarga_ecv, sobrecarga_agrupada, eurostat_europa, ccaa,
                            list(ccaa = modulo_ccaa, edad = modulo_edad, tenencia = modulo_tenencia),
                            c("2021" = fichero_nuts_2021, "2024" = fichero_nuts_2024), indicadores,
                            quintil = sobrecarga_quintil, rupturas = rupturas_sobrecarga, dir_web = DIR_WEB)
  }, format = "file"),
  tar_target(validacion_web_sobrecarga, {
    ficheros_web_sobrecarga
    validar_referencias(comprobar_web_sobrecarga(sobrecarga_ecv, sobrecarga_agrupada, eurostat_europa, escalera, ccaa,
                                                 list(ccaa = modulo_ccaa, edad = modulo_edad, tenencia = modulo_tenencia),
                                                 indicadores, quintil = sobrecarga_quintil,
                                                 rupturas = rupturas_sobrecarga, dir_web = DIR_WEB),
                        referencias)
  })
)

list(inventario, sobrecarga, prueba_f1, mapa_base, bloque_renta_adrh, bloque_serpavi, bloque_censo2021, bloque_vut, modulo_acceso, bloque_mochila, bloque_derivados, bloque_tabla_larga, bloque_web)
