# Visor de comprobación del mapa base

Página mínima (MapLibre GL JS y PMTiles, cargados de unpkg con versión fija) para ver en local el mapa base del seccionado de referencia (2021): secciones, municipios, provincias y comunidades. No es la web del atlas (`web/`).

## Generar el mapa base

En R, desde la carpeta del proyecto:

```r
targets::tar_make(names = c(ficheros_jerarquia, fichero_mapa_base, validacion_mapa_base))
targets::tar_read(resumen_mapa_base)   # teselas y bytes por nivel de zoom
```

Escribe:

- `geo/jerarquia_2021.csv` y `geo/territorios_2021.csv`, en git;
- `geo/referencia/mapa_base_2021.pmtiles`, fuera de git (`*.pmtiles` en `.gitignore`).

Con `PROVINCIA=28` (variable de entorno, antes de `tar_make()`), los ficheros llevan `_28` en el nombre.

Las teselas se hacen con GDAL (controlador PMTiles, el que trae `sf`), sin tippecanoe. Funciones en `R/geo_mapa_base.R`.

## Ver el mapa

Hay dos formas:

1. **Con servidor local.** El PMTiles se lee por rangos HTTP, que `python -m http.server` no atiende. `servir.mjs` solo necesita Node:

   ```bash
   node geo/visor/servir.mjs
   ```

   Después se abre <http://localhost:8765/geo/visor/>. Otro fichero de la carpeta del proyecto: `?pmtiles=/geo/referencia/<fichero>.pmtiles`. La vista va en el enlace (`#zoom/latitud/longitud`).

2. **Sin servidor.** Se abre `geo/visor/index.html` con doble clic y se elige el `.pmtiles` en el selector del panel. Necesita conexión para cargar MapLibre y PMTiles.

Al pasar el cursor, el panel inferior muestra la sección, el distrito, el municipio y la provincia. Los colores solo distinguen secciones vecinas: no son datos.
