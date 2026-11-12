// Recorridos guiados por el mapa (backlog, tarea 49): lógica sin DOM de web/js/historias.js sobre
// la muestra inventada de pruebas/datos/historias_muestra.json (la forma del contrato con R), las
// claves `historia` y `paso` de estado.js, los textos de la interfaz y la entrada «Historias» del
// menú de todas las páginas. Con la exportación del pipeline (web/datos/historias.json), también el
// fichero real frente al contrato y el manifiesto. Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/historias.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leerJson = (...ruta) => JSON.parse(leerTexto(...ruta));
const H = await modulo('web/js/historias.js');
const { leerEstado, consulta, CLAVES } = await modulo('web/js/estado.js');
const muestra = () => leerJson('pruebas', 'datos', 'historias_muestra.json');
const i18n = { es: leerJson('web', 'i18n', 'es.json'), en: leerJson('web', 'i18n', 'en.json') };
const en = (dic, clave) => clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);

// --- Contrato ----------------------------------------------------------------------------------

test('la muestra cumple el contrato', () => {
  assert.deepEqual(H.validarHistorias(muestra()), []);
  assert.deepEqual(H.validarHistorias(muestra(), { mapas: ['alquiler_mes', 'anios_salario_compra'] }), []);
});

test('la validación detecta lo que rompe el contrato', () => {
  const casos = [
    [(d) => { delete d.historias; }, /historias/],
    [(d) => { d.historias[1].id = 'centro'; }, /repetido/],
    [(d) => { d.historias[0].id = 'Centro-1'; }, /id no válido/],
    [(d) => { d.historias[0].titulo.en = ''; }, /título: falta el texto en «en»/],
    [(d) => { d.historias[0].pasos = []; }, /sin pasos/],
    [(d) => { d.historias[0].pasos[0].texto.es = 'Con <b>negrita</b>'; }, /etiquetas HTML/],
    [(d) => { delete d.historias[0].pasos[1].fuente; }, /fuente: falta el texto/],
    [(d) => { delete d.historias[0].pasos[0].estado.vista; }, /falta la vista/],
    [(d) => { d.historias[0].pasos[0].estado.seccion = '2807901001'; }, /no admitida «seccion»/],
    [(d) => { d.historias[0].pasos[0].estado.ficha = 'peon'; }, /valor no válido de «ficha» \(peon\)/],
    [(d) => { d.historias[1].pasos[2].estado.ficha = 'casa'; }, /valor no válido de «ficha» \(casa\)/],
    [(d) => { d.historias[0].pasos[2].estado.territorio = 'municipio:280'; }, /valor no válido de «territorio»/],
    [(d) => { d.historias[0].pasos[2].estado.escala = 'nacional'; }, /valor no válido de «escala»/],
    [(d) => { d.historias[1].pasos[0].enlace.href = 'javascript:alert(1)'; }, /dirección del enlace/],
    [(d) => { d.historias[1].pasos[0].enlace.href = 'https://example.org/x.html'; }, /dirección del enlace/],
    [(d) => { delete d.historias[1].pasos[0].enlace.texto; }, /texto del enlace/],
    [(d) => { d.historias[0].pasos = Array(21).fill(d.historias[0].pasos[0]); }, /más de 20 pasos/],
  ];
  for (const [romper, error] of casos) {
    const d = muestra();
    romper(d);
    const errores = H.validarHistorias(d);
    assert.ok(errores.some((e) => error.test(e)), `${error}: ${errores.join('; ')}`);
  }
  assert.ok(H.validarHistorias(muestra(), { mapas: ['alquiler_mes'] }).some((e) => /anios_salario_compra.*manifiesto/.test(e)));
});

test('cargarHistorias: el fichero válido se lee; si falta, no se lee o no cumple, null', async () => {
  const respuesta = (ok, cuerpo) => async () => ({ ok, json: async () => (typeof cuerpo === 'function' ? cuerpo() : cuerpo) });
  const avisar = console.warn;
  console.warn = () => {};
  try {
    assert.equal((await H.cargarHistorias({ leer: respuesta(true, muestra()) })).historias.length, 2);
    assert.equal(await H.cargarHistorias({ leer: respuesta(false, null) }), null);
    assert.equal(await H.cargarHistorias({ leer: respuesta(true, () => { throw new SyntaxError('JSON'); }) }), null);
    assert.equal(await H.cargarHistorias({ leer: async () => { throw new TypeError('red'); } }), null);
    const rota = muestra();
    rota.historias[0].pasos[0].estado.ficha = 'peon';
    assert.equal(await H.cargarHistorias({ leer: respuesta(true, rota) }), null);
  } finally {
    console.warn = avisar;
  }
});

test('la nota del paso es opcional: vale con los dos idiomas, null o sin ella; no con uno solo ni con HTML', () => {
  const con = (nota) => { const d = muestra(); d.historias[0].pasos[0].nota = nota; return H.validarHistorias(d); };
  assert.equal(muestra().historias[0].pasos[0].nota.es, 'Nota inventada: cómo se mide la cifra.');
  assert.equal(muestra().historias[0].pasos[1].nota, null);
  assert.deepEqual(con(null), []);
  assert.deepEqual(con(undefined), []);
  assert.equal(con({ es: 'Solo en castellano' }).length, 1);
  assert.equal(con({ es: 'Con <b>marcado</b>', en: 'With markup' }).length, 1);
  assert.equal(con('texto suelto').length, 1);
  assert.equal(H.textoEn(null, 'es'), '');
});

// --- Pasos -------------------------------------------------------------------------------------

test('buscar historia y paso: sin paso, el 1; fuera de rango, el más cercano', () => {
  const d = muestra();
  assert.equal(H.buscarHistoria(d, 'anios').id, 'anios');
  assert.equal(H.buscarHistoria(d, 'no_existe'), null);
  assert.equal(H.buscarHistoria(null, 'centro'), null);
  const h = H.buscarHistoria(d, 'centro');
  assert.deepEqual([undefined, 1, 3, 4, 9, 0, -2, '2'].map((n) => H.pasoDe(h, n).n), [1, 1, 3, 4, 4, 1, 1, 2]);
  assert.equal(H.pasoDe(h, 3).total, 4);
  assert.equal(H.pasoDe(h, 3).paso.titulo.es, 'Paso A3');
  assert.equal(H.pasoDe(null, 1), null);
  assert.equal(H.pasoDe({ pasos: [] }, 1), null);
});

test('un paso con ficha de perfil deja el mapa en «¿te llega?» con ella y el año del paso; el siguiente sin ficha la quita', async () => {
  const { modoDe } = await modulo('web/js/sueldo.js');
  const perfiles = { tartera: { anios: { 2020: { '00': 1038 } } } };
  const h = H.buscarHistoria(muestra(), 'anios');
  assert.deepEqual(H.FICHAS_PASO, ['llave', 'mochila', 'tartera', 'transistor']);
  assert.ok(!H.CLAVES_QUITADAS.includes('ficha'));
  const estado = { mapa: 'alquiler_mes', seccion: '2807901001', ficha: 'peon', historia: 'anios', paso: 2 };
  Object.assign(estado, H.cambiosDePaso(H.pasoDe(h, 3).paso));
  assert.equal(estado.ficha, 'tartera');
  assert.equal(estado.anio, 2020);
  assert.equal(estado.seccion, undefined);
  assert.equal(modoDe(estado, null, perfiles), 'llega');
  assert.equal(consulta(estado), '?mapa=anios_salario_compra&anio=2020&ficha=tartera&vista=4.60/39.80000/-3.70000&historia=anios&paso=2');
  Object.assign(estado, H.cambiosDePaso(H.pasoDe(h, 2).paso));
  assert.equal(estado.ficha, undefined);
  assert.equal(modoDe(estado, null, perfiles), 'necesario');
  // El peón (el sueldo de quien visita) o una ficha que no existe no entran: el paso queda sin ficha
  assert.equal(H.cambiosDePaso({ estado: { vista: '11/40/-3', ficha: 'peon' } }).ficha, undefined);
  assert.equal(H.cambiosDePaso({ estado: { vista: '11/40/-3', ficha: 'casa' } }).ficha, undefined);
  // El enlace a otra historia (mapa.html con consulta) vale
  assert.equal(H.pasoDe(h, 3).paso.enlace.href, 'mapa.html?historia=centro');
  assert.equal(H.enlaceEnIdioma('mapa.html?historia=centro', 'en'), 'mapa.html?historia=centro&idioma=en');
});

test('un paso pasa a cambios de estado: sus claves, las ausentes quitadas y sin sección, comparación, ficha, tipología, superficie ni umbral', () => {
  const h = H.buscarHistoria(muestra(), 'centro');
  const tercero = H.cambiosDePaso(H.pasoDe(h, 3).paso);
  assert.deepEqual(tercero, {
    mapa: 'alquiler_mes', anio: 2024, vista: '11.30/40.42000/-3.70000', territorio: 'municipio:28079', escala: 'municipio',
    seccion: undefined, comparar: undefined, ficha: undefined, tipologia: undefined, superficie: undefined, umbral: undefined,
    gastos: undefined,   // otros gastos de vivienda (12-nov-2026): un paso los apaga
  });
  // Sin territorio ni escala en el paso: se quitan los que hubiera (escala nacional, sin ficha de territorio),
  // y también la superficie y el umbral elegidos antes: el mapa del paso, con los supuestos por defecto
  const estado = { idioma: 'en', mapa: 'renta_hogar', seccion: '2807901001', comparar: 'municipio', ficha: 'peon', tipologia: 'VU',
    territorio: 'provincia:28', escala: 'municipio', superficie: 70, umbral: 40, gastos: 1, historia: 'centro', paso: 3 };
  Object.assign(estado, H.cambiosDePaso(H.pasoDe(h, 1).paso));
  assert.equal(consulta(estado), '?idioma=en&mapa=alquiler_mes&anio=2015&vista=11.30/40.42000/-3.70000&historia=centro&paso=3');
  // Un valor que no vale no entra
  assert.equal(H.cambiosDePaso({ estado: { vista: '11/40/-3', escala: 'nacional', anio: '2025-05' } }).escala, undefined);
  assert.equal(H.cambiosDePaso({ estado: { vista: '11/40/-3', anio: '2025-05' } }).anio, '2025-05');
  for (const clave of H.CLAVES_PASO.concat(H.CLAVES_QUITADAS)) assert.ok(CLAVES.includes(clave), clave);
});

test('textos en el idioma de la página, con el castellano de reserva, y enlace en inglés', () => {
  const h = H.buscarHistoria(muestra(), 'anios');
  assert.equal(H.textoEn(h.titulo, 'en'), 'Test story B');
  assert.equal(H.textoEn({ es: 'Solo castellano' }, 'en'), 'Solo castellano');
  assert.equal(H.textoEn(null, 'es'), '');
  assert.equal(H.enlaceEnIdioma('historico.html#hist-renta', 'es'), 'historico.html#hist-renta');
  assert.equal(H.enlaceEnIdioma('historico.html#hist-renta', 'en'), 'historico.html?idioma=en#hist-renta');
  assert.equal(H.enlaceEnIdioma('mapa.html?mapa=alquiler_mes', 'en'), 'mapa.html?mapa=alquiler_mes&idioma=en');
  assert.equal(H.enlaceEnIdioma('metodo.html#indicadores', 'en'), 'method.html#indicadores');
  assert.equal(H.enlaceEnIdioma('datos.html', 'en'), 'data.html');
});

// --- Estado y página -----------------------------------------------------------------------------

test('claves historia (id) y paso (1 a 20) en la dirección', () => {
  assert.deepEqual(leerEstado('?historia=centro&paso=3'), { historia: 'centro', paso: 3 });
  assert.deepEqual(leerEstado('?historia=Centro&paso=0'), {});
  assert.deepEqual(leerEstado('?historia=a_b_2&paso=21'), { historia: 'a_b_2' });
  assert.deepEqual(leerEstado('?paso=20'), { paso: 20 });
  assert.deepEqual(leerEstado(`?historia=${'x'.repeat(31)}&paso=1.5`), {});
  assert.equal(consulta({ historia: 'centro', paso: 4 }), '?historia=centro&paso=4');
});

test('textos de la interfaz del recorrido en los dos idiomas', () => {
  for (const clave of ['nav.historias', 'interfaz.historia.etiqueta', 'interfaz.historia.elegir', 'interfaz.historia.contador',
    'interfaz.historia.fuente', 'interfaz.historia.anterior', 'interfaz.historia.siguiente', 'interfaz.historia.salir',
    'interfaz.historia.salir_largo']) {
    for (const idioma of ['es', 'en']) assert.equal(typeof en(i18n[idioma], clave), 'string', `${clave} (${idioma})`);
  }
  assert.equal(i18n.es.nav.historias, 'Historias');
  assert.equal(i18n.en.nav.historias, 'Stories');
  for (const idioma of ['es', 'en']) assert.match(i18n[idioma].interfaz.historia.contador, /\{n\}.*\{total\}/);
});

test('mapa.html: el panel con región aria-live, los tres botones y el selector; cada data-i18n con su texto', () => {
  const html = leerTexto('web', 'mapa.html');
  assert.match(html, /<section id="historia" class="tarjeta historia" aria-labelledby="historia-titulo" hidden>/);
  assert.match(html, /<div id="historia-paso" class="historia-paso" aria-live="polite" tabindex="-1">/);
  for (const id of ['historia-elegir', 'historia-anterior', 'historia-siguiente', 'historia-salir', 'historia-texto', 'historia-fuente', 'historia-contador', 'historia-nota', 'historia-nota-texto']) {
    assert.match(html, new RegExp(`id="${id}"`), id);
  }
  for (const [, clave] of html.matchAll(/data-i18n(?:-title)?="(interfaz\.historia\.\w+)"/g)) {
    assert.equal(typeof en(i18n.es, clave), 'string', clave);
  }
  // La nota del paso («Cómo se mide»): un desplegable, después de la región viva y fuera de ella
  assert.match(html, /<details id="historia-nota" class="historia-nota" hidden>\s*<summary data-i18n="interfaz\.historia\.nota">/);
  assert.ok(html.indexOf('id="historia-nota"') > html.indexOf('id="historia-enlace"'));
  // En pantallas estrechas, bajo el mapa y antes de la ficha (no lo tapa)
  const css = leerTexto('web', 'estilo', 'sitio.css');
  const movil = css.slice(css.indexOf('@media (max-width: 760px)'));
  assert.match(movil, /\.historia \{ order: -2; \}/);
  assert.doesNotMatch(css, /\.historia \{[^}]*position: (absolute|fixed)/);
  // Con un recorrido abierto, el mapa se queda fijo arriba y el paso va debajo, a la vista los dos
  assert.match(movil, /body\.con-historia \.mapa-marco \{[^}]*position: sticky; top: 0;/);
  assert.match(movil, /body\.con-historia \.mapa-columna, body\.con-historia \.lateral \{ display: contents; \}/);
  assert.match(movil, /\.historia-acciones \{[^}]*position: sticky; bottom: 0;/);
});

test('menú: «Historias» en todas las páginas con menú, hacia mapa.html?historia=centro, y «Máquina del tiempo» al final', () => {
  for (const pagina of ['index.html', 'mapa.html', 'sobrecarga.html', 'historico.html']) {
    const nav = /<nav class="navegacion"[^>]*>([\s\S]*?)<\/nav>/.exec(leerTexto('web', pagina))[1];
    const enlace = /<a ([^>]*)data-i18n="nav\.historias">/.exec(nav)?.[1] ?? '';
    assert.match(enlace, /href="mapa\.html\?historia=centro"/, pagina);
    assert.match(enlace, /data-href-es="mapa\.html\?historia=centro" data-href-en="mapa\.html\?historia=centro&amp;idioma=en"/, pagina);
    const enlaces = [...nav.matchAll(/data-i18n="(nav\.\w+)"/g)].map((m) => m[1]);
    assert.equal(enlaces.at(-1), 'nav.historico', pagina);
  }
  assert.match(leerTexto('web', 'herramientas', 'plantilla_documento.html'), /\$if\(texto_historias\)\$\n\s+<a href="\$historias\$">\$texto_historias\$<\/a>\n\$endif\$/);
  assert.match(leerTexto('web', 'herramientas', 'documento_es.yaml'), /^historias: "mapa\.html\?historia=centro"$/m);
  assert.match(leerTexto('web', 'herramientas', 'documento_en.yaml'), /^historias: "mapa\.html\?historia=centro&idioma=en"$/m);
  assert.match(leerTexto('.github', 'workflows', 'pages.yml'), /texto_historias="\$\(jq -r '\.nav\.historias \/\/ empty' "\$dic"\)"/);
});

// --- Fichero real (con la exportación del pipeline) ---------------------------------------------

const real = join(raiz, 'web', 'datos', 'historias.json');
test('web/datos/historias.json cumple el contrato y sus mapas están en el manifiesto', { skip: !existsSync(real) && 'sin web/datos/historias.json' }, () => {
  const d = leerJson('web', 'datos', 'historias.json');
  const mapas = existsSync(join(raiz, 'web', 'datos', 'manifiesto.json')) ? Object.keys(leerJson('web', 'datos', 'manifiesto.json').mapas) : null;
  assert.deepEqual(H.validarHistorias(d, { mapas }), []);
  // El enlace del menú lleva a una historia que existe
  assert.ok(H.buscarHistoria(d, 'centro'), 'falta la historia «centro» (enlace del menú)');
  // Las cifras, ya escritas: ninguna marca {…} sin sustituir
  for (const h of d.historias) {
    for (const [k, p] of h.pasos.entries()) {
      for (const idioma of ['es', 'en']) {
        assert.doesNotMatch(p.texto[idioma], /\{\w+\}/, `${h.id}, paso ${k + 1} (${idioma})`);
        if (p.nota) assert.doesNotMatch(p.nota[idioma], /\{\w+\}/, `${h.id}, nota del paso ${k + 1} (${idioma})`);
      }
    }
  }
});
