# Especificación · el CIS por comunidad autónoma

*Borrador para la v1.2 (12-nov-2026), por decidir. Encargo: backlog, «Para la v1.2», «Microdatos del CIS por comunidad»; nota metodológica, §7.10 («Lo que no se usa»: los microdatos darían la cifra por comunidad y el contraste por comunidad sigue pendiente). Provisional, como todo el plan.*

**Estado: decidido (13-nov-2026), por hacer: las ocho preguntas del final, con la opción recomendada (decisión del autor).** Revisado el 13-nov-2026. La fuente cambia: en lugar de los microdatos del CIS, que piden un formulario, los microdatos armonizados de *Barómetro a barómetro*, publicados con licencia CC BY 4.0 y sin registro (apartado «Revisión del 13-nov-2026»). Lo que sigue a ese apartado queda como antecedente. Nada de esto está en el pipeline.

## Revisión del 13-nov-2026: los microdatos armonizados

*Barómetro a barómetro* (<https://gastiaso.github.io/barometros/>, repositorio `gastiaso/barometros`) publica los barómetros mensuales del CIS de enero de 2021 a octubre de 2026 armonizados en un solo fichero: `barometros_armonizados.parquet`, una fila por entrevista (64 barómetros, 264.081 entrevistas, unos 19 MB), con `metadatos.json` (rupturas, fechas de campo y efecto de diseño de cada estudio). Licencia CC BY 4.0 para la armonización; los datos de origen, con las condiciones del CIS. Se descarga sin formulario desde su sitio y en ediciones fechadas (release `vAAAA-MM`; la primera, `v2026-10`). Eso resuelve la pregunta del formulario para 2021 en adelante.

**Lo que trae** (leído de la edición `v2026-10` el 13-nov-2026): `estudio`, `mes`, `peso` (el peso del CIS), `peso_ccaa` (`PESOCCAA`), `ccaa` (las 19 comunidades y ciudades autónomas), `provincia`, `prob_esp_1` a `prob_esp_3` y `prob_per_1` a `prob_per_3` (códigos armonizados; «La vivienda» es `PROB_007`; «ocupación de viviendas», `PROB_081`, va aparte y no se suma), además de sexo, edad, estudios y el resto de variables de perfil. `peso_ccaa` está en los 64 barómetros.

**Método de la herramienta**, el mismo que se propone aquí: porcentaje de entrevistados que citan `PROB_007` entre sus hasta tres menciones, con `peso`; base, quien tiene una primera mención distinta de «no procede» (NS y NC cuentan en la base); margen al 95 % con el intervalo de Wilson sobre el tamaño efectivo (efecto de diseño de Kish en cada base); ningún dato con menos de 50 entrevistas; las rupturas de tipo C se marcan y no se calculan variaciones a través de ellas (R10, noviembre de 2023: ponderación con ajuste por nivel educativo, que lleva el efecto de diseño de 1,1 a 2).

**Contraste con la serie nacional del atlas.** Con `peso`, la media anual de España calculada desde el Parquet coincide con la media de las cifras mensuales publicadas que ya tiene `cis_vivienda`: 1,6 % en 2021 y 32,3 % en 2025 (once barómetros cada año).

**`peso` y no `peso_ccaa`.** Antes de R10 dan lo mismo dentro de cada comunidad (comprobado en 2021: diferencias de una décima, salvo Melilla, con 89 entrevistas). Desde R10, `peso_ccaa` da entre 0,2 y 6,7 puntos más en todas las comunidades (2025: Andalucía, 32,3 frente a 28,5; Illes Balears, 47,4 frente a 41,0), y su suma no reproduce la cifra nacional publicada. `peso` es el que usan las tabulaciones del CIS y la herramienta.

**Muestra por comunidad, 2025** (problema de España; entrevistas en la base, porcentaje y efecto de diseño):

| Comunidad | Entrevistas | % | Efecto de diseño |
|---|---|---|---|
| Andalucía | 7.630 | 28,5 | 2,1 |
| Madrid | 6.187 | 39,2 | 1,9 |
| Cataluña | 6.184 | 35,3 | 2,0 |
| Comunitat Valenciana | 4.368 | 32,9 | 2,1 |
| Illes Balears | 1.151 | 41,0 | 2,5 |
| País Vasco | 1.981 | 39,0 | 2,0 |
| La Rioja | 1.025 | 25,0 | 2,1 |
| Ceuta | 192 | 30,8 | 2,4 |
| Melilla | 198 | 25,6 | 1,9 |
| España | 44.336 | 32,3 | 2,1 |

Con unas mil entrevistas al año y un efecto de diseño de 2, el margen de las comunidades pequeñas ronda ±4 puntos; el de Ceuta y Melilla, ±9 (unos ±7 si se agrupan dos años).

**Lo que no cubre:** de 2014 a 2020 (la serie nacional empieza en 2014). Para esos años seguirían haciendo falta los microdatos del CIS, con su formulario. El Barómetro de Vivienda 2026 (estudio 3532) solo tiene avance, sin microdatos.

**Encaje que cambia respecto a lo de abajo:** la descarga es automática (`descargar_con_cache()` de la edición fechada, con su SHA-256), no manual; la fuente nueva va en `inventario/fuentes.csv` y en el calendario (una edición por barómetro); la compuerta `cis_ccaa_espana` (bloqueo) compara cada mes de España calculado desde el Parquet con la cifra publicada de `cis_vivienda`, a ±0,1 puntos, y `cis_ccaa_suma`, que las comunidades ponderadas den España.

## Lo que ya hay

- **Serie nacional** (F6, tarea 31): «La vivienda» entre los tres principales problemas de España y entre los tres que más afectan personalmente, mensual, de enero de 2014 a octubre de 2026 (134 barómetros; 55,7 % en octubre de 2026, el máximo). `R/fuente_cis_barometros.R` (`cis_descargar_estudios()`, `cis_leer_barometros()`, `cis_serie_vivienda()`), objetivos `cis_estudios`, `cis_barometros`, `cis_vivienda`, `ficheros_web_cis`; tabla propia, fuera de la tabla larga; `web/datos/cis_vivienda.json` y el bloque «La vivienda como problema (CIS)» de `historico.html`.
- **Inventario:** `inventario/fuentes.csv` (`cis_barometros`), `inventario/calendario_fuentes.csv` (mensual, sin agosto) e `inventario/cis_transcripcion_pdf.csv` (seis meses solo en PDF, con su SHA-256).
- **Compuertas:** `cis_vivienda_publicada`, `cis_vivienda_suma`, `cis_vivienda_rango`, `cis_vivienda_pdf`, `cis_vivienda_web` (bloqueo); `cis_vivienda_categoria`, `cis_vivienda_cobertura`, `cis_vivienda_meses` (alerta).
- **Lo que se descartó** (§7.10 y la cabecera del código): el catálogo de series (protegido frente a accesos automatizados), los datos de las fichas de serie (ruta excluida por `robots.txt`) y los microdatos, que piden un formulario.
- **Las tabulaciones abiertas no cruzan por comunidad.** El XLSX de «Resultados y cruces verticales» de octubre de 2026 (estudio 3582, ya en `datos/brutos/cis_barometros/resultados/`) trae cruces por sexo, edad, estudios, tamaño de municipio, recuerdo de voto, ocupación, clase social, ideología y religiosidad; la comunidad solo aparece en la ficha técnica. La cifra por comunidad exige los microdatos.

## Qué ofrece el CIS

| Qué | Cómo se obtiene | Condiciones |
|---|---|---|
| **Fichero de datos de cada estudio** (`MDxxxx.zip`; el de octubre de 2026, 2,91 MB, enlazado desde el JSON-LD de su página: `https://www.cis.es/documents/20117/14396821/MD3582.zip`) | **Formulario previo a cada descarga** («para descargar los ficheros de datos del CIS, previamente debe cumplimentar un formulario»; preguntas frecuentes del CIS, https://www.cis.es/en/studies/frequently-asked-questions/instructions-data-files). La comprobación del 10-nov-2026 vio un formulario con correo y aceptación de condiciones. Un estudio cada vez: no hay descarga masiva | Reutilización libre, también comercial y de los datos «en bruto», según la Ley 37/2007 (condiciones de reutilización del CIS, https://www.cis.es/en/conditions-reusing-cis-data): citar «Fuente de los datos: Centro de Investigaciones Sociológicas», la fecha de la última actualización si la hay, no desnaturalizar y no sugerir que el CIS participa o patrocina. El JSON-LD de cada estudio declara CC BY 4.0 |
| Contenido del zip | Cuestionario, ficha técnica, libro de códigos, datos en ASCII de ancho fijo (`DAxxxx`), sintaxis de SPSS; `.sav` desde 2018; CSV con etiquetas (`xxxx_etiq.csv`) y numérico (`xxxx_num.csv`) desde 2023 | — |
| Variables útiles | Comunidad autónoma (`CCAA` en el cuestionario de octubre de 2026), las tres menciones de cada pregunta de problemas («La vivienda», código 7 en ese cuestionario), `PESO` (muestra total) y `PESOCCAA` (estimación por comunidad) | El CIS anonimiza el entrevistador, la sección, el distrito y los municipios de 100.000 habitantes o menos que no son capital |
| **Fichero de Datos Integrados (FID)** | **Registro** (nombre, correo, contraseña y código de activación); se piden variables armonizadas de varios estudios de una colección en un solo fichero (SPSS o texto separado por tabuladores); el CIS aprueba la petición (en general, en 24 horas) y el enlace caduca | Las mismas. Por comprobar si las preguntas de problemas y la comunidad están entre las variables armonizadas |

### Barómetros que preguntan por la vivienda

- **Todos los mensuales**, con las dos preguntas de problemas, que incluyen «La vivienda» (distinta de «La ocupación de viviendas»). Son la base de la serie nacional y de esta propuesta.
- **Módulos propios de vivienda.** Según las palabras clave de las páginas en caché del pipeline («Vivienda y entorno»), junio de 2019 y octubre de 2026 (por comprobar en los cuestionarios: las palabras clave pueden faltar). El de octubre de 2026 (estudio 3582) pregunta por un caso de desahucio, por el conocimiento de los decretos de vivienda de 29-sep-2026, a favor o en contra de once medidas, qué administración tiene y cuál debería tener más competencias, y si priorizar «el derecho a la vivienda como un derecho constitucional» o «la vivienda como bien de mercado». Son preguntas de coyuntura, sin serie.
- **Barómetro de Vivienda 2026**, convenio entre el Ministerio de Vivienda y Agenda Urbana y el CIS de 17-jun-2026 (Resolución de 22-jul-2026, `BOE-A-2026-16808`): unas 6.000 entrevistas telefónicas en tres oleadas, cuotas por comunidad y «representación nacional y por comunidad y ciudad autónoma», con sobremuestra en municipios medianos y grandes. Explora la importancia de la vivienda, la demanda de propiedad o alquiler, la accesibilidad, las políticas públicas, la vivienda turística, la concentración de la propiedad y la inversión extranjera. Resultados antes del 30-nov-2026; los microdatos anonimizados irán al Banco de Datos del CIS y sus variables comunes, al FID. Según la prensa, es el tercer barómetro específico de vivienda del CIS (por verificar los anteriores).

## Tamaño de la muestra por comunidad

| Barómetro | Entrevistas | Afijación | Ponderación | Fuente |
|---|---|---|---|---|
| Enero de 2014 (estudio 3011) | 2.480, en el domicilio | Proporcional | «No procede» | Ficha técnica |
| Enero de 2023 (estudio 3390) | 3.961, telefónicas | No proporcional: mínimo de 100 por comunidad; 20 en Ceuta y en Melilla | `PESO` y `PESOCCAA` | Ficha técnica |
| Octubre de 2026 (estudio 3582) | 5.024, telefónicas | No proporcional: mínimo de 125 por comunidad; 20 en Ceuta y en Melilla | `PESO` y `PESOCCAA` | Ficha técnica |

Entre 2014 y 2023 cambian el modo de entrevista y la afijación; el año exacto del cambio, por comprobar en las fichas técnicas intermedias. Con la afijación proporcional de 2014, una comunidad con el 0,7 % de la población, como La Rioja, tendría unas 17 entrevistas al mes.

### Error esperado

Margen al 95,5 % (dos sigmas) de un porcentaje *p* con *n* entrevistas, en muestreo aleatorio simple: ±2 × √(*p*(1 − *p*) / *n*). Con *p* = 55,7 % (España, octubre de 2026) y las entrevistas realizadas de ese mes; el anual suma once barómetros con la misma muestra (sin agosto) y, en la última columna, un efecto de diseño de 1,3 por la ponderación (supuesto: el real sale de los pesos, con la fórmula de Kish, como en la mochila):

| Comunidad | Entrevistas (oct-2026) | Margen del mes (CIS, *p* = *q*) | Margen del mes (*p* = 55,7 %) | Entrevistas en un año | Margen anual | Margen anual con efecto de diseño |
|---|---|---|---|---|---|---|
| Andalucía | 833 | ±3,5 | ±3,4 | 9.163 | ±1,0 | ±1,2 |
| Cataluña | 760 | ±3,6 | ±3,6 | 8.360 | ±1,1 | ±1,2 |
| Madrid | 672 | ±3,9 | ±3,8 | 7.392 | ±1,2 | ±1,3 |
| Comunitat Valenciana | 510 | ±4,4 | ±4,4 | 5.610 | ±1,3 | ±1,5 |
| Galicia | 299 | ±5,8 | ±5,7 | 3.289 | ±1,7 | ±2,0 |
| Castilla y León | 242 | ±6,4 | ±6,4 | 2.662 | ±1,9 | ±2,2 |
| País Vasco | 237 | ±6,5 | ±6,5 | 2.607 | ±1,9 | ±2,2 |
| Canarias | 219 | ±6,8 | ±6,7 | 2.409 | ±2,0 | ±2,3 |
| Castilla-La Mancha | 207 | ±7,0 | ±6,9 | 2.277 | ±2,1 | ±2,4 |
| Murcia | 145 | ±8,3 | ±8,3 | 1.595 | ±2,5 | ±2,8 |
| Cantabria | 127 | ±8,9 | ±8,8 | 1.397 | ±2,7 | ±3,0 |
| Aragón | 126 | ±8,9 | ±8,9 | 1.386 | ±2,7 | ±3,0 |
| Asturias | 126 | ±8,9 | ±8,9 | 1.386 | ±2,7 | ±3,0 |
| Extremadura | 124 | ±9,0 | ±8,9 | 1.364 | ±2,7 | ±3,1 |
| Illes Balears | 123 | ±9,0 | ±9,0 | 1.353 | ±2,7 | ±3,1 |
| Navarra | 122 | ±9,1 | ±9,0 | 1.342 | ±2,7 | ±3,1 |
| La Rioja | 114 | ±9,4 | ±9,3 | 1.254 | ±2,8 | ±3,2 |
| Melilla | 20 | ±22,4 | ±22,2 | 220 | ±6,7 | ±7,6 |
| Ceuta | 18 | ±23,6 | ±23,4 | 198 | ±7,1 | ±8,1 |
| España | 5.024 | ±1,4 | ±1,4 | 55.264 | ±0,4 | — |

Lectura: un mes por comunidad no sirve fuera de las cuatro grandes (márgenes de ±6 a ±9 puntos y de ±22 en Ceuta y Melilla), cuando el cambio de un mes a otro en España es de pocos puntos. Un año agregado deja todas las comunidades por debajo de ±3,5 puntos, salvo Ceuta y Melilla. En los años de afijación proporcional, las comunidades pequeñas quedan muy por debajo de esas muestras.

## Método propuesto

### Indicador

Porcentaje de entrevistados de la comunidad que cita «La vivienda» en alguna de las tres menciones de la pregunta de problemas de España (y de la personal), con `PESOCCAA`, y su margen al 95 %. Es la misma definición que la serie nacional; con `PESO` y toda la muestra, el cálculo debe reproducir la cifra nacional publicada de cada mes.

### Alternativas

- **A · Mensual por comunidad.** Demasiado ruido fuera de las comunidades grandes (tabla de arriba). Descartada.
- **B · Media anual por comunidad**: la cifra de cada mes con `PESOCCAA` y la del año como media de los meses con barómetro, todos con el mismo peso; el margen, de las varianzas de cada mes. El año que va en curso, con los meses publicados y rotulado («enero a octubre»).
- **C · Media móvil de doce meses**, actualizada cada mes. Más reciente que B, más difícil de leer y con meses solapados.
- **D · Solo el Barómetro de Vivienda 2026**: una foto con unas 6.000 entrevistas y preguntas específicas, representativa por comunidad. Sin serie.
- **E · FID**: una petición con todas las muestras de un año, si las variables están armonizadas. Exige registro y una aprobación por petición, y no deja una descarga reproducible por el pipeline.

**Recomendación: B, desde el primer año con `PESOCCAA` y afijación mínima por comunidad** (a más tardar, 2023), con **Ceuta y Melilla agrupadas de dos en dos años** (`anio` = el último, como los cruces de varias olas de la ECV); D como complemento cuando se publique, si sus preguntas lo justifican; E, solo si el formulario de cada estudio resulta inviable.

### Lectura de los microdatos

- **Desde 2023, el CSV numérico** (`xxxx_num.csv`): se lee con lo que ya usa el pipeline, sin paquetes nuevos. Antes de 2023 haría falta el `.sav` (el paquete `haven`, que `renv.lock` no tiene) o el ASCII con las posiciones del libro de códigos.
- **Códigos de la categoría** «La vivienda» y de las comunidades: de las etiquetas de cada estudio (`xxxx_etiq.csv` o el libro de códigos), nunca fijados en el código; el inventario guarda el código de cada estudio y la compuerta comprueba su etiqueta.
- **Descarga manual** (guía, «Datos»: ficheros que la fuente no deja descargar de forma automática): el autor rellena el formulario y guarda cada zip en `datos/brutos/cis_microdatos/MDxxxx.zip`; el pipeline se detiene y dice qué estudio falta, su página y el nombre del fichero. Volumen: un zip de unos 3 MB al mes, unos 40 desde 2023 (unos 120 MB, fuera de git). Cada fichero lleva su tamaño y su SHA-256 en un inventario nuevo, `inventario/cis_microdatos.csv` (estudio, mes, fichero, tamaño, suma, fecha de descarga, código de «La vivienda»), como `cis_transcripcion_pdf.csv`.

## Encaje

### Tabla larga

**No entra**, como la serie nacional (§7.10): es opinión, no registro, y la tabla larga es por sección. Tabla propia, `cis_vivienda_ccaa` (comunidad, año, pregunta, cifra, margen, entrevistas, meses, estado), con su CSV en las descargas. Alternativa: indicador auxiliar en la tabla larga a nivel de comunidad, con `estado` `estimado` (pregunta 5).

### Fuente y calendario

- `inventario/fuentes.csv`: `cis_microdatos` (CIS; https://www.cis.es, página de cada barómetro; acceso: descarga manual con formulario; condiciones: las de arriba; mensual; comunidad autónoma; desde 2023).
- `inventario/calendario_fuentes.csv`: misma cadencia que `cis_barometros` (el fichero de datos llega unos días después de los resultados: el de octubre de 2026, el 22-oct, dos días después). Objetivo `fichero_cis_microdatos`, `renovar` manual.

### Web

- **«Máquina del tiempo»** (`historico.html`, bloque del CIS): bajo el gráfico nacional, «Por comunidad autónoma», con el último año completo: una fila por comunidad con la cifra, el intervalo como barra horizontal y las entrevistas, ordenadas, con España como referencia. Sin mapa de coropletas: con márgenes de ±2 a ±3 puntos, las comunidades vecinas en el orden no se distinguen, y un mapa lo ocultaría. Un selector de año para los anteriores.
- **Ficha de comunidad del mapa** (opcional, pregunta 6): una línea, «La vivienda, entre los tres principales problemas de España: {cifra} % ({año}, enero a octubre; ±{margen} puntos; CIS)».
- **Textos:** advertencia «opinión, no registro», la fuente con la cita del CIS y su licencia, y el margen explicado en una frase; `web/i18n/es.json` y `en.json`; nota metodológica §7.10 en los dos idiomas.

### Compuertas (`inventario/referencias_validacion.csv`)

| Id | Tipo | Comprueba |
|---|---|---|
| `cis_ccaa_espana` | bloqueo | Con `PESO` y toda la muestra, cada mes reproduce la cifra nacional de la tabla `cis_vivienda` (±0,1 puntos), las dos preguntas |
| `cis_ccaa_muestra` | bloqueo | Entrevistas por comunidad = las «realizadas» de la ficha técnica de cada estudio |
| `cis_ccaa_codigos` | bloqueo | En cada estudio, el código guardado en el inventario tiene la etiqueta «La vivienda» y las comunidades son las 19 |
| `cis_ccaa_fichero` | bloqueo | Tamaño y SHA-256 de cada zip = los del inventario |
| `cis_ccaa_pesos` | bloqueo | `PESOCCAA` presente y positivo; la media de `PESO` por comunidad, la de la tabla de ponderaciones de la ficha técnica |
| `cis_ccaa_margen` | alerta | Comunidades y años con margen de más de ±5 puntos (Ceuta y Melilla sin agrupar) |
| `cis_ccaa_meses` | alerta | Años con menos de nueve barómetros con microdatos |
| `web_cis_ccaa` | bloqueo | Ida y vuelta del JSON de la web |

### Pruebas

- R: la cifra de un mes con un fichero inventado de 20 entrevistas y pesos conocidos; la media anual y su margen; el agrupado de Ceuta y Melilla; un estudio con otro código para «La vivienda».
- Web (node): la tabla por comunidad se ordena, pinta el intervalo y dice el año y los meses; sin el fichero, el bloque nacional sigue igual.

## Esfuerzo

**M**, si el autor acepta la descarga manual: lectura del CSV, tabla, compuertas y bloque de la web. Más el tiempo de la descarga, unos 40 formularios para 2023–2026 y uno al mes después. Ir antes de 2023 con el `.sav` o el ASCII y la afijación proporcional, **L**, para comunidades pequeñas con muestras que no aguantan.

## Preguntas para el autor

**Cerradas (13-nov-2026), decisión del autor: las ocho con la opción recomendada.** Además, el bloque del CIS de la «Máquina del tiempo» enlaza ya a la historia «Cómo la vivienda se convirtió en el primer problema de España» (<https://gastiaso.github.io/historias/vivienda/>) y a *Barómetro a barómetro* (<https://gastiaso.github.io/barometros/#vivienda>). Revisadas el 13-nov-2026, con la fuente nueva. Las del 12-nov-2026 (formulario, periodo, agregación, Ceuta y Melilla, dónde se guarda, dónde se ve y Barómetro de Vivienda) quedan absorbidas aquí.

1. **Fuente.** Los microdatos armonizados de *Barómetro a barómetro* (edición fechada, CC BY 4.0, citando la armonización y al CIS), desde 2021; de 2014 a 2020, fuera hasta que se decida bajar los del CIS con su formulario. Recomendada: **sí**.
2. **Peso.** `peso`, el de las tabulaciones del CIS, que reproduce la serie nacional publicada; no `peso_ccaa`. Recomendado: **`peso`**.
3. **Ruptura R10 (noviembre de 2023).** Tabla anual desde 2021 con 2023 marcado (mezcla los dos métodos) y sin variaciones a través de él. Recomendado: **sí**.
4. **Agregación.** Media anual de las entrevistas del año, con el año en curso rotulado «hasta {mes}». Recomendada: **sí**.
5. **Ceuta y Melilla.** Agrupadas de dos en dos años. Recomendado: **sí**.
6. **Problema personal.** Además del problema de España, la serie del problema que afecta personalmente, como en la serie nacional. Recomendado: **las dos**.
7. **Dónde se guarda y se ve.** Tabla propia (`cis_vivienda_ccaa`), fuera de la tabla larga; en la «Máquina del tiempo» y con una línea en la ficha de comunidad. Recomendado: **sí**.
8. **Barómetro de Vivienda 2026.** Esperar a sus microdatos; el avance no da cifras por comunidad. Recomendado: **esperar**.

## Hecho cuando

- La tabla `cis_vivienda_ccaa` trae las 19 comunidades por año desde 2021, con cifra, margen y entrevistas, y pasan las compuertas `cis_ccaa_*`.
- La «Máquina del tiempo» muestra la tabla por comunidad con sus intervalos, en castellano e inglés, y la nota (§7.10) explica el cálculo y los márgenes.
- El Parquet se descarga solo, de una edición fechada, y la compuerta `cis_ccaa_espana` reproduce la serie nacional publicada mes a mes.
