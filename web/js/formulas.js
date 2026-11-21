// Transformaciones que la web aplica en el navegador a un indicador base (manifiesto, «mapas»).
// Cada una tiene dos caras que deben dar lo mismo: la expresión de estilo de MapLibre, para
// colorear el mapa sin volver a descargar teselas, y el cálculo en JS, para la ficha y la leyenda.
// El manifiesto solo nombra la fórmula; aquí no se evalúa texto que venga de los datos. Las que dan
// un sueldo llevan `sueldo`; las que usan la superficie elegida, `superficie`.

import { SUPUESTOS } from './supuestos.js';

// Otros gastos de vivienda (decisión del autor, 12-nov-2026): las dos fórmulas del sueldo necesario
// suman al alquiler `s.otros` si lo hay (la cifra del territorio, supuestosEn() de sueldo.js; en el
// mapa, una expresión de MapLibre, colorNecesario()). Sin `otros`, como antes.
// Con la superficie (decisión del autor, 18-nov-2026): solo crece la parte de los otros gastos ligada
// a los metros (comunidad, calefacción y combustibles, conservación; inventario/supuestos.csv,
// otros_gastos_parte_superficie). La cifra de la ECV vale tal cual para la superficie de referencia
// (otros_gastos_superficie_referencia, 50 m²); con otra superficie, × factorOtrosGastos(). La cifra
// con el alquiler mensual real, que no elige superficie, la suma tal cual.
export const OTROS_PARTE_SUPERFICIE = SUPUESTOS.otros_parte_superficie;
export const OTROS_SUPERFICIE_REFERENCIA = SUPUESTOS.otros_superficie_referencia;
export function factorOtrosGastos(superficie) {
  if (!Number.isFinite(superficie) || !(superficie > 0)) return 1;
  return 1 - OTROS_PARTE_SUPERFICIE + (OTROS_PARTE_SUPERFICIE * superficie) / OTROS_SUPERFICIE_REFERENCIA;
}
// Otros gastos de una cifra: los del territorio × el factor de su superficie; sin superficie (el piso
// real, la llave), tal cual; null sin cifra. Las columnas otros_gastos y otros_gastos_minimo del CSV
// (19-nov-2026).
export const otrosConFactor = (valor, superficie = null) => (Number.isFinite(valor) ? valor * factorOtrosGastos(superficie) : null);
const otrosDe = (s) => (Number.isFinite(s?.otros) ? s.otros : 0);
const sinOtros = (s) => s?.otros === undefined || s?.otros === null || s?.otros === 0;
// Los otros gastos con la superficie: la cifra (o su expresión en el mapa) × el factor, si no es 1.
const otrosConSuperficie = (s, superficie) => {
  const f = factorOtrosGastos(superficie);
  return f === 1 ? s.otros : typeof s.otros === 'number' ? s.otros * f : ['*', s.otros, f];
};
const masOtros = (valor, s, superficie = null) => (sinOtros(s) ? valor : ['+', valor, otrosConSuperficie(s, superficie)]);

export const FORMULAS = {
  // El indicador tal cual.
  directo: {
    expresion: (valor) => valor,
    calcular: (x) => x,
    fijo: () => 0,
  },
  // Indicador 21, cifra principal (decisión 4; tarea 40): sueldo neto mensual necesario para que el
  // alquiler mensual mediano real de la sección no pase del `umbral` del sueldo. Base: alquiler
  // mensual mediano (indicador 8). No usa la superficie.
  alquiler_mes_a_sueldo: {
    sueldo: true,
    expresion: (valor, s) => ['/', masOtros(valor, s), s.umbral],
    calcular: (x, s) => (x + otrosDe(s)) / s.umbral,
    // Parte de la cifra que no viene del alquiler (el margen de la mediana no la toca): otros / umbral
    fijo: (s) => otrosDe(s) / s.umbral,
  },
  // Indicador 21, mínimo teórico (al lado de la cifra principal; tarea 40): sueldo neto mensual
  // necesario para que el alquiler de `superficie_m2` no pase del `umbral` del sueldo. Base:
  // alquiler mediano por m² (indicador 9).
  alquiler_m2_a_sueldo: {
    sueldo: true,
    superficie: true,
    expresion: (valor, s) => ['/', masOtros(['*', valor, s.superficie_m2], s, s.superficie_m2), s.umbral],
    calcular: (x, s) => (x * s.superficie_m2 + otrosDe(s) * factorOtrosGastos(s.superficie_m2)) / s.umbral,
    fijo: (s) => (otrosDe(s) * factorOtrosGastos(s.superficie_m2)) / s.umbral,
  },
};

export function formulaDe(mapaDef) {
  const f = FORMULAS[mapaDef.formula ?? 'directo'];
  if (!f) throw new Error(`Fórmula desconocida en el manifiesto: ${mapaDef.formula}`);
  return f;
}

// Parte de la cifra de un mapa que no viene del alquiler (los otros gastos de vivienda en su unidad):
// la que el margen de la mediana del alquiler no toca (intervaloMargen() de sueldo.js).
export const fijoDe = (mapaDef, s) => formulaDe(mapaDef).fijo?.(s) ?? 0;

// ¿Da el mapa un sueldo (el indicador 21, con cualquiera de sus dos cifras)?
export const daSueldo = (mapaDef) => Boolean(mapaDef && formulaDe(mapaDef).sueldo);

// Tarea 40: el mínimo teórico de un mapa (`minimo` del manifiesto: { base, formula }), calculado con
// la superficie y el umbral elegidos. `x(serie)` da el valor de una serie; `serie(nombre)`, la de la
// tipología elegida. null sin `minimo` o sin dato.
export function minimoDe(mapaDef, x, supuestos, serie = (s) => s) {
  const def = mapaDef?.minimo;
  if (!def) return null;
  const base = x(serie(def.base));
  return base === null || base === undefined || !Number.isFinite(base) ? null : formulaDe(def).calcular(base, supuestos);
}

// Texto de los supuestos de un mapa que los usa (leyenda, ficha, comparador e imagen): con el mínimo
// al lado (el sueldo necesario; tarea 40), «Alquiler mediano de la sección · umbral del 30 %» y la
// superficie del mínimo; si no, la superficie y el umbral. Sin supuestos (los «directo»), null.
// Con los otros gastos de vivienda encendidos (supuestos.gastos), lo dice con su cifra: la del
// territorio (`otros`, supuestosEn() de sueldo.js) o, sin territorio, la horquilla de las comunidades.
// `otros`: otro texto para esa cifra (el comparador da la de sus dos columnas).
// Con el mínimo al lado, el factor de la superficie solo va con el mínimo: la cifra con el alquiler real
// suma los otros gastos tal cual, y el texto lo dice (textoOtrosGastos(), `minimo`; 19-nov-2026).
export function textoSupuestos(t, mapaDef, supuestos, otros = textoOtrosGastos(t, supuestos, { minimo: Boolean(mapaDef?.minimo) })) {
  if ((mapaDef?.formula ?? 'directo') === 'directo') return null;
  const umbral = t.porcentaje(supuestos.umbral);
  const sufijo = otros ? '_gastos' : '';
  if (mapaDef.minimo) return t(`interfaz.leyenda.supuestos_real${sufijo}`, { umbral, superficie: t.numero(supuestos.superficie_m2), otros });
  return t(`interfaz.leyenda.supuestos${sufijo}`, { superficie: t.numero(supuestos.superficie_m2), umbral, otros });
}

// Texto de los otros gastos de vivienda de unos supuestos (null si están apagados): con territorio,
// «149 € al mes en Aragón, ECV 2024», o la cifra de España si su muestra no llega; sin él, «de 114
// a 161 € al mes según la comunidad, ECV 2024». Con otra superficie que la de referencia, el factor
// («; con 70 m², × 1,20: …»). Lo usan la leyenda, la ficha, la imagen y «Tu sueldo». Con `minimo` (el
// sueldo necesario, con el alquiler real y el mínimo teórico al lado), el factor se dice del mínimo
// («; en el mínimo de 70 m², × 1,20: …; con el alquiler real, la cifra tal cual»; 19-nov-2026).
export function textoOtrosGastos(t, supuestos, { minimo = false } = {}) {
  const g = supuestos?.gastos;
  if (!g) return null;
  const anio = g.anio_ecv;
  const euros = (x) => t.numero(Math.round(x));
  const nombre = (c) => (c === '00' ? t('vocabulario.nivel.nacional') : g.nombres?.[c] ?? c);
  const de = supuestos.otros_de;
  // Con otra superficie que la de referencia, el factor de los otros gastos (18-nov-2026)
  const factor = factorOtrosGastos(supuestos.superficie_m2);
  const sufijo = factor === 1 ? ''
    : t(`interfaz.leyenda.otros_gastos_superficie${minimo ? '_minimo' : ''}`, { superficie: t.numero(supuestos.superficie_m2), factor: t.numero(factor, 2) });
  if (de && Number.isFinite(supuestos.otros)) {
    if (de.espana) {
      return t('interfaz.leyenda.otros_gastos_espana', { euros: euros(supuestos.otros), territorio: nombre(de.ccaa), minimo: t.numero(g.minimo ?? 0), anio }) + sufijo;
    }
    return t('interfaz.leyenda.otros_gastos', { euros: euros(supuestos.otros), territorio: nombre(de.ccaa), anio }) + sufijo;
  }
  const v = Object.values(g.ccaa ?? {}).map((x) => x.v).filter(Number.isFinite);
  if (!v.length) return t('interfaz.leyenda.otros_gastos', { euros: euros(g.espana.v), territorio: nombre('00'), anio }) + sufijo;
  return t('interfaz.leyenda.otros_gastos_rango', { desde: euros(Math.min(...v)), hasta: euros(Math.max(...v)), anio }) + sufijo;
}
