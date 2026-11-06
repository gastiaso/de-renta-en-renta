# Inventario

Decisiones en CSV, no en código. UTF-8, separador coma, listas internas separadas por `;`.

| Fichero | Una fila por | Columnas clave |
|---|---|---|
| `fuentes.csv` | fuente | `id` (se usa en los nombres de función: `descargar_<id>()`), `acceso`, `licencia`, `cadencia`, `desfase`, `nivel_nativo`, `forales`, `indicadores`, `estado` |
| `indicadores.csv` | indicador (23) | `id` (número del plan), `codigo`, nombres ES/EN, `familia` (A–E), `fuentes` (ids de `fuentes.csv`), `nivel_nativo`, `serie`, `fase`, `nucleo_v01` |
| `referencias_validacion.csv` | comprobación de la compuerta | `indicador` (ids o `geo`), `referencia`, `tolerancia`, `tipo` (`bloqueo` para el pipeline; `alerta` avisa), `estado` |
| `rupturas.csv` | ruptura de serie | `fuente`, `indicador`, `anio`, `descripcion`, `tratamiento` |

`estado` de las fuentes: «por verificar» mientras no se haya comprobado acceso y licencia en la propia fuente; «BLOQUEANTE» si de ella depende el alcance de una versión.

Las pruebas de `pruebas/testthat/test-inventario.R` comprueban que los identificadores son únicos y que las referencias cruzadas existen.
