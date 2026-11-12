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

test('estado de la URL: valida corte, grupo, año y territorio contra los datos', () => {
  assert.deepEqual(S.leerEstado('?idioma=en'), { idioma: 'en', corte: 'total', grupo: 'total', anio: null, geo: null });
  assert.deepEqual(S.leerEstado('', DATOS), { idioma: 'es', corte: 'total', grupo: 'total', anio: 2025, geo: null });
  assert.equal(S.leerEstado('?anio=2024', DATOS).anio, 2024);
  assert.equal(S.leerEstado('?anio=1999', DATOS).anio, 2025);
  const desglose = S.leerEstado('?corte=tenencia&grupo=RENT_MKT&anio=2024&geo=ES30', DATOS);
  assert.deepEqual(desglose, { idioma: 'es', corte: 'tenencia', grupo: 'RENT_MKT', anio: 2025, geo: 'ES30' });
  // Grupo que no está en el mapa, o sin vista: toda la población
  assert.equal(S.leerEstado('?corte=tenencia&grupo=RENT_FR', DATOS).corte, 'total');
  assert.equal(S.leerEstado('?corte=tenencia&grupo=OWN_L', DATOS).corte, 'total');
  assert.equal(S.leerEstado('?geo=<script>', DATOS).geo, null);
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
        assert.ok(f.tabla?.startsWith('ilc_lvho07'), `${v.clave} ${f.geo}: tabla de Eurostat`);
        assert.equal(f.n, undefined);
      }
    }
    assert.ok(d.geometrias[v.nuts], `${v.clave}: geometría ${v.nuts}`);
    const comunidades = v.filas.filter((f) => f.bloque === 'comunidad');
    assert.equal(comunidades.length, 19, `${v.clave}: comunidades`);
    assert.ok(S.referencia(v, 'ES') && S.referencia(v, 'EU27_2020'), `${v.clave}: referencias`);
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
