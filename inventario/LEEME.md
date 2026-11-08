# Inventario

Decisiones en CSV, no en código. UTF-8, separador coma, listas internas separadas por `;`.

| Fichero | Una fila por | Columnas clave |
|---|---|---|
| `fuentes.csv` | fuente | `id` (se usa en los nombres de función: `descargar_<id>()`), `nombre` y `nombre_en`, `acceso`, `licencia`, `cadencia`, `desfase`, `nivel_nativo`, `forales`, `indicadores`, `estado` |
| `indicadores.csv` | indicador (23) | `id` (número del plan), `codigo`, ficha en castellano e inglés (`nombre`, `unidad`, `definicion`, `calculo`, `lectura`, con sufijo `_es` y `_en`), `familia` (A–E), `fuentes` (ids de `fuentes.csv`), `nivel_nativo`, `serie`, `fase`, `nucleo_v01`, `notas`, `cortes_web` (de uno a cinco cortes del mapa de la web, separados por `;`; en la sobrecarga, los de cada grupo tras «|», como `RENT_MKT=15;20;25;30;40`) y `escala_web` (precisión de la serie en la web: vacía, una décima; `100`, dos decimales) |
| `referencias_validacion.csv` | comprobación de la compuerta | `indicador` (ids, `geo` o `web`), `referencia`, `tolerancia`, `tipo` (`bloqueo` para el pipeline; `alerta` avisa), `estado` |
| `rupturas.csv` | ruptura de serie | `fuente`, `indicador`, `anio`, `descripcion`, `tratamiento`, `estado` (las `aplicado` del indicador 22 de la ECV cortan la serie de España en la sección «Sobrecarga») |
| `vocabulario.csv` | término de la web | `grupo` (familia, nivel, estado, fiabilidad, corte y los grupos de cada corte: tenencia, edad, sexo), `clave`, `es`, `en`. Los cortes y grupos de la tabla larga tienen que estar aquí |

`estado` de las fuentes: «por verificar» mientras no se haya comprobado acceso y licencia en la propia fuente; «BLOQUEANTE» si de ella depende el alcance de una versión.

Las pruebas de `pruebas/testthat/test-inventario.R` comprueban que los identificadores son únicos y que las referencias cruzadas existen.

Los textos de las fichas, los nombres de las fuentes y el vocabulario pasan a los diccionarios de la web (`web/i18n/`) con `exportar_i18n()`: se corrigen aquí, no en el JSON. Registro de los textos: impersonal, denso, sin valoraciones.
