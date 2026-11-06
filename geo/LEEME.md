# Geografía

- `brutos/` (fuera de git): seccionados anuales del INE, callejero y edificios del Catastro.
- `tablas_paso/`: sección del año *t* → sección de 2021, con pesos por callejero (vía a) y por viviendas del Catastro (vía b). Ficheros pequeños: van en git. Por ahora, la prueba de Madrid: `callejero_2015_2021_28.csv`, `callejero_2022_2021_28.csv` (prueba de un año) y `callejero_2025_2021_28.csv` (columnas `origen`, `destino`, `portales`, `metodo`, `fraccion`; las fracciones de cada origen suman 1).
- `ccaa.csv`: tabla fija de comunidades y ciudades autónomas: código del INE (01–19), nombre tal como lo escribe el INE en sus tablas y región NUTS 2.
- `referencia/`: geometría del seccionado de referencia, el del Censo 2021 (1 de enero de 2021), simplificada por nivel de zoom.

Prueba de cierre: la población del padrón por sección reproyectada cuadra con los totales municipales publicados (±0,5 %). Los seccionados se descargan del INE (`ine_seccionado` en `inventario/fuentes.csv`).
