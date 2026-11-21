# Especificación · el Notariado con licencia propia no comercial, solo en la web

*Para la v1.3 (19-nov-2026). Encargo: backlog, «Para la v1.3», «Notariado, con licencia propia no comercial»; plan v0.57. Provisional, como todo el plan.*

**Estado: implementada la opción recomendada en cada punto (19-nov-2026); las alternativas quedan como preguntas para el autor al final.** Fuentes en `inventario/fuentes.csv` (`notariado` y `notariado_cien`), código en `R/fuente_notariado.R` y `R/web_notariado.R`, objetivos en `bloque_notariado` de `_targets.R`, compuertas `notariado_*`, `notariado_cien_*` y `web_notariado`, web en `web/datos/notariado/` y `web/js/notariado.js`, nota metodológica §7.11.

## Decisiones del autor (19-nov-2026)

- Entran el **CIEN** (notariado.org, «Estadísticas al completo»: series de actos notariales por España, comunidad y provincia desde 2007; su aviso legal solo exige autorización para los usos comerciales) y el **Portal Estadístico** (penotariado.com: compraventa de vivienda por municipio y código postal, foto móvil de 12 meses; el autor asume el riesgo del §6 de sus términos).
- Sus cifras van con **licencia propia no comercial** («© Consejo General del Notariado, solo uso no comercial») y **solo en la web**: ni tabla larga, ni descargas CSV, ni paquete del *release* (`datos_web.tar.gz`, `tabla_larga.parquet`, `historico.parquet`). El §4 de los términos de penotariado prohíbe incorporar sus datos a bases de datos que otros puedan consultar individualmente con fines comerciales: el diseño no los ofrece como base de datos descargable.
- **Nunca se mezclan con Registradores** (indicador 11), que mide otra superficie.
- El resto del proyecto sigue en CC BY-SA 4.0 (datos) y MIT (código).

## Qué ofrecen las fuentes (comprobado el 19-nov-2026)

**Portal Estadístico.** El mapa de precios de penotariado.com lee un servicio ArcGIS público (`PENOTARIADO_URL`), con cinco capas: España (0), comunidad (1), provincia (2), municipio (3) y código postal (4). Una fila por territorio, tipo de construcción (todas, nueva, usada) y clase de finca (todas, piso, unifamiliar), con precio por m², precio medio, superficie media, número de compraventas y compraventas con precio y superficie informados, y una marca de valor estimado. Sin serie: es la foto de los 12 meses anteriores, con la fecha de la última edición de la capa (21-oct-2026 en la consulta). Códigos del INE como texto (comunidad, provincia y municipio). Filas de todas las viviendas en la foto del 21-oct-2026: 1 España, 19 comunidades, 52 provincias, 8.124 municipios y 10.830 códigos postales. España: 2.031,47 €/m², 227.374 € de precio medio, 111,9 m² y 699.562 compraventas (614.604 informadas). El precio por m² × la superficie media da el precio medio en todas las filas con 20 o más informadas. La serie y los informes, con registro: no se usan.

**CIEN.** Un buscador con POST de formulario, sin sesión, que responde JSON en ISO-8859-1. 364 series de actos (hipotecas, préstamos, donaciones, herencias, arrendamientos, sociedades, poderes…), casi todas solo nacionales; con provincia, pocas: la hipoteca inmobiliaria (y su subcategoría de adquisición de vivienda), los préstamos hipotecarios, cancelaciones, subrogaciones, donaciones, herencias, declaraciones de herederos, segregaciones, testamentos, poderes y pólizas. Ningún municipio. Los territorios llegan por nombre; Ceuta y Melilla, juntas como una provincia y dentro de Andalucía. Fecha de autorización (firma), no de inscripción. Hipotecas para compra de vivienda, España, 2025: 385.194, con una cuantía media de 174.956 €; el 19-nov-2026 llegaba a mayo de 2026. La compraventa de vivienda no está en el CIEN.

**CORS.** El servicio ArcGIS responde con `Access-Control-Allow-Origin: *`: el navegador puede consultarlo directamente. El del CIEN no manda cabeceras CORS: el navegador no puede leer sus respuestas desde otro sitio.

## Qué entra y dónde

**Recomendada (implementada):** cinco indicadores numerados, aparte de los del plan, con mapa propio y ficha:

| N.º | Código | Fuente | Niveles | Periodo | Mapa |
|---|---|---|---|---|---|
| 25 | `precio_escriturado_m2` | `notariado` | municipio, provincia, comunidad, España | foto de 12 meses | municipal, cortes 600, 900, 1.200, 1.700 y 2.500 €/m² |
| 26 | `precio_escriturado_vivienda` | `notariado` | ídem | ídem | municipal, cortes 70.000 a 300.000 € |
| 27 | `compraventas_notariado` | `notariado` | ídem | ídem | municipal, cortes 5, 20, 50, 200 y 1.000 |
| 28 | `hipotecas_compra_vivienda` | `notariado_cien` | provincia, comunidad, España | 2007–último año completo | provincial, cortes 1.000 a 20.000 |
| 29 | `cuantia_hipoteca_vivienda` | `notariado_cien` | ídem | ídem | provincial, cortes 100.000 a 200.000 € |

- De penotariado entran todas las viviendas (nuevas y usadas, pisos y unifamiliares juntos), en el año de la foto (2026). La superficie media no va aparte: es el 26 entre el 25. El año de la foto es la etiqueta del periodo; la ficha dice la fecha exacta y que son los 12 meses anteriores.
- Del CIEN, los años con los doce meses de España publicados (2007–2025): el año en curso no entra hasta que se completa. La serie anual se pide al CIEN como anual (cifra publicada, regla 1); la mensual de España sirve para el último mes y para la compuerta de los meses.
- Andalucía (01): el CIEN la da con Ceuta y Melilla, así que la del atlas es la suma de sus ocho provincias (número) y su media ponderada por las hipotecas con cuantía informada (cuantía), las dos `dato`: la compuerta comprueba que esa ponderación reproduce la media publicada de cada comunidad (diferencia por debajo de 0,00001 % en todos los años). Ceuta y Melilla (provincias 51 y 52, comunidades 18 y 19) quedan sin dato.
- La ficha de municipio, provincia y comunidad enseña la cifra, la lectura del indicador (que dice la licencia y que no se compara con el 11) y, en los de penotariado, la fecha de la foto y el umbral.

**Alternativas:**
- (a) Un solo indicador de compraventa con grupos (precio por m², precio medio, número), como los portales (`oferta_privada`). Descartada: cada grupo tiene su unidad, y la leyenda y la ficha toman la unidad del indicador.
- (b) Desgloses de penotariado por tipo de construcción y clase de finca (nueva/usada, piso/unifamiliar) como corte. Por revisar: con 20 informadas como mínimo, el municipio se queda casi vacío; tendría sentido en provincia y comunidad.
- (c) Código postal: la capa existe y se guarda en cada foto, pero el atlas no tiene geometría de códigos postales; la tabla `geo/codigos_postales_2021.csv` permitiría listarlos en la ficha del municipio. Por revisar.
- (d) Más series del CIEN con provincia (préstamos hipotecarios en total, cancelaciones, donaciones, herencias). Por revisar: las hipotecas para comprar vivienda son las que hablan del acceso; las demás, de patrimonio.
- (e) Serie mensual del CIEN en la evolución de la ficha. Por revisar: la ficha de hoy trabaja con años.

## Umbral de fiabilidad

**Recomendado (implementado):** sin precio (estado `secreto`) con menos de 20 compraventas con precio y superficie informados en los 12 meses (`NOTARIADO_MIN_INFORMADAS`). El número de compraventas se publica siempre. Las filas que la fuente marca como estimadas, `estimado` (ninguna en la foto del 21-oct-2026). En la foto del 21-oct-2026, 2.475 de los 7.451 municipios con compraventas tienen precio. Del CIEN, sin umbral: el propio CIEN oculta el número con muy pocos actos («ND»), que pasa a `secreto`.

**Alternativas:** 10 informadas (como el mínimo del SERPAVI), con «pocas compraventas» marcado por debajo de 30, como la ficha del alquiler; o 50. Por revisar.

## Cómo llegan las cifras al sitio

El sitio se monta con `web/` tal como está en git y los ficheros del *release* (`.github/workflows/pages.yml`). Las cifras del Notariado no pueden ir en el *release*.

| Opción | Cómo | A favor | En contra |
|---|---|---|---|
| A. Consulta directa desde el navegador | La web pide al servicio ArcGIS las cifras del territorio que se mira | Nada se copia ni se guarda; siempre la última foto | Solo vale para penotariado: el CIEN no tiene CORS. Sin compuertas (regla 3), con el umbral en JavaScript, y el sitio depende de un servicio ajeno que ha cambiado de campos alguna vez; cada visita consulta al Notariado |
| B. Montaje en el flujo de Pages | El flujo consulta las dos fuentes en cada publicación y escribe `datos/notariado/` | Nada en git ni en el *release* | Repite en el flujo (sin R) la lectura, el umbral y las compuertas del pipeline: lo publicado no sería lo validado en local; cada publicación depende de que los dos servicios respondan |
| C. Ficheros en git (implementada el 19-nov-2026; descartada por el autor el 21-nov-2026) | El pipeline escribe `web/datos/notariado/` tras sus compuertas y la carpeta va en git (excepción en `.gitignore`); el flujo la copia con `web/` | Lo publicado es exactamente lo validado (`validacion_notariado`, `validacion_web_notariado`), en el commit publicado; el flujo apenas cambia; 127 ficheros, unos 170 KB | Las cifras quedan en la historia de un repositorio público, que se puede clonar entero: retirarlas del todo exige reescribir la historia. Cada foto nueva añade su diferencia a git |
| **D. Fichero aparte en un *release* en borrador (elegida por el autor, 21-nov-2026; implementada)** | Como la propuesta para los portales: un `.tar.gz` que baja un trabajo con permiso de escritura | Fuera de git y del *release* público | Un trabajo más con `contents: write`; los artefactos de un repositorio público se pueden bajar mientras duran; más piezas que mantener |

Decisión del autor (21-nov-2026): D, para que las cifras no estén en el repositorio público ni en su historia. `empaquetar_notariado()` (`R/publicar.R`) empaqueta `web/datos/notariado/` (fuera de git) en `publicacion_notariado/notariado.tar.gz` con su `SHA256SUMS`, solo con la capa encendida y su compuerta sin fallos; el autor lo sube al *release* en borrador «notariado», que solo ven quienes pueden escribir en el repositorio y que nunca se publica; el flujo de Pages lo baja (`contents: write` en el trabajo de montaje, solo para ver el borrador), comprueba la suma y que solo trae `datos/notariado/`, y lo monta; sin el borrador, deja la capa apagada. El sitio sirve las cifras al navegador igual que con cualquier otra opción, y el artefacto de Pages de cada publicación las lleva, como el sitio. No se ofrecen como descarga ni van en ningún paquete de datos, y llevan la licencia propia (`LICENCIA_DATOS.md`; `licencia` en su manifiesto). `empaquetar_publicacion()` comprueba que nada del Notariado entra en el paquete público (`sin_notariado`) y el flujo rechaza un `datos_web.tar.gz` con `datos/notariado/`.

## Compuertas (`inventario/referencias_validacion.csv`)

Resultado en el pipeline, 19-nov-2026 (foto del 21-oct-2026; CIEN hasta mayo de 2026):

| `id` | Qué comprueba | Tipo | Resultado |
|---|---|---|---|
| `notariado_niveles` | 1 España, 19 comunidades y 52 provincias; municipios y códigos postales con filas | bloqueo | 0 |
| `notariado_codigos` | Códigos repetidos; comunidades y provincias fuera del seccionado de 2021 | bloqueo | 0 |
| `notariado_municipios` | Municipios fuera del seccionado de 2021 | alerta | 0 de 8.124 |
| `notariado_suma` | Compraventas: comunidades frente a España y provincias frente a su comunidad, ±0,1 % | bloqueo | 0,007 % (699.510 frente a 699.562) y 0 |
| `notariado_suma_municipios` | Municipios nunca por encima de su provincia (±0,1 %) | bloqueo | 0 |
| `notariado_identidad` | Precio por m² × superficie = precio medio (±1 %), con 20 o más informadas | bloqueo | 0 |
| `notariado_rango` | Precios publicables fuera de 50–20.000 €/m²; informadas por encima del total | bloqueo | 0 |
| `notariado_foto` | Días entre las fechas de datos de las cinco capas (±2) | bloqueo | 0 |
| `notariado_foto_antiguedad` | Días desde la foto (±120) | alerta | 29 |
| `notariado_mivau_espana` | Precio medio por compraventa de España frente al valor medio del MIVAU de los cuatro últimos trimestres cerrados antes de la foto (±15 %) | alerta | +5,7 % (227.374 € frente a 215.115 €, de 2025-T2 a 2026-T1) |
| `notariado_mivau_provincias` | Provincias con precio publicable a más de un 25 % del valor medio del MIVAU | alerta | 0 de 52 (de −6,1 a +13,7 %) |
| `notariado_cien_territorios` | Nombres sin correspondencia y filas repetidas | bloqueo | 0 |
| `notariado_cien_suma_ccaa` | Por año, comunidades = España | bloqueo | 0 en 2007–2026 |
| `notariado_cien_suma_provincias` | Por año, provincias = comunidad (Ceuta y Melilla dentro de Andalucía) | bloqueo | 0 en 2007–2026 |
| `notariado_cien_meses` | Por año completo, meses de España = año | bloqueo | 0 en 2007–2025 |
| `notariado_cien_espana` | España, 2025: 385.194 | bloqueo | 385.194 |
| `notariado_cien_cuantia` | Cuantía de cada comunidad = media de sus provincias ponderada (±0,01 %) | bloqueo | < 0,00001 % |
| `notariado_cien_rango` | Cuantías fuera de 20.000–1.000.000 €; números negativos | bloqueo | 0 |
| `web_notariado` | Ida y vuelta de `web/datos/notariado/`, licencia en el manifiesto, ficheros de más y series en el manifiesto general | bloqueo | 0 |

Coherencia entre fuentes: penotariado no tiene serie con que contrastar el CIEN, y el Notariado no se compara con Registradores (regla 5). Desde el 21-nov-2026, dos alertas (`comprobar_notariado_mivau()`, objetivo `validacion_notariado_mivau`) comparan el precio medio por compraventa de la foto con el valor medio de las compraventas de vivienda libre del MIVAU (`mivau_transacciones`, tabla 34020150), que sale de las mismas escrituras. Las dos cifras no miden lo mismo: la foto son 12 meses móviles de todas las viviendas, y el MIVAU va unos meses por detrás y cuenta la vivienda libre; con precios al alza, la foto queda por encima (+5,7 % en España). Los márgenes (±15 % en España, 25 % por provincia) dejan pasar ese desfase y avisan de un error de nivel: unidades, o una foto de otra clase de fincas. El número de compraventas no se contrasta: el atlas no baja el del MIVAU (sería otra tabla del boletín, una descarga nueva que decide el autor).

## Licencia y atribución en la web

**Recomendada (implementada):** la etiqueta de la fuente, «© Consejo General del Notariado, solo uso no comercial» (`vocabulario.etiqueta.notariado` y `.notariado_cien`, desde `inventario/vocabulario.csv`), con el mismo mecanismo que el «dato privado de oferta» de los portales: sobre el mapa, en la leyenda, en la ficha y en el PNG; el CSV no se ofrece y la barra lo explica con su propio aviso. La lectura de cada indicador repite la licencia, y la ficha de penotariado cita la fecha de la foto («Compraventas escrituradas en los 12 meses anteriores a la foto del Portal Estadístico del Notariado del 21 de octubre de 2026»). Además: `LICENCIA_DATOS.md`, la nota metodológica (§2.2, §2.3, §2.4 y §7.11) y `version.json` (`licencia.excepciones.notariado`: no va en el paquete).

**Alternativa:** un enlace a la fuente en la etiqueta (como el informe de cada cifra de los portales). Por revisar: el §6 de penotariado no lo pide, y su aviso legal pide citar la procedencia.

## Plan de retirada

Se borra el *release* en borrador «notariado» (`gh release delete notariado`) y se vuelve a publicar con el flujo, que sin él deja el sitio sin la capa. `NOTARIADO=FALSE` antes de `targets::tar_make()` (o quitar el bloque de `_targets.R`) deja `web/datos/notariado/` con solo `{"capa":"notariado","activa":false}` y no consulta nada. Ninguna cifra está en la historia de git. Las fotos de `datos/brutos/notariado/` y las consultas de `datos/brutos/notariado_cien/` (fuera de git) se borran. Los indicadores 25 a 29 pueden quedarse en el inventario sin datos, o salir de él con sus textos.

## Decisiones (eran las preguntas «por revisar»)

1. ¿Ficheros en git (C) o montaje en el flujo (B)? Decidida por el autor (21-nov-2026): *release* en borrador (D).

Las demás, cerradas en el repaso de pendientes del 21-nov-2026. El criterio común: los términos del Portal Estadístico prohíben poner sus datos a disposición del público sin autorización, y ese riesgo, que el autor asume, crece con cada cifra que se copia y con lo fina que sea; se publica lo que responde a la pregunta del atlas y nada más.

2. **Umbral: 20 compraventas informadas.** El precio es una media, no una mediana, y la fuente no da su dispersión: no se puede acompañar de un margen, como el alquiler del SERPAVI (que por eso admite 10 testigos con su aviso). Con 20 tienen precio 2.475 de los 7.451 municipios con compraventas.
3. **Sin desgloses** por obra nueva y usada ni por piso y unifamiliar: multiplican las cifras copiadas, y la pregunta del atlas es el acceso, no el producto.
4. **Sin códigos postales** en la ficha del municipio: es la escala más fina de la fuente, sin geometría en el atlas, y con el umbral de 20 quedaría casi vacía.
5. **Sin más series del CIEN ni la mensual:** las hipotecas para comprar vivienda son las que hablan del acceso, y la ficha trabaja con años.
6. **Las fotos se siguen guardando** (fuera de git, con su fecha), y la serie propia no se publica todavía: con una sola foto no hay serie. Se decide cuando haya dos fotos de fin de año (enero de 2028); hasta entonces, la web enseña la última.
7. **Numeración 25 a 29,** también en el plan (§5, tabla F): ya están así en el inventario, las pruebas, la web y el registro de cambios.
8. **Aviso de coherencia con las transacciones del MIVAU: sí, como `alerta`.** Las transacciones del MIVAU salen de los mismos ficheros notariales, así que vería un error de nivel en toda la foto, que las sumas internas no ven. Es una compuerta, no un indicador: no mezcla fuentes (regla 5). Hecho el 21-nov-2026 con el precio medio, no con el número de compraventas que proponía esta decisión: de `mivau_transacciones` el atlas tiene el valor medio y no el recuento («Compuertas», arriba).

La etiqueta de la licencia se queda sin enlace a la fuente (alternativa de «Licencia y atribución en la web»): la procedencia ya se cita en la etiqueta, la ficha y la nota.

## Hecho cuando

- Las dos fuentes en el inventario, con su licencia; `tar_make()` las baja, pasa las compuertas `notariado_*`, `notariado_cien_*` y `web_notariado` y escribe `web/datos/notariado/`. **Hecho (19-nov-2026).**
- La web enseña los mapas 25 a 29 con la etiqueta de la licencia y sin CSV, y la ficha cita la foto. **Hecho (21-nov-2026): comprobado en el navegador, en local y contra el sitio publicado.**
- `empaquetar_publicacion()` deja fuera todo lo del Notariado (`sin_notariado`) y el flujo de Pages monta la carpeta desde el *release* en borrador «notariado» (21-nov-2026). **Hecho y publicado (21-nov-2026, con `b7de592`).**
- Nota metodológica (§7.11 y las filas de licencias de §2.2 y §2.4) y `LICENCIA_DATOS.md`. **Hecho.**
