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

**33 bis. Publicar la v0.4.0** (decisión 17). Commit de la publicación, `empaquetar_publicacion()`, release `v0.4.0` y flujo de Pages con `ref` en ese commit. **Hecho cuando:** la prueba en el navegador pasa contra el sitio publicado y la oferta sale «próximamente».

**33. Subir lo pendiente.** `main` va 9 commits por delante del remoto y hay cambios sin commit.
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

**37. Indicadores de «Entrar».**
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

**41. Indicador 14: nombre y tramos.**
- Divide el alquiler de quien alquila entre la renta de todos los hogares, y no discrimina: 18,3 % en el quintil más pobre y 17,5 % en el más rico; el 99,6 % de las secciones cae en dos de cinco tramos.
- Renombrar («alquiler mediano sobre renta media del barrio»), tramos nuevos por cuantiles de 2024 y aviso de lectura en la ficha. La ficha «llave» lleva el mismo aviso.
- **Decidido (10-nov-2026):** el indicador sale del selector del mapa y se queda en la ficha, renombrado y con el aviso. Los tramos de abajo quedan como referencia.
- **Hecho cuando:** el selector del mapa no ofrece el indicador 14 y la ficha lo muestra con su aviso.
- **Tramos calculados (10-nov-2026; 26.125 secciones con dato en 2024):**
  - con los actuales (20; 30; 40; 50): 68,0 %, 31,6 %, 0,4 %, 0 % y 0 %;
  - propuesta con cuatro cortes (15; 17; 19; 22): 27,6 %, 17,0 %, 16,3 %, 19,1 % y 20,0 %;
  - alternativa con cinco cortes (14; 16; 18; 20; 23): 19,6 %, 16,5 %, 17,0 %, 14,9 %, 17,5 % y 14,6 %.
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

**43. Ruido de las series por sección.**
- Con 10–19 contratos, el 16,6 % de las secciones cambia más de un 15 % en un año; con 100 o más, el 0,9 %.
- Gráfico de evolución con banda del margen; las variaciones de un año, solo con 30 contratos o más en los dos años, o como media de tres años.
- **Hecho cuando:** la ficha no muestra una variación anual sin su aviso en una sección con pocos contratos.

**44. Fichas comparables.**
- Pensionista: buscar la pensión mediana de jubilación; si no existe, media con aviso.
- Cada ficha dice qué estadístico usa (media, mediana, mínimo legal) y de quién (hogar, persona).
- **Hecho cuando:** el método de cada ficha, en la web, lo declara en una línea.
- **Investigado (10-nov-2026):** no aparece una pensión mediana de jubilación publicada. La Seguridad Social sí publica las pensiones por tramos de cuantía, de donde se puede interpolar una mediana (`estimado`); por provincia, a comprobar. **Decidido (10-nov-2026):** mediana estimada por tramos (`estimado`) solo si los tramos se publican por provincia; si no, la media con aviso en la ficha.
- **Comprobado (10-nov-2026):** los Excel mensuales por provincia que ya descarga el pipeline (`CA<AAAAMM>.xlsx`) traen número, importe y pensión media por régimen y clase, sin tramos de cuantía. Los tramos del anuario son nacionales, y eSTADISS no se puede automatizar. Según lo decidido, la ficha del pensionista se queda con la media y su aviso. Opción que no exige fuente nueva: añadir en la ficha la pensión media de jubilación de autónomos de la provincia como referencia baja.

**45. Series nominales y regla del 30 %.**
- Opción de ver las series en euros constantes (IPC del INE), o aviso fijo de que son nominales.
- La nota explica el límite de usar la misma proporción para todos los ingresos (enfoque de ingreso residual; Stone, 2006).
- **Hecho cuando:** el gráfico de evolución dice si está en euros corrientes o constantes.

**46. Revisión de las preguntas 43–48** (antes, tarea 32; plan §11). Sigue igual, con dos cambios:
- 43 h: dos sueldos con 70 m² se aplica también a «Entrar».
- 45 a: el indicador 11 sale de Registradores.

## Bloque D · Lo que faltaba de la v1.0

**47. Tabla de paso desde el seccionado de 2011.** Viviendas turísticas de 2020–2023 y Censo 2011 (pregunta 14). Mismas dos vías y compuertas que F1.

**48. Módulo de supuestos.** Superficie, umbral, pagas y segundo sueldo, documentados y validados en una muestra (plan, F3). Incluye la superficie típica del municipio.

**49. Primeras historias.** Dos o tres, y una de ellas, la brecha entre entrar y quedarse. Con cifras de la compuerta y enlace a su vista del mapa.

## Bloque E · Web

**50. Móvil.**
- El mapa empieza tras unos 450 px de controles, y la ficha se abre dos pantallas más abajo al tocar una sección.
- La ficha se abre sobre el mapa o la página se desplaza a ella; controles plegables; menú sin desplazamiento horizontal.
- **Hecho cuando:** a 375 px, tocar un territorio deja su ficha a la vista sin desplazarse.

**51. Lectura del mapa.**
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

**52. Portada al día.**
- Cartas con las cifras nuevas: sueldo para entrar, brecha, sueldo necesario real.
- Casillas «Zona tensionada» y «Tasación», activas: sus mapas ya existen.

**53. Transparencia.**
- «Avisar de un error» y fe de erratas en la web.
- Fecha de los datos, visible en el mapa.
- «Método en dos páginas» (ES y EN), enlazado desde la ficha: qué mide cada familia y a quién deja fuera.
- **Avance (10-nov-2026):** borrador en castellano, `docs/metodo_corto.md`. Falta la versión inglesa, enlazarlo desde la web y la fe de erratas.

## Bloque F · Ingeniería

**54. Pruebas en cada push.** Flujo de GitHub con las pruebas que no necesitan datos (inventario, utilidades, web con la muestra). El de publicación sigue manual.

**55. Avisos del pipeline (93).**
- 56 de geometría sobre coordenadas geográficas: proyectar antes de calcular el punto interior.
- 6 «NA introducidos por coerción» en el módulo de salarios que alimenta la mochila: explicarlos o corregirlos.
- **Hecho cuando:** cada aviso que quede está justificado en `docs/actualizacion.md`.

**56. Limpieza.**
- Fichero `0` de la raíz, fuera de git.
- Textos que aún dicen que el Notariado «no se puede reutilizar».
- La guía y el README apuntan a este backlog.

**57. Licencias.** Tabla única en la nota (§2): qué fuente, qué licencia, qué obliga. Señala los tres catastros con licencias contradictorias, la ODbL de Registradores, las geometrías europeas de uso no comercial e Idealista (solo web). Plan de retirada por fuente.
- **Avance (10-nov-2026):** tabla resumida en `docs/metodo_corto.md`. Falta Registradores (tarea 46) y el plan de retirada por fuente.

**58. Reproducir en limpio.** Ejecutar el pipeline en otra máquina, desde `renv::restore()`, con la lista de descargas manuales. Anotar lo que falle.

## Bloque G · Verificación y v1.0

**59. Rederivar a mano** diez cifras de F4–F6 y cinco de «Entrar», desde los ficheros de la fuente.

**60. Lectura externa.** Una persona que no haya participado revisa la nota corta y el mapa antes de anunciar. El autor decide quién.

**61. *Release* v1.0.** Paquete con el histórico, prueba de navegador contra el sitio publicado, CHANGELOG `[1.0.0]`, descongelar el sitio.

## Orden

33 → 34 → 35 y 36 (en paralelo) → 37 → 38 y 39 → 40 a 45 → 46 → 50 a 53 → 47 a 49 → 54 a 58 → 59 a 61.

Los bloques B y C van antes que la web porque cambian las cifras que la web enseña.

## Para la v1.1

- Venta y otros portales.
- Microdatos del CIS por comunidad.
- Línea de ingreso residual.
- Autorización del Notariado, si llega.
- Geometría de las zonas de Idealista, si hay fuente reutilizable.
- Barrios de Idealista, si la extracción guarda el enlace de cada fila y hay más de un mes.

## Por decidir

- Nada pendiente a 10-nov-2026.
