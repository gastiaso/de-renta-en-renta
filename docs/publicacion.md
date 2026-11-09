# Publicación en GitHub Pages

Cómo se publica la web (plan §6.6; §11, preguntas abiertas 16 y 21). Comprobado contra la documentación de GitHub el 8-nov-2026.

## Cómo funciona

El sitio se monta en GitHub Actions con el flujo `.github/workflows/pages.yml`. Se ejecuta en cada push a `main` y a mano. Junta dos cosas:

| Parte del sitio | De dónde sale | Por qué |
|---|---|---|
| `web/` (HTML, JS, estilo, diccionarios, librerías, muestra de `datos/ejemplo/`) | git | Es código: cambia poco y cada cambio se revisa |
| `datos/` (manifiesto, índices, valores, fichas, perfiles…) | release: `datos_web.tar.gz` | Unos 8.800 ficheros y 92 MB (15,8 MB comprimido); cada actualización los reescribe casi todos y engordaría la historia de git sin aportar nada (pregunta 21) |
| `teselas/seccionado_2021.pmtiles` | release: `seccionado_2021.pmtiles` | 35,3 MB binarios que se regeneran con el pipeline (pregunta 16) |
| `descargas/tabla_larga.parquet` | release: `tabla_larga.parquet` | La tabla larga completa (36,9 MB), para la página «Datos» |
| `descargas/version.json` | release: `version.json` | Fecha, commit, versiones de las fuentes y suma de cada fichero |
| `metodo.html`, `method.html` | git: se generan en el flujo desde `docs/metodologia.md` y `docs/methodology.md` | La página «Método» sale siempre de la nota que hay en `main` |

El flujo baja los ficheros del **último release** (el marcado como *Latest*; nunca un borrador ni una versión previa), comprueba sus sumas SHA-256 con `SHA256SUMS`, monta el sitio y lo publica. Las herramientas de desarrollo de `web/` (`LEEME.md`, `servir.mjs`, `herramientas/`) no se publican.

**Página «Método».** El flujo instala pandoc (paquete de Ubuntu; la imagen de GitHub no lo trae) y convierte la nota metodológica en `metodo.html` y `method.html`, con la cabecera de la web (`estilo/documento.css`) y un índice plegable. La plantilla y los textos propios de cada idioma están en `web/herramientas/` (`plantilla_documento.html`, `documento_es.yaml`, `documento_en.yaml`); el título, el subtítulo y los nombres del menú salen de `web/i18n/`. Para verla en local, con pandoc instalado:

```bash
pandoc docs/metodologia.md --from gfm --to html5 --standalone --toc --toc-depth 2 --wrap none --template web/herramientas/plantilla_documento.html --metadata-file web/herramientas/documento_es.yaml --metadata titulo="De renta en renta" --metadata subtitulo="Vivienda y sueldos, sección a sección" --metadata texto_mapa=Mapa --metadata texto_sobrecarga=Sobrecarga --metadata texto_metodo=Método --output web/metodo.html
```

y abrir <http://localhost:8000/metodo.html> con `node web/servir.mjs`. Ese `web/metodo.html` es una copia local: no se añade a git.

- No usa secretos: solo el token que GitHub da a cada ejecución. El trabajo que monta el sitio solo puede leer el repositorio; el que lo publica solo puede escribir en Pages.
- No lleva el nombre del repositorio: funciona igual con cualquier nombre o cuenta.
- La web usa rutas relativas, así que funciona en la dirección de un sitio de proyecto, `https://<cuenta>.github.io/de-renta-en-renta/`.

Los ficheros del release los prepara `empaquetar_publicacion()` (`R/publicar.R`) en `publicacion/`, que está fuera de git. No forma parte de `tar_make()`: se ejecuta a mano cuando se quiere publicar.

## Qué queda fuera de git

| Qué | Dónde se regenera | Cómo se publica |
|---|---|---|
| `datos/brutos/`, `datos/intermedios/` (incluida la tabla larga) | `targets::tar_make()` | La tabla larga, en el release |
| `web/datos/` (salvo la muestra de `web/datos/ejemplo/`) | `targets::tar_make(names = c(ficheros_web, validacion_web))` | Release |
| `*.pmtiles` (`geo/referencia/`, `web/teselas/`) | `targets::tar_make(names = fichero_mapa_base)` | Release |
| `publicacion/` | `empaquetar_publicacion()` | Es el release |
| `_targets/`, `renv/library/` | El pipeline y `renv::restore()` | No se publican |
| `.Renviron` | A mano | Nunca: credenciales |

Las capas de los portales tampoco entran en git ni se publican (guía, regla 6).

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

`empaquetar_publicacion()` escribe en `publicacion/` cinco ficheros: `datos_web.tar.gz`, `seccionado_2021.pmtiles`, `tabla_larga.parquet`, `version.json` y `SHA256SUMS`. Se detiene, sin dejar nada a medias, si:

- algún fichero pasa de 2 GiB (límite de GitHub por fichero de un release);
- el sitio montado pasa de 1 GB (límite de Pages) o tiene algún fichero de más de 100 MiB;
- la exportación es la muestra, o el mapa base no es un PMTiles en `teselas/`;
- el PMTiles o el Parquet no tienen la cabecera de su formato;
- el `.tar.gz` no lleva exactamente los ficheros de `web/datos/` (sin la muestra);
- la exportación de la web y la tabla larga son de pasadas distintas del pipeline (fuentes con otra versión).

Avisa, y lo anota en `version.json`, si hay cambios sin commit.

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

Las etiquetas siguen la versión del atlas (`v0.1.0`, `v0.1.1`…). Si solo cambian los datos, basta con un release nuevo.

### 5. Publicar y comprobar

```bash
gh workflow run pages.yml
gh run watch
```

En la web: *Actions → Publicar en Pages → Run workflow*. El resumen de la ejecución dice qué release se ha usado, de qué commit son los datos y cuánto ocupa el sitio.

Comprobaciones en `https://gastiaso.github.io/de-renta-en-renta/`:

- la prueba en el navegador contra el sitio publicado (`R/web_navegador.R`; Chrome sin ventana, con `chromote`): la página recalcula una muestra de 300 secciones en todos los años y abre seis fichas, y todo coincide con la tabla larga, sin errores de JavaScript ni de carga. Todas las filas deben dar 0:

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

## Actualizar

- **Cambia el código de la web:** push a `main`. El flujo vuelve a publicar con los datos del último release.
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

  Un uso comercial exige una licencia de EuroGeographics. Si las geometrías se publican como fichero (en el sitio o en un release), la página «Datos» debe advertir que no se rigen por CC BY-SA 4.0.

## Si algo falla

| Síntoma | Causa y arreglo |
|---|---|
| «No hay ningún release publicado» | Crear el release (paso 4) y relanzar el flujo |
| `sha256sum: WARNING: … computed checksum did NOT match` | Un fichero del release no es el del paquete: volver a subir los cinco con `--clobber` |
| «… is not allowed to deploy to github-pages due to environment protection rules» | El flujo se lanzó desde otra rama o una etiqueta: solo publica desde `main` |
| El trabajo «Publicar en Pages» falla al empezar | Pages no está activado o su origen no es «GitHub Actions» (paso 1) |
| La dirección da 404 justo después de publicar | Esperar uno o dos minutos; si sigue, revisar *Settings → Pages* |
| El mapa sale con «Datos de ejemplo» | No se encontró `datos/manifiesto.json`: revisar el paso «Montar el sitio» en la ejecución |
