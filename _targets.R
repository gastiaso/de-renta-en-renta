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
  # Tarea 51: tres juegos de cortes del mapa por indicador (sección, municipio, provincia y comunidad)
  tar_target(fichero_cortes_niveles, "inventario/cortes_web_niveles.csv", format = "file"),
  tar_target(cortes_niveles, leer_cortes_niveles(fichero_cortes_niveles)),
  # Diccionarios ES/EN de la web: las secciones de indicadores, fuentes y vocabulario salen del inventario
  tar_target(ficheros_i18n, exportar_i18n(indicadores, fuentes, vocabulario), format = "file"),
  tar_target(validacion_i18n, validar_referencias(comprobar_i18n(ficheros_i18n), referencias)),
  # Página «Datos»: valores de las columnas y diccionario de indicadores, en docs/ (ES y EN)
  tar_target(ficheros_diccionario_datos, exportar_diccionario_datos(indicadores, vocabulario, fuentes), format = "file"),
  # Kit de diseño (tarea 9): tokens.css, tipografías autoalojadas y contrastes
  tar_target(fichero_tokens, "diseno/tokens.json", format = "file"),
  tar_target(tokens, jsonlite::read_json(fichero_tokens)),
  tar_target(ficheros_tipografias, descargar_tipografias(), format = "file"),
  tar_target(fichero_tokens_css, {
    ficheros_tipografias
    generar_tokens_css(tokens)
  }, format = "file"),
  tar_target(validacion_diseno, validar_referencias(comprobar_contrastes(tokens, fichero_tokens_css), referencias)),
  # Portada (tarea 24; R/web_portada.R): las casillas de web/index.html, desde su CSV (regla 7)
  tar_target(fichero_casillas_portada, "inventario/casillas_portada.csv", format = "file"),
  tar_target(casillas_portada, leer_casillas_portada(fichero_casillas_portada)),
  tar_target(fichero_portada_html, escribir_casillas_portada(casillas_portada), format = "file")
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

# F3: indicadores 4–6 del ADRH (R/fuente_ine_adrh_distribucion.R): peso de los salarios en la renta,
# población por debajo del 60 % de la mediana e índice de Gini. Tres tablas de secciones de toda
# España (2,1 GB; se leen por trozos en unos 30 s) y tres de totales (España, comunidades y
# provincias). El 4 y el 5 se reproyectan como medias ponderadas (renta bruta; población) y el 6,
# con la regla de medianas; los huecos forales, «ausente» (decisiones del autor, 9-nov-2026).
ADRH_FUENTES <- "30825"      # distribución por fuente de ingresos
ADRH_UMBRALES <- "30829"     # umbrales relativos por sexo
ADRH_GINI_P80 <- "37677"     # índice de Gini y P80/P20
ADRH_TOTALES <- c(fuentes = "53687", umbrales = "53694", gini = "53688")
bloque_adrh_distribucion <- list(
  tar_target(fichero_adrh_fuentes, descargar_ine_adrh(ADRH_FUENTES), format = "file"),
  tar_target(fichero_adrh_umbrales, descargar_ine_adrh(ADRH_UMBRALES), format = "file"),
  tar_target(fichero_adrh_gini, descargar_ine_adrh(ADRH_GINI_P80), format = "file"),
  tar_target(ficheros_adrh_totales, vapply(ADRH_TOTALES, descargar_ine_adrh, character(1)), format = "file"),
  tar_target(fuentes_ingreso_adrh, leer_ine_adrh_distribucion(fichero_adrh_fuentes, ADRH_FUENTES_INGRESO, AMBITO)),
  tar_target(umbrales_adrh, leer_ine_adrh_distribucion(fichero_adrh_umbrales, ADRH_UMBRALES_DEBAJO, AMBITO)),
  tar_target(gini_adrh, leer_ine_adrh_distribucion(fichero_adrh_gini, ADRH_GINI, AMBITO)),
  tar_target(totales_adrh_distribucion, bind_rows(
    leer_ine_adrh_totales(ficheros_adrh_totales[1], ADRH_FUENTES_INGRESO, ccaa, territorios_2021, ambito = AMBITO),
    leer_ine_adrh_totales(ficheros_adrh_totales[2], ADRH_UMBRALES_DEBAJO, ccaa, territorios_2021, ambito = AMBITO),
    leer_ine_adrh_totales(ficheros_adrh_totales[3], ADRH_GINI, ccaa, territorios_2021, ambito = AMBITO)
  )),
  tar_target(renta_bruta_adrh, leer_ine_adrh(fichero_adrh_renta, "Renta bruta media por persona", AMBITO)),
  tar_target(pesos_adrh_distribucion_secciones, pesos_adrh_distribucion(pesos_adrh_prueba, renta_bruta_adrh)),
  tar_target(comprobaciones_adrh_distribucion,
             comprobar_ine_adrh_distribucion(fuentes_ingreso_adrh, umbrales_adrh, gini_adrh, totales_adrh_distribucion,
                                             pesos_adrh_distribucion_secciones, ambito = AMBITO)),
  tar_target(validacion_adrh_distribucion, validar_referencias(comprobaciones_adrh_distribucion, referencias)),
  tar_target(larga_adrh_distribucion, {
    validacion_adrh_distribucion; validacion_f1   # las compuertas van antes que la armonización
    armonizar_ine_adrh_distribucion(seleccionar_adrh_distribucion(fuentes_ingreso_adrh, umbrales_adrh, gini_adrh),
                                    seleccionar_adrh_distribucion(totales_adrh_distribucion),
                                    pesos_adrh_distribucion_secciones, tablas_paso_adrh,
                                    version = version_de(fichero_adrh_fuentes)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
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
  tar_target(resumen_fiabilidad, resumen_fiabilidad_serpavi(larga_serpavi)),
  # Tarea 42: viviendas alquiladas del SERPAVI frente a hogares en alquiler del Censo 2021, en las
  # mismas secciones y el mismo año (R/serpavi_universo.R; nota §7.1). No aísla a las personas jurídicas.
  tar_target(contraste_serpavi_censo, serpavi_contraste_censo(larga_serpavi, censo2021))
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

# Tarea 47: tabla de paso desde las secciones del Censo 2011 (R/paso2011.R; nota §3.11). Lleva al
# seccionado de 2021 el indicador 18 de 2011 (Censo 2011) y el 19 de agosto de 2020 a febrero de 2023
# (PERIODOS_VUT_2011, con las viviendas del Censo 2011 como denominador, el del INE). Las dos vías de
# F1: callejero de enero de 2012 (aplicación antigua, como 2016–2020) y edificios del Catastro ya leídos
# en F1 (edificios_paso; no se vuelve a leer ninguno): construidos hasta 2011 en la tabla del Censo y hasta
# 2020 en la de las viviendas turísticas. La compuerta reutiliza cierre_poblacional y cobertura_destino
# (anio 2011 y 2020, una por tabla) y añade las paso2011_*.
#   targets::tar_make(names = c(larga_paso2011, fichero_paso_final_2011, resumen_paso2011))
bloque_paso2011 <- list(
  tar_target(zip_cartografia_censo2011, paso2011_descargar_cartografia(), format = "file"),
  tar_target(secciones_censo2011, leer_ine_seccionado(zip_cartografia_censo2011, 2011L, SECCIONES_AMBITO)),
  tar_target(zip_callejero_2012, descargar_ine_callejero(PASO2011_CALLEJERO), format = "file"),
  tar_target(tramos_2012, leer_ine_callejero(zip_callejero_2012, FICHEROS_TRAMOS[["antigua_2015"]], AMBITO)),
  tar_target(grupos_2011, geo_grupos_municipio(secciones_censo2011, secciones_2021)),
  tar_target(paso2011_callejero, geo_tabla_paso_callejero_por_provincia(tramos_2012, tramos_2021_antigua,
                                                                        topes_portal, grupos_2011)),
  tar_target(fichero_paso2011_callejero, exportar_tabla_paso(
    paso2011_callejero, sprintf("geo/tablas_paso/callejero_2011_2021%s.csv", SUFIJO_AMBITO)), format = "file"),
  # Edificios de F1 con su sección del Censo 2011 (unos 5 min): una tabla de la vía (b) con los construidos
  # hasta 2011, para el Censo, y otra con los construidos hasta 2020, para las viviendas turísticas
  tar_target(edificios_censo2011, paso2011_origen_edificios(edificios_paso, secciones_censo2011, sf::st_crs(secciones_2021))),
  tar_target(paso2011_catastro, paso2011_tabla_catastro(edificios_censo2011, PASO2011_ANIO_CATASTRO, grupos_2011)),
  tar_target(paso2011_catastro_vut, paso2011_tabla_catastro(edificios_censo2011, PASO2011_ANIO_CATASTRO_VUT, grupos_2011)),
  tar_target(paso2011_descasados, paso2011_municipios_descasados(secciones_censo2011$seccion, tramos_2012$seccion)),
  tar_target(paso_final_2011, paso2011_combinar(paso2011_catastro, paso2011_callejero, unique(secciones_censo2011$seccion),
                                                secciones_2021$seccion, paso2011_descasados)),
  tar_target(paso_final_2011_vut, paso2011_combinar(paso2011_catastro_vut, paso2011_callejero,
                                                    unique(secciones_censo2011$seccion), secciones_2021$seccion,
                                                    paso2011_descasados)),
  tar_target(fichero_paso_final_2011, c(
    exportar_tabla_paso(paso_final_2011, sprintf("geo/tablas_paso/combinada_2011_2021%s.csv", SUFIJO_AMBITO)),
    exportar_tabla_paso(paso_final_2011_vut, sprintf("geo/tablas_paso/combinada_2011_2021_vut%s.csv", SUFIJO_AMBITO))),
    format = "file"),
  tar_target(resumen_paso2011, bind_rows(
    mutate(paso2011_resumen(paso2011_callejero, paso_final_2011, unique(secciones_censo2011$seccion)),
           anio_catastro = PASO2011_ANIO_CATASTRO),
    mutate(paso2011_resumen(paso2011_callejero, paso_final_2011_vut, unique(secciones_censo2011$seccion)),
           anio_catastro = PASO2011_ANIO_CATASTRO_VUT))),
  tar_target(fichero_censo2011, paso2011_descargar_indicadores(), format = "file"),
  tar_target(ficheros_censo2011_tablas, vapply(TABLAS_CENSO2011, paso2011_descargar_tabla, character(1)), format = "file"),
  tar_target(censo2011, paso2011_leer_censo2011(fichero_censo2011, AMBITO)),
  tar_target(censo2011_tenencia, paso2011_leer_tenencia(ficheros_censo2011_tablas[1], ccaa, territorios_2021)),
  tar_target(censo2011_viviendas, paso2011_leer_viviendas(ficheros_censo2011_tablas[2], ccaa, territorios_2021)),
  tar_target(censo2011_2021, paso2011_reproyectar_censo(censo2011, paso_final_2011, secciones_2021$seccion)),
  tar_target(vut_2011_2021, paso2011_reproyectar_vut(vut, paso_final_2011_vut, censo2011, secciones_2021$seccion)),
  tar_target(comprobaciones_paso2011, paso2011_comprobar(
    paso_final_2011, paso_final_2011_vut, edificios_censo2011, censo2011, censo2011_2021, censo2011_tenencia, vut,
    vut_2011_2021, vut_provincias, secciones_censo2011$seccion, secciones_2021$seccion, grupos_2011, excepciones_cobertura)),
  tar_target(validacion_paso2011, validar_referencias(comprobaciones_paso2011, referencias)),
  tar_target(larga_paso2011, {
    validacion_paso2011   # la compuerta va antes que la armonización
    paso2011_armonizar(censo2011_2021, vut_2011_2021, censo2011_tenencia, vut_provincias,
                       version_censo = version_de(fichero_censo2011), version_vut = version_de(fichero_vut_FEB2023)) |>
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

# Indicador 7 (F3): salario medio anual por asalariado, total y de 26 a 35 años, por provincia,
# comunidad y España, 2011–2024 (AEAT, tabla provincial por edad y sexo; R/fuente_aeat_salarios.R).
# País Vasco y Navarra, «ausente» (la AEAT no los cubre). Compuerta: lectura, cobertura y suma y
# media de las provincias frente a su comunidad y España.
salarios_por_anio <- tarchetypes::tar_map(
  values = list(anio_salarios = ANIOS_SALARIOS), names = "anio_salarios",
  tar_target(paginas_salarios, descargar_aeat_salarios(anio_salarios), format = "file"),
  tar_target(salarios_leidos, leer_aeat_salarios(paginas_salarios, anio_salarios))
)
bloque_salarios <- list(
  salarios_por_anio,
  tarchetypes::tar_combine(salarios_aeat_leidos, salarios_por_anio[["salarios_leidos"]], command = dplyr::bind_rows(!!!.x)),
  tar_target(salarios_aeat, codificar_aeat_salarios(salarios_aeat_leidos, provincias_aeat, ccaa)),
  tar_target(validacion_salarios, validar_referencias(comprobar_aeat_salarios(salarios_aeat), referencias)),
  tar_target(larga_salarios, {
    validacion_salarios   # la compuerta va antes que la tabla larga
    armonizar_aeat_salarios(salarios_aeat, version = version_de(paginas_salarios_2024)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  })
)

# Ficha «mochila» (plan §3.1, método en cinco pasos; R/ficha_mochila.R), de 2015 a 2024: salario
# medio de 26 a 35 años de la provincia (indicador 7) × relación mediana/media del salario medio
# estimado (SME) de su comunidad y año (módulo de año completo, desde 2019; antes, la de 2019), a neto
# con la cotización del trabajador y la retención de la AEAT de su comunidad y año. Control con la ECV
# de cada año (ingresos del mismo año que la AEAT). Método B, adoptado el 7-nov-2026; A y C, como
# registro (datos/intermedios/mochila/mochila.csv). Las retenciones de los asalariados salen de las
# mismas páginas que las del transistor (retenciones_por_anio).
ANIO_AEAT <- 2024L
modulo_sme_por_anio <- tarchetypes::tar_map(
  values = list(anio_sme = ANIOS_SME), names = "anio_sme",
  tar_target(paginas_sme_deciles, descargar_aeat_mochila("deciles", anio_sme), format = "file"),
  tar_target(paginas_sme_edad, descargar_aeat_mochila("sme_edad", anio_sme), format = "file"),
  tar_target(paginas_sme_recorrido, descargar_aeat_mochila("recorrido", anio_sme), format = "file"),
  tar_target(paginas_sme_centiles, descargar_aeat_mochila("centiles", anio_sme), format = "file"),
  tar_target(modulo_sme, leer_modulo_sme(paginas_sme_deciles, paginas_sme_edad, paginas_sme_recorrido,
                                         paginas_sme_centiles, anio_sme, ccaa))
)
# Control con la ECV: ficheros de hogares (d) y personas (p) de la ola siguiente a cada año de ingresos
ecv_por_anio <- tarchetypes::tar_map(
  values = list(anio_ecv = ANIOS_MOCHILA), names = "anio_ecv",
  tar_target(csv_ecv_asalariados, obtener_csv_ine_ecv(anio_ecv + 1L, c("d", "p")), format = "file"),
  tar_target(ecv_asalariados, resumir_ecv_asalariados(leer_ecv_asalariados(csv_ecv_asalariados, anio_ecv), anio_ecv))
)
bloque_mochila <- list(
  modulo_sme_por_anio,
  tarchetypes::tar_combine(modulos_sme, modulo_sme_por_anio[["modulo_sme"]], command = combinar_modulos_sme(list(!!!.x))),
  tar_target(validacion_mochila, validar_referencias(modulos_sme$interpolacion, referencias)),
  tar_target(formas_mochila, {
    validacion_mochila
    formas_sme(modulos_sme)
  }),
  tar_target(mochila, {
    validacion_salarios
    # 2015–2018, con la relación de 2019; escalada con la ECV solo si avisa y se valida (pregunta 44 f)
    calcular_mochila_serie(salarios_aeat, formas_mochila, correccion = correccion_mochila$factores)
  }),
  tar_target(fichero_mochila, {
    ruta <- "datos/intermedios/mochila/mochila.csv"
    dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(mutate(mochila, across(where(is.double), ~ round(.x, 3))), ruta)
    ruta
  }, format = "file"),
  ecv_por_anio,
  tarchetypes::tar_combine(ecv_mochila, ecv_por_anio[["ecv_asalariados"]], command = dplyr::bind_rows(!!!.x)),
  tar_target(validacion_mochila_ecv, validar_referencias(
    comprobar_mochila_ecv(mochila, ecv_mochila, ccaa,
                          espana = mochila_espana(salarios_aeat, formas_mochila, correccion = correccion_mochila$factores)),
    referencias)),
  # Pregunta 44 f: relación mediana/media de 2015 a 2018 frente a 2019 con la ECV (quienes trabajaron
  # los doce meses, de 26 a 35 años), y corrección solo si avisa y el método se valida en 2020–2024
  tar_target(correccion_mochila, ecv_mochila_correccion(ecv_mochila, formas_mochila)),
  tar_target(validacion_mochila_relacion, validar_referencias(correccion_mochila$comprobaciones, referencias)),
  # Paso 3: de bruto anual a neto mensual en 12 (regla 8); control con el neto de la ECV
  tar_target(validacion_mochila_neto_ecv,
             validar_referencias(comprobar_neto_ecv(retenciones_mochila, ecv_mochila, ccaa), referencias)),
  tar_target(mochila_neta, {
    validacion_mochila_ecv; validacion_mochila_neto_ecv
    calcular_mochila_neta(mochila, retenciones_mochila)
  }),
  tar_target(validacion_mochila_serie,
             validar_referencias(comprobar_mochila(mochila_neta, formas_mochila, provincias_aeat), referencias)),
  tar_target(fichero_mochila_neta, {
    ruta <- "datos/intermedios/mochila/mochila_neta.csv"
    dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(mutate(mochila_neta, across(where(is.double), ~ round(.x, 3))), ruta)
    ruta
  }, format = "file")
)

# Percentil salarial (F3, plan §7; R/percentil_salarial.R): curvas del salario cobrado en el año por
# los asalariados de cada comunidad y España (AEAT, tabla por comunidad y tramos de salario), netas
# en 12 con la cotización y la retención de cada año, 2015–2024, para expresar el sueldo necesario
# como percentil en la web (datos/salarios.json)
tramos_por_anio <- tarchetypes::tar_map(
  values = list(anio_tramos = ANIOS_PERCENTIL), names = "anio_tramos",
  tar_target(paginas_tramos, descargar_aeat_tramos(anio_tramos), format = "file"),
  tar_target(tramos_salario, leer_aeat_tramos(paginas_tramos, anio_tramos, ccaa))
)
bloque_percentil <- list(
  tramos_por_anio,
  tarchetypes::tar_combine(tramos_salariales, tramos_por_anio[["tramos_salario"]], command = dplyr::bind_rows(!!!.x)),
  tar_target(curvas_salariales_aeat, curvas_salariales(tramos_salariales, retenciones_mochila)),
  tar_target(validacion_percentil,
             validar_referencias(comprobar_curvas_salariales(curvas_salariales_aeat, tramos_salariales), referencias))
)

# Ficha «transistor» (F3; plan §3.1, método decidido por el autor el 9-nov-2026): pensión media de
# jubilación del INSS por provincia, media de los doce meses de cada año de 2015 a 2024
# (R/fuente_inss_pensiones.R), neta de la retención de la AEAT de quienes solo cobran pensiones, de
# su comunidad y año (País Vasco y Navarra, con la de España: «estimado»), repartida en 12
# (R/ficha_transistor.R). Compuerta: las provincias reproducen las cifras de comunidad y España
# publicadas en el mismo Excel.
retenciones_por_anio <- tarchetypes::tar_map(
  values = list(anio_transistor = ANIOS_TRANSISTOR), names = "anio_transistor",
  tar_target(paginas_retenciones_transistor, descargar_aeat_mochila("retenciones", anio_transistor), format = "file"),
  tar_target(grupos_retribuciones, leer_aeat_mercado(paginas_retenciones_transistor)),
  tar_target(retenciones_pensionistas, retenciones_pensiones(grupos_retribuciones, anio_transistor, ccaa)),
  tar_target(retenciones_salariales, retenciones_aeat(grupos_retribuciones, anio_transistor, ccaa))
)
bloque_transistor <- list(
  tar_target(fichero_provincias_inss, "inventario/provincias_inss.csv", format = "file"),
  tar_target(provincias_inss, readr::read_csv(fichero_provincias_inss, col_types = "cccc")),
  tar_target(excel_inss, unlist(lapply(ANIOS_TRANSISTOR, descargar_inss_pensiones)), format = "file"),
  tar_target(inss_mensual, armonizar_inss_pensiones(leer_inss_pensiones(excel_inss), provincias_inss)),
  tar_target(validacion_inss, validar_referencias(comprobar_inss_pensiones(inss_mensual, provincias_inss), referencias)),
  tar_target(inss_anual, {
    validacion_inss   # la compuerta va antes que la media anual
    anual_inss_pensiones(inss_mensual)
  }),
  retenciones_por_anio,
  tarchetypes::tar_combine(retenciones_transistor, retenciones_por_anio[["retenciones_pensionistas"]],
                           command = dplyr::bind_rows(!!!.x)),
  # Retenciones de quien solo cobra salarios, de las mismas páginas: mochila y percentil salarial
  tarchetypes::tar_combine(retenciones_mochila, retenciones_por_anio[["retenciones_salariales"]],
                           command = dplyr::bind_rows(!!!.x)),
  tar_target(transistor, calcular_transistor(inss_anual, retenciones_transistor)),
  tar_target(validacion_transistor, validar_referencias(comprobar_transistor(transistor), referencias)),
  tar_target(fichero_transistor, {
    ruta <- "datos/intermedios/transistor/transistor.csv"
    dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(mutate(transistor, across(where(is.double), ~ round(.x, 4))), ruta)
    ruta
  }, format = "file")
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
  # Unidades administrativas del IGN (condominios; R/fuente_ign_au.R): nombres del suelo sin sección
  tar_target(ficheros_ign, ficheros_ign_au(), format = "file"),
  tar_target(unidades_ign, leer_ign_au(ficheros_ign)),
  # Disolución de las capas y suelo sin sección (≈ 4,5 min) y teselas en un solo paso (≈ 7 min en
  # total, 8-nov-2026): las capas no se guardan
  tar_target(fichero_mapa_base, {
    validacion_jerarquia
    generar_pmtiles(geo_capas_mapa_base(secciones_2021, jerarquia_2021, territorios_2021, unidades_ign),
                    sprintf("geo/referencia/mapa_base_2021%s.pmtiles", SUFIJO_AMBITO))
  }, format = "file"),
  tar_target(resumen_mapa_base, pmtiles_resumen(fichero_mapa_base)),
  tar_target(validacion_mapa_base, validar_referencias(
    comprobar_mapa_base(fichero_mapa_base, secciones_2021, unidades_ign), referencias))
)

# Indicadores derivados (R/derivados.R): 14 (esfuerzo de residentes; en la web, solo en la ficha), 21
# (sueldo neto necesario, mapa por defecto: alquiler mensual real y umbral del 30 %, con el mínimo de
# 50 m² al lado como corte «superficie»; tarea 40) y 15 (peso del alquiler en el ingreso: se calcula en la web; aquí,
# la tartera, la mochila y el transistor de 2015 a 2024, como control).
# Alquiler de vivienda colectiva; estado, el peor de sus términos (plan, preguntas abiertas 12 y 15);
# numerador y denominador del mismo año (regla 4).
# `perfiles`: ingreso neto mensual de cada ficha (tartera, mochila, transistor y llave), para la web.
bloque_derivados <- list(
  tar_target(fichero_provincias_aeat, "inventario/provincias_aeat.csv", format = "file"),
  tar_target(provincias_aeat, readr::read_csv(fichero_provincias_aeat, col_types = "ccc")),
  # Salario mínimo de la tartera (SMI_FICHAS, 2015–2026) frente a los XML del BOE (2015–2023)
  tar_target(xml_boe_smi, descargar_boe_smi(), format = "file"),
  tar_target(validacion_smi, validar_referencias(comprobar_smi_boe(leer_boe_smi(xml_boe_smi)), referencias)),
  tar_target(perfiles, {
    validacion_smi; validacion_transistor; validacion_mochila_serie
    perfiles_fichas(mochila_neta, provincias_aeat, larga_adrh, transistor = transistor)
  }),
  tar_target(resumen_perfiles_llave, resumen_llave(perfiles)),
  tar_target(derivados, armonizar_derivados(larga_serpavi, larga_adrh, perfiles)),
  tar_target(comprobaciones_derivados,
             comprobar_derivados(derivados, larga_serpavi, larga_adrh, perfiles, provincias_aeat, mochila_neta)),
  tar_target(validacion_derivados, validar_referencias(comprobaciones_derivados, referencias)),
  tar_target(larga_derivados, {
    validacion_derivados   # la compuerta va antes que la tabla larga
    validar_tabla_larga(derivados, indicadores, fuentes, vocabulario)
  }),
  tar_target(resumen_larga_derivados, resumen_derivados(larga_derivados)),
  # Tarea 48, módulo de supuestos (R/comun_supuestos.R): inventario/supuestos.csv, que leen R y la
  # web (web/js/supuestos.js, generado); superficie típica de los pisos alquilados (SERPAVI, de la
  # sección a la comunidad, sin salir a la web) y compuerta en una muestra de catorce territorios
  # con todas las combinaciones de «Tu ficha» (pruebas/datos/supuestos_muestra.json).
  tar_target(fichero_supuestos, "inventario/supuestos.csv", format = "file"),
  tar_target(supuestos_inventario, leer_supuestos(fichero_supuestos)),
  tar_target(fichero_supuestos_js, generar_supuestos_js(supuestos_inventario), format = "file"),
  tar_target(fichero_mapa_html, "web/mapa.html", format = "file"),
  tar_target(fichero_muestra_supuestos, "pruebas/datos/supuestos_muestra.json", format = "file"),
  tar_target(superficie_tipica, superficie_tipica_serpavi(larga_serpavi)),
  tar_target(terminos_supuestos, muestra_supuestos(larga_serpavi, perfiles)),
  tar_target(validacion_supuestos, validar_referencias(
    comprobar_supuestos(supuestos_inventario, terminos_supuestos, larga_derivados, superficie_tipica,
                        ruta_js = fichero_supuestos_js, ruta_mapa = fichero_mapa_html,
                        ruta_muestra = fichero_muestra_supuestos), referencias))
)

# F4, compraventa: indicadores 10 (variación anual del alquiler, IPVA del INE), 11 (precio de
# compraventa por m², de Registradores, por provincia; tarea 46), 12 (valor tasado
# del MIVAU), 16 (derivado con el salario medio de la AEAT, indicador 7) y 17 (con la renta neta por
# hogar del ADRH y el tipo de los préstamos nuevos para vivienda del Banco de España; plan §11,
# pregunta 45 d y e), compuerta de coherencia entre la tasación y las
# escrituras ante notario (transacciones inmobiliarias del MIVAU) y tabla de paso código postal ↔
# municipio (callejero de enero de 2021, a geo/). El 11 no sale del Notariado, cuyas webs reservan
# sus derechos y piden autorización expresa (inventario/fuentes.csv), sino de Registradores, por
# provincia (decisión del autor, 10-nov-2026). Los ficheros del Ministerio salen de
# su boletín estadístico en línea (R/fuente_mivau_valor_tasado.R). Con PROVINCIA, el bloque no
# entra (los nombres del Ministerio se casan con toda España).
#   targets::tar_make(names = c(larga_compraventa, fichero_cp_municipio))
ANIOS_VALOR_TASADO <- 2015:2025
ADRH_RENTA_TOTALES <- "53689"   # ADRH: renta media de España, comunidades, provincias e islas (17)
bloque_compraventa <- if (AMBITO != "") list(tar_target(larga_compraventa, NULL)) else list(
  tar_target(ficheros_ipva, vapply(TABLAS_IPVA, descargar_ine_ipva, character(1)), format = "file"),
  tar_target(ipva, leer_ine_ipva_tablas(ficheros_ipva)),
  tar_target(validacion_ipva, validar_referencias(comprobar_ine_ipva(ipva, territorios_2021), referencias)),
  tar_target(larga_ipva, {
    validacion_ipva   # la compuerta va antes que la tabla larga
    armonizar_ine_ipva(ipva, version = version_de(ficheros_ipva)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(ficheros_hipotecas, vapply(TABLAS_HIPOTECAS, descargar_ine_hipotecas, character(1)), format = "file"),
  tar_target(hipotecas_anual, leer_ine_hipotecas(ficheros_hipotecas[1])),
  tar_target(hipotecas_mensual, leer_ine_hipotecas(ficheros_hipotecas[2])),
  tar_target(validacion_hipotecas, validar_referencias(
    comprobar_ine_hipotecas(hipotecas_anual, hipotecas_mensual, ANIOS_VALOR_TASADO), referencias)),
  tar_target(tipo_hipotecario_anual, {
    validacion_hipotecas
    tipo_hipotecario(hipotecas_anual)
  }),
  tar_target(ficheros_valor_tasado, vapply(FICHEROS_MIVAU[c("valor_tasado", "tasaciones", "valor_tasado_municipios")],
                                           descargar_mivau_boletin, character(1)), format = "file"),
  tar_target(fichero_transacciones, descargar_mivau_boletin(FICHEROS_MIVAU[["transacciones_valor"]],
                                                            dir = file.path("datos", "brutos", "mivau_transacciones")),
             format = "file"),
  tar_target(fichero_nombres_mivau, "inventario/nombres_mivau.csv", format = "file"),
  tar_target(nombres_mivau, readr::read_csv(fichero_nombres_mivau, col_types = "ccccc")),
  tar_target(valor_tasado_territorios, leer_mivau_trimestral(ficheros_valor_tasado[1])),
  tar_target(tasaciones_territorios, leer_mivau_trimestral(ficheros_valor_tasado[2], 0L)),
  tar_target(valor_tasado_municipios, leer_mivau_valor_tasado_municipios(ficheros_valor_tasado[3])),
  tar_target(transacciones_territorios, leer_mivau_trimestral(fichero_transacciones)),
  tar_target(nombres_casados_mivau, casar_nombres_mivau(
    unique(c(valor_tasado_territorios$nombre, tasaciones_territorios$nombre, transacciones_territorios$nombre)),
    valor_tasado_municipios, territorios_2021, nombres_mivau)),
  tar_target(niveles_casados_mivau, niveles_mivau(nombres_casados_mivau, territorios_2021)),
  tar_target(valor_tasado_trim, valor_tasado_trimestral(valor_tasado_territorios, tasaciones_territorios,
                                                        valor_tasado_municipios, niveles_casados_mivau)),
  tar_target(validacion_valor_tasado, validar_referencias(
    comprobar_mivau_valor_tasado(valor_tasado_trim, nombres_casados_mivau, territorios_2021), referencias)),
  tar_target(transacciones_trim, codificar_mivau_trimestral(transacciones_territorios, niveles_casados_mivau)),
  # «Hecho cuando» de F4: la tasación y las escrituras, coherentes (R/derivados_compraventa.R)
  tar_target(validacion_coherencia_compraventa, validar_referencias(
    comprobar_coherencia_compraventa(valor_tasado_trim, transacciones_trim), referencias)),
  tar_target(larga_valor_tasado, {
    validacion_valor_tasado; validacion_coherencia_compraventa   # las compuertas van antes
    armonizar_mivau_valor_tasado(valor_tasado_anual(valor_tasado_trim), version = version_de(ficheros_valor_tasado),
                                 anios = ANIOS_VALOR_TASADO) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  # 17 con el tipo de los préstamos nuevos para vivienda del Banco de España (D_IMVTIPLV, del módulo
  # histórico) y la renta neta media por hogar del ADRH (plan §11, pregunta 45 d y e revisadas); el
  # tipo medio del INE sigue con su compuerta (validacion_hipotecas)
  tar_target(tipo_bde_anual, compraventa_tipo_bde(series_bde)),
  # Renta por hogar de provincias, comunidades y España: la publicada por el INE (tabla de totales
  # 53689 del ADRH; 11-nov-2026), con su compuerta frente a la media de los municipios
  tar_target(fichero_adrh_renta_totales, descargar_ine_adrh(ADRH_RENTA_TOTALES), format = "file"),
  tar_target(renta_hogar_publicada, leer_ine_adrh_totales(fichero_adrh_renta_totales, "Renta neta media por hogar",
                                                          ccaa, territorios_2021)),
  tar_target(validacion_renta_hogar_publicada, validar_referencias(
    comprobar_renta_hogar_publicada(renta_adrh, pesos_adrh_prueba, territorios_2021, renta_hogar_publicada), referencias)),
  tar_target(renta_hogar_17, {
    validacion_renta_hogar_publicada   # la compuerta va antes
    compraventa_renta_hogar(renta_adrh, pesos_adrh_prueba, territorios_2021, publicada = renta_hogar_publicada)
  }),
  tar_target(derivados_compraventa, armonizar_derivados_compraventa(larga_valor_tasado, larga_salarios, tipo_bde_anual,
                                                                    renta_hogar = renta_hogar_17,
                                                                    version_renta = max(version_de(fichero_adrh_renta),
                                                                                        version_de(fichero_adrh_renta_totales)))),
  tar_target(validacion_derivados_compraventa, validar_referencias(
    comprobar_derivados_compraventa(derivados_compraventa, larga_valor_tasado, larga_salarios, tipo_bde_anual,
                                    renta_hogar = renta_hogar_17),
    referencias)),
  # 11 desde Registradores, por provincia (R/fuente_registradores.R; plan §11, pregunta 45 a y b
  # revisadas): fichero manual en datos/brutos/registradores/, compuerta de lectura y coherencia con
  # el valor tasado (12), provincia frente a provincia
  tar_target(fichero_registradores, registradores_descargar(), format = "file"),
  tar_target(registradores, registradores_leer(fichero_registradores)),
  tar_target(validacion_registradores, validar_referencias(bind_rows(
    registradores_comprobar(registradores, territorios_2021),
    registradores_coherencia_tasado(registradores, larga_valor_tasado)), referencias)),
  tar_target(larga_registradores, {
    validacion_registradores   # la compuerta va antes que la tabla larga
    registradores_armonizar(registradores, version = version_de(fichero_registradores)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(larga_compraventa, {
    validacion_derivados_compraventa   # la compuerta va antes que la tabla larga
    bind_rows(larga_ipva, larga_registradores, larga_valor_tasado, derivados_compraventa) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  # Tabla de paso código postal ↔ municipio (R/geo_codigos_postales.R), en git como la jerarquía
  tar_target(tramos_cp_2021, leer_ine_callejero_cp(zip_callejero_2021)),
  tar_target(cp_municipio, geo_tabla_cp_municipio(tramos_cp_2021)),
  tar_target(validacion_cp_municipio, validar_referencias(
    comprobar_cp_municipio(cp_municipio, tramos_cp_2021, territorios_2021), referencias)),
  tar_target(fichero_cp_municipio, {
    validacion_cp_municipio
    exportar_cp_municipio(cp_municipio)
  }, format = "file"),
  tar_target(resumen_cp, resumen_cp_municipio(cp_municipio))
)

# F5, indicador 20: zonas de mercado residencial tensionado declaradas (R/fuente_zonas_tensionadas.R).
# Decisiones en inventario/zonas_tensionadas.csv (una fila por municipio y declaración); el XML de cada
# resolución trimestral del MIVAU en el BOE, en datos/brutos/zonas_tensionadas/, y la compuerta
# zonas_tensionadas_* comprueba el CSV contra sus tablas. En la tabla larga, todos los municipios del
# seccionado de 2021, situación a 31 de diciembre de cada año (2 todo el municipio, 1 una parte, 0
# ninguna). Con PROVINCIA, el bloque no entra (los códigos se comprueban con toda España).
bloque_zonas_tensionadas <- if (AMBITO != "") list(tar_target(larga_zonas_tensionadas, NULL), tar_target(zonas_tensionadas, NULL)) else list(
  tar_target(fichero_zonas_tensionadas, "inventario/zonas_tensionadas.csv", format = "file"),
  tar_target(zonas_tensionadas, leer_zonas_tensionadas(fichero_zonas_tensionadas)),
  tar_target(xml_zonas_tensionadas, descargar_zonas_tensionadas(zonas_tensionadas$boe), format = "file"),
  tar_target(boe_zonas_tensionadas, leer_boe_zonas_tensionadas(xml_zonas_tensionadas)),
  tar_target(validacion_zonas_tensionadas, validar_referencias(
    comprobar_zonas_tensionadas(zonas_tensionadas, boe_zonas_tensionadas, territorios_2021), referencias)),
  tar_target(larga_zonas_tensionadas, {
    validacion_zonas_tensionadas   # la compuerta va antes que la tabla larga
    armonizar_zonas_tensionadas(zonas_tensionadas, territorios_2021, version = version_de(fichero_zonas_tensionadas)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(resumen_larga_zonas_tensionadas, resumen_zonas_tensionadas(larga_zonas_tensionadas, zonas_tensionadas))
)

# F5 y tarea 35, indicador 13: precios de oferta de los portales (R/fuente_portales.R y R/web_portales.R).
# Capa desmontable (plan §2.2, regla 6) y solo web (backlog, decisión 3): no entra en la tabla larga,
# así que encenderla o apagarla no toca tabla_larga ni lo que cuelga de ella. Con PORTALES distinto de
# TRUE (por defecto), no se lee nada: larga_portales es NULL y la web lleva la capa apagada
# (datos/portales/manifiesto.json con activa = false). Con PORTALES=TRUE: la extracción de Idealista
# (datos/brutos/portales/idealista/) casada con inventario/portales_idealista_territorios.csv y los CSV
# manuales de datos/brutos/portales/ (formato en el fichero de R), media anual con 9 meses como mínimo,
# compuerta portales_* y exportación a web/datos/portales/ con la suya (web_portales). DIR_WEB, más abajo.
# Tarea 37, indicadores de «entrar» (R/derivados_entrar.R): brecha entre la oferta y el parque, sueldo
# para entrar (superficie típica y 50 m²) y barrera de las fichas, exactos solo dentro del pipeline,
# para la compuerta entrar_* (que incluye el aviso de la tarea 36 con el IPVA); a la web, en la
# carpeta de la capa, solo el tramo de la brecha (inventario/entrar_tramos.csv; decisión 18), con su
# compuerta web_entrar.
bloque_portales <- if (!PORTALES || AMBITO != "") list(
  tar_target(larga_portales, NULL),
  tar_target(ficheros_web_portales, portales_apagar_web(dir_web = DIR_WEB), format = "file")
) else list(
  tar_target(ficheros_portales, buscar_ficheros_portales(), format = "file", cue = tar_cue(mode = "always")),
  tar_target(fichero_idealista_territorios, "inventario/portales_idealista_territorios.csv", format = "file"),
  tar_target(idealista_territorios, idealista_leer_territorios(fichero_idealista_territorios)),
  tar_target(portales, leer_portales(ficheros_portales, idealista_territorios)),   # mensual, formato de la capa
  tar_target(portales_anual, anualizar_portales(portales)),
  tar_target(validacion_portales, validar_referencias(bind_rows(
    comprobar_portales(portales, territorios_2021),
    idealista_comprobar(portales, portales_anual, idealista_territorios)), referencias)),
  tar_target(larga_portales, {
    validacion_portales   # la compuerta va antes
    armonizar_portales(portales_anual, version = version_de(ficheros_portales)) |>
      validar_tabla_larga(indicadores, fuentes, vocabulario)
  }),
  tar_target(resumen_portales, portales_resumen(portales_anual)),
  # Tarea 37: «entrar»
  tar_target(fichero_tramos_entrar, "inventario/entrar_tramos.csv", format = "file"),
  tar_target(tramos_entrar, entrar_leer_tramos(fichero_tramos_entrar)),
  tar_target(terminos_entrar, entrar_terminos(larga_portales, larga_serpavi, perfiles)),
  tar_target(indicadores_entrar, entrar_calcular(terminos_entrar)),     # cifras exactas: no salen del pipeline
  tar_target(validacion_entrar, validar_referencias(
    entrar_comprobar(indicadores_entrar, terminos_entrar, tramos_entrar, larga_portales, larga_ipva, territorios_2021),
    referencias)),
  tar_target(tramos_web_entrar, {
    validacion_entrar   # la compuerta va antes que la exportación
    entrar_tramos_web(indicadores_entrar, tramos_entrar)
  }),
  tar_target(resumen_entrar, entrar_resumen(indicadores_entrar)),
  tar_target(ficheros_web_portales, portales_exportar_web(larga_portales, portales_anual, portales, indicadores,
                                                          jerarquia_2021, territorios_2021, vocabulario = vocabulario,
                                                          dir_web = DIR_WEB, entrar = tramos_web_entrar,
                                                          tramos_entrar = tramos_entrar,
                                                          cortes_niveles = cortes_niveles), format = "file"),   # tarea 51
  tar_target(validacion_web_portales, {
    ficheros_web_portales
    validar_referencias(portales_comprobar_web(larga_portales, portales_anual, indicadores, jerarquia_2021,
                                               territorios_2021, dir_web = DIR_WEB), referencias)
  }),
  tar_target(validacion_web_entrar, {
    ficheros_web_portales
    validar_referencias(entrar_comprobar_web(tramos_web_entrar, tramos_entrar, jerarquia_2021, territorios_2021,
                                             dir_web = DIR_WEB), referencias)
  })
)

# Tabla larga única: cada bloque entra después de pasar su compuerta
bloque_tabla_larga <- list(
  tar_target(tabla_larga, {
    validacion_sobrecarga; validacion_modulo; validacion_fiabilidad
    bind_rows(
      larga_adrh,
      larga_adrh_distribucion,   # 4–6 (F3): secciones, municipios y totales publicados
      larga_serpavi,      # 8 y 9, contratos y margen: la tipología como corte; sin filas «total»
      larga_censo2021,    # 18
      larga_vut,          # 19: el mes de referencia en corte y grupo
      larga_paso2011,     # tarea 47: 18 de 2011 y 19 de 2020-2023, desde las secciones del Censo 2011
      larga_salarios,    # 7 (F3): el total sin desglose; de 26 a 35 años, con corte de edad
      larga_compraventa,  # 10, 11, 12, 16 y 17 (F4); en PROVINCIA, nada
      larga_zonas_tensionadas,   # 20 (F5): municipios, situación a 31 de diciembre; en PROVINCIA, nada
      # 13 (portales): no entra; solo web (decisión 3), en bloque_portales
      larga_derivados,    # 14 y 21 sin desglose (el mínimo de 50 m² del 21, con el corte superficie); 15 con la ficha como corte
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
    validacion_jerarquia; validacion_mapa_base; validacion_derivados; validacion_percentil    # con sus compuertas pasadas
    exportar_web(tabla_larga, indicadores, jerarquia_2021, territorios_2021, pmtiles = fichero_mapa_base,
                 perfiles = perfiles, cajas = cajas_municipios, salarios = salarios_web(curvas_salariales_aeat),
                 dir_web = DIR_WEB,
                 vocabulario = vocabulario, zonas = zonas_tensionadas,   # F5: categorías y declaraciones del 20
                 cortes_niveles = cortes_niveles)                        # tarea 51: juegos de cortes por escala
  }, format = "file"),
  # Tarea 51: reparto de los territorios entre los tramos de cada juego en el último año (alerta)
  tar_target(validacion_web_tramos, {
    ficheros_web
    validar_referencias(comprobar_tramos_web(tabla_larga, indicadores, DIR_WEB), referencias)
  }),
  tar_target(validacion_web, {
    ficheros_web
    validar_referencias(comprobar_web(tabla_larga, indicadores, jerarquia_2021, territorios_2021, DIR_WEB,
                                      perfiles = perfiles), referencias)
  }),
  # F5: declaraciones del indicador 20 (datos/zonas_tensionadas.json): ida y vuelta con el inventario
  if (AMBITO == "") tar_target(validacion_web_zonas_tensionadas, {
    ficheros_web
    validar_referencias(comprobar_zonas_web(zonas_tensionadas, DIR_WEB), referencias)
  }),
  # Percentil salarial (datos/salarios.json): ida y vuelta con las curvas del pipeline
  tar_target(validacion_web_salarios, {
    ficheros_web
    validar_referencias(comprobar_salarios_web(curvas_salariales_aeat, DIR_WEB), referencias)
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
  }),
  # Portada (tarea 24; R/web_portada.R): cifras de las cartas en datos/portada.json, desde la tabla
  # larga y los perfiles, y compuertas portada_valores y portada_casillas (destinos en el manifiesto,
  # en estado.js y en las páginas generadas que haya en web/).
  #   targets::tar_make(names = c(fichero_portada_web, validacion_portada))
  tar_target(fichero_portada_web, {
    ficheros_web
    exportar_portada(tabla_larga, perfiles, dir_web = DIR_WEB)
  }, format = "file"),
  tar_target(validacion_portada, {
    fichero_portada_html
    mapas <- names(jsonlite::read_json(file.path(DIR_WEB, "datos", "manifiesto.json"))$mapas)
    validar_referencias(bind_rows(
      comprobar_portada(tabla_larga, perfiles, dir_web = dirname(dirname(fichero_portada_web))),
      comprobar_casillas_portada(casillas_portada, mapas = mapas, anclas = anclas_paginas_web(),
                                 claves_estado = claves_estado_web())
    ), referencias)
  })
)

# F6, histórico: «máquina del tiempo» (plan §7; R/fuente_bde.R, R/fuente_ine_cne.R, R/historico.R y
# R/web_historico.R). Series nacionales y de comunidad desde 1987 en una tabla propia, no en la tabla
# larga (trimestrales y mensuales): años de renta y esfuerzo teórico del Banco de España, tipos
# oficiales de referencia del mercado hipotecario, valor tasado del MIVAU desde 1995 (la lectura de
# F4, valor_tasado_trim) y sueldo bruto medio por asalariado de la Contabilidad Nacional desde 1995.
# Compuerta con las cifras publicadas (inventario/historico_referencias.csv) y las fechas clave
# (inventario/historico_fechas.csv). Datos de la página web/historico.html en datos/historico/.
# Con PROVINCIA, el bloque no entra (el valor tasado sale del bloque de compraventa).
#   targets::tar_make(names = c(fichero_historico, validacion_web_historico))
bloque_historico <- if (AMBITO != "") list() else list(
  tar_target(ficheros_bde, vapply(HIST_TABLAS_BDE, hist_descargar_bde, character(1)), format = "file"),
  # Los objetivos de tipo fichero no guardan los nombres: se ponen otra vez, en el orden de la lista
  tar_target(series_bde, hist_leer_bde_tablas(stats::setNames(ficheros_bde, names(HIST_TABLAS_BDE)))),
  tar_target(ficheros_cne, vapply(HIST_TABLAS_CNE, hist_descargar_ine_cne, character(1)), format = "file"),
  tar_target(cne_agregados, hist_leer_ine_cne(ficheros_cne[1])),     # HIST_TABLAS_CNE: agregados y empleo
  tar_target(cne_empleo, hist_leer_ine_cne(ficheros_cne[2])),
  tar_target(validacion_cne, validar_referencias(hist_comprobar_ine_cne(cne_agregados, cne_empleo), referencias)),
  tar_target(fichero_historico_fechas, "inventario/historico_fechas.csv", format = "file"),
  tar_target(historico_fechas, hist_leer_fechas(fichero_historico_fechas)),
  tar_target(fichero_historico_referencias, "inventario/historico_referencias.csv", format = "file"),
  tar_target(historico_referencias, hist_leer_referencias(fichero_historico_referencias)),
  tar_target(historico, {
    validacion_cne   # la compuerta de la lectura de la CNE va antes
    hist_armar(series_bde, hist_valor_tasado(valor_tasado_trim), hist_sueldo_asalariado(cne_agregados, cne_empleo),
               versiones = c(bde_accesibilidad = version_de(ficheros_bde[1]),
                             bde_tipos_referencia = version_de(ficheros_bde[2]),
                             mivau_valor_tasado = version_de(ficheros_valor_tasado), ine_cne = version_de(ficheros_cne)))
  }),
  tar_target(validacion_historico, validar_referencias(
    hist_comprobar(historico, series_bde, valor_tasado_trim, territorios_2021, historico_fechas, historico_referencias,
                   rupturas), referencias)),
  tar_target(fichero_historico, {
    validacion_historico   # la compuerta va antes
    hist_exportar_parquet(historico, file.path("datos", "intermedios", "historico.parquet"))
  }, format = "file"),
  tar_target(ficheros_web_historico, {
    validacion_historico
    hist_exportar_web(historico, historico_fechas, rupturas, ccaa, dir_web = DIR_WEB)
  }, format = "file"),
  tar_target(validacion_web_historico, {
    ficheros_web_historico
    validar_referencias(hist_comprobar_web(historico, historico_fechas, rupturas, dir_web = DIR_WEB), referencias)
  })
)

# Tarea 49, primeras historias (R/web_historias.R; decisiones del autor del 11-nov-2026): recorridos
# guiados dentro del mapa. Textos, nota y vista de cada paso en inventario/historias.csv; cifras calculadas
# desde la tabla larga, el histórico, el IPC y los cortes de la web (inventario/historias_cifras.csv), con una
# compuerta que para si alguna se aparta de la redactada (el texto se revisa a mano). Salida:
# datos/historias.json. Sin el histórico (con PROVINCIA), el bloque no entra.
#   targets::tar_make(names = c(fichero_historias_web, validacion_historias))
bloque_historias <- if (AMBITO != "") list() else list(
  tar_target(fichero_historias, "inventario/historias.csv", format = "file"),
  tar_target(fichero_historias_cifras, "inventario/historias_cifras.csv", format = "file"),
  tar_target(fichero_estado_js, "web/js/estado.js", format = "file"),
  tar_target(fichero_historico_html, "web/historico.html", format = "file"),
  tar_target(historias_inventario, leer_historias(fichero_historias)),
  tar_target(historias_cifras, historias_calcular(leer_historias_cifras(fichero_historias_cifras), tabla_larga,
                                                  historico, cortes_niveles, ipc = ipc)),
  tar_target(validacion_historias, {
    ficheros_web; fichero_historico_html
    validar_referencias(comprobar_historias(
      historias_inventario, historias_cifras,
      manifiesto = jsonlite::read_json(file.path(DIR_WEB, "datos", "manifiesto.json")),
      claves_estado = claves_estado_web(fichero_estado_js),
      anclas = anclas_paginas_web(DIR_WEB, c("historico.html", "metodo.html", "method.html", "datos.html", "data.html")),
      larga = tabla_larga, indicadores = indicadores), referencias)
  }),
  tar_target(fichero_historias_web, {
    validacion_historias   # la compuerta va antes
    exportar_historias(historias_inventario, historias_cifras, dir_web = DIR_WEB)
  }, format = "file")
)

# F6, CIS: la vivienda entre los tres principales problemas de España y entre los que más afectan
# personalmente, por barómetro mensual (R/fuente_cis_barometros.R). Serie nacional en una tabla propia
# (no va a la tabla larga), desde enero de 2014: los resultados abiertos de cada barómetro (tabulaciones
# en XLSX o resultados en HTML; sin registro). Compuerta cis_vivienda_* (notas de prensa del CIS, suma de
# menciones, rango y huecos) y JSON para la página del histórico (datos/cis_vivienda.json, fuera de
# datos/historico/, que su exportación borra). cis_estudios busca los barómetros nuevos cuando el
# calendario dice que toca (señal de R/calendario_fuentes.R).
#   targets::tar_make(names = c(fichero_cis_vivienda, validacion_web_cis))
CIS_DESDE <- 2014L
bloque_cis <- list(
  tar_target(cis_estudios, cis_descargar_estudios(CIS_DESDE), format = "file",
             cue = tarchetypes::tar_cue_force(cal_toca("cis_barometros"))),
  tar_target(cis_barometros, cis_leer_barometros(cis_estudios)),
  # Meses publicados solo en PDF, transcritos a mano (plan §11, pregunta 48 a; sin lector de PDF)
  tar_target(fichero_cis_transcripcion, "inventario/cis_transcripcion_pdf.csv", format = "file"),
  tar_target(cis_transcripcion, cis_leer_transcripcion(fichero_cis_transcripcion)),
  tar_target(cis_barometros_completos, cis_aplicar_transcripcion(cis_barometros, cis_transcripcion)),
  tar_target(validacion_cis, validar_referencias(bind_rows(
    cis_comprobar_vivienda(cis_barometros_completos),
    cis_comprobar_transcripcion(cis_barometros, cis_transcripcion)), referencias)),
  tar_target(cis_vivienda, {
    validacion_cis   # la compuerta va antes
    cis_serie_vivienda(cis_barometros_completos)
  }),
  tar_target(fichero_cis_vivienda, {
    ruta <- file.path("datos", "intermedios", "cis", "cis_vivienda.csv")
    dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(cis_vivienda, ruta)
    ruta
  }, format = "file"),
  tar_target(ficheros_web_cis, cis_exportar_vivienda(cis_vivienda, dir_web = DIR_WEB), format = "file"),
  tar_target(validacion_web_cis, validar_referencias(cis_comprobar_web(cis_vivienda, ficheros_web_cis), referencias))
)

# F6, calendario de fuentes (R/calendario_fuentes.R; inventario/calendario_fuentes.csv; procedimiento en
# docs/actualizacion.md). fuentes_pendientes se vuelve a ejecutar cuando cambia el conjunto de fuentes que
# tocan (edición nueva esperable desde la última descarga, o periodo posterior al último del atlas ya
# publicable): avisa con la lista y la forma de renovar cada una, y la deja en
# datos/intermedios/calendario/pendientes.csv. La señal se evalúa al leer este fichero, con la fecha de hoy.
bloque_calendario <- list(
  tar_target(fichero_calendario_fuentes, "inventario/calendario_fuentes.csv", format = "file"),
  tar_target(calendario_fuentes, cal_leer_calendario(fichero_calendario_fuentes)),
  tar_target(validacion_calendario, validar_referencias(cal_comprobar_calendario(calendario_fuentes, fuentes), referencias)),
  tar_target(fuentes_pendientes, {
    validacion_calendario   # la compuerta va antes
    cal_avisar_pendientes(cal_fuentes_pendientes(calendario_fuentes))
  }, cue = tarchetypes::tar_cue_force(cal_hay_cambios()))
)

# Tarea 45: IPC del INE (medias anuales del índice general, tabla 76144; R/fuente_ine_ipc.R) para el
# aviso de euros corrientes de la evolución de la ficha (datos/ipc.json). No deflacta ninguna cifra ni
# entra en la tabla larga.
#   targets::tar_make(names = c(ficheros_web_ipc, validacion_web_ipc))
bloque_ipc <- list(
  tar_target(fichero_ipc, ipc_descargar(), format = "file"),
  tar_target(ipc, ipc_leer(fichero_ipc)),
  tar_target(validacion_ipc, validar_referencias(ipc_comprobar(ipc), referencias)),
  tar_target(ficheros_web_ipc, {
    validacion_ipc   # la compuerta va antes
    ipc_exportar_web(ipc, dir_web = DIR_WEB)
  }, format = "file"),
  tar_target(validacion_web_ipc, validar_referencias(ipc_comprobar_web(ipc, ficheros_web_ipc), referencias))
)

list(inventario, sobrecarga, prueba_f1, mapa_base, bloque_renta_adrh, bloque_adrh_distribucion, bloque_serpavi, bloque_censo2021, bloque_vut, bloque_paso2011, modulo_acceso, bloque_salarios, bloque_mochila, bloque_percentil, bloque_transistor, bloque_derivados, bloque_compraventa, bloque_zonas_tensionadas, bloque_portales, bloque_tabla_larga, bloque_web, bloque_historico,
     bloque_cis, bloque_calendario,   # F6, CIS y calendario
     bloque_ipc,                      # tarea 45, IPC
     bloque_historias)                # tarea 49, primeras historias
