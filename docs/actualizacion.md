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

Si una descarga falla, el pipeline se detiene en ese objetivo. Los ficheros apartados vuelven a su sitio con `cal_restaurar("AAAA-MM-DD")` (la fecha de la carpeta de `_anteriores`), que solo devuelve los que no se han vuelto a bajar.

## 3. Comprobar

```r
targets::tar_make()                               # se detiene si falla una compuerta de bloqueo
testthat::test_dir("pruebas/testthat")
targets::tar_outdated()                           # debe salir vacío
```

Las compuertas de cada fuente están en `inventario/referencias_validacion.csv`. Una edición nueva puede mover cifras publicadas que sirven de referencia (notas de prensa, totales): se revisan en la fila de la compuerta y, si cambian, en la nota metodológica.

## 4. Anotar

- `inventario/calendario_fuentes.csv`: `ultimo_dato` de la fuente renovada (y el día o el mes de publicación, si han cambiado).
- `inventario/fuentes.csv`: `periodo` y, si hace falta, `notas` (edición leída y fecha).
- `CHANGELOG.md` y, si cambian cifras citadas, `docs/metodologia.md` y `docs/methodology.md` a la vez.

## 5. Publicar

La publicación (release y sitio) sigue `docs/publicacion.md` y la decide el autor: hasta la v1.0 no hay releases intermedios.
