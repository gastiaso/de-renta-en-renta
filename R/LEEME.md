# Funciones del pipeline

`_targets.R` carga todos los `.R` de esta carpeta con `tar_source("R")`.

| Fichero | Contenido |
|---|---|
| `comun_utilidades.R` | Redondeo, códigos territoriales, neto mensual |
| `comun_descargar.R` | `descargar_con_cache()`: descarga a `datos/brutos/`, no repite y conserva la versión anterior si falla |
| `comun_validar.R` | Compuerta: `leer_tolerancia()` y `validar_referencias()` |
| `fuente_<id>.R` | Una fuente: `descargar_<id>()`, `leer_<id>()`, `armonizar_<id>()`. El `id` es el de `inventario/fuentes.csv` |
| `fuente_ine_ecv.R` | ECV: descarga, extracción y lectura de los microdatos; sobrecarga con el método de Eurostat y su comparación con Eurostat |
| `fuente_eurostat_ilc_lvho07.R` | Eurostat: sobrecarga publicada (`ilc_lvho07a`, `ilc_lvho07c`, `ilc_lvho07_r`) |
| `fuente_ine_seccionado.R` | Cartografía de secciones del INE: descarga y lectura de una provincia dentro del zip |
| `fuente_ine_callejero.R` | Callejero del censo electoral: descarga y lectura de los tramos de una provincia (aplicaciones antigua y nueva) |
| `fuente_ine_adrh.R` | ADRH: descarga de tablas de INEbase y lectura de los indicadores demográficos |
| `comun_geo.R` | Tablas de paso por el callejero, estado de lo reproyectado (`dato`, `estimado`, `ausente`), reproyección de recuentos, medias ponderadas y medianas, prueba de cierre, diagnóstico y cambios de límites. Previsto: jerarquía territorial y vía (b), Catastro |
| `comun_exportar.R` | Tablas de paso a CSV. Previsto: tabla larga en Parquet y ficheros para la web |

Convenciones: nombres en castellano y en `snake_case`; una función hace una cosa; las descargas guardan en `datos/brutos/` y no repiten si el fichero existe, salvo que se pida; los errores dicen qué falta y dónde conseguirlo. El código reaprovechado de proyectos anteriores lleva en la cabecera la fecha de incorporación.
