# Registro de cambios

Formato inspirado en *Keep a Changelog*, en castellano. Versiones previstas: v0.0 (sobrecarga y Europa), v0.1 (núcleo por sección censal), v0.2 a v0.4 (salarios, compraventa, presión y portales), v1.0.

## [Sin publicar]

### Añadido (7-nov-2026, medición para toda España)

- Medición de las descargas para llevar la geografía constante a toda España (plan v0.14, §6.3): 1.489 municipios con secciones repartidas por el callejero en algún año; 3,57 GB de edificios del Catastro por bajar (1.256 zips) y unos 0,9 GB de las dos tablas nacionales del ADRH. Nada descargado todavía.
- Inventario: los feeds de edificios del Catastro de cada provincia permiten el uso gratuito citando a la D. G. del Catastro; el feed general sigue diciendo «all rights reserved».

### Añadido (7-nov-2026, mochila)

- Lectura de la AEAT, *Mercado de trabajo y pensiones* (`R/fuente_aeat_mercado.R`): busca la tabla en el mapa de la edición, recorre los menús de filtros y guarda cada página HTML en `datos/brutos/aeat_mercado/<año>/` (2024: 74 páginas, 3,6 MB). Los filtros pasan a columnas sin tildes (`distribucion_geografica`, `tramos_de_edad`…), porque `targets` no admite símbolos no ASCII en las funciones.
- Opciones A, B y C de la mochila por provincia (`R/ficha_mochila.R`, `mochila_opciones`), con la mediana del SME interpolada desde los deciles nacionales, y su comprobación frente a los centiles (`aeat_mediana_deciles`, alerta). Resultados y control con la ECV en el plan v0.14, §3.1. La pregunta abierta 7 sigue abierta.

### Cambiado (7-nov-2026, decisiones del autor)

- Preguntas abiertas cerradas (plan v0.14, §11): escalonado (v0.0, v0.1 con 10 indicadores, v1.0 con 23) y portales (capa desmontable, solo informes agregados) confirmados; sin dominio propio (la web irá en la dirección de GitHub Pages); País Vasco y Navarra sin alquiler por sección en los años sin SERPAVI, con las fianzas como capa municipal aparte; la sobrecarga sin intervalos, con el número de observaciones y la marca de fiabilidad; `adrh_suma_secciones` se queda como alerta.
- Tabla larga con dos columnas nuevas, `corte` y `grupo` (`total` por defecto). Entran la sobrecarga de España por tenencia y edad (cada año), la de comunidad × tenencia y comunidad × edad (tres olas agrupadas, con `anio` = la última) y la búsqueda sin éxito de España por edad, sexo y tenencia (tablas 79629 y 79635 del módulo). La compuerta comprueba cortes y grupos contra `inventario/vocabulario.csv`, que gana sus textos en castellano e inglés; `modulo_acceso_lectura` compara también el total de las tablas por edad y por tenencia.
- El ADRH 2015 pasa al seccionado y al callejero de 2016, como el resto de años (*t* + 1). Descargados `seccionado_2016.zip` y `caj_esp_012016.zip`. En Madrid no cambia casi nada: los dos seccionados tienen los mismos códigos (secciones `estimado` de 2021: 191, antes 192). La tabla `geo/tablas_paso/callejero_2015_2021_28.csv` se sustituye por `callejero_2016_2021_28.csv`.
- Agente de usuario de las descargas con el nombre nuevo.

### Cambiado (7-nov-2026, nombre)

- Nombre: *De renta en renta*, sin traducir; dicho de portada «De renta en renta, y pago porque me toca» (`web/i18n`, clave `sitio.dicho`). Carpeta y proyecto de RStudio: `de-renta-en-renta`; el repositorio de GitHub llevará el mismo nombre.
- Plan v0.13.

### Añadido (7-nov-2026, séptima tanda)

- Tablas de paso de todos los años del ADRH en Madrid (2015–2024): callejeros y seccionados de enero de 2017–2020, 2023 y 2024; una tabla por seccionado con `tarchetypes::tar_map()` (`PASOS_2021`). La renta de todos los años va en el seccionado de 2021 (plan v0.12).
- Edificios del Catastro leídos municipio a municipio (ramas dinámicas): un municipio nuevo no obliga a releer el resto.
- `geo_fase_codigos()` (diagnóstico): secciones del ADRH, del mapa y del callejero de cada año. Confirma que el ADRH del año t va con el seccionado de t + 1.
- Alerta `adrh_suma_secciones`: el ADRH no siempre suma sus secciones al total municipal que publica (2016, 2017 y 2019).
- Lectura del callejero de 2019 (tramos dentro de «TRAMOS-NAL.zip»; `patron_zip_interno()`).

### Cambiado (7-nov-2026, séptima tanda)

- `cierre_poblacional` compara con la suma de las secciones de origen de cada municipio, no con el total publicado: mide solo la tabla. La diferencia de la fuente la vigila `adrh_suma_secciones`.

### Añadido (7-nov-2026, sexta tanda)

- Tabla 2022 → 2021 combinada con el Catastro (seccionado de 2022) y prueba de un año de la vía (b): en las secciones que el callejero reparte, los errores de más del 20 % bajan de 50 a 7 (plan v0.11, §6.3). La renta de 2021 usa la tabla combinada.
- Secciones «fantasma» del seccionado (códigos del mapa que no están en el callejero ni en el ADRH del mismo año): sus edificios pasan al origen de los datos que cubre el mismo destino (`reasignar_fantasmas()`).
- Compuerta `cobertura_destino` (bloqueo): ninguna sección de 2021 se queda sin recibir nada de la tabla de paso (`comprobar_cobertura_destino()`).

### Cambiado (7-nov-2026, quinta tanda)

- Tablas de paso combinadas (plan v0.10): callejero donde las secciones caen enteras y Catastro donde hay que repartir (`combinar_vias()`), con edificios filtrados por año de construcción y sin pares entre municipios. Se usan en la renta de 2015 y 2024 y en la prueba de cierre; la de 2022 sigue con el callejero.
- El pipeline carga `sf` en todos los pasos (filtrar objetos espaciales guardados).

### Añadido (7-nov-2026, cuarta tanda)

- Vía (b) de las tablas de paso, Catastro (`R/fuente_catastro_inspire.R`): feed ATOM, municipios casados por nombre con el INE, edificios con viviendas, tabla de paso por viviendas, combinación con el callejero y comparación de las dos vías. Prueba en los 55 municipios de Madrid con secciones `estimado`: en esas secciones, los errores de más del 20 % bajan de 128 a 27.
- Pruebas de la vía (b) con geometrías inventadas.

### Añadido (7-nov-2026, tercera tanda)

- Kit de diseño en la web (backlog, tarea 9): `web/estilo/tokens.css` generado desde `diseno/tokens.json`, tipografías autoalojadas con su licencia y compuertas `contraste_texto`, `contraste_declarado` y `rampa_contorno` (`R/web_estilo.R`).
- Corrección: Yellowtail tiene licencia Apache 2.0, no OFL (`tokens.json`, `diseno/LEEME.md`).

### Añadido (7-nov-2026, segunda tanda)

- Fichas de los 23 indicadores en castellano e inglés (backlog, tarea 8): unidad, definición, cálculo y lectura en `inventario/indicadores.csv`.
- Diccionarios de la web (tarea 10): `exportar_i18n()` genera las secciones de indicadores, fuentes y vocabulario de `web/i18n/` desde el inventario; `nombre_en` en `fuentes.csv`; `inventario/vocabulario.csv`; compuerta `i18n_completo`.

### Añadido (7-nov-2026)

- Sobrecarga (F1b): tres olas de la ECV (2023–2025) con `tarchetypes::tar_map()`, corte por edad (RB081), cruces comunidad × tenencia y × edad con las olas agrupadas y marca de fiabilidad de EU-SILC (`calcular_sobrecarga_agrupada()`); datos europeos de Eurostat (`descargar_eurostat_europa()`), geometrías NUTS 2021 y 2024 de GISCO (`R/fuente_gisco_nuts.R`) y «escalera» (`armar_escalera()`). Nuevas comprobaciones: `sobrecarga_es_edad` y `nuts_geometria` (alertas).
- Indicador 23 desde las tablas del módulo de acceso de la ECV 2025 (`R/fuente_ine_ecv_modulo.R`; fuente `ine_ecv_modulo`; comprobación `modulo_acceso_lectura`).
- Tabla larga única con los indicadores 1–3, 22 y 23; nivel `nacional` («00») y tabla fija de comunidades `geo/ccaa.csv` (código del INE, nombre y NUTS 2).
- Plan: preguntas abiertas 9 (intervalos de confianza) y 10 (desgloses en la tabla larga).

### Añadido (6-nov-2026, séptima tanda)

- Comprobación del nombre (backlog, tarea 2): GitHub, dominios y marcas de las tres candidatas (plan §10.1). Decisión pendiente.

### Añadido (6-nov-2026, sexta tanda)

- Pipeline de punta a punta (backlog, tarea 7): renta del ADRH de Madrid (indicadores 1–3) leída, validada (`adrh_municipio`, bloqueo; `adrh_municipio_detalle`, alerta), llevada al seccionado de 2021 con estado y escrita en la tabla larga en Parquet (`validar_tabla_larga()`, `exportar_tabla_larga()`).
- `geo_tabla_identidad()` y `geo_cobertura_origenes()`: el año nativo pasa sin tabla y los orígenes con secreto marcan el destino como `estimado` o `secreto`.
- Pruebas de la tabla larga y de la armonización del ADRH.

### Cambiado (6-nov-2026, quinta tanda)

- Inventario de fuentes (backlog, tareas 3 y 4): acceso, licencia citada, cadencia y desfase comprobados en las fuentes de la v0.0 y la v0.1 (INE, Eurostat y GISCO, AEAT, Seguridad Social, Catastro, Gobierno Vasco); nueva fuente de referencia `nastat_epav`; ruptura `vut_calendario_2024`.
- Plan v0.9: revisión del método de la mochila (pregunta abierta 7), alquiler del País Vasco y Navarra sin SERPAVI (pregunta abierta 8), huecos y versiones NUTS del mapa europeo, vía (b) del Catastro.
- `LICENCIA_DATOS.md`: las geometrías NUTS de GISCO quedan fuera de la licencia CC BY 4.0.

### Añadido (6-nov-2026)

- Esqueleto del repositorio: estructura de carpetas, licencias (MIT y CC BY 4.0), `CITATION.cff`, `.gitignore`, `.gitattributes` y proyecto de RStudio.
- Guía de trabajo (`docs/guia_de_trabajo.md`) y backlog de F0 (`docs/backlog_f0.md`).
- Plan de integración v0.3 (`docs/plan_integracion_atlas.md`).
- Inventario inicial: 25 fuentes, 23 indicadores, 12 referencias de validación y una ruptura (`inventario/`).
- Kit de diseño del tablero: colores con contrastes calculados, tipografías y cinco fichas en SVG (`diseno/`).
- Pipeline mínimo (`_targets.R`), utilidades comunes y pruebas del inventario.

### Añadido (6-nov-2026, tercera tanda)

- Prueba de F1 en Madrid (backlog, tarea 6): lectura del seccionado (`R/fuente_ine_seccionado.R`), del callejero (`R/fuente_ine_callejero.R`) y de la población por sección del ADRH (`R/fuente_ine_adrh.R`); tablas de paso por el callejero, reproyección de recuentos, prueba de cierre, diagnóstico sección a sección y cambios de límites (`R/comun_geo.R`); exportación de las tablas (`R/comun_exportar.R`, `geo/tablas_paso/`).
- Rupturas `callejero_aplicacion_2021` y `callejero_diseno_2025`.
- Pruebas de las tablas de paso con tramos inventados, incluido el caso de las pseudovías.
- Prueba de un año en Madrid (tabla 2022 → 2021 y diagnóstico frente al ADRH 2020).
- Regla de estado de las cifras reproyectadas (`dato`, `estimado`, `ausente`), adoptada en el plan v0.7: `geo_estado_paso()`, `geo_reproyectar_media()` y `geo_reproyectar_mediana()`; `geo_reproyectar_recuento()` devuelve el estado.
- Medianas reproyectadas: se copia la del origen dominante (≥ 95 % de los portales) como `estimado` en lugar de dejarlas `ausente` (plan v0.8). `geo_estado_paso()` devuelve el origen de la copia.

### Añadido (6-nov-2026, segunda tanda)

- Indicador 22, sobrecarga por gastos de vivienda (backlog, tarea 5): descarga y lectura de los microdatos de la ECV (`R/fuente_ine_ecv.R`), cálculo con el método de Eurostat por total, tenencia y región NUTS 2, y consulta de las cifras de Eurostat (`R/fuente_eurostat_ilc_lvho07.R`). Con la ECV 2025 pasa la compuerta en España, inquilinos a precio de mercado y las 19 comunidades.
- Compuerta de publicación (`R/comun_validar.R`): `validar_referencias()` lee la tolerancia y el tipo de `inventario/referencias_validacion.csv`; los bloqueos paran el pipeline.
- Descargas con caché (`R/comun_descargar.R`).
- Pruebas de la sobrecarga y de la compuerta con datos inventados.

### Cambiado (6-nov-2026)

- Entorno (backlog, tarea 0): R 4.6.1 con `renv`; `renv.lock` fija todas las versiones de la biblioteca del proyecto.
- SERPAVI por sección censal (backlog, tarea 1): descarga directa de la base de datos del MIVAU, 2011–2024, en el seccionado del Censo 2021. Fila `mivau_serpavi` completa; `gv_emal` acotada a los años sin SERPAVI en el País Vasco; nueva ruptura `serpavi_forales`; la referencia `serpavi_provincia` pasa a comprobar recuentos de testigos, con tolerancia exacta.
- Plan v0.4: cobertura real del SERPAVI (§2.4), geografía constante del alquiler (§6.3) y pregunta abierta sobre el seccionado de referencia (§11).
- Plan v0.5: el seccionado de referencia es el del Censo 2021, no el último; tablas de paso en las dos direcciones (§6.3). Guía, backlog (tarea 6), `geo/LEEME.md` e inventario, al día.
- Indicador 8: «Alquiler mensual (mediana)» en lugar de «Alquiler medio mensual».

### Procedencia

- Convenciones de redondeo y de códigos territoriales: reaprovechadas de un proyecto propio anterior.
- Fichas SVG y paleta: maquetas de diseño (`docs/maquetas.md`).
