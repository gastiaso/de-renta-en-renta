# Publicación en GitHub Pages

Cómo se publica la web (plan §6.6; §11, preguntas abiertas 16 y 21). Comprobado contra la documentación de GitHub el 8-nov-2026.

## Cómo funciona

El sitio se monta en GitHub Actions con el flujo `.github/workflows/pages.yml`. Lo único que lanza un push es otro flujo, el de las pruebas que no necesitan datos (`.github/workflows/pruebas.yml`; backlog, tarea 54; `pruebas/LEEME.md`), que no publica nada. El de Pages solo se lanza a mano y monta el código y la nota de la referencia `ref` (por defecto, el commit de la última publicación) con los datos del último release; un push a `main` no publica nada. Del 9 al 10-nov-2026 el sitio estuvo congelado en la v0.1 (commit `cdd9892`); desde la v0.4.0 (decisión del autor, 10-nov-2026), `ref` es el commit de cada publicación. Junta dos cosas:

| Parte del sitio | De dónde sale | Por qué |
|---|---|---|
| `web/` (HTML, JS, estilo, diccionarios, librerías, muestra de `datos/ejemplo/`) | git | Es código: cambia poco y cada cambio se revisa |
| `datos/` (manifiesto, índices, valores, fichas, perfiles…) | release: `datos_web.tar.gz` | Unos 8.800 ficheros y 92 MB (15,8 MB comprimido); cada actualización los reescribe casi todos y engordaría la historia de git sin aportar nada (pregunta 21) |
| `teselas/seccionado_2021.pmtiles` | release: `seccionado_2021.pmtiles` | 35,3 MB binarios que se regeneran con el pipeline (pregunta 16) |
| `descargas/tabla_larga.parquet` | release: `tabla_larga.parquet` | La tabla larga completa (36,9 MB), para la página «Datos» |
| `descargas/historico.parquet` | release: `historico.parquet` | La tabla del módulo histórico (desde la v1.0; plan §11, pregunta 47 a). El flujo la copia si el release la trae |
| `descargas/version.json` | release: `version.json` | Fecha, commit, versiones de las fuentes, cobertura de la tabla larga por indicador y suma de cada fichero |
| `metodo.html`, `method.html` | git: se generan en el flujo desde `docs/metodologia.md` y `docs/methodology.md` | La página «Método» sale siempre de la nota que hay en `main` |
| `datos.html`, `data.html` | git y release: se generan en el flujo desde `docs/datos.md` y `docs/data.md`, el diccionario de `docs/` y `descargas/version.json` | La página «Datos» describe siempre la tabla larga del release que se publica |

El flujo baja los ficheros del **último release** (el marcado como *Latest*; nunca un borrador ni una versión previa), comprueba sus sumas SHA-256 con `SHA256SUMS`, monta el sitio y lo publica. Las herramientas de desarrollo de `web/` (`LEEME.md`, `servir.mjs`, `herramientas/`) no se publican.

**Página «Método».** El flujo instala pandoc (paquete de Ubuntu; la imagen de GitHub no lo trae) y convierte la nota metodológica en `metodo.html` y `method.html`, con la cabecera de la web (`estilo/documento.css`) y un índice plegable. La plantilla y los textos propios de cada idioma están en `web/herramientas/` (`plantilla_documento.html`, `documento_es.yaml`, `documento_en.yaml`); el título, el subtítulo y los nombres del menú salen de `web/i18n/`. Para verla en local, con pandoc instalado:

```bash
pandoc docs/metodologia.md --from gfm --to html5 --standalone --toc --toc-depth 2 --wrap none --template web/herramientas/plantilla_documento.html --metadata-file web/herramientas/documento_es.yaml --metadata titulo="De renta en renta" --metadata subtitulo="Vivienda y sueldos, sección a sección" --metadata texto_mapa=Mapa --metadata texto_sobrecarga=Sobrecarga --metadata texto_datos=Datos --metadata texto_metodo=Método --output web/metodo.html
```

y abrir <http://localhost:8000/metodo.html> con `node web/servir.mjs`. Ese `web/metodo.html` es una copia local: no se añade a git.

**Página «Datos».** La descarga de la tabla larga, su modelo de datos y su diccionario, las licencias y la cita, y cómo leerla en R y en Python, en `datos.html` y `data.html`. Se monta en el mismo paso que «Método», en dos tiempos:

1. `web/herramientas/pagina_datos.mjs` (Node, sin paquetes; la imagen de GitHub lo trae) parte del texto a mano, `docs/datos.md` o `docs/data.md`, y rellena sus tres marcas: la caja de descarga (tamaño, suma SHA-256, fecha y commit de los datos, y enlace al release) y la cobertura por indicador, desde el `version.json` del release que se publica, y la cita, desde `CITATION.cff`. Le añade al final los valores de las columnas y el diccionario de indicadores, que genera R desde el inventario (`docs/datos_diccionario.md` y `docs/data_dictionary.md`; `exportar_diccionario_datos()`, objetivo `ficheros_diccionario_datos`: no se editan a mano).
2. pandoc lo convierte con la misma plantilla y `documento_<idioma>.yaml`, más `datos_<idioma>.yaml`, que cambia el título y la entrada activa del menú.

El flujo se detiene si la página no enlaza `descargas/tabla_larga.parquet`. La cobertura por indicador entra en `version.json` desde que `empaquetar_publicacion()` la escribe (después del `v0.1.0`): con un release anterior, la página lo dice y sigue sin ella. Para verla en local (PowerShell, con pandoc instalado; la copia de `web/descargas/` queda fuera de git):

```powershell
New-Item -ItemType Directory -Force web/descargas | Out-Null
Copy-Item publicacion/tabla_larga.parquet, publicacion/historico.parquet, publicacion/version.json web/descargas/
node web/herramientas/pagina_datos.mjs --idioma es --nota docs/datos.md --diccionario docs/datos_diccionario.md --version web/descargas/version.json --cita CITATION.cff --salida "$env:TEMP/datos_es.md"
pandoc "$env:TEMP/datos_es.md" --from gfm --to html5 --standalone --toc --toc-depth 2 --wrap none --template web/herramientas/plantilla_documento.html --metadata-file web/herramientas/documento_es.yaml --metadata-file web/herramientas/datos_es.yaml --metadata titulo="De renta en renta" --metadata subtitulo="Vivienda y sueldos, sección a sección" --metadata texto_mapa=Mapa --metadata texto_sobrecarga=Sobrecarga --metadata texto_datos=Datos --metadata texto_metodo=Método --output web/datos.html
```

y abrir <http://localhost:8000/datos.html>. Sin `--etiqueta` ni `--repositorio`, la caja de descarga sale sin enlaces a GitHub; el flujo les pasa los de la ejecución.

- No usa secretos: solo el token que GitHub da a cada ejecución. El trabajo que monta el sitio solo puede leer el repositorio; el que lo publica solo puede escribir en Pages.
- No lleva el nombre del repositorio: funciona igual con cualquier nombre o cuenta.
- La web usa rutas relativas, así que funciona en la dirección de un sitio de proyecto, `https://<cuenta>.github.io/de-renta-en-renta/`.

Los ficheros del release los prepara `empaquetar_publicacion()` (`R/publicar.R`) en `publicacion/`, que está fuera de git. No forma parte de `tar_make()`: se ejecuta a mano cuando se quiere publicar.

## Qué queda fuera de git

| Qué | Dónde se regenera | Cómo se publica |
|---|---|---|
| `datos/brutos/`, `datos/intermedios/` (incluida la tabla larga) | `targets::tar_make()` | La tabla larga, en el release |
| `web/datos/` (salvo la muestra de `web/datos/ejemplo/` y la capa de portales) | `targets::tar_make(names = c(ficheros_web, validacion_web))` | Release |
| `web/datos/portales/` (capa de portales, tarea 35) | `targets::tar_make(names = c(ficheros_web_portales, validacion_web_portales))`, con `PORTALES=TRUE` (apagada, solo el manifiesto vacío) | No va en el release; ver «Capa de portales» |
| `*.pmtiles` (`geo/referencia/`, `web/teselas/`) | `targets::tar_make(names = fichero_mapa_base)` | Release |
| `publicacion/` | `empaquetar_publicacion()` | Es el release |
| `web/metodo.html`, `web/method.html`, `web/datos.html`, `web/data.html`, `web/descargas/` | Copias locales para ver las páginas de texto (pandoc y la copia de `publicacion/`) | Las genera el flujo |
| `_targets/`, `renv/library/` | El pipeline y `renv::restore()` | No se publican |
| `.Renviron` | A mano | Nunca: credenciales |

Las capas de los portales tampoco entran en git ni en el release (guía, regla 6; backlog, decisión 3).

## Capa de portales (tarea 35): propuesta, por revisar

La capa de precios de oferta (indicador 13, alquiler de Idealista) es solo web: no entra en la tabla larga, ni en las descargas, ni en el release. El pipeline la escribe en su carpeta, `web/datos/portales/` (`R/web_portales.R`): manifiesto propio, valores por nivel y año, enlace al informe de cada cifra y zonas por municipio. La web suma sus series al manifiesto general al cargar (`unirCapas()` de `web/js/datos.js`).

**Lo que ya está (10-nov-2026):**
- `empaquetar_publicacion()` deja fuera `datos/portales/` del `.tar.gz` y se detiene si el paquete llevara la capa: comprobación `sin_portales` (ningún fichero de `datos/portales/` en el `.tar.gz`, ninguna serie de los portales en el manifiesto, ninguna fila con la fuente `portales` o el corte `oferta_privada` en la tabla larga). Lo prueba `test-publicar.R`.
- El flujo rechaza un `datos_web.tar.gz` con `datos/portales/` y monta el sitio con la capa apagada: escribe `datos/portales/manifiesto.json` con `{"capa":"portales","activa":false}`, así que la web no pide nada más ni da un error de carga. Con el sitio congelado en la v0.1, ese fichero no lo lee nadie.

**Lo que falta decidir:** cómo llega la capa al sitio. Opciones:
1. Dentro de `datos_web.tar.gz`. Lo más simple, pero la capa quedaría en un fichero público del release, junto a los datos con licencia CC BY-SA 4.0, y `version.json` la contaría como parte del paquete. Choca con la decisión 3: descartada.
2. Un fichero aparte, `portales_web.tar.gz`, en el mismo release o en una etiqueta propia, con su suma. El flujo lo bajaría si está y, si no, dejaría la capa apagada. Sigue siendo una descarga pública de toda la capa de una vez.
3. **Propuesta:** el mismo fichero aparte, en un release en borrador (por ejemplo, `capa-portales`), que no es público: solo lo ven quienes pueden escribir en el repositorio. Para leer un borrador, el token del flujo necesita `contents: write`, así que lo bajaría un trabajo propio con ese permiso, antes del que monta el sitio (que sigue con `contents: read`), y se lo pasaría como artefacto de la ejecución, con un día de vida. Contras: los artefactos de un repositorio público los puede bajar cualquier usuario de GitHub mientras duran, y el flujo gana un trabajo con permiso de escritura. Las cifras se sirven igual en el sitio (cualquiera puede pedir los JSON de `datos/portales/`), pero no quedan en el release público ni en un fichero único.

**Antes de cualquiera de las tres:** las condiciones generales de Idealista (30-abr-2025) piden su autorización escrita para incorporar su contenido a otro sitio web y para enlazar sus páginas en profundidad (fila `portales` de `inventario/fuentes.csv`). Sin esa autorización, ninguna opción resuelve el problema de fondo; con ella, lo que diga decide la forma. Hasta entonces, el sitio de la v1.0 saldría con la capa apagada.

## Antes de la primera publicación: decisiones del autor

1. **Cuándo se crea el repositorio.** Creado el 9-nov-2026. El nombre ya estaba decidido, `gastiaso/de-renta-en-renta` (plan §6.1; backlog, 7-nov-2026), y da la dirección del sitio: `https://gastiaso.github.io/de-renta-en-renta/`. Si cambia, basta con cambiarlo en los comandos de esta guía: el flujo no lleva el nombre.
2. **Visibilidad.** Con GitHub Free, **Pages solo funciona en repositorios públicos**: «If the account that owns the repository uses GitHub Free or GitHub Free for organizations, the repository must be public» (*Creating a GitHub Pages site*, consultada el 8-nov-2026). Con GitHub Pro se puede publicar desde un repositorio privado, pero el sitio es público igualmente: los sitios privados exigen una organización con GitHub Enterprise Cloud (*GitHub's plans*). El plan prevé un repositorio público (§6.1). Decisión del autor (9-nov-2026): público desde su creación.
   - En un repositorio público, los *releases* (datos, mapa base y tabla larga) también son públicos.
   - En un repositorio público, Actions no cuesta nada. En uno privado, el flujo gasta minutos del plan (pocos por publicación: a medir en la primera).
3. **Revisión de privacidad** de todo lo versionado antes de hacer público el repositorio: la historia de git se publica entera. Hecha el 9-nov-2026 (31 commits, todos los ficheros de la historia y el paquete del *release*, con los metadatos del PMTiles y del Parquet): sin rutas locales, enlaces privados, secretos, ficheros de datos en bruto ni metadatos de procedencia en los SVG. El correo de autor de cada commit (`git config user.email`) también se publica: GitHub ofrece una dirección `noreply` (*Settings → Emails → Keep my email addresses private*), que vale para los commits nuevos; los ya hechos solo cambian reescribiendo la historia antes de hacer público el repositorio. Hecho el 9-nov-2026: la historia se reescribió con la dirección `noreply` (`git filter-branch --env-filter`, mismo contenido en cada commit) y se subió a un repositorio recién creado, para que no quedara en GitHub ningún commit con el correo anterior.

## Paso a paso

Hace falta la línea de comandos de GitHub (`gh`), con la sesión iniciada (`gh auth login`). Todo lo que se hace con `gh` se puede hacer también en la web de GitHub; se indica en cada paso.

**Estado (9-nov-2026).** Publicado: release `v0.1.0` (datos del commit `573dbf6`) y sitio en <https://gastiaso.github.io/de-renta-en-renta/>, montado por el flujo. Contra el sitio publicado pasan la prueba en el navegador (seis fichas y 300 secciones en los 10 años, sin errores) y las comprobaciones del paso 5.

### 1. Crear el repositorio y activar Pages

El repositorio ya existe (9-nov-2026): de este paso solo falta activar Pages. Para crearlo de nuevo, desde la carpeta del proyecto:

```bash
gh repo create gastiaso/de-renta-en-renta --public --source . --remote origin
```

En la web: *New repository*, sin README, licencia ni `.gitignore` (ya los tiene el proyecto), y después `git remote add origin https://github.com/gastiaso/de-renta-en-renta.git`.

Después, en la web del repositorio: **Settings → Pages → Build and deployment → Source: GitHub Actions**. No hace falta elegir ninguna plantilla: el flujo ya está en `.github/workflows/pages.yml`.

### 2. Preparar el paquete

En R, desde la raíz del proyecto:

```r
targets::tar_make()                       # pipeline y compuertas, con la exportación de la web
testthat::test_dir("pruebas/testthat")    # pruebas, también la del navegador (test-navegador.R, con chromote)
empaquetar_publicacion()                  # (tras source("R/publicar.R") si no se ha cargado)
```

`empaquetar_publicacion()` escribe en `publicacion/` seis ficheros: `datos_web.tar.gz`, `seccionado_2021.pmtiles`, `tabla_larga.parquet`, `historico.parquet` (tabla del módulo histórico, desde la tarea 46), `version.json` (con las licencias: la general y la ODbL de las filas de Registradores) y `SHA256SUMS`. Se detiene, sin dejar nada a medias, si:

- algún fichero pasa de 2 GiB (límite de GitHub por fichero de un release);
- el sitio montado pasa de 1 GB (límite de Pages) o tiene algún fichero de más de 100 MiB;
- la exportación es la muestra, o el mapa base no es un PMTiles en `teselas/`;
- el PMTiles o el Parquet no tienen la cabecera de su formato;
- el `.tar.gz` no lleva exactamente los ficheros de `web/datos/` (sin la muestra);
- la exportación de la web y la tabla larga son de pasadas distintas del pipeline (fuentes con otra versión);
- el paquete llevaría la capa de portales (`sin_portales`; ver «Capa de portales»).

Avisa, y lo anota en `version.json`, si hay cambios sin commit. `version.json` lleva también la cobertura de la tabla larga por indicador (filas, primer y último año, niveles y cortes, en el orden de `inventario/indicadores.csv`; `cobertura_publicacion()`), que muestra la página «Datos».

### 3. Subir el código

```bash
git push -u origin main
```

El push lanza el flujo. Si todavía no hay ningún release, falla en «Bajar los ficheros del último release» con el aviso «No hay ningún release publicado». Es lo esperado la primera vez: se vuelve a lanzar en el paso 5.

### 4. Crear el release

```bash
gh release create v0.1.0 publicacion/* --target main --latest --title "v0.1.0" --notes "Datos de la web, mapa base del seccionado de 2021 y tabla larga. Versiones de las fuentes y sumas en version.json."
```

En la web: *Releases → Draft a new release*, etiqueta `v0.1.0` sobre `main`, arrastrar los cinco ficheros de `publicacion/`, marcar *Set as the latest release* y publicar.

Las etiquetas siguen la versión del atlas: `v0.1.0` (9-nov-2026), `v0.4.0` (10-nov-2026, con F3 a F6 y sin la oferta de Idealista) y `v1.0.0`. La etiqueta va sobre el commit de la publicación, el mismo que se pone como `ref` en el flujo.

### 5. Publicar y comprobar

```bash
gh workflow run pages.yml
gh run watch
```

En la web: *Actions → Publicar en Pages → Run workflow*. El resumen de la ejecución dice qué release se ha usado, de qué commit son los datos y cuánto ocupa el sitio.

Comprobaciones en `https://gastiaso.github.io/de-renta-en-renta/`:

- la prueba en el navegador contra el sitio publicado (`R/web_navegador.R`; Chrome sin ventana, con `chromote`): la página recalcula una muestra de 300 secciones en todos los años y abre seis fichas, y todo coincide con la tabla larga, sin errores de JavaScript ni de carga. Desde la portada (10-nov-2026) abre el mapa en `mapa.html` y comprueba también la portada, la redirección de los enlaces viejos y la ficha por niveles, así que solo vale contra un sitio montado con ese código (la v1.0), no contra el de la v0.1. Todas las filas deben dar 0:

  ```r
  comprobar_web_navegador("https://gastiaso.github.io/de-renta-en-renta/",
                          larga = targets::tar_read(tabla_larga), perfiles = targets::tar_read(perfiles))
  ```


- el mapa carga toda España y no aparece la etiqueta «Datos de ejemplo»;
- el buscador encuentra un municipio y la ficha de una sección muestra su evolución;
- ES/EN cambian todos los textos;
- el PMTiles se sirve por rangos (debe responder `206` y 16 bytes). La petición tiene que ser un `GET`: con `curl -sI`, que solo pide la cabecera, GitHub responde `200` con el tamaño entero aunque sí sirva por rangos:

  ```bash
  curl -s -o /dev/null -D - -H "Range: bytes=0-15" https://gastiaso.github.io/de-renta-en-renta/teselas/seccionado_2021.pmtiles
  ```

- `descargas/version.json` dice la fecha y el commit esperados, y `descargas/tabla_larga.parquet` se baja entera.
- la página «Datos» (`datos.html` y `data.html`), desde el menú del mapa, de la sobrecarga y de «Método», en los dos idiomas: la caja de descarga da el tamaño, la suma, la fecha y el commit de `version.json`, el enlace al release es el de la etiqueta publicada, el enlace del Parquet lo baja y la suma coincide (`Get-FileHash tabla_larga.parquet -Algorithm SHA256`). En el resumen de la ejecución, el paso «Páginas «Método» y «Datos»» no da errores. Con el `v0.1.0`, la sección «Qué trae este release» dice que su `version.json` no trae la cobertura; con un release empaquetado después, lleva una fila por indicador.

## Actualizar

- **Publicaciones** (desde la v0.4.0, 10-nov-2026): commit de la publicación, `empaquetar_publicacion()`, etiqueta y release sobre ese commit, y un commit aparte que pone su identificador como `ref` por defecto en `pages.yml` (un commit no puede llevar su propio identificador). Un push a `main` no publica nada; *Actions → Publicar en Pages → Run workflow* monta `ref` con los datos del último release. Del 9 al 10-nov-2026, el sitio estuvo congelado en la v0.1 (`cdd9892`, con los datos del `v0.1.0`). Antes de congelarlo, el sitio llegó a montar el código del commit `e0d5132` con esos datos: la prueba en el navegador no dio errores, y lo que necesita datos nuevos no aparecía.
- **Cambia el código de la web (desde la v1.0):** se publica la referencia que se pase al flujo (la etiqueta del release).
- **Cambian los datos:** `tar_make()`, `empaquetar_publicacion()`, release nuevo (paso 4) y `gh workflow run pages.yml` (paso 5). Crear un release no relanza el flujo: un flujo lanzado por un release correría sobre su etiqueta, y el entorno `github-pages` solo admite publicaciones desde `main`.
- **Cambian a la vez el formato de los datos y el código que los lee:** primero el release y después el push, para que el sitio nunca junte código nuevo con datos viejos.
- **Volver a unos datos anteriores:** `gh release edit <etiqueta anterior> --latest` y `gh workflow run pages.yml`.
- **Sustituir un fichero de un release** (por ejemplo, tras regenerar el paquete el mismo día): `gh release upload <etiqueta> publicacion/* --clobber`. Hay que subir los cinco, porque `SHA256SUMS` cambia con cada empaquetado.

## Límites

Documentación de GitHub, consultada el 8-nov-2026:

| Límite | Valor | Hoy |
|---|---|---|
| Sitio publicado en Pages | 1 GB | 167,3 MB (9.251 ficheros) |
| Fichero dentro del sitio | 100 MiB (límite de git, que se mantiene también aquí) | 36,9 MB (la tabla larga) |
| Fichero de un release | menos de 2 GiB; sin límite del total ni de tráfico | 36,9 MB |
| Ficheros por release | 1.000 | 5 |
| Tráfico de Pages | 100 GB al mes (límite blando) | — |
| Publicación | 10 minutos como máximo | A medir en la primera |
| Artefacto que se sube a Pages | 10 GB, sin enlaces simbólicos ni duros | 167,3 MB |

El límite de diez publicaciones por hora no se aplica a los flujos propios de Actions.

## Licencias y avisos en el sitio publicado

- **Datos derivados y textos:** CC BY-SA 4.0; **código:** MIT (`LICENCIA_DATOS.md`, `LICENSE`). La página «Datos» lo dice junto a la descarga del Parquet.
- **Mapa base:** geometrías del INE (seccionado de 2021), con su atribución en el mapa (`mapa_base.atribucion` del manifiesto).
- **Geometrías NUTS de Eurostat (GISCO)**, cuando se publique el mapa europeo de sobrecarga: no entran en la licencia CC BY-SA 4.0. GISCO las cede para usos no comerciales y citando la fuente, con este aviso en la leyenda del mapa y en la página de entrada de la publicación:
  - «© EuroGeographics para los límites administrativos»;
  - en inglés, «© EuroGeographics for the administrative boundaries».

  Un uso comercial exige una licencia de EuroGeographics. El sitio las publica como ficheros (`datos/sobrecarga/nuts_2021.geojson` y `nuts_2024.geojson`, dentro de `datos_web.tar.gz`), así que la página «Datos» advierte que no se rigen por CC BY-SA 4.0, con el aviso en los dos idiomas.
- **Cita:** la página «Datos» la toma de `CITATION.cff` al publicar; al cambiar de versión basta con poner al día ese fichero.

## Si algo falla

| Síntoma | Causa y arreglo |
|---|---|
| «No hay ningún release publicado» | Crear el release (paso 4) y relanzar el flujo |
| `sha256sum: WARNING: … computed checksum did NOT match` | Un fichero del release no es el del paquete: volver a subir los cinco con `--clobber` |
| «… is not allowed to deploy to github-pages due to environment protection rules» | El flujo se lanzó desde otra rama o una etiqueta: solo publica desde `main` |
| El trabajo «Publicar en Pages» falla al empezar | Pages no está activado o su origen no es «GitHub Actions» (paso 1) |
| La dirección da 404 justo después de publicar | Esperar uno o dos minutos; si sigue, revisar *Settings → Pages* |
| El mapa sale con «Datos de ejemplo» | No se encontró `datos/manifiesto.json`: revisar el paso «Montar el sitio» en la ejecución |
| `pagina_datos.mjs: La nota debe llevar la marca …` | A `docs/datos.md` o `docs/data.md` le falta (o le sobra) una de sus marcas `<!-- descarga -->`, `<!-- cita -->` o `<!-- cobertura -->` |
| «La página datos.html no enlaza la tabla larga» | La herramienta o pandoc no han montado bien la página «Datos»: revisar el paso «Páginas «Método» y «Datos»» |
