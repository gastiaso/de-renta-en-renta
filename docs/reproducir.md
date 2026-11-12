# Reproducir en limpio

Cómo rehacer el atlas desde cero, en una copia limpia del repositorio y sin nada de `datos/` ni de `_targets/` (backlog, tarea 58). Preparada el 12-nov-2026 sobre la v1.1.0; la prueba no se ha hecho todavía. Lo que falle se anota en la tarea 58.

## Qué hace falta

| Requisito | Detalle |
|---|---|
| R 4.6.1 | La versión de `renv.lock`. En Windows, Rtools 4.6 solo si algún paquete no tiene binario y hay que compilarlo |
| `renv` | `renv::restore()` instala las versiones de `renv.lock`. En un equipo que ya tiene el proyecto, `renv` reutiliza su caché global y apenas descarga: para probar también la instalación, se apunta `RENV_PATHS_CACHE` a una carpeta vacía (abajo) |
| GDAL ≥ 3.8 con el controlador PMTiles | El mapa base sale de `sf::gdal_utils()` (`generar_pmtiles()`). El binario de `sf` para Windows trae el suyo (GDAL 3.12.1 el 12-nov-2026); se comprueba con `"PMTiles" %in% sf::st_drivers()$name` |
| Node 18 o posterior | Pruebas de la web y `web/servir.mjs`, sin paquetes. El flujo de pruebas de GitHub usa Node 24, que además expande el comodín de `node --test "pruebas/web/*.test.mjs"` |
| git | Para clonar y para el último paso de la comprobación |
| Espacio en disco | Unos 12 GB: `datos/brutos/` 9,6 GB, `_targets/` 1,2 GB, `datos/intermedios/` 0,5 GB, `renv/library/` 0,4 GB y `web/datos/` 0,1 GB (medido el 12-nov-2026). Conviene dejar 20 GB libres: las descargas se escriben primero en un `.parcial` y el mapa base pasa por un GeoPackage temporal |
| Memoria | 16 GB, sin otras sesiones de R pesadas a la vez. El pipeline carga cada objetivo y lo suelta al acabar (`memory = "transient"`): los objetos geográficos de toda España no caben a la vez |
| Conexión | Unos 9,6 GB de descargas desde cero; con `PROVINCIA=28`, unos 5,7 GB (abajo) |

## Qué se descarga

`datos/brutos/` tiene tres clases de ficheros. La lista de las descargas manuales y de los ficheros que vinieron de fuera del pipeline está en `inventario/descargas_manuales.csv`; la del resto, en la columna `ficheros` de `inventario/calendario_fuentes.csv`. `brutos_informe()` (`R/brutos_comprobar.R`) las mira las dos y dice qué falta antes de lanzar `tar_make()`, sin descargar nada.

### Descargas manuales

Si falta alguna, `tar_make()` se detiene en su objetivo y dice qué bajar y con qué nombre guardarlo.

| Fichero en `datos/brutos/` | Página | Tamaño | Por qué es manual |
|---|---|---|---|
| `mivau_serpavi/bd_serpavi_2011-2024.xlsx` | <https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi>, base de datos 2011–2024 | 71,2 MB | La web del MIVAU responde a las descargas automáticas con una página de bloqueo, y el nombre del Excel cambia en cada edición. El año del nombre es `ULTIMO_ANIO_SERPAVI` de `_targets.R` |
| `registradores/RP_ComprvResid_2007-2t2026.csv` | <https://opendata.registradores.org/dataset/dataset/compraventas-de-inmuebles-uso-residencial-por-provincia> | 0,6 MB | El servidor rechaza los clientes que no son un navegador. Se guarda con el nombre que trae: el último trimestre publicado va en él. Con `PROVINCIA` no se lee |
| `ign_au/territorios_53.geojson` y `ign_au/territorios_54.geojson` | WFS INSPIRE del IGN, <https://www.ign.es/wfs-inspire/unidades-administrativas> | 1,1 y 0,3 MB | GetFeature (WFS 2.0.0) de `au:AdministrativeUnit` en GeoJSON, solo con 53 (condominios, 81 unidades) o 54 (territorios que no son de ninguna provincia, 7) en las posiciones 7 y 8 del código nacional (`nationalCode`). La consulta no está en el código: se bajó una vez, el 9-nov-2026 |
| `portales/idealista/alquiler_historico_AAAA-MM.csv` y `alquiler_zonas_AAAA-MM.csv` | Informes de precios de la sala de prensa de Idealista | 19 MB | Solo con `PORTALES=TRUE`; nunca entran en git ni en el release (guía, regla 6). Sin la capa, no hacen falta |

### Ficheros que vinieron de fuera del pipeline

En el equipo del autor, estos ficheros no los bajó el pipeline, pero el pipeline sabe bajarlos: si faltan, los descarga de la fuente.

| Fichero en `datos/brutos/` | Fuente | Tamaño | Si falta |
|---|---|---|---|
| `ine_ecv/2025/esudb25d.csv`, `esudb25h.csv`, `esudb25p.csv` y `esudb25r.csv` | <https://www.ine.es/ftp/microdatos/ecv/ecv_b2013/datos_2025.zip> | 70,9 MB | `obtener_csv_ine_ecv()` baja el zip (unos 76 MB) a `datos/brutos/ine_ecv/` y saca los CSV a `datos/intermedios/ine_ecv/2025/` |
| `ine_seccionado/seccionado_2025.zip` | <https://www.ine.es/prodyser/cartografia/seccionado_2025.zip> | 60,3 MB | `descargar_ine_seccionado(2025)` lo baja; es el mismo fichero (60.298.555 bytes) |

Los reales decretos del SMI (`boe_smi/`, XML del BOE de 2015 a 2023, 0,2 MB) los baja `descargar_boe_smi()`; no son manuales.

### Descargas automáticas

Las baja `tar_make()` la primera vez y las guarda en `datos/brutos/` (`descargar_con_cache()`: no repite una descarga que ya está). Tamaños del 12-nov-2026, de mayor a menor:

| Fuente (`inventario/fuentes.csv`) | Carpeta | Tamaño | Notas |
|---|---|---|---|
| `catastro_inspire` | `catastro/` | 4,2 GB | 1.421 zips de edificios, uno por municipio, del servicio ATOM del Catastro; solo los municipios que reparte la tabla de paso. Madrid (28): 73 zips, 0,36 GB |
| `ine_adrh` | `ine_adrh/` | 3,0 GB | Tablas de toda España aunque se pida una provincia; la 30829, sola, 1,6 GB |
| `ine_seccionado` | `ine_seccionado/` | 0,72 GB | Once seccionados, de 2015 a 2025 |
| `ine_callejero` | `ine_callejero/` | 0,59 GB | Doce callejeros de enero, de 2012 y de 2015 a 2025 |
| `ine_ecv` | `ine_ecv/` | 0,44 GB | Microdatos de 2016 a 2024 (y el de 2025 si faltan sus CSV) |
| `aeat_mercado_trabajo` | `aeat_mercado/` | 97 MB | 3.220 páginas HTML recorridas desde el mapa de la estadística; el nombre de cada página cambia cada año |
| `ine_censo2011` | `ine_censo2011/` | 70 MB | Indicadores, cartografía y tablas de 2011 |
| `catastro_foral` | `catastro_foral/` | 69 MB | Álava, Bizkaia, Gipuzkoa y Navarra; con `PROVINCIA` de fuera, nada |
| `ine_vut` | `ine_vut/` | 58 MB | |
| `inss_pensiones` | `inss_pensiones/` | 12 MB | 132 Excel mensuales; el enlace de cada uno se saca de la página |
| `ine_cne` | `ine_cne/` | 11 MB | |
| `ine_censo2021` | `ine_censo2021/` | 8 MB | |
| `cis_barometros` | `cis_barometros/` | 6 MB | Cinco estudios de 2025 responden 404: avisan sin parar (`docs/actualizacion.md`) |
| Resto (`mivau_valor_tasado`, `eurostat_nuts`, `ine_ipva`, `bde_*`, `eurostat_ilc_lvho07*`, `boe_smi`, `mivau_transacciones`, `zonas_tensionadas`, `ine_ipc`, `ine_hipotecas`, `ine_ecv_modulo`) | | 11 MB entre todas | |

Las tipografías de la web (`descargar_tipografias()`) están en git, en `web/estilo/fuentes/`: no se descargan.

**Ediciones.** Una copia limpia baja la edición vigente de cada fuente, que puede no ser la de la v1.1.0 (12-nov-2026). Si una fuente ha publicado desde entonces, sus cifras cambian y alguna compuerta puede pararse porque su referencia ya no es la publicada: antes de comparar, `cal_fuentes_pendientes(cal_leer_calendario())` dice cuáles tocan (`docs/actualizacion.md`). Con las manuales pasa lo mismo: si el MIVAU o Registradores ya no sirven la edición del nombre de arriba, la reproducción de la v1.1.0 necesita la copia del fichero que usó.

## Pasos

En PowerShell, en una carpeta con espacio (no dentro de la copia de trabajo):

```powershell
git clone https://github.com/gastiaso/de-renta-en-renta.git de-renta-en-renta-limpio
cd de-renta-en-renta-limpio
```

Para probar también la instalación de los paquetes en el mismo equipo, una caché de `renv` vacía (solo en esa consola):

```powershell
$env:RENV_PATHS_CACHE = "$env:TEMP\renv-cache-limpio"
```

En R (Positron o RStudio, o `R` en esa misma consola), con la carpeta del proyecto como directorio de trabajo:

```r
renv::restore()                                      # paquetes de renv.lock
"PMTiles" %in% sf::st_drivers()$name                 # TRUE
```

Descargas manuales: bajarlas desde su página (tabla de arriba) y guardarlas con su nombre en `datos/brutos/`. Para crear las carpetas y copiar un fichero ya bajado:

```powershell
New-Item -ItemType Directory -Force datos\brutos\mivau_serpavi, datos\brutos\registradores, datos\brutos\ign_au | Out-Null
Copy-Item "$env:USERPROFILE\Downloads\RP_ComprvResid_2007-2t2026.csv" datos\brutos\registradores\
```

Antes de lanzar el pipeline:

```r
source("R/brutos_comprobar.R")
brutos_informe()      # «Lista para tar_make()»: no falta ninguna descarga manual
```

### Pasada corta: Madrid

Una provincia, para ver que el entorno funciona antes de la pasada completa. Las tablas de paso de la provincia llevan su código en el nombre y no se versionan, y la web sale a `datos/intermedios/web_28/`: no toca nada de git. No entran los bloques de compraventa, zonas tensionadas, histórico e historias (sin Registradores, valor tasado ni zonas tensionadas). Aun así baja unos 5,7 GB, porque el ADRH, los seccionados, los callejeros y la ECV son ficheros de toda España; del Catastro, solo Madrid.

```r
Sys.setenv(PROVINCIA = "28")    # targets lo hereda: tar_make() corre en otro proceso de R
targets::tar_make()
targets::tar_outdated()         # vacío
```

### Pasada completa

```r
Sys.unsetenv("PROVINCIA")
brutos_informe()                # con PROVINCIA vacía, Registradores vuelve a hacer falta
targets::tar_make()
```

Rehace lo que dependía del ámbito; las descargas de la pasada corta no se repiten.

## Tiempos

| Paso | Tiempo |
|---|---|
| Pasada completa desde cero | Unas 3 h 30 min. La nota metodológica (§10) da unas tres horas y cuarto de cálculo, sobre todo la lectura de los edificios del Catastro estatal (2 h 16 min), la comparación de límites (21 min) y los catastros forales (unos 17 min); las descargas dependen de la línea |
| Mapa base (`fichero_mapa_base` y su compuerta) | Unos 9 min, dentro de lo anterior |
| Pasada corta con `PROVINCIA=28` | Sin medir. Mucho menos que la completa: del Catastro solo lee Madrid (73 de 1.421 municipios) y no lee los forales. Se anota en la tarea 58 |
| `renv::restore()` con la caché vacía | Sin medir: se anota en la tarea 58 |

## Cómo comprobar el resultado

1. `tar_make()` acaba sin errores. Los avisos que quedan son los de `docs/actualizacion.md` («Avisos de `tar_make()`»), y las alertas de las compuertas, las de la guía («Cómo verificar»): mismas comprobaciones y mismos recuentos. Una compuerta se lee con `targets::tar_read(validacion_<nombre>)`; los avisos, con `targets::tar_meta(fields = warnings, complete_only = TRUE)`.
2. `targets::tar_outdated()` sale vacío.
3. `testthat::test_dir("pruebas/testthat")` en verde.
4. Pruebas de la web: `node --test "pruebas/web/*.test.mjs"` (Node 21 o posterior; con uno anterior, fichero a fichero, `web/LEEME.md`).
5. `git status --short` sale vacío: lo que el pipeline escribe en ficheros versionados (tablas de paso de `geo/`, diccionarios de `docs/` y de `web/i18n/`, `web/estilo/tokens.css`, `web/js/supuestos.js`, las casillas de `web/index.html`) sale idéntico al del repositorio.
6. La tabla larga coincide con la del release `v1.1.0` (`tabla_larga.parquet`) salvo la columna `version`, que es la fecha de cada fichero descargado (`version_de()`) y cambia en una descarga nueva. Vale si el código que calcula no ha cambiado desde la etiqueta: `git diff --stat v1.1.0 -- R _targets.R inventario geo` no lista nada más que lo que no toca cifras (como `R/brutos_comprobar.R` e `inventario/descargas_manuales.csv`).

```r
nueva <- arrow::read_parquet(targets::tar_read(fichero_tabla_larga))
publicada <- arrow::read_parquet("tabla_larga.parquet")   # la del release, bajada a mano
claves <- c("geo_id", "nivel", "anio", "indicador", "corte", "grupo")
ordenar <- function(x) dplyr::arrange(dplyr::select(x, -version), dplyr::across(dplyr::all_of(claves)))
all.equal(ordenar(nueva), ordenar(publicada))
```

Las diferencias se explican por una edición nueva de alguna fuente (arriba, «Ediciones») o se anotan como fallo en la tarea 58.
