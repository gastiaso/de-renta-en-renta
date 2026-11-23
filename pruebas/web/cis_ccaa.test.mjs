// Pruebas de la vivienda como problema por comunidad (CIS; tarea 63) sin navegador
// (web/js/cis_ccaa.js), con datos inventados; si el pipeline ya ha exportado
// web/datos/cis_vivienda_ccaa.json, se comprueba también su contrato.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/cis_ccaa.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const C = await import(pathToFileURL(join(raiz, 'web/js/cis_ccaa.js')).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leerJson = (...ruta) => JSON.parse(leerTexto(...ruta));

function traductor(idioma) {
  const dic = leerJson('web', 'i18n', `${idioma}.json`);
  const t = (clave, valores = {}) => {
    const texto = clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);
    if (typeof texto !== 'string') throw new Error(`Falta ${clave} (${idioma})`);
    return texto.replace(/\{(\w+)\}/g, (m, n) => (n in valores ? valores[n] : m));
  };
  t.idioma = idioma;
  t.numero = (x, d = 0) => new Intl.NumberFormat(idioma === 'en' ? 'en-GB' : 'es-ES',
    { minimumFractionDigits: d, maximumFractionDigits: d, useGrouping: 'always' }).format(x);
  return t;
}

// Dos años (2025 completo y 2026 en curso hasta octubre), España, dos comunidades y Ceuta (dos años
// juntos), las dos preguntas; Ceuta 2025 sin cifra (menos de 50 entrevistas).
function jsonInventado() {
  const filas = [
    ['00', 2025, '2025-01', '2025-12', 1, 'espana', 32.3, 31.7, 32.9, 0.6, 44336, 11, false, false, 'dato'],
    ['01', 2025, '2025-01', '2025-12', 1, 'espana', 28.5, 27.0, 30.0, 1.5, 7630, 11, false, false, 'dato'],
    ['13', 2025, '2025-01', '2025-12', 1, 'espana', 39.2, 37.5, 40.9, 1.7, 6187, 11, false, false, 'dato'],
    ['18', 2025, '2024-01', '2025-12', 2, 'espana', null, null, null, null, 40, 22, false, false, 'ausente'],
    ['00', 2026, '2026-01', '2026-10', 1, 'espana', 44.4, 43.7, 45.1, 0.7, 37194, 9, true, false, 'dato'],
    ['01', 2026, '2026-01', '2026-10', 1, 'espana', 40.1, 38.4, 41.8, 1.7, 6000, 9, true, false, 'dato'],
    ['13', 2026, '2026-01', '2026-10', 1, 'espana', 47.0, 45.2, 48.8, 1.8, 5000, 9, true, false, 'dato'],
    ['18', 2026, '2025-01', '2026-10', 2, 'espana', 28.0, 21.6, 35.2, 6.8, 336, 20, true, false, 'dato'],
    ['00', 2025, '2025-01', '2025-12', 1, 'personal', 22.5, 21.9, 23.1, 0.6, 44336, 11, false, false, 'dato'],
    ['13', 2025, '2025-01', '2025-12', 1, 'personal', 30.0, 28.4, 31.6, 1.6, 6187, 11, false, true, 'dato'],
  ];
  const campos = ['codigo', 'anio', 'desde', 'hasta', 'anios', 'pregunta', 'valor', 'inferior', 'superior', 'margen',
    'entrevistas', 'meses', 'en_curso', 'ruptura', 'estado'];
  return { edicion: 'v2099-01', ultimo_mes: '2026-10', nombres: { '00': 'España', '01': 'Andalucía', '13': 'Madrid, Comunidad de', 18: 'Ceuta' },
    filas: Object.fromEntries(campos.map((c, k) => [c, filas.map((f) => f[k])])) };
}

test('las filas del JSON se leen como objetos; sin JSON, ninguna', () => {
  const filas = C.filasCis(jsonInventado());
  assert.equal(filas.length, 10);
  assert.deepEqual(filas[3], { codigo: '18', anio: 2025, desde: '2024-01', hasta: '2025-12', anios: 2, pregunta: 'espana',
    valor: null, inferior: null, superior: null, margen: null, entrevistas: 40, meses: 22, en_curso: false, ruptura: false, estado: 'ausente' });
  assert.deepEqual(C.filasCis(null), []);
  assert.deepEqual(C.filasCis({ filas: {} }), []);
});

test('la tabla abre en el último año completo, ordena por la cifra y deja España aparte', () => {
  const filas = C.filasCis(jsonInventado());
  assert.deepEqual(C.aniosCis(filas), [2025, 2026]);
  assert.equal(C.anioInicial(filas), 2025);
  assert.equal(C.anioInicial(filas.filter((f) => f.anio === 2026)), 2026);   // solo el año en curso
  const tabla = C.tablaAnio(filas, 2025, 'espana', (c) => ({ '00': 'España', '01': 'Andalucía', 13: 'Madrid', 18: 'Ceuta' })[c]);
  assert.equal(tabla.espana.valor, 32.3);
  assert.equal(tabla.espana.nombre, 'España');
  assert.deepEqual(tabla.comunidades.map((f) => f.nombre), ['Madrid', 'Andalucía', 'Ceuta']);   // sin cifra, al final
  const escala = C.escalaCis([tabla.espana, ...tabla.comunidades]);
  assert.deepEqual(escala, { min: 0, max: 50 });
  assert.equal(C.posicion(25, escala), 50);
  assert.equal(C.posicion(80, escala), 100);
  assert.equal(C.posicion(-1, escala), 0);
});

test('periodos, cifras, márgenes y notas en castellano y en inglés', () => {
  const filas = C.filasCis(jsonInventado());
  const es = traductor('es');
  const en = traductor('en');
  const ceuta26 = filas.find((f) => f.codigo === '18' && f.anio === 2026);
  assert.equal(C.textoPeriodoCis(ceuta26, es), '2025–2026, hasta octubre');
  assert.equal(C.textoPeriodoCis(ceuta26, en), '2025–2026, up to October');
  const and25 = filas.find((f) => f.codigo === '01' && f.anio === 2025);
  assert.equal(C.textoPeriodoCis(and25, es), '2025');
  assert.equal(C.textoCifraCis(and25, es), '28,5 %');
  assert.equal(C.textoCifraCis(and25, en), '28.5%');
  assert.equal(C.textoMargenCis(and25, es), '±1,5 puntos');
  assert.equal(C.textoIntervaloCis(and25, en), '95% interval: 27.0% to 30.0%');
  const ceuta25 = filas.find((f) => f.codigo === '18' && f.anio === 2025);
  assert.equal(C.textoCifraCis(ceuta25, es), 'menos de 50 entrevistas');
  assert.equal(C.textoMargenCis(ceuta25, es), '');
  assert.equal(C.nombreMes('2026-10', 'es'), 'octubre');
  assert.equal(C.nombreMes('x', 'es'), '');
  // notas: en 2025 (España), Ceuta agrupada; en 2026, además, el año en curso; en la personal de 2025, la ruptura
  const notas25 = C.notasCis(C.tablaAnio(filas, 2025, 'espana'), es);
  assert.equal(notas25.length, 1);
  assert.match(notas25[0], /Ceuta y Melilla/);
  const notas26 = C.notasCis(C.tablaAnio(filas, 2026, 'espana'), en);
  assert.equal(notas26.length, 2);
  assert.match(notas26[0], /up to October/);
  assert.match(C.notasCis(C.tablaAnio(filas, 2025, 'personal'), es)[0], /noviembre de 2023/);
});

test('la línea de la ficha de comunidad da la cifra más reciente, con su periodo, margen y entrevistas', () => {
  const filas = C.filasCis(jsonInventado());
  assert.equal(C.lineaFichaCis(filas, '13', traductor('es')),
    'La vivienda, entre los tres principales problemas de España: 47,0 % (2026, hasta octubre; ±1,8 puntos; 5.000 entrevistas).');
  assert.equal(C.lineaFichaCis(filas, '13', traductor('en')),
    'Housing among Spain’s three main problems: 47.0% (2026, up to October; ±1.8 points; 5,000 interviews).');
  assert.equal(C.lineaFichaCis(filas, '99', traductor('es')), null);
  assert.equal(C.lineaFichaCis(filas.filter((f) => f.codigo === '18' && f.anio === 2025), '18', traductor('es')), null);
});

test('sin el JSON, la ficha no pinta nada y la carga no falla', async () => {
  const pedido = C.cargarCis(async () => ({ ok: false }));
  assert.equal(await pedido, null);
});

test('los textos de la tabla y de la ficha están en los dos idiomas', () => {
  for (const idioma of ['es', 'en']) {
    const dic = leerJson('web', 'i18n', `${idioma}.json`);
    for (const k of ['titulo', 'subtitulo', 'anio', 'pregunta', 'tabla', 'col_comunidad', 'col_cifra', 'col_intervalo', 'col_margen',
      'col_entrevistas', 'periodo_dos', 'periodo_en_curso', 'sin_cifra', 'margen', 'intervalo', 'marca_ruptura', 'nota_en_curso',
      'nota_ruptura', 'nota_agrupadas', 'nota_margen', 'fuente', 'csv', 'metodo']) {
      assert.equal(typeof dic.historico.cis_ccaa[k], 'string', `${idioma}: historico.cis_ccaa.${k}`);
    }
    for (const k of ['titulo', 'linea', 'nota']) assert.equal(typeof dic.interfaz.ficha.cis_ccaa[k], 'string', `${idioma}: ficha ${k}`);
    // atribución: el CIS y Barómetro a barómetro, con su licencia
    assert.match(dic.historico.cis_ccaa.fuente, /Centro de Investigaciones Sociológicas/);
    assert.match(dic.historico.cis_ccaa.fuente, /Barómetro a barómetro.*CC BY 4\.0/);
  }
  const html = leerTexto('web', 'historico.html');
  assert.match(html, /id="hi-cis-ccaa"/);
  assert.match(html, /href="datos\/cis_vivienda_ccaa\.csv"/);
});

const exportado = join(raiz, 'web', 'datos', 'cis_vivienda_ccaa.json');
test('contrato del JSON exportado por el pipeline', { skip: !existsSync(exportado) && 'sin web/datos/cis_vivienda_ccaa.json' }, () => {
  const json = leerJson('web', 'datos', 'cis_vivienda_ccaa.json');
  const filas = C.filasCis(json);
  const n = json.filas.codigo.length;
  for (const lista of Object.values(json.filas)) assert.equal(lista.length, n);
  assert.match(json.fuente, /Centro de Investigaciones Sociol/);
  assert.match(json.licencia, /CC BY 4\.0/);
  assert.match(json.edicion, /^v\d{4}-\d{2}$/);
  // las 19 comunidades y España, en cada año y pregunta
  for (const anio of C.aniosCis(filas)) {
    for (const pregunta of C.PREGUNTAS_CIS) {
      const del = filas.filter((f) => f.anio === anio && f.pregunta === pregunta);
      assert.equal(new Set(del.map((f) => f.codigo)).size, 20, `${anio} ${pregunta}`);
    }
  }
  assert.ok(C.aniosCis(filas)[0] <= 2021);
  // cifras dentro de su intervalo y nada con menos de 50 entrevistas
  for (const f of filas) {
    if (f.valor === null) {
      assert.equal(f.estado, 'ausente');
      continue;
    }
    assert.ok(f.entrevistas >= 50);
    assert.ok(f.inferior <= f.valor + 0.05 && f.valor <= f.superior + 0.05, `${f.codigo} ${f.anio}`);
  }
  // Ceuta y Melilla, de dos en dos años (salvo el primero)
  assert.ok(filas.filter((f) => ['18', '19'].includes(f.codigo) && f.anio > C.aniosCis(filas)[0]).every((f) => f.anios === 2));
  // 2023 (ruptura R10) marcado
  assert.ok(filas.filter((f) => f.anio === 2023).every((f) => f.ruptura));
});

test('ficha de comunidad: el enlace lleva a la tabla por comunidad de la Máquina del tiempo (23-nov-2026)', () => {
  const js = leerTexto('web', 'js', 'cis_ccaa.js');
  assert.match(js, /enlace\.href = `historico\.html\$\{t\.idioma === 'en' \? '\?idioma=en' : ''\}#hi-cis-ccaa`;/);
  assert.doesNotMatch(js, /#hist-cis`/);
  // El ancla existe en la página y la página baja hasta ella cuando ya ha pintado (historico.js)
  assert.match(leerTexto('web', 'historico.html'), /id="hi-cis-ccaa"/);
  assert.match(leerTexto('web', 'js', 'historico.js'), /if \(ancla\) ancla\.scrollIntoView\(\);/);
});

test('tabla por comunidad en el móvil: el margen, debajo de la cifra cuando se oculta su columna (23-nov-2026)', () => {
  const js = leerTexto('web', 'js', 'historico.js');
  assert.match(js, /el\('span', \{ class: 'hi-cis-ccaa-margen-movil' \}, C\.textoMargenCis\(f, t\)\)/);
  const css = leerTexto('web', 'estilo', 'historico.css');
  assert.match(css, /\.hi-cis-ccaa-margen-movil \{ display: none; \}/);
  const movil = css.slice(css.indexOf('@media (max-width: 480px)'));
  assert.match(movil, /td:nth-child\(4\) \{ display: none; \}/);
  assert.match(movil, /\.hi-cis-ccaa-margen-movil \{ display: block;/);
});
