# Guía de trabajo · reglas del proyecto

Atlas web de vivienda y salarios por sección censal, con fichas de perfil («para quién»), un cálculo con el sueldo de cada usuario y una sección europea de sobrecarga por gastos de vivienda. Proyecto personal. Nombre: *De renta en renta*, sin traducir; sin dominio propio (GitHub Pages) y sin registro de marca (proyecto abierto y no comercial).

Lectura recomendada antes de tocar nada, en este orden:
1. Esta guía (reglas).
2. `docs/backlog_f0.md` (qué toca ahora y cuándo está hecho).
3. `docs/plan_integracion_atlas.md` (plan v0.33: fuente de verdad de las decisiones).

## Estado (9 de noviembre de 2026)

- v0.1 publicada (9-nov-2026): web en <https://gastiaso.github.io/de-renta-en-renta/>, datos en el release `v0.1.0` de GitHub (`docs/publicacion.md`).
- F3 en marcha (9-nov-2026): tartera de 2015 a 2026 y transistor, indicadores 4–6 del ADRH, página «Datos» y nombres del IGN en el suelo sin sección (backlog, tareas 20–23); todavía sin release con estos datos.
- Hechas las tareas 0 (entorno y git), 1 (SERPAVI por sección censal), 3 y 4 (comprobaciones e inventario de fuentes), 5 (sobrecarga con la ECV, compuerta superada) y 6 (geografía constante: probada en Madrid y extendida a toda España, con los catastros forales de País Vasco y Navarra). Detalle en el backlog.
- F2 en marcha (8-nov-2026): indicadores 1–3, 8, 9, 14, 15 (control), 18, 19 y 21 en la tabla larga; jerarquía y mapa base en PMTiles; datos de la web exportados desde el pipeline; web en local con «Tu sueldo», comparador, buscador, barra de la vista, descargas CSV y PNG y la sección «Sobrecarga»; publicación en Pages preparada (`docs/publicacion.md`), sin remoto; nota metodológica en castellano e inglés (`docs/metodologia.md`, `docs/methodology.md`). Detalle en el backlog, al final.

## Forma de trabajo

- Todo en español: código, comentarios, nombres de funciones y de ficheros, documentación. Textos visibles en castellano e inglés desde el principio (`web/i18n/`).
- Textos de fichas, metodología y web: registro impersonal, densos, sin valoraciones ni recomendaciones.
- Todo es provisional. Lo que se decida se anota en el plan (subiendo su versión) o en `CHANGELOG.md`, en la misma tanda que el cambio.
- Mensajes de commit en castellano. Remoto en GitHub: `gastiaso/de-renta-en-renta`, público desde el 9-nov-2026 (decisión del autor), con el correo `noreply` de GitHub en los commits.
- La nota metodológica tiene dos versiones, `docs/metodologia.md` y `docs/methodology.md`: se cambian a la vez (`test-metodologia.R` comprueba que citan lo mismo y dan las mismas cifras).

## Orden de trabajo

F0 → en paralelo **F1b** (sobrecarga y Europa: publicable pronto, no depende de la geografía constante) y una **prueba de F1** (geografía constante: el mayor riesgo del proyecto) → F2 (v0.1) → F3 → F4 → F5 → F6. La web (`web/`) no se toca hasta F2, salvo pasar el kit de diseño a variables CSS.

## Reglas que no se rompen

1. **Nivel nativo.** Cada indicador en la escala en que lo publica su fuente. Nunca se desagrega hacia abajo. Hacia arriba, solo si es aritméticamente válido: medias ponderadas sí; medianas e índices no (se toma la cifra publicada).
2. **Geografía constante.** Las series se reproyectan al seccionado de referencia, el del Censo 2021 (1 de enero de 2021), con tablas de paso documentadas: callejero donde las secciones caen enteras y viviendas del Catastro donde hay que repartir. Lo reproyectado lleva estado: `dato` si las secciones de origen caen enteras en la de 2021, `estimado` si alguna se reparte; las medianas, `dato` solo 1:1, `estimado` desde un origen dominante (≥ 95 % de los portales) y `ausente` si ninguno domina (plan, §6.3).
3. **Compuerta.** No se publica nada que no reproduzca las cifras de la fuente: `inventario/referencias_validacion.csv`. Las de tipo `bloqueo` paran el pipeline; las de tipo `alerta`, avisan.
4. **Mismo año** en numerador y denominador. Si no es posible, se dice en la ficha y en la web.
5. **Cada fuente dice qué mide.** Contratos declarados (SERPAVI), escrituras (Notariado), tasación (MIVAU) y oferta (portales) no se mezclan en un mismo indicador.
6. **Portales.** La capa es desmontable: `PORTALES` vale `FALSE` por defecto (variable de entorno). Solo informes agregados de las salas de prensa; nunca anuncios. Sus datos brutos no entran en git.
7. **Decisiones en CSV, no en código:** fuentes, indicadores, rupturas, tablas de paso y referencias de validación viven en `inventario/`.
8. **Ingresos de las fichas en neto mensual repartido en 12** (plan, §3.1). Las fichas de una persona buscan 50 m²; la llave paga el alquiler mediano de su sección.
9. **Las maquetas llevan valores inventados.** Nunca se copian como datos. Solo dos cifras de las maquetas son reales: el SMI neto de 2026 y los tres porcentajes del módulo de acceso de la ECV 2025.

## Convenciones técnicas

- **Pipeline:** R con `targets` (`_targets.R`). Funciones en `R/`, una por fuente y paso: `descargar_<fuente>()`, `leer_<fuente>()`, `armonizar_<fuente>()`. Comunes: `geo_*()`, `validar_*()`, `exportar_*()`. Los identificadores de fuente son los de `inventario/fuentes.csv`.
- **Descargas** con `httr2` y caché en `datos/brutos/`. Si una descarga falla, se conserva la versión anterior y se avisa. Ficheros manuales: el proceso se detiene e indica la página de descarga y el nombre con el que guardarlo en `datos/brutos/`.
- **Modelo de datos:** una tabla larga en Parquet (`arrow`): `geo_id | nivel | anio | indicador | corte | grupo | valor | estado | fuente | geo_ref | version`. `estado` ∈ {dato, secreto, ausente, estimado}. `corte` y `grupo` guardan los desgloses (tenencia, edad, sexo) con los códigos de `inventario/vocabulario.csv`; sin desglose, las dos valen `total`. Los cruces que agrupan varias olas de una encuesta llevan en `anio` la última.
- **Códigos territoriales** como texto con ceros a la izquierda. Sección censal: 10 dígitos (provincia 2, municipio 3, distrito 2, sección 3).
- **Redondeo:** `as.numeric(sprintf("%.1f", x))`, no `round()` (R redondea al par en los empates y descuadra ±0,1 respecto a las cifras publicadas). La tabla larga guarda la precisión de la fuente; los derivados se calculan desde sus términos ya redondeados, como los recibe la web (`termino_publicado()`), para que la página y R coincidan.
- **Pruebas:** `testthat` en `pruebas/testthat/`. Ejecutar con `testthat::test_dir("pruebas/testthat")`.
- **Teselas:** PMTiles con GDAL desde R (`generar_pmtiles()`, en `targets`); no hace falta tippecanoe. Para verlas en local, `node geo/visor/servir.mjs`; la web, con `node web/servir.mjs`.
- **Credenciales:** nunca en el repositorio (`.Renviron` está en `.gitignore`).
- **Código reaprovechado** de proyectos anteriores: lleva en la cabecera la fecha de incorporación y se anota en `CHANGELOG.md`.

## Datos

- `datos/brutos/` y `datos/intermedios/`: fuera de git. Se regeneran con el pipeline.
- Lo publicado (solo derivados que han pasado la compuerta) sale en un release de GitHub, desde `publicacion/` (`empaquetar_publicacion()`, fuera de git; `docs/publicacion.md`). Ojo con los límites de GitHub: 100 MB por fichero en el sitio, 1 GB por sitio de Pages.
- No se copian datos en bloque de otras carpetas: el pipeline descarga de la fuente para que todo sea reproducible. Excepción documentada: ficheros que la fuente no deja descargar de forma automática.

## Identidad

Tablero (*De renta en renta*): `diseno/tokens.json` (colores con contrastes calculados, tipografías libres, formas), `web/estilo/tokens.css` (generado) y `diseno/fichas/*.svg` (cinco fichas). Nada de elementos propios de Monopoly. Maquetas: `docs/maquetas.md`.

## Cómo verificar

```r
renv::restore()                           # solo la primera vez (R 4.6)
targets::tar_make()                       # descarga, calcula y pasa las compuertas
testthat::test_dir("pruebas/testthat")    # pruebas con datos inventados
targets::tar_outdated()                   # debe salir vacío
```

`tar_make()` se detiene si falla una comprobación de tipo `bloqueo` de `inventario/referencias_validacion.csv`; las de tipo `alerta` salen como avisos al final (hoy, con toda España: geometrías NUTS de códigos agrupados; 579 cifras municipales del ADRH a más de ±1 % de sus secciones agregadas; 160 municipios y años donde el ADRH no suma sus secciones; nueve secciones huérfanas del ADRH; 98 cifras municipales de la distribución de la renta (4–6) a más de 1 punto de la publicada; seis casos de dos secciones con un defecto conocido de cobertura, 164 cifras de municipios y distritos del SERPAVI que no cuadran con sus secciones; 40 secciones, 36 distritos y 36 municipios del seccionado de 2021 que la base del SERPAVI no trae; 23 cifras derivadas fuera del rango habitual, 28 filas de municipio sin hueco en el índice de la web y 95 huecos del seccionado de 2021, 1.495 km² de suelo sin sección, 57 de ellos y 1.176,5 km² con nombre del IGN). Una pasada completa desde cero tarda unas tres horas y cuarto; `PROVINCIA=28` la limita a una provincia. Para ver una compuerta: `targets::tar_read(validacion_sobrecarga)` (o `validacion_f1`, `validacion_adrh`, `validacion_adrh_distribucion`, `validacion_modulo`, `validacion_fiabilidad`, `validacion_smi`, `validacion_inss`, `validacion_transistor`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`, `validacion_serpavi`, `validacion_censo2021`, `validacion_vut`, `validacion_jerarquia`, `validacion_mapa_base`, `validacion_derivados`, `validacion_web`, `validacion_web_sobrecarga`, `validacion_quintil`). Pruebas de la web: `node --test pruebas/web/datos.test.mjs`. Datos de la web: `targets::tar_make(names = c(ficheros_web, validacion_web, ficheros_web_sobrecarga, validacion_web_sobrecarga))` y `node web/servir.mjs`; pruebas de la sección de sobrecarga: `node --test pruebas/web/sobrecarga.test.mjs`. Publicación: `empaquetar_publicacion()` y `docs/publicacion.md`.
