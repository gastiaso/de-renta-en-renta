# Funciones del pipeline

`_targets.R` carga todos los `.R` de esta carpeta con `tar_source("R")`.

| Fichero | Contenido |
|---|---|
| `comun_utilidades.R` | Redondeo, códigos territoriales, neto mensual |
| `fuente_<id>.R` | Una fuente: `descargar_<id>()`, `leer_<id>()`, `armonizar_<id>()`. El `id` es el de `inventario/fuentes.csv` |
| `comun_geo.R` | Seccionado, tablas de paso, jerarquía territorial |
| `comun_validar.R` | Compuerta: `validar_referencias()` |
| `comun_exportar.R` | Tabla larga en Parquet y ficheros para la web |

Convenciones: nombres en castellano y en `snake_case`; una función hace una cosa; las descargas guardan en `datos/brutos/` y no repiten si el fichero existe, salvo que se pida; los errores dicen qué falta y dónde conseguirlo. El código reaprovechado de proyectos anteriores lleva en la cabecera la fecha de incorporación.
