// Pruebas sin navegador de F5: mapas sin sección (indicador 20, zonas tensionadas, y los de F4), mapas
// de categorías y capa desmontable de los portales (indicador 13, «dato privado de oferta»).
//   - el CSV lleva la columna de la categoría y la de la etiqueta solo cuando hacen falta;
//   - con la exportación del pipeline (web/datos/manifiesto.json), cada mapa con `nivel_minimo` tiene
//     su serie sin sección y con ese nivel; las categorías tienen su texto en los dos idiomas; el
//     detalle de las declaraciones existe; y no hay ninguna serie ni mapa de los portales, que van
//     aparte, en datos/portales/ (tarea 35; pruebas/web/portales.test.mjs);
//   - los textos de la interfaz de F5 están en los dos idiomas.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/municipal.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerJson = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
const exportar = await modulo('web/js/exportar.js');
const i18n = { es: leerJson('web', 'i18n', 'es.json'), en: leerJson('web', 'i18n', 'en.json') };
const en = (dic, clave) => clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);
const ESTADOS = ['dato', 'estimado', 'secreto', 'ausente'];
const tPrueba = (clave) => clave.split('.').at(-1);
const comun = {
  t: tPrueba, codigos: ['08019', '28079'], valores: [2, 0], estados: Uint8Array.from([0, 0]), nombresEstado: ESTADOS,
  nivel: 'municipio', nombreDe: (c) => c, indicador: 'Zona tensionada', unidad: 'categoría', tipologia: '', periodo: 2026,
  fuente: 'BOE', decimales: 1,
};

test('CSV: sin categoría ni etiqueta, las columnas de siempre', () => {
  const { cabecera } = exportar.tablaCsv(comun);
  assert.deepEqual(cabecera, ['codigo', 'nombre', 'nivel', 'indicador', 'tipologia', 'periodo', 'valor', 'unidad', 'estado', 'fuente']);
});

test('CSV del indicador 20: el texto de cada categoría en su columna', () => {
  const textos = { 0: 'Sin declaración en vigor', 2: 'Declarada en todo el municipio' };
  const { cabecera, filas } = exportar.tablaCsv({ ...comun, categoria: (x) => textos[x] });
  assert.equal(cabecera.at(-1), 'categoria');
  assert.deepEqual(filas.map((f) => [f[6], f.at(-1)]), [[2, 'Declarada en todo el municipio'], [0, 'Sin declaración en vigor']]);
});

test('CSV de la capa de portales: «dato privado de oferta» en todas las filas', () => {
  const { cabecera, filas } = exportar.tablaCsv({ ...comun, valores: [12.2, null], estados: Uint8Array.from([0, 3]),
    etiqueta: 'Dato privado de oferta' });
  assert.equal(cabecera.at(-1), 'etiqueta');
  assert.deepEqual(filas.map((f) => f.at(-1)), ['Dato privado de oferta', 'Dato privado de oferta']);
});

test('textos de F5 en los dos idiomas', () => {
  const claves = ['vocabulario.etiqueta.portales', 'vocabulario.zona_tensionada.0', 'vocabulario.zona_tensionada.1',
    'vocabulario.zona_tensionada.2', 'vocabulario.corte.oferta_privada', 'vocabulario.oferta_privada.alquiler_idealista',
    'interfaz.exportar.columnas.categoria', 'interfaz.exportar.columnas.etiqueta',
    ...['titulo', 'municipio', 'parcial', 'vigencia', 'resolucion', 'ninguna', 'nota'].map((k) => `interfaz.ficha.zonas.${k}`),
    'indicadores.zona_tensionada.lectura', 'indicadores.precio_oferta.nombre'];
  for (const idioma of ['es', 'en']) {
    for (const clave of claves) assert.equal(typeof en(i18n[idioma], clave), 'string', `${idioma}: ${clave}`);
  }
  assert.match(en(i18n.es, 'interfaz.ficha.zonas.parcial'), /\{ambito\}/);
  assert.match(en(i18n.en, 'interfaz.ficha.zonas.vigencia'), /\{inicio\}.*\{fin\}/);
});

const manifiesto = join(raiz, 'web', 'datos', 'manifiesto.json');
test('exportación del pipeline: mapas sin sección, categorías y capa de portales apagada', { skip: !existsSync(manifiesto) && 'sin la exportación de la web' }, () => {
  const m = leerJson('web', 'datos', 'manifiesto.json');
  const sinSeccion = Object.entries(m.mapas).filter(([, def]) => def.nivel_minimo);
  assert.ok(sinSeccion.some(([id]) => id === 'zona_tensionada'), 'el mapa del indicador 20');
  for (const [id, def] of sinSeccion) {
    const niveles = m.indicadores[def.base].niveles;
    assert.ok(!niveles.includes('sc'), `${id}: sin sección`);
    assert.ok(niveles.includes(def.nivel_minimo), `${id}: con ${def.nivel_minimo}`);
  }
  for (const [id, def] of Object.entries(m.mapas)) {
    if (!def.nivel_minimo) assert.ok(m.indicadores[def.base].niveles.includes('sc'), `${id}: con sección`);
  }
  const z = m.mapas.zona_tensionada;
  assert.deepEqual(z.categorias.valores, [0, 1, 2]);
  assert.equal(z.cortes.length + 1, z.categorias.valores.length);
  for (const idioma of ['es', 'en']) {
    for (const v of z.categorias.valores) assert.equal(typeof en(i18n[idioma], `vocabulario.${z.categorias.vocabulario}.${v}`), 'string');
  }
  assert.ok(existsSync(join(raiz, 'web', z.detalle)), z.detalle);
  const declaraciones = leerJson('web', ...z.detalle.split('/'));
  assert.ok(Object.keys(declaraciones).length > 300);
  assert.ok(declaraciones['08019'].every((d) => /^BOE-A-\d{4}-\d+$/.test(d.boe) && d.inicio < d.fin));
  // Tarea 35: la capa de portales nunca va en la exportación general (va en datos/portales/; portales.test.mjs)
  assert.deepEqual(Object.entries(m.indicadores).filter(([, d]) => d.fuente === 'portales').map(([k]) => k), []);
  assert.deepEqual(Object.entries(m.mapas).filter(([, d]) => d.indicador === 'precio_oferta').map(([k]) => k), []);
});
