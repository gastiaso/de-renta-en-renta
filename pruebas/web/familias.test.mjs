// Pruebas sin navegador de la tarea 34 (backlog): dos familias de indicadores de alquiler y euros
// que quedan al mes.
//   - la resta (ingreso de la ficha − alquiler) con los mismos términos que el porcentaje, cada
//     término redondeado al euro como lo enseña la web; negativa, «faltan»; nunca un umbral;
//   - la línea de la familia bajo el título de la leyenda («Quedarse · quien ya vive de alquiler»):
//     la del mapa del manifiesto, «quedarse» en «¿te llega?» y nada sin familia;
//   - la ficha y la evolución de «¿te llega?» con los euros al lado del porcentaje;
//   - la portada: gancho y pregunta en el centro, sin la línea de las familias ni sus lecturas
//     (decisión del autor, 12-nov-2026), y el dicho al pie.
// La leyenda y la ficha se pintan con un DOM mínimo de pega (solo lo que usan).
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/familias.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');

// --- DOM de pega y diccionarios reales ----------------------------------------------------------

class Nodo {
  constructor(etiqueta) {
    this.etiqueta = etiqueta;
    this.hijos = [];
    this.className = '';
    this.textContent = '';
    this.style = {};
    this.atributos = {};
  }
  get children() { return this.hijos.filter((h) => typeof h !== 'string'); }
  append(...xs) { this.hijos.push(...xs); }
  replaceChildren(...xs) { this.hijos = xs; }
  addEventListener() {}
  setAttribute(k, v) { this.atributos[k] = v; }
  // Texto de un nodo y sus hijos (los textos sueltos de append() son cadenas)
  get texto() { return this.textContent + this.hijos.map((h) => (typeof h === 'string' ? h : h.texto)).join(''); }
  buscar(clase) {
    const dentro = this.hijos.filter((h) => typeof h !== 'string');
    return [...dentro.filter((h) => h.className.split(' ').includes(clase)), ...dentro.flatMap((h) => h.buscar(clase))];
  }
}
globalThis.document = { createElement: (e) => new Nodo(e), documentElement: {}, getElementById: () => null, querySelector: () => null };
globalThis.getComputedStyle = () => ({
  getPropertyValue: (p) => { const n = Number(/--rampa-(\d+)/.exec(p)?.[1]); return n >= 1 && n <= 7 ? '#7d291e' : ''; },
});
// cargarIdioma() pide i18n/<idioma>.json: aquí, el fichero de web/i18n.
globalThis.fetch = async (ruta) => ({ ok: true, json: async () => JSON.parse(leerTexto('web', ruta)) });

const { cargarIdioma } = await modulo('web/js/i18n.js');
const sueldo = await modulo('web/js/sueldo.js');
const familias = await modulo('web/js/familias.js');
const { pintarLeyenda } = await modulo('web/js/leyenda.js');
const ficha = await modulo('web/js/ficha.js');
const portada = await modulo('web/js/portada.js');
const t = { es: await cargarIdioma('es'), en: await cargarIdioma('en') };

// --- Euros que quedan al mes ----------------------------------------------------------------------

test('euros que quedan: ingreso menos alquiler, con los dos términos ya redondeados al euro', () => {
  assert.equal(sueldo.eurosQueQuedan({ alquiler: 890, ingreso: 1237.4 }), 347);
  // La resta cuadra con las dos cifras que enseña la ficha (1.185 − 512), no con la resta sin redondear (672,2)
  const terminos = { alquiler: 512.4, ingreso: 1184.6 };
  assert.equal(sueldo.eurosQueQuedan(terminos), 673);
  const leida = (x) => Number(t.es.numero(x).replace(/\./g, ''));
  assert.equal(sueldo.eurosQueQuedan(terminos), leida(terminos.ingreso) - leida(terminos.alquiler));
  // Empates: al alza, como Intl.NumberFormat con las cifras positivas
  assert.equal(sueldo.eurosQueQuedan({ alquiler: 600.5, ingreso: 1000 }), 399);
  assert.equal(t.es.numero(600.5), '601');
});

test('euros que quedan: negativos si el alquiler pasa del ingreso; sin un término, nada', () => {
  assert.equal(sueldo.eurosQueQuedan({ alquiler: 1602, ingreso: 800 }), -802);
  assert.equal(sueldo.eurosQueQuedan({ alquiler: 1000.4, ingreso: 1000.4 }), 0);
  for (const malo of [null, undefined, {}, { alquiler: 500 }, { ingreso: 1000 }, { alquiler: null, ingreso: 1000 },
    { alquiler: 500, ingreso: 0 }, { alquiler: -1, ingreso: 1000 }, { alquiler: NaN, ingreso: 1000 }]) {
    assert.equal(sueldo.eurosQueQuedan(malo), null, JSON.stringify(malo));
  }
});

test('euros que quedan: los mismos términos que el porcentaje de «¿te llega?», en cada ficha', () => {
  const perfiles = {
    llave: { ingreso: { serie: 'renta_hogar', divisor: 12 }, vivienda: { serie: 'alquiler_mes' } },
    tartera: { anio: 2024, nivel: 'nacional', neto_mensual: { '00': 1237.4 }, superficie_m2: 50 },
  };
  const x = (valores) => (serie) => valores[serie] ?? null;
  const tartera = sueldo.calculoLlega({ ficha: 'tartera', perfiles, superficie: 50 }).calcular('2807901001', x({ alquiler_m2: 17.8 }));
  assert.equal(tartera.alquiler, 890);
  assert.equal(sueldo.eurosQueQuedan(tartera), 347);
  const peon = sueldo.calculoLlega({ ficha: 'peon', perfiles, sueldo: { neto: 800, pagas: 12 }, superficie: 90 })
    .calcular('2807901001', x({ alquiler_m2: 17.8 }));
  assert.equal(sueldo.eurosQueQuedan(peon), -802);
  const llave = sueldo.calculoLlega({ ficha: 'llave', perfiles, superficie: null }).calcular('2807901001', x({ alquiler_mes: 900, renta_hogar: 36000 }));
  assert.equal(sueldo.eurosQueQuedan(llave), 2100);   // 36.000 / 12 − 900
  assert.equal(sueldo.eurosQueQuedan(sueldo.calculoLlega({ ficha: 'tartera', perfiles, superficie: 50 }).calcular('2807901001', x({}))), null);
});

test('texto de los euros que quedan: «quedan», o «faltan» en positivo; singular con 1 €; en los dos idiomas', () => {
  const texto = (idioma, euros, opciones) => ficha.textoResto(t[idioma], euros, opciones)?.texto ?? null;
  assert.equal(texto('es', 347), 'Quedan 347 € al mes después del alquiler');
  assert.equal(texto('es', 1347), 'Quedan 1.347 € al mes después del alquiler');
  assert.equal(texto('es', -802), 'Faltan 802 € al mes para cubrir el alquiler');
  assert.equal(texto('es', 1), 'Queda 1 € al mes después del alquiler');
  assert.equal(texto('es', -1), 'Falta 1 € al mes para cubrir el alquiler');
  assert.equal(texto('es', 0), 'Quedan 0 € al mes después del alquiler');
  assert.equal(texto('es', 347, { corto: true }), 'quedan 347 €');
  assert.equal(texto('es', -802, { corto: true }), 'faltan 802 €');
  assert.equal(texto('en', 1347), '€1,347 left each month after rent');
  assert.equal(texto('en', -802), '€802 short of the rent each month');
  assert.equal(texto('en', -802, { corto: true }), '€802 short');
  // Con los otros gastos de vivienda restados, la frase larga lo dice; la corta no cambia (12-nov-2026)
  assert.equal(texto('es', 197, { gastos: true }), 'Quedan 197 € al mes después del alquiler y los otros gastos');
  assert.equal(texto('es', 1, { gastos: true }), 'Queda 1 € al mes después del alquiler y los otros gastos');
  assert.equal(texto('es', -10, { gastos: true }), 'Faltan 10 € al mes para cubrir el alquiler y los otros gastos');
  assert.equal(texto('es', -1, { gastos: true }), 'Falta 1 € al mes para cubrir el alquiler y los otros gastos');
  assert.equal(texto('es', 197, { corto: true, gastos: true }), 'quedan 197 €');
  assert.equal(texto('en', 197, { gastos: true }), '€197 left each month after rent and other housing costs');
  assert.equal(texto('en', -10, { gastos: true }), '€10 short of rent and other housing costs each month');
  assert.equal(texto('es', null), null);
  assert.equal(ficha.textoResto(t.es, -802).cifra, '802 €');
});

test('texto de los euros que quedan: una resta, sin umbral ni «acceso» o «barrera»', () => {
  for (const idioma of ['es', 'en']) {
    const dic = JSON.parse(leerTexto('web', 'i18n', `${idioma}.json`));
    const textos = [...Object.values(dic.interfaz.ficha.resto), ...Object.values(dic.interfaz.leyenda.lectura_familia)];
    assert.deepEqual(Object.keys(dic.interfaz.ficha.resto).sort(), [
      'euros', 'falta', 'falta_corto', 'falta_corto_uno', 'falta_gastos', 'falta_uno', 'falta_uno_gastos',
      'queda', 'queda_corto', 'queda_corto_uno', 'queda_gastos', 'queda_uno', 'queda_uno_gastos',
    ]);
    for (const s of textos) {
      assert.doesNotMatch(s, /llega|basta|suficien|alcanza|enough|afford|sufficien|make rent/i, s);
      assert.doesNotMatch(s, /acceso|access|barrera|barrier/i, s);
    }
  }
});

// --- Familia del mapa en la leyenda ---------------------------------------------------------------

test('familia: la del mapa del manifiesto; en «¿te llega?», siempre «quedarse»; si no, ninguna', () => {
  assert.equal(familias.familiaDe({ modo: 'necesario', mapaDef: { familia: 'quedarse' } }), 'quedarse');
  assert.equal(familias.familiaDe({ modo: 'necesario', mapaDef: { familia: 'entrar' } }), 'entrar');
  assert.equal(familias.familiaDe({ modo: 'necesario', mapaDef: { base: 'renta_hogar' } }), null);
  assert.equal(familias.familiaDe({ modo: 'necesario', mapaDef: { familia: 'otra' } }), null);
  assert.equal(familias.familiaDe({ modo: 'llega', mapaDef: { base: 'renta_hogar' } }), 'quedarse');
  assert.equal(familias.familiaDe({ modo: 'llega', mapaDef: { familia: 'entrar' } }), 'quedarse');
  assert.equal(familias.familiaDe(), null);
});

test('familia: nombre y lectura literal en los dos idiomas; sin sus textos, nada', () => {
  assert.equal(familias.textoFamilia(t.es, 'quedarse'), 'Quedarse · quien ya vive de alquiler');
  assert.equal(familias.textoFamilia(t.es, 'entrar'), 'Entrar · quien busca piso hoy');
  assert.equal(familias.textoFamilia(t.en, 'quedarse'), 'Staying · those already renting');
  assert.equal(familias.textoFamilia(t.en, 'entrar'), 'Moving in · those looking for a home today');
  assert.equal(familias.textoFamilia(t.es, null), null);
  assert.equal(familias.textoFamilia(t.es, 'otra'), null);
  const sinTextos = Object.assign((clave) => clave, { existe: () => false });
  assert.equal(familias.textoFamilia(sinTextos, 'quedarse'), null);
});

// Leyenda pintada: [summary, ...cuerpo]
function leyenda(idioma, datos) {
  const contenedor = new Nodo('div');
  pintarLeyenda(contenedor, t[idioma], { superficie: 50, umbral: 0.3, periodo: 2024, ...datos });
  return contenedor.hijos[0];
}
const MAPA_ALQUILER = { base: 'alquiler_mes', formula: 'directo', cortes: [350, 425, 500, 650], decimales: 0 };

test('leyenda: bajo el título, la familia del mapa con su lectura literal', () => {
  const pliegue = leyenda('es', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef: { ...MAPA_ALQUILER, familia: 'quedarse' } });
  assert.equal(pliegue.hijos[0].etiqueta, 'summary');
  assert.equal(pliegue.hijos[1].className, 'leyenda-familia');
  assert.equal(pliegue.hijos[1].textContent, 'Quedarse · quien ya vive de alquiler');
  assert.equal(pliegue.hijos[2].className, 'leyenda-unidad');
  const entrar = leyenda('en', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef: { ...MAPA_ALQUILER, familia: 'entrar' } });
  assert.equal(entrar.buscar('leyenda-familia')[0].textContent, 'Moving in · those looking for a home today');
});

test('leyenda: en «¿te llega?», «quedarse»; un mapa sin familia, sin línea', () => {
  const llega = leyenda('es', { modo: 'llega', mapaId: 'sueldo_necesario', mapaDef: { base: 'alquiler_m2' }, vivienda: '50 m²' });
  assert.equal(llega.buscar('leyenda-familia')[0].textContent, 'Quedarse · quien ya vive de alquiler');
  const renta = leyenda('es', { modo: 'necesario', mapaId: 'renta_hogar', mapaDef: { base: 'renta_hogar', cortes: [25000, 30000, 35000, 40000] } });
  assert.deepEqual(renta.buscar('leyenda-familia'), []);
});

test('leyenda: el juego de cortes de la escala que se ve, aviso al cambiar y año de anclaje (tarea 51)', () => {
  const mapaDef = {
    ...MAPA_ALQUILER, cortes: [325, 400, 450, 500, 600, 700],
    juegos: {
      seccion: { cortes: [325, 400, 450, 500, 600, 700], metodo: 'recalibrado', anio: 2024 },
      municipio: { cortes: [300, 350, 400, 450, 500, 600], metodo: 'anclado', anio: 2024 },
    },
  };
  const seccion = leyenda('es', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef, nivel: 'sc' });
  assert.equal(seccion.buscar('leyenda-tramo').length, 7);
  assert.deepEqual(seccion.buscar('leyenda-corte').map((n) => n.textContent), ['325', '400', '450', '500', '600', '700']);
  assert.match(seccion.buscar('leyenda-juego')[0].textContent, /^Tramos para secciones censales/);
  assert.deepEqual(seccion.buscar('leyenda-anclaje'), []);   // recalibrado: sin nota de anclaje
  const municipio = leyenda('es', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef, nivel: 'municipio', cambioJuego: true });
  assert.deepEqual(municipio.buscar('leyenda-corte').map((n) => n.textContent), ['300', '350', '400', '450', '500', '600']);
  const aviso = municipio.buscar('leyenda-juego-cambio')[0];
  assert.equal(aviso.textContent, 'Cambio de escala: ahora, tramos para municipios.');
  assert.equal(aviso.atributos.role, 'status');
  assert.match(municipio.buscar('leyenda-anclaje')[0].textContent, /^Tramos fijados con el último año \(2024\)/);
  const en = leyenda('en', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef, nivel: 'municipio' });
  assert.match(en.buscar('leyenda-anclaje')[0].textContent, /^Bands set with the latest year \(2024\)/);
  // Un solo juego (o ninguno): sin línea de escala
  const uno = leyenda('es', { modo: 'necesario', mapaId: 'alquiler_mes', mapaDef: MAPA_ALQUILER, nivel: 'municipio' });
  assert.deepEqual(uno.buscar('leyenda-juego'), []);
});

// --- Ficha y evolución de «¿te llega?» ------------------------------------------------------------

function fichaLlega(valor) {
  const contenedor = new Nodo('aside');
  ficha.fichaSeccion(contenedor, {
    t: t.es, codigo: '2807901001', territorios: { municipio: { 28079: 'Madrid' }, provincia: { 28: 'Madrid' } },
    modo: 'llega', mapaId: 'sueldo_necesario', mapaDef: { base: 'alquiler_m2' }, ficha: 'tartera',
    supuestos: { superficie_m2: 50, umbral: 0.3 }, anio: 2024, valor, estado: 0, estados: ['dato', 'estimado', 'secreto', 'ausente'],
  });
  return contenedor.buscar('ficha-valor')[0];
}

test('ficha de «¿te llega?»: los euros que quedan, justo después del porcentaje', () => {
  const r = { alquiler: 890, ingreso: 1237.4, ratio: 890 / 1237.4, tramo: 2 };
  const bloque = fichaLlega(r);
  const clases = bloque.hijos.map((h) => h.className);
  assert.equal(clases[clases.indexOf('ficha-cifra') + 1], 'ficha-resto');
  const resto = bloque.buscar('ficha-resto')[0];
  assert.equal(resto.texto, 'Quedan 347 € al mes después del alquiler');
  assert.equal(resto.buscar('ficha-resto-cifra')[0].textContent, '347 €');
  // Las dos cantidades de la resta, debajo
  assert.ok(bloque.buscar('ficha-estado').some((p) => p.textContent === 'Alquiler: 890 € · ingreso: 1.237 € al mes'));
  const falta = fichaLlega({ alquiler: 1602, ingreso: 800, ratio: 1602 / 800, tramo: 2 }).buscar('ficha-resto')[0];
  assert.equal(falta.texto, 'Faltan 802 € al mes para cubrir el alquiler');
  assert.deepEqual(fichaLlega(null).buscar('ficha-resto'), []);
});

test('evolución de «¿te llega?»: una columna con los euros; sin ellos, como antes', () => {
  const pintar = (filas) => {
    const contenedor = new Nodo('div');
    ficha.fichaSeries(contenedor, { t: t.es, titulo: 'Evolución', filas, estados: ['dato', 'estimado', 'secreto', 'ausente'], periodo: 2024 });
    return contenedor.buscar('ficha-tabla')[0].hijos[0].hijos;   // filas del tbody
  };
  const con = pintar([{ periodo: 2023, texto: '73 %', estado: 0, resto: 'quedan 319 €' }, { periodo: 2024, texto: '—', estado: 3, resto: null }]);
  assert.deepEqual(con[0].hijos.map((c) => c.className), [undefined, 'ficha-tabla-cifra', 'ficha-tabla-resto', 'ficha-tabla-estado'].map((c) => c ?? ''));
  assert.equal(con[0].hijos[2].textContent, 'quedan 319 €');
  assert.equal(con[1].hijos[2].textContent, '');
  const sin = pintar([{ periodo: 2024, texto: '1.217', estado: 0 }]);
  assert.equal(sin[0].hijos.length, 3);
});

// --- Portada --------------------------------------------------------------------------------------

test('portada: gancho y pregunta en el centro, sin la línea de las familias ni sus lecturas; el dicho, al pie', () => {
  const html = leerTexto('web', 'index.html');
  const centro = html.split('<section class="portada-centro"')[1].split('</section>')[0];
  const orden = ['sitio.titulo', 'sitio.subtitulo', 'sitio.gancho', 'sitio.lema'].map((c) => centro.indexOf(`data-i18n="${c}"`));
  assert.ok(orden.every((i) => i > 0), 'faltan textos en el centro');
  assert.deepEqual([...orden].sort((a, b) => a - b), orden, 'orden del centro');
  // Decisión del autor (12-nov-2026): ningún lector entendió las familias en el centro
  assert.ok(!centro.includes('sitio.familias') && !centro.includes('portada-lecturas'), 'sin las familias en el centro');
  assert.equal(t.es.existe('sitio.familias'), false);
  assert.equal('lecturasFamilias' in portada, false);
  assert.ok(!centro.includes('sitio.dicho'), 'el dicho ya no va en el centro');
  const pie = html.split('<footer class="portada-pie">')[1].split('</footer>')[0];
  assert.match(pie, /<p class="portada-dicho" data-i18n="sitio\.dicho">/);
});

// --- La oferta de Idealista, «próximamente» ---------------------------------------------------------

test('selector del mapa: la oferta, desactivada y «próximamente» mientras su capa no esté encendida', () => {
  const sinCapa = { sueldo_necesario: { base: 'alquiler_m2' }, alquiler_mes: { base: 'alquiler_mes' } };
  const op = familias.opcionProximamente(t.es, sinCapa);
  assert.equal(op.desactivada, true);
  assert.equal(op.valor, 'proximamente:precio_oferta');
  assert.match(op.texto, / · próximamente$/);
  assert.match(familias.opcionProximamente(t.en, sinCapa).texto, / · coming soon$/);
  // Con la capa encendida, el mapa de la oferta ya está: nada que anunciar
  assert.equal(familias.opcionProximamente(t.es, { ...sinCapa, precio_oferta_alquiler_idealista: { indicador: 'precio_oferta' } }), null);
  assert.equal(familias.opcionProximamente(t.es, { ...sinCapa, precio_oferta: { base: 'precio_oferta' } }), null);
});
