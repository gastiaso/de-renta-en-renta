// Pruebas de la web sin navegador: formato de los valores (JSON de enteros), series de la
// ficha, fórmulas, «Tu sueldo», tipología, comparador, buscador, estado de la URL y descargas.
// Datos inventados; si el pipeline ya ha exportado web/datos/manifiesto.json, se comprueban
// también su contrato y que la página recalcula el sueldo necesario igual que R (plan, §6.5).
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/datos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const {
  decodificar, periodoPara, rutaValores, codificacionDe, serieDeTipologia, tieneTipologia, tipologiaDe,
} = await modulo('web/js/datos.js');
const exportar = await modulo('web/js/exportar.js');
const { FORMULAS, formulaDe } = await modulo('web/js/formulas.js');
const sueldo = await modulo('web/js/sueldo.js');
const { codigoComparado } = await modulo('web/js/comparador.js');
const { buscar, formasDeNombre } = await modulo('web/js/buscador.js');
const { ordenNatural } = await modulo('web/js/nombres.js');
const { consulta, leerEstado } = await modulo('web/js/estado.js');
const colores = await modulo('web/js/colores.js');

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

test('colores: seis tramos en el sueldo necesario; tres en «¿te llega?», sin dato aparte', () => {
  const paleta = colores.paletaDe(['r1', 'r2', 'r3', 'r4', 'r5', 'r6'], 'f');
  assert.deepEqual(paleta.llega, ['r1', 'r4', 'r6']);
  const def = { base: 'alquiler_m2', formula: 'alquiler_m2_a_sueldo', cortes: [1, 2, 3, 4, 5] };
  const necesario = sueldo.colorNecesario(def, { superficie_m2: 50, umbral: 0.3 }, paleta);
  assert.equal(necesario[0], 'case');
  assert.deepEqual(necesario[3].slice(2), ['r1', 1, 'r2', 2, 'r3', 3, 'r4', 4, 'r5', 5, 'r6']);
  // Un mapa de cinco tramos toma pasos repartidos de punta a punta
  const cinco = sueldo.colorNecesario({ ...def, cortes: [1, 2, 3, 4] }, { superficie_m2: 50, umbral: 0.3 }, paleta);
  assert.deepEqual(cinco[3].slice(2), ['r1', 1, 'r2', 2, 'r4', 3, 'r5', 4, 'r6']);
  assert.throws(() => sueldo.colorNecesario({ ...def, cortes: [1, 2, 3, 4, 5, 6] }, {}, paleta), /seis|6 pasos/);
  const llega = sueldo.colorLlega(sueldo.calculoLlega({ ficha: 'tartera', perfiles: PERFILES, superficie: 50 }), 'seccion', paleta);
  assert.deepEqual(llega.filter((x) => typeof x === 'string' && x !== 'case'), ['f', 'r1', 'r4', 'r6']);
});

test('colores: pasos de la rampa, contraste WCAG y contorno de las secciones', () => {
  assert.deepEqual(colores.pasosDeRampa(6, 6), [0, 1, 2, 3, 4, 5]);
  assert.deepEqual(colores.pasosDeRampa(5, 6), [0, 1, 3, 4, 5]);
  assert.deepEqual(colores.pasosDeRampa(3, 5), [0, 2, 4]);   // la rampa de cinco: pasos 1, 3 y 5, como antes
  assert.deepEqual(colores.clasesTramos(3, 6), ['tramo-1', 'tramo-4', 'tramo-6']);
  assert.throws(() => colores.pasosDeRampa(7, 6), /6 pasos/);
  assert.equal(colores.contraste('#000000', '#ffffff'), 21);
  assert.equal(colores.contraste('#777777', '#777777'), 1);
  // La rampa de tokens.json: tinta sobre los tres pasos claros (contraste ≥ 3:1), placa sobre los oscuros
  const tokens = leer('diseno', 'tokens.json');
  const rampa = tokens.rampa_secuencial.pasos.map((p) => p.hex);
  assert.equal(rampa.length, 6);
  rampa.forEach((hex, i) => assert.ok(Math.abs(colores.contraste(hex, tokens.colores.crema.hex) - tokens.rampa_secuencial.pasos[i].contraste_crema) <= 0.05, hex));
  const tinta = tokens.colores.tinta.hex;
  const placa = tokens.colores.placa.hex;
  const contorno = colores.paletaContorno(colores.paletaDe(rampa, '#cccccc'), tinta, placa);
  assert.deepEqual(contorno.rampa, [tinta, tinta, tinta, placa, placa, placa]);
  assert.deepEqual(contorno.llega, [tinta, placa, placa]);
  assert.equal(contorno.fuera, tinta);
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
  for (const [id, def] of Object.entries(m.mapas)) {
    assert.ok(m.indicadores[def.base], `mapa sin serie base: ${def.base}`);
    assert.ok(!m.indicadores[def.base].por_defecto, `${id}: la base es la serie de por defecto, no una variante`);
    assert.ok(def.cortes.length >= 1 && def.cortes.length <= 5, 'de dos a seis tramos: de uno a cinco cortes');
    assert.ok(def.cortes.every((c, i) => i === 0 || c > def.cortes[i - 1]), 'cortes crecientes');
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
  // La muestra prueba los selectores: varios mapas, uno por periodos con mes, y una tipología
  assert.ok(Object.keys(m.mapas).length > 1 && m.mapas.sueldo_necesario);
  assert.ok(Object.values(m.mapas).some((d) => m.indicadores[d.base].periodos));
  assert.equal(m.indicadores.alquiler_m2.variantes.VU, 'alquiler_m2_vu');
});

test('muestra: las series de la ficha cuadran, año a año, con los valores del mapa', () => {
  const m = leer('web', 'datos', 'ejemplo', 'manifiesto.json');
  const secciones = leer('web', m.indices.sc);
  const fichas = new Map();
  for (const [serie, def] of Object.entries(m.indicadores)) {
    // Las variantes de vivienda unifamiliar no van en las fichas (la web las saca de cada periodo).
    if (def.por_defecto) {
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
