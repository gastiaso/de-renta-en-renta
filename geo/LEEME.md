# Geografía

- `brutos/` (fuera de git): seccionados anuales del INE, callejero y edificios del Catastro.
- `tablas_paso/`: sección del año *t* → sección de referencia, con pesos por callejero (vía a) y por viviendas del Catastro (vía b). Ficheros pequeños: van en git.
- `referencia/`: geometría del seccionado de referencia simplificada por nivel de zoom.

Prueba de cierre: la población del padrón por sección reproyectada cuadra con los totales municipales publicados (±0,5 %). Los seccionados se descargan del INE (`ine_seccionado` en `inventario/fuentes.csv`).
