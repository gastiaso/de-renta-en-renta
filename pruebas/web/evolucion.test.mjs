// Pruebas sin navegador de la evolución de la ficha (backlog, tareas 43 y 45; web/js/evolucion.js):
//   - variaciones de un año solo con 30 contratos o más en los dos años; si no, la media anual de
//     tres años, marcada, o ninguna: nunca una variación de un año sin su aviso con pocos contratos;
//   - banda del margen (la cifra ± su margen) y puntos huecos con pocos contratos;
//   - geometría del gráfico: tramos cortados donde falta la cifra, banda y marcas del eje;
//   - aviso de euros corrientes con la variación del IPC del periodo (datos/ipc.json);
//   - la tabla de la evolución con la columna de variación, su cabecera, el gráfico y las notas;
//   - los textos nuevos, en castellano y en inglés.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/evolucion.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
// Intl separa la cifra y el % con un espacio duro en castellano (carácter 160)
const sinNbsp = (s) => s.split(String.fromCharCode(160)).join(' ');

// DOM de pega: solo lo que usa fichaSeries()
class Nodo {
  constructor(etiqueta) {
    this.etiqueta = etiqueta;
    this.hijos = [];
    this.className = '';
    this.textContent = '';
  }
  append(...xs) { this.hijos.push(...xs); }
  replaceChildren(...xs) { this.hijos = xs; }
  setAttribute() {}
  get texto() { return this.textContent + this.hijos.map((h) => (typeof h === 'string' ? h : h.texto)).join(''); }
  buscar(clase) {
    const dentro = this.hijos.filter((h) => typeof h !== 'string');
    return [...dentro.filter((h) => (h.className ?? '').split(' ').includes(clase)), ...dentro.flatMap((h) => h.buscar(clase))];
  }
}
globalThis.document = { createElement: (e) => new Nodo(e), documentElement: {}, getElementById: () => null, querySelector: () => null };
globalThis.fetch = async (ruta) => ({ ok: true, json: async () => JSON.parse(leerTexto('web', ruta)) });

const { cargarIdioma } = await modulo('web/js/i18n.js');
const E = await modulo('web/js/evolucion.js');
const ficha = await modulo('web/js/ficha.js');
const t = { es: await cargarIdioma('es'), en: await cargarIdioma('en') };

const PERIODOS = [2015, 2016, 2017, 2018, 2019, 2020];

// --- Variaciones con la regla de los contratos ------------------------------------------------------

test('variación de un año con 30 contratos o más en los dos años', () => {
  const v = E.variaciones({ periodos: PERIODOS, valores: [100, 110, 121, null, 130, 143], contratos: [40, 40, 40, 40, 40, 40] });
  assert.equal(v[0], null);                       // primer año
  assert.equal(v[1].tipo, 'anual');
  assert.ok(Math.abs(v[1].valor - 10) < 1e-9);
  assert.ok(Math.abs(v[2].valor - 10) < 1e-9);
  assert.equal(v[3], null);                       // sin cifra
  assert.equal(v[4], null);                       // sin cifra el año anterior
  assert.ok(Math.abs(v[5].valor - 10) < 1e-9);
});

test('con menos de 30 contratos en alguno de los dos años: media anual de tres años, o ninguna', () => {
  const valores = [100, 110, 121, 133.1, 120, 160];
  const contratos = [12, 40, 40, 25, 40, 40];
  const v = E.variaciones({ periodos: PERIODOS, valores, contratos });
  assert.equal(v[1].tipo, 'pocos');               // 2016 frente a 2015 (12 contratos) y sin 2013
  assert.equal(v[2].tipo, 'anual');               // 40 y 40
  assert.equal(v[3].tipo, 'media');               // 2018 tiene 25 contratos: media 2015–2018
  assert.equal(v[3].desde, 2015);
  assert.ok(Math.abs(v[3].valor - 10) < 1e-9);    // (133,1 / 100)^(1/3) = 1,1
  assert.equal(v[4].tipo, 'media');               // 2019 frente a 2018 (25): media 2016–2019
  assert.ok(Math.abs(v[4].valor - 100 * ((120 / 110) ** (1 / 3) - 1)) < 1e-9);
  assert.equal(v[5].tipo, 'anual');               // 40 y 40
  // Con contratos que no se conocen, nunca una variación de un año
  const sin = E.variaciones({ periodos: PERIODOS, valores, contratos: [40, null, 40, 40, 40, 40] });
  assert.notEqual(sin[1].tipo, 'anual');
  assert.notEqual(sin[2].tipo, 'anual');
});

test('ninguna variación de un año sin su aviso en una sección con pocos contratos (hecho cuando de la tarea 43)', () => {
  // Una sección inventada con pocos contratos todos los años salvo dos
  const valores = [480, 530, 470, 560, 600, 590];
  const contratos = [11, 14, 35, 18, 31, 33];
  const lista = E.variaciones({ periodos: PERIODOS, valores, contratos });
  const textos = E.textosVariacion(t.es, lista);
  PERIODOS.forEach((p, i) => {
    if (i === 0) return;
    const pocos = contratos[i] < 30 || contratos[i - 1] < 30;
    if (pocos) assert.ok(textos[i] === '' || textos[i] === '—' || textos[i].endsWith('†'), `${p}: «${textos[i]}»`);
  });
  assert.equal(sinNbsp(textos[5]), '−1,7 %');              // 2020 frente a 2019: 33 y 31 contratos
  // Y el pie explica las dos marcas
  const notas = E.notasEvolucion(t.es, { lista });
  assert.ok(notas.some((n) => n.startsWith('†')));
  assert.ok(notas.some((n) => n.startsWith('—')));
});

test('sin contratos (series que no son del alquiler), la variación de un año; periodos que no son años, ninguna', () => {
  const v = E.variaciones({ periodos: PERIODOS, valores: [1, 2, 3, 4, 5, 6] });
  assert.ok(v.slice(1).every((x) => x.tipo === 'anual'));
  const meses = E.variaciones({ periodos: ['2024-02', '2024-08'], valores: [1, 2], contratos: [40, 40] });
  assert.deepEqual(meses, [null, null]);
});

// --- Banda, pocos contratos e IPC ---------------------------------------------------------------------

test('banda del margen y puntos con pocos contratos', () => {
  const banda = E.bandaMargen([100, null, 200], [5, 3, null]);
  assert.deepEqual(banda[0], { desde: 95, hasta: 105 });
  assert.equal(banda[1], null);
  assert.equal(banda[2], null);
  assert.deepEqual(E.pocosContratos([100, null, 200, 300], [12, 5, 30, null]), [true, false, false, false]);
});

test('variación del IPC entre el primer y el último año', () => {
  const ipc = { anios: [2014, 2015, 2024, 2025], indice: [79.281, 78.885, 97.397, 100] };
  const x = E.variacionIpc(ipc, 2015, 2024);
  assert.equal(x.desde, 2015);
  assert.equal(x.hasta, 2024);
  assert.ok(Math.abs(x.valor - 23.467) < 0.001);
  assert.equal(E.variacionIpc(ipc, 2015, 2030), null);
  assert.equal(E.variacionIpc(ipc, '2024-02', '2025-08'), null);
  assert.equal(E.variacionIpc(null, 2015, 2024), null);
});

test('euros corrientes: la nota lo dice, con el IPC del periodo, en los dos idiomas', () => {
  assert.equal(E.enEuros(t.es('indicadores.alquiler_mes.unidad')), true);
  assert.equal(E.enEuros(t.en('indicadores.alquiler_mes.unidad')), true);
  assert.equal(E.enEuros(t.es('indicadores.gini.unidad')), false);
  const ipc = { desde: 2015, hasta: 2024, valor: 23.467 };
  const es = E.notasEvolucion(t.es, { euros: 'cifra', ipc }).join(' ');
  assert.match(es, /euros corrientes/);
  assert.match(sinNbsp(es), /IPC general de 2015 a 2024: \+23,5 %/);
  const en = E.notasEvolucion(t.en, { euros: 'cifra', ipc }).join(' ');
  assert.match(en, /current euros/);
  assert.match(en, /from 2015 to 2024: \+23\.5%/);
  // En «¿te llega?», los euros que quedan
  assert.match(E.notasEvolucion(t.es, { euros: 'resto' }).join(' '), /euros que quedan/);
  // Sin euros, nada
  assert.deepEqual(E.notasEvolucion(t.es, {}), []);
});

test('el fichero del IPC de la web, si está, tiene años e índices de la misma longitud', () => {
  let ipc = null;
  try { ipc = JSON.parse(leerTexto('web', 'datos', 'ipc.json')); } catch { return; }   // sin exportar: nada que probar
  assert.equal(ipc.anios.length, ipc.indice.length);
  assert.ok(ipc.anios.includes(2015) && ipc.anios.includes(2024));
});

// --- Geometría del gráfico ------------------------------------------------------------------------------

test('geometría: la línea y la banda se cortan donde falta la cifra; marcas que cubren el recorrido', () => {
  const valores = [100, 110, null, 130, 140];
  const banda = E.bandaMargen(valores, [10, 10, null, 10, null]);
  const g = E.geometriaEvolucion({ valores, banda });
  assert.equal(g.lineas.length, 2);
  assert.equal(g.bandas.length, 2);              // 2015–2016 y el punto suelto de 2018
  assert.equal(g.ys[2], null);
  assert.ok(g.xs.every((x, i) => i === 0 || x > g.xs[i - 1]));
  const min = Math.min(...g.marcas.map((m) => m.valor));
  const max = Math.max(...g.marcas.map((m) => m.valor));
  assert.ok(min <= 90 && max >= 143);
  // Menos de dos cifras: sin gráfico
  assert.equal(E.geometriaEvolucion({ valores: [null, 5, null] }), null);
});

test('marcas del eje redondas', () => {
  assert.deepEqual(E.marcasEje(0, 10), [0, 5, 10]);
  const m = E.marcasEje(1180, 1960);
  assert.ok(m[0] <= 1180 && m.at(-1) >= 1960);
  assert.ok(m.every((x) => x % 100 === 0 || x % 250 === 0));
});

// --- La tabla de la ficha --------------------------------------------------------------------------------

test('tabla de la evolución con variación, cabecera, gráfico y notas', () => {
  const contenedor = new Nodo('div');
  const grafico = new Nodo('svg');
  grafico.className = 'evo-grafico';
  const filas = [
    { periodo: 2023, texto: '1.150', estado: 0, variacion: null },
    { periodo: 2024, texto: '1.217', estado: 0, variacion: '+5,8 %' },
  ];
  ficha.fichaSeries(contenedor, {
    t: t.es, titulo: 'Evolución', filas, estados: ['dato', 'estimado', 'secreto', 'ausente'], periodo: 2024, grafico,
    cabeceras: { periodo: 'Año', cifra: '€ netos por mes', variacion: 'Variación' }, notas: ['En euros corrientes de cada año, sin descontar la inflación.'],
  });
  const seccion = contenedor.hijos[0];
  assert.equal(seccion.hijos[1], grafico);                      // el gráfico, bajo el título
  const tabla = contenedor.buscar('ficha-tabla')[0];
  assert.equal(tabla.hijos[0].etiqueta, 'thead');
  assert.deepEqual(tabla.hijos[0].hijos[0].hijos.map((c) => c.textContent), ['Año', '€ netos por mes', 'Variación', '']);
  const cuerpo = tabla.hijos[1].hijos;
  assert.equal(cuerpo[1].hijos[2].className, 'ficha-tabla-variacion');
  assert.equal(cuerpo[1].hijos[2].textContent, '+5,8 %');
  assert.equal(cuerpo[0].hijos[2].textContent, '');
  assert.ok(seccion.texto.includes('euros corrientes'));
  // Sin variación, la tabla de siempre (sin cabecera ni columna nueva)
  const otro = new Nodo('div');
  ficha.fichaSeries(otro, { t: t.es, titulo: 'Evolución', filas: [{ periodo: 2024, texto: '1.217', estado: 0 }], estados: ['dato'], periodo: 2024 });
  const tablaOtro = otro.buscar('ficha-tabla')[0];
  assert.equal(tablaOtro.hijos[0].etiqueta, 'tbody');
  assert.equal(tablaOtro.hijos[0].hijos[0].hijos.length, 3);
});

// --- Euros constantes (decisión del autor, 12-nov-2026) ------------------------------------------------

test('euros constantes: año base, índice de un año y deflactado como R (ipc_deflactar())', () => {
  const ipc = { anios: [2014, 2015, 2024, 2025], indice: [79.281, 78.885, 97.397, 100] };
  assert.equal(E.anioBaseIpc(ipc), 2025);
  assert.equal(E.anioBaseIpc({ ...ipc, anio_base: 2024 }), 2024);
  assert.equal(E.anioBaseIpc({ ...ipc, anio_base: 2030 }), 2025);   // un año base sin índice no vale
  assert.equal(E.anioBaseIpc(null), null);
  assert.equal(E.anioDePeriodo('2024-T2'), 2024);
  assert.equal(E.anioDePeriodo(2015), 2015);
  assert.equal(E.anioDePeriodo('T2'), null);
  // 1.000 € de 2015 en euros de 2025: 1.000 × 100 / 78,885
  assert.ok(Math.abs(E.deflactar(1000, 2015, ipc) - 1267.668124484)< 1e-6);
  assert.equal(E.deflactar(1000, 2025, ipc), 1000);
  assert.equal(E.deflactar(1000, 2016, ipc), null);   // sin media anual
  assert.equal(E.deflactar(null, 2015, ipc), null);
  assert.deepEqual(E.deflactarSerie([2015, '2025-T1', 2026], [100, 200, 300], ipc).map((x) => (x === null ? null : Math.round(x * 10) / 10)),
    [126.8, 200, null]);
});

test('euros constantes: la nota dice el año base y los periodos que quedan fuera, en los dos idiomas', () => {
  const ipc = { desde: 2015, hasta: 2024, valor: 23.467 };
  const es = sinNbsp(E.notasEvolucion(t.es, { euros: 'cifra', ipc, unidad: 'constantes', base: 2025, fuera: [2026] }).join(' '));
  assert.match(es, /En euros de 2025, con la inflación descontada/);
  assert.match(es, /fuera de los euros de 2025: 2026/);
  assert.match(es, /IPC general de 2015 a 2024: \+23,5 %/);
  assert.doesNotMatch(es, /euros corrientes/);
  const en = E.notasEvolucion(t.en, { euros: 'cifra', ipc, unidad: 'constantes', base: 2025 }).join(' ');
  assert.match(en, /In 2025 euros, adjusted for inflation/);
  // Con «corrientes», el aviso de siempre; en «¿te llega?» (resto), también aunque se pida constantes
  assert.match(E.notasEvolucion(t.es, { euros: 'cifra', unidad: 'corrientes', base: 2025 }).join(' '), /euros corrientes/);
  assert.match(E.notasEvolucion(t.es, { euros: 'resto', unidad: 'constantes', base: 2025 }).join(' '), /euros que quedan/);
});

test('euros constantes: el selector va bajo el título de la evolución', () => {
  const caja = new Nodo('div');
  const selector = new Nodo('div');
  selector.className = 'evo-euros';
  ficha.fichaSeries(caja, { t: t.es, titulo: 'Evolución', filas: [{ periodo: 2024, texto: '1.217', estado: 0 }], estados: ['dato'], periodo: 2024, selector });
  const seccion = caja.hijos[0];
  assert.equal(seccion.hijos[0].etiqueta, 'h3');
  assert.equal(seccion.hijos[1], selector);
});

test('euros constantes: la evolución abre en euros de cada año y no guarda la elección en la dirección', () => {
  const principal = leerTexto('web', 'js', 'principal.js');
  assert.match(principal, /let eurosEvolucion = 'corrientes';/);
  assert.doesNotMatch(leerTexto('web', 'js', 'estado.js'), /eurosEvolucion|euros_evolucion|constantes/);
});

// --- Textos ---------------------------------------------------------------------------------------------

test('los textos de la evolución están en castellano y en inglés', () => {
  const claves = ['evolucion_grafico', 'evolucion_banda', 'evolucion_pocos', 'cabecera_periodo', 'cabecera_variacion',
    'variacion_media', 'variacion_pocos', 'euros_corrientes', 'euros_corrientes_resto', 'ipc_periodo',
    'euros_grupo', 'euros_boton_constantes', 'euros_boton_corrientes', 'euros_constantes', 'euros_sin_ipc', 'euros_cabecera_constantes'];
  for (const idioma of ['es', 'en']) {
    for (const c of claves) assert.ok(t[idioma].existe(`interfaz.ficha.${c}`), `${idioma}: ${c}`);
  }
  assert.equal(E.textoVariacion(t.en, 4.24), '+4.2%');
  assert.equal(sinNbsp(E.textoVariacion(t.es, -0.81)), '−0,8 %');
  assert.equal(sinNbsp(E.textoVariacion(t.es, 0.01)), '0 %');
});
