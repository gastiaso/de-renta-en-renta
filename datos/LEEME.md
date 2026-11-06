# Datos

| Carpeta | En git | Contenido |
|---|---|---|
| `brutos/` | no | Ficheros tal como se descargan de la fuente (caché) |
| `intermedios/` | no | Resultados intermedios del pipeline |
| `portales/` | no | Capa de precios de oferta (solo con `PORTALES=TRUE`) |
| `publicados/` | sí | Derivados que han pasado la compuerta, en Parquet y CSV |

Nada se edita a mano: todo se regenera con `targets::tar_make()`. Límite de GitHub: 100 MB por fichero.

La tabla larga (`intermedios/tabla_larga.parquet`, por ahora solo la prueba de Madrid) tiene una fila por territorio, año e indicador: `geo_id | nivel | anio | indicador | valor | estado | fuente | geo_ref | version`. `estado` ∈ {`dato`, `estimado`, `secreto`, `ausente`}; `geo_ref` es el seccionado de referencia (2021). `validar_tabla_larga()` comprueba el esquema antes de escribirla. Pasará a `publicados/` cuando se decida publicar.
