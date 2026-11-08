// Pruebas de la web sin navegador: formato de los valores (JSON de enteros), series de la
// ficha y fórmulas. Datos inventados. Se ejecutan desde la raíz del proyecto, sin paquetes:
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

const CODIFICACION = { escala: 10, estados: ['dato', 'estimado', 'secreto', 'ausente'] };
const leer = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));

test('decodificar: valores × 10, nulos y estados', () => {
  const { valores, estados } = decodificar({ v: [253, -15, null, 0], e: '0123' }, 4, CODIFICACION);
  assert.deepEqual(valores, [25.3, -1.5, null, 0]);
  assert.deepEqual([...estados], [0, 1, 2, 3]);
});

test('decodificar: rechaza longitudes que no casan con el índice y estados desconocidos', () => {
  assert.throws(() => decodificar({ v: [1, 2, 3], e: '000' }, 4, CODIFICACION), /se esperaban 4/);
  assert.throws(() => decodificar({ v: [1, 2, 3, 4], e: '000' }, 4, CODIFICACION), /se esperaban 4/);
  assert.throws(() => decodificar({ v: [1], e: '4' }, 1, CODIFICACION), /Estado desconocido/);
  assert.throws(() => decodificar({ v: [1], e: 'x' }, 1, CODIFICACION), /Estado desconocido/);
  assert.throws(() => decodificar(null, 1, CODIFICACION), /se esperaban 1/);
});

test('sueldo necesario: alquiler por m² × superficie / umbral', () => {
  const s = { superficie_m2: 50, umbral: 0.3 };
  assert.equal(Math.round(FORMULAS.alquiler_m2_a_sueldo.calcular(24.8, s)), 4133);
  assert.deepEqual(FORMULAS.alquiler_m2_a_sueldo.expresion('v', s), ['/', ['*', 'v', 50], 0.3]);
  assert.equal(formulaDe({}).calcular(7), 7);
  assert.throws(() => formulaDe({ formula: 'eval' }), /desconocida/);
});

test('muestra: los valores que escribe R se leen enteros y los nulos son secreto o ausente', () => {
  const manifiesto = leer('web', 'datos', 'ejemplo', 'manifiesto.json');
  const secciones = leer('web', 'datos', 'ejemplo', 'secciones.json');
  assert.equal(manifiesto.ejemplo, true);
  assert.ok(secciones.every((c) => /^\d{10}$/.test(c)));
  for (const [codigo, def] of Object.entries(manifiesto.indicadores)) {
    for (const anio of def.anios) {
      const datos = leer('web', def.ruta.replace('{anio}', anio));
      assert.ok(datos.v.every((x) => x === null || Number.isInteger(x)), `${codigo} ${anio}: enteros`);
      const { valores, estados } = decodificar(datos, secciones.length, manifiesto.codificacion);
      valores.forEach((v, i) => {
        const nombre = manifiesto.codificacion.estados[estados[i]];
        assert.equal(v === null, nombre === 'secreto' || nombre === 'ausente', `${codigo} ${anio} ${secciones[i]}`);
      });
    }
  }
  for (const def of Object.values(manifiesto.mapas)) {
    assert.ok(manifiesto.indicadores[def.base], `mapa sin indicador base: ${def.base}`);
    assert.equal(def.cortes.length, 4, 'cinco tramos: cuatro cortes');
  }
});

test('muestra: las series de la ficha cuadran, año a año, con los valores del mapa', () => {
  const manifiesto = leer('web', 'datos', 'ejemplo', 'manifiesto.json');
  const secciones = leer('web', 'datos', 'ejemplo', 'secciones.json');
  const fichas = new Map();
  for (const [codigo, def] of Object.entries(manifiesto.indicadores)) {
    def.anios.forEach((anio, k) => {
      const mapa = decodificar(leer('web', def.ruta.replace('{anio}', anio)), secciones.length, manifiesto.codificacion);
      secciones.forEach((seccion, i) => {
        const municipio = seccion.slice(0, 5);
        if (!fichas.has(municipio)) fichas.set(municipio, leer('web', manifiesto.fichas.replace('{municipio}', municipio)));
        const fichero = fichas.get(municipio);
        assert.deepEqual(fichero.anios[codigo], def.anios, `${municipio}: años de ${codigo}`);
        const serie = decodificar(fichero.series[seccion][codigo], def.anios.length, manifiesto.codificacion);
        assert.equal(serie.valores[k], mapa.valores[i], `${seccion} ${codigo} ${anio}: valor`);
        assert.equal(serie.estados[k], mapa.estados[i], `${seccion} ${codigo} ${anio}: estado`);
      });
    });
  }
});
