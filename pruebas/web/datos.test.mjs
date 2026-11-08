// Pruebas de la web sin navegador: formato de los valores (JSON de enteros), series de la
// ficha, fórmulas, «Tu sueldo», comparador, buscador y estado de la URL. Datos inventados; si
// el pipeline ya ha exportado web/datos/manifiesto.json, se comprueba también su contrato.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/datos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const { decodificar, periodoPara, rutaValores, codificacionDe } = await modulo('web/js/datos.js');
const { FORMULAS, formulaDe } = await modulo('web/js/formulas.js');
const sueldo = await modulo('web/js/sueldo.js');
const { codigoComparado } = await modulo('web/js/comparador.js');
const { buscar, formasDeNombre } = await modulo('web/js/buscador.js');
const { ordenNatural } = await modulo('web/js/nombres.js');
const { consulta } = await modulo('web/js/estado.js');

const CODIFICACION = { escala: 10, estados: ['dato', 'estimado', 'secreto', 'ausente'] };
const leer = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
const periodos = (def) => def.periodos ?? def.anios;

// --- Formato ---------------------------------------------------------------------------------

test('decodificar: valores × 10, nulos y estados', () => {
  const { valores, estados } = decodificar({ v: [253, -15, null, 0], e: '0123' }, 4, CODIFICACION);
  assert.deepEqual(valores, [25.3, -1.5, null, 0]);
  assert.deepEqual([...estados], [0, 1, 2, 3]);
  assert.deepEqual(decodificar({ v: [253], e: '0' }, 1, { ...CODIFICACION, escala: 100 }).valores, [2.53]);
});

test('decodificar: rechaza longitudes que no casan con el índice y estados desconocidos', () => {
  assert.throws(() => decodificar({ v: [1, 2, 3], e: '000' }, 4, CODIFICACION), /se esperaban 4/);
  assert.throws(() => decodificar({ v: [1, 2, 3, 4], e: '000' }, 4, CODIFICACION), /se esperaban 4/);
  assert.throws(() => decodificar({ v: [1], e: '4' }, 1, CODIFICACION), /Estado desconocido/);
  assert.throws(() => decodificar({ v: [1], e: 'x' }, 1, CODIFICACION), /Estado desconocido/);
  assert.throws(() => decodificar(null, 1, CODIFICACION), /se esperaban 1/);
});

test('periodos y rutas: el año pedido, o el último anterior, o el último', () => {
  assert.equal(periodoPara({ anios: [2020, 2021, 2024] }, 2022), 2021);
  assert.equal(periodoPara({ anios: [2021] }, 2024), 2021);
  assert.equal(periodoPara({ anios: [2023, 2024] }, 2019), 2024);
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11', '2025-05'] }, 2024), '2024-11');
  assert.equal(rutaValores({ ruta: 'datos/{nivel}/x/{anio}.json' }, 'sc', 2024), 'datos/sc/x/2024.json');
  assert.equal(rutaValores({ ruta: 'datos/{nivel}/x/{periodo}.json' }, 'sc', '2025-05'), 'datos/sc/x/2025-05.json');
  const m = { codificacion: CODIFICACION, indicadores: { a: {}, b: { escala: 100 } } };
  assert.equal(codificacionDe(m, 'a').escala, 10);
  assert.equal(codificacionDe(m, 'b').escala, 100);
});

test('sueldo necesario: alquiler por m² × superficie / umbral', () => {
  const s = { superficie_m2: 50, umbral: 0.3 };
  assert.equal(Math.round(FORMULAS.alquiler_m2_a_sueldo.calcular(24.8, s)), 4133);
  assert.deepEqual(FORMULAS.alquiler_m2_a_sueldo.expresion('v', s), ['/', ['*', 'v', 50], 0.3]);
  assert.equal(formulaDe({}).calcular(7), 7);
  assert.throws(() => formulaDe({ formula: 'eval' }), /desconocida/);
});

// --- «Tu sueldo» -----------------------------------------------------------------------------

const PERFILES = {
  llave: { ingreso: { serie: 'renta_hogar', divisor: 12 }, vivienda: { serie: 'alquiler_mes' } },
  mochila: { anio: 2024, nivel: 'provincia', neto_mensual: { 28: 1500, '08': 1400 }, superficie_m2: 50 },
  tartera: { anio: 2026, nivel: 'nacional', neto_mensual: { '00': 1300 }, superficie_m2: 50 },
};

test('Tu ficha: neto mensual repartido en 12, con 14 pagas y segundo sueldo', () => {
  assert.equal(sueldo.ingresoPeon({ neto: 1200, pagas: 12 }), 1200);
  assert.equal(sueldo.ingresoPeon({ neto: 1200, pagas: 14 }), 1400);
  assert.equal(sueldo.ingresoPeon({ neto: 1200, pagas: 12, segundo: 900 }), 2100);
  assert.equal(sueldo.ingresoPeon({ neto: 0 }), null);
  assert.equal(sueldo.ingresoPeon({ neto: 1e6 }), null);
  assert.equal(sueldo.ingresoPeon(null), null);
});

test('modo, superficie y umbral según la ficha (plan, §3.1)', () => {
  const s1 = { neto: 1500, pagas: 12 };
  const s2 = { neto: 1500, pagas: 12, segundo: 1000 };
  assert.equal(sueldo.modoDe({}, null, PERFILES), 'necesario');
  assert.equal(sueldo.modoDe({ ficha: 'peon' }, null, PERFILES), 'necesario');
  assert.equal(sueldo.modoDe({ ficha: 'peon' }, s1, PERFILES), 'llega');
  assert.equal(sueldo.modoDe({ ficha: 'transistor' }, null, PERFILES), 'necesario');   // sin datos todavía
  assert.equal(sueldo.superficieDe({ ficha: 'peon' }, s1, PERFILES), 50);
  assert.equal(sueldo.superficieDe({ ficha: 'peon' }, s2, PERFILES), 70);
  assert.equal(sueldo.superficieDe({ ficha: 'peon', superficie: 90 }, s2, PERFILES), 90);
  assert.equal(sueldo.superficieDe({ ficha: 'mochila', superficie: 90 }, null, PERFILES), 50);
  assert.equal(sueldo.superficieDe({ ficha: 'llave' }, null, PERFILES), null);
  assert.equal(sueldo.superficieDe({ superficie: 70 }, null, PERFILES), 70);
  assert.equal(sueldo.umbralDe({}), 0.3);
  assert.equal(sueldo.umbralDe({ umbral: 40 }), 0.4);
  assert.equal(sueldo.umbralDe({ umbral: 35 }), 0.3);
});

test('¿te llega?: alquiler sobre ingreso para cada ficha', () => {
  const x = (valores) => (serie) => valores[serie] ?? null;
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: PERFILES, sueldo: { neto: 1500, pagas: 12 }, superficie: 50 });
  assert.deepEqual(peon.series, ['alquiler_m2']);
  assert.equal(peon.calcular('2807901001', x({ alquiler_m2: 9 })).ratio, 0.3);
  assert.equal(peon.calcular('2807901001', x({})), null);

  const mochila = sueldo.calculoLlega({ ficha: 'mochila', perfiles: PERFILES, superficie: 50 });
  assert.equal(mochila.calcular('2807901001', x({ alquiler_m2: 12 })).ingreso, 1500);
  assert.equal(mochila.calcular('0801901001', x({ alquiler_m2: 12 })).ingreso, 1400);
  assert.equal(mochila.calcular('4802001001', x({ alquiler_m2: 12 })), null);   // provincia sin dato
  const { ratio } = mochila.expresion('seccion');
  assert.deepEqual(ratio[2][0], 'match');
  assert.ok(ratio[2].includes('28') && ratio[2].includes(1500));

  const tartera = sueldo.calculoLlega({ ficha: 'tartera', perfiles: PERFILES, superficie: 50 });
  assert.equal(tartera.calcular('4802001001', x({ alquiler_m2: 7.8 })).ratio, 0.3);

  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles: PERFILES, superficie: null });
  assert.deepEqual(llave.series, ['alquiler_mes', 'renta_hogar']);
  const r = llave.calcular('2807901001', x({ alquiler_mes: 900, renta_hogar: 36000 }));
  assert.equal(r.ingreso, 3000);
  assert.equal(r.ratio, 0.3);
  assert.equal(llave.calcular('2807901001', x({ alquiler_mes: 900, renta_hogar: 0 })), null);
});

test('tramos, resumen y regla de la leyenda', () => {
  assert.deepEqual([0.1, 0.3, 0.31, 0.4, 0.41].map(sueldo.tramoLlega), [0, 0, 1, 1, 2]);
  const secciones = ['2807901001', '2807901002', '2807901003', '2807901004'];
  const m2 = [6, 9, 12, null];
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: PERFILES, sueldo: { neto: 1500 }, superficie: 50 });
  const r = sueldo.resumenLlega(peon, secciones, (serie, i) => m2[i], 0.3);
  assert.deepEqual(r, { con: 3, caben: 2, proporcion: 2 / 3 });

  const cortes = [700, 900, 1100, 1500];
  assert.equal(sueldo.posicionEnRegla(0, cortes), 0);
  assert.equal(sueldo.posicionEnRegla(700, cortes), 0.2);
  assert.equal(sueldo.posicionEnRegla(1000, cortes), 0.5);
  assert.equal(sueldo.posicionEnRegla(1300, cortes), 0.7);
  assert.equal(sueldo.posicionEnRegla(1e6, cortes), 1);
  assert.equal(sueldo.cuantil([4, null, 1, 3, 2], 0.5), 2.5);
  assert.equal(sueldo.cuantil([null], 0.5), null);

  const { marcas, llave } = sueldo.marcasRegla({ perfiles: PERFILES, seccion: '0801901001', rentaHogar: [24000, 36000, null, 48000] });
  assert.deepEqual(marcas, [{ ficha: 'mochila', valor: 1400, mediana: false }, { ficha: 'tartera', valor: 1300, mediana: false }]);
  assert.deepEqual(llave, { desde: 2500, hasta: 3500 });
  assert.equal(sueldo.marcasRegla({ perfiles: PERFILES, seccion: null }).marcas[0].mediana, true);
});

test('colores: cinco tramos en el sueldo necesario; tres en «¿te llega?», sin dato aparte', () => {
  const paleta = { rampa: ['r1', 'r2', 'r3', 'r4', 'r5'], llega: ['l1', 'l2', 'l3'], fuera: 'f' };
  const necesario = sueldo.colorNecesario({ base: 'alquiler_m2', formula: 'alquiler_m2_a_sueldo', cortes: [1, 2, 3, 4] },
    { superficie_m2: 50, umbral: 0.3 }, paleta);
  assert.equal(necesario[0], 'case');
  assert.deepEqual(necesario[3].slice(2), ['r1', 1, 'r2', 2, 'r3', 3, 'r4', 4, 'r5']);
  const llega = sueldo.colorLlega(sueldo.calculoLlega({ ficha: 'tartera', perfiles: PERFILES, superficie: 50 }), 'seccion', paleta);
  assert.deepEqual(llega.filter((x) => typeof x === 'string' && x !== 'case'), ['f', 'l1', 'l2', 'l3']);
});

// --- Comparador, buscador y URL ----------------------------------------------------------------

test('comparador: territorio con el que se compara una sección', () => {
  const territorios = { ccaa_de_provincia: { 28: '13' } };
  assert.deepEqual(codigoComparado('2807901001', 'distrito', territorios), { nivel: 'distrito', codigo: '2807901' });
  assert.deepEqual(codigoComparado('2807901001', 'municipio', territorios), { nivel: 'municipio', codigo: '28079' });
  assert.deepEqual(codigoComparado('2807901001', 'ccaa', territorios), { nivel: 'ccaa', codigo: '13' });
  assert.deepEqual(codigoComparado('2807901001', 'nacional', territorios), { nivel: 'nacional', codigo: '00' });
  assert.deepEqual(codigoComparado('2807901001', '0801901001', territorios), { nivel: 'sc', codigo: '0801901001' });
  assert.equal(codigoComparado('0801901001', 'ccaa', territorios), null);
});

test('nombres del INE en orden natural', () => {
  assert.equal(ordenNatural('Coruña, A'), 'A Coruña');
  assert.equal(ordenNatural('Madrid, Comunidad de'), 'Comunidad de Madrid');
  assert.equal(ordenNatural('Balears, Illes'), 'Illes Balears');
  assert.equal(ordenNatural("Hospitalet de Llobregat, L'"), "L'Hospitalet de Llobregat");
  assert.equal(ordenNatural('Alacant/Alicante'), 'Alacant/Alicante');
  assert.equal(ordenNatural(undefined), undefined);
});

test('buscador: nombres sin tildes, con el artículo delante y códigos', () => {
  assert.deepEqual(formasDeNombre('Palmas de Gran Canaria, Las'), ['palmas de gran canaria, las', 'las palmas de gran canaria']);
  assert.deepEqual(formasDeNombre("Hospitalet de Llobregat, L'"), ["hospitalet de llobregat, l'", "l'hospitalet de llobregat"]);
  const municipios = [['28079', 'Madrid'], ['35016', 'Palmas de Gran Canaria, Las'], ['28006', 'Alcobendas'], ['01059', 'Vitoria-Gasteiz']]
    .map(([c, n]) => [c, n, formasDeNombre(n)]);
  const fuentes = { municipios, secciones: ['2807901001', '2807901002', '3501601001'] };
  assert.deepEqual(buscar('las palmas', fuentes).map((o) => o.codigo), ['35016']);
  assert.deepEqual(buscar('MADRID', fuentes).map((o) => o.codigo), ['28079']);
  assert.deepEqual(buscar('gasteiz', fuentes).map((o) => o.codigo), ['01059']);   // contiene
  assert.deepEqual(buscar('280', fuentes).map((o) => o.codigo), ['28079', '28006']);
  assert.deepEqual(buscar('2807901', fuentes).map((o) => [o.tipo, o.codigo]), [['seccion', '2807901001'], ['seccion', '2807901002']]);
  assert.deepEqual(buscar('m', fuentes), []);
});

test('URL: solo las claves válidas y nunca el sueldo', () => {
  const q = consulta({ idioma: 'en', ficha: 'peon', superficie: 70, umbral: 40, seccion: '2807901001', comparar: 'distrito', sueldo: 1500, neto: 1500, anio: 2024 });
  assert.equal(q, '?idioma=en&anio=2024&ficha=peon&superficie=70&umbral=40&seccion=2807901001&comparar=distrito');
  assert.equal(consulta({ idioma: 'fr', seccion: '123', umbral: 35, comparar: 'barrio' }), '');
});

// --- Muestra y exportación del pipeline -------------------------------------------------------

function comprobarManifiesto(dir, { completo }) {
  const m = leer(dir, 'manifiesto.json');
  const indices = {};
  for (const [nivel, ruta] of Object.entries(m.indices)) {
    indices[nivel] = leer('web', ruta);
    assert.ok(indices[nivel].length > 0, `índice vacío: ${nivel}`);
  }
  assert.ok(indices.sc.every((c) => /^\d{10}$/.test(c)), 'códigos de sección de 10 dígitos');
  for (const [serie, def] of Object.entries(m.indicadores)) {
    const ps = periodos(def);
    assert.ok(ps?.length, `${serie}: sin periodos`);
    // En la muestra, todos los ficheros; en la exportación, el último periodo de cada nivel.
    for (const nivel of def.niveles) {
      for (const p of completo ? ps : [ps.at(-1)]) {
        const datos = leer('web', rutaValores(def, nivel, p));
        assert.ok(datos.v.every((x) => x === null || Number.isInteger(x)), `${serie} ${nivel} ${p}: enteros`);
        const { valores, estados } = decodificar(datos, indices[nivel].length, codificacionDe(m, serie));
        valores.forEach((v, i) => {
          const nombre = m.codificacion.estados[estados[i]];
          assert.equal(v === null, nombre === 'secreto' || nombre === 'ausente', `${serie} ${nivel} ${p} ${indices[nivel][i]}`);
        });
      }
    }
  }
  for (const def of Object.values(m.mapas)) {
    assert.ok(m.indicadores[def.base], `mapa sin serie base: ${def.base}`);
    assert.equal(def.cortes.length, 4, 'cinco tramos: cuatro cortes');
    formulaDe(def);
  }
  const perfiles = leer('web', m.perfiles);
  if (perfiles.llave) {
    assert.ok(m.indicadores[perfiles.llave.ingreso.serie] && m.indicadores[perfiles.llave.vivienda.serie], 'series de la llave');
  }
  for (const ficha of ['mochila', 'tartera', 'transistor'].filter((f) => perfiles[f])) {
    const p = perfiles[ficha];
    assert.ok(['nacional', 'provincia'].includes(p.nivel), `${ficha}: nivel`);
    assert.ok(Object.values(p.neto_mensual).every((x) => x > 0 && x < 10000), `${ficha}: neto mensual`);
  }
  const territorios = leer('web', m.territorios);
  assert.ok(Object.keys(territorios.ccaa_de_provincia).every((p) => territorios.ccaa[territorios.ccaa_de_provincia[p]]), 'provincia → comunidad');
  return { m, indices };
}

test('muestra: los valores que escribe R se leen enteros y los nulos son secreto o ausente', () => {
  const { m } = comprobarManifiesto(join('web', 'datos', 'ejemplo'), { completo: true });
  assert.equal(m.ejemplo, true);
});

test('muestra: las series de la ficha cuadran, año a año, con los valores del mapa', () => {
  const m = leer('web', 'datos', 'ejemplo', 'manifiesto.json');
  const secciones = leer('web', m.indices.sc);
  const fichas = new Map();
  for (const [serie, def] of Object.entries(m.indicadores)) {
    periodos(def).forEach((p, k) => {
      const mapa = decodificar(leer('web', rutaValores(def, 'sc', p)), secciones.length, m.codificacion);
      secciones.forEach((seccion, i) => {
        const municipio = seccion.slice(0, 5);
        if (!fichas.has(municipio)) fichas.set(municipio, leer('web', m.fichas.replace('{municipio}', municipio)));
        const fichero = fichas.get(municipio);
        assert.deepEqual(fichero.anios[serie], periodos(def), `${municipio}: periodos de ${serie}`);
        const s = decodificar(fichero.series[seccion][serie], periodos(def).length, m.codificacion);
        assert.equal(s.valores[k], mapa.valores[i], `${seccion} ${serie} ${p}: valor`);
        assert.equal(s.estados[k], mapa.estados[i], `${seccion} ${serie} ${p}: estado`);
      });
    });
  }
});

const exportada = existsSync(join(raiz, 'web', 'datos', 'manifiesto.json'));
test('exportación del pipeline: el contrato de web/datos/ se cumple', { skip: !exportada && 'sin web/datos/manifiesto.json' }, () => {
  const { m, indices } = comprobarManifiesto(join('web', 'datos'), { completo: false });
  assert.equal(m.ejemplo, false);
  // Una ficha de municipio: sus secciones y periodos cuadran con el índice y el manifiesto.
  const municipio = indices.sc[0].slice(0, 5);
  const fichero = leer('web', m.fichas.replace('{municipio}', municipio));
  const propias = indices.sc.filter((c) => c.startsWith(municipio));
  assert.deepEqual(Object.keys(fichero.series).sort(), propias.sort());
  for (const [serie, ps] of Object.entries(fichero.anios)) {
    assert.deepEqual(ps, periodos(m.indicadores[serie]), `${municipio}: periodos de ${serie}`);
    decodificar(fichero.series[propias[0]][serie], ps.length, codificacionDe(m, serie));
  }
});
