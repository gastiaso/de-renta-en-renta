// Pruebas de la web sin navegador: formato de los valores (JSON de enteros), series de la
// ficha, fórmulas, «Tu sueldo», tipología, comparador, buscador, estado de la URL, descargas y suelo
// sin sección.
// Datos inventados; si el pipeline ya ha exportado web/datos/manifiesto.json, se comprueban
// también su contrato y que la página recalcula el sueldo necesario igual que R (plan, §6.5).
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/datos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const {
  decodificar, periodoPara, rutaValores, codificacionDe, serieDeTipologia, tieneTipologia, tipologiaDe,
  fueraDeSerie, inicioSerie, atributosSinSeccion, elegirSinSeccion,
} = await modulo('web/js/datos.js');
const { provinciasSinSeccion } = await modulo('web/js/ficha.js');
const exportar = await modulo('web/js/exportar.js');
const { FORMULAS, formulaDe, daSueldo, minimoDe, textoSupuestos } = await modulo('web/js/formulas.js');
const sueldo = await modulo('web/js/sueldo.js');
const { codigoComparado, filasComparador } = await modulo('web/js/comparador.js');
const { buscar, formasDeNombre } = await modulo('web/js/buscador.js');
const { ordenNatural } = await modulo('web/js/nombres.js');
const { consulta, leerEstado } = await modulo('web/js/estado.js');
const colores = await modulo('web/js/colores.js');
const fiabilidad = await modulo('web/js/fiabilidad.js');

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

test('periodos y rutas: el año pedido o el último anterior; antes de la serie, ninguno', () => {
  assert.equal(periodoPara({ anios: [2020, 2021, 2024] }, 2022), 2021);
  assert.equal(periodoPara({ anios: [2021] }, 2024), 2021);
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11', '2025-05'] }, 2024), '2024-11');
  // Año anterior a toda la serie (pregunta abierta 32): sin periodo, y desde cuándo hay serie
  assert.equal(periodoPara({ anios: [2023, 2024] }, 2019), null);
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11'] }, 2023), null);
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11'] }, '2024-01'), null);
  assert.equal(periodoPara({ anios: [2023, 2024] }, '2023-03'), 2023);   // serie anual: cuenta el año
  assert.deepEqual(fueraDeSerie({ periodos: ['2024-02', '2024-11'] }, 2020), { anio: 2020, desde: '2024-02' });
  assert.equal(fueraDeSerie({ periodos: ['2024-02', '2024-11'] }, 2024), null);
  assert.equal(fueraDeSerie({ anios: [2021] }, 2024), null);           // después de la serie: su último año
  assert.equal(fueraDeSerie({ anios: [2021] }, undefined), null);
  assert.equal(inicioSerie({ anios: [2015, 2024] }), 2015);
  // Periodos con mes elegidos en la barra: el mismo, o el último anterior; en series anuales, su año
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11', '2025-05'] }, '2024-11'), '2024-11');
  assert.equal(periodoPara({ periodos: ['2024-02', '2024-11', '2025-05'] }, '2025-01'), '2024-11');
  assert.equal(periodoPara({ anios: [2023, 2024] }, '2024-08'), 2024);
  assert.equal(periodoPara({ anios: [2023, 2024] }, '2025-05'), 2024);
  // Sin año elegido, el último periodo de cada serie
  assert.equal(periodoPara({ anios: [2023, 2024] }, undefined), 2024);
  assert.equal(periodoPara({ periodos: ['2024-02', '2025-05'] }, null), '2025-05');
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

test('sueldo necesario con dos cifras (tarea 40): alquiler mensual real / umbral y, al lado, el mínimo de la superficie elegida', () => {
  const s = { superficie_m2: 50, umbral: 0.3 };
  assert.equal(FORMULAS.alquiler_mes_a_sueldo.calcular(570, s), 1900);
  assert.equal(FORMULAS.alquiler_mes_a_sueldo.calcular(570, { superficie_m2: 90, umbral: 0.4 }), 1425);   // sin superficie
  assert.deepEqual(FORMULAS.alquiler_mes_a_sueldo.expresion('v', s), ['/', 'v', 0.3]);
  const def = { base: 'alquiler_mes', formula: 'alquiler_mes_a_sueldo', minimo: { base: 'alquiler_m2', formula: 'alquiler_m2_a_sueldo' } };
  assert.ok(daSueldo(def) && daSueldo({ formula: 'alquiler_m2_a_sueldo' }) && !daSueldo({ formula: 'directo' }) && !daSueldo(null));
  const x = (valores) => (serie) => valores[serie] ?? null;
  assert.equal(Math.round(minimoDe(def, x({ alquiler_m2: 7.3 }), s)), 1217);
  assert.equal(Math.round(minimoDe(def, x({ alquiler_m2: 7.3 }), { superficie_m2: 70, umbral: 0.3 })), 1703);
  assert.equal(minimoDe(def, x({ alquiler_m2_vu: 9 }), s, (b) => `${b}_vu`), 1500);   // la serie de la tipología elegida
  assert.equal(minimoDe(def, x({}), s), null);
  assert.equal(minimoDe({ base: 'alquiler_m2', formula: 'directo' }, x({ alquiler_m2: 7 }), s), null);
  // Supuestos: con el mínimo al lado, el alquiler real y el umbral; si no, la superficie y el umbral
  const tt = Object.assign((clave) => clave.split('.').at(-1), { porcentaje: (p) => `${p * 100} %`, numero: (n) => String(n) });
  assert.equal(textoSupuestos(tt, def, s), 'supuestos_real');
  assert.equal(textoSupuestos(tt, { formula: 'alquiler_m2_a_sueldo' }, s), 'supuestos');
  assert.equal(textoSupuestos(tt, { formula: 'directo' }, s), null);
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
  // Tarea 40: al lado, la proporción con el alquiler mensual real; el mapa sigue con 50 m² (regla 8)
  assert.equal(tartera.serieReal, 'alquiler_mes');
  assert.deepEqual(tartera.series, ['alquiler_m2']);
  const conReal = tartera.calcular('4802001001', x({ alquiler_m2: 7.8, alquiler_mes: 650 }));
  assert.equal(conReal.ratio, 0.3);
  assert.deepEqual(conReal.real, { alquiler: 650, ratio: 0.5 });
  assert.equal(tartera.calcular('4802001001', x({ alquiler_m2: 7.8 })).real, undefined);
  const secciones = ['4802001001', '4802001002', '4802001003'];
  const valores = [{ alquiler_m2: 7.8, alquiler_mes: 650 }, { alquiler_m2: 6, alquiler_mes: 390 }, { alquiler_m2: 6 }];
  assert.deepEqual(sueldo.resumenLlegaReal(tartera, secciones, (s, i) => valores[i][s] ?? null, 0.3), { con: 2, caben: 1, proporcion: 0.5 });

  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles: PERFILES, superficie: null });
  assert.equal(sueldo.resumenLlegaReal(llave, secciones, () => 1, 0.3), null);   // la llave ya paga el alquiler real
  assert.deepEqual(llave.series, ['alquiler_mes', 'renta_hogar']);
  const r = llave.calcular('2807901001', x({ alquiler_mes: 900, renta_hogar: 36000 }));
  assert.equal(r.ingreso, 3000);
  assert.equal(r.ratio, 0.3);
  assert.equal(llave.calcular('2807901001', x({ alquiler_mes: 900, renta_hogar: 0 })), null);
});

test('ingreso de la ficha del año del alquiler (regla 4): la tartera de cada año; sin ese año, el último', () => {
  const P = {
    ...PERFILES,
    tartera: { ...PERFILES.tartera, anios: { 2015: { '00': 708.6 }, 2024: { '00': 1237.4 }, 2026: { '00': 1300 } } },
  };
  const t15 = sueldo.perfilDelAnio(P.tartera, 2015);
  assert.equal(t15.anio, 2015);
  assert.deepEqual(t15.neto_mensual, { '00': 708.6 });
  assert.equal(sueldo.perfilDelAnio(P.tartera, 2019), P.tartera);   // sin ese año: el último, con aviso
  assert.equal(sueldo.perfilDelAnio(P.tartera, null), P.tartera);
  assert.equal(sueldo.perfilDelAnio(P.mochila, 2015), P.mochila);   // sin `anios`
  const a = sueldo.perfilesDelAnio(P, '2024');
  assert.equal(a.llave, P.llave);
  assert.equal(a.tartera.anio, 2024);
  const tartera = sueldo.calculoLlega({ ficha: 'tartera', perfiles: a, superficie: 50 });
  assert.equal(tartera.calcular('4802001001', (s) => (s === 'alquiler_m2' ? 10 : null)).ingreso, 1237.4);
  assert.equal(sueldo.marcasRegla({ perfiles: a, seccion: null }).marcas.find((k) => k.ficha === 'tartera').valor, 1237.4);
});

// --- Tipología de la vivienda (decisión 12) ----------------------------------------------------

const M_TIPOLOGIA = {
  indicadores: {
    alquiler_m2: { variantes: { VU: 'alquiler_m2_vu' } },
    alquiler_m2_vu: { por_defecto: 'alquiler_m2' },
    alquiler_mes: { variantes: { VU: 'alquiler_mes_vu' } },
    alquiler_mes_vu: { por_defecto: 'alquiler_mes' },
    renta_hogar: {},
  },
};

test('tipología: colectiva por defecto, unifamiliar con su variante, sin mezclar', () => {
  const m = M_TIPOLOGIA;
  assert.equal(serieDeTipologia(m, 'alquiler_m2', undefined), 'alquiler_m2');
  assert.equal(serieDeTipologia(m, 'alquiler_m2', 'VC'), 'alquiler_m2');
  assert.equal(serieDeTipologia(m, 'alquiler_m2', 'VU'), 'alquiler_m2_vu');
  assert.equal(serieDeTipologia(m, 'alquiler_m2_vu', 'VC'), 'alquiler_m2');   // de la variante, a la de por defecto
  assert.equal(serieDeTipologia(m, 'renta_hogar', 'VU'), 'renta_hogar');      // sin tipología, la misma
  assert.equal(tieneTipologia(m, 'alquiler_mes_vu'), true);
  assert.equal(tieneTipologia(m, 'renta_hogar'), false);
  assert.deepEqual(['alquiler_m2', 'alquiler_m2_vu', 'renta_hogar'].map((s) => tipologiaDe(m, s)), ['VC', 'VU', null]);
});

test('tipología en «¿te llega?»: el alquiler de la vivienda elegida, también en el mapa', () => {
  const vu = (s) => serieDeTipologia(M_TIPOLOGIA, s, 'VU');
  const x = (valores) => (serie) => valores[serie] ?? null;
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: PERFILES, sueldo: { neto: 1500, pagas: 12 }, superficie: 50, serie: vu });
  assert.deepEqual(peon.series, ['alquiler_m2_vu']);
  assert.equal(peon.calcular('2807901001', x({ alquiler_m2: 9, alquiler_m2_vu: 12 })).ratio, 0.4);
  assert.equal(peon.calcular('2807901001', x({ alquiler_m2: 9 })), null);   // sin dato de la unifamiliar: sin dato
  assert.ok(JSON.stringify(peon.expresion('seccion')).includes('"alquiler_m2_vu"'));
  assert.ok(!JSON.stringify(peon.expresion('seccion')).includes('"alquiler_m2"'));
  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles: PERFILES, superficie: null, serie: vu });
  assert.deepEqual(llave.series, ['alquiler_mes_vu', 'renta_hogar']);
  assert.equal(llave.calcular('2807901001', x({ alquiler_mes_vu: 1200, renta_hogar: 36000 })).ratio, 0.4);
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

test('colores: siete tramos en el sueldo necesario; tres en «¿te llega?», sin dato aparte (tarea 51)', () => {
  const paleta = colores.paletaDe(['r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7'], 'f');
  assert.deepEqual(paleta.llega, ['r1', 'r4', 'r7']);
  const def = { base: 'alquiler_m2', formula: 'alquiler_m2_a_sueldo', cortes: [1, 2, 3, 4, 5, 6] };
  const necesario = sueldo.colorNecesario(def, { superficie_m2: 50, umbral: 0.3 }, paleta);
  assert.equal(necesario[0], 'case');
  assert.deepEqual(necesario[3].slice(2), ['r1', 1, 'r2', 2, 'r3', 3, 'r4', 4, 'r5', 5, 'r6', 6, 'r7']);
  // Un mapa de cinco tramos toma pasos repartidos de punta a punta
  const cinco = sueldo.colorNecesario({ ...def, cortes: [1, 2, 3, 4] }, { superficie_m2: 50, umbral: 0.3 }, paleta);
  assert.deepEqual(cinco[3].slice(2), ['r1', 1, 'r3', 2, 'r4', 3, 'r6', 4, 'r7']);
  assert.throws(() => sueldo.colorNecesario({ ...def, cortes: [1, 2, 3, 4, 5, 6, 7] }, {}, paleta), /7 pasos/);
  const llega = sueldo.colorLlega(sueldo.calculoLlega({ ficha: 'tartera', perfiles: PERFILES, superficie: 50 }), 'seccion', paleta);
  assert.deepEqual(llega.filter((x) => typeof x === 'string' && x !== 'case'), ['f', 'r1', 'r4', 'r7']);
});

test('juegos de cortes: cada escala pinta con el suyo (tarea 51)', () => {
  const def = {
    base: 'alquiler_m2', formula: 'alquiler_m2_a_sueldo', cortes: [1, 2, 3, 4, 5, 6],
    juegos: {
      seccion: { cortes: [1, 2, 3, 4, 5, 6], metodo: 'recalibrado', anio: 2024 },
      municipio: { cortes: [10, 20, 30, 40, 50, 60], metodo: 'anclado', anio: 2024 },
      provincia_ccaa: { cortes: [100, 200, 300, 400, 500, 600], metodo: 'anclado_septiles', anio: 2025 },
    },
  };
  assert.deepEqual(colores.juegoDe(def, 'sc'), { nombre: 'seccion', cortes: [1, 2, 3, 4, 5, 6], metodo: 'recalibrado', anio: 2024 });
  assert.equal(colores.juegoDe(def, 'municipio').cortes[0], 10);
  assert.equal(colores.juegoDe(def, 'provincia').nombre, 'provincia_ccaa');
  assert.equal(colores.juegoDe(def, 'ccaa').anio, 2025);
  assert.deepEqual(colores.juegoDe(def, 'distrito'), { nombre: null, cortes: def.cortes, metodo: null, anio: null });
  assert.deepEqual(colores.juegoDe({ cortes: [7] }, 'municipio').cortes, [7]);   // sin juegos, los cortes del mapa
  assert.ok(colores.cambiaConLaEscala(def));
  assert.ok(!colores.cambiaConLaEscala({ cortes: [1] }));
  assert.ok(colores.anclado(colores.juegoDe(def, 'municipio')) && colores.anclado(colores.juegoDe(def, 'ccaa')));
  assert.ok(!colores.anclado(colores.juegoDe(def, 'sc')));
  const paleta = colores.paletaDe(['r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7'], 'f');
  const supuestos = { superficie_m2: 50, umbral: 0.3 };
  assert.deepEqual(sueldo.colorNecesario(def, supuestos, paleta, 'municipio')[3].filter((x) => typeof x === 'number'), [10, 20, 30, 40, 50, 60]);
  assert.deepEqual(sueldo.colorNecesario(def, supuestos, paleta, 'ccaa')[3].filter((x) => typeof x === 'number'), [100, 200, 300, 400, 500, 600]);
  assert.deepEqual(sueldo.colorNecesario(def, supuestos, paleta)[3].filter((x) => typeof x === 'number'), [1, 2, 3, 4, 5, 6]);
});

test('colores: pasos de la rampa, contraste WCAG y contorno de las secciones', () => {
  assert.deepEqual(colores.pasosDeRampa(7, 7), [0, 1, 2, 3, 4, 5, 6]);
  assert.deepEqual(colores.pasosDeRampa(6, 7), [0, 1, 2, 4, 5, 6]);
  assert.deepEqual(colores.pasosDeRampa(5, 7), [0, 2, 3, 5, 6]);   // viviendas turísticas
  assert.deepEqual(colores.pasosDeRampa(3, 5), [0, 2, 4]);   // la rampa de cinco: pasos 1, 3 y 5, como antes
  assert.deepEqual(colores.clasesTramos(3, 7), ['tramo-1', 'tramo-4', 'tramo-7']);   // «¿te llega?»
  assert.throws(() => colores.pasosDeRampa(8, 7), /7 pasos/);
  assert.equal(colores.contraste('#000000', '#ffffff'), 21);
  assert.equal(colores.contraste('#777777', '#777777'), 1);
  // La rampa de tokens.json: tinta sobre los tres pasos claros (contraste ≥ 3:1), placa sobre los oscuros
  const tokens = leer('diseno', 'tokens.json');
  const rampa = tokens.rampa_secuencial.pasos.map((p) => p.hex);
  assert.equal(rampa.length, 7);
  rampa.forEach((hex, i) => assert.ok(Math.abs(colores.contraste(hex, tokens.colores.crema.hex) - tokens.rampa_secuencial.pasos[i].contraste_crema) <= 0.05, hex));
  const tinta = tokens.colores.tinta.hex;
  const placa = tokens.colores.placa.hex;
  const contorno = colores.paletaContorno(colores.paletaDe(rampa, '#cccccc'), tinta, placa);
  assert.deepEqual(contorno.rampa, [tinta, tinta, tinta, placa, placa, placa, placa]);
  assert.deepEqual(contorno.llega, [tinta, placa, placa]);
  assert.equal(contorno.fuera, tinta);
});

test('leyenda: los cortes, con los decimales que necesitan (dos decimales en el 19, pregunta 24)', () => {
  assert.equal(colores.decimalesDeCortes([0.5, 1, 2.5, 5], 2), 1);           // «0,5 · 1,0 · 2,5 · 5,0»
  assert.equal(colores.decimalesDeCortes([0.25, 1], 2), 2);
  assert.equal(colores.decimalesDeCortes([4, 5.5, 7, 9], 1), 1);             // como hasta ahora
  assert.equal(colores.decimalesDeCortes([20, 30, 40, 50], 1), 1);
  assert.equal(colores.decimalesDeCortes([700, 900, 1100, 1500, 2000], 0), 0);
  assert.equal(colores.decimalesDeCortes([0.5], 0), 0);                      // nunca más que el mapa
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

test('comparador: con un año anterior a la serie, sin dato y desde cuándo (pregunta 32)', async () => {
  const m = {
    codificacion: CODIFICACION,
    indicadores: {
      viviendas_turisticas: { niveles: ['sc', 'nacional'], periodos: ['2024-02', '2026-05'], ruta: 'datos/{nivel}/v/{periodo}.json', escala: 100, decimales: 2 },
    },
  };
  // Sin pedir ficheros: la serie no llega al año
  const filas = await filasComparador({ m, seccion: '2807901001', comparado: { nivel: 'nacional', codigo: '00' }, anio: 2020, supuestos: {} });
  assert.equal(filas.length, 1);
  assert.equal(filas[0].periodo, null);
  assert.equal(filas[0].desde, '2024-02');
  assert.equal(filas[0].decimales, 2);
  assert.deepEqual([filas[0].a, filas[0].b], [{ valor: null, estado: 3 }, { valor: null, estado: 3 }]);
});

test('suelo sin sección: atributos de la capa y provincias que lo rodean', () => {
  const sinNombre = { nombre: null, tipo: null };
  assert.deepEqual(atributosSinSeccion({ km2: 418.44, provincias: '31 50', nombre: 'Bardenas Reales', tipo: 'condominio' }),
    { km2: 418.44, provincias: ['31', '50'], nombre: 'Bardenas Reales', tipo: 'condominio' });
  assert.deepEqual(atributosSinSeccion({ km2: '0.25', provincias: '28' }), { km2: 0.25, provincias: ['28'], ...sinNombre });
  assert.deepEqual(atributosSinSeccion({}), { km2: null, provincias: [], ...sinNombre });
  assert.deepEqual(atributosSinSeccion({ km2: null, provincias: ' 01  x 20 ', nombre: '  ', tipo: 7 }),
    { km2: null, provincias: ['01', '20'], ...sinNombre });
  assert.deepEqual(atributosSinSeccion({ nombre: ' Comunidad de 09076 y 09290 ' }).nombre, 'Comunidad de 09076 y 09290');
  // Bajo el punto, el hueco entero y, encima, el trozo con nombre: manda el trozo
  const hueco = { km2: 264.03, provincias: '01 31' };
  const trozo = { km2: 49.11, provincias: '01', nombre: 'Parzoneria de Entzia', tipo: 'condominio' };
  assert.equal(elegirSinSeccion([hueco, trozo]), trozo);
  assert.equal(elegirSinSeccion([trozo, hueco]), trozo);
  assert.equal(elegirSinSeccion([hueco, { ...hueco, nombre: ' ' }]), hueco);
  assert.equal(elegirSinSeccion([null, hueco]), hueco);
  assert.equal(elegirSinSeccion([]), null);
  assert.equal(elegirSinSeccion(undefined), null);
  const territorios = { provincia: { '01': 'Araba/Álava', '31': 'Navarra', '20': 'Gipuzkoa' } };
  assert.deepEqual(provinciasSinSeccion(['31', '01', '20'], territorios), ['Araba/Álava', 'Gipuzkoa', 'Navarra']);
  assert.deepEqual(provinciasSinSeccion(['99'], territorios), ['99']);   // sin nombre, el código
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

test('URL: mapa, año o periodo y tipología de la barra', () => {
  assert.equal(consulta({ mapa: 'viviendas_turisticas', anio: '2025-05', tipologia: 'VU' }), '?mapa=viviendas_turisticas&anio=2025-05&tipologia=VU');
  assert.equal(consulta({ anio: '2025-13', tipologia: 'VX' }), '');
  assert.deepEqual(leerEstado('?anio=2024&tipologia=VU&mapa=renta_hogar'), { mapa: 'renta_hogar', anio: 2024, tipologia: 'VU' });
  assert.deepEqual(leerEstado('?anio=2025-05'), { anio: '2025-05' });
  assert.deepEqual(leerEstado('?anio=2025-5&tipologia=vu&mapa=Renta%20hogar'), {});
});

// --- Descargas ---------------------------------------------------------------------------------

// Traductor de prueba: devuelve la clave (sin sustituciones).
const tPrueba = (clave) => clave.split('.').at(-1);

test('descargas: nivel del CSV, redondeo y nombre del fichero', () => {
  assert.equal(exportar.nivelParaExportar('municipio', ['sc', 'distrito', 'municipio', 'provincia', 'ccaa']), 'municipio');
  assert.equal(exportar.nivelParaExportar('provincia', ['sc', 'municipio']), 'municipio');   // la renta no llega a provincia
  assert.equal(exportar.nivelParaExportar('provincia', ['sc']), 'sc');
  assert.equal(exportar.nivelParaExportar('sc', ['municipio']), 'municipio');
  assert.equal(exportar.redondear(1216.6666666, 1), 1216.7);
  assert.equal(exportar.redondear(0.15, 1), 0.1);   // como sprintf("%.1f", 0.15) en R: 0,15 es 0,1499… en binario
  assert.equal(exportar.decimalesDeEscala(10), 1);
  assert.equal(exportar.decimalesDeEscala(100), 2);
  assert.equal(exportar.nombreFichero({ mapa: 'sueldo_necesario', periodo: 2024, nivel: 'municipio', extension: 'csv' }),
    'de-renta-en-renta_sueldo_necesario_2024_municipio.csv');
  assert.equal(exportar.nombreFichero({ mapa: 'alquiler_m2', periodo: 2024, tipologia: 'VU', nivel: 'sc', extension: 'csv' }),
    'de-renta-en-renta_alquiler_m2_vu_2024_sc.csv');
  assert.equal(exportar.nombreFichero({ mapa: 'te_llega_peon', periodo: '2025-05', tipologia: 'VC', extension: 'png' }),
    'de-renta-en-renta_te_llega_peon_2025-05.png');
});

test('descargas: CSV con BOM, comillas cuando hacen falta, estados y supuestos', () => {
  const { cabecera, filas } = exportar.tablaCsv({
    t: tPrueba,
    codigos: ['2807901001', '2807901002', '2807901003'],
    valores: [7.3, null, 10],
    estados: Uint8Array.from([0, 2, 1]),
    nombresEstado: CODIFICACION.estados,
    nivel: 'sc',
    nombreDe: (c) => `Madrid, distrito 01, sección ${c.slice(7)}`,
    indicador: 'Sueldo neto necesario', unidad: '€ netos por mes', tipologia: 'Vivienda colectiva', periodo: 2024,
    fuente: 'SERPAVI; "cálculo propio"',
    transformar: (x) => FORMULAS.alquiler_m2_a_sueldo.calcular(x, { superficie_m2: 50, umbral: 0.3 }),
    decimales: 1,
    supuestos: { superficie_m2: 50, umbral: 0.3 },
  });
  assert.deepEqual(cabecera, ['codigo', 'nombre', 'nivel', 'indicador', 'tipologia', 'periodo', 'valor', 'unidad', 'estado', 'fuente', 'superficie_m2', 'umbral']);
  assert.deepEqual(filas.map((f) => f[6]), [1216.7, null, 1666.7]);
  assert.deepEqual(filas.map((f) => f[8]), ['dato', 'secreto', 'estimado']);
  const texto = exportar.textoCsv(cabecera, filas);
  assert.ok(texto.startsWith('﻿codigo,nombre,'));
  const lineas = texto.slice(1).split('\r\n');
  assert.equal(lineas.length, 5);   // cabecera, tres filas y el salto final
  assert.equal(lineas[1], '2807901001,"Madrid, distrito 01, sección 001",sc,Sueldo neto necesario,Vivienda colectiva,2024,1216.7,€ netos por mes,dato,"SERPAVI; ""cálculo propio""",50,0.3');
  assert.ok(lineas[2].includes(',,€ netos por mes,secreto,'));   // sin valor: campo vacío
});

test('descargas: el sueldo necesario lleva al lado el mínimo de la superficie elegida (tarea 40)', () => {
  const s = { superficie_m2: 50, umbral: 0.3 };
  const { cabecera, filas } = exportar.tablaCsv({
    t: tPrueba, codigos: ['2807901001', '2807901002', '2807901003'], valores: [570, null, 900],
    estados: Uint8Array.from([0, 2, 1]), nombresEstado: CODIFICACION.estados, nivel: 'sc', nombreDe: (c) => c,
    indicador: 'Sueldo neto necesario', unidad: '€ netos por mes', tipologia: 'Vivienda colectiva', periodo: 2024, fuente: 'SERPAVI',
    transformar: (x) => FORMULAS.alquiler_mes_a_sueldo.calcular(x, s), decimales: 1, supuestos: s,
    minimo: { valores: [7.3, null, 12], transformar: (x) => FORMULAS.alquiler_m2_a_sueldo.calcular(x, s) },
  });
  assert.deepEqual(cabecera.slice(-3), ['superficie_m2', 'umbral', 'valor_minimo']);
  assert.deepEqual(filas.map((f) => [f[6], f.at(-1)]), [[1900, 1216.7], [null, null], [3000, 2000]]);
  // Sin la serie del mínimo en ese nivel: la columna, vacía
  const vacia = exportar.tablaCsv({
    t: tPrueba, codigos: ['28'], valores: [600], estados: Uint8Array.from([0]), nombresEstado: CODIFICACION.estados, nivel: 'provincia',
    nombreDe: (c) => c, indicador: 'i', unidad: 'u', periodo: 2024, fuente: 'f', transformar: null, decimales: 1, supuestos: s,
    minimo: { valores: null, transformar: null },
  });
  assert.equal(vacia.filas[0].at(-1), null);
});

test('descargas: dos decimales con escala 100 y año anterior a la serie (preguntas 24 y 32)', () => {
  const t = (clave, datos) => (datos?.desde ? `sin dato: la serie empieza en ${datos.desde}` : clave.split('.').at(-1));
  const comun = {
    t, codigos: ['2807901001', '2807901002'], valores: [1.234, 0.5], estados: Uint8Array.from([0, 0]),
    nombresEstado: CODIFICACION.estados, nivel: 'sc', nombreDe: (c) => c, indicador: 'Viviendas turísticas',
    unidad: '% de las viviendas', tipologia: '', fuente: 'INE', decimales: exportar.decimalesDeEscala(100),
  };
  const { filas } = exportar.tablaCsv({ ...comun, periodo: '2026-05' });
  assert.deepEqual(filas.map((f) => f[6]), [1.23, 0.5]);
  const fuera = exportar.tablaCsv({ ...comun, periodo: 2020, desde: '2024-02' }).filas;
  assert.deepEqual(fuera.map((f) => [f[5], f[6], f[8]]), [
    [2020, null, 'sin dato: la serie empieza en 2024-02'],
    [2020, null, 'sin dato: la serie empieza en 2024-02'],
  ]);
});

// --- Fiabilidad de la mediana del alquiler (preguntas 12 y 15 ampliadas) -----------------------

test('fiabilidad: intervalo con el margen y «en el límite» a los dos lados del 30 y del 40 %', () => {
  assert.deepEqual(sueldo.intervaloMargen(2000, 10), { desde: 1800, hasta: 2200 });
  assert.equal(sueldo.intervaloMargen(null, 10), null);
  assert.equal(sueldo.intervaloMargen(2000, null), null);
  assert.equal(sueldo.intervaloMargen(2000, Number.NaN), null);
  // ±10 %: 0,28 llega a 0,308 (cruza el 30 %); 0,26 se queda en 0,286 (no cruza)
  assert.equal(sueldo.enLimiteLlega(0.28, 10), true);
  assert.equal(sueldo.enLimiteLlega(0.32, 10), true);    // baja a 0,288: debajo del 30 %
  assert.equal(sueldo.enLimiteLlega(0.26, 10), false);
  assert.equal(sueldo.enLimiteLlega(0.38, 10), true);    // sube a 0,418: pasa del 40 %
  assert.equal(sueldo.enLimiteLlega(0.43, 10), true);    // baja a 0,387: debajo del 40 %
  assert.equal(sueldo.enLimiteLlega(0.35, 10), false);   // de 0,315 a 0,385: el mismo tramo
  assert.equal(sueldo.enLimiteLlega(0.5, 10), false);
  assert.equal(sueldo.enLimiteLlega(0.28, null), false); // sin margen, nunca
  // Los tramos no cambian con el umbral elegido (40 %): «en el límite» tampoco
  const x = (valores) => (serie) => valores[serie] ?? null;
  for (const umbral of [30, 40]) {
    assert.equal(sueldo.umbralDe({ umbral }), umbral / 100);
    const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: PERFILES, sueldo: { neto: 1500, pagas: 12 }, superficie: 50 });
    const r = peon.calcular('2807901001', x({ alquiler_m2: 8.4 }));   // 420 / 1500 = 0,28
    assert.equal(sueldo.enLimiteLlega(r.ratio, 10), true);
  }
});

test('fiabilidad: estado de «¿te llega?», el del alquiler; sin ingreso de la ficha, ausente', () => {
  const x = (valores) => (serie) => valores[serie] ?? null;
  const mochila = sueldo.calculoLlega({ ficha: 'mochila', perfiles: PERFILES, superficie: 50 });
  assert.equal(mochila.ingreso('2807901001'), 1500);
  assert.equal(mochila.ingreso('4802001001'), null);                      // foral: sin mochila
  assert.equal(sueldo.estadoLlega(0, mochila.ingreso('2807901001'), 3), 0);
  assert.equal(sueldo.estadoLlega(2, mochila.ingreso('2807901001'), 3), 2);   // el del alquiler, también secreto
  assert.equal(sueldo.estadoLlega(0, mochila.ingreso('4802001001'), 3), 3);
  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles: PERFILES, superficie: null });
  assert.equal(llave.ingreso('2807901001', x({ renta_hogar: 36000 })), 3000);
  assert.equal(llave.ingreso('2807901001', x({ renta_hogar: null })), null);
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles: PERFILES, sueldo: { neto: 1500 }, superficie: 50 });
  assert.equal(peon.ingreso('4802001001'), 1500);
});

test('fiabilidad: la ficha dice contratos y margen, «pocos contratos», secreto y «sin contratos»', () => {
  const f = fiabilidad.fiabilidadFicha;
  assert.deepEqual(f({ contratos: 72, margen: 4.3, estado: 'dato' }), { tipo: 'mediana', contratos: 72, margen: 4.3, pocos: false });
  assert.deepEqual(f({ contratos: 12, margen: 11.8, estado: 'dato' }), { tipo: 'mediana', contratos: 12, margen: 11.8, pocos: true });
  assert.equal(f({ contratos: 30, margen: 5, estado: 'estimado' }).pocos, false);
  assert.equal(f({ contratos: 29, margen: 5, estado: 'dato', umbral: 20 }).pocos, false);
  assert.equal(f({ contratos: 15, margen: null, estado: 'dato' }).margen, null);
  assert.deepEqual(f({ contratos: 4, estado: 'secreto' }), { tipo: 'secreto', contratos: 4 });
  // Una sección con 0 contratos: no es «sin dato»
  assert.deepEqual(f({ contratos: 0, estado: 'ausente' }), { tipo: 'sin_contratos' });
  assert.equal(f({ contratos: null, estado: 'ausente' }), null);
  assert.equal(f({ contratos: undefined, estado: 'dato' }), null);
  // Series y umbral del manifiesto
  const m = { indicadores: { alquiler_m2: { fiabilidad: { contratos: 'c', margen: 'm' } }, renta_hogar: {} }, umbral_pocos_contratos: 25 };
  assert.deepEqual(fiabilidad.seriesFiabilidad(m, 'alquiler_m2'), { contratos: 'c', margen: 'm' });
  assert.equal(fiabilidad.seriesFiabilidad(m, 'renta_hogar'), null);
  assert.equal(fiabilidad.umbralPocos(m), 25);
  assert.equal(fiabilidad.umbralPocos({}), fiabilidad.UMBRAL_POCOS_CONTRATOS);
});

test('fiabilidad: el CSV lleva contratos y margen_pct, vacíos sin recuento o sin margen', () => {
  const { cabecera, filas } = exportar.tablaCsv({
    t: tPrueba, codigos: ['2807901001', '2807901002', '2807901003'], valores: [7.3, null, null],
    estados: Uint8Array.from([0, 2, 3]), nombresEstado: CODIFICACION.estados, nivel: 'sc', nombreDe: (c) => c,
    indicador: 'Sueldo neto necesario', unidad: '€ netos por mes', tipologia: 'Vivienda colectiva', periodo: 2024, fuente: 'SERPAVI',
    transformar: (x) => FORMULAS.alquiler_m2_a_sueldo.calcular(x, { superficie_m2: 50, umbral: 0.3 }), decimales: 1,
    supuestos: { superficie_m2: 50, umbral: 0.3 },
    fiabilidad: { contratos: [25, 4, 0], margen: [8.36, null, null] },
  });
  assert.deepEqual(cabecera.slice(-4), ['contratos', 'margen_pct', 'superficie_m2', 'umbral']);
  assert.deepEqual(filas.map((fila) => fila.slice(10, 12)), [[25, 8.4], [4, null], [0, null]]);
  // Sin series de fiabilidad, las columnas de siempre
  const sin = exportar.tablaCsv({ t: tPrueba, codigos: ['1'], valores: [1], estados: Uint8Array.from([0]), nombresEstado: CODIFICACION.estados,
    nivel: 'sc', nombreDe: (c) => c, indicador: 'x', unidad: 'u', periodo: 2024, fuente: 'f', decimales: 1 });
  assert.equal(sin.cabecera.includes('contratos'), false);
  // Con un año anterior a la serie, vacías
  const fuera = exportar.tablaCsv({ t: (c) => c.split('.').at(-1), codigos: ['1'], valores: [1], estados: Uint8Array.from([0]),
    nombresEstado: CODIFICACION.estados, nivel: 'sc', nombreDe: (c) => c, indicador: 'x', unidad: 'u', periodo: 2010,
    fuente: 'f', decimales: 1, desde: 2015, fiabilidad: { contratos: [25], margen: [8] } });
  assert.deepEqual(fuera.filas[0].slice(10, 12), [null, null]);
});

// --- Muestra y exportación del pipeline -------------------------------------------------------

// Contratos y margen de cada serie con `fiabilidad`, frente al estado de su mediana (regla de
// secreto del SERPAVI): con mediana, 10 o más contratos y margen; en secreto, de 1 a 9 y sin
// margen; sin dato, 0 contratos o ninguno, y sin margen. Devuelve los fallos.
function comprobarFiabilidad(m, indices, serie, nivel, p) {
  const fia = m.indicadores[serie].fiabilidad;
  const n = indices[nivel].length;
  const leerSerie = (s) => decodificar(leer('web', rutaValores(m.indicadores[s], nivel, p)), n, codificacionDe(m, s));
  const mediana = leerSerie(serie);
  const contratos = leerSerie(fia.contratos);
  const margen = leerSerie(fia.margen);
  const fallos = [];
  for (let i = 0; i < n; i++) {
    const e = m.codificacion.estados[mediana.estados[i]];
    const c = contratos.valores[i];
    const mg = margen.valores[i];
    const bien = e === 'dato' || e === 'estimado' ? c >= 10 && mg !== null
      : e === 'secreto' ? c >= 1 && c <= 9 && mg === null
        : (c === null || c === 0) && mg === null;
    if (!bien) fallos.push({ serie, nivel, p, codigo: indices[nivel][i], estado: e, contratos: c, margen: mg });
  }
  return fallos;
}

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
    // Escala propia (pregunta 24): potencia de diez, y nunca más decimales a la vista que guardados
    const escala = codificacionDe(m, serie).escala;
    assert.ok([10, 100, 1000].includes(escala), `${serie}: escala ${escala}`);
    assert.ok((def.decimales ?? 0) <= Math.log10(escala), `${serie}: decimales ${def.decimales} con escala ${escala}`);
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
  // Variantes por tipología: la de la vivienda unifamiliar apunta a la de por defecto y tiene sus
  // mismos niveles y periodos.
  for (const [serie, def] of Object.entries(m.indicadores)) {
    for (const variante of Object.values(def.variantes ?? {})) {
      const otra = m.indicadores[variante];
      assert.ok(otra, `${serie}: falta la variante ${variante}`);
      assert.equal(otra.por_defecto, serie, `${variante}: por_defecto`);
      assert.deepEqual(otra.niveles, def.niveles, `${variante}: niveles`);
      assert.deepEqual(periodos(otra), periodos(def), `${variante}: periodos`);
    }
  }
  // Fiabilidad (contratos y margen de la mediana del alquiler): las series existen, con los mismos
  // periodos que la serie a la que acompañan, sin mapa propio y con la tipología de la serie.
  for (const [serie, def] of Object.entries(m.indicadores)) {
    if (!def.fiabilidad) continue;
    for (const [papel, aux] of Object.entries(def.fiabilidad)) {
      assert.ok(['contratos', 'margen'].includes(papel), `${serie}: papel ${papel}`);
      assert.ok(m.indicadores[aux], `${serie}: falta ${aux}`);
      assert.deepEqual(periodos(m.indicadores[aux]), periodos(def), `${serie}: periodos de ${aux}`);
      assert.ok(!m.mapas[aux], `${aux}: sin mapa propio`);
      assert.equal(tipologiaDe(m, aux), tipologiaDe(m, serie) ?? 'VC', `${serie}: tipología de ${aux}`);
    }
  }
  for (const [id, def] of Object.entries(m.mapas)) {
    assert.ok(m.indicadores[def.base], `mapa sin serie base: ${def.base}`);
    assert.ok(!m.indicadores[def.base].por_defecto, `${id}: la base es la serie de por defecto, no una variante`);
    assert.ok(def.cortes.length >= 1 && def.cortes.length <= 6, 'de dos a siete tramos: de uno a seis cortes (tarea 51)');
    assert.ok(def.cortes.every((c, i) => i === 0 || c > def.cortes[i - 1]), 'cortes crecientes');
    for (const [juego, j] of Object.entries(def.juegos ?? {})) {
      assert.ok(j.cortes.length >= 1 && j.cortes.length <= 6, `${id}, juego ${juego}: de uno a seis cortes`);
      assert.ok(j.cortes.every((c, i) => i === 0 || c > j.cortes[i - 1]), `${id}, juego ${juego}: cortes crecientes`);
    }
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
    if (p.anios) {
      assert.ok(Object.values(p.anios).every((a) => Object.values(a).every((x) => x > 0 && x < 10000)), `${ficha}: neto de cada año`);
      assert.deepEqual(p.anios[String(p.anio)], p.neto_mensual, `${ficha}: el último año`);
    }
  }
  const territorios = leer('web', m.territorios);
  assert.ok(Object.keys(territorios.ccaa_de_provincia).every((p) => territorios.ccaa[territorios.ccaa_de_provincia[p]]), 'provincia → comunidad');
  return { m, indices };
}

test('muestra: los valores que escribe R se leen enteros y los nulos son secreto o ausente', () => {
  const { m, indices } = comprobarManifiesto(join('web', 'datos', 'ejemplo'), { completo: true });
  assert.equal(m.ejemplo, true);
  // Contratos y margen, coherentes con la mediana en todas las series de alquiler y años
  // (las del alquiler: el esfuerzo lleva también el estado de la renta)
  const conFiabilidad = Object.keys(m.indicadores).filter((s) => m.indicadores[s].fiabilidad && tieneTipologia(m, s));
  assert.ok(conFiabilidad.includes('alquiler_m2') && conFiabilidad.includes('alquiler_mes_vu'));
  const fallos = conFiabilidad.flatMap((s) => periodos(m.indicadores[s]).flatMap((p) => comprobarFiabilidad(m, indices, s, 'sc', p)));
  assert.deepEqual(fallos.slice(0, 3), []);
  assert.equal(m.umbral_pocos_contratos, 30);
  // La muestra prueba los selectores: varios mapas, uno por periodos con mes, y una tipología
  assert.ok(Object.keys(m.mapas).length > 1 && m.mapas.sueldo_necesario);
  assert.ok(Object.values(m.mapas).some((d) => m.indicadores[d.base].periodos));
  assert.equal(m.indicadores.alquiler_m2.variantes.VU, 'alquiler_m2_vu');
});

test('muestra: las series de la ficha cuadran, año a año, con los valores del mapa', () => {
  const m = leer('web', 'datos', 'ejemplo', 'manifiesto.json');
  const secciones = leer('web', m.indices.sc);
  const fichas = new Map();
  // Las series auxiliares (contratos y margen de la mediana) tampoco: la ficha las lee del periodo
  const auxiliares = new Set(Object.values(m.indicadores).flatMap((d) => Object.values(d.fiabilidad ?? {})));
  for (const [serie, def] of Object.entries(m.indicadores)) {
    // Las variantes de vivienda unifamiliar no van en las fichas (la web las saca de cada periodo).
    if (def.por_defecto || auxiliares.has(serie)) {
      assert.equal(leer('web', m.fichas.replace('{municipio}', secciones[0].slice(0, 5))).anios[serie], undefined);
      continue;
    }
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
  // Las viviendas turísticas (19), con dos decimales, como las publica el INE (pregunta 24)
  if (m.indicadores.viviendas_turisticas) {
    assert.equal(m.indicadores.viviendas_turisticas.escala, 100);
    assert.equal(m.indicadores.viviendas_turisticas.decimales, 2);
    assert.equal(m.mapas.viviendas_turisticas?.decimales ?? 2, 2);
  }
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

// Preguntas 12 y 15 ampliadas: lo que la página lee de contratos y margen casa con la mediana que
// pinta, en cada serie de alquiler (colectiva y unifamiliar) y en cada nivel del último año, y el
// umbral de «pocos contratos» es el de R.
test('exportación del pipeline: contratos y margen de cada mediana, coherentes con su estado', { skip: !exportada && 'sin web/datos/manifiesto.json' }, (t) => {
  const m = leer('web', 'datos', 'manifiesto.json');
  const indices = Object.fromEntries(Object.entries(m.indices).map(([nivel, ruta]) => [nivel, leer('web', ruta)]));
  assert.equal(m.umbral_pocos_contratos, 30);
  const series = ['alquiler_m2', 'alquiler_m2_vu', 'alquiler_mes', 'alquiler_mes_vu'].filter((s) => m.indicadores[s]?.fiabilidad);
  assert.equal(series.length, 4, 'las cuatro series del alquiler llevan fiabilidad');
  assert.deepEqual(m.indicadores.alquiler_m2.fiabilidad, { contratos: 'contratos_alquiler', margen: 'margen_alquiler_m2' });
  assert.deepEqual(m.indicadores.alquiler_mes_vu.fiabilidad, { contratos: 'contratos_alquiler_vu', margen: 'margen_alquiler_mes_vu' });
  let comparadas = 0;
  const fallos = [];
  for (const serie of series) {
    const def = m.indicadores[serie];
    const p = periodos(def).at(-1);
    for (const nivel of def.niveles) {
      fallos.push(...comprobarFiabilidad(m, indices, serie, nivel, p));
      comparadas += indices[nivel].length;
    }
  }
  t.diagnostic(`${comparadas} territorios comparados; ${fallos.length} fallos`);
  assert.deepEqual(fallos.slice(0, 5), []);
});

// Metadatos de un PMTiles (v3): cabecera de 127 bytes y JSON en la posición que dice, comprimido
// según la compresión interna (1: ninguna; 2: gzip).
function metadatosPmtiles(ruta) {
  const b = readFileSync(ruta);
  assert.equal(b.toString('latin1', 0, 7), 'PMTiles');
  assert.equal(b[7], 3, 'versión 3');
  const desde = Number(b.readBigUInt64LE(24));
  const largo = Number(b.readBigUInt64LE(32));
  const crudo = b.subarray(desde, desde + largo);
  return JSON.parse((b[97] === 2 ? gunzipSync(crudo) : crudo).toString('utf8'));
}

const teselas = exportada && join(raiz, 'web', leer('web', 'datos', 'manifiesto.json').mapa_base.url ?? '');
test('exportación del pipeline: el PMTiles trae las capas del manifiesto y el suelo sin sección en todos los zooms',
  { skip: !(teselas && existsSync(teselas)) && 'sin el PMTiles de web/teselas/' }, () => {
    const m = leer('web', 'datos', 'manifiesto.json');
    const capas = Object.fromEntries(metadatosPmtiles(teselas).vector_layers.map((c) => [c.id, c]));
    for (const [capa, def] of Object.entries(m.mapa_base.capas)) {
      assert.ok(capas[capa], `falta la capa ${capa}`);
      if (def.id) assert.ok(def.id in capas[capa].fields, `${capa}: sin ${def.id}`);
    }
    const s = capas.sin_seccion;
    assert.ok(s, 'capa sin_seccion');
    assert.deepEqual([s.minzoom, s.maxzoom], [0, 12]);
    assert.deepEqual(Object.keys(s.fields).sort(), ['km2', 'nombre', 'provincias', 'tipo']);
    assert.deepEqual(m.mapa_base.capas.sin_seccion.atributos, ['km2', 'provincias', 'nombre', 'tipo']);
  });

// Plan, §6.5: la página recalcula y coincide con R. El mapa del sueldo necesario (21) se pinta en
// el navegador desde el alquiler por m² (9) con formulas.js; aquí se hace la misma cuenta en
// todas las secciones (y en los demás niveles) y años, se redondea a una décima como la web
// (exportar.js) y se compara con la serie que exporta R, `sueldo_necesario`: mismo valor, mismos
// nulos y mismo estado.
test('§6.5: el sueldo necesario que calcula la página coincide con el de R', { skip: !exportada && 'sin web/datos/manifiesto.json' }, (t) => {
  const m = leer('web', 'datos', 'manifiesto.json');
  const mapa = m.mapas.sueldo_necesario;
  const publicada = m.indicadores.sueldo_necesario;
  assert.ok(mapa && publicada, 'el manifiesto tiene el mapa y la serie del sueldo necesario');
  const base = m.indicadores[mapa.base];
  const formula = formulaDe(mapa);
  const codificacion21 = codificacionDe(m, 'sueldo_necesario');
  const decimales = exportar.decimalesDeEscala(codificacion21.escala);
  const resultado = { comparadas: 0, conValor: 0, diferencias: [] };
  for (const nivel of publicada.niveles.filter((n) => base.niveles.includes(n))) {
    const n = leer('web', m.indices[nivel]).length;
    for (const p of periodos(publicada).filter((q) => periodos(base).includes(q))) {
      const alquiler = decodificar(leer('web', rutaValores(base, nivel, p)), n, codificacionDe(m, mapa.base));
      const bruto = leer('web', rutaValores(publicada, nivel, p));
      const r = decodificar(bruto, n, codificacion21);
      for (let i = 0; i < n; i++) {
        const x = alquiler.valores[i];
        const pagina = x === null ? null : Math.round(exportar.redondear(formula.calcular(x, m.supuestos), decimales) * codificacion21.escala);
        resultado.comparadas++;
        if (pagina !== null) resultado.conValor++;
        if (pagina !== bruto.v[i] || alquiler.estados[i] !== r.estados[i]) {
          resultado.diferencias.push({ nivel, periodo: p, i, pagina, r: bruto.v[i], estados: [alquiler.estados[i], r.estados[i]] });
        }
      }
    }
  }
  t.diagnostic(`${resultado.comparadas} territorios y años comparados (${resultado.conValor} con valor); ${resultado.diferencias.length} diferencias`);
  assert.ok(resultado.conValor > 0, 'hay valores que comparar');
  assert.deepEqual(resultado.diferencias.slice(0, 5), [], `${resultado.diferencias.length} diferencias`);
});
