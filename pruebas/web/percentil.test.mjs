// Pruebas del percentil salarial de la ficha (web/js/percentil.js), sin navegador. Datos inventados;
// si el pipeline ya ha exportado web/datos/salarios.json, se comprueba también su contrato.
//   node --test pruebas/web/percentil.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const { curvaSalarial, percentilEnCurva, percentilSalarial, primerAnioSalarial } =
  await import(pathToFileURL(join(raiz, 'web/js/percentil.js')).href);

const percentiles = Array.from({ length: 99 }, (_, i) => i + 1);
// Curva lineal: el percentil p vale 1.000 + 10 p euros (España) y 1.500 + 10 p (Cataluña).
const lineal = (base) => percentiles.map((p) => base + 10 * p);
const salarios = { percentiles, anios: { 2019: { '00': lineal(1000) }, 2024: { '00': lineal(1000), '09': lineal(1500) } } };

test('percentil interpolado en una curva creciente, con los extremos abiertos', () => {
  const c = lineal(1000);
  assert.equal(percentilEnCurva(1500, c, percentiles), 50);
  assert.equal(percentilEnCurva(1505, c, percentiles), 50.5);
  assert.equal(percentilEnCurva(1010, c, percentiles), 1);
  assert.equal(percentilEnCurva(1000, c, percentiles), 0);     // por debajo del percentil 1
  assert.equal(percentilEnCurva(2000, c, percentiles), 100);   // por encima del 99
  assert.equal(percentilEnCurva(NaN, c, percentiles), null);
  assert.equal(percentilEnCurva(1500, c.slice(1), percentiles), null);   // curva incompleta
});

test('curva de la comunidad de la sección; sin curva propia, la de España; sin año, ninguna', () => {
  assert.equal(curvaSalarial(salarios, 2024, '09').ambito, '09');
  assert.equal(curvaSalarial(salarios, 2024, '16').ambito, '00');
  assert.equal(curvaSalarial(salarios, 2019, '09').ambito, '00');
  assert.equal(curvaSalarial(salarios, 2015, '09'), null);
  assert.equal(primerAnioSalarial(salarios), 2019);
});

test('percentil del sueldo necesario de un territorio, con la curva de su comunidad', () => {
  assert.deepEqual(percentilSalarial(salarios, { valor: 2000, anio: 2024, ccaa: '09' }),
    { percentil: 50, ambito: '09', anio: 2024 });
  assert.deepEqual(percentilSalarial(salarios, { valor: 1500, anio: 2024, ccaa: '16' }),
    { percentil: 50, ambito: '00', anio: 2024 });
  assert.deepEqual(percentilSalarial(salarios, { valor: 1500, anio: '2024', ccaa: null }),
    { percentil: 50, ambito: '00', anio: 2024 });
  assert.deepEqual(percentilSalarial(salarios, { valor: 1500, anio: 2016, ccaa: '09' }),
    { sinCurva: true, desde: 2019 });
  assert.equal(percentilSalarial(null, { valor: 1500, anio: 2024, ccaa: '09' }), null);
  assert.equal(percentilSalarial(salarios, { valor: null, anio: 2024, ccaa: '09' }), null);
});

const real = join(raiz, 'web', 'datos', 'salarios.json');
test('datos/salarios.json del pipeline: 99 percentiles, curvas crecientes y España todos los años', { skip: !existsSync(real) }, () => {
  const s = JSON.parse(readFileSync(real, 'utf8'));
  assert.deepEqual(s.percentiles, percentiles);
  const anios = Object.keys(s.anios);
  assert.ok(anios.length >= 6);
  for (const a of anios) {
    assert.ok(Array.isArray(s.anios[a]['00']), `España sin curva en ${a}`);
    for (const [ccaa, curva] of Object.entries(s.anios[a])) {
      assert.equal(curva.length, 99, `${a} ${ccaa}`);
      for (let i = 1; i < curva.length; i += 1) assert.ok(curva[i] >= curva[i - 1], `${a} ${ccaa} no crece en ${i + 1}`);
    }
  }
});
