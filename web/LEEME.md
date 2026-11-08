# Web

Web estática de *De renta en renta* (plan, §6.6): MapLibre con PMTiles para las secciones, sin servidor ni analítica, castellano e inglés, estado de la vista en la URL y publicación en GitHub Pages. «Tu sueldo» calcula en el navegador: el sueldo del usuario no sale del dispositivo salvo que pulse «Compartir».

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

Mientras el pipeline no exporte los datos, la web carga la **muestra** de `datos/ejemplo/`: las 111 secciones de 2021 del distrito Centro de Madrid, con valores **inventados** de alquiler por m² de 2020 a 2024 (y sus series en `fichas/28079.json`) y la etiqueta «Datos de ejemplo» siempre visible (guía, regla 9).

## Estructura

| Ruta | Contenido |
|---|---|
| `index.html` | Página: cabecera, selector ES/EN, mapa, leyenda y ficha |
| `js/principal.js` | Arranque: idioma, manifiesto, mapa, leyenda y ficha |
| `js/estado.js` | Estado de la vista en la URL (`idioma`, `mapa`, `anio`, `seccion`, `vista`) |
| `js/i18n.js` | Textos desde `i18n/<idioma>.json`; cifras con el formato de cada idioma |
| `js/datos.js` | Manifiesto, índice de secciones, valores de los indicadores y series de la ficha |
| `js/mapa.js` | MapLibre: mapa base (PMTiles o GeoJSON), color por tramos, selección |
| `js/formulas.js` | Transformaciones que la web calcula (sueldo necesario desde el alquiler por m²) |
| `js/leyenda.js`, `js/ficha.js` | Leyenda (regla de tramos) y ficha de sección, con su evolución por años |
| `estilo/tokens.css` | Generado por el pipeline desde `diseno/tokens.json`: no se edita a mano |
| `estilo/sitio.css` | Maquetación; solo usa las variables de `tokens.css` |
| `estilo/fuentes/` | Tipografías autoalojadas, con su licencia |
| `i18n/es.json`, `i18n/en.json` | Diccionarios (ver abajo) |
| `i18n/pendiente_interfaz.json` | Textos de la interfaz que aún no están en los diccionarios (sección `interfaz`) |
| `vendor/` | Librerías de terceros, con su licencia |
| `datos/` | Datos para la web: `manifiesto.json`, valores por indicador y año, series por municipio (exportación del pipeline) |
| `datos/ejemplo/` | Muestra con valores inventados (`herramientas/generar_ejemplo.R`) |
| `teselas/` | Mapa base en PMTiles (fuera de git, como todo `*.pmtiles`) |

## Datos: el manifiesto

`js/datos.js` busca `datos/manifiesto.json` y, si no existe, `datos/ejemplo/manifiesto.json`. Ese es el punto de enganche: cuando el pipeline escriba el manifiesto y el PMTiles, la web los usa sin tocar el código.

El manifiesto dice:

- `mapa_base`: de qué tipo es (`pmtiles`, un fichero con varias capas, o `geojson`, un fichero por capa), dónde está y cómo se llama la propiedad que identifica cada elemento. Las capas son las del mapa base del seccionado de 2021: `comunidades` (`ccaa`), `provincias` (`provincia`), `municipios` (`municipio`) y `secciones` (`seccion`, código de 10 dígitos como texto).
- `secciones`: el índice, es decir, los códigos en el orden de los valores.
- `territorios`: los nombres por nivel.
- `codificacion`: la escala de los enteros (`10`) y los nombres de los estados en el orden de sus cifras (`dato`, `estimado`, `secreto`, `ausente`).
- `indicadores`: los años de cada indicador y la ruta de sus valores (`{anio}` se sustituye por el año).
- `fichas`: la ruta de las series por municipio (`{municipio}`, los cinco primeros dígitos del código de sección).
- `mapas`: lo que se pinta. Cada mapa da su indicador base, la fórmula que aplica la web (`js/formulas.js`) y los cuatro cortes de los cinco tramos.
- `supuestos`: superficie y umbral por defecto.
- `ejemplo`: `true` en la muestra.

**Valores de un indicador, nivel y año** (`datos/<nivel>/<indicador>/<anio>.json`; plan, §6.6, pregunta abierta 17): un JSON de enteros con el valor × 10, de modo que el decimal es exacto (`sprintf("%.1f")`), `null` si no hay valor, y una cadena con un carácter de estado por territorio: `0` dato, `1` estimado, `2` secreto, `3` ausente. Los dos van en el orden del índice:

```json
{"v": [247, 251, null, 131], "e": "0020"}
```

Ocupa lo mismo comprimido que un binario (57–121 KB por indicador y año en las 36.333 secciones), y GitHub Pages lo sirve comprimido. Desde R:

```r
v <- rep(NA_integer_, length(x))
v[!is.na(x)] <- as.integer(sprintf("%.0f", x[!is.na(x)] * 10))
jsonlite::write_json(list(v = I(v), e = paste(estado, collapse = "")), ruta,
                     auto_unbox = TRUE, na = "null", digits = NA)
```

`I()` evita que un vector de longitud 1 salga como escalar, y `na = "null"` escribe los `NA` como `null`.

**Series de la ficha** (`datos/fichas/<municipio>.json`): todos los años de las secciones de un municipio, para no bajar un fichero por año al abrir una ficha. Cada serie usa el mismo par `v` y `e`, en el orden de los años de `anios`:

```json
{"municipio": "28079",
 "anios": {"alquiler_m2": [2020, 2021, 2022, 2023, 2024]},
 "series": {"2807901001": {"alquiler_m2": {"v": [221, 227, 234, 240, 247], "e": "00000"}}}}
```

La web lo pide solo al abrir la ficha de una sección de ese municipio. Madrid, el mayor, ronda 350 KB comprimido con los indicadores de la v0.1.

Los valores no van dentro de las teselas. Se guardan como estado de cada sección en MapLibre (*feature-state*), y el color sale de una expresión de estilo. Así, cambiar el umbral, la superficie o el sueldo no obliga a descargar nada.

## Diccionarios

En `i18n/es.json` e `i18n/en.json`, las secciones `indicadores`, `fuentes` y `vocabulario` las genera el pipeline desde `inventario/` (`exportar_i18n()`) y no se editan a mano; `sitio`, `nav`, `fichas` y `avisos` se escriben a mano y el pipeline las conserva. La comprobación `i18n_completo` exige las mismas claves en los dos idiomas y ningún texto vacío.

Los textos de la interfaz del esqueleto están, de momento, en `i18n/pendiente_interfaz.json`, con la misma estructura (`es.interfaz…`, `en.interfaz…`). Al pasarlos a una sección `interfaz` de los diccionarios, ese fichero se borra: la web lo usa solo para las claves que falten.

## Estilo

`estilo/tokens.css` lo genera el pipeline desde `diseno/tokens.json`. Incluye las variables de color, la rampa con contorno en los tramos claros, las fichas, las tipografías y las formas, y las clases `.tramo-N`, `.secreto`, `.muestra-pequena` y `.cabecera-carta`. En el mapa, los tramos 1 y 2 no llegan a 3:1 sobre la crema; por eso todas las secciones llevan contorno de tinta. Nada de elementos propios de Monopoly (plan, §10.2).

## Librerías (`vendor/`)

| Librería | Versión | Ficheros | Licencia |
|---|---|---|---|
| MapLibre GL JS | 6.15.0 (18-oct-2026) | `maplibre-gl.mjs`, `maplibre-gl-worker.mjs`, `maplibre-gl.css` | BSD-3 (`LICENSE.txt`) |
| PMTiles | 4.5.0 (10-ago-2026) | `pmtiles.js` | BSD-3 (`LICENSE`) |

Se bajaron de jsDelivr (paquetes de npm, carpeta `dist/`). Para actualizarlas, se sustituyen los ficheros por los de la nueva versión, se cambia esta tabla y se prueba en local. d3 entrará cuando haga falta un gráfico.

## Pruebas

```bash
node --test pruebas/web/datos.test.mjs
```

Comprueban, con datos inventados, el formato de los valores y las fórmulas. También comprueban que la muestra que escribe R se lee entera desde JavaScript y que las series de la ficha cuadran, año a año, con los valores del mapa. Queda para F2 la prueba en navegador con `chromote`: la página recalcula una muestra de cifras y deben coincidir con R (plan, §6.5).

## Publicación

GitHub Pages sirve esta carpeta tal cual, con los rangos HTTP que pide el PMTiles. El PMTiles no entra en git y se añade al publicar. El flujo de publicación está pendiente.
