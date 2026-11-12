// «Tu sueldo» (decisión del autor, 12-nov-2026): aviso junto al resultado de «¿te llega?», frase del
// resultado que dice qué y cuánto, «Ingresos netos al mes», umbral «solo alquiler» y el selector
// «Añadir otros gastos de vivienda» (otros gastos de los inquilinos de la ECV, por comunidad). La
// página hace las mismas cuentas que R en los casos de pruebas/datos/otros_gastos_inventado.json, que
// comprueba también pruebas/testthat/test-otros-gastos.R. Con la exportación del pipeline, el fichero
// datos/otros_gastos.json cumple su contrato y da cifra a todas las provincias. Desde la raíz:
//   node --test pruebas/web/otros_gastos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const sueldo = await modulo('web/js/sueldo.js');
const { FORMULAS, textoSupuestos, textoOtrosGastos } = await modulo('web/js/formulas.js');
const exportar = await modulo('web/js/exportar.js');
const { supuestosDeColumnas, textoSupuestosFila, filasComparador } = await modulo('web/js/comparador.js');
const { leerEstado, consulta } = await modulo('web/js/estado.js');
const H = await modulo('web/js/historias.js');
const leer = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const casos = JSON.parse(leer('pruebas', 'datos', 'otros_gastos_inventado.json'));
const cerca = (a, b) => Math.abs(a - b) < 1e-9 * Math.max(1, Math.abs(b));

// Tabla inventada con el formato de datos/otros_gastos.json: Aragón con su cifra (la de España de la
// ola por su factor), Ceuta con la de España por falta de muestra y Madrid sin fila (también la de España).
const TABLA = {
  minimo_hogares: 50,
  anios: [2023, 2024],
  factores: { '02': { f: 1.118, n: 251 }, 18: { f: 1, n: 38, espana: true } },
  cifras: {
    2023: { '00': { v: 150, n: 3300 }, '02': { v: 167.7 } },
    2024: { '00': { v: 145.3, n: 3721 }, '02': { v: 162.4 }, 18: { v: 145.3, espana: true } },
  },
};
const CCAA_DE_PROVINCIA = { 50: '02', 22: '02', 51: '18', 28: '13' };
const NOMBRES = { '02': 'Aragón', 18: 'Ceuta', 13: 'Madrid' };
const t = (clave, p = {}) => `${clave}${Object.keys(p).length ? JSON.stringify(p) : ''}`;
t.numero = (x) => String(x);
t.porcentaje = (x) => `${Math.round(x * 100)} %`;

test('R y la página dan la misma cuenta con otros gastos (casos inventados)', () => {
  for (const c of casos.sueldo) {
    const s = { umbral: c.umbral, otros: c.otros };
    assert.ok(cerca(FORMULAS.alquiler_mes_a_sueldo.calcular(c.alquiler_mes, s), c.esperado), JSON.stringify(c));
  }
  for (const c of casos.minimo) {
    const s = { umbral: c.umbral, superficie_m2: c.superficie, otros: c.otros };
    assert.ok(cerca(FORMULAS.alquiler_m2_a_sueldo.calcular(c.alquiler_m2, s), c.esperado), JSON.stringify(c));
  }
  for (const c of casos.llega) {
    assert.equal(sueldo.eurosQueQuedan({ alquiler: c.alquiler, ingreso: c.ingreso, otros: c.otros }), c.euros);
  }
  assert.deepEqual(casos.anios.alquiler.map((a) => sueldo.anioEcv(casos.anios.olas, a)), casos.anios.esperado);
  assert.equal(sueldo.anioEcv(casos.anios.olas, '2025-05'), 2025);
  assert.equal(sueldo.anioEcv([], 2024), null);
});

test('sin otros gastos, las fórmulas y el mapa no cambian', () => {
  const s = { umbral: 0.3, superficie_m2: 50 };
  assert.deepEqual(FORMULAS.alquiler_mes_a_sueldo.expresion('v', s), ['/', 'v', 0.3]);
  assert.deepEqual(FORMULAS.alquiler_m2_a_sueldo.expresion('v', s), ['/', ['*', 'v', 50], 0.3]);
  assert.equal(FORMULAS.alquiler_mes_a_sueldo.calcular(900, s), 3000);
  assert.equal(sueldo.supuestosEn(s, '5029701001'), s);
  assert.equal(textoOtrosGastos(t, s), null);
  assert.equal(sueldo.eurosQueQuedan({ alquiler: 890, ingreso: 1237.4 }), 347);
});

test('cifra de cada territorio: su comunidad, o España', () => {
  const g = sueldo.gastosDelAnio(TABLA, 2024, CCAA_DE_PROVINCIA, NOMBRES);
  assert.equal(g.anio_ecv, 2024);
  assert.deepEqual(g.olas, { desde: 2023, hasta: 2024 });   // las olas del factor de las comunidades
  assert.equal(g.provincia['50'], 162.4);
  assert.deepEqual(sueldo.otrosGastosEn(g, '5029701001'), { valor: 162.4, ccaa: '02', espana: false });
  assert.deepEqual(sueldo.otrosGastosEn(g, '22', 'provincia'), { valor: 162.4, ccaa: '02', espana: false });
  assert.deepEqual(sueldo.otrosGastosEn(g, '02', 'ccaa'), { valor: 162.4, ccaa: '02', espana: false });
  assert.deepEqual(sueldo.otrosGastosEn(g, '51001', 'municipio'), { valor: 145.3, ccaa: '18', espana: true });
  assert.deepEqual(sueldo.otrosGastosEn(g, '2807901001'), { valor: 145.3, ccaa: '00', espana: false });
  assert.deepEqual(sueldo.otrosGastosEn(g, '00', 'nacional'), { valor: 145.3, ccaa: '00', espana: false });
  // La ola más cercana al año del alquiler, y la anterior si es la que toca
  assert.equal(sueldo.gastosDelAnio(TABLA, 2015, CCAA_DE_PROVINCIA).anio_ecv, 2023);
  assert.equal(sueldo.gastosDelAnio(TABLA, 2023, CCAA_DE_PROVINCIA).provincia['50'], 167.7);
  assert.equal(sueldo.gastosDelAnio(null, 2024), null);
  assert.deepEqual(sueldo.rangoOtrosGastos(g), { desde: 145.3, hasta: 162.4 });
  // Expresión del mapa: por provincia en las secciones y por código en las comunidades
  assert.deepEqual(sueldo.expresionOtrosGastos(g, 'id'), ['match', ['slice', ['to-string', ['get', 'id']], 0, 2], '22', 162.4, '50', 162.4, '51', 145.3, 145.3]);
  assert.deepEqual(sueldo.expresionOtrosGastos(g, 'id', 'ccaa'), ['match', ['to-string', ['get', 'id']], '18', 145.3, '02', 162.4, 145.3]);
});

test('el sueldo necesario y «¿te llega?» suman la cifra de la comunidad', () => {
  const g = sueldo.gastosDelAnio(TABLA, 2024, CCAA_DE_PROVINCIA, NOMBRES);
  const supuestos = { superficie_m2: 50, umbral: 0.3, gastos: g };
  const s = sueldo.supuestosEn(supuestos, '5029701001', 'sc');
  assert.equal(s.otros, 162.4);
  assert.ok(cerca(FORMULAS.alquiler_mes_a_sueldo.calcular(800, s), (800 + 162.4) / 0.3));
  assert.ok(cerca(FORMULAS.alquiler_m2_a_sueldo.calcular(12.5, s), (625 + 162.4) / 0.3));
  // Mapa: la expresión del sueldo necesario lleva la de los otros gastos
  const def = { base: 'alquiler_mes', formula: 'alquiler_mes_a_sueldo', cortes: [1000, 2000] };
  const paleta = { fuera: '#000', rampa: ['#1', '#2', '#3', '#4', '#5', '#6'] };
  const color = sueldo.colorNecesario(def, supuestos, paleta, 'sc', null, 'id');
  assert.deepEqual(color[3][1], ['/', ['+', ['to-number', ['feature-state', 'alquiler_mes']], sueldo.expresionOtrosGastos(g, 'id', 'sc')], 0.3]);
  // Sin propiedad del código (pruebas antiguas), como antes
  assert.deepEqual(sueldo.colorNecesario(def, { superficie_m2: 50, umbral: 0.3 }, paleta)[3][1], ['/', ['to-number', ['feature-state', 'alquiler_mes']], 0.3]);
  // «¿te llega?»: proporción y euros que quedan con los otros gastos; el alquiler sigue siendo el alquiler
  const x = (valores) => (serie) => valores[serie] ?? null;
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: {}, sueldo: { neto: 1500, pagas: 12 }, superficie: 50, gastos: g });
  const r = peon.calcular('5029701001', x({ alquiler_m2: 12.5, alquiler_mes: 700 }));
  assert.equal(r.alquiler, 625);
  assert.equal(r.otros, 162.4);
  assert.ok(cerca(r.ratio, (625 + 162.4) / 1500));
  assert.ok(cerca(r.real.ratio, (700 + 162.4) / 1500));
  assert.equal(sueldo.eurosQueQuedan(r), 1500 - 625 - 162);
  const e = peon.expresion('id', 'sc');
  assert.deepEqual(e.ratio[1], ['+', ['*', ['to-number', ['feature-state', 'alquiler_m2']], 50], sueldo.expresionOtrosGastos(g, 'id', 'sc')]);
  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles: { llave: { ingreso: { serie: 'renta_hogar', divisor: 12 }, vivienda: { serie: 'alquiler_mes' } } }, superficie: null, gastos: g });
  const rl = llave.calcular('5029701001', x({ alquiler_mes: 900, renta_hogar: 36000 }));
  assert.ok(cerca(rl.ratio, (900 + 162.4) / 3000));
  // Sin gastos, el resultado no lleva `otros`
  const sin = sueldo.calculoLlega({ ficha: 'peon', perfiles: {}, sueldo: { neto: 1500, pagas: 12 }, superficie: 50 });
  assert.equal('otros' in sin.calcular('5029701001', x({ alquiler_m2: 12.5 })), false);
});

test('los textos dicen que lleva otros gastos y cuántos', () => {
  const g = sueldo.gastosDelAnio(TABLA, 2024, CCAA_DE_PROVINCIA, NOMBRES);
  const supuestos = { superficie_m2: 50, umbral: 0.3, gastos: g };
  assert.match(textoOtrosGastos(t, sueldo.supuestosEn(supuestos, '5029701001')), /^interfaz\.leyenda\.otros_gastos\{"euros":"162","territorio":"Aragón","anio":2024\}$/);
  assert.match(textoOtrosGastos(t, sueldo.supuestosEn(supuestos, '5100101001')), /otros_gastos_espana.*"territorio":"Ceuta"/);
  assert.match(textoOtrosGastos(t, supuestos), /otros_gastos_rango.*"desde":"145","hasta":"162"/);
  assert.match(textoSupuestos(t, { formula: 'alquiler_mes_a_sueldo', minimo: {} }, supuestos), /^interfaz\.leyenda\.supuestos_real_gastos/);
  assert.match(textoSupuestos(t, { formula: 'alquiler_m2_a_sueldo' }, supuestos), /^interfaz\.leyenda\.supuestos_gastos/);
  assert.match(textoSupuestos(t, { formula: 'alquiler_mes_a_sueldo', minimo: {} }, { superficie_m2: 50, umbral: 0.3 }), /^interfaz\.leyenda\.supuestos_real\{/);
});

test('el comparador suma a cada columna los otros gastos de su comunidad', async () => {
  // Como supuestosComparador() de principal.js: los supuestos de cada territorio en el año de la fila
  const supuestos = { superficie_m2: 50, umbral: 0.3 };
  const de = (codigo, nivel, periodo) => sueldo.supuestosEn({ ...supuestos, gastos: sueldo.gastosDelAnio(TABLA, periodo, CCAA_DE_PROVINCIA, NOMBRES) }, codigo, nivel);
  const def = { formula: 'alquiler_mes_a_sueldo', minimo: {} };
  // Una sección de Zaragoza frente a España: 162,4 y 145,3 €
  const c = supuestosDeColumnas(de, { seccion: '5029701001', comparado: { nivel: 'nacional', codigo: '00' }, periodo: 2024 });
  assert.deepEqual([c.a.otros, c.b.otros], [162.4, 145.3]);
  assert.ok(cerca(FORMULAS.alquiler_mes_a_sueldo.calcular(800, c.a), (800 + 162.4) / 0.3));
  assert.ok(cerca(FORMULAS.alquiler_mes_a_sueldo.calcular(800, c.b), (800 + 145.3) / 0.3));
  const texto = textoSupuestosFila(t, def, c);
  assert.ok(texto.startsWith('interfaz.leyenda.supuestos_real_gastos'), texto);
  assert.ok(texto.includes('Aragón') && texto.includes('; ') && texto.includes('145'), texto);
  // Frente a su provincia o su comunidad, la misma cifra: se dice una vez
  const igual = supuestosDeColumnas(de, { seccion: '5029701001', comparado: { nivel: 'ccaa', codigo: '02' }, periodo: 2024 });
  assert.deepEqual([igual.a.otros, igual.b.otros], [162.4, 162.4]);
  assert.equal(textoSupuestosFila(t, def, igual).includes('; '), false);
  // Una fila de otro año toma la ola de ese año; la ficha de un territorio pasa su nivel
  const c23 = supuestosDeColumnas(de, { seccion: '02', nivelA: 'ccaa', comparado: { nivel: 'nacional', codigo: '00' }, periodo: 2023 });
  assert.deepEqual([c23.a.otros, c23.b.otros], [167.7, 150]);
  // Sin el selector (un objeto), los mismos supuestos y el texto de siempre
  const sin = supuestosDeColumnas(supuestos, { seccion: '5029701001', comparado: { nivel: 'nacional', codigo: '00' }, periodo: 2024 });
  assert.equal(sin.a, supuestos);
  assert.equal(sin.b, supuestos);
  assert.ok(textoSupuestosFila(t, def, sin).startsWith('interfaz.leyenda.supuestos_real{'));
  // filasComparador() deja en la fila del sueldo necesario los supuestos de sus dos columnas
  const m = {
    codificacion: { estados: ['dato', 'secreto', 'estimado', 'ausente'] },
    mapas: { sueldo_necesario: { base: 'alquiler_mes', formula: 'alquiler_mes_a_sueldo', minimo: {}, decimales: 0 } },
    indicadores: { alquiler_mes: { niveles: ['sc', 'nacional'], periodos: [2024], ruta: 'datos/{nivel}/a/{periodo}.json' } },
  };
  // Sin pedir ficheros: el año es anterior a la serie
  const filas = await filasComparador({ m, seccion: '5029701001', comparado: { nivel: 'nacional', codigo: '00' }, anio: 2020, supuestos: de });
  const fila = filas.find((f) => f.indicador === 'sueldo_necesario');
  assert.equal(fila.periodo, null);
  assert.equal(fila.supuestos.a.umbral, 0.3);
  assert.equal(filas.find((f) => f.indicador === 'alquiler_mes').supuestos, null);
});

test('el CSV lleva la cifra sumada en cada fila', () => {
  const tt = (c, p) => (p ? `${c.split('.').at(-1)}` : c.split('.').at(-1));
  const { cabecera, filas } = exportar.tablaCsv({
    t: tt, codigos: ['5029701001', '5100101001'], valores: [800, null], estados: Uint8Array.from([0, 3]),
    nombresEstado: ['dato', 'estimado', 'secreto', 'ausente'], nivel: 'sc', nombreDe: (c) => c, indicador: 'i', unidad: 'u',
    tipologia: '', periodo: 2024, fuente: 'f', decimales: 1, supuestos: { superficie_m2: 50, umbral: 0.3 },
    transformar: (x, codigo) => (x + (codigo.startsWith('50') ? 162.4 : 145.3)) / 0.3,
    otros: (codigo) => (codigo.startsWith('50') ? 162.4 : 145.3),
  });
  assert.ok(cabecera.includes('otros_gastos'));
  const i = cabecera.indexOf('otros_gastos');
  assert.equal(filas[0][i], 162.4);
  assert.equal(filas[1][i], 145.3);
  assert.equal(filas[0][cabecera.indexOf('valor')], 3208);
});

test('la dirección guarda el selector y un paso de una historia lo apaga', () => {
  assert.deepEqual(leerEstado('?gastos=1'), { gastos: 1 });
  assert.deepEqual(leerEstado('?gastos=si'), {});
  assert.equal(consulta({ gastos: 1, umbral: 40 }), '?umbral=40&gastos=1');
  assert.ok(H.CLAVES_QUITADAS.includes('gastos'));
  assert.equal(H.cambiosDePaso({ estado: { mapa: 'sueldo_necesario' } }).gastos, undefined);
  assert.ok('gastos' in H.cambiosDePaso({ estado: { mapa: 'sueldo_necesario' } }));
});

test('tarjeta y textos en los dos idiomas', () => {
  const html = leer('web', 'mapa.html');
  for (const id of ['sueldo-gastos', 'sueldo-gastos-nota', 'sueldo-aviso', 'sueldo-umbral-titulo']) assert.ok(html.includes(`id="${id}"`), id);
  assert.match(html, /<input id="sueldo-gastos" type="checkbox"/);
  const textos = { es: JSON.parse(leer('web', 'i18n', 'es.json')), en: JSON.parse(leer('web', 'i18n', 'en.json')) };
  const claves = {
    sueldo: ['gastos', 'gastos_que', 'gastos_nota', 'gastos_nota_pais', 'gastos_nota_espana', 'gastos_nota_rango', 'gastos_anio', 'gastos_sin', 'gastos_ficha',
      'umbral', 'umbral_gastos', 'aviso_parque', 'resumen_peon', 'resumen_ficha', 'resumen_peon_gastos', 'resumen_ficha_gastos', 'resumen_real'],
    leyenda: ['supuestos_gastos', 'supuestos_real_gastos', 'otros_gastos', 'otros_gastos_espana', 'otros_gastos_rango', 'llega_sub_gastos', 'llega_gastos'],
  };
  for (const idioma of ['es', 'en']) {
    for (const [seccion, lista] of Object.entries(claves)) {
      for (const clave of lista) assert.ok(textos[idioma].interfaz[seccion][clave], `${idioma} ${seccion}.${clave}`);
    }
    assert.ok(textos[idioma].interfaz.exportar.columnas.otros_gastos);
  }
  // Decisiones del autor (12-nov-2026): frases fijas
  const es = textos.es.interfaz.sueldo;
  assert.equal(es.aviso_parque, 'Es el alquiler de quien ya tiene contrato; quien busca piso hoy suele pagar más.');
  assert.equal(es.resumen_peon, 'El alquiler de {vivienda} no pasa del {umbral} de tus ingresos en el {pct} de las secciones con dato ({caben} de {total}).');
  assert.equal(es.neto, 'Ingresos netos al mes');
  assert.equal(es.segundo, 'Segundo ingreso (opcional)');
  assert.equal(es.umbral, 'Umbral (solo alquiler)');
  assert.equal(es.umbral_gastos, 'Umbral (alquiler y otros gastos)');
  assert.equal(es.gastos, 'Añadir otros gastos de vivienda');
  assert.equal(textos.es.nav.tu_sueldo, 'Tu sueldo');
  // La lectura del sueldo necesario ya no dice que «se inspira» en la ley
  for (const idioma of ['es', 'en']) assert.doesNotMatch(textos[idioma].indicadores.sueldo_necesario.lectura, /inspira|draws on/);
});

const RUTA = join(raiz, 'web', 'datos', 'otros_gastos.json');
test('exportación del pipeline: datos/otros_gastos.json', { skip: !existsSync(RUTA) && 'sin la exportación del pipeline' }, () => {
  const j = JSON.parse(readFileSync(RUTA, 'utf8'));
  const territorios = JSON.parse(leer('web', 'datos', 'territorios.json'));
  assert.equal(j.fuente, 'ine_ecv');
  assert.ok(j.minimo_hogares > 0);
  assert.ok(j.anios.length >= 1);
  // Un factor por comunidad, con las olas juntas: sin muestra, 1 y la marca de la cifra de España
  for (const ccaa of Object.keys(territorios.ccaa)) {
    const f = j.factores[ccaa];
    assert.ok(f && Number.isFinite(f.f) && f.f > 0, `factor ${ccaa}`);
    assert.equal(Boolean(f.espana), f.n < j.minimo_hogares, `factor ${ccaa}`);
    if (f.espana) assert.equal(f.f, 1);
  }
  for (const anio of j.anios) {
    const c = j.cifras[String(anio)];
    assert.ok(Number.isFinite(c['00'].v) && c['00'].n >= j.minimo_hogares, `${anio} España`);
    for (const ccaa of Object.keys(territorios.ccaa)) {
      const x = c[ccaa];
      const f = j.factores[ccaa];
      assert.ok(x && Number.isFinite(x.v), `${anio} ${ccaa}`);
      assert.equal(Boolean(x.espana), Boolean(f.espana), `${anio} ${ccaa}`);
      // La cifra es la de España de la ola por el factor, a un decimal
      assert.ok(Math.abs(x.v - c['00'].v * f.f) <= 0.05 + 1e-9, `${anio} ${ccaa}: ${x.v} frente a ${c['00'].v} × ${f.f}`);
    }
    // Todas las provincias tienen cifra
    const g = sueldo.gastosDelAnio(j, anio, territorios.ccaa_de_provincia, territorios.ccaa);
    for (const p of Object.keys(territorios.provincia)) assert.ok(Number.isFinite(g.provincia[p]), `${anio} provincia ${p}`);
  }
});
