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

test('serie: trazado con huecos, techo del eje y etiquetas que no se pisan', () => {
  const x = S.escalaLineal(2020, 2022, 0, 100);
  const y = S.escalaLineal(0, 10, 100, 0);
  assert.equal(S.trazado([2020, 2021, 2022], [5, null, 10], x, y), 'M0.0,50.0M100.0,0.0');
  assert.equal(S.trazado([2020, 2021], [5, 6], x, y), 'M0.0,50.0L50.0,40.0');
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
  assert.equal(d.espana.serie.anios.length, Object.values(d.espana.serie.valores)[0].length);
  assert.ok(d.modulo.ccaa.length === 19 && d.modulo.razones.some((r) => r.grupo === 'precio'));
});
