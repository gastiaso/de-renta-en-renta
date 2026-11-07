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

## 2. Nombre · HECHA (7-nov-2026)

**Comprobación hecha** (plan §10.1): «Casilla de salida» está libre en GitHub, dominios y marcas; «Square One» está ocupado en GitHub, dominios y con marcas vigentes en las clases 9, 35, 41 y 42. Antes de registrar nada: confirmar el .es en dominios.es y repetir la búsqueda en el localizador de la OEPM. La decisión es del autor.

**Decisión (7-nov-2026):** *De renta en renta*, sin traducir (plan, §10.1). Primera búsqueda sin coincidencias: ningún repositorio de GitHub ni web con ese nombre.

- Sin dominio propio (decisión del autor, 7-nov-2026): la web va en la dirección de GitHub Pages del repositorio `de-renta-en-renta`. Ya no hace falta comprobar dominios.
- Marcas: no se registran (decisión del autor, 7-nov-2026): el proyecto es abierto y no comercial. La búsqueda previa en TMview y en la OEPM no encontró la frase (plan §10.1).
- Evitar coincidencias con otros atlas de vivienda ya publicados.
- **Hecho cuando:** las comprobaciones de *De renta en renta* están anotadas en el plan (§10.1). Si alguna choca, se vuelve a la lista de §10.1.

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

**Prueba de un año (2022 → 2021):** donde cada sección de origen cae entera en la de 2021 (89,5 % de las secciones), el error es el ruido de un año (94,6 % dentro de ±5 %); donde hay que repartir (10,5 %), no (66,5 %, con errores de hasta el doble). De ahí la regla de estado `dato` / `estimado` / `ausente`, adoptada e implementada (plan v0.7, §6.3). Medianas: se copia la del origen dominante (≥ 95 % de los portales) como `estimado`; contrastado con la edad media y el tamaño del hogar, se comporta como el caso 1:1 (plan v0.8).

**Vía (b), Catastro (7-nov-2026):** en las 558 secciones `estimado` por el callejero (2024 → 2021), los errores de más del 20 % bajan de 128 a 27 y las secciones dentro de ±5 %, del 33 al 54 %; en las demás, igual. Adoptado el 7-nov-2026: callejero donde las secciones caen enteras y Catastro donde hay que repartir, con los edificios filtrados por año de construcción y sin cruzar municipios (plan v0.10, §6.3). En Madrid, las cifras `estimado` de la renta bajan de 1.536 a 326 en 2024, de 2.095 a 571 en 2015 y de 1.218 a 63 en 2021. Prueba de un año de la vía (b) (2022 → 2021): en las 465 secciones que el callejero reparte, las que quedan dentro de ±5 % pasan del 66,5 al 92,5 % y los errores de más del 20 %, de 50 a 7, igual que el ruido de un año en las secciones que caen enteras. El mapa de 2022 dibuja dos secciones fuera de fase con el callejero y el ADRH: sus edificios pasan al origen de los datos, y la nueva compuerta `cobertura_destino` comprueba que ninguna sección de 2021 se quede vacía (plan v0.11). Con los callejeros y seccionados de 2017–2020, 2023 y 2024 (7-nov-2026), nueve tablas de paso: todos los años del ADRH en el seccionado de 2021 (plan v0.12). Pendiente: la licencia del Catastro.

**Toda España (7-nov-2026):** las nueve tablas de paso para las 52 provincias, con el Catastro en 1.420 municipios (País Vasco y Navarra, por el callejero), fusiones y segregaciones de municipios, y el Catastro también donde el callejero no llega. Cierre y cobertura pasan todos los años, con nueve secciones huérfanas del ADRH y dos excepciones de cobertura documentadas (plan v0.16, §6.3). Pendiente: los catastros forales.

- Referencia: el seccionado de 2021 (plan v0.5, §6.3). Con los seccionados de 2015, 2021 y 2025 del INE, construir las tablas de paso 2015 → 2021 (hacia delante: reparte) y 2025 → 2021 (hacia atrás: agrega) de **una provincia** (por ejemplo, Madrid, la que más secciones ha cambiado) por la vía del callejero.
- Medir con la geometría cuántas secciones de 2021 conservan el código pero cambian de límites.
- **Hecho cuando:** la prueba de cierre poblacional queda dentro de ±0,5 %, o hay un diagnóstico de por qué no y de qué cambia en el plan.

## 7. Esqueleto del pipeline · HECHA (6-nov-2026)

**Resultado (Madrid):** los indicadores 1–3 (renta del ADRH) recorren el pipeline de punta a punta: descarga → lectura → compuerta → paso al seccionado de 2021 con estado → tabla larga validada (`validar_tabla_larga()`) → Parquet en `datos/intermedios/tabla_larga.parquet` (58.193 filas). Compuerta en dos niveles: `adrh_municipio` (bloqueo, mediana de la desviación; pasa con ≤ 0,011 %) y `adrh_municipio_detalle` (alerta por municipio: avisa en 12, por encima del 5 % solo en tres municipios de renta muy alta). Años en 2021: todos los del ADRH, 2015–2024 (2020 nativo; el resto con su tabla de paso combinada, desde el 7-nov-2026).

- `_targets.R`: fuentes → descarga → lectura → armonizado → validación → exportación.
- `validar_referencias()`: lee `inventario/referencias_validacion.csv`, para en los `bloqueo` y avisa en los `alerta`.
- Esquema de la tabla larga en Parquet.
- **Hecho cuando:** un indicador de prueba (por ejemplo, la renta media por hogar del ADRH de una provincia) recorre el pipeline de punta a punta y pasa su comprobación.

## 8. Fichas de indicador · HECHA (7-nov-2026)

**Resultado:** los 23 indicadores tienen nombre, unidad, definición, cálculo y lectura en castellano e inglés en `inventario/indicadores.csv`; la prueba `test-inventario.R` exige que no falte ninguno. Fuentes, nivel y serie ya estaban. Quedan a la espera de decisiones: el método de la mochila (indicador 7 y ficha «joven», pregunta abierta 7) y el umbral del indicador 5 (confirmar en la metodología del ADRH). Los textos son borradores para revisar.

- Completar `inventario/indicadores.csv` para los 23 indicadores, en castellano e inglés: definición, cálculo, lectura, unidad, fuentes, nivel, serie.
- **Hecho cuando:** cada indicador tiene su ficha completa en los dos idiomas.

## 9. Kit de diseño a CSS · HECHA (7-nov-2026)

**Resultado:** `web/estilo/tokens.css` generado desde `diseno/tokens.json` (`generar_tokens_css()`), con las cuatro tipografías autoalojadas en `web/estilo/fuentes/` (woff2 latino, 78 KB en total, con su licencia). Compuertas: `contraste_texto` (13 de 13 pares de texto por encima de 4,5:1, recalculados con la fórmula WCAG), `contraste_declarado` (lo de `tokens.json` cuadra con lo recalculado) y `rampa_contorno` (los tramos 1 y 2, por debajo de 3:1, llevan contorno). Corrección: Yellowtail tiene licencia Apache 2.0, no OFL.

- `web/estilo/tokens.css` a partir de `diseno/tokens.json`; tipografías autoalojadas.
- **Hecho cuando:** los contrastes de texto cumplen 4,5:1 y los dos tramos claros de la rampa llevan siempre contorno.

## 10. Diccionario i18n base · HECHA (7-nov-2026)

**Resultado:** `exportar_i18n()` vuelca en `web/i18n/es.json` y `en.json` las fichas de los 23 indicadores, los nombres de las 27 fuentes (`nombre_en` nuevo en `fuentes.csv`) y el vocabulario de la web (`inventario/vocabulario.csv`: familias, niveles, estados y fiabilidad), conservando las secciones escritas a mano. Compuerta `i18n_completo`: mismas claves en los dos idiomas y ningún texto vacío.

- Ampliar `web/i18n/es.json` y `en.json` con las etiquetas de los 23 indicadores y de las fuentes.
- **Hecho cuando:** ninguna etiqueta visible de la v0.0 queda sin traducir.

## Cierre de F0 (del plan)

Cada fuente tiene una función de R de descarga reproducible y cada indicador, su ficha completa en castellano e inglés.
