# Web

Web estática de *De renta en renta* (plan, §6.6): MapLibre con PMTiles para las secciones, sin servidor ni analítica, castellano e inglés, estado de la vista en la URL y publicación en GitHub Pages.

**Pila (decisión del autor, 8-nov-2026): HTML y módulos JavaScript nativos, sin compilar.** No hay npm ni paso de compilación: el código que se edita es el que corre. Las librerías están copiadas en `vendor/` con versión fijada. El código importa `maplibre-gl` por su nombre gracias al *import map* de `mapa.html` y `sobrecarga.html`, así que, si algún día hiciera falta, se podría pasar a un empaquetador (Vite) sin reescribir los módulos.

## Verla en local

Desde la raíz del proyecto:

```bash
node web/servir.mjs
```

y abrir <http://localhost:8000/> (la portada; el mapa está en `mapa.html`). Para parar: Ctrl+C. Si el puerto está ocupado, se puede usar otro: `node web/servir.mjs 8080`.

- `servir.mjs` es un servidor propio, sin paquetes (Node 18 o posterior). Solo escucha en el propio equipo.
- Hace falta porque el PMTiles se lee por trozos (rangos HTTP) y `python -m http.server` no los atiende.
- Abrir `index.html` con doble clic no funciona: el navegador no deja cargar módulos ni datos desde `file://`.

Con la exportación del pipeline (`datos/manifiesto.json` y `teselas/seccionado_2021.pmtiles`), la web muestra toda España. Sin ella, carga la **muestra** de `datos/ejemplo/`: las 111 secciones de 2021 del distrito Centro de Madrid, con valores **inventados** y la etiqueta «Datos de ejemplo» siempre visible (guía, regla 9). La muestra tiene cuatro mapas (uno con periodos por meses) y la variante de vivienda unifamiliar de los alquileres, para probar los selectores.

## Qué hace

- **Portada** (`index.html`; `docs/especificacion_portada.md`, `docs/backlog_f0.md`, tarea 24): el tablero de la identidad.
  - **Rutas.** La raíz es la portada y el mapa está en `mapa.html`. Hasta la portada, la raíz era el mapa: `js/redireccion.js`, un script clásico y síncrono en el `<head>`, manda a `mapa.html` (con la misma consulta y el mismo fragmento, antes de pintar) los enlaces ya compartidos que traen alguna clave del estado de la vista salvo el idioma, un sueldo tras «#» o el ancla `#tu-sueldo`. `?idioma=en` solo se queda en la portada, en inglés. En todos los menús, «Mapa» va a `mapa.html`, «Tu sueldo» a `mapa.html#tu-sueldo` y el título del sitio a la portada (también en la plantilla de «Método» y «Datos»).
  - **Centro:** título, subtítulo, gancho (`sitio.gancho`), pregunta rectora (`sitio.lema`) y familias (`sitio.familias`), con su lectura literal (`js/familias.js`, con los mismos textos que la leyenda: «Quedarse · quien ya vive de alquiler» y «Entrar · quien busca piso hoy»); el dicho (`sitio.dicho`, «De renta en renta, y pago porque me toca») va al pie (tarea 34). Ojo con los nombres: `lema` es la pregunta y `dicho`, el lema; las claves no se renombran. «Tu sueldo»: el sueldo neto al mes y «¿Te llega?», que abre `mapa.html?ficha=peon` con el sueldo tras «#» (como «Compartir»; el mapa lo lee y lo quita de la barra). Sin JavaScript, el formulario lleva a «Tu sueldo» del mapa sin el sueldo (el campo no tiene `name`). Buscador (un municipio abre el mapa con su ficha, `territorio=municipio:…`; una sección, con la suya) y «Tira el dado»: una sección al azar con `dato` en el último año del alquiler por m² (sin giro con `prefers-reduced-motion`).
  - **Fichas** («¿para quién?»): las cinco, con los iconos de `diseno/fichas/` (copiados en `estilo/fichas/`; una prueba de R los compara), cada una al mapa con su ficha en «¿te llega?» y con una línea que dice qué estadístico usa (media, mediana o mínimo legal) y de quién (hogar o persona; tarea 44). Una ficha sin ingreso en `perfiles.json` sale desactivada y rotulada «próximamente».
  - **Casillas:** 24 (7 × 7: cuatro esquinas y cinco por lado), una lista ordenada colocada con CSS en el borde del tablero, en el sentido de las agujas del reloj desde la esquina de arriba a la izquierda. Salen de `inventario/casillas_portada.csv` (regla 7: textos en los dos idiomas, familia, destino, destino en inglés si cambia el ancla, activa): `escribir_casillas_portada()` (R, objetivo `fichero_portada_html`) las escribe en `index.html` entre sus marcas, con `data-texto-es`/`data-texto-en` y `data-href-es`/`data-href-en` para el idioma. Activas solo donde hay datos o página; las demás, sin enlace y «próximamente». Bandas por familia (ingresos, alquiler, compra y barrio) con colores de `tokens.css` de al menos 3:1 sobre la crema; las inactivas, rayadas. Nada propio de Monopoly.
  - **Cartas:** tres cifras reales del pipeline, de `datos/portada.json` (`exportar_portada()`, compuerta `portada_valores`): sueldo necesario de la sección mediana con el alquiler mensual real y sus percentiles 10 y 90, y al lado el mínimo de 50 m²; secciones donde el piso de 50 m² pasa del 30 y del 40 % del salario mínimo neto y, al lado, donde lo pasa el alquiler mensual real (decisión 4, tarea 40); sobrecarga de quienes viven de alquiler a precio de mercado y del total. Si falta un término (también la cifra de al lado), la carta no sale. Sin el fichero (o con la muestra), no hay cartas.
  - **Pie:** fuentes y fecha de los datos de `descargas/version.json` (o del manifiesto), licencias y repositorio.
  - Escritorio: tablero cuadrado de hasta 720 px con el centro encima y una columna con las fichas y las cartas; de 700 a 1.159 px, en una columna (hasta el 10-nov-2026, 1.039 px: con el gancho y las familias, el centro no cabía en un tablero más estrecho); en el móvil, el centro, las fichas, las cartas y las casillas como recorrido vertical. Sin JavaScript se ven el tablero y los enlaces.
- **Barra de la vista**, encima del mapa:
  - **mapa**: los de `mapas` del manifiesto; por defecto, el sueldo necesario, y los demás con la fórmula `directo`. El indicador 14 no tiene mapa (sin `cortes_web`; decisión 10, tarea 41): está en la ficha. En «¿te llega?», la primera opción es «¿Te llega? · ficha»; elegir otro mapa sale de ese modo;
  - **año**: los periodos de la serie que da color (los meses, escritos: «mayo de 2026»). Sin año elegido, el último de cada serie; con uno elegido, cada serie usa ese o el último anterior y, si el año es anterior a toda la serie, sin dato y un aviso con el inicio de la serie («2020 (sin datos)» en la barra);
  - **vivienda**: colectiva o unifamiliar, solo si la serie del mapa tiene variante (`variantes` en el manifiesto). Colectiva por defecto y nunca mezcladas (decisión 12). Cambia el mapa, la leyenda, la ficha, su evolución y el comparador; en «¿te llega?», el alquiler que se usa;
  - **descargar**: los datos del mapa en CSV y su imagen en PNG (ver abajo).
  - Todo se maneja con el teclado (los dos primeros son `<select>` nativos, que en el móvil abren el selector del sistema) y queda en la URL.
  - Si la serie no llega al nivel que se ve (una serie solo por sección con el mapa de España), un aviso pide acercar el mapa.
- **Descargas**, sin dependencias y sin el sueldo escrito (como «Compartir»):
  - **CSV** de la serie del mapa en el nivel que se ve (comunidad, provincia, municipio o sección; si la serie no llega a ese nivel, el más fino que tenga), con una fila por territorio y las columnas código, nombre, nivel, indicador, tipología, periodo, valor (con la precisión de la serie: una décima; dos en las viviendas turísticas), unidad, estado y fuente; en las series del alquiler (y las que salen de él), los contratos de la mediana y su margen aproximado (`contratos`, `margen_pct`); en el sueldo necesario, también la superficie y el umbral y, al lado de la cifra principal, el mínimo teórico con esa superficie (`valor_minimo`; tarea 40). UTF-8 con BOM, coma entre campos y punto decimal. En «¿te llega?» lleva el alquiler que usa el mapa y no la proporción, de la que se despejaría el sueldo;
  - **PNG** del mapa tal como se ve, con título, periodo, tipología, leyenda, claves de los huecos, fuente y fecha de los datos. Con «Tu ficha», el ingreso se nombra («el sueldo escrito») sin la cifra, y antes de descargar la imagen sale un aviso como el de «Compartir» (sus colores dejan deducir el sueldo), que se puede cancelar.
  - El nombre del fichero lleva el mapa, la tipología si es la unifamiliar, el periodo y, en el CSV, el nivel: `de-renta-en-renta_sueldo_necesario_2024_municipio.csv`.
- **Mapa por defecto: sueldo neto necesario** (indicador 21) para que el alquiler mensual mediano de la sección no pase del 30 % del sueldo (decisión 4, tarea 40; por revisar). Hay seis tramos con los cortes del manifiesto (1.000 · 1.300 · 1.600 · 2.000 · 2.600 €), uno por paso de la rampa. Se pinta con el alquiler mensual mediano (indicador 8) y la fórmula `alquiler_mes_a_sueldo` de `js/formulas.js`; umbral del 30 o del 40 %. Al lado, en la ficha y en el CSV, el mínimo teórico con un piso de 50, 70 o 90 m² (`minimo` del mapa en el manifiesto: el alquiler por m², indicador 9, con `alquiler_m2_a_sueldo`); la superficie elegida solo cambia esa cifra, y la leyenda y la tarjeta «Tu sueldo» lo dicen. Ninguna pantalla da el mínimo de 50 m² sin la cifra con el alquiler real al lado.
  - En la regla de la leyenda, las fichas de una persona aparecen como marcas en su ingreso: la mochila, con la provincia de la sección elegida o la mediana de las provincias, y la tartera. La llave aparece como un tramo, del cuartil 1 al 3 de la renta de los hogares ÷ 12.
- **«¿Te llega?»** al escribir un sueldo (neto al mes, 12 o 14 pagas, segundo sueldo opcional) o al elegir una ficha. Muestra el alquiler sobre el ingreso en tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %) y la frase «te cabe en el X % de las secciones con dato».
  - Cada ficha tiene su vivienda (plan, §3.1):
    - las de una persona, 50 m² (regla 8): el mapa se pinta así y, al lado, la ficha y la tarjeta dan la misma cuenta con el alquiler mensual mediano real de la sección (tarea 40; `serieReal` y `resumenLlegaReal()` de `js/sueldo.js`);
    - la llave, el alquiler mensual mediano de su sección frente a la renta de sus hogares ÷ 12: el mismo cociente que el indicador 14, con su aviso de lectura (tarea 41);
    - «Tu ficha», 50 m² con un sueldo y 70 con dos, cambiable a 50, 70, 90 m² o «típica» (`superficie=tipica`): la superficie típica de los pisos alquilados (alquiler mensual mediano / alquiler por m² mediano) del territorio que manda, que es el municipio de la sección de la ficha, el territorio elegido o, sin ficha, el municipio del centro de la vista (decisión del autor, 11-nov-2026). La ficha de municipio la da en una línea.
  - Cada ficha dice en una línea qué estadístico usa y de quién (`fichas_metodo` de i18n; tarea 44), en su ficha y en la tarjeta «Tu sueldo»: la llave, la media del hogar; la mochila, la mediana de una persona; la tartera, el mínimo legal; el transistor, la media de una persona, con el aviso de que no se publica la mediana por provincia; «Tu ficha», la cifra escrita.
  - Si el ingreso de la ficha no es del mismo año que el alquiler (la tartera es el SMI del año en curso), se avisa (regla 4).
  - El estado de la cifra es el del alquiler; si la ficha no tiene ingreso en la sección (la mochila en los territorios forales, Ceuta y Melilla), «sin dato» (pregunta 15 ampliada).
  - Si el margen aproximado de la mediana deja la proporción a los dos lados del 30 o del 40 %, la ficha dice que está «en el límite entre dos tramos».
- **Cálculo en el navegador**, sin descargar nada más: los valores van en el estado de cada elemento del mapa (*feature-state*) y el color sale de expresiones de estilo (`js/sueldo.js`).
  - Con poco zoom, donde el PMTiles aún no trae secciones, se pintan los municipios (zoom 5–7: toda España en una pantalla de escritorio), las provincias (4–5) y, alejando más, las comunidades (menos de 4; en el móvil, toda España), cada nivel solo en su franja y con las cifras publicadas en él (tarea 26). En una comunidad, las fichas con ingreso por provincia (mochila y transistor) quedan sin dato: no tienen uno solo para toda la comunidad.
  - **Con ratón**, una etiqueta sigue al cursor con los nombres del territorio (tarea 25): en las secciones, el municipio, el distrito (su número: el INE no publica nombres de distrito) y el código; en los municipios y las provincias, su nombre y el del territorio superior; en las comunidades, su nombre; en el suelo sin sección, qué es. Son los de `territorios.json`, como en la ficha. En pantallas táctiles no hay etiqueta: la ficha hace ese papel.
  - **Pulsar** un municipio, una provincia o una comunidad abre su ficha (abajo); queda en la URL (`territorio=municipio:28079`). Con poco zoom, el suelo sin sección que una provincia o una comunidad incluye abre la suya.
  - El suelo que no es de ninguna sección (terrenos comunales fuera de todo municipio) se pinta como «sin dato» en todos los zooms; al pulsarlo, la ficha dice qué es y, donde el IGN dibuja una unidad (condominios), su nombre y su tipo, con la fuente.
- **El sueldo no sale del dispositivo.** No entra en la URL ni se guarda. Solo va en un enlace si se pulsa «Compartir» y se elige «Copiar con mi sueldo», con aviso previo, y entonces va tras «#», que el navegador no envía al servidor. Al abrir ese enlace, el sueldo se lee y se quita de la barra de direcciones.
- **Ficha de sección:**
  - el valor del mapa activo; en el sueldo necesario, al lado el mínimo teórico con la superficie elegida (tarea 40) y también la paga en 14 pagas (× 12 ÷ 14) y lo de cada uno entre dos sueldos iguales (÷ 2); con «Tu ficha», de dónde sale su ingreso (la paga, el segundo sueldo y las 14 pagas repartidas en 12; F3);
  - debajo, en la sección y en el municipio, el indicador 14 («alquiler mediano sobre renta media del barrio») del periodo de la vista, con su aviso de lectura (tarea 41; fuera en «¿te llega?» con la llave, que ya es ese cociente);
  - bajo la cifra, la fiabilidad de la mediana del alquiler (`js/fiabilidad.js`; preguntas 12 y 15 ampliadas): «Mediana de N contratos · margen aproximado ±X %», con la marca «pocos contratos» por debajo de `umbral_pocos_contratos` (30); en el sueldo necesario y los mapas del alquiler, el intervalo de la cifra con ese margen. Sin mediana: con 1 a 9 contratos, cuántos hay; con 0, «sin contratos de alquiler de pisos registrados» (o de viviendas unifamiliares) en lugar de «sin dato», y un contexto rotulado que no se pinta en el mapa (regla 1): la mediana de la otra tipología en la sección y la de la misma en su municipio. Las secciones con pocos contratos no se atenúan en el mapa: la marca va en la ficha y en el CSV;
  - la evolución por años, desde `datos/fichas/<municipio>.json` (las variantes de vivienda unifamiliar no van en esos ficheros: se sacan de los de cada periodo), con un gráfico (`js/evolucion.js`; tareas 43 y 45): la banda del margen en los mapas del alquiler y en «¿te llega?», un punto hueco con menos de 30 contratos, la variación de cada año en la tabla (solo con 30 contratos o más en los dos años; si no, la media anual de tres años, con «†», o ninguna) y, en las series en euros, el aviso de euros corrientes con la variación del IPC del periodo (`datos/ipc.json`). Los contratos y el margen de cada año se leen de los ficheros de cada periodo;
  - el **comparador** con su distrito, su municipio, su provincia, su comunidad, España u otra sección elegida en el mapa, con los indicadores de la v0.1 y el mismo periodo en las dos columnas.
- **Ficha de territorio** (municipio, provincia o comunidad; tarea 26): su nombre y código, los territorios que lo contienen, la cifra del mapa activo publicada en su nivel (regla 1: si alguna serie que da color no llega a él, «sin dato en este nivel»; nunca se suman secciones), con su fiabilidad si la tiene, su evolución por años y el comparador con su provincia, su comunidad o España.
- **Buscador** de municipio (por nombre, sin tildes y con el artículo delante o detrás: «Las Palmas» o «Palmas de Gran Canaria, Las»), que abre su ficha, o de sección (por código). En los mapas de una sola escala (`nivel_minimo`), lo elegido abre la ficha del territorio de ese nivel que lo contiene (en el 11, su provincia; `territorioEnNivel()` de `js/comparador.js`).
- **Leyenda plegable**, abierta al entrar (tarea 51). A escala de sección, en los mapas con juego de cortes de la sección, ofrece «Tramos: De España · De <municipio>» (`escala=municipio`; `js/escala_municipio.js`; decisión del autor, 11-nov-2026): septiles de las secciones con dato del municipio de la ficha (o, sin ficha, del centro de la vista) en el año y la serie que se ven, redondeados a pasos de 1, 2, 2,5 o 5 por una potencia de 10, con la línea «no comparables con otros municipios»; las secciones de fuera quedan sin color. Con menos de 14 secciones con dato, la opción sale desactivada.

## Estructura

| Ruta | Contenido |
|---|---|
| `index.html` | Portada: el tablero, con el centro, las fichas, las cartas y las casillas (estas, entre marcas, de `inventario/casillas_portada.csv`) |
| `mapa.html` | Mapa: cabecera con buscador e idioma, barra de la vista, mapa, leyenda, etiqueta, «Tu sueldo», ficha y diálogo «Compartir» |
| `js/portada.js`, `js/redireccion.js`, `estilo/portada.css`, `estilo/fichas/` | Portada: idioma, fichas, cartas, «Tu sueldo», buscador, dado y pie; redirección de los enlaces viejos de la raíz a `mapa.html`; maquetación; iconos de las fichas |
| `sobrecarga.html` | Sección «Sobrecarga» (v0.0): mapa de Europa, escalera, serie de España y de la UE-27 desde el primer año publicado (cortada en las rupturas de Eurostat y en las del atlas, como la de 2013 en España, que Eurostat no marca; las cifras de Eurostat llevan sus marcas), desgloses de España por tenencia, edad y quintil de renta, y módulo de acceso |
| `historico.html` | «Máquina del tiempo» (F6): series de España desde 1987 (años de renta y esfuerzo teórico del Banco de España, tipos oficiales de referencia del mercado hipotecario, valor tasado del MIVAU, también por comunidad, y sueldo bruto medio por asalariado del INE) y, al final, la vivienda como problema en los barómetros del CIS (mensual, desde 2014); un gráfico por bloque con el mismo eje de años, que se lee con el ratón o con el teclado, fechas clave, lectura y tabla; sin mapa |
| `js/principal.js` | Arranque del mapa y coordinación de todo lo demás |
| `js/estado.js` | Estado de la vista en la URL (`idioma`, `mapa`, `anio`, que puede ser un periodo como `2025-05`, `tipologia`, `ficha`, `superficie`, `umbral`, `seccion`, `comparar`, `vista`, `territorio`) y enlace para compartir |
| `js/barra_vista.js` | Barra de la vista: selectores de mapa, año y tipología, y botones de descarga |
| `js/exportar.js` | CSV de la serie del mapa y nombre de los ficheros, sin DOM salvo la descarga |
| `js/imagen.js` | PNG del mapa con título, leyenda y fuente, compuesto en un lienzo |
| `js/aviso_imagen.js` | Aviso antes de descargar la imagen de «¿te llega?» con «Tu ficha» |
| `js/i18n.js` | Textos desde `i18n/<idioma>.json`; cifras con el formato de cada idioma |
| `js/datos.js` | Manifiesto, índices, valores por serie, nivel y periodo, series de la ficha, nombres, cajas y perfiles |
| `js/entrar.js` | «Entrar» (tarea 37), sin DOM: lectura de los tramos de la brecha entre la oferta y el parque, sus límites, los intervalos del sueldo para entrar (superficie típica y 50 m²) y de la barrera, y «¿te llega?» con un intervalo, también con el sueldo de «Tu ficha». La interfaz es de las tareas 38 y 39 |
| `js/sueldo.js` | Lógica de «Tu sueldo», sin DOM: modos, superficies, cálculos y expresiones de color, resumen y marcas de la regla |
| `js/formulas.js` | Transformaciones del manifiesto (`directo`, `alquiler_mes_a_sueldo`, `alquiler_m2_a_sueldo`), el mínimo teórico de un mapa (`minimoDe`) y el texto de sus supuestos (`textoSupuestos`; tarea 40) |
| `js/colores.js` | Pasos de la rampa de cada tramo (los mapas con menos tramos toman pasos repartidos; «¿te llega?», el 1, el 4 y el 6), contraste WCAG y color del contorno de las secciones |
| `js/mapa.js` | MapLibre: mapa base (PMTiles o GeoJSON), capas coloreadas por niveles, etiqueta, selección, comparación y encuadre |
| `js/leyenda.js`, `js/ficha.js` | Leyenda y fichas de sección y de territorio; en «¿te llega?», los euros que quedan al mes (tarea 34) |
| `js/evolucion.js` | Evolución de la ficha (tareas 43 y 45): variaciones con la regla de los contratos (de un año con 30 o más en los dos; si no, media anual de tres años), banda del margen, puntos con pocos contratos, variación del IPC del periodo y notas, sin DOM; el gráfico SVG (`graficoEvolucion`) y la carga de `datos/ipc.json` |
| `js/familias.js` | Familias de alquiler («quedarse» y «entrar») y su lectura literal, para la leyenda y la portada (tarea 34); lo que sale «próximamente» mientras no tenga mapa: la familia «entrar» en la portada y la oferta de Idealista en el selector del mapa (v0.4.0) |
| `js/sobrecarga.js`, `js/sobrecarga_datos.js`, `estilo/sobrecarga.css` | Sección «Sobrecarga»: página (DOM y MapLibre) y su lógica sin DOM; datos en `datos/sobrecarga/` (`exportar_web_sobrecarga()`) |
| `js/historico.js`, `js/historico_datos.js`, `estilo/historico.css` | «Máquina del tiempo»: página (DOM y SVG) y su lógica sin DOM; datos en `datos/historico/` (`hist_exportar_web()`, `R/web_historico.R`) y `datos/cis_vivienda.json` (`cis_exportar_vivienda()`, `R/fuente_cis_barometros.R`; si falta, el bloque del CIS dice que no hay datos) |
| `js/panel_sueldo.js`, `js/compartir.js` | Tarjeta «Tu sueldo» y diálogo «Compartir» |
| `js/movil.js` | Pantallas estrechas (tarea 50; por debajo de 760 px, el corte de `sitio.css`): baja hasta la ficha al tocar el mapa si no está a la vista (sin animación con «reducir movimiento») y pliega la tipología y las descargas de la barra con «Más opciones» (`aria-expanded`). En escritorio no hace nada |
| `js/transparencia.js` | Transparencia (tarea 53): «Avisar de un error» (incidencias del repositorio), «Método en dos páginas» y su fe de erratas en cada idioma, y la fecha de los datos en largo; la línea bajo el mapa (con la fecha, `generado` del manifiesto), al pie de la ficha y en el pie de la portada |
| `js/comparador.js`, `js/buscador.js` | Comparador entre territorios y buscador |
| `metodo.html`, `method.html`, `metodo_corto.html`, `short_method.html`, `datos.html`, `data.html` | Páginas de texto «Método», «Método en dos páginas» (con la fe de erratas) y «Datos»: no están en git, las genera el flujo de Pages con pandoc (ver abajo, «Páginas de texto») |
| `herramientas/plantilla_documento.html`, `herramientas/documento_<idioma>.yaml`, `herramientas/datos_<idioma>.yaml` | Plantilla de pandoc de las páginas de texto (cabecera y menú de la web, índice plegable) y sus textos por idioma |
| `herramientas/pagina_datos.mjs` | Monta el Markdown de la página «Datos»: rellena la descarga, la cita y la cobertura desde `version.json` y `CITATION.cff` y le añade el diccionario generado en R |
| `herramientas/pagina_metodo_corto.mjs`, `herramientas/metodo_corto_<idioma>.yaml` | Monta el Markdown de «Método en dos páginas» (`docs/metodo_corto.md`, `docs/short_method.md`) con la fe de erratas de `inventario/erratas.csv` (tarea 53), y sus textos por idioma para pandoc |
| `estilo/tokens.css` | Generado por el pipeline desde `diseno/tokens.json`: no se edita a mano |
| `estilo/sitio.css` | Maquetación; solo usa las variables de `tokens.css` |
| `estilo/documento.css` | Páginas de texto: cuerpo, índice, tablas y código, con las variables de `tokens.css` |
| `estilo/fuentes/` | Tipografías autoalojadas, con su licencia |
| `i18n/es.json`, `i18n/en.json` | Diccionarios (ver abajo) |
| `vendor/` | Librerías de terceros, con su licencia |
| `datos/` | Exportación del pipeline (`exportar_web()` y `exportar_portada()`, fuera de git); `datos/ejemplo/`, la muestra (`herramientas/generar_ejemplo.R`), en git |
| `teselas/` | Mapa base en PMTiles (fuera de git, como todo `*.pmtiles`) |

## Datos: el contrato con el pipeline

`js/datos.js` busca `datos/manifiesto.json` y, si no existe, `datos/ejemplo/manifiesto.json`. Ese es el punto de enganche: cuando el pipeline escribe el manifiesto y el PMTiles, la web los usa sin tocar el código. La prueba `exportación del pipeline` de `pruebas/web/datos.test.mjs` comprueba el contrato.

El manifiesto dice:

- `mapa_base`: de qué tipo es (`pmtiles`, un fichero con varias capas, o `geojson`, un fichero por capa), dónde está y cómo se llama la propiedad que identifica cada elemento. Las capas son `comunidades` (`ccaa`), `provincias` (`provincia`), `municipios` (`municipio`) y `secciones` (`seccion`, código de 10 dígitos como texto). En el PMTiles hay una quinta, sin código: `sin_seccion`, el suelo que no es de ninguna sección, con `km2`, `provincias` y, en los trozos de una unidad del IGN, `nombre` y `tipo` (`atributos`). `atribucion`: las fuentes del mapa base («INE, IGN»).
- `indices`: un fichero por nivel (`sc`, `distrito`, `municipio`, `provincia`, `ccaa`, `nacional`) con los códigos en el orden de los valores. España es `"00"`.
- `territorios`: nombres por nivel y `ccaa_de_provincia`, porque la comunidad no está en el código de sección.
- `cajas`: caja de cada municipio, para el buscador.
- `fichas`: ruta de las series por municipio (`{municipio}`).
- `perfiles`: ingreso neto mensual de cada ficha, en euros y sin multiplicar por 10:
  - mochila y transistor, por provincia;
  - tartera, nacional (`"00"`);
  - la llave no lleva cifras, solo las series de su ingreso (`renta_hogar` ÷ 12) y de su vivienda (`alquiler_mes`).
  - Una ficha sin datos se deja fuera y la web no la ofrece.
- `codificacion`: la escala de los enteros (`10`) y los nombres de los estados en el orden de sus cifras. Una serie puede llevar su propia `escala` (100 para dos decimales): el pipeline la pone desde `escala_web` de `inventario/indicadores.csv` (hoy, solo el 19).
- `indicadores`: las series, con `niveles`, `decimales`, `anios` (o `periodos`, como `"2024-08"`, si no son años) y `ruta` (`{nivel}`, `{anio}` o `{periodo}`).
  - La serie por defecto lleva el código del indicador. Las variantes llevan `indicador`, `corte` y `grupo` (por ejemplo, la vivienda unifamiliar).
  - Tipología: la serie de la vivienda colectiva lleva `variantes` (`{"VU": "alquiler_m2_vu"}`) y la variante, `por_defecto` (`"alquiler_m2"`), con los mismos niveles y periodos. Las variantes no van en las series de la ficha.
- `mapas`: lo que se pinta. Cada mapa lleva su serie base (la de por defecto, nunca una variante), la fórmula de la web y de uno a cinco cortes (de dos a seis tramos). La leyenda escribe los cortes con los decimales que necesitan, sin pasar de los del mapa. La clave del mapa es la de sus textos en `indicadores` de los diccionarios. Desde F5 (10-nov-2026), además:
  - `nivel_minimo` (`"municipio"`): la serie no tiene secciones (el indicador 20 y los de compraventa, 10, 12, 16 y 17). La capa de municipios se pinta y se pulsa a toda escala y las secciones se apagan (`ponerNivelMinimo()` de `js/mapa.js`); una sección de la dirección se ve en la ficha de su municipio, que lleva la lectura del indicador.
  - `categorias` (`{"vocabulario": "zona_tensionada", "valores": [0, 1, 2]}`): mapa de categorías. Los cortes separan los valores; la leyenda, la ficha, su evolución, el CSV (columna `categoria`) y el PNG dicen el texto de cada una (`vocabulario.<vocabulario>.<valor>` de los diccionarios).
  - `detalle`: fichero con lo que la ficha del municipio añade (las declaraciones de zona tensionada, `datos/zonas_tensionadas.json`: resolución del BOE, ámbito, vigencia y declaración de la comunidad, con sus enlaces).
  - `minimo` (tarea 40; solo el sueldo necesario): `{"base": "alquiler_m2", "formula": "alquiler_m2_a_sueldo"}`, la serie y la fórmula de la cifra que va al lado de la que se pinta (el mínimo teórico con la superficie elegida), en la ficha, la leyenda y el CSV (`minimoDe()` de `js/formulas.js`).
  - Mapas por grupo (capa de portales, indicador 13, solo con `PORTALES=TRUE`): la clave es la de la serie (`precio_oferta_alquiler_idealista`), con `indicador`, `corte` y `grupo`; los textos, los del indicador y el grupo. Toda serie cuya fuente tiene texto en `vocabulario.etiqueta` lleva esa etiqueta («Dato privado de oferta») sobre el mapa (`#aviso-privado`), en la leyenda, la ficha y el PNG; el CSV no se ofrece (backlog, decisión 3: `descargaPermitida()` de `js/exportar.js`). Desde la tarea 35 (10-nov-2026) estas series no están en este manifiesto: llegan del de la capa (abajo).
- **Capas desmontables** (tarea 35): la capa de portales tiene su propio manifiesto, `datos/portales/manifiesto.json` (`R/web_portales.R`), que el pipeline escribe siempre y el flujo de Pages también. Apagada, solo `{"capa": "portales", "activa": false}`. Encendida, con `indicadores` y `mapas` en el formato de arriba (las rutas, bajo `datos/portales/`, con los índices generales) y, en cada serie, `ultimo_mes` (hasta qué mes llega el último año), `meses_minimos` (9), `enlaces` (`{nivel: {código: url}}`, el informe de cada cifra) y `zonas` (`{anios, escala, municipios: {municipio: [{zona, nombre, tipo, url, v, e}]}}`: zonas del portal y localidades, sin geometría, para la ficha del municipio de la tarea 38). `cargarManifiesto()` de `js/datos.js` la suma al manifiesto general con `unirCapas()`, sin pisar ninguna clave; la muestra de `datos/ejemplo/` no tiene capas.
  - **«Entrar»** (tarea 37; decisión 18), en la capa encendida: la entrada `entrar` del manifiesto de la capa, que `unirCapas()` pasa a `m.entrar`, con `base` (`brecha_entrar_quedarse`), `tramos` (`cortes`, `limites` y `aviso`, de `inventario/entrar_tramos.csv`), `series` (solo la de la base: `niveles`, `anios`, `ruta` bajo `datos/portales/entrar/` y `valor`: `"tramo"`), `derivados` (`sueldo_entrar`, `sueldo_entrar_50` y `barrera_entrar`: la serie pública por la que se multiplica el tramo, la superficie y, en la barrera, los cortes de «¿te llega?») y `supuestos`. Cada fichero lleva `{"v": [tramo o null], "e": "0123…"}` por territorio del índice general del nivel: el tramo k va de `cortes[k-1]` (o `limites[0]`) a `cortes[k]` (o `limites[1]`), sin incluir el borde de arriba. Ninguna cifra exacta: el sueldo para entrar, el de 50 m² y la barrera se dan como intervalo, los límites del tramo × el alquiler mensual mediano / umbral, × el alquiler por m² × superficie / umbral y × el alquiler por m² × superficie / ingreso (`js/entrar.js`). La web de hoy no lo pinta: lo harán las tareas 38 y 39.
- `supuestos`: superficie y umbral por defecto.
- `umbral_pocos_contratos`: por debajo de este número de contratos, la ficha marca «pocos contratos» (`UMBRAL_POCOS_CONTRATOS` del pipeline, 30).
- Fiabilidad: cada serie del alquiler (y el esfuerzo y el sueldo necesario, que salen de él) lleva `fiabilidad`, `{"contratos": "contratos_alquiler", "margen": "margen_alquiler_m2"}` (el alquiler mensual, el esfuerzo y, desde la tarea 40, el sueldo necesario, con `margen_alquiler_mes`), con las series auxiliares de su misma tipología: el recuento de contratos del SERPAVI (0 incluido) y el margen aproximado de la mediana en %. Son series como las demás (con `variantes`), sin número de indicador ni mapa propio, y no van en las fichas por municipio: la ficha las lee de los ficheros del periodo que pinta el mapa.
- `ejemplo`: `true` en la muestra.

**Valores de una serie, nivel y periodo** (`datos/<nivel>/<serie>/<periodo>.json`; plan, §6.6, pregunta abierta 17): un JSON de enteros con el valor × 10, de modo que el decimal es exacto (`sprintf("%.1f")`), `null` si no hay valor, y una cadena con un carácter de estado por territorio: `0` dato, `1` estimado, `2` secreto, `3` ausente. Los dos van en el orden del índice de su nivel:

```json
{"v": [247, 251, null, 131], "e": "0020"}
```

Desde R:

```r
v <- rep(NA_integer_, length(x))
v[!is.na(x)] <- as.integer(round(as.numeric(sprintf("%.1f", x[!is.na(x)])) * 10))
jsonlite::write_json(list(v = I(v), e = paste(estado, collapse = "")), ruta,
                     auto_unbox = TRUE, na = "null", digits = NA)
```

Primero se redondea como manda la guía y después se multiplica por 10. `sprintf("%.0f", x * 10)` no da lo mismo en algunos casos: 0,15 queda en 0,1 con la guía y en 2 décimas así. `I()` evita que un vector de longitud 1 salga como escalar, y `na = "null"` escribe los `NA` como `null`.

**Series de la ficha** (`datos/fichas/<municipio>.json`): todos los periodos de las secciones de un municipio, para no bajar un fichero por año al abrir una ficha. Cada serie usa el mismo par `v` y `e`, en el orden de `anios`:

```json
{"municipio": "28079",
 "anios": {"alquiler_m2": [2020, 2021, 2022, 2023, 2024]},
 "series": {"2807901001": {"alquiler_m2": {"v": [221, 227, 234, 240, 247], "e": "00000"}}}}
```

**Cartas de la portada** (`datos/portada.json`, `exportar_portada()` en `R/web_portada.R`; no va en el manifiesto): `cartas.sueldo` (`anio`, `secciones`, `p10`, `mediana`, `p90`, con el alquiler mensual real, y `minimo`, la mediana del mínimo de 50 m²; `superficie_m2`, `umbral`, `mapa`, `fuentes`), `cartas.smi` (`anio`, `secciones`, `pct_30`, `pct_40` con 50 m², `pct_30_real`, `pct_40_real` con el alquiler mensual real, `superficie_m2`, `ficha`, `neto_mensual`, `fuentes`) y `cartas.sobrecarga` (`anio`, `total`, `alquiler_mercado`, `fuentes`), con el redondeo de la guía (tarea 40: la cifra de al lado). La compuerta `portada_valores` recalcula cada cifra por otro camino (el alquiler mensual y por m² y el ingreso de la tartera, como la web) y `portada_casillas` comprueba el CSV de las casillas y sus destinos.

**IPC** (`datos/ipc.json`, `ipc_exportar_web()` en `R/fuente_ine_ipc.R`; no va en el manifiesto; tarea 45): `fuente`, `licencia`, `base` (el año de índice 100) y, año a año, `anios` e `indice` (medias anuales del índice general del INE, tabla 76144, con tres decimales). La evolución de la ficha lo lee una vez (`cargarIpc()`, `js/evolucion.js`) para dar la variación del IPC entre el primer y el último año con cifra; sin el fichero, dice igual que las cifras van en euros corrientes. Compuerta `web_ipc` (ida y vuelta).

**Cálculos de la web y del pipeline.** La web calcula el indicador 21 con el 9 ya redondeado a una décima, y el 15 con el 9 y el ingreso de la ficha de `perfiles.json`, también redondeados. El pipeline calcula los derivados (14, 15 y 21) desde esos mismos términos redondeados (`termino_publicado()`, pregunta abierta 19), así que la página y R dan la misma cifra.

## Diccionarios

En `i18n/es.json` e `i18n/en.json`, las secciones `indicadores`, `fuentes` y `vocabulario` las genera el pipeline desde `inventario/` (`exportar_i18n()`) y no se editan a mano. `sitio`, `nav`, `fichas`, `avisos`, `interfaz`, `portada`, `sobrecarga` e `historico` (los textos de la web) se escriben a mano, y el pipeline las conserva. Los textos de las casillas de la portada no van aquí: salen de `inventario/casillas_portada.csv`. La comprobación `i18n_completo` exige las mismas claves en los dos idiomas y ningún texto vacío.

Los textos de la web son impersonales, salvo los del plan para «Tu sueldo» («Tu ficha», «¿te llega?», «te cabe…»).

## Estilo

`estilo/tokens.css` lo genera el pipeline desde `diseno/tokens.json`. Incluye las variables de color, la rampa de seis pasos con contorno en los tramos claros, las fichas, las tipografías y las formas, y las clases `.tramo-N`, `.secreto`, `.muestra-pequena` y `.cabecera-carta` (la de «Tu sueldo»).

En el mapa, todas las secciones llevan contorno, porque los dos primeros tramos no llegan a 3:1 sobre la crema. Es de tinta sobre los tres tramos más claros, donde contrasta con ella al menos 3:1, y de placa sobre los oscuros. La selección lleva un halo de placa. La rampa tiene seis pasos (pregunta abierta 20), con la claridad repartida para que los contiguos se distingan también con daltonismo (compuerta `rampa_daltonismo`). «¿Te llega?» usa los pasos 1, 4 y 6, que se distinguen también por la claridad. Nada de elementos propios de Monopoly (plan, §10.2).

## Librerías (`vendor/`)

| Librería | Versión | Ficheros | Licencia |
|---|---|---|---|
| MapLibre GL JS | 6.15.0 (18-oct-2026) | `maplibre-gl.mjs`, `maplibre-gl-worker.mjs`, `maplibre-gl.css` | BSD-3 (`LICENSE.txt`) |
| PMTiles | 4.5.0 (10-ago-2026) | `pmtiles.js` | BSD-3 (`LICENSE`) |

Se bajaron de jsDelivr (paquetes de npm, carpeta `dist/`). Para actualizarlas, se sustituyen los ficheros por los de la nueva versión, se cambia esta tabla y se prueba en local. d3 entrará cuando haga falta un gráfico.

## Pruebas

```bash
node --test pruebas/web/datos.test.mjs
node --test pruebas/web/sobrecarga.test.mjs
node --test pruebas/web/historico.test.mjs
node --test pruebas/web/pagina_datos.test.mjs
node --test pruebas/web/portada.test.mjs
node --test pruebas/web/municipal.test.mjs
node --test pruebas/web/portales.test.mjs
node --test pruebas/web/entrar.test.mjs
node --test pruebas/web/evolucion.test.mjs
```

Todas a la vez: `node --test pruebas/web/*.test.mjs`. Así las pasa GitHub con cada push (`.github/workflows/pruebas.yml`, con la muestra de `datos/ejemplo/`); las que piden la exportación del pipeline se saltan solas.

La de la evolución (tareas 43 y 45) prueba las variaciones con la regla de los contratos (nunca una variación de un año sin aviso con menos de 30 contratos en alguno de los dos años), la banda del margen, la geometría del gráfico, el aviso de euros corrientes con la variación del IPC, la tabla con la columna de variación y los textos en los dos idiomas; con la exportación del pipeline, que `datos/ipc.json` trae los años del alquiler.

La de «entrar» (tarea 37) usa los mismos casos inventados que la prueba de R (`pruebas/datos/entrar_inventado.json`), para que R y la página coincidan en el tramo, en sus límites, en los intervalos y en «¿te llega?», también con el sueldo de «Tu ficha», y lee el fichero de tramos que escribe R; con la exportación del pipeline y la capa encendida, comprueba que los ficheros de «entrar» solo llevan tramos.

La quinta (F5) prueba los mapas sin sección, los de categorías y la capa de portales: las columnas `categoria` y `etiqueta` del CSV, los textos de F5 en los dos idiomas y, con la exportación del pipeline, que cada mapa con `nivel_minimo` tiene su serie sin sección, que las categorías tienen texto, que existe el fichero de las declaraciones y que no hay series ni mapas de los portales en el manifiesto general. La capa de portales tiene su prueba, `node --test pruebas/web/portales.test.mjs`: `unirCapas()`, el CSV que no se ofrece y, con la exportación del pipeline, el manifiesto de la capa (apagada, vacío; encendida, las series de España a municipio con sus ficheros, enlaces y zonas).

La cuarta prueba la portada y lo que cambia con ella en el mapa: la redirección de los enlaces viejos de la raíz (la lista de claves es la de `estado.js`), los destinos de las casillas y de las fichas (claves del mapa, mapas del manifiesto, anclas de las páginas), los menús de todas las páginas y de la plantilla, que el sueldo de la portada va tras «#» y nunca en la consulta, las cartas (sin un término, no salen), el dado, la clave `territorio`, el comparador y «¿te llega?» por niveles, y el desglose de las pagas en la ficha.

La tercera prueba la página «Datos» (`herramientas/pagina_datos.mjs`): cifras, fechas y enlaces de la caja de descarga en los dos idiomas, con y sin `version.json` y con uno anterior a la cobertura; tabla de cobertura; cita de `CITATION.cff`; marcas de `docs/datos.md` y `docs/data.md`, y la línea de órdenes.

Comprueban, con datos inventados:

- el formato de los valores, los periodos (también con meses) y las fórmulas;
- la lógica de «Tu sueldo»: ingresos, superficies, cálculos, tramos, resumen y regla;
- la tipología: la serie de cada una y el alquiler de «¿te llega?»;
- el comparador, el buscador, la URL (mapa, periodo y tipología) y que el sueldo nunca entra en ella;
- el CSV (BOM, comillas, estados, supuestos), el redondeo, el nivel y el nombre de los ficheros;
- que la muestra que escribe R se lee entera y que sus series cuadran con el mapa.

Si existe `datos/manifiesto.json`, comprueban también la exportación del pipeline y que **la página recalcula y coincide con R** (plan, §6.5): el sueldo necesario calculado con `js/formulas.js` desde la base de su mapa (el alquiler mensual desde la tarea 40; antes, el alquiler por m²), en todas las secciones y niveles y en todos los años, redondeado a una décima como en la web, da los mismos enteros, nulos y estados que la serie `sueldo_necesario` que exporta R. Con la exportación del 8-nov-2026: 550.140 territorios y años, 294.082 con valor, ninguna diferencia.

Queda aparte la prueba en un navegador de verdad, con `chromote` (que no está en `renv.lock`): `comprobar_web_navegador()` (`R/web_navegador.R`, `pruebas/testthat/test-navegador.R`). Además de la muestra del sueldo necesario y las fichas (con el mínimo de 50 m² al lado de la cifra principal; tarea 40), comprueba la redirección de los enlaces viejos, la portada en los dos idiomas con sus cartas frente a la tabla larga, los destinos de las casillas, «Tu sueldo» de la portada hasta el mapa, que a 375 px no hay desbordes, la ficha de una comunidad, una provincia y un municipio frente a la tabla larga, la etiqueta y el clic en cada escala y, desde F5, los mapas sin sección: la ficha del indicador 20 en un municipio declarado entero, uno en parte y uno sin declarar, con sus declaraciones, el clic a escala de sección, que abre la del municipio, y la cifra municipal del valor tasado.

## Páginas de texto

«Método» (`metodo.html`, `method.html`) y «Datos» (`datos.html`, `data.html`) no son módulos de la web: el flujo de Pages las genera con pandoc desde `docs/` y `herramientas/plantilla_documento.html`, con la misma cabecera y el mismo menú, en un fichero por idioma (el botón ES/EN lleva al otro). Sus copias locales están fuera de git; cómo montarlas: `docs/publicacion.md`.

«Datos» lleva la descarga de la tabla larga (`descargas/tabla_larga.parquet`, con su tamaño, su suma SHA-256, la fecha y el commit de los datos y el enlace al release, de `descargas/version.json`), las licencias y la cita, cómo leerla en R y en Python, el modelo de datos, la cobertura de cada indicador en el release, los valores de las columnas y el diccionario de indicadores. Los textos a mano están en `docs/datos.md` y `docs/data.md`; los valores de las columnas y el diccionario, en `docs/datos_diccionario.md` y `docs/data_dictionary.md`, que genera R desde `inventario/` (`exportar_diccionario_datos()`): no se editan a mano. El menú de `index.html`, `mapa.html` y `sobrecarga.html` la enlaza con `data-href-es` y `data-href-en`, como «Método».

## Publicación

GitHub Pages sirve esta carpeta tal cual, con los rangos HTTP que pide el PMTiles. Ni el PMTiles ni los datos exportados (`datos/`, salvo la muestra de `datos/ejemplo/`) entran en la historia de git: se publican desde un *release* y el flujo de Pages los copia junto a la web (preguntas abiertas 16 y 21), con la tabla larga en `descargas/` para la página «Datos». El sitio publicado ocupa unos 139 MB. Flujo: `.github/workflows/pages.yml`; paquete del release: `empaquetar_publicacion()`; pasos: `docs/publicacion.md`. `LEEME.md`, `servir.mjs` y `herramientas/` no se publican.
