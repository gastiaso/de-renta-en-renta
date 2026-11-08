# Nota metodológica

*De renta en renta · v0.1, borrador · 8 de noviembre de 2026 · conforme al plan v0.21.*

Esta nota describe cómo se obtienen las cifras del atlas: fuentes, geografía constante, jerarquía territorial y mapa base, compuerta de validación, indicadores de la v0.1 e ingresos de las fichas. La versión inglesa, `docs/methodology.md`, es una traducción fiel de esta.

## 0. Cómo se cita cada cifra

- **Trazabilidad.** Cada cifra lleva entre paréntesis su origen. Puede ser:
  - un objetivo del pipeline, que se lee con `targets::tar_read(<objetivo>)`;
  - una función de `R/`;
  - un fichero de `inventario/`;
  - una sección del plan (`docs/plan_integracion_atlas.md`, «plan §»).
- **Objetivos repetidos.** Los que terminan en `_<seccionado>` se repiten una vez por seccionado de origen, según `PASOS_2021` en `_targets.R`. Por ejemplo, `paso_final_2016` lleva el ADRH 2015.
- **Almacén de referencia.** Las cifras sin otra indicación salen del almacén de `targets` del 8-nov-2026, con toda España. El objetivo `tabla_larga` es de las 11:43, ya con los derivados; `validacion_derivados`, de las 11:50.
- **Decisiones.** Las preguntas abiertas que el plan ya ha cerrado se citan como «plan §11, pregunta *n*».
- **Pendiente.** Así se marca lo que el pipeline no calcula todavía.
- **Formato.** Las cifras usan punto de miles y coma decimal. El redondeo a un decimal se hace con `redondear_1()`, que usa `sprintf("%.1f")`: `round()` redondea al par en los empates.

---

## 1. Pregunta rectora y alcance

**Pregunta.** Dónde, desde cuándo y para quién se ha roto la relación entre lo que cuesta vivir y la capacidad de pago (plan §1).

**Público.** Principal: periodistas de datos y técnicos de administraciones y entidades. Secundario: capa ciudadana.

**Escala y periodo.** Sección censal, de 2015 al último dato disponible. Todas las series se dibujan en el seccionado del Censo 2021 (§3).

**Dos familias de indicadores** (plan §3):
- **Esfuerzo de residentes:** renta de quien ya vive en la sección frente al alquiler de esa sección.
- **Barrera de acceso:** alquiler de la sección frente a un ingreso de referencia («fichas», §6).

La segunda familia corrige un sesgo de la primera: los barrios caros parecen asequibles porque los habita población con más renta.

**Escalonado** (plan §2.3):

| Versión | Contenido | Estado del cálculo (8-nov-2026) |
|---|---|---|
| v0.0 | Indicadores 22 (sobrecarga por gastos de vivienda, método Eurostat) y 23 (búsqueda de vivienda sin éxito) | En la tabla larga: 261 y 32 filas (`tabla_larga`, fuentes `ine_ecv` e `ine_ecv_modulo`) |
| v0.1 | Núcleo de 10 indicadores: 1–3, 8, 9, 14, 15, 18, 19 y 21 | Los 10, en la tabla larga; la barrera (15), solo con la mochila y la tartera de 2024 (§7.4) |
| v1.0 | Los 23 indicadores del catálogo (plan §5) | — |

**Núcleo de la v0.1** (`inventario/indicadores.csv`, columna `nucleo_v01`):

| # | Indicador | Fuente | Nivel nativo | Serie | Estado |
|---|---|---|---|---|---|
| 1 | Renta neta media por persona | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 2 | Renta neta media por hogar | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 3 | Mediana de la renta por unidad de consumo | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 8 | Alquiler mensual (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Calculado (`larga_serpavi`) |
| 9 | Alquiler por m² (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Calculado (`larga_serpavi`) |
| 14 | Esfuerzo de residentes en alquiler | SERPAVI y ADRH | Sección | 2015–2024 | Calculado (`larga_derivados`) |
| 15 | Barrera de acceso al alquiler | SERPAVI e ingreso de cada ficha | Sección × ingreso | 2015–2024 | Control en `larga_derivados` (mochila y tartera, 2024); la web la calcula con cada ficha |
| 18 | Hogares en alquiler | INE, Censo 2021 | Sección (seccionado de 2021) | 2021 (2011, en F6) | Calculado (`larga_censo2021`) |
| 19 | Viviendas de uso turístico | INE, estadística experimental | Sección (seccionado de 2024, llevado al de 2021) | Febrero de 2024 – mayo de 2026, semestral (2020–2023, en F6) | Calculado (`larga_vut`) |
| 21 | Sueldo neto necesario (mapa por defecto) | SERPAVI | Sección | 2015–2024 | Calculado (`larga_derivados`) |

**Tipología del alquiler** (plan §11, pregunta 12). El SERPAVI no publica una mediana conjunta de la vivienda colectiva y la unifamiliar. El mapa de alquiler usa por defecto la vivienda colectiva, que reúne el 88,9 % de los testigos en 2024: 2.271.987 frente a 284.591 (`serpavi`, hoja de comunidades). La unifamiliar es una opción, y las dos no se mezclan en un mismo mapa. Los derivados (14, 15 y 21) se calculan con la colectiva.

**Indicador 7.** El salario provincial de la AEAT se adelanta en versión mínima. El indicador 15 lo necesita a través de la ficha «mochila» (plan §7, F2). La mochila ya está calculada para 2024 (`mochila_neta`, §6.2).

**Desfase.** El atlas va uno o dos años por detrás en renta y salarios. El ADRH tiene un desfase de unos 22 meses: el de 2024 se publicó el 19-oct-2026. *Mercado de trabajo y pensiones* de la AEAT tiene uno de unos 11 meses (plan §8).

---

## 2. Fuentes y licencias

### 2.1 Fuentes que usa la v0.1

El inventario completo, con dirección, acceso, cadencia y notas, está en `inventario/fuentes.csv`. La columna `licencia` cita el texto de cada fuente.

| Fuente (`id`) | Organismo | Uso | Licencia (resumen de `fuentes.csv`) |
|---|---|---|---|
| `ine_adrh` | INE | Indicadores 1–3; población y hogares de las pruebas de la geografía; nombres de municipio | CC BY 4.0 |
| `mivau_serpavi` | MIVAU | Indicadores 8, 9, 14, 15 y 21 | Reutilización autorizada por el aviso legal del MIVAU (Ley 37/2007 y RD 1495/2011), citando la fuente y la fecha, sin desnaturalizar la información |
| `ine_censo2021` | INE | Indicador 18; denominador del 19 | CC BY 4.0 |
| `ine_vut` | INE | Indicador 19 | CC BY 4.0 |
| `aeat_mercado_trabajo` | AEAT | Ficha «mochila» (indicador 7) | Reutilización libre, también comercial, citando la fuente y la fecha de última actualización |
| `boe_smi` | BOE | Ficha «tartera» | Reutilizable |
| `ine_ecv` | INE | Control de la mochila; indicador 22 | CC BY 4.0 |
| `ine_ecv_modulo` | INE | Indicador 23 | CC BY 4.0 |
| `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r` | Eurostat | Compuerta del indicador 22 | CC BY 4.0 |
| `eurostat_nuts` | Eurostat (GISCO) | Geometrías del mapa europeo | Uso no comercial con el aviso «© EuroGeographics para los límites administrativos». No es CC BY |
| `ine_seccionado` | INE | Seccionados de 2016 a 2025; jerarquía territorial y mapa base | CC BY 4.0 |
| `ine_callejero` | INE | Tablas de paso, vía (a) | CC BY 4.0 |
| `catastro_inspire` | D. G. del Catastro | Tablas de paso, vía (b) | Contradictoria: ver abajo |
| `catastro_foral` | Diputaciones forales de Álava, Bizkaia y Gipuzkoa; Gobierno de Navarra | Vía (b) en País Vasco y Navarra | Distinta en cada territorio: ver abajo |
| `gv_emal` | Gobierno Vasco | Capa municipal de contexto (fianzas); no se mezcla con el indicador 8 | CC BY 4.0 |
| `calculo_propio` | De renta en renta | Indicadores derivados 14, 15 y 21, a partir de las fuentes de cada término | CC BY-SA 4.0 |

**Descarga manual del SERPAVI.** La web del MIVAU bloquea las descargas automáticas. Si falta el Excel, `descargar_mivau_serpavi()` detiene el pipeline e indica la página y el nombre con el que guardarlo (`inventario/fuentes.csv`, columna `acceso`).

### 2.2 Licencias contradictorias

**Catastro estatal.** Las fuentes oficiales no coinciden:
- los metadatos de la IDEE dicen CC BY 4.0;
- la página INSPIRE del Catastro enlaza una licencia de 2016 que exige transformar los datos antes de difundirlos;
- el feed ATOM general dice «all rights reserved»;
- los feeds de edificios de cada provincia permiten el uso gratuito citando a la D. G. del Catastro como autora y propietaria.

**Catastros forales:**
- Álava y Navarra: CC BY 4.0, sin contradicciones.
- Bizkaia: CC BY 3.0 ES con condiciones de la Ley 37/2007; las entradas municipales de su feed dicen «all rights reserved».
- Gipuzkoa: solo atribución en el WFS y CC BY-SA 4.0 en los metadatos y en el feed.

(`inventario/fuentes.csv`; plan §6.3.)

### 2.3 Licencia de los derivados

**Decisión del autor (8-nov-2026):** las fuentes se tratan como datos abiertos. Los datos derivados, los textos y el inventario se publican con licencia CC BY-SA 4.0 (`LICENCIA_DATOS.md`; plan §6.1). Hasta esa fecha, la licencia era CC BY 4.0.

CompartirIgual admite las fuentes con licencia CC BY y las que piden compartir igual, como Gipuzkoa. A cambio, quien reutilice los derivados debe publicar lo suyo con la misma licencia.

**Qué incluye:**
- Desde esa fecha, las tablas de paso combinadas con el Catastro se versionan en `geo/tablas_paso/combinada_<año>_2021.csv` (objetivo `fichero_paso_final_<seccionado>`).
- La jerarquía territorial (`geo/jerarquia_2021.csv`, `geo/territorios_2021.csv`) y el mapa base en PMTiles derivan del seccionado del INE y llevan la misma licencia. El PMTiles no entra en git: se publica desde un *release* del repositorio (§3.10).

**Excepciones:**
- Las geometrías NUTS de GISCO quedan fuera de la licencia de los derivados.
- La capa de precios de oferta de los portales no se redistribuye y está apagada por defecto (`PORTALES=FALSE`; plan §2.2).
- Las bibliotecas de la web, MapLibre GL JS 6.15.0 y PMTiles 4.5.0 (`web/vendor/`), conservan su licencia BSD-3 (plan §6.6).
- El código tiene licencia MIT (`LICENSE`).

**Atribución sugerida:** «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]» (`LICENCIA_DATOS.md`).

---

## 3. Seccionado de referencia y geografía constante

### 3.1 Referencia: el seccionado del Censo 2021

**Qué es.** El mapa y todas las series usan el seccionado del INE a 1 de enero de 2021: 36.333 secciones (`secciones_2021`; plan §1 y §6.3).

**Por qué.** En ese seccionado publican toda su serie el SERPAVI (2011–2024) y el Censo 2021 (indicador 18): ninguno de los dos necesita tabla de paso (plan §6.3). Con el último seccionado habría que repartir las medianas del SERPAVI: 227 de las 26.137 secciones con dato en 2024 tienen un código que desaparece antes de 2025 (plan §11, pregunta 4).

**Qué se reproyecta:**
- la renta del ADRH, que se publica cada año en su propio seccionado (§3.2 y §5);
- las viviendas turísticas (indicador 19), que desde febrero de 2024 se publican en el seccionado de 2024 (§7.3; ruptura `vut_seccionado_2024` en `inventario/rupturas.csv`). El plan las situaba en el seccionado de 2021 desde la v0.9; se corrigió en la v0.20.

**Coste.** Las secciones que cambian después de 2021 se ven con sus límites de 2021.
- De 2021 a 2025, 35.995 secciones conservan el código, desaparecen 338 y aparecen 559 (`secciones_2021`, `secciones_2025`).
- De las que conservan el código, cambian más de un 1 % de superficie 1.444 (más de un 5 %, 1.304; más de un 25 %, 933).
- De 2016 a 2021 cambian más de un 1 % de superficie 3.265 de 35.917 (más de un 5 %, 1.938) (`cambios_limites`, `geo_cambios_limites()`).

### 3.2 Años del ADRH y tablas de paso

**Fase de los códigos.** El ADRH del año *t* (renta de *t*) se publica en el seccionado de 1 de enero de *t* + 1 (`seccionado_adrh()`). Lo confirma la coincidencia de códigos (`fase_codigos`, `geo_fase_codigos()`). El ADRH 2020 es nativo en el seccionado de 2021.

**Tablas.** Hay nueve tablas de paso, una por seccionado de origen, cada una hacia las secciones de 2021 (`PASOS_2021` en `_targets.R`):

| Seccionado de origen | ADRH | Callejero (formato de la aplicación del INE) | Sentido |
|---|---|---|---|
| 2016 | 2015 | Enero de 2016 (antigua) | Hacia delante: reparte |
| 2017–2020 | 2016–2019 | Enero del mismo año (antigua) | Hacia delante: reparte |
| 2022 | 2021 | Enero de 2022 (nueva) | Hacia atrás: casi siempre agrega |
| 2023–2025 | 2022–2024 | Enero del mismo año (nueva) | Hacia atrás: casi siempre agrega |

El ADRH 2020 usa una tabla identidad (`geo_tabla_identidad()`). La tabla del seccionado de 2024 (`paso_final_2024`) lleva también las viviendas turísticas a 2021 (§7.3).

**Formato de las tablas.** Cada fila es un par (sección de origen, sección de 2021) con estas columnas (`geo/LEEME.md`):
- `portales`: el peso del par;
- `metodo`: `callejero`, `catastro`, `codigo` o `identidad`;
- `fraccion`: la parte del origen que va a ese destino. Las fracciones de cada origen suman 1.

**Fuera de git.** Con `PROVINCIA=<código>`, el pipeline se limita a una provincia. Esas tablas llevan el código en el nombre y no se versionan.

### 3.3 Vía (a): callejero del censo electoral

- **Peso.** Cada tramo de vía del callejero tiene una sección y un rango de portales. El peso de cada par es el número de portales que comparten la sección de origen y la de 2021 (`geo_tabla_paso_callejero()`, `contar_portales()`).
- **Provincia a provincia.** El cálculo se hace por provincias (`geo_tabla_paso_callejero_por_provincia()`). El cruce es por municipio, así que el resultado no cambia y la memoria se limita a la provincia mayor (plan §6.3).
- **Misma aplicación en los dos extremos.** Cada tabla compara tramos de la misma aplicación del INE. El callejero de enero de 2021 se publicó con la antigua y con la nueva (`tramos_2021_antigua`, `tramos_2021_nueva`; ruptura `callejero_aplicacion_2021` en `inventario/rupturas.csv`).
- **Rangos genéricos.** Los rangos 0001–9999 de la aplicación antigua se recortan al último portal real que da la nueva (`geo_topes_portal()`, `recortar_tramos()`).
- **Límite.** El peso cuenta portales, no viviendas: un bloque de cien viviendas pesa lo mismo que una casa. Además, el número de portal no distingue los portales que solo existen sobre el papel, como en los barrios a medio construir. Por eso existe la vía (b).

### 3.4 Vía (b): viviendas del Catastro

- **Peso.** Cada edificio con viviendas del servicio INSPIRE trae su número de viviendas (`numberOfDwellings`). De cada edificio se toma un punto dentro de su huella (`leer_catastro_edificios()`, `leer_catastro_foral()`). El punto se sitúa en una sección de origen y en una de 2021 (`seccion_de_puntos()`), y el peso del par es la suma de viviendas (`geo_tabla_paso_catastro()`).
- **Año de construcción.** En la tabla de un seccionado solo cuentan los edificios construidos hasta ese año; los de año desconocido también cuentan. El año sale de la fecha de construcción del Catastro (`beginning`). En los forales, cada territorio usa una parte distinta de la fecha: Navarra, `beginning`; Bizkaia y Gipuzkoa, `end`; Álava, `anyPoint` (`anio_construccion_foral()`).
- **Sin cruzar municipios.** Los pares de municipios distintos se descartan, salvo dentro de un grupo de fusión o segregación (§3.7). Los límites municipales se digitalizan de forma distinta en cada seccionado; sin ese filtro, la prueba de cierre de 2015 fallaba en dos municipios de Madrid (±6–7 %; plan §6.3).
- **Municipios.** Se lee el Catastro de 1.501 municipios: los que tienen secciones `estimado` por el callejero en alguna tabla o están en un grupo de fusión o segregación (`municipios_catastro_sel`, `seleccionar_municipios_catastro()`).
  - 1.420 son del Catastro estatal. Cada uno casa con su zip por nombre (`casar_municipios_catastro()`): 1.351 por el nombre normalizado y el resto por variantes, bilingües, nombres cortados y una tabla manual. Hay seis gerencias con feed propio: Cartagena, Gijón, Jerez, Vigo, Ceuta y Melilla (plan §6.3).
  - 81 son de País Vasco y Navarra, con sus catastros forales (desde el 8-nov-2026).
- **Edificios.** En total, 5.849.539 edificios con 20.601.213 viviendas (`edificios_paso`):

  | Catastro | Edificios con viviendas | Viviendas |
  |---|---|---|
  | Estatal | 5.718.204 | 19.565.802 |
  | Forales (`edificios_forales`) | 131.335 | 1.035.411 |

  - 1.574 edificios no tienen año de construcción.
  - 603 no caen en ninguna sección de 2021.
- **Contraste foral con el Censo 2021.** En los 11 municipios con cifra del Censo, la diferencia de viviendas va de −5,0 % a +3,0 %; en total, −0,1 % (plan §6.3).

### 3.5 Regla de combinación

La regla se adoptó el 7-nov-2026 y está en `combinar_vias()` (plan §6.3).

**Qué vía decide en cada sección de origen:**
1. **Cae entera** (fracción ≥ 0,99 hacia una sección de 2021): decide la vía (a). Si el Catastro da sus viviendas, el peso pasa a ser el número de viviendas, para que el origen dominante de las medianas compare viviendas con viviendas.
2. **Se reparte:** decide la vía (b), si la sección tiene edificios con viviendas.
3. **El Catastro decide también donde el callejero no llega:**
   - orígenes que el Catastro lleva a otro municipio del mismo grupo de fusión o segregación;
   - orígenes con datos del ADRH que están en el mapa pero no en el callejero;
   - orígenes que el Catastro lleva en parte a una sección de 2021 que la combinación dejaría vacía. Se repite hasta que no queda ninguna.
4. **Secciones «fantasma»:** códigos del mapa que no están ni en el callejero ni en el ADRH del mismo año. Sus edificios pasan al origen de datos que, según el callejero, cubre el mismo destino. Si lo cubren varios, esos orígenes siguen por el callejero (`reasignar_fantasmas()`).
5. **Sin ninguna vía:** las secciones con datos que ninguna vía lleva a 2021, pero cuyo código existe en 2021, pasan a esa sección (`completar_por_codigo()`, `metodo = "codigo"`).

**Resultado.** Secciones de 2021 con recuentos `estimado` y con medianas `ausente`, primero con solo el callejero y luego con la tabla combinada:

| ADRH | Seccionado de origen | `estimado`, solo callejero | `estimado`, combinada | Medianas `ausente`, solo callejero | Medianas `ausente`, combinada | Pares por callejero / por Catastro |
|---|---|---|---|---|---|---|
| 2015 | 2016 | 8.235 | 1.665 | 3.348 | 614 | 28.789 / 8.563 |
| 2016 | 2017 | 7.808 | 1.485 | 3.224 | 521 | 29.062 / 8.168 |
| 2017 | 2018 | 7.211 | 934 | 3.080 | 377 | 29.513 / 7.444 |
| 2018 | 2019 | 6.534 | 395 | 2.820 | 137 | 29.987 / 6.636 |
| 2019 | 2020 | 6.284 | 281 | 2.731 | 66 | 30.155 / 6.380 |
| 2021 | 2022 | 6.180 | 195 | 2.717 | 127 | 30.371 / 6.122 |
| 2022 | 2023 | 6.358 | 604 | 2.754 | 393 | 30.817 / 5.990 |
| 2023 | 2024 | 6.693 | 878 | 2.882 | 536 | 30.624 / 6.375 |
| 2024 | 2025 | 7.057 | 1.194 | 3.101 | 753 | 30.483 / 6.792 |

Origen de las columnas:
- solo callejero: plan §6.3 (`tablas_paso_callejero`, con `geo_estado_paso()`);
- combinada: `tablas_paso_finales`, con `geo_estado_paso()`;
- pares: columna `metodo` de `tablas_paso_finales`. Ninguna tabla lleva hoy pares por código (`metodo = "codigo"`).

### 3.6 Estado de las cifras reproyectadas

La regla se adoptó el 6-nov-2026 (`geo_estado_paso()`; plan §6.3). Decide la sección de destino, no la dirección. Una sección de origen «cae entera» en la de 2021 si su fracción hacia ella es ≥ 0,99.

- **Recuentos y medias ponderadas:**
  - `dato` si todos los orígenes que recibe la sección caen enteros: sumar, o promediar con su denominador, es exacto;
  - `estimado` si alguno se reparte.
- **Medianas e índices.** No se combinan: se copia la de un solo origen.
  - `dato` con un único origen que cae entero: la misma sección, aunque cambie de código.
  - `estimado` con un único origen repartido, o con un origen dominante que aporta al menos el 95 % del peso que recibe la sección.
  - `ausente` si ningún origen domina. En ese caso se remite a la escala superior.
- **Excepción declarada.** El `estimado` es una excepción a la regla del nivel nativo, limitada a esas secciones y años.
- **Secreto estadístico.** Al aplicar la tabla a los datos (`armonizar_ine_adrh()`, §5.3) entra el que traiga la fuente.

**Contraste del origen dominante** (Madrid, prueba de un año con la edad media y el tamaño medio del hogar, que no se suman; plan §6.3):
- Con un origen que aporta al menos el 95 % (264 secciones), el error es el de las secciones 1:1. En la edad media: mediana de 0,4 años y percentil 90 de 0,87 años, frente a 0,90 en las 1:1.
- Entre el 80 y el 95 % (100 secciones), el percentil 99 sube a 2,7 años, frente a 1,4.

### 3.7 Fusiones y segregaciones de municipios

Entre 2016 y 2025 hay nueve grupos con 19 municipios (`grupos_municipio`, `geo_grupos_municipio()`; plan §6.3):
- Cerdedo y Cotobade forman Cerdedo-Cotobade (2017).
- Siete segregaciones andaluzas en el seccionado de 2019: San Martín del Tesorillo, Fuente Carreteros, La Guijarrosa, Valderrubio, Torrenueva Costa, La Zarza-Perrunal y El Palmar de Troya.
- Usansolo se segrega de Galdakao (2024).

**Cómo se forma un grupo.** Cada municipio que solo está en uno de los dos seccionados forma grupo con los del otro que ocupan al menos el 1 % de su superficie.

**Qué cambia dentro de un grupo:**
- Las tablas de paso y la prueba de cierre cruzan municipios (`agrupar_municipio()`).
- Los municipios nuevos conservan de forma muy desigual los códigos de vía del callejero (Fuente Carreteros, 38 de 38; El Palmar de Troya, 19 de 71). Por eso, en los orígenes que se van a otro municipio decide el Catastro.

### 3.8 Secciones huérfanas y excepciones de cobertura

**Secciones huérfanas del ADRH** (alerta `adrh_seccion_huerfana`; `huerfanas_adrh`, `seccion_huerfanas()`):
- Son nueve códigos que no están en ningún seccionado de 2016 a 2025: siete en 2015 (5.409 personas en total), una en 2016 y una en 2021.
- El ADRH las publica con códigos de un seccionado anterior. Casi siempre es una sección más de un municipio que luego la fusiona.
- Sin mapa ni callejero no hay tabla de paso: quedan fuera de la tabla y de la prueba de cierre.

| Año del ADRH | Sección | Población |
|---|---|---|
| 2015 | 0518602001 | 785 |
| 2015 | 2706501005 | 556 |
| 2015 | 4308601002 | 735 |
| 2015 | 4315503003 | 1.527 |
| 2015 | 4622004005 | 196 |
| 2015 | 5029703010 | 852 |
| 2015 | 5029703031 | 758 |
| 2016 | 4622004005 | 175 |
| 2021 | 1808704004 | 5 |

**Excepciones de cobertura** (`inventario/excepciones_cobertura.csv`; alerta `cobertura_destino_excepcion`). Son dos secciones de 2021 que la tabla deja vacías por un defecto conocido de la fuente:
- **3500201010** (ADRH 2015 y 2016). Tiene el mismo polígono en todos los seccionados y población en el ADRH: 2.373 personas en 2015. Pero el callejero de 2016 y 2017 lleva su origen a otra sección, y el Catastro no la alcanza.
- **0309002003**, en Mutxamel (ADRH 2021–2024; también las viviendas turísticas, §7.3). En el mapa de 2021 es una zona agrícola de 11 km² sin viviendas en el Catastro, mientras el ADRH 2020 le da 1.110 habitantes. Desde 2022 el código está en otro sitio. Probable polígono mal rotulado en el seccionado de 2021.

Por eso, la tabla combinada llega a 36.332 de las 36.333 secciones de 2021 en 2015, 2016 y 2021–2024, y a todas en 2017–2019 (`tablas_paso_finales`).

### 3.9 Prueba de cierre y prueba de un año

**Prueba de cierre** (`cierre_poblacional`, bloqueo, ±0,5 %; `comprobar_cierre_poblacional()`):
- **Qué compara.** La población del ADRH por sección, llevada a 2021, sumada por municipio (o por grupo), frente a la suma de sus secciones de origen.
- **Resultado.** Pasa en los nueve años: 66.407 comparaciones de municipio o grupo y año. La desviación máxima es de 1,5 × 10⁻¹⁴ %, el error de redondeo de la máquina (`comprobaciones_f1`).
- **Es débil por construcción.** Las tablas no cruzan municipios y cada origen reparte el 100 %, así que solo detecta secciones sin tabla y municipios que cambian (plan §6.3).
- **Antes del 7-nov-2026** se comparaba con el total municipal publicado. Esa diferencia de la fuente la vigila ahora la alerta `adrh_suma_secciones` (§4).

**Cobertura de destino** (`cobertura_destino`, bloqueo): ninguna sección de 2021 se queda sin recibir nada en los nueve años, salvo las dos excepciones (§3.8; `comprobar_cobertura_destino()`).

**Prueba de un año.**
- **Diseño.** El ADRH 2021 (seccionado de 2022) se lleva a 2021 y se compara con el ADRH 2020, nativo en 2021. Con un año de distancia apenas hay crecimiento real, así que la razón entre los dos mide sobre todo el error de la tabla. Con la aplicación antigua del callejero se repite con el ADRH 2019 (seccionado de 2020).
- **Qué compara la tabla siguiente.** Las secciones que el callejero reparte, con la tabla de solo callejero y con la tabla combinada:

| Ámbito | ADRH (seccionado) | Secciones que el callejero reparte | Dentro de ±5 %: callejero → combinada | 90 % central de la razón: callejero → combinada | Razón fuera de [0,8; 1,25]: callejero → combinada | Secciones que caen enteras: dentro de ±5 % | Fuente |
|---|---|---|---|---|---|---|---|
| Madrid (provincia) | 2021 (2022) | 465 | 66,5 → 92,5 % | 0,81–1,28 → 0,96–1,04 | 50 → 7 | 94,8 % | Plan §6.3 |
| País Vasco y Navarra (municipios forales) | 2021 (2022) | 300 | 76,7 → 95,0 % | 0,88–1,15 → 0,96–1,04 | 12 → 0 | 95,9 % | Plan §6.3 |
| 1.501 municipios con Catastro (toda España) | 2021 (2022) | 6.180 | 61,2 → 94,1 % | 0,72–1,52 → 0,96–1,04 | 1.003 → 37 | 96,0 % (21.265 secciones) | `comparacion_vias` |
| 1.501 municipios con Catastro (toda España) | 2019 (2020) | 6.280 | 58,3 → 94,8 % | 0,63–2,12 → 0,97–1,04 | 1.443 → 44 | 96,7 % (21.151 secciones) | `comparacion_vias` |

Origen: `comparar_vias_paso()`; en `comparacion_vias`, filas con `estimada_a` verdadero y falso.

- **Resultado.** En las secciones que el callejero reparte, la tabla combinada da una dispersión del mismo orden que la de las secciones que caen enteras.
- **Diagnóstico sección a sección** (`diagnostico_f1`, `geo_diagnostico_paso()`; no es compuerta). Compara cada año con el ADRH 2020. Con cuatro o cinco años de distancia mezcla el error de la tabla con el crecimiento real de los barrios.

### 3.10 Jerarquía territorial y mapa base

**Jerarquía** (`geo_jerarquia()`, `geo_territorios()`; objetivos `jerarquia_2021` y `territorios_2021`). Cada sección del seccionado de 2021 cuelga de un distrito, un municipio, una provincia y una comunidad. El distrito, el municipio y la provincia salen del código de la sección; la comunidad, de la columna CCA del seccionado.

| Nivel | Territorios | Nombre |
|---|---|---|
| Sección | 36.333 | Sin nombre (código) |
| Distrito | 10.479 | Sin nombre |
| Municipio | 8.131 | El vigente, del ADRH (`nombres_municipios_adrh()`) |
| Provincia | 52 | Seccionado de 2021 |
| Comunidad | 19 | `geo/ccaa.csv` |

**Ficheros en git** (`ficheros_jerarquia`, `exportar_jerarquia()`):
- `geo/jerarquia_2021.csv`: una fila por sección, con su distrito, municipio, provincia y comunidad;
- `geo/territorios_2021.csv`: nivel, código, nombre, territorio superior y número de secciones de cada territorio. Es la tabla de nombres de la web.

**Compuerta** (`comprobar_jerarquia()`, `validacion_jerarquia`; §4.1). Ninguna sección repetida; ningún territorio con dos superiores; códigos que encajan; cada territorio suma sus partes, y el total, las 36.333 secciones; ningún territorio sin nombre. Las 14 cifras valen 0.

**Mapa base** (`fichero_mapa_base`; `geo/referencia/mapa_base_2021.pmtiles`, fuera de git):
- **Capas** (`ZOOMS_MAPA_BASE`). Comunidades, provincias y municipios se obtienen disolviendo las secciones (`geo_capas_mapa_base()`), así que sus bordes coinciden con los de las secciones. Por encima del zoom 12, MapLibre amplía las teselas.

  | Capa | Zooms | Atributos |
  |---|---|---|
  | comunidades | 0–12 | `ccaa`, `nombre` |
  | provincias | 3–12 | `provincia`, `nombre` |
  | municipios | 5–12 | `municipio`, `nombre` |
  | secciones | 7–12 | `seccion` |

- **Teselas.** Se generan con GDAL desde R, con los controladores PMTiles y MVT (`generar_pmtiles()`), sin tippecanoe (plan §6.2). Cada tesela usa una rejilla de 4.096 unidades por 512 píxeles. La simplificación se mide en unidades de esa rejilla, así que es la misma a los dos lados de un borde compartido.
- **Simplificación** (plan §11, pregunta 16): 4 unidades (medio píxel) por debajo del zoom 12 y ninguna en el zoom 12. En GDAL, el parámetro del zoom máximo es una tolerancia, no un número de zoom: vale 0 (`simplificacion_zoom_max`).
- **Tamaño.** El fichero ocupa 35,2 MB (1 MB = 10⁶ bytes), con 13.235 teselas (`resumen_mapa_base`, `pmtiles_resumen()`):

  | Zoom | Teselas | MB | Mayor tesela (KB) |
  |---|---|---|---|
  | 0–4 | 13 | 0,03 | 5,7 |
  | 5 | 5 | 0,34 | 142,7 |
  | 6 | 10 | 0,46 | 149,1 |
  | 7 | 24 | 1,67 | 208,2 |
  | 8 | 71 | 2,26 | 142,4 |
  | 9 | 208 | 2,77 | 85,3 |
  | 10 | 702 | 4,10 | 68,4 |
  | 11 | 2.548 | 6,47 | 38,4 |
  | 12 | 9.654 | 17,03 | 58,0 |

- **Compuerta** (`mapa_base_secciones`; `comprobar_mapa_base()`, `validacion_mapa_base`). Lee con GDAL las teselas del zoom 12 del fichero y encuentra las 36.333 secciones.
- **Publicación** (plan §6.6; plan §11, pregunta 16). El PMTiles no entra en la historia de git: se regenera con `targets` y se publica desde un *release* del repositorio, que el flujo de GitHub Pages copia junto a la web. En local se ve con `node geo/visor/servir.mjs` (`geo/visor/`).

**Códigos postales** (plan §6.3; plan §11, pregunta 16). No son una unidad del INE y no hay polígonos oficiales reutilizables. La correspondencia sección ↔ código postal saldrá del callejero del INE (campo CPOS de los tramos): en enero de 2021, el 80,7 % de las secciones tiene un solo código postal (11.051 códigos; 2.262 cruzan municipios). Solo la necesitan los indicadores 11 y 16. Una geometría propia a partir de los portales de CartoCiudad se decide en F4.

---

## 4. Compuerta de validación

**Regla.** No se publica nada que no reproduzca las cifras de la fuente (guía, regla 3; plan §6.5). Cada comprobación tiene una fila en `inventario/referencias_validacion.csv`, con su referencia, su tolerancia y su tipo. Si una comprobación no tiene fila, el pipeline se detiene.

**Cómo se aplica.** `validar_referencias()` compara cada cifra calculada con su referencia:
- las de tipo `bloqueo` paran el pipeline;
- las de tipo `alerta` salen como avisos al final de `tar_make()`.

**Orden de cálculo.** Cada objetivo que alimenta la tabla larga depende de su compuerta:
- `larga_adrh`, de `validacion_adrh` y de `validacion_f1` (la geografía, desde el 8-nov-2026);
- `larga_serpavi`, `larga_censo2021` y `larga_vut`, de `validacion_serpavi`, `validacion_censo2021` y `validacion_vut`;
- `larga_derivados`, de `validacion_derivados`;
- `tabla_larga`, además, de `validacion_sobrecarga` y `validacion_modulo`;
- los ficheros de la jerarquía y el mapa base, de `validacion_jerarquia`. `validacion_mapa_base` lee el PMTiles ya generado: comprueba el fichero antes de publicarlo;
- los datos de la web (`ficheros_web`), de `validacion_jerarquia`, `validacion_mapa_base` y `validacion_derivados`. `validacion_web` comprueba los ficheros ya escritos.

Cada bloque de la tabla larga pasa además por `validar_tabla_larga()`: columnas, niveles y longitud de los códigos, estados, valores vacíos solo en `secreto` y `ausente`, filas repetidas, y cortes, grupos, indicadores y fuentes que existen en `inventario/`.

### 4.1 Comprobaciones en el pipeline

| `id` | Qué compara | Tolerancia | Tipo | Resultado | Objetivo |
|---|---|---|---|---|---|
| `adrh_municipio` | Mediana, por año e indicador, de la desviación entre las medias de sección agregadas a municipio y la cifra municipal | ±0,1 % | Bloqueo | 0,0 % en 2015–2024, renta por persona y por hogar | `validacion_adrh` |
| `cierre_poblacional` | Población reproyectada a 2021 frente a la suma de sus orígenes, por municipio o grupo | ±0,5 % | Bloqueo | Pasa en los nueve años (§3.9) | `validacion_f1` |
| `cobertura_destino` | Secciones de 2021 que no reciben nada | Exacto | Bloqueo | Ninguna, salvo las excepciones | `validacion_f1` |
| `serpavi_provincia` | Testigos de las secciones sumados a provincia, por año y tipología, frente a la hoja de provincias (las medianas no se agregan) | Exacto | Bloqueo | Pasa en las 1.040 cifras: 52 provincias, 10 años y 2 tipologías | `validacion_serpavi` |
| `serpavi_espana` | Testigos de las secciones, y por otro lado los de las comunidades, sumados a España, frente a la fila de España de la hoja de comunidades | Exacto | Bloqueo | Pasa en las 40 cifras. En 2022 y 2023, España es la suma de las comunidades sin Gipuzkoa, porque el País Vasco aún no tiene cifra | `validacion_serpavi` |
| `serpavi_secreto` | Secciones, provincias y comunidades con mediana y menos de 10 testigos, o sin mediana y con 10 o más | Exacto | Bloqueo | 0 casos en las 60 cifras de año, nivel y tipología | `validacion_serpavi` |
| `serpavi_cuartiles` | Mediana sin cuartiles, alquiler mensual sin alquiler por m² (o al revés) o cuartiles desordenados | Exacto | Bloqueo | 0 casos en las 60 cifras | `validacion_serpavi` |
| `serpavi_escalas` | Porcentaje de municipios y distritos que no cuadran con sus secciones, por año y nivel | ±1 % | Bloqueo | Máximo, 0,56 % (municipios de 2022) | `validacion_serpavi` |
| `censo2021_alquiler` | Hogares en alquiler (%) de España y de cada provincia con las secciones, frente a la tabla 59523. Las secciones en secreto entran como un intervalo: sus hogares pueden estar entre el 0 y el 100 % en alquiler | ±0,1 puntos | Bloqueo | Pasa en los 53 territorios; España, 16,10 % en las dos; diferencia máxima, 0,055 puntos (Huelva) | `validacion_censo2021` |
| `censo2021_principales` | Hogares de las secciones frente a los publicados, en España y en las 19 provincias sin secciones en secreto | ±0,5 % | Bloqueo | España, −0,20 % (los hogares de las secciones en secreto); provincias, de 0 a +0,17 % | `validacion_censo2021` |
| `censo2021_seccionado` | Secciones del CSV fuera del seccionado de 2021 y secciones del seccionado sin fila en el CSV | Exacto | Bloqueo | 0 y 0 | `validacion_censo2021` |
| `vut_viviendas_provincia` | Viviendas turísticas de las secciones sumadas por provincia y España, en los 13 periodos, frente a la tabla 39364 | Exacto | Bloqueo | Cuadran las 689 cifras: 13 periodos y 53 territorios | `validacion_vut` |
| `vut_seccionado` | Desde febrero de 2024: secciones del seccionado de 2024 que faltan en la tabla 5, más secciones con viviendas turísticas fuera de él | Exacto | Bloqueo | 0 en los seis periodos | `validacion_vut` |
| `vut_paso_2021` | Viviendas turísticas llevadas a 2021 con la tabla 2024 → 2021, sumadas por provincia y España, frente a la tabla 39364 | ±0,01 % | Bloqueo | Desviación 0 en las 318 cifras | `validacion_vut` |
| `vut_denominador` | Secciones de 2024 que caen enteras y solas en la de 2021 del mismo código: mediana de la diferencia entre el porcentaje del INE y 100 × viviendas turísticas / viviendas del Censo 2021 | ±0,01 puntos | Bloqueo | 0 en los seis periodos | `validacion_vut` |
| `jerarquia_unica` | Secciones repetidas, territorios con más de un superior y códigos que no encajan | Exacto | Bloqueo | 0 en las 5 cifras | `validacion_jerarquia` |
| `jerarquia_sumas` | Territorios que no suman sus partes; secciones de más o de menos frente al seccionado de 2021 | Exacto | Bloqueo | 0 en las 6 cifras | `validacion_jerarquia` |
| `jerarquia_nombres` | Comunidades, provincias y municipios sin nombre | Exacto | Bloqueo | 0 en las 3 cifras | `validacion_jerarquia` |
| `mapa_base_secciones` | Secciones de 2021 que faltan en las teselas del zoom máximo del PMTiles | Exacto | Bloqueo | 0 | `validacion_mapa_base` |
| `smi_neto` | Ingreso neto mensual de la tartera de 2026 (`perfiles`) frente a la cifra del plan: 17.094 € × (1 − 0,065) / 12 ≈ 1.332 € | ±1 € | Bloqueo | 1.331,91 €; diferencia, −0,09 € | `validacion_derivados` |
| `derivados_terminos` | Desviación máxima, por año e indicador, entre cada cifra derivada y la recalculada con sus términos | ±0,001 % | Bloqueo | 4,3 × 10⁻¹⁴ % como máximo en las 22 cifras | `validacion_derivados` |
| `derivados_estado` | Cifras derivadas cuyo estado no es el peor de sus términos, o con valor y estado `secreto` o `ausente` (o al revés) | Exacto | Bloqueo | 0 en las 22 cifras | `validacion_derivados` |
| `derivados_rango` | Cifras derivadas fuera del rango posible: esfuerzo, del 0,1 al 100 %; barrera, del 0,1 al 300 %; sueldo necesario, de 100 a 10.000 € netos al mes | Exacto | Bloqueo | 0 en las 22 cifras | `validacion_derivados` |
| `perfiles_mochila` | Provincias de la mochila sin código del INE en `inventario/provincias_aeat.csv`, códigos repetidos y nombres sin mochila | Exacto | Bloqueo | 0 en las 3 cifras | `validacion_derivados` |
| `web_valores` | Ficheros de valores de `web/datos/` cuyos valores o estados no son los de la tabla larga (con el redondeo de la guía) o cuya longitud no es la del índice; series sin fichero | Exacto | Bloqueo | 0 en las 339 cifras | `validacion_web` |
| `web_fichas` | Por municipio: celdas de las series de su ficha que no reproducen la tabla larga, y secciones de más o de menos | Exacto | Bloqueo | 0 en los 8.131 municipios | `validacion_web` |
| `sobrecarga_es_total`, `sobrecarga_es_mercado`, `sobrecarga_ccaa` | Sobrecarga con los microdatos de la ECV frente a Eurostat | ±0,1 puntos | Bloqueo | Pasan en 2023–2025 (§7.5) | `validacion_sobrecarga` |
| `modulo_acceso_lectura` | Suma de las comunidades frente al total nacional del módulo de la ECV 2025 | ±0,1 % | Bloqueo | Pasa | `validacion_modulo` |
| `i18n_completo`, `contraste_texto`, `rampa_contorno` | Diccionarios ES/EN y contrastes de la web | Exacto | Bloqueo | Pasan | `validacion_i18n`, `validacion_diseno` |
| `adrh_municipio_detalle` | Desviación de cada municipio entre las medias de sección agregadas y la cifra municipal | ±1 % | Alerta | Avisa en 579 de 146.306 cifras de municipio, año e indicador; 135 pasan del 5 % | `comprobaciones_adrh` |
| `adrh_suma_secciones` | Población por sección del ADRH sumada por municipio frente al total municipal de la misma tabla | ±0,5 % | Alerta | Avisa en 160 municipios y años, todos de 2015–2019 (38, 34, 30, 29 y 29) | `comprobaciones_f1` |
| `adrh_seccion_huerfana` | Secciones del ADRH sin código en ningún seccionado de 2016–2025 | Exacto | Alerta | 9 (§3.8) | `huerfanas_adrh` |
| `cobertura_destino_excepcion` | Secciones de 2021 vacías por un defecto conocido de la fuente | Exacto | Alerta | 2 secciones, 6 años-sección (§3.8) | `comprobaciones_f1` |
| `serpavi_escalas_detalle` | Cada municipio o distrito, año y tipología que no cuadra con sus secciones | Exacto | Alerta | Avisa en 164 filas, que van como `ausente` (§7.1) | `validacion_serpavi` |
| `serpavi_forales` | Primer año con testigos de cada provincia foral frente al de la ruptura `serpavi_forales` | Exacto | Alerta | Coinciden los cuatro | `validacion_serpavi` |
| `vut_denominador_detalle` | Las secciones de `vut_denominador`, una a una (solo las que se apartan más de 0,001 puntos) | ±0,1 puntos | Alerta | Pasa: 839 secciones y periodos, todos desde noviembre de 2024; diferencia máxima, 0,091 puntos | `validacion_vut` |
| `derivados_rango_detalle` | Cada cifra derivada fuera del rango habitual: esfuerzo, por debajo del 3 % o por encima del 60 %; barrera, del 3 % o del 150 %; sueldo necesario, de 200 € o de 4.000 € | Exacto | Alerta | Avisa en 23 cifras: tres esfuerzos de más del 60 % (2019 y 2022), 18 sueldos necesarios por debajo de 200 € en 2015–2018 y dos por encima de 4.000 € (dos secciones de Madrid, 2024) | `validacion_derivados` |
| `web_fuera_indice` | Filas de la tabla larga que van a la web sin hueco en el índice de su nivel | Exacto | Alerta | Avisa en 16 filas de municipio; en los demás niveles, 0 | `validacion_web` |
| `aeat_mediana_deciles` | Mediana del SME por comunidad interpolada desde deciles frente a centiles | ±0,5 % | Alerta | Entre −0,11 y +0,20 % | `validacion_mochila` |
| `mochila_ecv` | Mochila de cada comunidad frente a la mediana del bruto de la ECV | ±15 % | Alerta | Entre −10,6 y +7,2 % | `validacion_mochila_ecv` |
| `mochila_neto_ecv` | Paso a neto aplicado a la mediana del bruto de la ECV frente a la mediana del neto | ±5 % | Alerta | Entre −2,0 y +3,4 %; España, +0,5 % | `validacion_mochila_neto_ecv` |
| `sobrecarga_es_edad` | Sobrecarga de España por grupos de edad | ±0,1 puntos | Alerta | Pasa en 2023–2025; diferencia máxima, 0,05 puntos (plan §7, F1b) | `validacion_sobrecarga` |
| `nuts_geometria` | Regiones con dato sin geometría en su versión NUTS | Exacto | Alerta | Avisa: el código agrupado FI19_20 en 2021–2025, y Bosnia y Herzegovina en 2022–2023 | `validacion_nuts` |
| `contraste_declarado` | Contraste declarado en `tokens.json` frente al recalculado | ±0,05 | Alerta | Pasa; diferencia máxima, 0,003 | `validacion_diseno` |

**Lectura de los resultados de `adrh_municipio`.** La mediana es 0,0 % porque la mayoría de los municipios tiene una sola sección. La alerta `adrh_municipio_detalle` recoge los casos en que la fuente no cuadra entre escalas con todas las secciones con dato. En Madrid, por ejemplo, Alcobendas y Pozuelo de Alarcón quedan todos los años por encima del 5 % (`inventario/referencias_validacion.csv`).

### 4.2 Comprobaciones pendientes

| `id` | Qué compara | Tolerancia | Tipo |
|---|---|---|---|
| `aeat_provincia` | Salario medio provincial leído frente a la tabla publicada de la AEAT | Exacto | Bloqueo |
| `adrh_aeat` | Renta del ADRH frente a la renta bruta de la AEAT por municipio | Tendencia coherente | Alerta |
| `serpavi_ipva` | Tendencia del SERPAVI frente al IPVA | Tendencia coherente | Alerta |
| `notariado_tasado` | Precio del Notariado frente al valor tasado (indicadores 11 y 12, F4) | Umbral razonado | Alerta |

`adrh_aeat`, `serpavi_ipva` y `notariado_tasado` no tienen todavía una tolerancia numérica. `validar_referencias()` no admite tolerancias de texto, así que habrá que fijar una antes de que entren en el pipeline.

---

## 5. Renta (indicadores 1–3)

### 5.1 Fuente y lectura

**Tablas.** El ADRH de toda España se baja de INEbase (`descargar_ine_adrh()`) en dos tablas:
- **30824:** renta media y mediana (`fichero_adrh_renta`);
- **30832:** indicadores demográficos (`fichero_adrh_demografia`).

Son CSV separados por «;», con coma decimal. El valor «.» significa dato no publicado (secreto estadístico) y esas filas se descartan al leer (`leer_ine_adrh()`).

**Indicadores** (`INDICADORES_ADRH_RENTA`, `leer_ine_adrh_renta()`):

| # | Código | Nombre en el ADRH | Tipo |
|---|---|---|---|
| 1 | `renta_persona` | Renta neta media por persona | Media; se pondera con la población |
| 2 | `renta_hogar` | Renta neta media por hogar | Media; se pondera con los hogares |
| 3 | `renta_uc_mediana` | Mediana de la renta por unidad de consumo | Mediana (escala de la OCDE modificada); no se agrega |

**Pesos** (`pesos_adrh()`):
- **Población:** la «Población» de la tabla demográfica.
- **Hogares:** población ÷ tamaño medio del hogar. La fuente redondea el tamaño medio del hogar a un decimal, así que el número de hogares es aproximado.

La tabla nacional redondea ese tamaño una décima distinto que las provinciales en unas 200 secciones de Madrid por año. Por eso, al pasar de la tabla de Madrid a la nacional, cambiaron 33 cifras de renta por hogar, en menos de un 0,3 % (plan §6.3).

**Lectura de las cifras** (`inventario/indicadores.csv`):
- La renta es del año *t*, con la población a 1 de enero de *t* + 1.
- No incluye el valor de uso de la vivienda propia.
- La renta por hogar es renta de varios perceptores, no un sueldo.

### 5.2 Compuerta antes de reproyectar

La compuerta se aplica a las cifras de sección en su seccionado original, antes de reproyectar (`comprobar_adrh_municipio()`):
- `adrh_municipio` (bloqueo, §4.1): media de las secciones ponderada con la población (indicador 1) o con los hogares (indicador 2), frente a la cifra municipal publicada.
- `adrh_municipio_detalle` (alerta): lo mismo, municipio a municipio.
- La mediana (indicador 3) no tiene compuerta de agregación, porque no se agrega.

### 5.3 Reproyección al seccionado de 2021

Se hace en `armonizar_ine_adrh()`, con la tabla de cada año (`tablas_paso_adrh`: las nueve combinadas y la identidad de 2020).

**Medias (indicadores 1 y 2)** (`geo_reproyectar_media()`). Para cada sección de 2021 *d*:

  valor(*d*) = Σₒ valor(*o*) · peso(*o*) · fracción(*o*, *d*) / Σₒ peso(*o*) · fracción(*o*, *d*)

donde:
- la suma recorre los orígenes *o* con dato;
- peso(*o*) es la población (indicador 1) o los hogares (indicador 2) del origen en el año del ADRH;
- fracción(*o*, *d*) es la de la tabla de paso.

**Mediana (indicador 3)** (`geo_reproyectar_mediana()`):
- Se copia el valor del único origen, o del origen dominante (≥ 95 % del peso que recibe *d*).
- Si ningún origen domina, la cifra queda `ausente`.

**Estado final de cada cifra.** Se combina el estado de la tabla (§3.6) con la cobertura de los datos (`geo_cobertura_origenes()`):
- `secreto` si ninguno de los orígenes tiene valor publicado;
- `estimado` si falta el valor de alguno de los orígenes que recibe la sección, aunque la tabla la dé como `dato`. En las medias, el valor se calcula entonces solo con los orígenes que tienen dato;
- `ausente` en las medianas sin origen dominante;
- en el resto, el estado de la tabla: `dato` o `estimado`.

**Nivel municipal.** Se toma la cifra municipal publicada, con estado `dato`. No se agrega desde las secciones: la fuente no siempre cuadra entre escalas (§4.1), y las medianas no se agregan (regla 1 de la guía).

### 5.4 Resultado

Secciones de 2021 por estado, para cada año (`tabla_larga`, filas con `fuente == "ine_adrh"` y `nivel == "sc"`):

| Año | Medias (1 y 2): `dato` | Medias: `estimado` | Medias: `secreto` | Mediana (3): `dato` | Mediana: `estimado` | Mediana: `secreto` | Mediana: `ausente` |
|---|---|---|---|---|---|---|---|
| 2015 | 32.592 | 1.634 | 2.106 | 31.868 | 1.257 | 2.593 | 614 |
| 2016 | 33.002 | 1.456 | 1.874 | 32.323 | 1.127 | 2.361 | 521 |
| 2017 | 33.374 | 907 | 2.052 | 33.179 | 670 | 2.107 | 377 |
| 2018 | 33.886 | 391 | 2.056 | 33.751 | 297 | 2.148 | 137 |
| 2019 | 33.958 | 281 | 2.094 | 33.854 | 224 | 2.189 | 66 |
| 2020 | 35.826 | 0 | 507 | 34.349 | 0 | 1.984 | 0 |
| 2021 | 36.123 | 195 | 14 | 34.647 | 158 | 1.400 | 127 |
| 2022 | 35.645 | 613 | 74 | 34.070 | 478 | 1.391 | 393 |
| 2023 | 35.367 | 877 | 88 | 33.677 | 665 | 1.454 | 536 |
| 2024 | 35.043 | 1.194 | 95 | 33.184 | 886 | 1.509 | 753 |

Los dos indicadores de media tienen los mismos recuentos por estado.

**Por qué el `secreto` es mayor en 2015–2019.** Esos años el ADRH no publica por sección entre 1.327 y 1.629 códigos que sí están en el callejero, sobre todo de País Vasco y Navarra (`fase_codigos`, columna `callejero_sin_adrh`; plan §6.3).

**Filas en la tabla larga.** 1.303.484 filas del ADRH (§9.1). Nivel municipal: 73.777 filas por cada media y 65.958 de la mediana. La columna `version` lleva la fecha del fichero de la fuente: 7-nov-2026.

---

## 6. Ingresos de las fichas

### 6.1 Regla común y fichas

**Regla común:** ingreso neto mensual repartido en 12 (guía, regla 8; plan §3.1). El alquiler se paga doce veces al año; con la paga de un sueldo de 14 pagas, el esfuerzo saldría inflado en torno a un 17 % (14 / 12 = 1,167).

**Vivienda.** Las fichas de una persona buscan 50 m², para que sus mapas solo difieran por el ingreso. El alquiler de las fichas es el de la vivienda colectiva (plan §11, pregunta 12).

| Ficha | Ingreso de referencia | Fuente | Escala | Vivienda | Estado |
|---|---|---|---|---|---|
| Llave (hogar del barrio) | Renta neta media por hogar ÷ 12 | INE, ADRH (indicador 2) | Sección | Alquiler mediano de su sección, sin superficie fija | Ingreso calculado (`perfiles`); esfuerzo (indicador 14), en `larga_derivados` (§7.4) |
| Mochila (joven de 26 a 35 años) | Mediana estimada del salario cobrado en el año, neta, ÷ 12 | AEAT; control con la ECV | Provincia | 50 m² | Calculada para 2024 (`mochila_neta`, `perfiles`) |
| Tartera (salario mínimo) | SMI neto anual ÷ 12 | RD 126/2026 (y RD 145/2024) | Nacional | 50 m² | Calculada con el SMI de 2024 y el de 2026 (`perfiles`) |
| Transistor (pensionista) | Pensión media de jubilación, neta de IRPF, ÷ 12 | INSS | Provincia | 50 m² | Fase F3: pendiente |
| Tu ficha | Neto mensual que escribe quien consulta: 12 o 14 pagas, segundo sueldo opcional | — | — | 50 m² con un sueldo, 70 m² con dos; cambiable a 50, 70 o 90 | Se calcula en el navegador y no se guarda: pendiente (web) |

### 6.2 Mochila: método B y paso a neto

La decisión del autor es del 7-nov-2026 (plan §3.1; pregunta abierta 7, cerrada). La AEAT es la de 2024, y la ECV es la ola de 2025, que trae los ingresos de 2024.

**1. Salario de partida.** Salario medio anual bruto de 26 a 35 años por provincia (AEAT, *Mercado de trabajo y pensiones*; tabla «Asalariados, percepciones salariales y salarios por provincia, edad y sexo»; `aeat_provincia`).
- Es salario real del año: incluye a quien trabajó pocos meses.
- Las tablas de la AEAT son páginas HTML, una por combinación de filtros (`descargar_aeat_mercado()`, `leer_aeat_mercado()`).

**2. De media a mediana.** Se multiplica por la relación mediana/media del salario medio estimado (SME, módulo de «año completo») de 26 a 35 años de su comunidad.
- La AEAT no publica esa mediana. Se interpola con dos tablas (`cuantil_tramos()`, `calcular_mochila_opciones()`):
  - los recuentos de asalariados de cada comunidad y edad en cada decil nacional;
  - los límites de los centiles nacionales.
- Supuesto de la interpolación: dentro de cada decil nacional, la comunidad se reparte como el país. Contraste con los recuentos por centil que la AEAT da por comunidad, para todas las edades: entre −0,11 y +0,20 % (`aeat_mediana_deciles`).
- Supuesto del método: la relación mediana/media es la misma en todas las provincias de una comunidad.
- Fórmula: bruto anual = salario medio real provincial × relación mediana/media del SME de su comunidad (`calcular_mochila()`, `mochila`).

**3. De bruto a neto** (`calcular_mochila_neta()`): neto anual = bruto × (1 − cotización − retención); neto mensual = neto anual ÷ 12.
- **Cotización del trabajador en 2024:** 6,47 % (`COTIZACION_TRABAJADOR`). Suma contingencias comunes (4,70), desempleo (1,55), formación profesional (0,10) y MEI (0,12). Con contrato temporal sería 6,52 %.
- **Retención:** tipo medio de la AEAT de las personas que solo cobran salarios, por comunidad y tramo de renta anual (*Grupos de población por la naturaleza de sus retribuciones*; `aeat_retenciones`, `retenciones_aeat()`).
  - Se interpola linealmente entre los salarios medios de los tramos; fuera de ellos se toma el tipo del tramo extremo (`tipo_retencion()`).
  - En España (`retenciones_mochila`): entre el 1,6 y el 1,8 % por debajo de 12.000 €; 2,6 % de 12.000 a 18.000 €; 9,0 % de 18.000 a 24.000 €; 13,6 % de 24.000 a 30.000 €.
  - Es la retención de la nómina, no la cuota final del IRPF.

**4. Lo cobrado en el año.** La ficha usa el salario cobrado en el año, no el de quien trabaja doce meses: la AEAT no publica ese salario, porque su «año completo» anualiza por días cotizados. En la ECV 2025, el 73,9 % de los asalariados de 26 a 35 años con salario trabajó los doce meses (`ecv_mochila`, España).

**5. Control con la ECV 2025.** Microdatos de personas: salario bruto (PY010G), neto (PY010N), factor (PB040) y edad al final del año de ingresos (`leer_ecv_asalariados()`, `resumir_ecv_asalariados()`).
- `mochila_ecv`: la mochila de cada una de las 15 comunidades de régimen común queda entre un −10,6 % (La Rioja) y un +7,2 % (Castilla y León) de la mediana del bruto de la ECV.
- `mochila_neto_ecv`: el paso a neto aplicado a la mediana del bruto de la ECV queda entre un −2,0 % (Canarias) y un +3,4 % (Galicia) de la mediana del neto. En España, +0,5 %, con 4.857 observaciones.

**Resultado 2024** (`mochila_neta`; `datos/intermedios/mochila/mochila_neta_2024.csv`):
- **Cobertura:** 46 provincias de régimen común. País Vasco y Navarra no están en las tablas de la AEAT (forales aparte); Ceuta y Melilla no están en el módulo de año completo.
- **Bruto anual:** 18.334 € de media de las provincias ponderada por asalariados.
- **Neto mensual:** de 990 € (Huelva) a 1.529 € (Barcelona); media ponderada, 1.330 €. La relación neto/bruto es 0,87.

**Opciones descartadas.** Las opciones A y C se siguen calculando como registro (`mochila_opciones`):
- La opción A sale entre 1,24 y 1,49 veces la B (mediana, 1,34). Media ponderada: 24.257 € frente a 18.334 €.
- Frente a la ECV 2025, A queda un 14 % por encima de la mediana de quienes trabajan los doce meses. B queda un 1,7 % por debajo de la mediana de todos los asalariados, en media ponderada de las comunidades (plan §3.1).

### 6.3 Tartera: salario mínimo

**Cálculo** (plan §3.1; `perfiles_fichas()`, `SMI_FICHAS`; objetivo `perfiles`). Ingreso neto mensual = SMI mensual × 14 pagas × (1 − cotización del trabajador) / 12, sin retención de IRPF:
- 2026: 1.221 € × 14 = 17.094 € brutos anuales (RD 126/2026). Con una cotización del 6,50 % (MEI, 0,15 %), 1.331,91 € netos al mes: es la cifra de la web. La comprobación `smi_neto` la compara con los 1.332 € del plan (§4.1).
- 2024: 1.134 € × 14 (RD 145/2024). Con una cotización del 6,47 %, 1.237,40 € netos al mes. Sirve para la barrera de 2024, con el alquiler del mismo año (§7.4).

**Comparación con la mochila.**
- La mochila de 2024 (1.330 € netos de media) sale casi igual que la tartera con el SMI de 2026. Son años distintos (regla 4).
- Con el SMI de 2024 (1.237 € netos), la mochila queda un 7,5 % por encima (plan §3.1).
- La exención de IRPF del SMI vale para quien lo cobra el año entero. La tabla de la AEAT da retenciones del 1,6–1,8 % también por debajo de 12.000 €.

### 6.4 Llave: hogar del barrio

**Ingreso** (`perfiles`): la renta neta media por hogar del ADRH de cada sección (indicador 2, §5) ÷ 12, con el estado de su reproyección. En 2024, en las 36.237 secciones con valor: percentil 10, 2.319 €; mediana, 3.021 €; percentil 90, 4.501 € al mes (`resumen_perfiles_llave`).

**Vivienda:** el alquiler mediano de vivienda colectiva de la propia sección, sin superficie fija. Es la única ficha que varía por los dos lados, el ingreso y el alquiler.

**Esfuerzo:** el cruce con el SERPAVI es el indicador 14 (§7.4).

---

## 7. Alquiler, hogares en alquiler, viviendas turísticas, derivados y sobrecarga

### 7.1 Alquiler (indicadores 8 y 9)

**Fuente.** La base de datos del SERPAVI del MIVAU (`mivau_serpavi`), edición 2011–2024. Es un Excel con una hoja por nivel: comunidades (con el total de España), provincias, municipios, distritos y secciones. Toda la serie está en el seccionado de 2021 (plan §6.3). El fichero se baja a mano (§2.1); la columna `version` lleva su fecha, 6-nov-2026.

**Qué mide.** Contratos de vivienda habitual vigentes declarados en el IRPF y cruzados con el Catastro. Es el parque alquilado, no los contratos nuevos (guía, regla 5).

**Lectura** (`leer_mivau_serpavi()`; objetivo `serpavi`, 1.099.500 filas). Una fila por territorio, año (desde 2015) y tipología: vivienda colectiva (`VC`) y unifamiliar o rural (`VU`). Cada fila trae el recuento de testigos y la mediana, el primer y el tercer cuartil del alquiler mensual y del alquiler por m². España sale de la fila sin código de la hoja de comunidades y solo trae el recuento.

**Tabla larga** (`armonizar_mivau_serpavi()`; objetivo `larga_serpavi`, 3.927.860 filas; plan §6.4):
- indicadores `alquiler_mes` (8) y `alquiler_m2` (9);
- la mediana, en el corte `tipologia`, con los grupos `VC` y `VU`; los cuartiles, en los cortes `tipologia_p25` y `tipologia_p75`, solo donde hay dato;
- sin filas `total`: el SERPAVI no publica una mediana conjunta de las dos tipologías (§1);
- niveles: sección, distrito, municipio, provincia y comunidad. España no tiene medianas y queda fuera;
- `geo_ref = 2021`, sin tabla de paso;
- valores con la precisión de la fuente, sin redondear. Los derivados toman el valor redondeado a un decimal, el mismo que recibe la web (§7.4).

**Estados** (`estado_serpavi()`):
- `dato`: mediana publicada;
- `secreto`: de 1 a 9 testigos. La fuente solo publica el recuento; el valor queda vacío, nunca 0;
- `ausente`: sin testigos; provincias forales antes de su entrada (`ENTRADA_SERPAVI_FORALES`: Navarra 2021, Gipuzkoa 2022, Álava y Bizkaia 2024; ruptura `serpavi_forales`); municipios y distritos que no cuadran con sus secciones (plan §11, pregunta 13).

**Cobertura territorial** (`larga_serpavi`, `jerarquia_2021`):
- La base tiene 36.293 de las 36.333 secciones de 2021. Las 40 restantes no tienen ninguna fila en la tabla larga: 36 son municipios de una sola sección (34 de Navarra, uno de Álava y uno de Bizkaia) y 4 son secciones de Madrid, Las Palmas de Gran Canaria (2) y Zaragoza.
- Quedan fuera 4 municipios y 68 distritos de las hojas que no existen en el seccionado de 2021 (`estado_serpavi()`).
- En la tabla larga hay 8.095 municipios, 10.443 distritos, 52 provincias y 19 comunidades.

**Errores de las hojas de municipios y distritos** (alerta `serpavi_escalas_detalle`, `descuadres_serpavi()`; plan §11, pregunta 13). Son 164 cifras de territorio, año y tipología que no cuadran con sus secciones. Van como `ausente`, y las secciones conservan su dato:
- en Navarra: 82 municipios de 2022 con la mediana y el P25 de vivienda colectiva cruzados; 18 distritos de 2022 con los recuentos desplazados una fila (31 filas); 40 filas de municipio de 2023 y 2024 sin el recuento que sí tienen sus secciones;
- fuera de Navarra, todas en 2022: 7 municipios con mediana de vivienda unifamiliar y 0 testigos; el distrito 4622101 (2 filas); un recuento no entero en Valmadrid (50275); Cabanes (17030), con un alquiler por m² distinto del de su única sección.

(`inventario/referencias_validacion.csv`.)

**Resultado: secciones por año y tipología** (`resumen_larga_serpavi`; las dos últimas columnas, de `larga_serpavi`). El indicador 9 tiene los mismos estados que el 8.

| Año | `VC`: `dato` | `VC`: `secreto` | `VC`: `ausente` | `VU`: `dato` | `VU`: `secreto` | `VU`: `ausente` | Con alguna mediana | Solo secreto |
|---|---|---|---|---|---|---|---|---|
| 2015 | 21.627 | 5.995 | 8.671 | 5.543 | 15.250 | 15.500 | 23.497 | 7.885 |
| 2016 | 22.051 | 5.749 | 8.493 | 6.065 | 15.073 | 15.155 | 24.086 | 7.474 |
| 2017 | 22.447 | 5.511 | 8.335 | 6.537 | 14.907 | 14.849 | 24.575 | 7.059 |
| 2018 | 22.820 | 5.289 | 8.184 | 6.972 | 14.709 | 14.612 | 25.024 | 6.719 |
| 2019 | 23.136 | 5.123 | 8.034 | 7.430 | 14.443 | 14.420 | 25.444 | 6.391 |
| 2020 | 23.415 | 5.063 | 7.815 | 7.823 | 14.335 | 14.135 | 25.844 | 6.142 |
| 2021 | 23.988 | 5.023 | 7.282 | 8.180 | 14.409 | 13.704 | 26.440 | 6.160 |
| 2022 | 24.671 | 4.954 | 6.668 | 8.386 | 14.528 | 13.379 | 27.192 | 5.995 |
| 2023 | 24.878 | 4.861 | 6.554 | 8.697 | 14.412 | 13.184 | 27.420 | 5.862 |
| 2024 | 26.137 | 4.849 | 5.307 | 9.065 | 14.482 | 12.746 | 28.735 | 5.791 |

- «Con alguna mediana»: `dato` en al menos una tipología.
- «Solo secreto»: la sección tiene testigos, pero ninguna tipología llega a 10.
- Las cifras de 2024 reproducen las del plan (§2.4).

**Cobertura de la vivienda colectiva por provincia** (% de secciones con mediana; `resumen_larga_serpavi`, elemento `provincias`). Las cinco más bajas y las cinco más altas en 2024, y las forales que faltan:

| Provincia | 2015 | 2020 | 2024 |
|---|---|---|---|
| Soria | 18,1 | 19,4 | 19,4 |
| Cuenca | 16,1 | 20,0 | 21,9 |
| Teruel | 19,3 | 21,8 | 22,5 |
| Zamora | 21,6 | 23,8 | 24,1 |
| Ávila | 21,5 | 25,3 | 27,6 |
| Illes Balears | 86,7 | 88,8 | 91,1 |
| Bizkaia | — | — | 92,2 |
| Barcelona | 90,7 | 92,2 | 92,6 |
| Madrid | 92,3 | 94,4 | 95,1 |
| Gipuzkoa | — | — | 95,4 |
| Navarra | — | — | 68,6 |
| Álava | — | — | 80,8 |

«—»: antes de la entrada de la provincia en el SERPAVI.

**Valores de 2024, vivienda colectiva** (`larga_serpavi`):
- En las 26.137 secciones con dato, la mediana de cada sección va de 150 a 3.504 €/mes. Percentil 10, 370 €; mediana, 570 €; percentil 90, 893 €. En alquiler por m²: 4,2, 7,3 y 12,7 €/m².
- Provincias: Madrid, 800 € y 12,1 €/m²; Barcelona, 753 € y 11,0 €/m²; Bizkaia, 734 € y 10,2 €/m²; Navarra, 598 € y 6,9 €/m².

**Compuerta** (`comprobar_mivau_serpavi()`; §4.1): `serpavi_provincia`, `serpavi_espana`, `serpavi_secreto`, `serpavi_cuartiles` y `serpavi_escalas` (bloqueo), y `serpavi_escalas_detalle` y `serpavi_forales` (alerta). Las medianas no se agregan: la compuerta suma testigos y comprueba las reglas de la fuente.

**Territorios forales** (ruptura `serpavi_forales` en `inventario/rupturas.csv`). Antes de su entrada, esas secciones van sin dato. La estadística de fianzas del Gobierno Vasco (`gv_emal`) no baja a sección y da la media, no la mediana: se muestra como capa municipal aparte (plan §11, pregunta 8).

### 7.2 Hogares en alquiler (indicador 18)

**Fuente.** El CSV de indicadores por sección del Censo de Población y Viviendas 2021 del INE (`ine_censo2021`), en el seccionado de 2021: no necesita tabla de paso. La columna `version` lleva la fecha del fichero, 8-nov-2026.

**Cálculo** (`leer_ine_censo2021()`, `armonizar_ine_censo2021()`; objetivo `larga_censo2021`). Hogares en alquiler (%) = 100 × `t20_2` (viviendas principales en alquiler) / `t19_1` (viviendas principales). Cada vivienda principal es un hogar: en ninguna sección con los dos recuentos difieren `t21_1` (hogares) y `t19_1` (`censo2021`). El valor se guarda sin redondear.

**Estados:**
- `dato`: 34.970 secciones;
- `secreto`: 1.363 secciones con el bloque de vivienda en blanco (falta `t19_1` o `t20_2`);
- `ausente` (sin viviendas principales): ninguna.

El secreto se concentra en provincias rurales: Guadalajara, 173 de 394 secciones; Burgos, 161 de 587; Soria, 118 de 216; Ávila, 95 de 312; Teruel, 94 de 285. En 19 provincias no hay ninguna sección en secreto (`larga_censo2021`).

**Resultado** (las 36.333 secciones del seccionado de 2021). Va de 0 a 65,5 % (0801909055, en Barcelona). Percentil 1, 2,9 %; percentil 10, 6,1 %; mediana, 13,8 %; percentil 90, 26,9 %; percentil 99, 40,0 %. 12 secciones tienen 0 %.

**Rareza de la fuente.** En 78 secciones, propiedad, alquiler y otro régimen (`t20_1` + `t20_2` + `t20_3`) no suman las viviendas principales (`censo2021`). El porcentaje usa igualmente `t20_2` / `t19_1`.

**Compuerta** (`comprobar_ine_censo2021()`; §4.1). Se compara con la tabla 59523 del Censo 2021. España: 16,10 % de hogares en alquiler en las secciones y en la tabla. La tabla solo cuenta viviendas convencionales; por eso, en algunas provincias las secciones suman más hogares (`inventario/referencias_validacion.csv`).

**Censo 2011** (plan §11, pregunta 14). Está en el seccionado de 2011 y no hay tabla de paso de 2011 a 2021: la v0.1 lleva solo el corte de 2021. La tabla de paso 2011 → 2021 (callejero y seccionado de 2011, más la vía b) se construye en F6, con el histórico.

### 7.3 Viviendas de uso turístico (indicador 19)

**Fuente.** La estadística experimental del INE sobre viviendas turísticas, a partir de los anuncios de las plataformas (`ine_vut`). La tabla 5 (distritos y secciones) es un xlsx por periodo, con 13 periodos semestrales de agosto de 2020 a mayo de 2026 (`PERIODOS_VUT`). Las tablas 39364 (viviendas) y 39365 (porcentaje) dan las provincias. La columna `version` lleva la fecha del último fichero, 8-nov-2026.

**Seccionado de cada periodo** (comprobado código a código el 8-nov-2026; ruptura `vut_seccionado_2024` en `inventario/rupturas.csv`):

| Periodos | Secciones del fichero | Denominador del porcentaje del INE |
|---|---|---|
| Agosto de 2020 – febrero de 2023 (6) | 35.960, las del Censo 2011 | Viviendas del Censo 2011 |
| Agosto de 2023 | 37.063 códigos: las del Censo 2011 y otras de seccionados posteriores | Viviendas del Censo 2021 (`inventario/indicadores.csv`) |
| Febrero de 2024 | Seccionado de 2024, más 258 códigos antiguos sin viviendas turísticas | Viviendas del Censo 2021 (`t18_1`) |
| Agosto de 2024 – mayo de 2026 (5) | Seccionado de 2024 (36.477 secciones) | Viviendas del Censo 2021 (`t18_1`) |

**Periodos del atlas** (plan §11, pregunta 14). Los seis del seccionado de 2024, de febrero de 2024 a mayo de 2026 (`PERIODOS_VUT_2024`). Los siete anteriores se leen (`leer_ine_vut()`) y entran en la compuerta de recuentos provinciales, pero no en el indicador: no hay tabla de paso desde el seccionado de 2011, que se construye en F6. Se descartó usar para esos años el nivel municipal del INE, porque mezclaría escalas en la serie.

**Cálculo en el seccionado de 2021** (`reproyectar_ine_vut()`; objetivo `vut_2021`):
- Las viviendas turísticas de cada sección de 2024 pasan a 2021 con la tabla combinada 2024 → 2021 (`paso_final_2024`; §3.5), como recuento (`geo_reproyectar_recuento()`).
- Si la sección de 2021 recibe una sola sección de 2024, entera, se copia el porcentaje del INE. Son 35.131 secciones (`secciones_1a1_vut()`).
- En las demás, porcentaje = 100 × viviendas turísticas reproyectadas / viviendas del Censo 2021 de la sección (`t18_1`), el mismo denominador que usa el INE.

**Estados:**
- `dato`: sección 1:1 o suma de secciones enteras;
- `estimado`: alguna sección de 2024 se reparte (877 secciones);
- `secreto`: porcentaje protegido por el INE o viviendas del Censo 2021 en secreto;
- `ausente`: la sección no recibe nada de la tabla de paso. Es una sola: 0309002003, la excepción de cobertura de Mutxamel (§3.8).

**Secreto.** El INE publica siempre el número de viviendas turísticas y protege el porcentaje en algunas secciones. En el seccionado de 2021 quedan en `secreto` 1.371 secciones en febrero y agosto de 2024 y 172 desde noviembre de 2024; todas son secciones 1:1 (`vut_2021`).

**Tabla larga** (`armonizar_ine_vut()`; objetivo `larga_vut`, 217.998 filas: 6 periodos por 36.333 secciones; plan §6.4):
- `anio`: el año del mes de referencia;
- `corte = mes` y `grupo` `M02`, `M05`, `M08` o `M11`;
- sin filas `total`: la web toma el último mes;
- mes y no semestre: el calendario cambió en 2024, que tiene tres periodos (ruptura `vut_calendario_2024`).

**Resultado** (`larga_vut`; viviendas turísticas, suma de `vut_2021`). La mediana y el percentil 90 van con dos decimales:

| Periodo | `dato` | `estimado` | `secreto` | `ausente` | Viviendas turísticas (España) | Mediana (%) | Percentil 90 | Percentil 99 | Máximo | Secciones con 0 % |
|---|---|---|---|---|---|---|---|---|---|---|
| Febrero de 2024 | 34.084 | 877 | 1.371 | 1 | 351.389 | 0,25 | 2,16 | 9,8 | 36,8 | 11.022 |
| Agosto de 2024 | 34.084 | 877 | 1.371 | 1 | 403.267 | 0,30 | 2,50 | 11,1 | 38,5 | 10.111 |
| Noviembre de 2024 | 35.283 | 877 | 172 | 1 | 376.463 | 0,27 | 2,32 | 10,3 | 38,5 | 11.282 |
| Mayo de 2025 | 35.283 | 877 | 172 | 1 | 381.837 | 0,26 | 2,35 | 10,7 | 38,7 | 11.442 |
| Noviembre de 2025 | 35.283 | 877 | 172 | 1 | 329.764 | 0,19 | 2,02 | 9,8 | 37,9 | 13.435 |
| Mayo de 2026 | 35.283 | 877 | 172 | 1 | 341.001 | 0,20 | 2,12 | 9,8 | 52,4 | 13.405 |

- La suma de viviendas turísticas es igual a la de la tabla 39364 (`vut_paso_2021`).
- Las cifras de distribución son de las secciones con `dato` o `estimado`.
- El máximo de mayo de 2026 es la sección 2906703002, 1:1, con el porcentaje copiado del INE: 460 viviendas turísticas sobre 878 viviendas.

**Mismo año** (guía, regla 4). Numerador y denominador no son del mismo año: las viviendas son las del Censo 2021, como en el INE. La ficha lo dice (`inventario/indicadores.csv`).

**Compuerta** (`comprobar_ine_vut()`; §4.1). Las secciones suman exactamente los totales provinciales publicados en los 13 periodos, también después de la tabla de paso. En las secciones 1:1, el porcentaje del INE es 100 × viviendas turísticas / `t18_1`; desde noviembre de 2024, entre 194 y 225 secciones por periodo se apartan hasta 0,09 puntos (`inventario/referencias_validacion.csv`).

### 7.4 Derivados (indicadores 14, 15 y 21)

**Definición** (plan §5, bloque C; `inventario/indicadores.csv`):

| # | Indicador | Fórmula | Unidad | Términos |
|---|---|---|---|---|
| 14 | Esfuerzo de residentes | Alquiler mediano mensual × 12 / renta neta media por hogar, del mismo año | % de la renta del hogar | Indicadores 8 y 2 |
| 15 | Barrera de acceso | Alquiler mediano por m² × 50 / ingreso neto mensual de la ficha | % del ingreso de la ficha | Indicador 9 e ingreso de la ficha (§6) |
| 21 | Sueldo neto necesario (mapa por defecto) | Alquiler mediano por m² × 50 / 0,30 (umbral cambiable al 40 %) | € netos al mes | Indicador 9 |

**Tipología** (plan §11, pregunta 12): el alquiler de los tres es el de la vivienda colectiva (`grupo = VC`).

**Estado** (plan §11, pregunta 15; `peor_estado()`): el peor de sus términos, en el orden `dato` < `estimado` < `secreto` < `ausente`.
- Una sección con el alquiler en secreto queda en `secreto`.
- Con el alquiler `dato` y la renta `estimado`, el esfuerzo queda `estimado`.
- Si falta algún término, `ausente`. Es el caso de la barrera con la mochila en País Vasco, Navarra, Ceuta y Melilla, donde la ficha no tiene ingreso (§6.2).
- El 21 tiene un solo término: lleva el estado del indicador 9.

**Términos redondeados** (plan §11, pregunta 19; `termino_publicado()`). El alquiler, la renta por hogar y el ingreso de la ficha entran en el cálculo redondeados a un decimal con `sprintf("%.1f")` (§0), como los recibe la web. Así, la cifra de R y la que la web recalcula en el navegador coinciden exactamente.

**Mismo año** (guía, regla 4). En el esfuerzo, el SERPAVI y el ADRH coinciden en 2015–2024. La barrera de la tabla larga usa ingresos de 2024, el año del último alquiler: la mochila (AEAT de 2024) y la tartera con el SMI de 2024. La web usa la tartera con el SMI de 2026; cuando los años no coinciden, se dice en la ficha y en la web.

**Cómo se leen:**
- El indicador 15 se lee por tramos: hasta el 30 %, del 30 al 40 % y más del 40 %.
- El indicador 21 es el alquiler expresado en otra unidad. El umbral del 30 % se inspira en el criterio de zona tensionada de la Ley 12/2023 (art. 18), que usa la renta del hogar y los suministros; no es ese criterio.
- El 15 y el 21 cambian con el umbral, la superficie y el sueldo de «Tu ficha»: la web los recalcula en el navegador (plan §6.6).

**Cálculo** (`armonizar_derivados()`; objetivo `larga_derivados`, 1.103.301 filas, fuente `calculo_propio`):
- **14** (`calcular_esfuerzo_residentes()`): en las secciones y los municipios, los niveles en que el SERPAVI y el ADRH publican los dos términos (`NIVELES_ESFUERZO`), y en los años con los dos, 2015–2024. Sin desglose.
- **21** (`calcular_sueldo_necesario()`): en todos los niveles del SERPAVI, 2015–2024, con 50 m² y el umbral del 30 %. Sin desglose.
- **15** (`calcular_barrera_acceso()`): corte `ficha`, con los grupos `mochila` y `tartera`, solo en 2024. La mochila, en las provincias y sus secciones, distritos y municipios; la tartera, también en las comunidades. Es un control: la web calcula la barrera con la ficha elegida.
- **Ingresos de las fichas** (`perfiles_fichas()`; objetivo `perfiles`): la tartera (§6.3); la mochila de cada provincia, con su código del INE en `inventario/provincias_aeat.csv` (46 provincias con dato y 6 `ausente`); la llave (§6.4).
- **Versión:** la más reciente de sus términos, 7-nov-2026.

**Resultado: esfuerzo de residentes (14) en las secciones** (`larga_derivados`):

| Año | `dato` | `estimado` | `secreto` | `ausente` | Percentil 10 (%) | Mediana (%) | Percentil 90 (%) |
|---|---|---|---|---|---|---|---|
| 2015 | 20.671 | 937 | 6.014 | 8.711 | 13,0 | 17,6 | 23,8 |
| 2016 | 20.988 | 874 | 5.938 | 8.533 | 12,8 | 17,4 | 23,7 |
| 2017 | 21.888 | 543 | 5.527 | 8.375 | 12,8 | 17,3 | 23,8 |
| 2018 | 22.600 | 206 | 5.303 | 8.224 | 12,6 | 17,2 | 23,9 |
| 2019 | 22.989 | 134 | 5.136 | 8.074 | 12,8 | 17,7 | 24,7 |
| 2020 | 23.413 | 0 | 5.065 | 7.855 | 13,1 | 18,2 | 25,7 |
| 2021 | 23.858 | 130 | 5.023 | 7.322 | 13,0 | 18,1 | 25,4 |
| 2022 | 24.235 | 433 | 4.957 | 6.708 | 12,9 | 17,9 | 24,9 |
| 2023 | 24.275 | 592 | 4.872 | 6.594 | 12,6 | 17,6 | 24,2 |
| 2024 | 25.271 | 854 | 4.861 | 5.347 | 12,6 | 17,6 | 24,0 |

- El esfuerzo tiene fila en las 36.333 secciones: también en las 40 que no están en el SERPAVI, que quedan `ausente`.
- El `estimado` viene de la renta reproyectada (§5.4): el alquiler no se reproyecta.
- El sueldo necesario (21) tiene los mismos estados que el alquiler de vivienda colectiva (§7.1).

**Valores de 2024 en las secciones** (`larga_derivados`):

| Indicador | Secciones con valor | Mínimo | Percentil 10 | Mediana | Percentil 90 | Máximo |
|---|---|---|---|---|---|---|
| Esfuerzo de residentes (%) | 26.125 | 6,2 | 12,6 | 17,6 | 24,0 | 51,3 |
| Sueldo neto necesario (€ al mes) | 26.137 | 300 | 700 | 1.217 | 2.117 | 4.283 |
| Barrera con la mochila (%) | 24.117 | 7,2 | 16,8 | 27,5 | 43,7 | 87,9 |
| Barrera con la tartera, SMI de 2024 (%) | 26.137 | 7,3 | 17,0 | 29,5 | 51,3 | 103,8 |

Con la mochila, 7.576 secciones quedan `ausente` en 2024: todas las de País Vasco, Navarra, Ceuta y Melilla, donde la ficha no tiene ingreso, y las que no tienen alquiler.

**Compuerta** (`comprobar_derivados()`, `validacion_derivados`; §4.1): `derivados_terminos`, `derivados_estado`, `derivados_rango`, `perfiles_mochila` y `smi_neto` (bloqueo), y `derivados_rango_detalle` (alerta).

### 7.5 Sobrecarga y acceso (indicadores 22 y 23, v0.0)

**Método de Eurostat** (`calcular_sobrecarga_ecv()`, `tasa_sobrecarga()`):
- cuenta personas, no hogares;
- cociente: gastos de vivienda menos ayudas entre renta disponible menos ayudas, por encima del 40 %;
- de la hipoteca, solo los intereses;
- la renta es la del año anterior a la encuesta.

**Olas.** Tres olas de la ECV (2023–2025). Comunidad × tenencia y comunidad × edad se calculan con las tres olas agrupadas (`sobrecarga_agrupada`). Todas las celdas superan las 50 observaciones (plan §7, F1b).

**Compuerta frente a Eurostat** (`comprobaciones_sobrecarga`):

| Ola | España: calculado (Eurostat) | Inquilinos a precio de mercado: calculado (Eurostat) |
|---|---|---|
| 2023 | 8,24 % (8,2) | 30,61 % (30,6) |
| 2024 | 7,77 % (7,8) | 28,07 % (28,1) |
| 2025 | 7,17 % (7,2) | 26,80 % (26,8) |

Las 19 comunidades y los cuatro grupos de edad quedan dentro de ±0,05 puntos (plan §7, F1b).

**Intervalos.** Se publica sin intervalos, con el número de observaciones y la marca de fiabilidad de EU-SILC (`fiabilidad_eusilc()`). Los microdatos públicos no traen estratos ni unidades primarias de muestreo (plan §11, pregunta 9).

**Indicador 23.** Sale de las tablas del módulo de acceso a la vivienda de la ECV 2025: por comunidad, por edad y sexo, y por tenencia (`armonizar_ine_ecv_modulo()`, `armonizar_ine_ecv_modulo_cortes()`).

---

## 8. Limitaciones conocidas

**Geografía constante:**
- **Errores residuales.** Las cifras `estimado` llevan un error residual. En la prueba de un año de toda España, 37 de las 6.180 secciones que el callejero reparte siguen fuera de [0,8; 1,25] con la tabla combinada (§3.9). Con cuatro o cinco años de distancia no se puede separar ese error del crecimiento real de los barrios.
- **El Catastro es una foto actual** (`inventario/fuentes.csv`, periodo «actual»). Los edificios demolidos antes de la descarga no están. El año de construcción es el original (`beginning`), aunque el edificio se haya reformado o ampliado. 1.574 edificios no tienen año y cuentan en todas las tablas.
- **La prueba de cierre es débil por construcción** (§3.9). La detección de errores de reparto descansa en la prueba de un año.
- **Secciones fuera de la serie.** Las nueve secciones huérfanas del ADRH quedan fuera de la tabla de paso. Las dos excepciones de cobertura dejan una sección de 2021 sin dato en seis años-sección (§3.8) y una sin viviendas turísticas (§7.3).
- **Cambios de límites posteriores a 2021.** Las secciones que cambian después de 2021 se dibujan con sus límites de 2021 (§3.1).

**Jerarquía y mapa base:**
- Los distritos no tienen nombre (§3.10).
- Por debajo del zoom 12, los bordes se simplifican medio píxel; por encima, MapLibre amplía las teselas del zoom 12 (§3.10).

**Renta:**
- **La fuente no cuadra entre escalas.** El ADRH no siempre suma sus secciones al total municipal (`adrh_suma_secciones`, 160 municipios y años en 2015–2019). Sus medias de sección agregadas se separan más de un 5 % de la cifra municipal en 135 cifras (`adrh_municipio_detalle`). El atlas no lo corrige: muestra la cifra publicada en cada escala.
- **Hogares aproximados.** Salen de un tamaño medio del hogar redondeado a un decimal (§5.1).
- **País Vasco y Navarra en 2015–2019.** El ADRH no los publica por sección esos años: esas secciones van como `secreto` (§5.4).

**Alquiler:**
- **Parque, no contratos nuevos.** El SERPAVI mide el parque alquilado: quien entra hoy paga más (indicador 8).
- **Secreto y cobertura.** En 2024, 4.849 secciones tienen la mediana de vivienda colectiva en secreto. La cobertura va del 19,4 % de las secciones en Soria al 95,4 % en Gipuzkoa: las zonas rurales tienen menos dato (§7.1).
- **Dos tipologías sin mediana conjunta.** El mapa por defecto muestra la vivienda colectiva; la unifamiliar va aparte (§1).
- **Territorios forales.** Series cortas: Navarra desde 2021, Gipuzkoa desde 2022, Álava y Bizkaia desde 2024 (§7.1).
- **Secciones sin fila.** 40 secciones de 2021 no están en la base del SERPAVI (§7.1).
- **Errores de la fuente.** 164 cifras de municipios y distritos van como `ausente` (§7.1).

**Hogares en alquiler:**
- Es una fotografía de 2021, no una serie (§7.2).
- 1.363 secciones están en secreto, sobre todo en provincias rurales (§7.2).

**Viviendas turísticas:**
- **Años distintos.** El denominador son las viviendas del Censo 2021 (§7.3).
- **Anuncios de plataformas.** Es una estadística experimental del INE construida con anuncios, no un registro (`inventario/indicadores.csv`).
- **Serie corta.** Empieza en febrero de 2024; de 2020 a 2023, en F6 (§7.3).
- **Meses distintos.** Los meses de referencia cambiaron en 2024 (§7.3).
- **Reparto.** 877 secciones son `estimado` en cada periodo (§7.3).

**Derivados:**
- **Huecos heredados.** Un derivado no tiene valor donde falta alguno de sus términos: en 2024, 10.208 de las 36.333 secciones no tienen esfuerzo (§7.4).
- **Vulnerabilidad, no acceso.** El esfuerzo divide el alquiler entre la renta media de todos los hogares de la sección, no solo la de los que alquilan (`inventario/indicadores.csv`).
- **La barrera de la tabla larga es un control.** Solo con la mochila y la tartera de 2024; la web la calcula con la ficha elegida (§7.4).

**Mochila:**
- **Supuestos:**
  - la relación mediana/media del SME de una comunidad vale para todas sus provincias;
  - la distribución dentro de cada decil nacional es la del país;
  - la retención de la nómina es la media de todas las edades;
  - la cotización es la de un contrato indefinido.
- **Cobertura.** Sin País Vasco, Navarra, Ceuta ni Melilla (§6.2).
- **Lo cobrado en el año.** La ficha usa lo cobrado en el año, que incluye a quien trabajó pocos meses; la ficha lo dice.

**Años distintos entre fichas.** La tartera (SMI de 2026) y la mochila (AEAT de 2024) son de años distintos, y a escala de España dan ingresos casi iguales (§6.3).

**Licencias.** El Catastro estatal y los forales de Bizkaia y Gipuzkoa tienen licencias contradictorias y se tratan como datos abiertos por decisión del autor (§2.2).

**Sobrecarga.** Se publica sin intervalos de confianza (§7.5).

**Desfase.** La renta y los salarios van uno o dos años por detrás del año en curso (§1).

---

## 9. Tabla larga y datos de la web

### 9.1 Tabla larga

**Esquema** (plan §6.4): `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo`, `valor`, `estado`, `fuente`, `geo_ref` y `version`. La clave de una fila es `geo_id`, `nivel`, `anio`, `indicador`, `corte` y `grupo`.

**Contenido** (`tabla_larga`; `exportar_tabla_larga()`, `datos/intermedios/tabla_larga.parquet`): 6.589.269 filas.

| Fuente (`fuente`) | Filas | Niveles | Versión |
|---|---|---|---|
| `ine_adrh` | 1.303.484 | Sección (1.089.972) y municipio (213.512) | 7-nov-2026 |
| `mivau_serpavi` | 3.927.860 | Sección (2.691.192), distrito (715.704), municipio (512.812), provincia (5.992) y comunidad (2.160) | 6-nov-2026 |
| `ine_censo2021` | 36.333 | Sección | 8-nov-2026 |
| `ine_vut` | 217.998 | Sección | 8-nov-2026 |
| `ine_ecv` | 261 | Comunidad (228) y España (33) | 6-nov-2026 |
| `ine_ecv_modulo` | 32 | Comunidad (19) y España (13) | 6-nov-2026 |
| `calculo_propio` | 1.103.301 | Sección (798.846), distrito (125.316), municipio (178.306), provincia (624) y comunidad (209) | 7-nov-2026 |

**Por estado:** `dato`, 4.689.443 filas; `ausente`, 1.026.746; `secreto`, 842.257; `estimado`, 30.823.

**Sin publicar.** No hay todavía datos publicados: la carpeta `datos/publicados/` no existe.

### 9.2 Datos de la web

La exportación sigue las decisiones del autor del 8-nov-2026 (plan §6.6; plan §11, preguntas 16 y 17). `exportar_web()` (objetivo `ficheros_web`) escribe en `web/datos/`, desde la tabla larga ya validada, los indicadores del núcleo de la v0.1, de la sección a España:
- **Valores.** Un fichero JSON por serie, nivel y periodo, con los valores × 10 en enteros (redondeo de la guía; un decimal exacto) y una cadena con el estado de cada territorio, en el orden del índice de su nivel. Comprimido pesa lo mismo que un binario: de 57 a 121 KB por indicador y año en las secciones.
- **Series de la ficha.** Un fichero por municipio (`fichas/<municipio>.json`) con las series de sus secciones y del propio municipio.
- **Qué no se exporta.** Los cuartiles del SERPAVI y la barrera (15), que la web calcula con la ficha elegida. El sueldo necesario (21) se recalcula en el navegador desde el alquiler por m² cuando cambian la superficie o el umbral (`FORMULAS_WEB`).
- **Otros ficheros.** Los nombres de los territorios, los rectángulos de los municipios para el buscador (`cajas_municipios`) y los ingresos de las fichas (`perfiles`). El mapa base se copia a `web/teselas/`; al publicar, sale de un *release* (§3.10).
- **Volumen** (`ficheros_web`, 11:59): 8.479 ficheros y 120,1 MB, con el PMTiles.
- **Compuerta** (`comprobar_web()`, `validacion_web`): `web_valores` y `web_fichas` (bloqueo) y `web_fuera_indice` (alerta) (§4.1).

---

## 10. Cómo reproducir las cifras

**Requisitos.** R 4.6 con `renv` (`renv.lock`). Los datos brutos no están en git: el pipeline los descarga en `datos/brutos/`, salvo el Excel del SERPAVI, que se baja a mano (§2.1).

```r
renv::restore()                           # solo la primera vez
targets::tar_make()                       # descarga, calcula y pasa las compuertas
testthat::test_dir("pruebas/testthat")    # pruebas con datos inventados
targets::tar_read(validacion_f1)          # una compuerta: columnas calculado, referencia, correcto
```

**Duración.** Una pasada completa desde cero tarda unas tres horas y cuarto (plan §6.3):
- leer los edificios del Catastro estatal, 2 h 16 min;
- comparar límites, 21 min;
- leer los catastros forales, unos 17 min.

El mapa base tarda unos 4,5 minutos (plan §7, F1). Con `PROVINCIA=28` (variable de entorno, antes de `tar_make()`), el cálculo se limita a una provincia, y los ficheros llevan el código en el nombre.

**Objetivos citados en esta nota:**
- **Geografía:** `secciones_2021`, `tablas_paso_callejero`, `tablas_paso_finales`, `edificios_paso`, `edificios_forales`, `municipios_catastro_sel`, `grupos_municipio`, `huerfanas_adrh`, `fase_codigos`, `cambios_limites`, `comprobaciones_f1`, `diagnostico_f1`, `comparacion_vias`.
- **Jerarquía y mapa base:** `jerarquia_2021`, `territorios_2021`, `ficheros_jerarquia`, `fichero_mapa_base`, `resumen_mapa_base`.
- **Renta:** `comprobaciones_adrh`, `tablas_paso_adrh`, `larga_adrh`, `tabla_larga`.
- **Alquiler:** `serpavi`, `larga_serpavi`, `resumen_larga_serpavi`.
- **Hogares en alquiler y viviendas turísticas:** `censo2021`, `larga_censo2021`, `vut`, `vut_2021`, `larga_vut`.
- **Mochila:** `mochila_opciones`, `mochila`, `mochila_neta`, `retenciones_mochila`, `ecv_mochila`.
- **Fichas y derivados:** `perfiles`, `resumen_perfiles_llave`, `larga_derivados`.
- **Web:** `ficheros_web`, `cajas_municipios`.
- **Compuertas:** `validacion_f1`, `validacion_adrh`, `validacion_serpavi`, `validacion_censo2021`, `validacion_vut`, `validacion_derivados`, `validacion_jerarquia`, `validacion_mapa_base`, `validacion_web`, `validacion_sobrecarga`, `validacion_modulo`, `validacion_mochila`, `validacion_mochila_ecv`, `validacion_mochila_neto_ecv`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`.
