# Registro de cambios

Formato inspirado en *Keep a Changelog*, en castellano. Versiones previstas: v0.0 (sobrecarga y Europa), v0.1 (núcleo por sección censal), v0.2 a v0.4 (salarios, compraventa, presión y portales), v1.0.

## [Sin publicar]

### Añadido (7-nov-2026)

- Sobrecarga (F1b): tres olas de la ECV (2023–2025) con `tarchetypes::tar_map()`, corte por edad (RB081), cruces comunidad × tenencia y × edad con las olas agrupadas y marca de fiabilidad de EU-SILC (`calcular_sobrecarga_agrupada()`); datos europeos de Eurostat (`descargar_eurostat_europa()`), geometrías NUTS 2021 y 2024 de GISCO (`R/fuente_gisco_nuts.R`) y «escalera» (`armar_escalera()`). Nuevas comprobaciones: `sobrecarga_es_edad` y `nuts_geometria` (alertas).
- Indicador 23 desde las tablas del módulo de acceso de la ECV 2025 (`R/fuente_ine_ecv_modulo.R`; fuente `ine_ecv_modulo`; comprobación `modulo_acceso_lectura`).
- Tabla larga única con los indicadores 1–3, 22 y 23; nivel `nacional` («00») y tabla fija de comunidades `geo/ccaa.csv` (código del INE, nombre y NUTS 2).
- Plan: preguntas abiertas 9 (intervalos de confianza) y 10 (desgloses en la tabla larga).

### Añadido (6-nov-2026, séptima tanda)

- Comprobación del nombre (backlog, tarea 2): GitHub, dominios y marcas de las tres candidatas (plan §10.1). Decisión pendiente.

### Añadido (6-nov-2026, sexta tanda)

- Pipeline de punta a punta (backlog, tarea 7): renta del ADRH de Madrid (indicadores 1–3) leída, validada (`adrh_municipio`, bloqueo; `adrh_municipio_detalle`, alerta), llevada al seccionado de 2021 con estado y escrita en la tabla larga en Parquet (`validar_tabla_larga()`, `exportar_tabla_larga()`).
- `geo_tabla_identidad()` y `geo_cobertura_origenes()`: el año nativo pasa sin tabla y los orígenes con secreto marcan el destino como `estimado` o `secreto`.
- Pruebas de la tabla larga y de la armonización del ADRH.

### Cambiado (6-nov-2026, quinta tanda)

- Inventario de fuentes (backlog, tareas 3 y 4): acceso, licencia citada, cadencia y desfase comprobados en las fuentes de la v0.0 y la v0.1 (INE, Eurostat y GISCO, AEAT, Seguridad Social, Catastro, Gobierno Vasco); nueva fuente de referencia `nastat_epav`; ruptura `vut_calendario_2024`.
- Plan v0.9: revisión del método de la mochila (pregunta abierta 7), alquiler del País Vasco y Navarra sin SERPAVI (pregunta abierta 8), huecos y versiones NUTS del mapa europeo, vía (b) del Catastro.
- `LICENCIA_DATOS.md`: las geometrías NUTS de GISCO quedan fuera de la licencia CC BY 4.0.

### Añadido (6-nov-2026)

- Esqueleto del repositorio: estructura de carpetas, licencias (MIT y CC BY 4.0), `CITATION.cff`, `.gitignore`, `.gitattributes` y proyecto de RStudio.
- Guía de trabajo (`docs/guia_de_trabajo.md`) y backlog de F0 (`docs/backlog_f0.md`).
- Plan de integración v0.3 (`docs/plan_integracion_atlas.md`).
- Inventario inicial: 25 fuentes, 23 indicadores, 12 referencias de validación y una ruptura (`inventario/`).
- Kit de diseño del tablero: colores con contrastes calculados, tipografías y cinco fichas en SVG (`diseno/`).
- Pipeline mínimo (`_targets.R`), utilidades comunes y pruebas del inventario.

### Añadido (6-nov-2026, tercera tanda)

- Prueba de F1 en Madrid (backlog, tarea 6): lectura del seccionado (`R/fuente_ine_seccionado.R`), del callejero (`R/fuente_ine_callejero.R`) y de la población por sección del ADRH (`R/fuente_ine_adrh.R`); tablas de paso por el callejero, reproyección de recuentos, prueba de cierre, diagnóstico sección a sección y cambios de límites (`R/comun_geo.R`); exportación de las tablas (`R/comun_exportar.R`, `geo/tablas_paso/`).
- Rupturas `callejero_aplicacion_2021` y `callejero_diseno_2025`.
- Pruebas de las tablas de paso con tramos inventados, incluido el caso de las pseudovías.
- Prueba de un año en Madrid (tabla 2022 → 2021 y diagnóstico frente al ADRH 2020).
- Regla de estado de las cifras reproyectadas (`dato`, `estimado`, `ausente`), adoptada en el plan v0.7: `geo_estado_paso()`, `geo_reproyectar_media()` y `geo_reproyectar_mediana()`; `geo_reproyectar_recuento()` devuelve el estado.
- Medianas reproyectadas: se copia la del origen dominante (≥ 95 % de los portales) como `estimado` en lugar de dejarlas `ausente` (plan v0.8). `geo_estado_paso()` devuelve el origen de la copia.

### Añadido (6-nov-2026, segunda tanda)

- Indicador 22, sobrecarga por gastos de vivienda (backlog, tarea 5): descarga y lectura de los microdatos de la ECV (`R/fuente_ine_ecv.R`), cálculo con el método de Eurostat por total, tenencia y región NUTS 2, y consulta de las cifras de Eurostat (`R/fuente_eurostat_ilc_lvho07.R`). Con la ECV 2025 pasa la compuerta en España, inquilinos a precio de mercado y las 19 comunidades.
- Compuerta de publicación (`R/comun_validar.R`): `validar_referencias()` lee la tolerancia y el tipo de `inventario/referencias_validacion.csv`; los bloqueos paran el pipeline.
- Descargas con caché (`R/comun_descargar.R`).
- Pruebas de la sobrecarga y de la compuerta con datos inventados.

### Cambiado (6-nov-2026)

- Entorno (backlog, tarea 0): R 4.6.1 con `renv`; `renv.lock` fija todas las versiones de la biblioteca del proyecto.
- SERPAVI por sección censal (backlog, tarea 1): descarga directa de la base de datos del MIVAU, 2011–2024, en el seccionado del Censo 2021. Fila `mivau_serpavi` completa; `gv_emal` acotada a los años sin SERPAVI en el País Vasco; nueva ruptura `serpavi_forales`; la referencia `serpavi_provincia` pasa a comprobar recuentos de testigos, con tolerancia exacta.
- Plan v0.4: cobertura real del SERPAVI (§2.4), geografía constante del alquiler (§6.3) y pregunta abierta sobre el seccionado de referencia (§11).
- Plan v0.5: el seccionado de referencia es el del Censo 2021, no el último; tablas de paso en las dos direcciones (§6.3). Guía, backlog (tarea 6), `geo/LEEME.md` e inventario, al día.
- Indicador 8: «Alquiler mensual (mediana)» en lugar de «Alquiler medio mensual».

### Procedencia

- Convenciones de redondeo y de códigos territoriales: reaprovechadas de un proyecto propio anterior.
- Fichas SVG y paleta: maquetas de diseño (`docs/maquetas.md`).
