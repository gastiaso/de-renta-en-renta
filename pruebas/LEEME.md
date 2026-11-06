# Pruebas

```r
testthat::test_dir("pruebas/testthat")
```

- `test-inventario.R`: identificadores únicos y referencias cruzadas entre fuentes, indicadores y validaciones.
- `test-utilidades.R`: códigos de sección, ceros a la izquierda y neto mensual (SMI de 2026).

Cada función nueva de `R/` llega con su prueba. Las comprobaciones contra cifras publicadas no van aquí sino en la compuerta (`inventario/referencias_validacion.csv`).
