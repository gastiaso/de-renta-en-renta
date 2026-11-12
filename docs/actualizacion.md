# Actualización de las fuentes

El atlas se actualiza en local con `targets`. El calendario de fuentes (`inventario/calendario_fuentes.csv`, una fila por fuente del pipeline) dice cuándo es esperable una edición nueva de cada una; las funciones están en `R/calendario_fuentes.R`. Nada se ejecuta solo ni en el repositorio remoto: cada paso lo lanza el autor desde R, en la raíz del proyecto.

## El calendario

| Columna | Contenido |
|---|---|
| `cadencia` | `mensual`, `trimestral`, `semestral`, `anual`, `decenal`, `unica` o `continua` |
| `meses_publicacion`, `dia_publicacion` | Meses (`1-7;9-12`) y día habituales de publicación; vacíos si la fuente no se renueva con el calendario |
| `desfase_dias` | Días entre el final de un periodo y su publicación (negativo si se publica antes de que acabe, como el barómetro del CIS) |
| `meses_dato` | Meses con dato, en las series mensuales o semestrales que no tienen todos (el CIS no hace barómetro en agosto) |
| `ultimo_dato` | Último periodo que tiene el atlas: `AAAA`, `AAAA-Tn` o `AAAA-MM` |
| `url_calendario` | Calendario oficial, donde lo hay (INE, Eurostat, Banco de España, CIS) |
| `objetivos`, `ficheros` | Objetivos de `targets` que la descargan y sus ficheros en `datos/brutos/` |
| `renovar` | `mover`, `invalidar`, `codigo`, `manual` o `fija` (abajo) |
| `cambio_codigo` | Qué constante de `_targets.R` cambia con un periodo nuevo |

Una fuente **toca** cuando desde su última descarga (el fichero más reciente) ha pasado una fecha de publicación esperable (`edicion_nueva`) o cuando, a la fecha de hoy, ya debería estar publicado un periodo posterior a `ultimo_dato` (`dato_nuevo`). Las de tipo `fija` (geometrías, tablas de paso, censo) no tocan nunca.

## 1. Ver qué toca

```r
targets::tar_load_globals()                       # funciones de R/ y constantes de _targets.R
cal_fuentes_pendientes(cal_leer_calendario())     # una fila por fuente; columna «toca»
targets::tar_outdated()                           # «fuentes_pendientes» si ha cambiado lo que toca
```

El objetivo `fuentes_pendientes` se vuelve a ejecutar cada vez que cambia el conjunto de fuentes que tocan (su señal se evalúa al leer `_targets.R`): `targets::tar_make()` avisa entonces con la lista, la forma de renovar cada fuente y la orden para hacerlo, y la deja en `datos/intermedios/calendario/pendientes.csv`.

## 2. Renovar

| `renovar` | Qué hacer |
|---|---|
| `mover` | La edición nueva reescribe los mismos ficheros. `cal_actualizar()` los aparta a `datos/brutos/_anteriores/<fecha>/`; sus objetivos de descarga quedan desactualizados y el siguiente `tar_make()` los vuelve a bajar |
| `invalidar` | El objetivo de descarga busca lo nuevo al volver a ejecutarse. El del CIS (`cis_estudios`) lo hace solo cuando toca; a mano, `cal_actualizar("cis_barometros", ejecutar = TRUE)` |
| `codigo` | Un año o un periodo nuevos: cambiar la constante que dice `cambio_codigo` en `_targets.R` |
| `manual` | Descarga a mano, como indica la columna `acceso` de `inventario/fuentes.csv` |

```r
cal_actualizar()                                  # plan de las que tocan, sin ejecutar nada
cal_actualizar(c("ine_ipva", "ine_hipotecas"), ejecutar = TRUE)
targets::tar_make()                               # descarga, compuertas, tablas y web
```

El IPC (`ine_ipc`) mueve el año base de los euros constantes de la web: cuando el INE publica en enero la media anual del año anterior, el siguiente `tar_make()` la recoge, el año base pasa a ese año (`ipc_anio_base()`) y la Máquina del tiempo y la evolución de la ficha cambian sus cifras en euros del año base. Las cifras de la nota metodológica en euros de 2025 se rehacen entonces. Cuando el INE cambie de base, cambia también el número de la tabla (`TABLA_IPC`, `R/fuente_ine_ipc.R`).

Si una descarga falla, el pipeline se detiene en ese objetivo. Los ficheros apartados vuelven a su sitio con `cal_restaurar("AAAA-MM-DD")` (la fecha de la carpeta de `_anteriores`), que solo devuelve los que no se han vuelto a bajar.

## 3. Comprobar

```r
targets::tar_make()                               # se detiene si falla una compuerta de bloqueo
testthat::test_dir("pruebas/testthat")
targets::tar_outdated()                           # debe salir vacío
```

Las compuertas de cada fuente están en `inventario/referencias_validacion.csv`. Una edición nueva puede mover cifras publicadas que sirven de referencia (notas de prensa, totales): se revisan en la fila de la compuerta y, si cambian, en la nota metodológica.

### Avisos de `tar_make()`

`targets` guarda los avisos de cada objetivo en sus metadatos hasta que el objetivo vuelve a ejecutarse; `tar_make()` los resume al final («warnings»). Para verlos:

```r
m <- targets::tar_meta(fields = warnings, complete_only = TRUE)
m[!is.na(m$warnings), ]
```

Revisión de la tarea 55 del backlog (11-nov-2026): 94 objetivos con avisos (93 cuando se abrió la tarea). Los de `modulo_sme_*` y las 56 ramas de `edificios_foral` en coordenadas geográficas se han corregido (abajo); cada uno de los que quedan tiene su motivo:

| Objetivos | Aviso | Por qué se queda |
|---|---|---|
| `edificios_foral`: la rama de Gipuzkoa (`ES.GFA.BU.zip`) | `GDAL Error 1: Could not resolve host: b5mdev` (dos veces) | El GML cita un servidor interno de la Diputación Foral (`b5mdev`) que no se resuelve desde fuera; GDAL lee el fichero igual. Quitarlo también rehace `edificios_foral` |
| `diagnostico_paso_*` y `comparacion_paso_*` (seccionados de 2016, 2017, 2022, 2024 y 2025), `larga_adrh` y `larga_adrh_distribucion` | `N secciones de origen sin tabla de paso: su valor se pierde` | Son las secciones huérfanas del ADRH (nota, §3.8): tienen dato, pero ni el callejero ni el mapa de su año las llevan a 2021. Las cuenta la compuerta |
| `cis_barometros` | `CIS, estudio …: … responde 404` (cinco estudios de 2025) | El CIS no sirve el fichero de esos barómetros. Sus meses quedan sin dato, con las alertas `cis_vivienda_cobertura` de `validacion_cis`; se vuelven a pedir al renovar el CIS |
| `ficheros_cne` | `Descarga cortada (…): se repite` | Una descarga cortada que el pipeline repitió con éxito. Se borra en la siguiente ejecución del objetivo |
| `fuentes_pendientes` | `Calendario de fuentes: tocan N fuentes` | Es el aviso del calendario (apartado 1) |
| `validacion_*` (16 compuertas) | `Alertas de validación: …` | Comprobaciones de tipo `alerta` de `inventario/referencias_validacion.csv`: avisan sin detener el pipeline, y cada una está explicada en la nota (§4.1) y en la guía («Cómo verificar») |

Corregido (11-nov-2026, decisión del autor): las 56 ramas de `edificios_foral` de Bizkaia (33) y Navarra (23) daban `st_point_on_surface may not give correct results for longitude/latitude data`. Sus GML vienen en ETRS89 geográficas (EPSG:4258) y el punto dentro de cada edificio se calculaba en grados, como si fueran metros. `leer_catastro_foral()` usa ahora `punto_interior()` (`R/fuente_catastro_foral.R`), que proyecta a ETRS89 / UTM 30N antes de tomar el punto. Rehízo `edificios_foral` (7 min 45 s), `edificios_forales`, `edificios_paso` y las diez `paso_catastro_*` (unos 13 min): los puntos se mueven dentro de su huella, pero ninguno de los 131.335 edificios forales con viviendas cambia de sección de 2021 y las diez tablas de paso salen idénticas (mismo hash), así que nada de lo que cuelga de ellas se rehízo y las compuertas de F1 y de las tablas de paso quedan como estaban (`cierre_poblacional`, 1,5 × 10⁻¹⁴ % como máximo; `cobertura_destino`, 0). Sin el Catastro estatal (`zips_catastro`, `edificios_municipio`). Queda el aviso de Gipuzkoa (`b5mdev`).

Corregido: `modulo_sme_2019` a `modulo_sme_2024` daban `NAs introducidos por coerción`. Las cabeceras de grupo de las tablas del recorrido y de los centiles del SME llevan la sangría en píxeles (`margin-left: 10px`) y `aeat_sangria()` solo la leía en em. Ahora devuelve NA sin aviso, como antes pero en silencio: esas filas no usan la sangría y las tablas que salen no cambian.

## 4. Anotar

- `inventario/calendario_fuentes.csv`: `ultimo_dato` de la fuente renovada (y el día o el mes de publicación, si han cambiado).
- `inventario/fuentes.csv`: `periodo` y, si hace falta, `notas` (edición leída y fecha).
- `CHANGELOG.md` y, si cambian cifras citadas, `docs/metodologia.md` y `docs/methodology.md` a la vez.

## 5. Publicar

La publicación (release y sitio) sigue `docs/publicacion.md` y la decide el autor: hasta la v1.0 no hay releases intermedios.
