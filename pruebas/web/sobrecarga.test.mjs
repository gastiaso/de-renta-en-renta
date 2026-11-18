// Pruebas de la sección «Sobrecarga» sin navegador (web/js/sobrecarga_datos.js), con datos
// inventados; si el pipeline ya ha exportado web/datos/sobrecarga/, se comprueba también su
// contrato. Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/sobrecarga.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const S = await import(pathToFileURL(join(raiz, 'web/js/sobrecarga_datos.js')).href);
const leer = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));

// Traductor mínimo: devuelve la clave con sus valores, y los países de un diccionario fijo
const PAISES = { EL: 'Grecia', AT: 'Austria', ES: 'España', EU27_2020: 'UE-27' };
const t = (clave, valores = {}) => {
  if (clave.startsWith('sobrecarga.paises.')) return PAISES[clave.split('.').at(-1)];
  if (clave === 'sobrecarga.formato.porcentaje') return `${valores.x} %`;
  return `${clave}${Object.keys(valores).length ? ` ${JSON.stringify(valores)}` : ''}`;
};
t.existe = (clave) => clave.startsWith('sobrecarga.paises.') && clave.split('.').at(-1) in PAISES;
t.numero = (x, d = 0) => x.toFixed(d).replace('.', ',');

const fila = (geo, puesto, v, bloque, extra = {}) => ({ geo, puesto, v, bloque, nivel: 2, ...extra });
const DATOS = {
  escala: 10,
  anios: [2024, 2025],
  anio_desgloses: 2025,
  cortes: { general: [4, 6, 8, 10, 15], RENT_MKT: [15, 20, 25, 30, 40] },
  grupos_mapa: { tenencia: ['RENT_MKT', 'OWN_L'], edad: ['Y_LT18'] },
  comunidades: { ES30: { codigo: '13', nombre: 'Madrid, Comunidad de' } },
  nombres: { EL51: 'Anatoliki Makedonia, Thraki', NL1: 'Noord-Nederland' },
  vistas: [
    { clave: 'total-2024', corte: 'total', grupo: 'total', anio: 2024, nuts: '2024', filas: [fila('EL51', 1, 300, 'europa')] },
    {
      clave: 'total-2025', corte: 'total', grupo: 'total', anio: 2025, nuts: '2024',
      filas: [
        fila('EL51', 1, 339, 'europa'), fila('AT', 2, 70, 'europa', { nivel: 0 }), fila('NL1', 3, 69, 'europa', { nivel: 1 }),
        fila('EU27_2020', 4, 76, 'referencia', { nivel: undefined }), fila('ES', 5, 72, 'referencia', { nivel: undefined, n: 71161 }),
        fila('ES30', 6, 99, 'comunidad', { n: 7089, fiabilidad: 'normal' }), fila('ES64', null, null, 'comunidad', { fiabilidad: 'no publicable' }),
        fila('ES63', 7, 40, 'comunidad', { fiabilidad: 'baja' }),
      ],
    },
    { clave: 'tenencia-RENT_MKT-2025', corte: 'tenencia', grupo: 'RENT_MKT', anio: 2025, nuts: '2024', filas: [fila('RO', 1, 560, 'europa', { nivel: 0 })] },
  ],
};
// Con la segunda medida (indicador 24): sus años, cortes, grupos y vistas
const DATOS_P = {
  ...DATOS,
  pobreza: {
    anios: [2023, 2025], anio_desgloses: 2025, olas: { anuales: [2023, 2025], agrupadas: [2023, 2025] },
    cortes: { general: [20, 25, 30, 35, 40], RENT_MKT: [45, 50, 55, 60, 70] }, grupos_mapa: { tenencia: ['RENT_MKT', 'OWN_L'] },
    umbrales: [{ anio: 2023, euros: 10990 }, { anio: 2025, euros: 12220 }],
  },
  vistas: [
    ...DATOS.vistas,
    { clave: 'pobreza-total-2023', medida: 'pobreza', corte: 'total', grupo: 'total', anio: 2023, nuts: '2021', filas: [fila('EL', 1, 418, 'europa', { nivel: 0 })] },
    { clave: 'pobreza-total-2025', medida: 'pobreza', corte: 'total', grupo: 'total', anio: 2025, nuts: '2024',
      filas: [fila('EL', 1, 418, 'europa', { nivel: 0 }), fila('ES', 2, 287, 'referencia', { nivel: undefined, n: 71161 })] },
    { clave: 'pobreza-tenencia-RENT_MKT-2025', medida: 'pobreza', corte: 'tenencia', grupo: 'RENT_MKT', anio: 2025, nuts: '2024',
      filas: [fila('ES42', 1, 708, 'comunidad'), fila('ES', 2, 567, 'referencia', { nivel: undefined })] },
  ],
};

test('estado de la URL: valida corte, grupo, año y territorio contra los datos', () => {
  assert.deepEqual(S.leerEstado('?idioma=en'), { idioma: 'en', medida: 'sobrecarga', corte: 'total', grupo: 'total', anio: null, geo: null });
  assert.deepEqual(S.leerEstado('', DATOS), { idioma: 'es', medida: 'sobrecarga', corte: 'total', grupo: 'total', anio: 2025, geo: null });
  assert.equal(S.leerEstado('?anio=2024', DATOS).anio, 2024);
  assert.equal(S.leerEstado('?anio=1999', DATOS).anio, 2025);
  const desglose = S.leerEstado('?corte=tenencia&grupo=RENT_MKT&anio=2024&geo=ES30', DATOS);
  assert.deepEqual(desglose, { idioma: 'es', medida: 'sobrecarga', corte: 'tenencia', grupo: 'RENT_MKT', anio: 2025, geo: 'ES30' });
  // Grupo que no está en el mapa, o sin vista: toda la población
  assert.equal(S.leerEstado('?corte=tenencia&grupo=RENT_FR', DATOS).corte, 'total');
  assert.equal(S.leerEstado('?corte=tenencia&grupo=OWN_L', DATOS).corte, 'total');
  assert.equal(S.leerEstado('?geo=<script>', DATOS).geo, null);
});

test('dos medidas: la pobreza tras la vivienda con sus años, grupos, cortes y vistas', () => {
  assert.deepEqual(S.medidasCon(DATOS), ['sobrecarga']);
  assert.deepEqual(S.medidasCon(DATOS_P), ['sobrecarga', 'pobreza']);
  // Sin el bloque `pobreza`, la medida de la dirección no vale
  assert.equal(S.leerEstado('?medida=pobreza', DATOS).medida, 'sobrecarga');
  assert.deepEqual(S.leerEstado('?medida=pobreza', DATOS_P),
    { idioma: 'es', medida: 'pobreza', corte: 'total', grupo: 'total', anio: 2025, geo: null });
  assert.equal(S.leerEstado('?medida=pobreza&anio=2023', DATOS_P).anio, 2023);
  assert.equal(S.leerEstado('?medida=pobreza&anio=2024', DATOS_P).anio, 2025);          // 2024 es de la sobrecarga
  assert.equal(S.leerEstado('?medida=pobreza&corte=edad&grupo=Y_LT18', DATOS_P).corte, 'total');
  assert.equal(S.leerEstado('?medida=pobreza&corte=tenencia&grupo=RENT_MKT', DATOS_P).grupo, 'RENT_MKT');
  assert.equal(S.vistaDe(DATOS_P, { medida: 'pobreza' }).clave, 'pobreza-total-2025');
  assert.equal(S.vistaDe(DATOS_P, {}).clave, 'total-2025');                               // la sobrecarga, por defecto
  assert.equal(S.vistaDe(DATOS_P, { medida: 'pobreza', corte: 'tenencia', grupo: 'RENT_MKT' }).clave, 'pobreza-tenencia-RENT_MKT-2025');
  assert.deepEqual(S.gruposCon(DATOS_P, 'tenencia', 'pobreza'), ['RENT_MKT']);
  assert.deepEqual(S.gruposCon(DATOS_P, 'tenencia'), ['RENT_MKT']);
  assert.equal(S.ultimoAnio(DATOS_P, 'pobreza'), 2025);
  assert.deepEqual(S.cortesDe(DATOS_P, 'total', 'pobreza'), [20, 25, 30, 35, 40]);
  assert.deepEqual(S.cortesDe(DATOS_P, 'RENT_MKT', 'pobreza'), [45, 50, 55, 60, 70]);
  assert.deepEqual(S.cortesDe(DATOS_P, 'RENT_MKT'), [15, 20, 25, 30, 40]);
  assert.equal(S.umbralDe(DATOS_P, 2025), 12220);
  assert.equal(S.umbralDe(DATOS, 2025), null);
  // Los países de la pobreza son todos de nivel país: sin trama de nivel grueso
  assert.deepEqual(S.conTramaGruesa(S.vistaDe(DATOS_P, { medida: 'pobreza' })), []);
  assert.equal(S.consulta({ idioma: 'en', medida: 'pobreza', corte: 'total', grupo: 'total', anio: 2025, geo: null }, DATOS_P),
    '?idioma=en&medida=pobreza');
  assert.equal(S.consulta({ idioma: 'es', medida: 'pobreza', corte: 'total', grupo: 'total', anio: 2023, geo: 'ES42' }, DATOS_P),
    '?medida=pobreza&anio=2023&geo=ES42');
  assert.equal(S.consulta({ idioma: 'es', medida: 'pobreza', corte: 'tenencia', grupo: 'RENT_MKT', anio: 2025, geo: null }, DATOS_P),
    '?medida=pobreza&corte=tenencia&grupo=RENT_MKT');
});

test('pobreza: serie de ilc_li48 y desgloses de España por edad y grado de urbanización', () => {
  const serie22 = { anios: [2024, 2025], valores: { ES_TOTAL: [78, 72] }, marcas: { ES_TOTAL: [null, 'b'] } };
  const serie24 = { anios: [2004, 2025], valores: { ES_TOTAL: [275, 287], EU27_TOTAL: [null, 294] }, marcas: {} };
  const espana = { serie: serie22, anual: [
    { anio: 2025, corte: 'total', grupo: 'total', v: 72 }, { anio: 2025, corte: 'edad', grupo: 'Y15-29', v: 72 },
    { anio: 2025, corte: 'quintil', grupo: 'QU1', v: 277 }, { anio: 2024, corte: 'tenencia', grupo: 'RENT_MKT', v: 281 }] };
  const d = { ...DATOS_P, espana, pobreza: { ...DATOS_P.pobreza, serie: serie24, espana: [
    { anio: 2025, corte: 'total', grupo: 'total', v: 287 }, { anio: 2025, corte: 'urbanizacion', grupo: 'DEG3', v: 303 },
    { anio: 2025, corte: 'edad', grupo: 'Y_GE18', v: 267 }, { anio: 2025, corte: 'tenencia', grupo: 'RENT_MKT', v: 567 }] } };
  // Serie: la de la sobrecarga por defecto; con la pobreza, la de ilc_li48 (España y UE-27, sin alquiler)
  assert.equal(S.serieDe(d), serie22);
  assert.equal(S.serieDe(d, 'pobreza'), serie24);
  assert.deepEqual(S.lineasSerie(d, 'pobreza').map((l) => l.clave), ['ES_TOTAL', 'EU27_TOTAL']);
  assert.equal(S.lineasSerie(d).length, 4);
  // Sin `pobreza.serie` (exportación anterior), la de la sobrecarga
  const sinSerie = { ...d, pobreza: { ...d.pobreza, serie: undefined } };
  assert.equal(S.serieDe(sinSerie, 'pobreza'), serie22);
  assert.equal(S.lineasSerie(sinSerie, 'pobreza').length, 4);
  // Desgloses: cada medida con sus filas y sus cortes, en orden; la pobreza sin quintil
  const fp = S.filasDesgloses(d, 'pobreza', 2025);
  assert.deepEqual(S.cortesDesgloses(fp), ['tenencia', 'edad', 'urbanizacion']);
  assert.deepEqual(S.cortesDesgloses(S.filasDesgloses(d, 'sobrecarga', 2025)), ['edad', 'quintil']);
  assert.deepEqual(S.filasDesgloses(d, 'sobrecarga', 2024).map((f) => f.grupo), ['RENT_MKT']);
  assert.ok(S.ORDEN_DESGLOSES.edad.includes('Y_GE18') && S.ORDEN_DESGLOSES.urbanizacion.length === 3);
  // Notas de los desgloses: la de cada medida, en los dos idiomas, y la página tiene las dos
  const html = readFileSync(join(raiz, 'web', 'sobrecarga.html'), 'utf8');
  assert.match(html, /data-i18n="sobrecarga\.desgloses\.nota_pobreza" hidden/);
  // Qué notas se ven con cada medida (revisión del 17-nov-2026: antes se buscaba el texto del código)
  assert.deepEqual(S.notasDesgloses('pobreza'), ['nota_pobreza']);
  assert.deepEqual(S.notasDesgloses('sobrecarga'), ['nota', 'nota_quintil']);
  for (const n of S.NOTAS_DESGLOSES) assert.match(html, new RegExp(`data-i18n="sobrecarga\\.desgloses\\.${n}"`), `la página tiene la nota ${n}`);
  for (const idioma of ['es', 'en']) {
    const s = leer('web', 'i18n', `${idioma}.json`).sobrecarga;
    for (const k of ['nota_pobreza', 'urbanizacion']) assert.ok(s.desgloses[k]?.length, `${idioma} desgloses.${k}`);
    assert.ok(!/15/.test(s.desgloses.nota_pobreza), `${idioma}: la nota de la pobreza no habla del grupo de 15 a 29`);
    for (const k of ['subtitulo_pobreza', 'fuente_pobreza', 'rupturas_atlas_pobreza', 'grafico_pobreza']) {
      assert.ok(s.serie[k]?.length, `${idioma} serie.${k}`);
    }
    assert.deepEqual([...s.serie.grafico_pobreza.matchAll(/\{(\w+)\}/g)].map((x) => x[1]), ['desde', 'hasta']);
  }
});

test('textos de la pobreza tras la vivienda en los dos idiomas, con las mismas marcas', () => {
  const marcas = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort();
  const claves = ['controles.medida', 'controles.medidas.sobrecarga', 'controles.medidas.pobreza', 'controles.nota_pobreza',
    'controles.nota_desglose_pobreza', 'controles.nota_desglose_pobreza_edad', 'mapa.titulo_pobreza_tenencia',
    'mapa.fuente_pobreza', 'mapa.fuente_pobreza_tenencia', 'mapa.nota_pobreza', 'mapa.nota_pobreza_tenencia',
    'mapa.nota_pobreza_edad', 'detalle.puesto_nota_pobreza_olas', 'escalera.periodo_pobreza', 'desgloses.titulo_pobreza',
    'metodo.pobreza'];
  const es = leer('web', 'i18n', 'es.json').sobrecarga;
  const en = leer('web', 'i18n', 'en.json').sobrecarga;
  const de = (d, k) => k.split('.').reduce((x, p) => x?.[p], d);
  for (const k of claves) {
    assert.ok(typeof de(es, k) === 'string' && de(es, k).length, `es ${k}`);
    assert.ok(typeof de(en, k) === 'string' && de(en, k).length, `en ${k}`);
    assert.deepEqual(marcas(de(es, k)), marcas(de(en, k)), k);
  }
  const js = readFileSync(join(raiz, 'web', 'js', 'sobrecarga.js'), 'utf8');
  for (const k of claves.filter((x) => !x.startsWith('metodo.') && !x.startsWith('controles.medida'))) {
    assert.ok(js.includes(`'sobrecarga.${k}'`), `sobrecarga.js usa ${k}`);
  }
  // Botón del grupo «18 y más» (pobreza por edad, 18-nov-2026) y grado de urbanización en la nota de la sobrecarga
  assert.ok(es.controles.grupos.Y_GE18 && en.controles.grupos.Y_GE18);
  assert.match(es.desgloses.nota, /ilc_lvho07d/);
  assert.match(en.desgloses.nota, /ilc_lvho07d/);
  const html = readFileSync(join(raiz, 'web', 'sobrecarga.html'), 'utf8');
  assert.match(html, /data-i18n="sobrecarga\.metodo\.pobreza"/);
  assert.match(html, /id="sc-medida"/);
});

test('grado de urbanización en el mapa de la sobrecarga y total con el último trienio en la pobreza (18-nov-2026)', () => {
  const d = {
    ...DATOS_P,
    grupos_mapa: { ...DATOS.grupos_mapa, urbanizacion: ['DEG1', 'DEG2', 'DEG3'] },
    pobreza: { ...DATOS_P.pobreza, trienio: [{ geo: 'ES30', v: 235, n: 21000, hogares: 8500, fiabilidad: 'normal' }] },
    vistas: [...DATOS_P.vistas,
      { clave: 'urbanizacion-DEG1-2025', corte: 'urbanizacion', grupo: 'DEG1', anio: 2025, nuts: '2024',
        filas: [fila('AT', 1, 110, 'europa', { nivel: 0, tabla: 'ilc_lvho07d' }), fila('ES30', 2, 104, 'comunidad', { fiabilidad: 'baja' })] }],
  };
  assert.ok(S.CORTES.includes('urbanizacion'));
  const e = S.leerEstado('?corte=urbanizacion&grupo=DEG1&geo=ES30', d);
  assert.deepEqual(e, { idioma: 'es', medida: 'sobrecarga', corte: 'urbanizacion', grupo: 'DEG1', anio: 2025, geo: 'ES30' });
  assert.equal(S.consulta(e, d), '?corte=urbanizacion&grupo=DEG1&geo=ES30');
  assert.deepEqual(S.gruposCon(d, 'urbanizacion'), ['DEG1']);                 // solo los grupos con vista
  assert.deepEqual(S.gruposCon(d, 'urbanizacion', 'pobreza'), []);             // la pobreza no lo trae en el mapa
  assert.equal(S.leerEstado('?medida=pobreza&corte=urbanizacion&grupo=DEG1', d).corte, 'total');
  assert.deepEqual(S.conMuestraPequena(S.vistaDe(d, { corte: 'urbanizacion', grupo: 'DEG1' })), ['ES30']);
  assert.equal(S.valorDe(S.trienioDe(d, 'ES30')), 23.5);
  assert.equal(S.trienioDe(d, 'ES61'), null);
  assert.equal(S.trienioDe(DATOS, 'ES30'), null);
  // Textos en los dos idiomas, con las mismas marcas; la página y sobrecarga.js los usan
  const marcas = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort();
  const de = (o, k) => k.split('.').reduce((x, p) => x?.[p], o);
  const claves = ['controles.urbanizacion', 'controles.todos_grados', 'controles.grupos.DEG1', 'controles.grupos.DEG2',
    'controles.grupos.DEG3', 'detalle.trienio', 'comunidades.valor_anio', 'comunidades.valor_trienio', 'comunidades.personas_trienio', 'comunidades.nota_trienio'];
  const es = leer('web', 'i18n', 'es.json').sobrecarga;
  const en = leer('web', 'i18n', 'en.json').sobrecarga;
  for (const k of claves) {
    assert.ok(de(es, k)?.length && de(en, k)?.length, k);
    assert.deepEqual(marcas(de(es, k)), marcas(de(en, k)), k);
  }
  assert.deepEqual(marcas(es.detalle.trienio), ['desde', 'fiabilidad', 'hasta', 'n', 'v']);
  for (const texto of [es.controles.nota_desglose, es.mapa.nota_paises]) assert.match(texto, /grado de urbanización/);
  for (const texto of [en.controles.nota_desglose, en.mapa.nota_paises]) assert.match(texto, /degree of urbanisation/);
  const js = readFileSync(join(raiz, 'web', 'js', 'sobrecarga.js'), 'utf8');
  for (const k of ['controles.todos_grados', 'detalle.trienio', 'comunidades.valor_anio', 'comunidades.valor_trienio', 'comunidades.personas_trienio', 'comunidades.nota_trienio']) {
    assert.ok(js.includes(`'sobrecarga.${k}'`), `sobrecarga.js usa ${k}`);
  }
  const html = readFileSync(join(raiz, 'web', 'sobrecarga.html'), 'utf8');
  assert.match(html, /id="sc-urbanizacion-grupo"[^>]*>\s*<legend data-i18n="sobrecarga\.controles\.urbanizacion"/);
  assert.match(html, /id="sc-comunidades-nota" class="nota" hidden/);
});

test('consulta: solo lo que no vale por defecto', () => {
  assert.equal(S.consulta({ idioma: 'es', corte: 'total', grupo: 'total', anio: 2025, geo: null }, DATOS), '');
  assert.equal(S.consulta({ idioma: 'en', corte: 'total', grupo: 'total', anio: 2024, geo: 'EL51' }, DATOS), '?idioma=en&anio=2024&geo=EL51');
  assert.equal(S.consulta({ idioma: 'es', corte: 'edad', grupo: 'Y_LT18', anio: 2025, geo: null }, DATOS), '?corte=edad&grupo=Y_LT18');
});

test('vistas: el total por año, los desgloses en su año, y solo los grupos con vista', () => {
  assert.equal(S.vistaDe(DATOS, { anio: 2024 }).clave, 'total-2024');
  assert.equal(S.vistaDe(DATOS, {}).clave, 'total-2025');
  assert.equal(S.vistaDe(DATOS, { corte: 'tenencia', grupo: 'RENT_MKT', anio: 2024 }).clave, 'tenencia-RENT_MKT-2025');
  assert.deepEqual(S.gruposCon(DATOS, 'tenencia'), ['RENT_MKT']);
  const v = S.vistaDe(DATOS, {});
  assert.deepEqual(S.pintables(v).map((f) => f.geo), ['EL51', 'AT', 'NL1', 'ES30', 'ES64', 'ES63']);
  assert.deepEqual(S.conTramaGruesa(v), ['AT', 'NL1']);
  assert.deepEqual(S.conTramaGruesa(S.vistaDe(DATOS, { corte: 'tenencia', grupo: 'RENT_MKT' })), []);
  assert.deepEqual(S.conMuestraPequena(v), ['ES63']);
  assert.equal(S.puestos(v), 7);
  assert.equal(S.valorDe(S.referencia(v, 'ES')), 7.2);
  assert.equal(S.valorDe(S.referencia(v, 'ES64')), null);
});

test('tramos: menos del primer corte es el 0; sin valor, null; los cortes del alquiler de mercado', () => {
  const c = S.cortesDe(DATOS, 'total');
  assert.deepEqual([3.9, 4, 7.2, 14.9, 15, 33.9].map((x) => S.tramoDe(x, c)), [0, 1, 2, 4, 5, 5]);
  assert.equal(S.tramoDe(null, c), null);
  assert.deepEqual(S.cortesDe(DATOS, 'RENT_MKT'), [15, 20, 25, 30, 40]);
  const etiquetas = S.etiquetasTramos([4, 6, 8.5], (clave, v) => `${clave.split('.').at(-1)} ${Object.values(v).join('-')}`, t.numero);
  assert.deepEqual(etiquetas, ['menos_de 4', 'entre 4-6', 'entre 6-8,5', 'o_mas 8,5']);
});

test('escalera: tres bloques con el puesto de la lista completa; sin valor, al final', () => {
  const v = S.vistaDe(DATOS, {});
  const b = S.bloquesEscalera(v, 2);
  assert.deepEqual(b.europa.map((f) => f.geo), ['EL51', 'AT']);
  assert.deepEqual(b.referencias.map((f) => f.geo), ['EU27_2020', 'ES']);
  assert.deepEqual(b.comunidades.map((f) => f.geo), ['ES30', 'ES63', 'ES64']);
  assert.equal(b.total, 7);
  assert.equal(S.escaleraCompleta(v).at(-1).geo, 'ES64');
  assert.deepEqual(['ES30', 'EU27_2020', 'AT', 'EL51'].map((g) => S.tipoDe(v.filas.find((f) => f.geo === g))),
    ['comunidad', 'referencia', 'pais', 'region']);
});

test('nombres: comunidades en orden natural, países y UE-27 del diccionario, regiones con su país', () => {
  const natural = (x) => x.replace(/^(.*), (.*)$/, '$2 $1');
  assert.equal(S.nombreDe('ES30', DATOS, t, natural), 'Comunidad de Madrid');
  assert.equal(S.nombreDe('AT', DATOS, t), 'Austria');
  assert.equal(S.nombreDe('EU27_2020', DATOS, t), 'UE-27');
  assert.equal(S.nombreDe('EL51', DATOS, t), 'Anatoliki Makedonia, Thraki (Grecia)');
  assert.equal(S.nombreDe('EL51', DATOS, t, undefined, { conPais: false }), 'Anatoliki Makedonia, Thraki');
  assert.equal(S.nombreDe('EL99', DATOS, t), 'Grecia (EL99)');
  assert.equal(S.porcentaje(7.2, t), '7,2 %');
  assert.equal(S.porcentaje(null, t), '—');
});

test('marcas de Eurostat: letras, poca fiabilidad, rupturas y tramos de estimaciones', () => {
  assert.deepEqual(S.marcasDe('bu'), ['b', 'u']);
  assert.deepEqual(S.marcasDe(null), []);
  assert.ok(S.pocoFiable({ bandera: 'u' }) && S.pocoFiable({ fiabilidad: 'baja' }));
  assert.ok(!S.pocoFiable({ bandera: 'b', fiabilidad: 'normal' }));
  const anios = [2008, 2009, 2010, 2011, 2012, 2013];
  const marcas = ['b', null, 'e', 'e', null, 'be'];
  assert.deepEqual(S.rupturasDe(anios, marcas), [2008, 2013]);
  assert.deepEqual(S.rupturasDe(anios), []);
  // Con las rupturas del atlas (2013 ya marcada por Eurostat aquí: no se repite) y sin ellas
  assert.deepEqual(S.rupturasSerie(anios, marcas, [2011, 2013, 2020]), [2008, 2011, 2013]);
  assert.deepEqual(S.rupturasSerie(anios, [], [2011]), [2011]);
  assert.deepEqual(S.rupturasSerie(anios, marcas, null), [2008, 2013]);
  assert.deepEqual(S.tramosConMarca(anios, marcas, 'e'), [[2010, 2011], [2013, 2013]]);
  const v = { corte: 'total', filas: [{ geo: 'PL41', bloque: 'europa', nivel: 2, bandera: 'u' }, { geo: 'ES30', bloque: 'comunidad', fiabilidad: 'normal' }] };
  assert.deepEqual(S.conMuestraPequena(v), ['PL41']);
});

test('serie: trazado con huecos, techo del eje y etiquetas que no se pisan', () => {
  const x = S.escalaLineal(2020, 2022, 0, 100);
  const y = S.escalaLineal(0, 10, 100, 0);
  assert.equal(S.trazado([2020, 2021, 2022], [5, null, 10], x, y), 'M0.0,50.0M100.0,0.0');
  assert.equal(S.trazado([2020, 2021], [5, 6], x, y), 'M0.0,50.0L50.0,40.0');
  // Una ruptura corta la línea: el año de la ruptura empieza un tramo nuevo
  assert.equal(S.trazado([2020, 2021, 2022], [5, 6, 7], x, y, [2021]), 'M0.0,50.0M50.0,40.0L100.0,30.0');
  assert.equal(S.techoEje([[7.2, 26.8], [null, 47.5]]), 50);
  assert.equal(S.techoEje([[null]]), 10);
  const ys = S.separarEtiquetas([100, 104, 30, 102], 14, 0, 110);
  assert.equal(ys[2], 30);
  const juntas = [ys[0], ys[1], ys[3]].sort((a, b) => a - b);
  assert.ok(juntas[1] - juntas[0] >= 14 && juntas[2] - juntas[1] >= 14);
  assert.ok(Math.max(...ys) <= 110);
});

const exportada = join(raiz, 'web', 'datos', 'sobrecarga', 'sobrecarga.json');
test('exportación del pipeline: vistas, escalera, muestra y geometrías', { skip: !existsSync(exportada) && 'sin exportar' }, () => {
  const d = leer('web', 'datos', 'sobrecarga', 'sobrecarga.json');
  assert.equal(d.escala, 10);
  for (const v of d.vistas) {
    // La escalera ordena lo que pinta el mapa: puestos 1…n de más a menos
    const conValor = v.filas.filter((f) => f.v !== null).sort((a, b) => a.puesto - b.puesto);
    if (v.corte !== 'total') {
      assert.deepEqual(conValor.map((f) => f.puesto), conValor.map((_, i) => i + 1), v.clave);
    }
    for (let i = 1; i < conValor.length; i++) assert.ok(conValor[i - 1].v >= conValor[i].v, `${v.clave}: orden`);
    for (const f of v.filas) {
      if (f.fuente === 'ine_ecv') {
        assert.ok(Number.isInteger(f.n) && Number.isInteger(f.hogares), `${v.clave} ${f.geo}: muestra`);
        assert.ok(['normal', 'baja', 'no publicable'].includes(f.fiabilidad), `${v.clave} ${f.geo}: fiabilidad`);
        if (f.fiabilidad === 'no publicable') assert.equal(f.v, null);
      } else {
        const tabla = v.medida !== 'pobreza' ? 'ilc_lvho07' : (v.corte === 'edad' ? 'ilc_li45' : 'ilc_li48');
        assert.ok(f.tabla?.startsWith(tabla), `${v.clave} ${f.geo}: tabla de Eurostat`);
        assert.equal(f.n, undefined);
      }
    }
    assert.ok(d.geometrias[v.nuts], `${v.clave}: geometría ${v.nuts}`);
    const comunidades = v.filas.filter((f) => f.bloque === 'comunidad');
    // Por grado de urbanización, una comunidad sin personas de ese grado (Ceuta y Melilla no tienen
    // zonas rurales) no tiene fila
    if (v.corte === 'urbanizacion') assert.ok(comunidades.length >= 15 && comunidades.length <= 19, `${v.clave}: comunidades`);
    else assert.equal(comunidades.length, 19, `${v.clave}: comunidades`);
    // Referencias: España siempre; la UE-27, salvo en la pobreza tras la vivienda por tenencia (Eurostat no la publica)
    assert.ok(S.referencia(v, 'ES'), `${v.clave}: España`);
    if (!(v.medida === 'pobreza' && v.corte === 'tenencia')) assert.ok(S.referencia(v, 'EU27_2020'), `${v.clave}: UE-27`);
  }
  // Nombres (revisión del 17-nov-2026: el Reino Unido de la pobreza de 2016–2018 salía «UK (UK)»): cada
  // territorio que no es una comunidad tiene nombre de país en los dos idiomas, o nombre propio y país
  for (const idioma of ['es', 'en']) {
    const paises = leer('web', 'i18n', `${idioma}.json`).sobrecarga.paises;
    const sinNombre = new Set();
    for (const v of d.vistas) {
      for (const { geo } of v.filas) {
        if (d.comunidades?.[geo] || paises[geo]) continue;
        if (!d.nombres?.[geo] || !paises[geo.slice(0, 2)]) sinNombre.add(`${v.clave} ${geo}`);
      }
    }
    assert.deepEqual([...sinNombre], [], `${idioma}: territorios sin nombre`);
  }
  for (const ruta of Object.values(d.geometrias)) {
    const g = leer('web', ruta);
    assert.equal(g.type, 'FeatureCollection');
    assert.ok(g.features.some((f) => f.properties.tipo === 'recuadro'), `${ruta}: recuadros`);
    const [o, s, e, n] = d.limites;
    for (const f of g.features.slice(0, 50)) {
      const c = JSON.stringify(f.geometry.coordinates).match(/-?\d+(\.\d+)?/g).map(Number);
      for (let i = 0; i < c.length; i += 2) assert.ok(c[i] >= o - 0.01 && c[i] <= e + 0.01 && c[i + 1] >= s - 0.01 && c[i + 1] <= n + 0.01);
    }
  }
  // Serie desde el primer año publicado, con una marca (o null) por año en cada serie
  const s = d.espana.serie;
  for (const clave of Object.keys(s.valores)) {
    assert.equal(s.valores[clave].length, s.anios.length, clave);
    assert.equal(s.marcas[clave].length, s.anios.length, `${clave}: marcas`);
  }
  const primero = Math.min(...Object.values(s.valores).map((v) => s.anios[v.findIndex((x) => x !== null)]));
  assert.equal(s.anios[0], primero);
  // Cortes del mapa: de 1 a 5 crecientes por grupo
  for (const [grupo, c] of Object.entries(d.cortes)) {
    assert.ok(c.length >= 1 && c.length <= 5 && c.every((x, i) => i === 0 || x > c[i - 1]), grupo);
  }
  // Quintiles de España: cinco por ola, con su muestra
  const quintiles = d.espana.anual.filter((f) => f.corte === 'quintil');
  assert.equal(quintiles.length, 5 * d.olas.anuales.length);
  assert.ok(quintiles.every((f) => Number.isInteger(f.n) && f.fiabilidad));
  assert.ok(d.modulo.ccaa.length === 19 && d.modulo.razones.some((r) => r.grupo === 'precio'));
  // Indicador 24 (tarea 65, parte B): vistas propias, bloque `pobreza` y España en total y por tenencia
  assert.equal(d.indicadores.pobreza_tras_vivienda, 24);
  assert.ok(d.vistas.every((v) => ['sobrecarga', 'pobreza'].includes(v.medida)));
  const p = d.pobreza;
  for (const a of p.anios) assert.ok(S.vistaDe(d, { medida: 'pobreza', anio: a }), `pobreza ${a}`);
  assert.deepEqual(S.gruposCon(d, 'tenencia', 'pobreza'), ['RENT_MKT', 'RENT_FR', 'OWN_L', 'OWN_NL']);
  // Por edad (18-nov-2026): los cuatro grupos de ilc_li45, con países de Eurostat y las 19 comunidades
  assert.deepEqual(S.gruposCon(d, 'edad', 'pobreza'), ['Y_LT18', 'Y18-64', 'Y_GE65', 'Y_GE18']);
  for (const g of S.gruposCon(d, 'edad', 'pobreza')) {
    const v = S.vistaDe(d, { medida: 'pobreza', corte: 'edad', grupo: g });
    assert.ok(v.filas.filter((f) => f.bloque === 'europa').length > 20, `pobreza edad ${g}: países`);
  }
  // Sobrecarga de España por grado de urbanización (18-nov-2026), cada ola
  assert.equal(d.espana.anual.filter((f) => f.corte === 'urbanizacion').length, 3 * d.olas.anuales.length);
  // Y en el mapa, con los países de ilc_lvho07d y las 19 comunidades del último trienio (18-nov-2026)
  assert.deepEqual(S.gruposCon(d, 'urbanizacion'), ['DEG1', 'DEG2', 'DEG3']);
  for (const g of S.gruposCon(d, 'urbanizacion')) {
    const v = S.vistaDe(d, { corte: 'urbanizacion', grupo: g });
    assert.ok(v.filas.filter((f) => f.bloque === 'europa').length > 20, `urbanización ${g}: países`);
    assert.ok(v.filas.filter((f) => f.bloque === 'europa').every((f) => f.tabla === 'ilc_lvho07d'), `urbanización ${g}: tabla`);
  }
  // Total de las 19 comunidades con el último trienio de la pobreza (18-nov-2026), con su muestra
  assert.equal(d.pobreza.trienio.length, 19);
  assert.ok(d.pobreza.trienio.every((f) => Number.isInteger(f.n) && f.fiabilidad && d.comunidades[f.geo]));
  assert.ok(p.umbrales.length === p.olas.anuales.length && p.umbrales.every((u) => u.euros > 5000 && u.euros < 20000));
  assert.equal(p.espana.filter((f) => f.corte === 'total').length, p.olas.anuales.length);
  const pt = S.vistaDe(d, { medida: 'pobreza' });
  assert.ok(pt.filas.filter((f) => f.bloque === 'europa').every((f) => f.nivel === 0), 'pobreza: países');
  assert.deepEqual(S.conTramaGruesa(pt), []);
  // Olas 2016–2025 (17-nov-2026): las del 24 en el mapa, todas con su vista; España por edad y
  // grado de urbanización cada ola; la serie de ilc_li48 de España y de la UE-27
  assert.ok(p.anios.length >= 10 && p.anios[0] <= 2016, 'pobreza: olas desde 2016');
  assert.ok(d.olas.anuales[0] <= 2016, 'sobrecarga: olas anuales desde 2016');
  for (const a of p.olas.anuales) {
    const f = S.filasDesgloses(d, 'pobreza', a);
    assert.deepEqual(S.cortesDesgloses(f), ['tenencia', 'edad', 'urbanizacion'], `pobreza ${a}`);
    assert.deepEqual(f.filter((x) => x.corte === 'edad').map((x) => x.grupo).sort(), ['Y18-64', 'Y_GE18', 'Y_GE65', 'Y_LT18']);
  }
  assert.equal(p.serie.fuente, 'eurostat_ilc_li48');
  assert.deepEqual(Object.keys(p.serie.valores).sort(), ['ES_TOTAL', 'EU27_TOTAL']);
  for (const k of Object.keys(p.serie.valores)) assert.equal(p.serie.valores[k].length, p.serie.anios.length, k);
  assert.ok(p.serie.anios[0] <= 2004 && p.serie.anios.at(-1) >= 2025);
});

test('«Puesto X de N»: debajo, en letra de nota, qué vale ese orden, en los dos idiomas', () => {
  // Decisión del autor (12-nov-2026), ajustada a cómo sale el puesto (R/web_sobrecarga.R): sin
  // márgenes de error; con toda la población, un mismo año de encuesta para todos; con tenencia o
  // edad, las comunidades con las olas agrupadas
  for (const idioma of ['es', 'en']) {
    const d = leer('web', 'i18n', `${idioma}.json`).sobrecarga.detalle;
    const marcas = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort();
    assert.deepEqual(marcas(d.puesto_nota), ['anio'], idioma);
    assert.deepEqual(marcas(d.puesto_nota_olas), ['anio', 'desde', 'hasta'], idioma);
  }
  const js = readFileSync(join(raiz, 'web', 'js', 'sobrecarga.js'), 'utf8');
  assert.match(js, /fila\.puesto \? el\('p', \{ class: 'nota sc-detalle-puesto-nota' \}, notaPuesto\(v\)\) : null/);
  assert.match(js, /'sobrecarga\.detalle\.puesto_nota'/);
  assert.match(js, /'sobrecarga\.detalle\.puesto_nota_olas'/);
});
