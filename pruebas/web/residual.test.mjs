// Línea de ingreso residual (backlog, tarea 65; docs/especificacion_ingreso_residual.md, parte A):
// línea del año y del tipo de hogar, ingreso residual, tramos de la regla residual, color del mapa,
// resumen, estado en la dirección y, con la muestra de pruebas/datos/residual_muestra.json (la que
// escribe R, escribir_muestra_residual()), que la página da el mismo ingreso residual y el mismo tramo
// que R. Con la exportación del pipeline, datos/lineas_residual.json cumple su contrato. Desde la raíz:
//   node --test pruebas/web/residual.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const R = await modulo('web/js/residual.js');
const sueldo = await modulo('web/js/sueldo.js');
const { leerEstado, consulta } = await modulo('web/js/estado.js');
const { SUPUESTOS } = await modulo('web/js/supuestos.js');
const leer = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const cerca = (a, b) => Math.abs(a - b) < 1e-9 * Math.max(1, Math.abs(b));

// Tabla inventada con el formato de datos/lineas_residual.json
const TABLA = {
  limites: [1, 1.25],
  imv: { anios: {
    2019: { una_persona: 500, dos_adultos: 650, tipo: 'pnc' },
    2024: { una_persona: 600, dos_adultos: 780, tipo: 'imv' },
  } },
  ecv: { anios: { 2024: { una_persona: 1000, dos_adultos: 1500, ola: 2025 } } },
};
const COLORES = { fuera: 'gris', llega: ['verde', 'ambar', 'rojo'] };

test('supuestos: regla apagada por defecto, IMV por defecto y tramos en 1 y 1,25 × la línea', () => {
  assert.deepEqual([...R.REGLAS], ['porcentaje', 'residual']);
  assert.equal(R.REGLA_POR_DEFECTO, 'porcentaje');
  assert.deepEqual([...R.LINEAS], ['imv', 'ecv']);
  assert.equal(R.LINEA_POR_DEFECTO, 'imv');
  assert.deepEqual([...R.LIMITES_RESIDUAL], [1, 1.25]);
  assert.equal(R.reglaDe({}), 'porcentaje');
  assert.equal(R.reglaDe({ regla: 'residual' }), 'residual');
  assert.equal(R.reglaDe({ regla: 'otra' }), 'porcentaje');
  assert.equal(R.lineaDe({ linea: 'ecv' }), 'ecv');
  assert.equal(R.lineaDe({ linea: 'smi' }), 'imv');
  assert.equal(SUPUESTOS.linea_residual, 'imv');
});

test('tipo de hogar: una persona, dos adultos con segundo sueldo y la llave sin línea', () => {
  assert.equal(R.hogarDe('tartera'), 'una_persona');
  assert.equal(R.hogarDe('mochila'), 'una_persona');
  assert.equal(R.hogarDe('transistor'), 'una_persona');
  assert.equal(R.hogarDe('peon', { neto: 1500, pagas: 12 }), 'una_persona');
  assert.equal(R.hogarDe('peon', { neto: 1500, pagas: 12, segundo: 1000 }), 'dos_adultos');
  assert.equal(R.hogarDe('peon', { neto: 1500, pagas: 12, segundo: 0 }), 'una_persona');
  assert.equal(R.hogarDe('llave'), null);
  assert.equal(R.hogarDe(undefined), null);
});

test('línea del año del alquiler: IMV, PNC antes del IMV, ola de la ECV y año sin línea', () => {
  assert.deepEqual(R.lineaDelAnio(TABLA, 'imv', 2024, 'una_persona'), { linea: 'imv', hogar: 'una_persona', valor: 600, anio: 2024, tipo: 'imv' });
  assert.equal(R.lineaDelAnio(TABLA, 'imv', '2024-05', 'dos_adultos').valor, 780);
  assert.equal(R.lineaDelAnio(TABLA, 'imv', 2019, 'una_persona').tipo, 'pnc');
  const ecv = R.lineaDelAnio(TABLA, 'ecv', 2024, 'dos_adultos');
  assert.equal(ecv.valor, 1500);
  assert.equal(ecv.ola, 2025);
  assert.equal(ecv.tipo, 'ecv');
  // Sin umbral para los ingresos de 2025: lo dice, con el último año que lo tiene
  assert.deepEqual(R.lineaDelAnio(TABLA, 'ecv', 2025, 'una_persona'), { linea: 'ecv', hogar: 'una_persona', sin: true, anio: 2025, ultimo: 2024 });
  assert.equal(R.lineaDelAnio(TABLA, 'imv', 2024, null), null);
  assert.equal(R.lineaDelAnio(null, 'imv', 2024, 'una_persona'), null);
  assert.equal(R.lineaDelAnio(TABLA, 'imv', null, 'una_persona'), null);
});

test('ingreso residual: ingreso − alquiler − otros gastos, sin redondear; tramos con sus límites', () => {
  assert.equal(R.ingresoResidual({ ingreso: 1331.91, alquiler: 700 }), 1331.91 - 700);
  assert.equal(R.ingresoResidual({ ingreso: 1331.91, alquiler: 700, otros: 120.4 }), 1331.91 - 700 - 120.4);
  assert.equal(R.ingresoResidual({ ingreso: 0, alquiler: 700 }), null);
  assert.equal(R.ingresoResidual({ ingreso: 1000, alquiler: null }), null);
  assert.equal(R.ingresoResidual(null), null);
  // Ejemplo de la especificación: la tartera de 2026 con 700 € de alquiler queda por debajo del IMV de 2026
  const r = R.ingresoResidual({ ingreso: 1331.91, alquiler: 700 });
  assert.ok(cerca(r, 631.91));
  assert.equal(R.tramoResidual(r, 733.6), 2);
  // Límites: por debajo de la línea, 2; justo en la línea y hasta 1,25 ×, 1; por encima, 0
  assert.equal(R.tramoResidual(599.99, 600), 2);
  assert.equal(R.tramoResidual(600, 600), 1);
  assert.equal(R.tramoResidual(750, 600), 1);
  assert.equal(R.tramoResidual(750.01, 600), 0);
  assert.equal(R.tramoResidual(null, 600), null);
  // Negativo (el alquiler pasa del ingreso): por debajo
  assert.equal(R.tramoResidual(-50, 600), 2);
});

test('ficha: distancia a la línea, año sin línea y la llave «no aplica»', () => {
  const linea = R.lineaDelAnio(TABLA, 'imv', 2024, 'una_persona');
  const f = R.residualFicha({ ingreso: 1500, alquiler: 700, otros: 100 }, 'tartera', linea);
  assert.equal(f.residual, 700);
  assert.equal(f.distancia, 100);
  assert.equal(f.tramo, 1);
  assert.deepEqual(R.residualFicha({ ingreso: 1500, alquiler: 700 }, 'llave', null), { noAplica: true });
  const sin = R.lineaDelAnio(TABLA, 'ecv', 2025, 'una_persona');
  assert.deepEqual(R.residualFicha({ ingreso: 1500, alquiler: 700 }, 'tartera', sin), { linea: sin });
  assert.equal(R.residualFicha(null, 'tartera', linea), null);
  assert.equal(R.claveLinea(linea), 'interfaz.residual.nombre.imv');
  assert.equal(R.claveLinea(R.lineaDelAnio(TABLA, 'imv', 2019, 'una_persona')), 'interfaz.residual.nombre.pnc');
  assert.equal(R.claveLinea(R.lineaDelAnio(TABLA, 'ecv', 2024, 'una_persona')), 'interfaz.residual.nombre.ecv');
  // Decisiones del 17-nov-2026: 2020, «IMV desde el 1 de junio de 2020» (la misma cifra)
  const de2020 = R.lineaDelAnio({ imv: { anios: { 2020: { una_persona: 461.5, dos_adultos: 599.95, tipo: 'imv' } } } }, 'imv', 2020, 'una_persona');
  assert.equal(R.claveLinea(de2020), 'interfaz.residual.nombre.imv_2020');
  assert.ok(R.esInicioImv(de2020) && !R.esInicioImv(linea));
});

test('la llave con «Lo que queda»: el mapa va con la proporción y la elección se queda en el estado', () => {
  assert.equal(R.reglaEn({ ficha: 'llave', regla: 'residual' }), 'porcentaje');
  assert.equal(R.reglaEn({ ficha: 'tartera', regla: 'residual' }), 'residual');
  assert.equal(R.reglaEn({ ficha: 'llave' }), 'porcentaje');
  assert.equal(R.residualEnLlave({ ficha: 'llave', regla: 'residual' }), true);
  assert.equal(R.residualEnLlave({ ficha: 'tartera', regla: 'residual' }), false);
  assert.equal(R.residualEnLlave({ ficha: 'llave' }), false);
  // La dirección guarda «Lo que queda» con la llave: al volver a otra ficha, se recupera
  const q = consulta({ ficha: 'llave', regla: 'residual' });
  assert.match(q, /regla=residual/);
  assert.equal(leerEstado(q.startsWith('?') ? q : `?${q}`).regla, 'residual');
});

test('en el límite: el margen de la mediana del alquiler cruza un corte de la regla residual', () => {
  // 1.500 − 800 = 700 (tramo 1, entre 600 y 750); con ±10 %: de 620 a 780, cruza 750
  assert.equal(R.enLimiteResidual({ ingreso: 1500, alquiler: 800 }, 10, 600), true);
  assert.equal(R.enLimiteResidual({ ingreso: 1500, alquiler: 800 }, 1, 600), false);
  assert.equal(R.enLimiteResidual({ ingreso: 1500, alquiler: 800 }, null, 600), false);
});

// Con calculoLlega() de sueldo.js: «Tu ficha» con 1.500 € y 50 m², y otros gastos de 100 € en toda España
const GASTOS = { espana: { v: 100 }, ccaa: {}, provincia: {}, ccaaDeProvincia: {} };
const calculoPeon = (gastos = null) => sueldo.calculoLlega({
  ficha: 'peon', perfiles: {}, sueldo: { neto: 1500, pagas: 12 }, superficie: 50, gastos,
});

test('mapa: el color de la regla residual resta el gasto de vivienda del ingreso, con los otros gastos', () => {
  const calculo = calculoPeon(GASTOS);
  const color = R.colorResidual(calculo, 'id', COLORES, null, 600);
  assert.equal(color[0], 'case');
  // ['case', ['!', valido], fuera, ['<', resto, 600], rojo, ['<=', resto, 750], ámbar, verde]
  assert.equal(color[2], 'gris');
  assert.deepEqual(color[3][0], '<');
  assert.equal(color[3][2], 600);
  assert.equal(color[5][2], 750);
  assert.deepEqual(color.slice(4).filter((x) => typeof x === 'string'), ['rojo', 'ambar', 'verde']);
  const resto = color[3][1];
  assert.equal(resto[0], '-');
  assert.equal(resto[1], 1500);                                  // el ingreso de «Tu ficha»
  assert.deepEqual(resto[2][0], '+');                            // alquiler + otros gastos de vivienda
  assert.equal(resto[2][2], 100);
  // Sin línea o con la llave: sin color
  assert.equal(R.colorResidual(calculo, 'id', COLORES, null, null), 'gris');
  assert.equal(R.colorResidual({ ficha: 'llave' }, 'id', COLORES, null, 600), 'gris');
});

test('resumen: proporción de secciones donde lo que queda no baja de la línea, y con el alquiler real', () => {
  const calculo = calculoPeon();
  // Alquiler por m² de 4 secciones: 50 m² → 400, 900, 1.000 y sin dato; queda 1.100, 600, 500 y nada
  const m2 = [8, 18, 20, null];
  const mes = [500, 1200, null, null];
  const x = (serie, i) => (serie === 'alquiler_m2' ? m2[i] : serie === 'alquiler_mes' ? mes[i] : null);
  const r = R.resumenResidual(calculo, ['a', 'b', 'c', 'd'], x, 600);
  assert.deepEqual(r, { con: 3, encima: 2, proporcion: 2 / 3 });
  const real = R.resumenResidual(calculo, ['a', 'b', 'c', 'd'], x, 600, { real: true });
  assert.deepEqual(real, { con: 2, encima: 1, proporcion: 1 / 2 });
  // Con los otros gastos, también se restan: 1.000, 500, 400 → una por encima
  const conGastos = R.resumenResidual(calculoPeon(GASTOS), ['a', 'b', 'c', 'd'], x, 600);
  assert.equal(conGastos.encima, 1);
  assert.equal(R.resumenResidual(calculo, ['a'], x, null).proporcion, null);
});

test('dirección: regla=residual y linea=ecv entran y salen; lo demás no', () => {
  assert.deepEqual(leerEstado('?regla=residual&linea=ecv'), { regla: 'residual', linea: 'ecv' });
  assert.deepEqual(leerEstado('?regla=otra&linea=smi'), {});
  assert.equal(consulta({ ficha: 'tartera', regla: 'residual', linea: 'ecv' }), '?ficha=tartera&regla=residual&linea=ecv');
  assert.equal(consulta({ regla: undefined, linea: undefined }), '');
});

// R y la página coinciden: los casos de la muestra (los catorce territorios de 2024 × las combinaciones de
// «Tu ficha» y las tres fichas de una persona), con las líneas de 2024, sin y con los otros gastos
const ruta = join(raiz, 'pruebas', 'datos', 'residual_muestra.json');
test('muestra de R (pruebas/datos/residual_muestra.json): mismo ingreso residual y mismo tramo', { skip: !existsSync(ruta) }, () => {
  const j = JSON.parse(readFileSync(ruta, 'utf8'));
  assert.ok(j.casos.length > 500);
  let comprobados = 0;
  for (const c of j.casos) {
    const ficha = c.ficha;
    const sueldoC = ficha === 'peon' ? { neto: j.peon.neto, pagas: c.pagas, segundo: c.segundo ? j.peon.segundo : 0 } : null;
    assert.equal(R.hogarDe(ficha, sueldoC), c.hogar);
    for (const conGastos of [false, true]) {
      const r = { ingreso: c.ingreso, alquiler: c.alquiler, ...(conGastos ? { otros: c.otros } : {}) };
      const residual = R.ingresoResidual(r);
      const esperado = conGastos ? c.residual_gastos : c.residual;
      if (esperado === null) { assert.equal(residual, null); continue; }
      assert.ok(cerca(residual, esperado), `${c.geo_id} ${ficha} ${residual} ≠ ${esperado}`);
      for (const linea of ['imv', 'ecv']) {
        const l = R.lineaDelAnio(j.lineas, linea, j.anio, c.hogar);
        assert.equal(l.valor, c[`linea_${linea}`]);
        assert.equal(R.tramoResidual(residual, l.valor), c[`tramo_${linea}${conGastos ? '_gastos' : ''}`]);
        comprobados++;
      }
    }
  }
  assert.ok(comprobados > 1000);
});

// Con la exportación del pipeline: datos/lineas_residual.json
const exportado = join(raiz, 'web', 'datos', 'lineas_residual.json');
test('datos/lineas_residual.json: las dos líneas, de 2015 en adelante, con la escala de dos adultos', { skip: !existsSync(exportado) }, () => {
  const j = JSON.parse(readFileSync(exportado, 'utf8'));
  assert.deepEqual(j.limites, [1, 1.25]);
  for (const linea of ['imv', 'ecv']) {
    const anios = Object.keys(j[linea].anios).map(Number);
    assert.ok(Math.min(...anios) <= 2015, linea);
    for (const [a, x] of Object.entries(j[linea].anios)) {
      const escala = linea === 'imv' ? 1.3 : 1.5;
      assert.ok(Math.abs(x.dos_adultos - x.una_persona * escala) < 0.013, `${linea} ${a}`);
      assert.ok(x.una_persona > 300 && x.una_persona < 1500, `${linea} ${a}`);
    }
  }
  // Antes del IMV, la pensión no contributiva, rotulada
  assert.equal(j.imv.anios['2015'].tipo, 'pnc');
  assert.equal(j.imv.anios['2019'].tipo, 'pnc');
  assert.equal(j.imv.anios['2021'].tipo, 'imv');
  assert.equal(j.ecv.anios['2024'].ola, 2025);
});

// --- Remates de la web (tarea 65): sueldo necesario con la línea, evolución, CSV y portada ----------
const exportar = await modulo('web/js/exportar.js');
const ficha = await modulo('web/js/ficha.js');
const portada = await modulo('web/js/portada.js');

test('remates: sueldo necesario con la línea y lo que queda menos la línea', () => {
  assert.equal(R.sueldoConLinea(890, null, 604.21), 890 + 604.21);
  assert.equal(R.sueldoConLinea(890, 149.1, 604.21), 890 + 149.1 + 604.21);
  assert.equal(R.sueldoConLinea(null, 149.1, 604.21), null);
  assert.equal(R.sueldoConLinea(890, 149.1, null), null);
  assert.ok(cerca(R.distanciaLinea({ ingreso: 1237.4, alquiler: 890 }, 604.21), 1237.4 - 890 - 604.21));
  assert.ok(cerca(R.distanciaLinea({ ingreso: 1500, alquiler: 700, otros: 100 }, 600), 100));
  assert.equal(R.distanciaLinea({ ingreso: 0, alquiler: 700 }, 600), null);
  assert.equal(R.distanciaLinea({ ingreso: 1500, alquiler: 700 }, null), null);
});

test('remates: celda de la evolución, con la PNC antes del IMV, y textos en los dos idiomas', () => {
  const tt = (clave, v = {}) => `${clave}|${Object.values(v).join('|')}`;
  tt.numero = (x) => String(Math.round(x));
  assert.equal(ficha.celdaLinea(tt, R.lineaDelAnio(TABLA, 'imv', 2024, 'una_persona')), 'interfaz.residual.celda.imv|600');
  assert.equal(ficha.celdaLinea(tt, R.lineaDelAnio(TABLA, 'imv', 2019, 'una_persona')), 'interfaz.residual.celda.pnc|500');
  assert.equal(ficha.celdaLinea(tt, R.lineaDelAnio(TABLA, 'ecv', 2025, 'una_persona')), '—');
  assert.equal(ficha.celdaLinea(tt, null), null);
  for (const idioma of ['es', 'en']) {
    const j = JSON.parse(leer('web', 'i18n', `${idioma}.json`));
    const r = j.interfaz.residual;
    for (const k of ['sueldo_linea', 'sueldo_linea_gastos']) {
      // Decisiones del 17-nov-2026: la cola da la cifra de la línea sin repetir su nombre
      assert.deepEqual([...r[k].matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort(), ['cifra', 'corto', 'euros'], `${idioma} ${k}`);
    }
    for (const t of ['imv', 'pnc', 'ecv']) assert.match(r.celda[t], /\{euros\}/, `${idioma} celda.${t}`);
    for (const l of ['imv', 'ecv']) assert.match(r.evolucion_nota[l], /\{hogar\}/, `${idioma} evolucion_nota.${l}`);
    assert.ok(r.evolucion_pnc && r.no_aplica_corto && r.evolucion_2020);
    // Decisiones del 17-nov-2026: rótulo de 2020, la llave con la proporción y, en inglés, «pension»
    assert.match(r.nombre.imv_2020, /\{hogar\}/);
    assert.match(r.nombre.imv_2020, idioma === 'es' ? /IMV desde el 1 de junio de 2020/ : /IMV since 1 June 2020/);
    assert.match(r.llave_proporcion, /\{umbral\}/);
    assert.match(r.celda.pnc, idioma === 'es' ? /^PNC / : /^pension /);
    if (idioma === 'en') assert.ok(!/NCP/.test(JSON.stringify(r)), 'en: sin «NCP»');
    for (const c of ['linea_residual', 'linea_residual_euros', 'queda_menos_linea']) assert.ok(j.interfaz.exportar.columnas[c], `${idioma} ${c}`);
    assert.deepEqual([...j.portada.cuenta.linea.matchAll(/\{(\w+)\}/g)].map((x) => x[1]).sort(), ['encima', 'linea', 'pct', 'total']);
    // Revisión del 17-nov-2026: el nombre corto de la segunda cifra del sueldo necesario va por el tipo
    for (const c of ['imv', 'imv_2020', 'pnc', 'ecv']) assert.ok(r.corto[c], `${idioma} corto.${c}`);
  }
});

test('remates: la segunda cifra del sueldo necesario nombra la línea por su tipo (PNC antes de 2020)', () => {
  // Elementos mínimos para crear() de ficha.js, sin navegador
  const anterior = globalThis.document;
  globalThis.document = { createElement: (tag) => ({ tag, className: '', textContent: '', partes: [], append(...x) { this.partes.push(...x); } }) };
  try {
    const tt = (clave, v = {}) => `${clave}|${Object.values(v).join('|')}`;
    tt.numero = (x) => String(x);
    const corto = (linea) => ficha.lineaSueldoConLinea(tt, { valor: 1400, linea, gastos: false }).partes[0].split('|')[1];
    assert.equal(corto(R.lineaDelAnio(TABLA, 'imv', 2019, 'una_persona')), 'interfaz.residual.corto.pnc');
    assert.equal(corto(R.lineaDelAnio(TABLA, 'imv', 2024, 'una_persona')), 'interfaz.residual.corto.imv');
    assert.equal(corto(R.lineaDelAnio(TABLA, 'ecv', 2024, 'una_persona')), 'interfaz.residual.corto.ecv');
    const de2020 = R.lineaDelAnio({ imv: { anios: { 2020: { una_persona: 461.5, dos_adultos: 599.95, tipo: 'imv' } } } }, 'imv', 2020, 'una_persona');
    assert.equal(corto(de2020), 'interfaz.residual.corto.imv_2020');
  } finally {
    globalThis.document = anterior;
  }
});

test('remates: el CSV de «¿te llega?» lleva la línea y, con las fichas de una persona, lo que queda menos la línea', () => {
  const tt = (c) => c.split('.').at(-1);
  const base = {
    t: tt, codigos: ['2807901001', '2807901002'], valores: [17.8, null], estados: Uint8Array.from([0, 3]),
    nombresEstado: ['dato', 'estimado', 'secreto', 'ausente'], nivel: 'sc', nombreDe: (c) => c, indicador: 'i', unidad: 'u',
    tipologia: '', periodo: 2024, fuente: 'f', decimales: 1, supuestos: null,
  };
  const calculo = sueldo.calculoLlega({ ficha: 'tartera', perfiles: { tartera: { neto_mensual: { '00': 1237.4 } } }, superficie: 50 });
  const linea = { nombre: 'IMV', valor: 604.21, distancia: (codigo, i) => R.distanciaLinea(calculo.calcular(codigo, () => base.valores[i]), 604.21) };
  const { cabecera, filas } = exportar.tablaCsv({ ...base, linea });
  const k = (c) => cabecera.indexOf(c);
  assert.deepEqual(cabecera.slice(-3), ['linea_residual', 'linea_residual_euros', 'queda_menos_linea']);
  assert.equal(filas[0][k('linea_residual_euros')], 604.21);
  assert.equal(filas[0][k('queda_menos_linea')], Number((1237.4 - 890 - 604.21).toFixed(2)));   // −256,81
  assert.equal(filas[1][k('queda_menos_linea')], null);
  // «Tu ficha» (sin distancia: despejaría el sueldo) y la llave («no se aplica», sin cifra)
  const sin = exportar.tablaCsv({ ...base, linea: { nombre: 'IMV', valor: 604.21, distancia: null } });
  assert.deepEqual(sin.cabecera.slice(-2), ['linea_residual', 'linea_residual_euros']);
  const llave = exportar.tablaCsv({ ...base, linea: { nombre: 'no se aplica', valor: null, distancia: null } });
  assert.equal(llave.filas[0].at(-1), null);
  assert.equal(llave.filas[0].at(-2), 'no se aplica');
  // Sin línea, las columnas de antes
  assert.ok(!exportar.tablaCsv(base).cabecera.includes('linea_residual'));
});

test('remates, muestra de R: el mismo sueldo necesario con la línea y lo que queda menos la línea', { skip: !existsSync(ruta) }, () => {
  const j = JSON.parse(readFileSync(ruta, 'utf8'));
  let n = 0;
  for (const c of j.casos) {
    for (const linea of ['imv', 'ecv']) {
      const una = R.lineaDelAnio(j.lineas, linea, j.anio, 'una_persona').valor;
      if (c.alquiler_mes === null) continue;
      assert.ok(cerca(R.sueldoConLinea(c.alquiler_mes, null, una), c[`sueldo_linea_${linea}`]), `${c.geo_id} ${linea}`);
      // los otros gastos de la comunidad tal cual, sin el factor de la superficie de la ficha (19-nov-2026)
      assert.ok(cerca(R.sueldoConLinea(c.alquiler_mes, c.otros_sin_factor, una), c[`sueldo_linea_${linea}_gastos`]), `${c.geo_id} ${linea} gastos`);
      if (c.residual !== null) {
        const l = c[`linea_${linea}`];
        assert.ok(cerca(R.distanciaLinea({ ingreso: c.ingreso, alquiler: c.alquiler }, l), c.residual - l));
      }
      n++;
    }
  }
  assert.ok(n > 1000);
});

test('remates: la cuenta de la portada con la línea, con los datos reales, da lo mismo que R', { skip: !existsSync(ruta) }, (ctx) => {
  const j = JSON.parse(readFileSync(ruta, 'utf8'));
  // Sin datos reales de la web, se salta y lo dice; con ellos, la muestra tiene que traer la cuenta y ser
  // del mismo año que el alquiler de la portada (revisión del 17-nov-2026: antes daba la prueba por buena)
  if (!existsSync(join(raiz, 'web', 'datos', 'manifiesto.json'))) return ctx.skip('sin web/datos/manifiesto.json');
  const m = JSON.parse(leer('web', 'datos', 'manifiesto.json'));
  if (m.ejemplo) return ctx.skip('web/datos con la muestra de ejemplo');
  assert.ok(j.portada, 'la muestra no trae la cuenta de la portada: escribir_muestra_residual(…, tar_read(cuenta_portada_residual))');
  const s = portada.seriesCuenta(m);
  assert.equal(String(s.periodo), String(j.anio), 'la portada usa otro año del alquiler que la muestra de R: rehacer la muestra');
  const secciones = JSON.parse(leer('web', ...m.secciones.split('/')));
  const columnas = Object.fromEntries(s.pedidos.map(([serie, p]) => {
    const r = m.indicadores[serie].ruta.replaceAll('{nivel}', 'sc').replaceAll('{anio}', p);
    const { v } = JSON.parse(leer('web', ...r.split('/')));
    return [serie, { valores: v.map((x) => (x === null ? null : x / m.codificacion.escala)) }];
  }));
  const lineas = JSON.parse(leer('web', 'datos', 'lineas_residual.json'));
  for (const caso of j.portada) {
    for (const linea of ['imv', 'ecv']) {
      const r = portada.cuentaLinea(caso.neto, secciones, columnas, s.serie, R.lineaDelAnio(lineas, linea, s.periodo, 'una_persona'));
      assert.equal(r.con, caso.con, `${caso.neto} ${linea}`);
      assert.equal(r.encima, caso[`encima_${linea}`], `${caso.neto} ${linea}`);
    }
  }
  assert.equal(portada.cuentaLinea(1500, secciones, columnas, s.serie, null), null);
});
