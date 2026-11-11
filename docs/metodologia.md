# Nota metodológica

*De renta en renta · v0.1, borrador · 8 de noviembre de 2026 · conforme al plan v0.26.*

Esta nota describe cómo se obtienen las cifras del atlas: fuentes, geografía constante, jerarquía territorial y mapa base, compuerta de validación, indicadores de la v0.1 e ingresos de las fichas. La versión inglesa, `docs/methodology.md`, es una traducción fiel de esta.

## 0. Cómo se cita cada cifra

- **Trazabilidad.** Cada cifra lleva entre paréntesis su origen. Puede ser:
  - un objetivo del pipeline, que se lee con `targets::tar_read(<objetivo>)`;
  - una función de `R/`;
  - un fichero de `inventario/`;
  - una sección del plan (`docs/plan_integracion_atlas.md`, «plan §»).
- **Objetivos repetidos.** Los que terminan en `_<seccionado>` se repiten una vez por seccionado de origen, según `PASOS_2021` en `_targets.R`. Por ejemplo, `paso_final_2016` lleva el ADRH 2015.
- **Almacén de referencia.** Las cifras sin otra indicación salen del almacén de `targets` del 8-nov-2026, con toda España, tras la pasada completa que acabó a las 22:25: `tabla_larga` es de las 21:13, ya con las comunidades y las provincias de los indicadores 18 y 19; el mapa base, de las 22:12; los datos de la web, de las 22:14, y la sección de sobrecarga de la web, de las 21:04.
- **Decisiones.** Las preguntas abiertas que el plan ya ha cerrado se citan como «plan §11, pregunta *n*».
- **Pendiente.** Así se marca lo que el pipeline no calcula todavía.
- **Formato.** Las cifras usan punto de miles y coma decimal. El redondeo a un decimal se hace con `redondear_1()`, que usa `sprintf("%.1f")`: `round()` redondea al par en los empates.

---

## 1. Pregunta rectora y alcance

**Pregunta.** ¿A quién le queda sueldo después de pagar la vivienda? Dónde, desde cuándo y para quién ha cambiado la relación entre lo que cuesta la vivienda y lo que se cobra (plan §1). Para quien ya está en el tablero y para quien entra nuevo en la partida: la primera familia de indicadores mide a quien ya vive de alquiler (el parque alquilado) y la segunda, a quien busca piso hoy (la oferta y los contratos nuevos). No se mezclan en una misma cifra.

**Público.** Principal: periodistas de datos y técnicos de administraciones y entidades. Secundario: capa ciudadana.

**Escala y periodo.** Sección censal, de 2015 al último dato disponible. Todas las series se dibujan en el seccionado del Censo 2021 (§3).

**Dos familias de indicadores de alquiler** (plan §1; columna `familia_alquiler` de `inventario/indicadores.csv`):
- **Quedarse** (quien ya vive de alquiler): el parque alquilado, con los contratos vigentes que declara el SERPAVI. Dentro de ella, el alquiler mediano sobre la renta media del barrio (indicador 14: renta de todos los hogares de la sección frente al alquiler de esa sección; solo en la ficha, con su aviso de lectura) y el peso del alquiler en el ingreso (alquiler de la sección frente al ingreso de una ficha, §6).
- **Entrar** (quien busca piso hoy): la oferta de los portales y el índice del INE con contratos nuevos. Se incorpora antes de la v1.0; hasta entonces, el atlas solo mide la primera familia. El índice de contratos nuevos ya está en la tabla larga (indicador 10, corte `contrato`; §7.7), sin mapa. La brecha entre la oferta y el parque, el sueldo para entrar y la barrera para entrar se calculan con la capa de portales encendida y llegan a la web solo por tramos (§7.8).

Las cifras del SERPAVI miden a quien ya vive de alquiler, no lo que cuesta entrar. El peso del alquiler en el ingreso corrige un sesgo del esfuerzo: los barrios caros parecen asequibles porque los habita población con más renta.

**Escalonado** (plan §2.3):

| Versión | Contenido | Estado del cálculo (8-nov-2026) |
|---|---|---|
| v0.0 | Indicadores 22 (sobrecarga por gastos de vivienda, método Eurostat) y 23 (búsqueda de vivienda sin éxito) | En la tabla larga: 261 y 32 filas (`tabla_larga`, fuentes `ine_ecv` e `ine_ecv_modulo`) |
| v0.1 | Núcleo de 10 indicadores: 1–3, 8, 9, 14, 15, 18, 19 y 21 | Los 10, en la tabla larga; el peso del alquiler en el ingreso (15), solo con la mochila y la tartera de 2024 (§7.4) |
| v1.0 | Los 23 indicadores del catálogo (plan §5) | — |

**Núcleo de la v0.1** (`inventario/indicadores.csv`, columna `nucleo_v01`):

| # | Indicador | Fuente | Nivel nativo | Serie | Estado |
|---|---|---|---|---|---|
| 1 | Renta neta media por persona | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 2 | Renta neta media por hogar | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 3 | Mediana de la renta por unidad de consumo | INE, ADRH | Sección | 2015–2024 | Calculado (`larga_adrh`) |
| 8 | Alquiler mensual (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Calculado (`larga_serpavi`) |
| 9 | Alquiler por m² (mediana) | MIVAU, SERPAVI | Sección (seccionado de 2021) | 2015–2024 | Calculado (`larga_serpavi`) |
| 14 | Alquiler mediano sobre renta media del barrio (solo en la ficha) | SERPAVI y ADRH | Sección | 2015–2024 | Calculado (`larga_derivados`) |
| 15 | Peso del alquiler en el ingreso | SERPAVI e ingreso de cada ficha | Sección × ingreso | 2015–2024 | Control en `larga_derivados` (tartera, mochila y transistor, 2015–2024); la web la calcula con cada ficha |
| 18 | Hogares en alquiler | INE, Censo 2021 | Sección (seccionado de 2021) | 2021 (2011, en F6) | Calculado (`larga_censo2021`) |
| 19 | Viviendas de uso turístico | INE, estadística experimental | Sección (seccionado de 2024, llevado al de 2021) | Febrero de 2024 – mayo de 2026, semestral (2020–2023, en F6) | Calculado (`larga_vut`) |
| 21 | Sueldo neto necesario (mapa por defecto; con el alquiler mensual real y, al lado, el mínimo de 50 m²) | SERPAVI | Sección | 2015–2024 | Calculado (`larga_derivados`) |

**Tipología del alquiler** (plan §11, pregunta 12). El SERPAVI no publica una mediana conjunta de la vivienda colectiva y la unifamiliar. El mapa de alquiler usa por defecto la vivienda colectiva, que reúne el 88,9 % de los testigos en 2024: 2.271.987 frente a 284.591 (`serpavi`, hoja de comunidades). La unifamiliar es una opción, y las dos no se mezclan en un mismo mapa. Los derivados (14, 15 y 21) se calculan con la colectiva.

**Indicador 7.** Salario medio anual por asalariado de la AEAT, en total y de 26 a 35 años, por provincia, comunidad y España, de 2011 a 2024, en la tabla larga (`larga_salarios`, §5.6). Es el punto de partida de la ficha «mochila», que tiene serie de 2015 a 2024 (`mochila_neta`, §6.2).

**Desfase.** El atlas va uno o dos años por detrás en renta y salarios. El ADRH tiene un desfase de unos 22 meses: el de 2024 se publicó el 19-oct-2026. *Mercado de trabajo y pensiones* de la AEAT tiene uno de unos 11 meses (plan §8).

---

## 2. Fuentes y licencias

### 2.1 Fuentes que usa la v0.1

El inventario completo, con dirección, acceso, cadencia y notas, está en `inventario/fuentes.csv`. La columna `licencia` cita el texto de cada fuente.

| Fuente (`id`) | Organismo | Uso | Licencia (resumen de `fuentes.csv`) |
|---|---|---|---|
| `ine_adrh` | INE | Indicadores 1–6; renta neta por hogar del indicador 17 (§7.7); población y hogares de las pruebas de la geografía; nombres de municipio | CC BY 4.0 |
| `mivau_serpavi` | MIVAU | Indicadores 8, 9, 14, 15 y 21 | Reutilización autorizada por el aviso legal del MIVAU (Ley 37/2007 y RD 1495/2011), citando la fuente y la fecha, sin desnaturalizar la información |
| `ine_censo2021` | INE | Indicador 18; denominador del 19 | CC BY 4.0 |
| `ine_vut` | INE | Indicador 19 | CC BY 4.0 |
| `aeat_mercado_trabajo` | AEAT | Indicador 7; fichas «mochila» y «transistor» (retención de los pensionistas); percentil salarial (§6.6) | Reutilización libre, también comercial, citando la fuente y la fecha de última actualización |
| `boe_smi` | BOE | Ficha «tartera» (2015–2026) | Reutilizable |
| `inss_pensiones` | INSS (Seguridad Social) | Ficha «transistor» | Reutilización citando la fuente y la fecha de última actualización |
| `ine_ecv` | INE | Control de la mochila; indicador 22 | CC BY 4.0 |
| `ine_ecv_modulo` | INE | Indicador 23 | CC BY 4.0 |
| `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r` | Eurostat | Compuerta del indicador 22, también por quintil de renta (`ilc_lvho07b`); serie y mapa europeo de la web | CC BY 4.0 |
| `eurostat_nuts` | Eurostat (GISCO) | Geometrías del mapa europeo | Uso no comercial con el aviso «© EuroGeographics para los límites administrativos». No es CC BY |
| `ine_seccionado` | INE | Seccionados de 2016 a 2025; jerarquía territorial y mapa base | CC BY 4.0 |
| `ign_au` | IGN | Nombre y tipo del suelo sin sección en el mapa base (§3.10) | CC BY 4.0 (Orden FOM/2807/2015), con la atribución `Obra derivada de BDDAE 2026 CC-BY 4.0 ign.es` |
| `ine_callejero` | INE | Tablas de paso, vía (a) | CC BY 4.0 |
| `catastro_inspire` | D. G. del Catastro | Tablas de paso, vía (b) | Contradictoria: ver abajo |
| `catastro_foral` | Diputaciones forales de Álava, Bizkaia y Gipuzkoa; Gobierno de Navarra | Vía (b) en País Vasco y Navarra | Distinta en cada territorio: ver abajo |
| `gv_emal` | Gobierno Vasco | Capa municipal de contexto (fianzas); no se mezcla con el indicador 8 | CC BY 4.0 |
| `ine_ipva` | INE | Indicador 10 | CC BY 4.0 |
| `mivau_valor_tasado` | MIVAU | Indicadores 12, 16 y 17 | Reutilización autorizada por el aviso legal del MIVAU, citando la fuente y la fecha |
| `mivau_transacciones` | MIVAU (escrituras del Notariado) | Compuerta de coherencia de la tasación (§7.7) | Reutilización autorizada por el aviso legal del MIVAU, citando la fuente y la fecha |
| `ine_hipotecas` | INE | Compuerta de su tipo medio (`validacion_hipotecas`); el indicador 17 usa el tipo del Banco de España (§7.7) | CC BY 4.0 |
| `bde_accesibilidad`, `bde_tipos_referencia` | Banco de España | Módulo histórico (§7.9); tipo de los préstamos nuevos para vivienda del indicador 17 (§7.7) | Reutilización citando la fuente y la fecha de actualización, sin sugerir que participa en el atlas |
| `ine_ipc` | INE | Aviso de euros corrientes de la evolución de la ficha, con la variación del IPC del periodo; no deflacta ninguna cifra (§9.2) | CC BY 4.0 |
| `notariado` | Consejo General del Notariado | No se usa: sus webs reservan los derechos y piden autorización expresa para reutilizar las cifras; el indicador 11 sale de Registradores, por provincia (§7.7) | Derechos reservados: solo uso personal; reutilizar exige su autorización expresa |
| `zonas_tensionadas` | MIVAU, en el BOE (declaraciones de las comunidades autónomas) | Indicador 20 (§7.8) | Reutilizable citando la fuente (condiciones de reutilización del BOE) |
| `portales` | Idealista y Fotocasa (salas de prensa) | Indicador 13, capa desmontable y solo web, apagada por defecto: alquiler de Idealista de 2015 a 2026 (§7.8) | Condiciones generales de Idealista: uso personal y privado; sin su permiso escrito, ni extracción automática o manual, ni copia en otro sitio web, ni enlaces en profundidad; sus informes, citando la fuente. Por revisar: pedir esa autorización (§7.8) |
| `cis_barometros` | CIS | La vivienda como problema: serie nacional y mensual de los barómetros, fuera de la tabla larga (§7.10) | Reutilización libre citando al CIS, sin desnaturalizar el contenido (Ley 37/2007); los metadatos de cada estudio declaran CC BY 4.0 |
| `calculo_propio` | De renta en renta | Indicadores derivados 14, 15, 16, 17 y 21, a partir de las fuentes de cada término, y margen aproximado de la mediana del alquiler (§7.6) | CC BY-SA 4.0 |

**Descarga manual del SERPAVI.** La web del MIVAU bloquea las descargas automáticas. Si falta el Excel, `descargar_mivau_serpavi()` detiene el pipeline e indica la página y el nombre con el que guardarlo (`inventario/fuentes.csv`, columna `acceso`).

**Descarga manual de Registradores** (indicador 11; fuente `registradores`). El servidor de su portal de datos abiertos rechaza los clientes que no son un navegador, y no se fuerza: el CSV `RP_ComprvResid_2007-2t2026.csv` (577 KB) se baja a mano y se guarda con su nombre en `datos/brutos/registradores/`, fuera de git. `registradores_descargar()` toma la versión más reciente y, si no hay ninguna, se detiene y dice qué bajar y dónde dejarlo. El fichero de 2007-2t2026 (577.366 bytes) está en su sitio desde el 11-nov-2026 y el bloque de `_targets.R` está conectado (§7.7).

### 2.2 Licencias: qué obliga cada fuente

Tabla única de licencias (backlog, tarea 57). El texto de cada licencia, con su dirección y la fecha en que se leyó, está en la columna `licencia` de `inventario/fuentes.csv`. Van en negrita los cuatro casos que piden cuidado: los tres catastros con licencias contradictorias, la ODbL de Registradores, las geometrías europeas de uso no comercial e Idealista, solo en la web.

| Fuente | Licencia | Qué obliga |
|---|---|---|
| INE (ADRH, Censo 2021, viviendas turísticas, IPVA, hipotecas, ECV, seccionado, callejero, padrón, Contabilidad Nacional e IPC), Eurostat (datos), IGN y Gobierno Vasco | CC BY 4.0 | Citar la fuente. El IGN pide además la atribución `Obra derivada de BDDAE 2026 CC-BY 4.0 ign.es` |
| MIVAU (SERPAVI, valor tasado y transacciones), AEAT, INSS, BOE (salario mínimo y zonas tensionadas), Banco de España y CIS | Reutilización autorizada por sus avisos legales o condiciones de uso (Ley 37/2007) | Citar la fuente y la fecha de la última actualización, sin desnaturalizar la información. El Banco de España pide además no sugerir que participa en el atlas o lo patrocina; el CIS, no atribuirle carácter oficial |
| Catastro estatal (D. G. del Catastro) | **Contradictoria:** CC BY 4.0 en los metadatos de la IDEE; una licencia de 2016 que exige transformar los datos antes de difundirlos en la página INSPIRE; «all rights reserved» en el feed ATOM general; uso gratuito citando a la D. G. del Catastro como autora y propietaria en los feeds de edificios | Se trata como dato abierto (decisión del autor, 8-nov-2026). Citar a la D. G. del Catastro como autora y propietaria. Solo se difunden derivados (las tablas de paso), nunca los edificios |
| Catastro foral de Bizkaia | **Contradictoria:** CC BY 3.0 ES con las condiciones de la Ley 37/2007; las entradas municipales de su feed dicen «all rights reserved» | Citar a la Diputación Foral y la fecha de actualización, sin alterar el contenido |
| Catastro foral de Gipuzkoa | **Contradictoria:** solo atribución en el WFS; CC BY-SA 4.0 en los metadatos y en el feed | Citar a la Diputación Foral y publicar los derivados con la misma licencia: por eso el atlas publica en CC BY-SA 4.0 (§2.3) |
| Catastros forales de Álava y Navarra | CC BY 4.0, sin contradicciones | Citar; Navarra pide «Servicio proporcionado por el Gobierno de Navarra» |
| Registradores (Estadística Registral Inmobiliaria): indicador 11, por provincia (backlog, tarea 46) | **ODbL** (Open Database License) | Citar a Registradores en cada uso público. Lo que se publique como base de datos derivada de la suya (las filas del indicador 11 en la tabla larga y en el *release*) va con ODbL, no con CC BY-SA 4.0, y sin medidas técnicas que cierren el acceso; en mapas y gráficos, un aviso de que usan su base con ODbL. El paquete lo dice en `version.json` (`licencia`; `LICENCIA_DATOS.md`) |
| Eurostat, GISCO: geometrías NUTS del mapa europeo | **Uso no comercial**, con el aviso «© EuroGeographics para los límites administrativos». No es CC BY | El aviso, en la leyenda del mapa y en la página «Datos». Las geometrías quedan fuera de la licencia de los derivados; un uso comercial exige una licencia de EuroGeographics |
| Idealista: indicador 13 y derivados de «entrar» | **Solo en la web, «próximamente»:** sus condiciones generales limitan el uso al personal y privado y piden su permiso escrito para copiar su contenido en otro sitio web, extraerlo o enlazar en profundidad; sus informes se citan con su fuente | Hasta su autorización escrita, la capa está apagada y la web la anuncia «próximamente». Nada suyo en la tabla larga, las descargas ni el *release*; en el repositorio, solo una docena de cifras citadas en la documentación y en la compuerta, con su fuente (backlog, decisión 19). Sus derivados, solo por tramos (decisión 18) |
| Consejo General del Notariado | Derechos reservados: uso personal; reutilizar exige su autorización expresa | No se usa: el atlas no descarga sus cifras (§7.7) |
| De renta en renta: derivados, textos e inventario | CC BY-SA 4.0 | Citar y publicar lo que se derive con la misma licencia (`LICENCIA_DATOS.md`; §2.3) |
| Código del atlas; bibliotecas de la web (MapLibre GL JS 6.15.0 y PMTiles 4.5.0) | MIT; BSD-3 | Conservar el aviso de licencia (`LICENSE`, `web/vendor/`) |

(`inventario/fuentes.csv`; plan §6.3.)

### 2.3 Licencia de los derivados

**Decisión del autor (8-nov-2026):** las fuentes se tratan como datos abiertos. Los datos derivados, los textos y el inventario se publican con licencia CC BY-SA 4.0 (`LICENCIA_DATOS.md`; plan §6.1). Hasta esa fecha, la licencia era CC BY 4.0.

CompartirIgual admite las fuentes con licencia CC BY y las que piden compartir igual, como Gipuzkoa. A cambio, quien reutilice los derivados debe publicar lo suyo con la misma licencia.

**Qué incluye:**
- Desde esa fecha, las tablas de paso combinadas con el Catastro se versionan en `geo/tablas_paso/combinada_<año>_2021.csv` (objetivo `fichero_paso_final_<seccionado>`).
- La jerarquía territorial (`geo/jerarquia_2021.csv`, `geo/territorios_2021.csv`) y el mapa base en PMTiles derivan del seccionado del INE y llevan la misma licencia. El PMTiles no entra en git: se publica desde un *release* del repositorio (§3.10).

**Excepciones:**
- Las geometrías NUTS de GISCO quedan fuera de la licencia de los derivados.
- Las cifras del indicador 11, de Registradores, siguen la ODbL (§2.2).
- La capa de precios de oferta de los portales no se redistribuye y está apagada por defecto (`PORTALES=FALSE`; plan §2.2): no va en el *release* ni en las descargas, solo en la web (backlog, decisión 3).
- Las bibliotecas de la web, MapLibre GL JS 6.15.0 y PMTiles 4.5.0 (`web/vendor/`), conservan su licencia BSD-3 (plan §6.6).
- El código tiene licencia MIT (`LICENSE`).

**Atribución sugerida:** «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]» (`LICENCIA_DATOS.md`).

### 2.4 Plan de retirada por fuente

Qué se hace si una fuente aclara su licencia en contra, retira su permiso o pide que se quiten sus datos. Lo ya publicado sigue en los *releases* anteriores y en la historia de git: retirar una fuente es publicar un *release* sin ella, borrar sus ficheros de los anteriores (`gh release delete-asset`) y, solo si la fuente lo exige, reescribir la historia de git.

| Fuente | Qué depende de ella | Cómo se retira |
|---|---|---|
| Catastro estatal | Vía (b) de las tablas de paso fuera del País Vasco y Navarra, y las tablas combinadas que se versionan en git | Tablas de paso solo con el callejero, vía (a), con un cambio en `_targets.R`. Cuesta precisión: con el seccionado de 2025, 7.057 secciones `estimado` y 3.101 medianas `ausente`, frente a 1.194 y 753 con la tabla combinada (§3.5). Las tablas combinadas salen de git en un commit nuevo |
| Catastros forales de Bizkaia o Gipuzkoa | Vía (b) en su territorio | Sus zips, fuera de `ZIPS_CATASTRO_FORAL` o `FEEDS_CATASTRO_FORAL` (`R/fuente_catastro_foral.R`): sus secciones pasan a la vía (a) |
| Registradores | Indicador 11 en la tabla larga, el *release* y la web | Fuera su bloque de `_targets.R` (tarea 46), y paquete y *release* nuevos: el 11 vuelve a quedar sin fuente |
| Eurostat, GISCO | Mapa europeo de la sección de sobrecarga | `nuts_2021.geojson` y `nuts_2024.geojson` salen del paquete de la web; la sección se queda con la serie y la tabla de países |
| Idealista | Capa de portales (indicador 13) y derivados de «entrar» | La capa ya está apagada por defecto (`PORTALES=FALSE`) y no sale del pipeline: se borra su extracción de `datos/brutos/portales/`. Si lo pide, salen también las cifras citadas en la documentación y las referencias `portales_*` de la compuerta |
| Fuentes oficiales con cita (INE, MIVAU, AEAT, INSS, BOE, Banco de España y CIS) | Sus indicadores; el SERPAVI es el núcleo del atlas (indicadores 8, 9, 14, 15 y 21) | Fuera sus filas de la tabla larga (columna `fuente`), sus mapas y sus fichas; paquete y *release* nuevos |

---

## 3. Seccionado de referencia y geografía constante

### 3.1 Referencia: el seccionado del Censo 2021

**Qué es.** El mapa y todas las series usan el seccionado del INE a 1 de enero de 2021: 36.333 secciones (`secciones_2021`; plan §1 y §6.3).

**Por qué.** En ese seccionado publican toda su serie el SERPAVI (2011–2024) y el Censo 2021 (indicador 18): ninguno de los dos necesita tabla de paso (plan §6.3). Con el último seccionado habría que repartir las medianas del SERPAVI: 227 de las 26.137 secciones con dato en 2024 tienen un código que desaparece antes de 2025 (plan §11, pregunta 4).

**Qué se reproyecta:**
- la renta del ADRH, que se publica cada año en su propio seccionado (§3.2 y §5);
- las viviendas turísticas (indicador 19), que desde febrero de 2024 se publican en el seccionado de 2024 (§7.3; ruptura `vut_seccionado_2024` en `inventario/rupturas.csv`). El plan las situaba en el seccionado de 2021 desde la v0.9; se corrigió en la v0.20.
- el Censo 2011 (indicador 18 de 2011) y las viviendas turísticas de agosto de 2020 a febrero de 2023, que están en las secciones del Censo 2011 (§3.11; tarea 47).

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
- **Capas** (`ZOOMS_MAPA_BASE`). Comunidades, provincias y municipios se obtienen disolviendo las secciones (`geo_capas_mapa_base()`), así que sus bordes coinciden con los de las secciones, salvo donde absorben suelo sin sección (abajo). Por encima del zoom 12, MapLibre amplía las teselas.

  | Capa | Zooms | Atributos |
  |---|---|---|
  | comunidades | 0–12 | `ccaa`, `nombre` |
  | provincias | 3–12 | `provincia`, `nombre` |
  | municipios | 5–12 | `municipio`, `nombre` |
  | secciones | 7–12 | `seccion` |
  | sin_seccion | 0–12 | `km2`, `provincias`, `nombre`, `tipo` |

- **Suelo sin sección.** El seccionado del INE de 2021 no cubre el suelo que no pertenece a ningún término municipal: montes y terrenos comunales compartidos, como las Bardenas Reales o las sierras de Urbasa y Andía. Quedan como anillos interiores de la unión de las secciones (`geo_huecos()`). Se cuentan los de al menos 0,01 km² (`UMBRAL_SIN_SECCION_KM2`), sin las secciones que caen dentro (enclaves): 95, que suman 1.495 km²; el mayor, 418,4 km². Por debajo del umbral solo hay rendijas entre secciones vecinas, 1.140 de menos de 1 m² y una de 13 m²; entre 13 m² y 1 ha no hay ningún anillo. Los huecos van en la capa `sin_seccion`, con su superficie y los códigos de las provincias que tocan. Los 77 que tocan una sola provincia se suman a ella, y los 5 que tocan varias provincias de una sola comunidad, a la comunidad (`geo_absorber_huecos()`). Los 13 restantes quedan fuera de esas capas, porque sin la línea límite oficial no se reparte suelo entre provincias. La web los pinta como «sin dato»; al pulsarlos, la ficha dice qué son. No tienen población, sección ni datos. Los huecos que tocan la costa o la frontera no son anillos interiores y no se detectan.

- **Nombres del IGN** (decisión del autor, 9-nov-2026). Las unidades administrativas del IGN (`ign_au`; `leer_ign_au()`, objetivo `unidades_ign`) traen los condominios: montes y terrenos de varios municipios, como facerías, parzonerías, ledanías o comunidades. Cada hueco se parte por las unidades que lo solapan en al menos 0,01 km² (`geo_nombrar_huecos()`), el mismo umbral que los huecos: los solapes menores son de 0,001 km² o menos, roces de bordes, y el siguiente es de 0,012 km². Cada trozo lleva el nombre literal del IGN, su tipo y las provincias que toca. El tipo es «condominio», como los clasifica el mapa político del IGN (el servicio INSPIRE les da el nivel «Municipio»). Quedan nombrados 57 de los 95 huecos y 1.176,5 km², en 73 trozos; 7 huecos tienen dos unidades o más, y uno de Burgos, 10. La capa lleva cada hueco entero, sin nombre, y encima sus trozos con nombre; al pulsar, la web da el del trozo y, fuera de los trozos, el del hueco. Lo que no cubre ninguna unidad se queda así con el texto genérico: 182,2 km² en los huecos con nombre, de ellos 165,1 en el de 264 km² entre Álava y Navarra, donde el IGN solo dibuja la Parzonería de Entzia y el Monte Comunal de las Limitaciones de las Améscoas. El resto son franjas finas en los bordes, donde las líneas del IGN y las del INE no coinciden; como trozos aparte, la cuantización de las teselas las rompía. Los otros 38 huecos (136,3 km²) no tienen unidad del IGN y conservan el texto genérico. Siete nombres de Burgos llevan identificadores de cinco cifras en lugar de nombres («Comunidad de 09076, 09290, 09578, 09606 y 09822»): no son códigos de municipio del INE y se dan tal cual. Ninguna de las 7 unidades del código 54 (territorios que no son de ninguna provincia) toca un hueco. La ficha cita al IGN con la atribución que pide su licencia.

- **Teselas.** Se generan con GDAL desde R, con los controladores PMTiles y MVT (`generar_pmtiles()`), sin tippecanoe (plan §6.2). Cada tesela usa una rejilla de 4.096 unidades por 512 píxeles. La simplificación se mide en unidades de esa rejilla, así que es la misma a los dos lados de un borde compartido.
- **Simplificación** (plan §11, pregunta 16): 4 unidades (medio píxel) por debajo del zoom 12 y ninguna en el zoom 12. En GDAL, el parámetro del zoom máximo es una tolerancia, no un número de zoom: vale 0 (`simplificacion_zoom_max`).
- **Tamaño.** El fichero ocupa 35,4 MB (1 MB = 10⁶ bytes), con 13.235 teselas (`resumen_mapa_base`, `pmtiles_resumen()`):

  | Zoom | Teselas | MB | Mayor tesela (KB) |
  |---|---|---|---|
  | 0–4 | 13 | 0,04 | 9,0 |
  | 5 | 5 | 0,35 | 146,0 |
  | 6 | 10 | 0,46 | 149,4 |
  | 7 | 24 | 1,67 | 208,4 |
  | 8 | 71 | 2,27 | 142,5 |
  | 9 | 208 | 2,78 | 85,3 |
  | 10 | 702 | 4,12 | 68,4 |
  | 11 | 2.548 | 6,50 | 38,4 |
  | 12 | 9.654 | 17,13 | 58,0 |

- **Compuerta** (`comprobar_mapa_base()`, `validacion_mapa_base`). Lee con GDAL las teselas del zoom 12. `mapa_base_secciones`: encuentra las 36.333 secciones. `mapa_base_huecos` (alerta): 95 huecos del seccionado y 1.495 km², calculados desde las secciones. `mapa_base_sin_seccion` (bloqueo): con las secciones y la capa `sin_seccion` juntas, ensanchada la capa una unidad de la rejilla (2,4 m en el zoom 12), no queda ningún hueco abierto. Con las unidades del IGN, `mapa_base_huecos` da también los huecos con nombre (57) y su superficie (1.176,5 km²). `mapa_base_nombres` (bloqueo): los 73 trozos con nombre lo llevan, con su tipo, en la capa del zoom 12, en su punto interior. `mapa_base_nombres_dobles` (bloqueo): ningún suelo tiene dos unidades a la vez (0 km²).
- **Publicación** (plan §6.6; plan §11, pregunta 16). El PMTiles no entra en la historia de git: se regenera con `targets` y se publica desde un *release* del repositorio, que el flujo de GitHub Pages copia junto a la web. En local se ve con `node geo/visor/servir.mjs` (`geo/visor/`).

**Códigos postales** (plan §6.3; plan §11, pregunta 16). No son una unidad del INE y no hay polígonos oficiales reutilizables. La correspondencia sección ↔ código postal saldrá del callejero del INE (campo CPOS de los tramos): en enero de 2021, el 80,7 % de las secciones tiene un solo código postal (11.051 códigos; 2.262 cruzan municipios). Solo la necesitan los indicadores 11 y 16. Una geometría propia a partir de los portales de CartoCiudad se decide en F4.

### 3.11 Tabla de paso desde el Censo 2011

**Qué lleva** (plan §11, pregunta 14; tarea 47). El indicador 18 de 2011 (Censo 2011) y el 19 de agosto de 2020 a febrero de 2023 (`PERIODOS_VUT_2011`), que el INE publica en las 35.960 secciones del Censo 2011, a 1 de noviembre de 2011. Agosto de 2023 queda fuera: mezcla códigos de varios seccionados (§7.3).

**Insumos** (`R/paso2011.R`; `bloque_paso2011` en `_targets.R`):
- **Mapa:** la cartografía de las secciones del Censo 2011 (`secciones_censo2011`). Coincide código a código con las viviendas turísticas y con los indicadores del Censo (`paso2011_seccionado`). El seccionado de 1 de enero de 2011 no coincide: tiene 4 códigos que no están en el Censo y le faltan 3 (por revisar).
- **Callejero:** el de enero de 2012, con los tramos a 31 de diciembre de 2011 (`tramos_2012`), en la aplicación antigua, como las tablas de 2016–2020. Es el más cercano a la fecha del Censo: el de enero de 2011 queda diez meses antes y el de 2012, dos meses después (decisión del autor, 10-nov-2026). Aun así no va en fase: 63 códigos suyos no están en el Censo y 45 del Censo no están en él, en 69 municipios (`paso2011_descasados`, `paso2011_municipios_descasados()`).
- **Catastro:** los edificios de F1 (`edificios_paso`, §3.4), sin leer ninguno más. Se sitúan en las secciones del Censo (`edificios_censo2011`, `paso2011_origen_edificios()`): 5.848.919 edificios con 20.599.073 viviendas.

**Dos tablas** (`paso2011_tabla_catastro()`). Como en F1, la vía (b) solo cuenta los edificios construidos hasta el año de los datos:
- la del Censo, con los construidos hasta 2011 (`paso_final_2011`; 19.778.309 viviendas);
- la de las viviendas turísticas, con los construidos hasta 2020, el año del primer periodo (`paso_final_2011_vut`; 20.258.627 viviendas). Con los de 2011, las secciones de los barrios construidos después no recibirían viviendas turísticas.

**Combinación** (`paso2011_combinar()`). La regla de F1 (`combinar_vias()`, §3.5), con dos ajustes por la fase del callejero:
- los orígenes del callejero que no están en el mapa del Censo salen de la tabla;
- en los municipios descasados, decide la vía (b) en las secciones con edificios del Catastro, porque el callejero solo ve una parte de ellas. En 3 de esos municipios no hay Catastro y decide el callejero.

Las fusiones y segregaciones de municipios entre 2011 y 2021 forman 15 grupos con 37 municipios (`grupos_2011`, §3.7).

**Resultado** (secciones de 2021; `resumen_paso2011`, `paso2011_resumen()`):

| Tabla | Secciones de 2021 que reciben algo | `estimado` | Medianas `ausente` | Pares por callejero / Catastro / código |
|---|---|---|---|---|
| Solo callejero | 36.286 | 11.043 | 4.242 | 81.344 / 0 / 3 |
| Combinada del Censo (edificios hasta 2011) | 36.300 | 5.446 | 1.974 | 24.465 / 15.972 / 1 |
| Combinada de las viviendas turísticas (hasta 2020) | 36.314 | 5.497 | 1.998 | 24.464 / 16.032 / 1 |

- Hay más secciones `estimado` que en cualquier año del ADRH (de 195 a 1.665; §3.5): son diez años de cambios de límites, con el Catastro leído solo en los municipios de F1. De las 5.446 de la tabla del Censo, 366 están en 179 municipios sin Catastro, donde reparte el callejero.
- Las medianas `ausente` no afectan a estas series: el 18 y el 19 son cocientes de recuentos.

**Compuerta** (`paso2011_comprobar()`, `validacion_paso2011`; §4.1). En `anio`, 2011 para la tabla del Censo y 2020 para la de las viviendas turísticas.
- `cierre_poblacional`: la población del Censo 2011 llevada a 2021 frente a la de sus orígenes, por municipio o grupo. Pasa en las dos tablas, con 8.112 comparaciones cada una y una desviación máxima de 1,4 × 10⁻¹⁴ %. Queda fuera un municipio sin población en el Censo.
- `cobertura_destino`: pasa en las dos tablas con 19 excepciones (`inventario/excepciones_cobertura.csv`): secciones de 2021 a las que no llegan ni el callejero de enero de 2012 ni el Catastro de F1, en 18 municipios. Son barrios posteriores a 2011 o municipios sin Catastro en F1 (por revisar). Una de ellas, 3500201010, es ya excepción del ADRH (§3.8).
- `paso2011_cobertura_posterior` (alerta): 14 secciones de 2021 sin nada de la tabla del Censo cuyos edificios son todos de 2012 o después (de Madrid, Boadilla del Monte, Getafe, Leganés, Tres Cantos, Pamplona y Zaragoza). En 2011 no tenían viviendas: su cifra de 2011 es `ausente`. La tabla de las viviendas turísticas sí llega a ellas.
- `paso2011_sin_paso` (alerta): 2 secciones del Censo con datos que ninguna vía lleva a 2021, 1502501002 y 3200701003: no tienen tramos en el callejero ni edificios del Catastro leídos, y su código no está en 2021 (por revisar). Pierden una vivienda turística en dos periodos (§7.3).

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
- los datos de la web (`ficheros_web`), de `validacion_jerarquia`, `validacion_mapa_base` y `validacion_derivados`. `validacion_web` comprueba los ficheros ya escritos;
- la sección de sobrecarga de la web (`ficheros_web_sobrecarga`), de `validacion_sobrecarga`, `validacion_modulo`, `validacion_nuts` y `validacion_quintil` (el quintil de renta, `sobrecarga_quintil`, frente a Eurostat, `eurostat_quintil`): no depende de la tabla larga. `validacion_web_sobrecarga` comprueba los ficheros ya escritos.

Cada bloque de la tabla larga pasa además por `validar_tabla_larga()`: columnas, niveles y longitud de los códigos, estados, valores vacíos solo en `secreto` y `ausente`, filas repetidas, y cortes, grupos, indicadores y fuentes que existen en `inventario/`.

### 4.1 Comprobaciones en el pipeline

| `id` | Qué compara | Tolerancia | Tipo | Resultado | Objetivo |
|---|---|---|---|---|---|
| `adrh_municipio` | Mediana, por año e indicador, de la desviación entre las medias de sección agregadas a municipio y la cifra municipal | ±0,1 % | Bloqueo | 0,0 % en 2015–2024, renta por persona y por hogar | `validacion_adrh` |
| `adrh_dist_cobertura` | Provincias con municipios en cada tabla de secciones de los indicadores 4–6 (una descarga cortada se queda en una provincia intermedia sin dar error) | Exacto | Bloqueo | 52 en las tres tablas | `validacion_adrh_distribucion` |
| `adrh_dist_rango` | Cifras de los indicadores 4–6 fuera de 0–100 | Exacto | Bloqueo | 0 en las 30 cifras de año e indicador | `validacion_adrh_distribucion` |
| `adrh_dist_fuentes_suma` | Máxima desviación, por año, de la suma de las cinco fuentes de ingreso respecto a 100, en los territorios con las cinco publicadas | ±0,25 puntos | Bloqueo | 0,2 puntos como máximo en 2015–2024 | `validacion_adrh_distribucion` |
| `adrh_dist_umbrales_orden` | Territorios con la población por debajo del 40 % de la mediana mayor que la del 50 %, o esta mayor que la del 60 % | Exacto | Bloqueo | 0 en los 10 años | `validacion_adrh_distribucion` |
| `adrh_dist_seccion_unica` | Máxima diferencia, por año e indicador, entre la sección y el municipio en los municipios de una sola sección | Exacto | Bloqueo | 0 en las 30 cifras | `validacion_adrh_distribucion` |
| `adrh_dist_municipio` | Mediana, por año e indicador, de la desviación (puntos) entre las secciones del 4 y el 5 agregadas a municipio como media ponderada (el 4 con la renta bruta y el 5 con la población) y la cifra municipal | ±0,05 puntos | Bloqueo | 0,006 puntos como máximo (indicador 5); 0 en el 4 | `validacion_adrh_distribucion` |
| `adrh_dist_provincia` | Lo mismo por provincia, con las secciones publicadas, frente a la tabla de totales: comprueba el casado de los nombres | ±0,3 puntos | Bloqueo | 0,16 puntos como máximo | `validacion_adrh_distribucion` |
| `cierre_poblacional` | Población reproyectada a 2021 frente a la suma de sus orígenes, por municipio o grupo | ±0,5 % | Bloqueo | Pasa en los nueve años (§3.9) | `validacion_f1` |
| `cierre_poblacional` (tablas de 2011) | Lo mismo con la población del Censo 2011, en las dos tablas desde el Censo 2011 (`anio` 2011 y 2020) | ±0,5 % | Bloqueo | Pasa: 8.112 comparaciones por tabla, 1,4 × 10⁻¹⁴ % como máximo (§3.11) | `validacion_paso2011` |
| `cobertura_destino` | Secciones de 2021 que no reciben nada | Exacto | Bloqueo | Ninguna, salvo las excepciones | `validacion_f1` |
| `cobertura_destino` (tablas de 2011) | Lo mismo en las dos tablas desde el Censo 2011, sin las secciones de `paso2011_cobertura_posterior` | Exacto | Bloqueo | Ninguna, salvo 19 excepciones en cada tabla (§3.11) | `validacion_paso2011` |
| `paso2011_seccionado` | Secciones de las viviendas turísticas de 2020–2023 y del Censo 2011 fuera del mapa del Censo 2011, y secciones del mapa sin fila en las viviendas turísticas | Exacto | Bloqueo | 0, 0 y 0 | `validacion_paso2011` |
| `paso2011_censo_alquiler` | Hogares en alquiler (%) de 2011 de España, de cada comunidad y de cada provincia de la tabla 02003 frente a las secciones del Censo 2011, con las secciones en secreto como intervalo | ±0,1 puntos | Bloqueo | Los 72 territorios, dentro del intervalo | `validacion_paso2011` |
| `paso2011_censo_principales` | Hogares de las secciones del Censo 2011 sumados frente a los de la tabla 02003 | ±1 % | Bloqueo | España, −0,03 %; de −0,56 % (Pontevedra) a +0,06 % | `validacion_paso2011` |
| `paso2011_censo_paso` | Hogares y hogares en alquiler de 2011 llevados a 2021, sumados por provincia, frente a sus secciones del Censo 2011 | ±0,01 % | Bloqueo | 0 en las 104 cifras | `validacion_paso2011` |
| `paso2011_vut_paso` | Viviendas turísticas de 2020–2023 llevadas a 2021, sumadas por provincia y España, frente a la tabla 39364 | ±0,02 % | Bloqueo | 0, salvo A Coruña en dos periodos (−0,02 %; `paso2011_sin_paso`) | `validacion_paso2011` |
| `paso2011_vut_denominador` | Secciones del Censo 2011 que caen enteras y solas en la de 2021 del mismo código: mediana de la diferencia entre el porcentaje del INE y 100 × viviendas turísticas / viviendas del Censo 2011, por periodo | ±0,01 puntos | Bloqueo | 0,0001 puntos como máximo | `validacion_paso2011` |
| `paso2011_vut_territorios` | 2020–2023: porcentaje de España, de cada comunidad y de cada provincia de la tabla 39365 frente a 100 × viviendas turísticas de sus secciones / viviendas del Censo 2011 de sus secciones | ±0,01 puntos | Bloqueo | Las 432 cifras; diferencia máxima, 0,0063 puntos (A Coruña, agosto de 2022) | `validacion_paso2011` |
| `serpavi_provincia` | Testigos de las secciones sumados a provincia, por año y tipología, frente a la hoja de provincias (las medianas no se agregan) | Exacto | Bloqueo | Pasa en las 1.040 cifras: 52 provincias, 10 años y 2 tipologías | `validacion_serpavi` |
| `serpavi_espana` | Testigos de las secciones, y por otro lado los de las comunidades, sumados a España, frente a la fila de España de la hoja de comunidades | Exacto | Bloqueo | Pasa en las 40 cifras. En 2022 y 2023, España es la suma de las comunidades sin Gipuzkoa, porque el País Vasco aún no tiene cifra | `validacion_serpavi` |
| `serpavi_secreto` | Secciones, provincias y comunidades con mediana y menos de 10 testigos, o sin mediana y con 10 o más | Exacto | Bloqueo | 0 casos en las 60 cifras de año, nivel y tipología | `validacion_serpavi` |
| `serpavi_cuartiles` | Mediana sin cuartiles, alquiler mensual sin alquiler por m² (o al revés) o cuartiles desordenados | Exacto | Bloqueo | 0 casos en las 60 cifras | `validacion_serpavi` |
| `serpavi_escalas` | Porcentaje de municipios y distritos que no cuadran con sus secciones, por año y nivel | ±1 % | Bloqueo | Máximo, 0,56 % (municipios de 2022) | `validacion_serpavi` |
| `serpavi_seccionado` | Secciones de la base fuera del seccionado de 2021, y distritos y municipios fuera de él con testigos o mediana | Exacto | Bloqueo | 0 en los tres niveles | `validacion_serpavi` |
| `contratos_mediana` | Territorios cuya mediana y cuyos contratos (`contratos_alquiler`) no casan con la regla de secreto: con mediana, 10 o más; en secreto, de 1 a 9; sin dato, 0 o ninguno | Exacto | Bloqueo | 0 casos en las 100 cifras de año, nivel y tipología | `validacion_fiabilidad` |
| `contratos_suma` | Contratos de las secciones sumados a provincia y, como en `serpavi_espana`, a España, en la tabla larga | Exacto | Bloqueo | Pasa en las 1.080 cifras: 1.040 de provincia y 40 de España | `validacion_fiabilidad` |
| `censo2021_alquiler` | Hogares en alquiler (%) de España, de cada comunidad y de cada provincia con las secciones, frente a la tabla 59523. Las secciones en secreto entran como un intervalo: sus hogares pueden estar entre el 0 y el 100 % en alquiler | ±0,1 puntos | Bloqueo | Pasa en los 72 territorios; la cifra publicada cae dentro del intervalo en 52; España, 16,10 % en las dos; diferencia máxima, 0,055 puntos (Huelva) | `validacion_censo2021` |
| `censo2021_principales` | Hogares de las secciones frente a los publicados, en España y en las 7 comunidades y 19 provincias sin secciones en secreto | ±0,5 % | Bloqueo | España, −0,20 % (los hogares de las secciones en secreto); comunidades y provincias, de 0 a +0,17 % (Melilla) | `validacion_censo2021` |
| `censo2021_seccionado` | Secciones del CSV fuera del seccionado de 2021 y secciones del seccionado sin fila en el CSV | Exacto | Bloqueo | 0 y 0 | `validacion_censo2021` |
| `censo2021_nacional` | Hogares en alquiler (%) de España publicado frente a la media ponderada de las provincias y, aparte, de las comunidades de la tabla 59523 | Exacto | Bloqueo | Pasa: 16,10 % en los tres | `validacion_censo2021` |
| `vut_viviendas_provincia` | Viviendas turísticas de las secciones sumadas por provincia y España, en los 13 periodos, frente a la tabla 39364 | Exacto | Bloqueo | Cuadran las 689 cifras: 13 periodos y 53 territorios | `validacion_vut` |
| `vut_seccionado` | Desde febrero de 2024: secciones del seccionado de 2024 que faltan en la tabla 5, más secciones con viviendas turísticas fuera de él | Exacto | Bloqueo | 0 en los seis periodos | `validacion_vut` |
| `vut_paso_2021` | Viviendas turísticas llevadas a 2021 con la tabla 2024 → 2021, sumadas por provincia y España, frente a la tabla 39364 | ±0,01 % | Bloqueo | Desviación 0 en las 318 cifras | `validacion_vut` |
| `vut_denominador` | Secciones de 2024 que caen enteras y solas en la de 2021 del mismo código: mediana de la diferencia entre el porcentaje del INE y 100 × viviendas turísticas / viviendas del Censo 2021 | ±0,01 puntos | Bloqueo | 0 en los seis periodos | `validacion_vut` |
| `vut_nacional_viviendas` | Viviendas turísticas de las 52 provincias sumadas frente a las de España, en los 13 periodos, en la tabla 39364 | Exacto | Bloqueo | Cuadran los 13 periodos | `validacion_vut` |
| `vut_nacional_porcentaje` | Desde febrero de 2024: porcentaje de España de la tabla 39365 frente a la media de los provinciales ponderada con las viviendas del Censo 2021 | ±0,02 puntos | Bloqueo | De −0,001 a +0,009 puntos | `validacion_vut` |
| `vut_territorios` | Desde febrero de 2024: porcentaje de España, de cada comunidad y de cada provincia de la tabla 39365 frente a 100 × viviendas turísticas de sus secciones / viviendas del Censo 2021, con el denominador del INE en cada periodo (secciones con dato hasta agosto de 2024; tabla 59521 desde noviembre de 2024) | ±0,005 puntos | Bloqueo | Pasan las 432 cifras; diferencia máxima, 0,005 puntos, el redondeo (Jaén, febrero de 2024) | `validacion_vut` |
| `jerarquia_unica` | Secciones repetidas, territorios con más de un superior y códigos que no encajan | Exacto | Bloqueo | 0 en las 5 cifras | `validacion_jerarquia` |
| `jerarquia_sumas` | Territorios que no suman sus partes; secciones de más o de menos frente al seccionado de 2021 | Exacto | Bloqueo | 0 en las 6 cifras | `validacion_jerarquia` |
| `jerarquia_nombres` | Comunidades, provincias y municipios sin nombre | Exacto | Bloqueo | 0 en las 3 cifras | `validacion_jerarquia` |
| `mapa_base_secciones` | Secciones de 2021 que faltan en las teselas del zoom máximo del PMTiles | Exacto | Bloqueo | 0 | `validacion_mapa_base` |
| `mapa_base_sin_seccion` | Huecos del seccionado que siguen abiertos con las secciones y la capa `sin_seccion` del zoom máximo juntas | Exacto | Bloqueo | 0 | `validacion_mapa_base` |
| `mapa_base_nombres` | Trozos del suelo sin sección con nombre del IGN que no lo llevan, con su tipo, en la capa `sin_seccion` del zoom máximo | Exacto | Bloqueo | 0 de 73 | `validacion_mapa_base` |
| `mapa_base_nombres_dobles` | Superficie de los huecos con dos unidades del IGN a la vez | Exacto | Bloqueo | 0 km² | `validacion_mapa_base` |
| `smi_neto` | Ingreso neto mensual de la tartera de 2026 (`perfiles`) frente a la cifra del plan: 17.094 € × (1 − 0,065) / 12 ≈ 1.332 € | ±1 € | Bloqueo | 1.331,91 €; diferencia, −0,09 € | `validacion_derivados` |
| `derivados_terminos` | Desviación máxima, por año e indicador, entre cada cifra derivada y la recalculada con sus términos | ±0,001 % | Bloqueo | 4,3 × 10⁻¹⁴ % como máximo en las 41 cifras | `validacion_derivados` |
| `derivados_estado` | Cifras derivadas cuyo estado no es el peor de sus términos (en el 15, el del alquiler, o `ausente` sin ingreso de la ficha), o con valor y estado `secreto` o `ausente` (o al revés) | Exacto | Bloqueo | 0 en las 41 cifras | `validacion_derivados` |
| `derivados_rango` | Cifras derivadas fuera del rango posible: esfuerzo, del 0,1 al 100 %; peso del alquiler en el ingreso, del 0,1 al 300 %; sueldo necesario, de 100 a 20.000 € netos al mes con el alquiler mensual real y de 100 a 10.000 € con el mínimo de 50 m² (por indicador y corte; tarea 40) | Exacto | Bloqueo | 0 en las 60 cifras | `validacion_derivados` |
| `perfiles_mochila` | Provincias de la mochila sin código del INE en `inventario/provincias_aeat.csv`, provincias repetidas en un año y provincias de la tabla sin mochila (en los 10 años) | Exacto | Bloqueo | 0 en las 3 cifras | `validacion_derivados` |
| `supuestos_inventario` | Supuestos de `inventario/supuestos.csv` con el valor por defecto fuera de sus opciones, sin unidad, uso o decisión, repetidos u obligatorios que faltan (§6.7) | Exacto | Bloqueo | 0 en los 12 supuestos | `validacion_supuestos` |
| `supuestos_r` | Constantes del pipeline distintas del CSV (superficies, umbral, tramos de «¿te llega?», supuestos del manifiesto y de la compraventa) | Exacto | Bloqueo | 0 de 9 | `validacion_supuestos` |
| `supuestos_web` | `web/js/supuestos.js` distinto del que genera R desde el CSV, o botones de superficie, umbral y pagas de `web/mapa.html` distintos de sus opciones | Exacto | Bloqueo | 0 de 4 | `validacion_supuestos` |
| `supuestos_muestra_21` | Muestra de 14 territorios de 2024: sueldo necesario de las cuentas de la página con los supuestos por defecto frente al indicador 21 de la tabla larga, con sus dos cifras | ±0,001 % | Bloqueo | 0 % | `validacion_supuestos` |
| `supuestos_muestra_15` | Misma muestra: peso del alquiler en el ingreso de la tartera, la mochila y el transistor frente al indicador 15 de la tabla larga | ±0,001 % | Bloqueo | 2 × 10⁻¹⁴ % como máximo en las 40 cifras | `validacion_supuestos` |
| `supuestos_superficie_tipica` | Superficie típica de Madrid, Barcelona y València en 2024 frente a la tarea 37 del backlog (62, 66 y 83 m²) | ±0,5 | Bloqueo | 62,1, 65,7 y 83,0 m² | `validacion_supuestos` |
| `smi_boe` | Cuantía mensual del SMI de cada año en `SMI_FICHAS` frente a la del real decreto en su XML del BOE, y la norma citada; 2021, media ponderada por meses de vigencia | Exacto | Bloqueo | 0 en las 18 cifras (2015–2023) | `validacion_smi` |
| `inss_cobertura` | Provincias, comunidades de varias provincias y España que faltan o se repiten en algún mes del año (Excel del INSS) | Exacto | Bloqueo | 0 en los 10 años | `validacion_inss` |
| `inss_suma` | Pensiones de jubilación de las provincias frente al número publicado para su comunidad y para España, cada mes | Exacto | Bloqueo | 0 en los 10 años (132 cifras al mes) | `validacion_inss` |
| `inss_media` | Pensión media de jubilación de las provincias, ponderada, frente a la publicada para su comunidad y para España, cada mes | ±0,01 € | Bloqueo | 4,5 × 10⁻¹³ € como máximo | `validacion_inss` |
| `transistor_cobertura` | Provincias sin ingreso neto del transistor en algún año | Exacto | Bloqueo | 0 en los 10 años | `validacion_transistor` |
| `transistor_retencion` | Retenciones del transistor fuera de [0, 30 %] | Exacto | Bloqueo | 0 en los 10 años | `validacion_transistor` |
| `aeat_provincia` | Cifras de la tabla provincial de la AEAT cuyo salario medio publicado no es salarios / asalariados redondeado al euro | Exacto | Bloqueo | 0 en los 14 años (2011–2024) | `validacion_salarios` |
| `aeat_salarios_cobertura` | Provincias (48), comunidades (17) y España de régimen común sin el salario medio total y el de 26 a 35 años, o repetidas | Exacto | Bloqueo | 0 en los 14 años | `validacion_salarios` |
| `aeat_salarios_suma` | Asalariados de las provincias sumados frente a los publicados para su comunidad y para España | Exacto | Bloqueo | 0 en los 14 años (36 cifras al año) | `validacion_salarios` |
| `aeat_salarios_media` | Salario medio de las provincias (salarios / asalariados sumados) frente al publicado para su comunidad y para España | ±0,5 € | Bloqueo | 0,499 € como máximo: el redondeo de la cifra publicada | `validacion_salarios` |
| `mochila_cobertura` | Provincias de régimen común con módulo de año completo (46) sin mochila neta en algún año, o repetidas | Exacto | Bloqueo | 0 en los 10 años (2015–2024) | `validacion_mochila_serie` |
| `percentil_cobertura` | Comunidades de régimen común (15) y España sin curva salarial completa (percentiles 1 a 99) | Exacto | Bloqueo | 0 en los 10 años (2015–2024) | `validacion_percentil` |
| `percentil_monotono` | Curvas salariales cuyo neto no crece con el percentil | Exacto | Bloqueo | 0 en los 10 años | `validacion_percentil` |
| `percentil_suma` | Asalariados de los 13 tramos de salario frente al total de su comunidad o de España | ±10 asalariados | Bloqueo | 1 como máximo, en 5 de los 10 años: la fuente no cuadra por un asalariado | `validacion_percentil` |
| `percentil_limites` | Tramos cuyo salario medio cae fuera de sus límites con el SMI anual del año (14 pagas) | Exacto | Bloqueo | 0 en los 10 años | `validacion_percentil` |
| `web_salarios` | Cifras de `web/datos/salarios.json` distintas de las curvas redondeadas al euro, y curvas que faltan o sobran | Exacto | Bloqueo | 0 | `validacion_web_salarios` |
| `web_valores` | Ficheros de valores de `web/datos/` cuyos valores o estados no son los de la tabla larga (con el redondeo de la guía a la precisión de cada serie: una décima; dos en el 19) o cuya longitud no es la del índice; series sin fichero. También los contratos y el margen de cada serie del alquiler | Exacto | Bloqueo | 0 en las 830 cifras | `validacion_web` |
| `web_fichas` | Por municipio: celdas de las series de su ficha que no reproducen la tabla larga con la precisión de cada serie, y secciones de más o de menos | Exacto | Bloqueo | 0 en los 8.131 municipios | `validacion_web` |
| `portada_valores` | Cifras de las cartas de la portada (`web/datos/portada.json`): sueldo necesario de la sección mediana con el alquiler mensual real y sus percentiles 10 y 90, y al lado la mediana del mínimo de 50 m²; secciones donde el alquiler de 50 m² pasa del 30 y del 40 % del salario mínimo neto y, al lado, donde lo pasa el alquiler mensual real; y sobrecarga de España, recalculadas desde el alquiler mensual y por m² y el ingreso de la tartera que recibe la web y desde las filas de la sobrecarga | Exacto | Bloqueo | 0 en las 15 cifras | `validacion_portada` |
| `portada_casillas` | Casillas de la portada (`inventario/casillas_portada.csv`): 24, orden sin huecos, ids únicos, cuatro familias, activas con destino e inactivas sin él, y destinos que existen (mapas del manifiesto, claves de `web/js/estado.js` y anclas de las páginas generadas) | Exacto | Bloqueo | 0 en las 24 casillas | `validacion_portada` |
| `web_sobrecarga_valores` | Sección de sobrecarga de la web: por vista, valor, puesto, bloque, fuente y marca de cada cifra frente a los objetivos del pipeline (con el redondeo de la guía), y territorios de más o de menos; serie de España, desgloses anuales con el quintil, módulo de acceso y cortes del mapa frente a `cortes_web` del indicador 22 | Exacto | Bloqueo | 0 en las 17 cifras | `validacion_web_sobrecarga` |
| `web_sobrecarga_muestra` | Cifras del INE sin muestra, con una muestra distinta de la del cálculo, con una marca que no es la de EU-SILC o con valor y menos de 20 observaciones; cifras de Eurostat sin su tabla, con muestra o con una marca distinta de la de la fuente | Exacto | Bloqueo | 0 en las 13 cifras | `validacion_web_sobrecarga` |
| `sobrecarga_es_total`, `sobrecarga_es_mercado`, `sobrecarga_ccaa` | Sobrecarga con los microdatos de la ECV frente a Eurostat | ±0,1 puntos | Bloqueo | Pasan en 2023–2025 (§7.5) | `validacion_sobrecarga` |
| `sobrecarga_quintil_total` | Por ola: media de las tasas de sobrecarga de los cinco quintiles de renta, ponderada por sus personas, frente a la tasa total | ±0,01 puntos | Bloqueo | Diferencia 0 en las tres olas | `validacion_quintil` |
| `sobrecarga_quintil_eurostat` | Sobrecarga de España por quintil de renta, con los microdatos de la ECV y sin redondear, frente a Eurostat (`ilc_lvho07b`) del mismo año | ±0,1 puntos | Bloqueo | Pasan las 15 cifras de 2023–2025, iguales a un decimal; diferencia máxima, 0,045 puntos (§7.5) | `validacion_quintil` |
| `modulo_acceso_lectura` | Suma de las comunidades frente al total nacional del módulo de la ECV 2025 | ±0,1 % | Bloqueo | Pasa | `validacion_modulo` |
| `i18n_completo`, `contraste_texto`, `rampa_contorno`, `rampa_daltonismo` | Diccionarios ES/EN, contrastes de la web y rampa de siete pasos distinguible con daltonismo simulado (0,07 en OKLab como mínimo; tarea 51) | Exacto | Bloqueo | Pasan | `validacion_i18n`, `validacion_diseno` |
| `adrh_municipio_detalle` | Desviación de cada municipio entre las medias de sección agregadas y la cifra municipal | ±1 % | Alerta | Avisa en 579 de 146.306 cifras de municipio, año e indicador; 135 pasan del 5 % | `comprobaciones_adrh` |
| `adrh_dist_municipio_detalle` | Desviación (puntos) de cada municipio entre las secciones del 4 y el 5 agregadas como media ponderada y la cifra municipal | ±1 punto | Alerta | Avisa en 98 de 108.360 cifras de municipio, año e indicador; 33 pasan de 2 puntos y la mayor es de 5,8 | `comprobaciones_adrh_distribucion` |
| `adrh_suma_secciones` | Población por sección del ADRH sumada por municipio frente al total municipal de la misma tabla | ±0,5 % | Alerta | Avisa en 160 municipios y años, todos de 2015–2019 (38, 34, 30, 29 y 29) | `comprobaciones_f1` |
| `adrh_seccion_huerfana` | Secciones del ADRH sin código en ningún seccionado de 2016–2025 | Exacto | Alerta | 9 (§3.8) | `huerfanas_adrh` |
| `cobertura_destino_excepcion` | Secciones de 2021 vacías por un defecto conocido de la fuente | Exacto | Alerta | 2 secciones, 6 años-sección (§3.8) | `comprobaciones_f1` |
| `cobertura_destino_excepcion` (tablas de 2011) | Las mismas, en las tablas desde el Censo 2011 | Exacto | Alerta | 19 secciones en cada tabla (§3.11) | `comprobaciones_paso2011` |
| `paso2011_cobertura_posterior` | Secciones de 2021 sin nada de una tabla desde el Censo 2011 cuyos edificios del Catastro son todos posteriores a su año | Exacto | Alerta | 14 en la tabla del Censo; ninguna en la de las viviendas turísticas | `comprobaciones_paso2011` |
| `paso2011_sin_paso` | Secciones del Censo 2011 con datos que ninguna vía lleva a 2021 | Exacto | Alerta | 2, en las dos tablas | `comprobaciones_paso2011` |
| `mapa_base_huecos` | Huecos del seccionado de 2021 de al menos 0,01 km² (suelo que no es de ninguna sección): número y superficie, en total y con nombre del IGN | Exacto | Alerta | Avisa con 95 huecos y 1.495 km² (el mayor, 418,4 km²); con nombre del IGN, 57 y 1.176,5 km² (§3.10) | `validacion_mapa_base` |
| `serpavi_escalas_detalle` | Cada municipio o distrito, año y tipología que no cuadra con sus secciones | Exacto | Alerta | Avisa en 164 filas, que van como `ausente` (§7.1) | `validacion_serpavi` |
| `serpavi_forales` | Primer año con testigos de cada provincia foral frente al de la ruptura `serpavi_forales` | Exacto | Alerta | Coinciden los cuatro | `validacion_serpavi` |
| `serpavi_sin_fila` | Secciones, distritos y municipios del seccionado de 2021 que la base no trae (van como `ausente`) | Exacto | Alerta | Avisa con 40 secciones, 36 distritos y 36 municipios (§7.1) | `validacion_serpavi` |
| `margen_rango` | Secciones con el margen aproximado de la mediana fuera del 1–40 %, por año, indicador y tipología | Exacto | Alerta | Avisa en las 40 cifras: 2.414 secciones y años en 2015–2024, 2.242 de vivienda unifamiliar; en 2024, 16 de colectiva y 268 de unifamiliar (§7.6) | `validacion_fiabilidad` |
| `vut_denominador_detalle` | Las secciones de `vut_denominador`, una a una (solo las que se apartan más de 0,001 puntos) | ±0,1 puntos | Alerta | Pasa: 839 secciones y periodos, todos desde noviembre de 2024; diferencia máxima, 0,091 puntos | `validacion_vut` |
| `derivados_rango_detalle` | Cada cifra derivada fuera del rango habitual: esfuerzo, por debajo del 3 % o por encima del 60 %; peso del alquiler en el ingreso, del 3 % o del 150 %; sueldo necesario, de 200 € o de 10.000 € con el alquiler mensual real y de 200 € o de 4.000 € con el mínimo de 50 m² | Exacto | Alerta | Avisa en 43 cifras: tres esfuerzos de más del 60 % (2019 y 2022); con el mínimo de 50 m², 18 sueldos necesarios por debajo de 200 € en 2015–2018 y dos por encima de 4.000 € (dos secciones de Madrid, 2024); con el alquiler mensual real, 19 por encima de 10.000 € y uno por debajo de 200 € (tarea 40) | `validacion_derivados` |
| `supuestos_muestra_fichero` | `pruebas/datos/supuestos_muestra.json` (14 territorios × 40 combinaciones de «Tu ficha» y las tres fichas de una persona) distinto de la muestra del pipeline | Exacto | Alerta | Al día | `validacion_supuestos` |
| `supuestos_superficie_tipica_mediana` | Mediana de la superficie típica de los municipios en 2024 frente al cálculo del 11-nov-2026 (82,1 m²) | ±0,5 | Alerta | 82,1 m² en 2.555 municipios | `validacion_supuestos` |
| `supuestos_superficie_tipica_rango` | Cifras municipales de la superficie típica fuera de 40 a 160 m², de 2015 a 2024 | Exacto | Alerta | Ninguna | `validacion_supuestos` |
| `web_fuera_indice` | Filas de la tabla larga que van a la web sin hueco en el índice de su nivel | Exacto | Alerta | Avisa en 16 filas de municipio; en los demás niveles, 0 | `validacion_web` |
| `web_tramos` | Por mapa y juego de cortes (sección, municipio, y provincia y comunidad juntas), en el último año: tramos vacíos o con más del 35 % de los territorios con dato; mapas sin juegos que no son excepción declarada | Exacto | Alerta | Pasa: ningún tramo vacío ni por encima del 35 % en los 35 juegos de 15 mapas; el más lleno, el 31 % (Gini, provincia y comunidad, 2024) | `validacion_web_tramos` |
| `web_sobrecarga_geometria` | Territorios de una vista del mapa de la sobrecarga sin geometría en su versión NUTS ni en la de respaldo | Exacto | Alerta | Pasa: 0 en las 12 vistas (§7.5) | `validacion_web_sobrecarga` |
| `aeat_mediana_deciles` | Mediana del SME por comunidad interpolada desde deciles frente a centiles | ±0,5 % | Alerta | Entre −0,19 y +0,45 % (2019–2024) | `validacion_mochila` |
| `mochila_ecv` | Mochila de cada comunidad y de España frente al intervalo del 95 % de la mediana del bruto de la ECV, que sale del tamaño de su muestra (cuánto se sale, en %) | Exacto | Alerta | Avisa en 20 de 160 cifras (con ±15 %, en 32); el intervalo va de ±2,7 % (España) a ±57 % (comunidades de unas 50 observaciones) | `validacion_mochila_ecv` |
| `mochila_neto_ecv` | Paso a neto aplicado a la mediana del bruto de la ECV frente a la mediana del neto, cada año | ±5 % | Alerta | Avisa en 8 de 180 cifras, todas de comunidades (de −5,0 a +19,0 %); en 2024, entre −2,0 y +3,4 %; España, entre −1,2 y +2,5 % (+0,5 % en 2024) | `validacion_mochila_neto_ecv` |
| `mochila_forma` | Relación mediana/media del SME de 26 a 35 años de cada comunidad, de 2020 a 2024, frente a la de 2019, que usan 2015–2018 | ±3 % | Alerta | Pasa: entre −2,7 y +1,7 % | `validacion_mochila_serie` |
| `mochila_relacion_ecv` | Relación mediana/media del bruto de quien trabajó los doce meses, de 26 a 35 años, en la ECV de España, de 2015 a 2018 frente a la de 2019 (puntos) | ±2 puntos | Alerta | Avisa en 2015 (+2,1) y 2017 (−3,1) | `validacion_mochila_relacion` |
| `mochila_relacion_correccion` | Si la anterior avisa, la corrección (la relación de 2019 escalada con la ECV) solo se aplica si se valida en 2020–2024 | Exacto | Alerta | Avisa y no se corrige: error medio de 4,0 puntos escalada frente a 0,6 sin escalar | `validacion_mochila_relacion` |
| `percentil_media` | Media de la distribución por tramos modelada frente al salario medio publicado de cada comunidad y de España | ±0,5 % | Alerta | Pasa: 0,12 % como máximo (2017) | `validacion_percentil` |
| `sobrecarga_es_edad` | Sobrecarga de España por grupos de edad | ±0,1 puntos | Alerta | Pasa en 2023–2025; diferencia máxima, 0,05 puntos (plan §7, F1b) | `validacion_sobrecarga` |
| `sobrecarga_quintil_reparto` | Población con renta (factor RB050) de cada quintil, por ola | ±1 punto sobre el 20 % | Alerta | Pasa: del 19,95 al 20,05 % | `validacion_quintil` |
| `nuts_geometria` | Regiones con dato sin geometría en su versión NUTS ni, como respaldo, en una posterior | Exacto | Alerta | Avisa: el código agrupado FI19_20 en 2021–2025 | `validacion_nuts` |
| `contraste_declarado` | Contraste declarado en `tokens.json` frente al recalculado | ±0,05 | Alerta | Pasa; diferencia máxima, 0,003 | `validacion_diseno` |
| `ipva_variacion` | Variación anual publicada del IPVA frente a la recalculada con los índices | ±0,06 puntos | Bloqueo | Diferencia máxima, 0,051 puntos | `validacion_ipva` |
| `ipva_nota` | España, Madrid, Barcelona y la Comunitat Valenciana en 2024 frente a la nota de prensa | Exacto | Bloqueo | 3,5; 3,6; 3,3 y 5,0 % | `validacion_ipva` |
| `ipva_contrato_enlace` | Variación de 2021 de los contratos nuevos y existentes frente a la recalculada con su índice y el índice general de 2020 | ±0,06 puntos | Bloqueo | Diferencia máxima, 0,049 puntos | `validacion_ipva` |
| `ipva_contrato` | España por antigüedad del contrato (tabla 59004): índice de 2021 y 2024 de los contratos nuevos, los existentes y el total; variación de los nuevos y los existentes en 2021, 2022 y 2024 | Exacto | Bloqueo | Índice: 114,871 y 137,041; 112,229 y 120,637; 112,694 y 122,920. Variación: 3,5 y 1,2 %; 5,3 y 2,1 %; 8,8 y 2,8 % | `validacion_ipva` |
| `hipotecas_tipo_anual` | Tipo medio anual de las hipotecas sobre viviendas frente a la media de sus doce meses | ±0,05 puntos | Bloqueo | Diferencia máxima, 0,024 puntos (2020) | `validacion_hipotecas` |
| `valor_tasado_nombres` | Nombres del Ministerio sin código del INE | Exacto | Bloqueo | Ninguno: 306 municipios casados | `validacion_valor_tasado` |
| `valor_tasado_ccaa` | Comunidades y España fuera del intervalo de sus provincias | Exacto | Bloqueo | Ningún trimestre desde 2015 | `validacion_valor_tasado` |
| `valor_tasado_tasaciones` | Tasaciones de las comunidades y de España frente a la suma de las de sus provincias | Exacto | Bloqueo | Iguales desde 2015 | `validacion_valor_tasado` |
| `valor_tasado_nota` | España en el primer trimestre de 2026 | Exacto | Bloqueo | 2.315,7 €/m² | `validacion_valor_tasado` |
| `compraventa_coherencia_espana` | Superficie implícita de España (escrituras entre tasación) fuera de 70–110 m² | Exacto | Bloqueo | Pasa: de 91,8 a 106,1 m² (2015–2025) | `validacion_coherencia_compraventa` |
| `compraventa_coherencia_provincias` | Provincias y trimestres con la superficie implícita fuera de 50–150 m² | ±5 % | Bloqueo | 1,9 % como máximo (2021) | `validacion_coherencia_compraventa` |
| `compraventa_terminos` | Años de salario y esfuerzo hipotecario frente a sus términos | ±0,001 % | Bloqueo | Pasa en 2015–2024 | `validacion_derivados_compraventa` |
| `registradores_lectura` | Registradores (indicador 11): por año, provincias, comunidades o España que faltan, filas repetidas y cifras vacías | Exacto | Bloqueo | 0 en 2015–2026 | `validacion_registradores` |
| `registradores_espana` | España, precio por m² de vivienda de 2025 (plan §11, pregunta 45: 2.284 €/m²) | ±0,5 | Bloqueo | Pasa: 2.283,52 €/m² | `validacion_registradores` |
| `registradores_suma` | Compraventas de las provincias frente a las de su comunidad y de España, cada trimestre | Exacto | Bloqueo | 0 en 2015–2026 | `validacion_registradores` |
| `registradores_agregado` | Precio por m² de España y de las comunidades frente a la media de sus provincias ponderada por compraventas | ±3 % | Alerta | De −0,6 a +1,5 % (2015–2025): no avisa | `validacion_registradores` |
| `registradores_rango` | Precios por m² fuera de 300–10.000 € | Exacto | Bloqueo | 0 | `validacion_registradores` |
| `registradores_tasado_espana` | Precio por m² de Registradores entre el valor tasado por m², España, fuera de 0,85–1,25 (pregunta 45 b) | Exacto | Bloqueo | Pasa: de 0,99 (2015) a 1,12 (2022) | `validacion_registradores` |
| `registradores_tasado_provincias` | El mismo cociente, provincia frente a provincia: % fuera de 0,6–1,6 | ±5 % | Bloqueo | 0 % todos los años (de 0,74 a 1,41) | `validacion_registradores` |
| `registradores_tasado_detalle` | Cada provincia y año con el cociente fuera de 0,7–1,4 | Exacto | Alerta | Avisa en Santa Cruz de Tenerife, 2022 (1,41) | `validacion_registradores` |
| `compraventa_renta_cobertura` | Renta neta media por hogar publicada (ADRH, tabla 53689): provincias, comunidades o España que faltan, con cifra o sin ella, y filas repetidas | Exacto | Bloqueo | 0 en 2015–2024 | `validacion_renta_hogar_publicada` |
| `compraventa_renta_publicada` | Mediana, por año y nivel, de la desviación absoluta entre la renta por hogar de los municipios agregada con sus hogares y la publicada | ±0,5 % | Bloqueo | 0,13 % como máximo (España, 2021) | `validacion_renta_hogar_publicada` |
| `compraventa_renta_publicada_detalle` | Cada provincia, comunidad y año con la agregada a más de ±1 % de la publicada | ±1 % | Alerta | Avisa en 6 de 691 cifras: Guadalajara de 2015 a 2019 (de +1,1 a +1,3 %) y Sevilla en 2016 (−1,4 %) | `validacion_renta_hogar_publicada` |
| `cp_municipio_reparto` | Pesos de un código postal que no suman 100, o sin un único municipio principal | ±0,001 | Bloqueo | Pasa en los 11.046 códigos postales | `validacion_cp_municipio` |
| `zonas_tensionadas_resolucion` | Filas del inventario del indicador 20 sin su resolución del BOE descargada, o con otra fecha de publicación | Exacto | Bloqueo | Ninguna de 321 | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_codigos` | Códigos que no son municipios del seccionado de 2021, con otro nombre del INE o fuera de la comunidad de su fila del BOE | Exacto | Bloqueo | Ninguno | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_completa` | Municipios o ámbitos de las tablas del BOE que el inventario no recoge | Exacto | Bloqueo | Ninguno en las 31 filas de las 10 resoluciones | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_fechas` | Fecha de efecto distinta del día siguiente a la publicación (en una prórroga, o al fin del periodo que prorroga), fecha de fin distinta de la que fija el texto y prórrogas sin declaración anterior del mismo ámbito | Exacto | Bloqueo | Ninguna de 321 | `validacion_zonas_tensionadas` |
| `web_zonas_tensionadas` | Declaraciones de la web distintas de las del inventario | Exacto | Bloqueo | Ninguna | `validacion_web_zonas_tensionadas` |
| `portales_codigos` | Cifras de la capa de portales con códigos que no son comunidades, provincias ni municipios del seccionado de 2021 (zonas y localidades: el de su municipio) | Exacto | Bloqueo | Ninguna, con `PORTALES=TRUE` | `validacion_portales` |
| `portales_idealista_espana` | España, alquiler de Idealista, media anual de los meses publicados (9 como mínimo) en 2015 y 2024 | ±0,005 | Bloqueo | Pasa: 7,58 y 13,06 €/m² | `validacion_portales` |
| `portales_idealista_municipios` | Municipios de Idealista con serie y, de ellos, con serie desde 2015 o antes | Exacto | Bloqueo | Pasa: 278 de 286 | `validacion_portales` |
| `web_portales` | Ida y vuelta de `datos/portales/`: cifras, estados, enlaces a los informes y zonas frente a la capa, y ninguna serie de los portales en el manifiesto general | Exacto | Bloqueo | Ninguna diferencia, con `PORTALES=TRUE` | `validacion_web_portales` |
| `entrar_tramos` | Tramos de `inventario/entrar_tramos.csv`: cada tramo de la brecha, contados los límites, al menos un 15 % más ancho de borde a borde, y los derivados, sin cortes propios (§7.8) | Exacto | Bloqueo | Ninguno, con `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_rango` | Brechas entre la oferta y el parque fuera de 0,8–2,5, en cualquier nivel | Exacto | Bloqueo | Ninguna, con `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_rango_detalle` | Cada brecha de 2 o más | Exacto | Alerta | 17 cifras municipales: 2 en 2017, 2 en 2018, 5 en 2023 y 8 en 2024 | `validacion_entrar` |
| `entrar_coherencia` | Sueldo para entrar (superficie típica y 50 m²) y barrera para entrar (`barrera_entrar`) de las tres fichas fuera del intervalo que la web calcula con el tramo de su brecha | Exacto | Bloqueo | Ninguna, con `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_municipios` | Municipios con oferta y SERPAVI el mismo año, frente a la tarea 37 del backlog | Exacto | Bloqueo | Pasa: 256 en 2015 y 259 en 2024 | `validacion_entrar` |
| `entrar_mediana` | Brecha mediana de esos municipios en 2015 y 2024, frente a la tarea 37 del backlog | ±0,01 | Bloqueo | Pasa a menos de 0,01, no de 0,005: la referencia divide por el SERPAVI a la precisión de la fuente, y el pipeline, a un decimal, como la web (por revisar) | `validacion_entrar` |
| `entrar_mediana_rango` | Brecha mediana de los municipios en 2024, entre 1,30 y 1,40 | ±0,05 | Bloqueo | Pasa | `validacion_entrar` |
| `entrar_superficie` | Superficie típica mediana de esos municipios en 2024, frente a la tarea 37 del backlog | ±0,5 | Bloqueo | Pasa: 77 m² | `validacion_entrar` |
| `entrar_ipva` | Provincias donde la oferta crece de 2021 a 2024 más del doble que los contratos nuevos del IPVA | Exacto | Alerta | 7 de 47 provincias | `validacion_entrar` |
| `web_entrar` | Ida y vuelta de `datos/portales/entrar/`: tramo y estado de cada territorio frente a R, cortes del manifiesto y ningún valor que no sea un tramo | Exacto | Bloqueo | Ninguna diferencia, con `PORTALES=TRUE` | `validacion_web_entrar` |
| `hist_series` | Módulo histórico (§7.9): por serie de España, periodos sin cifra entre el primero y el último, repetidos y cifras fuera de su rango creíble | Exacto | Bloqueo | 0 en las siete series de España (1987–2026) | `validacion_historico` |
| `hist_publicadas` | Años de renta y esfuerzo teórico de 2023 a 2026 de la tabla en PDF del Banco de España (5-nov-2026; un año, media simple de sus trimestres) y tipo de referencia de agosto de 2026 del BOE. Una revisión del Banco de España avisa y pide actualizar la referencia | ±0,05 | Alerta | Pasa: las 14 cifras del PDF y la del BOE (3,134 %) | `validacion_historico` |
| `hist_publicadas_enteras` | Valor tasado de España que reproduce el Banco de España en euros enteros, de 2023 a 2026 | ±0,5 | Alerta | Pasa: las 7 cifras | `validacion_historico` |
| `hist_prensa` | Cifras de prensa del plan que la serie confirma (§7.9) | ±0,5 | Alerta | Pasa: 2,90 (1.er trimestre de 1987), 9,46 (3.er trimestre de 2007) y 72,47 % (2.º trimestre de 1990) | `validacion_historico` |
| `hist_fechas` | Fechas clave de la página: máximos y mínimos en su periodo, las demás dentro de su serie, y las rupturas, las de `inventario/rupturas.csv` | Exacto | Bloqueo | Pasa: 14 fechas, 3 de ellas rupturas | `validacion_historico` |
| `hist_valor_tasado_bde` | Diferencia máxima entre el valor tasado de España del MIVAU y el que reproduce el Banco de España | ±0,1 €/m² | Bloqueo | 0,0 €/m² en 126 trimestres | `validacion_historico` |
| `hist_valor_tasado_ccaa` | Por año, trimestres con una comunidad de varias provincias fuera del intervalo de sus provincias, y trimestres sin cifra de las comunidades | Exacto | Alerta | Avisa en 15 trimestres (§7.9) | `validacion_historico` |
| `hist_salarios_suma` | Contabilidad Nacional: remuneración frente a sueldos más cotizaciones, y total frente a la suma de las ramas A10 (sueldos y personas asalariadas) | ±1 | Bloqueo | 0 en 1995–2025 | `validacion_cne` |
| `web_historico` | Ida y vuelta de `datos/historico/historico.json`: cifras, periodos, series, territorios, fechas clave y rupturas | Exacto | Bloqueo | 0 | `validacion_web_historico` |
| `cis_vivienda_publicada` | La vivienda como problema (CIS), España y personal, redondeada a un decimal, frente a las notas de prensa del CIS (§7.10) | ±0,1 puntos | Bloqueo | Pasan las cinco cifras, exactas | `validacion_cis` |
| `cis_vivienda_suma` | Total de menciones frente a la suma de la primera, la segunda y la tercera | ±0,2 puntos | Bloqueo | Como mucho 0,1 puntos en el HTML y 0,045 en el XLSX | `validacion_cis` |
| `cis_vivienda_rango` | Cifras fuera de 0–100 o sin valor, barómetros con menos de 1.000 entrevistas, meses con una sola pregunta y estudios repetidos | Exacto | Bloqueo | Ninguno | `validacion_cis` |
| `cis_vivienda_categoria` | Barómetros sin la categoría «La vivienda» en una pregunta (el mes no entra en la serie) | Exacto | Alerta | Abril y mayo de 2020, pregunta de España | `validacion_cis` |
| `cis_vivienda_cobertura` | Barómetros sin resultados abiertos en XLSX ni en HTML, o con la descarga fallida | Exacto | Alerta | Ninguno: los seis meses solo en PDF (julio de 2014 y febrero, abril, mayo, junio y julio de 2025) están transcritos | `validacion_cis` |
| `cis_vivienda_pdf` | Transcripción de los meses solo en PDF (`inventario/cis_transcripcion_pdf.csv`): meses con resultados abiertos, estudios de otro mes, preguntas que faltan, totales a más de 0,2 puntos de la suma de los tres problemas o con menos de 1.000 entrevistas, y enlaces ajenos | Exacto | Bloqueo | Ninguno en las 12 filas | `validacion_cis` |
| `cis_vivienda_meses` | Meses sin barómetro entre el primero y el último, salvo agosto | Exacto | Alerta | Siete (§7.10) | `validacion_cis` |
| `cis_vivienda_web` | `datos/cis_vivienda.json` frente a la tabla `cis_vivienda`: periodos, cifras con un decimal, estudio y entrevistas | Exacto | Bloqueo | Ninguna diferencia | `validacion_web_cis` |
| `calendario_fuentes` | `inventario/calendario_fuentes.csv`: fuentes del inventario, vocabulario, meses, días y periodos (§9.3) | Exacto | Bloqueo | Ninguno | `validacion_calendario` |
| `calendario_descargas` | Fuentes que se renuevan desde el calendario sin ningún fichero descargado | Exacto | Alerta | Todas tienen ficheros | `validacion_calendario` |
| `ipc_variacion` | IPC (tabla 76144): variación de las medias anuales publicada frente a la recalculada con los índices, que el INE da con tres decimales | ±0,06 puntos | Bloqueo | Diferencia máxima, 0,049 puntos | `validacion_ipc` |
| `ipc_serie` | Años sin índice general de 2015 a 2024, los del alquiler | Exacto | Bloqueo | Ninguno | `validacion_ipc` |
| `ipc_referencia` | Variación de las medias anuales de 2022 publicada por el INE | Exacto | Bloqueo | 8,4 % | `validacion_ipc` |
| `web_ipc` | `datos/ipc.json` frente a la tabla `ipc`: años e índices | Exacto | Bloqueo | Ninguna diferencia | `validacion_web_ipc` |

**Lectura de los resultados de `adrh_municipio`.** La mediana es 0,0 % porque la mayoría de los municipios tiene una sola sección. La alerta `adrh_municipio_detalle` recoge los casos en que la fuente no cuadra entre escalas con todas las secciones con dato. En Madrid, por ejemplo, Alcobendas y Pozuelo de Alarcón quedan todos los años por encima del 5 % (`inventario/referencias_validacion.csv`).

### 4.2 Comprobaciones pendientes

| `id` | Qué compara | Tolerancia | Tipo |
|---|---|---|---|
| `adrh_aeat` | Renta del ADRH frente a la renta bruta de la AEAT por municipio | Tendencia coherente | Alerta |
| `serpavi_ipva` | Tendencia del SERPAVI frente al IPVA | Tendencia coherente | Alerta |
| `notariado_tasado` | Precio del Notariado frente al valor tasado (indicadores 11 y 12, F4) | Umbral razonado | Alerta |

Las `registradores_*`, antes en esta lista, están en el pipeline desde el 11-nov-2026 (§4.1). `adrh_aeat`, `serpavi_ipva` y `notariado_tasado` no tienen todavía una tolerancia numérica. `validar_referencias()` no admite tolerancias de texto, así que habrá que fijar una antes de que entren en el pipeline.

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

**Filas en la tabla larga.** 1.303.484 filas de la renta (§9.1). Nivel municipal: 73.777 filas por cada media y 65.958 de la mediana. La columna `version` lleva la fecha del fichero de la fuente: 7-nov-2026.

### 5.5 Distribución de la renta (indicadores 4–6)

**Tablas** (`descargar_ine_adrh()`, 9-nov-2026). Tres de toda España por sección, distrito y municipio, y tres de totales:
- **30825:** distribución por fuente de ingresos, en porcentaje de la renta bruta (`fichero_adrh_fuentes`);
- **30829:** umbrales relativos por sexo (`fichero_adrh_umbrales`; 1,65 GB);
- **37677:** índice de Gini y P80/P20 (`fichero_adrh_gini`);
- **53687, 53694 y 53688:** España, comunidades, provincias e islas (`ficheros_adrh_totales`), con nombres y sin códigos. Las comunidades casan por su nombre del INE y las provincias, por el suyo dentro de su comunidad (`codigos_totales_adrh()`). Las islas no entran.
- **53689:** renta media y mediana de España, comunidades, provincias e islas (`fichero_adrh_renta_totales`, 416 KB), con el mismo formato y el mismo casado; de ella sale la renta neta media por hogar de esos niveles para el indicador 17 (§7.7; desde el 11-nov-2026).

**Lectura** (`leer_ine_adrh_distribucion()`, por trozos). Se toman el salario de las cinco fuentes de ingreso, la población de ambos sexos por debajo del 40, del 50 y del 60 % de la mediana (el 40 y el 50 %, solo para la compuerta) y el Gini. El CSV usa tres marcas: «.» es secreto estadístico (`secreto`); «..», dato no disponible, y una celda vacía, año sin publicar en ese territorio (las dos, `ausente`).

| # | Código | En el ADRH | Reproyección |
|---|---|---|---|
| 4 | `peso_salarios` | Fuente de ingreso: salario (% de la renta bruta) | Media ponderada con la renta bruta de la sección (renta bruta media por persona × población) |
| 5 | `bajo_60_mediana` | Población con ingresos por unidad de consumo por debajo del 60 % de la mediana | Media ponderada con la población |
| 6 | `gini` | Índice de Gini | Regla de medianas e índices (§3.6) |

**Por qué el 4 y el 5 se ponderan** (decisión del autor, 9-nov-2026). Son cocientes de sumas: renta de salarios entre renta bruta, y personas por debajo de un umbral que cada año es el mismo en toda España. Agregados a municipio con esos pesos, reproducen la cifra municipal publicada (`adrh_dist_municipio`: mediana de la desviación de 0,006 puntos como máximo). El INE los calcula sobre la población que encuentra en los registros tributarios (más del 98,6 % de la residente), y aquí se pondera con la población del ADRH: la diferencia es la que mide esa compuerta. El Gini no se agrega: sigue la regla de las medianas.

**Estado.** Como en la renta (§5.3), con una diferencia: una sección de 2021 sin valor es `secreto` si alguno de sus orígenes lo es, y `ausente` si ninguno está publicado (`reproyectar_adrh_distribucion()`). Municipios, provincias, comunidades y España llevan la cifra publicada (regla 1 de la guía); de los municipios entran las cifras publicadas y las secretas.

**Compuerta** (`comprobar_ine_adrh_distribucion()`, objetivo `validacion_adrh_distribucion`; §4.1). Comprueba que cada tabla trae las 52 provincias (la primera descarga de la 30829 se cortó en Pontevedra sin dar error), que las cifras están entre 0 y 100, que las cinco fuentes de ingreso suman 100, que los umbrales van en orden, que sección y municipio coinciden en los municipios de una sola sección y que las secciones agregadas reproducen los municipios y las provincias.

**Territorios forales** (ruptura `adrh_forales_distribucion`). Bizkaia está en toda la serie; Gipuzkoa, desde 2016; Álava, desde 2020, y Navarra, desde 2021 (el 4, con unas 80 secciones con dato en 2017–2020 y las demás en secreto). España, desde 2021. Antes, `ausente`: Eustat y Nastat no completan los huecos porque miden otra cosa (decisión del autor, 9-nov-2026; `eustat_nastat` en `inventario/fuentes.csv`).

**Rupturas del indicador 5:**
- `adrh_umbral_mediana_2023`: el umbral es el 60 % de la mediana del territorio fiscal común hasta la edición ADRH 2022 y el de la mediana de toda España desde la 2023, según la metodología del INE, que no dice si la tabla actual recalcula los años anteriores.
- `adrh_umbrales_secreto_2024`: desde la edición 2024, el secreto pide 50 hombres y 50 mujeres por territorio en lugar de 500 residentes. En la tabla solo cambia 2024: las secciones en secreto bajan de unas 2.500–3.000 a 989. Cambia cuántas cifras se publican, no las cifras.

**Resultado** (secciones de 2021; `larga_adrh_distribucion`):

| Indicador y año | `dato` | `estimado` | `secreto` | `ausente` |
|---|---|---|---|---|
| 4 (2015) | 32.085 | 1.608 | 1.274 | 1.365 |
| 4 (2020) | 34.410 | 0 | 1.841 | 82 |
| 4 (2024) | 33.699 | 1.195 | 1.435 | 3 |
| 5 (2015) | 29.306 | 1.591 | 4.070 | 1.365 |
| 5 (2020) | 31.563 | 0 | 4.194 | 576 |
| 5 (2024) | 33.437 | 1.194 | 1.700 | 1 |
| 6 (2015) | 31.666 | 1.246 | 1.487 | 1.933 |
| 6 (2020) | 34.349 | 0 | 1.408 | 576 |
| 6 (2024) | 33.206 | 887 | 1.485 | 754 |

En 2024, la sección mediana tiene el 58,2 % de la renta bruta en salarios, el 19,2 % de la población por debajo del 60 % de la mediana y un Gini de 27,9. España: 60,0 %, 20,2 % y 31,9.

**Filas en la tabla larga.** 1.331.166: sección (1.089.972), municipio (239.034), provincia (1.560), comunidad (570) y España (30). Versión: 9-nov-2026.

**Mapas** (§9.2). Tramos de la columna `cortes_web`: en el 4, 50, 55, 60, 65 y 70 %; en el 5, 10, 15, 20, 25 y 30 %; en el 6, 25, 27, 29, 31 y 33. Desde la tarea 51, siete tramos con un juego de cortes por escala (§9.2) y un decimal.

### 5.6 Salario medio por asalariado (indicador 7)

**Fuente y lectura** (`descargar_aeat_salarios()`, `leer_aeat_salarios()`). AEAT, *Mercado de trabajo y pensiones en las fuentes tributarias*, tabla «Asalariados, percepciones salariales y salarios por provincia, edad y sexo», con el sexo total y todos los tramos de edad: una página HTML por tramo y año.
- Ediciones: de 2011 a 2024. Las anteriores no están en la web de la AEAT.
- Las ediciones cambian de maqueta: hasta 2014, cabeceras de tabla sin prefijo y sangría por margen (`aeat_sangria()`); hasta 2017, filtros en el subtítulo. El tramo de edad se llama «Edad», «Tramo de edad» o «Tramos de Edad», y Ourense, «Orense» hasta 2013.
- Salario medio = salarios / asalariados: lo cobrado en el año por los asalariados con domicilio fiscal en el territorio, también por quien trabajó pocos meses.

**Códigos y niveles** (`codificar_aeat_salarios()`; objetivo `salarios_aeat`): la provincia, por su nombre en `inventario/provincias_aeat.csv`; la comunidad, por su nombre en `geo/ccaa.csv`, con una clave que no depende de cómo lo escribe cada edición (`clave_comunidad()`); España, «00». Las comunidades de una provincia (Asturias, Baleares, Cantabria, Madrid, Murcia y La Rioja), Ceuta y Melilla solo tienen fila de comunidad, que es también la de su provincia.

**En la tabla larga** (`armonizar_aeat_salarios()`; objetivo `larga_salarios`): indicador `salario_medio`, fuente `aeat_mercado_trabajo`, con la cifra publicada en cada nivel (guía, regla 1). El total va sin desglose, y el tramo de 26 a 35 años, con corte `edad` y grupo `Y26-35`. Son 2.016 filas: 14 años, 72 territorios (52 provincias, 19 comunidades y España) y 2 tramos.
- **País Vasco y Navarra.** La AEAT no los cubre (domicilio fiscal foral): sus 4 provincias y 2 comunidades van como `ausente` todos los años (168 filas). De las haciendas forales, solo la de Gipuzkoa publica una cifra comparable (modelo 190, salario medio por edad), en un informe anual en PDF; las de Bizkaia, Álava y Navarra no publican ninguna. La Estadística Municipal de Estructura Salarial de Nastat y la Encuesta Anual de Estructura Salarial del INE miden otra cosa (otro universo y otro ajuste).
- **España** es el territorio de régimen común: sin País Vasco ni Navarra.

**Compuerta** (`comprobar_aeat_salarios()`, `validacion_salarios`; §4.1): `aeat_provincia`, `aeat_salarios_cobertura`, `aeat_salarios_suma` y `aeat_salarios_media`, de bloqueo. Pasan los 14 años. La media de las provincias se aparta como mucho 0,499 € de la publicada para su comunidad o para España: el redondeo al euro.

**Resultado** (España, régimen común):

| Año | Asalariados | Salario medio (€) | De 26 a 35 años: asalariados | De 26 a 35 años: salario medio (€) |
|---|---|---|---|---|
| 2011 | 17.788.121 | 19.102 | 4.996.038 | 15.842 |
| 2015 | 17.349.558 | 18.645 | 4.129.678 | 14.422 |
| 2019 | 19.157.767 | 20.566 | 4.006.014 | 16.594 |
| 2024 | 20.637.992 | 24.962 | 4.090.037 | 21.506 |

En 2024, por provincia, de 17.792 € (Jaén) a 31.911 € (Madrid) en total, y de 15.281 € (Huelva) a 26.037 € (Madrid) de 26 a 35 años.

---

## 6. Ingresos de las fichas

### 6.1 Regla común y fichas

**Regla común:** ingreso neto mensual repartido en 12 (guía, regla 8; plan §3.1). El alquiler se paga doce veces al año; con la paga de un sueldo de 14 pagas, el esfuerzo saldría inflado en torno a un 17 % (14 / 12 = 1,167).

**Vivienda.** Las fichas de una persona buscan 50 m², para que sus mapas solo difieran por el ingreso. El alquiler de las fichas es el de la vivienda colectiva (plan §11, pregunta 12).

| Ficha | Ingreso de referencia | Fuente | Escala | Vivienda | Estado |
|---|---|---|---|---|---|
| Llave (hogar del barrio) | Renta neta media por hogar ÷ 12 | INE, ADRH (indicador 2) | Sección | Alquiler mediano de su sección, sin superficie fija | Ingreso calculado (`perfiles`); esfuerzo (indicador 14), en `larga_derivados` (§7.4) |
| Mochila (joven de 26 a 35 años) | Mediana estimada del salario cobrado en el año, neta, ÷ 12 | AEAT; control con la ECV | Provincia | 50 m² | Calculada de 2015 a 2024 (`mochila_neta`, `perfiles`), como `estimado` |
| Tartera (salario mínimo) | SMI neto anual ÷ 12 | Real decreto de cada año (RD 1106/2014 a RD 126/2026) | Nacional | 50 m² | Calculada de 2015 a 2026 (`perfiles`) |
| Transistor (pensionista) | Pensión media de jubilación, neta de IRPF, ÷ 12 | INSS; retención de la AEAT | Provincia | 50 m² | Calculada de 2015 a 2024 (`transistor`, `perfiles`); País Vasco y Navarra, como `estimado` |
| Tu ficha | Neto mensual que escribe quien consulta: 12 o 14 pagas, segundo sueldo opcional | — | — | 50 m² con un sueldo, 70 m² con dos; cambiable a 50, 70 o 90 | Se calcula en el navegador y no se guarda (`js/sueldo.js`) |

**Estadístico de cada ficha** (tarea 44 del backlog). La web lo dice en una línea en la ficha de «¿te llega?», en la tarjeta «Tu sueldo» y en la portada:
- llave: media del hogar (renta neta media por hogar de la sección);
- mochila: mediana de una persona (salario de 26 a 35 años, estimado);
- tartera: mínimo legal de una persona (salario mínimo interprofesional);
- transistor: media de una persona (pensión media de jubilación), con aviso: la Seguridad Social no publica la pensión mediana por provincia (§6.5);
- Tu ficha: cifra propia, de una persona o de dos con el segundo sueldo.

**Euros que quedan** (tarea 34 del backlog). En «¿te llega?», junto al peso del alquiler en el ingreso (15), la ficha da los euros que quedan al mes: el ingreso neto mensual de la ficha menos el alquiler mensual de la misma vivienda y del mismo año, los dos términos del porcentaje, redondeados al euro antes de restar (`web/js/sueldo.js`). Si el alquiler pasa del ingreso, la diferencia se da como lo que falta. Los euros que quedan son una resta, no un umbral de suficiencia: no dicen si ese resto cubre los demás gastos de un hogar.

### 6.2 Mochila: método B, paso a neto y serie

La decisión del método es del autor, del 7-nov-2026 (plan §3.1; pregunta abierta 7, cerrada). La serie va de 2015 a 2024 (10-nov-2026): cada año, con la AEAT de ese año y con la ola de la ECV del año siguiente, que trae sus ingresos.

**1. Salario de partida.** Salario medio anual bruto de 26 a 35 años por provincia: el indicador 7 (§5.6; objetivo `salarios_aeat`).
- Es salario real del año: incluye a quien trabajó pocos meses.
- Las tablas de la AEAT son páginas HTML, una por combinación de filtros (`descargar_aeat_mercado()`, `leer_aeat_mercado()`).

**2. De media a mediana.** Se multiplica por la relación mediana/media del salario medio estimado (SME, módulo de «año completo») de 26 a 35 años de su comunidad y año (`leer_modulo_sme()`, `formas_sme()`; objetivos `modulos_sme` y `formas_mochila`).
- La AEAT no publica esa mediana. Se interpola con dos tablas (`cuantil_tramos()`):
  - los recuentos de asalariados de cada comunidad y edad en cada decil nacional;
  - los límites de los centiles nacionales.
- Supuesto de la interpolación: dentro de cada decil nacional, la comunidad se reparte como el país. Contraste con los recuentos por centil que la AEAT da por comunidad, para todas las edades: entre −0,19 y +0,45 % de 2019 a 2024 (`aeat_mediana_deciles`).
- Supuesto del método: la relación mediana/media es la misma en todas las provincias de una comunidad.
- **Antes de 2019.** El módulo de año completo empieza en la edición de 2019: de 2015 a 2018 se usa la relación de 2019 (columna `anio_forma`). De 2020 a 2024, la de cada comunidad se aparta de la de 2019 entre un −2,7 % (Baleares, 2021) y un +1,7 % (Asturias, 2020) (`mochila_forma`); la de España es 0,844 en 2019 y en 2024. Esos cuatro años son una estimación con la relación de otro año: la columna `metodo_forma` lo dice (`primer_anio`) y la ficha va como `estimado`, como toda la mochila (plan §11, pregunta 44 f revisada).
- **Comprobación con la ECV de 2015 a 2018** (`ecv_mochila_correccion()`; objetivos `correccion_mochila` y `validacion_mochila_relacion`). Relación mediana/media del bruto de quien trabajó los doce meses, de 26 a 35 años, en España: 0,930 en 2015, 0,904 en 2016, 0,879 en 2017, 0,892 en 2018 y 0,909 en 2019; de 0,857 a 0,899 de 2020 a 2024. Se aparta más de 2 puntos de la de 2019 en 2015 (+2,1) y 2017 (−3,1): avisa (`mochila_relacion_ecv`). La corrección prevista, la relación de 2019 escalada por el cambio que mide la ECV, se valida antes en 2020–2024 y no pasa: se aleja más de la relación del módulo de cada comunidad y año (error medio de 4,0 puntos) que la de 2019 sin escalar (0,6), porque la de la ECV baja un 5,7 % de 2019 a 2024 y la del módulo no se mueve. No se corrige (`mochila_relacion_correccion`, alerta); si un año se validara, `ecv_mochila_aplicar()` escalaría esos años (`primer_anio_ecv`).
- Fórmula: bruto anual = salario medio real provincial × relación mediana/media del SME de su comunidad (`calcular_mochila_serie()`, `mochila`).

**3. De bruto a neto** (`calcular_mochila_neta()`): neto anual = bruto × (1 − cotización − retención); neto mensual = neto anual ÷ 12.
- **Cotización del trabajador del año** (`cotizacion_trabajador()`, la de la tartera en `SMI_FICHAS`): 6,35 % hasta 2022, con contingencias comunes (4,70), desempleo (1,55) y formación profesional (0,10); con el MEI, 6,45 % en 2023 y 6,47 % en 2024. Con contrato temporal, 0,05 puntos más.
- **Retención:** tipo medio de la AEAT de las personas que solo cobran salarios, por comunidad, tramo de renta anual y año (*Grupos de población por la naturaleza de sus retribuciones*; `retenciones_aeat()`, objetivo `retenciones_mochila`). Sale de las mismas páginas que la del transistor (§6.5).
  - Se interpola linealmente entre los salarios medios de los tramos; fuera de ellos se toma el tipo del tramo extremo (`tipo_retencion()`).
  - En España en 2024: entre el 1,6 y el 1,8 % por debajo de 12.000 €; 2,6 % de 12.000 a 18.000 €; 9,0 % de 18.000 a 24.000 €; 13,6 % de 24.000 a 30.000 €.
  - Es la retención de la nómina, no la cuota final del IRPF.

**4. Lo cobrado en el año.** La ficha usa el salario cobrado en el año, no el de quien trabaja doce meses: la AEAT no publica ese salario, porque su «año completo» anualiza por días cotizados. En la ECV, entre el 68,0 % (ingresos de 2015) y el 77,6 % (2021) de los asalariados de 26 a 35 años con salario trabajó los doce meses; con los de 2024, el 73,9 % (`ecv_mochila`, España).

**5. Control con la ECV de cada año** (olas de 2016 a 2025). Microdatos de personas: salario bruto (PY010G), neto (PY010N), factor (PB040) y edad al final del año de ingresos (`leer_ecv_asalariados()`, `resumir_ecv_asalariados()`).
- `mochila_ecv`: la mochila de cada comunidad de régimen común y de España (`mochila_espana()`) frente a la mediana del bruto de la ECV. En 2024, las 15 comunidades quedan entre un −10,6 % (La Rioja) y un +7,2 % (Castilla y León) de la mediana; España, entre un −5,9 % (2015) y un +7,2 % (2020) en la serie. Desde el 11-nov-2026, la tolerancia sale del tamaño de la muestra (plan §11, pregunta 44 g), no de un ±15 % fijo: la alerta mide cuánto se sale la mochila del intervalo del 95 % de la mediana de la ECV, con la muestra efectiva de los pesos (Kish) y el método de Woodruff (`resumir_ecv_asalariados()`). El intervalo va de ±2,7 % (España) a ±57 % (comunidades de unas 50 observaciones). Avisa en 20 de las 160 cifras (con el ±15 % fijo, en 32), hasta un 19,5 % fuera del intervalo (Comunitat Valenciana, 2016, 151 observaciones). España sale del suyo en 2019, 2020, 2022 y 2023, como mucho un 1,9 %: con 2.733 a 4.826 observaciones el intervalo es estrecho, y lo que queda es una diferencia de fondo entre la AEAT y la ECV.
- `mochila_neto_ecv`: el paso a neto aplicado a la mediana del bruto de la ECV frente a la mediana del neto. En 2024, entre un −2,0 % (Canarias) y un +3,4 % (Galicia); España, +0,5 %. En la serie, España queda entre un −1,2 y un +2,5 %, y la alerta salta en 8 de las 170 cifras de comunidad.

**Resultado** (`mochila_neta`; `datos/intermedios/mochila/mochila_neta.csv`):
- **Cobertura:** 46 provincias de régimen común cada año. País Vasco y Navarra no están en las tablas de la AEAT (forales aparte); Ceuta y Melilla no están en el módulo de año completo.
- **Serie** (media de las provincias ponderada por asalariados; el mínimo es siempre Huelva y el máximo, Barcelona):

| Año | Bruto anual (€) | Neto mensual (€) | Mínimo (€) | Máximo (€) |
|---|---|---|---|---|
| 2015 | 12.313 | 920 | 633 | 1.100 |
| 2016 | 12.468 | 930 | 638 | 1.115 |
| 2017 | 12.793 | 952 | 666 | 1.148 |
| 2018 | 13.435 | 999 | 710 | 1.210 |
| 2019 | 14.170 | 1.055 | 762 | 1.270 |
| 2020 | 13.926 | 1.036 | 759 | 1.250 |
| 2021 | 15.079 | 1.112 | 817 | 1.331 |
| 2022 | 16.242 | 1.186 | 866 | 1.397 |
| 2023 | 17.401 | 1.267 | 922 | 1.473 |
| 2024 | 18.334 | 1.330 | 990 | 1.529 |

- La de 2024 es la misma que antes de la serie (diferencias de menos de una milésima de euro). La relación neto/bruto baja de 0,90 (2015) a 0,87 (2024): la retención media pasa del 3,7 al 6,0 %.

**Opciones descartadas.** Las opciones A y C se siguen calculando como registro, en `mochila` (columnas `A` y `C`; `datos/intermedios/mochila/mochila.csv`):
- En 2024, la opción A sale entre 1,24 y 1,49 veces la B (mediana, 1,34). Media ponderada: 24.257 € frente a 18.334 €.
- Frente a la ECV 2025, A queda un 14 % por encima de la mediana de quienes trabajan los doce meses. B queda un 1,7 % por debajo de la mediana de todos los asalariados, en media ponderada de las comunidades (plan §3.1).

### 6.3 Tartera: salario mínimo

**Cálculo** (plan §3.1; `perfiles_fichas()`, `SMI_FICHAS`; objetivo `perfiles`). Ingreso neto mensual = SMI mensual × 14 pagas × (1 − cotización del trabajador) / 12, sin retención de IRPF. La cuantía es la del real decreto de cada año (fuente `boe_smi`), y la cotización, la del trabajador de ese año con contrato indefinido: contingencias comunes (4,70 %), desempleo (1,55 %) y formación profesional (0,10 %), más el MEI desde 2023 (0,10 % en 2023, 0,12 % en 2024, 0,13 % en 2025 y 0,15 % en 2026). La orden de cotización de cada año se cita en `SMI_FICHAS` sin bajarla (decisión del autor, 9-nov-2026).

| Año | Norma | SMI mensual (€, 14 pagas) | Cotización (%) | Neto mensual en 12 (€) |
|---|---|---|---|---|
| 2015 | RD 1106/2014 | 648,60 | 6,35 | 708,65 |
| 2016 | RD 1171/2015 | 655,20 | 6,35 | 715,86 |
| 2017 | RD 742/2016 | 707,70 | 6,35 | 773,22 |
| 2018 | RD 1077/2017 | 735,90 | 6,35 | 804,03 |
| 2019 | RD 1462/2018 | 900 | 6,35 | 983,32 |
| 2020 | RD 231/2020 | 950 | 6,35 | 1.037,95 |
| 2021 | RD 231/2020 y RD 817/2021 | 955 | 6,35 | 1.043,42 |
| 2022 | RD 152/2022 | 1.000 | 6,35 | 1.092,58 |
| 2023 | RD 99/2023 | 1.080 | 6,45 | 1.178,73 |
| 2024 | RD 145/2024 | 1.134 | 6,47 | 1.237,40 |
| 2025 | RD 87/2025 | 1.184 | 6,48 | 1.291,82 |
| 2026 | RD 126/2026 | 1.221 | 6,50 | 1.331,91 |

- **2021.** Tuvo dos cuantías: 950 € de enero a agosto (la de 2020, prorrogada) y 965 € desde el 1 de septiembre (RD 817/2021). Se usa su media ponderada por meses de vigencia, 955 €, coherente con las rentas anuales del ADRH y de la AEAT (plan §11, pregunta 18).
- **Compuerta.** Las cuantías de 2015 a 2023 se leen del XML del BOE de cada real decreto (`descargar_boe_smi()`, `leer_boe_smi()`, `comprobar_smi_boe()`; `smi_boe`, objetivo `validacion_smi`); las de 2024 a 2026 se citan. `smi_neto` compara la de 2026 con los 1.332 € del plan (§4.1).
- **Uso.** El peso del alquiler en el ingreso de la tabla larga (§7.4) y la web usan el SMI del mismo año que el alquiler (regla 4; decisión del autor, 9-nov-2026): con el alquiler de 2024, 1.237,40 €. Los de 2025 y 2026 no tienen alquiler del mismo año; la web cita el último junto al del año elegido.

**Comparación con la mochila.**
- La mochila de 2024 (1.330 € netos de media) sale casi igual que la tartera con el SMI de 2026. Son años distintos (regla 4).
- Con el SMI de 2024 (1.237 € netos), la mochila queda un 7,5 % por encima (plan §3.1).
- La exención de IRPF del SMI vale para quien lo cobra el año entero. La tabla de la AEAT da retenciones del 1,6–1,8 % también por debajo de 12.000 €.

### 6.4 Llave: hogar del barrio

**Ingreso** (`perfiles`): la renta neta media por hogar del ADRH de cada sección (indicador 2, §5) ÷ 12, con el estado de su reproyección. En 2024, en las 36.237 secciones con valor: percentil 10, 2.319 €; mediana, 3.021 €; percentil 90, 4.501 € al mes (`resumen_perfiles_llave`).

**Vivienda:** el alquiler mediano de vivienda colectiva de la propia sección, sin superficie fija. Es la única ficha que varía por los dos lados, el ingreso y el alquiler.

**Esfuerzo:** el cruce con el SERPAVI es el indicador 14 (§7.4), «alquiler mediano sobre renta media del barrio»: la llave en «¿te llega?» es ese mismo cociente y lleva su aviso de lectura (tarea 41).

### 6.5 Transistor: pensionista

**Estadístico.** Es la media, no la mediana: la Seguridad Social no publica la pensión mediana de jubilación por provincia (comprobado el 10-nov-2026: los Excel mensuales por provincia traen número, importe y pensión media por régimen y clase; los tramos de cuantía del anuario son nacionales). La web lo dice en la línea de la ficha (tarea 44).

**Pregunta.** Responde a «si tuviera que alquilar hoy»: el 89,1 % de los mayores de 65 años vive en casa propia (ECV 2023; plan §3.1), y la web lo dice junto a la ficha.

**Método** (plan §3.1; decisión del autor del 9-nov-2026):
1. **Pensión de partida.** Pensión media de jubilación del total del sistema por provincia (INSS, *Pensiones contributivas del Sistema de la Seguridad Social*; Excel mensual «Pensiones por CCAA y provincias»; `descargar_inss_pensiones()`, `leer_inss_pensiones()`). No incluye Clases Pasivas. Es la media de una paga ordinaria; la provincia es la de la dirección provincial que gestiona la pensión, no la de residencia, y se cuentan pensiones, no pensionistas.
2. **Media del año.** Media de las doce cifras mensuales (pensiones en vigor a día 1 de cada mes), ponderada por el número de pensiones (`armonizar_inss_pensiones()`, `anual_inss_pensiones()`; objetivos `inss_mensual` e `inss_anual`). Los nombres de los territorios pasan a códigos con una tabla fija (`inventario/provincias_inss.csv`). El Excel cambia de forma con los años (nombre de la hoja, una hoja por régimen y, desde 2024, el importe): la hoja del total del sistema y la columna de la jubilación se buscan por su texto.
3. **De bruto a neto** (`calcular_transistor()`): bruto anual = media × 14 pagas; neto mensual = bruto anual × (1 − retención) / 12. Las pensiones no cotizan.
   - **Retención:** tipo medio de la AEAT de las personas que solo cobran pensiones (*Grupos de población por la naturaleza de sus retribuciones*, bloque de pensiones, columna «Pensionistas»), por comunidad y tramo de renta anual, del mismo año, interpolado como en la mochila (`retenciones_pensiones()`, `tipo_retencion()`; objetivo `retenciones_transistor`). En 2024, del 0,4 % (Ourense) al 10,8 % (Bizkaia).
   - La AEAT no separa la jubilación de las demás pensiones (viudedad, incapacidad, en parte exenta, y Clases Pasivas): la curva es la de todos los pensionistas con esa renta. Es la retención practicada, no la cuota final del IRPF.
   - **País Vasco y Navarra:** su IRPF es foral y la AEAT no los cubre; se usa la curva de España y el ingreso queda como `estimado` (decisión del autor). Ceuta y Melilla tienen curva propia, con retenciones más bajas por su bonificación.
4. **Compuerta** (§4.1; objetivos `validacion_inss` y `validacion_transistor`): cada mes, las provincias reproducen el número y la pensión media publicados para su comunidad y para España en el mismo Excel (`inss_suma`, `inss_media`), sin territorios que falten ni sobren (`inss_cobertura`); el neto cubre las 52 provincias cada año, con retenciones entre el 0 y el 30 % (`transistor_cobertura`, `transistor_retencion`).

**Resultado** (`transistor`; `datos/intermedios/transistor/transistor.csv`), en euros:

| Año | Pensión media de jubilación en España (por paga) | Neto mensual en 12: mínimo (Ourense) | Máximo (Bizkaia) | Media de las provincias ponderada por pensiones |
|---|---|---|---|---|
| 2015 | 1.021,19 | 825 | 1.411 | 1.151 |
| 2016 | 1.042,65 | 839 | 1.436 | 1.173 |
| 2017 | 1.063,50 | 855 | 1.457 | 1.192 |
| 2018 | 1.090,70 | 878 | 1.490 | 1.225 |
| 2019 | 1.137,81 | 923 | 1.542 | 1.281 |
| 2020 | 1.161,80 | 945 | 1.563 | 1.303 |
| 2021 | 1.189,65 | 972 | 1.588 | 1.328 |
| 2022 | 1.254,14 | 1.030 | 1.657 | 1.385 |
| 2023 | 1.374,58 | 1.136 | 1.796 | 1.503 |
| 2024 | 1.442,67 | 1.198 | 1.869 | 1.574 |

- En 2024, el transistor (1.574 € de media) queda por encima de la mochila (1.330 €) y de la tartera (1.237 €) del mismo año.
- Las fuentes, descargadas con permiso del autor (9-nov-2026): los 120 Excel del INSS de 2015 a 2024 (≈ 9,6 MB) y las retenciones de la AEAT de 2015 a 2023 (1.458 páginas, ≈ 39 MB; las de 2024 ya estaban). Las ediciones de la AEAT hasta 2017 tienen otra maqueta y otros nombres de comunidad («Región de Murcia»): `aeat_titulo()` y `aeat_menus()` leen las dos.

### 6.6 Percentil salarial del sueldo necesario

El sueldo necesario (21) se expresa también como percentil de la distribución salarial, para comparar en el tiempo sin depender de los precios de cada año (plan §7, F3; 10-nov-2026). Es una propuesta pendiente de revisión.

**Distribución** (`leer_aeat_tramos()`, `curvas_salariales()`; objetivos `tramos_salariales` y `curvas_salariales_aeat`): lo cobrado en el año por los asalariados de cada comunidad y de España, la misma medida que el indicador 7 y la mochila (§5.6 y §6.2), de 2015 a 2024.
- Fuente: AEAT, tabla «Asalariados, percepciones salariales y salarios por Comunidad Autónoma, tramos de salario y sexo», con el sexo total: asalariados y salarios en 13 tramos de salario anual, en múltiplos del SMI anual del año (14 pagas). En 2020 y 2021 la tabla añade la situación ERTE (se toma su total) y no trae Ceuta ni Melilla.
- Dentro de cada tramo, una densidad lineal con la media del tramo; el último, abierto, se cierra con su media (uniforme entre 10 SMI y 2 × media − 10 SMI). De ahí salen los percentiles 1 a 99 del salario bruto anual (`cuantil_tramos_salario()`).
- A neto mensual en 12 con la cotización del trabajador y la retención de la AEAT de su comunidad y año, como la mochila (§6.2). Es una función creciente del bruto, así que el orden no cambia.
- País Vasco y Navarra no están en la estadística: usan la curva de España. Ceuta y Melilla, también en 2020 y 2021.
- Incluye a quien trabajó pocos meses: el percentil dice qué parte de los asalariados cobró en el año menos que ese sueldo, neto y repartido en 12.

**En la web** (`salarios_web()`; `datos/salarios.json`): en el mapa del sueldo necesario, la ficha de la sección (y la de los municipios, provincias y comunidades) da el percentil del sueldo que pinta (la cifra principal, con el alquiler mensual real; tarea 40), con el umbral elegido, en la curva de su comunidad y del año del alquiler (`web/js/percentil.js`): «Percentil 84 de los salarios (Comunidad de Madrid, 2024; …)». Por debajo del percentil 1 o por encima del 99, lo dice así.

**Compuerta** (`comprobar_curvas_salariales()`, `validacion_percentil`; `comprobar_salarios_web()`, `validacion_web_salarios`; §4.1): `percentil_cobertura`, `percentil_monotono`, `percentil_suma`, `percentil_limites` y `web_salarios` (bloqueo) y `percentil_media` (alerta). La media de la distribución modelada se aparta como mucho un 0,12 % de la publicada (2017); los tramos no cuadran con el total por un asalariado en 5 de los 10 años.

**Resultado** (España, neto mensual en 12, en euros, y percentil de algunas cantidades):

| Año | Percentil 10 | Mediana | Percentil 90 | 700 € | 1.100 € | 1.500 € | 2.000 € |
|---|---|---|---|---|---|---|---|
| 2015 | 118 | 1.071 | 2.408 | 34,5 | 51,4 | 69,2 | 82,6 |
| 2019 | 179 | 1.202 | 2.541 | 28,1 | 44,7 | 65,6 | 80,0 |
| 2024 | 249 | 1.422 | 2.879 | 21,5 | 33,4 | 54,2 | 73,2 |

- El percentil 10 es bajo porque cuenta a quien trabajó pocos meses.
- Con el alquiler mensual real, la sección mediana de España necesitaba 1.333 € en 2015 (percentil 62,6 de los salarios de España) y 1.900 € en 2024 (percentil 70,5); con el mínimo de 50 m², 867 € (40,7) y 1.217 € (38,1).
- La sección 2807901001 (Madrid) necesitaba, con el alquiler mensual real, 2.667 € en 2015 (percentil 87,2 de los salarios de la Comunidad de Madrid) y 4.256 € en 2024 (percentil 93,9), y con el mínimo de 50 m², 2.000 € (73,9) y 2.967 € (84,1); la 0801901001 (Barcelona), 2.000 € (percentil 79,1 de los de Cataluña) y 2.790 € (85,9), y 1.783 € (73,2) y 2.400 € (78,1).
- **Alternativa descartada** (10-nov-2026): el salario medio estimado (SME) del módulo de año completo (§6.2), que anualiza por días cotizados y deja fuera a quien no llega al SMI. Solo existe de 2019 a 2024, y su percentil 1 queda en el SMI: la sección mediana caía por debajo del percentil 3 todos los años.

### 6.7 Módulo de supuestos

Los supuestos del cálculo están en un solo sitio, `inventario/supuestos.csv` (backlog, tarea 48; plan §7, F3), con su valor por defecto, sus opciones, su unidad, dónde se usan y dónde se decidieron. Lo leen R (`leer_supuestos()`, `supuesto()`; las constantes de los derivados salen de él) y la web, por `web/js/supuestos.js`, que genera `generar_supuestos_js()` (objetivo `fichero_supuestos_js`) y no se edita a mano.

| Supuesto | Por defecto | Opciones | Dónde |
|---|---|---|---|
| Superficie de una persona | 50 m² | 50, 70 o 90 m² en «Tu ficha» | Tartera, mochila y transistor; «Tu ficha» con un sueldo; mínimo teórico del sueldo necesario (21); peso del alquiler en el ingreso (15) |
| Superficie de dos sueldos | 70 m² | 50, 70 o 90 m² | «Tu ficha» con segundo sueldo y la línea de dos sueldos de la ficha |
| Umbral | 30 % | 30 o 40 % | Sueldo necesario (21), con sus dos cifras |
| Tramos de «¿te llega?» | 30 y 40 % | Fijos | Peso del alquiler en el ingreso (15) y barrera para entrar |
| Pagas | 12 | 12 o 14 | «Tu ficha»: la paga × pagas / 12 (§6.1) |
| Segundo sueldo | Ninguno | Opcional | «Tu ficha»: se suma al primero con las mismas pagas y pasa la superficie por defecto a la de dos sueldos |
| Vivienda tipo de la compraventa | 80 m², 80 % financiado a 25 años | Fijos | Indicadores 16 y 17 (§7.7) |

**Superficie típica** (backlog, decisión 5; `superficie_tipica_serpavi()`, objetivo `superficie_tipica`): alquiler mensual mediano / alquiler por m² mediano del SERPAVI, vivienda colectiva, con los dos términos como se publican, por territorio y año, de la sección a la comunidad. Es el cociente de dos medianas, no la mediana de las superficies, y son m² del contrato. Sale de datos que ya están en el pipeline: ni el Catastro de F1 (el pipeline solo guarda de cada edificio sus viviendas y su año) ni los indicadores por sección del Censo 2021 traen la superficie de las viviendas. En 2024, mediana de 82,1 m² en los 2.555 municipios con los dos términos, de 45,8 a 153 m²; 62 m² en Madrid, 66 en Barcelona y 83 en València. Con la de su propio territorio, el mínimo teórico del sueldo necesario es la cifra principal (alquiler mensual real / umbral), salvo el redondeo. En la web (decisión del autor, 11-nov-2026; plan §11, pregunta 59), «Tu ficha» la ofrece como opción, «típica», junto a 50, 70 y 90 m², sin cambiar los 50 m² por defecto: la del territorio que manda, que es el municipio de la sección de la ficha, el territorio elegido o, sin ficha, el municipio del centro de la vista (una sección toma la de su municipio, no la suya). La ficha de municipio la da en una línea. La calcula la página (`superficieTipica` en `web/js/sueldo.js`) con los dos términos que ya exporta.

**Compuerta en una muestra** (`comprobar_supuestos()`, `validacion_supuestos`; §4.1): catorce territorios de 2024 (ocho municipios, cuatro secciones, la provincia y la comunidad de Madrid) × las 40 combinaciones de «Tu ficha» (superficie por defecto, 50, 70, 90 m² o típica, la del municipio en las secciones; umbral del 30 o del 40 %; 12 o 14 pagas; con o sin segundo sueldo) y las tres fichas de una persona. Con los supuestos por defecto, las cuentas de la página reproducen el sueldo necesario (21, sus dos cifras) y el peso del alquiler en el ingreso (15) de la tabla larga (`supuestos_muestra_21`, `supuestos_muestra_15`). Las constantes de R (`supuestos_r`), `web/js/supuestos.js` y los botones de `web/mapa.html`, con la opción «típica» (`supuestos_web`), son los del CSV (`supuestos_inventario`). Los casos de la muestra están en `pruebas/datos/supuestos_muestra.json` (`escribir_muestra_supuestos()`; `supuestos_muestra_fichero` avisa si se apartan del pipeline), y los comprueban `test-supuestos.R` y `pruebas/web/supuestos.test.mjs`: R y la página dan lo mismo en cada combinación. La superficie típica, con `supuestos_superficie_tipica`, `supuestos_superficie_tipica_mediana` y `supuestos_superficie_tipica_rango`.

---

## 7. Alquiler, hogares en alquiler, viviendas turísticas, derivados y sobrecarga

### 7.1 Alquiler (indicadores 8 y 9)

**Fuente.** La base de datos del SERPAVI del MIVAU (`mivau_serpavi`), edición 2011–2024. Es un Excel con una hoja por nivel: comunidades (con el total de España), provincias, municipios, distritos y secciones. Toda la serie está en el seccionado de 2021 (plan §6.3). El fichero se baja a mano (§2.1); la columna `version` lleva su fecha, 6-nov-2026.

**Qué mide.** Contratos de vivienda habitual vigentes declarados en el IRPF y cruzados con el Catastro. Es el parque alquilado, no los contratos nuevos (guía, regla 5).

**Universo** (backlog, tarea 42). Lo fija la metodología oficial del MIVAU de 18 de marzo de 2026 («Sistema Estatal de Referencia del Precio del Alquiler de Vivienda. Explotación estadística de fuentes tributarias. Metodología»), a la que remite la Resolución de 16 de abril de 2026 de la Secretaría de Estado de Vivienda y Agenda Urbana (BOE-A-2026-8691, BOE de 20 de abril de 2026). El PDF se guarda en `datos/brutos/mivau_serpavi/` (`inventario/fuentes.csv`), y las páginas que se citan se comprobaron a mano el 10-nov-2026. El SERPAVI cuenta los inmuebles con ingresos por arrendamiento de titulares que son personas físicas, declarados en el modelo 100 del IRPF (109 en Gipuzkoa) como vivienda habitual del inquilino, no afectos a actividades económicas y sin parentesco entre las partes (pp. 6, 8 y 17). Sus fuentes son solo el IRPF y el Catastro (p. 16). La renta es el ingreso íntegro anualizado declarado, por m² de vivienda sin zonas comunes (p. 9): un contrato de pocos meses se eleva al año. Quedan fuera:
- las sociedades y demás personas jurídicas, también las administraciones y su vivienda pública (p. 6);
- el alquiler no declarado;
- el alquiler a parientes (pp. 6 y 17);
- el que el arrendador declara como actividad económica (pp. 8 y 17);
- los inmuebles de territorio común cuyos titulares residen todos en territorio foral o en el extranjero, y los de declarantes de territorio común situados fuera de él (p. 6);
- los registros erróneos o muy atípicos (p. 6) y los inmuebles cuya superficie construida triplica la de su parcela (p. 17).

El documento no trata las habitaciones, el alquiler de temporada ni la vivienda protegida, ni fija un mínimo de días arrendados.

**Cuánto pesa lo que queda fuera** (`serpavi_contraste_censo()`; objetivo `contraste_serpavi_censo`). No hay tabla abierta del parque alquilado por tipo de arrendador y municipio: el Censo 2021 no distingue al arrendador, y las estadísticas de titularidad del Catastro cuentan todo el parque residencial, no el alquilado. Dos cifras acotan el sesgo:
- en España, el Banco de España estima que las personas jurídicas privadas son dueñas de un 8 % de las viviendas principales en alquiler de mercado, y cifra el alquiler social en unas 300.000 viviendas, el 1,5 % de las principales (Informe Anual 2023, cap. 4, p. 240); no da cifras por municipio;
- en las mismas secciones y el mismo año, el SERPAVI cuenta 2.186.305 viviendas alquiladas (colectiva y unifamiliar) y el Censo, 2.817.666 hogares en alquiler: un 77,6 %, en las 32.084 secciones con las dos cifras, sin País Vasco.

| Provincia | Viviendas del SERPAVI (2021) | Hogares en alquiler (Censo 2021) | SERPAVI / Censo (%) |
|---|---|---|---|
| Melilla | 2.861 | 7.947 | 36,0 |
| Huelva | 9.229 | 24.428 | 37,8 |
| Almería | 21.215 | 41.534 | 51,1 |
| Santa Cruz de Tenerife | 50.265 | 87.604 | 57,4 |
| Ceuta | 2.427 | 4.217 | 57,6 |
| Barcelona | 368.857 | 521.222 | 70,8 |
| Madrid | 450.819 | 525.456 | 85,8 |
| Castellón | 29.550 | 29.048 | 101,7 |
| A Coruña | 64.718 | 62.788 | 103,1 |
| Pontevedra | 43.632 | 41.856 | 104,2 |
| Teruel | 5.451 | 5.010 | 108,8 |
| Salamanca | 17.546 | 14.754 | 118,9 |

La diferencia no aísla a las personas jurídicas: suma todo lo que el SERPAVI deja fuera y diferencias del Censo en los dos sentidos. El Censo cuenta hogares a 1 de enero, con el régimen de tenencia imputado en algo menos de una cuarta parte de ellos (INE, metodología del Censo, p. 86). El SERPAVI cuenta los inmuebles alquilados en algún momento del año, también los de estudiantes empadronados en otro sitio, que el Censo no cuenta como hogares de la sección: por eso pasa del 100 % en provincias universitarias como Salamanca. Por municipio, en los 1.739 con todas sus secciones y al menos 100 hogares en alquiler, la mediana es del 73,3 % (percentil 10, 25,9 %; percentil 90, 117,3 %); 441 quedan por debajo del 50 % y 328 pasan del 100 %. Con esa mezcla, la web no marca municipios: la ficha del indicador (`inventario/indicadores.csv`, columna `lectura`) y esta nota dicen a quién no mide la fuente, y el reparto por tipo de arrendador queda por revisar (§8).

**Lectura** (`leer_mivau_serpavi()`; objetivo `serpavi`, 1.099.500 filas). Una fila por territorio, año (desde 2015) y tipología: vivienda colectiva (`VC`) y unifamiliar o rural (`VU`). Cada fila trae el recuento de testigos y la mediana, el primer y el tercer cuartil del alquiler mensual y del alquiler por m². España sale de la fila sin código de la hoja de comunidades y solo trae el recuento.

**Tabla larga** (`armonizar_mivau_serpavi()`; objetivo `larga_serpavi`, 5.898.530 filas con los auxiliares; plan §6.4):
- indicadores `alquiler_mes` (8) y `alquiler_m2` (9);
- la mediana, en el corte `tipologia`, con los grupos `VC` y `VU`; los cuartiles, en los cortes `tipologia_p25` y `tipologia_p75`, solo donde hay dato;
- como auxiliares, los contratos de cada mediana (`contratos_alquiler`) y su margen aproximado (`margen_alquiler_mes` y `margen_alquiler_m2`; §7.6);
- sin filas `total`: el SERPAVI no publica una mediana conjunta de las dos tipologías (§1);
- niveles: sección, distrito, municipio, provincia y comunidad. España no tiene medianas: solo entra su recuento de contratos (§7.6);
- `geo_ref = 2021`, sin tabla de paso;
- valores con la precisión de la fuente, sin redondear. Los derivados toman el valor redondeado a un decimal, el mismo que recibe la web (§7.4).

**Estados** (`estado_serpavi()`):
- `dato`: mediana publicada;
- `secreto`: de 1 a 9 testigos. La fuente solo publica el recuento; el valor queda vacío, nunca 0;
- `ausente`: sin testigos; provincias forales antes de su entrada (`ENTRADA_SERPAVI_FORALES`: Navarra 2021, Gipuzkoa 2022, Álava y Bizkaia 2024; ruptura `serpavi_forales`); municipios y distritos que no cuadran con sus secciones (plan §11, pregunta 13).

**Cobertura territorial** (`larga_serpavi`, `jerarquia_2021`):
- La base tiene 36.293 de las 36.333 secciones de 2021. Las 40 restantes van como `ausente` en todos los años y tipologías (`completar_secciones_serpavi()`; alerta `serpavi_sin_fila`). 36 son municipios de una sola sección (34 de Navarra, uno de Álava y uno de Bizkaia), que tampoco están en las hojas de municipios y distritos. Las otras 4, de Madrid, Las Palmas de Gran Canaria (2) y Zaragoza, no tienen testigos: su distrito suma lo mismo que sus secciones publicadas. Así, el 8, el 9, el 15 y el 21 tienen fila en las 36.333 secciones, como el 14, el 18 y el 19.
- Quedan fuera 4 municipios y 68 distritos de las hojas que no existen en el seccionado de 2021 (`estado_serpavi()`). Están vacíos de 2015 a 2024; los municipios son 15026, 15063, 36011 y 36012, fusionados en 15902 y 36902 (bloqueo `serpavi_seccionado`).
- Los 36 municipios de una sola sección y sus distritos van también como `ausente`, como municipio y como distrito (alerta `serpavi_sin_fila`; plan §11, pregunta 26). En la tabla larga están los 8.131 municipios y los 10.479 distritos de la jerarquía, 52 provincias y 19 comunidades.

**Errores de las hojas de municipios y distritos** (alerta `serpavi_escalas_detalle`, `descuadres_serpavi()`; plan §11, pregunta 13). Son 164 cifras de territorio, año y tipología que no cuadran con sus secciones. Van como `ausente`, y las secciones conservan su dato:
- en Navarra: 82 municipios de 2022 con la mediana y el P25 de vivienda colectiva cruzados; 18 distritos de 2022 con los recuentos desplazados una fila (31 filas); 40 filas de municipio de 2023 y 2024 sin el recuento que sí tienen sus secciones;
- fuera de Navarra, todas en 2022: 7 municipios con mediana de vivienda unifamiliar y 0 testigos; el distrito 4622101 (2 filas); un recuento no entero en Valmadrid (50275); Cabanes (17030), con un alquiler por m² distinto del de su única sección.

(`inventario/referencias_validacion.csv`.)

**Resultado: secciones por año y tipología** (`resumen_larga_serpavi`; las dos últimas columnas, de `larga_serpavi`). El indicador 9 tiene los mismos estados que el 8.

| Año | `VC`: `dato` | `VC`: `secreto` | `VC`: `ausente` | `VU`: `dato` | `VU`: `secreto` | `VU`: `ausente` | Con alguna mediana | Solo secreto |
|---|---|---|---|---|---|---|---|---|
| 2015 | 21.627 | 5.995 | 8.711 | 5.543 | 15.250 | 15.540 | 23.497 | 7.885 |
| 2016 | 22.051 | 5.749 | 8.533 | 6.065 | 15.073 | 15.195 | 24.086 | 7.474 |
| 2017 | 22.447 | 5.511 | 8.375 | 6.537 | 14.907 | 14.889 | 24.575 | 7.059 |
| 2018 | 22.820 | 5.289 | 8.224 | 6.972 | 14.709 | 14.652 | 25.024 | 6.719 |
| 2019 | 23.136 | 5.123 | 8.074 | 7.430 | 14.443 | 14.460 | 25.444 | 6.391 |
| 2020 | 23.415 | 5.063 | 7.855 | 7.823 | 14.335 | 14.175 | 25.844 | 6.142 |
| 2021 | 23.988 | 5.023 | 7.322 | 8.180 | 14.409 | 13.744 | 26.440 | 6.160 |
| 2022 | 24.671 | 4.954 | 6.708 | 8.386 | 14.528 | 13.419 | 27.192 | 5.995 |
| 2023 | 24.878 | 4.861 | 6.594 | 8.697 | 14.412 | 13.224 | 27.420 | 5.862 |
| 2024 | 26.137 | 4.849 | 5.347 | 9.065 | 14.482 | 12.786 | 28.735 | 5.791 |

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
| Bizkaia | — | — | 92,1 |
| Barcelona | 90,7 | 92,2 | 92,6 |
| Madrid | 92,3 | 94,3 | 95,1 |
| Gipuzkoa | — | — | 95,4 |
| Navarra | — | — | 64,6 |
| Álava | — | — | 80,4 |

«—»: antes de la entrada de la provincia en el SERPAVI. El denominador son las secciones de la provincia en el seccionado de 2021, también las que la base no trae.

**Valores de 2024, vivienda colectiva** (`larga_serpavi`):
- En las 26.137 secciones con dato, la mediana de cada sección va de 150 a 3.504 €/mes. Percentil 10, 370 €; mediana, 570 €; percentil 90, 893 €. En alquiler por m²: 4,2, 7,3 y 12,7 €/m².
- Provincias: Madrid, 800 € y 12,1 €/m²; Barcelona, 753 € y 11,0 €/m²; Bizkaia, 734 € y 10,2 €/m²; Navarra, 598 € y 6,9 €/m².

**Compuerta** (`comprobar_mivau_serpavi()`; §4.1): `serpavi_provincia`, `serpavi_espana`, `serpavi_secreto`, `serpavi_cuartiles`, `serpavi_escalas` y `serpavi_seccionado` (bloqueo), y `serpavi_escalas_detalle`, `serpavi_forales` y `serpavi_sin_fila` (alerta). Las medianas no se agregan: la compuerta suma testigos y comprueba las reglas de la fuente. Los contratos y el margen tienen su propia compuerta, sobre la tabla larga (§7.6).

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

**España, comunidades y provincias** (`territorios_ine_censo2021()`; plan §11, pregunta 25). Son las cifras publicadas en la tabla 59523: España, 100 × 2.983.619 hogares en alquiler / 18.536.616 hogares = 16,10 %; las 19 comunidades y las 52 provincias, del mismo modo (provincias, de 5,7 % en Jaén a 31,6 % en Melilla; comunidades, de 9,1 % en Extremadura a 31,6 % en Melilla). El CSV de indicadores solo trae secciones, y su suma no da estas cifras: faltan las 1.363 en secreto. Ceuta y Melilla salen como comunidad (18 y 19) y como provincia (51 y 52), con la misma cifra; los códigos 18 y 19 de provincia son Granada y Guadalajara, y el nivel los distingue. Compuertas: `censo2021_nacional` (las 52 provincias y las 19 comunidades suman exactamente los hogares y los hogares en alquiler de España) y `censo2021_alquiler` (cada territorio frente a sus secciones, con las secciones en secreto como intervalo; §4.1). Estas 72 filas son `dato` y no llevan seccionado (`geo_ref` vacío).

**Censo 2011** (plan §11, pregunta 14; tarea 47). Indicadores por sección del Censo 2011 (`ine_censo2011`; `paso2011_leer_censo2011()`, objetivo `censo2011`): población (`t1_1`), viviendas (`t16_1`), viviendas principales (`t17_1`) y en alquiler (`t18_4`). Es un censo muestral: cada cifra es una estimación redondeada a múltiplos de 5, y una celda vacía es secreto (menos de 5 unidades muestrales). De las 35.960 secciones del Censo, 35.917 tienen fila; en 8.512 falta el alquiler o las principales.
- **Cálculo en el seccionado de 2021** (`paso2011_reproyectar_censo()`, objetivo `censo2011_2021`): las viviendas principales y las alquiladas pasan como recuentos con la tabla del Censo (§3.11), y el porcentaje se rehace en cada sección de 2021. Estado: el de los recuentos; `secreto` si alguno de sus orígenes no trae los dos recuentos; `ausente` si no recibe nada.
- **Resultado:** `dato`, 23.655 secciones; `estimado`, 3.931; `secreto`, 8.714; `ausente`, 33. Mediana, 9,7 %; percentil 90, 29,6 %; 3.087 secciones con 0 %, por el redondeo de los recuentos pequeños.
- **España, comunidades y provincias** (tabla 02003; `paso2011_leer_tenencia()`, objetivo `censo2011_tenencia`): España, 100 × 2.438.574 / 18.083.692 = 13,48 %. Las comunidades de una provincia dan también la provincia. Compuertas `paso2011_censo_alquiler`, `paso2011_censo_principales` y `paso2011_censo_paso` (§4.1).
- **Dos fotografías** (ruptura `censo_metodo_2021`): el Censo 2011 es muestral y el de 2021 sale de registros.

### 7.3 Viviendas de uso turístico (indicador 19)

**Fuente.** La estadística experimental del INE sobre viviendas turísticas, a partir de los anuncios de las plataformas (`ine_vut`). La tabla 5 (distritos y secciones) es un xlsx por periodo, con 13 periodos semestrales de agosto de 2020 a mayo de 2026 (`PERIODOS_VUT`). Las tablas 39364 (viviendas) y 39365 (porcentaje) dan España, las comunidades y las provincias. La columna `version` lleva la fecha del último fichero, 8-nov-2026.

**Seccionado de cada periodo** (comprobado código a código el 8-nov-2026; ruptura `vut_seccionado_2024` en `inventario/rupturas.csv`):

| Periodos | Secciones del fichero | Denominador del porcentaje del INE |
|---|---|---|
| Agosto de 2020 – febrero de 2023 (6) | 35.960, las del Censo 2011 | Viviendas del Censo 2011 |
| Agosto de 2023 | 37.063 códigos: las del Censo 2011 y otras de seccionados posteriores | Viviendas del Censo 2021 (`inventario/indicadores.csv`) |
| Febrero de 2024 | Seccionado de 2024, más 258 códigos antiguos sin viviendas turísticas | Viviendas del Censo 2021 (`t18_1`) |
| Agosto de 2024 – mayo de 2026 (5) | Seccionado de 2024 (36.477 secciones) | Viviendas del Censo 2021 (`t18_1`) |

**Periodos del atlas** (plan §11, pregunta 14). Los seis del seccionado de 2024, de febrero de 2024 a mayo de 2026 (`PERIODOS_VUT_2024`). Desde la tarea 47, también los seis de agosto de 2020 a febrero de 2023 (`PERIODOS_VUT_2011`), en las secciones del Censo 2011, con su tabla de paso (§3.11; abajo). Agosto de 2023 se lee (`leer_ine_vut()`) y entra en la compuerta de recuentos provinciales, pero no en el indicador: mezcla las secciones del Censo 2011 con las de seccionados posteriores, sin decir qué geografía tiene cada código (por revisar). Se descartó usar el nivel municipal del INE, porque mezclaría escalas en la serie.

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

**Tabla larga** (`armonizar_ine_vut()`; objetivo `larga_vut`, 218.430 filas: 6 periodos por 36.333 secciones, más España, las 19 comunidades y las 52 provincias en cada periodo; plan §6.4):
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

**España, comunidades y provincias** (`territorios_ine_vut()`; plan §11, pregunta 25). El porcentaje publicado en la tabla 39365, con dos decimales, para España, las 19 comunidades y las 52 provincias, en los seis periodos de las secciones; todas las filas son `dato`. España: 1,33 % en febrero de 2024, 1,52 % en agosto de 2024, 1,41 % en noviembre de 2024, 1,43 % en mayo de 2025, 1,24 % en noviembre de 2025 y 1,28 % en mayo de 2026. Provincias, de 0,10 % (Melilla, noviembre de 2025) a 4,96 % (Las Palmas, noviembre de 2025); comunidades, de 0,10 % (Melilla) a 4,71 % (Canarias, noviembre de 2024). Ceuta y Melilla, como en el 18 (§7.2). Los siete periodos anteriores no entran, como en las secciones; hasta febrero de 2023, además, el denominador del INE son las viviendas del Censo 2011. Compuertas (`nacional_vut()`, `territorios_vut()`):
- `vut_nacional_viviendas`: las 52 provincias suman exactamente las viviendas turísticas de España en los 13 periodos;
- `vut_nacional_porcentaje`: la media de los porcentajes provinciales, ponderada con las viviendas del Censo 2021 de cada provincia, se aparta del porcentaje de España entre −0,001 y +0,009 puntos (tolerancia ±0,02: los porcentajes van con dos decimales y las secciones del Censo en secreto no pesan);
- `vut_territorios`: el porcentaje de España, de cada comunidad y de cada provincia frente a 100 × viviendas turísticas de sus secciones / viviendas del Censo 2021, con el denominador que usa el INE en cada periodo. En febrero y agosto de 2024, el INE dividía por las viviendas de las secciones publicadas. Desde noviembre de 2024 cuenta también las de las secciones del Censo en secreto, que no se publican, y la cifra baja hasta 0,11 puntos en las provincias que más tienen (Soria, mayo de 2025: 0,65 % publicado frente a 0,76 % con las secciones con dato). Para esos periodos, el denominador es la tabla 59521 del Censo 2021 (viviendas familiares convencionales por comunidad y provincia, `leer_ine_censo2021_viviendas()`; España, 26.623.708). Coinciden, al redondeo, las 432 cifras: tolerancia ±0,005 puntos, media unidad del último decimal publicado; diferencia máxima, 0,005 puntos (Jaén, febrero de 2024: 0,255 publicado como 0,26). La tabla solo cuenta viviendas convencionales: en 11 provincias las secciones suman algo más (hasta 791 viviendas, en Huelva).

El cambio de denominador de noviembre de 2024 figura como ruptura en `inventario/rupturas.csv` (`vut_denominador_2024`; plan §11, pregunta 35): la tabla larga lleva la cifra del INE de cada periodo, y en los territorios con secciones en secreto la de noviembre de 2024 baja algo frente a la de agosto solo por el denominador.

**Agosto de 2020 a febrero de 2023** (tarea 47; `paso2011_reproyectar_vut()`, objetivo `vut_2011_2021`). Las viviendas turísticas de las secciones del Censo 2011 pasan a 2021 como recuento, con su tabla (`paso_final_2011_vut`; §3.11). El denominador son las viviendas del Censo 2011 (`t16_1`), el del INE en esos periodos, llevadas con la misma tabla. Si la sección de 2021 recibe una sola sección del Censo, entera, se copia el porcentaje del INE (30.250 secciones). Estado: el de los recuentos; `secreto` si el INE protege el porcentaje de alguno de sus orígenes o el Censo 2011 no da sus viviendas; `ausente` si no recibe nada.

| Periodo | `dato` | `estimado` | `secreto` | `ausente` | Viviendas turísticas (España) | Mediana (%) | Percentil 90 | Percentil 99 | Máximo | Secciones con 0 % |
|---|---|---|---|---|---|---|---|---|---|---|
| Agosto de 2020 | 30.574 | 5.427 | 313 | 19 | 321.496 | 0,21 | 2,13 | 11,3 | 82,0 | 12.295 |
| Febrero de 2021 | 30.574 | 5.427 | 313 | 19 | 294.698 | 0,19 | 1,94 | 10,1 | 82,2 | 12.740 |
| Agosto de 2021 | 30.574 | 5.427 | 313 | 19 | 306.974 | 0,19 | 2,00 | 10,5 | 76,5 | 12.708 |
| Febrero de 2022 | 30.574 | 5.427 | 313 | 19 | 285.868 | 0,18 | 1,89 | 9,9 | 72,3 | 13.305 |
| Agosto de 2022 | 30.574 | 5.427 | 313 | 19 | 311.517 | 0,19 | 2,06 | 10,6 | 78,9 | 12.872 |
| Febrero de 2023 | 30.574 | 5.427 | 313 | 19 | 305.135 | 0,20 | 2,01 | 10,4 | 84,3 | 12.660 |

- La suma es la de la tabla 39364, salvo una vivienda turística en agosto de 2022 y en febrero de 2023: la de la sección 1502501002, que no tiene paso (`paso2011_vut_paso`, `paso2011_sin_paso`).
- Las 19 secciones `ausente` son las que la tabla deja sin nada (§3.11).
- España, comunidades y provincias: el porcentaje publicado en la tabla 39365 (`territorios_ine_vut()`). España: 1,28 % en agosto de 2020, 1,17 % en febrero de 2021, 1,22 % en agosto de 2021, 1,13 % en febrero de 2022, 1,24 % en agosto de 2022 y 1,21 % en febrero de 2023. Compuertas `paso2011_vut_denominador` y `paso2011_vut_territorios` (§4.1).
- **Mismo año** (guía, regla 4): viviendas turísticas de 2020–2023 sobre viviendas de 2011, como en el INE. En febrero de 2024 cambian a la vez el seccionado y el denominador (ruptura `vut_seccionado_2024`).

### 7.4 Derivados (indicadores 14, 15 y 21)

**Definición** (plan §5, bloque C; `inventario/indicadores.csv`):

| # | Indicador | Fórmula | Unidad | Términos |
|---|---|---|---|---|
| 14 | Alquiler mediano sobre renta media del barrio (antes, esfuerzo de residentes) | Alquiler mediano mensual × 12 / renta neta media por hogar, del mismo año | % de la renta del hogar | Indicadores 8 y 2 |
| 15 | Peso del alquiler en el ingreso | Alquiler mediano por m² × 50 / ingreso neto mensual de la ficha | % del ingreso de la ficha | Indicador 9 e ingreso de la ficha (§6) |
| 21 | Sueldo neto necesario (mapa por defecto) | Alquiler mensual mediano / 0,30 (umbral cambiable al 40 %); al lado, el mínimo teórico: alquiler mediano por m² × 50 / 0,30 | € netos al mes | Indicadores 8 y 9 |

**Tipología** (plan §11, pregunta 12): el alquiler de los tres es el de la vivienda colectiva (`grupo = VC`).

**Estado** (plan §11, pregunta 15; `peor_estado()`): el peor de sus términos, en el orden `dato` < `estimado` < `secreto` < `ausente`.
- Una sección con el alquiler en secreto queda en `secreto`.
- Con el alquiler `dato` y la renta `estimado`, el esfuerzo queda `estimado`.
- Si falta algún término, `ausente`. Es el caso del peso del alquiler con la mochila en País Vasco, Navarra, Ceuta y Melilla, donde la ficha no tiene ingreso (§6.2).
- En el 15, el ingreso de la ficha no cuenta como término (`estado_peso_alquiler()`; plan §11, pregunta 15 ampliada): el 15 lleva el estado del alquiler, y es `ausente` si la ficha no tiene ingreso. La mochila va como `estimado` (es una estimación, §6.2), y eso se explica una vez, en su método, no en cada sección.
- Cada cifra del 21 tiene un solo término: la principal lleva el estado del indicador 8 y el mínimo de 50 m², el del 9 (en la vivienda colectiva son los mismos en todas las filas).

**Términos redondeados** (plan §11, pregunta 19; `termino_publicado()`). El alquiler, la renta por hogar y el ingreso de la ficha entran en el cálculo redondeados a un decimal con `sprintf("%.1f")` (§0), como los recibe la web. Así, la cifra de R y la que la web recalcula en el navegador coinciden exactamente.

**Mismo año** (guía, regla 4). En el esfuerzo, el SERPAVI y el ADRH coinciden en 2015–2024. El peso del alquiler de la tabla larga usa el ingreso de la ficha del mismo año que el alquiler: la tartera, con el SMI de cada año de 2015 a 2024; el transistor, con la pensión de cada año; la mochila, con la AEAT de cada año. La web hace lo mismo con la ficha elegida (decisión del autor, 9-nov-2026).

**Cómo se leen:**
- El indicador 15 se lee por tramos: hasta el 30 %, del 30 al 40 % y más del 40 %.
- El indicador 21 es el alquiler expresado en otra unidad. El umbral del 30 % se inspira en el criterio de zona tensionada de la Ley 12/2023 (art. 18), que usa la renta del hogar y los suministros; no es ese criterio.
- **Dos cifras en el 21** (decisión 4 del backlog; tarea 40). La principal paga el alquiler mensual mediano de la sección; al lado va siempre el mínimo teórico de 50 m². La superficie implícita de las medianas (alquiler mensual / alquiler por m²) es de unos 79 m² en 2015 y en 2024, y solo el 3,4 % de las secciones baja de 55 m² en 2024: el piso de 50 m² queda por debajo de lo que se alquila. El mapa pinta la principal; el mínimo va en la ficha, el CSV y la portada (por revisar).
- El mapa del 21 se pinta en seis tramos, con cortes nacionales iguales todos los años: 1.000, 1.300, 1.600, 2.000 y 2.600 € con el alquiler mensual real (tarea 40; hasta entonces, 700, 900, 1.100, 1.500 y 2.000 € con 50 m²; plan §11, pregunta 20). La rampa de colores tiene seis pasos que se distinguen también con daltonismo (`rampa_daltonismo`).
- El 15 y el 21 cambian con el umbral; el 15 y el mínimo del 21, con la superficie, y el 15, con el sueldo de «Tu ficha»: la web los recalcula en el navegador (plan §6.6).
- **El 14, solo en la ficha** (decisión 10 del backlog; tarea 41). Divide el alquiler de quien alquila entre la renta media de todos los hogares de la sección, propietarios incluidos, y apenas distingue barrios: en 2024, la mediana es del 18,3 % en el quintil de secciones con menos renta por hogar y del 17,5 % en el de más, y los percentiles 5 y 95 son 11,6 y 25,3 %. Por eso sale del selector del mapa y queda en la ficha de la sección y del municipio, renombrado («alquiler mediano sobre renta media del barrio») y con ese aviso, que lleva también la llave, el mismo cociente (§6.4). Los tramos calculados para un mapa, en el backlog, quedan como referencia.
- **La misma proporción para todos los ingresos** (backlog, tarea 45). El umbral del 30 % trata igual un ingreso bajo y uno alto, y no dice si lo que queda tras pagar la vivienda alcanza para lo demás. Con un ingreso bajo, el resto puede no cubrir los gastos básicos aunque el alquiler no llegue al 30 %; con uno alto, pasar del 30 % aún deja mucho. El enfoque de ingreso residual compara lo que queda con un presupuesto mínimo de los demás gastos según el tamaño y la composición del hogar (Stone, M. E. (2006). «What is housing affordability? The case for the residual income approach». *Housing Policy Debate*, 17(1), 151–184). El atlas da los euros que quedan (§6.1), pero no fija ese presupuesto: la línea de ingreso residual queda para la v1.1 (backlog).

**Cálculo** (`armonizar_derivados()`; objetivo `larga_derivados`, 2.644.824 filas, fuente `calculo_propio`):
- **14** (`calcular_esfuerzo_residentes()`): en las secciones y los municipios, los niveles en que el SERPAVI y el ADRH publican los dos términos (`NIVELES_ESFUERZO`), y en los años con los dos, 2015–2024. Sin desglose.
- **21** (`calcular_sueldo_necesario()`): en todos los niveles del SERPAVI, 2015–2024, con el umbral del 30 %: la cifra principal, con el alquiler mensual mediano, sin desglose, y el mínimo teórico de 50 m², con corte `superficie` y grupo `50` (`CORTE_MINIMO_SUELDO`).
- **15** (`calcular_peso_alquiler_ingreso()`): corte `ficha`, con los grupos `tartera`, `mochila` y `transistor` (2015–2024). La mochila y el transistor, en las provincias y sus secciones, distritos y municipios; la tartera, también en las comunidades. Es un control: la web calcula el peso del alquiler con la ficha elegida.
- **Ingresos de las fichas** (`perfiles_fichas()`; objetivo `perfiles`): la tartera (§6.3); la mochila de cada provincia y año, de 2015 a 2024 (§6.2; 46 provincias con dato y 6 `ausente` cada año); la llave (§6.4); el transistor de cada provincia y año (§6.5).
- **Versión:** la más reciente de sus términos, 7-nov-2026.

**Resultado: alquiler mediano sobre renta media del barrio (14) en las secciones** (`larga_derivados`):

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

- Los tres derivados tienen fila en las 36.333 secciones y en los 8.131 municipios; el 15 y el 21, también en los 10.479 distritos. Los territorios que no están en la base del SERPAVI quedan `ausente` (§7.1).
- El `estimado` viene de la renta reproyectada (§5.4): el alquiler no se reproyecta.
- El sueldo necesario (21) tiene los mismos estados que el alquiler de vivienda colectiva (§7.1), en sus dos cifras.

**Valores de 2024 en las secciones** (`larga_derivados`):

| Indicador | Secciones con valor | Mínimo | Percentil 10 | Mediana | Percentil 90 | Máximo |
|---|---|---|---|---|---|---|
| Alquiler mediano sobre renta media del barrio (%) | 26.125 | 6,2 | 12,6 | 17,6 | 24,0 | 51,3 |
| Sueldo neto necesario, con el alquiler mensual real (€ al mes) | 26.137 | 500 | 1.235 | 1.900 | 2.976 | 11.679 |
| Sueldo neto necesario, mínimo de 50 m² (€ al mes) | 26.137 | 300 | 700 | 1.217 | 2.117 | 4.283 |
| Peso del alquiler con la mochila (%) | 24.117 | 7,2 | 16,8 | 27,5 | 43,7 | 87,9 |
| Peso del alquiler con la tartera, SMI de 2024 (%) | 26.137 | 7,3 | 17,0 | 29,5 | 51,3 | 103,8 |
| Peso del alquiler con el transistor (%) | 26.137 | 6,2 | 14,3 | 23,3 | 37,9 | 73,2 |

**Peso del alquiler con la tartera, la mochila y el transistor en las secciones, cada año con el ingreso de ese año** (`larga_derivados`; mediana y parte de las secciones con valor por encima del 30 %):

| Año | Tartera: mediana (%) | Tartera: más del 30 % | Mochila: mediana (%) | Mochila: más del 30 % | Transistor: mediana (%) | Transistor: más del 30 % |
|---|---|---|---|---|---|---|
| 2015 | 36,7 | 69,2 % | 28,2 | 43,0 % | 22,7 | 21,3 % |
| 2016 | 36,3 | 70,8 % | 28,4 | 43,4 % | 22,6 | 21,3 % |
| 2017 | 34,3 | 63,4 % | 28,2 | 43,3 % | 22,6 | 22,1 % |
| 2018 | 34,2 | 61,9 % | 27,8 | 41,5 % | 22,7 | 23,1 % |
| 2019 | 30,0 | 50,1 % | 28,2 | 43,4 % | 23,2 | 25,7 % |
| 2020 | 28,9 | 46,2 % | 29,7 | 49,1 % | 23,4 | 26,5 % |
| 2021 | 29,7 | 49,0 % | 28,6 | 44,8 % | 23,7 | 26,9 % |
| 2022 | 29,7 | 49,7 % | 27,9 | 41,9 % | 23,8 | 27,2 % |
| 2023 | 28,8 | 47,2 % | 27,4 | 39,9 % | 23,0 | 24,4 % |
| 2024 | 29,5 | 48,4 % | 27,5 | 40,2 % | 23,3 | 24,1 % |

Con la mochila, 7.616 secciones quedan `ausente` en 2024: todas las de País Vasco, Navarra, Ceuta y Melilla, donde la ficha no tiene ingreso, y las que no tienen alquiler.

**Compuerta** (`comprobar_derivados()`, `validacion_derivados`; §4.1): `derivados_terminos`, `derivados_estado`, `derivados_rango`, `perfiles_mochila` y `smi_neto` (bloqueo), y `derivados_rango_detalle` (alerta). Antes, la tartera pasa por `smi_boe`, la mochila por `mochila_cobertura` y el transistor por las del INSS (§6.2, §6.3 y §6.5).

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

**Quintil de renta** (`calcular_sobrecarga_quintil()`, `quintil_renta()`; objetivo `sobrecarga_quintil`; plan §11, pregunta 31). España por quintil de renta disponible equivalente, cada ola de 2023 a 2025: la renta del hogar (HY020) entre sus unidades de consumo (HX240, escala de la OCDE modificada). Los ficheros del INE no traen HX090 ni el factor HY025, que vale 1. Los cortes del 20, 40, 60 y 80 % se calculan sobre toda la población con renta, con el factor de cada persona (RB050). Una renta igual a un corte va al quintil de arriba: en cada ola hay de 2 a 7 personas por corte en ese caso, y con esa regla las cifras coinciden con las de Eurostat (plan §11, pregunta 36). Cada cifra lleva su número de observaciones y la marca de EU-SILC; las 15 son «normal». Solo va a la web: no entra en la tabla larga, porque `inventario/vocabulario.csv` no tiene ese corte. Europa, sin quintil en la v0.0.

Tasa de sobrecarga (%) y, entre paréntesis, personas en la muestra (`sobrecarga_quintil`):

| Ola | QU1 | QU2 | QU3 | QU4 | QU5 |
|---|---|---|---|---|---|
| 2023 | 32,0 (12.210) | 6,4 (12.936) | 2,2 (13.239) | 0,6 (14.274) | 0,1 (14.411) |
| 2024 | 29,6 (12.427) | 6,0 (14.007) | 2,1 (14.459) | 1,0 (15.564) | 0,3 (16.018) |
| 2025 | 27,7 (12.004) | 5,2 (13.298) | 1,9 (14.663) | 0,9 (15.348) | 0,2 (15.848) |

**Compuerta del quintil** (`comprobar_sobrecarga_quintil()`, `validacion_quintil`; §4.1):
- `sobrecarga_quintil_total`: la media de las cinco tasas, ponderada por sus personas, reproduce la tasa total de cada ola (8,24, 7,77 y 7,17 %) sin diferencia;
- `sobrecarga_quintil_reparto` (alerta): cada quintil reúne del 19,95 al 20,05 % de la población con renta;
- `sobrecarga_quintil_eurostat`: cada tasa, sin redondear, frente a la que publica Eurostat para España en `ilc_lvho07b` el mismo año (`descargar_eurostat_quintil()`, objetivo `eurostat_quintil`), con ±0,1 puntos, como el resto de la sobrecarga. Si Eurostat no publica una ola, el proceso se detiene. Cuadran las 15 cifras de 2023 a 2025, y a un decimal son las mismas: diferencia máxima, 0,045 puntos (segundo quintil de 2025: 5,245 frente a 5,2). Con el hogar del corte en el quintil de abajo, el primer quintil de 2025 daba 27,75 %, 27,8 al redondear, frente al 27,7 de Eurostat (plan §11, pregunta 36). Queda una diferencia de fondo, porque Eurostat usa HX090.

**Indicador 23.** Sale de las tablas del módulo de acceso a la vivienda de la ECV 2025: por comunidad, por edad y sexo, y por tenencia (`armonizar_ine_ecv_modulo()`, `armonizar_ine_ecv_modulo_cortes()`).

**Marcas de Eurostat** (`descargar_eurostat_europa()`, columna `bandera`; plan §11, pregunta 27). La consulta de `ilc_lvho07a`, `ilc_lvho07c` y `ilc_lvho07_r` trae la marca de cada cifra: b, ruptura de serie; u, poca fiabilidad; e, estimación; p, provisional. De las 9.690 cifras, 381 llevan «b», 4 «bu», 493 «e», 28 «p» y 34 «u»; ninguna cambió frente a la consulta sin marcas. España solo tiene una ruptura, la del total en 2008. La UE-27 lleva estimaciones («e») en el total de 2014 a 2018 y en el alquiler a precio de mercado de 2010 a 2018. De 2021 a 2025, solo cinco regiones polacas llevan «u», en 2025. La caída del alquiler a precio de mercado en España de 2022 a 2023 (del 39,4 al 30,6 %) no lleva marca. Tampoco 2013, cuando el INE pasa a obtener los ingresos combinando la entrevista con registros administrativos (`ecv_ingresos_2013` en `inventario/rupturas.csv`): la web corta ahí la serie de España como ruptura del atlas, con su propia nota (`rupturas_serie_sobrecarga()`; plan §11, pregunta 34).

**Web** (`exportar_web_sobrecarga()`, `ficheros_web_sobrecarga`). La sección de sobrecarga lee `web/datos/sobrecarga/` (1,1 MB): un JSON con doce vistas del mapa y dos ficheros de geometría NUTS (GISCO 2021 y 2024; © EuroGeographics para los límites administrativos, uso no comercial, fuera de la licencia de los datos; §2.3).
- Toda la población, cada año de 2021 a 2025: el mapa pinta la lista de la escalera (`armar_escalera()`), cada país en su nivel más fino publicado en `ilc_lvho07_r` y sin códigos agrupados. Es NUTS 2, salvo Austria, Albania y Turquía (y Francia desde 2022), que solo publican el país, y Países Bajos, en NUTS 1: van con trama. Las comunidades y España llevan la cifra de los microdatos de 2023 a 2025, que redondeada coincide con la de Eurostat en las 57 comunidades y años.
- Bosnia y Herzegovina, que publica en NUTS 1 en 2022 y 2023, toma la geometría de NUTS 2024, porque NUTS 2021 no la trae (`version_geometria()`; plan §11, pregunta 29); de 2021 a 2023, los países que NUTS 2021 no trae pasan al fondo del mapa. FI19_20, un código agrupado, sigue fuera del mapa y de la escalera.
- Con tenencia (cuatro grupos) o edad (tres), solo 2025: países de Eurostat y comunidades con las tres olas agrupadas.
- Seis tramos, fijos todos los años, de `cortes_web` del indicador 22 en `inventario/indicadores.csv` (`cortes_sobrecarga_web()`; plan §11, pregunta 28): cortes en 4, 6, 8, 10 y 15 %; en el alquiler a precio de mercado, en 15, 20, 25, 30 y 40 %.
- Las cifras van × 10 en enteros. Las del INE llevan su número de personas y hogares y la marca de fiabilidad de EU-SILC, y van sin valor con menos de 20 observaciones. Las de Eurostat llevan su marca, y las «u» van con la trama de las cifras del INE de muestra pequeña.
- La página añade la serie de España y de la UE-27 (Eurostat) desde el primer año publicado: España, 2004 (alquiler a precio de mercado, 2007); UE-27, 2010 (plan §11, pregunta 30). La línea se corta en las rupturas marcadas («b») y, en España, también en 2013, ruptura del atlas que Eurostat no marca, con un punto hueco y una nota bajo el gráfico. Añade también los desgloses anuales de España, con el quintil de renta, y el módulo de acceso (indicador 23).

La compuerta (`comprobar_web_sobrecarga()`, `validacion_web_sobrecarga`; §4.1) vuelve a leer lo escrito y lo compara cifra a cifra con los objetivos del pipeline: `web_sobrecarga_valores` y `web_sobrecarga_muestra` (bloqueo), también con las marcas, los cortes y el quintil, y `web_sobrecarga_geometria` (alerta: 0 en las 12 vistas).

---

### 7.6 Fiabilidad de las medianas del alquiler

**Por qué** (plan §11, preguntas 12 y 15 ampliadas; `docs/especificacion_contratos_margen.md`). `estado` dice si hay cifra, no si es fiable. En 2024, de las 26.137 medianas de vivienda colectiva por sección, 2.360 salen de 10 a 19 contratos y 2.047 de 20 a 29: 4.407 (16,9 %) de menos de 30. La sección típica tiene 72.

**Contratos** (`armonizar_fiabilidad_serpavi()`; indicador auxiliar `contratos_alquiler`, corte `tipologia`, grupos `VC` y `VU`). Es el recuento de testigos del SERPAVI, de la sección a España:
- `dato` cuando la fuente publica un recuento, también 0;
- `ausente` cuando la celda viene vacía o la fila falta, cuando la provincia foral aún no ha entrado o cuando el municipio o el distrito no cuadra con sus secciones: los mismos casos en que la mediana va como `ausente` (§7.1);
- España entra con el recuento que publica el SERPAVI: en 2024, 2.271.987 contratos de vivienda colectiva y 284.591 de unifamiliar. En 2022 y 2023 no cuenta Gipuzkoa, como la fuente (§7.1);
- ninguna sección tiene mediana con menos de 10 contratos (`serpavi_secreto`); los únicos casos de la base son siete municipios de vivienda unifamiliar de 2022, que ya van como `ausente` (§7.1).

**Margen aproximado de la mediana** (`margen_mediana()`; indicadores auxiliares `margen_alquiler_mes` y `margen_alquiler_m2`, fuente `calculo_propio`). Es el error típico relativo de la mediana de n contratos, en %: 1,2533 × σ / (P50 × √n), con σ ≈ (P75 − P25) / 1,349; en total, 0,929 × (P75 − P25) / (P50 × √n).
- Se calcula con los cuartiles del alquiler por m² para el 9, el 15 y el 21, y con los del alquiler mensual para el 8 y el 14, solo donde hay mediana (10 o más contratos).
- Ejemplo: P25 = 8, P50 = 10 y P75 = 12 €/m² con 10 contratos dan ±11,8 %.
- Es una aproximación: supone una distribución regular dentro del territorio y no corrige el sesgo de la fuente (contratos vigentes, no nuevos; §7.1).
- La tabla larga lo guarda sin redondear; la web lo recibe con una décima, la misma cifra que usa R (plan §11, pregunta 19).

**Resultado de 2024 en las secciones** (`resumen_fiabilidad`):

| Tipología | Con mediana | De 10 a 19 contratos | De 20 a 29 | Menos de 30 | Contratos (mediana) | Margen por m² (mediana) | Margen por m² (percentil 90) | Margen mensual (mediana) | Sin mediana: 0 contratos | Sin mediana ni recuento |
|---|---|---|---|---|---|---|---|---|---|---|
| `VC` | 26.137 | 2.360 | 2.047 | 4.407 | 72 | 4,3 % | 9,1 % | 3,6 % | 3.630 | 1.717 |
| `VU` | 9.065 | 4.925 | 1.883 | 6.808 | 18 | 13,4 % | 26,6 % | 11,2 % | 10.064 | 2.722 |

- En la vivienda colectiva, el margen típico baja con los años, del 5,1 % por m² en 2015 al 4,3 % en 2024, porque cada sección tiene más contratos: 51 de mediana en 2015 y 72 en 2024.
- Las 1.717 secciones de colectiva sin recuento en 2024 son las 1.677 que la base trae vacías y las 40 que no trae (§7.1).

**En la ficha de la web** (`web/js/fiabilidad.js`; §9.2):
- bajo la cifra, «Mediana de N contratos · margen aproximado ±X %», con la marca «pocos contratos» por debajo de 30 (`UMBRAL_POCOS_CONTRATOS`, que va en el manifiesto);
- en el sueldo necesario y en los mapas del alquiler, el intervalo de la cifra con ese margen;
- en «¿te llega?», los tres tramos no cambian: si el intervalo de la proporción cruza el 30 o el 40 %, la ficha dice que está en el límite entre dos tramos, también con «Tu ficha» y con el umbral del 40 %;
- sin mediana: con 1 a 9 contratos, cuántos hay; con 0, «sin contratos de alquiler de pisos registrados» (o de viviendas unifamiliares) en lugar de «sin dato», y un contexto rotulado que nunca se pinta en el mapa (guía, regla 1): la mediana de la otra tipología en la sección y la de la misma tipología en su municipio;
- el mapa no cambia: sin una prueba visual que lo justifique, las secciones con pocos contratos no se atenúan, y la marca va en la ficha y en el CSV;
- en la evolución (backlog, tarea 43; `web/js/evolucion.js`), un gráfico de la serie del mapa con la banda del margen (la cifra ± su margen, donde la ficha da el intervalo: los mapas del alquiler en cualquier unidad y «¿te llega?») y un punto hueco en los años con menos de 30 contratos. En la tabla, la variación de un año solo sale con 30 contratos o más en los dos años; si no, la variación media anual de los tres últimos años, marcada con «†», o ninguna («—») si falta la cifra de tres años antes. Los contratos y el margen de cada año se leen de los ficheros de cada periodo (§9.2).

**Compuerta** (`comprobar_fiabilidad_serpavi()`, `validacion_fiabilidad`; §4.1): `contratos_mediana` y `contratos_suma` (bloqueo), y `margen_rango` (alerta). El margen solo se comprueba en las secciones: en los territorios grandes baja de forma natural del 1 % (en las provincias, 0,3 % de mediana).

### 7.7 Compraventa (indicadores 10, 12, 16 y 17)

**Notariado: sin autorización; el indicador 11, de Registradores.** Las webs del Notariado reservan sus derechos: los términos y condiciones del Portal Estadístico y su aviso legal (verificados el 10-nov-2026) dejan los datos para uso personal y piden la autorización previa y expresa del Consejo General del Notariado para reproducirlos, distribuirlos o transformarlos, aunque se cite la procedencia. El atlas no descarga sus cifras (`inventario/fuentes.csv`, `notariado`). Decisión del autor (10-nov-2026): el precio de compraventa por m² (indicador 11) sale de Registradores, por provincia, sin mezclarse con el Notariado. Las escrituras llegan por otra vía: el MIVAU publica, con sus propias condiciones de reutilización, el valor medio de las compraventas de vivienda libre ante notario (`mivau_transacciones`), sin la superficie, y sirve para la compuerta de coherencia.

**Precio de compraventa por m² (indicador 11), de Registradores** (`R/fuente_registradores.R`; plan §11, pregunta 45 a revisada). Estadística Registral Inmobiliaria del Colegio de Registradores, datos abiertos con licencia ODbL (§2.2): compraventas de vivienda inscritas, importe medio y precio medio por m², por trimestre, de España, las 19 comunidades y las 52 provincias, desde 2007. Nivel: provincia, el más fino que publica la fuente abierta (decisión del autor, 10-nov-2026, que sustituye al municipio de la pregunta 45); la comunidad y España, con su cifra publicada (regla 1). Cada trimestre acumula los cuatro últimos, así que el año es el cuarto trimestre: el precio medio por m² de las compraventas del año natural (`registradores_anual()`), de 2015 a 2025 (`registradores_armonizar()`). No se mezcla con el Notariado, que mide otra superficie: en España, en 2025, 2.284 €/m² frente a 1.902 €/m² (plan, pregunta 45). Fichero manual (§2.1): lector (`registradores_leer()`), compuerta (`registradores_comprobar()`, §4.2) y pruebas con un CSV inventado del mismo formato (`pruebas/datos/registradores_inventado.csv`); en el pipeline desde el 11-nov-2026 (objetivos `fichero_registradores`, `registradores`, `validacion_registradores` y `larga_registradores`, dentro de `larga_compraventa`): 52 provincias, 19 comunidades y España, de 2015 a 2025, todas `dato`. Con el fichero publicado (de 2007 al segundo trimestre de 2026), España da 2.283,52 €/m² en 2025; las compraventas de las provincias suman las de sus comunidades y las de España en todos los trimestres, y el precio por m² de España y de las comunidades se aparta de la media de sus provincias ponderada por compraventas entre un −0,6 y un +1,5 % (la fuente no da los m², así que no es una identidad).

**Coherencia del valor tasado con Registradores** (`registradores_coherencia_tasado()`; pregunta 45 b). Precio por m² de Registradores entre el valor tasado por m² del MIVAU, mismo territorio y año, provincia frente a provincia: €/m² frente a €/m². Con el fichero publicado, de 2015 a 2025: España, de 0,99 (2015) a 1,12 (2022); provincias, de 0,74 (Badajoz, 2015) a 1,41 (Santa Cruz de Tenerife, 2022). Umbral: España, de 0,85 a 1,25; provincias, de 0,6 a 1,6, con un 5 % fuera como máximo (bloqueo), y aviso fuera de 0,7–1,4. Sigue también la coherencia por superficie implícita con las escrituras del MIVAU (abajo).

**Variación anual del alquiler (indicador 10).** Cifra publicada por el IPVA del INE (`leer_ine_ipva()`; objetivo `larga_ipva`) en su nivel nativo: España, 17 comunidades, 48 provincias, 718 municipios de más de 10.000 habitantes y 407 distritos de las capitales, todos en el seccionado de 2021. Sin País Vasco ni Navarra: el IPVA sale del IRPF de régimen común. Las filas «Resto» de cada provincia no entran. Es un índice: no se agrega ni se reproyecta (guía, regla 1). En 2024, España sube un 3,5 %, con una mediana municipal del 3,3 %.

**Contratos nuevos y existentes (indicador 10, corte `contrato`; backlog, tarea 36).** Desde la edición de 2021, el IPVA separa los contratos nuevos de los existentes en España y las comunidades (tabla 59004) y en las provincias (tabla 59005), de 2021 a 2024; no lo publica por municipio ni por distrito. `armonizar_ine_ipva()` añade a la tabla larga la variación anual publicada de cada grupo (`nuevo` y `existente`) en España, 17 comunidades y 48 provincias; el total sigue saliendo de las tablas generales. Lo que dice el INE (proyecto técnico del IPVA, junio de 2023):
- **Contrato nuevo:** el que tiene como año de contrato el de referencia, con la fecha del contrato que las bases de la AEAT recogen desde 2019; los demás son existentes. Los ingresos declarados son del año completo: si una vivienda tuvo dos contratos en el año, su precio anual incluye los dos, y la variación solo recoge una parte del efecto del cambio de contrato.
- **Base:** los índices publicados están en base 2015 = 100, encadenando los índices de cada año sobre el anterior. La antigüedad del contrato entra en los estratos desde 2021, y el documento no dice cómo se enlaza el desglose con la base. Las cifras lo aclaran: el índice de 2021 de cada grupo es el índice general de 2020 por la variación del grupo, en España, en las 17 comunidades y en las 48 provincias (`ipva_contrato_enlace`, diferencia máxima de 0,049 puntos). Antes de 2021, el desglose no existe.

En España, de 2021 a 2024, los contratos nuevos suben un 19,3 % (índice de 114,871 a 137,041) y los existentes, un 7,5 % (de 112,229 a 120,637), frente al 9,1 % del total (de 112,694 a 122,920); en 2024, un 8,8 y un 2,8 %. Es un índice, no un precio: no da el alquiler de quien entra y no se mezcla con la oferta (§1). Los contratos nuevos son de la familia «entrar» y los existentes, de «quedarse», pero la columna `familia_alquiler` es una por indicador y el 10 sigue en «quedarse» (por revisar). La web no exporta el corte: no tiene mapa.

**Valor tasado (indicador 12).** Valor medio de tasación de la vivienda libre por m² del MIVAU, trimestral, de España, las comunidades, las provincias y los municipios de más de 25.000 habitantes (306 desde 2020). El año es la media de sus cuatro trimestres ponderada por el número de tasaciones (`valor_tasado_anual()`); sin los cuatro, `ausente` (de 3 a 9 municipios al año hasta 2020). El Ministerio no publica media anual ni pondera sus comunidades por tasaciones: la comunidad publicada se aparta de la media de sus provincias ponderada así hasta un 3,3 % (`valor_tasado_ccaa_media`), por composición, pero nunca sale del intervalo de sus provincias (`valor_tasado_ccaa`). Los nombres del Ministerio se casan con los códigos del INE por su forma normalizada (`casar_nombres_mivau()`), por un nombre único en España cuando la tabla de municipios arrastra mal la provincia (siete municipios) y por `inventario/nombres_mivau.csv` (erratas y nombres distintos). España: 1.475,6 €/m² en 2015 y 1.913,9 €/m² en 2024.

**Coherencia entre escrituras y tasación** (`comprobar_coherencia_compraventa()`, `validacion_coherencia_compraventa`; el «hecho cuando» de F4). Las dos fuentes no comparten unidad: el valor medio escriturado es por vivienda y el tasado, por m². Su cociente es la superficie que tendría la vivienda media vendida si se pagara al valor tasado: la «superficie implícita». Si las dos miden el mismo mercado, cae cerca de la superficie media de las viviendas vendidas, algo por debajo, porque el precio escriturado suele quedar por debajo de la tasación; un error de lectura, de unidad o de casado la saca de golpe de ese entorno. Umbral: de 70 a 110 m² en España, cada año, y de 50 a 150 m² en provincias y trimestres, con un 5 % fuera como máximo. Resultado: España, de 91,8 a 106,1 m² (2015–2025); en provincias, un 1,9 % fuera como máximo (2021), con Baleares por encima de 150 m² en 2021 y 2022.

**Tipo medio** (`ine_hipotecas`; objetivo `tipo_hipotecario_anual`). Tipo de interés medio al inicio de las hipotecas sobre viviendas del INE, anual: 3,31 % en 2015, 1,92 % en 2021 y 3,26 % en 2024. Desde el 11-nov-2026 solo sirve a su compuerta (`validacion_hipotecas`).

**Tipo del Banco de España** (`compraventa_tipo_bde()`; objetivo `tipo_bde_anual`; plan §11, pregunta 45 e revisada). El de los préstamos nuevos para adquisición de vivienda de los hogares (`D_IMVTIPLV`, §7.9), el mismo con que el Banco de España calcula su esfuerzo teórico; el año, la media de sus doce meses, a dos decimales con el empate hacia arriba sobre la cifra decimal (`redondear_empate_arriba()`; decisión del autor, 11-nov-2026, plan §11, pregunta 59 b): 2,50 % en 2015, 1,62 % en 2021 y 3,47 % en 2024. La media de 2024 es exactamente 3,465, y `sprintf("%.2f")`, con el que se redondeaba antes, la dejaba en 3,46 porque el binario la guarda por debajo; de 2011 a 2025 es el único empate.

**Derivados** (`armonizar_derivados_compraventa()`; objetivo `derivados_compraventa`, fuente `calculo_propio`). Con el valor tasado de 80 m², del mismo año que el otro término (regla 4):
- años de salario para comprar (16): valor tasado × 80 / salario medio anual bruto por asalariado de la AEAT (indicador 7); en un municipio, el de su provincia;
- esfuerzo hipotecario teórico (17): cuota del primer año de un préstamo francés por el 80 % del valor, a 25 años y al tipo del Banco de España del año (`cuota_hipoteca()`), × 12 / renta neta media por hogar del ADRH × 100 (plan §11, pregunta 45 d revisada; `compraventa_renta_hogar()`, objetivo `renta_hogar_17`). En cada nivel, la renta que publica el INE: la del municipio y, desde el 11-nov-2026, la de la provincia, la comunidad y España, de la tabla de totales 53689 (`renta_hogar_publicada`; regla 1: hay cifra publicada y manda). Donde el INE no la publica (Navarra de 2015 a 2020, Álava de 2015 a 2019, Gipuzkoa en 2015, sus comunidades y España hasta 2020: 29 cifras), la provincia y la comunidad quedan `ausente`, sin cifra, porque la cobertura municipal es parcial (Navarra de 2017 a 2019, unos 60 de sus 272 municipios), y España lleva la media de sus municipios ponderada por sus hogares (población / tamaño medio del hogar de sus secciones), `estimado` (decisión del autor, 11-nov-2026). Compuerta `validacion_renta_hogar_publicada` (§4.1): la media agregada se aparta de la publicada un 0,13 % como máximo en la mediana de cada año y nivel, y en 6 de 691 cifras más de un 1 % (Guadalajara de 2015 a 2019 y Sevilla en 2016).

De 2015 a 2024, en España, las comunidades, las provincias y los municipios de más de 25.000 habitantes. El 16, sin salario de la AEAT (País Vasco y Navarra), `ausente`; el 17 tiene también los forales, con la renta del ADRH. Estado: el peor de sus términos (el 17 de provincias, comunidades y España, `dato` donde el INE publica la renta: 508 provincias, 179 comunidades y España de 2021 a 2024; España de 2015 a 2020, `estimado`; 12 provincias y 11 comunidades, `ausente`). En España, 6,3 años en 2015 y 6,1 en 2024 (16), y 17,8 % en 2015 (`estimado`) y 18,1 % en 2024 (17; con el tipo a 3,46 %, 18,0 %; con la renta agregada de los municipios, 15,3 % en 2021 frente a 15,2 % con la publicada; con el salario de la AEAT y el tipo del INE daba 29,8 y 28,7 %); entre los municipios de 2024, de 2,2 a 17,9 años (mediana, 5,3) y del 6,8 % (Puertollano) al 39,8 % (Santa Eulària des Riu), con una mediana del 15,4 %. Compuerta: `compraventa_terminos`, `compraventa_estado` y `compraventa_rango` (bloqueo), y `compraventa_rango_detalle` (alerta).

**Código postal ↔ municipio** (`leer_ine_callejero_cp()`, `geo_tabla_cp_municipio()`; objetivo `fichero_cp_municipio`, en `geo/codigos_postales_2021.csv`). Sale de los tramos de vía del callejero de enero de 2021: 11.046 códigos postales en 14.600 pares, que cubren los 8.131 municipios; 8.784 códigos postales caen en un solo municipio. El peso es la parte de los tramos del código postal en cada municipio. 50 pares tienen un código postal de otra provincia: enclaves como el condado de Treviño, con los de Álava, y erratas del callejero.

**Web.** Desde el 10-nov-2026, los cuatro tienen mapa municipal sin sección (§9.2), con cortes por revisar: 0 · 1 · 2 · 3 · 4 % (10), 1.000 · 1.500 · 2.000 · 2.500 · 3.500 € por m² (12), 3 · 4 · 5 · 7 · 10 años (16) y 15 · 20 · 25 · 30 · 40 % (17). Desde la tarea 51, siete tramos con un juego por municipio y otro por provincia y comunidad (§9.2). El 11 (Registradores), desde el 11-nov-2026, mapa provincial a toda escala, con municipios y secciones apagados (`nivel_minimo` «provincia»), y siete tramos con cortes en 950 · 1.200 · 1.400 · 1.650 · 1.950 · 2.550 € por m² (juego `provincia_ccaa` de `inventario/cortes_web_niveles.csv`, septiles de las provincias en 2025; tarea 51); en `cortes_web`, 1.000 · 1.250 · 1.500 · 2.000 · 2.500.

### 7.8 Presión: zonas tensionadas (indicador 20) y precios de oferta (indicador 13)

**Zonas de mercado residencial tensionado (indicador 20).** La Ley 12/2023, por el derecho a la vivienda, deja la declaración en manos de la comunidad autónoma y obliga al Ministerio de Vivienda y Agenda Urbana a publicar cada trimestre en el BOE una resolución con la relación de zonas declaradas, su periodo de vigencia y el enlace a la declaración de la comunidad (art. 18, apartado 2.d). Esas resoluciones son la fuente del atlas (`zonas_tensionadas`): 10, de la del 15 de marzo de 2024 (`BOE-A-2024-5214`) a la del 3 de noviembre de 2026 (`BOE-A-2026-23088`), localizadas recorriendo los sumarios del BOE desde la entrada en vigor de la ley; una corrección de erratas (`BOE-A-2025-20246`) solo cambia enlaces. Todas fijan la misma vigencia: tres años desde el día siguiente a la publicación de la resolución; el plazo acaba el mismo día del año de vencimiento (Ley 39/2015, art. 30, apartado 4). Ninguna vence antes del 15 de marzo de 2027.

**Inventario y compuerta.** Las decisiones están en `inventario/zonas_tensionadas.csv`: una fila por municipio y declaración, 321 filas y 320 municipios (Llanes tiene dos declaraciones de núcleos distintos), con el nombre literal del BOE, el código y el nombre del INE, el ámbito, las fechas y los enlaces a la resolución y a la declaración de la comunidad. `descargar_zonas_tensionadas()` baja el XML de cada resolución y `leer_boe_zonas_tensionadas()` lee sus tablas; la compuerta (`comprobar_zonas_tensionadas()`, objetivo `validacion_zonas_tensionadas`, toda de bloqueo) exige que cada fila tenga su resolución descargada y su fecha de publicación, un código de municipio del seccionado de 2021 con su nombre del INE y en la comunidad de su fila del BOE, el nombre literal en la tabla de su resolución, que ningún nombre de las tablas quede fuera del inventario, la fecha de efecto el día siguiente a la publicación y la de fin, la que fija el texto. El BOE omite una coma entre Manresa y el Masnou (`BOE-A-2024-5214`) y parte por su coma el nombre de Castell d'Aro, Platja d'Aro i S'Agaró (`BOE-A-2024-20576`): el inventario lleva los nombres como están y la compuerta los encuentra. Para añadir resoluciones, `proponer_zonas_tensionadas()` propone los códigos casando los nombres normalizados (artículos pospuestos, formas bilingües) con los del INE de su comunidad; se revisan a mano. **Prórrogas** (plan §11, pregunta 46 e): la declaración dura tres años y puede prorrogarse (art. 18, apartado 3), y la prórroga llega al BOE como una resolución nueva. Va como una fila más, con la columna opcional `prorroga_de` (la resolución de la declaración que prorroga, del mismo municipio y ámbito). Si su texto cuenta el periodo desde el fin del anterior, la compuerta lo comprueba así (`zt_desde_publicacion()`), y también que la prórroga tenga una declaración anterior y no llegue con ella ya vencida; la situación a 31 de diciembre junta todos los periodos del municipio. A 10-nov-2026 no hay ninguna: las primeras declaraciones vencen el 15-mar-2027.

**Ámbitos que no son un municipio entero.** Ocho declaraciones cubren solo una parte: el distrito 2 de Galdakao, Vitoria-Gasteiz salvo la zona rural de las entidades locales menores, núcleos de Llanes (dos declaraciones) y de Cabrales, los barrios de La Arena y Cimadevilla en Gijón, el de La Magdalena en Avilés y Luanco en Gozón. El BOE no da su geometría, que tampoco coincide con las secciones censales, así que el mapa pinta el municipio entero con una categoría propia, «declarada en parte del municipio», y la ficha da el ámbito literal.

**Tabla larga** (`armonizar_zonas_tensionadas()`; objetivo `larga_zonas_tensionadas`). Los 8.131 municipios del seccionado de 2021, de 2024 a 2026, con la situación a 31 de diciembre de cada año: 2 si está en vigor una declaración de todo el municipio, 1 si solo de una parte, 0 si ninguna, también como `dato`, porque que no haya declaración es un hecho publicado. Sin desglose ni otros niveles: un recuento de municipios no es la cifra de ninguna fuente. Resultado: 271 municipios declarados en 2024, todos de Cataluña; 304 en 2025 (302 enteros y 2 en parte), y 320 en 2026 (313 enteros y 7 en parte): Cataluña 271, Navarra 21, País Vasco 21, Asturias 5 y Galicia 2.

**Web.** Mapa municipal a toda escala con las tres categorías (§9.2). La ficha del municipio lista sus declaraciones (resolución del BOE, ámbito, vigencia y declaración de la comunidad, con sus enlaces; `datos/zonas_tensionadas.json`, compuerta `web_zonas_tensionadas`) y dice que es una capa de política pública, no una medida del mercado.

**Precios de oferta de los portales (indicador 13), capa desmontable y solo web** (plan §2.2; guía, regla 6; backlog, decisión 3 y tarea 35). El pipeline no descarga nada de los portales. Con la variable de entorno `PORTALES=TRUE` (por defecto, apagada) lee, fuera de git, la extracción que el autor hace de los informes de alquiler de la sala de prensa de Idealista, en `datos/brutos/portales/idealista/` (136.816 cifras mensuales de €/m², de enero de 2006 a octubre de 2026, y 816 territorios con su dirección), y los CSV que se copien a mano con el formato de la capa (`R/fuente_portales.R`: portal, operación, nivel, código del INE, zona, nombre, periodo, precio por m², informe y enlace; la venta y Fotocasa quedan para la v1.1, sin datos). Cada territorio de Idealista se casa con su código del INE por su dirección en `inventario/portales_idealista_territorios.csv`, casada por nombre y revisada a mano: España, 19 comunidades (Ceuta solo tiene página de comunidad), 51 provincias, 286 municipios, 449 zonas y 10 localidades que Idealista lista como municipio sin serlo (`idealista_convertir()`).
- **Valor anual:** la media de los meses publicados, con 9 como mínimo; con menos, el año queda `ausente` (`anualizar_portales()`). Sustituye a la regla anterior, el último mes publicado del año, que deja de usarse. La media se redondea a dos decimales con los empates hacia arriba (7,575 da 7,58). El último año es la media de enero a octubre de 2026; la web dice hasta qué mes llega (`ultimo_mes`).
- **Niveles:** España, comunidades, provincias y municipios, de 2015 a 2026, cada uno con la cifra que Idealista publica para él (regla 1): nada se agrega ni se reparte. Municipios con dato: 262 en 2015, 259 en 2024 y 255 en 2026. Las zonas de Idealista no son distritos del INE: se guardan con su municipio, sin geometría, en una lista para la ficha del municipio (`portales_zonas()`). Las ocho localidades con un solo municipio van en esa lista, como zonas; La Alcaidesa y La Manga del Mar Menor, que tocan dos municipios, no se exportan. Con algún dato desde 2015: 441 zonas y siete localidades, en 150 municipios.
- **Solo web:** la capa no entra en la tabla larga ni en lo que cuelga de ella, ni en las descargas (CSV de la web y Parquet), ni en el *release*: encenderla o apagarla no cambia la tabla larga. Sale a una carpeta propia, `datos/portales/` (`portales_exportar_web()`), con su manifiesto, los valores por nivel y año, el enlace al informe de cada cifra y las zonas por municipio; la web suma sus series a las del manifiesto general al cargar. Apagada, la carpeta solo lleva un manifiesto vacío (`portales_apagar_web()`). En la web, un mapa municipal por operación y portal, con la etiqueta «dato privado de oferta» sobre el mapa, en la leyenda, la ficha y el PNG; el CSV no se ofrece. Nunca se mezcla un portal con otro ni la oferta con el SERPAVI, la tasación o las escrituras (regla 5).
- **Compuerta** (bloqueo): `portales_formato`, `portales_codigos`, `portales_rango`, `portales_repetidas` (sin meses duplicados), `portales_idealista_casados`, `portales_idealista_espana` (España: 7,58 €/m² en 2015 y 13,06 en 2024), `portales_idealista_municipios` (278 de los 286 municipios, con serie desde 2015 o antes) y `web_portales`. Probada también con datos inventados en `pruebas/` (`test-portales.R`).
- **Qué mide** (metodología de Idealista de 30 de julio de 2026): el precio de oferta de los anuncios activos en los tres meses anteriores, sin alquiler de temporada ni anuncios duplicados; la mediana de cada zona final, agregada hacia arriba con pesos por número de anuncios. Los meses sin muestra suficiente de una zona se estiman desde los cercanos. El método de julio de 2026 se aplicó hacia atrás donde la serie lo requería, sin decir desde cuándo.

**Indicadores de «entrar», solo por tramos** (backlog, decisiones 1, 5, 9 y 18, y tarea 37; `R/derivados_entrar.R`). Con la capa encendida, el pipeline compara la oferta de Idealista (media anual, arriba) con el parque del SERPAVI (mediana de la vivienda colectiva, §7.1) y con el ingreso de las fichas (§6), por territorio y año, con los términos como los recibe la web (`termino_publicado()`; `entrar_terminos()`, `entrar_calcular()`):
- **Superficie típica:** alquiler mensual mediano / alquiler por m² mediano del SERPAVI. Es el cociente de dos medianas, no la mediana de las superficies, y son m² del contrato, no los del anuncio: la ficha lo dice. Mediana de 77 m² en los municipios con oferta y SERPAVI en 2024.
- **Brecha entre entrar y quedarse** (`brecha_entrar_quedarse`): oferta / alquiler por m² mediano del SERPAVI, en comunidades, provincias y municipios (el SERPAVI no da España). Compara dos fuentes que miden cosas distintas, el anuncio y el contrato vigente, y lo dice; no las mezcla en una cifra (regla 5). Municipios con las dos el mismo año: 256 en 2015 y 259 en 2024. Con 2 o más, la ficha avisa: en los municipios turísticos la oferta puede llevar alquiler de temporada y vivienda de gama alta, que el SERPAVI no recoge.
- **Sueldo para entrar** (`sueldo_entrar`): oferta × superficie típica / 0,30, y su mínimo con 50 m² (`sueldo_entrar_50`). **Barrera para entrar** (`barrera_entrar`): oferta × 50 / ingreso neto mensual de la tartera, la mochila o el transistor del mismo año (regla 4), × 100, con el estado de la oferta, o `ausente` sin ingreso (`estado_peso_alquiler()`). Sin informe del portal o sin SERPAVI ese año, `ausente`.
- **Solo por tramos** (decisión 18). Las cifras exactas no salen del pipeline: con ellas se reconstruye la oferta (la brecha, por el alquiler del SERPAVI, que es público; el sueldo de 50 m², por 0,30 / 50). Tampoco sirven varios juegos de tramos, uno por indicador: cada indicador es la oferta por una cifra pública distinta en cada territorio, así que cada juego corta la oferta por otro sitio y, juntos, la acotan mucho más que cualquiera de ellos. A la web solo llega el tramo de la brecha (`entrar_tramos_web()`): seis tramos, con cortes en 1; 1,15; 1,35; 1,6 y 2, y los límites de la compuerta, 0,8 y 2,5, en los extremos (`inventario/entrar_tramos.csv`, por revisar). Cada tramo abarca al menos un 15 %: con el alquiler del SERPAVI, acota la oferta como mucho a ±7 % de su centro.
- **Lo demás, en intervalo:** el sueldo para entrar, el de 50 m² y la barrera para entrar son la brecha por una cifra pública de «quedarse» (el sueldo necesario, indicador 21, con sus dos cifras: el alquiler mensual mediano / 0,30 y el mínimo de 50 m²; el peso del alquiler en el ingreso, indicador 15), así que la web los da como los límites del tramo por esa cifra (`entrar_intervalo()`), que no dicen nada que no diga el tramo. La barrera se lee con los tramos de «¿te llega?» (hasta el 30 %, del 30 al 40 % y más del 40 %) y, si el intervalo cruza un corte, «en el límite» (`entrar_llega()`). Igual con el sueldo que escribe el usuario («Tu ficha»), que así no necesita la oferta exacta en el navegador.
- **Web:** `datos/portales/entrar/`, dentro de la capa (`entrar_escribir_web()`): un fichero por nivel y año con el tramo de cada territorio, y la entrada `entrar` del manifiesto de la capa. Ni en la tabla larga, ni en las descargas, ni en el *release*. La interfaz es de las tareas 38 y 39.
- **Compuerta** (`entrar_comprobar()`, `entrar_comprobar_web()`; §4.1). De bloqueo: `entrar_tramos` (ancho mínimo, y derivados sin cortes propios), `entrar_rango` (brechas fuera de 0,8–2,5), `entrar_estado`, `entrar_coherencia` (cada cifra exacta, dentro del intervalo de su tramo), `entrar_municipios`, `entrar_mediana`, `entrar_mediana_rango` (la mediana de 2024, entre 1,30 y 1,40), `entrar_superficie` y `web_entrar` (ida y vuelta de los tramos y ningún valor que no sea un tramo). De aviso: `entrar_rango_detalle` (cada brecha de 2 o más) y `entrar_ipva`, el contraste de la tarea 36: provincias donde la oferta crece de 2021 a 2024 más del doble que los contratos nuevos del IPVA (§7.7), con sus variaciones anuales encadenadas. R y la página hacen las mismas cuentas: `test-entrar.R` y `pruebas/web/entrar.test.mjs` comparten los casos inventados de `pruebas/datos/entrar_inventado.json`.

### 7.9 Módulo histórico: «máquina del tiempo» (F6)

**Tabla propia, no la tabla larga.** Las series del módulo son nacionales (el valor tasado, también de comunidad), trimestrales, mensuales o anuales, y no bajan a la sección censal. El `anio` de la tabla larga es anual: meter trimestres o meses obligaría a promediarlos o a mezclar periodos en un mismo año (regla 4). Van en una tabla propia (`hist_armar()`; objetivo `historico`, también en `datos/intermedios/historico.parquet`) con `serie`, `geo_id`, `nivel`, `frecuencia`, `anio`, `subperiodo` (trimestre, mes o 0), `valor`, `unidad`, `fuente`, `codigo` y `version`, y la rejilla de periodos completa del primer dato al último (`hist_completar()`). Cada serie conserva su fuente, su unidad y su periodo: no se combinan en un indicador (reglas 4 y 5). La tabla entra en el paquete del *release* de la v1.0 como `historico.parquet`, en `descargas/` (`empaquetar_publicacion()`; plan §11, pregunta 47 a).

**Accesibilidad del Banco de España** (`bde_accesibilidad`; `hist_leer_bde_tablas()`, objetivo `series_bde`). Tabla «Indicadores del mercado inmobiliario» de la Síntesis de indicadores (`si_1_5`), en CSV de dirección estable, trimestral desde el 1.er trimestre de 1987:
- años de renta (`D_TKB57110_IPV`): precio medio de una vivienda libre tipo (93,75 m² hasta 2004, por interpolación; después, la superficie media de las compraventas registradas) entre la renta bruta estimada del hogar mediano, que el Banco de España saca de la Encuesta Financiera de las Familias, interpolada y extrapolada con la Contabilidad Nacional y la EPA;
- esfuerzo teórico anual sin deducciones (`D_TKB57210_IPV`): cuotas del primer año de un préstamo por el 80 % del valor, sistema francés, al tipo medio de los préstamos nuevos para vivienda y al plazo medio de las hipotecas, en porcentaje de la renta disponible del hogar mediano.

La serie con la deducción por vivienda habitual (vigente hasta diciembre de 2012), que cita la nota metodológica del Banco de España, no está ni en el CSV ni en su API: el atlas solo tiene la serie sin deducciones. El Banco de España no publica estos indicadores por comunidad. Ruptura `bde_tipo_circular_2003`: el tipo de los préstamos nuevos con que se calcula el esfuerzo se declara con la Circular 8/1990 hasta diciembre de 2002 y con la 4/2002 desde enero de 2003. Reutilización: los términos de uso de las estadísticas del Banco de España permiten reutilizar sin alterar el contenido ni los metadatos, citando la fuente («elaboración propia con datos extraídos del sitio web del Banco de España») y la fecha de actualización, sin sugerir que participa en el atlas.

**Cifras de prensa del plan, contrastadas con la serie** (plan §2.5 y §10.2; `inventario/historico_referencias.csv`):

| Cifra de prensa | Serie del Banco de España (tabla de noviembre de 2026) | Compuerta |
|---|---|---|
| Menos de tres años de renta en 1987 | 2,90 en el 1.er trimestre de 1987; 3,00 en el 2.º | `hist_prensa` |
| 9,45 años de renta en el récord de 2007 | 9,46 en el 3.er trimestre de 2007, máximo de la serie | `hist_prensa` |
| Esfuerzo del 72 % en junio de 1990 | 72,47 % en el 2.º trimestre de 1990, máximo de la serie | `hist_prensa` |
| 7,6 años de renta en 2023 | No coincide: 7,24, 7,16, 7,11 y 6,97 (media de 2023, 7,1); 7,6 es la media de 2025 | ninguna |

**Tipos de interés** (`bde_accesibilidad` y `bde_tipos_referencia`; el mismo lector; plan §11, pregunta 47 c revisada). Línea principal: el tipo de los préstamos nuevos para adquisición de vivienda de los hogares (`D_IMVTIPLV`, en la tabla `si_1_5`, mensual desde enero de 1989), el mismo con que el Banco de España calcula el esfuerzo teórico: 17,05 % en enero de 1991 (máximo) y 1,50 % en diciembre de 2021 (mínimo), con la ruptura `bde_tipo_prestamos_2003` en enero de 2003 (de la Circular 8/1990 a la 4/2002), la misma que la del esfuerzo. Como referencia, una sola línea con dos índices distintos: el MIBOR a un año hasta diciembre de 1998 (`D_1E723706.EUR`) y el euríbor a 12 meses desde enero de 1999 (`D_1NBAF472`, tabla `be1901`), cada mes con su código y el cambio marcado (ruptura `bde_mibor_euribor_1999`; `hist_enlazar_mibor_euribor()`). El MIBOR siguió al euríbor desde 1999, con hasta 0,14 puntos de diferencia hasta julio de 2013, y coincide con él desde agosto de 2013. Máximo, 16,43 % en mayo de 1987 (MIBOR); mínimo, −0,505 % en enero de 2021 (euríbor). La tabla del módulo conserva el tipo oficial de referencia de los préstamos hipotecarios a más de tres años para adquisición de vivienda libre (`D_1T9H0000`, desde noviembre de 1990; anejo 8 de la Circular 5/2012), que la página ya no dibuja: 16,92 % en enero de 1991 (máximo) y 1,412 % en noviembre de 2021 (mínimo); agosto de 2026, 3,134 %, la cifra de la resolución del Banco de España publicada en el BOE (`BOE-A-2026-19481`).

**Valor tasado desde 1995** (`mivau_valor_tasado`; `hist_valor_tasado()`). La lectura trimestral de F4 (objetivo `valor_tasado_trim`, §7.7) desde el 1.er trimestre de 1995, de España y de las 19 comunidades y ciudades autónomas, en euros por m² y sin pasar a años; las cifras fuera del rango creíble de F4 quedan sin valor. España: 670,8 € por m² en el 1.er trimestre de 1995 y 2.355,0 € por m² en el 2.º de 2026.

**Sueldo bruto medio por asalariado** (`ine_cne`; `hist_leer_ine_cne()`, `hist_sueldo_asalariado()`). Contabilidad Nacional Anual de España, base 2020 (tablas 71129 y 71133 del INE): sueldos y salarios del total de la economía entre las personas asalariadas del mismo año (regla 4), desde 1995. Es la serie oficial más larga que mide lo mismo todos los años: SEC 2010 en base 2020, sin rupturas; los últimos años son provisionales y el INE los revisa cada septiembre. No es el salario medio de la AEAT (indicador 7, desde 2011): cuenta a todos los asalariados del año, también a quien trabaja parte de él o a tiempo parcial, y sale de las cuentas nacionales, no de las retenciones. 15.635 € en 1995, 21.699 € en 2007, 31.200 € en 2024 y 32.706 € en 2025. Queda por encima del salario medio de la AEAT (24.962 € en 2024): divide entre las personas asalariadas de media en el año, de modo que quien trabaja unos meses cuenta solo por esa parte, e incluye el País Vasco y Navarra, que la AEAT no cubre. La página lo dice, y que la serie empieza en 1995 (plan §11, pregunta 47 d).

**Compuerta** (`hist_comprobar()`, objetivo `validacion_historico`; `hist_comprobar_ine_cne()`, objetivo `validacion_cne`; `hist_comprobar_web()`, objetivo `validacion_web_historico`): las comprobaciones `hist_*` y `web_historico` de §4.1, con las cifras publicadas de `inventario/historico_referencias.csv`. Resultado (10-nov-2026): pasan todas las de bloqueo. Se reproducen las 21 cifras de la tabla en PDF del Banco de España y la del BOE; el valor tasado del MIVAU es igual al que reproduce el Banco de España en los 126 trimestres comunes (diferencia máxima, 0,0 € por m²), y la Contabilidad Nacional suma sin diferencias. La alerta `hist_valor_tasado_ccaa` avisa en 15 trimestres: 14 de comunidades que el MIVAU publica fuera del intervalo de sus provincias, comparadas solo cuando todas sus provincias tienen cifra (la Comunitat Valenciana de 1995 a 1997, Andalucía en 1995 y Extremadura en 1999, 2000 y 2012), y uno sin cifra de Melilla (2013). F4 comprueba lo mismo, como bloqueo, desde 2015 (`valor_tasado_ccaa`). Desde el 11-nov-2026, una revisión del Banco de España (`hist_publicadas`, `hist_publicadas_enteras` y `hist_prensa`) avisa y pide actualizar la referencia de `inventario/historico_referencias.csv`, sin bloquear (plan §11, pregunta 47 g).

**Web** (`hist_exportar_web()`, objetivo `ficheros_web_historico`). Página `historico.html`, «Máquina del tiempo», sin mapa: un gráfico por bloque, todos con el mismo eje de años desde 1987, con las fechas clave de `inventario/historico_fechas.csv` (los máximos y mínimos, comprobados en la serie; las rupturas, y el fin de la deducción por vivienda), una lectura sin valoraciones (primer dato, máximo, mínimo y último) y la tabla de cifras; el valor tasado, también por comunidad. Los datos van en `datos/historico/historico.json`, cada serie y territorio en enteros (× 100 los años de renta y el esfuerzo, × 1.000 los tipos, × 10 el valor tasado; el sueldo, en euros). La casilla «Sube el euríbor» de la portada lleva a sus tipos, y las cifras del Banco de España llevan la cita que piden sus términos de uso.

### 7.10 Barómetros del CIS: la vivienda como problema (F6)

**Qué se mide.** El barómetro mensual del Centro de Investigaciones Sociológicas pregunta, con respuesta espontánea y hasta tres menciones, «¿Cuál es, a su juicio, el principal problema que existe actualmente en España? ¿Y el segundo? ¿Y el tercero?» y «¿Y cuál es el problema que a Ud., personalmente, le afecta más?». La serie toma la columna TOTAL de la categoría «La vivienda» (distinta de «La ocupación de viviendas»): el porcentaje de entrevistados que la cita en cualquiera de las tres menciones, que es la suma de las tres columnas, porque nadie repite un problema. Es una encuesta de opinión, no un registro: mide cuánto se nombra la vivienda, no su precio. Es nacional y mensual, sin barómetro en agosto, y no entra en la tabla larga por sección: va en una tabla propia (objetivo `cis_vivienda`; `cis_serie_vivienda()`).

**Fuente y lectura** (`cis_descargar_estudios()`, `cis_leer_barometros()`; objetivos `cis_estudios` y `cis_barometros`). La página de cada barómetro declara sus documentos en JSON-LD, con licencia CC BY 4.0; se guarda en `datos/brutos/cis_barometros/estudios/`. De cada estudio se leen las tabulaciones en XLSX («Resultados y cruces verticales», desde febrero de 2025, con toda la precisión) o, si no las hay, los resultados en HTML (de enero de 2014 a enero de 2025, con un decimal; `cis_leer_xlsx()`, `cis_leer_html()`). Las tablas llegan en dos disposiciones, con los problemas en filas o en columnas, y con cabeceras que cambian («Primer problema [recod.]» en 2024): el lector reconoce todas. Antes de 2014 solo hay resultados abiertos sueltos (2009, 2011 y 2013) o en microdatos, así que la serie empieza en enero de 2014.

**Lo que no se usa.** El catálogo de series del CIS está protegido frente a accesos automatizados, y los datos de sus fichas de serie se sirven por una ruta que `robots.txt` excluye. Los microdatos de cada barómetro, que darían la cifra por comunidad autónoma, piden un formulario con correo y la aceptación de unas condiciones: quedan fuera, y el contraste por comunidad sigue pendiente.

**Resultado** (10-nov-2026). Hay 134 barómetros de enero de 2014 a octubre de 2026: 126 meses con dato de España y 128 de la pregunta personal (112 y 114 desde el HTML; 14 y 14 desde el XLSX); con los seis meses transcritos de los PDF (abajo), 132 y 134. La vivienda pasa del 1,5 % de enero de 2014 al 11,5 % de mayo de 2023, el 28,3 % de enero de 2025, el 48,9 % de mayo de 2026 y el 55,7 % de octubre de 2026 (55,65 en las tabulaciones), el máximo de la serie; en la pregunta personal, del 1,6 al 33,8 %.

**Meses solo en PDF.** Julio de 2014 y febrero, abril, mayo, junio y julio de 2025 solo publican sus resultados en PDF (el enlace del CIS a sus tabulaciones da error y no hay HTML). Se transcriben a mano, sin lector de PDF (plan §11, pregunta 48 a), en `inventario/cis_transcripcion_pdf.csv`: la fila «La vivienda» de las dos preguntas, con la página, el enlace a cada PDF de distribuciones marginales, su tamaño, su suma SHA-256 y la comprobación de cada fila (la suma de los tres problemas frente al total; dos filas, revisadas además a ojo sobre la página). `cis_aplicar_transcripcion()` los suma a la serie con el formato `pdf_transcrito`, y la compuerta `cis_vivienda_pdf` los comprueba (`cis_comprobar_transcripcion()`). La vivienda, en esos meses: 1,6 y 1,7 % en julio de 2014; de 25,6 a 34,1 % (España) y de 18,3 a 22,5 % (personal) en 2025. **Huecos.** Ninguno por falta de resultados abiertos (alerta `cis_vivienda_cobertura`). Abril y mayo de 2020 no traen la categoría «La vivienda» en la pregunta de España (alerta `cis_vivienda_categoria`) y no entran en la serie: falta la categoría, no es un cero medido. Siete meses no tienen barómetro: julio de 2016; marzo, abril, octubre y diciembre de 2019, y junio y septiembre de 2023 (alerta `cis_vivienda_meses`).

**Compuerta** (`cis_comprobar_vivienda()`; objetivo `validacion_cis`). Las cinco cifras de las notas de prensa del CIS de 28-ene-2026 y 14-sep-2026 (enero de 2026, 42,6 y 28,2 %; septiembre, 37,5 y 27,9 %; julio, 37,5 + 5,5 = 43,0 %) coinciden exactas (`cis_vivienda_publicada`, ±0,1 puntos). El total se aparta de la suma de las tres menciones como mucho 0,1 puntos en el HTML y 0,045 en el XLSX (`cis_vivienda_suma`, ±0,2 puntos). Ninguna cifra queda fuera de rango ni hay meses con una sola pregunta (`cis_vivienda_rango`). Si falta el mes de una nota, su cifra pasa a la alerta de cobertura, y solo bloquea si no se puede contrastar ninguna.

**Web** (`cis_exportar_vivienda()`; objetivo `ficheros_web_cis`). El fichero `datos/cis_vivienda.json` lleva las dos series (periodo, cifra con un decimal, estudio y entrevistas), la fuente, la licencia y la fecha del último barómetro. Va fuera de `datos/historico/`, que su exportación borra. Ida y vuelta: `cis_vivienda_web` (objetivo `validacion_web_cis`), también del estudio y las entrevistas de cada mes. La página `historico.html` ya lo muestra, en el bloque «La vivienda como problema (CIS)», tras las series del histórico: las dos preguntas en un gráfico mensual con el mismo eje de años desde 1987, cortado en los meses sin dato (agosto no cuenta: no hay barómetro); al pasar el ratón o con el teclado, el mes, las dos cifras, el estudio y las entrevistas; una lectura sin valoraciones (primer dato, máximo, último y meses sin dato), la cita del CIS con su licencia, la advertencia «opinión, no registro» y la tabla de cifras. Sin el fichero, el bloque dice que no hay datos.

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
- **Suelo sin sección** (§3.10): 1.495 km² de terrenos comunales no tienen sección ni datos y se ven como «sin dato». No se reparten entre provincias cuando tocan varias, y los que tocan la costa o la frontera no se detectan. Los nombres del IGN cubren 1.176,5 km²; en los bordes quedan franjas sin nombre, donde las líneas del IGN y las del INE no coinciden.

**Renta:**
- **La fuente no cuadra entre escalas.** El ADRH no siempre suma sus secciones al total municipal (`adrh_suma_secciones`, 160 municipios y años en 2015–2019). Sus medias de sección agregadas se separan más de un 5 % de la cifra municipal en 135 cifras (`adrh_municipio_detalle`). El atlas no lo corrige: muestra la cifra publicada en cada escala.
- **Hogares aproximados.** Salen de un tamaño medio del hogar redondeado a un decimal (§5.1).
- **País Vasco y Navarra en 2015–2019.** El ADRH no los publica por sección esos años: esas secciones van como `secreto` (§5.4).
- **Distribución de la renta (4–6), huecos forales.** Navarra hasta 2020, Álava hasta 2019 y Gipuzkoa en 2015 van como `ausente`; España tiene cifra desde 2021 (§5.5).
- **Umbral del indicador 5.** Cambia en 2023, de la mediana del territorio fiscal común a la de toda España, y en 2024 se publican más secciones (§5.5).
- **Ponderación aproximada del 4 y el 5.** Se reproyectan con la población del ADRH, no con la que el INE encuentra en los registros; agregadas a municipio, 98 cifras se separan más de 1 punto de la publicada (`adrh_dist_municipio_detalle`).

**Alquiler:**
- **Parque, no contratos nuevos.** El SERPAVI mide el parque alquilado: quien entra hoy paga más (indicador 8).
- **Solo caseros que son personas físicas** (metodología del MIVAU de 18 de marzo de 2026). El SERPAVI no cuenta el alquiler de sociedades y demás personas jurídicas, también la vivienda pública, ni el no declarado ni el de parientes. En 2021 recoge un 77,6 % de los hogares en alquiler del Censo, del 36,0 % de Melilla al 118,9 % de Salamanca, aunque la diferencia mezcla otras causas; no hay tabla abierta del parque alquilado por tipo de arrendador y municipio para marcar dónde pesa más (§7.1).
- **Secreto y cobertura.** En 2024, 4.849 secciones tienen la mediana de vivienda colectiva en secreto. La cobertura va del 19,4 % de las secciones en Soria al 95,4 % en Gipuzkoa: las zonas rurales tienen menos dato (§7.1).
- **Dos tipologías sin mediana conjunta.** El mapa por defecto muestra la vivienda colectiva; la unifamiliar va aparte (§1).
- **Territorios forales.** Series cortas: Navarra desde 2021, Gipuzkoa desde 2022, Álava y Bizkaia desde 2024 (§7.1).
- **Territorios sin fila en la fuente.** 40 secciones de 2021, 36 distritos y 36 municipios no están en la base del SERPAVI: van como `ausente` (§7.1).
- **Errores de la fuente.** 164 cifras de municipios y distritos van como `ausente` (§7.1).
- **Margen aproximado.** El margen de la mediana supone una distribución regular dentro de la sección y no corrige que sean contratos vigentes; con pocos contratos es solo un orden de magnitud. En 2024, 4.407 medianas de vivienda colectiva salen de menos de 30 contratos (§7.6).

**Hogares en alquiler:**
- Es una fotografía de 2021, no una serie (§7.2).
- 1.363 secciones están en secreto, sobre todo en provincias rurales (§7.2).

**Viviendas turísticas:**
- **Años distintos.** El denominador son las viviendas del Censo 2021 (§7.3).
- **Anuncios de plataformas.** Es una estadística experimental del INE construida con anuncios, no un registro (`inventario/indicadores.csv`).
- **Serie corta.** Empieza en febrero de 2024; de 2020 a 2023, en F6 (§7.3).
- **Meses distintos.** Los meses de referencia cambiaron en 2024 (§7.3).
- **Reparto.** 877 secciones son `estimado` en cada periodo (§7.3).
- **Denominador de comunidades y provincias.** Desde noviembre de 2024 el INE cuenta las viviendas de las secciones del Censo en secreto, que no se publican: en 33 provincias y 12 comunidades la compuerta solo acota la cifra por arriba, y el cambio de criterio mueve hasta 0,11 puntos la de Soria (§7.3).

**Derivados:**
- **Huecos heredados.** Un derivado no tiene valor donde falta alguno de sus términos: en 2024, 10.208 de las 36.333 secciones no tienen esfuerzo (§7.4).
- **Vulnerabilidad, no entrada.** El esfuerzo divide el alquiler entre la renta media de todos los hogares de la sección, no solo la de los que alquilan (`inventario/indicadores.csv`).
- **El peso del alquiler de la tabla larga es un control.** Con la tartera, la mochila y el transistor de 2015 a 2024; la web la calcula con la ficha elegida (§7.4).
- **La misma proporción para todos los ingresos.** El umbral del 30 % del 15 y el 21 no dice si lo que queda alcanza para los demás gastos, y pesa más con ingresos bajos (enfoque de ingreso residual; §7.4).

**Salarios (indicador 7):**
- **Sin País Vasco ni Navarra.** La AEAT no los cubre, y de las haciendas forales solo Gipuzkoa publica una cifra comparable (§5.6).
- **Lo cobrado en el año.** Es una media que incluye a quien trabajó pocos meses, no el salario de un empleo a tiempo completo.

**Mochila:**
- **Supuestos:**
  - de 2015 a 2018, la relación mediana/media es la de 2019;
  - la relación mediana/media del SME de una comunidad vale para todas sus provincias;
  - la distribución dentro de cada decil nacional es la del país;
  - la retención de la nómina es la media de todas las edades;
  - la cotización es la de un contrato indefinido.
- **Cobertura.** Sin País Vasco, Navarra, Ceuta ni Melilla (§6.2).
- **Lo cobrado en el año.** La ficha usa lo cobrado en el año, que incluye a quien trabajó pocos meses; la ficha lo dice.
- **Control débil antes de 2022.** Las olas de la ECV de 2016 a 2022 tienen menos muestra: la mochila de una comunidad se aparta más de un 15 % de la mediana de la encuesta en 32 cifras, aunque la de España queda entre un −5,9 y un +7,2 % (§6.2).

**Transistor:**
- **Pensiones, no pensionistas.** Quien cobra dos pensiones cuenta dos veces, y la provincia es la de la dirección provincial que gestiona la pensión (§6.5).
- **Retención de todos los pensionistas.** La AEAT no separa la jubilación; en País Vasco y Navarra, la curva es la de España (`estimado`; §6.5).
- **Casa propia.** La gran mayoría de los mayores de 65 años no alquila: la ficha responde a «si tuviera que alquilar hoy» (§6.5).

**Años de las fichas.** La tartera, la mochila y el transistor tienen ingreso de cada año de 2015 a 2024 (§7.4).

**Percentil salarial.** Cuenta a quien trabajó pocos meses, así que los percentiles bajos son cantidades pequeñas; dentro de cada tramo de salario se supone una densidad lineal; País Vasco y Navarra (y Ceuta y Melilla en 2020 y 2021) usan la curva de España (§6.6).

**Licencias.** El Catastro estatal y los forales de Bizkaia y Gipuzkoa tienen licencias contradictorias y se tratan como datos abiertos por decisión del autor (§2.2; plan de retirada, §2.4).

**Sobrecarga.** Se publica sin intervalos de confianza. El quintil de renta usa HY020 ÷ HX240, no la HX090 de Eurostat, que el INE no publica, y lleva al quintil de arriba la renta igual a un corte, con lo que las 15 cifras coinciden con las de Eurostat a un decimal. La serie de España se corta en 2013, el año en que cambia la forma de obtener los ingresos, aunque Eurostat no lo marca (§7.5).

**Compraventa.** El precio es el de tasación, no el escriturado ante notario: las webs del Notariado reservan sus derechos y piden autorización expresa; el indicador 11 sale de Registradores, por provincia (§7.7). El año del valor tasado es una media de trimestres que el Ministerio no publica. Los años de salario usan el salario bruto individual de la provincia, no la renta del hogar, y no cubren País Vasco ni Navarra; el IPVA tampoco. El esfuerzo hipotecario usa la renta por hogar del ADRH, estimada desde los municipios donde el INE no la publica (España hasta 2020 y los territorios forales que aún no estaban enteros). El precio de compraventa de Registradores (11) llega solo a la provincia.

**Zonas tensionadas.** Las ocho declaraciones de una parte del municipio se pintan en el municipio entero, con su propia categoría (§7.8). Solo entra lo publicado en el BOE: las declaraciones que una comunidad haya publicado después del 30 de septiembre de 2026 llegarán con la resolución del cuarto trimestre, y las solicitudes denegadas no figuran en ninguna resolución. La tabla larga es una foto a 31 de diciembre; las fechas exactas están en la ficha y en el inventario.

**Precios de oferta.** Es precio de oferta de los anuncios, no de cierre ni de contrato, y su media cambia con el tipo de piso que se anuncia (§7.8). Idealista publica 286 municipios, donde vive el 59,3 % de la población (ADRH 2024); el resto queda sin dato. El último año es parcial (2026: de enero a octubre). Las condiciones generales de Idealista exigen su autorización escrita para incorporar su contenido a otro sitio web y para enlazar sus páginas en profundidad: está por pedir antes de publicar la capa.

**Desfase.** La renta y los salarios van uno o dos años por detrás del año en curso (§1).

**Euros corrientes.** Las series en euros (renta, salarios, alquiler y sueldo necesario) no se deflactan: van en euros de cada año. La evolución de la ficha lo dice y da la variación del IPC entre el primer y el último año con cifra; de 2015 a 2024, +23,5 % (§9.2; backlog, tarea 45).

---

## 9. Tabla larga y datos de la web

### 9.1 Tabla larga

**Esquema** (plan §6.4): `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo`, `valor`, `estado`, `fuente`, `geo_ref` y `version`. La clave de una fila es `geo_id`, `nivel`, `anio`, `indicador`, `corte` y `grupo`.

**Contenido** (`tabla_larga`; `exportar_tabla_larga()`, `datos/intermedios/tabla_larga.parquet`): 11.483.367 filas, más 254.835 de la tarea 47 (11-nov-2026; §3.11).

| Fuente (`fuente`) | Filas | Niveles | Versión |
|---|---|---|---|
| `ine_adrh` | 2.634.650 | Sección (2.179.944), municipio (452.546), provincia (1.560), comunidad (570) y España (30) | 7-nov-2026 (1–3) y 9-nov-2026 (4–6) |
| `mivau_serpavi` | 5.032.640 | Sección (3.419.452), distrito (926.724), municipio (676.872), provincia (7.032), comunidad (2.540) y España (20) | 6-nov-2026 |
| `ine_censo2021` | 36.405 | Sección (36.333), comunidad (19), provincia (52) y España (1) | 8-nov-2026 |
| `ine_vut` | 436.860 | Sección (435.996), comunidad (228), provincia (624) y España (12); la mitad, de 2020–2023 (tarea 47) | 8-nov-2026 |
| `ine_censo2011` | 36.405 | Sección (36.333), comunidad (19), provincia (52) y España (1) | 10-nov-2026 |
| `ine_ecv` | 261 | Comunidad (228) y España (33) | 6-nov-2026 |
| `ine_ecv_modulo` | 32 | Comunidad (19) y España (13) | 6-nov-2026 |
| `aeat_mercado_trabajo` | 2.016 | Provincia (1.456), comunidad (532) y España (28) | 9-nov-2026 |
| `ine_ipva` | 12.438 | Distrito (4.070), municipio (7.180), provincia (864), comunidad (306) y España (18) | 10-nov-2026 |
| `mivau_valor_tasado` | 4.048 | Municipio (3.256), provincia (572), comunidad (209) y España (11) | 10-nov-2026 |
| `zonas_tensionadas` | 24.393 | Municipio (24.393) | 10-nov-2026 |
| `calculo_propio` | 3.518.054 | Sección (2.436.386), distrito (568.152), municipio (506.960), provincia (5.076), comunidad (1.460) y España (20) | 7-nov-2026 |

**Por estado:** `dato`, 8.507.796 filas; `ausente`, 1.690.991; `secreto`, 1.233.209; `estimado`, 51.371.

**Publicación.** La tabla larga se publica en el release `v0.1.0` de GitHub (9-nov-2026), y la web, en `https://gastiaso.github.io/de-renta-en-renta/` (`docs/publicacion.md`).

### 9.2 Datos de la web

La exportación sigue las decisiones del autor del 8-nov-2026 (plan §6.6; plan §11, preguntas 16 y 17). `exportar_web()` (objetivo `ficheros_web`) escribe en `web/datos/`, desde la tabla larga ya validada, los indicadores del núcleo de la v0.1 y los que tienen mapa (columna `cortes_web` y cifras de sección: los 4–6 de F3, desde el 9-nov-2026), de la sección a España:
- **Valores.** Un fichero JSON por serie, nivel y periodo, con los valores × 10 en enteros (× 100 en las viviendas turísticas, con dos decimales, como las publica el INE: columna `escala_web` de `inventario/indicadores.csv`, vacía en los demás; plan §11, pregunta 24), con el redondeo de la guía a esos decimales, y una cadena con el estado de cada territorio, en el orden del índice de su nivel. Comprimido pesa lo mismo que un binario (plan §11, pregunta 17): cada fichero de secciones ocupa de 139 a 291 KB, y de 19 a 98 KB con gzip.
- **España, comunidades y provincias.** Los indicadores 18 y 19 tienen las cifras publicadas de España, de las 19 comunidades y de las 52 provincias (§7.2 y §7.3); las de España, en siete ficheros. El alquiler (8 y 9) y el sueldo necesario (21) tienen comunidades y provincias, pero no España: el SERPAVI solo publica su recuento de testigos, que va en la serie de contratos (§7.6). La renta (1–3) y el esfuerzo (14) llegan al municipio (§5.3 y §7.4). La distribución de la renta (4–6) tiene las cifras publicadas de las comunidades, de las provincias y, desde 2021, de España (§5.5).
- **Series de la ficha.** Un fichero por municipio (`fichas/<municipio>.json`) con las series de sus secciones y del propio municipio.
- **Fiabilidad** (§7.6). Los contratos y el margen de la mediana van como series auxiliares de cada serie del alquiler, de su misma tipología (`fiabilidad` en el manifiesto), sin número de indicador ni mapa propio. No van en las fichas por municipio, donde pesarían una cuarta parte más: la ficha los lee de los ficheros del periodo que pinta el mapa.
- **Qué no se exporta.** Los cuartiles del SERPAVI y el peso del alquiler en el ingreso (15), que la web calcula con la ficha elegida. El sueldo necesario (21) se recalcula en el navegador cuando cambian el umbral o la superficie (`FORMULAS_WEB`): la cifra principal, desde el alquiler mensual, y el mínimo de al lado (`minimo` del mapa), desde el alquiler por m² (tarea 40).
- **La web frente a R.** La prueba de la web (`pruebas/web/datos.test.mjs`, en node) recalcula con el módulo de la página, `web/js/formulas.js`, el sueldo necesario desde la base de su mapa (desde la tarea 40, el alquiler mensual) en todas las secciones, distritos, municipios, provincias y comunidades de 2015 a 2024, y lo compara con el que exporta R: 550.140 territorios y años, 294.082 con valor, sin diferencias en el valor, los nulos ni el estado (plan §6.5). Además, `comprobar_web_navegador()` abre la página en Chrome sin ventana (`chromote`): con sus propios módulos, recalcula una muestra de 300 secciones en los 10 años y lee sus contratos y su margen, y abre seis fichas. En local y en el sitio publicado coincide todo con la tabla larga, sin errores (9-nov-2026; `docs/publicacion.md`).
- **Descargas.** La web descarga la serie del mapa en CSV, en el nivel que se ve (valor con la precisión de la serie, estado y fuente; en las series del alquiler, contratos y margen; en el 21, superficie y umbral y el mínimo de 50 m² al lado, `valor_minimo`), y el mapa en PNG con su leyenda y su fuente. Con «Tu ficha», ninguna de las dos lleva el sueldo escrito: el CSV da el alquiler, no la proporción. Los colores del PNG de «¿te llega?» sí dejan deducirlo de forma aproximada, así que con «Tu ficha» se descarga tras un aviso que se puede cancelar (plan §11, pregunta 23).
- **Año fuera de la serie** (plan §11, pregunta 32). Con un año anterior a todos los periodos de una serie (2020 en las viviendas turísticas), el mapa, la leyenda, la ficha, el comparador y las dos descargas dan «sin dato» y dicen desde cuándo hay serie; el CSV, con una fila sin valor por territorio y el inicio de la serie en la columna del estado. Con un año posterior se toma el último periodo, y la leyenda lo dice.
- **Otros ficheros.** Los nombres de los territorios, los rectángulos de los municipios para el buscador (`cajas_municipios`) y los ingresos de las fichas (`perfiles`), de cada año (`anios`), para que la web use el del año del alquiler, y las curvas del percentil salarial (`salarios_web()`, `datos/salarios.json`; §6.6). El mapa base se copia a `web/teselas/`; al publicar, sale de un *release* (§3.10).
- **Volumen** (`ficheros_web`, 9-nov-2026): 8.970 ficheros y 147,7 MB, con el PMTiles (35,4 MB). En disco, `web/datos/` suma 9.354 ficheros y 113,6 MB: los 8.969 de `ficheros_web` (112,3 MB; las fichas por municipio, 57,9 MB), los 3 de la sección de sobrecarga (`ficheros_web_sobrecarga`, 1,1 MB) y la muestra versionada de `web/datos/ejemplo/` (382 ficheros, 0,2 MB). Los contratos y el margen (§7.6) añaden unos 17 MB, y la distribución de la renta (§5.5), unos 21 MB, 14 de ellos en las fichas por municipio.
- **Compuerta** (`comprobar_web()`, `validacion_web`): `web_valores` y `web_fichas` (bloqueo) y `web_fuera_indice` (alerta); el percentil, `web_salarios` (`comprobar_salarios_web()`, `validacion_web_salarios`, bloqueo) (§4.1).
- **Portada** (`exportar_portada()`, objetivo `fichero_portada_web`; 10-nov-2026). Las tres cartas de la portada llevan cifras de la tabla larga, con el redondeo de la guía, en `web/datos/portada.json`: en 2024, la sección mediana de las 26.137 con dato pide 1.900 € netos al mes con su alquiler mensual mediano y el umbral del 30 % (percentil 10, 1.234,7 €; percentil 90, 2.976,5 €; cuantiles de R de tipo 7), y 1.216,7 € con el mínimo de 50 m², al lado (tarea 40); con el salario mínimo de 2024 (1.237,4 € netos al mes), el alquiler de 50 m² pasa del 30 % del ingreso en el 48,4 % de esas secciones y del 40 % en el 24,7 %, y el alquiler mensual mediano, en el 89,9 % y el 66,7 %; en la ECV 2025, la sobrecarga es del 26,8 % en el alquiler a precio de mercado y del 7,2 % en el total. Las casillas salen de `inventario/casillas_portada.csv` (`escribir_casillas_portada()`, objetivo `fichero_portada_html`). Compuertas `portada_valores` y `portada_casillas` (bloqueo, `validacion_portada`; §4.1).
- **Mapas sin sección y de categorías** (F5, 10-nov-2026). Las series con mapa (columna `cortes_web`) sin secciones, el indicador 20 y los de compraventa 10, 12, 16 y 17, llevan en el manifiesto `nivel_minimo`: la web pinta y deja pulsar los municipios a toda escala y apaga las secciones, y una sección elegida se ve en la ficha de su municipio. Sin municipio, el 11 (Registradores; tarea 46, 11-nov-2026) lleva `nivel_minimo` «provincia»: la web pinta las provincias a toda escala, apaga municipios y secciones, y una sección elegida se ve en la ficha de su provincia. El 20 lleva además `categorias`, con el texto de cada valor de `inventario/vocabulario.csv` en los dos idiomas, y `detalle`, sus declaraciones (`datos/zonas_tensionadas.json`, 195 KB). La capa de portales, con `PORTALES=TRUE`, da un mapa por operación y portal desde su propia carpeta, `datos/portales/` (§7.8). Los euros por m² de la compraventa se muestran sin decimales, y los años de salario, con uno.
- **Ficha por niveles** (backlog, tarea 26). Con poco zoom, el mapa pinta y deja pulsar comunidades, provincias y municipios con la cifra publicada en su nivel, la misma de los ficheros de valores; si alguna serie que da color no llega a ese nivel, la ficha dice «sin dato en este nivel» y no suma secciones (§5.3). En una comunidad, las fichas con ingreso por provincia (mochila y transistor) no tienen cifra.
- **Tramos del mapa** (backlog, tarea 51; decisiones 13 a 15 del autor). Siete tramos con cortes fijos entre años y tres juegos por indicador, uno por escala: la sección, el municipio, y la provincia y la comunidad (`inventario/cortes_web_niveles.csv`, `leer_cortes_niveles()`; `juegos` de cada mapa en el manifiesto). Cada capa del mapa se pinta con el juego de su nivel, y la leyenda, con el de la escala que se ve: al acercar o alejar el mapa cambia de regla y lo avisa. Método de cada juego: `recalibrado`, septiles de todos los años, si en el último año ningún tramo pasa del 30 % y en el primero, del 35 %; si no, `anclado`, sextiles del último año y un corte bajo en la mediana del primero, o `anclado_septiles`, septiles del último año, donde ese corte bajo deja vacío el primer tramo en el último año (provincias y comunidades del alquiler mensual, de la variación del alquiler y del sueldo necesario). En los anclados, los primeros años se acumulan en los tramos bajos (la subida de la década, en euros corrientes) y la leyenda lo dice: «tramos fijados con el último año». Los cortes no se mueven al entrar un año nuevo; se revisan en cada versión mayor. Sin juegos: las viviendas turísticas (distribución muy asimétrica), la zona tensionada (categorías) y la sobrecarga (sección propia); la brecha de «entrar» sigue con los seis tramos de `inventario/entrar_tramos.csv` (§7.8). Rampa de siete pasos (`diseno/tokens.json`): los extremos de la de cinco y cinco puntos de su recorrido en OKLab, a 0,075 como mínimo entre pasos contiguos con deuteranopía simulada y a 0,081 en visión normal; con esos extremos, siete pasos de un solo tono no llegan a 0,08, y `rampa_daltonismo` exige 0,07. Compuerta `web_tramos` (alerta; `comprobar_tramos_web()`, objetivo `validacion_web_tramos`): por mapa y juego, en el último año, ningún tramo vacío ni con más del 35 % de los territorios con dato (la provincia y la comunidad, juntas). Además, sin contorno de sección por debajo del zoom 9, indicador de carga, leyenda abierta al entrar (en el móvil, bajo el mapa) y vista inicial con Canarias.
- **Tramos relativos al municipio** (decisión del autor, 11-nov-2026; `web/js/escala_municipio.js`). Con los cortes de la sección, casi todo Madrid y Barcelona cae en el tramo más alto: en el alquiler mensual de 2024, el 87 % de las secciones de Madrid y el 95 % de las de Barcelona. A escala de sección, la leyenda ofrece pintar las secciones con los septiles de las de un municipio, en el año y la serie que se ven, calculados en la página; por defecto sigue la escala nacional, la comparable. Manda el municipio de la ficha (el de la sección o el municipio elegido) y, sin ficha, el del centro de la vista. Solo en los mapas con juego de cortes de la sección (no en las viviendas turísticas, la zona tensionada, la sobrecarga ni la capa de portales) y en municipios con 14 secciones con dato o más (dos por tramo). Cortes redondeados al mayor paso de 1, 2, 2,5 o 5 por una potencia de 10 que no pase de la mitad del hueco más estrecho entre cortes ni de la cuarta parte del mediano. La leyenda da sus cortes y dice «tramos de <municipio>, no comparables con otros municipios»; las secciones de fuera quedan sin color, y el PNG y el enlace (`escala=municipio`) llevan la escala elegida. En los mapas de una sola escala (el 11, provincial), un municipio o una sección elegidos en el buscador abren la ficha de su provincia (`nivel_minimo`).
- **Euros corrientes e IPC** (backlog, tarea 45; `ipc_exportar_web()`, objetivo `ficheros_web_ipc`). Las series del atlas no se deflactan. La evolución de la ficha lo dice bajo el gráfico, en las series en euros y en los euros que quedan de «¿te llega?», y da la variación del IPC entre el primer y el último año con cifra, con `datos/ipc.json`: las medias anuales del índice general del INE (`ine_ipc`, tabla 76144, base 2025), de 2002 a 2025, con sus tres decimales (`ipc_leer()`). Propuesta por revisar: el aviso fijo, no un selector de euros constantes, para que la ficha diga lo mismo que el mapa, la leyenda y el CSV. Compuertas de bloqueo: `ipc_variacion`, `ipc_serie` e `ipc_referencia` (`ipc_comprobar()`, objetivo `validacion_ipc`) y `web_ipc` (`ipc_comprobar_web()`, objetivo `validacion_web_ipc`).

### 9.3 Calendario de fuentes y actualización (F6)

`inventario/calendario_fuentes.csv` tiene una fila por fuente del pipeline (29, con el IPC de la tarea 45 y el Censo 2011). Cada una lleva su cadencia, los meses y el día habituales de publicación, el desfase entre el final de un periodo y su publicación y el último periodo que tiene el atlas. Lleva también su calendario oficial (INE, Eurostat, Banco de España o CIS), los objetivos que la descargan, sus ficheros y cómo se renueva (`mover`, `invalidar`, `codigo`, `manual` o `fija`).

`cal_fuentes_pendientes()` dice qué fuentes tocan a una fecha dada:
- cuando, desde la última descarga, ha pasado una fecha de publicación esperable;
- o cuando ya debería estar publicado un periodo posterior al último del atlas.

El objetivo `fuentes_pendientes` se vuelve a ejecutar cuando cambia ese conjunto de fuentes, y avisa con la lista y con la forma de renovar cada una. Su señal, `cal_hay_cambios()`, se evalúa al leer `_targets.R`: compara con la lista que dejó la pasada anterior en `datos/intermedios/calendario/pendientes.csv`, fuera de git. Con el calendario al día no fuerza nada, y `tar_outdated()` sale vacío. El objetivo del CIS, `cis_estudios`, se vuelve a ejecutar solo cuando toca (`cal_toca()`).

Nada se ejecuta solo ni en el repositorio remoto. El procedimiento, con las órdenes de R, está en `docs/actualizacion.md` (`cal_actualizar()`, `cal_restaurar()`).

El 10-nov-2026 toca una fuente, `inss_pensiones`: ya ha publicado 2025 entero y el atlas llega a 2024. Compuerta: `calendario_fuentes` (bloqueo) y `calendario_descargas` (alerta), en el objetivo `validacion_calendario`.

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

El mapa base tarda unos 9 minutos: 7 min 29 s el PMTiles (`fichero_mapa_base`) y 1 min 18 s su compuerta, que calcula los huecos del seccionado y sus nombres del IGN (9-nov-2026). Con `PROVINCIA=28` (variable de entorno, antes de `tar_make()`), el cálculo se limita a una provincia, y los ficheros llevan el código en el nombre.

**Objetivos citados en esta nota:**
- **Geografía:** `secciones_2021`, `tablas_paso_callejero`, `tablas_paso_finales`, `edificios_paso`, `edificios_forales`, `municipios_catastro_sel`, `grupos_municipio`, `huerfanas_adrh`, `fase_codigos`, `cambios_limites`, `comprobaciones_f1`, `diagnostico_f1`, `comparacion_vias`.
- **Jerarquía y mapa base:** `jerarquia_2021`, `territorios_2021`, `ficheros_jerarquia`, `unidades_ign`, `fichero_mapa_base`, `resumen_mapa_base`.
- **Renta:** `comprobaciones_adrh`, `tablas_paso_adrh`, `larga_adrh`, `tabla_larga`, `fichero_adrh_fuentes`, `fichero_adrh_umbrales`, `fichero_adrh_gini`, `ficheros_adrh_totales`, `comprobaciones_adrh_distribucion`, `larga_adrh_distribucion`.
- **Alquiler:** `serpavi`, `larga_serpavi`, `resumen_larga_serpavi`, `comprobaciones_fiabilidad`, `resumen_fiabilidad`, `contraste_serpavi_censo`.
- **Hogares en alquiler y viviendas turísticas:** `censo2021`, `larga_censo2021`, `vut`, `vut_2021`, `larga_vut`.
- **Tabla de paso desde el Censo 2011 (tarea 47):** `secciones_censo2011`, `tramos_2012`, `grupos_2011`, `paso2011_descasados`, `edificios_censo2011`, `paso_final_2011`, `paso_final_2011_vut`, `resumen_paso2011`, `censo2011`, `censo2011_tenencia`, `censo2011_2021`, `vut_2011_2021`, `comprobaciones_paso2011`, `validacion_paso2011`, `larga_paso2011`.
- **Salarios y mochila:** `salarios_aeat`, `larga_salarios`, `modulos_sme`, `formas_mochila`, `mochila`, `mochila_neta`, `retenciones_mochila`, `ecv_mochila`, `correccion_mochila`, `tramos_salariales`, `curvas_salariales_aeat`.
- **Fichas y derivados:** `perfiles`, `resumen_perfiles_llave`, `larga_derivados`, `inss_mensual`, `inss_anual`, `retenciones_transistor`, `transistor`, `fichero_supuestos`, `supuestos_inventario`, `fichero_supuestos_js`, `superficie_tipica`, `terminos_supuestos`, `validacion_supuestos`.
- **Sobrecarga:** `sobrecarga_agrupada`, `comprobaciones_sobrecarga`, `sobrecarga_quintil`, `eurostat_quintil`.
- **Compraventa:** `ipva`, `larga_ipva`, `valor_tasado_trim`, `larga_valor_tasado`, `tipo_hipotecario_anual`, `tipo_bde_anual`, `renta_hogar_publicada`, `validacion_renta_hogar_publicada`, `renta_hogar_17`, `derivados_compraventa`, `registradores`, `validacion_registradores`, `larga_registradores`, `larga_compraventa`, `cp_municipio`, `fichero_cp_municipio`.
- **Presión:** `zonas_tensionadas`, `boe_zonas_tensionadas`, `larga_zonas_tensionadas`, `resumen_larga_zonas_tensionadas`, `portales`, `portales_anual`, `larga_portales`, `resumen_portales`, `ficheros_web_portales`, `tramos_entrar`, `terminos_entrar`, `indicadores_entrar`, `tramos_web_entrar`, `resumen_entrar`.
- **Web:** `ficheros_web`, `cajas_municipios`, `ficheros_web_sobrecarga`, `fichero_ipc`, `ipc`, `ficheros_web_ipc`.
- **Histórico (F6):** `series_bde`, `cne_agregados`, `cne_empleo`, `historico`, `fichero_historico`, `ficheros_web_historico`.
- **CIS y calendario (F6):** `cis_estudios`, `cis_barometros`, `cis_transcripcion`, `cis_barometros_completos`, `cis_vivienda`, `fichero_cis_vivienda`, `ficheros_web_cis`, `calendario_fuentes`, `fuentes_pendientes`.
- **Compuertas:** `validacion_mochila_relacion`, `validacion_f1`, `validacion_adrh`, `validacion_adrh_distribucion`, `validacion_serpavi`, `validacion_fiabilidad`, `validacion_censo2021`, `validacion_vut`, `validacion_derivados`, `validacion_jerarquia`, `validacion_mapa_base`, `validacion_web`, `validacion_web_sobrecarga`, `validacion_sobrecarga`, `validacion_quintil`, `validacion_modulo`, `validacion_salarios`, `validacion_mochila`, `validacion_mochila_ecv`, `validacion_mochila_neto_ecv`, `validacion_mochila_serie`, `validacion_percentil`, `validacion_web_salarios`, `validacion_smi`, `validacion_inss`, `validacion_transistor`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`, `validacion_ipva`, `validacion_hipotecas`, `validacion_valor_tasado`, `validacion_coherencia_compraventa`, `validacion_derivados_compraventa`, `validacion_cp_municipio`, `validacion_zonas_tensionadas`, `validacion_web_zonas_tensionadas`, `validacion_historico`, `validacion_cne`, `validacion_web_historico`, `validacion_cis`, `validacion_web_cis`, `validacion_calendario`, `validacion_portales`, `validacion_web_portales`, `validacion_entrar`, `validacion_web_entrar`, `validacion_ipc`, `validacion_web_ipc`.
