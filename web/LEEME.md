# Web

Web estática de *De renta en renta* (plan, §6.6): MapLibre con PMTiles para las secciones, sin servidor ni analítica, castellano e inglés, estado de la vista en la URL y publicación en GitHub Pages.

**Pila (decisión del autor, 8-nov-2026): HTML y módulos JavaScript nativos, sin compilar.** No hay npm ni paso de compilación: el código que se edita es el que corre. Las librerías están copiadas en `vendor/` con versión fijada. El código importa `maplibre-gl` por su nombre gracias al *import map* de `index.html`, así que, si algún día hiciera falta, se podría pasar a un empaquetador (Vite) sin reescribir los módulos.

## Verla en local

Desde la raíz del proyecto:

```bash
node web/servir.mjs
```

y abrir <http://localhost:8000/>. Para parar: Ctrl+C. Si el puerto está ocupado, se puede usar otro: `node web/servir.mjs 8080`.

- `servir.mjs` es un servidor propio, sin paquetes (Node 18 o posterior). Solo escucha en el propio equipo.
- Hace falta porque el PMTiles se lee por trozos (rangos HTTP) y `python -m http.server` no los atiende.
- Abrir `index.html` con doble clic no funciona: el navegador no deja cargar módulos ni datos desde `file://`.

Con la exportación del pipeline (`datos/manifiesto.json` y `teselas/seccionado_2021.pmtiles`), la web muestra toda España. Sin ella, carga la **muestra** de `datos/ejemplo/`: las 111 secciones de 2021 del distrito Centro de Madrid, con valores **inventados** y la etiqueta «Datos de ejemplo» siempre visible (guía, regla 9). La muestra tiene cuatro mapas (uno con periodos por meses) y la variante de vivienda unifamiliar de los alquileres, para probar los selectores.

## Qué hace

- **Barra de la vista**, encima del mapa:
  - **mapa**: los de `mapas` del manifiesto; por defecto, el sueldo necesario, y los demás con la fórmula `directo`. En «¿te llega?», la primera opción es «¿Te llega? · ficha»; elegir otro mapa sale de ese modo;
  - **año**: los periodos de la serie que da color (los meses, escritos: «mayo de 2026»). Sin año elegido, el último de cada serie; con uno elegido, cada serie usa ese o el último anterior y, si el año es anterior a toda la serie, sin dato y un aviso con el inicio de la serie («2020 (sin datos)» en la barra);
  - **vivienda**: colectiva o unifamiliar, solo si la serie del mapa tiene variante (`variantes` en el manifiesto). Colectiva por defecto y nunca mezcladas (decisión 12). Cambia el mapa, la leyenda, la ficha, su evolución y el comparador; en «¿te llega?», el alquiler que se usa;
  - **descargar**: los datos del mapa en CSV y su imagen en PNG (ver abajo).
  - Todo se maneja con el teclado (los dos primeros son `<select>` nativos, que en el móvil abren el selector del sistema) y queda en la URL.
  - Si la serie no llega al nivel que se ve (una serie solo por sección con el mapa de España), un aviso pide acercar el mapa.
- **Descargas**, sin dependencias y sin el sueldo escrito (como «Compartir»):
  - **CSV** de la serie del mapa en el nivel que se ve (provincia, municipio o sección; si la serie no llega a ese nivel, el más fino que tenga), con una fila por territorio y las columnas código, nombre, nivel, indicador, tipología, periodo, valor (con la precisión de la serie: una décima; dos en las viviendas turísticas), unidad, estado y fuente; en el sueldo necesario, también la superficie y el umbral. UTF-8 con BOM, coma entre campos y punto decimal. En «¿te llega?» lleva el alquiler que usa el mapa y no la proporción, de la que se despejaría el sueldo;
  - **PNG** del mapa tal como se ve, con título, periodo, tipología, leyenda, claves de los huecos, fuente y fecha de los datos. Con «Tu ficha», el ingreso se nombra («el sueldo escrito») sin la cifra, y antes de descargar la imagen sale un aviso como el de «Compartir» (sus colores dejan deducir el sueldo), que se puede cancelar.
  - El nombre del fichero lleva el mapa, la tipología si es la unifamiliar, el periodo y, en el CSV, el nivel: `de-renta-en-renta_sueldo_necesario_2024_municipio.csv`.
- **Mapa por defecto: sueldo neto necesario** (indicador 21) para que el alquiler de 50 m² no pase del 30 % del sueldo. Hay seis tramos con los cortes del manifiesto (700 · 900 · 1.100 · 1.500 · 2.000 €), uno por paso de la rampa. Se pinta con el alquiler por m² (indicador 9) y la fórmula de `js/formulas.js`. Superficie de 50, 70 o 90 m² y umbral del 30 o del 40 %.
  - En la regla de la leyenda, las fichas de una persona aparecen como marcas en su ingreso: la mochila, con la provincia de la sección elegida o la mediana de las provincias, y la tartera. La llave aparece como un tramo, del cuartil 1 al 3 de la renta de los hogares ÷ 12.
- **«¿Te llega?»** al escribir un sueldo (neto al mes, 12 o 14 pagas, segundo sueldo opcional) o al elegir una ficha. Muestra el alquiler sobre el ingreso en tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %) y la frase «te cabe en el X % de las secciones con dato».
  - Cada ficha tiene su vivienda (plan, §3.1):
    - las de una persona, 50 m²;
    - la llave, el alquiler mensual mediano de su sección frente a la renta de sus hogares ÷ 12;
    - «Tu ficha», 50 m² con un sueldo y 70 con dos, cambiable.
  - Si el ingreso de la ficha no es del mismo año que el alquiler (la tartera es el SMI del año en curso), se avisa (regla 4).
- **Cálculo en el navegador**, sin descargar nada más: los valores van en el estado de cada elemento del mapa (*feature-state*) y el color sale de expresiones de estilo (`js/sueldo.js`).
  - Con poco zoom, donde el PMTiles aún no trae secciones, se pintan los municipios y, más abajo, las provincias, con las cifras publicadas en su nivel.
- **El sueldo no sale del dispositivo.** No entra en la URL ni se guarda. Solo va en un enlace si se pulsa «Compartir» y se elige «Copiar con mi sueldo», con aviso previo, y entonces va tras «#», que el navegador no envía al servidor. Al abrir ese enlace, el sueldo se lee y se quita de la barra de direcciones.
- **Ficha de sección:**
  - el valor del mapa activo;
  - la evolución por años, desde `datos/fichas/<municipio>.json` (las variantes de vivienda unifamiliar no van en esos ficheros: se sacan de los de cada periodo);
  - el **comparador** con su distrito, su municipio, su provincia, su comunidad, España u otra sección elegida en el mapa, con los indicadores de la v0.1 y el mismo periodo en las dos columnas.
- **Buscador** de municipio (por nombre, sin tildes y con el artículo delante o detrás: «Las Palmas» o «Palmas de Gran Canaria, Las») o de sección (por código).
- **Leyenda plegable**, cerrada de entrada en el móvil.

## Estructura

| Ruta | Contenido |
|---|---|
| `index.html` | Página: cabecera con buscador e idioma, barra de la vista, mapa, leyenda, «Tu sueldo», ficha y diálogo «Compartir» |
| `sobrecarga.html` | Sección «Sobrecarga» (v0.0): mapa de Europa, escalera, serie de España y de la UE-27 desde el primer año publicado (cortada en las rupturas de Eurostat; las cifras de Eurostat llevan sus marcas), desgloses de España por tenencia, edad y quintil de renta, y módulo de acceso |
| `js/principal.js` | Arranque y coordinación de todo lo demás |
| `js/estado.js` | Estado de la vista en la URL (`idioma`, `mapa`, `anio`, que puede ser un periodo como `2025-05`, `tipologia`, `ficha`, `superficie`, `umbral`, `seccion`, `comparar`, `vista`) y enlace para compartir |
| `js/barra_vista.js` | Barra de la vista: selectores de mapa, año y tipología, y botones de descarga |
| `js/exportar.js` | CSV de la serie del mapa y nombre de los ficheros, sin DOM salvo la descarga |
| `js/imagen.js` | PNG del mapa con título, leyenda y fuente, compuesto en un lienzo |
| `js/aviso_imagen.js` | Aviso antes de descargar la imagen de «¿te llega?» con «Tu ficha» |
| `js/i18n.js` | Textos desde `i18n/<idioma>.json`; cifras con el formato de cada idioma |
| `js/datos.js` | Manifiesto, índices, valores por serie, nivel y periodo, series de la ficha, nombres, cajas y perfiles |
| `js/sueldo.js` | Lógica de «Tu sueldo», sin DOM: modos, superficies, cálculos y expresiones de color, resumen y marcas de la regla |
| `js/formulas.js` | Transformaciones del manifiesto (`directo`, `alquiler_m2_a_sueldo`) |
| `js/colores.js` | Pasos de la rampa de cada tramo (los mapas con menos tramos toman pasos repartidos; «¿te llega?», el 1, el 4 y el 6), contraste WCAG y color del contorno de las secciones |
| `js/mapa.js` | MapLibre: mapa base (PMTiles o GeoJSON), capas coloreadas, selección, comparación y encuadre |
| `js/leyenda.js`, `js/ficha.js` | Leyenda y ficha de sección |
| `js/sobrecarga.js`, `js/sobrecarga_datos.js`, `estilo/sobrecarga.css` | Sección «Sobrecarga»: página (DOM y MapLibre) y su lógica sin DOM; datos en `datos/sobrecarga/` (`exportar_web_sobrecarga()`) |
| `js/panel_sueldo.js`, `js/compartir.js` | Tarjeta «Tu sueldo» y diálogo «Compartir» |
| `js/comparador.js`, `js/buscador.js` | Comparador entre territorios y buscador |
| `estilo/tokens.css` | Generado por el pipeline desde `diseno/tokens.json`: no se edita a mano |
| `estilo/sitio.css` | Maquetación; solo usa las variables de `tokens.css` |
| `estilo/fuentes/` | Tipografías autoalojadas, con su licencia |
| `i18n/es.json`, `i18n/en.json` | Diccionarios (ver abajo) |
| `vendor/` | Librerías de terceros, con su licencia |
| `datos/` | Exportación del pipeline (`exportar_web()`, fuera de git); `datos/ejemplo/`, la muestra (`herramientas/generar_ejemplo.R`), en git |
| `teselas/` | Mapa base en PMTiles (fuera de git, como todo `*.pmtiles`) |

## Datos: el contrato con el pipeline

`js/datos.js` busca `datos/manifiesto.json` y, si no existe, `datos/ejemplo/manifiesto.json`. Ese es el punto de enganche: cuando el pipeline escribe el manifiesto y el PMTiles, la web los usa sin tocar el código. La prueba `exportación del pipeline` de `pruebas/web/datos.test.mjs` comprueba el contrato.

El manifiesto dice:

- `mapa_base`: de qué tipo es (`pmtiles`, un fichero con varias capas, o `geojson`, un fichero por capa), dónde está y cómo se llama la propiedad que identifica cada elemento. Las capas son `comunidades` (`ccaa`), `provincias` (`provincia`), `municipios` (`municipio`) y `secciones` (`seccion`, código de 10 dígitos como texto).
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
- `mapas`: lo que se pinta. Cada mapa lleva su serie base (la de por defecto, nunca una variante), la fórmula de la web y de uno a cinco cortes (de dos a seis tramos). La leyenda escribe los cortes con los decimales que necesitan, sin pasar de los del mapa. La clave del mapa es la de sus textos en `indicadores` de los diccionarios.
- `supuestos`: superficie y umbral por defecto.
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

**Cálculos de la web y del pipeline.** La web calcula el indicador 21 con el 9 ya redondeado a una décima, y el 15 con el 9 y el ingreso de la ficha de `perfiles.json`, también redondeados. El pipeline calcula los derivados (14, 15 y 21) desde esos mismos términos redondeados (`termino_publicado()`, pregunta abierta 19), así que la página y R dan la misma cifra.

## Diccionarios

En `i18n/es.json` e `i18n/en.json`, las secciones `indicadores`, `fuentes` y `vocabulario` las genera el pipeline desde `inventario/` (`exportar_i18n()`) y no se editan a mano. `sitio`, `nav`, `fichas`, `avisos` e `interfaz` (los textos de la web) se escriben a mano, y el pipeline las conserva. La comprobación `i18n_completo` exige las mismas claves en los dos idiomas y ningún texto vacío.

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
```

Comprueban, con datos inventados:

- el formato de los valores, los periodos (también con meses) y las fórmulas;
- la lógica de «Tu sueldo»: ingresos, superficies, cálculos, tramos, resumen y regla;
- la tipología: la serie de cada una y el alquiler de «¿te llega?»;
- el comparador, el buscador, la URL (mapa, periodo y tipología) y que el sueldo nunca entra en ella;
- el CSV (BOM, comillas, estados, supuestos), el redondeo, el nivel y el nombre de los ficheros;
- que la muestra que escribe R se lee entera y que sus series cuadran con el mapa.

Si existe `datos/manifiesto.json`, comprueban también la exportación del pipeline y que **la página recalcula y coincide con R** (plan, §6.5): el sueldo necesario calculado con `js/formulas.js` desde el alquiler por m², en todas las secciones y niveles y en todos los años, redondeado a una décima como en la web, da los mismos enteros, nulos y estados que la serie `sueldo_necesario` que exporta R. Con la exportación del 8-nov-2026: 550.140 territorios y años, 294.082 con valor, ninguna diferencia.

Queda aparte la misma prueba en el navegador con `chromote`, que no está en `renv.lock`.

## Publicación

GitHub Pages sirve esta carpeta tal cual, con los rangos HTTP que pide el PMTiles. Ni el PMTiles ni los datos exportados (`datos/`, salvo la muestra de `datos/ejemplo/`) entran en la historia de git: se publican desde un *release* y el flujo de Pages los copia junto a la web (preguntas abiertas 16 y 21), con la tabla larga en `descargas/` para la página «Datos». El sitio publicado ocupa unos 139 MB. Flujo: `.github/workflows/pages.yml`; paquete del release: `empaquetar_publicacion()`; pasos: `docs/publicacion.md`. `LEEME.md`, `servir.mjs` y `herramientas/` no se publican.
