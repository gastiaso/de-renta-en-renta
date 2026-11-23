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
- **Prueba parcial (17/18-nov-2026), en el mismo equipo y sin descargas.** Copia limpia del commit 51e899a en otra carpeta, con una copia de `datos/brutos/` y la red cortada (proxy muerto); los feeds ATOM del Catastro, que se pedían siempre, con el valor guardado por el pipeline. `tar_make()` acaba sin errores en 3 h 56 min de cálculo (Catastro estatal, 2 h 12 min); `tar_outdated()` vacío; ninguna compuerta de bloqueo falla y las alertas son las mismas; la tabla larga, igual a la del proyecto (12.292.365 filas) salvo `version` del indicador 20, que salía de la fecha de `inventario/zonas_tensionadas.csv` (en una copia, la del checkout). Pruebas de la web en verde (259); `testthat`, 2.794 comprobaciones y 1 fallo (`test-navegador.R`: sin `metodo.html`, `method.html` ni `descargas/version.json`, que no salen de `tar_make()`). `renv::restore()` con la caché vacía necesita Rtools (`diffobj` 0.3.9 y `arrow` 26.0.0 ya no tienen binario para R 4.6 en CRAN; sin compilador, `renv` no instala nada); con la caché global, 1,4 min. `git status`: `web/estilo/tokens.css` con CRLF.
  - **Decisiones del autor (18-nov-2026):** Rtools 4.6 obligatorio en Windows (`docs/reproducir.md`); caché de los feeds del Catastro en `datos/brutos/`, renovada por el calendario; `version` del indicador 20, la fecha del BOE más reciente de `inventario/zonas_tensionadas.csv`; `tokens.css` con LF; `test-navegador.R` da por pendientes las páginas que monta el flujo de Pages; el GML de Gipuzkoa, sin buscar esquemas fuera. Queda la parte de otro equipo con `PROVINCIA=28`.
  - **Arreglos (18-nov-2026):** feeds del Catastro y forales con caché en `datos/brutos/` (mismo valor, nada rehecho), `version` del indicador 20 desde el BOE más reciente del inventario, `tokens.css` con LF, `test-navegador.R` con las páginas de Pages pendientes si faltan, GML forales sin pedir esquemas fuera (ramas idénticas) y Rtools 4.6 obligatorio en `docs/reproducir.md` y la guía. **Por revisar:** los feeds no se renuevan solos (se borra `feeds/`); `DOWNLOAD_SCHEMA=NO` en los cuatro forales; `brutos_informe()` no avisa si faltan los feeds. Pendiente: otra copia limpia con estos cambios, `PROVINCIA=28` en otro equipo.
- **Hecho cuando:** la pasada corta y la completa acaban sin errores en la copia limpia, con `tar_outdated()` vacío, `testthat` y las pruebas de la web en verde, `git status` sin cambios y la tabla larga igual a la del release salvo `version`; tiempos y fallos anotados aquí.

**62. Carga inicial del mapa · HECHA (12-nov-2026).** Abrir `mapa.html` cuesta unas 68 peticiones y 1,2 MB comprimidos (medido el 12-nov-2026).
- 29 módulos sin `modulepreload`, que el navegador descubre uno detrás de otro; MapLibre pesa 293 KB y su *worker*, 147 KB.
- Se cargan los cuatro niveles (comunidad, provincia, municipio y sección) aunque no se vean secciones: unos 370 KB.
- El primer clic en una sección pide 20 ficheros nacionales de contratos y margen (0,77 MB), que la ficha lee de los ficheros de cada periodo, más el fichero de fichas de su municipio (el de Madrid, 2,6 MB; 0,6 comprimido).
- Propuesta: el nivel `sc` (su índice y sus valores) solo con zoom ≥ 7, cuando el mapa base ya trae secciones; los contratos y el margen dentro de `fichas/<municipio>.json`, para no bajar los nacionales; partir las fichas de los municipios grandes (por distrito o por serie); `modulepreload` de los módulos en `mapa.html`.
- **Hecho cuando:** abrir `mapa.html` sin vista en la dirección no pide el índice `sc` ni ningún fichero de valores de sección; el primer clic en una sección de Madrid baja menos de 0,3 MB comprimidos y ningún fichero nacional; el total de la carga inicial (peticiones y bytes comprimidos, medido igual) baja y queda anotado aquí, con las pruebas de la web y `comprobar_web_navegador()` en verde.
- **Hecha (12-nov-2026):** el índice y los valores del nivel `sc` solo con zoom ≥ 7 (`secciones_desde_zoom`), con una sección elegida o con que comparar, en «¿te llega?» o al buscar un código de sección; la banda de la llave, de los cuartiles del manifiesto (`cuartiles_sc`); contratos y margen dentro de las fichas; los 47 municipios de más de 100 secciones, partidos por distrito (**por revisar**: también cabía por serie; umbral de 100 secciones; las secciones se piden al cruzar el zoom 7, cabría adelantarlo a 6,5); `modulepreload` de los 29 módulos. Medido igual (Chrome sin cabeza, gzip de cada fichero entero y cuerpo de las respuestas parciales del PMTiles): abrir `mapa.html` sin vista pasa de 76 peticiones y 1,27 MB comprimidos a 69 y 0,89 MB, sin índice `sc` ni valores de sección; el primer clic en una sección de Madrid, de 20 peticiones y 1,28 MB a 2 y 0,04 MB (`fichas/28079/01.json` e `ipc.json`), sin ficheros nacionales. Pruebas de la web (`pruebas/web/carga.test.mjs`, nueva), testthat de la exportación y `comprobar_web_navegador()` en verde (58 comprobaciones, con `navegador_carga`); `tar_outdated()` vacío. El código de la v1.1.0 no lee las fichas partidas: el próximo release de datos sale con este código o posterior.

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

## Bloque H · v1.2 (13-nov-2026)

Tres tareas desde las especificaciones decididas el 13-nov-2026 (decisiones del autor). Descargas aprobadas: el release `v2026-10` de *Barómetro a barómetro*, los textos consolidados del BOE y las cuantías del IMV, de las pensiones no contributivas y el umbral de pobreza de la ECV.

**63. CIS por comunidad autónoma · HECHA (13-nov-2026).** `docs/especificacion_cis_comunidad.md`: microdatos armonizados de *Barómetro a barómetro* (release `v2026-10`, con su SHA-256), `peso`, tabla `cis_vivienda_ccaa` desde 2021 con 2023 marcado (R10), Ceuta y Melilla de dos en dos años, problema de España y personal.
- **Hecho cuando:** se cumple el «Hecho cuando» de la especificación; las compuertas `cis_ccaa_*` en verde, con `cis_ccaa_espana` reproduciendo la serie nacional publicada mes a mes; la tabla en la «Máquina del tiempo» y una línea en la ficha de comunidad, en los dos idiomas.
- **Hecho (13-nov-2026):** `R/fuente_cis_ccaa.R`, `inventario/cis_ccaa_ficheros.csv` y `inventario/cis_ccaa_comunidades.csv`; 240 filas (19 comunidades y España, 2021–2026, dos preguntas), todas con cifra. `cis_ccaa_espana`: 124 cifras mensuales de España, exactas a un decimal; alertas: nueve márgenes de Ceuta y Melilla de más de ±5 puntos y junio y septiembre de 2023 sin cifra nacional. Bloque «Por comunidad autónoma» en `historico.html` y línea en la ficha de comunidad (`web/js/cis_ccaa.js`), en los dos idiomas; nota §7.10.
- **Por revisar:** (a) Ceuta y Melilla van en ventana móvil (cada año con el anterior), no en parejas fijas; (b) la web de *Barómetro a barómetro* da el margen con Wald y el efecto de diseño del estudio, y aquí va Wilson con el de Kish de la base, como se decidió: las cifras centrales coinciden y los márgenes pueden diferir algo; (c) junio y septiembre de 2023 están en los microdatos y no en la serie nacional del atlas; (d) el CSV va en los datos del sitio, no en las descargas del release; (e) la ficha del mapa da el año en curso y la tabla abre en el último año completo.
- **Contraste (17-nov-2026):** (c) junio y septiembre de 2023 sí tuvieron barómetro, los estudios 3410 y 3420 («postelectorales»), con una dirección del CIS más larga que la que arma `cis_url_estudio()`: dieron 404 y quedaron como `.sin_estudio` el 10-nov-2026. El CIS publica la vivienda (13,3 / 12,1 % en junio; 6,4 / 8,8 % en septiembre, España / personal), igual que los microdatos. Propuesta: tabla de excepciones de dirección en `inventario/` y volver a bajar esos dos estudios (descarga por autorizar); quizá la misma causa explica los huecos de julio de 2016 y de cuatro meses de 2019 (sin comprobar).
- **Hecho (17-nov-2026, descargas autorizadas por el autor):** (c) resuelto con `inventario/cis_url_excepciones.csv`: entran junio y septiembre de 2023 (estudios 3410 y 3420; 13,3 / 12,1 % y 6,4 / 8,8 %) y, de los otros huecos, julio de 2016 (3146) y marzo y diciembre de 2019 (3242 y 3269). Abril y octubre de 2019 (macrobarómetros 3245 y 3263) no tienen resultados en HTML y siguen en la alerta `cis_vivienda_meses`. `cis_ccaa_espana`, 128 cifras exactas, sin alertas `cis_ccaa_meses`.

**64. «Reglas del juego» · HECHA (13-nov-2026), salvo la revisión jurídica.** `docs/especificacion_reglas_del_juego.md`: inventario de normas y resúmenes (CSV → JSON → página), los siete temas estatales con lo autonómico como enlaces, comprobación de vigencia con la API del BOE, casillas 7, 10, 17 y 22 de la portada activas, `reglas_literal` de bloqueo; subtítulo «Normativa vigente». Los resúmenes quedan en `borrador` hasta la revisión jurídica del autor, y la compuerta no deja publicarlos antes.
- **Hecho cuando:** se cumple el «Hecho cuando» de la especificación, con los resúmenes en `borrador` y la página lista para cuando el autor los dé por buenos.
- **Hecho (13-nov-2026):** página `reglas.html` desde `inventario/reglas.csv` (siete temas), `reglas_normas.csv` y `reglas_literales.csv` (58 literales, todos en el texto vigente), con `R/reglas.R`, `datos/reglas.json` y `web/js/reglas.js`; fuente `boe_legislacion` y compuertas `reglas_*` y `web_reglas`; casillas 7, 10, 17 y 22 a sus anclas, la 3 y la 8 con enlace desde su destino, ficha del 20 con «Qué supone la declaración». Decretos-leyes comprobados en el BOE: el 29/2026, convalidado; el 28/2026, derogado (BOE de 13-nov-2026).
- **Falta:** la revisión jurídica del autor de los siete resúmenes. Hasta entonces el sitio publica solo sus títulos, «en revisión». Puntos que leer primero, con detalle en el CHANGELOG de la tarea: la garantía adicional como «aval» (fianza), la prórroga extraordinaria del RDL 29/2026, los límites de 2022–2024 a la actualización, los gastos a cargo del arrendador desde la Ley 12/2023, el órgano que publica las zonas tensionadas, los preceptos anulados por la STC 79/2024 y los términos ingleses.
- **Por revisar:** la página publicada con títulos «en revisión» (alternativa: no publicarla hasta el primer resumen revisado); la casilla 7 sin ancla; el cómputo del plazo de convalidación en la compuerta (días hábiles de lunes a viernes y 10 días de margen).
- **Contraste (17-nov-2026):** el BOE consolidado ya da por derogado el RDL 28/2026 (`BOE-A-2026-20822`: `estatus_derogacion` S, `fecha_derogacion` 20261113) y recoge la convalidación del 29/2026 (`BOE-A-2026-20823`, en `/analisis`); los identificadores 23754 y 23755 son las resoluciones del Congreso. Cuando se renueve la caché de metadatos, `reglas_al_dia` dejará este aviso y avisará de normas «actualizadas en el BOE» (LAU, 28/2026 y 29/2026) hasta anotar sus `fecha_actualizacion` en `inventario/reglas_normas.csv`.
- **Hecho (17-nov-2026, decisión del autor):** caché del BOE renovada para la LAU, el 28/2026 y el 29/2026; el artículo 10 de la LAU ya no lleva intercalada la redacción del 28/2026 y su texto vigente no cambia. `inventario/reglas_normas.csv` anota las `fecha_actualizacion` de 13-nov-2026 (consulta de 17-nov-2026), y de los cambios de `duracion_prorroga` sale la frase que ya no era cierta. `reglas_al_dia` sin alertas y las demás compuertas de las reglas en verde.
- **Hecho (19-nov-2026, decisión del autor: «adelante» con la guía de revisión jurídica):** propuestas P1–P21 aplicadas en `inventario/reglas*.csv`, tras leer en el BOE las lecturas pendientes (todas salvo las redacciones anteriores del art. 46 del RDL 6/2022, opcional): la DT 4ª de la Ley 12/2023 confirma lo que decían los resúmenes; el fallo de la STC 79/2024 anula también el art. 16; la DT 8ª de la LAU solo regula los contratos de temporada y de vivienda temporal anteriores al 8-oct-2026; la actualización del sistema de índices de 29-sep-2025 es `BOE-A-2025-19403`. 78 literales en el texto vigente; compuertas `reglas_*` y `web_reglas` en verde, con la alerta `reglas_borrador` (7). Los siete resúmenes siguen en `borrador`.
  - **Falta:** la firma del autor de cada resumen (`revisado` con la fecha); con ella, `empaquetar_publicacion()` publica su texto. Los puntos delicados de «Falta» quedan como referencia de lo que mirar al firmar.
  - **Por revisar:** (a) casilla 17, «Aval de tus padres»: sigue llevando a la fianza y garantías, con su literal en el art. 36.5 marcado «por revisar» (alternativas: quitar el enlace o llevarla a otra regla); (b) el IRAV como tope desde 2025 por la disposición adicional undécima, que no se afirma; (c) temas 5 y 7: ninguna transitoria dice a qué contratos se aplican los cambios de los arts. 18.1 (salvo los anteriores a 2023) y 20 del Real Decreto-ley 29/2026, y los resúmenes no lo dicen; (d) «Las comunidades que lo han establecido» (F13) no sale de la LAU.

**65. Línea de ingreso residual · HECHA (parte A, 13-nov-2026; parte B y remates de la web, 17-nov-2026).** `docs/especificacion_ingreso_residual.md`, parte A: líneas del IMV y del umbral de pobreza de la ECV con selector (IMV por defecto), PNC rotulada de 2015 a 2019, en «Tu sueldo», la ficha y como regla de «¿te llega?» (selector apagado por defecto), tres tramos y sin hogares con menores. La parte B (riesgo de pobreza tras los gastos de vivienda, ECV), después.
- **Hecho cuando:** se cumple el «Hecho cuando» de la especificación; R y la página coinciden en la muestra.
- **Hecho (13-nov-2026):** líneas del IMV y del umbral de la ECV por año y tipo de hogar en la tabla larga y en `datos/lineas_residual.json`, con las compuertas `residual_*` (BOE e INE); en «¿te llega?», la distancia a la línea en la ficha y la regla «Lo que queda» del mapa; R y la página coinciden en la muestra (`residual_muestra`); nota metodológica, §7.4 y §8. Las cifras «por verificar» de la especificación, contrastadas: umbral de la ECV 2025, 12.220,4 € (tabla 9964); IMV de 2026, RDL 3/2026; IPREM de 2026, 600 € al mes.
- **Remates de la web (17-nov-2026):** segunda cifra del sueldo necesario con la línea de una persona (alquiler + otros gastos + línea; selector «Línea» también en el sueldo necesario); la línea de cada año en la evolución de la ficha de «¿te llega?» (PNC de 2015 a 2019); columnas de la línea en el CSV de «¿te llega?» y, con las fichas de una persona, lo que queda menos la línea; la cuenta de la portada con la línea del IMV, comprobada en R con todas las secciones (`cuenta_portada_residual`, en `residual_muestra`). `navegador_casillas` fallaba por la comprobación (buscaba en el HTML las anclas que `reglas.html` pinta con JavaScript), no por la página: ahora nombra los destinos que fallan y acepta, diciéndolo, la casilla 7 sin ancla.
  - **Por revisar:** (f) la frase de la segunda cifra repite el nombre de la línea; (g) el sueldo necesario con la línea usa siempre la de una persona, también al repartir entre dos sueldos; (h) el selector «Línea» se ve también en el sueldo necesario; (i) la portada, solo con el IMV, sin selector; (j) rótulos de la evolución redondeados al euro y «NCP» en inglés, que no es sigla establecida; (k) nombres de las columnas del CSV y la distancia solo con las fichas de una persona (con «Tu ficha» dejaría despejar el sueldo); (l) siguen sin la línea el comparador, «Método en dos páginas» y `web/LEEME.md`.
- **Parte B · HECHA (17-nov-2026):** indicador 24, riesgo de pobreza tras los gastos de vivienda (`R/fuente_ine_ecv_pobreza.R`; fuente nueva `eurostat_ilc_li48`, `R/fuente_eurostat_ilc_li48.R`): renta disponible menos 12 × HH070, por unidad de consumo (HX240), por debajo del 60 % de la mediana de la renta equivalente antes de la vivienda (definición de Eurostat, *Statistics Explained*, «EU-SILC methodology – monetary poverty»). España en total y por tenencia y cada comunidad, olas 2023–2025; comunidad × tenencia con las tres olas agrupadas; 192 filas en la tabla larga. Compuertas de bloqueo: `ahc_es_eurostat` (29,634 · 29,097 · 28,692 frente a 29,6 · 29,1 · 28,7 de Eurostat), `ahc_umbral_ine` (0,05 € como máximo) y `ahc_tenencia_total`. En «Sobrecarga», selector «Medida» (`medida=pobreza`): mapa, escalera con los países de `ilc_li48` (España, puesto 23 de 49 en 2025), tabla de comunidades, ficha y desgloses de España por tenencia; ida y vuelta en `web_sobrecarga_*`. Nota metodológica §4.1 y §7.5; «Método en dos páginas». Descarga: `ilc_li48` por la API de Eurostat (93.945 bytes; autorizada por el autor el 17-nov-2026).
  - **Por revisar:** (1) solo las olas 2023–2025, como el 22 (los zips de 2016–2022 ya están); (2) hogares sin HH070, fuera (contados con gasto 0, 29,7 en 2023 frente a 29,6); (3) las ayudas a la vivienda, sin tocar: la regla sale de la sobrecarga y de reproducir las tres cifras, no de un texto literal de Eurostat; (4) sin desglose por edad (haría falta `ilc_li45`, no autorizada); (5) el grado de urbanización, solo el total; (6) las vistas por tenencia pintan solo España y comunidades (Eurostat no publica la tasa por tenencia); (7) con la medida de pobreza, la serie de España sigue siendo la de la sobrecarga; (8) cortes del mapa a ojo sobre 2025; (9) nombres `pobreza_tras_vivienda` y `ahc_*`; (10) umbral en la web redondeado al euro; (11) se reutilizan los ids `web_sobrecarga_*` con el detalle «pobreza: …»; (12) con la pobreza, la nota de edades de los desgloses sigue visible.
- **Por revisar:** (a) el IMV mensual, redondeado al céntimo (604,22 € en 2024; la Seguridad Social podría truncar: 604,21); (b) 2018, con los 5.321,40 € de la Ley 6/2018 para todo el año; (c) 2022, media ponderada por meses (546,94 €); (d) 2020 rotulado IMV aunque empieza en junio; (e) con la regla «Lo que queda», el mapa de la llave queda sin color.
- **Decisiones del autor (17-nov-2026), aplicadas:** (a) IMV y PNC truncados al céntimo (604,21 € en 2024), con las cifras publicadas de 2023–2025 en `residual_imv_publicada`; (d) rótulo «IMV desde el 1 de junio de 2020»; (e) con la llave, «Lo que queda» pinta con la proporción y una nota lo dice, y la elección se recupera al cambiar de ficha; (f) segunda cifra sin repetir el nombre de la línea; (j) «pension» en inglés; (l) la línea en «Método en dos páginas» y `web/LEEME.md`, el comparador sin ella. Parte B: (1) el 22 y el 24 con las olas 2016–2025; (4) el 24 de España por edad (`ilc_li45`, descarga autorizada); (5) por grado de urbanización, con compuerta y en la web; (7) con la pobreza, la serie de España y la UE-27 de `ilc_li48`; (12) con la pobreza, la nota de edades de la sobrecarga oculta y una propia. Sin cambios: (b), (c), (g), (h), (i), (k) y, de la parte B, (2), (3), (6), (8), (9), (10) y (11).
- **Por decidir (de la ampliación a 2016–2025):** (m) trienios móviles (cada ola con las dos anteriores) o fijos para los cruces por comunidad, y si la regla pasa a `supuestos.csv`; (n) el mapa del 22 de 2016 a 2020 (`ilc_lvho07_r` empieza en 2021: otra tabla de Eurostat o solo España); (o) comunidad × edad del 24 y edad en su mapa; (p) grado de urbanización también en el 22; (q) el grupo «18 y más» (`Y_GE18`) en los desgloses de edad; (r) la ruptura de 2013 también en la serie del 24.
  - **Decididas por el autor (17-nov-2026):** (m) trienios móviles, con la regla en las notas de `inventario/indicadores.csv`; (n) el mapa del 22, en 2021–2025; (o) el 24 por edad también por comunidad (con trienios) y en el mapa europeo (países de `ilc_li45`); (p) grado de urbanización también en el 22, con la tabla de Eurostat (descarga autorizada); (q) «18 y más» se queda en la web; (r) la ruptura de 2013 se queda en el 24. (o) y (p), hechas el 18-nov-2026.
  - **Hecho (18-nov-2026):** (o) el 24 por comunidad y edad (los cuatro grupos de `ilc_li45`) con trienios móviles, compuerta de coherencia `ahc_ccaa_edad_total` (bloqueo; 0 en las 304 comprobaciones; Eurostat no publica la tasa por comunidad) y 1.850 filas del 24 en la tabla larga; en el mapa europeo y «La escalera», por edad con los países de `ilc_li45` (ambos sexos, 2025) y las comunidades del último trienio. (p) el 22 de España por grado de urbanización (DB100), compuerta de bloqueo `sobrecarga_es_urbanizacion` frente a `ilc_lvho07d` (fuente nueva; descarga autorizada, 99.493 bytes): las 30 cifras de 2016 a 2025, diferencia máxima 0,055 puntos; en la tabla larga y en los desgloses de España de la web. Nota metodológica, «Método en dos páginas», LEEME, plan (v0.55) y CHANGELOG.
  - **Por revisar (18-nov-2026):** (s) la compuerta de comunidad × edad es de coherencia (los grupos rehacen el total de la comunidad con las mismas olas), no frente a una cifra publicada; el total agrupado de cada comunidad se calcula solo para ella y no se publica; (t) el mapa por edad pinta los países de `ilc_li45` de ambos sexos y la última ola, como la sobrecarga por edad, y también «18 y más», que se solapa con los otros dos grupos de adultos (como en los desgloses, decisión (q)); (u) los cortes del mapa por edad son los generales del 24 (20–40 %): con 65 y más, 8 de 51 territorios quedan por debajo del 20 % y 13 por encima del 40 %; con menores de 18, 10 por encima del 40 %; (v) el 22 por grado de urbanización, solo España: sin comunidades ni países en el mapa; (w) ciudades de 2017: 11,35 % frente al 11,3 de Eurostat, la única de las 30 cifras que no coincide a un decimal (pasa la tolerancia de ±0,1 puntos); (x) el título de los desgloses de la sobrecarga pasa a «España por tenencia, edad, renta y grado de urbanización».
  - **Decididas por el autor (18-nov-2026):** (s) el total agrupado de cada comunidad (trienios móviles) se publica, en la tabla larga y en la web; (t) «18 y más» se queda en el mapa; (u) los cortes generales del 24 para todas las edades; (v) el 22 por grado de urbanización también por comunidad, con trienios móviles (sin cifra publicada con que comparar: compuerta de coherencia); (w) ciudades de 2017, sin más; (x) el título se queda. (s) y (v), hechas el 18-nov-2026: total agrupado del 24 por comunidad en la tabla larga (`olas`/`trienio`) y en la web; el 22 por comunidad y grado de urbanización (trienios, compuerta `sobrecarga_ccaa_urbanizacion_total`, mapa con los países de `ilc_lvho07d`). **Por revisar:** el nombre `olas`/`trienio`; el mapa por grado de urbanización con países, además de las comunidades; el total agrupado del 22, solo para la compuerta; la columna del trienio al final de la tabla de comunidades, sin muestra propia (la muestra, en la ficha).
- **Contraste con las fuentes (17-nov-2026; detalle y URL en las notas de la sesión):** (a) la Seguridad Social **trunca** el IMV mensual: publicó 565,37 € (2023), 604,21 € (2024) y 658,81 € (2025), y da la anual como la mensual × 12; el atlas, un céntimo más (dos adultos y 2026 coinciden). Propuesta: truncar al céntimo en `R/linea_residual.R` (cambia también un céntimo en cuatro cifras de la PNC de 2015–2018). (b) Correcta: la Ley 6/2018 fija los 5.321,40 € «en el año 2018» y los atrasos desde enero se pagaron en julio. (c) Cuadra: RDL 6/2022, art. 45 (15 %, abril–junio), ampliado por el RDL 11/2022 hasta el 31 de diciembre. (d) El RDL 20/2020 entró en vigor el 1-jun-2020; propuesta: rótulo «IMV desde el 1 de junio de 2020», misma cifra.

- **Revisión del código del 18-nov-2026 (parche en dos commits sobre `df34db2`), integrada en la v1.2.0** (decisión del autor, 18-nov-2026): margen de la mediana al 95 % y solo sobre el alquiler; otros gastos de vivienda con la superficie (50 % ligado a los metros); tablas de paso desde el Censo 2011 sin cruces de vías entre municipios no emparentados (`paso_cruce_municipios`); huecos forales del ADRH como `ausente`; personas distintas estimadas en las olas agrupadas de la ECV; CIS por comunidad con `peso_ccaa`; mochila con el factor de composición; las cifras del método en dos páginas desde el pipeline (`metodo_corto_cifras`); el 17 con la superficie y el plazo del Banco de España (`compraventa_esfuerzo_bde`). Al integrarlo sobre los commits locales, diez ficheros chocaban y se resolvieron a mano; `pruebas/datos/residual_muestra.json` se reescribe con `escribir_muestra_residual()`. Las decisiones del 18-nov-2026 sobre el parche y los «por revisar» de (s) y (v):
  - **Decididas por el autor (18-nov-2026):** el parche entra en la v1.2.0, en un solo commit; las personas distintas estimadas también en comunidad × grado de urbanización del 22 y en los trienios del 24 (tenencia, edad y total; `contar_distintas()`); los feeds del Catastro se renuevan solos a los 90 días (`DIAS_RENOVAR_FEEDS`, `tarchetypes::tar_cue_age()`); `olas`/`trienio` se quedan; el mapa por grado de urbanización, con países y comunidades; el total agrupado del 22, solo para la compuerta; en la tabla de comunidades de «Sobrecarga», las columnas del trienio (cifra y personas) al lado de la cifra del año.
  - **Al pasar la revisión (18-nov-2026):** el plazo medio del Banco llega en meses y la revisión lo tomaba por años (el 17 salía con hipotecas de unos 295 años): ahora se pasa a años, y España queda en 21,8 % en 2024 (con 80 m² y 25 años, 18,1 %; el Banco, 34,5 %). Un encuestado del CIS (estudio 3366, Asturias) trae `peso_ccaa` 0: queda fuera de la estimación y la compuerta admite el cero. Con la regla nueva del callejero, Tiétar (1090401001) y Pueblonuevo de Miramontes (1090501001) se quedan sin origen en las tablas desde el Censo 2011: excepciones de cobertura. El método corto pasa al 84 % de la población.
  - **Por revisar:** bajar los zips del Catastro de Talayuela, Tiétar y Pueblonuevo de Miramontes (descarga nueva) para que esas dos secciones tengan paso desde 2011; con personas distintas, 4 celdas agrupadas del 22 y 3 del 24 quedan poco fiables (20–49), todas de trienios anteriores al último; los hogares de las celdas agrupadas siguen contando hogares-ola (solo las personas pasan a distintas); la renovación de los feeds puede rehacer el Catastro si un feed cambia; la alerta `compraventa_esfuerzo_bde` avisa todos los años (el 17 queda entre un 25 y un 37 % por debajo del Banco).

## Para la v1.3

La v1.2.0 (18-nov-2026, decisión del autor) sale con el CIS por comunidad (tarea 63), «Reglas del juego» con los resúmenes provisionales (tarea 64), la línea de ingreso residual y el indicador 24 (tarea 65); lo que esta lista reservaba «para la v1.2» y no se ha hecho pasa a la siguiente.

- **Hecho (19-nov-2026), «por decidir» de la revisión de 4354766 y de las cifras de la documentación:** (a) textos del margen al 95 % en el inventario, la web y el diccionario; (b) `compraventa_esfuerzo_bde` con referencia −31 % ±10 puntos (pasa en los diez años) y la unidad «Meses» del plazo comprobada; (c) el Catastro limitado a `geo_pares_permitidos()` (`cruce_permitido()`) y `paso_cruce_municipios` sobre todas las vías, sin cambio en las tablas; (d) «ninguna» con cero cruces; (e) `cis_ccaa_peso_ccaa` (bloqueo) y `cis_ccaa_peso_cero` (alerta, una); (f) descripciones y `referencias` con tres columnas; (g) el factor de los otros gastos dicho del mínimo, `otros_gastos_minimo` en el CSV y prueba del cableado del margen; (h) `redondear_empate_arriba()` en el método corto; (i) prueba del umbral exacto. Cortes nuevos del 17 en `cortes_web_niveles.csv`; `supuestos_muestra.json` rehecho; §3.11, §7.4, §7.7, §7.10, método corto y README corregidos. Comprobado con la pasada completa del 21-nov-2026.
- Venta y otros portales.
- **Notariado, con licencia propia no comercial** (decisiones del autor, 19-nov-2026). El CIEN (notariado.org, «Estadísticas al completo»: hipotecas, préstamos, donaciones, herencias… por España, comunidad y provincia, desde 2007) se usa sin autorización: su aviso legal solo la exige para los usos comerciales, y el autor asume el riesgo de esa lectura. Las cifras del Notariado van fuera de la CC BY-SA 4.0 del resto, con «© Consejo General del Notariado, solo uso no comercial» en `LICENCIA_DATOS.md`, y solo en la web: ni tabla larga, ni descargas, ni *release*, como la capa de portales; el resto del proyecto sigue en CC BY-SA 4.0 (datos) y MIT (código). El Portal Estadístico (penotariado.com: precio de compraventa por municipio y código postal, capa ArcGIS del mapa de precios) también entra, con el mismo trato: el §4 de sus términos prohíbe incorporar los datos a bases de datos que otros puedan consultar con fines comerciales, y la licencia propia y la web sin descargas lo cumplen; el §6 prohíbe además, sin distinguir el fin, reproducirlos o ponerlos a disposición del público sin autorización expresa, y el autor asume también ese riesgo. Nunca mezclado con Registradores (indicador 11), que mide otra superficie. Falta: las dos fuentes en `inventario/fuentes.csv` (el CIEN aparte de `notariado`), qué series y cifras entran y dónde, y la descarga (CIEN: `cienServices/service/buscador/json`, POST sin registro; penotariado: FeatureServer de ArcGIS, GET; es una foto móvil de 12 meses, así que cada descarga se guarda con su fecha).
  - **Hecho (19 y 21-nov-2026):** las dos fuentes en el inventario, descarga con el calendario, compuertas e indicadores 25 a 29 en la web con la licencia, fuera del release público y de git (decisión del autor del 21-nov-2026: *release* en borrador «notariado», con `empaquetar_notariado()`; `docs/publicacion.md`, «Capa del Notariado»). Comprobado en el navegador en local: mapa con la etiqueta, CSV bloqueado y ficha con la fecha de la foto.
  - **Hecho (21-nov-2026):** *release* en borrador «notariado» creado por el autor y sitio publicado con `b7de592`, que trae la capa (CHANGELOG, «Publicado en Pages»); el plan (§5, tabla F, v0.59) y la guía (regla 6) ya la recogen.
  - **Decidido (21-nov-2026), repaso de pendientes** (`docs/especificacion_notariado.md`, «Decisiones»): se queda el umbral de 20 compraventas informadas; sin desgloses por obra nueva y usada ni por piso y unifamiliar; sin códigos postales en la ficha; sin más series del CIEN ni la mensual; las fotos se siguen guardando y la serie propia se decide cuando haya dos de fin de año (enero de 2028); numeración 25 a 29, también en el plan.
  - **Aviso de coherencia con el MIVAU · HECHO (21 y 22-nov-2026), con el precio y con el recuento.** La tarea pedía comparar las compraventas de España del Portal Estadístico con la suma de 12 meses de las transacciones del MIVAU, pero de `mivau_transacciones` el atlas tenía el valor medio de las compraventas de vivienda libre (tabla 34020150), no su número. Primero, con lo ya descargado: `comprobar_notariado_mivau()` y el objetivo `validacion_notariado_mivau` (aparte de `validacion_notariado`, para que un boletín nuevo no rehaga la capa), con dos alertas: `notariado_mivau_espana` (precio medio por compraventa de la foto frente a la media de los cuatro últimos trimestres del MIVAU cerrados antes de ella, ±15 %: +5,7 % en la foto del 21-oct-2026) y `notariado_mivau_provincias` (provincias a más de un 25 %: 0 de 52; de −6,1 % en Zamora a +13,7 % en Soria). La foto queda por encima porque el MIVAU va unos meses por detrás, con precios al alza, y cuenta solo la vivienda libre. Es una compuerta, no un indicador: no mezcla fuentes (regla 5).
  - **Contraste del número de compraventas · HECHO (22-nov-2026), con el sí del autor a la descarga:** tabla 34010110 del boletín (número total de compraventas de vivienda, 0,1 MB; `fichero_transacciones_numero`, `transacciones_numero_trim`). `notariado_mivau_compraventas`: −5,3 % en España (699.562 de la foto frente a 738.787 de 2025-T2 a 2026-T1; ±15 %). `notariado_mivau_compraventas_provincias`: 0 de 52 a más de un 25 % (de −11,8 % en Álava a +9,8 % en Navarra). Ve lo que el precio no ve: un filtro que recorte la foto sin mover su precio medio.
  - **El boletín del Ministerio cambió de dirección** (visto el 22-nov-2026 al bajar esa tabla): `apps.fomento.gob.es/BoletinOnline2/sedal/<tabla>.XLS` responde ahora con una página web y estado 200, que se habría guardado como si fuera el Excel en la renovación de diciembre del valor tasado y las transacciones. `descargar_mivau_boletin()` baja de `cdn.transportes.gob.es/estadistica/BoletinOnline2/<tabla>.xls` (la dirección que enlaza el boletín nuevo) y se detiene si lo que llega no es un Excel (`es_xls()`). Los cuatro ficheros que ya estaban pesan lo mismo que los del servidor nuevo: no se han vuelto a bajar.
- Geometría de las zonas de Idealista, si hay fuente reutilizable.
- Barrios de Idealista, si la extracción guarda el enlace de cada fila y hay más de un mes.
- Revisión jurídica de los resúmenes de «Reglas del juego» (tarea 64): hasta entonces se publican solo sus títulos.

## Decisiones del 21-nov-2026 (repaso de pendientes)

Repaso de todo lo que seguía «por decidir» o «por revisar» en este backlog, en el plan (§11) y en las especificaciones. Donde dice «con la propuesta», se queda lo que ya estaba aplicado.

- **Duración de una pasada · hecho:** §10 de la nota (las dos versiones) y `docs/reproducir.md` dicen lo que el README y la guía: unas tres horas y cuarto de cálculo, más las descargas (3 h 56 min medidos el 18-nov-2026 en una copia limpia). Fuera «tres y media con las descargas», que nadie midió.
- **Redondeo del 17 · hecho:** `compraventa_plazo_bde()` y `compraventa_superficie_registradores()` redondean con `redondear_empate_arriba()`, como el tipo (pregunta 59). No cambia ninguna cifra: de los 36 términos de 2007 a 2025, ninguno cae en un empate (el más cercano, la superficie de 2023, 96,715042); `terminos_17` sale idéntico y nada más se rehace.
- **Plan, preguntas 43 a 48 y 59:** ya decididas por el autor el 10 y el 11-nov-2026; dejan de figurar como abiertas.
- **Plan, preguntas 53, 54, 55, 56 y 58:** cerradas con la propuesta. De la 56, tres puntos estaban ya sustituidos: la banda (margen al 95 %, 18-nov-2026), la lectura de los contratos y el margen (tarea 62) y el aviso de euros corrientes (selector, regla 10 de la guía).
- **Plan, pregunta 57:** cerrada con la propuesta, salvo (g): el formato de las prórrogas de zonas tensionadas se comprueba con la primera que se publique (las primeras declaraciones vencen el 15-mar-2027).
- **Plan, pregunta 52 (Idealista):** si llega la autorización, la capa va al sitio como la del Notariado (*release* en borrador que solo baja el flujo de Pages). Sigue abierta la autorización, que pide el autor.
- **Tarea 42 (personas jurídicas):** no se baja la titularidad del Catastro: cuenta todo el parque residencial, no el alquilado, y no sirve para marcar municipios.
- **Tarea 47 y revisión del 18-nov-2026 (tablas de paso desde 2011):** no se bajan los zips del Catastro de Talayuela, Tiétar y Pueblonuevo de Miramontes: son dos secciones de unas 36.000 y quedan como excepciones de cobertura, igual que las 19 excepciones y las 2 secciones sin paso de la tarea 47. Agosto de 2023 de las viviendas turísticas sigue fuera (mezcla seccionados) y la tabla de las viviendas turísticas, con los edificios hasta 2020.
- **Revisión del 18-nov-2026, lo demás:** las 4 celdas agrupadas del 22 y las 3 del 24 con 20 a 49 personas distintas se quedan con su marca de poca fiabilidad; los hogares de las celdas agrupadas siguen contando hogares-ola; que la renovación de los feeds a los 90 días pueda rehacer el Catastro es el precio aceptado de esa decisión.
- **Tarea 63 (CIS por comunidad), (a), (b), (d) y (e):** con la propuesta: Ceuta y Melilla en ventana móvil, como los trienios de la ECV; Wilson con el efecto de diseño de Kish; el CSV, en los datos del sitio; la ficha con el año en curso y la tabla con el último año completo.
- **Tarea 64 («Reglas del juego»), lo que no es jurídico:** con la propuesta: la página sigue publicada con los títulos «en revisión»; la casilla 7, sin ancla; el plazo de convalidación de la compuerta, con sus días hábiles de lunes a viernes y 10 días de margen (es un aviso prudente, no una lectura de la norma).
- **Tareas 44 y 51:** los textos de las fichas y los cortes revisados a mano, publicados desde la v1.0, se dan por buenos.
- **Notariado:** en «Para la v1.3».

## Decisiones del 23-nov-2026

Respuestas del autor a lo que dejaron por decidir la revisión independiente desde la v1.2.0 y la lectura del sitio publicado (noche del 22 al 23-nov-2026). Letras (a)–(g): las de la revisión, en «Por decidir»; L: las de la lectura.

**Para hacer ya** (sin pasada completa) · **HECHO (23-nov-2026)**, salvo subir el paquete de la capa al *release* en borrador, que hace el autor (CHANGELOG):

- **(a) Foto del Notariado a medias:** se aplica ya el parche de `descargar_penotariado()` (capas dentro de un `tryCatch`, la foto anterior con aviso si falla a medias y el aviso de antigüedad de 120 días en la propia descarga), con sus pruebas en `test-notariado.R`. Aceptadas las cinco peticiones pequeñas a ArcGIS del siguiente `tar_make()`.
- **(c) Ventana del MIVAU:** las provincias con los mismos trimestres que España, y la alerta salta si el último trimestre de España acaba más de 270 días antes de la foto.
- **(d) Provincia «ND» en el CIEN:** esas comunidades fuera de la suma de `notariado_cien_suma_provincias`, contadas en una fila de alerta aparte.
- **(e) Cifras del Notariado en git:** se reescribe la frase en la nota (§2), `docs/publicacion.md` y la especificación: ningún fichero ni serie suya está en git; solo una decena de cifras de España, citadas con su fuente en la documentación y en las compuertas.
- **(f) Flujo de Pages:** falla si el *release* público lleva algún fichero fuera de `SHA256SUMS`, `version.json`, `datos_web.tar.gz`, `tabla_larga.parquet`, `historico.parquet` y `*.pmtiles`.
- **(g) Tabla 34010110:** ya, a `bloque_notariado`, con su propio casado de nombres (con `NOTARIADO=FALSE` no se baja).
- **L11, casilla «Notaría»:** activa con la capa encendida, hacia `mapa.html?mapa=precio_escriturado_m2`; con `NOTARIADO=FALSE`, «próximamente». La compuerta de las casillas lee también el manifiesto de la capa.
- **L15, portada y mapa:** viniendo de la portada, el resumen de «¿te llega?» abre con la cifra del alquiler real, la que da la portada.
- **L10, superficie típica:** fuera de las fichas de los indicadores 25 a 29.
- **L22:** la licencia dentro de cada JSON de la capa del Notariado (se rehace la capa y se vuelve a subir su *release* en borrador) y `datos/ejemplo/` fuera del artefacto de Pages.
- **L18, inglés:** sin espacio antes de % y un solo formato de euros («€1,237»), también en `web/js/i18n.js`; «94th percentile»; «tract» siempre para la sección censal; «Can you make rent?» también en la portada.
- **L6 (b), «Reglas del juego»:** mientras dure la revisión jurídica, cada sección enseña ya la norma y los artículos citados, con su enlace al BOE y la fecha (hechos, sin interpretación).
- **Pie de «Reglas del juego»:** «consultados entre el 13 y el 17 de noviembre de 2026» (el intervalo de las consultas).

**Con la próxima pasada completa** (cambian `inventario/` y rehacen buena parte del pipeline):

- ~~(b) `notariado_cien_espana`: tolerancia de ±1 %~~: hecho ya (23-nov-2026); solo rehacía las compuertas.
- **L13, cortes del 16:** recalibrados con 2025.
- **Comillas inglesas** en las 11 cadenas de `inventario/indicadores.csv` (10) y `fuentes.csv` (1).

## Por decidir

Lo que queda, y de quién depende:

- **Del autor:**
  - la firma de los siete resúmenes de «Reglas del juego» (`revisado` con la fecha) y, con ella, los cuatro puntos jurídicos de la tarea 64: la casilla 17 («Aval de tus padres»), el IRAV desde 2025, a qué contratos se aplican los cambios de los temas 5 y 7 y «Las comunidades que lo han establecido»;
  - la autorización de Idealista (plan §11, pregunta 52); de ella cuelgan la capa de oferta, la historia de la brecha, la venta y otros portales, y las zonas y barrios de Idealista;
  - la prueba en limpio en otra máquina (tarea 58) y la lectura externa (tarea 60);
  - el envío del aviso al MIVAU de los errores de las hojas del SERPAVI (plan §11, pregunta 13): la nota y su anexo con las 164 filas están redactados (21-nov-2026), fuera del repositorio; los envía el autor.
- **Fuentes que el calendario da por pendientes:** renovadas el 21-nov-2026 con el sí del autor (`cal_actualizar()` y `tar_make()`; `docs/actualizacion.md`). Los tipos de referencia del Banco de España ganan octubre de 2026 (tipo medio de las hipotecas, 3,236 %): cambia solo el módulo histórico, que la página no dibuja en esa serie. Las hipotecas del INE vuelven idénticas (la mensual sigue en agosto de 2026; el tipo anual de 2025 ya estaba y `ANIOS_VALOR_TASADO` no cambia hasta el de 2026, en febrero de 2027). **Siguen pendientes:** el barómetro de noviembre del CIS, que el 21-nov-2026 no estaba en su dirección habitual (404; `cis_estudios` lo vuelve a pedir en cada `tar_make()` mientras toque, y hasta entonces `tar_outdated()` lista la cadena del CIS), y los portales (manual).
- **Con fecha:** el formato de las prórrogas de zonas tensionadas, en marzo de 2027 (pregunta 57 g); la serie propia del Notariado, en enero de 2028.
- **Flujo de pruebas en GitHub (tarea 54), comprobado el 21-nov-2026** en sus registros: sin caché (ejecución del 11-nov-2026, commit `df67c1b`), 2 min 18 s, con 35 s para restaurar `renv`; con caché, unos 2 min 30 s (8 s). Los 97 paquetes de `renv.lock` se instalan compilados, ninguno desde el código fuente. Las pruebas del mapa base pasan con el GDAL 3.8.4 de Ubuntu 24.04 (92 expectativas). Las acciones de r-lib (v2.14.0, fijadas por commit) no dejan avisos ni anotaciones. Última ejecución (commit `4da0487`): 432 pruebas, 3 saltadas, 0 fallos. Los cinco avisos que quedaban dentro de las pruebas (`test-geo.R`, tres de `max()` sin datos, y `test-otros-gastos.R`, dos de redondeo) se corrigieron el 23-nov-2026 en el código, no en las pruebas (CHANGELOG); ninguna cifra cambia.
- **Revisión independiente desde la v1.2.0 (23-nov-2026), propuestas: decididas por el autor el mismo día** (abajo, «Decisiones del 23-nov-2026»; las que tocan `inventario/referencias_validacion.csv` rehacen todo el pipeline: mejor con la próxima pasada completa):
  - (a) `descargar_penotariado()`: si falla a mitad de una foto (una capa vacía o una página que no llega), se detiene aunque haya foto anterior, y `ultima_consulta.txt` ya la da por consultada; y la alerta `notariado_foto_antiguedad` solo se recalcula cuando cambia la foto o el CIEN, así que no ve un servicio parado. Propuesta, con parche probado: las capas dentro de un `tryCatch`, la foto anterior con aviso y el aviso de antigüedad en la propia descarga (120 días). Aplicarlo con la próxima foto (hacia el 21-dic-2026), cuando `ficheros_penotariado` vaya a pedir la red de todos modos;
  - (b) `notariado_cien_espana`, exacta y de bloqueo sobre 2025: si el CIEN revisa 2025, la renovación de los 30 días (hacia el 19-dic-2026) para el pipeline. Propuesta: tolerancia de ±1 % (alternativa: referencia en 2024);
  - (c) ventana del MIVAU en `comprobar_notariado_mivau()`: cada provincia toma sus cuatro últimos trimestres con cifra y no hay límite de antigüedad. Propuesta: las provincias con los trimestres de España, y la alerta salta si el último trimestre de España acaba más de 270 días antes de la foto (hoy, 204);
  - (d) `notariado_cien_suma_provincias` con una provincia «ND»: la comunidad cuenta como descuadrada y, al ser de bloqueo, pararía el pipeline (hoy no hay ninguna). Propuesta: saltar esas comunidades y contarlas en una fila de alerta;
  - (e) «ninguna cifra suya está en la historia de git» (nota §2, `docs/publicacion.md` y la especificación del Notariado) no es literal: hay una decena de cifras de España del Notariado citadas en la documentación, el inventario, las compuertas y `CIEN_REFERENCIA_ESPANA`. Propuesta: decir que ningún fichero ni serie suya está en git, solo esas cifras citadas con su fuente. Es lectura de la licencia: decide el autor;
  - (f) el flujo de Pages no comprueba que el *release* público no traiga la capa: un `notariado.tar.gz` subido ahí seguiría sin aviso. Propuesta: que falle si el *release* lleva ficheros fuera de los esperados;
  - (g) menores: la casilla «Notaría» de la portada sigue «próximamente» (la tabla de licencias del método corto, corregida el 23-nov-2026); la nota de la foto repite el umbral de 20 también en el 27, que se publica siempre; con `NOTARIADO=FALSE` se sigue bajando la tabla 34010110 (pasarla a `bloque_notariado` con la próxima pasada).
