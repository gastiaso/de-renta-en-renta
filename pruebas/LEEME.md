# Pruebas

```r
testthat::test_dir("pruebas/testthat")
```

- `test-inventario.R`: identificadores únicos y referencias cruzadas entre fuentes, indicadores y validaciones.
- `test-utilidades.R`: códigos de sección, ceros a la izquierda y neto mensual (SMI de 2026).
- `test-pagina-datos.R`: página «Datos». El diccionario (con un inventario inventado), que `docs/datos_diccionario.md` y `docs/data_dictionary.md` están al día con el inventario (si no, `targets::tar_make()`), la paridad de `docs/datos.md` y `docs/data.md`, sus columnas, clave y tipos frente al esquema de la tabla larga, y sus ejemplos de lectura: el de R se ejecuta contra una tabla inventada; el de Python, también, si hay un Python con `pandas` y `pyarrow` (variable `PYTHON_PARQUET`; si no, se salta).

- `test-zonas-tensionadas.R` y `test-portales.R` (F5): el indicador 20 con una resolución del BOE inventada, y la capa de portales con la muestra inventada de `pruebas/datos/portales_inventado.csv` (nunca en `datos/brutos/`): apagada, la web exportada es idéntica a la de sin capa; encendida, la capa sale aparte y con su etiqueta.
- `test-entrar.R` (tarea 37): los indicadores de «entrar» con una capa, un SERPAVI, unas fichas y un IPVA inventados: tramos de `inventario/entrar_tramos.csv` con su ancho mínimo, cálculo exacto y estados, compuerta y exportación del tramo de la brecha sin ninguna cifra exacta. Sus casos de `pruebas/datos/entrar_inventado.json` los comprueba también `pruebas/web/entrar.test.mjs`: así R y la página coinciden en el tramo, en los intervalos y en «¿te llega?».

Pruebas de la web, sin navegador: `node --test pruebas/web/*.test.mjs` (`web/LEEME.md`).

Cada función nueva de `R/` llega con su prueba. Las comprobaciones contra cifras publicadas no van aquí sino en la compuerta (`inventario/referencias_validacion.csv`).
