# De renta en renta · atlas de vivienda y salarios por sección censal

> **En construcción.** Nada de lo que hay aquí es definitivo.

**Pregunta:** dónde, desde cuándo y para quién se ha roto la relación entre lo que cuesta vivir y la capacidad de pago.

Atlas web de vivienda, salarios y otros indicadores sociales para España, por sección censal y desde 2015. Incluye fichas de perfil (hogar del barrio, joven menor de 35, salario mínimo, pensionista y el sueldo de cada usuario) y una sección europea de sobrecarga por gastos de vivienda con el método de Eurostat.

*English.* *De renta en renta* is left untranslated: it plays on a rhyme from the Spanish Game of the Goose, and *renta* means both rent and income. A web atlas of housing costs and wages in Spain at census-tract level, from 2015 onwards, with reference profiles, a pay calculator that runs in the browser, and a European housing cost overburden section (Eurostat method). Under construction.

## Estado

Fase F0 (cimientos): inventario, kit de diseño, plan, pipeline con la sobrecarga de la ECV validada contra Eurostat y una prueba de la geografía constante en Madrid. Sin datos publicados ni web todavía.

- Plan: `docs/plan_integracion_atlas.md`
- Primeras tareas: `docs/backlog_f0.md`
- Reglas de trabajo: `docs/guia_de_trabajo.md`
- Nota metodológica: `docs/metodologia.md`

## Estructura

| Ruta | Contenido |
|---|---|
| `_targets.R` | Pipeline (R, `targets`) |
| `R/` | Funciones por fuente y comunes |
| `inventario/` | Fuentes, indicadores, rupturas y referencias de validación (CSV) |
| `geo/` | Seccionado, tablas de paso y geometría de referencia |
| `datos/` | Brutos e intermedios (fuera de git) y publicados |
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

## Licencias

- Código: MIT (`LICENSE`).
- Datos derivados, textos e inventario: CC BY-SA 4.0 (`LICENCIA_DATOS.md`).
- Los datos de origen mantienen las condiciones de cada fuente (`inventario/fuentes.csv`).
