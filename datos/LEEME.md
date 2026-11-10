# Datos

| Carpeta | En git | Contenido |
|---|---|---|
| `brutos/` | no | Ficheros tal como se descargan de la fuente (caché) |
| `intermedios/` | no | Resultados intermedios del pipeline |
| `portales/` | no | Reservada para la capa de precios de oferta; hoy sus ficheros van en `brutos/portales/` (la extracción de Idealista, en `brutos/portales/idealista/`; solo con `PORTALES=TRUE`) |
| `publicados/` | sí | Derivados que han pasado la compuerta, en Parquet y CSV |

Nada se edita a mano: todo se regenera con `targets::tar_make()`. Límite de GitHub: 100 MB por fichero.

La tabla larga (`intermedios/tabla_larga.parquet`: por ahora, la renta de Madrid por sección y municipio y los indicadores 22 y 23 de España y sus comunidades) tiene una fila por territorio, año e indicador: `geo_id | nivel | anio | indicador | valor | estado | fuente | geo_ref | version`. `estado` ∈ {`dato`, `estimado`, `secreto`, `ausente`}; `geo_ref` es el seccionado de referencia (2021) y queda vacío en los niveles de comunidad y nacional («00»). `validar_tabla_larga()` comprueba el esquema antes de escribirla. Pasará a `publicados/` cuando se decida publicar.

Sobrecarga (F1b), en `intermedios/sobrecarga/`: `espana_anual.csv` (cada ola, por total, tenencia, edad y comunidad), `espana_agrupada.csv` (comunidad × tenencia y × edad con las olas agrupadas, con número de observaciones y fiabilidad) y `escalera_<año>.csv`.
