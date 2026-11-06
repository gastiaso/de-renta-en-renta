# Web

No se toca hasta F2, salvo `estilo/tokens.css` (a partir de `diseno/tokens.json`) y los diccionarios de `i18n/`.

Previsto (plan, §6.6): MapLibre con PMTiles para las secciones, d3 para gráficos, dependencias y tipografías autoalojadas, sin servidor ni analítica, URL con el estado de la vista, castellano e inglés, exportación CSV y PNG. «Tu sueldo» calcula en el navegador: el sueldo del usuario no sale del dispositivo salvo que pulse «Compartir».

Diccionarios (`i18n/es.json`, `i18n/en.json`): las secciones `indicadores`, `fuentes` y `vocabulario` las genera el pipeline desde `inventario/` (`exportar_i18n()`) y no se editan a mano; `sitio`, `nav`, `fichas` y `avisos` se escriben aquí. La comprobación `i18n_completo` exige las mismas claves en los dos idiomas y ningún texto vacío.
