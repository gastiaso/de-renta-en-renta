# Funciones del pipeline

`_targets.R` carga todos los `.R` de esta carpeta con `tar_source("R")`.

| Fichero | Contenido |
|---|---|
| `comun_utilidades.R` | Redondeo, códigos territoriales, neto mensual |
| `comun_descargar.R` | `descargar_con_cache()`: descarga a `datos/brutos/`, no repite y conserva la versión anterior si falla |
| `comun_validar.R` | Compuerta: `leer_tolerancia()` y `validar_referencias()` |
| `fuente_<id>.R` | Una fuente: `descargar_<id>()`, `leer_<id>()`, `armonizar_<id>()`. El `id` es el de `inventario/fuentes.csv` |
| `fuente_ine_ecv.R` | ECV: descarga, extracción y lectura de los microdatos; sobrecarga con el método de Eurostat (total, tenencia, edad, región), olas agrupadas con marca de fiabilidad, comparación con Eurostat y paso a la tabla larga |
| `fuente_ine_ecv_modulo.R` | Tablas del módulo de acceso a la vivienda de la ECV 2025 (indicador 23) |
| `fuente_eurostat_ilc_lvho07.R` | Eurostat: sobrecarga publicada de España (compuerta) y de Europa, y «escalera» |
| `fuente_gisco_nuts.R` | Geometrías NUTS de GISCO por versión y comprobación de que cada región con dato tiene geometría |
| `fuente_ine_seccionado.R` | Cartografía de secciones del INE: descarga y lectura de una provincia dentro del zip |
| `fuente_ine_callejero.R` | Callejero del censo electoral: descarga y lectura de los tramos de una provincia (aplicaciones antigua y nueva) |
| `fuente_ine_adrh.R` | ADRH: descarga de tablas de INEbase, lectura de la renta (indicadores 1–3) y de la demografía, pesos (población y hogares), compuerta `adrh_municipio` y armonización al seccionado de 2021 en formato largo |
| `fuente_mivau_serpavi.R` | SERPAVI (indicadores 8 y 9): fichero manual del MIVAU, lectura de las cinco hojas (de la sección a España) en formato ordenado, compuerta (testigos sumados a provincia y a España, regla del secreto, cuartiles, municipios y distritos frente a sus secciones, entrada de los forales) y formato largo con la tipología como corte y estado `dato`, `secreto` o `ausente` |
| `fuente_ine_censo2021.R` | Censo 2021 (indicador 18): CSV de indicadores por sección (recuentos de viviendas y de tenencia), tabla 59523 de tenencia por provincia y su lectura (comunidades y provincias comparten códigos), compuerta con las secciones en secreto como intervalo y armonización en el seccionado de 2021 |
| `fuente_ine_vut.R` | Viviendas turísticas del INE (indicador 19): tabla 5 de cada periodo (hoja de secciones), tablas provinciales 39364 y 39365, paso del seccionado de 2024 al de 2021 con las viviendas del Censo 2021 como denominador (el % del INE se copia en las secciones 1:1), compuerta y armonización con el mes de referencia en `corte` y `grupo` |
| `fuente_catastro_inspire.R` | Catastro INSPIRE: feeds ATOM de las provincias y de las gerencias propias (Cartagena, Gijón, Jerez, Vigo, Ceuta y Melilla), municipios casados con el INE por nombre (con variantes, artículos y una tabla manual de fusiones), lectura de los edificios con viviendas, tabla de paso por viviendas (vía b) y comparación con la vía (a) |
| `fuente_catastro_foral.R` | Catastros forales (INSPIRE): zips del territorio entero (Álava y Gipuzkoa) y por municipio (Bizkaia y Navarra, con el código del INE en el enlace), lectura de los edificios con viviendas y del año de construcción, que cada territorio pone en una parte distinta de la fecha |
| `fuente_aeat_mercado.R` | AEAT, *Mercado de trabajo y pensiones*: busca una tabla en el mapa de la edición, recorre sus menús de filtros (una página HTML por combinación) y la lee en formato largo |
| `ficha_mochila.R` | Ficha «mochila» (26–35 años): mediana del SME por comunidad interpolada desde los deciles nacionales, opciones A, B y C por provincia, método adoptado (B), paso a neto (cotización y retención de la AEAT por tramo de renta, interpolada), comprobación de la interpolación y controles con los microdatos de personas de la ECV (bruto y neto) |
| `derivados.R` | Indicadores derivados con el alquiler de vivienda colectiva: 14 (esfuerzo de residentes), 21 (sueldo neto necesario, 50 m² y 30 %) y 15 (barrera de acceso de la mochila y la tartera, como control de la web); perfiles de las fichas (ingreso neto mensual de la tartera, la mochila y la llave); estado, el peor de sus términos; compuerta (términos, estados, rangos, SMI y provincias de la mochila) |
| `comun_geo.R` | Tablas de paso por el callejero, estado de lo reproyectado (`dato`, `estimado`, `ausente`), reproyección de recuentos, medias ponderadas y medianas, prueba de cierre, diagnóstico y cambios de límites. |
| `geo_mapa_base.R` | Jerarquía territorial del seccionado de 2021 (`geo_jerarquia`, `geo_territorios`, compuerta `comprobar_jerarquia`), capas del mapa base por disolución, PMTiles con GDAL (`generar_pmtiles`), lectura del PMTiles para medirlo por zoom (`pmtiles_resumen`) y compuerta `comprobar_mapa_base` |
| `comun_exportar.R` | Tablas de paso a CSV; esquema, validación (`validar_tabla_larga()`) y escritura en Parquet de la tabla larga; diccionarios ES/EN (`exportar_i18n()`). Previsto: ficheros para la web |
| `web_exportar.R` | Datos de la web (`exportar_web`): índices por nivel, valores por serie, nivel y periodo (JSON de enteros con estados), fichas por municipio, nombres, cajas y perfiles; compuerta de ida y vuelta (`comprobar_web`) |
| `web_estilo.R` | Kit de diseño: `tokens.css` desde `diseno/tokens.json`, contrastes WCAG y tipografías autoalojadas |

Convenciones: nombres en castellano y en `snake_case`; una función hace una cosa; las descargas guardan en `datos/brutos/` y no repiten si el fichero existe, salvo que se pida; los errores dicen qué falta y dónde conseguirlo. El código reaprovechado de proyectos anteriores lleva en la cabecera la fecha de incorporación.
