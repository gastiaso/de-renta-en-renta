# Especificación · contratos y margen del alquiler

*Encargo de F2. Decisión del autor del 9-nov-2026: preguntas abiertas 12 y 15, ampliadas (plan v0.29, §11). Provisional, como todo el plan.*

**Estado: hecho (9-nov-2026; plan v0.31, backlog, tarea 19).** El margen se guarda como dos indicadores auxiliares (`margen_alquiler_mes` y `margen_alquiler_m2`), sin cambiar el esquema de la tabla larga. `margen_rango` solo se comprueba en las secciones: por encima, el margen baja de forma natural del 1 %. En los datos no hay secciones con mediana y menos de 10 contratos (abajo se citan 118): los únicos casos de la base son siete municipios de vivienda unifamiliar de 2022, que ya van como `ausente`. Detalle y cifras: `docs/metodologia.md`, §7.6.

## Por qué

**Cobertura (pregunta 12).** En 2024, la vivienda colectiva tiene mediana en 26.137 de las 36.293 secciones. De las 10.156 restantes, solo 2.598 tienen mediana de la unifamiliar: mezclar tipologías apenas ganaría cobertura y rompería el precio por m² de un piso de 50 m². Se mantiene la colectiva. El hueco es sobre todo rural: en los 5.830 municipios de una sola sección, 662 tienen colectiva y 549 más, solo unifamiliar.

**Qué hay detrás de `ausente` (pregunta 12).** En la hoja de secciones del SERPAVI de 2024 (colectiva), de las 5.307 secciones sin dato, 3.630 traen un recuento de **0 contratos** y 1.677 vienen vacías. Son cosas distintas: «no hay pisos alquilados registrados» frente a «la fuente no da cifra». Las 4.849 en `secreto` tienen de 1 a 9 contratos (118 de ellas, con una mediana publicada que la fuente no debía dar).

**Fiabilidad (pregunta 15).** `estado` dice si hay cifra, no si es fiable. De las 26.137 medianas de la colectiva de 2024, 2.360 (9,0 %) salen de 10 a 19 contratos y 2.047 (7,8 %) de 20 a 29; la mediana es de 72 contratos. Con la dispersión que publica la fuente (el recorrido intercuartílico es, en la sección típica, un 40 % de la mediana), el error típico de una mediana ronda el ±12 % con 10 contratos y el ±7 % con 30. En «¿te llega?», un ±12 % sobre un sueldo necesario de 2.300 € son unos 280 €: la respuesta puede cambiar por ruido.

## Qué se hace

### 1. Contratos en la tabla larga

- Indicador auxiliar `contratos_alquiler`: recuento de testigos del SERPAVI (`BI_ALVHEPCO_T{VC,VU}_aa`), con `corte = "tipologia"` y `grupo` VC o VU, por año y nivel (de sección a comunidad).
- Estados: `dato` cuando la fuente publica un recuento, **0 incluido**; `ausente` cuando la celda viene vacía o la fila falta (pregunta 26).
- Catálogo: fila en `inventario/indicadores.csv` marcada como auxiliar, fuera de los 23 (ajustar `test-inventario.R`, que cuenta 23). No tiene mapa propio: va a la ficha y al CSV.

### 2. Margen de la mediana

- `margen_mediana(p25, p50, p75, n)`: error típico relativo de la mediana, en %, ≈ 0,929 × (p75 − p25) / (p50 × √n). Sale de 1,2533 × σ / √n con σ ≈ (p75 − p25) / 1,349.
- Con los cuartiles del alquiler por m² para el 9, el 21 y el 15; con los del alquiler mensual para el 8 y el 14. Solo donde hay mediana (n ≥ 10); si no, `NA`.
- Forma de guardarlo, a elegir con el menor cambio de esquema: indicador auxiliar `margen_alquiler` o campo de la exportación web. Requisito: R y la web usan la misma cifra redondeada a un decimal (pregunta 19).
- Es una aproximación: supone una distribución regular dentro de la sección y no corrige el sesgo de la fuente (contratos vigentes, no nuevos). Se dice así en la nota metodológica.

### 3. Estado de la barrera (15)

- El estado del 15 es el del alquiler. El ingreso de la ficha solo aporta `ausente` cuando falta (mochila en los territorios forales, Ceuta y Melilla).
- En `perfiles_fichas()`, la mochila pasa a `estimado` (el método B es una estimación) y `calcular_barrera_acceso()` deja de heredar ese estado. La calidad del ingreso se explica una vez, en el método de la ficha.
- Comprobar que `perfiles_web()`, `comprobar_web()` y la web dan lo mismo que antes, salvo la etiqueta de la mochila en `perfiles.json`.

### 4. Ficha de sección (web)

- **Fiabilidad**, bajo la cifra: «Mediana de N contratos · margen aproximado ±X %». Con menos de 30 contratos (`UMBRAL_POCOS_CONTRATOS`, en código y documentado), marca «pocos contratos».
- **«¿Te llega?»**: los tres tramos (hasta el 30 %, del 30 al 40 %, más del 40 %) no cambian. Si el intervalo cifra ± margen cruza el límite de un tramo, la ficha añade «en el límite entre dos tramos». Es la respuesta «justo» decidida el 9-nov, adaptada a los tres tramos que ya existen; vale también para «Tu ficha» y para el umbral cambiado al 40 %.
- **Sueldo necesario**: además de la cifra, el intervalo («entre A y B €»).
- **Sin mediana de la colectiva**:
  - con 0 contratos, «Sin contratos de alquiler de pisos registrados» en lugar de «Sin dato»;
  - contexto, rotulado como tal y nunca pintado en el mapa (regla 1): la mediana de la unifamiliar de la sección, si existe, y la de la colectiva del municipio.
- **Mapa**: sin textura nueva, porque la rayada ya es el secreto. Atenuar las secciones con pocos contratos solo si una prueba visual lo justifica; si no, la marca se queda en la ficha y en el CSV.

### 5. Descargas

CSV de secciones: columnas `contratos` y `margen_pct`.

### 6. Textos

- `web/i18n/es.json` y `en.json`: contratos, margen, pocos contratos, en el límite, sin contratos de pisos, contexto.
- `docs/metodologia.md` y `docs/methodology.md`: apartado «Fiabilidad de las medianas del alquiler», con la fórmula, la aproximación y las cifras de 2024.

## Compuerta (`inventario/referencias_validacion.csv`)

| Id | Tipo | Comprueba |
|---|---|---|
| `contratos_mediana` | bloqueo | Sobre la tabla larga: con mediana publicada, 10 o más contratos; en `secreto`, de 1 a 9; en `ausente`, 0 o sin recuento. Reutiliza la lógica de `secreto_roto` |
| `contratos_suma` | bloqueo | Contratos de las secciones = provincia y España (como `serpavi_provincia` y `serpavi_espana`, ahora sobre la tabla larga) |
| `margen_rango` | alerta | Margen fuera de 1–40 % |
| `web_valores` (ampliada) | bloqueo | Contratos y margen escritos para la web = tabla larga (ida y vuelta) |

## Pruebas

- R: `margen_mediana(8, 10, 12, 10)` = 11,8 %; `NA` con n < 10 o sin cuartiles.
- R: barrera de la mochila con ingreso `estimado` y alquiler `dato` → `dato`; con ingreso ausente → `ausente`.
- Web (node): «en el límite» a los dos lados del 30 % y del 40 %, también con el umbral cambiado; ficha de una sección con 0 contratos; la página y R coinciden en contratos y margen.

## Hecho cuando

- La tabla larga trae contratos y margen de la colectiva y la unifamiliar en todos los niveles y años, y pasan las compuertas nuevas.
- La ficha muestra contratos, margen, «pocos contratos», «en el límite», «sin contratos de pisos» y el contexto, en castellano e inglés.
- La nota metodológica, en los dos idiomas, explica la aproximación.
