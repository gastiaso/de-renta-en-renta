# Método en dos páginas

*Borrador para la v1.0 (10-nov-2026). Describe el atlas tal como quedará con las dos familias; el sitio publicado sigue en la v0.1. La versión completa es `docs/metodologia.md`. Falta la versión inglesa.*

## Qué pregunta el atlas

¿A quién le queda sueldo después de pagar la vivienda? Dónde, desde cuándo y para quién ha cambiado la relación entre lo que cuesta la vivienda y lo que se cobra. Para quien ya está en el tablero y para quien entra nuevo en la partida.

## Dos familias que no se mezclan

| | Quedarse | Entrar |
|---|---|---|
| A quién mide | A quien ya vive de alquiler | A quien busca piso hoy |
| Fuente | SERPAVI (Ministerio de Vivienda), con datos de Hacienda y Catastro | Precios de oferta de Idealista; índice del INE de contratos nuevos |
| Qué es la cifra | Mediana del alquiler de los contratos vigentes | Precio medio que se pide en los anuncios |
| Escala | Sección censal | Municipio (286), provincia, comunidad y España |
| Periodo | 2015–2024 | 2006–2026 (municipios, sobre todo desde 2011) |
| De 2015 a 2024, en España | +42 % por m² | +72 % por m² |

Ninguna cifra del atlas combina las dos fuentes. Cuando aparecen juntas, cada una lleva su nombre.

## A quién deja fuera cada fuente

- **SERPAVI:**
  - sale de las declaraciones de IRPF de los caseros que son personas físicas: no recoge las viviendas de sociedades, los alquileres a parientes ni el alquiler no declarado (metodología del Ministerio de 18-mar-2026);
  - en Navarra hay dato desde 2021; en Gipuzkoa, desde 2022; en Álava y Bizkaia, solo de 2024;
  - mide el parque, no lo que paga quien entra;
  - con menos de 10 contratos no hay cifra: tiene dato el 72 % de las secciones, donde vive en torno al 83 % de la población.
- **Idealista:**
  - es precio de anuncio, no de contrato firmado;
  - cubre 286 municipios, donde vive el 59 % de la población;
  - sus zonas no coinciden con distritos ni secciones.
- **Índice del INE de contratos nuevos:** es un índice, no un precio; empieza en 2021 y llega hasta provincia. Sirve para contrastar la oferta: de 2021 a 2024, en España, los contratos nuevos subieron un 19 %; los existentes, un 8 %; la oferta de Idealista, un 24 %.
- **Renta de los hogares (INE):** es la de todos los hogares de la sección, propietarios incluidos, no la de quienes alquilan.
- **Salarios (Hacienda):** es lo cobrado en el año, que incluye a quien trabajó pocos meses. No cubre País Vasco ni Navarra.

## Cómo leer las cifras

- **Sueldo necesario.** Dos cifras siempre:
  - con el alquiler mediano real de la zona;
  - con un piso teórico de 50 m², como mínimo. Los pisos alquilados miden unos 79 m² de mediana.
- **Lo que queda.** Ingreso menos alquiler, en euros al mes. Es una resta: no dice si lo que queda alcanza para vivir.
- **Umbral del 30 %.** Es una convención. La misma proporción deja mucho menos margen a un sueldo bajo que a uno alto.
- **Fichas.** Cada perfil usa un ingreso distinto y lo declara:
  - hogar del barrio: media del hogar;
  - joven de 26 a 35: mediana estimada;
  - salario mínimo: cuantía legal;
  - pensionista: pensión media de jubilación.
- **Margen.** Cada mediana de alquiler lleva su número de contratos y un margen aproximado. Con menos de 30 contratos, la cifra es orientativa y las variaciones de un año no se interpretan.
- **Euros.** Las series están en euros corrientes, salvo que se indique.
- **Estados.** «Dato», «estimado» (reconstruido con una regla escrita), «secreto» (hay alquiler, pero menos de 10 contratos) y «sin dato».

## Licencias

| Fuente | Condición | Qué obliga |
|---|---|---|
| INE, IGN, Eurostat (datos) | CC BY 4.0 | Citar |
| Ministerio de Vivienda, Hacienda, Seguridad Social, Banco de España, BOE, CIS | Reutilización con cita | Citar la fuente y la fecha |
| Catastro estatal y forales de Bizkaia y Gipuzkoa | Contradictoria entre sus propias páginas | Se tratan como abiertos; plan de retirada si se aclara en contra |
| Geometrías europeas (GISCO) | Uso no comercial | Aviso de © EuroGeographics en el mapa |
| Idealista | Condiciones de su web | Solo se muestra en la web, con enlace al informe; no se descarga |
| Derivados del atlas | CC BY-SA 4.0 | Citar y compartir igual |

El detalle por fuente está en `inventario/fuentes.csv`.

## Citar y corregir

- **Cita:** «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]», con la fecha de los datos.
- **Errores:** se avisan en el repositorio (`CONTRIBUTING.md`). Las correcciones se anotan con fecha en el registro de cambios.
