// Pruebas sin navegador de «entrar» (tarea 37; web/js/entrar.js): la web solo recibe el tramo de la
// brecha entre la oferta y el parque, y calcula los demás como intervalos (decisión 18).
//   - R y la página coinciden: los mismos casos inventados que la prueba de R
//     (pruebas/datos/entrar_inventado.json): límites del tramo, intervalos del sueldo para entrar, del
//     de 50 m² y de la barrera, «¿te llega?» y el fichero de tramos que escribe R;
//   - unirCapas() pasa la entrada `entrar` de la capa al manifiesto;
//   - con la exportación del pipeline y la capa encendida: los ficheros de «entrar» solo llevan tramos
//     (enteros de 0 al número de cortes), uno por territorio del índice de su nivel, y ninguna serie de
//     «entrar» está en el manifiesto general.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/entrar.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerJson = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
const entrar = await modulo('web/js/entrar.js');
const datos = await modulo('web/js/datos.js');
const sueldo = await modulo('web/js/sueldo.js');
const casos = leerJson('pruebas', 'datos', 'entrar_inventado.json');
const ESTADOS = ['dato', 'estimado', 'secreto', 'ausente'];

const cerca = (a, b, info) => assert.ok(Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(b)), `${info}: ${a} frente a ${b}`);

test('R y la página coinciden: límites del tramo, intervalos y «¿te llega?» de los casos comunes', () => {
  const { tramos } = casos;
  for (const [brecha, k] of casos.brechas) {
    const l = entrar.limitesTramo(tramos, k);
    assert.ok(l.desde <= brecha && brecha < l.hasta, `brecha ${brecha} en el tramo ${k} de R`);
  }
  assert.equal(entrar.limitesTramo(tramos, -1), null);
  assert.equal(entrar.limitesTramo(tramos, tramos.cortes.length + 1), null);
  assert.equal(entrar.limitesTramo(tramos, 1.5), null);
  for (const c of casos.casos) {
    const l = entrar.limitesTramo(tramos, c.tramo);
    assert.deepEqual([l.desde, l.hasta], c.limites);
    const terminos = { alquiler_m2: c.alquiler_m2, alquiler_mes: c.alquiler_mes, ingreso: c.ingreso, superficie: c.superficie, umbral: c.umbral };
    for (const cifra of ['sueldo_entrar', 'sueldo_entrar_50', 'barrera_entrar', 'sueldo_entrar_dos']) {
      const i = entrar.cifraEntrar(cifra, tramos, c.tramo, terminos);
      cerca(i.desde, c[cifra][0], `${cifra} desde, tramo ${c.tramo}`);
      cerca(i.hasta, c[cifra][1], `${cifra} hasta, tramo ${c.tramo}`);
    }
    const ll = entrar.llegaEntrar(entrar.cifraEntrar('barrera_entrar', tramos, c.tramo, terminos));
    assert.deepEqual([ll.desde, ll.hasta], c.llega);
    assert.equal(ll.enLimite, c.llega[0] !== c.llega[1]);
  }
  assert.equal(entrar.intervaloEntrar(entrar.limitesTramo(tramos, 2), 0), null);
  assert.equal(entrar.cifraEntrar('barrera_entrar', tramos, 2, { alquiler_m2: 10, superficie: 50, ingreso: null }), null);
  assert.throws(() => entrar.cifraEntrar('oferta', tramos, 2, {}), /desconocida/);
});

test('«Tu ficha»: el sueldo del usuario da «¿te llega?» sin la oferta exacta', () => {
  // Tramo 2 (de 1,15 a 1,35), 10 €/m² en el parque: la barrera de 50 m² va de 575/x a 675/x del ingreso
  const tramos = casos.tramos;
  const llega = (ingreso) => entrar.llegaEntrar(entrar.cifraEntrar('barrera_entrar', tramos, 2,
    { alquiler_m2: 10, superficie: 50, ingreso: sueldo.ingresoPeon({ neto: ingreso, pagas: 12 }) }));
  assert.deepEqual(llega(2500), { desde: 0, hasta: 0, enLimite: false });   // 23–27 %: te llega
  assert.deepEqual(llega(1800), { desde: 1, hasta: 1, enLimite: false });   // 31,9–37,5 %
  assert.deepEqual(llega(2000), { desde: 0, hasta: 1, enLimite: true });    // 28,75–33,75 %: en el límite
  assert.deepEqual(llega(1000), { desde: 2, hasta: 2, enLimite: false });
});

test('el fichero de tramos que escribe R se lee como en R; un valor que no es un tramo es un error', () => {
  const f = casos.fichero;
  const x = entrar.decodificarTramos(JSON.parse(f.json), f.indice.length, casos.tramos, ESTADOS);
  assert.deepEqual(x.tramos, f.tramos);
  assert.deepEqual(Array.from(x.estados, (e) => ESTADOS[e]), f.estados);
  assert.throws(() => entrar.decodificarTramos({ v: [1.4, null, 5, null], e: '0302' }, 4, casos.tramos, ESTADOS), /no es un tramo/);
  assert.throws(() => entrar.decodificarTramos({ v: [6, null, 5, null], e: '0302' }, 4, casos.tramos, ESTADOS), /no es un tramo/);
});

test('unirCapas: la entrada `entrar` de una capa encendida pasa al manifiesto; apagada, nada', () => {
  const general = { indicadores: {}, mapas: {} };
  const e = { base: 'brecha_entrar_quedarse', tramos: casos.tramos, series: {} };
  const capa = { capa: 'portales', activa: true, version: 'v', generado: 'g', indicadores: {}, mapas: {}, entrar: e };
  assert.equal(datos.unirCapas(general, [capa]).entrar, e);
  assert.equal(datos.unirCapas(general, [{ ...capa, entrar: undefined }]).entrar, undefined);
  assert.equal(datos.unirCapas(general, [{ ...capa, activa: false }]).entrar, undefined);
  assert.equal(entrar.tramosDe(datos.unirCapas(general, [capa]).entrar), casos.tramos);
});

const manifiestoCapa = join(raiz, 'web', 'datos', 'portales', 'manifiesto.json');
const conEntrar = existsSync(manifiestoCapa) && Boolean(leerJson('web', 'datos', 'portales', 'manifiesto.json').entrar);
test('exportación del pipeline: los ficheros de «entrar» solo llevan tramos', { skip: !conEntrar && 'sin «entrar» en la exportación (PORTALES=TRUE)' }, () => {
  const c = leerJson('web', 'datos', 'portales', 'manifiesto.json');
  const m = leerJson('web', 'datos', 'manifiesto.json');
  const e = c.entrar;
  assert.deepEqual(Object.keys(e.series), [e.base], 'un solo dato derivado de la oferta: el tramo de la brecha');
  const def = e.series[e.base];
  assert.equal(def.valor, 'tramo');
  assert.ok(def.ruta.startsWith('datos/portales/entrar/'), def.ruta);
  assert.ok(!def.niveles.includes('sc'));
  for (const cifra of ['sueldo_entrar', 'sueldo_entrar_50', 'barrera_entrar']) {
    assert.ok(e.derivados[cifra], cifra);
    assert.ok(!(cifra in m.indicadores) && !(cifra in (m.mapas ?? {})), `${cifra}: fuera del manifiesto general`);
  }
  assert.ok(!(e.base in m.indicadores), 'la brecha, fuera del manifiesto general');
  assert.deepEqual(e.derivados.barrera_entrar.cortes, sueldo.LIMITES_LLEGA);
  const unido = datos.unirCapas(m, [c]);
  let conTramo = 0;
  for (const nivel of def.niveles) {
    const indice = leerJson('web', ...m.indices[nivel].split('/'));
    for (const anio of def.anios) {
      const ruta = def.ruta.replaceAll('{nivel}', nivel).replaceAll('{anio}', anio);
      const x = entrar.decodificarTramos(leerJson('web', ...ruta.split('/')), indice.length, unido.entrar.tramos, m.codificacion.estados);
      x.tramos.forEach((t, i) => {
        const estado = m.codificacion.estados[x.estados[i]];
        assert.equal(t !== null, estado === 'dato' || estado === 'estimado', `${ruta}, ${indice[i]}`);
        if (t !== null) conTramo++;
      });
    }
  }
  assert.ok(conTramo > 0);
});
