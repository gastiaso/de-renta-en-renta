# Datos

| Carpeta | En git | Contenido |
|---|---|---|
| `brutos/` | no | Ficheros tal como se descargan de la fuente (caché) |
| `intermedios/` | no | Resultados intermedios del pipeline |
| `portales/` | no | Capa de precios de oferta (solo con `PORTALES=TRUE`) |
| `publicados/` | sí | Derivados que han pasado la compuerta, en Parquet y CSV |

Nada se edita a mano: todo se regenera con `targets::tar_make()`. Límite de GitHub: 100 MB por fichero.
