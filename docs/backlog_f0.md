# Backlog de F0 · cimientos

Orden propuesto. Cada tarea termina con un criterio verificable. Lo que se decida en cada una se anota en el plan (`docs/plan_integracion_atlas.md`) o en `CHANGELOG.md`. Todo provisional.

## 0. Entorno y git

- En Windows, desde la carpeta del proyecto: `git init -b main`. Sin remoto. Primer commit tras revisar `git status`.
- Paquetes de R: `targets`, `tarchetypes`, `httr2`, `readr`, `readxl`, `dplyr`, `arrow`, `sf`, `testthat`, `eurostat`, `giscoR`. Decidir si se usa `renv` (recomendable: el proyecto va a durar años).
- **Hecho cuando:** `targets::tar_make()` ejecuta el esqueleto (lee los dos CSV del inventario) y `testthat::test_dir("pruebas/testthat")` pasa.

## 1. SERPAVI por sección censal · BLOQUEANTE

- Comprobar si existe descarga reutilizable a escala de sección: años, variables (mediana, cuartiles, número de testigos, €/m², tipología), formato, licencia y cobertura.
- País Vasco: estadística de fianzas del Gobierno Vasco. Navarra: a confirmar.
- Precedente: el SERPAVI en PDF solo se ha podido transcribir **a mano**, y por comunidad. Hay una solicitud de acceso reutilizable en datos.gob.es (agosto de 2026). No consta descarga por sección.
- **Hecho cuando:** la fila `mivau_serpavi` de `inventario/fuentes.csv` está completa y hay una decisión anotada: (a) descarga directa; (b) solicitud formal al MIVAU, mientras se avanza con otra escala; (c) plan B a escala de municipio o distrito, con su efecto en la v0.1.

## 2. Nombre

- Comprobar «Casilla de salida» y «Square One»: repositorios en GitHub, dominios (.es, .org, .com) y marcas en la OEPM (clases 9, 35, 41 y 42).
- Evitar coincidencias con otros atlas de vivienda ya publicados.
- **Hecho cuando:** nombre decidido y anotado en el plan (§10). Hasta entonces, el repositorio de GitHub usa un nombre de trabajo neutro.

## 3. Comprobaciones pendientes del plan (§11)

- **AEAT, Mercado de trabajo:** cortes de edad de las tablas por provincia; desde qué año existe el módulo de año completo (deciles por comunidad y edad); si publica la retención media por tramo.
- **INSS:** pensión media de jubilación por provincia: formato, serie y si hay descarga estable.
- **Eurostat, `ilc_lvho07_r`:** cobertura por país y años (las regiones españolas están comprobadas para 2021–2024; ES30 Madrid: 13,4 % en 2021 y 11,2 % en 2024).
- **Hecho cuando:** cada punto tiene respuesta en `inventario/fuentes.csv` (columnas `estado` y `notas`) y, si cambia algo del método, en el plan.

## 4. Inventario de fuentes

- Completar `inventario/fuentes.csv`: dirección estable, forma de acceso, licencia (con el texto citado), cadencia y desfase.
- **Hecho cuando:** ninguna fila de las fuentes de la v0.0 y la v0.1 queda en «a confirmar» en acceso y licencia.

## 5. F1b · primer paso: sobrecarga de España

- Funciones `descargar_ine_ecv()` y `leer_ine_ecv()` para los microdatos de la ECV (última ola: 2025), reaprovechando código propio previo si lo hay.
- Calcular la tasa de sobrecarga con el método de Eurostat: personas; gastos de vivienda menos ayudas entre renta disponible menos ayudas, por encima del 40 %; de la hipoteca, solo los intereses.
- **Hecho cuando:** España total e inquilinos a precio de mercado coinciden con Eurostat en ±0,1 puntos (`referencias_validacion.csv`: `sobrecarga_es_total`, `sobrecarga_es_mercado`).

## 6. F1 · prueba de la geografía constante

- Con los seccionados de 2015 y 2025 del INE, construir la tabla de paso de **una provincia** (por ejemplo, Madrid) por la vía del callejero.
- **Hecho cuando:** la prueba de cierre poblacional queda dentro de ±0,5 %, o hay un diagnóstico de por qué no y de qué cambia en el plan.

## 7. Esqueleto del pipeline

- `_targets.R`: fuentes → descarga → lectura → armonizado → validación → exportación.
- `validar_referencias()`: lee `inventario/referencias_validacion.csv`, para en los `bloqueo` y avisa en los `alerta`.
- Esquema de la tabla larga en Parquet.
- **Hecho cuando:** un indicador de prueba (por ejemplo, la renta media por hogar del ADRH de una provincia) recorre el pipeline de punta a punta y pasa su comprobación.

## 8. Fichas de indicador

- Completar `inventario/indicadores.csv` para los 23 indicadores, en castellano e inglés: definición, cálculo, lectura, unidad, fuentes, nivel, serie.
- **Hecho cuando:** cada indicador tiene su ficha completa en los dos idiomas.

## 9. Kit de diseño a CSS

- `web/estilo/tokens.css` a partir de `diseno/tokens.json`; tipografías autoalojadas.
- **Hecho cuando:** los contrastes de texto cumplen 4,5:1 y los dos tramos claros de la rampa llevan siempre contorno.

## 10. Diccionario i18n base

- Ampliar `web/i18n/es.json` y `en.json` con las etiquetas de los 23 indicadores y de las fuentes.
- **Hecho cuando:** ninguna etiqueta visible de la v0.0 queda sin traducir.

## Cierre de F0 (del plan)

Cada fuente tiene una función de R de descarga reproducible y cada indicador, su ficha completa en castellano e inglés.
