// Pruebas de la web sin navegador: formato binario de los indicadores y fórmulas.
// Datos inventados. Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/datos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const { decodificar } = await modulo('web/js/datos.js');
const { FORMULAS, formulaDe } = await modulo('web/js/formulas.js');

const BINARIO = { nulo: -2147483648, estados: ['dato', 'estimado', 'secreto', 'ausente'] };

function binario(enteros, estados) {
  const buffer = new ArrayBuffer(5 * enteros.length);
  const vista = new DataView(buffer);
  enteros.forEach((x, i) => vista.setInt32(4 * i, x, true));
  new Uint8Array(buffer, 4 * enteros.length).set(estados);
  return buffer;
}

test('decodificar: valores × 10, nulos y estados', () => {
  const { valores, estados } = decodificar(binario([253, -15, BINARIO.nulo, 0], [0, 1, 2, 3]), 4, BINARIO);
  assert.deepEqual(valores, [25.3, -1.5, null, 0]);
  assert.deepEqual([...estados], [0, 1, 2, 3]);
});

test('decodificar: rechaza un binario que no casa con el índice de secciones', () => {
  assert.throws(() => decodificar(new ArrayBuffer(12), 4, BINARIO), /se esperaban 20/);
});

test('sueldo necesario: alquiler por m² × superficie / umbral', () => {
  const s = { superficie_m2: 50, umbral: 0.3 };
  assert.equal(Math.round(FORMULAS.alquiler_m2_a_sueldo.calcular(24.8, s)), 4133);
  assert.deepEqual(FORMULAS.alquiler_m2_a_sueldo.expresion('v', s), ['/', ['*', 'v', 50], 0.3]);
  assert.equal(formulaDe({}).calcular(7), 7);
  assert.throws(() => formulaDe({ formula: 'eval' }), /desconocida/);
});

test('muestra de web/datos/ejemplo: el binario de R se lee entero y los nulos son secreto o ausente', () => {
  const dir = join(raiz, 'web', 'datos', 'ejemplo');
  const manifiesto = JSON.parse(readFileSync(join(dir, 'manifiesto.json'), 'utf8'));
  const secciones = JSON.parse(readFileSync(join(dir, 'secciones.json'), 'utf8'));
  assert.equal(manifiesto.ejemplo, true);
  assert.ok(secciones.every((c) => /^\d{10}$/.test(c)));
  for (const [codigo, def] of Object.entries(manifiesto.indicadores)) {
    for (const anio of def.anios) {
      const fichero = readFileSync(join(raiz, 'web', def.ruta.replace('{anio}', anio)));
      const buffer = fichero.buffer.slice(fichero.byteOffset, fichero.byteOffset + fichero.byteLength);
      const { valores, estados } = decodificar(buffer, secciones.length, manifiesto.binario);
      valores.forEach((v, i) => {
        const nombre = manifiesto.binario.estados[estados[i]];
        assert.equal(v === null, nombre === 'secreto' || nombre === 'ausente', `${codigo} ${anio} ${secciones[i]}`);
      });
    }
  }
  for (const def of Object.values(manifiesto.mapas)) {
    assert.ok(manifiesto.indicadores[def.base], `mapa sin indicador base: ${def.base}`);
    assert.equal(def.cortes.length, 4, 'cinco tramos: cuatro cortes');
  }
});
