# Nota metodológica

*De renta en renta · versión 0.1, borrador · 8 de noviembre de 2026 · conforme al plan v0.19.*

Esta nota describe cómo se obtienen las cifras del atlas: fuentes, geografía constante, compuerta de validación, renta por sección censal e ingresos de las fichas. La versión inglesa se publicará más adelante.

## 0. Cómo se cita cada cifra

- **Trazabilidad.** Cada cifra lleva entre paréntesis su origen. Puede ser:
  - un objetivo del pipeline, que se lee con `targets::tar_read(<objetivo>)`;
  - una función de `R/`;
  - un fichero de `inventario/`;
  - una sección del plan (`docs/plan_integracion_atlas.md`, «plan §»).
- **Objetivos repetidos.** Los que terminan en `_<seccionado>` se repiten una vez por seccionado de origen, según `PASOS_2021` en `_targets.R`. Por ejemplo, `paso_final_2016` lleva el ADRH 2015.
- **Almacén de referencia.** Las cifras sin otra indicación salen de la pasada completa de toda España del 8-nov-2026. El objetivo `tabla_larga` es de las 10:02.
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
| v0.1 | Núcleo de 10 indicadores: 1–3, 8, 9, 14, 15, 18, 19 y 21 | Indicadores 1–3 calculados; los demás, pendientes (tabla siguiente) |
| v1.0 | Los 23 indicadores del catálogo (plan §5) | — |

**Núcleo de la v0.1** (`inventario/indicadores.csv`, columna `nucleo_v01`):

| # | Indicador | Fuente | Nivel nativo | Serie | Estado |
|---|---|---|---|---|---|
| 1 | Renta neta media por persona | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 2 | Renta neta media por hogar | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 3 | Mediana de la renta por unidad de consumo | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 8 | Alquiler mensual (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Pendiente |
| 9 | Alquiler por m² (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Pendiente |
| 14 | Esfuerzo de residentes en alquiler | SERPAVI y ADRH | Sección | 2015–2024 | Pendiente |
| 15 | Barrera de acceso al alquiler | SERPAVI e ingreso de cada ficha | Sección × ingreso | 2015–2024 | Pendiente |
| 18 | Hogares en alquiler | INE, Censo 2021 (y 2011) | Sección | 2011, 2021 | Pendiente |
| 19 | Viviendas de uso turístico | INE, estadística experimental | Sección (seccionado de 2021) | 2020–, semestral | Pendiente |
| 21 | Sueldo neto necesario (mapa por defecto) | SERPAVI | Sección | 2015–2024 | Pendiente |

**Indicador 7.** El salario provincial de la AEAT se adelanta en versión mínima. El indicador 15 lo necesita a través de la ficha «mochila» (plan §7, F2). La mochila ya está calculada para 2024 (`mochila_neta`, §6.2).

**Desfase.** El atlas va uno o dos años por detrás en renta y salarios. El ADRH tiene un desfase de unos 22 meses: el de 2024 se publicó el 19-10-2026. *Mercado de trabajo y pensiones* de la AEAT tiene uno de unos 11 meses (plan §8).

---

## 2. Fuentes y licencias

### 2.1 Fuentes que usa la v0.1

El inventario completo, con dirección, acceso, cadencia y notas, está en `inventario/fuentes.csv`. La columna `licencia` cita el texto de cada fuente.

| Fuente (`id`) | Organismo | Uso | Licencia (resumen de `fuentes.csv`) |
|---|---|---|---|
| `ine_adrh` | INE | Indicadores 1–3; población y hogares de las pruebas de la geografía | CC BY 4.0 |
| `mivau_serpavi` | MIVAU | Indicadores 8, 9, 14, 15 y 21 | Reutilización autorizada por el aviso legal del MIVAU (Ley 37/2007 y RD 1495/2011), citando la fuente y la fecha, sin desnaturalizar la información |
| `ine_censo2021` | INE | Indicador 18 | CC BY 4.0 |
| `ine_vut` | INE | Indicador 19 | CC BY 4.0 |
| `aeat_mercado_trabajo` | AEAT | Ficha «mochila» (indicador 7) | Reutilización libre, también comercial, citando la fuente y la fecha de última actualización |
| `boe_smi` | BOE | Ficha «tartera» | Reutilizable |
| `ine_ecv` | INE | Control de la mochila; indicador 22 | CC BY 4.0 |
| `ine_ecv_modulo` | INE | Indicador 23 | CC BY 4.0 |
| `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r` | Eurostat | Compuerta del indicador 22 | CC BY 4.0 |
| `eurostat_nuts` | Eurostat (GISCO) | Geometrías del mapa europeo | Uso no comercial con el aviso «© EuroGeographics para los límites administrativos». No es CC BY |
| `ine_seccionado` | INE | Seccionados de 2016 a 2025 | CC BY 4.0 |
| `ine_callejero` | INE | Tablas de paso, vía (a) | CC BY 4.0 |
| `catastro_inspire` | D. G. del Catastro | Tablas de paso, vía (b) | Contradictoria: ver abajo |
| `catastro_foral` | Diputaciones forales de Álava, Bizkaia y Gipuzkoa; Gobierno de Navarra | Vía (b) en País Vasco y Navarra | Distinta en cada territorio: ver abajo |
| `gv_emal` | Gobierno Vasco | Capa municipal de contexto (fianzas); no se mezcla con el indicador 8 | CC BY 4.0 |

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

Desde esa fecha, las tablas de paso combinadas con el Catastro se versionan en `geo/tablas_paso/combinada_<año>_2021.csv` (objetivo `fichero_paso_final_<seccionado>`).

**Excepciones:**
- Las geometrías NUTS de GISCO quedan fuera de la licencia de los derivados.
- La capa de precios de oferta de los portales no se redistribuye y está apagada por defecto (`PORTALES=FALSE`; plan §2.2).
- El código tiene licencia MIT (`LICENSE`).

**Atribución sugerida:** «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]» (`LICENCIA_DATOS.md`).

---

## 3. Seccionado de referencia y geografía constante

### 3.1 Referencia: el seccionado del Censo 2021

**Qué es.** El mapa y todas las series usan el seccionado del INE a 1 de enero de 2021: 36.333 secciones (`secciones_2021`; plan §1 y §6.3).

**Por qué.** En ese seccionado ya publican toda su serie:
- el SERPAVI (2011–2024);
- el Censo 2021 (indicador 18);
- la estadística experimental de viviendas turísticas (indicador 19, todos sus periodos).

Así, el alquiler, el Censo y las viviendas turísticas no necesitan tabla de paso. Solo la renta del ADRH, que se publica cada año en su propio seccionado, se reproyecta.

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

El ADRH 2020 usa una tabla identidad (`geo_tabla_identidad()`).

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
- **Sin cruzar municipios.** Los pares de municipios distintos se descartan, salvo dentro de un grupo de fusión o segregación (§3.6). Los límites municipales se digitalizan de forma distinta en cada seccionado; sin ese filtro, la prueba de cierre de 2015 fallaba en dos municipios de Madrid (±6–7 %; plan §6.3).
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
- **0309002003**, en Mutxamel (ADRH 2021–2024). En el mapa de 2021 es una zona agrícola de 11 km² sin viviendas en el Catastro, mientras el ADRH 2020 le da 1.110 habitantes. Desde 2022 el código está en otro sitio. Probable polígono mal rotulado en el seccionado de 2021.

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

---

## 4. Compuerta de validación

**Regla.** No se publica nada que no reproduzca las cifras de la fuente (guía, regla 3; plan §6.5). Cada comprobación tiene una fila en `inventario/referencias_validacion.csv`, con su referencia, su tolerancia y su tipo. Si una comprobación no tiene fila, el pipeline se detiene.

**Cómo se aplica.** `validar_referencias()` compara cada cifra calculada con su referencia:
- las de tipo `bloqueo` paran el pipeline;
- las de tipo `alerta` salen como avisos al final de `tar_make()`.

Los objetivos que alimentan la tabla larga dependen de su compuerta. Por ejemplo, `larga_adrh` se calcula después de `validacion_adrh`, y `tabla_larga`, después de `validacion_sobrecarga` y `validacion_modulo`.

La compuerta de la geografía (`validacion_f1`) no es todavía una dependencia de `larga_adrh`. Si falla, `tar_make()` se detiene, pero el orden de cálculo no garantiza que lo haga antes de reproyectar la renta. Mientras no haya datos publicados, esto no tiene efecto.

### 4.1 Comprobaciones en el pipeline

| `id` | Qué compara | Tolerancia | Tipo | Resultado | Objetivo |
|---|---|---|---|---|---|
| `adrh_municipio` | Mediana, por año e indicador, de la desviación entre las medias de sección agregadas a municipio y la cifra municipal | ±0,1 % | Bloqueo | 0,0 % en 2015–2024, renta por persona y por hogar | `validacion_adrh` |
| `cierre_poblacional` | Población reproyectada a 2021 frente a la suma de sus orígenes, por municipio o grupo | ±0,5 % | Bloqueo | Pasa en los nueve años (§3.9) | `validacion_f1` |
| `cobertura_destino` | Secciones de 2021 que no reciben nada | Exacto | Bloqueo | Ninguna, salvo las excepciones | `validacion_f1` |
| `sobrecarga_es_total`, `sobrecarga_es_mercado`, `sobrecarga_ccaa` | Sobrecarga con los microdatos de la ECV frente a Eurostat | ±0,1 puntos | Bloqueo | Pasan en 2023–2025 (§7) | `validacion_sobrecarga` |
| `modulo_acceso_lectura` | Suma de las comunidades frente al total nacional del módulo de la ECV 2025 | ±0,1 % | Bloqueo | Pasa | `validacion_modulo` |
| `i18n_completo`, `contraste_texto`, `rampa_contorno` | Diccionarios ES/EN y contrastes de la web | Exacto | Bloqueo | Pasan | `validacion_i18n`, `validacion_diseno` |
| `adrh_municipio_detalle` | Desviación de cada municipio entre las medias de sección agregadas y la cifra municipal | ±1 % | Alerta | Avisa en 579 de 146.306 cifras de municipio, año e indicador; 135 pasan del 5 % | `comprobaciones_adrh` |
| `adrh_suma_secciones` | Población por sección del ADRH sumada por municipio frente al total municipal de la misma tabla | ±0,5 % | Alerta | Avisa en 160 municipios y años, todos de 2015–2019 (38, 34, 30, 29 y 29) | `comprobaciones_f1` |
| `adrh_seccion_huerfana` | Secciones del ADRH sin código en ningún seccionado de 2016–2025 | Exacto | Alerta | 9 (§3.8) | `huerfanas_adrh` |
| `cobertura_destino_excepcion` | Secciones de 2021 vacías por un defecto conocido de la fuente | Exacto | Alerta | 2 secciones, 6 años-sección (§3.8) | `comprobaciones_f1` |
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
| `serpavi_provincia` | Testigos del SERPAVI por sección sumados a provincia, por año y tipología (las medianas no se agregan), frente a la hoja de provincias | Exacto | Bloqueo |
| `aeat_provincia` | Salario medio provincial leído frente a la tabla publicada de la AEAT | Exacto | Bloqueo |
| `smi_neto` | Ingreso de la tartera: 17.094 € × (1 − 0,065) / 12 ≈ 1.332 € | Exacto con los parámetros del año | Bloqueo |
| `adrh_aeat` | Renta del ADRH frente a la renta bruta de la AEAT por municipio | Tendencia coherente | Alerta |
| `serpavi_ipva` | Tendencia del SERPAVI frente al IPVA | Tendencia coherente | Alerta |

Las comprobaciones del SERPAVI se están incorporando al inventario (`serpavi_provincia` y otras), pero aún no tienen resultado en el almacén.

`adrh_aeat` y `serpavi_ipva` no tienen todavía una tolerancia numérica. `validar_referencias()` no admite tolerancias de texto, así que habrá que fijar una antes de que entren en el pipeline.

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

**Filas en la tabla larga.**
- La tabla larga (`datos/intermedios/tabla_larga.parquet`; `validar_tabla_larga()`, `exportar_tabla_larga()`) tiene 1.303.777 filas, de ellas 1.303.484 del ADRH.
- Nivel municipal: 73.777 filas por cada media y 65.958 de la mediana.
- La columna `version` lleva la fecha del fichero de la fuente: el ADRH, 7-nov-2026.
- No hay todavía datos publicados: la carpeta `datos/publicados/` no existe.

---

## 6. Ingresos de las fichas

### 6.1 Regla común y fichas

**Regla común:** ingreso neto mensual repartido en 12 (guía, regla 8; plan §3.1). El alquiler se paga doce veces al año; con la paga de un sueldo de 14 pagas, el esfuerzo saldría inflado en torno a un 17 % (14 / 12 = 1,167).

**Superficie.** Las fichas de una persona buscan 50 m², para que sus mapas solo difieran por el ingreso.

| Ficha | Ingreso de referencia | Fuente | Escala | Vivienda | Estado |
|---|---|---|---|---|---|
| Llave (hogar del barrio) | Renta neta media por hogar ÷ 12 | INE, ADRH (indicador 2) | Sección | Alquiler mediano de su sección, sin superficie fija | Ingreso calculado (`larga_adrh`); cruce con el alquiler, pendiente |
| Mochila (joven de 26 a 35 años) | Mediana estimada del salario cobrado en el año, neta, ÷ 12 | AEAT; control con la ECV | Provincia | 50 m² | Calculada para 2024 (`mochila_neta`) |
| Tartera (salario mínimo) | SMI neto anual ÷ 12 | RD 126/2026 | Nacional | 50 m² | Cálculo del plan; fuera del pipeline (`smi_neto`, pendiente) |
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

**Cálculo** (plan §3.1; `neto_mensual()`):
- SMI de 2026: 1.221 € × 14 pagas = 17.094 € brutos anuales (RD 126/2026).
- Sin retención de IRPF, menos cotizaciones del trabajador (≈ 6,5 %): ≈ 1.332 € netos al mes.

**Pendiente.** La comprobación `smi_neto` (bloqueo) y su objetivo no están en el pipeline todavía.

**Comparación con la mochila.**
- La mochila de 2024 (1.330 € netos de media) sale casi igual que la tartera con el SMI de 2026. Son años distintos (regla 4).
- Con el SMI de 2024 (≈ 1.237 € netos), la mochila queda un 7,5 % por encima (plan §3.1).
- La exención de IRPF del SMI vale para quien lo cobra el año entero. La tabla de la AEAT da retenciones del 1,6–1,8 % también por debajo de 12.000 €.

### 6.4 Llave: hogar del barrio

**Ingreso:** la renta neta media por hogar del ADRH de cada sección (indicador 2, §5) ÷ 12, con el estado de su reproyección.

**Vivienda:** el alquiler mediano de la propia sección, sin superficie fija. Es la única ficha que varía por los dos lados, el ingreso y el alquiler.

**Pendiente:** el cruce con el SERPAVI (indicador 14).

---

## 7. Indicadores pendientes de la v0.1 y sección de sobrecarga

### 7.1 Alquiler (indicadores 8 y 9)

**Fuente:** el SERPAVI del MIVAU (`mivau_serpavi`). Publica la mediana, el primer y el tercer cuartil del alquiler mensual y del alquiler por m², con el recuento de testigos y por tipología (colectiva y unifamiliar). Toda la serie 2011–2024 está en el seccionado de 2021 (plan §6.3).

**Qué mide:** contratos de vivienda habitual vigentes declarados en el IRPF y cruzados con el Catastro. Es el parque alquilado, no los contratos nuevos (guía, regla 5).

**Sin tabla de paso.** Las cifras van en su seccionado nativo, así que no se reproyectan.

**Secreto:** con menos de 10 testigos, la fuente solo da el recuento.

**Cobertura en 2024:** mediana de vivienda colectiva en 26.137 secciones, y 28.735 si se cuenta también la unifamiliar (plan §2.4).

**Territorios forales.** Entran en el SERPAVI en 2021 (Navarra), 2022 (Gipuzkoa) y 2024 (Álava y Bizkaia) (ruptura `serpavi_forales` en `inventario/rupturas.csv`).
- Antes de esas fechas, esas secciones van sin dato.
- La estadística de fianzas del Gobierno Vasco (`gv_emal`) no baja a sección y da la media, no la mediana. Se muestra como capa municipal aparte (plan §11, pregunta 8).

**Compuerta prevista:** `serpavi_provincia` (§4.2).

**Cifras:** pendientes.

### 7.2 Hogares en alquiler (indicador 18)

**Fuente:** el Censo de Población y Viviendas 2021 del INE (`ine_censo2021`), en el seccionado de 2021.

**Variables del CSV de indicadores por sección:** tenencia de las viviendas principales en `t20_1` (propiedad), `t20_2` (alquiler) y `t20_3` (otro régimen) (`inventario/fuentes.csv`).

**Corte de 2011.** Está en el seccionado de 2011, y las tablas de paso del pipeline cubren los seccionados de 2016 a 2025: su tratamiento está pendiente.

**Cifras:** pendientes.

### 7.3 Viviendas de uso turístico (indicador 19)

**Fuente:** la estadística experimental del INE (`ine_vut`). Es semestral, con 13 periodos de agosto de 2020 a mayo de 2026, todos en el seccionado de 2021.

**Ruptura `vut_calendario_2024`:** desde noviembre de 2024, los meses de referencia pasan de febrero y agosto a mayo y noviembre. Las series llevan el mes de referencia explícito.

**Cifras:** pendientes.

### 7.4 Derivados (indicadores 14, 15 y 21)

Fórmulas, según `inventario/indicadores.csv` y el plan §5:

| # | Indicador | Fórmula |
|---|---|---|
| 14 | Esfuerzo de residentes | Alquiler mediano mensual × 12 / renta neta media por hogar, del mismo año |
| 15 | Barrera de acceso | Alquiler mediano por m² × 50 / ingreso neto mensual de la ficha |
| 21 | Sueldo neto necesario (mapa por defecto) | Alquiler mediano por m² × 50 / 0,30 (umbral cambiable al 40 %) |

**Cómo se leen:**
- El indicador 15 se lee por tramos: hasta el 30 %, del 30 al 40 % y más del 40 %.
- El indicador 21 es el alquiler expresado en otra unidad. El umbral del 30 % se inspira en el criterio de zona tensionada de la Ley 12/2023 (art. 18), que usa la renta del hogar y los suministros; no es ese criterio.

**Mismo año** en numerador y denominador (guía, regla 4). El SERPAVI y el ADRH coinciden en 2015–2024.

**Pendientes:**
- la regla de estado de los derivados cuando uno de sus términos es `estimado`, `secreto` o `ausente`;
- todas las cifras.

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
- **Secciones fuera de la serie.** Las nueve secciones huérfanas del ADRH quedan fuera de la tabla de paso. Las dos excepciones de cobertura dejan una sección de 2021 sin dato en seis años-sección (§3.8).
- **Cambios de límites posteriores a 2021.** Las secciones que cambian después de 2021 se dibujan con sus límites de 2021 (§3.1).

**Renta:**
- **La fuente no cuadra entre escalas.** El ADRH no siempre suma sus secciones al total municipal (`adrh_suma_secciones`, 160 municipios y años en 2015–2019). Sus medias de sección agregadas se separan más de un 5 % de la cifra municipal en 135 cifras (`adrh_municipio_detalle`). El atlas no lo corrige: muestra la cifra publicada en cada escala.
- **Hogares aproximados.** Salen de un tamaño medio del hogar redondeado a un decimal (§5.1).
- **País Vasco y Navarra en 2015–2019.** El ADRH no los publica por sección esos años: esas secciones van como `secreto` (§5.4).

**Mochila:**
- **Supuestos:**
  - la relación mediana/media del SME de una comunidad vale para todas sus provincias;
  - la distribución dentro de cada decil nacional es la del país;
  - la retención de la nómina es la media de todas las edades;
  - la cotización es la de un contrato indefinido.
- **Cobertura.** Sin País Vasco, Navarra, Ceuta ni Melilla (§6.2).
- **Lo cobrado en el año.** La ficha usa lo cobrado en el año, que incluye a quien trabajó pocos meses; la ficha lo dice.

**Años distintos entre fichas.** La tartera (SMI de 2026) y la mochila (AEAT de 2024) son de años distintos, y a escala de España dan ingresos casi iguales (§6.3).

**Alquiler.** El SERPAVI mide el parque alquilado, no los contratos nuevos: quien entra hoy paga más (indicador 8).

**Licencias.** El Catastro estatal y los forales de Bizkaia y Gipuzkoa tienen licencias contradictorias y se tratan como datos abiertos por decisión del autor (§2.2).

**Sobrecarga.** Se publica sin intervalos de confianza (§7.5).

**Desfase.** La renta y los salarios van uno o dos años por detrás del año en curso (§1).

---

## 9. Cómo reproducir las cifras

**Requisitos.** R 4.6 con `renv` (`renv.lock`). Los datos brutos no están en git: el pipeline los descarga en `datos/brutos/`.

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

Con `PROVINCIA=28` (variable de entorno, antes de `tar_make()`), el cálculo se limita a una provincia.

**Objetivos citados en esta nota:**
- **Geografía:** `secciones_2021`, `tablas_paso_callejero`, `tablas_paso_finales`, `edificios_paso`, `edificios_forales`, `municipios_catastro_sel`, `grupos_municipio`, `huerfanas_adrh`, `fase_codigos`, `cambios_limites`, `comprobaciones_f1`, `diagnostico_f1`, `comparacion_vias`.
- **Renta:** `comprobaciones_adrh`, `tablas_paso_adrh`, `larga_adrh`, `tabla_larga`.
- **Mochila:** `mochila_opciones`, `mochila`, `mochila_neta`, `retenciones_mochila`, `ecv_mochila`.
- **Compuertas:** `validacion_f1`, `validacion_adrh`, `validacion_sobrecarga`, `validacion_modulo`, `validacion_mochila`, `validacion_mochila_ecv`, `validacion_mochila_neto_ecv`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`.
