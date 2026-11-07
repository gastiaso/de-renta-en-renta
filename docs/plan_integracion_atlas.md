# De renta en renta — Plan de integración por fases

*Borrador v0.14 · 7 de noviembre de 2026 · Todo lo que sigue es provisional y se revisa en cada fase.*

**Cambios en la v0.14:** decisiones del autor del 7-nov-2026. Escalonado y portales confirmados (§2.2 y §2.3). Sin dominio propio: la web va en la dirección de GitHub Pages (§10.1). País Vasco y Navarra sin alquiler por sección en los años sin SERPAVI, con las fianzas como capa municipal aparte. La sobrecarga se publica sin intervalos, con el número de observaciones y la marca de fiabilidad. La tabla larga gana las columnas `corte` y `grupo` (§6.4). La diferencia del ADRH entre secciones y municipio sigue como alerta. Preguntas abiertas 1, 2, 8, 9 y 10 cerradas; la 7 (mochila) espera al cálculo de A y B.

**Cambios en la v0.13:** nombre *De renta en renta*, sin traducir, con dicho de portada; se mantiene el tablero cuadrado (§10.1; pregunta abierta 3, cerrada).

**Cambios en la v0.12:** tablas de paso de todos los años del ADRH en Madrid (2015–2024), combinadas con el Catastro; la prueba de cierre pasa a medir solo la tabla, y la diferencia del ADRH entre secciones y municipio se vigila aparte (§6.3).

**Cambios en la v0.11:** tabla 2022 → 2021 con la vía (b) y prueba de un año de esa vía: en las secciones que el callejero reparte, el error baja al ruido de un año. Secciones «fantasma» del seccionado (códigos del mapa que no están en los datos del mismo año) y nueva compuerta `cobertura_destino` (§6.3).

**Cambios en la v0.10:** avance de F0 y F1b (tareas 2 y 7 a 10, sobrecarga con tres olas, Europa e indicador 23; preguntas abiertas 9 y 10) y vía (b) del Catastro adoptada para las secciones que hay que repartir, con los edificios filtrados por año de construcción (§1 y §6.3).

**Cambios en la v0.9:** comprobaciones de F0 (backlog, tareas 3 y 4). El método de la mochila no se puede aplicar tal cual (§3.1; pregunta abierta 7). El País Vasco no tiene alquiler por sección antes de entrar en el SERPAVI y Navarra no tiene nada antes de 2021 (pregunta abierta 8). Las viviendas turísticas del INE también usan el seccionado de 2021. La vía (b) del Catastro es viable, pero su licencia es contradictoria (§6.3). Huecos y versiones NUTS del mapa europeo y licencia de las geometrías de GISCO (§6.6).

**Cambios en la v0.8:** medianas reproyectadas desde el origen dominante (≥ 95 % de los portales) como `estimado`, contrastado con la prueba de un año (§6.3; cierra la pregunta abierta 6).

**Cambios en la v0.7:** adoptada la regla de estado de las cifras reproyectadas (`dato`, `estimado`, `ausente`; §1 y §6.3), que sustituye al tratamiento por direcciones. Nueva pregunta abierta sobre las medianas `ausente` por aportes pequeños (§11).

**Cambios en la v0.6:** prueba de F1 en Madrid (backlog, tarea 6): tablas de paso 2015 → 2021 y 2025 → 2021 por el callejero, prueba de cierre superada, diagnóstico sección a sección y prueba de un año (2022 → 2021), con una propuesta de estado `dato` / `estimado` (§6.3; pregunta abierta 5). El año *t* del ADRH está en el seccionado de *t* + 1. El coste del seccionado de 2021 es mayor que el estimado por códigos: en Madrid, el 5,7 % de las secciones ha cambiado en 2025.

**Cambios en la v0.5:** seccionado de referencia: el del Censo 2021, no el último (§1, §6.3; cierra la pregunta abierta 4). El indicador 8 pasa a llamarse «Alquiler mensual (mediana)», porque el SERPAVI no publica la media.

**Cambios en la v0.4:** SERPAVI por sección censal resuelto (backlog, tarea 1): el MIVAU publica la base de datos completa en un Excel descargable y reutilizable, 2011–2024, con secciones, distritos, municipios, provincias y comunidades; toda la serie va en el seccionado del Censo 2021 (§2.4, §6.3); mediana, P25 y P75 de alquiler, €/m² y superficie, con recuento de testigos y por tipología; los territorios forales entran entre 2021 y 2024 (`inventario/rupturas.csv`). Nueva pregunta abierta sobre el seccionado de referencia (§11).

**Cambios en la v0.3:** método de la mochila (AEAT provincial pasada a mediana, con la ECV como control, año completo); transistor solo con pensiones de jubilación (INSS); 50 m² para las fichas de una persona; un solo mapa europeo (regiones NUTS 2 para el total; países, y España por comunidades, para los desgloses), tras comprobar que la serie regional de Eurostat existe e incluye las comunidades.

**Cambios en la v0.2:** reutilización de código propio previo (§2.1); fichas con su ingreso de referencia (§3.1); «Tu sueldo» con el sueldo necesario como mapa por defecto (indicador 21, §6.6); sección de sobrecarga con método Eurostat y mapa de Europa (indicadores 22 y 23, fase F1b en paralelo a F1). Alcance: 23 indicadores.

---

## 1. Decisiones cerradas

| Tema | Decisión |
|---|---|
| Pregunta rectora | Dónde, desde cuándo y para quién se ha roto la relación entre lo que cuesta vivir y la capacidad de pago |
| Público | Principal: periodistas de datos y técnicos de administraciones y entidades. Secundario: capa ciudadana |
| Naturaleza | Escaparate personal y contribución cívica |
| Escala y periodo | Sección censal (SC), de 2015 al último dato disponible |
| Seccionado de referencia | El del Censo 2021 (1 de enero de 2021), en el que el SERPAVI publica toda su serie (§6.3) |
| Tablas de paso | Callejero (vía a) donde las secciones caen enteras; viviendas del Catastro (vía b) donde hay que repartir (§6.3) |
| Cifras reproyectadas | `dato` si las secciones de origen caen enteras en la de 2021; `estimado` si alguna se reparte; medianas `dato` solo 1:1, `estimado` desde un origen dominante (≥ 95 % de los portales) y `ausente` si ninguno domina (§6.3) |
| Alcance | 23 indicadores: los 20 iniciales y 3 añadidos el 6-nov (catálogo en §5) |
| Código previo | Se reutiliza el código propio que sirva (§2.1) |
| Para quién | Cinco fichas con ingreso neto mensual y superficie propia: llave, mochila, tartera, transistor y «Tu ficha» (§3.1) |
| Tu sueldo | Entrada en neto mensual; cálculo en el navegador; mapa por defecto: sueldo neto necesario en euros para 50 m² (§6.6) |
| Sobrecarga | Sección propia con método Eurostat y un solo mapa de Europa: regiones NUTS 2 para el total; con desgloses, países, y España por comunidades; fase F1b en paralelo a F1 |
| Precios privados | Se usan (ver objeción en §2.2) |
| País Vasco y Navarra | Se integran (Eustat, Nastat, Gobierno Vasco, Haciendas Forales). El alquiler por sección solo existe desde que entran en el SERPAVI (Navarra 2021, Gipuzkoa 2022, Álava y Bizkaia 2024): ver pregunta abierta 8 |
| Formato | Web exploratoria con fichas; las historias, después |
| Idioma | Castellano e inglés desde el primer día |
| Identidad | Tablero, *De renta en renta* (§10.1 y §10.2): propia, retro, que no parezca *barómetros* con otros datos |
| Herramientas | R al máximo (`targets`), JS solo en la web, MapLibre + PMTiles para las SC |
| Recursos | Una persona, sin fecha: avance por hitos, no por calendario |

---

## 2. Objeciones y matices a las decisiones

### 2.1 Reutilización de código previo — cerrado

Se reutiliza el código propio que sirva, empezando por el que ya trabaja con los microdatos de la ECV (F1b) y con el SERPAVI (F2). Queda un matiz: los **datasets compilados** a mano (zonas tensionadas, turistificación, titularidad) se reconstruyen desde las fuentes públicas en el pipeline del atlas, no se copian como ficheros, para que cada cifra tenga su función de descarga reproducible.

### 2.2 «Los precios de Idealista y Fotocasa son públicos en su web»

Que algo sea visible no significa que se pueda reutilizar.

- **Derecho sui generis.** La Directiva 96/9/CE (art. 7) y el TRLPI (arts. 133 y ss.) protegen al fabricante de una base de datos frente a la extracción o reutilización de partes sustanciales. También frente a la extracción repetida y sistemática de partes no sustanciales. El TJUE aplicó este derecho a metabuscadores (C-202/12, *Innoweb*).
- **Condiciones de uso.** Allí donde la base no está protegida, las condiciones contractuales de la web pueden prohibir la extracción (C-30/14, *Ryanair*).
- **Riesgo práctico.** Una retirada DMCA en GitHub tumba el repositorio entero, web incluida.

Medidas para usarlos sin poner en riesgo el resto (confirmadas el 7-nov-2026, pregunta abierta 2):

| Medida | Por qué |
|---|---|
| Usar solo los **informes agregados de la sala de prensa** (precio €/m² por municipio, distrito o barrio), citando la fuente; nunca anuncios individuales | Los difunden para que se reproduzcan; el riesgo baja mucho |
| **Capa desmontable**: un interruptor del pipeline (`PORTALES=0`, como el modo veda de *barómetros*) la retira sin tocar nada más | Si hay requerimiento, se apaga en un commit |
| Datos brutos **fuera de git**; en el repo solo el indicador derivado | Reduce la superficie |
| Valorar un **repo satélite** (`…-portales`) para esa capa | Una retirada no afecta al atlas principal |
| Escribir a Idealista y Fotocasa pidiendo permiso para uso no comercial | Si dicen que sí, se cierra el problema |

Además hay un argumento metodológico: es **precio de oferta**, no de cierre. En la web debe aparecer siempre como «referencia de oferta», nunca mezclado con SERPAVI o con el Notariado.

### 2.3 Veinte indicadores en la primera versión

Veinte indicadores, a nivel de sección censal, por una sola persona, retrasan mucho la primera publicación. Cada indicador exige ficha, validación, revisión de rupturas y traducción.

**Decidido (7-nov-2026):** los 23 son el alcance de la **v1.0**. Antes sale la sección de sobrecarga (v0.0, F1b), que no depende de la geografía constante. La v0.1 sale con un núcleo de 10 (los 9 iniciales y el sueldo necesario) que ya responde a la pregunta rectora. Así llegan comentarios de periodistas y técnicos antes de invertir en el resto.

### 2.4 Sección censal desde 2015

Aceptado, pero con su coste explícito:

- **El seccionado cambia cada año** (altas, bajas y correcciones de límites, consolidadas a 1 de enero). Comparar en el tiempo obliga a construir una **geografía constante** con tablas de paso (§6.3). Es la pieza más arriesgada del proyecto y va en la Fase 1, antes que cualquier indicador.
- **Cobertura y secreto estadístico.** El SERPAVI publica en 2024 la mediana del alquiler de vivienda colectiva en 26.137 de 36.293 secciones (28.735 si se cuenta también la unifamiliar); por debajo de 10 testigos solo da el recuento. El ADRH no publica las que no superan los umbrales de población. El mapa tendrá huecos, y hay que diseñarlos como información («sin dato por secreto estadístico»), no como error.
- **Mezcla de escalas.** Varios indicadores no existen a nivel de sección (salarios por provincia, compraventa por código postal). Principio: **cada indicador se muestra en su nivel nativo; nunca se desagrega hacia abajo** (§4).

### 2.5 La nostalgia de la identidad tiene trampa

«De cuando podíamos pagar la vivienda» depende de la métrica:

- En **años de renta**, la vivienda costaba menos de tres en 1987, frente a 9,45 en el récord de 2007 y 7,6 en 2023 (Banco de España).
- Pero el **esfuerzo teórico** (la cuota del primer año sobre la renta) tocó su máximo en **junio de 1990, con un 72 %**, por los tipos de interés. Es justo la época de los 8 bits.

Esto no invalida la estética. La convierte en argumento: el atlas existe para enseñar que «se podía» o «no se podía» según el supuesto. Se propone un módulo histórico (Fase 6) que justifique la identidad con series largas nacionales y autonómicas.

### 2.6 Preguntas que quedaron cerradas el 6-nov

- **P7 (salarios).** Resuelta con las fichas (§3.1) y con «Tu sueldo». El mapa por defecto habla en euros de sueldo necesario y no depende de elegir un salario de referencia, pero las series y el comparador sí lo necesitan: para comparar en el tiempo, el sueldo necesario se expresará también como percentil de la distribución salarial (F3).

### 2.7 Riesgos de las decisiones del 6-nov

- **El mapa por defecto es el alquiler en otra unidad.** Sueldo necesario = alquiler ÷ umbral: no añade información, añade lectura. Es una buena decisión de comunicación; conviene no venderla como un indicador nuevo.
- **La sobrecarga de Eurostat puede contar lo contrario que el atlas.** Mide a quien ya tiene casa, la dominan los propietarios sin hipoteca y no ve a quien no ha podido emanciparse; en España está en mínimos de la serie. El titular de la sección son los inquilinos a precio de mercado, y va acompañada de la búsqueda de vivienda sin éxito (indicador 23).
- **Falsa precisión en «Tu sueldo».** Un porcentaje exacto por sección se leerá como verdad. Se muestran tramos, el número de contratos detrás del dato y una banda entre el SERPAVI (contratos vigentes) y la oferta de los portales, porque quien entra hoy paga más que el parque.

---

## 3. De la pregunta a los datos

| Parte de la pregunta | Qué la responde en el atlas |
|---|---|
| **Dónde** | Mapa por sección censal, con agregados por distrito, municipio, provincia y comunidad |
| **Desde cuándo** | Series 2015–último dato en geografía constante; rupturas marcadas. Módulo histórico nacional desde 1987 (F6) |
| **Para quién** | **Fichas** que cambian el ingreso de referencia (§3.1): hogar del barrio, joven menor de 35, salario mínimo, pensionista y el sueldo que escriba cada usuario |
| **Se ha roto** | Dos familias de indicadores: **esfuerzo de residentes** (vulnerabilidad de quien ya vive allí) y **barrera de acceso** (lo que cuesta entrar con un ingreso de referencia). La segunda corrige el sesgo de clasificación: los barrios caros parecen asequibles porque los habita gente rica. A escala de comunidad y país, la **sobrecarga** de Eurostat (carga de quien ya tiene casa) frente a la **búsqueda sin éxito** (quien no consigue entrar) reproduce la misma pareja |

### 3.1 Fichas: de dónde sale cada ingreso

Regla común: **ingreso neto mensual repartido en 12**. El alquiler se paga doce veces al año; si se usa la paga de un sueldo de 14 pagas, el esfuerzo sale inflado en torno a un 17 %.

| Ficha | Ingreso de referencia | Fuente | Escala | Vivienda | Pendiente |
|---|---|---|---|---|---|
| Llave · hogar del barrio | Renta neta media por hogar ÷ 12 | INE, ADRH | Sección censal | Alquiler mensual mediano de su propia sección (sin m² fijos) | Mide esfuerzo de residentes, no acceso. Es renta del hogar (varios perceptores), no un sueldo |
| Mochila · joven menor de 35 | Mediana estimada del salario de 26–35 años, año completo, neta, ÷ 12 | AEAT, *Mercado de trabajo y pensiones* (media por provincia y edad, y deciles por comunidad y edad); control con microdatos de la ECV | Provincia | 50 m² | Ver «Método de la mochila». Tramo 26–35 confirmado; método en revisión tras comprobar la AEAT (pregunta abierta 7) |
| Tartera · salario mínimo | SMI neto anual ÷ 12 | RD 126/2026: 1.221 € × 14 = 17.094 € brutos; exento de IRPF; menos cotizaciones (≈ 6,5 %) → **≈ 1.332 €/mes** (cálculo propio aproximado) | Nacional | 50 m² | Revisar cada año con el real decreto |
| Transistor · pensionista | Pensión media de **jubilación**, neta de IRPF, ÷ 12 | INSS, *Pensiones contributivas del Sistema de la Seguridad Social* por provincia (mensual) | Provincia | 50 m² | Responde a «si tuviera que alquilar hoy»: el 89,1 % de los mayores de 65 años vive en casa propia (ECV 2023), y la ficha lo dice. No incluye Clases Pasivas. La AEAT no separa por clase de pensión: por eso cambia la fuente. Comprobado: Excel mensual por provincia y clase; pensión bruta por paga (14 pagas): × 14 / 12 antes del IRPF; la provincia es la de la dirección provincial que la gestiona, no la de residencia |
| Tu ficha (peón) | Lo que escriba el usuario: neto mensual, 12 o 14 pagas, segundo sueldo opcional | — | — | 50 m² con un sueldo, 70 m² con dos; cambiable a 50/70/90 | Se calcula en el navegador; no se guarda |

**Superficie.** Las tres fichas de una persona comparten 50 m² para que sus mapas solo difieran por el ingreso; con superficies distintas, la diferencia mezclaría ingreso y tamaño, y la regla de la leyenda dejaría de servir. El mapa por defecto (sueldo necesario) usa también 50 m². Las fichas de escala provincial o nacional varían solo por el lado del alquiler; la llave varía por los dos lados.

**Método de la mochila** (lo más fiel a lo que cobra un joven en su provincia con fuentes públicas):
1. **Nivel provincial:** salario medio anual de 26–35 años por provincia (AEAT).
2. **De media a mediana:** se multiplica por la relación mediana/media de ese tramo de edad en su comunidad, sacada de los deciles de la propia AEAT (módulo de año completo). Supuesto: la relación es igual en todas las provincias de una comunidad; se documenta.
3. **De bruto a neto:** cotizaciones del trabajador (≈ 6,5 %) y retención media del tramo (confirmar si la AEAT la publica; si no, tipo efectivo estimado).
4. **Año completo:** se usa el salario de quien trabaja los doce meses. Si ni así llega, el argumento es más difícil de rebatir; lo cobrado en el año reflejaría mejor la precariedad, pero mezcla trabajos de verano.
5. **Control con la ECV:** mediana neta de los asalariados de 26–35 años a año completo por comunidad, con tres olas agrupadas e intervalos. Si la estimación provincial agregada se aleja del intervalo, se marca. Desde 2013 los ingresos de la ECV salen de registros administrativos, así que no mide los salarios mejor que la AEAT; aporta el neto directo, los meses trabajados y si el joven vive con sus padres (posible variante de ficha más adelante).
6. **Descartada:** la MCVL con datos fiscales (provincia × edad), porque solo se cede con fines científicos a una entidad; solo sería viable si la solicita una universidad o un centro de investigación.

**Comprobación en la AEAT (6-nov-2026): el método no se puede aplicar tal cual** (pregunta abierta 7).
- La tabla provincial (salario medio anual bruto por provincia, edad y sexo) tiene el tramo de 26–35 años. Es salario real del año: incluye a quien trabajó pocos meses.
- El «módulo salarial de año completo» (desde la edición 2019) no recoge a quien trabaja los doce meses: anualiza el salario por días cotizados (salario medio estimado, SME) y excluye los SME por debajo del SMI. Media de 26–35 años en 2024: 28.628 €, frente a 21.506 € de salario real.
- No publica la mediana por comunidad y edad: solo la media y el recuento de asalariados en cada decil nacional (con los límites de cada decil en otra tabla). La mediana se puede interpolar con esos recuentos.
- No publica la retención por edad, pero sí por tramos de retribución en múltiplos del SMI: sirve para el paso 3 aplicada al bruto estimado.
- Sin País Vasco ni Navarra en ninguna de las dos tablas (forales aparte) y sin Ceuta ni Melilla en el módulo de año completo.
- Opciones:
  - **A (recomendada):** mediana del SME de 26–35 por comunidad (interpolada de los deciles), llevada a cada provincia con la posición de su salario medio real de 26–35 respecto al de su comunidad. Mantiene la provincia y el «año completo» del paso 4; supuesto: las diferencias relativas entre provincias de una comunidad son las mismas en salario real y anualizado.
  - **B:** salario medio real provincial × relación mediana/media del SME de su comunidad. Más cerca del plan, pero aplica la forma de una distribución anualizada a otra que no lo está (la real tiene más peso de empleos de pocos meses): la mediana saldría alta.
  - **C:** mediana del SME por comunidad, sin escala provincial. La más sencilla; pierde la provincia.

**Cálculo de A y B (7-nov-2026; AEAT 2024, 46 provincias de régimen común, bruto anual de 26 a 35 años)** (`mochila_opciones`, `datos/intermedios/mochila/opciones_2024.csv`):
- **La mediana del SME por comunidad y edad se puede interpolar.** Con los recuentos en deciles nacionales y los límites de los centiles nacionales, suponiendo que dentro de cada decil la comunidad se reparte como el país. Contraste con los recuentos por centil que la AEAT da por comunidad (todas las edades): la mediana se desvía como mucho un 0,2 % (alerta `aeat_mediana_deciles`, ±0,5 %).
- **A sale entre un 24 y un 49 % por encima de B** (mediana, 34 %). La diferencia es la misma en todas las provincias de una comunidad: A / B = media del SME / media del salario real de la comunidad. Media de las provincias ponderada por asalariados: A, 24.257 €; B, 18.334 €. Donde más se separan, Andalucía y Extremadura (×1,49); donde menos, Madrid (×1,24) y Cataluña (×1,26).
- **Control con la ECV 2025** (ingresos de 2024, asalariados de 26 a 35 años por comunidad; microdatos de personas leídos fuera del pipeline, de 95 a 990 observaciones por comunidad):
  - B se parece a la mediana real de todos los asalariados: −1,7 % de media ponderada; por comunidad, entre −11 y +7 %, dentro del ruido de la encuesta. La mediana de B no sale alta, como se temía.
  - A queda un 14 % por encima de la mediana de quienes trabajan los doce meses (+30 % en Andalucía y Extremadura). El SME anualiza por días cotizados y deja fuera lo que queda por debajo del SMI, así que no es lo que cobra quien trabaja todo el año.
  - En España, el 74 % de los asalariados de 26 a 35 años con salario trabajó los doce meses.
- **Efecto en la ficha** (neto aproximado con la relación neto/bruto de la ECV): A, unos 1.660 € al mes; B, unos 1.330 €. Un alquiler de 700 € supone el 42 % con A y el 53 % con B.
- **Variante posible (D):** B por la relación entre la mediana de los asalariados a año completo y la de todos, sacada de la ECV (×1,17 en España). Mantendría la provincia y el «año completo» del paso 4 sin el sesgo del SME.

---

## 4. Principios de diseño

1. **Nivel nativo.** Cada indicador se publica en la escala en que lo produce su fuente. No se desagrega hacia abajo. Hacia arriba solo se agrega si es aritméticamente válido (medias ponderadas sí; medianas e índices no, en ese caso se toma la cifra publicada).
2. **Geografía constante.** Todas las series se reproyectan al seccionado de referencia, el del Censo 2021, con tablas de paso documentadas.
3. **Supuestos a la vista.** Los indicadores derivados (esfuerzo, barrera, años de salario) exponen sus supuestos y permiten cambiarlos, como «Construye tu estimación» en *barómetros*.
4. **Alineación temporal explícita.** Regla única para emparejar años de precio y de renta (por defecto, el mismo año de referencia; nunca el último de cada fuente sin avisar).
5. **No se publica lo que no valida.** Ninguna cifra sale si el pipeline no reproduce las publicadas por la fuente (§6.5).
6. **Cada fuente dice qué mide.** Contratos declarados, compraventas escrituradas, valor de tasación y precio de oferta no se mezclan en un mismo indicador.
7. **Bilingüe de serie.** Todos los textos visibles viven en diccionarios ES/EN desde el primer commit.
8. **Capas desmontables.** Toda fuente con riesgo legal o de continuidad se puede apagar con un interruptor.
9. **Decisiones en CSV, no en código** (como en *barómetros*): fuentes, indicadores, rupturas, tablas de paso y referencias de validación son ficheros editables.

---

## 5. Catálogo de indicadores (alcance de la v1.0)

Las marcas ★ son el núcleo de la v0.1. «A confirmar» indica que hay que verificarlo en la fuente durante la Fase 0.

### A. Capacidad de pago

| # | Indicador | Fuente | Nivel nativo | Serie | Notas |
|---|---|---|---|---|---|
| 1 ★ | Renta neta media por persona | INE, ADRH | SC | 2015–2024 | El ADRH ya incorpora datos de las Haciendas Forales y de Nastat |
| 2 ★ | Renta neta media por hogar | INE, ADRH | SC | 2015–2024 | Denominador del esfuerzo de residentes |
| 3 ★ | Mediana de la renta por unidad de consumo | INE, ADRH | SC | 2015–2024 | No se agrega: a escalas superiores se toma el dato publicado |
| 4 | Peso de los salarios en la renta | INE, ADRH (fuente de ingresos) | SC (a confirmar) | 2015–2024 | Puente entre renta y salarios |
| 5 | Población con ingresos por unidad de consumo por debajo del 60 % de la mediana | INE, ADRH | SC | 2015–2024 | Sin País Vasco ni Navarra en el ADRH: completar con Eustat y Nastat (a confirmar) |
| 6 | Índice de Gini | INE, ADRH | SC / municipio (a confirmar) | 2015–2024 | Desigualdad interna del barrio |
| 7 | Salario medio anual por asalariado (total y menores de 35) | AEAT, *Mercado de trabajo y pensiones*; equivalentes forales | Provincia | ~2004–2024 | Denominador de la barrera de acceso |

### B. Coste de la vivienda

| # | Indicador | Fuente | Nivel nativo | Serie | Notas |
|---|---|---|---|---|---|
| 8 ★ | Alquiler mensual, mediana (€/mes) | MIVAU, SERPAVI; Gobierno Vasco (estadística de fianzas) | SC | 2015–último | Contratos declarados (parque alquilado), no contratos nuevos |
| 9 ★ | Alquiler por m² (€/m²/mes) | MIVAU, SERPAVI | SC | 2015–último | Ídem |
| 10 | Variación anual del alquiler | INE, IPVA | Municipio / distrito de capitales | 2015–2024 | Índice, no nivel; separa contratos nuevos y existentes |
| 11 | Precio de compraventa (€/m²) | Portal Estadístico del Notariado | Código postal / municipio | A confirmar | Precio escriturado; condiciones de reutilización por verificar |
| 12 | Valor tasado (€/m²) | MIVAU | Municipios de más de 25.000 habitantes (a confirmar) | Serie larga, trimestral | Contraste con el Notariado |
| 13 | Precio de oferta (alquiler y venta) | Informes de Idealista y Fotocasa | Municipio / distrito | Mensual | **Capa desmontable** (§2.2) |

### C. Esfuerzo y acceso (derivados)

| # | Indicador | Construcción | Nivel | Notas |
|---|---|---|---|---|
| 14 ★ | Esfuerzo de residentes en alquiler | (alquiler × 12) / renta media por hogar | SC | Mide vulnerabilidad, no acceso |
| 15 ★ | Barrera de acceso al alquiler | Alquiler mensual / salario mensual de referencia (perfil elegido) | SC × provincia | Indicador central de la pregunta rectora |
| 16 | Años de salario para comprar | €/m² × superficie tipo / salario anual de referencia | Código postal / municipio × provincia | Superficie tipo seleccionable (por defecto 80 m²) |
| 17 | Esfuerzo hipotecario teórico | Cuota del primer año (80 % de financiación, 25 años, tipo medio) / renta o salario | Municipio | Versión local del indicador del Banco de España |
| 21 ★ | Sueldo neto necesario | Alquiler (€/m² × superficie) / umbral (30 % o 40 %) | SC | **Mapa por defecto.** 50 m² (una persona). El 30 % se inspira en el criterio de zona tensionada de la Ley 12/2023 (art. 18), que usa renta del hogar y suministros; no es ese criterio |

### D. Estructura y presión

| # | Indicador | Fuente | Nivel nativo | Serie | Notas |
|---|---|---|---|---|---|
| 18 ★ | Hogares en alquiler (%) | INE, Censo 2021 (y 2011) | SC | Dos cortes | Fotografía, no serie |
| 19 ★ | Viviendas de uso turístico (% sobre viviendas) | INE, estadística experimental | SC | 2020–, semestral | Presión del uso turístico |
| 20 | Zona tensionada declarada | BOE / MIVAU | Municipio (o el ámbito que fije la declaración) | 2024– | Capa de política pública |

### E. Sobrecarga y acceso (encuesta, otra escala)

| # | Indicador | Fuente | Nivel nativo | Serie | Notas |
|---|---|---|---|---|---|
| 22 | Tasa de sobrecarga por gastos de vivienda (método Eurostat) | INE, microdatos de la ECV; Eurostat (`ilc_lvho07a`, `ilc_lvho07c`; `ilc_lvho07_r` por regiones NUTS 2, comprobada: incluye las comunidades, solo población total, 2021–2024) | Región NUTS 2 (total) y país (desgloses) en Europa; comunidad en España | Países desde 2008 (a confirmar); regiones desde 2021 | Personas, no hogares; hipoteca solo intereses; renta del año anterior. Cortes por tenencia, edad y quintil; IC al 95 %; compuerta contra la cifra de Eurostat |
| 23 | Búsqueda de vivienda sin éxito | INE, ECV 2025, módulo de acceso a la vivienda | Comunidad | Corte único (2025) | Módulo europeo; repetición futura por confirmar |

**Reserva para después de la v1.0:** viviendas vacías (Censo 2021), población y extranjeros (padrón por SC), paro registrado (SEPE, municipio), lanzamientos (CGPJ, partido judicial), viviendas arrendadas declaradas en el IRPF (AEAT), vivienda protegida. (Las pensiones medias por provincia ya entran como ingreso del transistor, §3.1.)

---

## 6. Arquitectura

### 6.1 Repositorio

- `gastiaso/<nombre>`, público. Código con licencia MIT; datos derivados, textos e inventario con CC BY 4.0. Incluye `CITATION.cff`, `CHANGELOG.md` y `CONTRIBUTING.md`, como en *barómetros*.
- Estructura:

```
inventario/   fuentes.csv, indicadores.csv (fichas), rupturas.csv, referencias_validacion.csv, traducciones/
geo/          seccionado anual, tablas de paso, geometría de referencia
R/            funciones por fuente (descargar_*, leer_*, armonizar_*) y comunes (geo, validar, exportar)
_targets.R    pipeline completo
web/          HTML + JS (d3, MapLibre, PMTiles; dependencias autoalojadas), i18n/
pruebas/      testthat + prueba de la web con chromote
```

### 6.2 Pipeline (R al máximo)

| Necesidad | Herramienta | Nota |
|---|---|---|
| Orquestación | `targets` | Descargas cacheadas, recálculo solo de lo que cambia |
| Descargas | `httr2`, `ineapir` (paquete oficial del INE, a confirmar), `readxl` | Una función por fuente |
| Geografía | `sf`, `mapSpain`, `rmapshaper` | Simplificación por nivel de zoom |
| Datos | `arrow` (Parquet), opcional `duckdb` | Tabla larga única |
| Teselas | `tippecanoe` (línea de comandos) en GitHub Actions | Única pieza que no es R; no la tocas a mano |
| Pruebas de la web y vista previa | `chromote` / `webshot2` | Sustituye a Playwright (Python) de *barómetros* |

### 6.3 Geografía constante (la pieza crítica)

- **Insumos:** el seccionado anual del INE (shapefile a 1 de enero, 2015 → último) y el callejero del censo electoral, cuyas variaciones entre fechas publica el INE desde 2011.
- **Referencia: el seccionado del Censo 2021** (decidido el 6-nov-2026). El mapa se dibuja con sus límites.
- **Por qué 2021 y no el último:** el SERPAVI publica toda su serie 2011–2024 en ese seccionado (según sus metadatos, agrega los inmuebles que constan a la vez en la fuente tributaria y en el Catastro), y el Censo 2021 (indicador 18) y las viviendas turísticas del INE (indicador 19, todos sus periodos) también. Así, el alquiler, el Censo y las viviendas turísticas no necesitan tabla de paso, y el núcleo de la v0.1 cumple la regla del nivel nativo sin excepciones. Con el último habría que repartir las medianas del SERPAVI en las secciones divididas después de 2021.
- **Coste:** las secciones que han cambiado desde 2021 se ven con sus límites antiguos. Por códigos, de 2021 a 2025 conservan el suyo 35.955 de 36.293 (99,1 %); desaparecen 338 y aparecen 599, con Madrid a la cabeza. Con la geometría, en la provincia de Madrid (prueba de F1, 6-nov-2026): de 2021 a 2025 desaparecen 48 códigos y otras 204 secciones conservan el código pero cambian más de un 1 % de su superficie (162, más de un 25 %), es decir, 252 de 4.417 secciones (5,7 %). Entre 2015 y 2021 son 140 las que conservan el código y cambian de límites. El coste real es mayor que el estimado por códigos (1–3 %) y se concentra en los barrios en crecimiento.
- **Tablas de paso** sección del año *t* → sección de 2021, con pesos de dos fuentes alternativas:
  - (a) tramos del callejero (portales asignados a cada sección);
  - (b) edificios residenciales del Catastro (INSPIRE) ponderados por número de viviendas.
- Se documenta cuál se usa y se contrastan ambas.
- **Vía (b), viable:** cada edificio del servicio INSPIRE del Catastro trae su número de viviendas (`numberOfDwellings`), con descarga por municipio. Sin País Vasco ni Navarra (servicios forales aparte). Su licencia es contradictoria (CC BY 4.0 en los metadatos de la IDEE; una licencia de 2016 en la web del Catastro): hay que aclararla antes de publicar derivados.
  - **Prueba en Madrid (7-nov-2026):** los 55 municipios con secciones `estimado` por el callejero (335.447 edificios con 2,69 millones de viviendas; 324 MB; 22 minutos de lectura). Cada edificio cae en una sección de 2025 y en una de 2021; el peso es su número de viviendas. Donde una sección de origen no tiene edificios con viviendas, se usa la vía (a).
  - **Resultado (2024 → 2021, frente al ADRH 2020):** en las 558 secciones `estimado` por la vía (a), el 90 % central de la razón pasa de 0,69–1,54 a 0,84–1,06, las que quedan dentro de ±5 % pasan del 33 al 54 % y los errores de más del 20 %, de 128 a 27. En las demás, las dos vías dan lo mismo. Con cuatro años de distancia la prueba mezcla error y crecimiento, pero la mejora es grande y está donde fallaba el callejero.
  - **Adoptado (7-nov-2026):** vía (a) donde las secciones de origen caen enteras en una de 2021 y vía (b) donde hay que repartir, si la sección tiene edificios con viviendas (`combinar_vias()`). En las que siguen por el callejero, el peso pasa a viviendas cuando el Catastro las da, para que el origen dominante de las medianas compare viviendas con viviendas. Para los años antiguos solo cuentan los edificios ya construidos (año de construcción del Catastro): la tabla 2015 → 2021 usa los de 2015 o antes. Los pares de secciones de municipios distintos se descartan: los límites municipales se digitalizan distinto en cada seccionado y, sin ese filtro, la prueba de cierre de 2015 fallaba en dos municipios (±6–7 %).
  - **Efecto en Madrid** (73 municipios, 385.611 edificios con viviendas): secciones `estimado` de 2021, de 724 a 192 (2015 → 2021) y de 558 a 112 (2025 → 2021); medianas `ausente`, de 91 a 20 y de 233 a 133. En las secciones que el callejero repartía, los errores de más del 20 % frente al ADRH 2020 bajan de 141 a 94 (2015) y de 128 a 26 (2024). La prueba de cierre sigue en 0,0012 % como máximo.
  - **Prueba de un año de la vía (b)** (7-nov-2026; ADRH 2021, en el seccionado de 2022, llevado a 2021 y comparado con el ADRH 2020). En las 465 secciones que el callejero reparte, las que quedan dentro de ±5 % pasan del 66,5 al 92,5 %, el 90 % central de la razón pasa de 0,81–1,28 a 0,96–1,04 y los errores de más del 20 %, de 50 a 7. Es lo mismo que en las secciones que caen enteras (94,8 % dentro de ±5 %; 0,96–1,04; 7 errores de más del 20 %), es decir, el ruido de un año. Con la tabla combinada, las secciones `estimado` de 2021 pasan de 465 a 22 y las medianas `ausente`, de 191 a 18; en la tabla larga, las cifras `estimado` de la renta de 2021 bajan de 1.218 a 63.
  - **Secciones «fantasma».** El mapa del seccionado no siempre va en fase con el callejero y el ADRH del mismo año. En Madrid, el de 2022 dibuja una sección que ya se ha fusionado (2800505019, en Alcalá de Henares) y otra que los datos aún no tienen (2811501034, en Pozuelo de Alarcón). Sin corregirlo, la vía (b) asignaba toda la población de la sección fusionada a una sola de 2021 y dejaba la otra vacía, sin que lo detectara la prueba de cierre municipal. Ahora los edificios de una sección fantasma pasan al origen de los datos que, según el callejero, cubre el mismo destino; si lo cubren varios, esos orígenes siguen por el callejero (`reasignar_fantasmas()`). Nueva compuerta `cobertura_destino` (bloqueo): toda sección de 2021 debe recibir algo de la tabla. Los mapas de 2015 y 2025 no tienen fantasmas; el de 2015 tiene diez códigos que el ADRH no publica por sección (municipios de una sola sección), que sí están en el callejero.
  - **Todos los años del ADRH** (7-nov-2026): nueve tablas, una por seccionado (2016–2020 y 2022–2025; hasta pasar el ADRH 2015 al seccionado de 2016, la primera era la de 2015), con los callejeros de enero del mismo año. Secciones de 2021 `estimado` (callejero → combinada): 724 → 192 (2015), 658 → 185 (2016), 475 → 10 (2017), 444 → 2 (2018), 430 → 2 (2019), 465 → 22 (2021), 517 → 96 (2022), 532 → 98 (2023) y 558 → 112 (2024). Entre 2018 y 2021 apenas hay cambios de límites en Madrid: casi todo lo que el callejero repartía era ruido de los rangos genéricos de la aplicación antigua. Con la aplicación antigua también hay prueba de un año (ADRH 2019, seccionado de 2020): en las 430 secciones que el callejero reparte, dentro de ±5 % pasan del 87,7 al 94,2 %. Con el ADRH 2015 en el seccionado de 2016, sus secciones `estimado` pasan a 694 (callejero) y 191 (combinada), y las que conservan el código y cambian más de un 1 % de superficie hasta 2021, de 140 a 138.
  - **Pendiente:** la licencia del Catastro. Hasta aclararla, las tablas combinadas no se versionan ni se publican (se quedan en el pipeline). El feed ATOM general de edificios dice «all rights reserved», pero los de cada provincia (21-8-2026) dicen que el servicio se puede usar gratis en todo caso citando a la D. G. del Catastro como autora y propietaria.
  - **Toda España, medición (7-nov-2026; siguiente bloque, decidido por el autor).** Con los callejeros nacionales ya descargados, las tablas de paso de la vía (a) de los nueve seccionados reparten secciones en 1.489 municipios: entre 906 (2020) y 1.206 (2025) según el año, y entre 6.180 y 8.188 secciones de origen. De ellos, 80 son de País Vasco y Navarra, sin Catastro estatal: allí la vía (b) necesita los catastros forales o se queda en el callejero. Del resto, 1.328 casan por nombre con el feed del Catastro; 81 no casan por diferencias en el nombre (bilingües, artículos) y hay que casarlos por código o a mano. Descarga pendiente de permiso:
    - Catastro: 1.256 zips que faltan, 3,57 GB (el mayor, Barcelona, 50 MB), más los 81 sin casar. Al ritmo de Madrid, la lectura llevaría varias horas, por ramas.
    - ADRH: el INE publica también las dos tablas de toda España (renta, 30824; indicadores demográficos, 30832), con 37.229 secciones. Unos 0,9 GB estimados a partir de los ficheros de Madrid (el INE no da el tamaño antes de descargar).
- **Población por sección para las pruebas:** además del ADRH, el Censo anual de población por secciones (2021–2025, con sexo y edad) y el Padrón continuo por secciones (2004–2022).
- **Vía (a) en la práctica** (prueba de Madrid):
  - cada tabla compara tramos de la misma aplicación del INE: el callejero de enero de 2021 se publicó con la antigua y con la nueva, así que 2015 → 2021 usa la antigua en los dos extremos y 2025 → 2021, la nueva;
  - los tramos sin vía (código 00000) se identifican por su pseudovía; los rangos genéricos 0001–9999 de la aplicación antigua se recortan al último portal real que da la nueva;
  - el peso es el número de portales, no de viviendas: un bloque de cien viviendas pesa lo mismo que una casa. Es la razón de la vía (b).
- **Años y direcciones** (ADRH y padrón, que se publican cada año en su seccionado). El año *t* del ADRH está en el seccionado de 1 de enero de *t* + 1 (Madrid: el ADRH 2020 coincide código a código con el seccionado de 2021, y el 2024 con el de 2025; `geo_fase_codigos()` lo confirma para 2016–2023, salvo diez municipios de una sola sección que el ADRH no publica por sección hasta 2020 y las secciones fantasma del mapa de 2022). El ADRH 2015, primer año, sigue la misma regla y va con el seccionado y el callejero de 2016 (desde el 7-nov-2026; antes, con los de 2015). En Madrid no se puede distinguir: los dos seccionados tienen los mismos 4.341 códigos y los tramos del callejero no cambian; solo tres secciones de un municipio cambian de límites, por un redibujado que no mueve población. En toda España, entre 2015 y 2016 desaparecen 44 códigos y aparecen 30: la comprobación se repetirá con el ADRH de todas las provincias. Así, el ADRH 2020 es nativo; 2015–2019 van hacia delante (las divisiones obligan a repartir) y 2021–2024, hacia atrás (casi siempre es juntar).
- **Estado de las cifras reproyectadas** (adoptado el 6-nov-2026, a partir de la prueba de un año; decide la sección, no la dirección). Una sección de origen «cae entera» en la de 2021 si su fracción hacia ella es ≥ 0,99:
  - recuentos y medias ponderadas: `dato` si todos los orígenes que recibe caen enteros (sumar, o promediar con su denominador, es exacto); `estimado` si alguno se reparte;
  - medianas e índices: no se combinan, se copia la de un solo origen. `dato` con un único origen que cae entero (la misma sección, aunque cambie de código); `estimado` con un único origen repartido o con un origen dominante, que aporta al menos el 95 % de los portales de la sección (adoptado el 6-nov-2026, pregunta abierta 6); `ausente` si ninguno domina, y se remite a la escala superior;
  - el `estimado` es una excepción declarada a la regla del nivel nativo, limitada a esas secciones y años.
  - En Madrid, secciones `dato` para recuentos y medias: 3.693 (2015 → 2021), 3.952 (2022 → 2021) y 3.859 (2025 → 2021) de 4.417. Para medianas, `ausente` en 91, 191 y 233 (sin la regla del origen dominante eran 525, 455 y 459: bastaba con que la sección recibiera una pequeña parte de una vecina).
  - **Contraste del origen dominante** (prueba de un año, con dos indicadores del ADRH que no se suman: edad media y tamaño medio del hogar, copiados de 2021 y comparados con 2020). Con un origen que aporta ≥ 95 % (264 secciones), el error es el de las secciones 1:1: en la edad media, mediana de 0,4 años y percentil 90 de 0,87 (0,90 en las 1:1); en el tamaño del hogar, igual. Entre el 80 y el 95 % (100 secciones) la cola empeora (percentil 99 de 2,7 años frente a 1,4), y por debajo del 80 %, más. Las 24 secciones con un único origen repartido tienen la peor cola (percentil 99 de 17 años): son divisiones donde la parte nueva no se parece a la madre.
  - Implementado en `geo_estado_paso()` y en `geo_reproyectar_recuento()`, `geo_reproyectar_media()` y `geo_reproyectar_mediana()`.
- **Prueba de cierre:** la población del padrón por sección reproyectada debe cuadrar, municipio a municipio, con la suma de sus secciones de origen (±0,5 %). Hasta el 7-nov-2026 se comparaba con el total municipal publicado, pero el ADRH no siempre suma sus secciones a ese total: en 2016, 2017 y 2019 se queda por debajo en unos pocos municipios (Tres Cantos, −1,2 %, y Paracuellos de Jarama, −1,0 %, en 2016; Arganda del Rey, −1,0 %, y Boadilla del Monte, −0,5 %, en 2019), con todas las secciones con dato. Es una diferencia de la fuente, no de la tabla: la vigila aparte la alerta `adrh_suma_secciones`.
  - **Resultado en Madrid (6-nov-2026):** ADRH 2015 → 2021 y ADRH 2024 → 2021, desviación máxima 0,001 % en 169 y 179 municipios; ninguna sección sin tabla de paso. Con las tablas combinadas (7-nov-2026), igual, y también con el ADRH 2021 (0,0012 % como máximo en los tres años).
  - **Con todos los años** (7-nov-2026): cierre exacto y cobertura completa en las nueve tablas.
  - **Cobertura de destino** (`cobertura_destino`, desde el 7-nov-2026): ninguna sección de 2021 se queda sin recibir nada.
  - **Es una prueba débil por construcción:** las tablas no cruzan municipios y cada sección reparte el 100 %, así que solo detecta secciones sin tabla y municipios que cambian. Un primer error de casado (tramos sin vía casados entre sí en todo el municipio) la pasaba igual.
  - **Diagnóstico sección a sección** (`diagnostico_f1`, no es compuerta): la población llevada a 2021 frente a la del ADRH 2020, nativo en 2021. En las secciones sin cambios, el 90 % de las razones queda entre 0,94 y 1,15 (2015) y entre 0,87 y 1,05 (2024). Quedan 63 y 26 secciones con razón fuera de [0,55; 1,8] (59 y 22 de ellas, en secciones afectadas por cambios), la mayoría en barrios en crecimiento (Valdebebas, El Cañaveral, Ensanche de Vallecas, entre otros), donde con cuatro o cinco años de distancia no se separa el error de la tabla del crecimiento real.
  - **Prueba de un año** (ADRH 2021, en el seccionado de 2022, llevado a 2021 y comparado con el ADRH 2020; un año de crecimiento apenas estorba):
    - en las 3.954 secciones de 2021 que no reciben población de otro código, el 94,6 % queda dentro de ±5 % (90 % entre 0,96 y 1,04): es el ruido de un año;
    - en las que reciben entre el 5 % y el 50 % de otro código (172), solo el 45,9 %; en las que reciben más del 50 % (31), el 12,9 %, con errores de hasta el doble;
    - la tabla es exacta cuando cada sección de origen cae entera en su destino (sumar recuentos no necesita pesos) y se equivoca cuando hay que repartir: el peso por números de portal no ve si un número existe solo sobre el papel, como en los barrios a medio construir.
  - **De ahí la regla de estado** (ver arriba): en la prueba de un año, las secciones `dato` (3.952, 89,5 %) se comportan como el ruido de un año (94,6 % dentro de ±5 %, 7 errores de más del 20 %); las `estimado` (465), no (66,5 %; 50 errores de más del 20 %).
  - **Siguiente paso** (hecho el 7-nov-2026): la vía (b), viviendas del Catastro, en las secciones `estimado`; su prueba de un año, más arriba.
- **Códigos postales:** no son una unidad del INE. Hay que localizar su geometría (CartoCiudad, a confirmar) y una tabla CP ↔ municipio, solo para los indicadores 11 y 16.

### 6.4 Modelo de datos

Una tabla larga en Parquet:

```
geo_id | nivel (sc, distrito, municipio, cp, provincia, ccaa) | anio | indicador | corte | grupo | valor | estado (dato, secreto, ausente, estimado) | fuente | geo_ref (seccionado de referencia) | version
```

`corte` y `grupo` (desde el 7-nov-2026, pregunta abierta 10) guardan los desgloses: `corte` es la variable (`tenencia`, `edad`) y `grupo`, su valor (`alquiler_mercado`, `18_64`…). Sin desglose, las dos valen `total`. La clave de una fila es `geo_id`, `nivel`, `anio`, `indicador`, `corte` y `grupo`.

Junto a ella, `metadatos.json` con fichas bilingües, rupturas, supuestos por defecto y fecha de cada fuente.

### 6.5 Validación (compuerta de publicación)

- **Reproducción:** agregados calculados frente a tablas publicadas. Por ejemplo, municipios del ADRH frente a sus SC cuando la agregación es válida; totales provinciales del SERPAVI; salarios provinciales de la AEAT.
- **Coherencia entre fuentes** (alerta, no bloqueo):
  - renta del ADRH frente a renta bruta de la AEAT por municipio;
  - tendencia del SERPAVI frente al IPVA;
  - Notariado frente a valor tasado.
- **Geografía:** cierre poblacional de las tablas de paso.
- **Sobrecarga (doble control):** el cálculo con microdatos de la ECV reproduce la cifra de Eurostat para España (total e inquilinos a precio de mercado) y la de cada comunidad en la serie regional `ilc_lvho07_r`, con ±0,1 puntos.
- **Mochila:** la estimación provincial agregada a comunidad cae dentro del intervalo de la mediana neta de la ECV.
- **Web:** la página recalcula una muestra de cifras y debe coincidir con R. Si algo falla, no se publica.

### 6.6 Web

- **Navegación:** mapa por SC (MapLibre + PMTiles con la geometría de referencia), ficha de sección y de municipio, comparador entre territorios, «Tu sueldo» y la sección de sobrecarga.
- **Tu sueldo:**
  - por defecto, el mapa muestra el sueldo neto necesario para 50 m² (indicador 21), con las fichas de una persona como marcas sobre la regla de la leyenda y la llave como un tramo, porque su renta cambia por sección;
  - al escribir un sueldo o elegir ficha, pasa a «¿te llega?»: tramos hasta el 30 %, 30–40 % y más del 40 %, y una frase resumen («te cabe en el X % de las secciones con dato»);
  - cada ficha con su vivienda (§3.1); «Tu ficha» con 50 o 70 m² según los sueldos, cambiable a 50/70/90; umbral del 30 o del 40 %;
  - el color se recalcula en el navegador cambiando la expresión de estilo de MapLibre, sin volver a descargar teselas;
  - el sueldo no sale del dispositivo; solo va en el enlace si el usuario pulsa «Compartir», con aviso previo.
- **Sobrecarga:** un solo mapa de Europa que cambia de escala según el corte. Para toda la población, regiones NUTS 2 (Eurostat; Canarias en recuadro). Con tenencia o edad, que Eurostat no publica por regiones, países, y España siempre por comunidades con los microdatos del INE. «La escalera» ordena en una sola lista lo que muestra el mapa en tres bloques: lo más alto de Europa (sin comunidades), las referencias (UE-27 y España) y las 19 comunidades, cada una con su puesto en la lista completa; caja de método y módulo de acceso. Se presenta como otro tablero: encuesta, no registro.
  - **Huecos del mapa regional** (`ilc_lvho07_r`, comprobado el 6-nov-2026): 204 regiones NUTS 2 de 26 países en 2025, de 2021 a 2025. Francia y Austria solo publican el dato del país y Países Bajos, solo NUTS 1; Dinamarca entra en 2025. Propuesta: pintar en esos países el dato disponible (país o NUTS 1) con una trama y una nota fija.
  - **Versión NUTS de cada año:** la serie mezcla NUTS 2021 (2021–2023) y NUTS 2024 (desde 2024; cambian las regiones de Portugal). La geometría se elige por año.
  - **Licencia de las geometrías:** las de GISCO (NUTS) son de uso no comercial y exigen el aviso «© EuroGeographics para los límites administrativos» en el mapa. No entran en la licencia CC BY 4.0 de los datos del atlas (`LICENCIA_DATOS.md`).
- **Datos:** binarios por indicador y año, que se cargan bajo demanda; sin servidor ni analítica.
- **Uso:** URL con el estado de la vista, ES/EN, modo daltónico, exportación CSV y PNG, descarga del Parquet.
- **Límites a vigilar:** 100 MB por fichero en GitHub y 1 GB por sitio de Pages. Una sola geometría de referencia mantiene el PMTiles bajo control.

---

## 7. Fases

Sin fechas. Cada fase se cierra con un criterio verificable y, salvo F0 y F1, con una publicación. El tamaño es relativo (M = mediano, L = grande).

### F0 · Cimientos — M

- **Contenido:**
  - resolver §2.2 (portales);
  - esqueleto del repo con licencias y CI vacío;
  - `fuentes.csv` (acceso, licencia, cadencia, desfase, cobertura, forales) y las 23 fichas de indicador;
  - cerrar el nombre (la identidad ya está elegida: tablero) y pasar las maquetas a un mini sistema de diseño;
  - diccionario i18n base.
- **Hecho cuando:** cada fuente tiene una función R de descarga reproducible y cada indicador, su ficha completa ES/EN.

### F1 · Geografía constante — L (la más arriesgada)

- **Contenido:**
  - seccionados 2015 → último, todos llevados al de 2021;
  - tablas de paso con las dos vías de ponderación, en las dos direcciones (§6.3);
  - jerarquía SC → distrito → municipio → provincia → comunidad;
  - geometría de CP;
  - PMTiles de referencia.
- **Hecho cuando:** pasa la prueba de cierre poblacional y el mapa base se ve en local.

### F1b · Sobrecarga y Europa → v0.0 pública — M (en paralelo a F1)

- **Contenido:**
  - indicadores 22 y 23;
  - microdatos de la ECV del INE (reutilizando código propio previo), Eurostat con el paquete `eurostat` y geometrías GISCO con `giscoR`;
  - mapa único de Europa: regiones NUTS 2 para el total (`ilc_lvho07_r`, geometrías NUTS de Eurostat); países y comunidades para tenencia, edad y quintil; «la escalera»;
  - varias olas agrupadas cuando la celda comunidad × tenencia no tenga muestra suficiente;
  - primera versión pública de la identidad, el bilingüe y la compuerta.
- **Hecho cuando:** pasa el doble control de §6.5 (España y cada comunidad frente a Eurostat, ±0,1 puntos).
- **Condición:** si el cruce comunidad × tenencia no supera los umbrales de publicación de EU-SILC, la sección pierde su valor añadido frente al visor de Eurostat y se aplaza a F6. Se publica sin intervalos, con el número de observaciones y la marca de fiabilidad (pregunta abierta 9, cerrada).
- **Avance (7-nov-2026):**
  - Tres olas de la ECV (2023–2025) en el pipeline; las tres pasan la compuerta: España, inquilinos a precio de mercado, las 19 comunidades y los cuatro grupos de edad (diferencia máxima con Eurostat, 0,05 puntos). La edad es la del final del año de ingresos (RB081): con la de la entrevista, el corte de 2025 se desviaba 0,12 puntos.
  - Comunidad × tenencia y comunidad × edad con las tres olas agrupadas: todas las celdas superan las 50 observaciones (la menor, 261 personas en alquiler de mercado en Melilla), así que pasan los umbrales de publicación de EU-SILC. Sin intervalos (pregunta abierta 9, cerrada).
  - Europa: todos los países (tenencia y edad) y las regiones NUTS 2, con su versión de geometría (GISCO 2021 y 2024); solo faltan geometrías para el código agrupado FI19_20 y para Bosnia y Herzegovina en 2022–2023. «La escalera» de 2025: 214 entradas; las comunidades van del puesto 23 (Melilla, 13,8 %) al 185 (Navarra, 3,5 %).
  - Indicador 23 desde las tablas del módulo (comunidades, edad y sexo, tenencia).
  - Ficheros intermedios en `datos/intermedios/sobrecarga/`; total y comunidades de los indicadores 22 y 23, también en la tabla larga.

### F2 · Núcleo renta y alquiler → v0.1 pública — L

- **Contenido:**
  - indicadores 1–3, 8, 9, 14, 15, 18, 19 y 21 (★), con País Vasco (Gobierno Vasco) y Navarra en el SERPAVI;
  - «Tu sueldo» mínimo: neto mensual, «Tu ficha» con su vivienda, umbral; la tartera (SMI) ya disponible;
  - compuerta de validación;
  - web con mapa, fichas, comparador y descargas, bilingüe.
- **Hecho cuando:** la validación pasa, la web se publica en Pages y hay una nota metodológica.
- **Nota:** el mapa por defecto (21) no necesita salarios; el indicador 15 y la mochila sí necesitan el salario provincial (7), que se adelanta en versión mínima.

### F3 · Salarios, fichas completas y supuestos → v0.2 — M

- **Contenido:**
  - indicadores 4–7 completos (por edad, forales);
  - fichas completas (§3.1): mochila con el método en cinco pasos y su control con la ECV; transistor con la pensión de jubilación del INSS;
  - sueldo necesario expresado también como percentil de la distribución salarial (para comparar en el tiempo);
  - 14 pagas, segundo sueldo y banda SERPAVI–oferta en la ficha de sección;
  - módulo de supuestos.
- **Hecho cuando:** cada combinación de supuestos está documentada y validada en una muestra.

### F4 · Compraventa → v0.3 — M

- **Contenido:**
  - indicadores 10–12, 16 y 17;
  - tabla de paso CP ↔ municipio;
  - tipo hipotecario medio.
- **Hecho cuando:** el Notariado y la tasación son coherentes dentro de un umbral razonado y las condiciones de reutilización del Notariado están verificadas.

### F5 · Presión y portales → v0.4 — M

- **Contenido:** indicadores 13 y 20, con la capa desmontable probada (apagar y encender sin romper la web).
- **Hecho cuando:** el interruptor funciona y la capa privada está etiquetada en todas partes.

### F6 · Histórico, relato y v1.0 — M

- **Contenido:**
  - módulo histórico nacional y autonómico desde 1987: esfuerzo del Banco de España, valor tasado, salarios y tipos (es la «máquina del tiempo» que da sentido a la identidad retro);
  - primeras historias;
  - enlace con *barómetros* (el problema de la vivienda en el CIS frente a los datos, por comunidad);
  - automatización de las actualizaciones.
- **Hecho cuando:** el calendario de fuentes dispara las actualizaciones y el CHANGELOG está al día.

---

## 8. Calendario de mantenimiento (orientativo, a confirmar)

| Fuente | Publicación habitual | Desfase aproximado |
|---|---|---|
| ADRH (INE) | Octubre | ~22 meses (datos de 2024 publicados el 19-10-2026) |
| AEAT IRPF por municipio y CP | Octubre | ~22 meses |
| AEAT *Mercado de trabajo* | Noviembre–diciembre | ~11 meses |
| IPVA (INE) | Mayo | ~17 meses |
| SERPAVI (MIVAU) | Anual, sin fecha fija | Variable |
| Viviendas turísticas (INE) | Semestral | Meses |
| Notariado | Mensual | Meses |
| Seccionado del INE | Anual (referencia 1 de enero) | — |
| ECV (INE) | Febrero | Rentas del año anterior |
| Sobrecarga por regiones (Eurostat) | Anual | Un año |
| Pensiones contributivas (INSS) | Mensual | Un mes |

Consecuencia: el atlas siempre irá **uno o dos años por detrás** en renta y salarios. Hay que decirlo arriba del todo, no en la letra pequeña.

---

## 9. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Tablas de paso entre seccionados poco robustas | Alta | Alto | F1 antes que nada; dos vías de ponderación; prueba de cierre y de cobertura; prueba de un año |
| Requerimiento de un portal | Media | Alto | Capa desmontable, repo satélite, solo informes agregados |
| Alcance (23 indicadores, una persona) | Alta | Medio | v0.0 con 2 (F1b), v0.1 con 10; el resto por fases |
| F1b le quita tiempo a F1, la fase crítica | Media | Medio | Condición de salida de F1b; si no aporta comunidad × tenencia, se aplaza |
| La sobrecarga cuenta la historia contraria (mínimos de la serie) | Alta | Medio | Titular por inquilinos a precio de mercado; módulo de acceso; texto que lo explica |
| Falsa precisión en «Tu sueldo» | Media | Medio | Tramos, número de contratos, banda SERPAVI–oferta, año del alquiler visible |
| Mochila: la relación mediana/media autonómica no vale para todas sus provincias | Media | Medio | Supuesto documentado; control con la ECV; revisión en las provincias más alejadas de la media de su comunidad |
| Mapa europeo que cambia de escala según el corte | Media | Bajo | Título y fuente del mapa cambian con el modo; nota fija bajo el mapa |
| Huecos por secreto estadístico | Seguro | Medio | Estado «secreto» explícito; agregados superiores |
| Cambio de método en una fuente (p. ej., el SERPAVI) | Media | Medio | Registro de rupturas y compuerta |
| Mantenimiento anual que se acumula | Alta | Medio | Calendario en CI; actualizaciones automáticas con revisión |
| Web pesada en móvil | Media | Medio | PMTiles por zoom y datos por demanda |
| Estética retro que resta credibilidad ante el público principal | Media | Medio | Pixel solo en identidad y titulares; datos en tipografía legible |

---

## 10. Identidad

### 10.1 Nombres (22)

| # | ES | EN | Idea | Riesgo |
|---|---|---|---|---|
| 1 | **Años de sueldo** | *Years of Pay* | El indicador es el nombre | Promete salarios; exige definir bien el salario de referencia |
| 2 | **Nivel de vida** | *Living Level* | Doble sentido: nivel del juego y nivel de vida | El juego de palabras no pasa al inglés |
| 3 | **¿Me llega?** | *Can I Make Rent?* | Pregunta cotidiana | Coloquial; puede sonar ligero |
| 4 | **Metro a metro** | *Metre by Metre* | m², barrio y guiño a *Barómetro a barómetro* | Puede sonar a «lo mismo» |
| 5 | **Techo** | *Ceiling* | Techo como casa y como límite de gasto | Genérico; difícil de buscar |
| 6 | **Piso piloto** | *Show Flat* | Folleto de promoción de los 70 y 80; proyecto piloto | Nombre muy usado |
| 7 | **Llave en mano** | *Turnkey* | Lenguaje inmobiliario clásico | Suena a promotora |
| 8 | **Casilla de salida** | *Square One* | Juego de mesa; emanciparse | — |
| 9 | **Inserte moneda** | *Insert Coin* | Pagar para jugar, pagar para vivir | Cínico |
| 10 | **Vida extra** | *Extra Life* | Lo que queda tras pagar la casa (renta residual) | Ambiguo sin subtítulo |
| 11 | **¿Cuántas nóminas?** | *How Many Paychecks?* | Métrica intuitiva | Largo |
| 12 | **Entrada** | *Down Payment* | La entrada del piso y el *start* | Genérico |
| 13 | **Barrio a barrio** | *Block by Block* | Escala del atlas | Cercano a «calle a calle» de los medios |
| 14 | **Hogar, dulce dato** | *Home, Sweet Data* | Dicho bordado de las casas | Tono amable que choca con el tema |
| 15 | **El precio de quedarse** | *The Price of Staying* | Desplazamiento y gentrificación | Más tesis que herramienta |
| 16 | **Mi primera casa** | *My First Home* | Caja de juguete («edad recomendada: +30») | — |
| 17 | **Cuesta arriba** | *Uphill* | La curva de precios como pendiente de un juego de plataformas | — |
| 18 | **Modo difícil** | *Hard Mode* | Dificultad por territorio | Gamifica un problema serio |
| 19 | **Se alquila** | *To Let* | Cartel de balcón | Solo alquiler |
| 20 | **Récord** | *High Score* | Récord de esfuerzo | Celebra lo negativo |
| 21 | **Atlas de lo asequible** | *Affordability Atlas* | Descriptivo y sobrio | Poca personalidad |
| 22 | **Mapa del esfuerzo** | *Effort Map* | Descriptivo, centrado en el indicador | Poca personalidad |

Terna inicial: **Años de sueldo** (claridad para periodistas), **Nivel de vida** (el mejor juego de palabras en castellano) y **Casilla de salida** (encaja con el «para quién» y la emancipación). Antes de decidir hay que comprobar que no choquen con otros proyectos (GitHub, dominios, OEPM).

**Comprobación (6-nov-2026; DNS, RDAP, API de GitHub y TMview, que reúne OEPM y EUIPO):**

| | Casilla de salida / *Square One* | Años de sueldo / *Years of Pay* | Nivel de vida / *Living Level* |
|---|---|---|---|
| GitHub | Libre en castellano. *Square One*: organizaciones `square-one` y `squareone` ocupadas y cientos de repositorios (ninguno de vivienda) | Libre | Libre (solo repositorios escolares parecidos) |
| Dominios | `casilladesalida` y `casilla-de-salida` (.es, .org, .com) no existen en DNS. *Square One*: todos registrados | Todos parecen libres | `niveldevida.com` registrado en octubre de 2026 (tienda); `livinglevel.com` a la venta; .es y .org parecen libres |
| Marcas (ES y UE, vigentes) | Ninguna «Casilla de salida». *Square One*: varias en las clases 9, 35, 41 y 42 (una de software de datos, otra de inmuebles) | Ninguna | Ninguna exacta; ocho «… Niveles de vida» en las clases 5 y 35 (complementos) |
| Choques | Frase hecha muy usada en prensa; *Square One*, ONG de vivienda en Oregón y modismo inglés | Es la métrica que publican portales y tasadoras («8,4 años de sueldo») | Término genérico; el ADRH del INE habla de «nivel de renta» |

Límites: un .es sin DNS puede estar registrado sin delegar (confirmar en dominios.es); TMview no tiene valor legal (confirmar en el localizador de la OEPM, clases 9, 35, 41 y 42).

**Elegido (7-nov-2026): *De renta en renta*.**
- **Origen:** el dicho del juego de la oca («de oca a oca y tiro porque me toca»), de dominio público. Con «en», como en «de casa en casa», expresa una serie.
- **Doble sentido:** *renta* es el ingreso y lo que paga el arrendatario (DLE, acepciones 2 y 3): los dos términos de la cuenta del atlas. También cubre la compraventa, que el Banco de España mide en años de renta.
- **Sin traducir.** El juego de palabras no pasa al inglés. Descartado *Rent to Rent*: en Reino Unido nombra una estrategia de inversión basada en subarrendar.
- **Dicho de portada:** «De renta en renta, y pago porque me toca» (`web/i18n`, `sitio.dicho`). Solo en la portada: el título, la cita (`CITATION.cff`) y los metadatos quedan neutros.
- **Repositorio y carpeta:** `de-renta-en-renta` (iguales, para que `git clone` cree la misma carpeta).
- **Identidad:** se mantiene el tablero cuadrado; la oca queda solo en el nombre.
- **Riesgos asumidos:** en España «la renta» evoca primero la declaración de Hacienda, y «vivir de las rentas», al rentista; el dicho opina.
- **Comprobado (7-nov-2026):** sin repositorios en GitHub ni webs con ese nombre. **Pendiente:** marcas (TMview y OEPM), con el método de la terna (backlog, tarea 2).
- **Sin dominio propio** (7-nov-2026): la web se sirve en la dirección de GitHub Pages del repositorio `de-renta-en-renta`.

### 10.2 Maquetas de estilo

22 maquetas de estilo: 20 retro, una de cartografía antigua y una de control sobria. Usan el mismo contenido: mapa pixelado ilustrativo y cifras nacionales de referencia del Banco de España (1987, 2007, 2023 y el 72 % de 1990), que hay que verificar en la serie original antes de publicarlas.

**Finalistas (6-nov-2026):** fósforo ámbar (*¿Me llega?*), recreativa (*Inserte moneda*) y tablero (*Casilla de salida*). Cada uno mantiene su nombre y se descarta la combinación de estilos. Cada finalista se prueba en cuatro pantallas: portada, explorador de mapa, ficha de sección en móvil y hoja de estilo con contrastes calculados. Los puntos débiles detectados son:
- **Ámbar:** sin variante clara para exportar gráficos a prensa.
- **Recreativa:** el amarillo es a la vez el tramo más alto del mapa y el color de los botones; los tramos bajos solo se distinguen por el tono; tiende a los rankings.
- **Tablero:** los dos tramos bajos quedan por debajo de 3:1 sobre la crema; es la menos «8 bits».

**Elegido (6-nov-2026): tablero** (entonces con el nombre de trabajo *Casilla de salida*; nombre definitivo en §10.1).
- **Portada:** el tablero completo.
- **Tipografía:** el juego de cartas clásico, con equivalentes libres (OFL; Yellowtail, Apache 2.0):
  - Jost para el tablero, los titulares y las cifras (en lugar de Kabel y Futura);
  - Marcellus SC para las cabeceras de escritura (en lugar de Copperplate Gothic);
  - Archivo Narrow para el texto de las cartas (grotesca condensada);
  - Yellowtail para las cabeceras de carta (en lugar de Brush Script).
- **Fichas:** dibujos propios en estilo clip-art de tablero clásico (tinta negra, color plano, sombra en bloque; opción A, elegida frente al grabado de 1904). El color del perfil va en el propio objeto y, sobre fondo oscuro, la ficha lleva una placa crema. Cada una combina objeto, color y nombre:
  - llave: hogar del barrio;
  - mochila: joven menor de 35;
  - tartera: salario mínimo;
  - transistor: pensionista;
  - peón verde: «Tu ficha», el sueldo que escribe cada usuario.
- **Pantallas añadidas (6-nov):** «Tu sueldo» (sueldo necesario y ¿te llega?) y «Sobrecarga» (España y Europa), con valores de ejemplo.
- **Límite:** nada de elementos propios de Monopoly (sus fichas, sus esquinas, la banda diagonal del título ni los nombres de sus mazos).
- **Referente histórico:** *The Landlord's Game* (Lizzie Magie, 1904), de dominio público.

**Criterios para elegir:**
1. Legibilidad de datos a 12–14 px.
2. Paleta secuencial de 4–5 pasos distinguible por personas daltónicas.
3. Que funcione en móvil.
4. Que no reste credibilidad ante el público principal.
5. Que sea propia: ni *barómetros* ni una marca comercial reconocible.

---

## 11. Preguntas abiertas

1. **Escalonado.** Cerrada el 7-nov-2026: v0.0 (sobrecarga), v0.1 con 10 indicadores y los 23 para la v1.0 (§2.3).
2. **Portales.** Cerrada el 7-nov-2026: capa desmontable, solo informes agregados y repo satélite por valorar (§2.2). El autor aportará los datos completos de Idealista; sus condiciones de uso se revisan al recibirlos.
3. **Nombre.** Cerrada el 7-nov-2026: *De renta en renta*, sin traducir (§10.1). Sin dominio propio: la web va en la dirección de GitHub Pages. Faltan las marcas (backlog, tarea 2).
4. **Seccionado de referencia.** Cerrada el 6-nov-2026: el del Censo 2021 (§1 y §6.3). Se descartó el último porque obligaba a repartir las medianas del SERPAVI: 227 de las 26.137 secciones con dato en 2024 tienen un código que desaparece antes de 2025 (0,6 % de los testigos).
5. **Estado de las cifras reproyectadas.** Cerrada el 6-nov-2026 (§1 y §6.3). Las medias ponderadas siguen a los recuentos, como manda la regla del nivel nativo; el 1:1 se exige solo a las medianas.
6. **Medianas `ausente` por aportes pequeños.** Cerrada el 6-nov-2026: se copia la mediana del origen dominante (≥ 95 % de los portales) como `estimado` (§6.3). En Madrid, las medianas `ausente` bajan a 91, 191 y 233 según el año.
7. **Método de la mochila.** La AEAT no publica la mediana por comunidad y edad, y su «año completo» es un salario anualizado, no el de quien trabaja doce meses (§3.1). Opciones A (recomendada), B y C. Por decidir antes de F3; la v0.1 solo necesita el salario provincial medio (indicador 7, versión mínima). Calculadas A y B (7-nov-2026, §3.1): A queda un 34 % por encima de B (mediana de las provincias) y un 14 % por encima de lo que cobra en la ECV quien trabaja los doce meses; B se parece a la mediana real. Decisión del autor (A, B, C o la variante D).
8. **Alquiler del País Vasco (y Navarra) en los años sin SERPAVI.** Cerrada el 7-nov-2026. La estadística del Gobierno Vasco (fianzas) no baja a sección censal (municipios de más de 5.000 habitantes y barrios de las capitales) y da la media, no la mediana; Navarra no tiene ninguna fuente antes de 2021. Esas secciones van sin dato esos años, y la estadística de fianzas, como capa aparte de contexto municipal, sin mezclarla con el indicador 8 (regla 5: cada fuente dice qué mide).
9. **Intervalos de confianza de la sobrecarga.** Cerrada el 7-nov-2026: sin intervalos. Los microdatos públicos de la ECV no traen estratos ni unidades primarias de muestreo, así que no se puede calcular el error de diseño, y la aproximación con los coeficientes de variación de otro indicador (la tasa AROPE) se descarta. Cada cifra lleva el número de observaciones y la marca de fiabilidad de EU-SILC.
10. **Desgloses en la tabla larga.** Cerrada el 7-nov-2026: dos columnas nuevas, `corte` y `grupo` (`total` en las dos por defecto), para que la sobrecarga por tenencia o edad viva en la misma tabla (§6.4).
11. **Diferencia del ADRH entre secciones y municipio.** Cerrada el 7-nov-2026: alerta (`adrh_suma_secciones`), no bloqueo. Es un fallo de la fuente que el atlas no puede corregir; se documenta en la ficha.

**Por verificar en F0** (no son decisiones, son comprobaciones), hechas el 6-nov-2026:
- cortes de edad de la AEAT (<18, 18–25, 26–35, 36–45, 46–55, 56–65, >65) y módulo de año completo (desde 2019; ver §3.1);
- retención media: no por edad; sí por tramos de renta y de retribución (§3.1);
- cobertura de `ilc_lvho07_r` país a país (§6.6).

---

## 12. Fuentes consultadas

- INE, [ADRH 2024, nota de prensa (19-10-2026)](https://www.ine.es/dyngs/Prensa/ADRH2024.htm) · [Metodología ADRH](https://ine.es/metodologia/metodologia_adrh.pdf)
- INE, [IPVA 2024 (11-05-2026)](https://www.ine.es/dyngs/Prensa/IPVA2024.htm)
- INE, [Cartografía de secciones censales y callejero del censo electoral](https://www.ine.es/uc/1dIJtjmE)
- MIVAU, [SERPAVI: base de datos 2011–2024, metodología y capas](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) · [aviso legal: reutilización](https://www.mivau.gob.es/ministerio/aviso-legal)
- La Moncloa / MIVAU, [Mapa de precios de referencia del alquiler: cobertura y actualización](https://www.lamoncloa.gob.es/serviciosdeprensa/notasprensa/vivienda-agenda-urbana/Paginas/2024/mapa-precios-referencia-alquiler-vivienda.aspx)
- datos.gob.es, [Solicitud de acceso reutilizable al SERPAVI (ago-2026)](https://datos.gob.es/es/solicitud-de-datos/ser-de-precios-de-alquiler-eum2-codigo-ine-periodicidad-historico-diccionario)
- AEAT, [IRPF de los mayores municipios por código postal](https://sede.agenciatributaria.gob.es/Sede/datosabiertos/catalogo/hacienda/Estadistica_del_IRPF_por_codigo_postal.shtml) · [Mercado de trabajo y pensiones 2024](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/mercado/2024/mapa.html) · [Viviendas declaradas en el IRPF](https://datos.gob.es/gl/catalogo/ea0028512-estadistica-de-viviendas-declaradas-en-el-irpf)
- Gobierno Vasco, [Estadística del mercado del alquiler](https://euskadi.eus/contenidos/informacion/ovv_emal_manual_122417/es_ovv_sevi/Consulta-de-la-estadistica-del-mercado-del-alquiler.pdf)
- Idescat, [E02 Estadística territorial de salarios (experimental)](https://idescat.cat/estad/experimental/e02?lang=en)
- Portal Estadístico del Notariado: [penotariado.com](https://www.penotariado.com)
- P. García Guzmán, [ineAtlas (R)](https://github.com/pablogguz/ineAtlas)
- Esade EcPol, [Regular el precio de alquiler: un dilema entre eficiencia y equidad](https://www.esade.edu/ecpol/es/publicaciones/regular-el-precio-de-alquiler-un-dilema-entre-eficiencia-y-equidad/)
- MIVAU / UPM, [Catálogo de Barrios Vulnerables 2021](https://oa.upm.es/91832/3/00_INTRODUCCION_A.pdf)
- Banco de España, vía prensa: [El Debate (2023)](https://www.eldebate.com/economia/20231004/familias-espanolas-necesitan-mas-7-anos-salario-39-ingresos-adquirir-vivienda_144203_amp.html) · [Bankinter](https://www.bankinter.com/blog/finanzas-personales/esfuerzo-economico-comprar-casa) · [Xataka](https://www.xataka.com/magnet/espana-se-ha-situado-cabeza-europa-algo-esfuerzo-acumulado-anos-80-para-comprarse-vivienda). *Cifras a contrastar con la serie original del Banco de España.*
- Normativa: TRLPI (RDLeg 1/1996), arts. 97.4 y 133 y ss.; Directiva 96/9/CE, art. 7; STJUE C-202/12 (*Innoweb*) y C-30/14 (*Ryanair*).
- Eurostat, [definición de la tasa de sobrecarga](https://ec.europa.eu/eurostat/web/products-eurostat-news/-/ddn-20210209-1) · EPAH, [ficha del indicador](https://energy-poverty.ec.europa.eu/modules/custom/epah_indicator/pdfs/Housing_cost_overburden_rate.pdf) y [serie por regiones NUTS (`ilc_lvho07_r`)](https://energy-poverty.ec.europa.eu/taxonomy/term/2902)
- INE, [ECV 2025, resultados definitivos (5-02-2026)](https://ine.es/dyngs/Prensa/ECV2025.pdf) · [Módulo de acceso a la vivienda](https://ine.es/dyngs/Prensa/m3ECV2025.htm)
- FEDEA, [esfuerzo residencial con microdatos de la ECV (2026)](https://documentos.fedea.net/pubs/eee/2026/eee2026-08.pdf): incluye la hipoteca bruta, no comparable con Eurostat
- CaixaBank Research, [contratos nuevos frente a existentes](https://www.caixabankresearch.com/en/node/14257/printable/print)
- [Real Decreto 126/2026 (SMI 2026), BOE de 19-02-2026](https://www.boe.es/boe/dias/2026/02/19/pdfs/BOE-A-2026-3815.pdf) · Ley 12/2023, por el derecho a la vivienda, art. 18
- DBnomics, [`ilc_lvho07_r`: España](https://db.nomics.world/Eurostat/ilc_lvho07_r?q=Spain) y [Comunidad de Madrid (ES30)](https://db.nomics.world/Eurostat/ilc_lvho07_r?q=Madrid) · Eurostat, Nuts2json (geometrías NUTS 2021, repositorio `eurostat/Nuts2json` en GitHub)
- Comunidad de Madrid, [ECV: ingresos con registros administrativos desde 2013](https://web.comunidad.madrid/iestadis/fijas/estructu/sociales/descarga/ecv16me.pdf)
- INE, [Decil de salarios del empleo principal (EPA) 2024](https://ine.es/dyngs/Prensa/dsEPA2024.htm)
- Seguridad Social, [solicitud de acceso a la MCVL](https://www.seg-social.es/descarga/es/120853)
- IMSERSO, [Pensiones y renta de las personas de 65 y más años (oct-2024)](https://imserso.es/documents/20123/0/pensiones_renta_personas_65a_202410.pdf/e8f79b1b-5e48-730e-3ab9-a602f4afcaad): tenencia en propiedad de los mayores de 65 (ECV 2023)
- Pensiones de jubilación por provincia (INSS), vía [El Español (abr-2026)](https://www.elespanol.com/sociedad/20260402/almeria-albacete-provincia-pension-baja-espana-euros-mensuales/1003744190352_0.amp.html) e [IEEX (oct-2026)](https://www.juntaex.es/documents/77055/46718143/PC_ND_2026_10.pdf/719c4825-03e5-4aed-fd37-67520a620b4f)
