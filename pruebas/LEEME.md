# Pruebas

```r
testthat::test_dir("pruebas/testthat")
```

- `test-inventario.R`: identificadores únicos y referencias cruzadas entre fuentes, indicadores y validaciones.
- `test-utilidades.R`: códigos de sección, ceros a la izquierda y neto mensual (SMI de 2026).
- `test-pagina-datos.R`: página «Datos». El diccionario (con un inventario inventado), que `docs/datos_diccionario.md` y `docs/data_dictionary.md` están al día con el inventario (si no, `targets::tar_make()`), la paridad de `docs/datos.md` y `docs/data.md`, sus columnas, clave y tipos frente al esquema de la tabla larga, y sus ejemplos de lectura: el de R se ejecuta contra una tabla inventada; el de Python, también, si hay un Python con `pandas` y `pyarrow` (variable `PYTHON_PARQUET`; si no, se salta).

- `test-zonas-tensionadas.R` y `test-portales.R` (F5): el indicador 20 con una resolución del BOE inventada, y la capa de portales con la muestra inventada de `pruebas/datos/portales_inventado.csv` (nunca en `datos/brutos/`): apagada, la web exportada es idéntica a la de sin capa; encendida, la capa sale aparte y con su etiqueta.
- `test-registradores.R` (tarea 46): el indicador 11 con un CSV inventado del formato de los datos abiertos de Registradores (`pruebas/datos/registradores_inventado.csv`): lectura, año (cuarto trimestre), tabla larga, compuerta, coherencia con el valor tasado y la parada sin el fichero manual.
- `test-entrar.R` (tarea 37): los indicadores de «entrar» con una capa, un SERPAVI, unas fichas y un IPVA inventados: tramos de `inventario/entrar_tramos.csv` con su ancho mínimo, cálculo exacto y estados, compuerta y exportación del tramo de la brecha sin ninguna cifra exacta. Sus casos de `pruebas/datos/entrar_inventado.json` los comprueba también `pruebas/web/entrar.test.mjs`: así R y la página coinciden en el tramo, en los intervalos y en «¿te llega?».
- `test-paso2011.R` (tarea 47): la tabla de paso desde el Censo 2011 con datos inventados: lectura de los indicadores por sección (secreto en NA), casado de las comunidades y provincias de sus tablas (también las de una provincia), municipios descasados entre el mapa y el callejero, tabla combinada (fuera los códigos que no están en el Censo; el Catastro decide en los descasados) y el 18 de 2011 y el 19 de 2020–2023 en el seccionado de 2021 con sus estados.
- `test-serpavi-universo.R` (tarea 42): el contraste del SERPAVI con el Censo 2021 con datos inventados: suma de las dos tipologías, solo secciones con las dos cifras (fuera el País Vasco y las del Censo en secreto), provincias de menor a mayor cobertura y municipios con todas sus secciones y un mínimo de hogares.
- `test-ipc.R` (tarea 45): lectura de un CSV inventado con el formato de la tabla 76144 del INE (índice general, media anual y variación; otros grupos fuera), parada con una serie cortada, compuerta `ipc_*` e ida y vuelta de `datos/ipc.json`.

Pruebas de la web de las tareas 43 y 45: `pruebas/web/evolucion.test.mjs` (variaciones con la regla de los contratos, que nunca dan una variación de un año sin aviso con pocos contratos; banda del margen; geometría del gráfico; aviso de euros corrientes con el IPC; tabla de la evolución y textos en los dos idiomas).

Pruebas de la web, sin navegador: `node --test pruebas/web/*.test.mjs` (`web/LEEME.md`).

Cada función nueva de `R/` llega con su prueba. Las comprobaciones contra cifras publicadas no van aquí sino en la compuerta (`inventario/referencias_validacion.csv`).
