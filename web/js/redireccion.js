// Redirección de los enlaces ya compartidos al mapa (portada, docs/especificacion_portada.md, §1).
// Hasta la portada, la raíz del sitio era el mapa; ahora el mapa está en mapa.html. Si la dirección
// trae alguna clave del estado de la vista (js/estado.js, CLAVES) que no sea el idioma, o un sueldo
// compartido o el ancla de «Tu sueldo» en el fragmento, se sustituye por la misma en mapa.html,
// antes de pintar nada (script clásico y síncrono en el <head> de index.html). El idioma solo
// (`?idioma=en`) se queda en la portada, que también lo usa.
// Las pruebas (pruebas/web/portada.test.mjs) comprueban que la lista coincide con CLAVES.
(function (global) {
  var CLAVES_MAPA = ['mapa', 'anio', 'tipologia', 'ficha', 'superficie', 'umbral', 'seccion', 'comparar', 'vista', 'territorio', 'escala'];

  // Destino de una dirección de la raíz: 'mapa.html?…#…' o null (se queda la portada).
  function destinoRedireccion(busqueda, fragmento) {
    var parametros = new URLSearchParams(busqueda || '');
    var hash = fragmento || '';
    var deMapa = CLAVES_MAPA.some(function (clave) { return parametros.has(clave); });
    var sueldo = /^#(?:.*&)?sueldo=/.test(hash) || hash === '#tu-sueldo';
    return deMapa || sueldo ? 'mapa.html' + (busqueda || '') + hash : null;
  }

  global.CLAVES_MAPA = CLAVES_MAPA;
  global.destinoRedireccion = destinoRedireccion;
  if (global.location && global.document) {
    var destino = destinoRedireccion(global.location.search, global.location.hash);
    if (destino) global.location.replace(destino);
  }
})(typeof window !== 'undefined' ? window : globalThis);
