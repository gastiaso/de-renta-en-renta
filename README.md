# De renta en renta · atlas de vivienda y salarios por sección censal

> **En construcción.** Nada de lo que hay aquí es definitivo.

**Web:** <https://gastiaso.github.io/de-renta-en-renta/> · **Datos:** [release `v1.1.0`](https://github.com/gastiaso/de-renta-en-renta/releases/tag/v1.1.0)

**Pregunta:** ¿A quién le queda sueldo después de pagar la vivienda? Dónde, desde cuándo y para quién ha cambiado la relación entre lo que cuesta la vivienda y lo que se cobra. Para quien ya está en el tablero y para quien entra nuevo en la partida: para quien ya vive de alquiler y para quien busca piso hoy.

Atlas web de vivienda, salarios y otros indicadores sociales para España, por sección censal y desde 2015. Incluye fichas de perfil (hogar del barrio, joven de 26 a 35, salario mínimo, pensionista y el sueldo de cada usuario) y una sección europea de sobrecarga por gastos de vivienda con el método de Eurostat.

*English.* *De renta en renta* is left untranslated: it plays on a rhyme from the Spanish Game of the Goose, and *renta* means both rent and income. A web atlas of housing costs and wages in Spain at census-tract level, from 2015 onwards, with reference profiles, a pay calculator that runs in the browser, and a European housing cost overburden section (Eurostat method). Under construction.

## Estado

v1.1.0 publicada (12-nov-2026): la portada en una columna y el tablero nuevo; cuatro historias, las dos primeras reescritas en lenguaje llano y dos nuevas; el buscador por código postal; «Tu sueldo» con el selector de otros gastos de vivienda y euros de 2025 en la Máquina del tiempo y en la ficha, y los datos de 2025 de la AEAT y del INSS. La oferta de los portales sigue «próximamente». v1.0.0 publicada (11-nov-2026): la familia «quedarse» completa, el indicador 11 (Registradores, por provincia), siete tramos por escala y la escala relativa al municipio, la superficie típica, el mapa en el móvil, la fe de erratas y «Método en dos páginas», y las dos primeras historias como recorridos guiados dentro del mapa. La oferta de los portales sigue «próximamente». v0.4.0 publicada (10-nov-2026): a lo de la v0.1 se suman los indicadores 4 a 7 y 10, 12, 16, 17 y 20, la mochila de 2015 a 2024, el percentil salarial, los mapas por municipio, provincia y comunidad, la portada, la «Máquina del tiempo» desde 1987 con la vivienda como problema en el CIS, y las dos familias de alquiler («quedarse» y «entrar»). La oferta de los portales, «próximamente». v0.1 publicada (9-nov-2026): mapa por sección censal de 2015 a 2024 (renta, alquiler, sueldo necesario, esfuerzo, hogares en alquiler y viviendas turísticas), «Tu sueldo» con las fichas de perfil, la sección europea de sobrecarga y la nota metodológica en castellano e inglés. Los datos (tabla larga en Parquet, mapa base y datos de la web) van en el release `v0.1.0`.

- Plan: `docs/plan_integracion_atlas.md`
- Tareas: `docs/backlog.md` (histórico: `docs/backlog_f0.md`)
- Reglas de trabajo: `docs/guia_de_trabajo.md`
- Nota metodológica: `docs/metodologia.md` (en inglés, `docs/methodology.md`)

## Estructura

| Ruta | Contenido |
|---|---|
| `_targets.R` | Pipeline (R, `targets`) |
| `R/` | Funciones por fuente y comunes |
| `inventario/` | Fuentes, indicadores, rupturas y referencias de validación (CSV) |
| `geo/` | Seccionado, tablas de paso y geometría de referencia |
| `datos/` | Brutos e intermedios (fuera de git); lo publicado sale en el release (`publicacion/`, `docs/publicacion.md`) |
| `web/` | Web (MapLibre, PMTiles, d3) y diccionarios ES/EN |
| `diseno/` | Identidad: colores, tipografías y fichas |
| `pruebas/` | Pruebas (`testthat`) |
| `docs/` | Plan, guía de trabajo, backlog y maquetas |

## Ejecución

```r
# Desde la carpeta del proyecto (Positron o RStudio), con R 4.6
renv::restore()                          # solo la primera vez: instala las versiones de renv.lock
targets::tar_make()
testthat::test_dir("pruebas/testthat")
```

La capa de precios de oferta de los portales está apagada por defecto. Se enciende con la variable de entorno `PORTALES=TRUE`.

Con cada push, GitHub pasa las pruebas que no necesitan datos (`.github/workflows/pruebas.yml`): la batería de `testthat` y las de la web.

## Licencias

- Código: MIT (`LICENSE`).
- Datos derivados, textos e inventario: CC BY-SA 4.0 (`LICENCIA_DATOS.md`).
- Los datos de origen mantienen las condiciones de cada fuente (`inventario/fuentes.csv`); qué obliga cada una, en la nota metodológica (§2.2).
