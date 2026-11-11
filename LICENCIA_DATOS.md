# Licencia de los datos y los textos

Los **datos derivados** que produce este proyecto (la tabla larga y los datos de la web, que se publican en los *releases* del repositorio), los **textos** (fichas, metodología, web) y el **inventario** (`inventario/`) se publican con licencia **Creative Commons Atribución-CompartirIgual 4.0 Internacional (CC BY-SA 4.0)**: <https://creativecommons.org/licenses/by-sa/4.0/deed.es>. Quien los reutilice o los transforme debe citar la fuente y publicar lo que derive de ellos con la misma licencia.

Decisión del autor (8-nov-2026): las fuentes se tratan como datos abiertos y los derivados se publican en CC BY-SA 4.0, que admite las fuentes con licencia CC BY y las que piden compartir igual (el catastro de Gipuzkoa).

Atribución sugerida: «De renta en renta (Guillermo Astiaso Llamazares), a partir de [fuente original]».

- Los **datos de origen** mantienen las condiciones de cada fuente. Están en `inventario/fuentes.csv` (columna `licencia`). Citar siempre también la fuente original. Qué licencia tiene cada fuente, qué obliga y qué se retira si alguna cambia: tabla única y plan de retirada de la nota metodológica (`docs/metodologia.md`, §2.2 y §2.4).
- Las **geometrías NUTS de Eurostat (GISCO)** del mapa europeo no entran en la licencia CC BY-SA 4.0: su uso es no comercial y lleva el aviso «© EuroGeographics para los límites administrativos».
- El **precio de compraventa por metro cuadrado** (indicador 11), que sale de la Estadística Registral Inmobiliaria del Colegio de Registradores (fuente `registradores`), se publica con la licencia de su fuente, la **Open Database License (ODbL) 1.0**: <https://opendatacommons.org/licenses/odbl/1-0/>. Sus filas de la tabla larga (`fuente` = `registradores`) y las bases de datos que deriven de ellas se reutilizan citando al Colegio de Registradores y, si se publican, con la misma licencia y abiertas. El paquete del *release* lo dice en `version.json` (`licencia`). Atribución sugerida: «Colegio de Registradores, Estadística Registral Inmobiliaria (datos abiertos, ODbL 1.0); elaboración: De renta en renta». No se mezcla con las cifras del Notariado.
- La **capa de precios de oferta de los portales** (Idealista) no se redistribuye: no entra en la tabla larga, ni en las descargas, ni en los *releases*. Solo la web la muestra, con su fuente, y está apagada («próximamente», `PORTALES=FALSE`) hasta que Idealista lo autorice por escrito.
- El **código** tiene su propia licencia (MIT, `LICENSE`).
