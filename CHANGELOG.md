# Registro de cambios

Formato inspirado en *Keep a Changelog*, en castellano. Versiones previstas: v0.0 (sobrecarga y Europa), v0.1 (núcleo por sección censal), v0.2 a v0.4 (salarios, compraventa, presión y portales), v1.0.

## [Sin publicar]

### Decidido (8-nov-2026, preguntas abiertas 22–33; plan v0.26)

- Sin modo daltónico en la v0.1: la rampa de seis pasos pasa `rampa_daltonismo`.
- Web: aviso previo antes de descargar el PNG de «¿te llega?» con «Tu ficha»; viviendas turísticas (19) con dos decimales; «sin dato» y desde cuándo hay serie si el año es anterior a todos sus periodos.
- Tabla larga: provincias y comunidades del 18 y el 19 con la cifra publicada por el INE; municipios y distritos de una sola sección sin SERPAVI, como `ausente`.
- Sobrecarga: cifras de Eurostat con sus marcas (descarga autorizada por el autor, unos 0,4 MB); serie desde el primer año publicado, con las rupturas marcadas; cortes en `inventario/indicadores.csv`; Bosnia y Herzegovina con la geometría de NUTS 2024 y FI19_20 fuera; España por quintil de renta.
- El CSV de secciones mantiene el nombre completo de la fuente.

### Añadido (8-nov-2026, preguntas 22–33; plan v0.26)

- **Comunidades y provincias del 18 y el 19** en la tabla larga, con la cifra publicada por el INE (tablas 59523 y 39365; el 19, en los seis periodos de las secciones) y los códigos de `geo/`: 71 filas del 18 y 426 del 19, todas `dato`. Ceuta y Melilla, como comunidad y como provincia. Funciones `territorios_ine_censo2021()`, `territorios_ine_vut()`, `territorios_vut()` y `sumar_territorios_ine()`; `nacional_ine_censo2021()` y `nacional_ine_vut()` quedan como envoltorios de España. Compuerta nueva `vut_territorios` (bloqueo, ±0,01 puntos; diferencia máxima, 0,0075); `censo2021_alquiler` y `censo2021_principales` se amplían a las comunidades.
- **Quintil de renta en la sobrecarga** (España, olas 2023–2025): `calcular_sobrecarga_quintil()` con la renta disponible equivalente (HY020 ÷ HX240) y cortes ponderados por persona; objetivos `sobrecarga_quintil` y `validacion_quintil`; compuertas `sobrecarga_quintil_total` (bloqueo, ±0,01 puntos), `sobrecarga_quintil_reparto` (alerta, ±1 punto) y `sobrecarga_quintil_eurostat` (bloqueo, ±0,1 puntos: las 15 cifras de 2023–2025 frente a Eurostat, con 0,051 puntos como mucho). Consulta nueva de Eurostat, autorizada por el autor: `ilc_lvho07b` de España con sus marcas (4 KB), por la API JSON-stat con `httr2` (`descargar_eurostat_quintil()`), porque el paquete `eurostat` pierde las marcas al filtrar. En la web, tercer bloque de desgloses con la muestra de cada cifra.
- **Marcas de Eurostat** en la consulta europea (`keepFlags`; descarga autorizada por el autor): ninguna de las 9.690 cifras cambia. La web las muestra junto a cada cifra, pinta con trama las «u» y corta la serie en las rupturas («b»: España, toda la población, 2008).
- Web: aviso previo antes de descargar el PNG de «¿te llega?» con «Tu ficha» (`js/aviso_imagen.js`).

### Cambiado (8-nov-2026, preguntas 22–33)

- Web: viviendas turísticas (19) con dos decimales, decididos en la columna nueva `escala_web` de `inventario/indicadores.csv` (vacía, una décima). `exportar_web()` escribe cada serie con su escala y `comprobar_web()` la compara con su precisión (`web_valores`, `web_fichas`). España da 1,33 % en febrero de 2024 y 1,28 % en mayo de 2026, como el INE. La leyenda escribe los cortes con los decimales que necesitan.
- Web: con un año anterior a toda la serie, `periodoPara()` ya no toma el último periodo: el mapa, la barra, la leyenda, la ficha, el comparador y las descargas dicen «sin dato» y desde cuándo hay serie.
- SERPAVI: los 36 municipios de una sola sección que la base no trae, y sus 36 distritos, van como `ausente` (`completar_secciones_serpavi()`, ahora en los tres niveles del seccionado). +2.880 filas del SERPAVI y +1.012 de los derivados (21: 720; 15: 144; 14 en municipios: 148), todas `ausente`; ningún valor cambia y la web queda idéntica. `serpavi_seccionado` (bloqueo) y `serpavi_sin_fila` (alerta) dan una fila por nivel: 0, 0 y 0; 40, 36 y 36.
- `exportar_i18n()` escribe los diccionarios en LF también en Windows.
- Sobrecarga: la serie de España y de la UE-27 empieza en el primer año publicado (España, 2004; alquiler a precio de mercado, 2007; UE-27, 2010), sin constante en el código. Los cortes del mapa pasan a `cortes_web` del indicador 22 (`4;6;8;10;15|RENT_MKT=15;20;25;30;40`; fuera `CORTES_SOBRECARGA_WEB`). Bosnia y Herzegovina toma en 2022 y 2023 la geometría de NUTS 2024 (`version_geometria()`), y los países que NUTS 2021 no trae pasan al fondo del mapa de esos años: `web_sobrecarga_geometria`, a cero.
- Tabla larga: 6.595.745 filas (+497 `dato` de comunidades y provincias y +3.892 `ausente` del SERPAVI y sus derivados). Datos de la web: 8.500 ficheros y 110,1 MB con el PMTiles; `web_valores` compara 360 ficheros.
- Nota metodológica (castellano e inglés) al día con las preguntas 22–33: comunidades y provincias del 18 y el 19 (§7.2 y §7.3), municipios y distritos sin SERPAVI como `ausente` (§7.1), quintil de renta, marcas de Eurostat y serie desde 2004 en la sobrecarga (§7.5), viviendas turísticas con dos decimales, aviso antes del PNG y año fuera de la serie (§9.2), cuatro compuertas nuevas (§4.1) y tabla larga (§9.1). Las preguntas 34–36 se describen como funciona hoy el pipeline.

### Añadido (8-nov-2026, barra de la vista, España, sobrecarga y publicación; plan v0.25)

- **Barra de la vista** encima del mapa: el mapa (los de `mapas` del manifiesto), el año o periodo de la serie que da color y la tipología de vivienda (colectiva por defecto; unifamiliar solo donde la serie tiene variante, sin mezclar), con el teclado y en la URL (`anio` admite `AAAA-MM`; `tipologia=VU`). En «¿te llega?», la tipología cambia el alquiler de todas las fichas. Aviso cuando la serie no llega al nivel que se ve (`js/barra_vista.js`).
- **Descargas** de la vista, sin dependencias nuevas: CSV de la serie del mapa en el nivel que se ve (UTF-8 con BOM; valor a una décima, estado y fuente; en el 21, superficie y umbral) y PNG del mapa con título, leyenda, claves y fuente. Ninguna lleva el sueldo escrito (`js/exportar.js`, `js/imagen.js`).
- **Prueba de §6.5 en node:** el sueldo necesario que recalcula la página coincide con el de R en 550.140 territorios y años (294.082 con valor), sin diferencias.
- **España en la tabla larga** para el 18 (16,10 %, tabla 59523) y el 19 (seis periodos de febrero de 2024 a mayo de 2026, tabla 39365), con la cifra publicada por el INE (`nacional_ine_censo2021()`, `nacional_ine_vut()`); `exportar_web()` las lleva al nivel `nacional` sin cambios. Compuertas `censo2021_nacional`, `vut_nacional_viviendas` y `vut_nacional_porcentaje` (bloqueo). Sin España, por la regla 1: renta (1–3), alquiler (8 y 9) y sus derivados (14 y 21).
- **Sección «Sobrecarga» (v0.0):** `web/sobrecarga.html`, `js/sobrecarga.js`, `js/sobrecarga_datos.js` y `estilo/sobrecarga.css`, con textos en castellano e inglés (`sobrecarga` en `web/i18n/`): mapa de Europa (regiones NUTS 2 para toda la población; países y comunidades con tenencia o edad), «la escalera», serie de España y de la UE-27, desgloses de España con su muestra, módulo de acceso y caja de método. Exportación en `R/web_sobrecarga.R` (`exportar_web_sobrecarga()`, `comprobar_web_sobrecarga()`; objetivos `ficheros_web_sobrecarga` y `validacion_web_sobrecarga`); compuertas `web_sobrecarga_valores` y `web_sobrecarga_muestra` (bloqueo) y `web_sobrecarga_geometria` (alerta).
- **Publicación en GitHub Pages, preparada sin remoto:** `.github/workflows/pages.yml` monta `web/` con los datos, el mapa base, la tabla larga y `version.json` del último *release*, comprobados con `SHA256SUMS`, genera la página «Método» (`metodo.html`, `method.html`) con pandoc y publica, sin secretos, con permisos mínimos y acciones oficiales fijadas por commit. `R/publicar.R`: `empaquetar_publicacion()` prepara el *release* en `publicacion/` (fuera de git) con los límites de GitHub y de Pages comprobados (74 MB el 8-nov-2026). Guía en `docs/publicacion.md`.
- **Menú:** Sobrecarga y Método enlazados desde el mapa y entre sí, con el idioma activo (`data-href-es` y `data-href-en`).
- Pruebas: `test-publicar.R`, `test-web-sobrecarga.R`, `pruebas/web/sobrecarga.test.mjs` y seis nuevas en `pruebas/web/datos.test.mjs`.

### Cambiado (8-nov-2026)

- SERPAVI: las 40 secciones del seccionado de 2021 que la base no trae van como `ausente` en los indicadores 8 y 9, en todos los años y tipologías (`completar_secciones_serpavi()`); el 21 y el 15 heredan esas filas. +2.080 filas en la tabla larga, todas `ausente`; ningún valor cambia. La cobertura por provincia se mide sobre el seccionado de 2021 (Navarra, 64,6 % en 2024). Compuertas `serpavi_seccionado` (bloqueo) y `serpavi_sin_fila` (alerta, 40).
- Web: `periodoPara()` admite periodos con mes y, sin año elegido, toma el último de cada serie; leyenda y ficha dicen el periodo y la tipología, y los supuestos solo en el sueldo necesario. Muestra con las variantes `alquiler_m2_vu` y `alquiler_mes_vu` y tres mapas `directo`; los valores anteriores no cambian.
- Tabla larga: 6.591.356 filas.
- Nota metodológica (castellano e inglés) al día: compuertas nuevas en §4.1, España en §7.2 y §7.3, las 40 secciones del SERPAVI en §7.1 y §7.4, la web de la sobrecarga en §7.5, tabla larga de 6.591.356 filas (§9.1) y datos de la web (§9.2: 8.486 ficheros y 109,8 MB con el PMTiles).

### Decidido (8-nov-2026, pregunta abierta 20; plan v0.24)

- Mapa del sueldo necesario en seis tramos, con un corte nuevo en 2.000 € (700 · 900 · 1.100 · 1.500 · 2.000 €), y rampa de seis pasos. En 2024, el último tramo pasa del 32 % al 13 % de las secciones.

### Cambiado (8-nov-2026, rampa de seis pasos)

- `diseno/tokens.json`: rampa #d9b25e · #d0893c · #bd5f2e · #a04025 · #7d291e · #4f1814, con los extremos de la de cinco y la claridad repartida en OKLab para separar los pasos contiguos con daltonismo simulado. Distancia mínima de 0,089, como la rampa de cinco. `tokens.css` regenerado, con `.tramo-6`.
- Compuerta nueva `rampa_daltonismo` (bloqueo; `R/web_estilo.R`): pasos contiguos a 0,08 en OKLab como mínimo, en visión normal y con protanopía, deuteranopía y tritanopía simuladas (Machado et al., 2009). `contraste_declarado` comprueba también la rampa.
- `cortes_web` admite de uno a cinco cortes (`MAX_CORTES_WEB`); el indicador 21 lleva cinco.
- Web: `js/colores.js` reparte los pasos de la rampa entre los tramos de cada mapa (con seis tramos, todos; «¿te llega?», el 1, el 4 y el 6) y decide el contorno de las secciones (tinta mientras contrasta 3:1). Leyenda, ficha y regla con cualquier número de tramos. Muestra con cinco cortes.
- Pruebas: 17 en la web y 555 en R, con las nuevas de la rampa y los cortes.

### Decidido (8-nov-2026, preguntas abiertas 18, 19 y 21; plan v0.23)

- Tartera: el SMI de 2015 a 2023 se completa en F3, con las cuantías de los reales decretos; cada descarga se pregunta antes.
- Derivados desde sus términos redondeados a un decimal, como los recibe la web, para que la página y R coincidan.
- `web/datos/` fuera de git, salvo la muestra, y publicado con el PMTiles desde un *release*.
- La 20 (sexto tramo en el mapa del sueldo necesario) queda en suspenso: exige un sexto color y la rampa tiene cinco pasos. Nueva propuesta: cinco tramos con los cortes 800 · 1.100 · 1.500 · 2.000 €.

### Cambiado (8-nov-2026, redondeo de los derivados)

- `R/derivados.R`: el alquiler, la renta por hogar y el ingreso de la ficha entran redondeados con `sprintf("%.1f")` (`termino_publicado()`, `ingresos_fichas()`) en el 14, el 15, el 21 y su compuerta. El 21 cambia 4,18 € de media y 8,33 € como máximo; la mediana de las secciones en 2024 pasa de 1.220 a 1.217 €. El 14 cambia como mucho 0,005 puntos. `derivados_rango_detalle` avisa ahora en 23 cifras.
- Nota metodológica (§7.1, §7.4 y compuertas), `web/LEEME.md`, guía y backlog al día. Pruebas: 539 en R.

### Añadido (8-nov-2026, derivados, datos de la web, «Tu sueldo» y nota en inglés)

- **Derivados** con el alquiler de vivienda colectiva y el estado del peor de sus términos (preguntas 12 y 15), en `R/derivados.R` y el bloque `bloque_derivados`:
  - 14, esfuerzo de residentes: alquiler mensual × 12 / renta media por hogar del ADRH, en sección y municipio, 2015–2024. En 2024, mediana del 17,6 % en las secciones;
  - 21, sueldo neto necesario: alquiler por m² × 50 / 0,30, en todas las escalas del SERPAVI, 2015–2024. En 2024, mediana de 1.220 € netos al mes;
  - 15, barrera de acceso: la mochila y la tartera de 2024, con el ingreso del mismo año que el alquiler, como control de la web.
  - `larga_derivados` en `tabla_larga` (fuente nueva `calculo_propio`; corte `ficha` con los grupos `tartera` y `mochila`): 6,6 millones de filas.
  - `perfiles`: ingreso neto mensual de la tartera (SMI de 2024 y 2026), la mochila (por provincia) y la llave (por sección y municipio); `resumen_perfiles_llave`. Correspondencia de las provincias de la AEAT con el INE (`inventario/provincias_aeat.csv`).
  - Compuerta `derivados_terminos`, `derivados_estado`, `derivados_rango`, `smi_neto` y `perfiles_mochila` (bloqueo), y `derivados_rango_detalle` (alerta; avisa en 26).
- **Datos de la web** (`R/web_exportar.R`; objetivos `cajas_municipios`, `ficheros_web` y `validacion_web`): manifiesto, índices por nivel, valores por serie, nivel y periodo, fichas por municipio con `series_municipio`, `territorios.json`, `cajas.json` y `perfiles.json`; copia del mapa base a `web/teselas/`. Toda España: 8.478 ficheros, 75 MB (15 MB comprimido). La unifamiliar como `alquiler_m2_vu` y `alquiler_mes_vu`; viviendas turísticas por periodo «AAAA-MM». Columna `cortes_web` en `inventario/indicadores.csv` (cuatro cortes fijos por mapa). Compuertas `web_valores` y `web_fichas` (bloqueo) y `web_fuera_indice` (alerta).
- **«Tu sueldo»** en la web: sueldo necesario calculado en el navegador con superficie (50/70/90 m²) y umbral (30/40 %); fichas como marcas en la regla y la llave como tramo; «¿te llega?» con sueldo propio (12 o 14 pagas, segundo sueldo) o con ficha, con la proporción de secciones en que cabe el alquiler; aviso si ingreso y alquiler son de años distintos. El sueldo no sale del dispositivo; «Compartir» avisa y lo lleva tras «#». `web/js/sueldo.js`, `panel_sueldo.js`, `compartir.js`.
- **Comparador** entre territorios (`web/js/comparador.js`), **buscador** de municipio y sección (`web/js/buscador.js`), leyenda plegable y nombres en orden natural (`web/js/nombres.js`).
- **Nota metodológica en inglés** (`docs/methodology.md`) y nota en castellano al día: alquiler, hogares en alquiler, viviendas turísticas, derivados, jerarquía, mapa base, datos de la web y decisiones 12–17. `test-metodologia.R` comprueba que las dos versiones citan lo mismo y dan las mismas cifras.
- Pruebas con datos inventados: `test-derivados.R`, `test-web-exportar.R`; pruebas de la web: 16, una de ellas del contrato con la exportación real.

### Cambiado (8-nov-2026, derivados y web)

- Fichas 14, 15 y 21: el cálculo dice que el alquiler es el de la vivienda colectiva y cómo se tratan los estados; el 21 ya no cita la estadística de fianzas entre sus fuentes. `smi_neto`: tolerancia de ±1 €.
- Textos de la interfaz en la sección `interfaz` de `web/i18n/es.json` y `en.json`; se borra `web/i18n/pendiente_interfaz.json`.
- `.gitignore`: `web/datos/` fuera de git, salvo la muestra (pregunta 21).

### Cambiado (8-nov-2026, web)

- Datos de la web en JSON de enteros (pregunta abierta 17): un fichero por indicador, nivel y año con `v` (valor × 10, `null` sin valor) y `e` (un carácter de estado por territorio: 0 dato, 1 estimado, 2 secreto, 3 ausente), en el orden del índice. Sustituye al binario.
- Ficha de sección con la evolución por años, desde un fichero de series por municipio (`fichas/<municipio>.json`).
- `web/js/datos.js`, `ficha.js`, `mapa.js` y `principal.js`; muestra regenerada (`web/herramientas/generar_ejemplo.R`, cinco años de ejemplo); `web/LEEME.md`; pruebas de la web: 5, con `node --test pruebas/web/datos.test.mjs`.

### Decidido (8-nov-2026, preguntas abiertas 12–17; plan v0.21)

- Alquiler (8, 9) y sus derivados (14, 15, 21): vivienda colectiva por defecto, con la unifamiliar como opción y sin mezclarlas.
- Errores de las hojas de municipios y distritos del SERPAVI: van como `ausente`; el aviso al MIVAU, si se envía, lo envía el autor.
- Viviendas turísticas desde febrero de 2024 y Censo 2021 en la v0.1; la tabla de paso desde el seccionado de 2011, en F6.
- Estado de los derivados: el peor de sus términos (`dato` < `estimado` < `secreto` < `ausente`).
- Mapa base: simplificación de medio píxel (35,2 MB) y publicación desde un *release*; códigos postales, del callejero.
- Datos de la web: JSON de enteros en lugar de binario, y un fichero de series por municipio para la ficha.

### Añadido (8-nov-2026, F2: SERPAVI, Censo, viviendas turísticas, mapa base, web y nota metodológica)

- **Indicadores 8 y 9** (alquiler mensual, mediana; alquiler por m²) con la base de datos del SERPAVI, 2015–2024, en el seccionado de 2021 sin tabla de paso (`R/fuente_mivau_serpavi.R`; bloque `bloque_serpavi`):
  - `descargar_mivau_serpavi()`: fichero manual (la web del MIVAU bloquea las descargas automáticas);
  - `leer_mivau_serpavi()`: las cinco hojas, de la sección a la comunidad con España;
  - `comprobar_mivau_serpavi()`: compuerta `serpavi_provincia`, `serpavi_espana`, `serpavi_secreto`, `serpavi_cuartiles` y `serpavi_escalas` (bloqueo), y `serpavi_escalas_detalle` y `serpavi_forales` (alerta). Pasa; avisa en 164 cifras de municipios y distritos que no cuadran con sus secciones, casi todas de Navarra en 2022–2024;
  - `armonizar_mivau_serpavi()`: tipología como corte (`tipologia`, `tipologia_p25`, `tipologia_p75`; grupos `VC` y `VU`) y estado `dato`, `secreto` (de 1 a 9 testigos) o `ausente`; País Vasco y Navarra desde su entrada;
  - secciones con mediana de vivienda colectiva: de 21.627 (2015) a 26.137 (2024).
- **Indicador 18** (hogares en alquiler) del Censo 2021 (`R/fuente_ine_censo2021.R`; bloque `bloque_censo2021`): t20_2 / t19_1, 34.970 secciones con dato y 1.363 en secreto; compuerta `censo2021_alquiler`, `censo2021_principales` y `censo2021_seccionado` (España, 16,10 % en el pipeline y en la tabla 59523).
- **Indicador 19** (viviendas turísticas sobre el total de viviendas) (`R/fuente_ine_vut.R`; bloque `bloque_vut`): seis periodos, de febrero de 2024 a mayo de 2026, en el seccionado de 2024, llevados al de 2021 con la tabla combinada; en las secciones 1:1 se copia el % del INE, en las demás se rehace con las viviendas del Censo 2021. Compuerta `vut_viviendas_provincia`, `vut_seccionado`, `vut_paso_2021` y `vut_denominador` (bloqueo), y `vut_denominador_detalle` (alerta). Ruptura `vut_seccionado_2024`.
- Vocabulario: cortes `tipologia`, `tipologia_p25`, `tipologia_p75` (grupos `VC`, `VU`) y `mes` (grupos `M02`, `M05`, `M08`, `M11`).
- `tabla_larga` incluye `larga_serpavi`, `larga_censo2021` y `larga_vut`.
- **Jerarquía territorial** del seccionado de 2021 (`R/geo_mapa_base.R`): `geo/jerarquia_2021.csv` (sección → distrito → municipio → provincia → comunidad) y `geo/territorios_2021.csv` (nombres, superior y número de secciones), con las compuertas `jerarquia_unica`, `jerarquia_sumas` y `jerarquia_nombres`.
- **Mapa base en PMTiles** (`geo/referencia/mapa_base_2021.pmtiles`, 35,2 MB, fuera de git), con GDAL desde R, sin tippecanoe: comunidades, provincias, municipios y secciones; simplificación de medio píxel por debajo del zoom 12. Objetivos `fichero_mapa_base`, `resumen_mapa_base` y `validacion_mapa_base` (compuerta `mapa_base_secciones`). Visor de comprobación en `geo/visor/` (`node geo/visor/servir.mjs`).
- **Web de la v0.1, esqueleto** (pila elegida por el autor: HTML y módulos JavaScript sin compilar): `web/index.html`, `web/js/`, `web/estilo/sitio.css`; cabecera, ES/EN, mapa MapLibre por tramos con la trama del secreto, leyenda, ficha de sección y estado de la vista en la URL (el sueldo nunca va en ella). MapLibre GL JS 6.15.0 y PMTiles 4.5.0 autoalojados en `web/vendor/` (BSD-3, con permiso del autor). Manifiesto de datos como punto de enganche y muestra con valores inventados en `web/datos/ejemplo/` (`web/herramientas/generar_ejemplo.R`). Servidor local `node web/servir.mjs`. Pruebas con `node --test pruebas/web/datos.test.mjs`.
- **Nota metodológica**, primera versión en castellano (`docs/metodologia.md`), con cifras trazables a su objetivo, función o CSV; `test-metodologia.R` comprueba que lo citado existe.
- Prueba de un año de la tabla combinada en toda España (`comparacion_vias`): en las 6.180 secciones de 2021 que el callejero reparte, dentro de ±5 %, del 61,2 al 94,1 %.
- Pruebas con datos inventados: `test-serpavi.R`, `test-censo2021-vut.R`, `test-mapa-base.R`.

### Cambiado (8-nov-2026, F2)

- `larga_adrh` depende también de `validacion_f1`: la compuerta de las tablas de paso va antes que la reproyección de la renta.
- Filas del inventario: `mivau_serpavi` (descarga manual; errores de las hojas de municipios y distritos), `ine_censo2021`, `ine_vut` e indicadores 18 y 19 (serie y lectura: numerador y denominador de años distintos).
- `.gitattributes`: `*.bin` como binario.

### Corregido (8-nov-2026)

- Las viviendas turísticas del INE no están en el seccionado de 2021 en todos sus periodos, como decían el plan (v0.9) y `inventario/fuentes.csv`: hasta febrero de 2023 usan las secciones del Censo 2011 y desde febrero de 2024, el seccionado de 2024.
- Plan §6.3: de 2021 a 2025 conservan el código 35.995 de 36.333 secciones y aparecen 559 (antes, 35.955 de 36.293 y 599).

### Cambiado (8-nov-2026, licencia)

- Datos derivados, textos e inventario pasan de CC BY 4.0 a CC BY-SA 4.0 (`LICENCIA_DATOS.md`, `README.md`; plan v0.19, §6.1). Las fuentes se tratan como datos abiertos (decisión del autor), incluidos el Catastro estatal y los forales de Bizkaia y Gipuzkoa, de licencia contradictoria (`inventario/fuentes.csv`).
- Las tablas de paso combinadas (callejero y Catastro), las que se usan, entran en git: `geo/tablas_paso/combinada_<año>_2021.csv` (objetivo `fichero_paso_final`).

### Añadido (8-nov-2026, catastros forales)

- Catastros forales de Álava, Bizkaia, Gipuzkoa y Navarra en la vía (b) de las tablas de paso (plan v0.18, §6.3). Fuente `catastro_foral` y fichero `R/fuente_catastro_foral.R`:
  - zips del territorio entero (Álava y Gipuzkoa) y por municipio (Bizkaia y Navarra, sacados de sus feeds ATOM): `zips_catastro_forales`, `seleccionar_zips_forales`, `descargar_catastro_foral`;
  - lector propio (`leer_catastro_foral`), que lee todos los GML de un zip y toma el año de construcción de la parte de la fecha que use cada territorio (`anio_construccion_foral`). No toca el lector del Catastro estatal, para no releer sus zips.
- Objetivos `municipios_forales`, `zips_forales_feeds`, `urls_forales`, `zips_forales`, `edificios_foral` y `edificios_forales`. Este último guarda solo los edificios de los municipios seleccionados. `edificios_paso` junta los estatales y los forales.
  - El bloque foral solo entra si el ámbito incluye alguna provincia foral: con `PROVINCIA=28` no hay nada que leer, y targets no admite ramas sobre una lista vacía.
  - `municipios_cubiertos` incluye ya los forales.
- Descarga y resultado:
  - 58 zips, 68,9 MB (con permiso del autor); 131.335 edificios con viviendas, 1.035.411 viviendas.
  - Censo 2021 en 11 municipios: −0,1 % en total.
  - Secciones de 2021 `estimado` en País Vasco y Navarra: de 300 a 2 en 2021 y de 360 a 62 en 2024.
- Pruebas con datos inventados de los enlaces, la selección de zips y el año de construcción (`test-catastro-foral.R`).

### Cambiado (8-nov-2026)

- Indicador 7: la lectura recoge el paso a neto de la mochila (ES y EN; diccionarios de la web regenerados).

### Añadido (7-nov-2026, mochila en neto)

- Paso a neto de la mochila (plan v0.17, §3.1, paso 3; regla 8): neto anual = bruto × (1 − cotización del trabajador − retención), ÷ 12 (`calcular_mochila_neta`, `mochila_neta`, `datos/intermedios/mochila/mochila_neta_2024.csv`). Cotización de 2024: 6,47 % (`COTIZACION_TRABAJADOR`). Retención: tipo medio de la AEAT de quien solo cobra salarios, por comunidad y tramo de renta anual, interpolado entre los salarios medios de los tramos (`retenciones_aeat`, `tipo_retencion`). 2024: de 990 € al mes (Huelva) a 1.529 € (Barcelona).
- Tabla *Grupos de población por la naturaleza de sus retribuciones* de la AEAT (`aeat_retenciones`; 162 páginas, 4,3 MB).
- `leer_aeat_mercado()` lee las filas agrupadas en bloques (cabecera de fila que abarca varias filas) y guarda el bloque en la columna `bloque`; las tablas sin bloques salen igual que antes.
- Control con la ECV: `leer_ecv_asalariados()` lee también el salario neto (PY010N) y `resumir_ecv_asalariados()` da su mediana. Alerta `mochila_neto_ecv` (±5 %): el paso a neto aplicado a la mediana del bruto de cada comunidad, frente a la mediana del neto. 2024: entre −2,0 y +3,4 %; España, +0,5 %.

### Cambiado (7-nov-2026, marcas)

- Sin registro de marca para *De renta en renta*: el proyecto es abierto y no comercial (decisión del autor). La búsqueda en TMview y en la OEPM no encontró la frase (plan v0.17, §10.1; backlog, tarea 2, cerrada).

### Añadido (7-nov-2026, geografía constante en toda España)

- El pipeline cubre las 52 provincias (plan v0.16, §6.3): tablas nacionales del ADRH (30824 y 30832), callejeros y seccionados enteros, y 1.420 municipios con edificios del Catastro (4,2 GB). La variable de entorno `PROVINCIA` lo limita a una provincia para pruebas. Memoria `transient` en `targets`. Una pasada completa, unas tres horas y cuarto.
- Tablas de paso del callejero nacionales en `geo/tablas_paso/callejero_<año>_2021.csv` (sustituyen a las de Madrid, `_28`), calculadas provincia a provincia.
- Catastro: feeds de las gerencias propias (Cartagena, Gijón, Jerez, Vigo, Ceuta y Melilla) y casado de municipios por nombre con variantes, artículos, bilingües, nombres cortados y una tabla manual de fusiones y cambios de nombre (`casar_municipios_catastro`). Los edificios se pasan al sistema del seccionado y se guardan con su sección de 2021.
- Fusiones y segregaciones de municipios (`geo_grupos_municipio`): las tablas y la prueba de cierre cruzan municipios dentro de un grupo.
- El Catastro decide también en las secciones con datos que no están en el callejero y donde la tabla combinada dejaría vacía una sección de 2021; las secciones con datos sin ninguna vía pasan por su código si existe en 2021 (`completar_por_codigo`).
- Alertas nuevas: `adrh_seccion_huerfana` (nueve secciones del ADRH con códigos de un seccionado anterior, fuera de la tabla y del cierre) y `cobertura_destino_excepcion` (dos secciones con un defecto conocido de la fuente, en `inventario/excepciones_cobertura.csv`).

### Cambiado (7-nov-2026, geografía constante en toda España)

- La renta por hogar de Madrid cambia en 33 cifras (menos de un 0,3 %): la tabla nacional del ADRH redondea el tamaño medio del hogar distinto que la provincial.

### Cambiado (7-nov-2026, método de la mochila)

- Mochila con el método B (plan v0.15, §3.1; pregunta abierta 7, cerrada): salario medio real de 26 a 35 años de la provincia × relación mediana/media del SME de su comunidad, en bruto anual (`mochila`, `datos/intermedios/mochila/mochila_2024.csv`). Las opciones A y C se siguen calculando (`mochila_opciones`) como registro de la decisión. Falta el paso a neto.
- Control con la ECV dentro del pipeline (`leer_ecv_asalariados`, `resumir_ecv_asalariados`, `comprobar_mochila_ecv`): mediana del bruto del año de los asalariados de 26 a 35 años por comunidad, con la ola de 2025 (ingresos de 2024). Alerta `mochila_ecv` (±15 %), que sustituye a la fila provisional de las referencias. 2024: entre −10,6 % y +7,2 % por comunidad.
- El CSV de personas de la ECV 2025 (`esudb25p.csv`) se toma de una copia local del zip original del INE, como los de hogares y registro; si falta, `obtener_csv_ine_ecv()` descarga el zip.

### Añadido (7-nov-2026, medición para toda España)

- Medición de las descargas para llevar la geografía constante a toda España (plan v0.14, §6.3): 1.489 municipios con secciones repartidas por el callejero en algún año; 3,57 GB de edificios del Catastro por bajar (1.256 zips) y unos 0,9 GB de las dos tablas nacionales del ADRH. Nada descargado todavía.
- Inventario: los feeds de edificios del Catastro de cada provincia permiten el uso gratuito citando a la D. G. del Catastro; el feed general sigue diciendo «all rights reserved».

### Añadido (7-nov-2026, mochila)

- Lectura de la AEAT, *Mercado de trabajo y pensiones* (`R/fuente_aeat_mercado.R`): busca la tabla en el mapa de la edición, recorre los menús de filtros y guarda cada página HTML en `datos/brutos/aeat_mercado/<año>/` (2024: 74 páginas, 3,6 MB). Los filtros pasan a columnas sin tildes (`distribucion_geografica`, `tramos_de_edad`…), porque `targets` no admite símbolos no ASCII en las funciones.
- Opciones A, B y C de la mochila por provincia (`R/ficha_mochila.R`, `mochila_opciones`), con la mediana del SME interpolada desde los deciles nacionales, y su comprobación frente a los centiles (`aeat_mediana_deciles`, alerta). Resultados y control con la ECV en el plan v0.14, §3.1. La pregunta abierta 7 sigue abierta.

### Cambiado (7-nov-2026, decisiones del autor)

- Preguntas abiertas cerradas (plan v0.14, §11): escalonado (v0.0, v0.1 con 10 indicadores, v1.0 con 23) y portales (capa desmontable, solo informes agregados) confirmados; sin dominio propio (la web irá en la dirección de GitHub Pages); País Vasco y Navarra sin alquiler por sección en los años sin SERPAVI, con las fianzas como capa municipal aparte; la sobrecarga sin intervalos, con el número de observaciones y la marca de fiabilidad; `adrh_suma_secciones` se queda como alerta.
- Tabla larga con dos columnas nuevas, `corte` y `grupo` (`total` por defecto). Entran la sobrecarga de España por tenencia y edad (cada año), la de comunidad × tenencia y comunidad × edad (tres olas agrupadas, con `anio` = la última) y la búsqueda sin éxito de España por edad, sexo y tenencia (tablas 79629 y 79635 del módulo). La compuerta comprueba cortes y grupos contra `inventario/vocabulario.csv`, que gana sus textos en castellano e inglés; `modulo_acceso_lectura` compara también el total de las tablas por edad y por tenencia.
- El ADRH 2015 pasa al seccionado y al callejero de 2016, como el resto de años (*t* + 1). Descargados `seccionado_2016.zip` y `caj_esp_012016.zip`. En Madrid no cambia casi nada: los dos seccionados tienen los mismos códigos (secciones `estimado` de 2021: 191, antes 192). La tabla `geo/tablas_paso/callejero_2015_2021_28.csv` se sustituye por `callejero_2016_2021_28.csv`.
- Agente de usuario de las descargas con el nombre nuevo.

### Cambiado (7-nov-2026, nombre)

- Nombre: *De renta en renta*, sin traducir; dicho de portada «De renta en renta, y pago porque me toca» (`web/i18n`, clave `sitio.dicho`). Carpeta y proyecto de RStudio: `de-renta-en-renta`; el repositorio de GitHub llevará el mismo nombre.
- Plan v0.13.

### Añadido (7-nov-2026, séptima tanda)

- Tablas de paso de todos los años del ADRH en Madrid (2015–2024): callejeros y seccionados de enero de 2017–2020, 2023 y 2024; una tabla por seccionado con `tarchetypes::tar_map()` (`PASOS_2021`). La renta de todos los años va en el seccionado de 2021 (plan v0.12).
- Edificios del Catastro leídos municipio a municipio (ramas dinámicas): un municipio nuevo no obliga a releer el resto.
- `geo_fase_codigos()` (diagnóstico): secciones del ADRH, del mapa y del callejero de cada año. Confirma que el ADRH del año t va con el seccionado de t + 1.
- Alerta `adrh_suma_secciones`: el ADRH no siempre suma sus secciones al total municipal que publica (2016, 2017 y 2019).
- Lectura del callejero de 2019 (tramos dentro de «TRAMOS-NAL.zip»; `patron_zip_interno()`).

### Cambiado (7-nov-2026, séptima tanda)

- `cierre_poblacional` compara con la suma de las secciones de origen de cada municipio, no con el total publicado: mide solo la tabla. La diferencia de la fuente la vigila `adrh_suma_secciones`.

### Añadido (7-nov-2026, sexta tanda)

- Tabla 2022 → 2021 combinada con el Catastro (seccionado de 2022) y prueba de un año de la vía (b): en las secciones que el callejero reparte, los errores de más del 20 % bajan de 50 a 7 (plan v0.11, §6.3). La renta de 2021 usa la tabla combinada.
- Secciones «fantasma» del seccionado (códigos del mapa que no están en el callejero ni en el ADRH del mismo año): sus edificios pasan al origen de los datos que cubre el mismo destino (`reasignar_fantasmas()`).
- Compuerta `cobertura_destino` (bloqueo): ninguna sección de 2021 se queda sin recibir nada de la tabla de paso (`comprobar_cobertura_destino()`).

### Cambiado (7-nov-2026, quinta tanda)

- Tablas de paso combinadas (plan v0.10): callejero donde las secciones caen enteras y Catastro donde hay que repartir (`combinar_vias()`), con edificios filtrados por año de construcción y sin pares entre municipios. Se usan en la renta de 2015 y 2024 y en la prueba de cierre; la de 2022 sigue con el callejero.
- El pipeline carga `sf` en todos los pasos (filtrar objetos espaciales guardados).

### Añadido (7-nov-2026, cuarta tanda)

- Vía (b) de las tablas de paso, Catastro (`R/fuente_catastro_inspire.R`): feed ATOM, municipios casados por nombre con el INE, edificios con viviendas, tabla de paso por viviendas, combinación con el callejero y comparación de las dos vías. Prueba en los 55 municipios de Madrid con secciones `estimado`: en esas secciones, los errores de más del 20 % bajan de 128 a 27.
- Pruebas de la vía (b) con geometrías inventadas.

### Añadido (7-nov-2026, tercera tanda)

- Kit de diseño en la web (backlog, tarea 9): `web/estilo/tokens.css` generado desde `diseno/tokens.json`, tipografías autoalojadas con su licencia y compuertas `contraste_texto`, `contraste_declarado` y `rampa_contorno` (`R/web_estilo.R`).
- Corrección: Yellowtail tiene licencia Apache 2.0, no OFL (`tokens.json`, `diseno/LEEME.md`).

### Añadido (7-nov-2026, segunda tanda)

- Fichas de los 23 indicadores en castellano e inglés (backlog, tarea 8): unidad, definición, cálculo y lectura en `inventario/indicadores.csv`.
- Diccionarios de la web (tarea 10): `exportar_i18n()` genera las secciones de indicadores, fuentes y vocabulario de `web/i18n/` desde el inventario; `nombre_en` en `fuentes.csv`; `inventario/vocabulario.csv`; compuerta `i18n_completo`.

### Añadido (7-nov-2026)

- Sobrecarga (F1b): tres olas de la ECV (2023–2025) con `tarchetypes::tar_map()`, corte por edad (RB081), cruces comunidad × tenencia y × edad con las olas agrupadas y marca de fiabilidad de EU-SILC (`calcular_sobrecarga_agrupada()`); datos europeos de Eurostat (`descargar_eurostat_europa()`), geometrías NUTS 2021 y 2024 de GISCO (`R/fuente_gisco_nuts.R`) y «escalera» (`armar_escalera()`). Nuevas comprobaciones: `sobrecarga_es_edad` y `nuts_geometria` (alertas).
- Indicador 23 desde las tablas del módulo de acceso de la ECV 2025 (`R/fuente_ine_ecv_modulo.R`; fuente `ine_ecv_modulo`; comprobación `modulo_acceso_lectura`).
- Tabla larga única con los indicadores 1–3, 22 y 23; nivel `nacional` («00») y tabla fija de comunidades `geo/ccaa.csv` (código del INE, nombre y NUTS 2).
- Plan: preguntas abiertas 9 (intervalos de confianza) y 10 (desgloses en la tabla larga).

### Añadido (6-nov-2026, séptima tanda)

- Comprobación del nombre (backlog, tarea 2): GitHub, dominios y marcas de las tres candidatas (plan §10.1). Decisión pendiente.

### Añadido (6-nov-2026, sexta tanda)

- Pipeline de punta a punta (backlog, tarea 7): renta del ADRH de Madrid (indicadores 1–3) leída, validada (`adrh_municipio`, bloqueo; `adrh_municipio_detalle`, alerta), llevada al seccionado de 2021 con estado y escrita en la tabla larga en Parquet (`validar_tabla_larga()`, `exportar_tabla_larga()`).
- `geo_tabla_identidad()` y `geo_cobertura_origenes()`: el año nativo pasa sin tabla y los orígenes con secreto marcan el destino como `estimado` o `secreto`.
- Pruebas de la tabla larga y de la armonización del ADRH.

### Cambiado (6-nov-2026, quinta tanda)

- Inventario de fuentes (backlog, tareas 3 y 4): acceso, licencia citada, cadencia y desfase comprobados en las fuentes de la v0.0 y la v0.1 (INE, Eurostat y GISCO, AEAT, Seguridad Social, Catastro, Gobierno Vasco); nueva fuente de referencia `nastat_epav`; ruptura `vut_calendario_2024`.
- Plan v0.9: revisión del método de la mochila (pregunta abierta 7), alquiler del País Vasco y Navarra sin SERPAVI (pregunta abierta 8), huecos y versiones NUTS del mapa europeo, vía (b) del Catastro.
- `LICENCIA_DATOS.md`: las geometrías NUTS de GISCO quedan fuera de la licencia CC BY 4.0.

### Añadido (6-nov-2026)

- Esqueleto del repositorio: estructura de carpetas, licencias (MIT y CC BY 4.0), `CITATION.cff`, `.gitignore`, `.gitattributes` y proyecto de RStudio.
- Guía de trabajo (`docs/guia_de_trabajo.md`) y backlog de F0 (`docs/backlog_f0.md`).
- Plan de integración v0.3 (`docs/plan_integracion_atlas.md`).
- Inventario inicial: 25 fuentes, 23 indicadores, 12 referencias de validación y una ruptura (`inventario/`).
- Kit de diseño del tablero: colores con contrastes calculados, tipografías y cinco fichas en SVG (`diseno/`).
- Pipeline mínimo (`_targets.R`), utilidades comunes y pruebas del inventario.

### Añadido (6-nov-2026, tercera tanda)

- Prueba de F1 en Madrid (backlog, tarea 6): lectura del seccionado (`R/fuente_ine_seccionado.R`), del callejero (`R/fuente_ine_callejero.R`) y de la población por sección del ADRH (`R/fuente_ine_adrh.R`); tablas de paso por el callejero, reproyección de recuentos, prueba de cierre, diagnóstico sección a sección y cambios de límites (`R/comun_geo.R`); exportación de las tablas (`R/comun_exportar.R`, `geo/tablas_paso/`).
- Rupturas `callejero_aplicacion_2021` y `callejero_diseno_2025`.
- Pruebas de las tablas de paso con tramos inventados, incluido el caso de las pseudovías.
- Prueba de un año en Madrid (tabla 2022 → 2021 y diagnóstico frente al ADRH 2020).
- Regla de estado de las cifras reproyectadas (`dato`, `estimado`, `ausente`), adoptada en el plan v0.7: `geo_estado_paso()`, `geo_reproyectar_media()` y `geo_reproyectar_mediana()`; `geo_reproyectar_recuento()` devuelve el estado.
- Medianas reproyectadas: se copia la del origen dominante (≥ 95 % de los portales) como `estimado` en lugar de dejarlas `ausente` (plan v0.8). `geo_estado_paso()` devuelve el origen de la copia.

### Añadido (6-nov-2026, segunda tanda)

- Indicador 22, sobrecarga por gastos de vivienda (backlog, tarea 5): descarga y lectura de los microdatos de la ECV (`R/fuente_ine_ecv.R`), cálculo con el método de Eurostat por total, tenencia y región NUTS 2, y consulta de las cifras de Eurostat (`R/fuente_eurostat_ilc_lvho07.R`). Con la ECV 2025 pasa la compuerta en España, inquilinos a precio de mercado y las 19 comunidades.
- Compuerta de publicación (`R/comun_validar.R`): `validar_referencias()` lee la tolerancia y el tipo de `inventario/referencias_validacion.csv`; los bloqueos paran el pipeline.
- Descargas con caché (`R/comun_descargar.R`).
- Pruebas de la sobrecarga y de la compuerta con datos inventados.

### Cambiado (6-nov-2026)

- Entorno (backlog, tarea 0): R 4.6.1 con `renv`; `renv.lock` fija todas las versiones de la biblioteca del proyecto.
- SERPAVI por sección censal (backlog, tarea 1): descarga directa de la base de datos del MIVAU, 2011–2024, en el seccionado del Censo 2021. Fila `mivau_serpavi` completa; `gv_emal` acotada a los años sin SERPAVI en el País Vasco; nueva ruptura `serpavi_forales`; la referencia `serpavi_provincia` pasa a comprobar recuentos de testigos, con tolerancia exacta.
- Plan v0.4: cobertura real del SERPAVI (§2.4), geografía constante del alquiler (§6.3) y pregunta abierta sobre el seccionado de referencia (§11).
- Plan v0.5: el seccionado de referencia es el del Censo 2021, no el último; tablas de paso en las dos direcciones (§6.3). Guía, backlog (tarea 6), `geo/LEEME.md` e inventario, al día.
- Indicador 8: «Alquiler mensual (mediana)» en lugar de «Alquiler medio mensual».

### Procedencia

- Convenciones de redondeo y de códigos territoriales: reaprovechadas de un proyecto propio anterior.
- Fichas SVG y paleta: maquetas de diseño (`docs/maquetas.md`).
