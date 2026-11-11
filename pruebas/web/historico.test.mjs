// Pruebas de la página «Máquina del tiempo» (F6) sin navegador (web/js/historico_datos.js), con datos
// inventados; si el pipeline ya ha exportado web/datos/historico/ y web/datos/cis_vivienda.json, se
// comprueba también su contrato.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/historico.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const H = await import(pathToFileURL(join(raiz, 'web/js/historico_datos.js')).href);
const { ordenNatural } = await import(pathToFileURL(join(raiz, 'web/js/nombres.js')).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leerJson = (...ruta) => JSON.parse(leerTexto(...ruta));

// Traductor mínimo con los textos reales de la sección «historico»
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
  t.periodo = (p) => p;
  return t;
}

const DATOS = {
  version: '2026-11-10',
  desde: 1987,
  series: {
    anios_renta: { fuente: 'bde_accesibilidad', frecuencia: 'trimestral', unidad: 'anios', escala: 100, version: '2026-11-10',
      territorios: { '00': { inicio: [1987, 1], v: [290, 300, null, 335, 439, 900, 946, 836] } } },
    tipo_hipotecas: { fuente: 'bde_tipos_referencia', frecuencia: 'mensual', unidad: 'porcentaje', escala: 1000, version: '2026-11-10',
      territorios: { '00': { inicio: [1990, 11], v: [16770, 16660, 16920, -505] } } },
    valor_tasado: { fuente: 'mivau_valor_tasado', frecuencia: 'trimestral', unidad: 'euros_m2', escala: 10, version: '2026-11-09',
      territorios: { '00': { inicio: [1995, 1], v: [6708, 6860] }, '03': { inicio: [1995, 1], v: [6580, null] }, '13': { inicio: [1995, 1], v: [9000, 9100] } } },
    sueldo_asalariado: { fuente: 'ine_cne', frecuencia: 'anual', unidad: 'euros_anio', escala: 1, version: '2026-11-10',
      territorios: { '00': { inicio: [1995, 0], v: [15635, 16000, 31200] } } },
  },
  territorios: { '03': 'Asturias, Principado de', '13': 'Madrid, Comunidad de' },
  fechas: [
    { id: 'max', serie: 'anios_renta', geo: '00', periodo: [1988, 3], tipo: 'maximo', texto_es: 'Máximo', texto_en: 'High' },
    { id: 'rup', serie: 'tipo_hipotecas', geo: '00', periodo: [1991, 1], tipo: 'ruptura', texto_es: 'Cambio', texto_en: 'Change' },
    { id: 'fuera', serie: 'anios_renta', geo: '00', periodo: [1987, 3], tipo: 'evento', texto_es: 'Sin cifra', texto_en: 'No figure' },
  ],
  rupturas: ['rup'],
};

test('estado de la URL: idioma y comunidad del valor tasado', () => {
  assert.deepEqual(H.leerEstado(''), { idioma: 'es', ccaa: null });
  assert.deepEqual(H.leerEstado('?idioma=en&ccaa=13', DATOS), { idioma: 'en', ccaa: '13' });
  assert.equal(H.leerEstado('?ccaa=99', DATOS).ccaa, null);
  assert.equal(H.leerEstado('?ccaa=00', DATOS).ccaa, null);
  assert.equal(H.leerEstado('?ccaa=<b>', DATOS).ccaa, null);
  assert.equal(H.consulta({ idioma: 'en', ccaa: '13' }), '?idioma=en&ccaa=13');
  assert.equal(H.consulta({ idioma: 'es', ccaa: null }), '');
});

test('puntos de una serie: periodos, centro del periodo y huecos', () => {
  const p = H.puntosDe(DATOS, 'anios_renta');
  assert.equal(p.length, 8);
  assert.deepEqual(p.map((x) => x.clave).slice(0, 5), ['1987-T1', '1987-T2', '1987-T3', '1987-T4', '1988-T1']);
  assert.equal(p[0].t, 1987.125);
  assert.equal(p[0].v, 2.9);
  assert.equal(p[2].v, null);
  const m = H.puntosDe(DATOS, 'tipo_hipotecas');
  assert.deepEqual(m.map((x) => x.clave), ['1990-11', '1990-12', '1991-01', '1991-02']);
  assert.equal(m[3].v, -0.505);
  const a = H.puntosDe(DATOS, 'sueldo_asalariado');
  assert.deepEqual(a.map((x) => [x.clave, x.t]), [['1995', 1995.5], ['1996', 1996.5], ['1997', 1997.5]]);
  assert.equal(H.puntosDe(DATOS, 'valor_tasado', '99'), null);
  assert.equal(H.puntosDe(DATOS, 'no_existe'), null);
});

test('extremos, punto cercano y trazado con huecos', () => {
  const p = H.puntosDe(DATOS, 'anios_renta');
  const e = H.extremos(p);
  assert.equal(e.primero.clave, '1987-T1');
  assert.equal(e.ultimo.clave, '1988-T4');
  assert.equal(e.maximo.clave, '1988-T3');
  assert.equal(e.minimo.clave, '1987-T1');
  assert.equal(H.cercano(p, 1987.6).clave, '1987-T2');          // el T3 no tiene cifra
  assert.equal(H.cercano(p, 2010, 0.75), null);
  const x = (v) => v;
  const y = (v) => v;
  assert.equal((H.trazado(p, x, y).match(/M/g) ?? []).length, 2);  // dos tramos
  assert.equal(H.extremos([]), null);
});

test('ejes: escala redonda (también con negativos) y años con marca', () => {
  assert.deepEqual(H.escalaEje([2.9, 9.46]), { min: 0, max: 10, paso: 2 });
  assert.deepEqual(H.escalaEje([-0.505, 16.92]), { min: -5, max: 20, paso: 5 });
  assert.deepEqual(H.escalaEje([15635, 31200]), { min: 0, max: 40000, paso: 10000 });
  assert.deepEqual(H.marcasAnios(1987, 2026, 5), [1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025]);
  assert.deepEqual(H.marcasAnios(1987, 2026, 10), [1990, 2000, 2010, 2020]);
  assert.deepEqual(H.rangoAnios(DATOS), { desde: 1987, hasta: 1998 });
});

test('lectura impersonal en los dos idiomas, sin repetir un punto', () => {
  const es = H.lectura(DATOS, 'anios_renta', '00', traductor('es'));
  assert.equal(es, 'Primer dato y mínimo de la serie, primer trimestre de 1987: 2,90 años. '
    + 'Máximo de la serie, tercer trimestre de 1988: 9,46 años. Último dato, cuarto trimestre de 1988: 8,36 años.');
  const en = H.lectura(DATOS, 'anios_renta', '00', traductor('en'));
  assert.equal(en, 'First figure and series low, Q1 1987: 2.90 years. Series high, Q3 1988: 9.46 years. Latest figure, Q4 1988: 8.36 years.');
  assert.match(H.lectura(DATOS, 'sueldo_asalariado', '00', traductor('es')), /^Primer dato y mínimo de la serie, 1995: 15\.635 €\./);
  assert.match(H.lectura(DATOS, 'tipo_hipotecas', '00', traductor('en')), /Series low and latest figure, 1991-02: -0\.505%\.$/);
  assert.equal(H.lectura(DATOS, 'valor_tasado', '99', traductor('es')), '');
});

test('fechas clave: su punto, las que caen sin cifra y las rupturas', () => {
  const f = H.fechasDe(DATOS, 'anios_renta');
  assert.deepEqual(f.map((x) => x.id), ['fuera', 'max']);
  assert.equal(f[0].punto, null);
  assert.equal(f[1].punto.v, 9.46);
  const r = H.fechasDe(DATOS, 'tipo_hipotecas');
  assert.equal(r[0].tipo, 'ruptura');
  assert.equal(r[0].clave, '1991-01');
  assert.deepEqual(H.fechasDe(DATOS, 'valor_tasado'), []);
});

test('comunidades del valor tasado en orden natural', () => {
  assert.deepEqual(H.comunidades(DATOS, ordenNatural), [
    { codigo: '13', nombre: 'Comunidad de Madrid' }, { codigo: '03', nombre: 'Principado de Asturias' }]);
});

test('textos: cada clave que usa la página está en los dos idiomas', () => {
  for (const idioma of ['es', 'en']) {
    const t = traductor(idioma);
    t('nav.historico');
    for (const b of H.BLOQUES) {
      for (const k of ['corto', 'titulo', 'subtitulo', 'fuente']) assert.ok(t(`historico.bloques.${b.id}.${k}`));
      for (const s of b.series) assert.ok(t(`historico.series.${s}`));
    }
    for (const u of ['anios', 'porcentaje', 'euros_m2', 'euros_anio']) {
      assert.ok(t(`historico.unidades.${u}`).includes('{x}'));
      assert.ok(t(`historico.ejes.${u}`));
    }
    for (const k of [1, 2, 3, 4]) assert.match(t(`historico.periodo.t${k}`, { anio: 2000 }), /2000/);
    const html = leerTexto('web', 'historico.html');
    for (const m of html.matchAll(/data-i18n(?:-aria)?="([^"]+)"/g)) assert.ok(t(m[1]), `${m[1]} (${idioma})`);
  }
});

test('página: una sección por bloque con su ancla y la entrada del menú al final en todas las páginas', () => {
  const html = leerTexto('web', 'historico.html');
  for (const b of H.BLOQUES) {
    assert.match(html, new RegExp(`<section id="${b.id}" class="tarjeta hi-bloque" data-bloque="${b.id}"`));
    assert.match(html, new RegExp(`<a href="#${b.id}"`));
  }
  assert.match(html, /<a href="historico\.html" aria-current="page" data-i18n="nav\.historico">/);
  assert.match(html, /<script type="module" src="js\/historico\.js"><\/script>/);
  for (const pagina of ['index.html', 'mapa.html', 'sobrecarga.html', 'historico.html']) {
    const nav = /<nav class="navegacion"[^>]*>([\s\S]*?)<\/nav>/.exec(leerTexto('web', pagina))[1];
    const enlaces = [...nav.matchAll(/data-i18n="(nav\.\w+)"/g)].map((m) => m[1]);
    assert.equal(enlaces.at(-1), 'nav.historico', pagina);
  }
  const plantilla = leerTexto('web', 'herramientas', 'plantilla_documento.html');
  assert.match(plantilla, /<a href="\$historico\$">\$texto_historico\$<\/a>/);
  for (const idioma of ['es', 'en']) {
    assert.match(leerTexto('web', 'herramientas', `documento_${idioma}.yaml`), /^historico: "historico\.html(\?idioma=en)?"$/m);
  }
  assert.match(leerTexto('.github', 'workflows', 'pages.yml'), /texto_historico="\$\(jq -r '\.nav\.historico \/\/ empty' "\$dic"\)"/);
});

const RUTA_REAL = join(raiz, 'web', 'datos', 'historico', 'historico.json');
test('datos exportados por el pipeline: contrato de historico.json', { skip: !existsSync(RUTA_REAL) && 'sin datos exportados' }, () => {
  const d = JSON.parse(readFileSync(RUTA_REAL, 'utf8'));
  assert.deepEqual(Object.keys(d.series).sort(),
    ['anios_renta', 'esfuerzo_teorico', 'mibor_euribor', 'sueldo_asalariado', 'tipo_hipotecas', 'tipo_prestamos', 'valor_tasado']);
  // Tipos (pregunta 47 c): el MIBOR hasta 1998 y el euríbor desde 1999, en una línea con su ruptura
  assert.ok(d.rupturas.includes('bde_mibor_euribor_1999'));
  assert.ok(d.rupturas.includes('bde_tipo_prestamos_2003'));
  assert.equal(d.series.tipo_prestamos.territorios['00'].inicio[0], 1989);
  for (const [clave, s] of Object.entries(d.series)) {
    assert.ok(s.frecuencia in H.SUBPERIODOS, clave);
    assert.ok([1, 10, 100, 1000].includes(s.escala), clave);
    assert.ok(Object.keys(s.territorios).includes('00'), clave);
    for (const terr of Object.values(s.territorios)) {
      assert.ok(terr.v.every((x) => x === null || Number.isInteger(x)), clave);
      assert.equal(terr.inicio.length, 2);
    }
  }
  assert.equal(d.series.anios_renta.territorios['00'].inicio[0], 1987);
  assert.ok(Object.keys(d.series.valor_tasado.territorios).length >= 18);
  // Fechas clave: cada máximo y mínimo cae en el máximo o el mínimo de su serie
  for (const f of d.fechas.filter((x) => x.tipo === 'maximo' || x.tipo === 'minimo')) {
    const e = H.extremos(H.puntosDe(d, f.serie, f.geo));
    assert.equal(e[f.tipo].clave, H.claveFecha(f.periodo, d.series[f.serie].frecuencia), f.id);
  }
  for (const id of d.rupturas) assert.ok(d.fechas.some((f) => f.id === id && f.tipo === 'ruptura'), id);
  // Las cifras que cita la nota metodológica
  const anios = H.extremos(H.puntosDe(d, 'anios_renta'));
  assert.equal(anios.maximo.clave, '2007-T3');
  assert.equal(anios.maximo.v, 9.46);
  assert.equal(H.extremos(H.puntosDe(d, 'esfuerzo_teorico')).maximo.v, 72.47);
});

// --- La vivienda como problema (CIS) ------------------------------------------------------------

// Como datos/cis_vivienda.json: solo los meses con dato, sin agosto; aquí, desordenados y con un
// periodo mal escrito, que no cuenta.
const CIS = {
  fuente: 'CIS', actualizado: '2014-12-12',
  series: {
    espana: { periodo: ['2014-02', '2014-01', '2014-04', '2014-07', '2014-09', '2014-11', '2014-1'],
      valor: [2.0, 1.5, 3.5, 2.5, 4.0, 3.0, 9.9], estudio: ['3013', '3011', '3020', '3030', '3035', '3041', 'x'],
      n: [2474, 2480, 2470, 2490, 2468, 2475, 1] },
    personal: { periodo: ['2014-01', '2014-02', '2014-04', '2014-07', '2014-09', '2014-10', '2014-11'],
      valor: [1.6, 1.6, 2.0, 2.2, 2.1, 2.2, 1.9], estudio: ['3011', '3013', '3020', '3030', '3035', '3038', '3041'],
      n: [2480, 2474, 2470, 2490, 2468, 2471, 2475] },
  },
};

test('CIS: rejilla mensual del primer mes al último, con huecos y sin agosto', () => {
  const p = H.puntosCis(CIS, 'espana');
  assert.deepEqual(p.map((x) => x.clave),
    ['2014-01', '2014-02', '2014-03', '2014-04', '2014-05', '2014-06', '2014-07', '2014-09', '2014-10', '2014-11']);
  assert.deepEqual(p.filter((x) => x.v === null).map((x) => x.clave), ['2014-03', '2014-05', '2014-06', '2014-10']);
  assert.equal(H.huecosCis(p), 4);
  assert.equal(p[0].t, 2014 + 0.5 / 12);
  assert.deepEqual([p[6].v, p[6].estudio, p[6].n], [2.5, '3030', 2490]);
  assert.deepEqual([p[2].estudio, p[2].n], [null, null]);
  // La línea se corta en cada hueco (julio y septiembre se unen: agosto no es un hueco) y los
  // meses sueltos, que no forman línea, van como punto
  const x = (v) => v;
  assert.equal((H.trazado(p, x, x).match(/M/g) ?? []).length, 4);
  assert.deepEqual(H.aislados(p).map((q) => q.clave), ['2014-04', '2014-11']);
  // Un agosto con dato sí entra
  const conAgosto = { series: { espana: { periodo: ['2015-07', '2015-08', '2015-09'], valor: [1, 2, 3] } } };
  assert.deepEqual(H.puntosCis(conAgosto, 'espana').map((q) => [q.clave, q.v, q.estudio]),
    [['2015-07', 1, null], ['2015-08', 2, null], ['2015-09', 3, null]]);
  // Sin JSON, sin la pregunta o sin meses válidos: null
  assert.equal(H.puntosCis(null, 'espana'), null);
  assert.equal(H.puntosCis(CIS, 'no_existe'), null);
  assert.equal(H.puntosCis({ series: { espana: { periodo: ['2014'], valor: [1] } } }, 'espana'), null);
  assert.equal(H.puntosCis({ series: { espana: { periodo: ['2014-01'], valor: [null] } } }, 'espana'), null);
});

test('CIS: máximo, último, mes cercano (también en un hueco) y lectura en los dos idiomas', () => {
  const p = H.puntosCis(CIS, 'espana');
  const e = H.extremos(p);
  assert.deepEqual([e.primero.clave, e.maximo.clave, e.maximo.v, e.ultimo.clave, e.ultimo.v],
    ['2014-01', '2014-09', 4, '2014-11', 3]);
  // Empate en el máximo: el primero
  const empate = H.extremos(H.puntosCis(CIS, 'personal'));
  assert.deepEqual([empate.maximo.clave, empate.ultimo.clave], ['2014-07', '2014-11']);
  // Ratón sobre marzo (sin dato): el globo dice «sin dato», no salta a febrero ni a abril
  const marzo = H.mesCercano(p, 2014 + 2.4 / 12);
  assert.deepEqual([marzo.clave, marzo.v], ['2014-03', null]);
  assert.equal(H.mesCercano(p, 2014 + 7.5 / 12).clave, '2014-07');  // agosto: el mes vecino
  assert.equal(H.mesCercano(p, 2010), null);
  assert.equal(H.lecturaCis(CIS, 'espana', traductor('es')),
    'Primer dato, 2014-01: 1,5 %. Máximo de la serie, 2014-09: 4,0 %. Último dato, 2014-11: 3,0 %. '
    + 'Meses sin dato, en los que la línea se corta: 4.');
  assert.equal(H.lecturaCis(CIS, 'personal', traductor('en')),
    'First figure, 2014-01: 1.6%. Series high, 2014-07: 2.2%. Latest figure, 2014-11: 1.9%. '
    + 'Months without a figure, where the line breaks: 3.');
  assert.equal(H.lecturaCis(null, 'espana', traductor('es')), '');
  assert.equal(H.textoCis(null, traductor('es')), 'sin dato');
  assert.equal(H.textoCis(55.7, traductor('es')), '55,7 %');
});

test('CIS: estudio y entrevistas del globo, pasos del teclado y eje común', () => {
  const es = traductor('es');
  const p = H.puntosCis(CIS, 'espana');
  const q = H.puntosCis(CIS, 'personal');
  assert.equal(H.textoEstudio([p[0], q[0]], es), 'Estudio 3011 · 2.480 entrevistas');
  assert.equal(H.textoEstudio([p[8], q[8]], traductor('en')), 'Study 3038 · 2,471 interviews');  // octubre: solo la personal
  assert.equal(H.textoEstudio([p[2], q[2]], es), '');                                           // marzo: ninguna
  const sinEstudio = H.puntosCis({ series: { espana: { periodo: ['2014-01'], valor: [1] } } }, 'espana');
  assert.equal(H.textoEstudio(sinEstudio, es), '');
  // El teclado pasa también por los meses sin dato del CIS; en las demás series, solo por los que tienen cifra
  assert.equal(H.pasosTeclado([p, q], true).length, 10);
  assert.equal(H.pasosTeclado([p]).length, 6);
  assert.equal(H.pasosTeclado([H.puntosDe(DATOS, 'anios_renta')]).length, 7);
  // El eje común llega al último mes del CIS si va más allá que el histórico (DATOS acaba en 1997)
  assert.deepEqual(H.rangoAnios(DATOS, [p, q]), { desde: 1987, hasta: 2015 });
  const pronto = H.puntosCis({ series: { espana: { periodo: ['1990-03'], valor: [1] } } }, 'espana');
  assert.deepEqual(H.rangoAnios(DATOS, [pronto, null]), { desde: 1987, hasta: 1998 });
});

test('CIS: bloque con su ancla, entrada del índice y textos cis_* en los dos idiomas', () => {
  const html = leerTexto('web', 'historico.html');
  assert.match(html, new RegExp(`<section id="${H.CIS_ID}" class="tarjeta hi-bloque" data-bloque="${H.CIS_ID}"`));
  assert.match(html, new RegExp(`<a href="#${H.CIS_ID}" data-i18n="historico\\.cis_corto">`));
  // El bloque del CIS va tras los del histórico, antes de la caja de método
  assert.ok(html.indexOf('id="hist-sueldo"') < html.indexOf(`id="${H.CIS_ID}"`));
  assert.ok(html.indexOf(`id="${H.CIS_ID}"`) < html.indexOf('id="hi-metodo-titulo"'));
  const claves = (idioma) => Object.keys(leerJson('web', 'i18n', `${idioma}.json`).historico).filter((k) => k.startsWith('cis_')).sort();
  assert.deepEqual(claves('es'), claves('en'));
  for (const idioma of ['es', 'en']) {
    const t = traductor(idioma);
    for (const k of ['corto', 'titulo', 'subtitulo', 'espana', 'personal', 'huecos', 'estudio', 'entrevistas', 'estudio_col',
      'entrevistas_col', 'aviso', 'fuente', 'fecha', 'sin_datos', 'metodo']) assert.ok(t(`historico.cis_${k}`), `${k} (${idioma})`);
    assert.match(t('historico.cis_fuente'), /CIS/);
    assert.match(t('historico.cis_fuente'), /CC BY 4\.0/);
    assert.match(t('historico.cis_fecha', { fecha: '2026-10-20' }), /2026-10-20/);
  }
  assert.match(traductor('es')('historico.cis_aviso'), /^Opinión, no registro/);
  assert.match(traductor('en')('historico.cis_aviso'), /^Opinion, not a register/);
});

const RUTA_CIS_REAL = join(raiz, 'web', 'datos', 'cis_vivienda.json');
test('datos exportados por el pipeline: contrato de cis_vivienda.json', { skip: !existsSync(RUTA_CIS_REAL) && 'sin datos exportados' }, () => {
  const d = JSON.parse(readFileSync(RUTA_CIS_REAL, 'utf8'));
  assert.equal(H.RUTA_CIS, 'datos/cis_vivienda.json');
  assert.match(d.actualizado, /^\d{4}-\d{2}-\d{2}$/);
  for (const pregunta of H.CIS_SERIES) {
    const s = d.series[pregunta];
    const n = s.periodo.length;
    for (const campo of ['valor', 'estudio', 'n']) assert.equal(s[campo].length, n, `${pregunta}.${campo}`);
    assert.ok(s.periodo.every((p, k) => /^\d{4}-\d{2}$/.test(p) && (k === 0 || p > s.periodo[k - 1])), pregunta);
    assert.ok(s.valor.every((v) => v >= 0 && v <= 100 && Math.abs(v * 10 - Math.round(v * 10)) < 1e-9), pregunta);
    assert.ok(s.n.every((x) => Number.isInteger(x) && x >= 1000), pregunta);
    assert.ok(!s.periodo.some((p) => p.endsWith('-08')), `${pregunta}: agosto`);
    // La rejilla de la página tiene todos los meses del JSON, con sus cifras
    assert.equal(H.puntosCis(d, pregunta).filter((p) => p.v !== null).length, n);
  }
  // Las cifras que cita la nota metodológica (§7.10)
  const espana = H.extremos(H.puntosCis(d, 'espana'));
  assert.deepEqual([espana.primero.clave, espana.primero.v], ['2014-01', 1.5]);
  assert.equal(espana.maximo.v, 55.7);
  assert.equal(H.extremos(H.puntosCis(d, 'personal')).primero.v, 1.6);
  // Sin los seis meses solo en PDF, que ya van transcritos (pregunta 48 a)
  assert.equal(H.huecosCis(H.puntosCis(d, 'espana')), 9);
  assert.equal(H.huecosCis(H.puntosCis(d, 'personal')), 7);
});
