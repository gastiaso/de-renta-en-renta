# Rederivación a mano · cifras de F4 a F6 y de «Entrar»

*Backlog, tarea 59 · 11 de noviembre de 2026.*

Dieciséis cifras de F4 a F6 (indicadores 10, 11, 12, 16, 17 y 20, módulo histórico y CIS) y cinco de «Entrar», más una auxiliar, se vuelven a calcular desde los ficheros de la fuente en `datos/brutos/`, con código propio que no carga nada de `R/` ni usa objetivos de `targets` para la cifra a mano. Después se comparan con lo que publica el atlas: la tabla larga (`datos/intermedios/tabla_larga.parquet`), el histórico (`datos/intermedios/historico.parquet`) o los datos de la web (`web/datos/`).

## Cómo se ejecuta

Desde la raíz del proyecto, con `datos/brutos/` completo y la tabla larga generada:

```r
Rscript pruebas/rederivar/rederivar.R          # F4–F6: escribe pruebas/rederivar/resultado.csv
Rscript pruebas/rederivar/rederivar_entrar.R   # «Entrar»: necesita la extracción de Idealista y el
                                               # objetivo indicadores_entrar (tar_make() con PORTALES=TRUE)
```

El primero tarda en torno a medio minuto (lee la tabla 30824 del ADRH, de 400 MB, hasta la línea de Madrid); el segundo, unos diez segundos.

**Privacidad de «Entrar»** (backlog, decisiones 17 a 19). Las cifras exactas de la oferta y de sus derivados se escriben solo en `datos/intermedios/rederivar/entrar.csv`, fuera de git. A `pruebas/rederivar/resultado_entrar.csv` y a este documento solo llegan «coincide / no coincide» y, en la brecha, el tramo de `inventario/entrar_tramos.csv`.

## F4 a F6

Tolerancia: la mitad de la última cifra publicada (0,05 en los porcentajes a un decimal; 0,005 en lo calculado a partir de términos ya redondeados) y cero en los recuentos y categorías.

| Cifra | Fuente | Fichero (`datos/brutos/`) | Valor a mano | Valor del atlas | Diferencia |
|---|---|---|---|---|---|
| 10 · Variación anual del alquiler, España, 2024 (%) | INE, IPVA | `ine_ipva/59056.csv` | 3,5 | 3,5 | 0 |
| 10 · Variación anual del alquiler, Madrid (municipio), 2024 (%) | INE, IPVA | `ine_ipva/59060.csv` | 3,6 | 3,6 | 0 |
| 10 · Variación anual, contratos nuevos, Valencia/València (provincia), 2024 (%) | INE, IPVA por antigüedad del contrato | `ine_ipva/59005.csv` | 12,4 | 12,4 | 0 |
| 11 · Precio de compraventa por m², España, 2025 (€/m²) | Colegio de Registradores | `registradores/RP_ComprvResid_2007-2t2026.csv` | 2.283,52 | 2.283,52 | 0 |
| 11 · Precio de compraventa por m², Madrid (provincia), 2024 (€/m²) | Colegio de Registradores | `registradores/RP_ComprvResid_2007-2t2026.csv` | 3.527,22 | 3.527,22 | 0 |
| 12 · Valor tasado, España, 2024 (€/m²) | MIVAU | `mivau_valor_tasado/35101000.xls` y `35103000.xls` | 1.913,857 | 1.913,857 | 0 |
| 12 · Valor tasado, Madrid (municipio), 2024 (€/m²) | MIVAU | `mivau_valor_tasado/35103500.xls` | 4.225,130 | 4.225,130 | 0 |
| 16 · Años de salario para comprar 80 m², Madrid (municipio), 2024 | MIVAU y AEAT | `35103500.xls` y `aeat_mercado/2024/` | 10,592 | 10,592 | 0 |
| 17 · Esfuerzo hipotecario teórico, Madrid (municipio), 2024 (%) | MIVAU, Banco de España e INE (ADRH) | `35103500.xls`, `bde/si_1_5.csv` y `ine_adrh/30824.csv` | 30,430 | 30,430 ¹ | 0 |
| 20 · Municipios con zona tensionada declarada, 31-12-2025 | MIVAU, resoluciones en el BOE | `zonas_tensionadas/BOE-A-*.xml` | 304 | 304 | 0 |
| 20 · Barcelona, categoría a 31-12-2025 | MIVAU, resolución en el BOE | `zonas_tensionadas/BOE-A-2024-5214.xml` | 2 | 2 | 0 |
| Histórico · Sueldo bruto medio por asalariado, España, 2024 (€ al año) | INE, Contabilidad Nacional | `ine_cne/71129.csv` y `71133.csv` | 31.199,74 | 31.199,74 | 0 |
| Histórico · Años de renta para comprar, España, 4.º trimestre de 2024 | Banco de España | `bde/si_1_5.csv` | 7,18 | 7,18 | 0 |
| Histórico · Tipo de los préstamos hipotecarios a más de tres años, diciembre de 2024 (%) | Banco de España | `bde/be1901.csv` | 3,105 | 3,105 | 0 |
| CIS · La vivienda entre los tres principales problemas de España, octubre de 2024 (%) | CIS, barómetro 3478 | `cis_barometros/resultados/3478.html` | 22,6 | 22,6 (web) | 0 |
| CIS · La vivienda entre los tres problemas que más afectan personalmente, octubre de 2024 (%) | CIS, barómetro 3478 | `cis_barometros/resultados/3478.html` | 17,6 | 17,6 (web) | 0 |

Cómo se rederiva cada una:

- **10:** índice del año / índice del anterior − 1, a un decimal, desde las filas «Índice» de la tabla; el atlas guarda la variación que publica el INE. Coinciden también en el desglose por antigüedad del contrato.
- **11:** fila del cuarto trimestre del año (cada trimestre acumula los cuatro últimos), columna `viv-pm2`.
- **12:** media de los cuatro trimestres ponderada por el número de tasaciones: en España, el bloque «Año 2024» de la fila TOTAL NACIONAL de las dos tablas territoriales; en Madrid, las hojas `T1A2024` a `T4A2024`, primera y última columna «Total».
- **16:** valor tasado de Madrid a un decimal × 80 / salario medio de la provincia, calculado como salarios / asalariados de la tabla provincial de la AEAT («Tramos de Edad: Total») y redondeado al euro, como lo publica la AEAT (comprobado contra su columna de salario medio).
- **17:** cuota del primer año de un préstamo francés del 80 % del valor de 80 m², a 25 años, al tipo de los préstamos nuevos para vivienda del Banco de España (`D_IMVTIPLV`, media de los doce meses), entre la renta neta media por hogar del municipio (ADRH, 53.213 € en 2024).
- **20:** nombres distintos de las tablas de las resoluciones del BOE publicadas hasta el 31-12-2025, todas con vigencia de tres años desde el día siguiente a su publicación; los ámbitos parciales («Galdakao (Distrito 2)», «Vitoria-Gasteiz, excepto la zona rural…») cuentan el municipio una vez.
- **Histórico:** sueldos y salarios (millones de euros) / personas asalariadas (miles) del total de la economía; las dos series del Banco de España, leídas de su columna y su fila.
- **CIS:** primer + segundo + tercer problema de la fila «La vivienda» (coincide con la columna TOTAL del CIS), frente a `web/datos/cis_vivienda.json`.

¹ **Redondeo del tipo en un empate** (hallazgo de esta rederivación, corregido el 11-nov-2026 por decisión del autor; plan §11, pregunta 59 b). La media de los doce meses de `D_IMVTIPLV` en 2024 es exactamente 3,465. A dos decimales con el empate hacia arriba, 3,47; el pipeline (`compraventa_tipo_bde()`) usaba `sprintf("%.2f")`, que da 3,46 porque el binario de 3,465 queda por debajo, y el atlas daba 30,397 (+0,033 de diferencia, y en torno a un 0,1 % relativo en todo el 17 de 2024). Desde el 11-nov-2026, el tipo se redondea con `redondear_empate_arriba()` (`R/comun_utilidades.R`), la utilidad que ya usaba la capa de portales, y el atlas da 30,430. De 2011 a 2025, 2024 es el único año con empate.

El indicador 11, conectado el 11-nov-2026 (tarea 46), ya está en la tabla larga: el guion toma de allí su cifra del atlas.

## «Entrar»

Cifras exactas, solo en `datos/intermedios/rederivar/entrar.csv`. Criterio: diferencia relativa por debajo de una millonésima. Términos como los recibe la web: la oferta, media anual de los meses publicados (al menos nueve) a dos decimales con el empate hacia arriba; el SERPAVI de vivienda colectiva (municipios con diez testigos o más) y el ingreso de la tartera, a un decimal.

| Cifra | Fuente | Fichero (`datos/brutos/`) | Resultado | Tramo de la brecha |
|---|---|---|---|---|
| Brecha entre la oferta y el parque, Madrid (municipio), 2024 | Idealista y MIVAU, SERPAVI | `portales/idealista/alquiler_historico_*.csv` y `mivau_serpavi/bd_serpavi_2011-2024.xlsx` | Coincide | 3 (de 1,35 a 1,6) |
| Brecha entre la oferta y el parque, Barcelona (municipio), 2024 | Idealista y MIVAU, SERPAVI | ídem | Coincide | 3 (de 1,35 a 1,6) |
| Brecha mediana de los municipios con oferta y SERPAVI, 2024 | Idealista y MIVAU, SERPAVI | ídem | Coincide (los mismos municipios a mano y en el atlas) | — |
| Sueldo para entrar con 50 m² (umbral del 30 %), València (municipio), 2024 | Idealista | `portales/idealista/alquiler_historico_*.csv` | Coincide | — |
| Barrera para entrar de la tartera (50 m², salario mínimo de 2023), Madrid (municipio), 2023 | Idealista y BOE, RD 99/2023 | ídem y `boe_smi/2023_BOE-A-2023-3982.xml` | Coincide | — |
| Auxiliar: superficie típica mediana de esos municipios, 2024 (SERPAVI) | MIVAU, SERPAVI | `mivau_serpavi/bd_serpavi_2011-2024.xlsx` | Coincide | — |

La cifra del atlas sale de `targets::tar_read(indicadores_entrar)`, las cifras exactas que no salen del pipeline (última pasada con `PORTALES=TRUE`: 10-nov-2026). El ingreso de la tartera de 2023 se rederiva del real decreto (1.080 € × 14 × (1 − 6,45 %) / 12).

## Resultado

Las dieciséis cifras de F4 a F6 coinciden con el atlas (11-nov-2026, tras corregir el redondeo del tipo del 17 en un empate, nota ¹; antes, 15 de 16). Las cinco de «Entrar» y la auxiliar coinciden.
