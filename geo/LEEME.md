# Geografía

- `brutos/` (fuera de git): seccionados anuales del INE, callejero y edificios del Catastro (estatal y forales).
- `tablas_paso/`: sección del año *t* → sección de 2021, con pesos por callejero (vía a) y por viviendas del Catastro (vía b). Ficheros pequeños: van en git. Toda España: `callejero_<año>_2021.csv`, una por seccionado (2016–2020 y 2022–2025; la de 2016 lleva el ADRH 2015 y la de 2022 es la prueba de un año), solo de la vía (a) (columnas `origen`, `destino`, `portales`, `metodo`, `fraccion`; las fracciones de cada origen suman 1). Las combinadas con el Catastro se quedan en el pipeline hasta aclarar su licencia.
- `ccaa.csv`: tabla fija de comunidades y ciudades autónomas: código del INE (01–19), nombre tal como lo escribe el INE en sus tablas y región NUTS 2.
- `referencia/`: geometría del seccionado de referencia, el del Censo 2021 (1 de enero de 2021), simplificada por nivel de zoom.

Prueba de cierre: la población del padrón por sección reproyectada cuadra, municipio a municipio, con la suma de sus secciones de origen (±0,5 %); otra comprobación (alerta) vigila que esas secciones sumen el total municipal publicado. Cobertura: toda sección de 2021 recibe algo de cada tabla. Los seccionados se descargan del INE (`ine_seccionado` en `inventario/fuentes.csv`).
