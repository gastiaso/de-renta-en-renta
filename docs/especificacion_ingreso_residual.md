# Especificación · línea de ingreso residual

*Borrador para la v1.2 (12-nov-2026), por decidir. Encargo: backlog, «Para la v1.2», «Línea de ingreso residual»; nota metodológica, §7.4 («La misma proporción para todos los ingresos») y §8. Provisional, como todo el plan.*

**Estado: decidido (13-nov-2026), por hacer.** Las siete preguntas del final se cerraron con la opción recomendada (decisión del autor). Nada de esto está en el pipeline ni en la web. Las cifras de las fuentes se consultaron en la web el 12-nov-2026, sin descargar ficheros; las marcadas «por verificar» no se han contrastado con la fuente primaria.

## Por qué

- El umbral del 30 % (indicadores 15 y 21, «¿te llega?») trata igual un ingreso bajo y uno alto, y no dice si lo que queda tras pagar la vivienda alcanza para lo demás. La nota lo reconoce (§7.4) y remite a esta línea.
- La web ya da los **euros que quedan** (tarea 34; `eurosQueQuedan()` de `web/js/sueldo.js`): ingreso de la ficha menos alquiler, sin umbral de suficiencia. La línea residual es la pieza que falta: con qué cifra se comparan esos euros.
- «Tu sueldo» ya puede sumar los **otros gastos de vivienda** de los inquilinos (HH070 − HH060 de la ECV; `R/fuente_ine_ecv_gastos.R`, `datos/otros_gastos.json`). El enfoque residual los necesita: lo que queda es el ingreso menos *todos* los gastos de la vivienda.

## Qué dice la literatura

- **Stone (2006)**, «What is housing affordability? The case for the residual income approach», *Housing Policy Debate*, 17(1), 151–184 (ya citado en la nota). Un hogar está en *shelter poverty* cuando, tras pagar la vivienda, no le queda lo necesario para cubrir un presupuesto mínimo de los demás gastos, fijado según el tamaño y la composición del hogar. La proporción máxima asumible no es fija: baja con el ingreso y con el tamaño del hogar.
- **Eurostat** publica la tasa de riesgo de pobreza **tras deducir los gastos de vivienda**: `ilc_li48`, «At-risk-of-poverty rate after deducting housing costs by degree of urbanisation» (por grado de urbanización: total, ciudades, pueblos y zonas suburbanas, rural). España, 2025: 28,7 % (ciudades 26,4; pueblos 31,8; rural 30,3); 2024: 29,1 % (consulta del 12-nov-2026 a la API de Eurostat). Es la versión estadística del enfoque residual: renta disponible menos gastos de vivienda frente a un umbral de pobreza. **Por verificar en los metadatos:** si el umbral es el 60 % de la mediana de la renta antes de deducir la vivienda (lo habitual) o se recalcula tras deducirla, y si los gastos se restan netos de ayudas a la vivienda, como en la tasa de sobrecarga.
- Variantes: la *housing-induced poverty* (el hogar cae bajo un umbral de los demás gastos solo por lo que paga de vivienda), las series *after housing costs* del Reino Unido y los **presupuestos de referencia** (cestas de bienes y servicios mínimos por tipo de hogar; proyecto piloto europeo de presupuestos de referencia, 2015). Ninguna tiene una cifra oficial española por tipo de hogar y año.

## Umbrales disponibles en España

| Umbral | Cifra (una persona) | Escala del hogar | Fuente y años | Qué es |
|---|---|---|---|---|
| **Renta garantizada del ingreso mínimo vital (IMV)** | 733,60 € al mes, 8.803,20 € al año (2026) | +30 % por miembro adicional, hasta el 220 %: dos adultos, 953,68 € al mes; un adulto y un menor, igual. Monoparentales, cuantías propias | Seguridad Social, página del IMV (consultada el 12-nov-2026). La mensual es el 100 % de la pensión no contributiva (PNC) anual dividida entre 12. Ley 19/2021, de 20 de diciembre; cuantías anuales en las normas de revalorización (2026: Real Decreto-ley 3/2026, por verificar). Desde junio de 2020 | El mínimo de ingresos que el Estado garantiza a un hogar para **todos** sus gastos, vivienda incluida |
| **Umbral de riesgo de pobreza de la ECV** | 12.220,4 € al año, 1.018,4 € al mes (ECV 2025, ingresos de 2024; por verificar en la tabla del INE: la cifra sale de fuentes secundarias que citan la nota del INE de 5-feb-2026) | Escala de la OCDE modificada (1; 0,5 por adulto; 0,3 por menor de 14): dos adultos, ×1,5 | INE, Encuesta de Condiciones de Vida, tabla de umbrales por tipo de hogar; anual desde 2008 | Convención estadística: 60 % de la mediana de la renta por unidad de consumo |
| **SMI** | 1.221 € × 14 (2026; neto prorrateado ≈ 1.332 € al mes, tartera) | Ninguna: es por persona que trabaja | Real Decreto 126/2026 (ya en `inventario/fuentes.csv`, `boe_smi`) | Suelo salarial, no una medida de necesidades |
| **IPREM** | 600 € al mes, 7.200 € al año (12 pagas) o 8.400 € (14 pagas) | Ninguna | Ley de presupuestos (los de 2023, prorrogados; por verificar en el BOE) | Índice de referencia para ayudas y subsidios; sus múltiplos (1×, 3×) fijan límites de acceso |

Umbrales legales que mezclan las dos ideas: la Ley 12/2023 (art. 3, letra d) toma como límite general de esfuerzo el 30 % de los ingresos del hogar, con la hipoteca o el alquiler y los suministros básicos, y la vulnerabilidad económica de las normas de protección de inquilinos suele combinar un tope de ingresos en múltiplos del IPREM con un esfuerzo mínimo (por ejemplo, alquiler más suministros ≥ 35 % de los ingresos en el Real Decreto-ley 11/2020, art. 5; por verificar el texto vigente). Sirven de contexto en la nota, no como línea.

## Lo que cambia la elección del umbral

La línea residual pide más que el 30 % solo cuando el ingreso es bajo. Con un ingreso mensual *I*, un umbral *N* y unos otros gastos de vivienda *G*:

- el 30 % admite un alquiler de hasta 0,30 × *I*;
- la línea residual, de hasta *I* − *G* − *N*;
- la residual es la más exigente cuando *I* < (*N* + *G*) / 0,70.

Sin otros gastos: con el IMV de 2026 (733,60 €), por debajo de **1.048 €** al mes; con el umbral de pobreza de la ECV 2025 (1.018,4 €), por debajo de **1.455 €**. Ejemplo, la tartera con el SMI de 2026 (1.331,91 € netos; años distintos, solo para ilustrar): el 30 % admite 400 €; el IMV, 598 €; el umbral de la ECV, 314 €. Con el IMV, la línea apenas añade información a las fichas (solo la mochila de las provincias más bajas, desde 990 €, queda por debajo del punto de cruce); con el umbral de la ECV, cambia la respuesta de la tartera, de buena parte de la mochila y de los transistores de las provincias con pensiones más bajas. Es la decisión principal (pregunta 1).

## Método propuesto

### Definición

- **Ingreso residual** = ingreso neto mensual (12 pagas; guía, regla 8) − alquiler mensual de la vivienda de la ficha − otros gastos de vivienda (si el selector está encendido).
- **Línea** = umbral mensual *N* del tipo de hogar y del año. Una persona: las tres fichas de una persona y «Tu ficha» con un sueldo. Dos adultos: «Tu ficha» con segundo sueldo. Sin menores: el atlas no los modela.
- **Lectura**: «queda por encima / por debajo de la línea», y la distancia en euros. Sin valoraciones: la web dice qué es la línea («renta garantizada del IMV para un hogar de una persona, 2026») y no si el resto «alcanza».
- **Mismo año** (regla 4): el umbral del año del alquiler. IMV: el del año; antes de 2020, la PNC anual / 12 (equivalencia de la Seguridad Social), rotulada como tal, o `ausente` (pregunta 3). ECV: la ola que trae los ingresos del año del alquiler (alquiler de 2024 → ECV 2025), como la mochila.

### Alternativas

- **A · Renta garantizada del IMV.** Cifra legal, anual, nacional, con escala del hogar publicada. Lectura directa: «tras pagar la vivienda queda menos de lo que la ley garantiza a un hogar como este para todos sus gastos». Límite: no es un presupuesto de los demás gastos; como línea residual es baja.
- **B · Umbral de riesgo de pobreza de la ECV.** Cifra del INE, anual, y la misma convención que `ilc_li48`. Lectura: «tras pagar la vivienda, el resto queda por debajo del umbral de pobreza». Límite: es un umbral de renta total, no de los gastos que no son vivienda; como línea residual es alta. Existe por comunidad solo como cálculo propio (el INE publica el nacional).
- **C · Presupuesto de referencia propio.** Gasto mínimo en bienes y servicios que no son vivienda por tipo de hogar, desde los microdatos de la Encuesta de Presupuestos Familiares (INE), por ejemplo la mediana del gasto no residencial del primer quintil. Es lo más cercano a Stone, pero obliga a fijar una cesta: decisiones discutibles, fuente nueva y compuerta sin cifra publicada. Esfuerzo L.
- **D · Dos líneas a la vez** (A y B), con un selector como el del umbral del 30/40 %.

**Recomendación: D, con A por defecto.** A da una frase que no exige explicar una convención estadística y tiene cifra oficial con escala; B se ofrece como segunda opción porque es la de Eurostat y la que mueve la respuesta en los ingresos bajos. C queda fuera de la v1.2.

### Parte B (opcional): tasa de riesgo de pobreza tras los gastos de vivienda por comunidad

Con los microdatos de la ECV que ya lee el pipeline (`R/fuente_ine_ecv.R`): renta disponible del hogar menos los gastos de vivienda (HH070 × 12, netos de ayudas a la vivienda si así lo hace Eurostat), por unidad de consumo, frente al umbral de la ola; por comunidad y por tenencia, con las olas agrupadas donde la muestra no llegue (como la sobrecarga, indicador 22). Compuerta: España total frente a `ilc_li48` (±0,1 puntos, bloqueo). Va a la sección «Sobrecarga» como indicador de la familia E. Depende de verificar la definición exacta de Eurostat (variables y umbral). Pregunta 5.

## Encaje

### Tabla larga

- **Umbrales:** indicadores auxiliares de nivel España, uno por línea, con corte `hogar` y grupos `una_persona` y `dos_adultos` (códigos nuevos en `inventario/vocabulario.csv`): `linea_imv` (2020–2026; antes, según la pregunta 3) y `linea_pobreza_ecv` (2015–2025, por año de ingresos), en euros al mes, `estado` `dato`, fuente `boe_imv` o `ine_ecv_umbral`. Fuera de los 23 (ajustar `test-inventario.R`, como con `contratos_alquiler`).
- **Ingreso residual por sección:** no entra. La web lo calcula en el navegador con términos que ya exporta (alquiler, ingreso de la ficha, otros gastos), como los euros que quedan. Si el autor quiere un control en la tabla larga, iría como el 15 (corte `ficha`), con más de un millón de filas más (unas 36.000 secciones × 10 años × 3 fichas, sin contar los otros niveles; pregunta 4).
- **Parte B**, si se hace: indicador nuevo de la familia E por comunidad, como el 22.

### Fuentes nuevas (`inventario/fuentes.csv` y `calendario_fuentes.csv`)

| Id propuesto | Organismo y URL | Licencia o condiciones | Nivel | Años | Calendario |
|---|---|---|---|---|---|
| `boe_imv` | Seguridad Social, página del IMV (https://www.seg-social.es, «Ingreso mínimo vital»), y la norma de revalorización de cada año en el BOE | Reutilizable citando la fuente (aviso legal del BOE; https://www.boe.es/informacion/aviso_legal/index.php#reutilizacion) | Nacional, por tipo de hogar | 2020–2026 (PNC desde 2015, si se usa) | Anual, enero o febrero (revalorización); como `boe_smi`, una fila nueva por año en el código o en un CSV de `inventario/` |
| `ine_ecv_umbral` | INE, ECV, umbral de riesgo de pobreza por tipo de hogar (INEbase; tabla por localizar, con descarga por la API JSON del INE) | Reutilización libre citando al INE (aviso legal del INE) | Nacional | 2008–2025 (ingresos de 2007–2024) | Anual, febrero (la ECV 2025 salió el 5-feb-2026) |
| `eurostat_ilc_li48` (solo con la parte B) | Eurostat, `ilc_li48` (API, como `eurostat_ilc_lvho07`) | CC BY 4.0 (aviso de copyright de Eurostat) | País | 2024–2025 con la clasificación actual (la serie larga, por comprobar) | Anual |

Supuestos (`inventario/supuestos.csv`): `linea_residual` (valor `imv`, opciones `imv;ecv`), `hogar_linea` (una persona sin segundo sueldo; dos adultos con él), con su decisión y su uso, para que R y `web/js/supuestos.js` lean lo mismo.

### Web

- **«Tu sueldo» y «Tu ficha»** (mapa y portada): bajo los euros que quedan, una línea: «Tras pagar el alquiler quedan {resto} €; la renta garantizada del IMV para un hogar de una persona es de 733,60 € al mes (2026): {distancia} € por debajo.» Con los otros gastos encendidos, la frase lo dice («tras pagar el alquiler y los otros gastos de vivienda»). En la portada, solo si la cuenta ya está a la vista (`portada.cuenta.*`).
- **Mapa, modo «¿te llega?»:** un selector «Regla: 30 % del ingreso · Lo que queda» (`regla=residual` en la dirección, apagado por defecto). Con «Lo que queda», tres tramos: por debajo de la línea; hasta 1,25 × la línea (el límite, a decidir, en `supuestos.csv`); por encima. La frase resumen cambia a «queda por encima de la línea en el X % de las secciones con dato». Estado de cada sección: el de «¿te llega?» (`estadoLlega()`).
- **Fichas de perfil:** la línea de cada ficha en «Tu sueldo» dice si su ingreso queda por encima de la línea con el alquiler de la sección. La **llave** queda fuera: su ingreso es la renta de todos los hogares de la sección, de tamaño desconocido; rotulada «no aplica».
- **Sueldo necesario (21):** sin mapa nuevo. Con la línea, el sueldo necesario es alquiler + otros gastos + *N*: el mapa del alquiler desplazado por una constante, sin información nueva. Va como segunda cifra en la ficha («con la línea del IMV: {cifra} €»).
- **Sobrecarga** (solo parte B): la tasa tras gastos de vivienda en «La escalera» y en el mapa de comunidades.
- **Textos:** `web/i18n/es.json` y `en.json` (línea, regla, tramos, «no aplica»); nota metodológica, §6.7 (supuestos) y §7.4, en los dos idiomas, a la vez (`test-metodologia.R`); «Método en dos páginas».

### Compuertas (`inventario/referencias_validacion.csv`)

| Id | Tipo | Comprueba |
|---|---|---|
| `residual_imv_publicada` | bloqueo | Las cuantías mensuales y anuales del IMV de la tabla larga frente a las publicadas (2026: 733,60 y 953,68 € al mes; ±0,005 €) |
| `residual_umbral_ecv` | bloqueo | El umbral de una persona de cada ola frente a la tabla del INE (±0,1 €) |
| `residual_escala` | bloqueo | El de dos adultos = una persona × 1,3 (IMV) o × 1,5 (ECV), al céntimo |
| `residual_muestra` | bloqueo | En la muestra de `validacion_supuestos` (catorce territorios × combinaciones de «Tu ficha»), R y la página dan el mismo ingreso residual y el mismo tramo; se añaden la regla y la línea a las combinaciones |
| `web_residual` | bloqueo | Ida y vuelta de las líneas escritas para la web |
| `residual_coherencia` | alerta | Ingreso residual = euros que quedan − otros gastos, en la muestra |
| `ahc_es_eurostat` (parte B) | bloqueo | La tasa tras gastos de vivienda de España con los microdatos frente a `ilc_li48` (±0,1 puntos) |

### Pruebas

- R: línea del IMV de 2026 para uno y dos adultos; tartera de 2026 con un alquiler de 700 € → residual 631,91 €, por debajo del IMV; sin ingreso → `NA`.
- Web (node): el selector cambia los tramos y la frase; con los otros gastos, la línea cuenta los gastos; la llave sale «no aplica»; la dirección conserva `regla=residual`.

## Esfuerzo

**M.** Fuente del IMV y del umbral de la ECV con su compuerta, S; web («Tu sueldo», selector, tramos, textos, pruebas), M; nota en dos idiomas, S. Parte B: M aparte (definición de Eurostat, olas agrupadas, compuerta). Alternativa C: L.

## Preguntas para el autor

**Cerradas (13-nov-2026), decisión del autor: las siete con la opción recomendada.** Umbral D (IMV y umbral de pobreza de la ECV con selector, el IMV por defecto); en «Tu sueldo», la ficha y como regla de «¿te llega?», con el selector apagado por defecto; PNC anual / 12 rotulada de 2015 a 2019; sin control por sección en la tabla larga; parte B después de la A; tres tramos; hogares con menores, fuera.

1. **Umbral.** A (IMV), B (umbral de pobreza de la ECV), C (presupuesto propio) o D (A y B con selector). Recomendada: **D, con el IMV por defecto**.
2. **Dónde va.** Solo en «Tu sueldo» y la ficha, o también como regla del mapa en «¿te llega?». Recomendada: **las dos**, con el selector apagado por defecto.
3. **Años antes del IMV (2015–2019).** PNC anual / 12, rotulada, o `ausente`. Recomendada: **PNC rotulada**, para no cortar la serie del alquiler (2015–2024).
4. **Control por sección en la tabla larga.** Recomendado: **no**; basta la muestra de `validacion_supuestos`.
5. **Parte B** (riesgo de pobreza tras los gastos de vivienda por comunidad, con la ECV). Recomendada: **sí, después de la parte A** y tras verificar la definición de `ilc_li48`.
6. **Tramo intermedio** del mapa con la regla residual: hasta 1,25 × la línea, o solo dos tramos. Recomendado: **tres tramos**, para que el mapa conserve la lógica de «¿te llega?».
7. **Hogares con menores.** Fuera (recomendado) o un selector de menores en «Tu ficha», que cambiaría la escala.

## Hecho cuando

- La tabla larga trae las líneas de cada año y tipo de hogar, y pasan las compuertas `residual_*`.
- «Tu sueldo» da el ingreso residual frente a la línea, en castellano e inglés, y el mapa lo pinta con la regla residual; R y la página coinciden en la muestra.
- La nota metodológica, en los dos idiomas, explica la línea, el punto de cruce con el 30 % y sus límites.
