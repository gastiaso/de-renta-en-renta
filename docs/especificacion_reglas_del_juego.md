# Especificación · pestaña «Reglas del juego»

*Borrador para la v1.2 (12-nov-2026), por decidir. Encargo: backlog, «Para la v1.2», «Pestaña "Reglas del juego", con resúmenes de las leyes vigentes»; hasta entonces, la casilla 7 de la portada, «Ley de Vivienda», va sin enlace («próximamente»; decisión del autor, 12-nov-2026; `docs/especificacion_portada.md`). Provisional, como todo el plan.*

**Estado: decidido (13-nov-2026), por hacer.** Preguntas del final cerradas por el autor; la revisión jurídica de cada resumen la hace él. Nada de esto está en el pipeline ni en la web. Los textos legales se consultaron en el BOE consolidado el 12-nov-2026, sin descargar ficheros.

## Por qué

- La portada nombra reglas (fianza, zona tensionada, tope de alquileres, renovación, actualización de la renta, aval) y su especificación exige que no contradiga la ley (`docs/especificacion_portada.md`, «Exactitud de las etiquetas»). Hoy ese control es manual.
- El indicador 20 (zonas tensionadas) pinta qué municipios tienen una declaración, pero no qué supone. La ficha del municipio dice que es «una capa de política pública, no una medida del mercado» y no tiene adónde enlazar.
- **Las reglas cambian deprisa.** A 12-nov-2026, la Ley de Arrendamientos Urbanos (LAU) tiene cuatro versiones desde el 30-sep-2026: los Reales Decretos-leyes 26/2026 y 27/2026, de 29 de septiembre, quedaron derogados por el Congreso (resoluciones de 2-oct-2026, `BOE-A-2026-20526` y `BOE-A-2026-20527`); el 29/2026, de 6 de octubre (`BOE-A-2026-20823`), modifica los artículos 10, 17, 18, 20 y 36 de la LAU con efectos desde el 8-oct-2026, y el 28/2026, de 6 de octubre (`BOE-A-2026-20822`), sustituiría el artículo 10 desde el 15-nov-2026. Según la prensa del 12-nov-2026, la Diputación Permanente convalidó el 29/2026 y no el 28/2026; el BOE aún no lo publica. Antes, el Real Decreto-ley 8/2026, de 20 de marzo, de medidas en el alquiler, fue derogado (`BOE-A-2026-9359`). Un resumen sin fecha de consulta y sin comprobación automática queda viejo en semanas.

## Objetivo

Una página, «Reglas del juego» (*Rules of the game*), con resúmenes breves de las normas estatales que fijan las condiciones del alquiler y la compra de vivienda habitual, cada uno con su norma y artículo enlazados al BOE consolidado, la fecha del texto consultado y su relación con los indicadores del atlas. Registro impersonal, sin valoraciones ni recomendaciones (guía, «Forma de trabajo»), y sin carácter de asesoramiento: el texto oficial es el del BOE.

## Fuentes

| Fuente | URL | Condiciones | Ámbito | Años |
|---|---|---|---|---|
| BOE, legislación consolidada (página de cada norma) | https://www.boe.es/buscar/act.php?id=BOE-A-1994-26003 (LAU), https://www.boe.es/buscar/act.php?id=BOE-A-2023-12203 (Ley 12/2023) | Reutilización libre, también comercial (aviso legal del BOE, https://www.boe.es/informacion/aviso_legal/index.php#reutilizacion): citar la fuente con enlace («Basado en datos de la Agencia Estatal Boletín Oficial del Estado» en obras derivadas), no desnaturalizar, indicar la fecha de la última actualización, no sugerir respaldo y **advertir que un texto consolidado es meramente informativo**; solo la edición electrónica del BOE es oficial | Estatal | Texto vigente y versiones anteriores |
| BOE, API de legislación consolidada | `https://boe.es/datosabiertos/api/legislacion-consolidada/id/{id}` y `/metadatos`, `/analisis`, `/texto/indice`, `/texto/bloque/{id_bloque}`, con la cabecera `Accept: application/xml` o `application/json` (documentación: https://www.boe.es/datosabiertos/documentos/APIconsolidada.pdf). Los metadatos traen `fecha_actualizacion` (ISO 8601, UTC) y `url_html_consolidada` | Las mismas | Estatal y autonómica (las normas autonómicas que el BOE consolida) | — |
| BOE, diario (resoluciones del Congreso de convalidación o derogación; resoluciones trimestrales de zonas tensionadas) | https://www.boe.es/diario_boe/ | Las mismas | Estatal | — |
| INE, índice de referencia para la actualización anual de los contratos de arrendamiento de vivienda (IRAV) | Metodología: https://ine.es/daco/daco42/irav/meto_IRAV.pdf | Reutilización libre citando al INE | Nacional, mensual | Desde diciembre de 2024 (por verificar el primer dato) |
| MIVAU, sistema estatal de índices de precios de referencia del alquiler | Resolución de 14 de marzo de 2024 (`BOE-A-2024-5213`); actualizaciones en `BOE-A-2025-7279` y `BOE-A-2026-8691` | Las del BOE; el índice sale del SERPAVI, la misma fuente que los indicadores 8 y 9 | Por vivienda (catastral) | Desde el 16-mar-2024 |
| Comunidades autónomas: declaraciones de zonas tensionadas y normas propias | Enlaces de `inventario/zonas_tensionadas.csv` (`url_declaracion`) y boletines autonómicos | Las de cada boletín (por revisar una a una) | Autonómico | — |

## Lista de normas propuesta

Primera tanda (v1.2), estatal, una ficha por tema y no por norma: lo que interesa al lector es «la fianza», no «el artículo 36».

| Id | Tema | Normas y artículos | Casilla de la portada | En el atlas |
|---|---|---|---|---|
| `ley_vivienda` | La Ley por el derecho a la vivienda | Constitución, art. 47; Ley 12/2023, de 24 de mayo (`BOE-A-2023-12203`): objeto, definiciones (art. 3: vivienda asequible incentivada, esfuerzo financiero del 30 % con suministros, gran tenedor), parques públicos de vivienda e información (artículos por localizar); sentencias del Tribunal Constitucional sobre la ley (entre ellas, la STC 79/2024, que anula su disposición transitoria primera) | 7, «Ley de Vivienda» (esquina) | Umbral del 30 % (15 y 21); nota, §7.4 |
| `zonas_tensionadas` | Zonas de mercado residencial tensionado | Ley 12/2023, art. 18 (y arts. 3.k, 19 y 31.3); LAU, arts. 10.3, 17.6 y 17.7 y disposición transitoria séptima | 6, «Zona tensionada», y 8, «Tope de alquileres» | Indicador 20 (muestra abajo) |
| `indice_referencia` | El índice de precios de referencia | LAU, art. 17.7; Real Decreto-ley 7/2019, disposición adicional segunda; resoluciones del sistema estatal de índices | 8, «Tope de alquileres» | Alquiler del SERPAVI (8, 9): misma fuente, otro cálculo; las medianas del atlas no son el índice |
| `duracion_prorroga` | Duración, prórrogas y renovación | LAU, arts. 9 y 10 (prórroga obligatoria hasta cinco años, siete si el arrendador es persona jurídica; prórroga tácita; prórroga extraordinaria por vulnerabilidad, de hasta un año, obligatoria para el gran tenedor; prórroga en zona tensionada) | 9, «Renueva el contrato» | «¿Te llega?» con la llave (alquiler de contratos vigentes) |
| `actualizacion_renta` | Actualización anual de la renta | LAU, art. 18 y disposición adicional undécima (IRAV); límites temporales anteriores (Real Decreto-ley 6/2022 y Ley 12/2023, por verificar) | 10, «Actualización de la renta» (hoy sin enlace) | Variación del alquiler (10) |
| `fianza_garantias` | Fianza y garantías adicionales | LAU, art. 36: fianza de una mensualidad en vivienda; garantía adicional de hasta dos mensualidades (una en temporada) y, desde el Real Decreto-ley 29/2026, sin seguro de impago como garantía y con documento de estado de la vivienda al final del contrato (art. 36.7). Depósito de las fianzas: normas autonómicas | 3, «Fianza: un mes», y 17, «Aval de tus padres» | El alquiler del SERPAVI sale de las fianzas declaradas |
| `gastos_contrato` | Gastos del contrato | LAU, art. 20: gastos de gestión inmobiliaria y de formalización a cargo del arrendador (Ley 12/2023); gastos generales del inmueble y servicios individualizados | 22, «Comunidad y derramas» (hoy sin enlace) | Otros gastos de vivienda de «Tu sueldo» (§6.7) |

Segunda tanda (después de la v1.2, pregunta 2): `vulnerabilidad_desahucios` (Ley de Enjuiciamiento Civil, en la redacción de la Ley 12/2023; suspensiones del Real Decreto-ley 29/2026); `temporada_habitaciones` (LAU, art. 3; Registro Único de Arrendamientos, Real Decreto 1312/2024, por verificar; relación con el indicador 19); `fiscalidad_alquiler` (reducción del rendimiento del alquiler en el IRPF y deducciones de 2026); `autonomico`: para las cinco comunidades con zonas declaradas (Cataluña, Navarra, País Vasco, Asturias y Galicia), su norma de vivienda y el enlace a la declaración, que ya está en el inventario; depósito de fianzas por comunidad (organismo, norma y plazo), en un CSV por localizar.

## Esquema de cada resumen

| Campo | Contenido |
|---|---|
| `id`, `orden` | Ancla de la página (`reglas.html#zonas-tensionadas`) y orden |
| `titulo_es`, `titulo_en` | Tema, no nombre de norma |
| `que_dice_es`, `que_dice_en` | Tres a seis frases o viñetas: la regla, las cifras legales y las excepciones |
| `a_quien_es`, `a_quien_en` | Contratos y personas a los que se aplica, y desde cuándo (por ejemplo, contratos firmados desde el 26-may-2023) |
| `cambios_es`, `cambios_en` | Versiones con fecha de efecto y norma que las introduce; las derogadas o no convalidadas, como tales |
| `en_el_atlas_es`, `en_el_atlas_en` | Indicador, mapa o casilla relacionados, con enlace; las cifras, del pipeline (nunca escritas a mano) |
| `normas` | Identificadores del BOE y artículos (`BOE-A-1994-26003#a36`), separados por `;` |
| `estado` | `vigente`, `vigente_pendiente_convalidacion`, `con_efectos_futuros`, `derogada`, `anulada_tc` |
| `texto_consultado` | Fecha en que se leyó el texto consolidado, y `fecha_actualizacion` del BOE en ese momento, por norma |
| `revisado` | Fecha de la última revisión del resumen; `borrador` hasta que el autor, que hace la revisión jurídica, lo da por bueno |

Al pie de la página, fijo: «Resúmenes informativos, sin valor jurídico. El texto oficial es el publicado en el BOE. Basado en datos de la Agencia Estatal Boletín Oficial del Estado (www.boe.es), consultados el {fecha}. La AEBOE no participa en este atlas ni lo patrocina.»

## Método: dónde viven los textos

- **A · CSV → JSON → página** (como las historias y las casillas): `inventario/reglas.csv` con los campos de arriba; `exportar_web_reglas()` escribe `web/datos/reglas.json`; `web/reglas.html` y `web/js/reglas.js` lo pintan en los dos idiomas (`?idioma=en`). Cumple la regla 7, deja comprobar los textos con compuertas y reutiliza el contrato de las historias.
- **B · Markdown y pandoc** (como «Método»): `docs/reglas_del_juego.md` y `docs/rules_of_the_game.md`, convertidos en el flujo de publicación. Más cómodo para escribir; las compuertas tendrían que leer Markdown y la página no existe en local hasta publicar.
- **C · HTML escrito a mano.** Sin compuertas.

**Recomendación: A.** Los textos legales cambian por artículos sueltos y las comprobaciones (fechas, literales, enlaces) son por fila.

## Mantenimiento al día

- **Fuente nueva** `boe_legislacion` en `inventario/fuentes.csv`, y fila en `inventario/calendario_fuentes.csv`: cadencia «continua», revisión mensual y, además, con cada resolución trimestral de zonas tensionadas (`zonas_tensionadas`, meses 1, 4, 7 y 10).
- **Comprobación automática** (`reglas_comprobar_boe()`, objetivo `validacion_reglas`): por cada norma citada, los metadatos de la API (`fecha_actualizacion`, y si la norma consta derogada o con la vigencia agotada) frente a `texto_consultado`. Un XML pequeño por norma, con caché en `datos/brutos/boe_legislacion/`.
- **Literales** (`inventario/reglas_literales.csv`): cada cifra legal de un resumen y de una casilla de la portada («Fianza: un mes»; «dos mensualidades»; «30 %»; «tres años») lleva una fila con la norma, el bloque del artículo (`/texto/bloque/{id_bloque}`, versión vigente) y el fragmento literal que la sostiene. La compuerta comprueba que el fragmento sigue en la versión vigente.
- **Decretos-leyes.** Entran en vigor cuando ellos mismos disponen (en general, al publicarse) y quedan derogados si el Congreso no los convalida en los 30 días siguientes a su promulgación (Constitución, art. 86.2). Un resumen que dependa de uno lleva el estado `vigente_pendiente_convalidacion` hasta que el BOE publique la convalidación o la derogación. Las versiones con efectos futuros (el Real Decreto-ley 28/2026, desde el 15-nov-2026) no se resumen como vigentes: van en «cambios», con su fecha.
- **Procedimiento** (en `docs/actualizacion.md`): con la alerta, releer el artículo en el BOE, rehacer el resumen, actualizar `texto_consultado` y `revisado`, y anotar el cambio en `CHANGELOG.md`.

### Compuertas (`inventario/referencias_validacion.csv`)

| Id | Tipo | Comprueba |
|---|---|---|
| `reglas_al_dia` | alerta | Normas con `fecha_actualizacion` del BOE posterior a `texto_consultado` |
| `reglas_vigencia` | bloqueo | Un resumen `vigente` cuya norma consta derogada o con la vigencia agotada, o un decreto-ley `vigente_pendiente_convalidacion` fuera del plazo de convalidación (30 días desde su promulgación, Constitución, art. 86.2; el cómputo, por verificar) sin resolución del Congreso en el inventario |
| `reglas_literal` | bloqueo | Cada fragmento de `reglas_literales.csv` está en la versión vigente de su bloque; también los de las casillas de la portada |
| `reglas_completo` | bloqueo | Cada fila con sus campos en los dos idiomas, normas con identificador del BOE válido, anclas únicas, `revisado` distinto de `borrador` para publicar |
| `reglas_enlaces` | bloqueo | Las casillas de la portada y la ficha del 20 enlazan a anclas que existen; los indicadores citados existen en `inventario/indicadores.csv` |
| `web_reglas` | bloqueo | Ida y vuelta de `reglas.json` |

## Relación con el indicador 20

- **Misma materia, dos piezas.** `inventario/zonas_tensionadas.csv` (resoluciones trimestrales del Ministerio) alimenta el mapa del 20; `reglas.csv` dice qué supone una declaración. Las resoluciones nuevas llegan por el mismo calendario: la revisión de `zonas_tensionadas` incluye la de esta ficha.
- **Enlaces.** La ficha del municipio del 20 añade «Qué supone la declaración» → `reglas.html#zonas-tensionadas`; el resumen enlaza al mapa (`mapa.html?mapa=zona_tensionada`) y a la declaración de cada comunidad.
- **Cifras.** Si el resumen da cuántos municipios tienen declaración, sale de la tabla larga del 20 (situación a 31 de diciembre), como el resto de la web; los criterios legales (30 %, tres puntos sobre el IPC, tres años) salen de `reglas_literales.csv`.
- **Prórrogas** de las declaraciones (art. 18.2.d, por plazos anuales): el inventario ya las prevé (`prorroga_de`); la ficha de reglas las explica.
- **El 20 no mide los criterios.** La declaración se apoya en la memoria de cada comunidad, con sus datos. El atlas no comprueba si un municipio cumple el 30 % o los tres puntos: el 21 usa otro umbral (sin suministros, el alquiler de una sección, otra renta), y la ficha lo dice.

## Web

- Página `web/reglas.html` (un solo fichero con `?idioma=en`, como el mapa), con índice, una sección por resumen, el estado de cada uno (por ejemplo, «Texto en vigor desde el 8-oct-2026; decreto-ley pendiente de convalidación») y el pie de arriba.
- Menú de todas las páginas, entre «Sobrecarga» y «Datos»: «Reglas del juego» / «Rules of the game» (también en `web/herramientas/plantilla_documento.html`).
- Portada (`inventario/casillas_portada.csv`): la casilla 7 pasa a activa con destino `reglas.html`; las 10 y 22, de «próximamente» a sus anclas; la 17, a `reglas.html#fianza-garantias`; la 3 y la 8, a decidir (pregunta 4). La compuerta `portada_casillas` ya exige que ningún enlace lleve a una página vacía.
- Inglés: el nombre oficial de cada norma en castellano, con una glosa («Ley 12/2023, por el derecho a la vivienda — Housing Act»).

## Muestra de resumen

> **Borrador, por revisar.** Texto consultado en el BOE consolidado el 12-nov-2026: Ley 12/2023, actualización del 7-oct-2026; LAU, versión en vigor desde el 8-oct-2026. Sin revisión jurídica.

**Zonas de mercado residencial tensionado**

*Qué dice.*
- La administración competente en materia de vivienda puede declarar zonas de mercado residencial tensionado donde exista un especial riesgo de oferta insuficiente de vivienda para la población (Ley 12/2023, art. 18.1).
- La declaración exige una memoria con datos objetivos que acredite al menos una de dos circunstancias: que la carga media del coste de la hipoteca o del alquiler, más los gastos y suministros básicos, supere el 30 % de los ingresos medios de los hogares, o que el precio de compra o de alquiler haya crecido en los cinco años anteriores al menos tres puntos por encima del IPC de la comunidad autónoma (art. 18.3).
- La declaración dura tres años y puede prorrogarse por periodos anuales si se mantienen las circunstancias. El Ministerio de Vivienda y Agenda Urbana publica cada trimestre en el BOE una resolución con la relación de zonas declaradas (art. 18.2.d). La administración que declara elabora un plan específico con medidas correctoras y su calendario (art. 18.4).

*Efectos en los alquileres de vivienda habitual (LAU).*
- **Prórroga extraordinaria:** al terminar la prórroga obligatoria o la tácita, el inquilino puede pedir prórrogas anuales hasta un máximo de tres años, mientras siga en vigor la declaración. El arrendador está obligado a aceptarlas, salvo que se pacten otras condiciones, se firme un contrato nuevo con los límites de renta del art. 17 o el arrendador haya comunicado en plazo que necesita la vivienda (art. 10.3).
- **Renta de un contrato nuevo:** no puede superar la del último contrato de esa vivienda en vigor en los cinco años anteriores, con la actualización que ese contrato preveía. Se admiten subidas de hasta el 10 % en supuestos tasados, como obras recientes de rehabilitación, de ahorro de energía o de accesibilidad, o un contrato de diez años o más (art. 17.6).
- **Grandes tenedores:** si el arrendador es un gran tenedor (más de diez inmuebles urbanos de uso residencial o más de 1.500 m² de uso residencial, sin garajes ni trasteros; la comunidad puede bajar el umbral a cinco inmuebles en la zona declarada; Ley 12/2023, art. 3.k), la renta del contrato nuevo no puede superar el límite del sistema estatal de índices de precios de referencia (art. 17.7; Resolución de 14 de marzo de 2024). Se aplica a los contratos firmados tras la entrada en vigor de la Ley 12/2023 y la aprobación del sistema de índices (disposición transitoria séptima).

*A quién y desde cuándo.* A los contratos de vivienda habitual de las viviendas situadas en una zona con declaración en vigor. Las primeras declaraciones publicadas por el Ministerio son de marzo de 2024 (`BOE-A-2024-5214`).

*Cambios.* Ley 12/2023 (en vigor desde el 26-may-2023): crea la figura y añade a la LAU los arts. 10.3, 17.6 y 17.7. Real Decreto-ley 29/2026 (en vigor desde el 8-oct-2026): modifica los arts. 10 y 17.6 y 17.7 y añade los apartados 8 y 9 del art. 17 (por resumir). Los Reales Decretos-leyes 26/2026 y 27/2026 fueron derogados por el Congreso el 2-oct-2026. El Real Decreto-ley 28/2026 sustituiría el art. 10 desde el 15-nov-2026.

*En el atlas.* Indicador 20, mapa municipal de las declaraciones en vigor a 31 de diciembre de cada año desde 2024 (`mapa.html?mapa=zona_tensionada`); la ficha de cada municipio lista sus declaraciones, con la resolución del BOE y la declaración de la comunidad. El atlas no comprueba los criterios del art. 18.3.

*Normas.* Ley 12/2023, de 24 de mayo, por el derecho a la vivienda, arts. 3 y 18 (https://www.boe.es/buscar/act.php?id=BOE-A-2023-12203); Ley 29/1994, de 24 de noviembre, de Arrendamientos Urbanos, arts. 10 y 17 y disposición transitoria séptima (https://www.boe.es/buscar/act.php?id=BOE-A-1994-26003).

> **Por revisar antes de publicar:** el texto de los arts. 10 y 17 en la versión del Real Decreto-ley 29/2026 (este borrador sigue la lectura del 12-nov-2026); la publicación en el BOE del resultado de la votación del 12-nov-2026 sobre los Reales Decretos-leyes 28/2026 y 29/2026 (según la prensa, el 29/2026 convalidado y el 28/2026 derogado), y la denominación vigente del Ministerio en el art. 18.2.d.

## Pruebas

- R: `reglas_comprobar_boe()` con metadatos inventados (al día, actualizada, derogada); `reglas_literal` con un fragmento que está y otro que no; un decreto-ley pendiente fuera de plazo.
- Web (node): la página carga `reglas.json`, pinta el estado y el pie, las anclas existen, el inglés trae los mismos ids; las casillas activas de la portada llevan a anclas existentes.

## Esfuerzo

**M** para la infraestructura (CSV, exportación, página, menú, casillas, compuertas y API del BOE). **M** para los siete resúmenes de la primera tanda en dos idiomas, más el tiempo de revisión del autor. La segunda tanda, sobre todo la autonómica, **L**.

## Preguntas para el autor

**Cerradas (13-nov-2026), decisión del autor.** De la 1 a la 5, con la opción recomendada: CSV → JSON → página; los siete temas estatales y lo autonómico como enlaces; el texto en vigor con su estado; las casillas 7, 10, 17 y 22 activas, y la 3 y la 8 sin cambios, con enlace a la regla desde su destino; `reglas_literal` de bloqueo también para las casillas. 6: la revisión jurídica la hace el autor; `revisado` queda en `borrador` hasta que él da cada resumen por bueno. 7: «Reglas del juego» en el menú y en la página, con el subtítulo «Normativa vigente».

1. **Formato.** CSV → JSON → página (A), Markdown con pandoc (B) o HTML a mano (C). Recomendada: **A**.
2. **Alcance de la v1.2.** Los siete temas estatales de la tabla, con lo autonómico como enlaces a las declaraciones ya inventariadas. Recomendado: **sí**; desahucios, temporada, fiscalidad y depósito de fianzas, después.
3. **Decretos-leyes en el aire.** Resumir solo el texto en vigor del BOE consolidado, con el estado «pendiente de convalidación», o esperar a la convalidación. Recomendado: **el texto en vigor con su estado**; nunca las versiones con efectos futuros como vigentes.
4. **Casillas.** Activar la 7, la 10, la 17 y la 22 hacia sus anclas. La 3 («Fianza: un mes») y la 8 («Tope de alquileres») hoy van a la página «Método» y al mapa de la variación del alquiler: ¿siguen ahí o pasan a la página de reglas? Recomendado: **3 y 8 sin cambios**, con un enlace a la regla desde su destino.
5. **Literales de la portada en la compuerta.** `reglas_literal` de bloqueo también para las casillas. Recomendado: **sí** (la portada no puede contradecir la ley).
6. **Revisión jurídica.** Una lectura por alguien con formación jurídica antes de publicar, como la lectura externa de la tarea 60. Recomendada: **sí**; sin ella, `revisado` queda en `borrador` y la compuerta impide publicar.
7. **Nombre.** «Reglas del juego» en el menú y en la página, con el subtítulo «Normas del alquiler y la compra de vivienda». Recomendado: **sí**.

## Hecho cuando

- La página muestra los resúmenes de la primera tanda en castellano e inglés, con sus normas enlazadas, su estado y la fecha del texto consultado.
- La casilla 7 de la portada, y las que se decidan, enlazan a sus anclas; la ficha del 20 enlaza a su resumen.
- Pasan las compuertas `reglas_*` y `web_reglas`, y `fuentes_pendientes` avisa cuando cambia una norma citada.
