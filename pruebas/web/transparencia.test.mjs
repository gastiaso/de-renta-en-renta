// Pruebas sin navegador de las tareas 52 y 53 (backlog):
//   - transparencia (web/js/transparencia.js): «Avisar de un error» lleva a las incidencias del
//     repositorio público, sin correo; «Método en dos páginas» y su fe de erratas, en cada idioma;
//     la fecha de los datos, la del manifiesto, en largo;
//   - el mapa la pone bajo el mapa (principal.js) y la ficha lleva los enlaces al pie (ficha.js);
//   - «Método en dos páginas» (docs/metodo_corto.md y docs/short_method.md): mismas secciones y
//     cifras en los dos idiomas, la marca de la fe de erratas y su título con el ancla que enlaza la
//     web; ninguna cifra de Idealista (decisiones 17–19);
//   - la fe de erratas (inventario/erratas.csv; web/herramientas/pagina_metodo_corto.mjs): CSV
//     válido, tabla de la más reciente a la más antigua y, sin filas, una línea que lo dice;
//   - la portada (tarea 52): las cartas de «entrar» salen «próximamente», sin cifras ni enlace,
//     mientras la familia esté en FAMILIAS_PROXIMAMENTE; «Zona tensionada» y «Tasación», activas.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/transparencia.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');

// DOM de pega: solo lo que usan lineaTransparencia() y las fichas
class Nodo {
  constructor(etiqueta) {
    this.etiqueta = etiqueta;
    this.hijos = [];
    this.className = '';
    this.textContent = '';
    this.atributos = {};
  }
  append(...xs) { this.hijos.push(...xs); }
  replaceChildren(...xs) { this.hijos = xs; }
  addEventListener() {}
  setAttribute(k, v) { this.atributos[k] = v; }
  get texto() { return this.textContent + this.hijos.map((h) => (typeof h === 'string' ? h : h.texto)).join(''); }
  enlaces() { return this.hijos.filter((h) => typeof h !== 'string').flatMap((h) => [...(h.etiqueta === 'a' ? [h] : []), ...h.enlaces()]); }
}
globalThis.document = { createElement: (e) => new Nodo(e), documentElement: {}, getElementById: () => null, querySelector: () => null };
globalThis.fetch = async (ruta) => ({ ok: true, json: async () => JSON.parse(leerTexto('web', ruta)) });

const { cargarIdioma } = await modulo('web/js/i18n.js');
const tr = await modulo('web/js/transparencia.js');
const ficha = await modulo('web/js/ficha.js');
const portada = await modulo('web/js/portada.js');
const familias = await modulo('web/js/familias.js');
const mc = await modulo('web/herramientas/pagina_metodo_corto.mjs');
const t = { es: await cargarIdioma('es'), en: await cargarIdioma('en') };

// --- Enlaces y fecha ---------------------------------------------------------------------------

test('«Avisar de un error»: las incidencias del repositorio público, sin correo', () => {
  assert.equal(tr.ENLACE_ERRORES, 'https://github.com/gastiaso/de-renta-en-renta/issues');
  for (const idioma of ['es', 'en']) {
    const e = tr.enlacesTransparencia(idioma, { erratas: true });
    assert.deepEqual(e.map((x) => x.clave), ['metodo_corto', 'erratas', 'error']);
    assert.ok(e.every((x) => !/mailto:|@/.test(x.href)), 'sin correo');
  }
  assert.deepEqual(tr.enlacesTransparencia('es').map((x) => x.clave), ['metodo_corto', 'error']);
});

test('«Método en dos páginas» y su fe de erratas, en cada idioma', () => {
  assert.equal(tr.enlaceMetodoCorto('es'), 'metodo_corto.html');
  assert.equal(tr.enlaceMetodoCorto('en'), 'short_method.html');
  assert.equal(tr.enlaceMetodoCorto(undefined), 'metodo_corto.html');
  assert.equal(tr.enlaceErratas('es'), 'metodo_corto.html#fe-de-erratas');
  assert.equal(tr.enlaceErratas('en'), 'short_method.html#errata');
});

test('fecha de los datos en largo, desde el texto del manifiesto; nada si no es una fecha', () => {
  assert.equal(tr.fechaLarga('2026-11-11', 'es'), '11 de noviembre de 2026');
  assert.equal(tr.fechaLarga('2026-11-09T13:14:33+0100', 'en'), '9 November 2026');
  for (const malo of [null, undefined, '', 'ayer', '2026-02-30', '11/11/2026']) assert.equal(tr.fechaLarga(malo, 'es'), null, String(malo));
});

test('línea de transparencia: la fecha y los enlaces, con sus textos en los dos idiomas', () => {
  for (const idioma of ['es', 'en']) {
    const p = tr.lineaTransparencia(t[idioma], { fecha: '2026-11-11', erratas: true });
    const enlaces = p.enlaces();
    assert.deepEqual(enlaces.map((a) => a.atributos['data-transparencia']), ['metodo_corto', 'erratas', 'error']);
    assert.ok(enlaces.every((a) => a.textContent && !a.textContent.startsWith('interfaz.')), idioma);
    assert.equal(enlaces.at(-1).atributos.rel, 'noopener');
    assert.match(p.texto, idioma === 'es' ? /^Datos generados el 11 de noviembre de 2026 · Método en dos páginas/ : /^Data generated on 11 November 2026 · Method in two pages/);
    // Sin fecha (o con una que no lo es), solo los enlaces
    assert.doesNotMatch(tr.lineaTransparencia(t[idioma], { fecha: 'x' }).texto, /2026/);
  }
});

test('la ficha de sección y la de territorio llevan al pie «Método en dos páginas» y «Avisar de un error»', () => {
  const pie = ficha.pieFicha(t.es);
  assert.ok(pie.className.includes('ficha-pie'));
  assert.deepEqual(pie.enlaces().map((a) => a.href), ['metodo_corto.html', tr.ENLACE_ERRORES]);
  const js = leerTexto('web', 'js', 'ficha.js');
  assert.equal((js.match(/pieFicha\(t\)/g) ?? []).length, 2, 'fichaSeccion y fichaTerritorio');
});

test('el mapa pone bajo el mapa la fecha del manifiesto, nunca escrita a mano', () => {
  const html = leerTexto('web', 'mapa.html');
  assert.match(html, /<p id="mapa-pie" class="mapa-pie">/);
  assert.doesNotMatch(html.split('id="mapa-pie"')[1].split('</p>')[0], /20\d\d/, 'sin fecha en el HTML');
  const js = leerTexto('web', 'js', 'principal.js');
  assert.match(js, /lineaTransparencia\(t, \{ fecha: m\?\.generado \?\? null, erratas: true \}\)/);
  // La portada: el enlace a las incidencias también sin JavaScript
  assert.match(leerTexto('web', 'index.html'), /<p id="portada-pie-transparencia"><a href="https:\/\/github\.com\/gastiaso\/de-renta-en-renta\/issues"/);
});

// --- «Método en dos páginas» -------------------------------------------------------------------

const nota = { es: leerTexto('docs', 'metodo_corto.md'), en: leerTexto('docs', 'short_method.md') };
const titulos = (md) => [...md.matchAll(/^(#{1,3}) (.+)$/gm)].map((x) => [x[1].length, x[2]]);
const cifras = (md) => [...md.replace(/<!--[\s\S]*?-->/g, '').matchAll(/\d[\d.,]*/g)]
  .map((x) => x[0].replace(/[.,]$/, '')).map((x) => x.replace(/(\d)[.,](\d{3})(?!\d)/g, '$1$2').replace(',', '.'));

test('método corto: mismas secciones y mismas cifras en castellano e inglés', () => {
  const es = titulos(nota.es);
  const en = titulos(nota.en);
  assert.deepEqual(es.map((x) => x[0]), en.map((x) => x[0]));
  assert.equal(es.at(-1)[1], 'Fe de erratas');
  assert.equal(en.at(-1)[1], 'Errata');
  assert.deepEqual(cifras(nota.es), cifras(nota.en));
  for (const idioma of ['es', 'en']) {
    assert.equal(nota[idioma].split(mc.MARCA_ERRATAS).length, 2, `${idioma}: una marca de la fe de erratas`);
    assert.doesNotMatch(nota[idioma], /[Bb]orrador|[Dd]raft/, `${idioma}: no es un borrador`);
  }
});

test('método corto: el ancla de la fe de erratas es la que enlaza la web (identificadores de pandoc)', () => {
  const ancla = (titulo) => titulo.toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, '').trim().replace(/\s+/g, '-');
  assert.equal(ancla(titulos(nota.es).at(-1)[1]), tr.ANCLAS_ERRATAS.es);
  assert.equal(ancla(titulos(nota.en).at(-1)[1]), tr.ANCLAS_ERRATAS.en);
});

test('método corto: ninguna cifra de la oferta de Idealista (decisiones 17–19)', () => {
  for (const idioma of ['es', 'en']) {
    const lineas = nota[idioma].split('\n').filter((l) => /Idealista/.test(l));
    for (const l of lineas) assert.doesNotMatch(l, /\d+ ?%|\d+ (municipios|municipalities)|€/, `${idioma}: ${l}`);
  }
});

// --- Fe de erratas -----------------------------------------------------------------------------

test('fe de erratas: el CSV del inventario es válido', () => {
  const erratas = mc.leerErratas(leerTexto('inventario', 'erratas.csv'));
  assert.ok(Array.isArray(erratas));
});

test('fe de erratas: CSV con comillas, validación y tabla de la más reciente a la más antigua', () => {
  const cabecera = mc.COLUMNAS_ERRATAS.join(',');
  assert.deepEqual(mc.leerCsv('a,b\n"x, y","z ""w"""\n'), [['a', 'b'], ['x, y', 'z "w"']]);
  const csv = `${cabecera}\n2026-11-01,0.4.0,Portada,Front page,Cifra mal,Wrong figure,"Corregida, con | barra",Fixed\n2026-12-02,0.4.0,Mapa,Map,Otra,Another,Bien,Right\n`;
  const filas = mc.leerErratas(csv);
  assert.equal(filas.length, 2);
  const es = mc.textoErratas(filas, 'es');
  assert.match(es, /^2 correcciones/);
  const tabla = es.split('\n').filter((l) => l.startsWith('| ') && !l.startsWith('| Fecha'));
  assert.match(tabla[0], /^\| 2 de diciembre de 2026 \| v0\.4\.0 \| Mapa/);
  assert.match(tabla[1], /Corregida, con \\\| barra/);
  assert.match(mc.textoErratas(filas, 'en'), /\| 1 November 2026 \| v0\.4\.0 \| Front page \| Wrong figure \| Fixed \|/);
  for (const malo of [`fecha,version\n`, `${cabecera}\n2026-13-01,0.4.0,a,b,c,d,e,f\n`, `${cabecera}\n2026-11-01,v0.4,a,b,c,d,e,f\n`,
    `${cabecera}\n2026-11-01,0.4.0,a,b,c,d,e,\n`, `${cabecera}\n2026-11-01,0.4.0,a,b\n`]) {
    assert.throws(() => mc.leerErratas(malo), /erratas\.csv/, malo);
  }
});

test('fe de erratas: sin filas, una línea que lo dice y remite al registro de cambios; la marca, rellena', () => {
  for (const idioma of ['es', 'en']) {
    const texto = mc.montarMetodoCorto(nota[idioma], [], idioma, 'cuenta/repo');
    assert.ok(!texto.includes(mc.MARCA_ERRATAS));
    assert.match(texto, /\(https:\/\/github\.com\/cuenta\/repo\/blob\/main\/CHANGELOG\.md\)\.\n?$/);
  }
  assert.throws(() => mc.montarMetodoCorto('sin marca', [], 'es'), /marca/);
});

test('flujo de Pages: monta las dos páginas con la fe de erratas y la plantilla de la web', () => {
  const flujo = leerTexto('.github', 'workflows', 'pages.yml');
  assert.match(flujo, /metodo_corto\.md metodo_corto\.html/);
  assert.match(flujo, /short_method\.md short_method\.html/);
  assert.match(flujo, /pagina_metodo_corto\.mjs --idioma "\$1" --nota "docs\/\$7"/);
  for (const idioma of ['es', 'en']) {
    const yaml = leerTexto('web', 'herramientas', `metodo_corto_${idioma}.yaml`);
    assert.match(yaml, /pagina_es: metodo_corto\.html/);
    assert.match(yaml, /pagina_en: short_method\.html/);
  }
  const ignorados = leerTexto('.gitignore');
  assert.match(ignorados, /^web\/metodo_corto\.html$/m);
  assert.match(ignorados, /^web\/short_method\.html$/m);
});

// --- Portada (tarea 52) ------------------------------------------------------------------------

test('portada: las cartas de «entrar» salen «próximamente», sin cifras ni enlace', () => {
  assert.ok(familias.FAMILIAS_PROXIMAMENTE.includes('entrar'));
  for (const idioma of ['es', 'en']) {
    const cartas = portada.cartasProximamente(t[idioma]);
    assert.deepEqual(cartas.map((c) => c.id), portada.CARTAS_ENTRAR);
    for (const c of cartas) {
      assert.equal(c.familia, familias.textoFamilia(t[idioma], 'entrar'));
      assert.ok(c.titulo && c.texto);
      assert.doesNotMatch(c.texto, /\{\w+\}/, 'sin marcas de cifras');
      assert.doesNotMatch(c.texto.replace(/\b(30|50) ?(%|m²)/g, ''), /\d/, `${idioma}: sin más cifras que el umbral y la superficie`);
      assert.ok(!('enlace' in c));
    }
  }
  // Sin sus textos, la carta no sale
  const sinTextos = Object.assign((k) => k, { idioma: 'es', existe: (k) => !k.startsWith('portada.cartas.') });
  assert.deepEqual(portada.cartasProximamente(sinTextos), []);
});

test('portada: «Zona tensionada» y «Tasación», activas y con su mapa', () => {
  const csv = leerTexto('inventario', 'casillas_portada.csv').trim().split('\n').slice(1).map((l) => l.split(','));
  const fila = (id) => csv.find((f) => f[1] === id);
  assert.equal(fila('zona_tensionada').at(-1), 'TRUE');
  assert.match(fila('zona_tensionada')[5], /^mapa\.html\?mapa=zona_tensionada&vista=/);
  assert.equal(fila('tasacion').at(-1), 'TRUE');
  assert.equal(fila('tasacion')[5], 'mapa.html?mapa=valor_tasado_m2');
  const ruta = join(raiz, 'web', 'datos', 'manifiesto.json');
  if (existsSync(ruta)) {
    const m = JSON.parse(readFileSync(ruta, 'utf8'));
    if (!m.ejemplo) for (const id of ['zona_tensionada', 'valor_tasado_m2']) assert.ok(m.mapas[id], id);
  }
});
