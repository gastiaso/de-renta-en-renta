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
| `fuente_catastro_inspire.R` | Catastro INSPIRE: feeds ATOM de las provincias y de las gerencias propias (Cartagena, Gijón, Jerez, Vigo, Ceuta y Melilla), municipios casados con el INE por nombre (con variantes, artículos y una tabla manual de fusiones), lectura de los edificios con viviendas, tabla de paso por viviendas (vía b) y comparación con la vía (a) |
| `fuente_aeat_mercado.R` | AEAT, *Mercado de trabajo y pensiones*: busca una tabla en el mapa de la edición, recorre sus menús de filtros (una página HTML por combinación) y la lee en formato largo |
| `ficha_mochila.R` | Ficha «mochila» (26–35 años): mediana del SME por comunidad interpolada desde los deciles nacionales, opciones A, B y C por provincia, método adoptado (B), paso a neto (cotización y retención de la AEAT por tramo de renta, interpolada), comprobación de la interpolación y controles con los microdatos de personas de la ECV (bruto y neto) |
| `comun_geo.R` | Tablas de paso por el callejero, estado de lo reproyectado (`dato`, `estimado`, `ausente`), reproyección de recuentos, medias ponderadas y medianas, prueba de cierre, diagnóstico y cambios de límites. Previsto: jerarquía territorial |
| `comun_exportar.R` | Tablas de paso a CSV; esquema, validación (`validar_tabla_larga()`) y escritura en Parquet de la tabla larga; diccionarios ES/EN (`exportar_i18n()`). Previsto: ficheros para la web |
| `web_estilo.R` | Kit de diseño: `tokens.css` desde `diseno/tokens.json`, contrastes WCAG y tipografías autoalojadas |

Convenciones: nombres en castellano y en `snake_case`; una función hace una cosa; las descargas guardan en `datos/brutos/` y no repiten si el fichero existe, salvo que se pida; los errores dicen qué falta y dónde conseguirlo. El código reaprovechado de proyectos anteriores lleva en la cabecera la fecha de incorporación.
