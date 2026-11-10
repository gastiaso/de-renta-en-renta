// Pruebas sin navegador de la portada (index.html; docs/especificacion_portada.md) y de lo que
// cambia en el mapa con ella (mapa.html): redirección de los enlaces viejos de la raíz, destinos de
// las casillas y de las fichas, menús de todas las páginas, «Tu sueldo» de la portada (el sueldo
// nunca en la consulta), cartas, dado, clave `territorio` del estado (tarea 26), comparador y
// cálculo por niveles, y el desglose de las pagas en la ficha (F3).
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/portada.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import vm from 'node:vm';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leerJson = (...ruta) => JSON.parse(leerTexto(...ruta));

const { CLAVES, leerEstado, consulta, leerTerritorio, territorioATexto, fragmentoSueldo } = await modulo('web/js/estado.js');
const portada = await modulo('web/js/portada.js');
const { codigoComparado, nivelesSuperiores } = await modulo('web/js/comparador.js');
const sueldo = await modulo('web/js/sueldo.js');
const { textoIngresoPeon, equivalenciasSueldo, nombresTerritorio } = await modulo('web/js/ficha.js');
const exportar = await modulo('web/js/exportar.js');

// Script clásico de la redirección, ejecutado con una dirección inventada. Devuelve adónde va.
function redirigir(search, hash) {
  const ventana = { location: { search, hash, replace(d) { ventana.destino = d; } }, document: {}, URLSearchParams, destino: null };
  vm.runInNewContext(leerTexto('web', 'js', 'redireccion.js'), { window: ventana, globalThis: ventana, URLSearchParams });
  return ventana;
}

// Casillas de la portada tal como están en el HTML: [{ clases, id, href, hrefEn, texto }].
function casillasHtml() {
  const html = leerTexto('web', 'index.html');
  const bloque = html.split('<!-- casillas:inicio')[1].split('<!-- casillas:fin -->')[0];
  return [...bloque.matchAll(/<li class="([^"]+)" data-casilla="([^"]+)"[^>]*>(.*?)<\/li>/g)].map(([, clases, id, cuerpo]) => ({
    clases: clases.split(' '), id,
    href: /<a href="([^"]+)"/.exec(cuerpo)?.[1]?.replaceAll('&amp;', '&') ?? null,
    hrefEn: /data-href-en="([^"]+)"/.exec(cuerpo)?.[1]?.replaceAll('&amp;', '&') ?? null,
    texto: /data-texto-es="([^"]+)"/.exec(cuerpo)?.[1] ?? '',
  }));
}

const partes = (destino) => {
  const [, pagina, busqueda = '', ancla = ''] = /^([^?#]*)(\?[^#]*)?(#.*)?$/.exec(destino);
  return { pagina, busqueda, ancla: ancla.slice(1) };
};
const ids = (html) => new Set([...html.matchAll(/\bid="([^"]+)"/g)].map((x) => x[1]));

// --- Redirección -----------------------------------------------------------------------------

test('redirección: la lista de claves es la de estado.js sin el idioma', () => {
  const v = redirigir('', '');
  assert.deepEqual([...v.CLAVES_MAPA].sort(), CLAVES.filter((c) => c !== 'idioma').sort());
});

test('redirección: un enlace viejo a la raíz abre mapa.html con la misma consulta y el mismo fragmento', () => {
  assert.equal(redirigir('?mapa=alquiler_mes&anio=2024', '').destino, 'mapa.html?mapa=alquiler_mes&anio=2024');
  assert.equal(redirigir('?seccion=2807901001&idioma=en', '').destino, 'mapa.html?seccion=2807901001&idioma=en');
  assert.equal(redirigir('', '#sueldo=1500&pagas=14').destino, 'mapa.html#sueldo=1500&pagas=14');
  assert.equal(redirigir('?ficha=peon', '#sueldo=1500').destino, 'mapa.html?ficha=peon#sueldo=1500');
  assert.equal(redirigir('', '#tu-sueldo').destino, 'mapa.html#tu-sueldo');
  assert.equal(redirigir('?vista=6.00/40.00000/-3.70000', '').destino, 'mapa.html?vista=6.00/40.00000/-3.70000');
  // Sin nada del mapa (o solo el idioma), se queda la portada
  assert.equal(redirigir('', '').destino, null);
  assert.equal(redirigir('?idioma=en', '').destino, null);
  assert.equal(redirigir('', '#portada-sueldo').destino, null);
});

test('redirección: el script va en el <head> de la portada antes que los estilos y es síncrono', () => {
  const html = leerTexto('web', 'index.html');
  const cabeza = html.split('</head>')[0];
  const script = cabeza.indexOf('<script src="js/redireccion.js"></script>');
  assert.ok(script > 0, 'falta el script de la redirección');
  assert.ok(script < cabeza.indexOf('<link rel="stylesheet"'), 'antes de los estilos');
});

// --- Casillas, fichas y menús --------------------------------------------------------------

test('casillas: 24, en el HTML como lista ordenada, activas con enlace e inactivas sin él', () => {
  const cs = casillasHtml();
  assert.equal(cs.length, 24);
  const csv = leerTexto('inventario', 'casillas_portada.csv').trim().split('\n').slice(1);
  const activas = new Set(csv.filter((l) => l.endsWith(',TRUE')).map((l) => l.split(',')[1]));
  for (const c of cs) {
    assert.equal(c.href !== null, activas.has(c.id), `${c.id}: enlace solo si está activa`);
    assert.equal(c.clases.includes('casilla-inactiva'), !activas.has(c.id), c.id);
  }
  assert.ok(/<ol class="casillas">/.test(leerTexto('web', 'index.html')));
  assert.deepEqual(cs.filter((c) => c.clases.includes('casilla-esquina')).map((c) => cs.indexOf(c) + 1), [1, 7, 13, 19]);
});

test('casillas: cada destino existe (claves del mapa, mapas del manifiesto, anclas de las páginas)', () => {
  const real = existsSync(join(raiz, 'web', 'datos', 'manifiesto.json'));
  const m = real ? leerJson('web', 'datos', 'manifiesto.json') : null;
  const paginas = { 'mapa.html': ids(leerTexto('web', 'mapa.html')), 'sobrecarga.html': ids(leerTexto('web', 'sobrecarga.html')),
    'historico.html': ids(leerTexto('web', 'historico.html')) };   // F6, histórico
  for (const generada of ['metodo.html', 'method.html', 'datos.html', 'data.html']) {
    if (existsSync(join(raiz, 'web', generada))) paginas[generada] = ids(leerTexto('web', generada));
  }
  for (const c of casillasHtml().filter((x) => x.href)) {
    for (const destino of [c.href, c.hrefEn]) {
      const { pagina, busqueda, ancla } = partes(destino);
      assert.ok(['mapa.html', 'sobrecarga.html', 'historico.html', 'metodo.html', 'method.html', 'datos.html', 'data.html'].includes(pagina), `${c.id}: ${destino}`);
      if (pagina === 'mapa.html') {
        const p = new URLSearchParams(busqueda);
        const leido = leerEstado(busqueda);
        for (const clave of p.keys()) assert.ok(clave in leido, `${c.id}: clave ${clave} no válida en ${destino}`);
        if (m && p.get('mapa')) assert.ok(m.mapas[p.get('mapa')], `${c.id}: mapa ${p.get('mapa')} no está en el manifiesto`);
      }
      if (ancla && paginas[pagina]) assert.ok(paginas[pagina].has(ancla), `${c.id}: ancla #${ancla} no está en ${pagina}`);
    }
    if (['mapa.html', 'sobrecarga.html', 'historico.html'].includes(partes(c.href).pagina)) {
      assert.equal(new URLSearchParams(partes(c.hrefEn).busqueda).get('idioma'), 'en', `${c.id}: el enlace inglés lleva el idioma`);
    }
  }
});

test('fichas de la portada: cinco, cada una al mapa con su ficha en «¿te llega?»', () => {
  const html = leerTexto('web', 'index.html');
  const fichas = [...html.matchAll(/class="ficha-enlace ficha-enlace-(\w+)" data-ficha="(\w+)" href="([^"]+)"/g)];
  assert.deepEqual(fichas.map((f) => f[2]), ['llave', 'mochila', 'tartera', 'transistor', 'peon']);
  for (const [, clase, ficha, href] of fichas) {
    assert.equal(clase, ficha);
    assert.equal(leerEstado(partes(href).busqueda).ficha, ficha);
    assert.equal(partes(href).pagina, 'mapa.html');
    assert.ok(existsSync(join(raiz, 'web', 'estilo', 'fichas', `${ficha}.svg`)), `icono de ${ficha}`);
  }
});

test('menús: «Mapa» va a mapa.html y el título a la portada, en todas las páginas', () => {
  const mapa = leerTexto('web', 'mapa.html');
  assert.match(mapa, /<a href="mapa\.html" aria-current="page" data-i18n="nav\.mapa">/);
  assert.match(mapa, /<h1 class="marca-titulo"><a href="\.\/" data-href-es="\.\/" data-href-en="\.\/\?idioma=en"/);
  const portadaHtml = leerTexto('web', 'index.html');
  assert.match(portadaHtml, /<a href="mapa\.html"[^>]*data-i18n="nav\.mapa">/);
  assert.match(portadaHtml, /<a href="mapa\.html#tu-sueldo"[^>]*data-i18n="nav\.tu_sueldo">/);
  const sc = leerTexto('web', 'sobrecarga.html');
  assert.match(sc, /<a href="mapa\.html" data-pagina="mapa\.html" data-enlace="" data-i18n="nav\.mapa">/);
  assert.match(sc, /<a href="mapa\.html#tu-sueldo" data-pagina="mapa\.html" data-enlace="#tu-sueldo"/);
  assert.match(sc, /class="marca-titulo"><a href="\.\/" data-pagina="\.\/"/);
  const plantilla = leerTexto('web', 'herramientas', 'plantilla_documento.html');
  assert.match(plantilla, /<p class="marca-titulo"><a href="\$portada\$">/);
  assert.match(plantilla, /<a href="\$tu_sueldo\$">\$texto_tu_sueldo\$<\/a>/);
  for (const idioma of ['es', 'en']) {
    const yaml = leerTexto('web', 'herramientas', `documento_${idioma}.yaml`);
    assert.match(yaml, idioma === 'es' ? /^mapa: "mapa\.html"$/m : /^mapa: "mapa\.html\?idioma=en"$/m);
    assert.match(yaml, /^portada: "\.\/(\?idioma=en)?"$/m);
    assert.match(yaml, /^tu_sueldo: "mapa\.html(\?idioma=en)?#tu-sueldo"$/m);
  }
  assert.match(leerTexto('.github', 'workflows', 'pages.yml'), /texto_tu_sueldo="\$\(jq -r \.nav\.tu_sueldo "\$dic"\)"/);
  // Ninguna página enlaza ya el mapa en la raíz
  for (const pagina of ['mapa.html', 'sobrecarga.html', 'index.html']) {
    assert.doesNotMatch(leerTexto('web', pagina), /href="\.\/#tu-sueldo"|data-i18n="nav\.mapa"[^>]*href="\.\/"/, pagina);
  }
});

test('el mapa tiene el ancla de «Tu sueldo» y el hueco de la etiqueta', () => {
  const ids_ = ids(leerTexto('web', 'mapa.html'));
  assert.ok(ids_.has('tu-sueldo'));
  assert.ok(ids_.has('mapa-etiqueta'));
});

// --- «Tu sueldo», cartas y dado ----------------------------------------------------------------

test('«Tu sueldo» de la portada: el sueldo va tras «#», nunca en la consulta', () => {
  assert.equal(portada.leerSueldo('1500'), 1500);
  assert.equal(portada.leerSueldo('1.500'), 1500);
  assert.equal(portada.leerSueldo('1500,50'), 1500.5);
  assert.equal(portada.leerSueldo(' 1 500 € '), 1500);
  assert.equal(portada.leerSueldo('abc'), null);
  assert.equal(portada.leerSueldo('0'), null);
  assert.equal(portada.leerSueldo('200000'), null);
  const enlace = portada.enlaceTeLlega(1500, 'es');
  assert.equal(enlace, 'mapa.html?ficha=peon#sueldo=1500');
  assert.equal(portada.enlaceTeLlega(1500, 'en'), 'mapa.html?ficha=peon&idioma=en#sueldo=1500');
  const [consultaEnlace] = enlace.split('#');
  assert.doesNotMatch(consultaEnlace, /1500|sueldo/);
  assert.equal(fragmentoSueldo({ neto: 1500, pagas: 14, segundo: 900 }), '#sueldo=1500&pagas=14&segundo=900');
  assert.equal(fragmentoSueldo(null), '');
});

test('enlaces con idioma', () => {
  assert.equal(portada.conIdioma('mapa.html', 'es'), 'mapa.html');
  assert.equal(portada.conIdioma('mapa.html', 'en'), 'mapa.html?idioma=en');
  assert.equal(portada.conIdioma('mapa.html?seccion=2807901001', 'en'), 'mapa.html?seccion=2807901001&idioma=en');
  assert.equal(portada.conIdioma('mapa.html#tu-sueldo', 'en'), 'mapa.html?idioma=en#tu-sueldo');
});

test('cartas: solo las que tienen todos sus términos, nunca «—»', () => {
  const datos = {
    cartas: {
      sueldo: { anio: 2024, secciones: 26137, p10: 700, mediana: 1216.7, p90: 2116.7, superficie_m2: 50, umbral: 30, mapa: 'sueldo_necesario', fuentes: ['mivau_serpavi'] },
      smi: { anio: 2024, secciones: 26137, pct_30: 48.4, pct_40: 24.7, superficie_m2: 50, ficha: 'tartera', neto_mensual: 1237.4, fuentes: ['mivau_serpavi'] },
      sobrecarga: { anio: 2025, total: 7.2, alquiler_mercado: null, fuentes: ['ine_ecv'] },
    },
  };
  const cartas = portada.cartasDe(datos);
  assert.deepEqual(cartas.map((c) => c.id), ['sueldo', 'smi']);
  assert.equal(cartas[0].enlace, 'mapa.html?mapa=sueldo_necesario&anio=2024');
  assert.equal(cartas[1].enlace, 'mapa.html?ficha=tartera&anio=2024');
  assert.deepEqual(portada.cartasDe(null), []);
  assert.deepEqual(portada.cartasDe({ cartas: { smi: { anio: 2024 } } }), []);
});

test('cartas: cada texto tiene sus marcas en los dos idiomas', () => {
  for (const idioma of ['es', 'en']) {
    const dic = leerJson('web', 'i18n', `${idioma}.json`);
    const marcas = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort();
    assert.deepEqual(marcas(dic.portada.cartas.sueldo.texto), ['anio', 'mediana', 'p10', 'p90', 'superficie', 'umbral']);
    assert.deepEqual(marcas(dic.portada.cartas.smi.texto), ['anio', 'neto', 'pct30', 'pct40', 'superficie']);
    assert.deepEqual(marcas(dic.portada.cartas.sobrecarga.texto), ['anio', 'mercado', 'total']);
  }
});

test('dado: una sección con dato, al azar', () => {
  const secciones = ['a', 'b', 'c', 'd'];
  const estados = Uint8Array.from([3, 0, 2, 0]);
  assert.equal(portada.seccionAlAzar(secciones, estados, 0, () => 0), 'b');
  assert.equal(portada.seccionAlAzar(secciones, estados, 0, () => 0.99), 'd');
  assert.equal(portada.seccionAlAzar(secciones, Uint8Array.from([3, 3, 3, 3]), 0), null);
});

// --- Estado, comparador y cálculo por niveles (tarea 26) ---------------------------------------

test('estado: el territorio elegido entra en la URL validado', () => {
  assert.deepEqual(leerEstado('?territorio=municipio:28079'), { territorio: 'municipio:28079' });
  assert.deepEqual(leerEstado('?territorio=provincia:28&territorio=x'), { territorio: 'provincia:28' });
  assert.deepEqual(leerEstado('?territorio=ccaa:13'), { territorio: 'ccaa:13' });
  for (const malo of ['municipio:28', 'provincia:280', 'sc:2807901001', 'ccaa:1', 'pais:00', 'municipio:2807a']) {
    assert.deepEqual(leerEstado(`?territorio=${malo}`), {}, malo);
  }
  assert.equal(consulta({ territorio: 'municipio:28079', comparar: 'provincia' }), '?comparar=provincia&territorio=municipio:28079');
  assert.deepEqual(leerTerritorio('municipio:28079'), { nivel: 'municipio', codigo: '28079' });
  assert.equal(leerTerritorio('municipio:1'), null);
  assert.equal(territorioATexto('ccaa', '13'), 'ccaa:13');
});

test('comparador: un territorio se compara con los que lo contienen', () => {
  const territorios = { ccaa_de_provincia: { 28: '13' } };
  assert.deepEqual(nivelesSuperiores('municipio'), ['provincia', 'ccaa', 'nacional']);
  assert.deepEqual(nivelesSuperiores('ccaa'), ['nacional']);
  assert.deepEqual(codigoComparado('28079', 'provincia', territorios, 'municipio'), { nivel: 'provincia', codigo: '28' });
  assert.deepEqual(codigoComparado('28079', 'ccaa', territorios, 'municipio'), { nivel: 'ccaa', codigo: '13' });
  assert.deepEqual(codigoComparado('28', 'ccaa', territorios, 'provincia'), { nivel: 'ccaa', codigo: '13' });
  assert.deepEqual(codigoComparado('13', 'nacional', territorios, 'ccaa'), { nivel: 'nacional', codigo: '00' });
  assert.equal(codigoComparado('13', 'ccaa', territorios, 'ccaa'), null);
  assert.equal(codigoComparado('28079', 'distrito', territorios, 'municipio'), null);
  assert.equal(codigoComparado('28079', '2807901001', territorios, 'municipio'), null);
  // La sección, como antes
  assert.deepEqual(codigoComparado('2807901001', 'distrito', territorios), { nivel: 'distrito', codigo: '2807901' });
});

test('«¿te llega?» por niveles: en una comunidad, sin ingreso provincial', () => {
  const perfiles = {
    mochila: { nivel: 'provincia', neto_mensual: { 13: 900, 28: 1400 } },
    tartera: { nivel: 'nacional', neto_mensual: { '00': 1237.4 } },
  };
  const x = () => 10;
  const enMunicipio = sueldo.calculoLlega({ ficha: 'mochila', perfiles, superficie: 50, nivel: 'municipio' });
  assert.equal(enMunicipio.calcular('28079', x).ingreso, 1400);
  const enCcaa = sueldo.calculoLlega({ ficha: 'mochila', perfiles, superficie: 50, nivel: 'ccaa' });
  assert.equal(enCcaa.calcular('13', x), null);           // no toma la provincia 13 (Ciudad Real)
  assert.equal(enCcaa.ingreso('13', x), null);
  assert.equal(enCcaa.expresion('ccaa').valido[2][1], 0);
  // El color de la capa de comunidades con la ficha de la sección (sin nivel), también sin ingreso
  const deSeccion = sueldo.calculoLlega({ ficha: 'mochila', perfiles, superficie: 50 });
  assert.equal(deSeccion.expresion('ccaa', 'ccaa').valido[2][1], 0);
  assert.notEqual(deSeccion.expresion('seccion').valido[2][1], 0);
  const tartera = sueldo.calculoLlega({ ficha: 'tartera', perfiles, superficie: 50, nivel: 'ccaa' });
  assert.equal(tartera.calcular('13', x).ingreso, 1237.4);   // la nacional vale en cualquier nivel
});

test('nombres de un territorio y los que lo contienen (ficha y etiqueta)', () => {
  const territorios = {
    municipio: { 28079: 'Madrid' }, provincia: { 28: 'Madrid', 15: 'Coruña, A' }, ccaa: { 13: 'Madrid, Comunidad de', 12: 'Galicia' },
    ccaa_de_provincia: { 28: '13', 15: '12' },
  };
  assert.deepEqual(nombresTerritorio('municipio', '28079', territorios).map((x) => x.nombre), ['Madrid', 'Madrid', 'Comunidad de Madrid']);
  assert.deepEqual(nombresTerritorio('provincia', '15', territorios).map((x) => [x.nivel, x.nombre]), [['provincia', 'A Coruña'], ['ccaa', 'Galicia']]);
  assert.deepEqual(nombresTerritorio('ccaa', '12', territorios).map((x) => x.nombre), ['Galicia']);
});

test('descargas: con las comunidades a la vista, el CSV sale por comunidad si la serie la tiene', () => {
  assert.equal(exportar.nivelParaExportar('ccaa', ['sc', 'distrito', 'municipio', 'provincia', 'ccaa']), 'ccaa');
  assert.equal(exportar.nivelParaExportar('ccaa', ['sc', 'municipio']), 'municipio');
  assert.equal(exportar.nivelParaExportar('provincia', ['sc', 'provincia', 'ccaa']), 'provincia');
});

// --- 14 pagas y segundo sueldo en la ficha (F3) ---------------------------------------------

test('ficha: el ingreso de «Tu ficha» desglosado y el sueldo necesario en 14 pagas y entre dos', async () => {
  const { cargarIdioma } = await modulo('web/js/i18n.js').catch(() => ({}));
  const dic = leerJson('web', 'i18n', 'es.json');
  // Traductor mínimo con el diccionario real (cargarIdioma usa fetch)
  const t = (clave, valores = {}) => clave.split('.').reduce((n, p) => n?.[p], dic).replace(/\{(\w+)\}/g, (m, k) => (k in valores ? valores[k] : m));
  t.numero = (x) => new Intl.NumberFormat('es-ES', { maximumFractionDigits: 0, useGrouping: 'always' }).format(x);
  assert.ok(cargarIdioma);
  const ingreso = (s) => sueldo.ingresoPeon(s);
  const s12 = { neto: 1500, pagas: 12, segundo: null };
  const s14 = { neto: 1500, pagas: 14, segundo: null };
  const s14b = { neto: 1500, pagas: 14, segundo: 900 };
  assert.equal(textoIngresoPeon(t, s12, ingreso(s12)), 'Tu ingreso: 1.500 € al mes.');
  assert.equal(textoIngresoPeon(t, s14, ingreso(s14)), 'Tu ingreso: 1.500 € × 14 pagas ÷ 12 = 1.750 € al mes.');
  assert.equal(textoIngresoPeon(t, s14b, ingreso(s14b)), 'Tu ingreso: (1.500 € + 900 € del segundo sueldo) × 14 pagas ÷ 12 = 2.800 € al mes.');
  assert.equal(textoIngresoPeon(t, null, 1000), null);
  const eq = equivalenciasSueldo(1400);
  assert.equal(eq.paga14, 1200);
  assert.equal(eq.cadaUno, 700);
  assert.equal(equivalenciasSueldo(null), null);
  for (const idioma of ['es', 'en']) {
    const d = leerJson('web', 'i18n', `${idioma}.json`).interfaz.ficha.ingreso_peon;
    assert.deepEqual(Object.keys(d).sort(), ['12', '12_segundo', '14', '14_segundo']);
  }
});
