# Backlog integrado · hacia la v1.0

*10 de noviembre de 2026 · plan v0.44. Sustituye a la sección «Siguiente» de `docs/backlog_f0.md`, que queda como histórico de las tareas 0–32. Reúne la revisión de las preguntas 43–48, la auditoría del 10-nov-2026 y la llegada de los datos de oferta. Todo provisional.*

## Por qué cambia el orden

La auditoría contrastó la tabla larga y encontró que el atlas medía el parque alquilado, no la entrada. En las mismas secciones, de 2015 a 2024:

| Medida | 2015 | 2024 |
|---|---|---|
| Barrera del salario mínimo (mediana, SERPAVI) | 36,7 % | 29,9 % |
| Barrera del joven de 26 a 35 (mediana, SERPAVI) | 28,2 % | 28,4 % |
| Alquiler por m², SERPAVI (contratos vigentes) | — | +42 % |
| Alquiler por m², oferta de Idealista (España) | 7,58 € | 13,06 € (+72 %) |

Fuentes: SERPAVI (MIVAU) y Idealista, informes de precios de alquiler de su sala de prensa (cifras citadas; decisión 19).

El parque dice que nada ha cambiado; la oferta dice otra cosa. La v1.0 tiene que enseñar las dos.

## Decisiones del autor (10-nov-2026)

1. **Dos familias, nunca mezcladas en una cifra:** «Quedarse» (SERPAVI, parque alquilado) y «Entrar» (oferta de Idealista e índice del INE de contratos nuevos). La pregunta rectora se reformula sin presuponer la respuesta.
2. **Mapa inicial: «Entrar», por municipio.** La sección censal (familia «Quedarse») aparece al acercarse.
3. **Idealista, solo en la web:** mapas y fichas con fuente y enlace al informe. No entra en git, ni en el CSV, ni en la tabla descargable (salvo las cifras citadas de la decisión 19).
4. **Sueldo necesario con dos cifras:** la principal, con el alquiler mediano real; al lado, el mínimo teórico de 50 m².
5. **Sueldo para entrar:** euros por m² de oferta × superficie típica de los pisos alquilados del municipio (SERPAVI), y al lado el mínimo de 50 m².
6. **Todo en la v1.0:** también la tabla de paso desde el seccionado de 2011 y el módulo de supuestos. Los datos de portales vuelven a la v1.0 (se revierte la pregunta 49) solo con el alquiler de Idealista; venta y otros portales, en la v1.1.
7. **Pensionista:** pensión mediana de jubilación si alguna fuente oficial la publica; si no, la media con aviso.
8. **Descargas autorizadas:** el índice del INE de alquiler con contratos nuevos y existentes, y la metodología oficial del SERPAVI.
9. **Mapa inicial de «Entrar»: la brecha** (oferta / parque, por municipio). Los dos sueldos para entrar, con superficie típica y con 50 m², van en la ficha.
10. **Indicador 14, fuera del selector del mapa:** se queda en la ficha, con su aviso de lectura.
11. **Indicador 15, nombre nuevo:** «Peso del alquiler en el ingreso» para el parque. «Barrera» queda reservada a la familia «Entrar» (`barrera_entrar`).
12. **Lectura externa, dos lectores:** uno metodológico (estadística o economía de la vivienda) y otro sin formación técnica que pruebe la web.
13. **Tramos de color:** cortes fijos entre años. Recalibrados con los cuantiles de toda la serie donde reparten bien; donde la subida de la década lo impide (sobre todo, series en euros), anclados en el último año: sus sextiles y un tramo bajo en la mediana del primer año.
14. **Tres juegos de cortes** por indicador: sección, municipio, y provincia y comunidad. La leyenda cambia al cruzar de escala, con aviso.
15. **Siete tramos** en todos los mapas: la rampa pasa de seis a siete pasos.
16. **Barrios de Idealista, fuera de la v1.0:** un solo mes, sin historia, sin geometría ni código, y filas ambiguas. Quedan para la v1.1 (ver al final).
17. **Publicar ya lo hecho** (10-nov-2026): v0.4.0 con F3 a F6 y las tareas 34–36, sin la oferta de Idealista, que sale «próximamente» hasta que autorice publicarla (plan §11, preguntas 42 y 52).
18. **Derivados de Idealista, solo por tramos:** la brecha y el sueldo para entrar no se publican con la cifra exacta (con ella se reconstruye la oferta), ni se descargan. Sin autorización, ninguna cifra de Idealista en la web.
19. **Cifras de Idealista citadas en la documentación** (10-nov-2026): se mantienen las que ya hay en el repositorio (España en 2015, 2024 y 2026, la tabla de ocho ciudades de la tarea 37, el contraste por provincias de la tarea 36 y las referencias de la compuerta), siempre con su fuente, como cita. No entra ninguna más, ni su serie.

## Bloque 0 · Hoy

**33 bis. Publicar la v0.4.0** (decisión 17) · HECHA (10-nov-2026): release `v0.4.0` (commit `e04c643`) y sitio montado con esa referencia; la prueba en el navegador contra el sitio publicado da 0 en sus 39 comprobaciones. Commit de la publicación, `empaquetar_publicacion()`, release `v0.4.0` y flujo de Pages con `ref` en ese commit. **Hecho cuando:** la prueba en el navegador pasa contra el sitio publicado y la oferta sale «próximamente».

**33. Subir lo pendiente · HECHA (11-nov-2026).** `main` va 9 commits por delante del remoto y hay cambios sin commit.
- **Hecho cuando:** `git status` dice «up to date with 'origin/main'».

## Bloque A · Marco: dos familias

**34. Pregunta rectora y vocabulario · HECHA (10-nov-2026, plan v0.45).**
- Textos decididos por el autor (10-nov-2026):
  - gancho: «¿A quién le queda sueldo después de pagar la vivienda?»;
  - pregunta: «Dónde, desde cuándo y para quién ha cambiado la relación entre lo que cuesta la vivienda y lo que se cobra»;
  - familias: «Para quien ya está en el tablero y para quien entra nuevo en la partida».
- En inglés (confirmado por el autor, 10-nov-2026): «Who has any pay left after paying for housing?»; «Where, since when and for whom the link between housing costs and pay has changed»; «For those already on the board and for those just joining the game».
- En la portada: el gancho en el centro del tablero, con la pregunta y las familias debajo; el dicho («De renta en renta, y pago porque me toca») baja al pie.
- Cerca de la metáfora, su lectura literal: en la leyenda y en la nota, «quien ya vive de alquiler» y «quien busca piso hoy».
- **El gancho obliga a enseñar lo que queda.** La ficha y «¿Te llega?» muestran, además del porcentaje, los euros que quedan al mes: ingreso de la ficha menos alquiler, en las dos familias. Es una resta, no un umbral de suficiencia: la nota lo dice.
- Cambiarlos en el plan (§1), la nota (§1), el README y los diccionarios (`sitio.lema` pasa a ser la pregunta; claves nuevas para el gancho y las familias), en ES y EN.
- `inventario/vocabulario.csv`: familias `quedarse` y `entrar`; cada indicador de alquiler lleva la suya.
- La «barrera de acceso» calculada con el SERPAVI pasa a llamarse por lo que mide (propuesta: «alquiler del parque sobre el ingreso de la ficha»). «Acceso» y «entrar» quedan para la oferta.
- **Hecho cuando:** ningún texto de la web ni de la nota llama «acceso» a una cifra del SERPAVI (prueba que lo busque).
- **Avance (10-nov-2026):** textos nuevos en el plan (§1), la nota (ES y EN), el README y los diccionarios (`sitio.gancho`, `sitio.lema`, `sitio.familias`); las 96 pruebas de la web pasan. Falta: portada (gancho y familias en el centro, dicho al pie), vocabulario de familias, nombre nuevo de la «barrera», euros que quedan, y ejecutar las pruebas de R, que no se han pasado tras el cambio.
- **Hecha (10-nov-2026):**
  - indicador 15, «Peso del alquiler en el ingreso», con código `peso_alquiler_ingreso` (decisión del autor: también el código); familia C, «Esfuerzo»;
  - `familia_alquiler` en el inventario y en el manifiesto; la leyenda la escribe con su lectura literal;
  - portada con el gancho en el centro y el dicho al pie;
  - euros que quedan (o que faltan) en «¿te llega?», en la ficha y en su evolución; no en el panel «Tu sueldo» (resumen de todo el mapa), en las filas de contexto ni en el PNG;
  - prueba de «acceso» y «barrera» (`test-familias-alquiler.R`) y 12 pruebas de la web.

## Bloque B · Entrar

**35. Oferta de Idealista en el pipeline · HECHA (10-nov-2026).**
- **Datos:** tres CSV del autor, de la sala de prensa (segunda extracción del 10-nov-2026), en `datos/brutos/portales/idealista/`, fuera de git:
  - `alquiler_historico`: 136.816 cifras mensuales de €/m², de enero de 2006 a octubre de 2026;
  - `alquiler_zonas`: 816 territorios (España, 19 comunidades, 51 provincias, 296 municipios y 449 zonas), con su dirección en la sala de prensa;
  - `alquiler_barrios`: 1.014 filas, solo octubre de 2026; no se usan en la v1.0 (decisión 16).
- **Conversor** al formato de la capa (`R/fuente_portales.R`). Valor anual: media de los meses del año (hoy la capa toma el último mes; se cambia y se documenta).
- **Correspondencia** de cada territorio de Idealista con su código del INE, en `inventario/` (regla 7), casada por nombre y revisada a mano. Las zonas de Idealista no son distritos del INE: se guardan con su municipio y sin geometría.
- **Solo web:** la capa se exporta a un fichero propio de `web/datos/` y no entra en `tabla_larga.parquet` ni en los CSV. Prueba: el paquete del *release* no contiene el corte `oferta_privada`.
- **Compuerta:**
  - España, media anual: 7,58 €/m² en 2015 y 13,06 en 2024;
  - 278 de los 286 municipios tienen serie desde 2015 o antes;
  - sin meses duplicados.
- **Condiciones de uso:** anotar en `inventario/fuentes.csv` lo que digan las de la sala de prensa. Cada cifra, con el enlace a su informe.
- **Hecho cuando:** `PORTALES=TRUE` produce el indicador 13 de alquiler para España, comunidades, provincias y municipios, de 2015 a 2026, y pasa la compuerta.
- **Avance (10-nov-2026):** los tres CSV están en `datos/brutos/portales/idealista/` y la correspondencia, en `inventario/portales_idealista_territorios.csv` (815 territorios): España, 18 comunidades (sin Ceuta), 51 provincias, 286 municipios, 449 zonas con su municipio y 10 localidades que Idealista lista como municipio y no lo son (Sotogrande, Montequinto, La Moraleja…; 8 con su municipio, y La Alcaidesa y La Manga, que tocan dos, sin él). 743 casados por nombre y 53 a mano, con los códigos comprobados en `geo/territorios_2021.csv`. En los 286 municipios vive el 59,3 % de la población (ADRH 2024). Sin meses duplicados. **Decidido (10-nov-2026):** la media anual exige al menos 9 meses; con menos, `ausente` ese año (en 2024 tienen los 12 meses 245 de los 286 municipios y alguno, 279).
- **Segunda extracción (10-nov-2026, tarde), con el recorrido completo de provincias y municipios:**
  - territorios: solo entra Ceuta (816 en total). El recorrido completo no encuentra municipios nuevos: Idealista publica 296 nodos de municipio;
  - historia: las 136.688 cifras comunes, idénticas (precio y las tres variaciones); se suman los 128 meses de Ceuta;
  - Ceuta: solo página de comunidad (Melilla tiene también provincia y municipio), de octubre de 2011 a noviembre de 2025 y sin 2021: parece discontinuada. Con el mínimo de 9 meses valen 2012–2019 y 2025. En la correspondencia, como comunidad (código 18);
  - barrios: 1.014 filas. Las 146 nuevas son de municipios sin distritos y cada una es el propio municipio, con el precio de su serie. De las 868 de distrito, 449 son el propio distrito; quedan 419 barrios en 129 distritos de 35 municipios, y 30 se llaman como su distrito (en 19, también con el mismo precio): sin el enlace de cada fila no se distinguen;
  - las cifras de referencia de la tarea 37 no cambian.
- **Hecha (10-nov-2026):**
  - conversor de la extracción al formato de la capa (`R/fuente_portales.R`), casado por dirección con la correspondencia; el formato admite España, comunidades, provincias, municipios, zonas y localidades, y deja sitio a la venta y Fotocasa (v1.1), sin datos;
  - valor anual: media de los meses con 9 como mínimo, a dos decimales con los empates hacia arriba; deja de usarse el último mes del año;
  - con `PORTALES=TRUE`, indicador 13 de alquiler de 2015 a 2026: España (7,58 €/m² en 2015, 13,06 en 2024 y 14,95 en 2026, de enero a octubre), 51 provincias, 18 o 19 comunidades según Ceuta y 262 municipios en 2015, 259 en 2024 y 255 en 2026. Compuerta superada: `portales_*`, `portales_idealista_casados`, `portales_idealista_espana`, `portales_idealista_municipios` (278 de 286) y `web_portales`;
  - solo web: fuera de la tabla larga (encender o apagar la capa no la invalida) y de las descargas; carpeta propia, `web/datos/portales/`, con enlace al informe de cada cifra y 441 zonas y 7 localidades por municipio, sin interfaz (tarea 38). La web suma la capa al manifiesto general y no ofrece su CSV;
  - el paquete del *release* no la lleva (comprobación `sin_portales` y prueba); el flujo de Pages monta el sitio con la capa apagada;
  - condiciones de uso de Idealista, en la fila `portales` de `inventario/fuentes.csv`.
- **Por revisar** (plan §11, pregunta 52): pedir a Idealista autorización escrita (sus condiciones generales la exigen para incorporar su contenido a otro sitio y para enlazar en profundidad); cómo llega la capa al sitio (propuesta en `docs/publicacion.md`); las localidades (las 8 con municipio, como zonas; La Alcaidesa y La Manga, fuera); dos decimales en la web y estado `dato` con 9 a 11 meses; 2026 como año parcial; si el método de julio de 2026 abre una ruptura.

**36. Índice del INE con contratos nuevos · HECHA (10-nov-2026).**
- La tabla larga solo tiene el total del IPVA (España: del 0,3 % en 2015 al 3,5 % en 2024). Descargar el desglose entre contratos nuevos y existentes (autorizada).
- **Hecho cuando:** `var_alquiler` lleva el corte `contrato` (nuevo, existente) en los niveles que el INE publique, con su compuerta.
- **Investigado (10-nov-2026):** el INE publica el desglose desde la edición de 2021. Contratos nuevos frente a existentes: 3,5 y 1,2 % en 2021; 5,3 y 2,1 % en 2022; 8,8 y 2,8 % en 2024. Tabla de ponderaciones por antigüedad del contrato: 59008; el resto, en las tablas de resultados de la operación (INEbase, `padre=8306`). El desglose no se publica por municipio.
- **Localizado (10-nov-2026):** el desglose por antigüedad del contrato está en la tabla 59004 (España y comunidades) y en la 59005 (provincias). Por municipio (59060) y por distrito (59061) solo hay índice general. Serie de 2021 a 2024, en índice y en variación anual.
  - España, índice: contratos nuevos, 114,871 en 2021 y 137,041 en 2024; existentes, 112,229 y 120,637; total, 112,694 y 122,920.
  - De 2021 a 2024: +19,3 % los nuevos, +7,5 % los existentes y +9,1 % el total.
  - Añadir las dos tablas a `TABLAS_IPVA` (`R/fuente_ine_ipva.R`) y a la fila `ine_ipva` de `inventario/fuentes.csv`. Compuerta: las seis cifras de España de arriba.
  - Por comprobar en el proyecto técnico del INE: que el índice por antigüedad tenga base 2015 = 100 como el total (los valores de 2021 lo sugieren; la tabla no lo dice) y cómo define «contrato nuevo».
- **Contraste con la oferta (10-nov-2026; 31 de las 48 provincias, las que se pudieron leer de la tabla 59005; cálculo fuera del pipeline):** variación de 2021 a 2024, mediana provincial:

  | Medida | 2021–2024 |
  |---|---|
  | Oferta de Idealista (€/m², media anual) | +24,0 % |
  | INE, contratos nuevos | +17,0 % |
  | SERPAVI, mediana del parque (€/m², vivienda colectiva) | +14,6 % |
  | INE, contratos existentes | +6,7 % |

  - La oferta sube 1,3 veces lo que los contratos nuevos (mediana), con un rango de 0,6 (Huesca) a 2,5 (Málaga e Illes Balears). Más del doble también en Huelva, Alicante y Girona.
  - Correlación entre provincias, oferta y contratos nuevos: 0,68 (Pearson) y 0,59 (rangos). Contratos nuevos y SERPAVI: 0,83.
  - Lectura provisional: las dos fuentes de «Entrar» ordenan las provincias de forma parecida, pero no miden lo mismo. El índice del INE sigue contratos firmados y declarados; Idealista, anuncios, y su media cambia con el tipo de piso que se anuncia. En las provincias turísticas el anuncio se aleja del contrato.
  - Consecuencia: el índice del INE no puede dar un precio de entrada (es un índice, llega solo a provincia y empieza en 2021). Sirve de contraste de la oferta, no de sustituto. La ficha de provincia enseña las dos evoluciones juntas.
  - Compuerta propuesta (aviso, no bloqueo): provincias donde la oferta crece más del doble que los contratos nuevos en el mismo periodo.
- **Hecha (10-nov-2026):**
  - tablas 59004 (29.648 bytes) y 59005 (76.407 bytes) descargadas con `descargar_con_cache()`, enteras: ninguna serie cortada ni cifra «..»;
  - `var_alquiler` con el corte `contrato` (`nuevo` y `existente`) en España, 17 comunidades y 48 provincias, de 2021 a 2024: 528 filas (`ine_ipva`, de 11.910 a 12.438). El total, como estaba. Corte y grupos en `inventario/vocabulario.csv` (ES y EN);
  - compuerta: `ipva_contrato`, las seis cifras del índice y las seis variaciones de España de arriba, todas iguales a la tabla; `ipva_contrato_enlace`, la variación de 2021 de cada grupo frente a su índice y el índice general de 2020 (0,049 puntos como máximo); `ipva_tablas`, también comunidades, provincias y los contratos de España entre tablas (sin diferencias); `ipva_variacion`, con las dos tablas (0,050 puntos como máximo);
  - **comprobado en el proyecto técnico del INE (junio de 2023):** contrato nuevo es el que tiene como año de contrato el de referencia (fecha del contrato de las bases de la AEAT, desde 2019); los demás, existentes. Los ingresos son del año completo: con dos contratos en el año, el precio anual mezcla los dos y la variación recoge solo una parte del cambio. Los índices publicados están en base 2015 = 100, encadenados año a año; el documento no dice cómo se enlaza el desglose por contrato, pero el índice de 2021 de cada grupo es, en todos los territorios, el general de 2020 por la variación del grupo (`ipva_contrato_enlace`). Nota (ES y EN), §7.7;
  - con las 48 provincias, de 2021 a 2024 (mediana provincial del índice): contratos nuevos +17,0 % (de +6,0 % en Melilla a +28,9 % en Valencia/València) y existentes +6,7 %, las mismas medianas que con las 31 del contraste;
  - **por revisar — familia:** los contratos nuevos son de «entrar» y `familia_alquiler` va por indicador (el 10 sigue en `quedarse`). Propuesta: `quedarse|nuevo=entrar`, con la sintaxis de `cortes_web`, leída por la web y el diccionario cuando el corte tenga mapa o ficha. Anotada en `notas` del indicador 10 y en el plan (§11, pregunta 53); la web no cambia. La exportación web no lleva el corte, y `validacion_web` pasa;
  - **para la tarea 37:** el aviso de provincias donde la oferta crece más del doble que los contratos nuevos, cuando estén los datos de Idealista (tarea 35).

**37. Indicadores de «Entrar» · HECHA (10-nov-2026).**
- `sueldo_entrar`: €/m² de oferta × superficie típica del municipio / umbral, y su mínimo de 50 m².
  - Superficie típica: alquiler mensual mediano / alquiler por m² mediano del SERPAVI, a escala de municipio.
  - Aviso en la ficha: los m² de un anuncio y los catastrales del SERPAVI no son la misma medida.
- `barrera_entrar` por ficha, con el mismo ingreso del mismo año (regla 4).
- `brecha_entrar_quedarse`: oferta / SERPAVI, en €/m², por municipio y año. Es una comparación entre dos fuentes rotulada como tal, no una mezcla.
- **En la web, solo por tramos** (decisión 18): ni la brecha ni el sueldo para entrar salen con la cifra exacta ni se descargan; la tabla larga tampoco los lleva.
- Estado `ausente` en los municipios sin informe.
- **De la tarea 36:** compuerta de aviso (no bloqueo) con las provincias donde la oferta crece más del doble que los contratos nuevos en el mismo periodo (`var_alquiler`, corte `contrato`, 48 provincias, 2021–2024), cuando la oferta de Idealista esté en el pipeline (tarea 35).
- **Hecho cuando:** los tres están en la exportación web, con compuerta de rango y prueba de que R y la página coinciden.
- **Cifras de referencia (10-nov-2026; cálculo fuera del pipeline: media anual con 9 meses o más, frente a la mediana del SERPAVI de vivienda colectiva del municipio):**
  - municipios con oferta y SERPAVI el mismo año: 256 en 2015 y 259 en 2024;
  - brecha mediana: 1,16 en 2015 y 1,35 en 2024 (percentiles 10 y 90 en 2024: 1,22 y 1,76). Sube en el 99 % de los 242 municipios con los dos años;
  - en 2024 solo un municipio queda por debajo de 1 (Boadilla del Monte, 0,97). Las mayores, en municipios turísticos: Santa Eulària des Riu (2,18), Andratx (2,15), San Bartolomé de Tirajana y Alcúdia (2,13), Estepona (2,07) y Orihuela (2,04);
  - superficie típica municipal: 77 m² de mediana (62 en Madrid, 66 en Barcelona, 83 en València);
  - sueldo neto al mes, municipio mediano: quedarse, 1.250 € en 2015 y 1.833 € en 2024; entrar, 1.440 y 2.585 €; entrar con 50 m², 914 y 1.646 €.

  | 2024 | Parque (€/m²) | Oferta (€/m²) | Brecha (2015) | Sueldo quedarse | Sueldo entrar | Entrar, 50 m² |
  |---|---|---|---|---|---|---|
  | Madrid | 14,0 | 20,0 | 1,43 (1,20) | 2.896 | 4.143 | 3.331 |
  | Barcelona | 13,7 | 20,2 | 1,47 (1,33) | 3.000 | 4.421 | 3.360 |
  | València | 8,2 | 14,3 | 1,75 (1,33) | 2.269 | 3.980 | 2.392 |
  | Sevilla | 9,2 | 11,8 | 1,28 (1,22) | 2.228 | 2.855 | 1.960 |
  | Málaga | 9,6 | 14,9 | 1,56 (1,22) | 2.394 | 3.745 | 2.490 |
  | Zaragoza | 7,7 | 10,1 | 1,31 (1,17) | 1.833 | 2.402 | 1.686 |
  | Palma | 9,8 | 17,1 | 1,74 (1,37) | 2.667 | 4.628 | 2.846 |
  | Bilbao | 11,5 | 14,7 | 1,28 (sin dato) | 2.667 | 3.415 | 2.457 |

  Fuente de la oferta: Idealista, informes de precios de alquiler de su sala de prensa; el resto, SERPAVI y cálculo propio. Cifras citadas (decisión 19): la web no publica la serie de Idealista ni sus derivados exactos.

- **Advertencias de diseño que salen de las cifras:**
  - `sueldo_entrar` con superficie típica es, por construcción, el sueldo de quedarse multiplicado por la brecha: no añade información a escala de municipio. Lo independiente es la brecha y la cifra de 50 m². Valorar que el mapa inicial enseñe la de 50 m² o la brecha, y que la de superficie típica quede en la ficha.
  - La brecha junta dos diferencias: entrar frente a quedarse, y anuncio frente a contrato. La ficha lo dice (ver el contraste de la tarea 36).
  - En los municipios turísticos la oferta puede incluir alquiler de temporada y vivienda de gama alta, que el SERPAVI no recoge (vivienda habitual). Aviso en la ficha con brecha de 2 o más.
  - El SERPAVI separa vivienda colectiva y unifamiliar y no da total. Propuesta: comparar con la colectiva y decirlo; revisar los municipios donde predomina la unifamiliar.
  - Compuerta propuesta: bloqueo fuera de 0,8–2,5; aviso con 2 o más; mediana de 2024 entre 1,30 y 1,40.
- **Hecha (10-nov-2026):**
  - `R/derivados_entrar.R`, solo con `PORTALES=TRUE`: superficie típica, brecha (comunidades, provincias y municipios; España no, porque el SERPAVI no da su mediana), sueldo para entrar (superficie típica y 50 m²) y barrera de la tartera, la mochila y el transistor, con el ingreso del mismo año. Cifras exactas solo dentro del pipeline (`indicadores_entrar`), para la compuerta;
  - **a la web, solo el tramo de la brecha** (`web/datos/portales/entrar/`, dentro de la capa; entrada `entrar` de su manifiesto), un entero por territorio y año. Con un juego de tramos por indicador, la oferta se reconstruiría cruzándolos: cada indicador es la oferta por una cifra pública distinta en cada territorio (el SERPAVI, la superficie típica, el ingreso de cada ficha), así que cada juego la corta por otro sitio. El sueldo para entrar, el de 50 m² y la barrera son la brecha por una cifra de «quedarse» y la web los da como intervalo desde el tramo (`web/js/entrar.js`), con «¿te llega?» y «en el límite»;
  - cortes, por revisar, en `inventario/entrar_tramos.csv`: 1; 1,15; 1,35; 1,6 y 2, con los límites de bloqueo (0,8 y 2,5) en los extremos; seis tramos, cada uno de al menos un 15 % (la oferta queda acotada como mucho a ±7 %). Sustituyen a las filas de la brecha de `inventario/cortes_web_niveles.csv`;
  - «Tu ficha»: el intervalo de la barrera con el sueldo del usuario, sin la oferta exacta en el navegador (`llegaEntrar()`), por revisar;
  - compuerta (`validacion_entrar`, `validacion_web_entrar`): `entrar_tramos`, `entrar_rango`, `entrar_estado`, `entrar_coherencia`, `entrar_municipios` (256 y 259, iguales), `entrar_mediana` (pasa a ±0,01: con el SERPAVI a un decimal, como la web, y no a la precisión de la fuente, como el cálculo de arriba, la mediana se aleja de la referencia algo más de 0,005; por revisar), `entrar_mediana_rango`, `entrar_superficie` (77 m², igual) y `web_entrar`, de bloqueo; `entrar_rango_detalle` (17 cifras municipales de 2 o más: 2 en 2017, 2 en 2018, 5 en 2023 y 8 en 2024) y `entrar_ipva` (aviso de la tarea 36, con las 47 provincias que tienen las dos series: avisa en 7, Málaga, Illes Balears, Huelva, Alicante, Segovia, Girona y Santa Cruz de Tenerife), de aviso;
  - prueba de que R y la página coinciden: `test-entrar.R` y `pruebas/web/entrar.test.mjs` comparten los casos inventados de `pruebas/datos/entrar_inventado.json` (tramo, límites, intervalos, «¿te llega?» y fichero de tramos);
  - comprobado (10-nov-2026): con `PORTALES=TRUE`, el pipeline pasa la compuerta y exporta 30 ficheros de tramos (municipios, provincias y comunidades, de 2015 a 2024), que la prueba de la web lee sin ninguna cifra exacta; con el valor por defecto, la capa vuelve a quedar apagada y `tar_outdated()` sale vacío; las pruebas de R y de la web pasan;
  - por revisar (plan §11, pregunta 54): el ancho mínimo y los cortes (seis tramos, no siete; más del 35 % de los municipios en un tramo todos los años), los derivados sin tramos propios, «Tu ficha», la tolerancia de la mediana, 2025 y 2026 sin SERPAVI (la web llega a 2024) y si los tres indicadores entran en el catálogo de los 23.

**38. Mapa inicial de «Entrar».**
- Vista inicial: `brecha_entrar_quedarse` por municipio, último año completo (decisión 9). `sueldo_entrar` y su mínimo de 50 m², en la ficha.
- Medir y publicar la cobertura: qué parte de la población vive en los 296 municipios con dato.
- Al acercarse aparecen las secciones, que son otra medida (parque). El cambio se ve: rótulo en el mapa, leyenda distinta y aviso al cruzar la escala. Nunca el mismo color para dos medidas.
- Zonas de Idealista: sin geometría, solo como lista en la ficha del municipio, con su serie. Los barrios, fuera de la v1.0 (decisión 16).
- Provincias y comunidades: la cifra que publica Idealista en ese nivel (regla 1).
- **Hecho cuando:** la prueba de navegador recorre municipio → sección y comprueba rótulo, leyenda y cifra en cada escala.

**39. Ficha: entrar frente a quedarse.**
- En cada sección: su alquiler (parque), el de oferta de su municipio y la brecha; la banda SERPAVI–oferta prevista en el plan.
- Evolución: las dos series en el mismo gráfico, cada una con su fuente.
- **Hecho cuando:** la ficha de una sección de un municipio con oferta muestra las tres cifras con el mismo año.

## Bloque C · Quedarse: correcciones de la auditoría

**40. Sueldo necesario con dos cifras.**
- Principal: alquiler mensual mediano / umbral. Al lado: mínimo teórico de 50 m². En 2024, sección mediana: unos 1.900 € frente a 1.217 €.
- Motivo: la superficie implícita de las medianas es de 79 m², y solo el 3,4 % de las secciones baja de 55 m².
- Afecta al mapa, la ficha, «¿te llega?», las cartas de la portada, el CSV y la nota.
- **Hecho cuando:** ninguna pantalla muestra el mínimo de 50 m² sin la cifra real al lado.
- **HECHA (11-nov-2026):** el 21 es el alquiler mensual mediano / 0,30 y lleva al lado el mínimo de 50 m², en la tabla larga como corte `superficie`, grupo `50` (`calcular_sueldo_necesario()`); compuerta por cifra y rangos por indicador y corte. Comprobado: superficie implícita mediana de 78,9 m² en 2024 (79,5 en 2015) y 3,4 % de secciones por debajo de 55 m²; en 2024, 1.900 € frente a 1.216,7 € en la sección mediana.
  - Mapa: la cifra real, con cortes 1.000; 1.300; 1.600; 2.000 y 2.600 €; ficha, leyenda, tarjeta «Tu sueldo», comparador, imagen y CSV (`valor_minimo`), con el mínimo al lado o dicho; cartas de la portada con las dos cifras; «¿te llega?», con 50 m² en el mapa (regla 8) y la cifra real al lado en la ficha y la tarjeta. Nota (ES y EN), §7.4 y siguientes.
  - **Por revisar** (plan §11, pregunta 55): que el mapa pinte la cifra real; los cortes; los rangos de la compuerta; «¿te llega?» con 50 m² en el mapa y la evolución de «¿te llega?», que aún da solo la de 50 m²; las filas del 21 de `inventario/cortes_web_niveles.csv` (son del mínimo de 50 m²; tarea 51).

**41. Indicador 14: nombre y tramos.**
- Divide el alquiler de quien alquila entre la renta de todos los hogares, y no discrimina: 18,3 % en el quintil más pobre y 17,5 % en el más rico; el 99,6 % de las secciones cae en dos de cinco tramos.
- Renombrar («alquiler mediano sobre renta media del barrio»), tramos nuevos por cuantiles de 2024 y aviso de lectura en la ficha. La ficha «llave» lleva el mismo aviso.
- **Decidido (10-nov-2026):** el indicador sale del selector del mapa y se queda en la ficha, renombrado y con el aviso. Los tramos de abajo quedan como referencia.
- **Hecho cuando:** el selector del mapa no ofrece el indicador 14 y la ficha lo muestra con su aviso.
- **Tramos calculados (10-nov-2026; 26.125 secciones con dato en 2024):**
  - con los actuales (20; 30; 40; 50): 68,0 %, 31,6 %, 0,4 %, 0 % y 0 %;
  - propuesta con cuatro cortes (15; 17; 19; 22): 27,6 %, 17,0 %, 16,3 %, 19,1 % y 20,0 %;
  - alternativa con cinco cortes (14; 16; 18; 20; 23): 19,6 %, 16,5 %, 17,0 %, 14,9 %, 17,5 % y 14,6 %.
- **HECHA (11-nov-2026):** «Alquiler mediano sobre renta media del barrio», con el aviso de lectura en `inventario/indicadores.csv` (comprobado: en 2024, mediana del 18,3 % en el quintil de secciones con menos renta por hogar y del 17,5 % en el de más); sin `cortes_web`, fuera del selector del mapa; en la ficha de la sección y del municipio con su aviso (`fichaResidentes()`), y en «¿te llega?» con la llave, el aviso bajo su cifra. La casilla «Renueva el contrato» de la portada pasa a `mapa.html?ficha=llave`. **Por revisar** (pregunta 55): el 14 en todas las fichas, salvo con la llave, y el destino de la casilla.
- **Objeción:** entre el percentil 5 (11,6 %) y el 95 (25,3 %) hay menos de 14 puntos. Los tramos por cuantiles cumplen el criterio, pero pintan contraste donde hay poca diferencia real y sobre un cociente que ya se sabe que no discrimina. Alternativa a decidir: sacar el indicador 14 del selector del mapa y dejarlo en la ficha con su aviso.

**42. Universo del SERPAVI.**
- Descargar la metodología oficial (autorizada) y confirmar qué deja fuera: caseros que son personas jurídicas, alquiler no declarado.
- Añadirlo a la nota (§7.1 y §8), a la ficha del indicador y a `inventario/fuentes.csv`.
- **Hecho cuando:** la nota cita el documento oficial y dice a quién no mide la fuente.
- **Investigado (10-nov-2026):** la metodología vigente es la de 18 de marzo de 2026 (resolución publicada en el BOE, BOE-A-2026-8691), en la web del Ministerio: falta leerla. Fuentes secundarias coincidentes: el proyecto técnico del IPVA (INE) y la nota de la AEAT sobre viviendas declaradas dicen que la base son las declaraciones de IRPF de arrendamientos de vivienda habitual; una nota jurídica (Osborne Clarke, 18-mar-2024) señala que queda fuera la vivienda de quien declara por el Impuesto de Sociedades.
- **Leída (10-nov-2026; lectura automática del PDF: verificar las páginas a mano antes de citarlas en la nota):** `2026-03-18_Metodologia_SERPAVI.pdf`, enlazada desde la página del SERPAVI del Ministerio.
  - Fuentes: modelo 100 del IRPF (109 en Gipuzkoa) y Catastro, y solo esas dos (pp. 6, 8 y 16).
  - Entran: arrendadores que son personas físicas, inmuebles no afectos a una actividad económica y alquilados como vivienda habitual del inquilino.
  - No entran: sociedades y demás personas jurídicas; alquileres a parientes; inmuebles fuera del territorio común, y los de territorio común cuyos titulares residen todos en territorio foral o en el extranjero; registros erróneos o atípicos; edificios con más de tres veces la superficie de la parcela (p. 17).
  - Territorios forales: Navarra, 2021–2024; Gipuzkoa, 2022–2024; Álava y Bizkaia, 2024. Coincide con lo que ya hay en la tabla larga.
  - Mínimo para publicar: 10 testigos. Estadísticos: mediana y percentiles 25 y 75 de renta, cuantía y superficie, y número de viviendas.
  - Renta: ingresos íntegros anualizados declarados, por m² de vivienda sin zonas comunes (p. 9). Un contrato de pocos meses se eleva al año.
  - El documento no dice nada de habitaciones, alquiler de temporada ni vivienda protegida, ni fija un mínimo de días arrendados. Tampoco se compara con las versiones anteriores (2024 y dos de 2025).
  - Pendiente: cuantificar el sesgo. Qué parte del parque en alquiler es de personas jurídicas, por municipio (Catastro o Censo 2021), para avisar donde pese más.
- **HECHA (11-nov-2026):** metodología bajada (`datos/brutos/mivau_serpavi/`, 1.013.585 bytes) y páginas comprobadas a mano: personas físicas, modelo 100 o 109, vivienda habitual, sin parientes, registros atípicos y titulares foráneos fuera (p. 6); no afectos a actividades económicas (p. 8); renta (p. 9); solo IRPF y Catastro (p. 16); criterios de selección, parcela y 10 testigos (p. 17). En la nota (§7.1 y §8, ES y EN), en la `lectura` del 8 y el 9 (`inventario/indicadores.csv`, que llega a la web) y en la fila `mivau_serpavi` de `inventario/fuentes.csv`.
  - Sesgo: no hay tabla abierta del parque alquilado por tipo de arrendador y municipio. Cifras: Banco de España, 8 % de las viviendas principales en alquiler de mercado de personas jurídicas privadas (España; Informe Anual 2023, cap. 4, p. 240); contraste del SERPAVI con los hogares en alquiler del Censo 2021 (`contraste_serpavi_censo`), 77,6 % en España sin País Vasco, del 36,0 % (Melilla) al 118,9 % (Salamanca), que no aísla a las personas jurídicas.
  - **Por revisar:** la web no marca municipios. La estadística de titularidad del Catastro por municipio (todo el parque residencial, no el alquilado) no se ha bajado: no cumple la condición de la descarga autorizada.

**43. Ruido de las series por sección.**
- Con 10–19 contratos, el 16,6 % de las secciones cambia más de un 15 % en un año; con 100 o más, el 0,9 %.
- Gráfico de evolución con banda del margen; las variaciones de un año, solo con 30 contratos o más en los dos años, o como media de tres años.
- **Hecho cuando:** la ficha no muestra una variación anual sin su aviso en una sección con pocos contratos.
- **HECHA (11-nov-2026):** gráfico de la evolución con la banda del margen y puntos huecos por debajo de 30 contratos (`web/js/evolucion.js`), y columna de variación: la de un año solo con 30 contratos o más en los dos años; si no, la media anual de tres años con «†», o ninguna. Prueba `pruebas/web/evolucion.test.mjs`; comprobado en el navegador. **Por revisar:** la media de tres años como variación media anual entre el año y tres antes, y el peso de leer los 20 ficheros de contratos y margen (CHANGELOG).

**44. Fichas comparables.**
- Pensionista: buscar la pensión mediana de jubilación; si no existe, media con aviso.
- Cada ficha dice qué estadístico usa (media, mediana, mínimo legal) y de quién (hogar, persona).
- **Hecho cuando:** el método de cada ficha, en la web, lo declara en una línea.
- **Investigado (10-nov-2026):** no aparece una pensión mediana de jubilación publicada. La Seguridad Social sí publica las pensiones por tramos de cuantía, de donde se puede interpolar una mediana (`estimado`); por provincia, a comprobar. **Decidido (10-nov-2026):** mediana estimada por tramos (`estimado`) solo si los tramos se publican por provincia; si no, la media con aviso en la ficha.
- **Comprobado (10-nov-2026):** los Excel mensuales por provincia que ya descarga el pipeline (`CA<AAAAMM>.xlsx`) traen número, importe y pensión media por régimen y clase, sin tramos de cuantía. Los tramos del anuario son nacionales, y eSTADISS no se puede automatizar. Según lo decidido, la ficha del pensionista se queda con la media y su aviso. Opción que no exige fuente nueva: añadir en la ficha la pensión media de jubilación de autónomos de la provincia como referencia baja.
- **HECHA (11-nov-2026):** cada ficha dice en una línea su estadístico y de quién (`fichas_metodo` de `web/i18n/`), en su ficha de «¿te llega?», en la tarjeta «Tu sueldo» y en la portada: llave, media del hogar; mochila, mediana de una persona; tartera, mínimo legal de una persona; transistor, media de una persona, con el aviso de que no se publica la mediana por provincia; «Tu ficha», cifra propia. Nota, §6.1 y §6.5. La referencia baja de autónomos no se ha añadido. **Por revisar:** los textos.

**45. Series nominales y regla del 30 %.**
- Opción de ver las series en euros constantes (IPC del INE), o aviso fijo de que son nominales.
- La nota explica el límite de usar la misma proporción para todos los ingresos (enfoque de ingreso residual; Stone, 2006).
- **Hecho cuando:** el gráfico de evolución dice si está en euros corrientes o constantes.
- **HECHA (11-nov-2026):** aviso fijo bajo el gráfico de la evolución («En euros corrientes de cada año, sin descontar la inflación»), con la variación del IPC del periodo (INE, tabla 76144, medias anuales; `datos/ipc.json`; de 2015 a 2024, +23,5 %). La nota explica la regla del 30 % y el ingreso residual (Stone, 2006) en §7.4 y §8. **Por revisar:** aviso fijo en lugar de un selector de euros constantes (propuesta; el selector podría añadirse sin datos nuevos).

**46. Revisión de las preguntas 43–48** (antes, tarea 32; plan §11) · HECHA (11-nov-2026). Sigue igual, con dos cambios:
- 43 h: dos sueldos con 70 m² se aplica también a «Entrar».
- 45 a: el indicador 11 sale de Registradores. **Nivel: provincia** (decisión del autor, 10-nov-2026, que sustituye al municipio de la pregunta 45): es el único que publica la fuente abierta.
- **Hecho (11-nov-2026):**
  - 43 h: entre dos sueldos, piso de 70 m² por defecto, a la vista y cambiable (50, 70, 90) en la ficha; en «entrar», `sueldo_entrar_dos` (intervalo, R y web, con datos inventados).
  - 43 e: nivel de la vista inicial según la pantalla: 1280 × 720, provincias (zoom 4,96); 1366 × 768 y 1920 × 1080, municipios (5,1 y unos 5,8); móvil de 375 × 812, comunidades (3,9). Por revisar con la tarea 38 (la decisión 2 pide municipios).
  - 44 e: ficha «Joven de 26 a 35» y el 7, «total y de 26 a 35 años».
  - 44 f: 2015–2018 con la relación de 2019 (`metodo_forma`), `estimado`; la ECV avisa en 2015 (+2,1 puntos) y 2017 (−3,1), y la corrección no se valida en 2020–2024 (error medio de 4,0 puntos frente a 0,6): no se corrige.
  - 44 g: `mochila_ecv` con el intervalo de la mediana de la ECV por su muestra: avisa en 20 de 160 cifras (antes, 32).
  - 45 a y b: `R/fuente_registradores.R` (lector, compuerta, coherencia con el valor tasado provincia frente a provincia), fila en `fuentes.csv`, ODbL en `LICENCIA_DATOS.md` y en `version.json`; probado con un CSV inventado. **Sin conectar** en `_targets.R`.
  - 45 d y e: el 17 con la renta neta por hogar del ADRH y el tipo D_IMVTIPLV del Banco de España: España, 17,8 % en 2015 y 18,1 % en 2024.
  - 46 e: prórrogas como resoluciones nuevas (`prorroga_de`), con su compuerta.
  - 47 a, c, d y g: `historico.parquet` en el paquete; tipos con D_IMVTIPLV y la referencia MIBOR (hasta 1998) y euríbor (desde 1999) como índices distintos; nota del sueldo de la Contabilidad Nacional; la revisión del Banco de España, alerta.
  - 48 a y g: los seis meses del CIS solo en PDF, transcritos en `inventario/cis_transcripcion_pdf.csv` con su compuerta; criterio de F6, «avisa».
- **Hecho (11-nov-2026), el fichero de Registradores:** `RP_ComprvResid_2007-2t2026.csv` en `datos/brutos/registradores/` (copiado por decisión del autor) y el bloque conectado en `bloque_compraventa` (`larga_registradores` en `larga_compraventa`, `fichero_registradores` en el calendario). El 11 de 2015 a 2025, 52 provincias, 19 comunidades y España (2.283,52 €/m² en 2025); pasan las ocho compuertas `registradores_*` y la de detalle avisa en Santa Cruz de Tenerife, 2022 (1,41). En la web, mapa provincial a toda escala (`nivel_minimo` «provincia»: municipios y secciones apagados), ficha, diccionario y descargas; siete tramos con su fila de `inventario/cortes_web_niveles.csv` (`anclado_septiles`, 950 a 2.550 €/m²; tarea 51) y, en `cortes_web`, 1.000 · 1.250 · 1.500 · 2.000 · 2.500 €/m². Además, el 17 con la renta por hogar publicada por el INE en provincias, comunidades y España (tabla 53689; compuerta `compraventa_renta_*`). Lo demás por revisar: plan §11, pregunta 57.

## Bloque D · Lo que faltaba de la v1.0

**47. Tabla de paso desde el seccionado de 2011 · HECHA (11-nov-2026).** Viviendas turísticas de 2020–2023 y Censo 2011 (pregunta 14). Mismas dos vías y compuertas que F1.
- Hecho: dos tablas desde las 35.960 secciones del Censo 2011 (cartografía del propio Censo, 1-nov-2011): callejero de enero de 2012 y edificios del Catastro de F1, construidos hasta 2011 (Censo) y hasta 2020 (viviendas turísticas), sin leer ningún edificio más (`R/paso2011.R`). En la tabla larga, el 18 de 2011 y el 19 de agosto de 2020 a febrero de 2023, de la sección a España, con su estado y su compuerta (`validacion_paso2011`); nota, §3.11.
- Secciones de 2021 `estimado`: 5.446 (Censo) y 5.497 (viviendas turísticas), frente a 11.043 con solo el callejero. Cierre exacto; 19 excepciones de cobertura y 2 secciones sin paso.
- Por revisar (CHANGELOG): agosto de 2023 (mezcla seccionados), edificios hasta 2020 en la tabla de las viviendas turísticas, las excepciones de cobertura y las secciones sin paso (leer el Catastro de esos municipios sería otra descarga).

**48. Módulo de supuestos · HECHA (11-nov-2026), salvo una decisión.** Superficie, umbral, pagas y segundo sueldo, documentados y validados en una muestra (plan, F3). Incluye la superficie típica del municipio.
- Hecho: `inventario/supuestos.csv`, fuente única de los supuestos (superficie de una persona, 50 m², y de dos sueldos, 70, con las opciones 50, 70 y 90; umbral del 30 o del 40 %; tramos de «¿te llega?»; 12 o 14 pagas; segundo sueldo; vivienda tipo de la compraventa), con su unidad, uso y decisión. R lo lee al cargar las funciones (`R/comun_supuestos.R`; las constantes de los derivados salen de él, con los mismos valores) y la web por `web/js/supuestos.js`, generado (`sueldo.js` y `estado.js` ya no llevan cifras propias). Nota, §6.7.
- Superficie típica de los pisos alquilados (decisión 5) con el SERPAVI que ya está en el pipeline, de la sección a la comunidad y de 2015 a 2024 (objetivo `superficie_tipica`): 82,1 m² de mediana en los 2.555 municipios de 2024; 62 en Madrid, 66 en Barcelona y 83 en València. Ni el Catastro de F1 ni el Censo 2021 por sección traen superficie de las viviendas: sin descarga nueva.
- Compuerta `supuestos_*` (`validacion_supuestos`) en una muestra de 14 territorios × las 40 combinaciones de «Tu ficha» y las tres fichas de una persona: con los supuestos por defecto reproduce los indicadores 21 y 15 de la tabla larga; los casos, en `pruebas/datos/supuestos_muestra.json`, que comprueban R (`test-supuestos.R`) y la página (`pruebas/web/supuestos.test.mjs`).
- **Falta (decisión del autor; plan §11, pregunta 59):** si «Tu ficha» y la ficha de municipio ofrecen la superficie típica, y si por defecto en lugar de 50 m². La cuenta está preparada en la web (`superficieTipica`), sin usar. **Decidido y hecho (11-nov-2026):** opción «Típica» en «Tu ficha» (la del municipio de la sección de la ficha, del territorio elegido o del municipio del centro de la vista), sin cambiar los 50 m² por defecto, y línea en la ficha de municipio; la muestra de `validacion_supuestos` toma en las secciones la de su municipio.

**49. Primeras historias · HECHA (11-nov-2026).** Dos o tres, y una de ellas, la brecha entre entrar y quedarse. Con cifras de la compuerta y enlace a su vista del mapa.
- **Decidido (11-nov-2026), decisión del autor:** la brecha entre entrar y quedarse se aplaza hasta la autorización de Idealista (sus cifras no pueden salir en la web: decisión 18); van dos historias de datos públicos, «El centro no cabe en la escala» y «Años de renta», como recorridos guiados dentro del mapa y no en una página aparte.
- **Hecho:** `inventario/historias.csv` (textos en castellano y en inglés y vista de cada paso: mapa, año, encuadre, territorio y escala) e `inventario/historias_cifras.csv` (42 cifras calculadas desde la tabla larga, el histórico y los cortes de la web, con la cifra redactada); `R/web_historias.R`, objetivos `historias_cifras`, `validacion_historias` (compuertas `historias_cifras`, `historias_textos`, `historias_estado` e `historias_privado`, bloqueo) y `fichero_historias_web` (`web/datos/historias.json`). Si una actualización mueve una cifra, el pipeline para y el texto se revisa a mano. Panel del recorrido en `mapa.html` (`web/js/historias.js`), claves `historia` y `paso` en la URL y «Historias» en el menú; prueba de navegador `navegador_historias`. Nota, §9.2.
- **Cifras** (2024 salvo otra fecha): alquiler mensual por sección, vivienda colectiva: en Madrid, el tramo más alto (700 € o más) recoge el 35 % de las 2.357 secciones en 2015 y el 87 % de las 2.421 en 2024 (España, 30 %), con la mitad por debajo de 600 y de 850 €; percentiles 10 y 90, 683 y 1.300 € (Barcelona: 95 % de 1.061; 730 y 1.228 €). Años de renta del Banco de España: 2,9 en el primer trimestre de 1987, máximo de 9,5 en el tercero de 2007, mínimo de 6,6 en el primero de 2015 y 8,4 en el segundo de 2026, la más alta desde el primero de 2011. Indicador 16: España, 6,3 años en 2015 y 6,1 en 2024; provincias de 2,7 (Ciudad Real) a 10,5 (Illes Balears); municipios con diez años o más, de 4 a 18; Santa Eulària des Riu, 17,9 (10,7 en 2015); Puertollano, 2,2; percentil 90 sobre percentil 10, de 2,1 a 3,0.

## Bloque E · Web

**50. Móvil · HECHA (11-nov-2026).**
- El mapa empieza tras unos 450 px de controles, y la ficha se abre dos pantallas más abajo al tocar una sección.
- La ficha se abre sobre el mapa o la página se desplaza a ella; controles plegables; menú sin desplazamiento horizontal.
- **Hecho cuando:** a 375 px, tocar un territorio deja su ficha a la vista sin desplazarse.
- **Hecho (11-nov-2026):** por debajo de 760 px, la ficha va antes que «Tu sueldo» y, al tocar el mapa, la página baja hasta ella (`web/js/movil.js`); menú en dos líneas; mapa en una fila de la barra y año en otra, con «Más opciones», que pliega la tipología y las descargas. A 375 × 812: el mapa empieza a unos 360 px (antes, 450) y, tras tocar Madrid, la ficha queda a 8 px del borde de arriba (antes, a 921 px). A 1280 y 1920, sin desbordes; solo la línea de transparencia bajo el mapa. Prueba en el navegador (`navegador_movil`) y `pruebas/web/movil.test.mjs`. **Por revisar** (plan §11, pregunta 58): ficha con desplazamiento y no encima del mapa; el mapa a 62vh pasa un poco del borde de un móvil de 812 px.

**51. Lectura del mapa.** · HECHA (11-nov-2026): siete tramos con tres juegos de cortes por indicador (sección, municipio, y provincia y comunidad) leídos de `inventario/cortes_web_niveles.csv`; la página pinta cada escala con su juego y la leyenda cambia de regla al acercar o alejar el mapa, con aviso y, en los juegos anclados, «tramos fijados con el último año». Rampa de siete pasos (0,075 en OKLab como mínimo con deuteranopía; `rampa_daltonismo` a 0,07). Cortes revisados a mano (alquiler mensual por municipio, variación del alquiler, juegos de provincia y comunidad) y recalculados (17, que ya divide por la renta por hogar, y 21, cuyas filas eran del mínimo de 50 m²). Compuerta `web_tramos` (alerta) y prueba de navegador `navegador_leyenda`. Leyenda abierta al entrar (en el móvil, bajo el mapa), sin contorno de sección por debajo del zoom 9, indicador de carga y Canarias en la vista inicial. Detalle en `CHANGELOG.md` y en la nota (§9.2). **Escala relativa al municipio · HECHA (11-nov-2026, decisión del autor):** a escala de sección, la leyenda ofrece «Tramos: De España · De <municipio>», con los septiles de las secciones del municipio de la ficha (o, sin ficha, del centro de la vista) en el año y la serie que se ven, calculados en la página (`web/js/escala_municipio.js`), redondeados a pasos de 1, 2, 2,5 o 5 por una potencia de 10; por defecto, la escala nacional; solo en los mapas con juego de la sección y en municipios con 14 secciones con dato o más; las secciones de fuera, sin color; la URL (`escala=municipio`) y el PNG llevan la escala. En 2024, con los cortes de la sección, el tramo más alto se lleva el 87 % de las secciones de Madrid y el 95 % de las de Barcelona en el alquiler mensual; con sus septiles, de 299 a 434 secciones por tramo en Madrid (de 2.421) y de 137 a 176 en Barcelona (de 1.061). Pruebas: `pruebas/web/escala_municipio.test.mjs` y `navegador_escala_municipio`. La capa de portales recibe los juegos (`cortes_niveles` en `portales_exportar_web()`).
- Saturación: en el tramo más alto está el 64 % de las secciones de Madrid y el 84 % de las de Barcelona. Opción de escala relativa al municipio, o más tramos por arriba.
- **Diagnóstico de los tramos (10-nov-2026; último año de cada serie, reparto de los territorios con dato entre los tramos de `cortes_web`):**

  | Indicador | Nivel | Reparto por tramo (%) | Problema |
  |---|---|---|---|
  | Renta por persona | municipio | 0 · 10 · 21 · 28 · 40 | el último corte (16.000 €) queda cerca de la mediana (14.600–16.000) |
  | Renta por persona | sección | 3 · 13 · 22 · 22 · 40 | ídem; el percentil 95 es 24.700 € |
  | Renta por hogar | sección | 3 · 15 · 26 · 21 · 35 | último corte, 40.000 €; percentil 95, 63.200 € |
  | Renta mediana por unidad de consumo | municipio | 1 · 4 · 20 · 38 · 37 | tres cuartas partes en los dos últimos tramos |
  | Renta mediana por unidad de consumo | sección | 3 · 4 · 16 · 32 · 44 | ídem |
  | Peso de los salarios | municipio | 40 · 18 · 18 · 14 · 6 · 3 | el primer corte (50 %) está en la mediana municipal |
  | Peso de los salarios | provincia | 0 · 19 · 50 · 27 · 4 · 0 | dos tramos vacíos |
  | Gini | provincia | 0 · 0 · 27 · 52 · 15 · 6 | dos tramos vacíos |
  | Variación del alquiler | municipio | 0 · 1 · 4 · 27 · 42 · 26 | los cortes (0 a 4 %) quedan por debajo de 2024 |
  | Alquiler mensual | sección | 6 · 14 · 15 · 28 · 38 | último corte, 650 €; percentil 95, 1.030 € |
  | Viviendas turísticas | sección | 68 · 12 · 11 · 5 · 3 | distribución muy asimétrica; puede ser correcto |

  - Causas: cortes fijados con cifras de los primeros años sobre series en euros corrientes (en 2024 todo se apila arriba); los mismos cortes para la sección y para la provincia, que tienen recorridos distintos; cinco tramos para recorridos largos.
  - Reparten bien y no hay que tocarlos: Gini, pobreza relativa y hogares en alquiler por sección; esfuerzo hipotecario y valor tasado por municipio.
  - Criterio propuesto para la compuerta: en el último año, ningún tramo con más del 35 % de los territorios ni vacío, por indicador y nivel. Excepción declarada: viviendas turísticas y zona tensionada.
- **Prueba de los cortes fijos recalibrados (10-nov-2026):** con cuantiles del conjunto 2015–2024, las series en euros empeoran en el último año. Renta por persona, 2024: 47 % de los municipios y 45 % de las secciones en el tramo más alto (hoy, 40 %). Alquiler mensual por sección: 55 % (hoy, 38 %).
  - Motivo: la mediana sube entre un 37 y un 57 % de 2015 a 2024 (renta por persona, +48 % por sección y +56 % por municipio; alquiler mensual, +43 %), y eso es del mismo orden que la distancia entre territorios de un mismo año (percentil 95 sobre percentil 5 de la renta: de 1,8 a 2,4). Ningún juego de cortes fijos en euros corrientes reparte bien el primer año y el último a la vez.
  - En cocientes y porcentajes no hay deriva (peso de los salarios, +2 %) y los cortes fijos recalibrados funcionan: ningún tramo pasa del 26 % ni en 2015 ni en 2024.
  - Alternativas medidas para las series en euros, con seis tramos (reparto en 2015 · 2024):

    | Serie y nivel | A · sextiles de 2024 | B · quintiles de 2024 y un tramo bajo en la mediana de 2015 |
    |---|---|---|
    | Renta por persona, sección | 72-11-6-4-4-3 · 16-16-18-15-19-16 | 48-28-9-7-4-4 · 3-19-17-22-19-21 |
    | Renta por persona, municipio | 87-8-3-1-1-0 · 15-17-21-14-16-17 | 53-37-6-2-1-0 · 0-19-19-21-19-21 |
    | Renta por hogar, sección | 70-9-6-6-4-4 · 18-15-16-19-15-17 | 51-18-12-8-5-5 · 5-13-20-23-19-20 |
    | Alquiler mensual, sección | 45-25-14-8-4-4 · 14-20-17-16-16-17 | 45-10-22-12-6-5 · 14-6-22-17-19-22 |

    Cortes de B para la renta por persona: 10.000, 12.500, 14.000, 16.000 y 18.500 € (sección); 10.000, 13.000, 14.500, 16.000 y 17.500 € (municipio).
  - El municipio y la sección no comparten recorrido en el alquiler: sextiles de 2024 del alquiler mensual, de 400 a 800 € por sección y de 325 a 575 € por municipio. En la renta sí se parecen.
- **Decidido (10-nov-2026):** decisiones 13 a 15. Propuesta calculada en `inventario/cortes_web_niveles.csv` (38 juegos de 16 indicadores):
  - regla: `recalibrado` (septiles de toda la serie) si ningún tramo pasa del 30 % en el último año ni del 35 % en el primero; si no, `anclado`;
  - resultado: en el último año, ningún tramo pasa del 32 % (hoy, hasta el 97 %); 19 juegos recalibrados y 19 anclados. En los anclados, el primer año queda cargado en los tramos bajos (del 37 al 69 %): es la subida de la década, y la leyenda lo dice («tramos fijados con el último año»);
  - por revisar a mano: el redondeo de los cortes (alquiler mensual por municipio, variación del alquiler, brecha) y los juegos de provincia y comunidad, con 19 y 52 territorios para siete tramos;
  - sin cambio: viviendas turísticas, zona tensionada y sobrecarga.
- **Implementación:**
  - `MAX_CORTES_WEB` pasa de 5 a 6 (`R/web_exportar.R`) y la exportación lee los cortes por juego; el manifiesto lleva los tres juegos y la página elige el del nivel que pinta;
  - rampa de siete pasos en `diseno/tokens.json`, construida como la de seis (extremos fijos, OKLab, pasos contiguos separados en visión normal y con las tres dicromacias simuladas); `pasosDeRampa()` y «¿te llega?» (hoy, pasos 1, 4 y 6) se ajustan;
  - leyenda: aviso al cambiar de juego y nota del año de anclaje;
  - compuerta: por indicador y juego, en el último año, ningún tramo vacío ni con más del 35 % (alerta), salvo las excepciones declaradas;
  - al entrar un año nuevo de datos, los cortes no se mueven; se revisan en cada versión mayor.
- **Objeción anotada:** siete tramos están en el límite de lo que se distingue en un mapa de coropletas con polígonos pequeños. La prueba de la rampa debe incluir la lectura a zoom de sección, no solo el contraste entre pasos; si falla, se vuelve a seis.
- **Hecho cuando:** los mapas usan los tres juegos con siete tramos, la compuerta pasa y la prueba de navegador comprueba el cambio de leyenda entre escalas.
- Leyenda abierta al entrar, sin tapar el mapa en pantallas pequeñas.
- Bordes de sección más finos, o sin ellos por debajo de cierto zoom.
- Indicador de carga: hoy hay de 5 a 8 segundos en blanco.
- Canarias dentro de la vista inicial.

**52. Portada al día · HECHA (11-nov-2026), salvo las cifras de «entrar».**
- Cartas con las cifras nuevas: sueldo para entrar, brecha, sueldo necesario real.
- Casillas «Zona tensionada» y «Tasación», activas: sus mapas ya existen.
- **Hecho (11-nov-2026):** el sueldo necesario real y el mínimo de 50 m² ya salían del pipeline (tarea 40; `portada.json`, compuerta `portada_valores`); el sueldo para entrar y la brecha, como cartas «próximamente», sin cifras ni enlace, como la familia «entrar» (`FAMILIAS_PROXIMAMENTE`); «Zona tensionada» (con una vista de municipios: el 20 no tiene otra escala) y «Tasación», activas (`inventario/casillas_portada.csv`, compuerta `portada_casillas`). **Falta:** las cifras de «entrar», por tramos, cuando Idealista autorice (decisiones 17–19).

**53. Transparencia · HECHA (11-nov-2026).**
- «Avisar de un error» y fe de erratas en la web.
- Fecha de los datos, visible en el mapa.
- «Método en dos páginas» (ES y EN), enlazado desde la ficha: qué mide cada familia y a quién deja fuera.
- **Avance (10-nov-2026):** borrador en castellano, `docs/metodo_corto.md`. Falta la versión inglesa, enlazarlo desde la web y la fe de erratas.
- **Hecho (11-nov-2026):** «Avisar de un error» (incidencias del repositorio) bajo el mapa, al pie de la ficha y en la portada; fecha de los datos bajo el mapa, del manifiesto (`web/js/transparencia.js`); «Método en dos páginas» revisado contra las cifras actuales y sin cifras de Idealista, en castellano e inglés (`docs/metodo_corto.md`, `docs/short_method.md`), generado por el flujo de Pages (`metodo_corto.html`, `short_method.html`) y enlazado desde la ficha; fe de erratas al final, desde `inventario/erratas.csv` (`web/herramientas/pagina_metodo_corto.mjs`), hoy vacía. Pruebas: `pruebas/web/transparencia.test.mjs`. **Por revisar** (plan §11, pregunta 58): si los cambios de las tareas 40 y 41 cuentan como erratas de la v0.4.0. Las páginas se ven en el sitio con la próxima publicación.

## Bloque F · Ingeniería

**54. Pruebas en cada push · HECHA (11-nov-2026).** Flujo de GitHub con las pruebas que no necesitan datos (inventario, utilidades, web con la muestra). El de publicación sigue manual.
- **Hecha en local (11-nov-2026), falta la primera ejecución en GitHub:** `.github/workflows/pruebas.yml`, con cada push y cada *pull request*: la batería de `testthat` entera con `renv` (caché y paquetes compilados de Posit Package Manager) y `node --test pruebas/web/*.test.mjs`. Las pruebas que piden datos ya se saltaban solas; en una copia limpia del repositorio pasan todas las demás (`pruebas/LEEME.md`).
- Por revisar tras el primer push: tiempo sin caché, versiones de `renv.lock` en binario, pruebas del mapa base con el GDAL de Ubuntu y uso de las acciones de r-lib (CHANGELOG).
- **Primera ejecución en GitHub (11-nov-2026, commit `d874fdb`):** la parte de la web pasa; la de R falla al restaurar `renv`, porque el binario de `igraph` no carga sin la biblioteca GLPK del sistema. Añadidas `libglpk-dev` y `libxml2-dev` a las bibliotecas del sistema del flujo. Comprobado: las pruebas pasan en GitHub desde el commit `df67c1b` (R y web).

**55. Avisos del pipeline (93) · HECHA (11-nov-2026).**
- 56 de geometría sobre coordenadas geográficas: proyectar antes de calcular el punto interior.
- 6 «NA introducidos por coerción» en el módulo de salarios que alimenta la mochila: explicarlos o corregirlos.
- **Hecho cuando:** cada aviso que quede está justificado en `docs/actualizacion.md`.
- **Hecha (11-nov-2026):** los 6 de coerción, corregidos (`aeat_sangria()`: sangría en píxeles); los que quedan, justificados en `docs/actualizacion.md` («Avisos de `tar_make()`»). Los 56 de geometría, corregidos con `punto_interior()` en `leer_catastro_foral()` (autorizado por el autor): rehízo `edificios_foral` (7 min 45 s) y las diez `paso_catastro_*` (unos 13 min); ningún edificio foral cambia de sección y las tablas de paso salen idénticas, así que las compuertas de F1 y de las tablas de paso no cambian. Queda el aviso de Gipuzkoa (`b5mdev`), justificado.

**56. Limpieza · HECHA (11-nov-2026).**
- Fichero `0` de la raíz, fuera de git: borrado (salida de una redirección mal escrita) y `.gitignore` al día. Falta que el autor registre el borrado en git.
- Textos que aún dicen que el Notariado «no se puede reutilizar»: nota, plan, guía, fila `notariado` de `inventario/fuentes.csv` y comentarios del código. La fila del indicador 11, con la tarea 46.
- La guía y el README apuntan a este backlog.

**57. Licencias · HECHA (11-nov-2026).** Tabla única en la nota (§2): qué fuente, qué licencia, qué obliga. Señala los tres catastros con licencias contradictorias, la ODbL de Registradores, las geometrías europeas de uso no comercial e Idealista (solo web). Plan de retirada por fuente.
- **Avance (10-nov-2026):** tabla resumida en `docs/metodo_corto.md`. Falta Registradores (tarea 46) y el plan de retirada por fuente.
- **Hecha (11-nov-2026):** tabla única en la nota (ES y EN, §2.2) y plan de retirada (§2.4); `docs/metodo_corto.md`, `LICENCIA_DATOS.md` y la página «Datos», al día. La ODbL en el paquete (`version.json`), con la tarea 46.

**58. Reproducir en limpio.** Ejecutar el pipeline en otra máquina, desde `renv::restore()`, con la lista de descargas manuales. Anotar lo que falle.
- **Aplazada (11-nov-2026), decisión del autor.** Desde cero son unos 9,6 GB de descargas (Catastro, 4,2 GB; ADRH, 3,0 GB) y unas tres horas y media de cálculo.
- **Preparada (12-nov-2026), sin ejecutar.** Guía en `docs/reproducir.md`; lista de descargas manuales en `inventario/descargas_manuales.csv`; `brutos_informe()` (`R/brutos_comprobar.R`) dice qué falta en `datos/brutos/` antes de `tar_make()` (contra la carpeta del autor: completa). Las tres manuales que paran el pipeline: SERPAVI, Registradores (no con `PROVINCIA`) y las unidades del IGN; Idealista, solo con `PORTALES=TRUE`. El SMI del BOE lo baja el pipeline.
- **Por revisar (propuesta):** (a) dónde: primero una copia limpia en el mismo equipo (otra carpeta, caché de `renv` vacía), con `PROVINCIA=28` y después completa; luego otro equipo, solo con `PROVINCIA=28`, para probar la instalación. (b) Ficheros de fuera: la ECV y el seccionado de 2025 los baja el pipeline de la fuente, y se comparan con los copiados (tamaño y SHA-256); Registradores y SERPAVI, con el navegador desde su página (si ya hay otra edición, se copia la del equipo del autor); las unidades del IGN se copian hasta que haya una `descargar_ign_au()`.
- **Hecho cuando:** la pasada corta y la completa acaban sin errores en la copia limpia, con `tar_outdated()` vacío, `testthat` y las pruebas de la web en verde, `git status` sin cambios y la tabla larga igual a la del release salvo `version`; tiempos y fallos anotados aquí.

**62. Carga inicial del mapa.** Abrir `mapa.html` cuesta unas 68 peticiones y 1,2 MB comprimidos (medido el 12-nov-2026).
- 29 módulos sin `modulepreload`, que el navegador descubre uno detrás de otro; MapLibre pesa 293 KB y su *worker*, 147 KB.
- Se cargan los cuatro niveles (comunidad, provincia, municipio y sección) aunque no se vean secciones: unos 370 KB.
- El primer clic en una sección pide 20 ficheros nacionales de contratos y margen (0,77 MB), que la ficha lee de los ficheros de cada periodo, más el fichero de fichas de su municipio (el de Madrid, 2,6 MB; 0,6 comprimido).
- Propuesta: el nivel `sc` (su índice y sus valores) solo con zoom ≥ 7, cuando el mapa base ya trae secciones; los contratos y el margen dentro de `fichas/<municipio>.json`, para no bajar los nacionales; partir las fichas de los municipios grandes (por distrito o por serie); `modulepreload` de los módulos en `mapa.html`.
- **Hecho cuando:** abrir `mapa.html` sin vista en la dirección no pide el índice `sc` ni ningún fichero de valores de sección; el primer clic en una sección de Madrid baja menos de 0,3 MB comprimidos y ningún fichero nacional; el total de la carga inicial (peticiones y bytes comprimidos, medido igual) baja y queda anotado aquí, con las pruebas de la web y `comprobar_web_navegador()` en verde.

## Bloque G · Verificación y v1.0

**59. Rederivar a mano** diez cifras de F4–F6 y cinco de «Entrar», desde los ficheros de la fuente. · **HECHA (11-nov-2026).**
- `pruebas/rederivar/rederivar.R`, sin cargar `R/` ni leer objetivos para la cifra a mano: dieciséis cifras de F4 a F6 (10, 11, 12, 16, 17, 20, histórico y CIS) desde `datos/brutos/`, frente a la tabla larga, el histórico y la web; `pruebas/rederivar/rederivar_entrar.R`: cinco de «Entrar» y la superficie típica, con las cifras exactas solo en `datos/intermedios/rederivar/` y en el repositorio «coincide / no coincide» y el tramo de la brecha. Tabla y método en `docs/rederivacion.md`.
- Coinciden 15 de 16 y las cinco de «Entrar». No coincide el 17 de 2024 (Madrid: 30,43 a mano, 30,40 en el atlas): la media del tipo del Banco de España de 2024 es exactamente 3,465 y `sprintf("%.2f")` la deja en 3,46 (el binario queda por debajo); con el empate hacia arriba, 3,47. Afecta a todo el 17 de 2024, unos 0,03 puntos. Sin cambiar: lo decide el autor (plan §11, pregunta 59).
- **Decidido y aplicado (11-nov-2026), decisión del autor:** el tipo se redondea con el empate hacia arriba (`redondear_empate_arriba()`, 3,47 % en 2024) y la rederivación coincide en las dieciséis cifras (Madrid, 30,43 a mano y en el atlas). En la misma tanda, el 17 de provincias y comunidades donde el INE no publica la renta por hogar pasa a `ausente` (22 cifras) y España sigue `estimado`.

**60. Lectura externa.** Una persona que no haya participado revisa la nota corta y el mapa antes de anunciar. El autor decide quién.

**61. *Release* v1.0 · HECHA (11-nov-2026).** Paquete con el histórico, prueba de navegador contra el sitio publicado, CHANGELOG `[1.0.0]`, descongelar el sitio.
- **Decidido (11-nov-2026), decisión del autor:** la v1.0 sale ya, antes de la prueba en limpio (58, aplazada) y de la lectura externa (60), que quedan como revisión posterior. Preparados `CHANGELOG.md` `[1.0.0]`, `CITATION.cff` (1.0.0) y `README.md`. - **Hecho (11-nov-2026):** release `v1.0.0` sobre `df67c1b` (seis ficheros, `version.json` sin cambios sin commit), `ref` por defecto de `pages.yml` en ese commit y sitio publicado. Contra el sitio, la prueba en el navegador da 0 en sus 56 comprobaciones (300 secciones, historias incluidas) y el PMTiles responde `206`. Al empaquetar, la comprobación `versiones` paraba con el indicador 18, que lleva dos fuentes desde la tarea 47: corregida en `R/publicar.R`, con su prueba.

## Orden

33 → 34 → 35 y 36 (en paralelo) → 37 → 38 y 39 → 40 a 45 → 46 → 50 a 53 → 47 a 49 → 54 a 58 → 59 a 61. La 62 (carga inicial del mapa), después de la v1.0, sin fecha.

Los bloques B y C van antes que la web porque cambian las cifras que la web enseña.

## Para la v1.2

La v1.1.0 (12-nov-2026) salió con la revisión de las seis lecturas, «Tu sueldo» y los datos de 2025; lo que esta lista reservaba «para la v1.1» pasa a la siguiente.

- Venta y otros portales.
- Microdatos del CIS por comunidad.
- Línea de ingreso residual.
- Autorización del Notariado, si llega.
- Geometría de las zonas de Idealista, si hay fuente reutilizable.
- Barrios de Idealista, si la extracción guarda el enlace de cada fila y hay más de un mes.
- Pestaña «Reglas del juego», con resúmenes de las leyes vigentes. Hasta entonces, la casilla «Ley de Vivienda» de la portada va sin enlace («próximamente»; decisión del autor, 12-nov-2026).

## Por decidir

- Nada pendiente a 10-nov-2026.
