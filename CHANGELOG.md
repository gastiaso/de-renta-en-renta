# Registro de cambios

Formato inspirado en *Keep a Changelog*, en castellano. Versiones previstas: v0.0 (sobrecarga y Europa), v0.1 (núcleo por sección censal), v0.2 a v0.4 (salarios, compraventa, presión y portales), v1.0.

## [Sin publicar]

### Añadido (8-nov-2026, F2: SERPAVI, Censo, viviendas turísticas, mapa base, web y nota metodológica)

- **Indicadores 8 y 9** (alquiler mensual, mediana; alquiler por m²) con la base de datos del SERPAVI, 2015–2024, en el seccionado de 2021 sin tabla de paso (`R/fuente_mivau_serpavi.R`; bloque `bloque_serpavi`):
  - `descargar_mivau_serpavi()`: fichero manual (la web del MIVAU bloquea las descargas automáticas);
  - `leer_mivau_serpavi()`: las cinco hojas, de la sección a la comunidad con España;
  - `comprobar_mivau_serpavi()`: compuerta `serpavi_provincia`, `serpavi_espana`, `serpavi_secreto`, `serpavi_cuartiles` y `serpavi_escalas` (bloqueo), y `serpavi_escalas_detalle` y `serpavi_forales` (alerta). Pasa; avisa en 164 cifras de municipios y distritos que no cuadran con sus secciones, casi todas de Navarra en 2022–2024;
  - `armonizar_mivau_serpavi()`: tipología como corte (`tipologia`, `tipologia_p25`, `tipologia_p75`; grupos `VC` y `VU`) y estado `dato`, `secreto` (de 1 a 9 testigos) o `ausente`; País Vasco y Navarra desde su entrada;
  - secciones con mediana de vivienda colectiva: de 21.627 (2015) a 26.137 (2024).
- **Indicador 18** (hogares en alquiler) del Censo 2021 (`R/fuente_ine_censo2021.R`; bloque `bloque_censo2021`): t20_2 / t19_1, 34.970 secciones con dato y 1.363 en secreto; compuerta `censo2021_alquiler`, `censo2021_principales` y `censo2021_seccionado` (España, 16,10 % en el pipeline y en la tabla 59523).
- **Indicador 19** (viviendas turísticas sobre el total de viviendas) (`R/fuente_ine_vut.R`; bloque `bloque_vut`): seis periodos, de febrero de 2024 a mayo de 2026, en el seccionado de 2024, llevados al de 2021 con la tabla combinada; en las secciones 1:1 se copia el % del INE, en las demás se rehace con las viviendas del Censo 2021. Compuerta `vut_viviendas_provincia`, `vut_seccionado`, `vut_paso_2021` y `vut_denominador` (bloqueo), y `vut_denominador_detalle` (alerta). Ruptura `vut_seccionado_2024`.
- Vocabulario: cortes `tipologia`, `tipologia_p25`, `tipologia_p75` (grupos `VC`, `VU`) y `mes` (grupos `M02`, `M05`, `M08`, `M11`).
- `tabla_larga` incluye `larga_serpavi`, `larga_censo2021` y `larga_vut`.
- **Jerarquía territorial** del seccionado de 2021 (`R/geo_mapa_base.R`): `geo/jerarquia_2021.csv` (sección → distrito → municipio → provincia → comunidad) y `geo/territorios_2021.csv` (nombres, superior y número de secciones), con las compuertas `jerarquia_unica`, `jerarquia_sumas` y `jerarquia_nombres`.
- **Mapa base en PMTiles** (`geo/referencia/mapa_base_2021.pmtiles`, 35,2 MB, fuera de git), con GDAL desde R, sin tippecanoe: comunidades, provincias, municipios y secciones; simplificación de medio píxel por debajo del zoom 12. Objetivos `fichero_mapa_base`, `resumen_mapa_base` y `validacion_mapa_base` (compuerta `mapa_base_secciones`). Visor de comprobación en `geo/visor/` (`node geo/visor/servir.mjs`).
- **Web de la v0.1, esqueleto** (pila elegida por el autor: HTML y módulos JavaScript sin compilar): `web/index.html`, `web/js/`, `web/estilo/sitio.css`; cabecera, ES/EN, mapa MapLibre por tramos con la trama del secreto, leyenda, ficha de sección y estado de la vista en la URL (el sueldo nunca va en ella). MapLibre GL JS 6.15.0 y PMTiles 4.5.0 autoalojados en `web/vendor/` (BSD-3, con permiso del autor). Manifiesto de datos como punto de enganche y muestra con valores inventados en `web/datos/ejemplo/` (`web/herramientas/generar_ejemplo.R`). Servidor local `node web/servir.mjs`. Pruebas con `node --test pruebas/web/datos.test.mjs`.
- **Nota metodológica**, primera versión en castellano (`docs/metodologia.md`), con cifras trazables a su objetivo, función o CSV; `test-metodologia.R` comprueba que lo citado existe.
- Prueba de un año de la tabla combinada en toda España (`comparacion_vias`): en las 6.180 secciones de 2021 que el callejero reparte, dentro de ±5 %, del 61,2 al 94,1 %.
- Pruebas con datos inventados: `test-serpavi.R`, `test-censo2021-vut.R`, `test-mapa-base.R`.

### Cambiado (8-nov-2026, F2)

- `larga_adrh` depende también de `validacion_f1`: la compuerta de las tablas de paso va antes que la reproyección de la renta.
- Filas del inventario: `mivau_serpavi` (descarga manual; errores de las hojas de municipios y distritos), `ine_censo2021`, `ine_vut` e indicadores 18 y 19 (serie y lectura: numerador y denominador de años distintos).
- `.gitattributes`: `*.bin` como binario.

### Corregido (8-nov-2026)

- Las viviendas turísticas del INE no están en el seccionado de 2021 en todos sus periodos, como decían el plan (v0.9) y `inventario/fuentes.csv`: hasta febrero de 2023 usan las secciones del Censo 2011 y desde febrero de 2024, el seccionado de 2024.
- Plan §6.3: de 2021 a 2025 conservan el código 35.995 de 36.333 secciones y aparecen 559 (antes, 35.955 de 36.293 y 599).

### Cambiado (8-nov-2026, licencia)

- Datos derivados, textos e inventario pasan de CC BY 4.0 a CC BY-SA 4.0 (`LICENCIA_DATOS.md`, `README.md`; plan v0.19, §6.1). Las fuentes se tratan como datos abiertos (decisión del autor), incluidos el Catastro estatal y los forales de Bizkaia y Gipuzkoa, de licencia contradictoria (`inventario/fuentes.csv`).
- Las tablas de paso combinadas (callejero y Catastro), las que se usan, entran en git: `geo/tablas_paso/combinada_<año>_2021.csv` (objetivo `fichero_paso_final`).

### Añadido (8-nov-2026, catastros forales)

- Catastros forales de Álava, Bizkaia, Gipuzkoa y Navarra en la vía (b) de las tablas de paso (plan v0.18, §6.3). Fuente `catastro_foral` y fichero `R/fuente_catastro_foral.R`:
  - zips del territorio entero (Álava y Gipuzkoa) y por municipio (Bizkaia y Navarra, sacados de sus feeds ATOM): `zips_catastro_forales`, `seleccionar_zips_forales`, `descargar_catastro_foral`;
  - lector propio (`leer_catastro_foral`), que lee todos los GML de un zip y toma el año de construcción de la parte de la fecha que use cada territorio (`anio_construccion_foral`). No toca el lector del Catastro estatal, para no releer sus zips.
- Objetivos `municipios_forales`, `zips_forales_feeds`, `urls_forales`, `zips_forales`, `edificios_foral` y `edificios_forales`. Este último guarda solo los edificios de los municipios seleccionados. `edificios_paso` junta los estatales y los forales.
  - El bloque foral solo entra si el ámbito incluye alguna provincia foral: con `PROVINCIA=28` no hay nada que leer, y targets no admite ramas sobre una lista vacía.
  - `municipios_cubiertos` incluye ya los forales.
- Descarga y resultado:
  - 58 zips, 68,9 MB (con permiso del autor); 131.335 edificios con viviendas, 1.035.411 viviendas.
  - Censo 2021 en 11 municipios: −0,1 % en total.
  - Secciones de 2021 `estimado` en País Vasco y Navarra: de 300 a 2 en 2021 y de 360 a 62 en 2024.
- Pruebas con datos inventados de los enlaces, la selección de zips y el año de construcción (`test-catastro-foral.R`).

### Cambiado (8-nov-2026)

- Indicador 7: la lectura recoge el paso a neto de la mochila (ES y EN; diccionarios de la web regenerados).

### Añadido (7-nov-2026, mochila en neto)

- Paso a neto de la mochila (plan v0.17, §3.1, paso 3; regla 8): neto anual = bruto × (1 − cotización del trabajador − retención), ÷ 12 (`calcular_mochila_neta`, `mochila_neta`, `datos/intermedios/mochila/mochila_neta_2024.csv`). Cotización de 2024: 6,47 % (`COTIZACION_TRABAJADOR`). Retención: tipo medio de la AEAT de quien solo cobra salarios, por comunidad y tramo de renta anual, interpolado entre los salarios medios de los tramos (`retenciones_aeat`, `tipo_retencion`). 2024: de 990 € al mes (Huelva) a 1.529 € (Barcelona).
- Tabla *Grupos de población por la naturaleza de sus retribuciones* de la AEAT (`aeat_retenciones`; 162 páginas, 4,3 MB).
- `leer_aeat_mercado()` lee las filas agrupadas en bloques (cabecera de fila que abarca varias filas) y guarda el bloque en la columna `bloque`; las tablas sin bloques salen igual que antes.
- Control con la ECV: `leer_ecv_asalariados()` lee también el salario neto (PY010N) y `resumir_ecv_asalariados()` da su mediana. Alerta `mochila_neto_ecv` (±5 %): el paso a neto aplicado a la mediana del bruto de cada comunidad, frente a la mediana del neto. 2024: entre −2,0 y +3,4 %; España, +0,5 %.

### Cambiado (7-nov-2026, marcas)

- Sin registro de marca para *De renta en renta*: el proyecto es abierto y no comercial (decisión del autor). La búsqueda en TMview y en la OEPM no encontró la frase (plan v0.17, §10.1; backlog, tarea 2, cerrada).

### Añadido (7-nov-2026, geografía constante en toda España)

- El pipeline cubre las 52 provincias (plan v0.16, §6.3): tablas nacionales del ADRH (30824 y 30832), callejeros y seccionados enteros, y 1.420 municipios con edificios del Catastro (4,2 GB). La variable de entorno `PROVINCIA` lo limita a una provincia para pruebas. Memoria `transient` en `targets`. Una pasada completa, unas tres horas y cuarto.
- Tablas de paso del callejero nacionales en `geo/tablas_paso/callejero_<año>_2021.csv` (sustituyen a las de Madrid, `_28`), calculadas provincia a provincia.
- Catastro: feeds de las gerencias propias (Cartagena, Gijón, Jerez, Vigo, Ceuta y Melilla) y casado de municipios por nombre con variantes, artículos, bilingües, nombres cortados y una tabla manual de fusiones y cambios de nombre (`casar_municipios_catastro`). Los edificios se pasan al sistema del seccionado y se guardan con su sección de 2021.
- Fusiones y segregaciones de municipios (`geo_grupos_municipio`): las tablas y la prueba de cierre cruzan municipios dentro de un grupo.
- El Catastro decide también en las secciones con datos que no están en el callejero y donde la tabla combinada dejaría vacía una sección de 2021; las secciones con datos sin ninguna vía pasan por su código si existe en 2021 (`completar_por_codigo`).
- Alertas nuevas: `adrh_seccion_huerfana` (nueve secciones del ADRH con códigos de un seccionado anterior, fuera de la tabla y del cierre) y `cobertura_destino_excepcion` (dos secciones con un defecto conocido de la fuente, en `inventario/excepciones_cobertura.csv`).

### Cambiado (7-nov-2026, geografía constante en toda España)

- La renta por hogar de Madrid cambia en 33 cifras (menos de un 0,3 %): la tabla nacional del ADRH redondea el tamaño medio del hogar distinto que la provincial.

### Cambiado (7-nov-2026, método de la mochila)

- Mochila con el método B (plan v0.15, §3.1; pregunta abierta 7, cerrada): salario medio real de 26 a 35 años de la provincia × relación mediana/media del SME de su comunidad, en bruto anual (`mochila`, `datos/intermedios/mochila/mochila_2024.csv`). Las opciones A y C se siguen calculando (`mochila_opciones`) como registro de la decisión. Falta el paso a neto.
- Control con la ECV dentro del pipeline (`leer_ecv_asalariados`, `resumir_ecv_asalariados`, `comprobar_mochila_ecv`): mediana del bruto del año de los asalariados de 26 a 35 años por comunidad, con la ola de 2025 (ingresos de 2024). Alerta `mochila_ecv` (±15 %), que sustituye a la fila provisional de las referencias. 2024: entre −10,6 % y +7,2 % por comunidad.
- El CSV de personas de la ECV 2025 (`esudb25p.csv`) se toma de una copia local del zip original del INE, como los de hogares y registro; si falta, `obtener_csv_ine_ecv()` descarga el zip.

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
