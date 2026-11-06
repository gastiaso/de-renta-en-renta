# Backlog de F0 · cimientos

Orden propuesto. Cada tarea termina con un criterio verificable. Lo que se decida en cada una se anota en el plan (`docs/plan_integracion_atlas.md`) o en `CHANGELOG.md`. Todo provisional.

## 0. Entorno y git · HECHA (6-nov-2026)

**Decisión:** R 4.6.1 con `renv` (`snapshot.type = "all"`: todo lo instalado en la biblioteca del proyecto queda en `renv.lock`). Git en `main`, sin remoto, primer commit hecho. `tar_make()` lee los tres CSV del inventario y las pruebas pasan.

- En Windows, desde la carpeta del proyecto: `git init -b main`. Sin remoto. Primer commit tras revisar `git status`.
- Paquetes de R: `targets`, `tarchetypes`, `httr2`, `readr`, `readxl`, `dplyr`, `arrow`, `sf`, `testthat`, `eurostat`, `giscoR`. Decidir si se usa `renv` (recomendable: el proyecto va a durar años).
- **Hecho cuando:** `targets::tar_make()` ejecuta el esqueleto (lee los dos CSV del inventario) y `testthat::test_dir("pruebas/testthat")` pasa.

## 1. SERPAVI por sección censal · HECHA (6-nov-2026)

**Decisión: (a) descarga directa.** El MIVAU publica la base de datos completa, 2011–2024, con una hoja por sección censal en el seccionado del Censo 2021 para toda la serie. Detalle en `inventario/fuentes.csv` (`mivau_serpavi`) y en el plan v0.4. Queda para F2: País Vasco antes de 2022/2024 (`gv_emal`) y Navarra antes de 2021.

- Comprobar si existe descarga reutilizable a escala de sección: años, variables (mediana, cuartiles, número de testigos, €/m², tipología), formato, licencia y cobertura.
- País Vasco: estadística de fianzas del Gobierno Vasco. Navarra: a confirmar.
- Precedente: el SERPAVI en PDF solo se ha podido transcribir **a mano**, y por comunidad. Hay una solicitud de acceso reutilizable en datos.gob.es (agosto de 2026). No consta descarga por sección.
- **Hecho cuando:** la fila `mivau_serpavi` de `inventario/fuentes.csv` está completa y hay una decisión anotada: (a) descarga directa; (b) solicitud formal al MIVAU, mientras se avanza con otra escala; (c) plan B a escala de municipio o distrito, con su efecto en la v0.1.

## 2. Nombre

- Comprobar «Casilla de salida» y «Square One»: repositorios en GitHub, dominios (.es, .org, .com) y marcas en la OEPM (clases 9, 35, 41 y 42).
- Evitar coincidencias con otros atlas de vivienda ya publicados.
- **Hecho cuando:** nombre decidido y anotado en el plan (§10). Hasta entonces, el repositorio de GitHub usa un nombre de trabajo neutro.

## 3. Comprobaciones pendientes del plan (§11) · HECHA (6-nov-2026)

**Resultado:** las tres, respondidas en `inventario/fuentes.csv` y en el plan v0.9. AEAT: tramo 26–35 confirmado; el módulo de «año completo» (desde 2019) es un salario anualizado por días cotizados y no hay mediana por comunidad y edad ni retención por edad, así que el método de la mochila se revisa (pregunta abierta 7). INSS: Excel mensual por provincia y clase; pensión bruta por paga (14 pagas), provincia de gestión. Eurostat: 204 regiones de 26 países en 2025; Francia, Austria y Países Bajos sin NUTS 2; NUTS 2021 hasta 2023 y NUTS 2024 desde 2024.

- **AEAT, Mercado de trabajo:** cortes de edad de las tablas por provincia; desde qué año existe el módulo de año completo (deciles por comunidad y edad); si publica la retención media por tramo.
- **INSS:** pensión media de jubilación por provincia: formato, serie y si hay descarga estable.
- **Eurostat, `ilc_lvho07_r`:** cobertura por país y años. España, hecho: las 19 comunidades, 2021–2025 (ES30 Madrid: 13,4 % en 2021, 11,2 % en 2024 y 9,9 % en 2025). Falta el resto de países.
- **Hecho cuando:** cada punto tiene respuesta en `inventario/fuentes.csv` (columnas `estado` y `notas`) y, si cambia algo del método, en el plan.

## 4. Inventario de fuentes · HECHA (6-nov-2026)

**Resultado:** ninguna fuente de la v0.0 ni de la v0.1 queda en «a confirmar» en acceso y licencia; siguen así las de fases posteriores o de referencia (valor tasado, Eustat y Nastat para el indicador 5, Idescat, Banco de España y la estadística de alquiler de Nastat). INE, Eurostat y Gobierno Vasco: CC BY 4.0; MIVAU, AEAT y Seguridad Social: reutilización citando fuente y fecha; GISCO: uso no comercial con aviso de EuroGeographics; Catastro: licencia contradictoria, por aclarar. Nueva fuente de referencia `nastat_epav` y ruptura `vut_calendario_2024`. Hallazgos que llevan a decisiones: preguntas abiertas 7 (mochila) y 8 (País Vasco y Navarra sin SERPAVI).

- Completar `inventario/fuentes.csv`: dirección estable, forma de acceso, licencia (con el texto citado), cadencia y desfase.
- **Hecho cuando:** ninguna fila de las fuentes de la v0.0 y la v0.1 queda en «a confirmar» en acceso y licencia.

## 5. F1b · primer paso: sobrecarga de España · HECHA (6-nov-2026)

**Resultado (ECV 2025):** España 7,17 % (Eurostat 7,2); inquilinos a precio de mercado 26,80 % (26,8); las 19 comunidades, dentro de ±0,05 puntos de `ilc_lvho07_r`. Las otras tenencias también cuadran (3,45 / 3,4; 1,87 / 1,9; 8,44 / 8,4). Código: `R/fuente_ine_ecv.R`, `R/fuente_eurostat_ilc_lvho07.R` y `R/comun_validar.R` (primera versión de `validar_referencias()`, adelantada de la tarea 7). Pendiente para F1b: intervalos de confianza y olas anteriores.

- Funciones `descargar_ine_ecv()` y `leer_ine_ecv()` para los microdatos de la ECV (última ola: 2025), reaprovechando código propio previo si lo hay.
- Calcular la tasa de sobrecarga con el método de Eurostat: personas; gastos de vivienda menos ayudas entre renta disponible menos ayudas, por encima del 40 %; de la hipoteca, solo los intereses.
- **Hecho cuando:** España total e inquilinos a precio de mercado coinciden con Eurostat en ±0,1 puntos (`referencias_validacion.csv`: `sobrecarga_es_total`, `sobrecarga_es_mercado`).

## 6. F1 · prueba de la geografía constante · HECHA (6-nov-2026)

**Resultado (Madrid):** tablas de paso 2015 → 2021 y 2025 → 2021 por el callejero, en `geo/tablas_paso/`. Prueba de cierre: desviación máxima 0,001 % (ADRH 2015 y 2024); ninguna sección sin tabla. La prueba es débil por construcción, así que se añade un diagnóstico sección a sección frente al ADRH 2020 (nativo en 2021): 63 y 26 atípicos, sobre todo en barrios en crecimiento. Geometría: de 2021 a 2025 cambian 252 de 4.417 secciones (5,7 %). Detalle en el plan v0.6, §6.3.

**Prueba de un año (2022 → 2021):** donde cada sección de origen cae entera en la de 2021 (89,5 % de las secciones), el error es el ruido de un año (94,6 % dentro de ±5 %); donde hay que repartir (10,5 %), no (66,5 %, con errores de hasta el doble). De ahí la regla de estado `dato` / `estimado` / `ausente`, adoptada e implementada (plan v0.7, §6.3). Medianas: se copia la del origen dominante (≥ 95 % de los portales) como `estimado`; contrastado con la edad media y el tamaño del hogar, se comporta como el caso 1:1 (plan v0.8). Pendiente: la vía (b), Catastro, en las secciones `estimado`.

- Referencia: el seccionado de 2021 (plan v0.5, §6.3). Con los seccionados de 2015, 2021 y 2025 del INE, construir las tablas de paso 2015 → 2021 (hacia delante: reparte) y 2025 → 2021 (hacia atrás: agrega) de **una provincia** (por ejemplo, Madrid, la que más secciones ha cambiado) por la vía del callejero.
- Medir con la geometría cuántas secciones de 2021 conservan el código pero cambian de límites.
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
