# Data

Every figure of the atlas that has passed the validation gate is in a single file: the long table, in Parquet. This page describes what it contains, how to read it and under which licence it can be reused. It is a faithful translation of `docs/datos.md`; the sections «Column values» and «Indicator dictionary» are generated from the inventory (`docs/data_dictionary.md`).

## Download

<!-- descarga -->

The SHA-256 sum of the downloaded file must match the one above:

```bash
sha256sum tabla_larga.parquet
```

In PowerShell:

```powershell
Get-FileHash tabla_larga.parquet -Algorithm SHA256
```

`version.json` also gives the version and the number of rows of each source. The release bundles the long table, the site data and the base map, with the sums of all of them in `SHA256SUMS`.

## Licence and citation

- **Derived data, texts and inventory:** [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) (`LICENCIA_DATOS.md`). Anyone who reuses or transforms them cites the source and publishes what they derive under the same licence.
- **Code:** MIT (`LICENSE`).
- **Source data:** keep the terms of each source (`inventario/fuentes.csv`, column `licencia`), which is also cited.
- **Base map:** INE 2021 census tract geometries.
- **Eurostat NUTS geometries (GISCO)** of the European overburden map, which the site publishes as files (`datos/sobrecarga/nuts_2021.geojson` and `datos/sobrecarga/nuts_2024.geojson`): they are not covered by CC BY-SA 4.0. Their use is non-commercial and carries the notice «© EuroGeographics for the administrative boundaries»; commercial use requires a EuroGeographics licence.

Attribution of the data: «De renta en renta (Guillermo Astiaso Llamazares), based on [original source]».

Citation of the atlas (`CITATION.cff`):

<!-- cita -->

## How to read it

The table has millions of rows: it is best filtered while reading, without loading it whole. Both examples extract the median rent per m² of flats in the municipalities in 2024 and show the one for Madrid (`28079`).

### R

With `arrow` and `dplyr`. The download:

```r
download.file("https://gastiaso.github.io/de-renta-en-renta/descargas/tabla_larga.parquet",
              "tabla_larga.parquet", mode = "wb")
```

The reading:

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

With `pandas` and `pyarrow`. The download:

```python
from urllib.request import urlretrieve

urlretrieve("https://gastiaso.github.io/de-renta-en-renta/descargas/tabla_larga.parquet",
            "tabla_larga.parquet")
```

The reading:

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

## Data model

One row per area, year, indicator, breakdown and source. The key is `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo` and `fuente`.

| Column | Type | Content |
|---|---|---|
| `geo_id` | text (`string`) | Area code, with leading zeros. Census tract: 10 digits (province 2, municipality 3, district 2 and tract 3); Spain: `00`. |
| `nivel` | text (`string`) | Geographic level of the area. |
| `anio` | integer (`int32`) | Reference year. Figures that pool several survey waves carry the latest one; those for periods shorter than a year, the year of their month, which goes in `corte` and `grupo`. |
| `indicador` | text (`string`) | Indicator code. |
| `corte` | text (`string`) | Breakdown variable (tenure, age, dwelling type…); `total` without a breakdown. |
| `grupo` | text (`string`) | Breakdown value; `total` without a breakdown. |
| `valor` | decimal (`double`) | Figure with the precision of the source, in the unit of the indicator; empty when `estado` is `secreto` or `ausente`. |
| `estado` | text (`string`) | `dato`, `estimado`, `secreto` or `ausente`. |
| `fuente` | text (`string`) | Source of the figure; `calculo_propio` for derived figures. |
| `geo_ref` | text (`string`) | Reference tract map (`2021`) of the figures built from tracts; empty for those the source already publishes for provinces, autonomous communities or Spain. |
| `version` | text (`string`) | Source version: date of the source file (YYYY-MM-DD). |

To read it:

- **Breakdowns.** Each indicator has its own, and some have no `total` rows: rent only comes by dwelling type (`corte` `tipologia`, with the quartiles in `tipologia_p25` and `tipologia_p75`) and tourist dwellings, by reference month (`corte` `mes`). Without filtering `corte` and `grupo`, breakdowns get mixed.
- **Statuses.** `estimado` flags figures of tracts whose boundaries changed and had to be split; `secreto`, those the source withholds for statistical confidentiality, and `ausente`, those that do not exist.
- **Levels.** Each level carries its own figure, the one the source publishes at that level or the one computed from figures at that level: medians and indices are not aggregated from tracts.
- **Geography.** The tracts of every year are those of the 2021 Census: earlier series are carried to that tract map (methodological note, under «Method»).
- **Rent reliability.** `contratos_alquiler`, `margen_alquiler_m2` and `margen_alquiler_mes` accompany the SERPAVI medians with the number of contracts and the approximate margin of each one.

## What this release contains

<!-- cobertura -->
