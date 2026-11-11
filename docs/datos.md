# Datos

Todas las cifras del atlas que han pasado la compuerta de validación están en un solo fichero: la tabla larga, en Parquet. Esta página dice qué trae, cómo se lee y con qué licencia se reutiliza. La versión inglesa, `docs/data.md`, es una traducción fiel de esta; las secciones «Valores de las columnas» y «Diccionario de indicadores» salen del inventario (`docs/datos_diccionario.md`).

## Descarga

<!-- descarga -->

La suma SHA-256 del fichero bajado debe coincidir con la de arriba:

```bash
sha256sum tabla_larga.parquet
```

En PowerShell:

```powershell
Get-FileHash tabla_larga.parquet -Algorithm SHA256
```

`version.json` da también la versión y el número de filas de cada fuente. El release reúne la tabla larga, los datos de la web y el mapa base, con las sumas de todos ellos en `SHA256SUMS`.

## Licencia y cita

- **Datos derivados, textos e inventario:** [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.es) (`LICENCIA_DATOS.md`). Quien los reutilice o los transforme cita la fuente y publica lo que derive de ellos con la misma licencia.
- **Código:** MIT (`LICENSE`).
- **Datos de origen:** mantienen las condiciones de cada fuente (`inventario/fuentes.csv`, columna `licencia`), que se cita también. Qué obliga cada una y qué se retira si alguna cambia: nota metodológica («Método»), §2.2 y §2.4.
- **Mapa base:** geometrías de las secciones censales de 2021 del INE.
- **Geometrías NUTS de Eurostat (GISCO)** del mapa europeo de sobrecarga, que el sitio publica como ficheros (`datos/sobrecarga/nuts_2021.geojson` y `datos/sobrecarga/nuts_2024.geojson`): no se rigen por CC BY-SA 4.0. Su uso es no comercial y lleva el aviso «© EuroGeographics para los límites administrativos»; el uso comercial exige una licencia de EuroGeographics.

Atribución de los datos: «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]».

Cita del atlas (`CITATION.cff`):

<!-- cita -->

## Cómo leerla

La tabla tiene millones de filas: conviene filtrarla al leerla, sin cargarla entera. Los dos ejemplos sacan el alquiler mediano por m² de la vivienda colectiva en los municipios en 2024 y muestran el de Madrid (`28079`).

### R

Con `arrow` y `dplyr`. La descarga:

```r
download.file("https://gastiaso.github.io/de-renta-en-renta/descargas/tabla_larga.parquet",
              "tabla_larga.parquet", mode = "wb")
```

La lectura:

```r
library(arrow)
library(dplyr)

alquiler <- open_dataset("tabla_larga.parquet") |>
  filter(indicador == "alquiler_m2", nivel == "municipio", anio == 2024,
         corte == "tipologia", grupo == "VC") |>
  select(geo_id, valor, estado) |>
  collect()

filter(alquiler, geo_id == "28079")
```

### Python

Con `pandas` y `pyarrow`. La descarga:

```python
from urllib.request import urlretrieve

urlretrieve("https://gastiaso.github.io/de-renta-en-renta/descargas/tabla_larga.parquet",
            "tabla_larga.parquet")
```

La lectura:

```python
import pandas as pd

alquiler = pd.read_parquet(
    "tabla_larga.parquet",
    columns=["geo_id", "valor", "estado"],
    filters=[("indicador", "==", "alquiler_m2"), ("nivel", "==", "municipio"), ("anio", "==", 2024),
             ("corte", "==", "tipologia"), ("grupo", "==", "VC")],
)

print(alquiler[alquiler["geo_id"] == "28079"])
```

## Modelo de datos

Una fila por territorio, año, indicador, desglose y fuente. La clave es `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo` y `fuente`.

| Columna | Tipo | Contenido |
|---|---|---|
| `geo_id` | texto (`string`) | Código del territorio, con los ceros a la izquierda. Sección censal: 10 cifras (provincia 2, municipio 3, distrito 2 y sección 3); España: `00`. |
| `nivel` | texto (`string`) | Escala del territorio. |
| `anio` | entero (`int32`) | Año de referencia. Las cifras que agrupan varias olas de una encuesta llevan la última; las de periodos de menos de un año, el de su mes, que va en `corte` y `grupo`. |
| `indicador` | texto (`string`) | Código del indicador. |
| `corte` | texto (`string`) | Variable del desglose (tenencia, edad, tipología de la vivienda…); `total` sin desglose. |
| `grupo` | texto (`string`) | Valor del desglose; `total` sin desglose. |
| `valor` | decimal (`double`) | Cifra con la precisión de la fuente, en la unidad del indicador; vacía si `estado` es `secreto` o `ausente`. |
| `estado` | texto (`string`) | `dato`, `estimado`, `secreto` o `ausente`. |
| `fuente` | texto (`string`) | Fuente de la cifra; `calculo_propio` en los derivados. |
| `geo_ref` | texto (`string`) | Seccionado de referencia (`2021`) de las cifras que salen de secciones; vacío en las que la fuente publica ya para provincias, comunidades o España. |
| `version` | texto (`string`) | Versión de la fuente: fecha del fichero de origen (AAAA-MM-DD). |

Para leerla:

- **Cortes.** Cada indicador tiene los suyos, y algunos no tienen filas `total`: el alquiler solo va por tipología de la vivienda (`corte` `tipologia`, con los cuartiles en `tipologia_p25` y `tipologia_p75`) y las viviendas turísticas, por mes de referencia (`corte` `mes`). Sin filtrar `corte` y `grupo` se mezclan desgloses.
- **Estados.** `estimado` marca las cifras de secciones que cambiaron de límites y hubo que repartir; `secreto`, las que la fuente no publica por secreto estadístico, y `ausente`, las que no existen.
- **Escalas.** Cada nivel lleva su propia cifra, la que publica la fuente en esa escala o la calculada con las de esa escala: las medianas y los índices no se agregan desde las secciones.
- **Geografía.** Las secciones de todos los años son las del Censo 2021: las series anteriores se reproyectan a ese seccionado (nota metodológica, en «Método»).
- **Fiabilidad del alquiler.** `contratos_alquiler`, `margen_alquiler_m2` y `margen_alquiler_mes` acompañan a las medianas del SERPAVI con el número de contratos y el margen aproximado de cada una.

## Qué trae este release

<!-- cobertura -->
