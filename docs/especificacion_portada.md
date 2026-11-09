# Especificación · portada (tablero completo)

*Encargo antes de anunciar la web. Decisión del autor del 9-nov-2026: la portada va en la raíz, el mapa pasa a `mapa.html` con redirección de los enlaces ya compartidos, y se hace antes de difundir el sitio. Fuente visual: maqueta de portada del tablero (`docs/maquetas.md`; fuera del repositorio), adaptada a las reglas de abajo. Provisional, como todo el plan.*

## Por qué

- El plan decide «Portada: el tablero completo» (§10.2), pero F2 (§7) describe la web como «mapa, fichas, comparador y descargas» y la portada no pasó al backlog. La raíz publicada (v0.1.0) es el mapa.
- El dicho de portada (`sitio.dicho`, «De renta en renta, y pago porque me toca») está en los diccionarios y no se muestra en ninguna página.
- Es la primera impresión del sitio: lleva la identidad, el «para quién» (las fichas) y «Tu sueldo», que es lo que más se comparte.

## 1. Rutas

- `web/index.html` pasa a ser la portada. El mapa actual se mueve, sin cambios de contenido, a `web/mapa.html`.
- **Redirección** (script en el `<head>` de `index.html`, antes de pintar): si la consulta trae alguna de las claves de `estado.js` (`CLAVES`) o el fragmento trae un sueldo compartido (`#sueldo=…`), `location.replace('mapa.html' + location.search + location.hash)`. Así siguen funcionando los enlaces ya compartidos al mapa.
- **Menús**: «Mapa» apunta a `mapa.html` en todas las páginas (mapa, sobrecarga y plantilla de «Método», `web/herramientas/plantilla_documento.html`); el título del sitio, a la portada. «Tu sueldo» apunta a `mapa.html#tu-sueldo`.
- Revisar todo lo que construye direcciones del mapa: `compartir.js`, `exportar.js` (PNG y CSV), `estado.js`, `sobrecarga.js`. Los enlaces nuevos se generan hacia `mapa.html`.
- `pages.yml` copia `web/` entero: comprobar que `mapa.html` se publica y que la página «Método» lleva el menú nuevo.

## 2. Contenido

### Centro del tablero

- Título, subtítulo (`sitio.subtitulo`), dicho (`sitio.dicho`) y pregunta rectora (`sitio.lema`). Las claves no se renombran; la confusión entre `lema` (la pregunta) y `dicho` (el lema real) se anota en `web/LEEME.md`.
- **«Tu sueldo» (ficha del peón)**: campo de sueldo neto mensual y botón «¿Te llega?», que abre `mapa.html?ficha=peon` con el sueldo en el fragmento, con el mismo formato que «Compartir» (`#sueldo=…&pagas=…&segundo=…`, `estado.js`), que el mapa lee y quita de la barra. El sueldo nunca va en la consulta. Aviso visible: «Tu sueldo no sale de este dispositivo».
- **Buscador**: reutiliza `buscador.js` (municipio o sección) y abre el mapa en el resultado.
- **«Tira el dado»**: abre una sección al azar con `dato` en el último año del mapa por defecto. Sin animación con `prefers-reduced-motion`.
- **Sin el mapa pixelado de la maqueta**: era ilustrativo («no son datos») y en la web pública solo entran cifras reales. Si más adelante se quiere, una rejilla real generada por el pipeline.

### Fichas («¿para quién?»)

Cinco botones con los iconos de `diseno/fichas/*.svg`: llave, mochila, tartera, transistor y peón. Cada uno abre `mapa.html?ficha=<ficha>` en el modo «¿te llega?». El transistor, mientras no tenga datos (F3), aparece desactivado y rotulado «próximamente», como «Datos» en el menú.

### Casillas

- **Tablero de la maqueta**: 7 × 7, con 4 esquinas y 5 casillas por lado (24). Se recorren en el sentido de las agujas del reloj desde la esquina superior izquierda.
- **Decisiones en CSV (regla 7)**: `inventario/casillas_portada.csv`, con `orden`, `id`, `texto_es`, `texto_en`, `familia`, `destino` (ruta relativa o vacío) y `activa` (`TRUE`/`FALSE`).
- **Activas solo donde hay datos o página.** Las demás, texto sin enlace con el título «próximamente». Ningún enlace lleva a una página vacía.
- **Bandas por familia** con la paleta del atlas (`diseno/tokens.json`, contraste ≥ 3:1 sobre el fondo crema) y una leyenda de cuatro familias: ingresos, alquiler, compra y barrio.
- **Nada propio de Monopoly**: ni «Salida» (la esquina de inicio es «Firma el contrato»), ni «La banca», ni «Suerte» o «Caja de comunidad», ni franja diagonal, ni la secuencia de colores de sus grupos.
- **Exactitud de las etiquetas** (la portada no puede contradecir la ley):
  - «Fianza: un mes» (art. 36.1 de la LAU), no «dos meses»;
  - fuera «Agencia: un mes»: desde la Ley 12/2023, los gastos de gestión inmobiliaria y de formalización del contrato corren a cargo del arrendador;
  - «Actualización de la renta» en lugar de «Sube el IPC».

Propuesta (a confirmar por el autor al revisar la portada):

| Orden | Casilla | Familia | Destino | Activa |
|---|---|---|---|---|
| 1 (esquina) | Firma el contrato | alquiler | `mapa.html` (sueldo necesario) | sí |
| 2 | Cobra la nómina | ingresos | `mapa.html#tu-sueldo` | sí |
| 3 | Fianza: un mes | alquiler | `metodo.html#…` (el alquiler sale de las fianzas del SERPAVI) | sí |
| 4 | Paga el alquiler | alquiler | mapa del alquiler mensual | sí |
| 5 | Pisos turísticos en el portal | barrio | mapa de viviendas turísticas (19) | sí |
| 6 | Zona tensionada | barrio | — (F5) | no |
| 7 (esquina) | Renueva el contrato | alquiler | mapa del esfuerzo de residentes (14) | sí |
| 8 | Actualización de la renta | alquiler | — (F4, indicador 10) | no |
| 9 | Vecinos de alquiler | barrio | mapa de hogares en alquiler (18) | sí |
| 10 | Compartir piso | ingresos | `mapa.html?ficha=peon#tu-sueldo` (dos sueldos) | sí |
| 11 | Mudanza | alquiler | comparador (`?comparar=municipio`) | sí |
| 12 | Cobra el salario mínimo | ingresos | `mapa.html?ficha=tartera` | sí |
| 13 (esquina) | Vuelve a casa de tus padres | barrio | `sobrecarga.html` (módulo de acceso, indicador 23) | sí |
| 14 | Ahorra la entrada | compra | — (F4) | no |
| 15 | Aval de tus padres | compra | — (F4) | no |
| 16 | Hipoteca variable | compra | — (F4) | no |
| 17 | Sube el euríbor | compra | — (F4) | no |
| 18 | Comunidad y derramas | barrio | — | no |
| 19 (esquina) | Tasación | compra | — (F4, indicador 12) | no |
| 20 | Notaría | compra | — (F4, indicador 11) | no |
| 21 | Sorteo de vivienda protegida | barrio | — | no |
| 22 | Herencia | compra | — | no |
| 23 | Cobra la pensión | ingresos | `mapa.html?ficha=transistor` (F3) | no |
| 24 | Sobrecarga en Europa | barrio | `sobrecarga.html` | sí |

Los identificadores de los mapas y las anclas de «Método» se toman del manifiesto y de la página generada, no se escriben a mano. La prueba comprueba que existen.

### Cartas del atlas

- Tres cartas, solo con **cifras reales** del pipeline (`portada.json`, abajo), cada una con año, fuente y enlace a su mapa.
- Fuera de esta tanda:
  - las cartas de la maqueta con cifras del Banco de España sin verificar: van con el módulo histórico (F6);
  - la carta de Lizzie Magie: si se quiere, en «Método», con su fuente.
- Registro impersonal. Las comparaciones en el tiempo, solo sobre las mismas secciones: en 2015 había 21.627 con dato y en 2024, 26.137.

Propuesta y valores de referencia actuales, que sirven también para las pruebas:

| Carta | Cifra (tabla larga, 9-nov-2026) |
|---|---|
| Sueldo necesario de la sección mediana (2024; 50 m², 30 %) | 1.217 € netos al mes (percentil 10: 700 €; percentil 90: 2.117 €) |
| Salario mínimo (2024) | el piso de 50 m² pasa del 30 % del SMI neto en el 48,4 % de las secciones con dato, y del 40 % en el 24,7 % |
| Sobrecarga (ECV 2025) | 26,8 % de quienes viven de alquiler a precio de mercado; 7,2 % del total |

Si falta un término, la carta no se muestra (nunca «—» en una carta).

### Pie

Fuentes, fecha de los datos (`version.json`), licencias vigentes (`LICENSE`, `LICENCIA_DATOS.md`) y enlace al repositorio.

## 3. Datos: `portada.json`

- `exportar_portada()` en R, desde la tabla larga y los perfiles, con el redondeo de la guía. Va con los demás datos de la web en el paquete del *release* (`datos_web.tar.gz`).
- Compuerta `portada_valores` (bloqueo): cada cifra de `portada.json`, recalculada desde la tabla larga, coincide.
- `inventario/casillas_portada.csv`: ids únicos, toda casilla activa con destino y toda inactiva sin él.

## 4. Diseño y accesibilidad

- Solo variables de `tokens.css` y las tipografías ya autoalojadas (Jost, Marcellus SC, Archivo Narrow y Yellowtail, con sus licencias en `estilo/fuentes/`).
- **Escritorio**: tablero cuadrado (hasta unos 720 px) y columna lateral con las fichas y las cartas.
- **Móvil** (menos de 700 px): primero el centro (título, dicho, «Tu sueldo», buscador), luego las fichas, las cartas y las casillas como recorrido vertical en el mismo orden. Nada de tablero comprimido.
- **HTML semántico**: las casillas son una lista ordenada (`<ol>`) colocada con CSS grid, no una imagen. Foco visible, navegable con teclado, contraste ≥ 4,5:1 en el texto.
- **Sin JavaScript**: se ven el tablero y los enlaces; las cartas, el buscador y «Tira el dado» lo necesitan.
- **Imagen para redes** (`og:image`, 1200 × 630, generada con `chromote` al empaquetar): segunda tanda, opcional.

## 5. Textos

Claves nuevas `portada.*` en `web/i18n/es.json` y `en.json` (cartas con marcadores para las cifras). Los textos de las casillas salen del CSV. Ningún texto escrito a mano en el HTML o el JS.

## 6. Pruebas

- **R**: `exportar_portada()` con datos de prueba; compuerta `portada_valores`; validez de `casillas_portada.csv`.
- **node**:
  - redirección: un enlace con `?mapa=…` abre `mapa.html` con la misma consulta; uno con `#sueldo=…` conserva el fragmento; sin nada, se queda la portada;
  - destinos de las casillas activas: existen en el manifiesto o en las páginas generadas.
- **Navegador** (`chromote`, `comprobar_web_navegador()` ampliada):
  - la portada carga sin errores, en castellano e inglés;
  - las cartas coinciden con la tabla larga;
  - cada casilla activa abre su destino;
  - «Tu sueldo» llega al mapa sin aparecer en la consulta;
  - a 375 px de ancho no hay desbordes.

## 7. Cambios en el plan y el backlog (los hace quien ejecute el encargo)

- **Plan**: §10.2, «Portada: el tablero completo», con referencia a esta especificación, la ruta (raíz) y el mapa en `mapa.html`. Subir la versión del plan con su línea de cambios.
- **Backlog**: tarea nueva «Portada (tablero completo)», y primera en «Siguiente», antes del SMI de 2015 a 2023, porque va antes de anunciar el sitio.
- **CHANGELOG**: «Decidido (9-nov-2026, portada)».

## Hecho cuando

- La raíz muestra el tablero, en castellano e inglés, en escritorio y en móvil.
- Los enlaces ya compartidos al mapa siguen funcionando.
- Las cartas salen del pipeline y pasan la compuerta.
- Ninguna casilla lleva a una página vacía y ninguna etiqueta contradice la ley vigente.
- No hay elementos propios de Monopoly.
- Se publica con un *release* nuevo (`v0.1.1` o `v0.2.0`, según `docs/publicacion.md`).
