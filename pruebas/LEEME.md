# Pruebas

```r
testthat::test_dir("pruebas/testthat")
```

- `test-inventario.R`: identificadores únicos y referencias cruzadas entre fuentes, indicadores y validaciones.
- `test-utilidades.R`: códigos de sección, ceros a la izquierda y neto mensual (SMI de 2026).
- `test-pagina-datos.R`: página «Datos». El diccionario (con un inventario inventado), que `docs/datos_diccionario.md` y `docs/data_dictionary.md` están al día con el inventario (si no, `targets::tar_make()`), la paridad de `docs/datos.md` y `docs/data.md`, sus columnas, clave y tipos frente al esquema de la tabla larga, y sus ejemplos de lectura: el de R se ejecuta contra una tabla inventada; el de Python, también, si hay un Python con `pandas` y `pyarrow` (variable `PYTHON_PARQUET`; si no, se salta).

Pruebas de la web, sin navegador: `node --test pruebas/web/*.test.mjs` (`web/LEEME.md`).

Cada función nueva de `R/` llega con su prueba. Las comprobaciones contra cifras publicadas no van aquí sino en la compuerta (`inventario/referencias_validacion.csv`).
