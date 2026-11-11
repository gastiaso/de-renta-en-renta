// Módulo de supuestos (tarea 48): la página toma superficies, umbrales, tramos de «¿te llega?» y
// pagas de js/supuestos.js, generado por R desde inventario/supuestos.csv, y hace las mismas cuentas
// que R en la muestra de pruebas/datos/supuestos_muestra.json (catorce territorios × todas las
// combinaciones de «Tu ficha», y las tres fichas de una persona), que comprueba también
// pruebas/testthat/test-supuestos.R. Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/supuestos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const { SUPUESTOS } = await modulo('web/js/supuestos.js');
const sueldo = await modulo('web/js/sueldo.js');
const { FORMULAS } = await modulo('web/js/formulas.js');
const { leerEstado } = await modulo('web/js/estado.js');
const leer = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');

// CSV con comillas (los textos llevan comas).
function leerCsv(texto) {
  const filas = [];
  let fila = [];
  let campo = '';
  let comillas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (comillas) {
      if (c === '"' && texto[i + 1] === '"') { campo += '"'; i++; } else if (c === '"') comillas = false; else campo += c;
    } else if (c === '"') comillas = true;
    else if (c === ',') { fila.push(campo); campo = ''; } else if (c === '\n' || c === '\r') {
      if (c === '\r' && texto[i + 1] === '\n') i++;
      fila.push(campo); filas.push(fila); fila = []; campo = '';
    } else campo += c;
  }
  if (campo || fila.length) { fila.push(campo); filas.push(fila); }
  const [cabecera, ...resto] = filas.filter((f) => f.length > 1);
  return resto.map((f) => Object.fromEntries(cabecera.map((k, i) => [k, f[i]])));
}

const csv = Object.fromEntries(leerCsv(leer('inventario', 'supuestos.csv')).map((f) => [f.id, f]));
const numeros = (x) => (x ? x.split(';').map(Number) : []);
const muestra = JSON.parse(leer('pruebas', 'datos', 'supuestos_muestra.json'));
const cerca = (a, b, msg) => {
  if (a === null || b === null || a === undefined || b === undefined) return assert.equal(a ?? null, b ?? null, msg);
  assert.ok(Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(b)), `${msg}: ${a} frente a ${b}`);
};

test('js/supuestos.js reproduce inventario/supuestos.csv', () => {
  assert.deepEqual([...SUPUESTOS.superficies], numeros(csv.superficie_una_persona.opciones));
  assert.equal(SUPUESTOS.superficie_una_persona, Number(csv.superficie_una_persona.valor));
  assert.equal(SUPUESTOS.superficie_dos_sueldos, Number(csv.superficie_dos_sueldos.valor));
  assert.deepEqual([...SUPUESTOS.umbrales], numeros(csv.umbral_sueldo.opciones).map((x) => Math.round(100 * x)));
  assert.equal(SUPUESTOS.umbral_sueldo, Math.round(100 * Number(csv.umbral_sueldo.valor)));
  assert.deepEqual([...SUPUESTOS.limites_llega], numeros(csv.limites_llega.valor));
  assert.deepEqual([...SUPUESTOS.pagas], numeros(csv.pagas.opciones));
  assert.equal(SUPUESTOS.pagas_defecto, Number(csv.pagas.valor));
  assert.equal(SUPUESTOS.divisor_llave, Number(csv.divisor_llave.valor));
  assert.equal(SUPUESTOS.sueldo_maximo, Number(csv.sueldo_maximo.valor));
  assert.ok(Object.isFrozen(SUPUESTOS) && Object.isFrozen(SUPUESTOS.superficies));
});

test('sueldo.js, estado.js y mapa.html usan los supuestos del CSV', () => {
  assert.deepEqual(sueldo.SUPERFICIES, SUPUESTOS.superficies);
  assert.equal(sueldo.SUPERFICIE_DOS_SUELDOS, SUPUESTOS.superficie_dos_sueldos);
  assert.deepEqual(sueldo.UMBRALES, SUPUESTOS.umbrales);
  assert.deepEqual(sueldo.LIMITES_LLEGA, SUPUESTOS.limites_llega);
  const html = leer('web', 'mapa.html');
  const botones = (a) => [...html.matchAll(new RegExp(`data-${a}="(\\d+)"`, 'g'))].map((m) => Number(m[1]));
  assert.deepEqual(botones('superficie'), [...SUPUESTOS.superficies]);
  assert.deepEqual(botones('umbral'), [...SUPUESTOS.umbrales]);
  assert.deepEqual(botones('pagas'), [...SUPUESTOS.pagas]);
  // estado.js: la URL acepta las opciones y nada más.
  for (const s of SUPUESTOS.superficies) assert.equal(leerEstado(`?superficie=${s}`).superficie, s);
  for (const u of SUPUESTOS.umbrales) assert.equal(leerEstado(`?umbral=${u}`).umbral, u);
  assert.equal(leerEstado('?superficie=60').superficie, undefined);
  assert.equal(leerEstado('?umbral=35').umbral, undefined);
});

test('superficie típica: alquiler mensual / alquiler por m², o null sin los dos términos', () => {
  assert.equal(sueldo.superficieTipica(869, 14), 869 / 14);
  assert.equal(sueldo.superficieTipica(null, 14), null);
  assert.equal(sueldo.superficieTipica(869, 0), null);
});

test('la muestra: la página hace las mismas cuentas que R con cada combinación de supuestos', () => {
  const terminos = Object.fromEntries(muestra.terminos.map((t) => [`${t.geo_id} ${t.nivel}`, t]));
  assert.ok(muestra.casos.length >= 14 * 40);
  let n = 0;
  for (const c of muestra.casos) {
    const t = terminos[`${c.geo_id} ${c.nivel}`];
    const x = (serie) => ({ alquiler_m2: t.alquiler_m2, alquiler_mes: t.alquiler_mes })[serie] ?? null;
    const msg = `${c.geo_id} ${c.ficha} ${c.eleccion} ${c.umbral} ${c.pagas} ${c.segundo}`;
    let superficie;
    let calculo;
    if (c.ficha === 'peon') {
      const s = { neto: muestra.peon.neto, pagas: c.pagas, segundo: c.segundo ? muestra.peon.segundo : null };
      const estado = { ficha: 'peon', superficie: c.eleccion === 'defecto' ? undefined : c.eleccion === 'tipica' ? 'tipica' : Number(c.eleccion) };
      // Superficie típica (decisión del autor, 11-nov-2026): la del municipio en las secciones (sus
      // términos, en la misma muestra) y la propia en los demás niveles, como territorioTipica()
      const propio = c.nivel === 'sc' ? terminos[`${c.geo_id.slice(0, 5)} municipio`] : t;
      const tipica = sueldo.superficieTipica(propio.alquiler_mes, propio.alquiler_m2);
      if (c.eleccion === 'tipica') cerca(tipica, t.superficie_tipica, `${msg}: superficie típica`);
      superficie = sueldo.superficieDe(estado, s, {}, tipica);
      cerca(sueldo.ingresoPeon(s), c.ingreso, `${msg}: ingreso`);
      calculo = sueldo.calculoLlega({ ficha: 'peon', perfiles: {}, sueldo: s, superficie });
    } else {
      if (c.ingreso === null) continue;   // la mochila y el transistor, sin ingreso en la comunidad
      const nivel = c.ficha === 'tartera' ? 'nacional' : 'provincia';
      const perfiles = { [c.ficha]: { nivel, neto_mensual: { [nivel === 'nacional' ? '00' : c.geo_id.slice(0, 2)]: c.ingreso },
                                      superficie_m2: SUPUESTOS.superficie_una_persona } };
      superficie = sueldo.superficieDe({ ficha: c.ficha }, null, perfiles);
      calculo = sueldo.calculoLlega({ ficha: c.ficha, perfiles, superficie });
    }
    cerca(superficie, c.superficie, `${msg}: superficie`);
    const r = calculo.calcular(c.geo_id, x);
    cerca(r.alquiler, c.alquiler, `${msg}: alquiler`);
    cerca(r.ratio, c.ratio, `${msg}: proporción`);
    assert.equal(sueldo.tramoLlega(r.ratio), c.tramo, `${msg}: tramo`);
    assert.equal(sueldo.eurosQueQuedan(r), c.euros, `${msg}: euros que quedan`);
    const s = { superficie_m2: superficie, umbral: c.umbral };
    cerca(FORMULAS.alquiler_m2_a_sueldo.calcular(t.alquiler_m2, s), c.sueldo_minimo, `${msg}: sueldo necesario mínimo`);
    cerca(FORMULAS.alquiler_mes_a_sueldo.calcular(t.alquiler_mes, s), c.sueldo_real, `${msg}: sueldo necesario`);
    n++;
  }
  assert.ok(n >= 14 * 40);
});
