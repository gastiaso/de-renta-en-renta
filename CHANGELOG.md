# Registro de cambios

Formato inspirado en *Keep a Changelog*, en castellano. Versiones previstas: v0.0 (sobrecarga y Europa), v0.1 (núcleo por sección censal), v0.2 a v0.4 (salarios, compraventa, presión y portales), v1.0. Tras la v0.1 no hay releases intermedios: lo de F3 a F6 se acumula en «Sin publicar» y sale junto en la v1.0; v0.2 a v0.4 quedan como hitos internos (decisión del autor, 9-nov-2026).

## [Sin publicar]

### Añadido (10-nov-2026, pregunta nueva y oferta de Idealista)

- Pregunta rectora nueva en el plan, la nota (ES y EN), el README y los diccionarios (`sitio.gancho`, `sitio.lema`, `sitio.familias`).
- `inventario/portales_idealista_territorios.csv`: los 815 territorios de los informes de alquiler de Idealista, con su código del INE (286 municipios, donde vive el 59,3 % de la población).
- `docs/metodo_corto.md`: borrador del método en dos páginas, con la tabla de licencias.
- `docs/backlog.md`: tablas del INE con contratos nuevos (59004 y 59005), contraste con la oferta, cifras de referencia de la brecha entre entrar y quedarse, tramos calculados del indicador 14 y lectura de la metodología del SERPAVI de 18-mar-2026.

### Decidido (10-nov-2026, backlog integrado y tramos de color; plan v0.44)

- **Mapa inicial de «Entrar»** (51): la brecha entre oferta y parque; los sueldos para entrar, en la ficha.
- **Indicador 14**, fuera del selector del mapa; **indicador 15**, «Peso del alquiler en el ingreso».
- **Tramos de color:** cortes fijos entre años, tres juegos por escala y siete tramos. Propuesta en `inventario/cortes_web_niveles.csv`.
- **Lectura externa:** dos lectores. **Pensionista:** media con aviso.

### Decidido (10-nov-2026, entrar y quedarse; plan v0.43)

- **Dos familias** (50): «Quedarse» (parque alquilado, SERPAVI) y «Entrar» (oferta de Idealista e IPVA de contratos nuevos), sin mezclarlas; pregunta rectora reformulada; mapa inicial de «Entrar» por municipio.
- **Sueldo necesario** con dos cifras: alquiler mediano real y mínimo teórico de 50 m².
- **Idealista**, solo en la web; el alquiler de oferta vuelve a la v1.0 (se revierte la 49).
- **Backlog integrado** hacia la v1.0: `docs/backlog.md` (tareas 33–61); `docs/backlog_f0.md` queda como histórico.

### Decidido (10-nov-2026, revisión de las preguntas abiertas 43–48; plan v0.42)

- **Indicador 11** (45): Registradores (Estadística Registral Inmobiliaria, ODbL) en lugar del Notariado, a escala de municipio y sin mezclar fuentes.
- **Mochila de 2015–2018** (44): `estimado`, con comprobación con la ECV.
- **Resto** (43–48): según el plan, §11; tareas en el backlog (32). Criterio de F6: el calendario «avisa».
- **Corte de la v1.0** (49): los datos de portales (indicador 13 y banda SERPAVI–oferta) pasan a la v1.1; la v1.0 no depende de datos de terceros.

### Añadido (10-nov-2026, F6: la vivienda como problema en la máquina del tiempo)

- `historico.html`: bloque «La vivienda como problema (CIS)», tras las series del histórico y en el mismo eje de años desde 1987: España y personal, mensual desde 2014, con la línea cortada en los 15 y 13 meses sin dato (agosto no cuenta: no hay barómetro) y los meses sueltos como punto; globo con el mes, las dos cifras, el estudio y las entrevistas; lectura generada (primer dato, máximo, último y meses sin dato); cita del CIS con su licencia (CC BY 4.0), advertencia «opinión, no registro» y tabla de cifras. Sin `datos/cis_vivienda.json`, el bloque dice que no hay datos.
- Los seis gráficos de la página se leen también con el teclado (Tab, flechas, Inicio, Fin y Escape).
- La compuerta `cis_vivienda_web` comprueba también el estudio y las entrevistas de cada mes.
- Nota metodológica, §7.10: la página ya muestra la serie; el máximo de octubre de 2026 es 55,7 % (no 55,6).

### Añadido (10-nov-2026, F6: CIS y calendario de fuentes; tarea 31; plan v0.41)

- La vivienda como problema (CIS): % de entrevistados que cita la vivienda entre los tres principales problemas de España y entre los que más le afectan personalmente, por barómetro mensual, de enero de 2014 a octubre de 2026 (126 y 128 meses; del 1,5 al 55,7 % en España). Fuente abierta y sin registro: tabulaciones en XLSX (desde febrero de 2025) y resultados en HTML (2014–enero de 2025) de cada barómetro (`R/fuente_cis_barometros.R`). Tabla propia, fuera de la tabla larga, y `datos/cis_vivienda.json` para la página del histórico, que la muestra. Compuerta `validacion_cis` con las notas de prensa del CIS (cinco cifras exactas) y `validacion_web_cis`.
- Calendario de fuentes (`inventario/calendario_fuentes.csv`, 27 fuentes; `R/calendario_fuentes.R`): qué fuentes tocan a una fecha, objetivo `fuentes_pendientes`, que avisa cuando cambia ese conjunto, renovación con `cal_actualizar()` y `cal_restaurar()` (reversibles; nada se renueva solo ni en el repositorio remoto) y compuerta `validacion_calendario`. Procedimiento en `docs/actualizacion.md`. El objetivo del CIS (`cis_estudios`) se vuelve a ejecutar solo cuando toca un barómetro nuevo.
- Nota metodológica: §7.10 (CIS) y §9.3 (calendario), en castellano e inglés.
- Descargas (10-nov-2026, CIS): páginas de los barómetros de 2008 a 2026 (solo su JSON-LD, 5,9 MB) y resultados de 2014 a 2026 (59 MB), con pausas entre peticiones y respetando `robots.txt`.

### Decidido (10-nov-2026, F6: CIS y calendario)

- Condiciones del CIS: reutilización libre citando la fuente, sin desnaturalizarla ni atribuirle carácter oficial (Ley 37/2007); CC BY 4.0 en los metadatos de cada estudio (verificado el 10-nov-2026). No se usan el catálogo de series (protegido frente a accesos automatizados) ni los datos que excluye `robots.txt`. Los microdatos, que darían el dato por comunidad, piden un formulario con aceptación de condiciones: quedan para el autor.
- Por revisar (plan §11, pregunta 48): serie desde 2014 con huecos (julio de 2014 y cinco meses de 2025 solo en PDF); abril y mayo de 2020 fuera (sin la categoría); una nota de prensa sin su mes pasa a la alerta de cobertura; la señal del calendario salta cuando cambia lo que toca; nada se renueva solo.

### Añadido (10-nov-2026, F6: módulo histórico, «máquina del tiempo»; tarea 30; plan v0.40)

- Módulo histórico en una tabla propia, no en la tabla larga (`historico`, `datos/intermedios/historico.parquet`, 3.704 filas; `R/historico.R`): años de renta y esfuerzo teórico sin deducciones del Banco de España, trimestrales desde el primer trimestre de 1987 (`R/fuente_bde.R`); tipos oficiales de referencia del mercado hipotecario, mensuales (tipo medio de las hipotecas a más de tres años, desde noviembre de 1990, y MIBOR a un año, desde 1987); valor tasado del MIVAU desde 1995, de España y las comunidades (lectura de F4), y sueldo bruto medio por asalariado de la Contabilidad Nacional del INE, 1995–2025 (`R/fuente_ine_cne.R`).
- Compuerta del módulo: `hist_series`, `hist_publicadas` (tabla en PDF del Banco de España del 5-nov-2026 y BOE de agosto de 2026), `hist_publicadas_enteras`, `hist_prensa`, `hist_fechas`, `hist_valor_tasado_bde` (el valor tasado del MIVAU es igual al que reproduce el Banco de España en 126 trimestres), `hist_valor_tasado_ccaa` (alerta: 15 trimestres de 1995–2013, de la fuente), `hist_salarios_suma` y `web_historico`. Fechas clave y cifras publicadas en `inventario/historico_fechas.csv` e `inventario/historico_referencias.csv`; rupturas `bde_mibor_euribor_1999` y `bde_tipo_circular_2003`.
- Página «Máquina del tiempo» (`web/historico.html`; datos en `datos/historico/historico.json`, `R/web_historico.R`), en castellano e inglés: cinco gráficos con el mismo eje de años, fechas clave, lectura sin valoraciones, tablas y el valor tasado por comunidad. Entrada al final del menú de todas las páginas; la casilla «Sube el euríbor» de la portada lleva a sus tipos.
- Descargas comprobadas enteras, con reintento, en los lectores del módulo: la tabla 71129 del INE llegó cortada sin error.
- Nota metodológica: §7.9 y nueve filas en §4.1, en los dos idiomas.
- Descargas (10-nov-2026, fuentes oficiales del plan): tablas `si_1_5` y `be1901` del Banco de España (0,45 MB) y tablas 71129 y 71133 de la Contabilidad Nacional del INE (11,5 MB).

### Decidido (10-nov-2026, F6: módulo histórico)

- Reutilización de las estadísticas del Banco de España verificada (términos de uso): permitida sin alterar contenido ni metadatos, citando «Elaboración propia con datos extraídos del sitio web del Banco de España (www.bde.es)» y la fecha de actualización, y sin sugerir su participación.
- Cifras del Banco de España del plan, contrastadas con la serie: 1987, menos de tres años solo en el primer trimestre (2,90); máximo de 9,46 en el tercer trimestre de 2007 (la prensa daba 9,45); máximo del esfuerzo, 72,47 % en el segundo trimestre de 1990. No coincide la de 7,6 años en 2023: la media de 2023 es 7,1 (7,6 es la de 2025). Corregidas en el plan (§2.5 y §10.2).
- Por revisar (plan §11, pregunta 47): tabla propia del módulo; solo el esfuerzo sin deducciones; tipos de referencia oficiales; sueldo de la Contabilidad Nacional; valor tasado trimestral; fechas clave; casilla «Sube el euríbor».

### Añadido (10-nov-2026, F5: presión; tarea 29; plan v0.39)

- Indicador 20, zona de mercado residencial tensionado declarada (`R/fuente_zonas_tensionadas.R`): las 10 resoluciones trimestrales del MIVAU en el BOE (Ley 12/2023, art. 18), de marzo de 2024 a noviembre de 2026, en `inventario/zonas_tensionadas.csv` (321 filas, 320 municipios: Cataluña 271, Navarra 21, País Vasco 21, Asturias 5 y Galicia 2; 8 declaraciones de una parte del municipio). Compuerta `validacion_zonas_tensionadas` contra el XML de cada resolución. En la tabla larga, los 8.131 municipios de 2024 a 2026 con la situación a 31 de diciembre (2 todo el municipio, 1 una parte, 0 ninguna): 271, 304 y 320 declarados. Tabla larga: 11.482.839 filas (+24.393).
- Indicador 13, capa desmontable de precios de oferta de los portales (`R/fuente_portales.R`), sin datos reales: con `PORTALES=TRUE`, CSV manuales de los informes agregados de las salas de prensa en `datos/brutos/portales/` (formato en el fichero), compuerta `portales_*` y corte `oferta_privada`; etiqueta «dato privado de oferta» en el mapa, la leyenda, la ficha, el CSV y el PNG. Apagada (por defecto), la tabla larga y la web quedan como sin capa. Probada en los dos sentidos con datos inventados (`pruebas/datos/`, `test-portales.R`).
- Web: mapas sin sección (`nivel_minimo` en el manifiesto: los municipios a toda escala y las secciones apagadas), mapas de categorías (`categorias`) y por grupo; ficha del municipio con sus declaraciones de zona tensionada (`datos/zonas_tensionadas.json`, compuerta `web_zonas_tensionadas`). Mapas de F4 conectados (10, 12, 16 y 17), con cortes por revisar.
- Pruebas: `test-zonas-tensionadas.R`, `test-portales.R`, `pruebas/web/municipal.test.mjs` y `navegador_municipal` en `comprobar_web_navegador()` (39 filas, todas a 0).
- Código reaprovechado: normalización de nombres de municipio de un script propio anterior de zonas tensionadas (10-nov-2026).
- Descargas (10-nov-2026, BOE): XML de las 10 resoluciones (138 KB) y sumarios diarios del BOE para localizarlas (unos 362 MB en dos barridos, borrados).

### Decidido (10-nov-2026, F5: presión)

- La fuente del 20 son las resoluciones del MIVAU en el BOE (art. 18.2.d), que recogen las declaraciones de las comunidades con su enlace; vigencia de tres años desde el día siguiente a la publicación.
- Por revisar (plan §11, pregunta 46): situación a 31 de diciembre; ámbitos parciales pintados en todo el municipio con su categoría; sin solicitudes denegadas; formato de la capa de portales y un mapa por operación y portal; decimales del valor tasado y de los años de salario; cortes de los mapas de F4.

### Añadido (10-nov-2026, F4: compraventa; tarea 28; plan v0.38)

- Indicador 10, variación anual del alquiler (IPVA del INE; `R/fuente_ine_ipva.R`): la cifra publicada, en total, de 2015 a 2024, de España a los distritos de las capitales (17 comunidades, 48 provincias, 718 municipios y 407 distritos; sin País Vasco ni Navarra). 11.910 filas. Compuerta `validacion_ipva`.
- Indicador 12, valor tasado de la vivienda libre (MIVAU; `R/fuente_mivau_valor_tasado.R`), del boletín estadístico en línea del Ministerio: año = media de los cuatro trimestres ponderada por las tasaciones, 2015–2025, de España a los 306 municipios de más de 25.000 habitantes. Nombres del Ministerio casados con el INE (`inventario/nombres_mivau.csv`). 4.048 filas. Compuerta `validacion_valor_tasado`.
- Indicadores 16 (años de salario para comprar) y 17 (esfuerzo hipotecario teórico), con 80 m², el salario medio de la AEAT del mismo año (indicador 7) y, en el 17, el tipo medio de las hipotecas sobre viviendas del INE (`R/fuente_ine_hipotecas.R`, `R/derivados_compraventa.R`), 2015–2024. España, 2024: 6,1 años y 28,7 %. Compuerta `validacion_derivados_compraventa`.
- Compuerta de coherencia entre tasación y escrituras ante notario (transacciones inmobiliarias del MIVAU): superficie implícita de España entre 91,8 y 106,1 m² (2015–2025). `validacion_coherencia_compraventa`.
- Tabla de paso código postal ↔ municipio desde el callejero de enero de 2021: `geo/codigos_postales_2021.csv` (11.046 códigos postales; `R/geo_codigos_postales.R`; compuerta `validacion_cp_municipio`).
- Tabla larga: 11.458.446 filas (+23.298 de F4).
- Código reaprovechado: lectura de las hojas del valor tasado de un proyecto propio anterior (10-nov-2026).
- Descargas (10-nov-2026, fuentes oficiales del plan): tablas del IPVA y de hipotecas del INE (2,2 MB) y cuatro ficheros del boletín del MIVAU (4,6 MB).

### Decidido (10-nov-2026, F4: compraventa)

- El Notariado no permite reutilizar sus cifras (solo uso personal, sin autorización expresa; términos y aviso legal consultados el 9 y el 10-nov-2026): el indicador 11 queda fuera y el atlas no descarga sus datos. Las escrituras entran por la estadística de transacciones del MIVAU, solo para la compuerta de coherencia.
- Por revisar (plan §11, pregunta 45): año del valor tasado ponderado por tasaciones; 16 y 17 con el salario de la AEAT; tipo medio del INE; pesos de la tabla código postal ↔ municipio; mapas de F4 con el municipio como nivel más fino.

### Añadido (10-nov-2026, F3: salarios; tarea 27; plan v0.37)

- Indicador 7, salario medio anual por asalariado (AEAT, *Mercado de trabajo y pensiones*), en total y de 26 a 35 años (grupo `Y26-35`), por provincia, comunidad y España, de 2011 a 2024, en la tabla larga (`larga_salarios`, 2.016 filas; `R/fuente_aeat_salarios.R`). País Vasco y Navarra, `ausente`: la AEAT no los cubre y, de las haciendas forales, solo Gipuzkoa publica una cifra comparable, en PDF. Compuerta: `aeat_provincia`, `aeat_salarios_cobertura`, `aeat_salarios_suma` y `aeat_salarios_media` (bloqueo).
- Mochila de 2015 a 2024 con el método en cinco pasos: salario medio de 26 a 35 años de la provincia × relación mediana/media del SME de su comunidad y año (de 2015 a 2018, la de 2019), a neto con la cotización y la retención de cada año, y control con la ECV de cada año (olas de 2016 a 2025). De 920 € netos al mes (2015) a 1.330 € (2024), media de las provincias; la de 2024 no cambia. Compuertas `mochila_cobertura` (bloqueo) y `mochila_forma` (alerta). Barrera de la mochila (15) de 2015 a 2024 en la tabla larga (+494.955 filas); la web usa la mochila del año del alquiler.
- Percentil salarial del sueldo necesario: curvas de lo cobrado en el año por los asalariados de cada comunidad y de España (AEAT, tramos de salario por comunidad), netas en 12, de 2015 a 2024 (`R/percentil_salarial.R`, `datos/salarios.json`); la ficha lo da en el mapa del sueldo necesario («Percentil 84 de los salarios (Comunidad de Madrid, 2024; …)»), con la superficie y el umbral elegidos (`web/js/percentil.js`). Compuertas `percentil_cobertura`, `percentil_monotono`, `percentil_suma`, `percentil_limites` y `web_salarios` (bloqueo) y `percentil_media` (alerta).
- Descargas (10-nov-2026, fuentes oficiales del plan): tablas de la AEAT de 2011 a 2024 (≈ 32,5 MB, 985 páginas) y microdatos de la ECV de 2016 a 2022 (≈ 238 MB).

### Cambiado (10-nov-2026, F3: salarios)

- `leer_aeat_mercado()` lee también las ediciones de 2011 a 2014 (`aeat_sangria()`).
- `R/ficha_mochila.R`, con códigos del INE y año; las opciones A y C, como columnas de `mochila`. Las retenciones de la AEAT se leen una vez por año para el transistor y la mochila.
- Nota metodológica (castellano e inglés): §5.6 y §6.6 nuevas, §6.2 rehecha y al día §1, §2.1, §4.1, §4.2, §6.1, §7.4, §8, §9 y §10.

### Decidido (10-nov-2026, F3: salarios; por revisar por el autor, plan §11, pregunta 44)

- Percentil con lo cobrado en el año (tramos de salario de la AEAT, 2015–2024), no con el SME del módulo de año completo (2019–2024, sin quien no llega al SMI).
- El percentil sale como nota de la ficha, en el mapa del sueldo necesario, no en la leyenda; va en `datos/salarios.json`, no en la tabla larga.
- Grupo de edad `Y26-35`, el tramo que publica la AEAT; forales del indicador 7, `ausente`.
- Mochila de 2015 a 2018 con la relación mediana/media de 2019; `mochila_ecv` deja la tolerancia en ±15 % (avisa en 32 de 160 cifras, de olas antiguas); `percentil_suma` con ±10 asalariados.

### Añadido (10-nov-2026, portada y mapa por niveles; tareas 24–26; plan v0.36)

- **Portada** (`docs/especificacion_portada.md`): la raíz es el tablero y el mapa pasa a `mapa.html`. Los enlaces ya compartidos a la raíz con el estado de la vista o un sueldo se redirigen a `mapa.html` con la misma consulta y el mismo fragmento antes de pintar (`web/js/redireccion.js`); en todos los menús, «Mapa» va a `mapa.html` y el título a la portada (también en «Método» y «Datos», que ganan «Tu sueldo»). Centro con el dicho, «Tu sueldo» (el sueldo va al mapa tras «#», nunca en la consulta), buscador y «Tira el dado»; cinco fichas; 24 casillas desde `inventario/casillas_portada.csv` (13 activas, bandas por familia, nada propio de Monopoly; `escribir_casillas_portada()`); tres cartas con cifras de la tabla larga en `web/datos/portada.json` (`exportar_portada()`): sueldo necesario de la sección mediana en 2024, 1.217 € (de 700 a 2.117 € entre los percentiles 10 y 90); con el salario mínimo de 2024, el piso de 50 m² pasa del 30 % del ingreso en el 48,4 % de las secciones y del 40 % en el 24,7 %; sobrecarga de 2025, 26,8 % en el alquiler a precio de mercado y 7,2 % en total. Compuertas `portada_valores` y `portada_casillas` (bloqueo, `validacion_portada`).
- **Mapa por niveles** (tarea 26): comunidades (zoom < 4), provincias (4–5), municipios (5–7) y secciones, cada nivel con sus cifras publicadas y su clic; ficha de territorio con la cifra de su nivel o «sin dato en este nivel» (regla 1), evolución y comparador con los niveles que lo contienen; enlazable (`territorio=municipio:28079`). En comunidades, las fichas con ingreso provincial no tienen cifra. CSV también por comunidad. El buscador abre la ficha del municipio elegido.
- **Etiqueta al pasar el ratón** (tarea 25): municipio, distrito y código de la sección; nombre del municipio, la provincia o la comunidad y el del territorio superior. No sale con el dedo.
- **F3: 14 pagas y segundo sueldo en la ficha**: en el sueldo necesario, la paga en 14 pagas y lo de cada uno entre dos sueldos iguales; con «Tu ficha», el desglose de su ingreso.
- Pruebas: `pruebas/web/portada.test.mjs` y `pruebas/testthat/test-portada.R`; `comprobar_web_navegador()` abre el mapa en `mapa.html` y comprueba además la redirección, la portada en los dos idiomas con sus cartas, los destinos de las casillas, «Tu sueldo» desde la portada, el ancho de 375 px, la ficha de una comunidad, una provincia y un municipio frente a la tabla larga, y la etiqueta y el clic en cada escala (0 de 33 filas mal, en local).

### Decidido (10-nov-2026, portada; por revisar por el autor, plan §11, pregunta 43)

- `?idioma=en` solo no redirige: abre la portada en inglés. `#tu-sueldo` en la raíz sí redirige.
- `casillas_portada.csv` lleva `destino_en` para las anclas que cambian con el idioma.
- Casillas: «Compartir piso» abre el sueldo necesario de 70 m²; «Cobra la pensión», activa (el transistor ya tiene datos); «Mudanza» deja elegido el comparador con el municipio para la sección que se pulse.
- Franjas de zoom del mapa: comunidades < 4, provincias 4–5, municipios 5–7.

### Decidido (9-nov-2026, publicación; plan v0.35)

- **Sin releases hasta la v1.0** (decisión del autor): los cambios de F3 a F6 se acumulan y se publican juntos en la v1.0; v0.2 a v0.4 quedan como hitos internos del plan. El sitio sigue con los datos del `v0.1.0`. El paquete que se preparó para un `v0.1.1` (datos del commit `e0d5132`) no se publica.
- **Sitio congelado en la v0.1** (decisión del autor): el flujo de Pages solo se lanza a mano y monta una referencia fija (`ref`, por defecto el commit `cdd9892`) con los datos del último release; un push a `main` ya no publica. La página «Datos» vuelve con la v1.0.

### Decidido (9-nov-2026, portada y mapa; plan v0.34)

- **Portada** (tarea 24): el tablero completo en la raíz del sitio y el mapa en `mapa.html`, con redirección de los enlaces ya compartidos; antes de anunciar el sitio. Especificación: `docs/especificacion_portada.md`.
- **Mapa** (tareas 25 y 26): etiqueta con los nombres del territorio al pasar el ratón, y clic con ficha en las escalas de municipio, provincia y comunidad.

Tareas 20–23 (F3 y página «Datos»), hechas en paralelo el 9-nov-2026 con las decisiones del autor de ese día (plan v0.33). No habrá release con estos datos hasta la v1.0: el sitio publicado sigue con los del `v0.1.0`.

### Añadido (9-nov-2026, F3: tartera de 2015 a 2026 y transistor)

- Tartera con el SMI de cada año: `SMI_FICHAS` (`R/derivados.R`) va de 2015 a 2026, con la norma, el XML del BOE y la orden de cotización de cada año. 2021, media de sus dos cuantías ponderada por meses de vigencia (955 €; pregunta 18). Cotización del trabajador con contrato indefinido: 6,35 % hasta 2022 y, con el MEI, 6,45 % en 2023, 6,47 % en 2024, 6,48 % en 2025 y 6,50 % en 2026, citada de la orden de cotización de cada año sin bajarla (decisión del autor). Neto mensual en 12: de 708,65 € (2015) a 1.237,40 € (2024) y 1.331,91 € (2026). Compuerta `smi_boe` (bloqueo): las cuantías de 2015 a 2023 frente al XML del BOE de cada real decreto (`R/fuente_boe_smi.R`).
- Barrera de acceso (15) de la tartera con el alquiler del mismo año, de 2015 a 2024, en la tabla larga (antes, solo 2024). Mediana de las secciones: del 36,7 % en 2015 al 29,5 % en 2024.
- Ficha «transistor» (pensionista): pensión media de jubilación del INSS por provincia (total del sistema, sin Clases Pasivas), media de los 12 meses de cada año ponderada por el número de pensiones, de 2015 a 2024; × 14 pagas, menos la retención de la AEAT de quienes solo cobran pensiones, de su comunidad y año (País Vasco y Navarra, con la de España, como `estimado`), ÷ 12 (`R/fuente_inss_pensiones.R`, `R/ficha_transistor.R`, `inventario/provincias_inss.csv`). En 2024, de 1.198 € (Ourense) a 1.869 € (Bizkaia); media ponderada, 1.574 €. Compuertas de bloqueo `inss_cobertura`, `inss_suma` e `inss_media` (las provincias reproducen las cifras de comunidad y España del mismo Excel), `transistor_cobertura` y `transistor_retencion`. En `perfiles` y en la barrera de la tabla larga (2015–2024).
- Web: «¿te llega?» usa el ingreso de la ficha del año del alquiler (`perfiles.json`, campo `anios`; decisión del autor): la tartera y el transistor, el de cada año; la mochila, el de 2024, con el aviso de años distintos. La tartera cita el SMI vigente junto al del año, y la evolución de la ficha usa el ingreso de cada año. Ficha «Pensionista», en castellano e inglés, con la nota de vivienda en propiedad de los mayores de 65 años (89,1 %, ECV 2023).
- Descargas autorizadas por el autor (9-nov-2026): 120 Excel mensuales del INSS de 2015 a 2024 (≈ 9,6 MB) y la tabla de retenciones de la AEAT de 2015 a 2023 (1.458 páginas, ≈ 39 MB).

### Añadido (9-nov-2026, F3: indicadores 4–6 del ADRH)

- Indicadores 4 (peso de los salarios en la renta), 5 (población por debajo del 60 % de la mediana de la renta por unidad de consumo) y 6 (índice de Gini) en la tabla larga, 2015–2024, de la sección a España (`R/fuente_ine_adrh_distribucion.R`, `larga_adrh_distribucion`): 1.331.166 filas. Tablas 30825, 30829 y 37677 del ADRH (por sección, en CSV; 2,1 GB) y, nuevas en la edición de octubre de 2026, 53687, 53694 y 53688 (España, comunidades y provincias, casadas por nombre). El 4 y el 5 se llevan al seccionado de 2021 como medias ponderadas (renta bruta; población) y el 6, con la regla de medianas (decisión del autor). En 2024, la sección mediana tiene el 58,2 % de la renta en salarios, el 19,2 % de la población bajo el 60 % de la mediana y un Gini de 27,9; España, 60,0 %, 20,2 % y 31,9.
- Compuerta `validacion_adrh_distribucion`: cobertura de las 52 provincias en cada tabla, rango, suma de las cinco fuentes de ingreso, orden de los umbrales, sección = municipio en los municipios de una sola sección, y agregación a municipio y a provincia (siete de bloqueo y una alerta).
- Rupturas `adrh_umbral_mediana_2023`, `adrh_forales_distribucion` y `adrh_umbrales_secreto_2024`.
- Web: tres mapas nuevos (4–6), con cortes en `inventario/indicadores.csv`, un decimal y en el comparador; la exportación lleva también los indicadores con mapa que no son del núcleo de la v0.1.

### Añadido (9-nov-2026, página «Datos»; pregunta 37)

- Página «Datos» (`datos.html` y `data.html`), enlazada en el menú del mapa, de la sobrecarga y de «Método»: descarga de la tabla larga en Parquet con su tamaño, su suma SHA-256, la fecha y el commit de los datos y el enlace al release; licencias (CC BY-SA 4.0 y MIT), aviso de las geometrías NUTS de GISCO y cita (de `CITATION.cff`); cómo leerla en R (`arrow`) y en Python (`pandas` y `pyarrow`); modelo de datos; cobertura de cada indicador en el release; valores de las columnas y diccionario de los 23 indicadores y los 3 auxiliares de fiabilidad. Se genera en el flujo de Pages con pandoc, como «Método», desde `docs/datos.md` y `docs/data.md` (`web/herramientas/pagina_datos.mjs`, que rellena la descarga, la cita y la cobertura).
- Diccionario generado desde el inventario (`exportar_diccionario_datos()`, `R/web_pagina_datos.R`; objetivo `ficheros_diccionario_datos`): `docs/datos_diccionario.md` y `docs/data_dictionary.md`, con una prueba que los compara con el inventario.
- `version.json` lleva la cobertura de la tabla larga por indicador: filas, primer y último año, niveles y cortes (`cobertura_publicacion()`). Desde el próximo release.
- Pruebas: `test-pagina-datos.R` (diccionario, paridad de los textos, columnas, clave y tipos, y los ejemplos de R y de Python ejecutados contra una tabla inventada) y `pruebas/web/pagina_datos.test.mjs`.

### Añadido (9-nov-2026, nombres del suelo sin sección)

- Mapa: el suelo sin sección lleva el nombre y el tipo de la unidad administrativa del IGN donde el IGN la dibuja (condominios: facerías, parzonerías, ledanías, comunidades…). Fuente nueva `ign_au` (WFS INSPIRE del IGN, CC BY 4.0), en `R/fuente_ign_au.R`. Cada hueco del seccionado se cruza con las unidades que lo solapan en al menos 0,01 km² (`geo_nombrar_huecos()`): 57 de los 95 huecos y 1.176,5 de los 1.495 km², en 73 trozos. La capa `sin_seccion` lleva los huecos enteros, sin nombre, y encima los trozos con `nombre` y `tipo`, con su superficie y sus provincias. La ficha da el nombre literal del IGN, el tipo («Condominio: territorio de varios municipios») y la fuente, en castellano e inglés; fuera de los trozos sigue el texto genérico. Atribución del mapa base: «INE, IGN».
- Compuertas `mapa_base_nombres` y `mapa_base_nombres_dobles` (bloqueo); `mapa_base_huecos` (alerta) da también los huecos y los km² con nombre. El PMTiles pasa de 35,3 a 35,4 MB: va en el próximo release.

### Cambiado (9-nov-2026, tareas 20–23)

- `aeat_titulo()` y `aeat_menus()` leen también la maqueta de las ediciones de la AEAT hasta 2017 (filtros en el subtítulo y en menús desplegables, otros nombres de comunidad).
- `larga_derivados`: de 1.104.793 a 2.149.869 filas (barrera de la tartera de 2015 a 2023 y del transistor de 2015 a 2024).
- Plantilla de las páginas de texto (`web/herramientas/plantilla_documento.html`) con «Datos» en el menú, la página activa y el botón ES/EN por variables; metadatos de «Datos» en `datos_es.yaml` y `datos_en.yaml`. Flujo de Pages: el paso de las páginas de texto monta «Método» y «Datos» y para si «Datos» no enlaza la tabla larga. `documento.css`: los códigos de la primera columna de las tablas no se parten. Fuera el texto `interfaz.proximamente` de los diccionarios de la web.
- Nota metodológica (castellano e inglés): §5.5 nueva (distribución de la renta, 4–6), §6.3 rehecha (tabla del SMI de 2015 a 2026), §6.5 nueva (transistor) y al día los apartados de fuentes, estados, mapa base, cifras y volumen.
- Plan v0.33 (preguntas 37–41; 18, cerrada del todo) y guía.

### Decidido (9-nov-2026, tareas 20–23)

- **Fichas:** la web usa el SMI del año elegido, con el vigente como texto; la cotización de cada año se cita de su orden, sin bajarla; transistor como media anual de 12 meses, neto con la retención de los pensionistas.
- **Indicadores 4–6:** descargas en CSV (pregunta 38); huecos forales `ausente`, sin Eustat ni Nastat (39); el 4 y el 5, medias ponderadas al reproyectar, y el 6, regla de medianas (40); mapas ya en la web (41).
- **Página «Datos»** (37): pandoc, como «Método»; diccionario desde el pipeline; cobertura real por indicador en `version.json`.
- **Suelo sin sección:** nombres por trozos, donde el IGN dibuja la unidad, y no uno por hueco, que ponía un nombre equivocado en parte de 6 huecos; nombres literales del IGN, también los siete de Burgos con identificadores de cinco cifras, que no son códigos de municipio del INE; tipo «condominio», el del mapa político del IGN.
- `eustat_nastat`, descartada como fuente.

## [0.1.0] · 9-nov-2026

Primera publicación: release `v0.1.0` (datos de la pasada del commit `573dbf6`) y web en GitHub Pages, https://gastiaso.github.io/de-renta-en-renta/. Lleva el mapa por sección censal y la sección europea de sobrecarga en un solo sitio (no hubo v0.0 aparte). Contra el sitio publicado pasan la prueba en el navegador (`comprobar_web_navegador()`: seis fichas y 300 secciones en los 10 años, sin errores), el mapa base se sirve por rangos y el Parquet de la tabla larga se baja con su suma. La etiqueta `v0.1.0` apunta al commit `573dbf6`; la prueba en el navegador, el paquete y la documentación de la publicación entraron justo después (`38d6870` y `fc7461c`), sin cambiar los datos ni la web.

### Cambiado (9-nov-2026, al publicar)

- Documentación al día con la v0.1 publicada (plan v0.32): README, `CITATION.cff` (versión 0.1.0, fecha y direcciones), guía, backlog, nota metodológica y `docs/publicacion.md`, donde la comprobación de rangos del PMTiles pasa a hacerse con un `GET` (con `HEAD`, GitHub responde `200` aunque sirva por rangos).

### Añadido (9-nov-2026, primer release)

- Prueba de la web en un navegador (`comprobar_web_navegador()`, `R/web_navegador.R`; `pruebas/testthat/test-navegador.R`): con `chromote`, Chrome sin ventana abre la página (en local, con `node web/servir.mjs`, o ya publicada), recalcula con sus propios módulos el sueldo necesario de una muestra de secciones en todos los años y lee sus contratos y su margen, abre seis fichas (con mediana, con pocos contratos, en secreto, con 0 contratos y «¿te llega?» en el límite y lejos de él) y lo compara con la tabla larga, sin errores de JavaScript ni de carga. Pasa en local.
- Paquete del release `v0.1.0` en `publicacion/` (fuera de git): datos de la web (15,8 MB comprimidos), mapa base (35,3 MB), tabla larga (36,9 MB), `version.json` y `SHA256SUMS`, de la pasada del commit `573dbf6`. El sitio publicado ocupará 167,3 MB en 9.251 ficheros.

### Añadido (9-nov-2026, tarea 19: contratos y margen del alquiler; plan v0.31)

- Tres indicadores auxiliares en `inventario/indicadores.csv` (columna nueva `auxiliar_de`, sin número ni mapa): `contratos_alquiler`, el recuento de testigos del SERPAVI de cada mediana, con 0 como dato y también España; `margen_alquiler_mes` y `margen_alquiler_m2`, el margen aproximado de la mediana, 0,929 × (P75 − P25) / (P50 × √n), solo donde hay mediana (`margen_mediana()`, `armonizar_fiabilidad_serpavi()`). `larga_serpavi` pasa de 3.932.340 a 5.898.530 filas, y la tabla larga, a 8.561.935.
- Compuerta de la fiabilidad (`comprobar_fiabilidad_serpavi()`, `validacion_fiabilidad`, antes de la tabla larga): `contratos_mediana` (regla de secreto entre mediana y contratos; 0 casos) y `contratos_suma` (secciones sumadas a provincia y a España; pasan las 1.080 cifras), de bloqueo, y `margen_rango` (margen de las secciones fuera del 1–40 %), de alerta: avisa en 2.414 secciones y años, casi todas de vivienda unifamiliar.
- Web: cada serie del alquiler lleva en el manifiesto sus series de `fiabilidad`, y el manifiesto, `umbral_pocos_contratos` (30). La ficha da «Mediana de N contratos · margen aproximado ±X %», la marca «pocos contratos», el intervalo del sueldo necesario y de los mapas del alquiler, el aviso «en el límite entre dos tramos» en «¿te llega?», «sin contratos de alquiler de pisos registrados» en lugar de «sin dato» con 0 contratos y, sin mediana, un contexto rotulado que no se pinta (`web/js/fiabilidad.js`). El CSV lleva `contratos` y `margen_pct`. Las secciones con pocos contratos no se atenúan en el mapa. Los auxiliares no van en las fichas por municipio.
- Muestra de la web (`web/datos/ejemplo/`) con contratos y margen inventados, coherentes con el estado de la mediana.

### Cambiado (9-nov-2026, tarea 19)

- Mochila `estimado` en `perfiles` (el método B es una estimación) y estado de la barrera (15), el del alquiler: el ingreso de la ficha solo aporta `ausente` cuando falta (`estado_barrera()`; compuerta `derivados_estado`, con la misma regla). En la web, la ficha y su evolución en «¿te llega?» siguen la misma regla. Las cifras de la barrera no cambian.
- Nota metodológica (castellano e inglés): §7.6 nueva, «Fiabilidad de las medianas del alquiler», y al día §2.1, §4.1, §6.1, §7.1, §7.4, §8, §9 y §10.

### Decidido (9-nov-2026, SMI de 2021 y orden de trabajo; plan v0.30)

- **SMI de 2021** (18): media de las dos cuantías ponderada por meses de vigencia, 955 € × 14 pagas (950 € hasta agosto, 965 € desde el 1 de septiembre, RD 817/2021).
- **Orden de trabajo** (backlog, «Siguiente»): desactivar el flujo de Pages hasta el primer *release*; la tarea 19 (contratos y margen) antes de publicar; después, el *release* `v0.1.0` con la prueba de `chromote`.

### Decidido (9-nov-2026, repositorio)

- **Repositorio público** en GitHub, `gastiaso/de-renta-en-renta`, desde su creación (decisión del autor), tras la revisión de privacidad de toda la historia, los ficheros y el paquete del *release* (`docs/publicacion.md`). El correo de autor de los commits pasa a la dirección `noreply` de GitHub, también en los ya hechos: la historia se reescribió con el mismo contenido antes de subirla.
- **Descargas** (autorizadas por el autor): `chromote` (en `renv.lock`), los reales decretos del SMI de 2015 a 2023 (XML del BOE, comprobados en `inventario/fuentes.csv`; entran en `SMI_FICHAS` en F3) y las unidades administrativas del IGN con código de provincia 53 y 54 (WFS INSPIRE, CC BY 4.0), para nombrar el suelo sin sección.

### Decidido (9-nov-2026, preguntas abiertas 12 y 15 ampliadas; plan v0.29)

- **Tipología del alquiler** (12): se confirma la colectiva; la ficha distingue «sin contratos de alquiler de pisos registrados» (0 contratos en la fuente: 3.630 secciones en 2024) de «sin dato» y da contexto rotulado sin pintarlo en el mapa.
- **Estado de los derivados** (15): el ingreso de la ficha solo aporta `ausente`; se añaden contratos, margen aproximado de la mediana, la marca «pocos contratos» y el aviso «en el límite». Especificación: `docs/especificacion_contratos_margen.md` (backlog, tarea 19).

### Decidido (9-nov-2026, preguntas abiertas 34–36; plan v0.28)

- **Ruptura de 2013 en la serie de sobrecarga** (34): la serie de España se corta en 2013, cuando el INE pasa a obtener los ingresos de la ECV combinando la entrevista con registros administrativos, aunque Eurostat no lo marca. `ecv_ingresos_2013` pasa a `aplicado` en `inventario/rupturas.csv`.
- **Denominador de las viviendas turísticas por territorio** (35): ruptura `vut_denominador_2024` en `inventario/rupturas.csv` y tabla 59521 del Censo 2021 (viviendas por comunidad y provincia; 143 KB, descarga autorizada por el autor) para la compuerta.
- **Empate en el corte de los quintiles** (36): el hogar con la renta de un corte va al quintil de arriba, como en Eurostat.

### Cambiado (9-nov-2026, preguntas abiertas 34–36)

- Sección «Sobrecarga»: las dos líneas de España se cortan también en 2013, con punto hueco y una nota propia («ruptura de serie del atlas, que Eurostat no marca»). `rupturas_serie_sobrecarga()` lee las rupturas aplicadas del indicador 22 de la ECV en `inventario/rupturas.csv` (objetivos nuevos `rupturas` y `rupturas_sobrecarga`); el JSON las lleva en `rupturas_atlas` y la compuerta de la página (`web_sobrecarga_valores`) las comprueba. La UE-27, sin cambio.
- Quintil de renta (`quintil_renta()`): la renta igual a un corte va al quintil de arriba. Las 15 cifras de 2023 a 2025 coinciden a un decimal con las de Eurostat (diferencia máxima, 0,045 puntos; antes, 0,051): el primer quintil de 2025 pasa de 27,8 a 27,7 %. Cada quintil reúne del 19,95 al 20,05 % de la población con renta (antes, del 19,98 al 20,01).
- Compuerta `vut_territorios`: exacta en los dos sentidos, con el denominador del INE en cada periodo (hasta agosto de 2024, las viviendas de las secciones con dato; desde noviembre de 2024, las de la tabla 59521, que cuenta también las de las secciones en secreto) y con España. Pasan las 432 cifras con ±0,005 puntos, el redondeo; antes, ±0,01 y solo cota superior en 33 provincias y 12 comunidades. Función nueva `leer_ine_censo2021_viviendas()` y objetivos `fichero_censo2021_viviendas` y `censo2021_viviendas`.
- Nota metodológica (castellano e inglés) al día: compuertas (§4.1), viviendas turísticas por territorio (§7.3), quintil, marcas de Eurostat y serie de la web (§7.5) y limitaciones (§8).

### Corregido (8-nov-2026, suelo sin sección; plan v0.27)

- Mapa: los terrenos comunales que no pertenecen a ningún término municipal se veían en blanco y no se podían pulsar. Son 95 huecos del seccionado de 2021 de al menos 0,01 km² (1.495 km²), como las Bardenas Reales o las sierras de Urbasa y Andía, casi todos en Navarra, Álava, Gipuzkoa y Burgos. El mapa base trae una capa nueva, `sin_seccion` (zooms 0–12, con `km2` y `provincias`), que la web pinta como «sin dato»; al pulsarla, la ficha explica por qué no hay datos. Los huecos que tocan una sola provincia, o varias de una sola comunidad, se suman a ella, y sus bordes ya no los rodean. Funciones `geo_huecos()` y `geo_absorber_huecos()` (`R/geo_mapa_base.R`); compuertas `mapa_base_huecos` (alerta) y `mapa_base_sin_seccion` (bloqueo). El PMTiles pasa de 35,2 a 35,3 MB, y generarlo, de unos 4 a unos 7 minutos.
- Nota metodológica (castellano e inglés): suelo sin sección en el mapa base (§3.10: capa `sin_seccion`, 95 huecos y 1.495 km², PMTiles de 35,3 MB), compuertas `mapa_base_sin_seccion` y `mapa_base_huecos` (§4.1), limitación en §8 y volumen de la web (§9.2).

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
