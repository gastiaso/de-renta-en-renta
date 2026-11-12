// Carga inicial del mapa (tarea 62). Lógica sin DOM y comprobaciones sobre los ficheros de la web:
//   - mapa.html lleva un modulepreload por cada módulo que importa js/principal.js, ni más ni menos,
//     después del mapa de importaciones;
//   - la ficha de una sección sale del fichero de su municipio o, en los municipios partidos, del de
//     su distrito; sin las claves nuevas en el manifiesto (datos de la v1.1.0, la muestra), como antes;
//   - el zoom desde el que se piden las secciones y la banda de la llave con los cuartiles del manifiesto;
//   - con la exportación del pipeline: los ficheros partidos existen, traen los contratos y el margen,
//     y los cuartiles del manifiesto son los que la web calcula con los valores de las secciones.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/carga.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import { join, posix } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leer = (...ruta) => JSON.parse(leerTexto(...ruta));

// Módulos que importa un módulo de web/, de forma estática, con los suyos (rutas relativas a web/;
// «maplibre-gl», la del mapa de importaciones).
function importaciones(ruta, vistos = new Set()) {
  const texto = leerTexto('web', ruta);
  const re = /^\s*(?:import|export)\s[^;]*?from\s+['"]([^'"]+)['"]/gms;
  for (const [, especificador] of texto.matchAll(re)) {
    const destino = especificador === 'maplibre-gl'
      ? 'vendor/maplibre-gl/maplibre-gl.mjs'
      : posix.join(posix.dirname(ruta), especificador);
    if (vistos.has(destino)) continue;
    vistos.add(destino);
    if (!destino.startsWith('vendor/')) importaciones(destino, vistos);
  }
  return vistos;
}

test('mapa.html: un modulepreload por módulo que importa principal.js, después del mapa de importaciones', () => {
  const html = leerTexto('web', 'mapa.html');
  const precargas = [...html.matchAll(/<link rel="modulepreload" href="([^"]+)">/g)].map((x) => x[1]);
  const esperadas = importaciones('js/principal.js');
  assert.equal(new Set(precargas).size, precargas.length, 'sin repetidos');
  assert.deepEqual([...precargas].sort(), [...esperadas].sort());
  assert.ok(esperadas.size > 20, 'el grafo de importaciones se ha leído');
  assert.ok(html.indexOf('type="importmap"') < html.indexOf('rel="modulepreload"'), 'el mapa de importaciones, antes');
  for (const ruta of precargas) assert.ok(existsSync(join(raiz, 'web', ruta)), ruta);
});

test('rutaFicha: municipio entero o, si está partido, su distrito; sin las claves nuevas, como antes', async () => {
  const { rutaFicha } = await modulo('web/js/datos.js');
  const nuevo = {
    fichas: 'datos/fichas/{municipio}.json', fichas_distrito: 'datos/fichas/{municipio}/{distrito}.json',
    fichas_partidas: ['28079', '08019'],
  };
  assert.equal(rutaFicha(nuevo, '2807901120'), 'datos/fichas/28079/01.json');
  assert.equal(rutaFicha(nuevo, '0801910005'), 'datos/fichas/08019/10.json');
  assert.equal(rutaFicha(nuevo, '0100101001'), 'datos/fichas/01001.json');
  const antiguo = { fichas: 'datos/fichas/{municipio}.json' };   // datos de la v1.1.0
  assert.equal(rutaFicha(antiguo, '2807901120'), 'datos/fichas/28079.json');
  assert.equal(rutaFicha({}, '2807901120'), null);
});

test('zoom de las secciones y cuartiles de la llave: del manifiesto, y sin ellos como antes', async () => {
  const { zoomSecciones, cuartilesSc } = await modulo('web/js/datos.js');
  assert.equal(zoomSecciones({ secciones_desde_zoom: 7 }), 7);
  assert.equal(zoomSecciones({}), 0);                                   // datos de la v1.1.0: desde el principio
  assert.equal(zoomSecciones(leer('web', 'datos', 'ejemplo', 'manifiesto.json')), 0);   // la muestra
  const m = { indicadores: { renta_hogar: { cuartiles_sc: { 2023: [30000, 42000], 2024: [1, 'x'] } } } };
  assert.deepEqual(cuartilesSc(m, 'renta_hogar', 2023), [30000, 42000]);
  assert.equal(cuartilesSc(m, 'renta_hogar', 2024), null);             // mal formados: nada
  assert.equal(cuartilesSc(m, 'renta_hogar', 2022), null);
  assert.equal(cuartilesSc(m, 'otra', 2023), null);
});

test('regla de la leyenda: la banda de la llave con los cuartiles es la de los valores de las secciones', async () => {
  const { marcasRegla, cuantil } = await modulo('web/js/sueldo.js');
  const perfiles = { llave: { ingreso: { serie: 'renta_hogar', divisor: 12 } } };
  const renta = [24000, null, 30000, 36000, 41000.5, 52000];
  const desdeValores = marcasRegla({ perfiles, rentaHogar: renta }).llave;
  const conCuartiles = marcasRegla({ perfiles, cuartiles: [cuantil(renta, 0.25), cuantil(renta, 0.75)] }).llave;
  assert.ok(Math.abs(desdeValores.desde - conCuartiles.desde) < 1e-9);
  assert.ok(Math.abs(desdeValores.hasta - conCuartiles.hasta) < 1e-9);
  // Los cuartiles mandan sobre los valores; sin ninguno de los dos, sin banda
  assert.equal(marcasRegla({ perfiles, rentaHogar: renta, cuartiles: [1200, 2400] }).llave.desde, 100);
  assert.equal(marcasRegla({ perfiles }).llave, null);
});

const exportada = existsSync(join(raiz, 'web', 'datos', 'manifiesto.json'));
test('exportación del pipeline: secciones desde el zoom 7, fichas partidas con contratos y margen, cuartiles',
  { skip: !exportada && 'sin web/datos/manifiesto.json' }, async () => {
    const { rutaFicha, decodificar, codificacionDe, periodosDe, rutaValores, cuartilesSc } = await modulo('web/js/datos.js');
    const { cuantil } = await modulo('web/js/sueldo.js');
    const m = leer('web', 'datos', 'manifiesto.json');
    if (m.secciones_desde_zoom === undefined) return;   // exportación anterior a la tarea 62
    assert.equal(m.secciones_desde_zoom, 7);
    const sc = leer('web', m.indices.sc);
    // Madrid, partido: cada distrito con sus secciones, contratos y margen, y menos de 0,3 MB comprimido
    assert.ok(m.fichas_partidas.includes('28079'));
    const madrid = sc.filter((c) => c.startsWith('28079'));
    const distritos = [...new Set(madrid.map((c) => c.slice(5, 7)))];
    let mayor = 0;
    for (const d of distritos) {
      const ruta = rutaFicha(m, `28079${d}001`);
      const texto = leerTexto('web', ruta);
      mayor = Math.max(mayor, gzipSync(texto).length);
      const f = JSON.parse(texto);
      assert.equal(f.distrito, d);
      assert.deepEqual(Object.keys(f.series).sort(), madrid.filter((c) => c.slice(5, 7) === d).sort(), `distrito ${d}`);
      for (const serie of Object.values(m.indicadores.alquiler_mes.fiabilidad)) {
        assert.deepEqual(f.anios[serie], periodosDe(m.indicadores[serie]), `${serie} en el distrito ${d}`);
      }
    }
    assert.ok(mayor < 300_000, `el distrito más pesado de Madrid, ${mayor} bytes comprimidos`);
    // Un fichero partido y otro entero no se pisan: el entero de Madrid ya no está
    assert.equal(existsSync(join(raiz, 'web', m.fichas.replace('{municipio}', '28079'))), false);
    // Contratos de una sección de Madrid en un año: los mismos en la ficha y en el fichero nacional
    const serie = m.indicadores.alquiler_mes.fiabilidad.contratos;
    const p = periodosDe(m.indicadores[serie]).at(-1);
    const nacional = decodificar(leer('web', rutaValores(m.indicadores[serie], 'sc', p)), sc.length, codificacionDe(m, serie));
    const i = sc.indexOf(madrid[0]);
    const ficha = leer('web', rutaFicha(m, madrid[0]));
    const k = ficha.anios[serie].indexOf(p);
    const enFicha = decodificar(ficha.series[madrid[0]][serie], ficha.anios[serie].length, codificacionDe(m, serie));
    assert.equal(enFicha.valores[k], nacional.valores[i]);
    assert.equal(enFicha.estados[k], nacional.estados[i]);
    // Cuartiles de la llave: los del manifiesto son los que la web calcula con los valores (último año)
    const renta = leer('web', 'datos', 'perfiles.json').llave.ingreso.serie;
    const anio = periodosDe(m.indicadores[renta]).at(-1);
    const valores = decodificar(leer('web', rutaValores(m.indicadores[renta], 'sc', anio)), sc.length, codificacionDe(m, renta)).valores;
    const q = cuartilesSc(m, renta, anio);
    assert.ok(q, `cuartiles de ${renta} en ${anio}`);
    assert.ok(Math.abs(q[0] - cuantil(valores, 0.25)) < 1e-6);
    assert.ok(Math.abs(q[1] - cuantil(valores, 0.75)) < 1e-6);
  });
