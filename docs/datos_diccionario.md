<!-- Generado por exportar_diccionario_datos() (R/web_pagina_datos.R) desde inventario/. No se edita a mano: lo rehace targets::tar_make(). -->

## Valores de las columnas

Códigos de las columnas con vocabulario cerrado y su significado (`inventario/vocabulario.csv` e `inventario/fuentes.csv`).

### `estado`

| Código | Significado |
| --- | --- |
| `dato` | Dato publicado o calculado sin estimar |
| `estimado` | Estimado: la sección cambió de límites y hubo que repartir |
| `secreto` | Sin dato por secreto estadístico |
| `ausente` | Sin dato |

### `nivel`

| Código | Significado | Cifras de `geo_id` |
| --- | --- | --- |
| `sc` | Sección censal | 10 |
| `distrito` | Distrito | 7 |
| `municipio` | Municipio | 5 |
| `cp` | Código postal | 5 |
| `provincia` | Provincia | 2 |
| `ccaa` | Comunidad autónoma | 2 |
| `nacional` | España | 2 (`00`) |

### `corte`

Variable del desglose. Sin desglose, `corte` y `grupo` valen `total`.

| Código | Significado |
| --- | --- |
| `total` | Total |
| `tenencia` | Régimen de tenencia |
| `edad` | Edad |
| `sexo` | Sexo |
| `tipologia` | Tipología de la vivienda (mediana) |
| `tipologia_p25` | Tipología de la vivienda, primer cuartil |
| `tipologia_p75` | Tipología de la vivienda, tercer cuartil |
| `mes` | Mes de referencia |
| `ficha` | Ficha (ingreso de referencia) |
| `oferta_privada` | Dato privado de oferta: operación y portal (capa desmontable, solo con PORTALES=TRUE) |
| `contrato` | Antigüedad del contrato de alquiler (IPVA) |
| `superficie` | Superficie supuesta (mínimo teórico del sueldo necesario) |

### `grupo`

Valor del desglose, según el corte.

| `corte` | Código | Significado |
| --- | --- | --- |
| `total` | `total` | Sin desglose |
| `tenencia` | `OWN` | Propiedad |
| `tenencia` | `OWN_NL` | Propiedad sin hipoteca ni préstamo |
| `tenencia` | `OWN_L` | Propiedad con hipoteca o préstamo |
| `tenencia` | `RENT` | Alquiler o cesión gratuita |
| `tenencia` | `RENT_MKT` | Alquiler a precio de mercado |
| `tenencia` | `RENT_FR` | Alquiler inferior al de mercado o cesión gratuita |
| `tenencia` | `RENT_RED` | Alquiler inferior al precio de mercado |
| `tenencia` | `FREE` | Cesión gratuita |
| `edad` | `Y_LT18` | Menos de 18 años |
| `edad` | `Y18-64` | De 18 a 64 años |
| `edad` | `Y_GE65` | 65 y más años |
| `edad` | `Y15-29` | De 15 a 29 años |
| `edad` | `Y16-29` | De 16 a 29 años |
| `edad` | `Y30-44` | De 30 a 44 años |
| `edad` | `Y45-64` | De 45 a 64 años |
| `edad` | `Y26-35` | De 26 a 35 años |
| `sexo` | `M` | Hombres |
| `sexo` | `F` | Mujeres |
| `tipologia` | `VC` | Vivienda colectiva |
| `tipologia` | `VU` | Vivienda unifamiliar o rural |
| `tipologia_p25` | `VC` | Vivienda colectiva, primer cuartil |
| `tipologia_p25` | `VU` | Vivienda unifamiliar o rural, primer cuartil |
| `tipologia_p75` | `VC` | Vivienda colectiva, tercer cuartil |
| `tipologia_p75` | `VU` | Vivienda unifamiliar o rural, tercer cuartil |
| `mes` | `M02` | Febrero |
| `mes` | `M05` | Mayo |
| `mes` | `M08` | Agosto |
| `mes` | `M11` | Noviembre |
| `ficha` | `tartera` | Salario mínimo |
| `ficha` | `mochila` | Joven de 26 a 35 |
| `ficha` | `transistor` | Pensionista |
| `oferta_privada` | `alquiler_idealista` | Alquiler, Idealista (dato privado de oferta) |
| `oferta_privada` | `alquiler_fotocasa` | Alquiler, Fotocasa (dato privado de oferta) |
| `oferta_privada` | `venta_idealista` | Venta, Idealista (dato privado de oferta) |
| `oferta_privada` | `venta_fotocasa` | Venta, Fotocasa (dato privado de oferta) |
| `contrato` | `nuevo` | Contrato nuevo (firmado en el año de referencia) |
| `contrato` | `existente` | Contrato existente (firmado antes del año de referencia) |
| `superficie` | `50` | Piso teórico de 50 m² |

### `fuente`

Fuentes que cita el inventario de indicadores; `calculo_propio` marca los derivados. Su enlace y su licencia están en `inventario/fuentes.csv` (columnas `url` y `licencia`).

| Código | Fuente |
| --- | --- |
| `ine_adrh` | Atlas de Distribución de Renta de los Hogares (ADRH) |
| `mivau_serpavi` | Sistema Estatal de Referencia del Precio del Alquiler de Vivienda (SERPAVI): base de datos |
| `gv_emal` | Estadística del Mercado del Alquiler (fianzas) |
| `ine_ipva` | Índice de Precios de Vivienda en Alquiler (IPVA) |
| `registradores` | Estadística Registral Inmobiliaria: compraventas de inmuebles de uso residencial por provincia (Colegio de Registradores; base de datos con licencia ODbL) |
| `mivau_valor_tasado` | Valor tasado de la vivienda libre |
| `portales` | Informes de precios de oferta (salas de prensa de Idealista y Fotocasa) |
| `aeat_mercado_trabajo` | Mercado de trabajo y pensiones en las fuentes tributarias |
| `inss_pensiones` | Pensiones contributivas del Sistema de la Seguridad Social (en vigor) |
| `boe_smi` | Real Decreto del salario mínimo interprofesional |
| `ine_censo2021` | Censo de Población y Viviendas 2021 |
| `ine_censo2011` | Censos de Población y Viviendas 2011 |
| `ine_vut` | Viviendas de uso turístico (estadística experimental) |
| `zonas_tensionadas` | Declaraciones de zonas de mercado residencial tensionado |
| `ine_ecv` | Encuesta de Condiciones de Vida (microdatos) |
| `ine_ecv_modulo` | Encuesta de Condiciones de Vida 2025: módulo sobre dificultades de acceso a la vivienda (tablas) |
| `eurostat_ilc_lvho07` | Tasa de sobrecarga por gastos de vivienda (ilc\_lvho07a, ilc\_lvho07b, ilc\_lvho07c) |
| `eurostat_ilc_lvho07_r` | Tasa de sobrecarga por regiones NUTS 2 (ilc\_lvho07\_r) |
| `bde_accesibilidad` | Indicadores de accesibilidad a la vivienda (años de renta, esfuerzo teórico) |
| `calculo_propio` | Cálculo propio a partir de las fuentes de cada término |

## Diccionario de indicadores

Los 23 indicadores del plan y 3 auxiliares de fiabilidad, en el orden de `inventario/indicadores.csv`. La columna `indicador` de la tabla larga lleva el código. «Versión» es la del atlas en que entra cada indicador: los que entran en una versión posterior a la del release todavía no están en la tabla larga.

| Nº | Código | Nombre | Unidad | Versión |
| --- | --- | --- | --- | --- |
| 1 | [`renta_persona`](#renta_persona) | Renta neta media por persona | € por persona y año | v0.1 |
| 2 | [`renta_hogar`](#renta_hogar) | Renta neta media por hogar | € por hogar y año | v0.1 |
| 3 | [`renta_uc_mediana`](#renta_uc_mediana) | Mediana de la renta por unidad de consumo | € por unidad de consumo y año | v0.1 |
| 4 | [`peso_salarios`](#peso_salarios) | Peso de los salarios en la renta | % de la renta bruta | v0.2 |
| 5 | [`bajo_60_mediana`](#bajo_60_mediana) | Población por debajo del 60 % de la mediana de renta por unidad de consumo | % de la población | v0.2 |
| 6 | [`gini`](#gini) | Índice de Gini | índice (0–100) | v0.2 |
| 7 | [`salario_medio`](#salario_medio) | Salario medio anual por asalariado (total y de 26 a 35 años) | € por asalariado y año (bruto) | v0.2 |
| 8 | [`alquiler_mes`](#alquiler_mes) | Alquiler mensual (mediana) | € por mes | v0.1 |
| 9 | [`alquiler_m2`](#alquiler_m2) | Alquiler por metro cuadrado | € por m² y mes | v0.1 |
| 10 | [`var_alquiler`](#var_alquiler) | Variación anual del alquiler | % de variación anual | v0.3 |
| 11 | [`precio_compra_m2`](#precio_compra_m2) | Precio de compraventa por metro cuadrado | € por m² | v0.3 |
| 12 | [`valor_tasado_m2`](#valor_tasado_m2) | Valor tasado por metro cuadrado | € por m² | v0.3 |
| 13 | [`precio_oferta`](#precio_oferta) | Precio de oferta (alquiler y venta) | € por m² (alquiler: por m² y mes) | v0.4 |
| 14 | [`esfuerzo_residentes`](#esfuerzo_residentes) | Alquiler mediano sobre renta media del barrio | % de la renta del hogar | v0.1 |
| 15 | [`peso_alquiler_ingreso`](#peso_alquiler_ingreso) | Peso del alquiler en el ingreso | % del ingreso de referencia | v0.1 |
| 16 | [`anios_salario_compra`](#anios_salario_compra) | Años de salario para comprar | años | v0.3 |
| 17 | [`esfuerzo_hipotecario`](#esfuerzo_hipotecario) | Cuota hipotecaria sobre la renta del hogar | % de la renta del hogar | v0.3 |
| 18 | [`hogares_alquiler`](#hogares_alquiler) | Hogares en alquiler | % de los hogares | v0.1 |
| 19 | [`viviendas_turisticas`](#viviendas_turisticas) | Viviendas de uso turístico sobre el total de viviendas | % de las viviendas | v0.1 |
| 20 | [`zona_tensionada`](#zona_tensionada) | Zona de mercado residencial tensionado declarada | categoría (2 todo el municipio, 1 una parte, 0 ninguna) | v0.4 |
| 21 | [`sueldo_necesario`](#sueldo_necesario) | Sueldo neto necesario para no pasar del umbral | € netos por mes | v0.1 |
| 22 | [`sobrecarga`](#sobrecarga) | Tasa de sobrecarga por gastos de vivienda (método Eurostat) | % de las personas | v0.1 |
| 23 | [`busqueda_sin_exito`](#busqueda_sin_exito) | Búsqueda de vivienda sin éxito | % de las personas de 16 o más años | v0.1 |
| Auxiliar | [`contratos_alquiler`](#contratos_alquiler) | Contratos de alquiler de la mediana | contratos | v0.1 |
| Auxiliar | [`margen_alquiler_mes`](#margen_alquiler_mes) | Margen aproximado de la mediana del alquiler mensual | % de la mediana | v0.1 |
| Auxiliar | [`margen_alquiler_m2`](#margen_alquiler_m2) | Margen aproximado de la mediana del alquiler por m² | % de la mediana | v0.1 |

### `renta_persona`

**1 · Renta neta media por persona**

- **Unidad:** € por persona y año
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.1
- **Definición:** Renta disponible media de los residentes: ingresos netos de impuestos y cotizaciones del conjunto de hogares de la sección, divididos entre su población.
- **Cálculo:** Cifra publicada por el INE (ADRH), a partir de datos tributarios. Los años publicados en otro seccionado se llevan al de 2021 como media ponderada por la población; si hay que repartir alguna sección, el estado pasa a «estimado».
- **Lectura:** Renta del año t con la población a 1 de enero de t + 1. No incluye el valor de uso de la vivienda propia. Va unos 22 meses por detrás del año en curso.

### `renta_hogar`

**2 · Renta neta media por hogar**

- **Unidad:** € por hogar y año
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.1
- **Definición:** Renta disponible media de los hogares de la sección.
- **Cálculo:** Cifra publicada por el INE (ADRH). En otros seccionados, media ponderada por el número de hogares (población entre tamaño medio del hogar), con el mismo estado que el indicador 1.
- **Lectura:** Es renta del hogar, con varios perceptores, no un sueldo. Es el denominador del alquiler mediano sobre renta media del barrio (14) y el ingreso de la ficha «hogar del barrio».

### `renta_uc_mediana`

**3 · Mediana de la renta por unidad de consumo**

- **Unidad:** € por unidad de consumo y año
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.1
- **Definición:** Mediana de la renta disponible por unidad de consumo (escala de la OCDE modificada): la mitad de la población de la sección vive en hogares con menos renta equivalente y la otra mitad, con más.
- **Cálculo:** Cifra publicada por el INE (ADRH) en cada escala; las medianas no se agregan. En otros seccionados se copia la de una sola sección de origen (la misma o la que aporta al menos el 95 % de los portales); si ninguna domina, queda sin dato.
- **Lectura:** Compara hogares de distinto tamaño. Es la base de los umbrales de pobreza relativa (indicador 5).

### `peso_salarios`

**4 · Peso de los salarios en la renta**

- **Unidad:** % de la renta bruta
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.2
- **Definición:** Parte de la renta bruta de los residentes de la sección que procede de salarios.
- **Cálculo:** Cifra publicada por el INE (ADRH, distribución por fuente de ingresos: salarios, pensiones, prestaciones por desempleo, otras prestaciones y otros ingresos, que suman 100). Los años publicados en otro seccionado se llevan al de 2021 como media ponderada por la renta bruta de cada sección (renta bruta media por persona × población); si hay que repartir alguna sección, el estado pasa a «estimado». Municipios, provincias, comunidades y España, con la cifra publicada.
- **Lectura:** Une la renta del barrio con los salarios: con un peso bajo, la renta depende más de pensiones, prestaciones u otras rentas. Sin dato en Álava hasta 2019, en Gipuzkoa en 2015 y en casi toda Navarra hasta 2020.

### `bajo_60_mediana`

**5 · Población por debajo del 60 % de la mediana de renta por unidad de consumo**

- **Unidad:** % de la población
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.2
- **Definición:** Población con ingresos por unidad de consumo por debajo del 60 % de la mediana de España (hasta 2022, de la del territorio fiscal común, sin el País Vasco ni Navarra).
- **Cálculo:** Cifra publicada por el INE (ADRH, umbrales relativos, ambos sexos). Los años publicados en otro seccionado se llevan al de 2021 como media ponderada por la población, porque el umbral es el mismo en toda España cada año; si hay que repartir alguna sección, el estado pasa a «estimado». Municipios, provincias, comunidades y España, con la cifra publicada.
- **Lectura:** Umbral estatal, no autonómico: un mismo ingreso cuenta igual en todo el territorio aunque el coste de la vida sea distinto. Ruptura en 2023: el umbral pasa de la mediana del territorio fiscal común a la de toda España. Sin dato en Álava hasta 2019, en Gipuzkoa en 2015 y en Navarra hasta 2020.

### `gini`

**6 · Índice de Gini**

- **Unidad:** índice (0–100)
- **Familia:** Capacidad de pago
- **Fuentes:** `ine_adrh`
- **Versión:** v0.2
- **Definición:** Índice de Gini de la renta por unidad de consumo de la sección: 0 si todos tienen la misma renta, 100 si una sola persona la concentra.
- **Cálculo:** Cifra publicada por el INE (ADRH), que antes de calcularlo sustituye el 1,5 % de las rentas más bajas y el 1,5 % de las más altas por el valor más próximo. En otros seccionados se copia el de una sola sección de origen (la misma o la que aporta al menos el 95 % de los portales); si ninguna domina, queda sin dato. Municipios, provincias, comunidades y España, con la cifra publicada.
- **Lectura:** Mide la desigualdad dentro del barrio, no entre barrios. Sin dato en Álava hasta 2019, en Gipuzkoa en 2015 y en Navarra hasta 2020.

### `salario_medio`

**7 · Salario medio anual por asalariado (total y de 26 a 35 años)**

- **Unidad:** € por asalariado y año (bruto)
- **Familia:** Capacidad de pago
- **Fuentes:** `aeat_mercado_trabajo`
- **Versión:** v0.2
- **Definición:** Salario medio anual bruto de los asalariados con domicilio fiscal en la provincia, en total y de 26 a 35 años.
- **Cálculo:** Cifra publicada por la AEAT (Mercado de trabajo y pensiones en las fuentes tributarias, tabla por provincia, edad y sexo): salarios / asalariados, en total y del tramo de 26 a 35 años; la comunidad y España, con su cifra publicada. El País Vasco y Navarra no están en la estadística (domicilio fiscal foral) y van sin dato.
- **Lectura:** Es salario real del año: incluye a quien trabajó pocos meses. Es una media, no una mediana; la ficha «joven de 26 a 35» la pasa a mediana con la relación mediana/media del salario medio estimado de su comunidad y después a neto mensual repartido en 12, con la cotización del trabajador y la retención media de la AEAT por comunidad y tramo de renta (plan §3.1, método B).

### `alquiler_mes`

**8 · Alquiler mensual (mediana)**

- **Unidad:** € por mes
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `mivau_serpavi`, `gv_emal`
- **Versión:** v0.1
- **Definición:** Mediana del alquiler mensual de los contratos de vivienda habitual vigentes en la sección, por tipología (colectiva y unifamiliar); se publican también el primer y el tercer cuartil.
- **Cálculo:** Cifra publicada por el MIVAU (SERPAVI), a partir de los alquileres declarados en el IRPF y del Catastro, en el seccionado de 2021 para toda la serie. Sin dato con menos de 10 contratos.
- **Lectura:** Es el parque alquilado, no los contratos nuevos: quien entra hoy paga más. Solo cuenta a los caseros que son personas físicas y declaran el alquiler como vivienda habitual en el IRPF: deja fuera las sociedades y la vivienda pública, el alquiler no declarado y el alquiler a parientes (metodología del MIVAU, 18-mar-2026). El País Vasco y Navarra entran en el SERPAVI entre 2021 y 2024.

### `alquiler_m2`

**9 · Alquiler por metro cuadrado**

- **Unidad:** € por m² y mes
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `mivau_serpavi`, `gv_emal`
- **Versión:** v0.1
- **Definición:** Mediana del alquiler mensual por metro cuadrado de los contratos de vivienda habitual vigentes en la sección, por tipología (colectiva y unifamiliar).
- **Cálculo:** Cifra publicada por el MIVAU (SERPAVI), con la superficie del Catastro.
- **Lectura:** Permite comparar secciones con viviendas de distinto tamaño y es la base del sueldo necesario (21). Mismo universo que el 8: solo caseros que son personas físicas y declaran el alquiler en el IRPF.

### `var_alquiler`

**10 · Variación anual del alquiler**

- **Unidad:** % de variación anual
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `ine_ipva`
- **Versión:** v0.3
- **Definición:** Variación anual del Índice de Precios de Vivienda en Alquiler.
- **Cálculo:** Cifra publicada por el INE (IPVA), que sigue los mismos contratos y separa los nuevos de los ya existentes.
- **Lectura:** Es un índice, no un nivel de precio: sirve para la tendencia, no para comparar cuánto se paga.

### `precio_compra_m2`

**11 · Precio de compraventa por metro cuadrado**

- **Unidad:** € por m²
- **Familia:** Coste de la vivienda
- **Fuentes:** `registradores`
- **Versión:** v0.3
- **Definición:** Precio medio por metro cuadrado de las compraventas de vivienda inscritas en los registros de la propiedad.
- **Cálculo:** Cifra publicada por el Colegio de Registradores (Estadística Registral Inmobiliaria, datos abiertos con licencia ODbL): precio medio por m² de vivienda del año, el del cuarto trimestre, que acumula el año natural; provincia, comunidad y España, cada uno con su cifra publicada.
- **Lectura:** Es precio de compraventa inscrita, no de oferta ni de tasación. No se compara con el precio por m² del Notariado, que mide otra superficie; provincia como nivel más fino.

### `valor_tasado_m2`

**12 · Valor tasado por metro cuadrado**

- **Unidad:** € por m²
- **Familia:** Coste de la vivienda
- **Fuentes:** `mivau_valor_tasado`
- **Versión:** v0.3
- **Definición:** Valor tasado medio por metro cuadrado de la vivienda libre.
- **Cálculo:** Cifra trimestral publicada por el MIVAU a partir de las tasaciones hipotecarias; el año es la media de sus cuatro trimestres ponderada por el número de tasaciones.
- **Lectura:** Valor de tasación, no precio pagado; solo municipios de más de 25.000 habitantes.

### `precio_oferta`

**13 · Precio de oferta (alquiler y venta)**

- **Unidad:** € por m² (alquiler: por m² y mes)
- **Familia:** Coste de la vivienda · Entrar
- **Fuentes:** `portales`
- **Versión:** v0.4
- **Definición:** Precio medio por metro cuadrado de los anuncios de alquiler y de venta.
- **Cálculo:** Cifra mensual de los informes agregados de la sala de prensa de cada portal (Idealista: extracción del autor, casada con los códigos del INE en inventario/portales\_idealista\_territorios.csv; formato en R/fuente\_portales.R); nunca anuncios individuales. Un valor por año, portal y operación: la media de los meses publicados, con 9 como mínimo (con menos, sin dato), o la cifra anual si el portal la publica; en cada nivel, la que publica el portal para ese nivel. El último mes del año ya no se usa (10-nov-2026). Capa desmontable (PORTALES=FALSE por defecto) y solo web: no está en la tabla larga ni en las descargas.
- **Lectura:** Es precio de oferta, un dato privado de oferta: no se mezcla con contratos, escrituras ni tasaciones, ni un portal con otro.

### `esfuerzo_residentes`

**14 · Alquiler mediano sobre renta media del barrio**

- **Unidad:** % de la renta del hogar
- **Familia:** Esfuerzo · Quedarse
- **Fuentes:** `mivau_serpavi`, `ine_adrh`
- **Versión:** v0.1
- **Definición:** Parte de la renta anual del hogar medio de la sección, la de todos sus hogares (propietarios incluidos), que se iría en el alquiler mediano de esa misma sección.
- **Cálculo:** Alquiler mensual mediano de la vivienda colectiva × 12 / renta neta media por hogar, del mismo año, × 100. Sección censal y municipio. Si alguno de los dos términos está en secreto o falta, la cifra también.
- **Lectura:** No es el esfuerzo de quien alquila: divide el alquiler de los contratos vigentes entre la renta media de todos los hogares de la sección, propietarios incluidos, y apenas distingue barrios (en 2024, mediana del 18,3 % en el quintil de secciones con menos renta por hogar y del 17,5 % en el de más). Los barrios caros parecen asequibles porque los habita gente con más renta.

### `peso_alquiler_ingreso`

**15 · Peso del alquiler en el ingreso**

- **Unidad:** % del ingreso de referencia
- **Familia:** Esfuerzo · Quedarse
- **Fuentes:** `mivau_serpavi`, `aeat_mercado_trabajo`, `boe_smi`, `inss_pensiones`
- **Versión:** v0.1
- **Definición:** Parte del ingreso neto mensual de una ficha (salario mínimo, joven, pensionista o el sueldo del usuario) que se iría en el alquiler de 50 m² de la sección.
- **Cálculo:** Alquiler mediano por m² de la vivienda colectiva × 50 / ingreso neto mensual de la ficha repartido en 12 pagas, × 100. Se calcula en la web con la ficha elegida, con el ingreso de la ficha del mismo año que el alquiler (el salario mínimo, el salario del joven y la pensión de cada año, de 2015 a 2024); si la ficha no tiene ese año, se usa el último y se indica.
- **Lectura:** Mide lo que se llevaría el alquiler de los contratos vigentes de la sección (quien ya vive de alquiler) con un ingreso dado; no es el precio de entrar hoy, que mide la oferta. Se lee por tramos (hasta el 30 %, del 30 al 40 % y más del 40 %), no como cifra exacta.

### `anios_salario_compra`

**16 · Años de salario para comprar**

- **Unidad:** años
- **Familia:** Esfuerzo
- **Fuentes:** `mivau_valor_tasado`, `aeat_mercado_trabajo`
- **Versión:** v0.3
- **Definición:** Años de salario bruto de referencia que costaría comprar una vivienda tipo.
- **Cálculo:** Valor tasado por m² × superficie tipo (80 m² por defecto) / salario medio anual bruto por asalariado (AEAT), del mismo año; en un municipio, el salario de su provincia.
- **Lectura:** Usa el valor de tasación, no el precio escriturado, y no tiene en cuenta la financiación ni la entrada; ver la cuota hipotecaria sobre la renta del hogar (17). Sin dato en País Vasco y Navarra, sin salario de la AEAT.

### `esfuerzo_hipotecario`

**17 · Cuota hipotecaria sobre la renta del hogar**

- **Unidad:** % de la renta del hogar
- **Familia:** Esfuerzo
- **Fuentes:** `mivau_valor_tasado`, `ine_adrh`, `bde_accesibilidad`
- **Versión:** v0.3
- **Definición:** Parte de la renta neta media de los hogares del territorio que se iría en la cuota del primer año de una hipoteca sobre un piso de 80 m².
- **Cálculo:** Cuota anual del primer año de un préstamo francés sobre el 80 % del valor tasado de 80 m², a 25 años y al tipo de los préstamos nuevos para adquisición de vivienda del Banco de España (media de los doce meses del año), dividida entre la renta neta media por hogar del ADRH (INE) del mismo año y territorio, × 100. La renta es la publicada en cada nivel; donde el INE no la publica, sin dato en la provincia y la comunidad (Navarra hasta 2020, Álava y el País Vasco hasta 2019, Gipuzkoa en 2015) y, en España hasta 2020, la media de los municipios ponderada por hogares, estimada.
- **Lectura:** Es una cuenta teórica: supone que se tiene el 20 % restante y los gastos de compra. No es el «esfuerzo teórico del primer año» del Banco de España de la Máquina del tiempo: la cuenta es la misma, pero el Banco de España usa la vivienda tipo que define y la renta del hogar mediano, y aquí van un piso de 80 m² y la renta neta media de todos los hogares del territorio, que es más alta. Por eso esta cifra da en torno a la mitad (España, 2024: 18,1 % aquí y 34,6 % de media en el Banco de España).

### `hogares_alquiler`

**18 · Hogares en alquiler**

- **Unidad:** % de los hogares
- **Familia:** Estructura y presión
- **Fuentes:** `ine_censo2021`, `ine_censo2011`
- **Versión:** v0.1
- **Definición:** Hogares que viven de alquiler sobre el total de hogares (viviendas principales) de la sección.
- **Cálculo:** Cifra de los Censos de Población y Viviendas 2021 y 2011 del INE, en el seccionado de 2021; la de 2011, llevada desde las secciones del Censo 2011 con su tabla de paso.
- **Lectura:** Es una fotografía de dos fechas, no una serie anual. El Censo 2011 es muestral: sus cifras por sección son estimaciones.

### `viviendas_turisticas`

**19 · Viviendas de uso turístico sobre el total de viviendas**

- **Unidad:** % de las viviendas
- **Familia:** Estructura y presión
- **Fuentes:** `ine_vut`
- **Versión:** v0.1
- **Definición:** Viviendas de uso turístico sobre el total de viviendas de la sección.
- **Cálculo:** Viviendas turísticas de la estadística experimental del INE (anuncios de plataformas) sobre el total de viviendas del Censo, el denominador que usa el INE: el de 2011 hasta febrero de 2023 y el de 2021 desde agosto de 2023. De agosto de 2020 a febrero de 2023, en las secciones del Censo 2011, y desde febrero de 2024, en el seccionado de 2024, llevados al de 2021 con su tabla de paso; semestral.
- **Lectura:** Mide la presión del uso turístico. Numerador y denominador no son del mismo año: las viviendas son las del Censo 2011 hasta febrero de 2023 y las del Censo 2021 desde febrero de 2024. Los meses de referencia cambiaron en 2024 (de febrero y agosto a mayo y noviembre).

### `zona_tensionada`

**20 · Zona de mercado residencial tensionado declarada**

- **Unidad:** categoría (2 todo el municipio, 1 una parte, 0 ninguna)
- **Familia:** Estructura y presión
- **Fuentes:** `zonas_tensionadas`
- **Versión:** v0.4
- **Definición:** Municipio o ámbito declarado zona de mercado residencial tensionado al amparo de la Ley 12/2023, en vigor a 31 de diciembre de cada año.
- **Cálculo:** Resoluciones trimestrales del MIVAU en el BOE con la relación de zonas declaradas por las comunidades autónomas (art. 18.2.d): vigencia de tres años desde el día siguiente a la publicación. 2 si la declaración cubre todo el municipio; 1 si cubre una parte (núcleos, barrios o distritos), que se pinta en el municipio entero con su propia categoría; 0 sin declaración en vigor.
- **Lectura:** Es una capa de política pública, no una medida del mercado: dice dónde rigen las medidas de la Ley 12/2023 (límites a la renta de los nuevos contratos y definición propia de gran tenedor), no cuánto cuesta la vivienda.

### `sueldo_necesario`

**21 · Sueldo neto necesario para no pasar del umbral**

- **Unidad:** € netos por mes
- **Familia:** Esfuerzo · Quedarse
- **Fuentes:** `mivau_serpavi`
- **Versión:** v0.1
- **Definición:** Sueldo neto mensual necesario para que el alquiler mensual mediano de la sección no pase del 30 % del sueldo. Al lado, el mínimo teórico: el mismo cálculo con un piso de 50 m².
- **Cálculo:** Alquiler mensual mediano de la vivienda colectiva / 0,30 (umbral cambiable al 40 %). Mínimo teórico (corte superficie, grupo 50): alquiler mediano por m² de la vivienda colectiva × 50 / 0,30 (superficie cambiable a 70 y 90 m² en la web). Cada cifra lleva el estado de su alquiler.
- **Lectura:** Es el alquiler expresado en otra unidad, no un indicador nuevo. La cifra principal paga la vivienda alquilada mediana de la sección, de unos 79 m² de mediana; el mínimo de 50 m² queda por debajo y no se da sin ella. El umbral del 30 % se inspira en el criterio de zona tensionada de la Ley 12/2023, que usa renta del hogar y suministros; no es ese criterio.

### `sobrecarga`

**22 · Tasa de sobrecarga por gastos de vivienda (método Eurostat)**

- **Unidad:** % de las personas
- **Familia:** Sobrecarga y acceso (encuesta)
- **Fuentes:** `ine_ecv`, `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r`
- **Versión:** v0.1
- **Definición:** Personas que viven en hogares cuyo gasto total en vivienda, neto de ayudas, supera el 40 % de su renta disponible, también neta de ayudas.
- **Cálculo:** Microdatos de la ECV con el método de Eurostat: de la hipoteca, solo los intereses; renta del año anterior; ponderación por persona. Reproduce las cifras de Eurostat (±0,1 puntos). Los cruces por comunidad, tenencia y edad agrupan tres olas.
- **Lectura:** Mide la carga de quien ya tiene casa; la dominan los propietarios sin hipoteca y no ve a quien no ha podido emanciparse. Se lee junto a la búsqueda de vivienda sin éxito (23) y por tenencia, sobre todo en el alquiler a precio de mercado.

### `busqueda_sin_exito`

**23 · Búsqueda de vivienda sin éxito**

- **Unidad:** % de las personas de 16 o más años
- **Familia:** Sobrecarga y acceso (encuesta)
- **Fuentes:** `ine_ecv_modulo`
- **Versión:** v0.1
- **Definición:** Personas de 16 o más años que han buscado vivienda activamente en los últimos 12 meses sin llegar a cambiarse.
- **Cálculo:** Cifra publicada por el INE en las tablas del módulo de 2025 de la ECV sobre dificultades de acceso a la vivienda, con la razón principal (sobre todo, el precio).
- **Lectura:** Es un corte único (2025). Ve a quien intenta entrar y no puede, al contrario que la sobrecarga.

### `contratos_alquiler`

**Auxiliar · Contratos de alquiler de la mediana**

- **Unidad:** contratos
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `mivau_serpavi`
- **Versión:** v0.1
- **Auxiliar de:** [`alquiler_mes`](#alquiler_mes), [`alquiler_m2`](#alquiler_m2), [`esfuerzo_residentes`](#esfuerzo_residentes), [`peso_alquiler_ingreso`](#peso_alquiler_ingreso), [`sueldo_necesario`](#sueldo_necesario)
- **Definición:** Número de contratos de vivienda habitual vigentes con que el SERPAVI calcula la mediana del alquiler del territorio, por tipología (colectiva y unifamiliar).
- **Cálculo:** Recuento publicado por el MIVAU (SERPAVI). Con menos de 10 contratos no se publica la mediana; con 0, no hay contratos de alquiler registrados, que no es lo mismo que «sin dato».
- **Lectura:** Dice cuántos contratos sostienen la mediana: con menos de 30, la ficha marca «pocos contratos». Acompaña al 8, el 9, el 14, el 15 y el 21; no tiene mapa propio.

### `margen_alquiler_mes`

**Auxiliar · Margen aproximado de la mediana del alquiler mensual**

- **Unidad:** % de la mediana
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `calculo_propio`, `mivau_serpavi`
- **Versión:** v0.1
- **Auxiliar de:** [`alquiler_mes`](#alquiler_mes), [`esfuerzo_residentes`](#esfuerzo_residentes), [`sueldo_necesario`](#sueldo_necesario)
- **Definición:** Error típico aproximado de la mediana del alquiler mensual (8), en porcentaje de la mediana, por tipología.
- **Cálculo:** 0,929 × (P75 − P25) / (P50 × √n), con los cuartiles y los contratos (n) del SERPAVI; solo donde se publica la mediana (10 o más contratos).
- **Lectura:** Orden de magnitud del ruido de la mediana: supone una distribución regular dentro del territorio y no corrige que sean contratos vigentes, no nuevos. Acompaña al 8, al 14 y a la cifra principal del 21, que son el alquiler mensual en otra unidad.

### `margen_alquiler_m2`

**Auxiliar · Margen aproximado de la mediana del alquiler por m²**

- **Unidad:** % de la mediana
- **Familia:** Coste de la vivienda · Quedarse
- **Fuentes:** `calculo_propio`, `mivau_serpavi`
- **Versión:** v0.1
- **Auxiliar de:** [`alquiler_m2`](#alquiler_m2), [`peso_alquiler_ingreso`](#peso_alquiler_ingreso)
- **Definición:** Error típico aproximado de la mediana del alquiler por metro cuadrado (9), en porcentaje de la mediana, por tipología.
- **Cálculo:** 0,929 × (P75 − P25) / (P50 × √n), con los cuartiles del alquiler por m² y los contratos (n) del SERPAVI; solo donde se publica la mediana (10 o más contratos).
- **Lectura:** Vale también para el 15 y para el mínimo de 50 m² del 21, que son el alquiler por m² en otra unidad: la ficha avisa cuando «¿te llega?» queda en el límite entre dos tramos.

