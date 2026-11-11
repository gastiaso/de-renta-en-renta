// Decisiones del autor del 11-nov-2026 sobre la web (plan §11): escala relativa al municipio
// (web/js/escala_municipio.js), superficie típica como opción de «Tu ficha» y en la ficha de
// municipio (web/js/sueldo.js, estado.js) y ficha del territorio que contiene lo elegido en los mapas
// de una sola escala (territorioEnNivel(), web/js/comparador.js). Con la exportación del pipeline
// (web/datos/), también los septiles de Madrid y Barcelona. Se ejecutan desde la raíz del proyecto,
// sin paquetes:
//   node --test pruebas/web/escala_municipio.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerJson = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
const E = await modulo('web/js/escala_municipio.js');
const sueldo = await modulo('web/js/sueldo.js');
const { leerEstado } = await modulo('web/js/estado.js');
const { territorioEnNivel } = await modulo('web/js/comparador.js');
const { juegoDe } = await modulo('web/js/colores.js');
const i18n = { es: leerJson('web', 'i18n', 'es.json'), en: leerJson('web', 'i18n', 'en.json') };
const en = (dic, clave) => clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);
const enOrden = (x) => x.every((c, i) => i === 0 || c > x[i - 1]);

const conJuegos = { base: 'renta_hogar', formula: 'directo', cortes: [1, 2], juegos: { seccion: { cortes: [1, 2] }, municipio: { cortes: [3, 4] } } };

test('la escala relativa solo se ofrece en los mapas con juego de cortes de la sección', () => {
  assert.equal(E.admiteRelativa(conJuegos), true);
  assert.equal(E.admiteRelativa(conJuegos, { modo: 'llega' }), false);                 // «¿te llega?»: tramos fijos
  assert.equal(E.admiteRelativa(conJuegos, { nivelMinimo: 'municipio' }), false);       // mapas sin sección
  assert.equal(E.admiteRelativa(conJuegos, { privado: true }), false);                  // capa de portales
  assert.equal(E.admiteRelativa({ ...conJuegos, categorias: { valores: [0, 1] } }), false);   // zona tensionada
  assert.equal(E.admiteRelativa({ base: 'viviendas_turisticas', cortes: [1, 2] }), false);   // sin juegos
  assert.equal(E.admiteRelativa({ ...conJuegos, juegos: { municipio: { cortes: [3, 4] } } }), false);
  assert.equal(E.MINIMO_SECCIONES_RELATIVA, 14);
});

test('manda el municipio de la ficha; sin ficha de sección ni de municipio, el del centro', () => {
  assert.equal(E.municipioQueManda({ seccion: '0801901001', centro: '28079' }), '08019');
  assert.equal(E.municipioQueManda({ territorio: { nivel: 'municipio', codigo: '41091' }, centro: '28079' }), '41091');
  assert.equal(E.municipioQueManda({ territorio: { nivel: 'provincia', codigo: '28' }, centro: '28079' }), '28079');
  assert.equal(E.municipioQueManda({}), null);
  assert.equal(E.municipioQueManda({ centro: 'x' }), null);
});

test('septiles: seis cortes que dejan un séptimo de los valores en cada tramo', () => {
  const valores = Array.from({ length: 700 }, (_, i) => i + 1);
  const cortes = E.cuantilesCortes(valores);
  assert.equal(cortes.length, 6);
  assert.deepEqual(E.reparto(valores, cortes.map(Math.ceil)), [100, 100, 100, 100, 100, 100, 100]);
});

test('redondeo legible: pasos de 1, 2, 2,5 o 5 por una potencia de 10, en orden y sin pasar de los decimales', () => {
  // Madrid, renta por hogar de 2024 (septiles sin redondear)
  assert.deepEqual(E.redondearCortes([33751.6, 37045.4, 41655, 48273.9, 57332.1, 73721.6]), [34000, 37000, 42000, 48000, 57000, 74000]);
  // Un hueco estrecho no obliga a cifras sin redondear (pasos de 5, no de 2)
  assert.deepEqual(E.redondearCortes([634.2, 650.1, 671.9, 695.7, 700, 750]), [635, 650, 670, 695, 700, 750]);
  // Con decimales: porcentajes con uno
  const pct = E.redondearCortes([12.34, 13.81, 15.02, 16.77, 18.9, 22.45], 1);
  assert.ok(enOrden(pct));
  assert.ok(pct.every((c) => Math.abs(c * 10 - Math.round(c * 10)) < 1e-9));
  // Sin decimales en el mapa, nunca un paso de 2,5
  assert.ok(E.redondearCortes([1.1, 3.4, 5.9, 8.2, 10.6, 13.3], 0).every(Number.isInteger));
  // Repetidos (muchas secciones con la misma cifra): fuera, menos tramos
  assert.deepEqual(E.redondearCortes([700, 700, 750, 800, 900, 1000]), [700, 750, 800, 900, 1000]);
  assert.deepEqual(E.redondearCortes([]), []);
  // En orden con cualquier entrada
  let semilla = 7;
  const azar = () => { semilla = (semilla * 16807) % 2147483647; return semilla / 2147483647; };
  for (let k = 0; k < 300; k++) {
    const escala = 10 ** Math.floor(azar() * 6 - 1);
    const crudos = Array.from({ length: 6 }, () => azar() * 100 * escala).sort((a, b) => a - b);
    const dec = Math.floor(azar() * 3);
    const r = E.redondearCortes(crudos, dec);
    assert.ok(enOrden(r), `${crudos} → ${r}`);
    assert.ok(r.every((c) => Math.abs(c * 10 ** dec - Math.round(c * 10 ** dec)) < 1e-6), `decimales ${dec}: ${r}`);
  }
});

test('cortes relativos: con menos de 14 secciones con dato, ninguno', () => {
  const trece = Array.from({ length: 13 }, (_, i) => 500 + 10 * i);
  assert.deepEqual(E.cortesRelativos([...trece, null, NaN]), { n: 13, cortes: null });
  const r = E.cortesRelativos([...trece, 640]);
  assert.equal(r.n, 14);
  assert.equal(r.cortes.length, 6);
  assert.ok(enOrden(r.cortes));
});

test('fuera del municipio, las secciones van del color que se pase (sin color)', () => {
  const x = E.soloEnMunicipio(['get', 'color'], { municipio: '28079', idSeccion: 'cusec', fueraColor: '#fffaf0' });
  assert.deepEqual(x, ['case', ['==', ['slice', ['to-string', ['get', 'cusec']], 0, 5], '28079'], ['get', 'color'], '#fffaf0']);
  // colorNecesario con cortes propios: los de la escala relativa, no los del juego
  const paleta = { rampa: ['a', 'b', 'c', 'd', 'e', 'f', 'g'], fuera: 'z' };
  const color = sueldo.colorNecesario(conJuegos, null, paleta, 'sc', [10, 20, 30, 40, 50, 60]);
  assert.deepEqual(color[3].slice(3), [10, 'b', 20, 'c', 30, 'd', 40, 'e', 50, 'f', 60, 'g']);
  assert.deepEqual(juegoDe(conJuegos, 'sc').cortes, [1, 2]);
});

test('estado: la escala y la superficie típica entran en la URL', () => {
  assert.equal(leerEstado('?escala=municipio').escala, 'municipio');
  assert.equal(leerEstado('?escala=provincia').escala, undefined);
  assert.equal(leerEstado('?superficie=tipica').superficie, 'tipica');
  assert.equal(leerEstado('?superficie=60').superficie, undefined);
});

test('superficie típica: opción de «Tu ficha»; las fichas de perfil y la llave siguen con la suya', () => {
  const perfiles = { tartera: { superficie_m2: 50 }, llave: {} };
  const sueldoPeon = { neto: 1500, pagas: 12 };
  assert.equal(sueldo.superficieDe({ superficie: 'tipica' }, null, perfiles, 62.3), 62.3);
  assert.equal(sueldo.superficieDe({ ficha: 'peon', superficie: 'tipica' }, sueldoPeon, perfiles, 66), 66);
  assert.equal(sueldo.superficieDe({ superficie: 'tipica' }, null, perfiles, null), 50);   // sin territorio: la de por defecto
  assert.equal(sueldo.superficieDe({ ficha: 'peon', superficie: 'tipica' }, { ...sueldoPeon, segundo: 900 }, perfiles, null), 70);
  assert.equal(sueldo.superficieDe({ ficha: 'tartera', superficie: 'tipica' }, null, perfiles, 62), 50);
  assert.equal(sueldo.superficieDe({ ficha: 'llave', superficie: 'tipica' }, null, perfiles, 62), null);
  assert.equal(sueldo.superficieDe({}, null, perfiles, 62), 50);   // por defecto, 50 m² (sin cambiar)
  const html = readFileSync(join(raiz, 'web', 'mapa.html'), 'utf8');
  assert.match(html, /data-superficie="tipica"/);
});

test('mapas de una sola escala: lo elegido se ve en la ficha del territorio de su nivel más fino', () => {
  assert.deepEqual(territorioEnNivel({ nivel: 'sc', codigo: '2807901001' }, 'provincia'), { nivel: 'provincia', codigo: '28' });
  assert.deepEqual(territorioEnNivel({ nivel: 'municipio', codigo: '28065' }, 'provincia'), { nivel: 'provincia', codigo: '28' });
  assert.deepEqual(territorioEnNivel({ nivel: 'sc', codigo: '0801901001' }, 'municipio'), { nivel: 'municipio', codigo: '08019' });
  assert.deepEqual(territorioEnNivel({ nivel: 'municipio', codigo: '28065' }, 'municipio'), { nivel: 'municipio', codigo: '28065' });
  assert.deepEqual(territorioEnNivel({ nivel: 'ccaa', codigo: '13' }, 'provincia'), { nivel: 'ccaa', codigo: '13' });
  assert.deepEqual(territorioEnNivel({ nivel: 'municipio', codigo: '28079' }, 'sc'), { nivel: 'municipio', codigo: '28079' });
});

test('textos de la escala relativa y de la superficie típica en los dos idiomas', () => {
  const claves = ['interfaz.leyenda.relativa.titulo', 'interfaz.leyenda.relativa.nacional', 'interfaz.leyenda.relativa.municipio',
    'interfaz.leyenda.relativa.municipio_sin', 'interfaz.leyenda.relativa.linea', 'interfaz.leyenda.relativa.fuera',
    'interfaz.leyenda.relativa.pocas', 'interfaz.leyenda.relativa.sin_municipio', 'interfaz.sueldo.tipica',
    'interfaz.sueldo.tipica_nota', 'interfaz.sueldo.tipica_sin', 'interfaz.sueldo.tipica_elegir', 'interfaz.ficha.superficie_tipica'];
  for (const idioma of ['es', 'en']) {
    for (const clave of claves) assert.equal(typeof en(i18n[idioma], clave), 'string', `${idioma}: ${clave}`);
  }
  // La línea dice que los tramos no se comparan con otros municipios
  assert.match(en(i18n.es, 'interfaz.leyenda.relativa.linea'), /no comparables con otros municipios/);
  assert.match(en(i18n.en, 'interfaz.leyenda.relativa.linea'), /not comparable with other municipalities/);
});

// Con la exportación del pipeline: Madrid y Barcelona, renta por hogar y alquiler mensual del último año
const manifiesto = join(raiz, 'web', 'datos', 'manifiesto.json');
test('septiles de Madrid y Barcelona con los datos exportados', { skip: !existsSync(manifiesto) && 'sin la exportación de la web' }, () => {
  const m = leerJson('web', 'datos', 'manifiesto.json');
  const codigos = leerJson('web', 'datos', 'indices', 'sc.json');
  const lista = Array.isArray(codigos) ? codigos : codigos.codigos;
  for (const mapa of ['renta_hogar', 'alquiler_mes']) {
    const def = m.mapas[mapa];
    assert.ok(E.admiteRelativa(def), `${mapa}: admite la escala relativa`);
    const serie = m.indicadores[def.base];
    const escala = serie.escala ?? m.codificacion.escala ?? 1;
    const d = leerJson('web', ...serie.ruta.replace('{nivel}', 'sc').replace('{anio}', String(serie.anios.at(-1))).split('/'));
    for (const municipio of ['28079', '08019']) {
      const valores = [];
      lista.forEach((c, i) => { if (c.startsWith(municipio) && d.v[i] !== null) valores.push(d.v[i] / escala); });
      const { n, cortes } = E.cortesRelativos(valores, { decimales: def.decimales ?? 0 });
      assert.ok(n >= 1000, `${mapa} ${municipio}: ${n} secciones`);
      assert.equal(cortes.length, 6, `${mapa} ${municipio}: ${cortes}`);
      const cuenta = E.reparto(valores, cortes);
      // Ningún tramo vacío ni con más del doble de un séptimo (los empates mueven secciones de tramo)
      assert.ok(cuenta.every((x) => x > 0 && x <= (2 * n) / 7), `${mapa} ${municipio}: ${cuenta}`);
      // Con los cortes de la sección, el centro cae casi entero en el tramo más alto (la razón de la opción)
      const nacional = E.reparto(valores, juegoDe(def, 'sc').cortes);
      assert.ok(nacional.at(-1) / n > 0.5, `${mapa} ${municipio}: ${nacional}`);
    }
  }
});
